-- 2026-03-01: Re-apply signup request RPCs with explicit table aliases to avoid output-column ambiguity.

create or replace function public.sync_signup_request(
  p_account_type text default null,
  p_full_name text default null,
  p_organization_id uuid default null,
  p_organization_name text default null
)
returns table (
  id uuid,
  user_id uuid,
  email text,
  full_name text,
  account_type text,
  organization_id uuid,
  organization_name text,
  status text,
  requester_notes text,
  reviewer_notes text,
  reviewed_by uuid,
  reviewed_at timestamptz,
  submitted_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text := lower(coalesce(auth.jwt() ->> 'email', ''));
  v_requested_account_type text := lower(trim(coalesce(p_account_type, '')));
  v_metadata_account_type text := lower(trim(
    coalesce(
      auth.jwt() -> 'user_metadata' ->> 'account_type',
      auth.jwt() -> 'app_metadata' ->> 'account_type',
      ''
    )
  ));
  v_account_type text := '';
  v_org_id uuid := null;
  v_org_name text := '';
  v_full_name text := trim(coalesce(
    p_full_name,
    auth.jwt() -> 'user_metadata' ->> 'full_name',
    auth.jwt() -> 'user_metadata' ->> 'name',
    ''
  ));
  v_role public.app_role := null;
  v_org_type public.org_type := null;
  v_existing_status text := '';
  v_target_status text := 'pending';
  v_request public.signup_requests%rowtype;
begin
  if v_user_id is null then
    raise exception 'Unauthenticated';
  end if;

  select
    m.organization_id,
    m.role,
    o.org_type,
    o.name
  into
    v_org_id,
    v_role,
    v_org_type,
    v_org_name
  from public.organization_memberships m
  join public.organizations o on o.id = m.organization_id
  where m.user_id = v_user_id
  order by m.is_default desc, m.created_at asc
  limit 1;

  if p_organization_id is not null then
    if public.is_platform_admin() or exists (
      select 1
      from public.organization_memberships m
      where m.user_id = v_user_id
        and m.organization_id = p_organization_id
    ) then
      v_org_id := p_organization_id;
    end if;
  end if;

  if v_org_id is not null and (p_organization_name is null or trim(p_organization_name) = '') then
    select o.name into v_org_name
    from public.organizations o
    where o.id = v_org_id
    limit 1;
  else
    v_org_name := trim(coalesce(p_organization_name, v_org_name, ''));
  end if;

  if v_requested_account_type in ('company', 'auditor', 'third_party', 'insurer', 'incert') then
    v_account_type := v_requested_account_type;
  elsif v_metadata_account_type in ('company', 'auditor', 'third_party', 'insurer', 'incert') then
    v_account_type := v_metadata_account_type;
  else
    if v_role = 'platform_admin' then
      v_account_type := 'incert';
    elsif v_role = 'insurer_viewer' then
      v_account_type := 'insurer';
    elsif v_role in ('inspector', 'auditor_viewer') then
      v_account_type := 'auditor';
    elsif v_role = 'provider_admin' and v_org_type = 'auditor' then
      v_account_type := 'third_party';
    elsif v_role = 'provider_admin' then
      v_account_type := 'auditor';
    else
      v_account_type := 'company';
    end if;
  end if;

  if v_account_type = 'incert' and not (public.is_platform_admin() or v_email = 'capener182@googlemail.com') then
    v_account_type := case
      when v_role = 'insurer_viewer' then 'insurer'
      when v_role in ('inspector', 'auditor_viewer') then 'auditor'
      when v_role = 'provider_admin' and v_org_type = 'auditor' then 'third_party'
      when v_role = 'provider_admin' then 'auditor'
      else 'company'
    end;
  end if;

  if v_email = 'capener182@googlemail.com' then
    v_account_type := 'incert';
  end if;

  select sr.status
  into v_existing_status
  from public.signup_requests sr
  where sr.user_id = v_user_id
  limit 1;

  if v_account_type = 'incert' or public.is_platform_admin() then
    v_target_status := 'approved';
  elsif v_existing_status in ('pending', 'approved', 'rejected') then
    v_target_status := v_existing_status;
  else
    v_target_status := 'pending';
  end if;

  insert into public.signup_requests (
    user_id,
    email,
    full_name,
    account_type,
    organization_id,
    organization_name,
    status,
    submitted_at
  )
  values (
    v_user_id,
    nullif(v_email, ''),
    nullif(v_full_name, ''),
    v_account_type,
    v_org_id,
    nullif(v_org_name, ''),
    v_target_status,
    now()
  )
  on conflict on constraint signup_requests_user_id_key do update
    set email = excluded.email,
        full_name = coalesce(excluded.full_name, public.signup_requests.full_name),
        account_type = excluded.account_type,
        organization_id = coalesce(excluded.organization_id, public.signup_requests.organization_id),
        organization_name = coalesce(excluded.organization_name, public.signup_requests.organization_name),
        status = case
          when public.signup_requests.status = 'approved' then 'approved'
          when excluded.status = 'approved' then 'approved'
          when public.signup_requests.status = 'rejected' then 'rejected'
          else 'pending'
        end,
        submitted_at = coalesce(public.signup_requests.submitted_at, now())
  returning * into v_request;

  return query
  select
    v_request.id,
    v_request.user_id,
    v_request.email::text,
    v_request.full_name,
    v_request.account_type,
    v_request.organization_id,
    v_request.organization_name,
    v_request.status,
    v_request.requester_notes,
    v_request.reviewer_notes,
    v_request.reviewed_by,
    v_request.reviewed_at,
    v_request.submitted_at,
    v_request.created_at,
    v_request.updated_at;
end;
$$;

create or replace function public.review_signup_request(
  p_request_id uuid,
  p_status text,
  p_reviewer_notes text default null
)
returns table (
  id uuid,
  user_id uuid,
  email text,
  full_name text,
  account_type text,
  organization_id uuid,
  organization_name text,
  status text,
  requester_notes text,
  reviewer_notes text,
  reviewed_by uuid,
  reviewed_at timestamptz,
  submitted_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text := lower(trim(coalesce(p_status, '')));
  v_request public.signup_requests%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  if not public.is_platform_admin() then
    raise exception 'Not authorized';
  end if;

  if v_status not in ('pending', 'approved', 'rejected') then
    raise exception 'Invalid status';
  end if;

  update public.signup_requests sr
  set
    status = v_status,
    reviewer_notes = nullif(trim(coalesce(p_reviewer_notes, '')), ''),
    reviewed_by = case when v_status = 'pending' then null else auth.uid() end,
    reviewed_at = case when v_status = 'pending' then null else now() end,
    updated_at = now()
  where sr.id = p_request_id
  returning * into v_request;

  if v_request.id is null then
    raise exception 'Signup request not found';
  end if;

  return query
  select
    v_request.id,
    v_request.user_id,
    v_request.email::text,
    v_request.full_name,
    v_request.account_type,
    v_request.organization_id,
    v_request.organization_name,
    v_request.status,
    v_request.requester_notes,
    v_request.reviewer_notes,
    v_request.reviewed_by,
    v_request.reviewed_at,
    v_request.submitted_at,
    v_request.created_at,
    v_request.updated_at;
end;
$$;

create or replace function public.request_signup_reapproval(
  p_message text default null
)
returns table (
  id uuid,
  user_id uuid,
  email text,
  full_name text,
  account_type text,
  organization_id uuid,
  organization_name text,
  status text,
  requester_notes text,
  reviewer_notes text,
  reviewed_by uuid,
  reviewed_at timestamptz,
  submitted_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_request public.signup_requests%rowtype;
begin
  if v_user_id is null then
    raise exception 'Unauthenticated';
  end if;

  perform public.sync_signup_request();

  update public.signup_requests sr
  set
    status = 'pending',
    requester_notes = nullif(trim(coalesce(p_message, '')), ''),
    reviewed_by = null,
    reviewed_at = null,
    updated_at = now()
  where sr.user_id = v_user_id
    and sr.status = 'rejected'
  returning * into v_request;

  if v_request.id is null then
    select *
    into v_request
    from public.signup_requests sr
    where sr.user_id = v_user_id
    limit 1;
  end if;

  return query
  select
    v_request.id,
    v_request.user_id,
    v_request.email::text,
    v_request.full_name,
    v_request.account_type,
    v_request.organization_id,
    v_request.organization_name,
    v_request.status,
    v_request.requester_notes,
    v_request.reviewer_notes,
    v_request.reviewed_by,
    v_request.reviewed_at,
    v_request.submitted_at,
    v_request.created_at,
    v_request.updated_at;
end;
$$;

grant execute on function public.sync_signup_request(text, text, uuid, text) to authenticated;
grant execute on function public.review_signup_request(uuid, text, text) to authenticated;
grant execute on function public.request_signup_reapproval(text) to authenticated;
