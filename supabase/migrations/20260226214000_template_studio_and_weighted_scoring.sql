-- 2026-02-26: Template studio with versioning, conditional logic, and weighted scoring

-- Enums

do $$
begin
  if not exists (select 1 from pg_type where typname = 'template_visibility') then
    create type public.template_visibility as enum (
      'private',
      'organization',
      'marketplace',
      'platform'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'template_release_status') then
    create type public.template_release_status as enum (
      'draft',
      'in_review',
      'published',
      'archived'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'template_control_type') then
    create type public.template_control_type as enum (
      'boolean',
      'choice_single',
      'choice_multi',
      'numeric',
      'text',
      'date',
      'photo',
      'evidence_file'
    );
  end if;
end $$;

create table if not exists public."InCert-inspection_template_definitions" (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  regime public.asset_regime not null,
  name text not null,
  description text,
  visibility public.template_visibility not null default 'organization',
  is_bespoke boolean not null default false,
  marketplace_listed boolean not null default false,
  current_version_id uuid,
  tags text[] not null default '{}'::text[],
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, regime, name)
);

create table if not exists public."InCert-inspection_template_versions" (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public."InCert-inspection_template_definitions"(id) on delete cascade,
  version_number integer not null check (version_number > 0),
  status public.template_release_status not null default 'draft',
  pass_score numeric(6, 2),
  max_score numeric(8, 2),
  scoring_model jsonb not null default '{}'::jsonb,
  page_size integer not null default 10 check (page_size between 1 and 100),
  release_notes text,
  published_at timestamptz,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (template_id, version_number)
);

create table if not exists public."InCert-inspection_template_sections" (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references public."InCert-inspection_template_versions"(id) on delete cascade,
  section_key text not null,
  title text not null,
  description text,
  display_order integer not null default 1,
  page_number integer,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (version_id, section_key)
);

create table if not exists public."InCert-inspection_template_controls" (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references public."InCert-inspection_template_versions"(id) on delete cascade,
  section_id uuid references public."InCert-inspection_template_sections"(id) on delete set null,
  control_key text not null,
  prompt text not null,
  guidance text,
  control_type public.template_control_type not null default 'boolean',
  is_required boolean not null default true,
  evidence_required boolean not null default false,
  critical_fail boolean not null default false,
  weight numeric(8, 3) not null default 1 check (weight >= 0),
  response_options jsonb not null default '[]'::jsonb,
  pass_rule jsonb not null default '{}'::jsonb,
  display_order integer not null default 1,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (version_id, control_key)
);

create table if not exists public."InCert-inspection_template_conditions" (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references public."InCert-inspection_template_versions"(id) on delete cascade,
  source_control_id uuid not null references public."InCert-inspection_template_controls"(id) on delete cascade,
  operator text not null,
  operand jsonb not null,
  target_control_id uuid not null references public."InCert-inspection_template_controls"(id) on delete cascade,
  effect text not null,
  effect_value jsonb,
  priority integer not null default 100,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint template_conditions_effect check (effect in ('show', 'hide', 'require', 'optional', 'set_weight'))
);

create table if not exists public."InCert-inspection_template_scoring_bands" (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references public."InCert-inspection_template_versions"(id) on delete cascade,
  min_score numeric(8, 2) not null,
  max_score numeric(8, 2) not null,
  label text not null,
  outcome text,
  display_order integer not null default 1,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint template_scoring_band_window check (max_score >= min_score)
);

create table if not exists public."InCert-inspection_template_publish_events" (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public."InCert-inspection_template_definitions"(id) on delete cascade,
  version_id uuid not null references public."InCert-inspection_template_versions"(id) on delete cascade,
  event_type text not null,
  event_at timestamptz not null default now(),
  actor_user_id uuid references auth.users(id) on delete set null,
  notes text,
  metadata jsonb not null default '{}'::jsonb
);

-- Back-link FK for current_version_id after version table exists

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'InCert-inspection_template_definitions'
      and constraint_name = 'inspection_template_definitions_current_version_fkey'
  ) then
    alter table public."InCert-inspection_template_definitions"
      add constraint inspection_template_definitions_current_version_fkey
      foreign key (current_version_id) references public."InCert-inspection_template_versions"(id)
      on delete set null;
  end if;
end $$;

