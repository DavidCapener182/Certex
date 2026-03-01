-- 2026-03-01: Ensure configured super-admin account is confirmed and mapped to InCert Team.

do $$
declare
  v_super_admin_email text := 'capener182@googlemail.com';
  v_user_id uuid;
  v_platform_org_id uuid;
begin
  select o.id
  into v_platform_org_id
  from public.organizations o
  where o.org_type = 'platform'
    and (o.slug = 'incert-team' or lower(o.name) = 'incert team')
  order by o.created_at asc
  limit 1;

  if v_platform_org_id is null then
    insert into public.organizations (name, slug, org_type)
    values ('InCert Team', 'incert-team', 'platform')
    returning id into v_platform_org_id;
  end if;

  select u.id
  into v_user_id
  from auth.users u
  where lower(u.email) = v_super_admin_email
  order by u.created_at asc
  limit 1;

  if v_user_id is null then
    return;
  end if;

  update auth.users
  set
    email_confirmed_at = coalesce(email_confirmed_at, now()),
    raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb)
      || jsonb_build_object('account_type', 'incert')
      || jsonb_build_object('full_name', coalesce(raw_user_meta_data ->> 'full_name', 'InCert Super Admin'))
  where id = v_user_id;

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
    using v_user_id, 'InCert Super Admin', 'InCert Team';
  else
    insert into public.profiles (id, display_name)
    values (v_user_id, 'InCert Super Admin')
    on conflict (id) do nothing;
  end if;

  insert into public.organization_memberships (organization_id, user_id, role, is_default)
  values (v_platform_org_id, v_user_id, 'platform_admin', true)
  on conflict (organization_id, user_id, role) do nothing;

  update public.organization_memberships
  set is_default = (organization_id = v_platform_org_id and role = 'platform_admin')
  where user_id = v_user_id;
end $$;
