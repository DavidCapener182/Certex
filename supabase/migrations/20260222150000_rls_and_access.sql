-- 2026-02-22: RBAC and RLS policies
-- This migration enforces tenant boundaries and role-scoped access.

create or replace function public.current_user_id()
returns uuid
language sql
stable
as $$
  select auth.uid();
$$;

create or replace function public.is_member(p_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.organization_memberships m
    where m.organization_id = p_organization_id
      and m.user_id = auth.uid()
  );
$$;

create or replace function public.has_role(p_organization_id uuid, p_roles public.app_role[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.organization_memberships m
    where m.organization_id = p_organization_id
      and m.user_id = auth.uid()
      and m.role = any(p_roles)
  );
$$;

create or replace function public.is_platform_admin()
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'organizations' and column_name = 'org_type') then
    return false;
  end if;
  return exists (
    select 1
    from public.organization_memberships m
    join public.organizations o on o.id = m.organization_id
    where m.user_id = auth.uid()
      and m.role = 'platform_admin'
      and o.org_type = 'platform'
  );
end;
$$;

create or replace function public.can_access_request(p_request_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.inspection_requests r
    where r.id = p_request_id
      and (
        public.is_member(r.organization_id)
        or exists (
          select 1
          from public.job_offers o
          where o.request_id = r.id
            and public.is_member(o.provider_organization_id)
        )
        or exists (
          select 1
          from public.inspection_jobs j
          where j.request_id = r.id
            and public.is_member(j.provider_organization_id)
        )
      )
  );
$$;

create or replace function public.can_access_job(p_job_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.inspection_jobs j
    join public.inspection_requests r on r.id = j.request_id
    where j.id = p_job_id
      and (
        public.is_member(r.organization_id)
        or public.is_member(j.provider_organization_id)
      )
  );
$$;

create or replace function public.can_access_asset(p_asset_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'assets' and column_name = 'organization_id') then
    return false;
  end if;
  return exists (
    select 1
    from public.assets a
    where a.id = p_asset_id
      and (
        public.is_member(a.organization_id)
        or exists (
          select 1
          from public.inspection_job_assets ja
          join public.inspection_jobs j on j.id = ja.job_id
          where ja.asset_id = a.id
            and public.is_member(j.provider_organization_id)
        )
      )
  );
end;
$$;

create or replace function public.can_access_certificate(p_certificate_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.certificates c
    where c.id = p_certificate_id
      and (
        public.is_member(c.operator_organization_id)
        or public.is_member(c.provider_organization_id)
      )
  );
$$;

alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.organization_memberships enable row level security;
alter table public.sites enable row level security;
alter table public.assets enable row level security;
alter table public.inspection_requests enable row level security;
alter table public.inspection_request_assets enable row level security;
alter table public.job_offers enable row level security;
alter table public.inspection_jobs enable row level security;
alter table public.inspection_job_assets enable row level security;
alter table public.inspection_findings enable row level security;
alter table public.certificates enable row level security;
alter table public.certificate_signatures enable row level security;
alter table public.evidence_files enable row level security;
alter table public.provider_credentials enable row level security;
alter table public.share_links enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;
alter table public.offline_sync_batches enable row level security;
alter table public.offline_sync_items enable row level security;
alter table public.compliance_snapshots enable row level security;

-- profiles
drop policy if exists profiles_select_self on public.profiles;
create policy profiles_select_self on public.profiles
for select to authenticated
using (id = auth.uid() or public.is_platform_admin());

drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles
for insert to authenticated
with check (id = auth.uid() or public.is_platform_admin());

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
for update to authenticated
using (id = auth.uid() or public.is_platform_admin())
with check (id = auth.uid() or public.is_platform_admin());

-- organizations
drop policy if exists organizations_select_members on public.organizations;
create policy organizations_select_members on public.organizations
for select to authenticated
using (public.is_member(id) or public.is_platform_admin());

drop policy if exists organizations_insert_platform on public.organizations;
create policy organizations_insert_platform on public.organizations
for insert to authenticated
with check (public.is_platform_admin());

drop policy if exists organizations_update_admins on public.organizations;
create policy organizations_update_admins on public.organizations
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

