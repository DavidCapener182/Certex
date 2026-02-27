-- 2026-02-26: Audit company operating model, competitive bidding, assignments, and dispatch intelligence

-- Enums (ensure asset_regime exists; it may be from initial_schema which might not be on remote)
do $$
begin
  if not exists (select 1 from pg_type where typname = 'asset_regime') then
    create type public.asset_regime as enum ('LOLER', 'PUWER', 'PSSR');
  end if;
end $$;

-- Enums

do $$
begin
  if not exists (select 1 from pg_type where typname = 'marketplace_bid_status') then
    create type public.marketplace_bid_status as enum (
      'draft',
      'submitted',
      'shortlisted',
      'awarded',
      'accepted',
      'rejected',
      'withdrawn',
      'expired'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'marketplace_award_strategy') then
    create type public.marketplace_award_strategy as enum (
      'manual',
      'best_value',
      'lowest_price',
      'highest_quality',
      'fastest_response'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'marketplace_assignment_status') then
    create type public.marketplace_assignment_status as enum (
      'assigned',
      'accepted',
      'declined',
      'reassigned',
      'released'
    );
  end if;
end $$;

create table if not exists public."InCert-audit_company_profiles" (
  organization_id uuid primary key references public.organizations(id) on delete cascade,
  legal_name text,
  trading_name text,
  margin_pct numeric(6, 4) not null default 0.03 check (margin_pct >= 0 and margin_pct <= 0.5),
  bidding_enabled boolean not null default true,
  assignment_mode text not null default 'manual',
  default_response_sla_minutes integer not null default 120 check (default_response_sla_minutes between 15 and 10080),
  quality_score numeric(6, 3),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-audit_company_auditors" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  auditor_user_id uuid not null references auth.users(id) on delete cascade,
  employment_model text not null default 'employee',
  competence_regimes public.asset_regime[] not null default '{}'::public.asset_regime[],
  home_region text,
  max_concurrent_jobs integer not null default 8 check (max_concurrent_jobs > 0),
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, auditor_user_id)
);

create table if not exists public."InCert-marketplace_bids" (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.inspection_requests(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  status public.marketplace_bid_status not null default 'draft',
  lead_time_hours numeric(8, 2) check (lead_time_hours is null or lead_time_hours >= 0),
  total_ex_vat numeric(12, 2) not null default 0 check (total_ex_vat >= 0),
  vat_amount numeric(12, 2) not null default 0 check (vat_amount >= 0),
  total_inc_vat numeric(12, 2) generated always as (round(total_ex_vat + vat_amount, 2)) stored,
  submitted_at timestamptz,
  expires_at timestamptz,
  quality_score numeric(6, 3),
  rank_score numeric(7, 3),
  notes text,
  scoring_breakdown jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint marketplace_bids_expiry_window check (expires_at is null or submitted_at is null or expires_at > submitted_at),
  unique (request_id, organization_id)
);

create table if not exists public."InCert-marketplace_bid_line_items" (
  id uuid primary key default gen_random_uuid(),
  bid_id uuid not null references public."InCert-marketplace_bids"(id) on delete cascade,
  line_code text not null,
  description text,
  amount_ex_vat numeric(12, 2) not null check (amount_ex_vat >= 0),
  quantity numeric(10, 2) not null default 1 check (quantity > 0),
  created_at timestamptz not null default now()
);

create table if not exists public."InCert-marketplace_award_rules" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  regime public.asset_regime,
  strategy public.marketplace_award_strategy not null default 'best_value',
  weight_price numeric(5, 4) not null default 0.40 check (weight_price between 0 and 1),
  weight_eta numeric(5, 4) not null default 0.20 check (weight_eta between 0 and 1),
  weight_quality numeric(5, 4) not null default 0.30 check (weight_quality between 0 and 1),
  weight_capacity numeric(5, 4) not null default 0.10 check (weight_capacity between 0 and 1),
  auto_award_enabled boolean not null default false,
  auto_award_threshold numeric(6, 3),
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint marketplace_award_rules_weight_sum check (
    abs((weight_price + weight_eta + weight_quality + weight_capacity) - 1) <= 0.001
  ),
  unique (organization_id, regime)
);

