-- 2026-02-26: Quality harness telemetry and release readiness gates

-- Enums

do $$
begin
  if not exists (select 1 from pg_type where typname = 'qa_run_status') then
    create type public.qa_run_status as enum (
      'queued',
      'running',
      'passed',
      'failed',
      'partial',
      'cancelled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'qa_case_status') then
    create type public.qa_case_status as enum (
      'passed',
      'failed',
      'skipped',
      'error'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'release_gate_status') then
    create type public.release_gate_status as enum (
      'pending',
      'passed',
      'failed',
      'waived'
    );
  end if;
end $$;

create table if not exists public."InCert-qa_test_suites" (
  id uuid primary key default gen_random_uuid(),
  suite_key text not null unique,
  name text not null,
  description text,
  owner_organization_id uuid references public.organizations(id) on delete set null,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-qa_test_cases" (
  id uuid primary key default gen_random_uuid(),
  suite_id uuid not null references public."InCert-qa_test_suites"(id) on delete cascade,
  case_key text not null,
  name text not null,
  severity public.severity_level not null default 'medium',
  automated boolean not null default true,
  sql_assertion text,
  expected_result jsonb,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (suite_id, case_key)
);

create table if not exists public."InCert-qa_test_runs" (
  id uuid primary key default gen_random_uuid(),
  suite_id uuid not null references public."InCert-qa_test_suites"(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete set null,
  status public.qa_run_status not null default 'queued',
  trigger_source text not null default 'manual',
  commit_sha text,
  branch_name text,
  started_at timestamptz,
  completed_at timestamptz,
  summary jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  triggered_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-qa_test_run_results" (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public."InCert-qa_test_runs"(id) on delete cascade,
  case_id uuid not null references public."InCert-qa_test_cases"(id) on delete cascade,
  status public.qa_case_status not null,
  duration_ms integer,
  actual_result jsonb,
  error_message text,
  executed_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  unique (run_id, case_id)
);

create table if not exists public."InCert-release_gates" (
  id uuid primary key default gen_random_uuid(),
  gate_key text not null unique,
  name text not null,
  description text,
  is_required boolean not null default true,
  weight numeric(6, 3) not null default 1 check (weight >= 0),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-release_gate_results" (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public."InCert-qa_test_runs"(id) on delete cascade,
  gate_id uuid not null references public."InCert-release_gates"(id) on delete cascade,
  status public.release_gate_status not null default 'pending',
  notes text,
  checked_by uuid references auth.users(id) on delete set null,
  checked_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (run_id, gate_id)
);

create index if not exists idx_qa_test_cases_suite_active on public."InCert-qa_test_cases"(suite_id, is_active);
create index if not exists idx_qa_test_runs_suite_status on public."InCert-qa_test_runs"(suite_id, status, created_at desc);
create index if not exists idx_qa_test_run_results_run_status on public."InCert-qa_test_run_results"(run_id, status);
create index if not exists idx_release_gate_results_run_status on public."InCert-release_gate_results"(run_id, status);

create or replace function public.start_qa_test_run(
  p_suite_id uuid,
  p_organization_id uuid default null,
  p_trigger_source text default 'manual',
  p_commit_sha text default null,
  p_branch_name text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_suite public."InCert-qa_test_suites"%rowtype;
  v_run_id uuid;
begin
  select * into v_suite from public."InCert-qa_test_suites" where id = p_suite_id and is_active = true;
  if not found then
    raise exception 'QA test suite % not found or inactive', p_suite_id;
  end if;

  if not (
    public.is_platform_admin()
    or (p_organization_id is not null and public.has_role(p_organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[]))
  ) then
    raise exception 'Not permitted to start QA run';
  end if;

  insert into public."InCert-qa_test_runs" (
    suite_id,
    organization_id,
    status,
    trigger_source,
    commit_sha,
    branch_name,
    started_at,
    triggered_by,
    metadata
  ) values (
    p_suite_id,
    p_organization_id,
    'running',
    coalesce(nullif(trim(p_trigger_source), ''), 'manual'),
    p_commit_sha,
    p_branch_name,
    now(),
    auth.uid(),
    jsonb_build_object('source', 'start_qa_test_run_rpc')
  )
  returning id into v_run_id;

  return v_run_id;
end;
$$;

create or replace function public.record_qa_test_case_result(
  p_run_id uuid,
  p_case_id uuid,
  p_status public.qa_case_status,
  p_duration_ms integer default null,
  p_actual_result jsonb default '{}'::jsonb,
  p_error_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_run public."InCert-qa_test_runs"%rowtype;
  v_result_id uuid;
begin
  select * into v_run from public."InCert-qa_test_runs" where id = p_run_id;
  if not found then
    raise exception 'QA run % not found', p_run_id;
  end if;

  if not (
    public.is_platform_admin()
    or (v_run.organization_id is not null and public.has_role(v_run.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[]))
  ) then
    raise exception 'Not permitted to record QA case result for run %', p_run_id;
  end if;

  insert into public."InCert-qa_test_run_results" (
    run_id,
    case_id,
    status,
    duration_ms,
    actual_result,
    error_message,
    metadata
  ) values (
    p_run_id,
    p_case_id,
    p_status,
    p_duration_ms,
    coalesce(p_actual_result, '{}'::jsonb),
    p_error_message,
    jsonb_build_object('source', 'record_qa_test_case_result_rpc')
  )
  on conflict (run_id, case_id)
  do update set
    status = excluded.status,
    duration_ms = excluded.duration_ms,
    actual_result = excluded.actual_result,
    error_message = excluded.error_message,
    executed_at = now(),
    metadata = excluded.metadata
  returning id into v_result_id;

  return v_result_id;
end;
$$;

create or replace function public.finalize_qa_test_run(
  p_run_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_run public."InCert-qa_test_runs"%rowtype;
  v_failed_count integer;
  v_passed_count integer;
  v_total_count integer;
  v_status public.qa_run_status;
begin
  select * into v_run from public."InCert-qa_test_runs" where id = p_run_id;
  if not found then
    raise exception 'QA run % not found', p_run_id;
  end if;

  if not (
    public.is_platform_admin()
    or (v_run.organization_id is not null and public.has_role(v_run.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[]))
  ) then
    raise exception 'Not permitted to finalize QA run %', p_run_id;
  end if;

  select
    count(*) filter (where status = 'failed' or status = 'error'),
    count(*) filter (where status = 'passed'),
    count(*)
  into v_failed_count, v_passed_count, v_total_count
  from public."InCert-qa_test_run_results"
  where run_id = p_run_id;

  v_status := case
    when coalesce(v_total_count, 0) = 0 then 'partial'
    when coalesce(v_failed_count, 0) = 0 and v_passed_count = v_total_count then 'passed'
    when coalesce(v_failed_count, 0) > 0 and coalesce(v_passed_count, 0) = 0 then 'failed'
    else 'partial'
  end;

  update public."InCert-qa_test_runs"
  set status = v_status,
      completed_at = now(),
      summary = jsonb_build_object(
        'total_cases', coalesce(v_total_count, 0),
        'passed_cases', coalesce(v_passed_count, 0),
        'failed_cases', coalesce(v_failed_count, 0)
      ),
      updated_at = now()
  where id = p_run_id;

  return p_run_id;
end;
$$;

-- Updated-at triggers

drop trigger if exists trg_qa_test_suites_updated_at on public."InCert-qa_test_suites";
create trigger trg_qa_test_suites_updated_at
before update on public."InCert-qa_test_suites"
for each row execute function public.set_updated_at();

drop trigger if exists trg_qa_test_cases_updated_at on public."InCert-qa_test_cases";
create trigger trg_qa_test_cases_updated_at
before update on public."InCert-qa_test_cases"
for each row execute function public.set_updated_at();

drop trigger if exists trg_qa_test_runs_updated_at on public."InCert-qa_test_runs";
create trigger trg_qa_test_runs_updated_at
before update on public."InCert-qa_test_runs"
for each row execute function public.set_updated_at();

drop trigger if exists trg_release_gates_updated_at on public."InCert-release_gates";
create trigger trg_release_gates_updated_at
before update on public."InCert-release_gates"
for each row execute function public.set_updated_at();

drop trigger if exists trg_release_gate_results_updated_at on public."InCert-release_gate_results";
create trigger trg_release_gate_results_updated_at
before update on public."InCert-release_gate_results"
for each row execute function public.set_updated_at();

-- RLS

alter table public."InCert-qa_test_suites" enable row level security;
alter table public."InCert-qa_test_cases" enable row level security;
alter table public."InCert-qa_test_runs" enable row level security;
alter table public."InCert-qa_test_run_results" enable row level security;
alter table public."InCert-release_gates" enable row level security;
alter table public."InCert-release_gate_results" enable row level security;

drop policy if exists qa_test_suites_select_scoped on public."InCert-qa_test_suites";
create policy qa_test_suites_select_scoped on public."InCert-qa_test_suites"
for select to authenticated
using (public.is_platform_admin() or owner_organization_id is null or public.is_member(owner_organization_id));

drop policy if exists qa_test_suites_write_scoped on public."InCert-qa_test_suites";
create policy qa_test_suites_write_scoped on public."InCert-qa_test_suites"
for all to authenticated
using (public.is_platform_admin())
with check (public.is_platform_admin());

drop policy if exists qa_test_cases_select_scoped on public."InCert-qa_test_cases";
create policy qa_test_cases_select_scoped on public."InCert-qa_test_cases"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-qa_test_suites" s
    where s.id = suite_id
      and (s.owner_organization_id is null or public.is_member(s.owner_organization_id))
  )
);

drop policy if exists qa_test_cases_write_scoped on public."InCert-qa_test_cases";
create policy qa_test_cases_write_scoped on public."InCert-qa_test_cases"
for all to authenticated
using (public.is_platform_admin())
with check (public.is_platform_admin());

drop policy if exists qa_test_runs_select_scoped on public."InCert-qa_test_runs";
create policy qa_test_runs_select_scoped on public."InCert-qa_test_runs"
for select to authenticated
using (public.is_platform_admin() or (organization_id is not null and public.is_member(organization_id)));

drop policy if exists qa_test_runs_write_scoped on public."InCert-qa_test_runs";
create policy qa_test_runs_write_scoped on public."InCert-qa_test_runs"
for all to authenticated
using (
  public.is_platform_admin()
  or (organization_id is not null and public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[]))
)
with check (
  public.is_platform_admin()
  or (organization_id is not null and public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[]))
);

drop policy if exists qa_test_run_results_select_scoped on public."InCert-qa_test_run_results";
create policy qa_test_run_results_select_scoped on public."InCert-qa_test_run_results"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-qa_test_runs" r
    where r.id = run_id
      and r.organization_id is not null
      and public.is_member(r.organization_id)
  )
);

