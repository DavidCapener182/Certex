-- 2026-02-22: QR labels + certificate rendering metadata
-- Adds printable asset tags, QR scan telemetry, and rendered certificate metadata.

create table if not exists public.asset_qr_labels (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  asset_id uuid not null references public.assets(id) on delete cascade,
  latest_certificate_id uuid references public.certificates(id) on delete set null,
  qr_token text not null unique,
  deep_link text not null,
  label_version integer not null default 1 check (label_version > 0),
  printed_count integer not null default 0 check (printed_count >= 0),
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (asset_id, label_version)
);

create table if not exists public.qr_scan_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  asset_id uuid references public.assets(id) on delete set null,
  certificate_id uuid references public.certificates(id) on delete set null,
  scanned_by uuid references auth.users(id) on delete set null,
  scan_source text not null default 'web',
  payload text not null,
  resolved_target text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.certificates
  add column if not exists render_template_version text not null default 'certex_html_v1',
  add column if not exists rendered_html text,
  add column if not exists rendered_svg text,
  add column if not exists rendered_pdf_storage_path text,
  add column if not exists rendered_at timestamptz;

create index if not exists idx_asset_qr_labels_org_asset on public.asset_qr_labels(organization_id, asset_id);
create index if not exists idx_asset_qr_labels_active on public.asset_qr_labels(is_active) where is_active = true;
create index if not exists idx_qr_scan_events_org_created on public.qr_scan_events(organization_id, created_at desc);
create index if not exists idx_qr_scan_events_asset on public.qr_scan_events(asset_id) where asset_id is not null;
create index if not exists idx_qr_scan_events_certificate on public.qr_scan_events(certificate_id) where certificate_id is not null;

drop trigger if exists tr_set_updated_at_asset_qr_labels on public.asset_qr_labels;
create trigger tr_set_updated_at_asset_qr_labels
before update on public.asset_qr_labels
for each row execute function public.set_updated_at();

create or replace function public.resolve_asset_qr_token(p_qr_token text)
returns table (
  qr_label_id uuid,
  organization_id uuid,
  asset_id uuid,
  asset_external_id text,
  asset_name text,
  regime public.asset_regime,
  next_due_date date,
  latest_certificate_id uuid,
  latest_certificate_number text,
  certificate_expiry_date date
)
language sql
security definer
set search_path = public
stable
as $$
  select
    q.id as qr_label_id,
    q.organization_id,
    a.id as asset_id,
    a.external_asset_id,
    a.name as asset_name,
    a.regime,
    a.next_due_date,
    c.id as latest_certificate_id,
    c.certificate_number as latest_certificate_number,
    c.expiry_date as certificate_expiry_date
  from public.asset_qr_labels q
  join public.assets a on a.id = q.asset_id
  left join public.certificates c on c.id = q.latest_certificate_id
  where q.qr_token = trim(coalesce(p_qr_token, ''))
    and q.is_active = true
  limit 1;
$$;

alter table public.asset_qr_labels enable row level security;
alter table public.qr_scan_events enable row level security;

drop policy if exists asset_qr_labels_select_scoped on public.asset_qr_labels;
create policy asset_qr_labels_select_scoped on public.asset_qr_labels
for select to authenticated
using (
  public.is_platform_admin()
  or public.is_member(organization_id)
  or public.can_access_asset(asset_id)
);

drop policy if exists asset_qr_labels_insert_roles on public.asset_qr_labels;
create policy asset_qr_labels_insert_roles on public.asset_qr_labels
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
);

drop policy if exists asset_qr_labels_update_roles on public.asset_qr_labels;
create policy asset_qr_labels_update_roles on public.asset_qr_labels
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
)
with check (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
);

drop policy if exists asset_qr_labels_delete_roles on public.asset_qr_labels;
create policy asset_qr_labels_delete_roles on public.asset_qr_labels
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin']::public.app_role[]
  )
);

drop policy if exists qr_scan_events_select_scoped on public.qr_scan_events;
create policy qr_scan_events_select_scoped on public.qr_scan_events
for select to authenticated
using (
  public.is_platform_admin()
  or public.is_member(organization_id)
  or (asset_id is not null and public.can_access_asset(asset_id))
  or (certificate_id is not null and public.can_access_certificate(certificate_id))
);

drop policy if exists qr_scan_events_insert_scoped on public.qr_scan_events;
create policy qr_scan_events_insert_scoped on public.qr_scan_events
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.is_member(organization_id)
);

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.asset_qr_labels;
    exception
      when duplicate_object then null;
    end;

    begin
      alter publication supabase_realtime add table public.qr_scan_events;
    exception
      when duplicate_object then null;
    end;
  end if;
end $$;
