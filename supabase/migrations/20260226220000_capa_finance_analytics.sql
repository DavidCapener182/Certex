-- 2026-02-26: CAPA workflow, finance automation, and analytics snapshots

-- Enums

do $$
begin
  if not exists (select 1 from pg_type where typname = 'capa_status') then
    create type public.capa_status as enum (
      'open',
      'in_progress',
      'blocked',
      'awaiting_verification',
      'closed',
      'cancelled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'capa_priority') then
    create type public.capa_priority as enum (
      'low',
      'medium',
      'high',
      'critical'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'finance_invoice_status') then
    create type public.finance_invoice_status as enum (
      'draft',
      'issued',
      'partially_paid',
      'paid',
      'void',
      'overdue'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'finance_payout_batch_status') then
    create type public.finance_payout_batch_status as enum (
      'draft',
      'scheduled',
      'processing',
      'paid',
      'failed',
      'cancelled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'finance_payment_event_type') then
    create type public.finance_payment_event_type as enum (
      'invoice_payment',
      'refund',
      'chargeback',
      'payout',
      'adjustment'
    );
  end if;
end $$;

create table if not exists public."InCert-capa_actions" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  finding_id uuid references public.inspection_findings(id) on delete set null,
  job_id uuid references public.inspection_jobs(id) on delete set null,
  title text not null,
  description text,
  status public.capa_status not null default 'open',
  priority public.capa_priority not null default 'medium',
  owner_user_id uuid references auth.users(id) on delete set null,
  due_date date,
  verification_due_date date,
  closed_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-capa_action_updates" (
  id uuid primary key default gen_random_uuid(),
  action_id uuid not null references public."InCert-capa_actions"(id) on delete cascade,
  status_from public.capa_status,
  status_to public.capa_status,
  comment text,
  updated_by_user_id uuid references auth.users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public."InCert-capa_action_evidence" (
  id uuid primary key default gen_random_uuid(),
  action_id uuid not null references public."InCert-capa_actions"(id) on delete cascade,
  evidence_file_id uuid not null references public.evidence_files(id) on delete cascade,
  linked_by_user_id uuid references auth.users(id) on delete set null,
  linked_at timestamptz not null default now(),
  unique (action_id, evidence_file_id)
);

create table if not exists public."InCert-finance_invoices" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  request_id uuid references public.inspection_requests(id) on delete set null,
  job_id uuid references public.inspection_jobs(id) on delete set null,
  invoice_number text not null unique,
  status public.finance_invoice_status not null default 'draft',
  currency_code char(3) not null default 'GBP',
  subtotal_ex_vat numeric(12, 2) not null default 0 check (subtotal_ex_vat >= 0),
  vat_amount numeric(12, 2) not null default 0 check (vat_amount >= 0),
  total_inc_vat numeric(12, 2) generated always as (round(subtotal_ex_vat + vat_amount, 2)) stored,
  outstanding_amount numeric(12, 2) not null default 0 check (outstanding_amount >= 0),
  issued_at timestamptz,
  due_at timestamptz,
  paid_at timestamptz,
  terms_days integer not null default 30 check (terms_days between 1 and 180),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-finance_invoice_line_items" (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public."InCert-finance_invoices"(id) on delete cascade,
  line_code text not null,
  description text not null,
  quantity numeric(10, 2) not null default 1 check (quantity > 0),
  unit_amount_ex_vat numeric(12, 2) not null check (unit_amount_ex_vat >= 0),
  line_amount_ex_vat numeric(12, 2) generated always as (round(quantity * unit_amount_ex_vat, 2)) stored,
  tax_rate numeric(6, 4) not null default 0.20 check (tax_rate >= 0 and tax_rate <= 1),
  created_at timestamptz not null default now()
);

create table if not exists public."InCert-finance_payout_batches" (
  id uuid primary key default gen_random_uuid(),
  provider_organization_id uuid not null references public.organizations(id) on delete cascade,
  status public.finance_payout_batch_status not null default 'draft',
  reference text,
  scheduled_for timestamptz,
  paid_at timestamptz,
  total_ex_vat numeric(12, 2) not null default 0 check (total_ex_vat >= 0),
  total_vat_amount numeric(12, 2) not null default 0 check (total_vat_amount >= 0),
  total_inc_vat numeric(12, 2) generated always as (round(total_ex_vat + total_vat_amount, 2)) stored,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."InCert-finance_payout_batch_items" (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public."InCert-finance_payout_batches"(id) on delete cascade,
  settlement_ledger_id uuid references public.settlement_ledgers(id) on delete set null,
  request_id uuid references public.inspection_requests(id) on delete set null,
  net_provider_amount numeric(12, 2) not null default 0 check (net_provider_amount >= 0),
  holdback_amount numeric(12, 2) not null default 0 check (holdback_amount >= 0),
  dispute_reserve_amount numeric(12, 2) not null default 0 check (dispute_reserve_amount >= 0),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public."InCert-finance_payment_events" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  invoice_id uuid references public."InCert-finance_invoices"(id) on delete set null,
  payout_batch_id uuid references public."InCert-finance_payout_batches"(id) on delete set null,
  event_type public.finance_payment_event_type not null,
  amount numeric(12, 2) not null check (amount >= 0),
  currency_code char(3) not null default 'GBP',
  event_at timestamptz not null default now(),
  external_reference text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public."InCert-analytics_kpi_snapshots" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  snapshot_date date not null,
  open_requests integer not null default 0,
  overdue_assets integer not null default 0,
  compliance_rate numeric(6, 3),
  avg_dispatch_minutes numeric(10, 2),
  avg_completion_hours numeric(10, 2),
  fail_rate numeric(6, 3),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (organization_id, snapshot_date)
);

create table if not exists public."InCert-analytics_provider_scorecards" (
  id uuid primary key default gen_random_uuid(),
  provider_organization_id uuid not null references public.organizations(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  jobs_completed integer not null default 0,
  on_time_pct numeric(6, 3),
  evidence_rejection_pct numeric(6, 3),
  avg_quality_score numeric(6, 3),
  avg_response_minutes numeric(10, 2),
  composite_score numeric(8, 3),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint analytics_provider_scorecards_window check (period_end >= period_start),
  unique (provider_organization_id, period_start, period_end)
);

create table if not exists public."InCert-analytics_risk_signals" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  asset_id uuid references public.assets(id) on delete set null,
  signal_type text not null,
  severity public.severity_level not null,
  score numeric(8, 3) not null check (score >= 0),
  description text,
  detected_at timestamptz not null default now(),
  resolved_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_capa_actions_org_status on public."InCert-capa_actions"(organization_id, status, due_date);
create index if not exists idx_capa_actions_finding on public."InCert-capa_actions"(finding_id);
create index if not exists idx_finance_invoices_org_status on public."InCert-finance_invoices"(organization_id, status, due_at);
create index if not exists idx_finance_payout_batches_provider_status on public."InCert-finance_payout_batches"(provider_organization_id, status, scheduled_for);
create index if not exists idx_finance_payment_events_org_event on public."InCert-finance_payment_events"(organization_id, event_at desc);
create index if not exists idx_analytics_kpi_snapshots_org_date on public."InCert-analytics_kpi_snapshots"(organization_id, snapshot_date desc);
create index if not exists idx_analytics_provider_scorecards_provider_period on public."InCert-analytics_provider_scorecards"(provider_organization_id, period_end desc);
create index if not exists idx_analytics_risk_signals_org_detected on public."InCert-analytics_risk_signals"(organization_id, detected_at desc);

create or replace function public.create_capa_action(
  p_finding_id uuid,
  p_title text,
  p_priority public.capa_priority default 'medium',
  p_due_date date default null,
  p_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_finding public.inspection_findings%rowtype;
  v_asset public.assets%rowtype;
  v_action_id uuid;
begin
  select * into v_finding from public.inspection_findings where id = p_finding_id;
  if not found then
    raise exception 'Inspection finding % not found', p_finding_id;
  end if;

  select * into v_asset from public.assets where id = v_finding.asset_id;

  if not (
    public.is_platform_admin()
    or public.has_role(v_asset.organization_id, array['dutyholder_admin', 'site_manager', 'auditor_viewer']::public.app_role[])
  ) then
    raise exception 'Not permitted to create CAPA action for finding %', p_finding_id;
  end if;

  insert into public."InCert-capa_actions" (
    organization_id,
    finding_id,
    job_id,
    title,
    description,
    status,
    priority,
    due_date,
    created_by,
    metadata
  ) values (
    v_asset.organization_id,
    p_finding_id,
    v_finding.job_id,
    p_title,
    p_description,
    'open',
    p_priority,
    p_due_date,
    auth.uid(),
    jsonb_build_object('source', 'create_capa_action_rpc')
  )
  returning id into v_action_id;

  insert into public."InCert-capa_action_updates" (
    action_id,
    status_from,
    status_to,
    comment,
    updated_by_user_id,
    metadata
  ) values (
    v_action_id,
    null,
    'open',
    'CAPA action created',
    auth.uid(),
    '{}'::jsonb
  );

  perform public.write_audit_log(
    v_asset.organization_id,
    'capa.action_created',
    'inspection_finding',
    p_finding_id,
    jsonb_build_object('capa_action_id', v_action_id)
  );

  return v_action_id;
end;
$$;

create or replace function public.generate_invoice_for_request(
  p_request_id uuid,
  p_issue_now boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.inspection_requests%rowtype;
  v_quote public.price_quotes%rowtype;
  v_invoice_id uuid;
  v_invoice_number text;
  v_count integer;
  v_due_at timestamptz;
begin
  select * into v_request from public.inspection_requests where id = p_request_id;
  if not found then
    raise exception 'Inspection request % not found', p_request_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(v_request.organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
  ) then
    raise exception 'Not permitted to generate invoice for request %', p_request_id;
  end if;

  select * into v_quote
  from public.price_quotes q
  where q.request_id = p_request_id
    and q.status in ('quoted', 'locked', 'accepted')
  order by q.created_at desc
  limit 1;

  if not found then
    raise exception 'No quote available for request %', p_request_id;
  end if;

  select count(*) + 1
  into v_count
  from public."InCert-finance_invoices" i
  where i.organization_id = v_request.organization_id
    and date_trunc('year', i.created_at) = date_trunc('year', now());

  v_invoice_number := format('INV-%s-%s', to_char(now(), 'YYYY'), lpad(v_count::text, 5, '0'));
  v_due_at := now() + interval '30 days';

  insert into public."InCert-finance_invoices" (
    organization_id,
    request_id,
    invoice_number,
    status,
    currency_code,
    subtotal_ex_vat,
    vat_amount,
    outstanding_amount,
    issued_at,
    due_at,
    created_by,
    metadata
  ) values (
    v_request.organization_id,
    p_request_id,
    v_invoice_number,
    case when p_issue_now then 'issued' else 'draft' end,
    v_quote.currency_code,
    v_quote.subtotal_ex_vat,
    v_quote.vat_amount,
    v_quote.total_inc_vat,
    case when p_issue_now then now() else null end,
    v_due_at,
    auth.uid(),
    jsonb_build_object('source', 'generate_invoice_for_request_rpc', 'quote_id', v_quote.id)
  )
  returning id into v_invoice_id;

  insert into public."InCert-finance_invoice_line_items" (
    invoice_id,
    line_code,
    description,
    quantity,
    unit_amount_ex_vat,
    tax_rate
  ) values (
    v_invoice_id,
    'AUDIT_REQUEST',
    coalesce(v_request.title, 'Statutory inspection request'),
    1,
    v_quote.subtotal_ex_vat,
    case when v_quote.subtotal_ex_vat = 0 then 0 else (v_quote.vat_amount / v_quote.subtotal_ex_vat) end
  );

  perform public.write_audit_log(
    v_request.organization_id,
    'finance.invoice_generated',
    'inspection_request',
    p_request_id,
    jsonb_build_object('invoice_id', v_invoice_id, 'invoice_number', v_invoice_number)
  );

  return v_invoice_id;
end;
$$;

create or replace function public.refresh_org_kpi_snapshot(
  p_organization_id uuid,
  p_snapshot_date date default current_date
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_open_requests integer;
  v_overdue_assets integer;
  v_total_assets integer;
  v_compliant_assets integer;
  v_snapshot_id uuid;
begin
  if not (
    public.is_platform_admin()
    or public.has_role(p_organization_id, array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[])
  ) then
    raise exception 'Not permitted to refresh KPI snapshot for organization %', p_organization_id;
  end if;

  select count(*) into v_open_requests
  from public.inspection_requests r
  where r.organization_id = p_organization_id
    and r.status in ('open', 'offered', 'scheduled');

  select count(*) into v_overdue_assets
  from public.assets a
  where a.organization_id = p_organization_id
    and a.next_due_date < p_snapshot_date;

  select count(*) into v_total_assets
  from public.assets a
  where a.organization_id = p_organization_id;

  select count(*) into v_compliant_assets
  from public.assets a
  where a.organization_id = p_organization_id
    and a.status = 'compliant';

  insert into public."InCert-analytics_kpi_snapshots" (
    organization_id,
    snapshot_date,
    open_requests,
    overdue_assets,
    compliance_rate,
    metadata
  ) values (
    p_organization_id,
    p_snapshot_date,
    v_open_requests,
    v_overdue_assets,
    case when v_total_assets = 0 then null else round((v_compliant_assets::numeric / v_total_assets::numeric), 4) end,
    jsonb_build_object('source', 'refresh_org_kpi_snapshot_rpc')
  )
  on conflict (organization_id, snapshot_date)
  do update set
    open_requests = excluded.open_requests,
    overdue_assets = excluded.overdue_assets,
    compliance_rate = excluded.compliance_rate,
    metadata = excluded.metadata,
    created_at = now()
  returning id into v_snapshot_id;

  return v_snapshot_id;
end;
$$;

-- Updated-at triggers

drop trigger if exists trg_capa_actions_updated_at on public."InCert-capa_actions";
create trigger trg_capa_actions_updated_at
before update on public."InCert-capa_actions"
for each row execute function public.set_updated_at();

drop trigger if exists trg_finance_invoices_updated_at on public."InCert-finance_invoices";
create trigger trg_finance_invoices_updated_at
before update on public."InCert-finance_invoices"
for each row execute function public.set_updated_at();

drop trigger if exists trg_finance_payout_batches_updated_at on public."InCert-finance_payout_batches";
create trigger trg_finance_payout_batches_updated_at
before update on public."InCert-finance_payout_batches"
for each row execute function public.set_updated_at();

-- RLS

alter table public."InCert-capa_actions" enable row level security;
alter table public."InCert-capa_action_updates" enable row level security;
alter table public."InCert-capa_action_evidence" enable row level security;
alter table public."InCert-finance_invoices" enable row level security;
alter table public."InCert-finance_invoice_line_items" enable row level security;
alter table public."InCert-finance_payout_batches" enable row level security;
alter table public."InCert-finance_payout_batch_items" enable row level security;
alter table public."InCert-finance_payment_events" enable row level security;
alter table public."InCert-analytics_kpi_snapshots" enable row level security;
alter table public."InCert-analytics_provider_scorecards" enable row level security;
alter table public."InCert-analytics_risk_signals" enable row level security;

drop policy if exists capa_actions_select_scoped on public."InCert-capa_actions";
create policy capa_actions_select_scoped on public."InCert-capa_actions"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists capa_actions_write_scoped on public."InCert-capa_actions";
create policy capa_actions_write_scoped on public."InCert-capa_actions"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'auditor_viewer']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'auditor_viewer']::public.app_role[])
);

drop policy if exists capa_action_updates_select_scoped on public."InCert-capa_action_updates";
create policy capa_action_updates_select_scoped on public."InCert-capa_action_updates"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (select 1 from public."InCert-capa_actions" a where a.id = action_id and public.is_member(a.organization_id))
);

drop policy if exists capa_action_updates_insert_scoped on public."InCert-capa_action_updates";
create policy capa_action_updates_insert_scoped on public."InCert-capa_action_updates"
for insert to authenticated
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-capa_actions" a
    where a.id = action_id
      and public.has_role(a.organization_id, array['dutyholder_admin', 'site_manager', 'auditor_viewer']::public.app_role[])
  )
);

