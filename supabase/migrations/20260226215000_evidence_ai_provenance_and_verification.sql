-- 2026-02-26: AI evidence QA, provenance chain, and regulator verification workflow

-- Enums

do $$
begin
  if not exists (select 1 from pg_type where typname = 'evidence_ai_job_status') then
    create type public.evidence_ai_job_status as enum (
      'queued',
      'processing',
      'completed',
      'failed',
      'needs_review'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'evidence_verification_decision') then
    create type public.evidence_verification_decision as enum (
      'pending',
      'approved',
      'rejected',
      'needs_more_evidence'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'provenance_event_type') then
    create type public.provenance_event_type as enum (
      'capture',
      'upload',
      'transform',
      'signature',
      'review',
      'export'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'verification_request_status') then
    create type public.verification_request_status as enum (
      'open',
      'in_review',
      'approved',
      'rejected',
      'expired'
    );
  end if;
end $$;

create table if not exists public."InCert-evidence_ai_jobs" (
  id uuid primary key default gen_random_uuid(),
  evidence_file_id uuid not null references public.evidence_files(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  status public.evidence_ai_job_status not null default 'queued',
  model_name text not null default 'gpt-5-mini',
  pipeline_version text,
  requested_by uuid references auth.users(id) on delete set null,
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-evidence_ai_extractions" (
  id uuid primary key default gen_random_uuid(),
  ai_job_id uuid not null references public."InCert-evidence_ai_jobs"(id) on delete cascade,
  field_key text not null,
  field_value_text text,
  field_value_json jsonb,
  confidence numeric(5, 4) check (confidence is null or (confidence >= 0 and confidence <= 1)),
  anomaly_flag boolean not null default false,
  anomaly_reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public."InCert-evidence_provenance_events" (
  id uuid primary key default gen_random_uuid(),
  evidence_file_id uuid not null references public.evidence_files(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  event_type public.provenance_event_type not null,
  chain_index integer not null check (chain_index >= 0),
  event_at timestamptz not null default now(),
  actor_user_id uuid references auth.users(id) on delete set null,
  device_identifier text,
  gps_latitude numeric(9, 6),
  gps_longitude numeric(9, 6),
  file_hash_sha256 text,
  previous_hash_sha256 text,
  signature text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (evidence_file_id, chain_index)
);

create table if not exists public."InCert-evidence_review_decisions" (
  id uuid primary key default gen_random_uuid(),
  evidence_file_id uuid not null references public.evidence_files(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  decision public.evidence_verification_decision not null default 'pending',
  reason text,
  reviewer_user_id uuid references auth.users(id) on delete set null,
  decided_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-regulator_verification_requests" (
  id uuid primary key default gen_random_uuid(),
  certificate_id uuid not null references public.certificates(id) on delete cascade,
  operator_organization_id uuid not null references public.organizations(id) on delete cascade,
  requester_organization_id uuid references public.organizations(id) on delete set null,
  requester_email text,
  status public.verification_request_status not null default 'open',
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  decision_notes text,
  reviewed_by_user_id uuid references auth.users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-regulator_verification_events" (
  id uuid primary key default gen_random_uuid(),
  verification_request_id uuid not null references public."InCert-regulator_verification_requests"(id) on delete cascade,
  event_type text not null,
  event_at timestamptz not null default now(),
  actor_user_id uuid references auth.users(id) on delete set null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_evidence_ai_jobs_org_status on public."InCert-evidence_ai_jobs"(organization_id, status, created_at desc);
create index if not exists idx_evidence_ai_jobs_file on public."InCert-evidence_ai_jobs"(evidence_file_id, created_at desc);
create index if not exists idx_evidence_ai_extractions_job on public."InCert-evidence_ai_extractions"(ai_job_id, created_at desc);
create index if not exists idx_evidence_provenance_file_chain on public."InCert-evidence_provenance_events"(evidence_file_id, chain_index desc);
create index if not exists idx_evidence_review_decisions_file on public."InCert-evidence_review_decisions"(evidence_file_id, created_at desc);
create index if not exists idx_reg_verification_cert_status on public."InCert-regulator_verification_requests"(certificate_id, status, created_at desc);

create or replace function public.enqueue_evidence_ai_job(
  p_evidence_file_id uuid,
  p_model_name text default 'gpt-5-mini'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_file public.evidence_files%rowtype;
  v_job_id uuid;
begin
  select * into v_file from public.evidence_files where id = p_evidence_file_id;
  if not found then
    raise exception 'Evidence file % not found', p_evidence_file_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.is_member(v_file.organization_id)
  ) then
    raise exception 'Not permitted to enqueue AI job for evidence file %', p_evidence_file_id;
  end if;

  insert into public."InCert-evidence_ai_jobs" (
    evidence_file_id,
    organization_id,
    status,
    model_name,
    requested_by,
    metadata
  ) values (
    p_evidence_file_id,
    v_file.organization_id,
    'queued',
    coalesce(nullif(trim(p_model_name), ''), 'gpt-5-mini'),
    auth.uid(),
    jsonb_build_object('source', 'enqueue_evidence_ai_job_rpc')
  )
  returning id into v_job_id;

  perform public.write_audit_log(
    v_file.organization_id,
    'evidence.ai_job_enqueued',
    'evidence_file',
    p_evidence_file_id,
    jsonb_build_object('ai_job_id', v_job_id)
  );

  return v_job_id;
end;
$$;

create or replace function public.append_evidence_provenance(
  p_evidence_file_id uuid,
  p_event_type public.provenance_event_type,
  p_hash_sha256 text default null,
  p_previous_hash_sha256 text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_file public.evidence_files%rowtype;
  v_next_index integer;
  v_event_id uuid;
begin
  select * into v_file from public.evidence_files where id = p_evidence_file_id;
  if not found then
    raise exception 'Evidence file % not found', p_evidence_file_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.is_member(v_file.organization_id)
  ) then
    raise exception 'Not permitted to append provenance for evidence file %', p_evidence_file_id;
  end if;

  select coalesce(max(chain_index), -1) + 1
  into v_next_index
  from public."InCert-evidence_provenance_events"
  where evidence_file_id = p_evidence_file_id;

  insert into public."InCert-evidence_provenance_events" (
    evidence_file_id,
    organization_id,
    event_type,
    chain_index,
    actor_user_id,
    file_hash_sha256,
    previous_hash_sha256,
    metadata
  ) values (
    p_evidence_file_id,
    v_file.organization_id,
    p_event_type,
    v_next_index,
    auth.uid(),
    p_hash_sha256,
    p_previous_hash_sha256,
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning id into v_event_id;

  return v_event_id;
end;
$$;

create or replace function public.record_evidence_review_decision(
  p_evidence_file_id uuid,
  p_decision public.evidence_verification_decision,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_file public.evidence_files%rowtype;
  v_decision_id uuid;
begin
  select * into v_file from public.evidence_files where id = p_evidence_file_id;
  if not found then
    raise exception 'Evidence file % not found', p_evidence_file_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(v_file.organization_id, array['dutyholder_admin', 'provider_admin', 'auditor_viewer']::public.app_role[])
  ) then
    raise exception 'Not permitted to review evidence file %', p_evidence_file_id;
  end if;

  insert into public."InCert-evidence_review_decisions" (
    evidence_file_id,
    organization_id,
    decision,
    reason,
    reviewer_user_id,
    decided_at,
    metadata
  ) values (
    p_evidence_file_id,
    v_file.organization_id,
    p_decision,
    p_reason,
    auth.uid(),
    now(),
    jsonb_build_object('source', 'record_evidence_review_decision_rpc')
  )
  returning id into v_decision_id;

  return v_decision_id;
end;
$$;

-- Updated-at triggers

drop trigger if exists trg_evidence_ai_jobs_updated_at on public."InCert-evidence_ai_jobs";
create trigger trg_evidence_ai_jobs_updated_at
before update on public."InCert-evidence_ai_jobs"
for each row execute function public.set_updated_at();

drop trigger if exists trg_evidence_review_decisions_updated_at on public."InCert-evidence_review_decisions";
create trigger trg_evidence_review_decisions_updated_at
before update on public."InCert-evidence_review_decisions"
for each row execute function public.set_updated_at();

drop trigger if exists trg_regulator_verification_requests_updated_at on public."InCert-regulator_verification_requests";
create trigger trg_regulator_verification_requests_updated_at
before update on public."InCert-regulator_verification_requests"
for each row execute function public.set_updated_at();

-- RLS

alter table public."InCert-evidence_ai_jobs" enable row level security;
alter table public."InCert-evidence_ai_extractions" enable row level security;
alter table public."InCert-evidence_provenance_events" enable row level security;
alter table public."InCert-evidence_review_decisions" enable row level security;
alter table public."InCert-regulator_verification_requests" enable row level security;
alter table public."InCert-regulator_verification_events" enable row level security;

drop policy if exists evidence_ai_jobs_select_scoped on public."InCert-evidence_ai_jobs";
create policy evidence_ai_jobs_select_scoped on public."InCert-evidence_ai_jobs"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists evidence_ai_jobs_write_scoped on public."InCert-evidence_ai_jobs";
create policy evidence_ai_jobs_write_scoped on public."InCert-evidence_ai_jobs"
for all to authenticated
using (public.is_platform_admin() or public.has_role(organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[]))
with check (public.is_platform_admin() or public.has_role(organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[]));

drop policy if exists evidence_ai_extractions_select_scoped on public."InCert-evidence_ai_extractions";
create policy evidence_ai_extractions_select_scoped on public."InCert-evidence_ai_extractions"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-evidence_ai_jobs" j
    where j.id = ai_job_id and public.is_member(j.organization_id)
  )
);

drop policy if exists evidence_ai_extractions_write_scoped on public."InCert-evidence_ai_extractions";
create policy evidence_ai_extractions_write_scoped on public."InCert-evidence_ai_extractions"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-evidence_ai_jobs" j
    where j.id = ai_job_id and public.has_role(j.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-evidence_ai_jobs" j
    where j.id = ai_job_id and public.has_role(j.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
);

drop policy if exists evidence_provenance_select_scoped on public."InCert-evidence_provenance_events";
create policy evidence_provenance_select_scoped on public."InCert-evidence_provenance_events"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists evidence_provenance_write_scoped on public."InCert-evidence_provenance_events";
create policy evidence_provenance_write_scoped on public."InCert-evidence_provenance_events"
for all to authenticated
using (public.is_platform_admin() or public.is_member(organization_id))
with check (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists evidence_review_decisions_select_scoped on public."InCert-evidence_review_decisions";
create policy evidence_review_decisions_select_scoped on public."InCert-evidence_review_decisions"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists evidence_review_decisions_write_scoped on public."InCert-evidence_review_decisions";
create policy evidence_review_decisions_write_scoped on public."InCert-evidence_review_decisions"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin', 'dutyholder_admin', 'auditor_viewer']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin', 'dutyholder_admin', 'auditor_viewer']::public.app_role[])
);

drop policy if exists regulator_verification_requests_select_scoped on public."InCert-regulator_verification_requests";
create policy regulator_verification_requests_select_scoped on public."InCert-regulator_verification_requests"
for select to authenticated
using (
  public.is_platform_admin()
  or public.is_member(operator_organization_id)
  or (requester_organization_id is not null and public.is_member(requester_organization_id))
);

drop policy if exists regulator_verification_requests_write_scoped on public."InCert-regulator_verification_requests";
create policy regulator_verification_requests_write_scoped on public."InCert-regulator_verification_requests"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(operator_organization_id, array['dutyholder_admin', 'auditor_viewer', 'insurer_viewer']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(operator_organization_id, array['dutyholder_admin', 'auditor_viewer', 'insurer_viewer']::public.app_role[])
);

drop policy if exists regulator_verification_events_select_scoped on public."InCert-regulator_verification_events";
create policy regulator_verification_events_select_scoped on public."InCert-regulator_verification_events"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-regulator_verification_requests" r
    where r.id = verification_request_id
      and (
        public.is_member(r.operator_organization_id)
        or (r.requester_organization_id is not null and public.is_member(r.requester_organization_id))
      )
  )
);

drop policy if exists regulator_verification_events_insert_scoped on public."InCert-regulator_verification_events";
create policy regulator_verification_events_insert_scoped on public."InCert-regulator_verification_events"
for insert to authenticated
with check (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-regulator_verification_requests" r
    where r.id = verification_request_id
      and public.has_role(r.operator_organization_id, array['dutyholder_admin', 'auditor_viewer', 'insurer_viewer']::public.app_role[])
  )
);

-- Realtime publication

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public."InCert-evidence_ai_jobs";
    exception when duplicate_object then null; end;

    begin
      alter publication supabase_realtime add table public."InCert-evidence_review_decisions";
    exception when duplicate_object then null; end;

    begin
      alter publication supabase_realtime add table public."InCert-regulator_verification_requests";
    exception when duplicate_object then null; end;
  end if;
end $$;

grant execute on function public.enqueue_evidence_ai_job(uuid, text) to authenticated;
grant execute on function public.append_evidence_provenance(uuid, public.provenance_event_type, text, text, jsonb) to authenticated;
grant execute on function public.record_evidence_review_decision(uuid, public.evidence_verification_decision, text) to authenticated;
