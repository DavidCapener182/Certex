-- 2026-02-26: Integrations/webhooks, mobile hardening, and enterprise controls

-- Enums

do $$
begin
  if not exists (select 1 from pg_type where typname = 'integration_sync_status') then
    create type public.integration_sync_status as enum (
      'queued',
      'running',
      'succeeded',
      'failed',
      'cancelled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'webhook_delivery_status') then
    create type public.webhook_delivery_status as enum (
      'pending',
      'delivered',
      'failed',
      'dead_letter'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'mobile_session_status') then
    create type public.mobile_session_status as enum (
      'active',
      'paused',
      'synced',
      'closed',
      'conflict'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'device_attestation_status') then
    create type public.device_attestation_status as enum (
      'unknown',
      'trusted',
      'revoked'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'sso_provider_kind') then
    create type public.sso_provider_kind as enum (
      'saml',
      'oidc',
      'azure_ad',
      'okta',
      'google_workspace'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'security_event_severity') then
    create type public.security_event_severity as enum (
      'info',
      'low',
      'medium',
      'high',
      'critical'
    );
  end if;
end $$;

create table if not exists public."InCert-api_clients" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  client_key text not null unique,
  scopes jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  last_used_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-api_client_secrets" (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public."InCert-api_clients"(id) on delete cascade,
  secret_hash text not null,
  valid_from timestamptz not null default now(),
  valid_to timestamptz,
  rotated_by uuid references auth.users(id) on delete set null,
  revoked_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint api_client_secrets_validity check (valid_to is null or valid_to > valid_from)
);

create table if not exists public."InCert-webhook_endpoints" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  url text not null,
  secret_hash text,
  subscribed_events jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  retry_policy jsonb not null default '{"max_attempts": 8, "base_delay_seconds": 30}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-webhook_delivery_events" (
  id uuid primary key default gen_random_uuid(),
  endpoint_id uuid not null references public."InCert-webhook_endpoints"(id) on delete cascade,
  event_type text not null,
  payload jsonb not null,
  status public.webhook_delivery_status not null default 'pending',
  attempt_count integer not null default 0,
  next_attempt_at timestamptz,
  delivered_at timestamptz,
  last_error text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-integration_sync_jobs" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  connector_name text not null,
  direction text not null check (direction in ('inbound', 'outbound', 'bidirectional')),
  status public.integration_sync_status not null default 'queued',
  trigger_source text not null default 'manual',
  started_at timestamptz,
  finished_at timestamptz,
  records_processed integer not null default 0,
  records_failed integer not null default 0,
  error_message text,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-mobile_devices" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  device_identifier text not null,
  platform text not null,
  app_version text,
  os_version text,
  attestation_status public.device_attestation_status not null default 'unknown',
  last_seen_at timestamptz,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, device_identifier)
);

create table if not exists public."InCert-mobile_audit_sessions" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  job_id uuid not null references public.inspection_jobs(id) on delete cascade,
  device_id uuid not null references public."InCert-mobile_devices"(id) on delete cascade,
  status public.mobile_session_status not null default 'active',
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  last_sync_at timestamptz,
  offline_queue_count integer not null default 0,
  conflict_count integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-mobile_sync_conflicts" (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public."InCert-mobile_audit_sessions"(id) on delete cascade,
  entity_type text not null,
  entity_id uuid,
  client_payload jsonb not null,
  server_payload jsonb not null,
  resolution_status text not null default 'open' check (resolution_status in ('open', 'resolved_client', 'resolved_server', 'resolved_merge')),
  resolved_by_user_id uuid references auth.users(id) on delete set null,
  resolved_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-enterprise_sso_providers" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  provider_kind public.sso_provider_kind not null,
  name text not null,
  issuer_url text,
  sso_url text,
  entity_id text,
  certificate_pem text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-enterprise_domain_claims" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  domain_name citext not null,
  verification_token text not null,
  verified_at timestamptz,
  is_verified boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (domain_name)
);

