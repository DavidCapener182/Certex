-- Expand supported audit regimes so new template catalog entries can be persisted.
do $$
begin
  if exists (select 1 from pg_type where typname = 'asset_regime') then
    alter type public.asset_regime add value if not exists 'HS';
    alter type public.asset_regime add value if not exists 'FRA';
    alter type public.asset_regime add value if not exists 'COSHH';
    alter type public.asset_regime add value if not exists 'ASBESTOS';
    alter type public.asset_regime add value if not exists 'LEGIONELLA';
    alter type public.asset_regime add value if not exists 'ELECTRICAL';
    alter type public.asset_regime add value if not exists 'SCAFFOLD';
    alter type public.asset_regime add value if not exists 'FOOD';
    alter type public.asset_regime add value if not exists 'WORKPLACE';
    alter type public.asset_regime add value if not exists 'SUPPLEMENTAL';
    alter type public.asset_regime add value if not exists 'MACHINE';
    alter type public.asset_regime add value if not exists 'FIRE_DOOR';
    alter type public.asset_regime add value if not exists 'RETAIL';
    alter type public.asset_regime add value if not exists 'HOSPITALITY';
    alter type public.asset_regime add value if not exists 'WAREHOUSE';
    alter type public.asset_regime add value if not exists 'CONSTRUCTION';
    alter type public.asset_regime add value if not exists 'EDUCATION';
    alter type public.asset_regime add value if not exists 'HEALTHCARE';
    alter type public.asset_regime add value if not exists 'MYSTERY';
    alter type public.asset_regime add value if not exists 'PEN_TEST';
  end if;
end $$;
