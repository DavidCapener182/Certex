-- 2026-02-22: Enforce take-rate minimums (30% standard, 40% expedite floor) and going-rate defaults

-- Provider rate cards: default and floor
alter table public.provider_rate_cards
  alter column platform_fee_pct set default 0.45;

update public.provider_rate_cards
set platform_fee_pct = greatest(0.30, least(1, coalesce(platform_fee_pct, 0.45)))
where platform_fee_pct is null
  or platform_fee_pct < 0.30
  or platform_fee_pct > 1;

alter table public.provider_rate_cards
  drop constraint if exists provider_rate_cards_platform_fee_pct_check;

alter table public.provider_rate_cards
  drop constraint if exists provider_rate_cards_platform_fee_pct_range;

alter table public.provider_rate_cards
  add constraint provider_rate_cards_platform_fee_pct_range
  check (platform_fee_pct >= 0.30 and platform_fee_pct <= 1);

-- Marketplace quote RPC: higher default take-rate, with minimum floor by urgency
create or replace function public.calculate_marketplace_quote(
  p_regime public.asset_regime,
  p_site_region text,
  p_estimated_hours numeric,
  p_access_complexity public.marketplace_access_complexity,
  p_travel_km numeric default 0,
  p_equipment_profile text default 'none',
  p_expedite boolean default false,
  p_platform_fee_pct numeric default 0.45
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
  v_min_take_rate numeric;
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

  v_min_take_rate := case when coalesce(p_expedite, false) then 0.40 else 0.30 end;
  v_subtotal := labour + travel + equipment + expedite;
  platform_fee := round(v_subtotal * greatest(v_min_take_rate, least(1, coalesce(p_platform_fee_pct, 0.45))), 2);
  total := round(v_subtotal + platform_fee, 2);

  return next;
end;
$$;

-- Quote table defaults and floor
alter table public.price_quotes
  alter column effective_take_rate set default 0.45;

update public.price_quotes
set effective_take_rate = greatest(0.30, least(1, coalesce(effective_take_rate, 0.45)))
where effective_take_rate is null
  or effective_take_rate < 0.30
  or effective_take_rate > 1;

alter table public.price_quotes
  drop constraint if exists price_quotes_effective_take_rate_check;

alter table public.price_quotes
  drop constraint if exists price_quotes_effective_take_rate_range;

alter table public.price_quotes
  add constraint price_quotes_effective_take_rate_range
  check (effective_take_rate >= 0.30 and effective_take_rate <= 1);

-- Quote creation RPC: default and floor
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
  p_effective_take_rate numeric default 0.45,
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
    greatest(0.30, least(1, coalesce(p_effective_take_rate, 0.45))),
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

-- Adjustment RPC: keep stored take-rate, but never below floor
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
      round((
        v_subtotal_ex_vat
        * greatest(0.30, least(1, coalesce(v_last_quote.effective_take_rate, 0.45)))
      )::numeric, 2)
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
    greatest(0.30, least(1, coalesce(v_last_quote.effective_take_rate, 0.45))),
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