drop policy if exists capa_action_evidence_select_scoped on public."InCert-capa_action_evidence";
create policy capa_action_evidence_select_scoped on public."InCert-capa_action_evidence"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (select 1 from public."InCert-capa_actions" a where a.id = action_id and public.is_member(a.organization_id))
);

drop policy if exists capa_action_evidence_write_scoped on public."InCert-capa_action_evidence";
create policy capa_action_evidence_write_scoped on public."InCert-capa_action_evidence"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-capa_actions" a
    where a.id = action_id
      and public.has_role(a.organization_id, array['dutyholder_admin', 'site_manager', 'auditor_viewer']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-capa_actions" a
    where a.id = action_id
      and public.has_role(a.organization_id, array['dutyholder_admin', 'site_manager', 'auditor_viewer']::public.app_role[])
  )
);

drop policy if exists finance_invoices_select_scoped on public."InCert-finance_invoices";
create policy finance_invoices_select_scoped on public."InCert-finance_invoices"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists finance_invoices_write_scoped on public."InCert-finance_invoices";
create policy finance_invoices_write_scoped on public."InCert-finance_invoices"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
);

drop policy if exists finance_invoice_line_items_select_scoped on public."InCert-finance_invoice_line_items";
create policy finance_invoice_line_items_select_scoped on public."InCert-finance_invoice_line_items"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (select 1 from public."InCert-finance_invoices" i where i.id = invoice_id and public.is_member(i.organization_id))
);

