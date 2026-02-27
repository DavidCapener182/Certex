-- 2026-02-26: Shared DB compatibility preflight for InCert extension migrations.
-- This migration is intentionally defensive: it only creates/patches prerequisites
-- required by the 20260226213xxx-20260226222xxx migration pack.

create extension if not exists pgcrypto;
create extension if not exists citext;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum (
      'platform_admin',
      'dutyholder_admin',
      'site_manager',
      'procurement',
      'provider_admin',
      'inspector',
      'auditor_viewer',
      'insurer_viewer',
      'landlord_viewer'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'asset_regime') then
    create type public.asset_regime as enum ('LOLER', 'PUWER', 'PSSR');
  end if;
end $$;

-- Core tenancy table
create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text,
  slug citext,
  org_type text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.organizations
  add column if not exists name text,
  add column if not exists slug citext,
  add column if not exists org_type text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

-- Membership table used by helper functions and policies.
create table if not exists public.organization_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  user_id uuid,
  role text,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

alter table if exists public.organization_memberships
  add column if not exists organization_id uuid,
  add column if not exists user_id uuid,
  add column if not exists role text,
  add column if not exists is_default boolean default false,
  add column if not exists created_at timestamptz default now();

-- Baseline business tables referenced by extension migrations and RPCs.
create table if not exists public.inspection_requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  title text,
  status text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.inspection_requests
  add column if not exists organization_id uuid,
  add column if not exists title text,
  add column if not exists status text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create table if not exists public.inspection_jobs (
  id uuid primary key default gen_random_uuid(),
  request_id uuid,
  provider_organization_id uuid,
  status text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.inspection_jobs
  add column if not exists request_id uuid,
  add column if not exists provider_organization_id uuid,
  add column if not exists status text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create table if not exists public.marketplace_dispatch_attempts (
  id uuid primary key default gen_random_uuid(),
  request_id uuid,
  provider_organization_id uuid,
  status text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.marketplace_dispatch_attempts
  add column if not exists request_id uuid,
  add column if not exists provider_organization_id uuid,
  add column if not exists status text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create table if not exists public.marketplace_requests (
  request_id uuid primary key,
  accepted_provider_organization_id uuid,
  accepted_at timestamptz,
  updated_at timestamptz
);

alter table if exists public.marketplace_requests
  add column if not exists accepted_provider_organization_id uuid,
  add column if not exists accepted_at timestamptz,
  add column if not exists updated_at timestamptz;

create table if not exists public.assets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  next_due_date date,
  status text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.assets
  add column if not exists organization_id uuid,
  add column if not exists next_due_date date,
  add column if not exists status text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create table if not exists public.certificates (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  created_at timestamptz not null default now()
);

alter table if exists public.certificates
  add column if not exists organization_id uuid,
  add column if not exists created_at timestamptz default now();

create table if not exists public.evidence_files (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  certificate_id uuid,
  created_at timestamptz not null default now()
);

alter table if exists public.evidence_files
  add column if not exists organization_id uuid,
  add column if not exists certificate_id uuid,
  add column if not exists created_at timestamptz default now();

create table if not exists public.inspection_findings (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid,
  job_id uuid,
  created_at timestamptz not null default now()
);

alter table if exists public.inspection_findings
  add column if not exists asset_id uuid,
  add column if not exists job_id uuid,
  add column if not exists created_at timestamptz default now();

create table if not exists public.price_quotes (
  id uuid primary key default gen_random_uuid(),
  request_id uuid,
  status text,
  subtotal_ex_vat numeric(12, 2) not null default 0,
  vat_amount numeric(12, 2) not null default 0,
  total_inc_vat numeric(12, 2) not null default 0,
  currency_code text not null default 'GBP',
  created_at timestamptz not null default now()
);

alter table if exists public.price_quotes
  add column if not exists request_id uuid,
  add column if not exists status text,
  add column if not exists subtotal_ex_vat numeric(12, 2) default 0,
  add column if not exists vat_amount numeric(12, 2) default 0,
  add column if not exists total_inc_vat numeric(12, 2) default 0,
  add column if not exists currency_code text default 'GBP',
  add column if not exists created_at timestamptz default now();

create table if not exists public.settlement_ledgers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid,
  created_at timestamptz not null default now()
);

alter table if exists public.settlement_ledgers
  add column if not exists request_id uuid,
  add column if not exists created_at timestamptz default now();

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  actor_user_id uuid,
  actor_role text,
  action text,
  resource_type text,
  resource_id uuid,
  ip_address inet,
  user_agent text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table if exists public.audit_logs
  add column if not exists organization_id uuid,
  add column if not exists actor_user_id uuid,
  add column if not exists actor_role text,
  add column if not exists action text,
  add column if not exists resource_type text,
  add column if not exists resource_id uuid,
  add column if not exists ip_address inet,
  add column if not exists user_agent text,
  add column if not exists metadata jsonb default '{}'::jsonb,
  add column if not exists created_at timestamptz default now();

-- Helper functions expected by later migrations.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create or replace function public.current_user_id()
returns uuid
language sql
stable
as $$
  select auth.uid();
$$;

create or replace function public.is_member(p_organization_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_result boolean := false;
begin
  if auth.uid() is null or p_organization_id is null then
    return false;
  end if;

  begin
    execute
      'select exists (
         select 1
         from public.organization_memberships
         where organization_id = $1
           and user_id = $2
       )'
      into v_result
      using p_organization_id, auth.uid();
  exception
    when undefined_table or undefined_column then
      v_result := false;
  end;

  return coalesce(v_result, false);
end;
$$;

create or replace function public.has_role(p_organization_id uuid, p_roles public.app_role[])
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_result boolean := false;
  v_roles text[];
begin
  if auth.uid() is null or p_organization_id is null or p_roles is null or array_length(p_roles, 1) is null then
    return false;
  end if;

  select coalesce(array_agg(role_name), array[]::text[])
  into v_roles
  from (
    select unnest(p_roles)::text as role_name
  ) roles;

  begin
    execute
      'select exists (
         select 1
         from public.organization_memberships
         where organization_id = $1
           and user_id = $2
           and role::text = any($3)
       )'
      into v_result
      using p_organization_id, auth.uid(), v_roles;
  exception
    when undefined_table or undefined_column then
      v_result := false;
  end;

  return coalesce(v_result, false);
