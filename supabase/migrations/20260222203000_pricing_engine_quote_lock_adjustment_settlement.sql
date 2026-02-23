-- 2026-02-22: Algorithmic pricing engine entities (versioned quotes, locks, adjustments, settlements)

do $$
begin
  if not exists (select 1 from pg_type where typname = 'price_quote_status') then
    create type public.price_quote_status as enum (
      'draft',
      'accepted',
      'adjusted',
      'superseded',
      'expired'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'pricing_adjustment_type') then
    create type public.pricing_adjustment_type as enum (
      'scope_up',
      'scope_down',
      'cancellation',
      'no_show',
      'service_credit'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'settlement_status') then
    create type public.settlement_status as enum (
      'pending_completion',
      'scheduled',
      'paid',
      'on_hold',
      'cancelled'
    );
  end if;
end $$;

create table if not exists public.pricing_model_versions (
  id uuid primary key default gen_random_uuid(),
  model_key text not null default 'marketplace_default',
  version_no integer not null default 1 check (version_no > 0),
  is_active boolean not null default true,
  effective_from timestamptz not null default now(),
  effective_to timestamptz,
  config_jsonb jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint pricing_model_versions_effective_window check (
    effective_to is null or effective_to >= effective_from
  ),
  unique (model_key, version_no)
);