drop policy if exists finance_invoice_line_items_write_scoped on public."InCert-finance_invoice_line_items";
create policy finance_invoice_line_items_write_scoped on public."InCert-finance_invoice_line_items"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-finance_invoices" i
    where i.id = invoice_id
      and public.has_role(i.organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-finance_invoices" i
    where i.id = invoice_id
      and public.has_role(i.organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
  )
);

drop policy if exists finance_payout_batches_select_scoped on public."InCert-finance_payout_batches";
create policy finance_payout_batches_select_scoped on public."InCert-finance_payout_batches"
for select to authenticated
using (public.is_platform_admin() or public.is_member(provider_organization_id));

drop policy if exists finance_payout_batches_write_scoped on public."InCert-finance_payout_batches";
create policy finance_payout_batches_write_scoped on public."InCert-finance_payout_batches"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
);

drop policy if exists finance_payout_batch_items_select_scoped on public."InCert-finance_payout_batch_items";
create policy finance_payout_batch_items_select_scoped on public."InCert-finance_payout_batch_items"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (select 1 from public."InCert-finance_payout_batches" b where b.id = batch_id and public.is_member(b.provider_organization_id))
);

drop policy if exists finance_payout_batch_items_write_scoped on public."InCert-finance_payout_batch_items";
create policy finance_payout_batch_items_write_scoped on public."InCert-finance_payout_batch_items"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-finance_payout_batches" b
    where b.id = batch_id
      and public.has_role(b.provider_organization_id, array['provider_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-finance_payout_batches" b
    where b.id = batch_id
      and public.has_role(b.provider_organization_id, array['provider_admin']::public.app_role[])
  )
);