create index if not exists idx_template_definitions_org_regime on public."InCert-inspection_template_definitions"(organization_id, regime, updated_at desc);
create index if not exists idx_template_versions_template_status on public."InCert-inspection_template_versions"(template_id, status, version_number desc);
create index if not exists idx_template_controls_version_order on public."InCert-inspection_template_controls"(version_id, display_order);
create index if not exists idx_template_conditions_version_priority on public."InCert-inspection_template_conditions"(version_id, priority);
create index if not exists idx_template_scoring_bands_version_order on public."InCert-inspection_template_scoring_bands"(version_id, display_order);

create or replace function public.publish_inspection_template_version(
  p_version_id uuid,
  p_release_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_version public."InCert-inspection_template_versions"%rowtype;
  v_template public."InCert-inspection_template_definitions"%rowtype;
begin
  select * into v_version from public."InCert-inspection_template_versions" where id = p_version_id;
  if not found then
    raise exception 'Template version % not found', p_version_id;
  end if;

  select * into v_template from public."InCert-inspection_template_definitions" where id = v_version.template_id;

  if not (
    public.is_platform_admin()
    or public.has_role(v_template.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  ) then
    raise exception 'Not permitted to publish template version %', p_version_id;
  end if;

  update public."InCert-inspection_template_versions"
  set status = 'archived', archived_at = now(), updated_at = now()
  where template_id = v_version.template_id
    and status = 'published'
    and id <> p_version_id;

  update public."InCert-inspection_template_versions"
  set status = 'published',
      published_at = now(),
      archived_at = null,
      release_notes = coalesce(p_release_notes, release_notes),
      updated_at = now()
  where id = p_version_id;

  update public."InCert-inspection_template_definitions"
  set current_version_id = p_version_id,
      updated_at = now()
  where id = v_version.template_id;

  insert into public."InCert-inspection_template_publish_events" (
    template_id,
    version_id,
    event_type,
    actor_user_id,
    notes,
    metadata
  ) values (
    v_version.template_id,
    p_version_id,
    'published',
    auth.uid(),
    p_release_notes,
    jsonb_build_object('source', 'publish_inspection_template_version_rpc')
  );

  perform public.write_audit_log(
    v_template.organization_id,
    'template.version_published',
    'template',
    v_version.template_id,
    jsonb_build_object('version_id', p_version_id, 'version_number', v_version.version_number)
  );

  return p_version_id;
end;
$$;

-- Updated-at triggers

drop trigger if exists trg_inspection_template_definitions_updated_at on public."InCert-inspection_template_definitions";
create trigger trg_inspection_template_definitions_updated_at
before update on public."InCert-inspection_template_definitions"
for each row execute function public.set_updated_at();

drop trigger if exists trg_inspection_template_versions_updated_at on public."InCert-inspection_template_versions";
create trigger trg_inspection_template_versions_updated_at
before update on public."InCert-inspection_template_versions"
for each row execute function public.set_updated_at();

drop trigger if exists trg_inspection_template_sections_updated_at on public."InCert-inspection_template_sections";
create trigger trg_inspection_template_sections_updated_at
before update on public."InCert-inspection_template_sections"
for each row execute function public.set_updated_at();

drop trigger if exists trg_inspection_template_controls_updated_at on public."InCert-inspection_template_controls";
create trigger trg_inspection_template_controls_updated_at
before update on public."InCert-inspection_template_controls"
for each row execute function public.set_updated_at();

drop trigger if exists trg_inspection_template_conditions_updated_at on public."InCert-inspection_template_conditions";
create trigger trg_inspection_template_conditions_updated_at
before update on public."InCert-inspection_template_conditions"
for each row execute function public.set_updated_at();

drop trigger if exists trg_inspection_template_scoring_bands_updated_at on public."InCert-inspection_template_scoring_bands";
create trigger trg_inspection_template_scoring_bands_updated_at
before update on public."InCert-inspection_template_scoring_bands"
for each row execute function public.set_updated_at();

-- RLS

alter table public."InCert-inspection_template_definitions" enable row level security;
alter table public."InCert-inspection_template_versions" enable row level security;
alter table public."InCert-inspection_template_sections" enable row level security;
alter table public."InCert-inspection_template_controls" enable row level security;
alter table public."InCert-inspection_template_conditions" enable row level security;
alter table public."InCert-inspection_template_scoring_bands" enable row level security;
alter table public."InCert-inspection_template_publish_events" enable row level security;

drop policy if exists template_definitions_select_scoped on public."InCert-inspection_template_definitions";
create policy template_definitions_select_scoped on public."InCert-inspection_template_definitions"
for select to authenticated
using (
  public.is_platform_admin()
  or public.is_member(organization_id)
  or visibility in ('marketplace', 'platform')
);

drop policy if exists template_definitions_write_scoped on public."InCert-inspection_template_definitions";
create policy template_definitions_write_scoped on public."InCert-inspection_template_definitions"
for all to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
);

drop policy if exists template_versions_select_scoped on public."InCert-inspection_template_versions";
create policy template_versions_select_scoped on public."InCert-inspection_template_versions"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-inspection_template_definitions" d
    where d.id = template_id
      and (public.is_member(d.organization_id) or d.visibility in ('marketplace', 'platform'))
  )
);