create table if not exists public."InCert-marketplace_job_assignments" (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.inspection_jobs(id) on delete cascade,
  provider_organization_id uuid not null references public.organizations(id) on delete cascade,
  assignee_user_id uuid not null references auth.users(id) on delete restrict,
  assigned_by_user_id uuid references auth.users(id) on delete set null,
  status public.marketplace_assignment_status not null default 'assigned',
  assigned_at timestamptz not null default now(),
  accepted_at timestamptz,
  released_at timestamptz,
  release_reason text,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (job_id, assignee_user_id, assigned_at)
);

create table if not exists public."InCert-dispatch_sla_events" (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.inspection_requests(id) on delete cascade,
  dispatch_attempt_id uuid references public.marketplace_dispatch_attempts(id) on delete set null,
  event_type text not null,
  event_at timestamptz not null default now(),
  minutes_from_open integer,
  is_breach boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public."InCert-dispatch_route_estimates" (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.inspection_requests(id) on delete cascade,
  provider_organization_id uuid not null references public.organizations(id) on delete cascade,
  route_km numeric(10, 2) not null check (route_km >= 0),
  route_minutes integer not null check (route_minutes >= 0),
  traffic_band text,
  source text not null default 'routing_engine_v1',
  computed_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  unique (request_id, provider_organization_id, computed_at)
);

create index if not exists idx_marketplace_bids_request_status on public."InCert-marketplace_bids"(request_id, status, submitted_at desc);
create index if not exists idx_marketplace_bids_org_status on public."InCert-marketplace_bids"(organization_id, status, submitted_at desc);
create index if not exists idx_marketplace_bid_line_items_bid on public."InCert-marketplace_bid_line_items"(bid_id);
create index if not exists idx_marketplace_assignments_job on public."InCert-marketplace_job_assignments"(job_id, assigned_at desc);
create index if not exists idx_marketplace_assignments_provider on public."InCert-marketplace_job_assignments"(provider_organization_id, status, assigned_at desc);
create index if not exists idx_dispatch_sla_events_request on public."InCert-dispatch_sla_events"(request_id, event_at desc);
create index if not exists idx_dispatch_route_estimates_request on public."InCert-dispatch_route_estimates"(request_id, computed_at desc);

create or replace function public.submit_marketplace_bid(
  p_request_id uuid,
  p_provider_organization_id uuid,
  p_total_ex_vat numeric,
  p_vat_amount numeric,
  p_lead_time_hours numeric default null,
  p_notes text default null,
  p_line_items jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.inspection_requests%rowtype;
  v_bid_id uuid;
  v_now timestamptz := now();
  v_item jsonb;
begin
  select * into v_request from public.inspection_requests where id = p_request_id;
  if not found then
    raise exception 'Inspection request % not found', p_request_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(p_provider_organization_id, array['provider_admin']::public.app_role[])
  ) then
    raise exception 'Not permitted to submit bid for provider organization %', p_provider_organization_id;
  end if;

  insert into public."InCert-marketplace_bids" (
    request_id,
    organization_id,
    status,
    lead_time_hours,
    total_ex_vat,
    vat_amount,
    submitted_at,
    expires_at,
    notes,
    created_by,
    metadata
  ) values (
    p_request_id,
    p_provider_organization_id,
    'submitted',
    p_lead_time_hours,
    greatest(0, coalesce(p_total_ex_vat, 0)),
    greatest(0, coalesce(p_vat_amount, 0)),
    v_now,
    v_now + interval '48 hours',
    p_notes,
    auth.uid(),
    jsonb_build_object('source', 'submit_marketplace_bid_rpc')
  )
  on conflict (request_id, organization_id)
  do update set
    status = 'submitted',
    lead_time_hours = excluded.lead_time_hours,
    total_ex_vat = excluded.total_ex_vat,
    vat_amount = excluded.vat_amount,
    submitted_at = excluded.submitted_at,
    expires_at = excluded.expires_at,
    notes = excluded.notes,
    updated_at = now(),
    metadata = coalesce(public."InCert-marketplace_bids".metadata, '{}'::jsonb) || jsonb_build_object('resubmitted_at', v_now)
  returning id into v_bid_id;

  delete from public."InCert-marketplace_bid_line_items" where bid_id = v_bid_id;

  if jsonb_typeof(p_line_items) = 'array' then
    for v_item in select value from jsonb_array_elements(p_line_items)
    loop
      insert into public."InCert-marketplace_bid_line_items" (bid_id, line_code, description, amount_ex_vat, quantity)
      values (
        v_bid_id,
        coalesce(nullif(trim(v_item->>'code'), ''), 'LINE_ITEM'),
        v_item->>'description',
        greatest(0, coalesce((v_item->>'amount_ex_vat')::numeric, 0)),
        greatest(0.01, coalesce((v_item->>'quantity')::numeric, 1))
      );
    end loop;
  end if;

  perform public.write_audit_log(
    v_request.organization_id,
    'marketplace.bid_submitted',
    'inspection_request',
    p_request_id,
    jsonb_build_object('bid_id', v_bid_id, 'provider_organization_id', p_provider_organization_id)
  );

  return v_bid_id;
end;
$$;

create or replace function public.award_marketplace_bid(
  p_bid_id uuid,
  p_award boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bid public."InCert-marketplace_bids"%rowtype;
  v_request public.inspection_requests%rowtype;
begin
  select * into v_bid from public."InCert-marketplace_bids" where id = p_bid_id;
  if not found then
    raise exception 'Bid % not found', p_bid_id;
  end if;

  select * into v_request from public.inspection_requests where id = v_bid.request_id;

  if not (
    public.is_platform_admin()
    or public.has_role(v_request.organization_id, array['dutyholder_admin', 'procurement', 'site_manager']::public.app_role[])
  ) then
    raise exception 'Not permitted to award bid for request %', v_bid.request_id;
  end if;

  if p_award then
    update public."InCert-marketplace_bids"
    set status = case when id = p_bid_id then 'awarded' else 'rejected' end,
        updated_at = now()
    where request_id = v_bid.request_id
      and status in ('submitted', 'shortlisted', 'awarded');

    update public.marketplace_requests
    set accepted_provider_organization_id = v_bid.organization_id,
        accepted_at = now(),
        updated_at = now()
    where request_id = v_bid.request_id;

    perform public.write_audit_log(
      v_request.organization_id,
      'marketplace.bid_awarded',
      'inspection_request',
      v_bid.request_id,
      jsonb_build_object('bid_id', p_bid_id, 'provider_organization_id', v_bid.organization_id)
    );
  else
    update public."InCert-marketplace_bids"
    set status = 'rejected', updated_at = now()
    where id = p_bid_id;

    perform public.write_audit_log(
      v_request.organization_id,
      'marketplace.bid_rejected',
      'inspection_request',
      v_bid.request_id,
      jsonb_build_object('bid_id', p_bid_id, 'provider_organization_id', v_bid.organization_id)
    );
  end if;

  return v_bid.request_id;
end;
$$;

create or replace function public.assign_marketplace_job_auditor(
  p_job_id uuid,
  p_provider_organization_id uuid,
  p_assignee_user_id uuid,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job public.inspection_jobs%rowtype;
  v_assignment_id uuid;
begin
  select * into v_job from public.inspection_jobs where id = p_job_id;
  if not found then
    raise exception 'Inspection job % not found', p_job_id;
  end if;

  if v_job.provider_organization_id <> p_provider_organization_id then
    raise exception 'Provider organization mismatch for job %', p_job_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(p_provider_organization_id, array['provider_admin']::public.app_role[])
  ) then
    raise exception 'Not permitted to assign auditors for provider organization %', p_provider_organization_id;
  end if;

  insert into public."InCert-marketplace_job_assignments" (
    job_id,
    provider_organization_id,
    assignee_user_id,
    assigned_by_user_id,
    status,
    notes,
    metadata
  ) values (
    p_job_id,
    p_provider_organization_id,
    p_assignee_user_id,
    auth.uid(),
    'assigned',
    p_notes,
    jsonb_build_object('source', 'assign_marketplace_job_auditor_rpc')
  )
  returning id into v_assignment_id;

  update public.inspection_jobs
  set inspector_user_id = p_assignee_user_id,
      updated_at = now()
  where id = p_job_id;

  perform public.write_audit_log(
    p_provider_organization_id,
    'marketplace.job_auditor_assigned',
    'inspection_job',
    p_job_id,
    jsonb_build_object('assignment_id', v_assignment_id, 'assignee_user_id', p_assignee_user_id)
  );

  return v_assignment_id;
end;
$$;

-- Updated-at triggers

drop trigger if exists trg_audit_company_profiles_updated_at on public."InCert-audit_company_profiles";
create trigger trg_audit_company_profiles_updated_at
before update on public."InCert-audit_company_profiles"
for each row execute function public.set_updated_at();

drop trigger if exists trg_audit_company_auditors_updated_at on public."InCert-audit_company_auditors";
create trigger trg_audit_company_auditors_updated_at
before update on public."InCert-audit_company_auditors"
for each row execute function public.set_updated_at();

drop trigger if exists trg_marketplace_bids_updated_at on public."InCert-marketplace_bids";
create trigger trg_marketplace_bids_updated_at
before update on public."InCert-marketplace_bids"
for each row execute function public.set_updated_at();

drop trigger if exists trg_marketplace_award_rules_updated_at on public."InCert-marketplace_award_rules";
create trigger trg_marketplace_award_rules_updated_at
before update on public."InCert-marketplace_award_rules"
for each row execute function public.set_updated_at();

drop trigger if exists trg_marketplace_job_assignments_updated_at on public."InCert-marketplace_job_assignments";
create trigger trg_marketplace_job_assignments_updated_at
before update on public."InCert-marketplace_job_assignments"
for each row execute function public.set_updated_at();

-- RLS

alter table public."InCert-audit_company_profiles" enable row level security;
alter table public."InCert-audit_company_auditors" enable row level security;
alter table public."InCert-marketplace_bids" enable row level security;
alter table public."InCert-marketplace_bid_line_items" enable row level security;
alter table public."InCert-marketplace_award_rules" enable row level security;
alter table public."InCert-marketplace_job_assignments" enable row level security;
alter table public."InCert-dispatch_sla_events" enable row level security;
alter table public."InCert-dispatch_route_estimates" enable row level security;

drop policy if exists audit_company_profiles_select_scoped on public."InCert-audit_company_profiles";
create policy audit_company_profiles_select_scoped on public."InCert-audit_company_profiles"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists audit_company_profiles_write_scoped on public."InCert-audit_company_profiles";
create policy audit_company_profiles_write_scoped on public."InCert-audit_company_profiles"
for all to authenticated
using (public.is_platform_admin() or public.has_role(organization_id, array['provider_admin']::public.app_role[]))
with check (public.is_platform_admin() or public.has_role(organization_id, array['provider_admin']::public.app_role[]));

drop policy if exists audit_company_auditors_select_scoped on public."InCert-audit_company_auditors";
create policy audit_company_auditors_select_scoped on public."InCert-audit_company_auditors"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists audit_company_auditors_write_scoped on public."InCert-audit_company_auditors";
create policy audit_company_auditors_write_scoped on public."InCert-audit_company_auditors"
for all to authenticated
using (public.is_platform_admin() or public.has_role(organization_id, array['provider_admin']::public.app_role[]))
with check (public.is_platform_admin() or public.has_role(organization_id, array['provider_admin']::public.app_role[]));

drop policy if exists marketplace_bids_select_scoped on public."InCert-marketplace_bids";
create policy marketplace_bids_select_scoped on public."InCert-marketplace_bids"
for select to authenticated
using (public.is_platform_admin() or public.can_access_request(request_id) or public.is_member(organization_id));

drop policy if exists marketplace_bids_write_scoped on public."InCert-marketplace_bids";
create policy marketplace_bids_write_scoped on public."InCert-marketplace_bids"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
  or public.has_role(
    (select r.organization_id from public.inspection_requests r where r.id = request_id),
    array['dutyholder_admin', 'procurement', 'site_manager']::public.app_role[]
  )
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
  or public.has_role(
    (select r.organization_id from public.inspection_requests r where r.id = request_id),
    array['dutyholder_admin', 'procurement', 'site_manager']::public.app_role[]
  )
);

drop policy if exists marketplace_bid_line_items_select_scoped on public."InCert-marketplace_bid_line_items";
create policy marketplace_bid_line_items_select_scoped on public."InCert-marketplace_bid_line_items"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-marketplace_bids" b
    where b.id = bid_id and (public.can_access_request(b.request_id) or public.is_member(b.organization_id))
  )
);