drop policy if exists organizations_delete_platform on public.organizations;
create policy organizations_delete_platform on public.organizations
for delete to authenticated
using (public.is_platform_admin());

-- memberships
drop policy if exists memberships_select_scoped on public.organization_memberships;
create policy memberships_select_scoped on public.organization_memberships
for select to authenticated
using (
  public.is_platform_admin()
  or user_id = auth.uid()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

drop policy if exists memberships_insert_admin on public.organization_memberships;
create policy memberships_insert_admin on public.organization_memberships
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

drop policy if exists memberships_update_admin on public.organization_memberships;
create policy memberships_update_admin on public.organization_memberships
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

drop policy if exists memberships_delete_admin on public.organization_memberships;
create policy memberships_delete_admin on public.organization_memberships
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

-- sites
drop policy if exists sites_select_members on public.sites;
create policy sites_select_members on public.sites
for select to authenticated
using (public.is_member(organization_id) or public.is_platform_admin());

drop policy if exists sites_insert_operator_admin on public.sites;
create policy sites_insert_operator_admin on public.sites
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager']::public.app_role[])
);

drop policy if exists sites_update_operator_admin on public.sites;
create policy sites_update_operator_admin on public.sites
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager']::public.app_role[])
);

drop policy if exists sites_delete_operator_admin on public.sites;
create policy sites_delete_operator_admin on public.sites
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager']::public.app_role[])
);

-- assets (only if assets has organization_id)
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'assets' and column_name = 'organization_id') then
    drop policy if exists assets_select_scoped on public.assets;
    create policy assets_select_scoped on public.assets
    for select to authenticated
    using (public.can_access_asset(id) or public.is_platform_admin());

    drop policy if exists assets_insert_operator_roles on public.assets;
    create policy assets_insert_operator_roles on public.assets
    for insert to authenticated
    with check (
      public.is_platform_admin()
      or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[])
    );

    drop policy if exists assets_update_operator_roles on public.assets;
    create policy assets_update_operator_roles on public.assets
    for update to authenticated
    using (
      public.is_platform_admin()
      or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[])
    )
    with check (
      public.is_platform_admin()
      or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[])
    );

    drop policy if exists assets_delete_operator_roles on public.assets;
    create policy assets_delete_operator_roles on public.assets
    for delete to authenticated
    using (
      public.is_platform_admin()
      or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[])
    );
  end if;
end $$;

-- inspection_requests
drop policy if exists inspection_requests_select_scoped on public.inspection_requests;
create policy inspection_requests_select_scoped on public.inspection_requests
for select to authenticated
using (public.can_access_request(id) or public.is_platform_admin());

drop policy if exists inspection_requests_insert_operator_roles on public.inspection_requests;
create policy inspection_requests_insert_operator_roles on public.inspection_requests
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[])
);

drop policy if exists inspection_requests_update_operator_roles on public.inspection_requests;
create policy inspection_requests_update_operator_roles on public.inspection_requests
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[])
);

drop policy if exists inspection_requests_delete_operator_roles on public.inspection_requests;
create policy inspection_requests_delete_operator_roles on public.inspection_requests
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[])
);

-- inspection_request_assets
drop policy if exists inspection_request_assets_select_scoped on public.inspection_request_assets;
create policy inspection_request_assets_select_scoped on public.inspection_request_assets
for select to authenticated
using (
  public.can_access_request(request_id)
  or public.can_access_asset(asset_id)
  or public.is_platform_admin()
);

drop policy if exists inspection_request_assets_insert_operator_roles on public.inspection_request_assets;
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'assets' and column_name = 'organization_id') then
    execute 'create policy inspection_request_assets_insert_operator_roles on public.inspection_request_assets for insert to authenticated with check (
      public.is_platform_admin()
      or (
        public.has_role(
          (select r.organization_id from public.inspection_requests r where r.id = request_id),
          array[''dutyholder_admin'', ''site_manager'', ''procurement'']::public.app_role[]
        )
        and exists (
          select 1 from public.inspection_requests r join public.assets a on a.id = asset_id
          where r.id = request_id and a.organization_id = r.organization_id
        )
      )
    )';
  end if;