end;
$$;

create or replace function public.is_platform_admin()
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_result boolean := false;
begin
  if auth.uid() is null then
    return false;
  end if;

  begin
    execute
      'select exists (
         select 1
         from public.organization_memberships
         where user_id = $1
           and role::text = ''platform_admin''
       )'
      into v_result
      using auth.uid();
  exception
    when undefined_table or undefined_column then
      v_result := false;
  end;

  return coalesce(v_result, false);
end;
$$;

create or replace function public.can_access_request(p_request_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
begin
  if p_request_id is null then
    return false;
  end if;

  if public.is_platform_admin() then
    return true;
  end if;

  begin
    execute
      'select organization_id
       from public.inspection_requests
       where id = $1
       limit 1'
      into v_organization_id
      using p_request_id;
  exception
    when undefined_table or undefined_column then
      return false;
  end;

  return public.is_member(v_organization_id);
end;
$$;

create or replace function public.can_access_job(p_job_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_request_id uuid;
  v_provider_organization_id uuid;
begin
  if p_job_id is null then
    return false;
  end if;

  if public.is_platform_admin() then
    return true;
  end if;

  begin
    execute
      'select request_id, provider_organization_id
       from public.inspection_jobs
       where id = $1
       limit 1'
      into v_request_id, v_provider_organization_id
      using p_job_id;
  exception
    when undefined_table or undefined_column then
      return false;
  end;

  if v_request_id is not null and public.can_access_request(v_request_id) then
    return true;
  end if;

  return public.is_member(v_provider_organization_id);
end;
$$;

create or replace function public.write_audit_log(
  p_organization_id uuid,
  p_action text,
  p_resource_type text,
  p_resource_id uuid default null,
  p_metadata jsonb default '{}'::jsonb,
  p_ip_address inet default null,
  p_user_agent text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_log_id uuid := gen_random_uuid();
  v_actor_role text := null;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  if p_organization_id is not null and not (public.is_platform_admin() or public.is_member(p_organization_id)) then
    raise exception 'Not authorized for organization %', p_organization_id;
  end if;

  begin
    execute
      'select m.role::text
       from public.organization_memberships m
       where m.organization_id = $1
         and m.user_id = $2
       order by m.created_at asc
       limit 1'
      into v_actor_role
      using p_organization_id, auth.uid();
  exception
    when undefined_table or undefined_column then
      v_actor_role := null;
  end;

  begin
    execute
      'insert into public.audit_logs (
         organization_id,
         actor_user_id,
         actor_role,
         action,
         resource_type,
         resource_id,
         ip_address,
         user_agent,
         metadata
       )
       values ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       returning id'
      into v_log_id
      using
        p_organization_id,
        auth.uid(),
        v_actor_role,
        p_action,
        p_resource_type,
        p_resource_id,
        p_ip_address,
        p_user_agent,
        coalesce(p_metadata, '{}'::jsonb);
  exception
    when undefined_table or undefined_column then
      -- Shared DB may have a different audit table shape; no-op but return a stable id.
      v_log_id := coalesce(v_log_id, gen_random_uuid());
  end;

  return v_log_id;
end;
$$;

grant execute on function public.current_user_id() to authenticated;
grant execute on function public.is_member(uuid) to authenticated;
grant execute on function public.has_role(uuid, public.app_role[]) to authenticated;
grant execute on function public.is_platform_admin() to authenticated;
grant execute on function public.can_access_request(uuid) to authenticated;
grant execute on function public.can_access_job(uuid) to authenticated;
grant execute on function public.write_audit_log(uuid, text, text, uuid, jsonb, inet, text) to authenticated;
