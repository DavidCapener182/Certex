-- 2026-02-22: RPC helpers, verification, and realtime publication setup

create or replace function public.write_audit_log(
  p_organization_id uuid,
  p_action text,
  p_resource_type text,
  p_resource_id uuid default null,
  p_metadata jsonb default '{}'::jsonb,
  p_ip_address inet default null,
  p_user_agent text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_log_id uuid;
  v_actor_role public.app_role;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  if not (
    public.is_platform_admin()
    or public.is_member(p_organization_id)
  ) then
    raise exception 'Not authorized for organization %', p_organization_id;
  end if;

  select m.role
  into v_actor_role
  from public.organization_memberships m
  where m.organization_id = p_organization_id
    and m.user_id = auth.uid()
  order by m.created_at asc
  limit 1;

  insert into public.audit_logs (
    organization_id,
    actor_user_id,
    actor_role,
    action,
    resource_type,
    resource_id,
    ip_address,
    user_agent,
    metadata
  )
  values (
    p_organization_id,
    auth.uid(),
    v_actor_role,
    p_action,
    p_resource_type,
    p_resource_id,
    p_ip_address,
    p_user_agent,
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning id into v_log_id;

  return v_log_id;
end;
$$;

create or replace function public.create_share_link(
  p_organization_id uuid,
  p_resource_type public.share_resource_type,
  p_resource_id uuid,
  p_ttl_hours integer default 72,
  p_permissions jsonb default '{"read_only": true}'::jsonb
)
returns table (
  share_link_id uuid,
  token text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token text;
  v_token_hash text;
  v_expires_at timestamptz;
  v_share_link_id uuid;
  v_resource_ok boolean;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  if p_ttl_hours < 1 or p_ttl_hours > 24 * 365 then
    raise exception 'p_ttl_hours must be between 1 and 8760';
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(
      p_organization_id,
      array[
        'dutyholder_admin',
        'site_manager',
        'procurement',
        'provider_admin',
        'auditor_viewer',
        'insurer_viewer',
        'landlord_viewer'
      ]::public.app_role[]
    )
  ) then
    raise exception 'Not authorized to create share links for organization %', p_organization_id;
  end if;

  v_resource_ok := true;

  if p_resource_type = 'certificate' then
    select exists (
      select 1
      from public.certificates c
      where c.id = p_resource_id
        and (
          c.operator_organization_id = p_organization_id
          or c.provider_organization_id = p_organization_id
        )
    ) into v_resource_ok;
  end if;

  if not v_resource_ok then
    raise exception 'Resource % (%) not found in organization %', p_resource_type, p_resource_id, p_organization_id;
  end if;

  v_token := replace(replace(replace(encode(gen_random_bytes(24), 'base64'), '/', '_'), '+', '-'), '=', '');
  v_token_hash := encode(digest(v_token, 'sha256'), 'hex');
  v_expires_at := now() + make_interval(hours => p_ttl_hours);

  insert into public.share_links (
    organization_id,
    created_by,
    resource_type,
    resource_id,
    token_hash,
    permissions,
    expires_at
  )
  values (
    p_organization_id,
    auth.uid(),
    p_resource_type,
    p_resource_id,
    v_token_hash,
    coalesce(p_permissions, '{"read_only": true}'::jsonb),
    v_expires_at
  )
  returning id into v_share_link_id;

  perform public.write_audit_log(
    p_organization_id,
    'share_link.created',
    p_resource_type::text,
    p_resource_id,
    jsonb_build_object('share_link_id', v_share_link_id, 'expires_at', v_expires_at)
  );

  return query
  select v_share_link_id, v_token, v_expires_at;
end;
$$;

create or replace function public.verify_share_token(p_token text)
returns table (
  share_link_id uuid,
  resource_type public.share_resource_type,
  resource_id uuid,
  organization_id uuid,
  expires_at timestamptz,
  certificate_id uuid,
  certificate_number text,
  asset_external_id text,
  asset_name text,
  provider_name text,
  issue_date date,
  expiry_date date,
  certificate_status public.certificate_status,
  sha256_hash text,
  verification_state text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token_hash text;
  v_link public.share_links%rowtype;
begin
  if p_token is null or length(trim(p_token)) = 0 then
    return;
  end if;

  v_token_hash := encode(digest(trim(p_token), 'sha256'), 'hex');

  select *
  into v_link
  from public.share_links sl
  where sl.token_hash = v_token_hash
  limit 1;

  if not found then
    return;
  end if;

  if v_link.revoked_at is not null then
    return query
    select
      v_link.id,
      v_link.resource_type,
      v_link.resource_id,
      v_link.organization_id,
      v_link.expires_at,
      null::uuid,
      null::text,
      null::text,
      null::text,
      null::text,
      null::date,
      null::date,
      null::public.certificate_status,
      null::text,
      'revoked'::text;
    return;
  end if;

  if v_link.expires_at <= now() then
    return query
    select
      v_link.id,
      v_link.resource_type,
      v_link.resource_id,
      v_link.organization_id,
      v_link.expires_at,
      null::uuid,
      null::text,
      null::text,
      null::text,
      null::text,
      null::date,
      null::date,
      null::public.certificate_status,
      null::text,
      'expired_link'::text;
    return;
  end if;

  update public.share_links
  set
    access_count = access_count + 1,
    last_accessed_at = now()
  where id = v_link.id;

  if v_link.resource_type = 'certificate' then
    return query
    select
      v_link.id,
      v_link.resource_type,
      v_link.resource_id,
      v_link.organization_id,
      v_link.expires_at,
      c.id,
      c.certificate_number,
      a.external_asset_id,
      a.name,
      p.name,
      c.issue_date,
      c.expiry_date,
      c.status,
      c.sha256_hash,
      case when c.status in ('valid', 'expired') then 'verified' else c.status::text end as verification_state
    from public.certificates c
    join public.assets a on a.id = c.asset_id
    join public.organizations p on p.id = c.provider_organization_id
    where c.id = v_link.resource_id;

    return;
  end if;

  return query
  select
    v_link.id,
    v_link.resource_type,
    v_link.resource_id,
    v_link.organization_id,
    v_link.expires_at,
    null::uuid,
    null::text,
    null::text,
    null::text,
    null::text,
    null::date,
    null::date,
    null::public.certificate_status,
    null::text,
    'valid_link'::text;
end;
$$;

create or replace function public.queue_notification(
  p_organization_id uuid,
  p_user_id uuid,
  p_kind text,
  p_title text,
  p_message text,
  p_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_notification_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(
      p_organization_id,
      array['dutyholder_admin', 'site_manager', 'procurement', 'provider_admin']::public.app_role[]
    )
  ) then
    raise exception 'Not authorized to queue notification';
  end if;

  insert into public.notifications (
    organization_id,
    user_id,
    kind,
    title,
    message,
    payload
  )
  values (
    p_organization_id,
    p_user_id,
    p_kind,
    p_title,
    p_message,
    coalesce(p_payload, '{}'::jsonb)
  )
  returning id into v_notification_id;

  return v_notification_id;
end;
$$;

create or replace function public.mark_notification_read(p_notification_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return false;
  end if;

  update public.notifications n
  set read_at = coalesce(n.read_at, now())
  where n.id = p_notification_id
    and n.user_id = auth.uid();

  return found;
end;
$$;

create or replace function public.refresh_compliance_snapshot(
  p_organization_id uuid,
  p_snapshot_month date default date_trunc('month', now())::date
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rows integer;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(p_organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
  ) then
    raise exception 'Not authorized to refresh compliance snapshots';
  end if;

  delete from public.compliance_snapshots cs
  where cs.organization_id = p_organization_id
    and cs.snapshot_month = p_snapshot_month;

  insert into public.compliance_snapshots (
    organization_id,
    snapshot_month,
    regime,
    compliant_count,
    warning_count,
    overdue_count
  )
  select
    p_organization_id,
    p_snapshot_month,
    a.regime,
    count(*) filter (where a.status = 'compliant')::integer,
    count(*) filter (where a.status = 'warning')::integer,
    count(*) filter (where a.status = 'overdue')::integer
  from public.assets a
  where a.organization_id = p_organization_id
  group by a.regime;

  get diagnostics v_rows = row_count;
  return v_rows;
end;
$$;

create or replace function public.log_certificate_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_role public.app_role;
begin
  if new.status is distinct from old.status then
    select m.role
    into v_actor_role
    from public.organization_memberships m
    where m.organization_id = new.operator_organization_id
      and m.user_id = auth.uid()
    order by m.created_at asc
    limit 1;

    insert into public.audit_logs (
      organization_id,
      actor_user_id,
      actor_role,
      action,
      resource_type,
      resource_id,
      metadata
    )
    values (
      new.operator_organization_id,
      auth.uid(),
      v_actor_role,
      'certificate.status_changed',
      'certificate',
      new.id,
      jsonb_build_object(
        'previous_status', old.status,
        'new_status', new.status,
        'certificate_number', new.certificate_number
      )
    );
  end if;

  return new;
end;
$$;

drop trigger if exists tr_log_certificate_status_change on public.certificates;
create trigger tr_log_certificate_status_change
after update of status on public.certificates
for each row execute function public.log_certificate_status_change();

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.notifications;
    exception
      when duplicate_object then null;
    end;

    begin
      alter publication supabase_realtime add table public.inspection_jobs;
    exception
      when duplicate_object then null;
    end;

    begin
      alter publication supabase_realtime add table public.certificates;
    exception
      when duplicate_object then null;
    end;

    begin
      alter publication supabase_realtime add table public.inspection_requests;
    exception
      when duplicate_object then null;
    end;

    begin
      alter publication supabase_realtime add table public.assets;
    exception
      when duplicate_object then null;
    end;
  end if;
end $$;

grant execute on function public.write_audit_log(uuid, text, text, uuid, jsonb, inet, text) to authenticated;
grant execute on function public.create_share_link(uuid, public.share_resource_type, uuid, integer, jsonb) to authenticated;
grant execute on function public.verify_share_token(text) to anon, authenticated;
grant execute on function public.queue_notification(uuid, uuid, text, text, text, jsonb) to authenticated;
grant execute on function public.mark_notification_read(uuid) to authenticated;
grant execute on function public.refresh_compliance_snapshot(uuid, date) to authenticated;