end $$;

drop policy if exists inspection_request_assets_delete_operator_roles on public.inspection_request_assets;
create policy inspection_request_assets_delete_operator_roles on public.inspection_request_assets
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    (select r.organization_id from public.inspection_requests r where r.id = request_id),
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
);

-- job_offers
drop policy if exists job_offers_select_scoped on public.job_offers;
create policy job_offers_select_scoped on public.job_offers
for select to authenticated
using (public.can_access_request(request_id) or public.is_platform_admin());

drop policy if exists job_offers_insert_operator_roles on public.job_offers;
create policy job_offers_insert_operator_roles on public.job_offers
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    (select r.organization_id from public.inspection_requests r where r.id = request_id),
    array['dutyholder_admin', 'procurement']::public.app_role[]
  )
);

drop policy if exists job_offers_update_scoped on public.job_offers;
create policy job_offers_update_scoped on public.job_offers
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
  or public.has_role(
    (select r.organization_id from public.inspection_requests r where r.id = request_id),
    array['dutyholder_admin', 'procurement']::public.app_role[]
  )
)
with check (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
  or public.has_role(
    (select r.organization_id from public.inspection_requests r where r.id = request_id),
    array['dutyholder_admin', 'procurement']::public.app_role[]
  )
);

drop policy if exists job_offers_delete_operator_roles on public.job_offers;
create policy job_offers_delete_operator_roles on public.job_offers
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    (select r.organization_id from public.inspection_requests r where r.id = request_id),
    array['dutyholder_admin', 'procurement']::public.app_role[]
  )
);

-- inspection_jobs
drop policy if exists inspection_jobs_select_scoped on public.inspection_jobs;
create policy inspection_jobs_select_scoped on public.inspection_jobs
for select to authenticated
using (public.can_access_job(id) or public.is_platform_admin());

drop policy if exists inspection_jobs_insert_scoped on public.inspection_jobs;
create policy inspection_jobs_insert_scoped on public.inspection_jobs
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    (select r.organization_id from public.inspection_requests r where r.id = request_id),
    array['dutyholder_admin', 'procurement']::public.app_role[]
  )
  or public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
);

drop policy if exists inspection_jobs_update_scoped on public.inspection_jobs;
create policy inspection_jobs_update_scoped on public.inspection_jobs
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin', 'inspector']::public.app_role[])
  or public.has_role(
    (select r.organization_id from public.inspection_requests r where r.id = request_id),
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
)
with check (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin', 'inspector']::public.app_role[])
  or public.has_role(
    (select r.organization_id from public.inspection_requests r where r.id = request_id),
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
);

drop policy if exists inspection_jobs_delete_operator_roles on public.inspection_jobs;
create policy inspection_jobs_delete_operator_roles on public.inspection_jobs
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    (select r.organization_id from public.inspection_requests r where r.id = request_id),
    array['dutyholder_admin', 'procurement']::public.app_role[]
  )
);

-- inspection_job_assets
drop policy if exists inspection_job_assets_select_scoped on public.inspection_job_assets;
create policy inspection_job_assets_select_scoped on public.inspection_job_assets
for select to authenticated
using (public.can_access_job(job_id) or public.is_platform_admin());

drop policy if exists inspection_job_assets_insert_scoped on public.inspection_job_assets;
create policy inspection_job_assets_insert_scoped on public.inspection_job_assets
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    (select j.provider_organization_id from public.inspection_jobs j where j.id = job_id),
    array['provider_admin', 'inspector']::public.app_role[]
  )
  or public.has_role(
    (
      select r.organization_id
      from public.inspection_jobs j
      join public.inspection_requests r on r.id = j.request_id
      where j.id = job_id
    ),
    array['dutyholder_admin', 'site_manager', 'procurement']::public.app_role[]
  )
);

