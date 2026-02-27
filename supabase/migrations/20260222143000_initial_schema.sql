-- 2026-02-22: Core schema for Statutory Inspection Certificate Exchange
-- This migration creates the tenant model, core entities, and baseline triggers/indexes.

create extension if not exists pgcrypto;
create extension if not exists citext;

-- Enums are created in a guarded block so reruns are safe.
do $$
begin
  if not exists (select 1 from pg_type where typname = 'org_type') then
    create type public.org_type as enum (
      'operator',
      'provider',
      'fm',
      'auditor',
      'insurer',
      'landlord',
      'platform'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum (
      'platform_admin',
      'dutyholder_admin',
      'site_manager',
      'procurement',
      'provider_admin',
      'inspector',
      'auditor_viewer',
      'insurer_viewer',
      'landlord_viewer'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'asset_regime') then
    create type public.asset_regime as enum ('LOLER', 'PUWER', 'PSSR');
  end if;

  if not exists (select 1 from pg_type where typname = 'asset_status') then
    create type public.asset_status as enum ('compliant', 'warning', 'overdue', 'out_of_service');
  end if;

  if not exists (select 1 from pg_type where typname = 'request_status') then
    create type public.request_status as enum ('draft', 'open', 'offered', 'scheduled', 'completed', 'cancelled');
  end if;

  if not exists (select 1 from pg_type where typname = 'offer_status') then
    create type public.offer_status as enum ('pending', 'accepted', 'declined', 'expired');
  end if;

  if not exists (select 1 from pg_type where typname = 'job_status') then
    create type public.job_status as enum (
      'pending',
      'accepted',
      'in_progress',
      'submitted',
      'verified',
      'rejected',
      'cancelled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'severity_level') then
    create type public.severity_level as enum ('low', 'medium', 'high', 'critical');
  end if;

  if not exists (select 1 from pg_type where typname = 'certificate_status') then
    create type public.certificate_status as enum ('valid', 'expired', 'superseded', 'revoked');
  end if;

  if not exists (select 1 from pg_type where typname = 'signature_algorithm') then
    create type public.signature_algorithm as enum ('kms_sha256_rsa', 'provider_pgp', 'provider_x509');
  end if;

  if not exists (select 1 from pg_type where typname = 'evidence_file_type') then
    create type public.evidence_file_type as enum (
      'certificate_pdf',
      'photo',
      'supporting_doc',
      'wse',
      'other'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'provider_credential_status') then
    create type public.provider_credential_status as enum ('pending', 'verified', 'expired', 'rejected');
  end if;

  if not exists (select 1 from pg_type where typname = 'share_resource_type') then
    create type public.share_resource_type as enum ('certificate', 'audit_pack', 'vault_folder');
  end if;

  if not exists (select 1 from pg_type where typname = 'sync_status') then
    create type public.sync_status as enum ('received', 'processing', 'processed', 'failed');
  end if;
end $$;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug citext unique,
  org_type public.org_type not null,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  phone text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organization_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.app_role not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  unique (organization_id, user_id, role)
);

create table if not exists public.sites (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  code text,
  address_line_1 text,
  address_line_2 text,
  city text,
  county text,
  postcode text,
  country_code text default 'GB',
  latitude numeric(9, 6),
  longitude numeric(9, 6),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, code)
);

create table if not exists public.assets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  site_id uuid not null references public.sites(id) on delete restrict,
  external_asset_id text not null,
  name text not null,
  asset_class text not null,
  regime public.asset_regime not null,
  next_due_date date not null,
  last_inspected_at date,
  status public.asset_status not null default 'warning',
  provider_organization_id uuid references public.organizations(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, external_asset_id)
);

create table if not exists public.inspection_requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  site_id uuid references public.sites(id) on delete set null,
  requested_by uuid references auth.users(id) on delete set null,
  title text not null default 'Inspection request',
  regime public.asset_regime,
  preferred_start_date date,
  preferred_end_date date,
  access_notes text,
  status public.request_status not null default 'open',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint inspection_requests_date_window check (
    preferred_end_date is null
    or preferred_start_date is null
    or preferred_end_date >= preferred_start_date
  )
);

