-- 2026-02-22: Marketplace scope, pricing, provider availability, and dispatch workflow

-- Marketplace-specific enums

do $$
begin
  if not exists (select 1 from pg_type where typname = 'marketplace_scope_template') then
    create type public.marketplace_scope_template as enum (
      'portfolio_sweep',
      'urgent_defect_followup',
      'insurer_verification',
      'written_scheme_review'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'marketplace_access_complexity') then
    create type public.marketplace_access_complexity as enum (
      'standard',
      'restricted',
      'out_of_hours'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'dispatch_attempt_status') then
    create type public.dispatch_attempt_status as enum (
      'offered',
      'accepted',
      'declined',
      'expired',
      'superseded',
      'cancelled'
    );
  end if;
end $$;

create table if not exists public.provider_rate_cards (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  regime public.asset_regime not null,
  region_code text not null default 'gb_default',
  currency_code char(3) not null default 'GBP',
  hourly_rate numeric(12, 2) not null check (hourly_rate > 0),
  minimum_callout numeric(12, 2) not null check (minimum_callout > 0),
  travel_rate_per_km numeric(12, 2) not null default 0 check (travel_rate_per_km >= 0),
  equipment_surcharge_map jsonb not null default '{}'::jsonb,
  expedite_surcharge_pct numeric(5, 4) not null default 0 check (expedite_surcharge_pct >= 0 and expedite_surcharge_pct <= 2),
  platform_fee_pct numeric(5, 4) not null default 0.10 check (platform_fee_pct >= 0 and platform_fee_pct <= 1),
  effective_from date not null default current_date,
  effective_to date,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint provider_rate_cards_date_window check (
    effective_to is null or effective_to >= effective_from
  ),
  unique (organization_id, regime, region_code, effective_from)
);

create table if not exists public.provider_availability_windows (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  weekday smallint not null check (weekday between 0 and 6),
  window_start time not null,
  window_end time not null,
  timezone text not null default 'Europe/London',
  max_concurrent_jobs integer not null default 4 check (max_concurrent_jobs > 0),
  is_available boolean not null default true,
  effective_from date not null default current_date,
  effective_to date,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint provider_availability_window_time check (window_end > window_start),
  constraint provider_availability_window_dates check (
    effective_to is null or effective_to >= effective_from
  )
);