drop policy if exists template_versions_write_scoped on public."InCert-inspection_template_versions";
create policy template_versions_write_scoped on public."InCert-inspection_template_versions"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-inspection_template_definitions" d
    where d.id = template_id
      and public.has_role(d.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-inspection_template_definitions" d
    where d.id = template_id
      and public.has_role(d.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
);

drop policy if exists template_sections_select_scoped on public."InCert-inspection_template_sections";
create policy template_sections_select_scoped on public."InCert-inspection_template_sections"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and (public.is_member(d.organization_id) or d.visibility in ('marketplace', 'platform'))
  )
);

drop policy if exists template_sections_write_scoped on public."InCert-inspection_template_sections";
create policy template_sections_write_scoped on public."InCert-inspection_template_sections"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and public.has_role(d.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and public.has_role(d.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
);

drop policy if exists template_controls_select_scoped on public."InCert-inspection_template_controls";
create policy template_controls_select_scoped on public."InCert-inspection_template_controls"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and (public.is_member(d.organization_id) or d.visibility in ('marketplace', 'platform'))
  )
);

drop policy if exists template_controls_write_scoped on public."InCert-inspection_template_controls";
create policy template_controls_write_scoped on public."InCert-inspection_template_controls"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and public.has_role(d.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and public.has_role(d.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
);

drop policy if exists template_conditions_select_scoped on public."InCert-inspection_template_conditions";
create policy template_conditions_select_scoped on public."InCert-inspection_template_conditions"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and (public.is_member(d.organization_id) or d.visibility in ('marketplace', 'platform'))
  )
);

drop policy if exists template_conditions_write_scoped on public."InCert-inspection_template_conditions";
create policy template_conditions_write_scoped on public."InCert-inspection_template_conditions"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and public.has_role(d.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and public.has_role(d.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
);

drop policy if exists template_scoring_bands_select_scoped on public."InCert-inspection_template_scoring_bands";
create policy template_scoring_bands_select_scoped on public."InCert-inspection_template_scoring_bands"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and (public.is_member(d.organization_id) or d.visibility in ('marketplace', 'platform'))
  )
);

drop policy if exists template_scoring_bands_write_scoped on public."InCert-inspection_template_scoring_bands";
create policy template_scoring_bands_write_scoped on public."InCert-inspection_template_scoring_bands"
for all to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and public.has_role(d.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
)
with check (
  public.is_platform_admin()
  or exists (
    select 1
    from public."InCert-inspection_template_versions" v
    join public."InCert-inspection_template_definitions" d on d.id = v.template_id
    where v.id = version_id
      and public.has_role(d.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
);

drop policy if exists template_publish_events_select_scoped on public."InCert-inspection_template_publish_events";
create policy template_publish_events_select_scoped on public."InCert-inspection_template_publish_events"
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-inspection_template_definitions" d
    where d.id = template_id and public.is_member(d.organization_id)
  )
);

drop policy if exists template_publish_events_insert_scoped on public."InCert-inspection_template_publish_events";
create policy template_publish_events_insert_scoped on public."InCert-inspection_template_publish_events"
for insert to authenticated
with check (
  public.is_platform_admin()
  or exists (
    select 1 from public."InCert-inspection_template_definitions" d
    where d.id = template_id and public.has_role(d.organization_id, array['provider_admin', 'dutyholder_admin']::public.app_role[])
  )
);

-- Realtime publication

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public."InCert-inspection_template_definitions";
    exception when duplicate_object then null; end;

    begin
      alter publication supabase_realtime add table public."InCert-inspection_template_versions";
    exception when duplicate_object then null; end;
  end if;
end $$;

grant execute on function public.publish_inspection_template_version(uuid, text) to authenticated;