create table if not exists public.inspection_request_assets (
  request_id uuid not null references public.inspection_requests(id) on delete cascade,
  asset_id uuid not null references public.assets(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (request_id, asset_id)
);

create table if not exists public.job_offers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.inspection_requests(id) on delete cascade,
  provider_organization_id uuid not null references public.organizations(id) on delete restrict,
  offered_by uuid references auth.users(id) on delete set null,
  offered_rate numeric(12, 2),
  currency_code char(3) not null default 'GBP',
  proposed_start_at timestamptz,
  proposed_end_at timestamptz,
  response_status public.offer_status not null default 'pending',
  responded_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (request_id, provider_organization_id)
);

create table if not exists public.inspection_jobs (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.inspection_requests(id) on delete cascade,
  provider_organization_id uuid not null references public.organizations(id) on delete restrict,
  accepted_offer_id uuid references public.job_offers(id) on delete set null,
  inspector_user_id uuid references auth.users(id) on delete set null,
  status public.job_status not null default 'pending',
  scheduled_start_at timestamptz,
  scheduled_end_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  submitted_at timestamptz,
  verified_at timestamptz,
  site_access_notes text,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint inspection_jobs_schedule_window check (
    scheduled_end_at is null
    or scheduled_start_at is null
    or scheduled_end_at >= scheduled_start_at
  )
);