create table if not exists public.marketplace_requests (
  request_id uuid primary key references public.inspection_requests(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  scope_template public.marketplace_scope_template not null default 'portfolio_sweep',
  asset_count integer not null default 1 check (asset_count > 0),
  estimated_hours numeric(8, 2) not null default 2 check (estimated_hours > 0),
  access_complexity public.marketplace_access_complexity not null default 'standard',
  equipment_profile text not null default 'none',
  travel_km numeric(10, 2) not null default 0 check (travel_km >= 0),
  weekend_access_required boolean not null default false,
  expedite_requested boolean not null default false,
  quote_currency char(3) not null default 'GBP',
  quote_labour numeric(12, 2) not null default 0 check (quote_labour >= 0),
  quote_travel numeric(12, 2) not null default 0 check (quote_travel >= 0),
  quote_equipment numeric(12, 2) not null default 0 check (quote_equipment >= 0),
  quote_expedite numeric(12, 2) not null default 0 check (quote_expedite >= 0),
  quote_platform_fee numeric(12, 2) not null default 0 check (quote_platform_fee >= 0),
  quote_total numeric(12, 2) not null default 0 check (quote_total >= 0),
  quote_version integer not null default 1 check (quote_version > 0),
  dispatch_sla_minutes integer not null default 360 check (dispatch_sla_minutes between 30 and 4320),
  dispatch_deadline_at timestamptz,
  latest_offer_expires_at timestamptz,
  latest_offer_provider_organization_id uuid references public.organizations(id) on delete set null,
  accepted_provider_organization_id uuid references public.organizations(id) on delete set null,
  accepted_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.marketplace_dispatch_attempts (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.inspection_requests(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  provider_organization_id uuid not null references public.organizations(id) on delete restrict,
  status public.dispatch_attempt_status not null default 'offered',
  rank_score numeric(6, 2),
  payout_estimate numeric(12, 2),
  offered_at timestamptz not null default now(),
  expires_at timestamptz,
  responded_at timestamptz,
  response_notes text,
  source text not null default 'incert_match_engine',
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint marketplace_dispatch_attempt_expiry check (
    expires_at is null or expires_at > offered_at
  )
);

create index if not exists idx_provider_rate_cards_org_regime_active
  on public.provider_rate_cards(organization_id, regime, is_active, effective_from desc);
create index if not exists idx_provider_rate_cards_region
  on public.provider_rate_cards(region_code, regime) where is_active = true;
create index if not exists idx_provider_availability_org_weekday
  on public.provider_availability_windows(organization_id, weekday, is_available);
create index if not exists idx_marketplace_requests_org_created
  on public.marketplace_requests(organization_id, created_at desc);
create index if not exists idx_marketplace_requests_accepted_provider
  on public.marketplace_requests(accepted_provider_organization_id) where accepted_provider_organization_id is not null;
create index if not exists idx_marketplace_dispatch_request_status
  on public.marketplace_dispatch_attempts(request_id, status, offered_at desc);
create index if not exists idx_marketplace_dispatch_provider_status
  on public.marketplace_dispatch_attempts(provider_organization_id, status, offered_at desc);

create or replace function public.prepare_marketplace_request()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_org_id uuid;
begin
  select r.organization_id
  into v_org_id
  from public.inspection_requests r
  where r.id = new.request_id;

  if v_org_id is null then
    raise exception 'Inspection request % does not exist', new.request_id;
  end if;

  new.organization_id = v_org_id;

  if new.dispatch_deadline_at is null then
    new.dispatch_deadline_at := now() + make_interval(mins => greatest(30, new.dispatch_sla_minutes));
  end if;

  if coalesce(new.quote_total, 0) = 0 then
    new.quote_total :=
      coalesce(new.quote_labour, 0)
      + coalesce(new.quote_travel, 0)
      + coalesce(new.quote_equipment, 0)
      + coalesce(new.quote_expedite, 0)
      + coalesce(new.quote_platform_fee, 0);
  end if;

  return new;
end;
$$;

create or replace function public.calculate_marketplace_quote(
  p_regime public.asset_regime,
  p_site_region text,
  p_estimated_hours numeric,
  p_access_complexity public.marketplace_access_complexity,
  p_travel_km numeric default 0,
  p_equipment_profile text default 'none',
  p_expedite boolean default false,
  p_platform_fee_pct numeric default 0.10
)
returns table (
  labour numeric,
  travel numeric,
  equipment numeric,
  expedite numeric,
  platform_fee numeric,
  total numeric
)
language plpgsql
stable
set search_path = public
as $$
declare
  v_hourly_rate numeric;
  v_complexity_multiplier numeric;
  v_regime_multiplier numeric;
  v_equipment_charge numeric;
  v_subtotal numeric;
begin
  v_hourly_rate := case lower(trim(coalesce(p_site_region, 'other')))
    when 'london' then 96
    when 'manchester' then 86
    when 'birmingham' then 84
    else 82
  end;

  v_complexity_multiplier := case p_access_complexity
    when 'restricted' then 1.22
    when 'out_of_hours' then 1.35
    else 1
  end;

  v_regime_multiplier := case p_regime
    when 'PSSR' then 1.16
    when 'PUWER' then 0.94
    else 1
  end;

  v_equipment_charge := case lower(trim(coalesce(p_equipment_profile, 'none')))
    when 'specialist_instruments' then 120
    when 'rope_access' then 160
    when 'confined_space' then 210
    else 0
  end;

  labour := round(greatest(180, coalesce(p_estimated_hours, 0) * v_hourly_rate * v_complexity_multiplier * v_regime_multiplier), 2);
  travel := round(greatest(0, coalesce(p_travel_km, 0) * 1.35), 2);
  equipment := round(greatest(0, v_equipment_charge), 2);
  expedite := case when coalesce(p_expedite, false)
    then round((labour + travel) * 0.18, 2)
    else 0
  end;

  v_subtotal := labour + travel + equipment + expedite;
  platform_fee := round(v_subtotal * greatest(0, least(1, coalesce(p_platform_fee_pct, 0.10))), 2);
  total := round(v_subtotal + platform_fee, 2);

  return next;
end;
$$;

create or replace function public.send_marketplace_offer(
  p_request_id uuid,
  p_provider_organization_id uuid,
  p_offer_ttl_minutes integer default 90,
  p_rank_score numeric default null,
  p_payout_estimate numeric default null,
  p_source text default 'incert_match_engine'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_attempt_id uuid;
  v_request_org uuid;
  v_expires_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  if p_offer_ttl_minutes < 15 or p_offer_ttl_minutes > 720 then
    raise exception 'p_offer_ttl_minutes must be between 15 and 720';
  end if;

  select r.organization_id
  into v_request_org
  from public.inspection_requests r
  where r.id = p_request_id;

  if v_request_org is null then
    raise exception 'Inspection request % not found', p_request_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(
      v_request_org,
      array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
    )
  ) then
    raise exception 'Not authorized to dispatch marketplace offers for request %', p_request_id;
  end if;

  v_expires_at := now() + make_interval(mins => p_offer_ttl_minutes);

  insert into public.marketplace_dispatch_attempts (
    request_id,
    organization_id,
    provider_organization_id,
    status,
    rank_score,
    payout_estimate,
    offered_at,
    expires_at,
    source,
    created_by
  )
  values (
    p_request_id,
    v_request_org,
    p_provider_organization_id,
    'offered',
    p_rank_score,
    p_payout_estimate,
    now(),
    v_expires_at,
    coalesce(nullif(trim(p_source), ''), 'incert_match_engine'),
    auth.uid()
  )
  returning id into v_attempt_id;

  insert into public.marketplace_requests (request_id, organization_id)
  values (p_request_id, v_request_org)
  on conflict (request_id) do update set
    updated_at = now();

  update public.marketplace_requests mr
  set
    latest_offer_provider_organization_id = p_provider_organization_id,
    latest_offer_expires_at = v_expires_at,
    accepted_provider_organization_id = null,
    accepted_at = null,
    updated_at = now()
  where mr.request_id = p_request_id;

  update public.inspection_requests r
  set
    status = 'offered',
    updated_at = now()
  where r.id = p_request_id
    and r.status in ('draft', 'open', 'offered');

  perform public.write_audit_log(
    v_request_org,
    'marketplace.offer_sent',
    'inspection_request',
    p_request_id,
    jsonb_build_object(
      'dispatch_attempt_id', v_attempt_id,
      'provider_organization_id', p_provider_organization_id,
      'offer_expires_at', v_expires_at
    )
  );

  return v_attempt_id;
end;
$$;

create or replace function public.accept_marketplace_offer(
  p_dispatch_attempt_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_attempt public.marketplace_dispatch_attempts%rowtype;
  v_request_org uuid;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  select *
  into v_attempt
  from public.marketplace_dispatch_attempts a
  where a.id = p_dispatch_attempt_id;

  if not found then
    return false;
  end if;

  select r.organization_id
  into v_request_org
  from public.inspection_requests r
  where r.id = v_attempt.request_id;

  if v_request_org is null then
    return false;
  end if;

  if not (
    public.is_platform_admin()
    or public.is_member(v_attempt.provider_organization_id)
    or public.has_role(
      v_request_org,
      array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
    )
  ) then
    raise exception 'Not authorized to accept dispatch attempt %', p_dispatch_attempt_id;
  end if;

  if v_attempt.expires_at is not null and v_attempt.expires_at <= now() then
    update public.marketplace_dispatch_attempts
    set
      status = 'expired',
      responded_at = coalesce(responded_at, now())
    where id = v_attempt.id;

    return false;
  end if;

  update public.marketplace_dispatch_attempts
  set
    status = 'accepted',
    responded_at = now()
  where id = v_attempt.id;

  update public.marketplace_dispatch_attempts
  set
    status = 'superseded',
    responded_at = coalesce(responded_at, now())
  where request_id = v_attempt.request_id
    and id <> v_attempt.id
    and status = 'offered';

  insert into public.marketplace_requests (request_id, organization_id)
  values (v_attempt.request_id, v_request_org)
  on conflict (request_id) do update set
    updated_at = now();

  update public.marketplace_requests mr
  set
    accepted_provider_organization_id = v_attempt.provider_organization_id,
    accepted_at = now(),
    latest_offer_provider_organization_id = v_attempt.provider_organization_id,
    latest_offer_expires_at = null,
    updated_at = now()
  where mr.request_id = v_attempt.request_id;

  update public.inspection_requests r
  set
    status = 'scheduled',
    updated_at = now()
  where r.id = v_attempt.request_id
    and r.status in ('open', 'offered');

  perform public.write_audit_log(
    v_request_org,
    'marketplace.offer_accepted',
    'inspection_request',
    v_attempt.request_id,
    jsonb_build_object(
      'dispatch_attempt_id', v_attempt.id,
      'provider_organization_id', v_attempt.provider_organization_id
    )
  );

  return true;
end;
$$;

drop trigger if exists tr_set_updated_at_provider_rate_cards on public.provider_rate_cards;
create trigger tr_set_updated_at_provider_rate_cards
before update on public.provider_rate_cards
for each row execute function public.set_updated_at();

drop trigger if exists tr_set_updated_at_provider_availability_windows on public.provider_availability_windows;
create trigger tr_set_updated_at_provider_availability_windows
before update on public.provider_availability_windows
for each row execute function public.set_updated_at();

drop trigger if exists tr_prepare_marketplace_request on public.marketplace_requests;
create trigger tr_prepare_marketplace_request
before insert or update on public.marketplace_requests
for each row execute function public.prepare_marketplace_request();

drop trigger if exists tr_set_updated_at_marketplace_requests on public.marketplace_requests;
create trigger tr_set_updated_at_marketplace_requests
before update on public.marketplace_requests
for each row execute function public.set_updated_at();

alter table public.provider_rate_cards enable row level security;
alter table public.provider_availability_windows enable row level security;
alter table public.marketplace_requests enable row level security;
alter table public.marketplace_dispatch_attempts enable row level security;

-- provider_rate_cards policies

drop policy if exists provider_rate_cards_select_scoped on public.provider_rate_cards;
create policy provider_rate_cards_select_scoped on public.provider_rate_cards
for select to authenticated
using (
  public.is_platform_admin()
  or public.is_member(organization_id)
);

drop policy if exists provider_rate_cards_insert_admin on public.provider_rate_cards;
create policy provider_rate_cards_insert_admin on public.provider_rate_cards
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
);

drop policy if exists provider_rate_cards_update_admin on public.provider_rate_cards;
create policy provider_rate_cards_update_admin on public.provider_rate_cards
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
);

drop policy if exists provider_rate_cards_delete_admin on public.provider_rate_cards;
create policy provider_rate_cards_delete_admin on public.provider_rate_cards
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
);

-- provider_availability_windows policies

drop policy if exists provider_availability_select_scoped on public.provider_availability_windows;
create policy provider_availability_select_scoped on public.provider_availability_windows
for select to authenticated
using (
  public.is_platform_admin()
  or public.is_member(organization_id)
);

drop policy if exists provider_availability_insert_admin on public.provider_availability_windows;
create policy provider_availability_insert_admin on public.provider_availability_windows
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
);