drop policy if exists inspection_job_assets_delete_scoped on public.inspection_job_assets;
create policy inspection_job_assets_delete_scoped on public.inspection_job_assets
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    (select j.provider_organization_id from public.inspection_jobs j where j.id = job_id),
    array['provider_admin']::public.app_role[]
  )
  or public.has_role(
    (
      select r.organization_id
      from public.inspection_jobs j
      join public.inspection_requests r on r.id = j.request_id
      where j.id = job_id
    ),
    array['dutyholder_admin', 'procurement']::public.app_role[]
  )
);

-- inspection_findings
drop policy if exists inspection_findings_select_scoped on public.inspection_findings;
create policy inspection_findings_select_scoped on public.inspection_findings
for select to authenticated
using (public.can_access_job(job_id) or public.is_platform_admin());

drop policy if exists inspection_findings_insert_provider_roles on public.inspection_findings;
create policy inspection_findings_insert_provider_roles on public.inspection_findings
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    (select j.provider_organization_id from public.inspection_jobs j where j.id = job_id),
    array['provider_admin', 'inspector']::public.app_role[]
  )
);

drop policy if exists inspection_findings_update_provider_roles on public.inspection_findings;
create policy inspection_findings_update_provider_roles on public.inspection_findings
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    (select j.provider_organization_id from public.inspection_jobs j where j.id = job_id),
    array['provider_admin', 'inspector']::public.app_role[]
  )
)
with check (
  public.is_platform_admin()
  or public.has_role(
    (select j.provider_organization_id from public.inspection_jobs j where j.id = job_id),
    array['provider_admin', 'inspector']::public.app_role[]
  )
);

drop policy if exists inspection_findings_delete_provider_roles on public.inspection_findings;
create policy inspection_findings_delete_provider_roles on public.inspection_findings
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    (select j.provider_organization_id from public.inspection_jobs j where j.id = job_id),
    array['provider_admin']::public.app_role[]
  )
);

-- certificates
drop policy if exists certificates_select_scoped on public.certificates;
create policy certificates_select_scoped on public.certificates
for select to authenticated
using (public.can_access_certificate(id) or public.is_platform_admin());

drop policy if exists certificates_insert_provider_roles on public.certificates;
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'assets' and column_name = 'organization_id') then
    execute 'create policy certificates_insert_provider_roles on public.certificates for insert to authenticated with check (
      public.is_platform_admin()
      or (
        public.has_role(provider_organization_id, array[''provider_admin'', ''inspector'']::public.app_role[])
        and exists (select 1 from public.inspection_jobs j where j.id = job_id and j.provider_organization_id = provider_organization_id)
        and exists (select 1 from public.assets a where a.id = asset_id and a.organization_id = operator_organization_id)
      )
    )';
  end if;
end $$;

drop policy if exists certificates_update_scoped on public.certificates;
create policy certificates_update_scoped on public.certificates
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
  or public.has_role(operator_organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(provider_organization_id, array['provider_admin']::public.app_role[])
  or public.has_role(operator_organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
);

drop policy if exists certificates_delete_platform on public.certificates;
create policy certificates_delete_platform on public.certificates
for delete to authenticated
using (public.is_platform_admin());

-- certificate_signatures
drop policy if exists certificate_signatures_select_scoped on public.certificate_signatures;
create policy certificate_signatures_select_scoped on public.certificate_signatures
for select to authenticated
using (public.can_access_certificate(certificate_id) or public.is_platform_admin());

drop policy if exists certificate_signatures_insert_provider_roles on public.certificate_signatures;
create policy certificate_signatures_insert_provider_roles on public.certificate_signatures
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    (
      select c.provider_organization_id
      from public.certificates c
      where c.id = certificate_id
    ),
    array['provider_admin', 'inspector']::public.app_role[]
  )
);

drop policy if exists certificate_signatures_delete_platform on public.certificate_signatures;
create policy certificate_signatures_delete_platform on public.certificate_signatures
for delete to authenticated
using (public.is_platform_admin());

-- evidence_files
drop policy if exists evidence_files_select_members on public.evidence_files;
create policy evidence_files_select_members on public.evidence_files
for select to authenticated
using (public.is_member(organization_id) or public.is_platform_admin());

drop policy if exists evidence_files_insert_roles on public.evidence_files;
create policy evidence_files_insert_roles on public.evidence_files
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'site_manager', 'procurement', 'provider_admin', 'inspector']::public.app_role[]
  )
);