drop policy if exists finance_payment_events_select_scoped on public."InCert-finance_payment_events";
create policy finance_payment_events_select_scoped on public."InCert-finance_payment_events"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists finance_payment_events_insert_scoped on public."InCert-finance_payment_events";
create policy finance_payment_events_insert_scoped on public."InCert-finance_payment_events"
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'procurement', 'provider_admin']::public.app_role[])
);

drop policy if exists analytics_kpi_snapshots_select_scoped on public."InCert-analytics_kpi_snapshots";
create policy analytics_kpi_snapshots_select_scoped on public."InCert-analytics_kpi_snapshots"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists analytics_kpi_snapshots_write_scoped on public."InCert-analytics_kpi_snapshots";
create policy analytics_kpi_snapshots_write_scoped on public."InCert-analytics_kpi_snapshots"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[])
);

drop policy if exists analytics_provider_scorecards_select_scoped on public."InCert-analytics_provider_scorecards";
create policy analytics_provider_scorecards_select_scoped on public."InCert-analytics_provider_scorecards"
for select to authenticated
using (public.is_platform_admin() or public.is_member(provider_organization_id));

drop policy if exists analytics_provider_scorecards_write_scoped on public."InCert-analytics_provider_scorecards";
create policy analytics_provider_scorecards_write_scoped on public."InCert-analytics_provider_scorecards"
for all to authenticated
using (public.is_platform_admin())
with check (public.is_platform_admin());