create table if not exists public."InCert-enterprise_access_policies" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  policy_name text not null,
  policy_type text not null,
  rules jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  effective_from timestamptz not null default now(),
  effective_to timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint enterprise_access_policies_window check (effective_to is null or effective_to > effective_from)
);

create table if not exists public."InCert-enterprise_security_events" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  event_type text not null,
  severity public.security_event_severity not null,
  source text,
  actor_user_id uuid references auth.users(id) on delete set null,
  description text,
  event_payload jsonb not null default '{}'::jsonb,
  event_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_api_clients_org_active on public."InCert-api_clients"(organization_id, is_active, created_at desc);
create index if not exists idx_webhook_endpoints_org_active on public."InCert-webhook_endpoints"(organization_id, is_active);
create index if not exists idx_webhook_delivery_events_endpoint_status on public."InCert-webhook_delivery_events"(endpoint_id, status, created_at desc);
create index if not exists idx_integration_sync_jobs_org_status on public."InCert-integration_sync_jobs"(organization_id, status, created_at desc);
create index if not exists idx_mobile_devices_org_user on public."InCert-mobile_devices"(organization_id, user_id, is_active);
create index if not exists idx_mobile_audit_sessions_job_status on public."InCert-mobile_audit_sessions"(job_id, status, started_at desc);
create index if not exists idx_mobile_sync_conflicts_session on public."InCert-mobile_sync_conflicts"(session_id, resolution_status, created_at desc);
create index if not exists idx_enterprise_security_events_org_time on public."InCert-enterprise_security_events"(organization_id, event_at desc);

