-- 2026-03-01: Re-apply bootstrap_current_user_access with qualified membership columns for legacy schemas.

create or replace function public.bootstrap_current_user_access(
  p_account_type text default null,
  p_full_name text default null,
  p_organization_name text default null
)
returns table (
  organization_id uuid,
  organization_name text,
  account_type text,
  role text,
  created_organization boolean,
  created_membership boolean,
  elevated_to_platform_admin boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text := lower(coalesce(auth.jwt() ->> 'email', ''));
  v_metadata_account_type text := lower(
    trim(
      coalesce(
        auth.jwt() -> 'user_metadata' ->> 'account_type',
        auth.jwt() -> 'app_metadata' ->> 'account_type',
        ''
      )
    )
  );
  v_requested_account_type text := lower(trim(coalesce(p_account_type, '')));
  v_target_account_type text := '';
  v_target_role public.app_role := 'dutyholder_admin';
  v_target_org_type public.org_type := 'operator';
  v_target_org_name text := '';
  v_profile_name text := trim(
    coalesce(
      p_full_name,
      auth.jwt() -> 'user_metadata' ->> 'full_name',
      auth.jwt() -> 'user_metadata' ->> 'name',
      ''
    )
  );
  v_profile_company text := trim(
    coalesce(
      nullif(trim(coalesce(p_organization_name, '')), ''),
      nullif(trim(coalesce(auth.jwt() -> 'user_metadata' ->> 'organization_name', '')), ''),
      'Workspace'
    )
  );
  v_profile_name_or_email text := '';
  v_org_slug text := '';
  v_org_id uuid := null;
  v_created_org boolean := false;
  v_created_membership boolean := false;
  v_elevated boolean := false;
  v_membership_count integer := 0;
  v_default_org_id uuid := null;
  v_has_platform_membership boolean := false;
  v_resolved_role public.app_role := null;
  v_resolved_org_type public.org_type := null;
begin
  if v_user_id is null then
    raise exception 'Unauthenticated';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'company'
  ) then
    execute $profile_upsert$
      insert into public.profiles (id, display_name, company)
      values ($1, $2, $3)
      on conflict (id) do nothing
    $profile_upsert$
    using v_user_id, nullif(v_profile_name, ''), v_profile_company;
  else
    insert into public.profiles (id, display_name)
    values (v_user_id, nullif(v_profile_name, ''))
    on conflict (id) do nothing;
  end if;

  select count(*)::integer
  into v_membership_count
  from public.organization_memberships m
  where m.user_id = v_user_id;

  select m.organization_id
  into v_default_org_id
  from public.organization_memberships m
  where m.user_id = v_user_id
    and m.is_default
  order by m.created_at asc
  limit 1;

  v_target_account_type := coalesce(
    nullif(v_requested_account_type, ''),
    nullif(v_metadata_account_type, ''),
    'company'
  );
  if v_target_account_type not in ('company', 'auditor', 'third_party', 'insurer', 'incert') then
    v_target_account_type := 'company';
  end if;

  if v_target_account_type = 'incert' then
    if v_email = 'capener182@googlemail.com' or public.is_platform_admin() then
      v_target_account_type := 'incert';
    else
      v_target_account_type := coalesce(nullif(v_metadata_account_type, ''), 'company');
      if v_target_account_type not in ('company', 'auditor', 'third_party', 'insurer') then
        v_target_account_type := 'company';
      end if;
    end if;
  end if;

  if v_email = 'capener182@googlemail.com' then
    v_target_account_type := 'incert';
  end if;

  case v_target_account_type
    when 'incert' then
      v_target_role := 'platform_admin';
      v_target_org_type := 'platform';
      v_target_org_name := 'InCert Team';
    when 'auditor' then
      v_target_role := 'inspector';
      v_target_org_type := 'provider';
    when 'third_party' then
      v_target_role := 'provider_admin';
      v_target_org_type := 'auditor';
    when 'insurer' then
      v_target_role := 'insurer_viewer';
      v_target_org_type := 'insurer';
    else
      v_target_role := 'dutyholder_admin';
      v_target_org_type := 'operator';
  end case;

  if v_target_account_type <> 'incert' then
    v_profile_name_or_email := trim(
      coalesce(
        nullif(trim(coalesce(p_organization_name, '')), ''),
        nullif(v_profile_name, ''),
        split_part(v_email, '@', 1),
        'Workspace'
      )
    );
    v_profile_name_or_email := regexp_replace(v_profile_name_or_email, '[^a-zA-Z0-9 ]+', ' ', 'g');
    v_profile_name_or_email := trim(regexp_replace(v_profile_name_or_email, '\s+', ' ', 'g'));
    if v_profile_name_or_email = '' then
      v_profile_name_or_email := 'Workspace';
    end if;

    if v_target_account_type = 'company' then
      v_target_org_name := case
        when v_profile_name_or_email ~* 'company$' then v_profile_name_or_email
        else v_profile_name_or_email || ' Company'
      end;
    elsif v_target_account_type = 'auditor' then
      v_target_org_name := case
        when v_profile_name_or_email ~* 'auditor$' then v_profile_name_or_email
        else v_profile_name_or_email || ' Auditor'
      end;
    elsif v_target_account_type = 'third_party' then
      v_target_org_name := case
        when v_profile_name_or_email ~* '(audit company|auditors)$' then v_profile_name_or_email
        else v_profile_name_or_email || ' Audit Company'
      end;
    elsif v_target_account_type = 'insurer' then
      v_target_org_name := case
        when v_profile_name_or_email ~* 'insurer$' then v_profile_name_or_email
        else v_profile_name_or_email || ' Insurer'
      end;
    else
      v_target_org_name := v_profile_name_or_email;
    end if;
  end if;

  if v_target_account_type = 'incert' then
    select o.id, o.name
    into v_org_id, v_target_org_name
    from public.organizations o
    where o.org_type = 'platform'
      and (o.slug = 'incert-team' or lower(o.name) = 'incert team')
    order by o.created_at asc
    limit 1;

    if v_org_id is null then
      insert into public.organizations (name, slug, org_type)
      values ('InCert Team', 'incert-team', 'platform')
      returning id, name into v_org_id, v_target_org_name;
      v_created_org := true;
    end if;

    select exists(
      select 1
      from public.organization_memberships m
      where m.organization_id = v_org_id
        and m.user_id = v_user_id
        and m.role = 'platform_admin'
    )
    into v_has_platform_membership;

    if not v_has_platform_membership then
      insert into public.organization_memberships (organization_id, user_id, role, is_default)
      values (v_org_id, v_user_id, 'platform_admin', true)
      on conflict (organization_id, user_id, role) do nothing;

      get diagnostics v_membership_count = row_count;
      v_created_membership := v_membership_count > 0;
    end if;

    update public.organization_memberships m
    set is_default = (m.organization_id = v_org_id and m.role = 'platform_admin')
    where m.user_id = v_user_id;

    v_elevated := v_email = 'capener182@googlemail.com';
  elsif v_membership_count = 0 then
    v_org_slug := lower(regexp_replace(v_target_org_name, '[^a-z0-9]+', '-', 'g'));
    v_org_slug := regexp_replace(v_org_slug, '(^-|-$)', '', 'g');
    if v_org_slug = '' then
      v_org_slug := 'workspace';
    end if;
    v_org_slug := left(v_org_slug || '-' || substr(replace(v_user_id::text, '-', ''), 1, 8), 63);

    insert into public.organizations (name, slug, org_type)
    values (v_target_org_name, v_org_slug, v_target_org_type)
    returning id into v_org_id;
    v_created_org := true;

    insert into public.organization_memberships (organization_id, user_id, role, is_default)
    values (v_org_id, v_user_id, v_target_role, true);
    v_created_membership := true;
  end if;

  if v_default_org_id is null then
    select m.organization_id
    into v_default_org_id
    from public.organization_memberships m
    where m.user_id = v_user_id
    order by m.is_default desc, m.created_at asc
    limit 1;

    if v_default_org_id is not null then
      update public.organization_memberships m
      set is_default = (m.organization_id = v_default_org_id)
      where m.user_id = v_user_id;
    end if;
  end if;

  select
    m.organization_id,
    o.name,
    m.role,
    o.org_type
  into
    v_org_id,
    v_target_org_name,
    v_resolved_role,
    v_resolved_org_type
  from public.organization_memberships m
  join public.organizations o on o.id = m.organization_id
  where m.user_id = v_user_id
  order by m.is_default desc, m.created_at asc
  limit 1;

  if v_resolved_role = 'platform_admin' then
    v_target_account_type := 'incert';
  elsif v_resolved_role = 'insurer_viewer' then
    v_target_account_type := 'insurer';
  elsif v_resolved_role in ('inspector', 'auditor_viewer') then
    v_target_account_type := 'auditor';
  elsif v_resolved_role = 'provider_admin' and v_resolved_org_type = 'auditor' then
    v_target_account_type := 'third_party';
  elsif v_resolved_role = 'provider_admin' then
    v_target_account_type := 'auditor';
  else
    v_target_account_type := 'company';
  end if;

  return query
  select
    v_org_id,
    coalesce(v_target_org_name, ''),
    v_target_account_type,
    coalesce(v_resolved_role::text, ''),
    coalesce(v_created_org, false),
    coalesce(v_created_membership, false),
    coalesce(v_elevated, false);
end;
$$;

grant execute on function public.bootstrap_current_user_access(text, text, text) to authenticated;