drop policy if exists provider_availability_update_admin on public.provider_availability_windows;
create policy provider_availability_update_admin on public.provider_availability_windows
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
);

drop policy if exists provider_availability_delete_admin on public.provider_availability_windows;
create policy provider_availability_delete_admin on public.provider_availability_windows
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
);

-- marketplace_requests policies

drop policy if exists marketplace_requests_select_scoped on public.marketplace_requests;
create policy marketplace_requests_select_scoped on public.marketplace_requests
for select to authenticated
using (
  public.is_platform_admin()
  or public.can_access_request(request_id)
);

drop policy if exists marketplace_requests_insert_scoped on public.marketplace_requests;
create policy marketplace_requests_insert_scoped on public.marketplace_requests
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
);

drop policy if exists marketplace_requests_update_scoped on public.marketplace_requests;
create policy marketplace_requests_update_scoped on public.marketplace_requests
for update to authenticated
using (
  public.is_platform_admin()
  or public.can_access_request(request_id)
)
with check (
  public.is_platform_admin()
  or public.can_access_request(request_id)
);

drop policy if exists marketplace_requests_delete_platform on public.marketplace_requests;
create policy marketplace_requests_delete_platform on public.marketplace_requests
for delete to authenticated
using (public.is_platform_admin());

-- marketplace_dispatch_attempts policies