create or replace function public.enqueue_webhook_delivery(
  p_endpoint_id uuid,
  p_event_type text,
  p_payload jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_endpoint public."InCert-webhook_endpoints"%rowtype;
  v_event_id uuid;
begin
  select * into v_endpoint from public."InCert-webhook_endpoints" where id = p_endpoint_id;
  if not found then
    raise exception 'Webhook endpoint % not found', p_endpoint_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(v_endpoint.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
  ) then
    raise exception 'Not permitted to enqueue webhook for endpoint %', p_endpoint_id;
  end if;

  insert into public."InCert-webhook_delivery_events" (
    endpoint_id,
    event_type,
    payload,
    status,
    next_attempt_at,
    metadata
  ) values (
    p_endpoint_id,
    p_event_type,
    coalesce(p_payload, '{}'::jsonb),
    'pending',
    now(),
    jsonb_build_object('source', 'enqueue_webhook_delivery_rpc')
  )
  returning id into v_event_id;

  return v_event_id;
end;
$$;

create or replace function public.rotate_api_client_secret(
  p_client_id uuid,
  p_secret_hash text,
  p_valid_to timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client public."InCert-api_clients"%rowtype;
  v_secret_id uuid;
begin
  select * into v_client from public."InCert-api_clients" where id = p_client_id;
  if not found then
    raise exception 'API client % not found', p_client_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(v_client.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
  ) then
    raise exception 'Not permitted to rotate secret for API client %', p_client_id;
  end if;

  update public."InCert-api_client_secrets"
  set revoked_at = now(), metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object('rotated_at', now())
  where client_id = p_client_id
    and revoked_at is null;

  insert into public."InCert-api_client_secrets" (
    client_id,
    secret_hash,
    valid_to,
    rotated_by,
    metadata
  ) values (
    p_client_id,
    p_secret_hash,
    p_valid_to,
    auth.uid(),
    jsonb_build_object('source', 'rotate_api_client_secret_rpc')
  )
  returning id into v_secret_id;

  return v_secret_id;
end;
$$;

create or replace function public.open_mobile_audit_session(
  p_job_id uuid,
  p_device_id uuid,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job public.inspection_jobs%rowtype;
  v_device public."InCert-mobile_devices"%rowtype;
  v_session_id uuid;
begin
  select * into v_job from public.inspection_jobs where id = p_job_id;
  if not found then
    raise exception 'Inspection job % not found', p_job_id;
  end if;

  select * into v_device from public."InCert-mobile_devices" where id = p_device_id;
  if not found then
    raise exception 'Mobile device % not found', p_device_id;
  end if;

  if v_device.organization_id <> v_job.provider_organization_id then
    raise exception 'Device organization does not match job provider organization';
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(v_device.organization_id, array['provider_admin', 'site_manager']::public.app_role[])
    or v_device.user_id = auth.uid()
  ) then
    raise exception 'Not permitted to open mobile session for job %', p_job_id;
  end if;

  insert into public."InCert-mobile_audit_sessions" (
    organization_id,
    job_id,
    device_id,
    status,
    started_at,
    metadata,
    created_by
  ) values (
    v_device.organization_id,
    p_job_id,
    p_device_id,
    'active',
    now(),
    coalesce(p_metadata, '{}'::jsonb),
    auth.uid()
  )
  returning id into v_session_id;

  return v_session_id;
end;
$$;

create or replace function public.log_enterprise_security_event(
  p_organization_id uuid,
  p_event_type text,
  p_severity public.security_event_severity,
  p_description text,
  p_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_id uuid;
begin
  if not (
    public.is_platform_admin()
    or public.has_role(p_organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
  ) then
    raise exception 'Not permitted to log enterprise security event for organization %', p_organization_id;
  end if;

  insert into public."InCert-enterprise_security_events" (
    organization_id,
    event_type,
    severity,
    source,
    actor_user_id,
    description,
    event_payload,
    event_at
  ) values (
    p_organization_id,
    p_event_type,
    p_severity,
    'app',
    auth.uid(),
    p_description,
    coalesce(p_payload, '{}'::jsonb),
    now()
  )
  returning id into v_event_id;

  return v_event_id;
end;
$$;

-- Updated-at triggers

drop trigger if exists trg_api_clients_updated_at on public."InCert-api_clients";
create trigger trg_api_clients_updated_at
before update on public."InCert-api_clients"
for each row execute function public.set_updated_at();

drop trigger if exists trg_webhook_endpoints_updated_at on public."InCert-webhook_endpoints";
create trigger trg_webhook_endpoints_updated_at
before update on public."InCert-webhook_endpoints"
for each row execute function public.set_updated_at();

drop trigger if exists trg_webhook_delivery_events_updated_at on public."InCert-webhook_delivery_events";
create trigger trg_webhook_delivery_events_updated_at
before update on public."InCert-webhook_delivery_events"
for each row execute function public.set_updated_at();

drop trigger if exists trg_integration_sync_jobs_updated_at on public."InCert-integration_sync_jobs";
create trigger trg_integration_sync_jobs_updated_at
before update on public."InCert-integration_sync_jobs"
for each row execute function public.set_updated_at();

drop trigger if exists trg_mobile_devices_updated_at on public."InCert-mobile_devices";
create trigger trg_mobile_devices_updated_at
before update on public."InCert-mobile_devices"
for each row execute function public.set_updated_at();

drop trigger if exists trg_mobile_audit_sessions_updated_at on public."InCert-mobile_audit_sessions";
create trigger trg_mobile_audit_sessions_updated_at
before update on public."InCert-mobile_audit_sessions"
for each row execute function public.set_updated_at();

drop trigger if exists trg_mobile_sync_conflicts_updated_at on public."InCert-mobile_sync_conflicts";
create trigger trg_mobile_sync_conflicts_updated_at
before update on public."InCert-mobile_sync_conflicts"
for each row execute function public.set_updated_at();

drop trigger if exists trg_enterprise_sso_providers_updated_at on public."InCert-enterprise_sso_providers";
create trigger trg_enterprise_sso_providers_updated_at
before update on public."InCert-enterprise_sso_providers"
for each row execute function public.set_updated_at();

drop trigger if exists trg_enterprise_domain_claims_updated_at on public."InCert-enterprise_domain_claims";
create trigger trg_enterprise_domain_claims_updated_at
before update on public."InCert-enterprise_domain_claims"
for each row execute function public.set_updated_at();

drop trigger if exists trg_enterprise_access_policies_updated_at on public."InCert-enterprise_access_policies";
create trigger trg_enterprise_access_policies_updated_at
before update on public."InCert-enterprise_access_policies"
for each row execute function public.set_updated_at();

-- RLS

alter table public."InCert-api_clients" enable row level security;
alter table public."InCert-api_client_secrets" enable row level security;
alter table public."InCert-webhook_endpoints" enable row level security;
alter table public."InCert-webhook_delivery_events" enable row level security;
alter table public."InCert-integration_sync_jobs" enable row level security;
alter table public."InCert-mobile_devices" enable row level security;
alter table public."InCert-mobile_audit_sessions" enable row level security;
alter table public."InCert-mobile_sync_conflicts" enable row level security;
alter table public."InCert-enterprise_sso_providers" enable row level security;
alter table public."InCert-enterprise_domain_claims" enable row level security;
alter table public."InCert-enterprise_access_policies" enable row level security;
alter table public."InCert-enterprise_security_events" enable row level security;

drop policy if exists api_clients_select_scoped on public."InCert-api_clients";
create policy api_clients_select_scoped on public."InCert-api_clients"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists api_clients_write_scoped on public."InCert-api_clients";
create policy api_clients_write_scoped on public."InCert-api_clients"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

drop policy if exists api_client_secrets_select_scoped on public."InCert-api_client_secrets";
create policy api_client_secrets_select_scoped on public."InCert-api_client_secrets"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (select 1 from public."InCert-api_clients" c where c.id = client_id and public.is_member(c.organization_id))
);

drop policy if exists api_client_secrets_write_scoped on public."InCert-api_client_secrets";
create policy api_client_secrets_write_scoped on public."InCert-api_client_secrets"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-api_clients" c
    where c.id = client_id
      and public.has_role(c.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-api_clients" c
    where c.id = client_id
      and public.has_role(c.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
  )
);

drop policy if exists webhook_endpoints_select_scoped on public."InCert-webhook_endpoints";
create policy webhook_endpoints_select_scoped on public."InCert-webhook_endpoints"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists webhook_endpoints_write_scoped on public."InCert-webhook_endpoints";
create policy webhook_endpoints_write_scoped on public."InCert-webhook_endpoints"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

drop policy if exists webhook_delivery_events_select_scoped on public."InCert-webhook_delivery_events";
create policy webhook_delivery_events_select_scoped on public."InCert-webhook_delivery_events"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (select 1 from public."InCert-webhook_endpoints" e where e.id = endpoint_id and public.is_member(e.organization_id))
);

drop policy if exists webhook_delivery_events_write_scoped on public."InCert-webhook_delivery_events";
create policy webhook_delivery_events_write_scoped on public."InCert-webhook_delivery_events"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-webhook_endpoints" e
    where e.id = endpoint_id
      and public.has_role(e.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-webhook_endpoints" e
    where e.id = endpoint_id
      and public.has_role(e.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
  )
);

drop policy if exists integration_sync_jobs_select_scoped on public."InCert-integration_sync_jobs";
create policy integration_sync_jobs_select_scoped on public."InCert-integration_sync_jobs"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists integration_sync_jobs_write_scoped on public."InCert-integration_sync_jobs";
create policy integration_sync_jobs_write_scoped on public."InCert-integration_sync_jobs"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

drop policy if exists mobile_devices_select_scoped on public."InCert-mobile_devices";
create policy mobile_devices_select_scoped on public."InCert-mobile_devices"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id) or user_id = auth.uid());