drop policy if exists marketplace_bid_line_items_write_scoped on public."InCert-marketplace_bid_line_items";
create policy marketplace_bid_line_items_write_scoped on public."InCert-marketplace_bid_line_items"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-marketplace_bids" b
    where b.id = bid_id and public.has_role(b.organization_id, array['provider_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-marketplace_bids" b
    where b.id = bid_id and public.has_role(b.organization_id, array['provider_admin']::public.app_role[])
  )
);

drop policy if exists marketplace_award_rules_select_scoped on public."InCert-marketplace_award_rules";
create policy marketplace_award_rules_select_scoped on public."InCert-marketplace_award_rules"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists marketplace_award_rules_write_scoped on public."InCert-marketplace_award_rules";
create policy marketplace_award_rules_write_scoped on public."InCert-marketplace_award_rules"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
);

drop policy if exists marketplace_job_assignments_select_scoped on public."InCert-marketplace_job_assignments";
create policy marketplace_job_assignments_select_scoped on public."InCert-marketplace_job_assignments"
for select to authenticated
using (public.is_platform_admin() or public.can_access_job(job_id));

drop policy if exists marketplace_job_assignments_write_scoped on public."InCert-marketplace_job_assignments";
create policy marketplace_job_assignments_write_scoped on public."InCert-marketplace_job_assignments"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
);