create table if not exists public.price_quotes (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.inspection_requests(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  provider_organization_id uuid references public.organizations(id) on delete set null,
  rate_card_id uuid references public.provider_rate_cards(id) on delete set null,
  pricing_model_version_id uuid references public.pricing_model_versions(id) on delete set null,
  quote_version integer not null check (quote_version > 0),
  quote_status public.price_quote_status not null default 'draft',
  currency_code char(3) not null default 'GBP',
  mapping_snapshot_jsonb jsonb not null default '{}'::jsonb,
  assumptions_jsonb jsonb not null default '[]'::jsonb,
  subtotal_ex_vat numeric(12, 2) not null check (subtotal_ex_vat >= 0),
  vat_amount numeric(12, 2) not null default 0 check (vat_amount >= 0),
  total_inc_vat numeric(12, 2) not null check (total_inc_vat >= 0),
  provider_payout_ex_vat numeric(12, 2) not null default 0 check (provider_payout_ex_vat >= 0),
  provider_vat_amount numeric(12, 2) not null default 0 check (provider_vat_amount >= 0),
  platform_fee_ex_vat numeric(12, 2) not null default 0 check (platform_fee_ex_vat >= 0),
  platform_vat_amount numeric(12, 2) not null default 0 check (platform_vat_amount >= 0),
  effective_take_rate numeric(5, 4) not null default 0.12 check (effective_take_rate >= 0 and effective_take_rate <= 1),
  valid_until timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint price_quotes_total_consistency check (
    total_inc_vat >= subtotal_ex_vat
  ),
  unique (request_id, quote_version)
);

create table if not exists public.price_quote_line_items (
  id uuid primary key default gen_random_uuid(),
  quote_id uuid not null references public.price_quotes(id) on delete cascade,
  line_no integer not null check (line_no > 0),
  code text not null,
  label text,
  quantity numeric(12, 3) not null default 1 check (quantity >= 0),
  unit text,
  unit_price_ex_vat numeric(12, 2),
  amount_ex_vat numeric(12, 2) not null,
  metadata_jsonb jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (quote_id, line_no)
);

create table if not exists public.pricing_locks (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.inspection_requests(id) on delete cascade,
  quote_id uuid not null references public.price_quotes(id) on delete restrict,
  booking_reference text,
  lock_reason text not null default 'quote_accept',
  metadata jsonb not null default '{}'::jsonb,
  locked_by uuid references auth.users(id) on delete set null,
  locked_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pricing_adjustments (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.inspection_requests(id) on delete cascade,
  quote_id uuid not null references public.price_quotes(id) on delete cascade,
  lock_id uuid references public.pricing_locks(id) on delete set null,
  adjustment_type public.pricing_adjustment_type not null,
  reason_code text not null,
  amount_ex_vat_delta numeric(12, 2) not null check (amount_ex_vat_delta <> 0),
  evidence_ref text,
  metadata jsonb not null default '{}'::jsonb,
  approved_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.settlement_ledgers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.inspection_requests(id) on delete cascade,
  lock_id uuid references public.pricing_locks(id) on delete set null,
  quote_id uuid references public.price_quotes(id) on delete set null,
  status public.settlement_status not null default 'pending_completion',
  payout_event text not null default 'EVIDENCE_ISSUED',
  provider_amount_ex_vat numeric(12, 2) not null default 0 check (provider_amount_ex_vat >= 0),
  provider_vat_amount numeric(12, 2) not null default 0 check (provider_vat_amount >= 0),
  platform_fee_ex_vat numeric(12, 2) not null default 0 check (platform_fee_ex_vat >= 0),
  platform_vat_amount numeric(12, 2) not null default 0 check (platform_vat_amount >= 0),
  holdback_pct numeric(5, 4) not null default 0.05 check (holdback_pct >= 0 and holdback_pct <= 1),
  holdback_amount numeric(12, 2) not null default 0 check (holdback_amount >= 0),
  dispute_reserve_pct numeric(5, 4) not null default 0.015 check (dispute_reserve_pct >= 0 and dispute_reserve_pct <= 1),
  dispute_reserve_amount numeric(12, 2) not null default 0 check (dispute_reserve_amount >= 0),
  net_provider_scheduled numeric(12, 2) not null default 0 check (net_provider_scheduled >= 0),
  scheduled_payout_date date,
  paid_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_price_quotes_request_created
  on public.price_quotes(request_id, created_at desc);
create index if not exists idx_price_quotes_org_status
  on public.price_quotes(organization_id, quote_status, created_at desc);
create index if not exists idx_price_quotes_provider_status
  on public.price_quotes(provider_organization_id, quote_status, created_at desc)
  where provider_organization_id is not null;
create index if not exists idx_price_quote_line_items_quote
  on public.price_quote_line_items(quote_id, line_no);
create index if not exists idx_pricing_adjustments_request
  on public.pricing_adjustments(request_id, created_at desc);
create index if not exists idx_settlement_ledgers_status
  on public.settlement_ledgers(status, scheduled_payout_date);

drop trigger if exists tr_set_updated_at_pricing_locks on public.pricing_locks;
create trigger tr_set_updated_at_pricing_locks
before update on public.pricing_locks
for each row execute function public.set_updated_at();

drop trigger if exists tr_set_updated_at_settlement_ledgers on public.settlement_ledgers;
create trigger tr_set_updated_at_settlement_ledgers
before update on public.settlement_ledgers
for each row execute function public.set_updated_at();

create or replace function public.create_price_quote(
  p_request_id uuid,
  p_provider_organization_id uuid default null,
  p_rate_card_id uuid default null,
  p_pricing_model_version_id uuid default null,
  p_subtotal_ex_vat numeric default 0,
  p_vat_amount numeric default 0,
  p_total_inc_vat numeric default 0,
  p_provider_payout_ex_vat numeric default 0,
  p_provider_vat_amount numeric default 0,
  p_platform_fee_ex_vat numeric default 0,
  p_platform_vat_amount numeric default 0,
  p_effective_take_rate numeric default 0.12,
  p_currency_code char(3) default 'GBP',
  p_valid_until timestamptz default null,
  p_mapping_snapshot_jsonb jsonb default '{}'::jsonb,
  p_assumptions_jsonb jsonb default '[]'::jsonb,
  p_line_items jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_quote_id uuid;
  v_org_id uuid;
  v_quote_version integer;
  v_line_no integer := 0;
  v_line_item jsonb;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  select r.organization_id
  into v_org_id
  from public.inspection_requests r
  where r.id = p_request_id;

  if v_org_id is null then
    raise exception 'Inspection request % not found', p_request_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(
      v_org_id,
      array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
    )
    or (
      p_provider_organization_id is not null
      and public.has_role(p_provider_organization_id, array['provider_admin']::public.app_role[])
    )
  ) then
    raise exception 'Not authorized to create quote for request %', p_request_id;
  end if;

  select coalesce(max(q.quote_version), 0) + 1
  into v_quote_version
  from public.price_quotes q
  where q.request_id = p_request_id;

  insert into public.price_quotes (
    request_id,
    organization_id,
    provider_organization_id,
    rate_card_id,
    pricing_model_version_id,
    quote_version,
    quote_status,
    currency_code,
    mapping_snapshot_jsonb,
    assumptions_jsonb,
    subtotal_ex_vat,
    vat_amount,
    total_inc_vat,
    provider_payout_ex_vat,
    provider_vat_amount,
    platform_fee_ex_vat,
    platform_vat_amount,
    effective_take_rate,
    valid_until,
    created_by
  )
  values (
    p_request_id,
    v_org_id,
    p_provider_organization_id,
    p_rate_card_id,
    p_pricing_model_version_id,
    v_quote_version,
    'draft',
    coalesce(p_currency_code, 'GBP'),
    coalesce(p_mapping_snapshot_jsonb, '{}'::jsonb),
    coalesce(p_assumptions_jsonb, '[]'::jsonb),
    greatest(0, round(coalesce(p_subtotal_ex_vat, 0)::numeric, 2)),
    greatest(0, round(coalesce(p_vat_amount, 0)::numeric, 2)),
    greatest(0, round(coalesce(p_total_inc_vat, 0)::numeric, 2)),
    greatest(0, round(coalesce(p_provider_payout_ex_vat, 0)::numeric, 2)),
    greatest(0, round(coalesce(p_provider_vat_amount, 0)::numeric, 2)),
    greatest(0, round(coalesce(p_platform_fee_ex_vat, 0)::numeric, 2)),
    greatest(0, round(coalesce(p_platform_vat_amount, 0)::numeric, 2)),
    greatest(0, least(1, coalesce(p_effective_take_rate, 0.12))),
    p_valid_until,
    auth.uid()
  )
  returning id into v_quote_id;

  if jsonb_typeof(coalesce(p_line_items, '[]'::jsonb)) = 'array' then
    for v_line_item in select * from jsonb_array_elements(coalesce(p_line_items, '[]'::jsonb))
    loop
      v_line_no := v_line_no + 1;
      insert into public.price_quote_line_items (
        quote_id,
        line_no,
        code,
        label,
        quantity,
        unit,
        unit_price_ex_vat,
        amount_ex_vat,
        metadata_jsonb
      )
      values (
        v_quote_id,
        v_line_no,
        coalesce(v_line_item->>'code', 'LINE_ITEM'),
        nullif(v_line_item->>'label', ''),
        coalesce((v_line_item->>'quantity')::numeric, 1),
        nullif(v_line_item->>'unit', ''),
        (v_line_item->>'unit_price_ex_vat')::numeric,
        coalesce((v_line_item->>'amount_ex_vat')::numeric, 0),
        coalesce(v_line_item->'metadata', '{}'::jsonb)
      );
    end loop;
  end if;

  perform public.write_audit_log(
    v_org_id,
    'pricing.quote_created',
    'inspection_request',
    p_request_id,
    jsonb_build_object('quote_id', v_quote_id, 'quote_version', v_quote_version)
  );

  return v_quote_id;
end;
$$;

create or replace function public.lock_price_quote(
  p_quote_id uuid,
  p_booking_reference text default null,
  p_lock_reason text default 'quote_accept'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_quote public.price_quotes%rowtype;
  v_lock_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  select *
  into v_quote
  from public.price_quotes q
  where q.id = p_quote_id;

  if not found then
    raise exception 'Quote % not found', p_quote_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(
      v_quote.organization_id,
      array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
    )
    or (
      v_quote.provider_organization_id is not null
      and public.has_role(v_quote.provider_organization_id, array['provider_admin']::public.app_role[])
    )
  ) then
    raise exception 'Not authorized to lock quote %', p_quote_id;
  end if;

  update public.price_quotes
  set quote_status = 'superseded'
  where request_id = v_quote.request_id
    and quote_status = 'accepted'
    and id <> v_quote.id;

  update public.price_quotes
  set quote_status = 'accepted'
  where id = v_quote.id;

  insert into public.pricing_locks (
    request_id,
    quote_id,
    booking_reference,
    lock_reason,
    locked_by,
    locked_at
  )
  values (
    v_quote.request_id,
    v_quote.id,
    nullif(trim(coalesce(p_booking_reference, '')), ''),
    coalesce(nullif(trim(coalesce(p_lock_reason, '')), ''), 'quote_accept'),
    auth.uid(),
    now()
  )
  on conflict (request_id) do update set
    quote_id = excluded.quote_id,
    booking_reference = excluded.booking_reference,
    lock_reason = excluded.lock_reason,
    locked_by = excluded.locked_by,
    locked_at = excluded.locked_at,
    updated_at = now()
  returning id into v_lock_id;

  perform public.write_audit_log(
    v_quote.organization_id,
    'pricing.quote_locked',
    'inspection_request',
    v_quote.request_id,
    jsonb_build_object('quote_id', v_quote.id, 'pricing_lock_id', v_lock_id)
  );

  return v_lock_id;
end;
$$;

create or replace function public.apply_price_adjustment(
  p_request_id uuid,
  p_adjustment_type public.pricing_adjustment_type,
  p_reason_code text,
  p_amount_ex_vat_delta numeric,
  p_evidence_ref text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
  v_last_quote public.price_quotes%rowtype;
  v_lock public.pricing_locks%rowtype;
  v_next_quote_id uuid;
  v_next_quote_version integer;
  v_subtotal_ex_vat numeric(12, 2);
  v_platform_fee_ex_vat numeric(12, 2);
  v_provider_ex_vat numeric(12, 2);
  v_provider_vat numeric(12, 2);
  v_platform_vat numeric(12, 2);
  v_total_inc_vat numeric(12, 2);
  v_adjustment_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  if coalesce(p_amount_ex_vat_delta, 0) = 0 then
    raise exception 'p_amount_ex_vat_delta must be non-zero';
  end if;

  select r.organization_id
  into v_org_id
  from public.inspection_requests r
  where r.id = p_request_id;

  if v_org_id is null then
    raise exception 'Inspection request % not found', p_request_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(
      v_org_id,
      array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
    )
  ) then
    raise exception 'Not authorized to adjust request %', p_request_id;
  end if;

  select *
  into v_lock
  from public.pricing_locks pl
  where pl.request_id = p_request_id;

  if not found then
    raise exception 'Cannot adjust request % before lock is created', p_request_id;
  end if;

  select *
  into v_last_quote
  from public.price_quotes q
  where q.request_id = p_request_id
  order by q.quote_version desc
  limit 1;

  if not found then
    raise exception 'No quote found for request %', p_request_id;
  end if;

  v_next_quote_version := v_last_quote.quote_version + 1;
  v_subtotal_ex_vat := greatest(0, round((v_last_quote.subtotal_ex_vat + p_amount_ex_vat_delta)::numeric, 2));
  v_platform_fee_ex_vat := greatest(
    0,
    least(
      v_subtotal_ex_vat,
      round((v_subtotal_ex_vat * coalesce(v_last_quote.effective_take_rate, 0.12))::numeric, 2)
    )
  );
  v_provider_ex_vat := greatest(0, round((v_subtotal_ex_vat - v_platform_fee_ex_vat)::numeric, 2));
  v_provider_vat := round((v_provider_ex_vat * 0.20)::numeric, 2);
  v_platform_vat := round((v_platform_fee_ex_vat * 0.20)::numeric, 2);
  v_total_inc_vat := round((v_subtotal_ex_vat + v_provider_vat + v_platform_vat)::numeric, 2);

  insert into public.price_quotes (
    request_id,
    organization_id,
    provider_organization_id,
    rate_card_id,
    pricing_model_version_id,
    quote_version,
    quote_status,
    currency_code,
    mapping_snapshot_jsonb,
    assumptions_jsonb,
    subtotal_ex_vat,
    vat_amount,
    total_inc_vat,
    provider_payout_ex_vat,
    provider_vat_amount,
    platform_fee_ex_vat,
    platform_vat_amount,
    effective_take_rate,
    valid_until,
    metadata,
    created_by
  )
  values (
    v_last_quote.request_id,
    v_last_quote.organization_id,
    v_last_quote.provider_organization_id,
    v_last_quote.rate_card_id,
    v_last_quote.pricing_model_version_id,
    v_next_quote_version,
    'adjusted',
    v_last_quote.currency_code,
    v_last_quote.mapping_snapshot_jsonb,
    v_last_quote.assumptions_jsonb,
    v_subtotal_ex_vat,
    v_provider_vat + v_platform_vat,
    v_total_inc_vat,
    v_provider_ex_vat,
    v_provider_vat,
    v_platform_fee_ex_vat,
    v_platform_vat,
    v_last_quote.effective_take_rate,
    v_last_quote.valid_until,
    jsonb_set(
      coalesce(v_last_quote.metadata, '{}'::jsonb),
      '{last_adjustment}',
      jsonb_build_object('type', p_adjustment_type, 'delta', p_amount_ex_vat_delta, 'reason_code', p_reason_code),
      true
    ),
    auth.uid()
  )
  returning id into v_next_quote_id;

  insert into public.price_quote_line_items (
    quote_id,
    line_no,
    code,
    label,
    quantity,
    unit,
    unit_price_ex_vat,
    amount_ex_vat,
    metadata_jsonb
  )
  values (
    v_next_quote_id,
    1,
    'ADJUSTMENT',
    p_reason_code,
    1,
    'event',
    p_amount_ex_vat_delta,
    p_amount_ex_vat_delta,
    jsonb_build_object('adjustment_type', p_adjustment_type, 'evidence_ref', p_evidence_ref)
  );

  update public.pricing_locks
  set
    quote_id = v_next_quote_id,
    updated_at = now()
  where id = v_lock.id;

  insert into public.pricing_adjustments (
    request_id,
    quote_id,
    lock_id,
    adjustment_type,
    reason_code,
    amount_ex_vat_delta,
    evidence_ref,
    approved_by
  )
  values (
    p_request_id,
    v_next_quote_id,
    v_lock.id,
    p_adjustment_type,
    p_reason_code,
    p_amount_ex_vat_delta,
    nullif(trim(coalesce(p_evidence_ref, '')), ''),
    auth.uid()
  )
  returning id into v_adjustment_id;

  perform public.write_audit_log(
    v_org_id,
    'pricing.adjustment_applied',
    'inspection_request',
    p_request_id,
    jsonb_build_object(
      'adjustment_id', v_adjustment_id,
      'quote_id', v_next_quote_id,
      'adjustment_type', p_adjustment_type,
      'delta_ex_vat', p_amount_ex_vat_delta
    )
  );

  return v_adjustment_id;
end;
$$;

create or replace function public.upsert_settlement_ledger_for_request(
  p_request_id uuid,
  p_status public.settlement_status default 'scheduled',
  p_payout_event text default 'EVIDENCE_ISSUED'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org_id uuid;
  v_lock public.pricing_locks%rowtype;
  v_quote public.price_quotes%rowtype;
  v_holdback_amount numeric(12, 2);
  v_dispute_amount numeric(12, 2);
  v_net_provider numeric(12, 2);
  v_settlement_id uuid;
  v_scheduled_payout_date date;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  select r.organization_id
  into v_org_id
  from public.inspection_requests r
  where r.id = p_request_id;

  if v_org_id is null then
    raise exception 'Inspection request % not found', p_request_id;
  end if;

  if not (
    public.is_platform_admin()
    or public.has_role(
      v_org_id,
      array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
    )
  ) then
    raise exception 'Not authorized to settle request %', p_request_id;
  end if;

  select *
  into v_lock
  from public.pricing_locks pl
  where pl.request_id = p_request_id;

  if not found then
    raise exception 'Pricing lock missing for request %', p_request_id;
  end if;

  select *
  into v_quote
  from public.price_quotes q
  where q.id = v_lock.quote_id;

  if not found then
    raise exception 'Locked quote missing for request %', p_request_id;
  end if;

  v_holdback_amount := round((v_quote.provider_payout_ex_vat * 0.05)::numeric, 2);
  v_dispute_amount := round((v_quote.provider_payout_ex_vat * 0.015)::numeric, 2);
  v_net_provider := greatest(
    0,
    round((
      (v_quote.provider_payout_ex_vat + v_quote.provider_vat_amount)
      - v_holdback_amount
      - v_dispute_amount
    )::numeric, 2)
  );
  v_scheduled_payout_date := (date_trunc('week', now())::date + 11);

  insert into public.settlement_ledgers (
    request_id,
    lock_id,
    quote_id,
    status,
    payout_event,
    provider_amount_ex_vat,
    provider_vat_amount,
    platform_fee_ex_vat,
    platform_vat_amount,
    holdback_pct,
    holdback_amount,
    dispute_reserve_pct,
    dispute_reserve_amount,
    net_provider_scheduled,
    scheduled_payout_date,
    created_by
  )
  values (
    p_request_id,
    v_lock.id,
    v_quote.id,
    p_status,
    coalesce(nullif(trim(coalesce(p_payout_event, '')), ''), 'EVIDENCE_ISSUED'),
    v_quote.provider_payout_ex_vat,
    v_quote.provider_vat_amount,
    v_quote.platform_fee_ex_vat,
    v_quote.platform_vat_amount,
    0.05,
    v_holdback_amount,
    0.015,
    v_dispute_amount,
    v_net_provider,
    v_scheduled_payout_date,
    auth.uid()
  )
  on conflict (request_id) do update set
    lock_id = excluded.lock_id,
    quote_id = excluded.quote_id,
    status = excluded.status,
    payout_event = excluded.payout_event,
    provider_amount_ex_vat = excluded.provider_amount_ex_vat,
    provider_vat_amount = excluded.provider_vat_amount,
    platform_fee_ex_vat = excluded.platform_fee_ex_vat,
    platform_vat_amount = excluded.platform_vat_amount,
    holdback_pct = excluded.holdback_pct,
    holdback_amount = excluded.holdback_amount,
    dispute_reserve_pct = excluded.dispute_reserve_pct,
    dispute_reserve_amount = excluded.dispute_reserve_amount,
    net_provider_scheduled = excluded.net_provider_scheduled,
    scheduled_payout_date = excluded.scheduled_payout_date,
    updated_at = now()
  returning id into v_settlement_id;

  perform public.write_audit_log(
    v_org_id,
    'pricing.settlement_upserted',
    'inspection_request',
    p_request_id,
    jsonb_build_object('settlement_ledger_id', v_settlement_id, 'quote_id', v_quote.id, 'status', p_status)
  );

  return v_settlement_id;
end;
$$;

alter table public.pricing_model_versions enable row level security;
alter table public.price_quotes enable row level security;
alter table public.price_quote_line_items enable row level security;
alter table public.pricing_locks enable row level security;
alter table public.pricing_adjustments enable row level security;
alter table public.settlement_ledgers enable row level security;

drop policy if exists pricing_model_versions_select_scoped on public.pricing_model_versions;
create policy pricing_model_versions_select_scoped on public.pricing_model_versions
for select to authenticated
using (public.is_platform_admin() or is_active = true);

drop policy if exists pricing_model_versions_write_platform on public.pricing_model_versions;
create policy pricing_model_versions_write_platform on public.pricing_model_versions
for all to authenticated
using (public.is_platform_admin())
with check (public.is_platform_admin());

drop policy if exists price_quotes_select_scoped on public.price_quotes;
create policy price_quotes_select_scoped on public.price_quotes
for select to authenticated
using (public.is_platform_admin() or public.can_access_request(request_id));

drop policy if exists price_quotes_insert_scoped on public.price_quotes;
create policy price_quotes_insert_scoped on public.price_quotes
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
  or (
    provider_organization_id is not null
    and public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
  )
);

drop policy if exists price_quotes_update_scoped on public.price_quotes;
create policy price_quotes_update_scoped on public.price_quotes
for update to authenticated
using (
  public.is_platform_admin()
  or public.can_access_request(request_id)
)
with check (
  public.is_platform_admin()
  or public.can_access_request(request_id)
);

drop policy if exists price_quote_line_items_select_scoped on public.price_quote_line_items;
create policy price_quote_line_items_select_scoped on public.price_quote_line_items
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1
    from public.price_quotes q
    where q.id = quote_id
      and public.can_access_request(q.request_id)
  )
);

drop policy if exists price_quote_line_items_insert_scoped on public.price_quote_line_items;
create policy price_quote_line_items_insert_scoped on public.price_quote_line_items
for insert to authenticated
with check (
  public.is_platform_admin()
  or exists (
    select 1
    from public.price_quotes q
    where q.id = quote_id
      and (
        public.has_role(
          q.organization_id,
          array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
        )
        or (
          q.provider_organization_id is not null
          and public.has_role(q.provider_organization_id, array['provider_admin']::public.app_role[])
        )
      )
  )
);

drop policy if exists pricing_locks_select_scoped on public.pricing_locks;
create policy pricing_locks_select_scoped on public.pricing_locks
for select to authenticated
using (public.is_platform_admin() or public.can_access_request(request_id));

drop policy if exists pricing_locks_insert_scoped on public.pricing_locks;
create policy pricing_locks_insert_scoped on public.pricing_locks
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    (
      select r.organization_id
      from public.inspection_requests r
      where r.id = request_id
    ),
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
  or exists (
    select 1
    from public.price_quotes q
    where q.id = quote_id
      and q.provider_organization_id is not null
      and public.has_role(q.provider_organization_id, array['provider_admin']::public.app_role[])
  )
);