drop policy if exists evidence_files_update_roles on public.evidence_files;
create policy evidence_files_update_roles on public.evidence_files
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'site_manager', 'procurement', 'provider_admin', 'inspector']::public.app_role[]
  )
)
with check (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'site_manager', 'procurement', 'provider_admin', 'inspector']::public.app_role[]
  )
);

drop policy if exists evidence_files_delete_roles on public.evidence_files;
create policy evidence_files_delete_roles on public.evidence_files
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
);

-- provider_credentials
drop policy if exists provider_credentials_select_members on public.provider_credentials;
create policy provider_credentials_select_members on public.provider_credentials
for select to authenticated
using (public.is_member(organization_id) or public.is_platform_admin());

drop policy if exists provider_credentials_insert_provider_admin on public.provider_credentials;
create policy provider_credentials_insert_provider_admin on public.provider_credentials
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
);

drop policy if exists provider_credentials_update_provider_admin on public.provider_credentials;
create policy provider_credentials_update_provider_admin on public.provider_credentials
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
)
with check (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
);

drop policy if exists provider_credentials_delete_provider_admin on public.provider_credentials;
create policy provider_credentials_delete_provider_admin on public.provider_credentials
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(organization_id, array['provider_admin']::public.app_role[])
);

-- share_links
drop policy if exists share_links_select_members on public.share_links;
create policy share_links_select_members on public.share_links
for select to authenticated
using (public.is_member(organization_id) or public.is_platform_admin());

drop policy if exists share_links_insert_roles on public.share_links;
create policy share_links_insert_roles on public.share_links
for insert to authenticated
with check (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array[
      'dutyholder_admin',
      'site_manager',
      'procurement',
      'provider_admin',
      'auditor_viewer',
      'insurer_viewer',
      'landlord_viewer'
    ]::public.app_role[]
  )
);

drop policy if exists share_links_update_roles on public.share_links;
create policy share_links_update_roles on public.share_links
for update to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'procurement', 'provider_admin']::public.app_role[]
  )
)
with check (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'procurement', 'provider_admin']::public.app_role[]
  )
);

drop policy if exists share_links_delete_roles on public.share_links;
create policy share_links_delete_roles on public.share_links
for delete to authenticated
using (
  public.is_platform_admin()
  or public.has_role(
    organization_id,
    array['dutyholder_admin', 'procurement', 'provider_admin']::public.app_role[]
  )
);

-- notifications (only if notifications has organization_id)
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'notifications' and column_name = 'organization_id') then
    drop policy if exists notifications_select_scoped on public.notifications;
    create policy notifications_select_scoped on public.notifications for select to authenticated using (
      user_id = auth.uid() or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement', 'provider_admin']::public.app_role[]) or public.is_platform_admin()
    );
    drop policy if exists notifications_insert_scoped on public.notifications;
    create policy notifications_insert_scoped on public.notifications for insert to authenticated with check (
      public.is_platform_admin() or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement', 'provider_admin']::public.app_role[])
    );
    drop policy if exists notifications_update_scoped on public.notifications;
    create policy notifications_update_scoped on public.notifications for update to authenticated using (
      user_id = auth.uid() or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement', 'provider_admin']::public.app_role[]) or public.is_platform_admin()
    ) with check (
      user_id = auth.uid() or public.has_role(organization_id, array['dutyholder_admin', 'site_manager', 'procurement', 'provider_admin']::public.app_role[]) or public.is_platform_admin()
    );
  end if;
end $$;

-- audit_logs (only if audit_logs has organization_id)
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'audit_logs' and column_name = 'organization_id') then
    drop policy if exists audit_logs_select_scoped on public.audit_logs;
    create policy audit_logs_select_scoped on public.audit_logs for select to authenticated using (
      public.is_platform_admin() or public.has_role(organization_id, array['dutyholder_admin', 'procurement', 'provider_admin', 'auditor_viewer', 'insurer_viewer']::public.app_role[])
    );
  end if;
end $$;