drop policy if exists analytics_risk_signals_select_scoped on public."InCert-analytics_risk_signals";
create policy analytics_risk_signals_select_scoped on public."InCert-analytics_risk_signals"
for select to authenticated
using (public.is_platform_admin() or public.is_member(organization_id));

drop policy if exists analytics_risk_signals_write_scoped on public."InCert-analytics_risk_signals";
create policy analytics_risk_signals_write_scoped on public."InCert-analytics_risk_signals"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'auditor_viewer']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'auditor_viewer']::public.app_role[])
);

-- Realtime publication

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public."InCert-capa_actions";
    exception when duplicate_object then null; end;

    begin
      alter publication supabase_realtime add table public."InCert-finance_invoices";
    exception when duplicate_object then null; end;

    begin
      alter publication supabase_realtime add table public."InCert-finance_payout_batches";
    exception when duplicate_object then null; end;

    begin
      alter publication supabase_realtime add table public."InCert-analytics_risk_signals";
    exception when duplicate_object then null; end;
  end if;
end $$;

grant execute on function public.create_capa_action(uuid, text, public.capa_priority, date, text) to authenticated;
grant execute on function public.generate_invoice_for_request(uuid, boolean) to authenticated;
grant execute on function public.refresh_org_kpi_snapshot(uuid, date) to authenticated;