drop policy if exists qa_test_run_results_write_scoped on public."InCert-qa_test_run_results";
create policy qa_test_run_results_write_scoped on public."InCert-qa_test_run_results"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-qa_test_runs" r
    where r.id = run_id
      and r.organization_id is not null
      and public.has_role(r.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-qa_test_runs" r
    where r.id = run_id
      and r.organization_id is not null
      and public.has_role(r.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
  )
);

drop policy if exists release_gates_select_scoped on public."InCert-release_gates";
create policy release_gates_select_scoped on public."InCert-release_gates"
for select to authenticated
using (public.is_platform_admin() or true);

drop policy if exists release_gates_write_scoped on public."InCert-release_gates";
create policy release_gates_write_scoped on public."InCert-release_gates"
for all to authenticated
using (public.is_platform_admin())
with check (public.is_platform_admin());

drop policy if exists release_gate_results_select_scoped on public."InCert-release_gate_results";
create policy release_gate_results_select_scoped on public."InCert-release_gate_results"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-qa_test_runs" r
    where r.id = run_id
      and r.organization_id is not null
      and public.is_member(r.organization_id)
  )
);

drop policy if exists release_gate_results_write_scoped on public."InCert-release_gate_results";
create policy release_gate_results_write_scoped on public."InCert-release_gate_results"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-qa_test_runs" r
    where r.id = run_id
      and r.organization_id is not null
      and public.has_role(r.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-qa_test_runs" r
    where r.id = run_id
      and r.organization_id is not null
      and public.has_role(r.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
  )
);

-- Realtime publication

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public."InCert-qa_test_runs";
    exception when duplicate_object then null; end;

    begin
      alter publication supabase_realtime add table public."InCert-release_gate_results";
    exception when duplicate_object then null; end;
  end if;
end $$;

grant execute on function public.start_qa_test_run(uuid, uuid, text, text, text) to authenticated;
grant execute on function public.record_qa_test_case_result(uuid, uuid, public.qa_case_status, integer, jsonb, text) to authenticated;
grant execute on function public.finalize_qa_test_run(uuid) to authenticated;