drop policy if exists mobile_devices_write_scoped on public."InCert-mobile_devices";
create policy mobile_devices_write_scoped on public."InCert-mobile_devices"
for all to authenticated
using (
  public.is_platform_admin()
  or user_id = auth.uid()
  or public.has_role(organization_id, array['provider_admin', 'site_manager']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or user_id = auth.uid()
  or public.has_role(organization_id, array['provider_admin', 'site_manager']::public.app_role[])
);

drop policy if exists mobile_audit_sessions_select_scoped on public."InCert-mobile_audit_sessions";
create policy mobile_audit_sessions_select_scoped on public."InCert-mobile_audit_sessions"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists mobile_audit_sessions_write_scoped on public."InCert-mobile_audit_sessions";
create policy mobile_audit_sessions_write_scoped on public."InCert-mobile_audit_sessions"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin', 'site_manager']::public.app_role[])
  or created_by = auth.uid()
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin', 'site_manager']::public.app_role[])
  or created_by = auth.uid()
);

drop policy if exists mobile_sync_conflicts_select_scoped on public."InCert-mobile_sync_conflicts";
create policy mobile_sync_conflicts_select_scoped on public."InCert-mobile_sync_conflicts"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-mobile_audit_sessions" s
    where s.id = session_id and public.is_member(s.organization_id)
  )
);