-- offline sync batches (only if offline_sync_batches has organization_id)
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'offline_sync_batches' and column_name = 'organization_id') then
    drop policy if exists offline_sync_batches_select_scoped on public.offline_sync_batches;
    create policy offline_sync_batches_select_scoped on public.offline_sync_batches for select to authenticated using (
      inspector_user_id = auth.uid() or public.is_platform_admin() or public.has_role(organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])
    );
    drop policy if exists offline_sync_batches_insert_scoped on public.offline_sync_batches;
    create policy offline_sync_batches_insert_scoped on public.offline_sync_batches for insert to authenticated with check (
      public.is_platform_admin() or (inspector_user_id = auth.uid() and public.has_role(organization_id, array['inspector', 'provider_admin']::public.app_role[]))
    );
    drop policy if exists offline_sync_batches_update_scoped on public.offline_sync_batches;
    create policy offline_sync_batches_update_scoped on public.offline_sync_batches for update to authenticated using (
      inspector_user_id = auth.uid() or public.is_platform_admin() or public.has_role(organization_id, array['provider_admin']::public.app_role[])
    ) with check (
      inspector_user_id = auth.uid() or public.is_platform_admin() or public.has_role(organization_id, array['provider_admin']::public.app_role[])
    );
  end if;
end $$;

-- offline sync items (only if offline_sync_batches has organization_id)
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'offline_sync_batches' and column_name = 'organization_id') then
    drop policy if exists offline_sync_items_select_scoped on public.offline_sync_items;
    create policy offline_sync_items_select_scoped on public.offline_sync_items for select to authenticated using (
      public.is_platform_admin() or exists (select 1 from public.offline_sync_batches b where b.id = batch_id and (b.inspector_user_id = auth.uid() or public.has_role(b.organization_id, array['dutyholder_admin', 'provider_admin']::public.app_role[])))
    );
    drop policy if exists offline_sync_items_insert_scoped on public.offline_sync_items;
    create policy offline_sync_items_insert_scoped on public.offline_sync_items for insert to authenticated with check (
      public.is_platform_admin() or exists (select 1 from public.offline_sync_batches b where b.id = batch_id and (b.inspector_user_id = auth.uid() or public.has_role(b.organization_id, array['provider_admin']::public.app_role[])))
    );
    drop policy if exists offline_sync_items_update_scoped on public.offline_sync_items;
    create policy offline_sync_items_update_scoped on public.offline_sync_items for update to authenticated using (
      public.is_platform_admin() or exists (select 1 from public.offline_sync_batches b where b.id = batch_id and (b.inspector_user_id = auth.uid() or public.has_role(b.organization_id, array['provider_admin']::public.app_role[])))
    ) with check (
      public.is_platform_admin() or exists (select 1 from public.offline_sync_batches b where b.id = batch_id and (b.inspector_user_id = auth.uid() or public.has_role(b.organization_id, array['provider_admin']::public.app_role[])))
    );
  end if;
end $$;

-- compliance snapshots (only if compliance_snapshots has organization_id)
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'compliance_snapshots' and column_name = 'organization_id') then
    drop policy if exists compliance_snapshots_select_scoped on public.compliance_snapshots;
    create policy compliance_snapshots_select_scoped on public.compliance_snapshots for select to authenticated using (public.is_member(organization_id) or public.is_platform_admin());
    drop policy if exists compliance_snapshots_insert_admin on public.compliance_snapshots;
    create policy compliance_snapshots_insert_admin on public.compliance_snapshots for insert to authenticated with check (
      public.is_platform_admin() or public.has_role(organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
    );
    drop policy if exists compliance_snapshots_update_admin on public.compliance_snapshots;
    create policy compliance_snapshots_update_admin on public.compliance_snapshots for update to authenticated using (
      public.is_platform_admin() or public.has_role(organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
    ) with check (
      public.is_platform_admin() or public.has_role(organization_id, array['dutyholder_admin', 'procurement']::public.app_role[])
    );
  end if;
end $$;

grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
do $$
begin
  if exists (select 1 from pg_views where schemaname = 'public' and viewname = 'v_compliance_summary') then
    grant select on public.v_compliance_summary to authenticated;
  end if;
end $$;