drop policy if exists marketplace_dispatch_attempts_select_scoped on public.marketplace_dispatch_attempts;
create policy marketplace_dispatch_attempts_select_scoped on public.marketplace_dispatch_attempts
for select to authenticated
using (
  public.is_platform_admin()
  or public.can_access_request(request_id)
  or public.is_member(provider_organization_id)
);

drop policy if exists marketplace_dispatch_attempts_insert_scoped on public.marketplace_dispatch_attempts;
create policy marketplace_dispatch_attempts_insert_scoped on public.marketplace_dispatch_attempts
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
);

drop policy if exists marketplace_dispatch_attempts_update_scoped on public.marketplace_dispatch_attempts;
create policy marketplace_dispatch_attempts_update_scoped on public.marketplace_dispatch_attempts
for update to authenticated
using (
  public.is_platform_admin()
  or public.can_access_request(request_id)
  or public.is_member(provider_organization_id)
)
with check (
  public.is_platform_admin()
  or public.can_access_request(request_id)
  or public.is_member(provider_organization_id)
);

drop policy if exists marketplace_dispatch_attempts_delete_platform on public.marketplace_dispatch_attempts;
create policy marketplace_dispatch_attempts_delete_platform on public.marketplace_dispatch_attempts
for delete to authenticated
using (public.is_platform_admin());

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.marketplace_requests;
    exception
      when duplicate_object then null;
    end;

    begin
      alter publication supabase_realtime add table public.marketplace_dispatch_attempts;
    exception
      when duplicate_object then null;
    end;
  end if;
end $$;

grant execute on function public.calculate_marketplace_quote(
  public.asset_regime,
  text,
  numeric,
  public.marketplace_access_complexity,
  numeric,
  text,
  boolean,
  numeric
) to authenticated;

grant execute on function public.send_marketplace_offer(
  uuid,
  uuid,
  integer,
  numeric,
  numeric,
  text
) to authenticated;

grant execute on function public.accept_marketplace_offer(uuid) to authenticated;