drop policy if exists mobile_sync_conflicts_write_scoped on public."InCert-mobile_sync_conflicts";
create policy mobile_sync_conflicts_write_scoped on public."InCert-mobile_sync_conflicts"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-mobile_audit_sessions" s
    where s.id = session_id
      and public.has_role(s.organization_id, array['provider_admin', 'site_manager']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-mobile_audit_sessions" s
    where s.id = session_id
      and public.has_role(s.organization_id, array['provider_admin', 'site_manager']::public.app_role[])
  )
);

drop policy if exists enterprise_sso_select_scoped on public."InCert-enterprise_sso_providers";
create policy enterprise_sso_select_scoped on public."InCert-enterprise_sso_providers"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists enterprise_sso_write_scoped on public."InCert-enterprise_sso_providers";
create policy enterprise_sso_write_scoped on public."InCert-enterprise_sso_providers"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

drop policy if exists enterprise_domains_select_scoped on public."InCert-enterprise_domain_claims";
create policy enterprise_domains_select_scoped on public."InCert-enterprise_domain_claims"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists enterprise_domains_write_scoped on public."InCert-enterprise_domain_claims";
create policy enterprise_domains_write_scoped on public."InCert-enterprise_domain_claims"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

drop policy if exists enterprise_policies_select_scoped on public."InCert-enterprise_access_policies";
create policy enterprise_policies_select_scoped on public."InCert-enterprise_access_policies"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists enterprise_policies_write_scoped on public."InCert-enterprise_access_policies";
create policy enterprise_policies_write_scoped on public."InCert-enterprise_access_policies"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

drop policy if exists enterprise_security_events_select_scoped on public."InCert-enterprise_security_events";
create policy enterprise_security_events_select_scoped on public."InCert-enterprise_security_events"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists enterprise_security_events_insert_scoped on public."InCert-enterprise_security_events";
create policy enterprise_security_events_insert_scoped on public."InCert-enterprise_security_events"
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

-- Realtime publication

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public."InCert-integration_sync_jobs";
    exception when duplicate_object then null; end;

    begin
      alter publication supabase_realtime add table public."InCert-mobile_audit_sessions";
    exception when duplicate_object then null; end;

    begin
      alter publication supabase_realtime add table public."InCert-webhook_delivery_events";
    exception when duplicate_object then null; end;
  end if;
end $$;

grant execute on function public.enqueue_webhook_delivery(uuid, text, jsonb) to authenticated;
grant execute on function public.rotate_api_client_secret(uuid, text, timestamptz) to authenticated;
grant execute on function public.open_mobile_audit_session(uuid, uuid, jsonb) to authenticated;
grant execute on function public.log_enterprise_security_event(uuid, text, public.security_event_severity, text, jsonb) to authenticated;