drop policy if exists pricing_locks_update_scoped on public.pricing_locks;
create policy pricing_locks_update_scoped on public.pricing_locks
for update to authenticated
using (public.is_platform_admin() or public.can_access_request(request_id))
with check (public.is_platform_admin() or public.can_access_request(request_id));

drop policy if exists pricing_adjustments_select_scoped on public.pricing_adjustments;
create policy pricing_adjustments_select_scoped on public.pricing_adjustments
for select to authenticated
using (public.is_platform_admin() or public.can_access_request(request_id));

drop policy if exists pricing_adjustments_insert_scoped on public.pricing_adjustments;
create policy pricing_adjustments_insert_scoped on public.pricing_adjustments
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    (
      select r.organization_id
      from public.inspection_requests r
      where r.id = request_id
    ),
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
);

drop policy if exists settlement_ledgers_select_scoped on public.settlement_ledgers;
create policy settlement_ledgers_select_scoped on public.settlement_ledgers
for select to authenticated
using (public.is_platform_admin() or public.can_access_request(request_id));

drop policy if exists settlement_ledgers_write_scoped on public.settlement_ledgers;
create policy settlement_ledgers_write_scoped on public.settlement_ledgers
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    (
      select r.organization_id
      from public.inspection_requests r
      where r.id = request_id
    ),
    array['dutyholder_admin', 'procurement']::public.app_role[]
  )
)
with check (
  public.is_platform_admin()
  or public.has_role(
    (
      select r.organization_id
      from public.inspection_requests r
      where r.id = request_id
    ),
    array['dutyholder_admin', 'procurement']::public.app_role[]
  )
);

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.price_quotes;
    exception
      when duplicate_object then null;
    end;

    begin
      alter publication supabase_realtime add table public.pricing_locks;
    exception
      when duplicate_object then null;
    end;

    begin
      alter publication supabase_realtime add table public.pricing_adjustments;
    exception
      when duplicate_object then null;
    end;

    begin
      alter publication supabase_realtime add table public.settlement_ledgers;
    exception
      when duplicate_object then null;
    end;
  end if;
end $$;

grant execute on function public.create_price_quote(
  uuid,
  uuid,
  uuid,
  uuid,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  numeric,
  char,
  timestamptz,
  jsonb,
  jsonb,
  jsonb
) to authenticated;

grant execute on function public.lock_price_quote(uuid, text, text) to authenticated;
grant execute on function public.apply_price_adjustment(
  uuid,
  public.pricing_adjustment_type,
  text,
  numeric,
  text
) to authenticated;
grant execute on function public.upsert_settlement_ledger_for_request(
  uuid,
  public.settlement_status,
  text
) to authenticated;