drop policy if exists dispatch_sla_events_select_scoped on public."InCert-dispatch_sla_events";
create policy dispatch_sla_events_select_scoped on public."InCert-dispatch_sla_events"
for select to authenticated
using (public.is_platform_admin() or public.can_access_request(request_id));

drop policy if exists dispatch_sla_events_write_scoped on public."InCert-dispatch_sla_events";
create policy dispatch_sla_events_write_scoped on public."InCert-dispatch_sla_events"
for all to authenticated
using (public.is_platform_admin() or public.can_access_request(request_id))
with check (public.is_platform_admin() or public.can_access_request(request_id));

drop policy if exists dispatch_route_estimates_select_scoped on public."InCert-dispatch_route_estimates";
create policy dispatch_route_estimates_select_scoped on public."InCert-dispatch_route_estimates"
for select to authenticated
using (public.is_platform_admin() or public.can_access_request(request_id));

drop policy if exists dispatch_route_estimates_write_scoped on public."InCert-dispatch_route_estimates";
create policy dispatch_route_estimates_write_scoped on public."InCert-dispatch_route_estimates"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
);

-- Realtime publication

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public."InCert-marketplace_bids";
    exception when duplicate_object then null; end;

    begin
      alter publication supabase_realtime add table public."InCert-marketplace_job_assignments";
    exception when duplicate_object then null; end;

    begin
      alter publication supabase_realtime add table public."InCert-dispatch_sla_events";
    exception when duplicate_object then null; end;
  end if;
end $$;

grant execute on function public.submit_marketplace_bid(uuid, uuid, numeric, numeric, numeric, text, jsonb) to authenticated;
grant execute on function public.award_marketplace_bid(uuid, boolean) to authenticated;
grant execute on function public.assign_marketplace_job_auditor(uuid, uuid, uuid, text) to authenticated;