create table if not exists public.inspection_job_assets (
  job_id uuid not null references public.inspection_jobs(id) on delete cascade,
  asset_id uuid not null references public.assets(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (job_id, asset_id)
);

create table if not exists public.inspection_findings (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.inspection_jobs(id) on delete cascade,
  asset_id uuid not null references public.assets(id) on delete cascade,
  finding_code text,
  summary text not null,
  severity public.severity_level not null default 'medium',
  action_required text,
  due_by date,
  is_regulatory_breach boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.certificates (
  id uuid primary key default gen_random_uuid(),
  certificate_number text not null unique,
  job_id uuid not null references public.inspection_jobs(id) on delete restrict,
  asset_id uuid not null references public.assets(id) on delete restrict,
  operator_organization_id uuid not null references public.organizations(id) on delete restrict,
  provider_organization_id uuid not null references public.organizations(id) on delete restrict,
  regime public.asset_regime not null,
  issue_date date not null,
  expiry_date date not null,
  status public.certificate_status not null default 'valid',
  version_no integer not null default 1 check (version_no > 0),
  supersedes_certificate_id uuid references public.certificates(id) on delete set null,
  pdf_storage_path text not null,
  json_payload jsonb not null default '{}'::jsonb,
  sha256_hash text not null,
  signed_by_user_id uuid references auth.users(id) on delete set null,
  issued_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint certificates_dates check (expiry_date >= issue_date)
);

create table if not exists public.certificate_signatures (
  id uuid primary key default gen_random_uuid(),
  certificate_id uuid not null references public.certificates(id) on delete cascade,
  signer_type text not null check (signer_type in ('platform', 'provider')),
  signer_organization_id uuid references public.organizations(id) on delete set null,
  signer_user_id uuid references auth.users(id) on delete set null,
  algorithm public.signature_algorithm not null,
  key_reference text not null,
  signature text not null,
  signed_at timestamptz not null default now()
);

create table if not exists public.evidence_files (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  asset_id uuid references public.assets(id) on delete set null,
  job_id uuid references public.inspection_jobs(id) on delete set null,
  certificate_id uuid references public.certificates(id) on delete set null,
  uploaded_by uuid references auth.users(id) on delete set null,
  file_type public.evidence_file_type not null default 'other',
  storage_path text not null unique,
  original_filename text not null,
  mime_type text not null,
  byte_size bigint not null check (byte_size > 0),
  checksum_sha256 text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.provider_credentials (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  credential_type text not null,
  credential_reference text,
  issued_by text,
  valid_from date,
  valid_to date,
  status public.provider_credential_status not null default 'pending',
  evidence_file_id uuid references public.evidence_files(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint provider_credentials_dates check (
    valid_to is null or valid_from is null or valid_to >= valid_from
  )
);

create table if not exists public.share_links (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  resource_type public.share_resource_type not null,
  resource_id uuid not null,
  token_hash text not null unique,
  permissions jsonb not null default '{"read_only": true}'::jsonb,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  last_accessed_at timestamptz,
  access_count integer not null default 0,
  created_at timestamptz not null default now(),
  constraint share_links_expiry check (expires_at > created_at)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null,
  title text not null,
  message text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete set null,
  actor_user_id uuid references auth.users(id) on delete set null,
  actor_role public.app_role,
  action text not null,
  resource_type text not null,
  resource_id uuid,
  ip_address inet,
  user_agent text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.offline_sync_batches (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  inspector_user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  status public.sync_status not null default 'received',
  submitted_at timestamptz not null default now(),
  processed_at timestamptz,
  error_message text,
  created_at timestamptz not null default now()
);

create table if not exists public.offline_sync_items (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.offline_sync_batches(id) on delete cascade,
  entity_type text not null,
  entity_temp_id text,
  payload jsonb not null default '{}'::jsonb,
  status public.sync_status not null default 'received',
  processed_at timestamptz,
  error_message text,
  created_at timestamptz not null default now()
);

create table if not exists public.compliance_snapshots (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  snapshot_month date not null,
  regime public.asset_regime not null,
  compliant_count integer not null default 0,
  warning_count integer not null default 0,
  overdue_count integer not null default 0,
  created_at timestamptz not null default now(),
  unique (organization_id, snapshot_month, regime)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.apply_asset_status()
returns trigger
language plpgsql
as $$
begin
  if new.next_due_date < current_date then
    new.status = 'overdue';
  elsif new.next_due_date <= (current_date + 30) then
    new.status = 'warning';
  else
    new.status = 'compliant';
  end if;

  return new;
end;
$$;

create or replace function public.apply_certificate_status()
returns trigger
language plpgsql
as $$
begin
  if new.status in ('revoked', 'superseded') then
    return new;
  end if;

  if new.expiry_date < current_date then
    new.status = 'expired';
  else
    new.status = 'valid';
  end if;

  return new;
end;
$$;

drop trigger if exists tr_set_updated_at_organizations on public.organizations;
drop trigger if exists tr_set_updated_at_profiles on public.profiles;
drop trigger if exists tr_set_updated_at_sites on public.sites;
drop trigger if exists tr_set_updated_at_assets on public.assets;
do $$
begin
  execute 'create trigger tr_set_updated_at_organizations before update on public.organizations for each row execute function public.set_updated_at()';
exception when others then null;
end $$;
do $$
begin
  execute 'create trigger tr_set_updated_at_profiles before update on public.profiles for each row execute function public.set_updated_at()';
exception when others then null;
end $$;
do $$
begin
  execute 'create trigger tr_set_updated_at_sites before update on public.sites for each row execute function public.set_updated_at()';
exception when others then null;
end $$;
do $$
begin
  execute 'create trigger tr_set_updated_at_assets before update on public.assets for each row execute function public.set_updated_at()';
exception when others then null;
end $$;

drop trigger if exists tr_apply_asset_status on public.assets;
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'assets' and column_name = 'next_due_date'
  ) then
    execute 'create trigger tr_apply_asset_status before insert or update of next_due_date on public.assets for each row execute function public.apply_asset_status()';
  end if;
end $$;

drop trigger if exists tr_set_updated_at_inspection_requests on public.inspection_requests;
do $$ begin create trigger tr_set_updated_at_inspection_requests before update on public.inspection_requests for each row execute function public.set_updated_at(); exception when others then null; end $$;
drop trigger if exists tr_set_updated_at_job_offers on public.job_offers;
do $$ begin create trigger tr_set_updated_at_job_offers before update on public.job_offers for each row execute function public.set_updated_at(); exception when others then null; end $$;
drop trigger if exists tr_set_updated_at_inspection_jobs on public.inspection_jobs;
do $$ begin create trigger tr_set_updated_at_inspection_jobs before update on public.inspection_jobs for each row execute function public.set_updated_at(); exception when others then null; end $$;
drop trigger if exists tr_set_updated_at_inspection_findings on public.inspection_findings;
do $$ begin create trigger tr_set_updated_at_inspection_findings before update on public.inspection_findings for each row execute function public.set_updated_at(); exception when others then null; end $$;
drop trigger if exists tr_set_updated_at_certificates on public.certificates;
do $$ begin create trigger tr_set_updated_at_certificates before update on public.certificates for each row execute function public.set_updated_at(); exception when others then null; end $$;
drop trigger if exists tr_apply_certificate_status on public.certificates;
do $$ begin create trigger tr_apply_certificate_status before insert or update of expiry_date, status on public.certificates for each row execute function public.apply_certificate_status(); exception when others then null; end $$;
drop trigger if exists tr_set_updated_at_provider_credentials on public.provider_credentials;
do $$ begin create trigger tr_set_updated_at_provider_credentials before update on public.provider_credentials for each row execute function public.set_updated_at(); exception when others then null; end $$;

do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'organizations' and column_name = 'org_type') then
    create index if not exists idx_organizations_org_type on public.organizations(org_type);
  end if;
end $$;
do $$
declare
  statements text[] := array[
    'create index if not exists idx_memberships_user_id on public.organization_memberships(user_id)',
    'create index if not exists idx_memberships_org_role on public.organization_memberships(organization_id, role)',
    'create index if not exists idx_sites_organization_id on public.sites(organization_id)',
    'create index if not exists idx_assets_org_site on public.assets(organization_id, site_id)',
    'create index if not exists idx_assets_org_status_due on public.assets(organization_id, status, next_due_date)',
    'create index if not exists idx_assets_regime_due on public.assets(regime, next_due_date)',
    'create index if not exists idx_assets_search on public.assets using gin (to_tsvector(''simple'', coalesce(name, '''') || '' '' || coalesce(external_asset_id, '''')))',
    'create index if not exists idx_inspection_requests_org_status_created on public.inspection_requests(organization_id, status, created_at desc)',
    'create index if not exists idx_inspection_request_assets_asset_id on public.inspection_request_assets(asset_id)',
    'create index if not exists idx_job_offers_provider_status on public.job_offers(provider_organization_id, response_status, created_at desc)',
    'create index if not exists idx_inspection_jobs_provider_status_schedule on public.inspection_jobs(provider_organization_id, status, scheduled_start_at)',
    'create index if not exists idx_inspection_jobs_request on public.inspection_jobs(request_id)',
    'create index if not exists idx_inspection_job_assets_asset on public.inspection_job_assets(asset_id)',
    'create index if not exists idx_inspection_findings_job_severity on public.inspection_findings(job_id, severity)',
    'create index if not exists idx_certificates_operator_expiry on public.certificates(operator_organization_id, expiry_date desc)',
    'create index if not exists idx_certificates_provider_issue on public.certificates(provider_organization_id, issue_date desc)',
    'create index if not exists idx_certificates_asset on public.certificates(asset_id)',
    'create index if not exists idx_certificates_status on public.certificates(status)',
    'create index if not exists idx_certificate_signatures_certificate on public.certificate_signatures(certificate_id)',
    'create index if not exists idx_evidence_files_org_created on public.evidence_files(organization_id, created_at desc)',
    'create index if not exists idx_share_links_org_created on public.share_links(organization_id, created_at desc)',
    'create index if not exists idx_share_links_resource on public.share_links(resource_type, resource_id)',
    'create index if not exists idx_share_links_expires on public.share_links(expires_at)',
    'create index if not exists idx_notifications_user_read_created on public.notifications(user_id, read_at, created_at desc)',
    'create index if not exists idx_audit_logs_org_created on public.audit_logs(organization_id, created_at desc)',
    'create index if not exists idx_offline_sync_batches_org_submitted on public.offline_sync_batches(organization_id, submitted_at desc)',
    'create index if not exists idx_offline_sync_items_batch on public.offline_sync_items(batch_id, created_at)',
    'create index if not exists idx_compliance_snapshots_org_month on public.compliance_snapshots(organization_id, snapshot_month desc)'
  ];
  stmt text;
begin
  foreach stmt in array statements loop
    begin
      execute stmt;
    exception when others then
      null;
    end;
  end loop;
end $$;

do $$
begin
  execute 'create or replace view public.v_compliance_summary as select organization_id, regime, status, count(*)::bigint as asset_count from public.assets group by organization_id, regime, status';
exception when others then null;
end $$;
