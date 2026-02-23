-- 2026-02-22: Certificate render artifacts in Supabase Storage + signed-url API payload RPCs

-- Artifact enums

do $$
begin
  if not exists (select 1 from pg_type where typname = 'certificate_artifact_type') then
    create type public.certificate_artifact_type as enum (
      'pdf',
      'html_snapshot',
      'svg_snapshot'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'certificate_artifact_status') then
    create type public.certificate_artifact_status as enum (
      'active',
      'superseded',
      'revoked'
    );
  end if;
end $$;

-- Private storage bucket for rendered artifacts
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'certificate-artifacts',
  'certificate-artifacts',
  false,
  15728640,
  array['application/pdf', 'text/html', 'image/svg+xml']::text[]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create table if not exists public.certificate_render_artifacts (
  id uuid primary key default gen_random_uuid(),
  certificate_id uuid not null references public.certificates(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  artifact_type public.certificate_artifact_type not null,
  artifact_status public.certificate_artifact_status not null default 'active',
  version_no integer not null default 1 check (version_no > 0),
  bucket_id text not null default 'certificate-artifacts',
  object_path text not null,
  mime_type text not null,
  byte_size bigint check (byte_size is null or byte_size >= 0),
  checksum_sha256 text,
  render_template_version text,
  metadata jsonb not null default '{}'::jsonb,
  generated_by uuid references auth.users(id) on delete set null,
  generated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  revoked_at timestamptz,
  constraint certificate_render_artifacts_bucket_check check (bucket_id = 'certificate-artifacts'),
  constraint certificate_render_artifacts_path_scope check (split_part(object_path, '/', 1) = certificate_id::text),
  unique (certificate_id, artifact_type, version_no),
  unique (bucket_id, object_path)
);

create table if not exists public.certificate_artifact_url_audit (
  id uuid primary key default gen_random_uuid(),
  certificate_artifact_id uuid not null references public.certificate_render_artifacts(id) on delete cascade,
  requested_by uuid references auth.users(id) on delete set null,
  ttl_seconds integer not null,
  issued_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists idx_certificate_render_artifacts_certificate_type
  on public.certificate_render_artifacts(certificate_id, artifact_type, version_no desc);
create index if not exists idx_certificate_render_artifacts_status
  on public.certificate_render_artifacts(artifact_status, generated_at desc);
create index if not exists idx_certificate_render_artifacts_org
  on public.certificate_render_artifacts(organization_id, created_at desc);
create index if not exists idx_certificate_artifact_url_audit_artifact
  on public.certificate_artifact_url_audit(certificate_artifact_id, issued_at desc);

create or replace function public.certificate_id_from_storage_path(p_object_path text)
returns uuid
language plpgsql
immutable
as $$
declare
  v_root text;
begin
  v_root := nullif(split_part(coalesce(p_object_path, ''), '/', 1), '');
  if v_root is null then
    return null;
  end if;

  begin
    return v_root::uuid;
  exception
    when others then
      return null;
  end;
end;
$$;

create or replace function public.can_manage_certificate_artifacts(p_certificate_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_platform_admin()
    or exists (
      select 1
      from public.certificates c
      join public.organization_memberships m
        on m.user_id = auth.uid()
       and m.organization_id in (c.operator_organization_id, c.provider_organization_id)
      where c.id = p_certificate_id
        and m.role = any (
          array[
            'dutyholder_admin',
            'site_manager',
            'procurement',
            'provider_admin',
            'inspector'
          ]::public.app_role[]
        )
    );
$$;

create or replace function public.prepare_certificate_render_artifact()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_operator_org uuid;
begin
  select c.operator_organization_id
  into v_operator_org
  from public.certificates c
  where c.id = new.certificate_id;

  if v_operator_org is null then
    raise exception 'Certificate % not found', new.certificate_id;
  end if;

  new.organization_id := v_operator_org;

  if new.generated_by is null then
    new.generated_by := auth.uid();
  end if;

  return new;
end;
$$;

create or replace function public.register_certificate_render_artifact(
  p_certificate_id uuid,
  p_artifact_type public.certificate_artifact_type,
  p_version_no integer,
  p_object_path text,
  p_mime_type text,
  p_byte_size bigint default null,
  p_checksum_sha256 text default null,
  p_render_template_version text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_artifact_id uuid;
  v_certificate public.certificates%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  if p_version_no < 1 then
    raise exception 'p_version_no must be >= 1';
  end if;

  if p_object_path is null or length(trim(p_object_path)) = 0 then
    raise exception 'p_object_path is required';
  end if;

  if p_mime_type is null or length(trim(p_mime_type)) = 0 then
    raise exception 'p_mime_type is required';
  end if;

  select *
  into v_certificate
  from public.certificates c
  where c.id = p_certificate_id;

  if not found then
    raise exception 'Certificate % not found', p_certificate_id;
  end if;

  if not public.can_manage_certificate_artifacts(p_certificate_id) then
    raise exception 'Not authorized to register certificate artifacts for %', p_certificate_id;
  end if;

  update public.certificate_render_artifacts
  set
    artifact_status = 'superseded',
    updated_at = now()
  where certificate_id = p_certificate_id
    and artifact_type = p_artifact_type
    and version_no < p_version_no
    and artifact_status = 'active';

  insert into public.certificate_render_artifacts (
    certificate_id,
    organization_id,
    artifact_type,
    artifact_status,
    version_no,
    bucket_id,
    object_path,
    mime_type,
    byte_size,
    checksum_sha256,
    render_template_version,
    metadata,
    generated_by,
    generated_at
  )
  values (
    p_certificate_id,
    v_certificate.operator_organization_id,
    p_artifact_type,
    'active',
    p_version_no,
    'certificate-artifacts',
    trim(p_object_path),
    trim(p_mime_type),
    p_byte_size,
    nullif(trim(coalesce(p_checksum_sha256, '')), ''),
    nullif(trim(coalesce(p_render_template_version, '')), ''),
    coalesce(p_metadata, '{}'::jsonb),
    auth.uid(),
    now()
  )
  on conflict (certificate_id, artifact_type, version_no)
  do update set
    object_path = excluded.object_path,
    mime_type = excluded.mime_type,
    byte_size = excluded.byte_size,
    checksum_sha256 = excluded.checksum_sha256,
    render_template_version = excluded.render_template_version,
    metadata = excluded.metadata,
    artifact_status = 'active',
    revoked_at = null,
    generated_by = auth.uid(),
    generated_at = now(),
    updated_at = now()
  returning id into v_artifact_id;

  if p_artifact_type = 'pdf' then
    update public.certificates c
    set
      rendered_pdf_storage_path = trim(p_object_path),
      render_template_version = coalesce(nullif(trim(coalesce(p_render_template_version, '')), ''), c.render_template_version),
      rendered_at = now(),
      updated_at = now()
    where c.id = p_certificate_id;
  elsif p_artifact_type = 'html_snapshot' then
    update public.certificates c
    set
      render_template_version = coalesce(nullif(trim(coalesce(p_render_template_version, '')), ''), c.render_template_version),
      rendered_at = now(),
      updated_at = now()
    where c.id = p_certificate_id;
  end if;

  perform public.write_audit_log(
    v_certificate.operator_organization_id,
    'certificate.artifact_registered',
    'certificate',
    p_certificate_id,
    jsonb_build_object(
      'certificate_artifact_id', v_artifact_id,
      'artifact_type', p_artifact_type,
      'version_no', p_version_no,
      'object_path', trim(p_object_path)
    )
  );

  return v_artifact_id;
end;
$$;

create or replace function public.get_certificate_artifact_signing_payload(
  p_certificate_id uuid,
  p_artifact_type public.certificate_artifact_type default 'pdf',
  p_ttl_seconds integer default 3600
)
returns table (
  certificate_artifact_id uuid,
  bucket_id text,
  object_path text,
  mime_type text,
  expires_in_seconds integer,
  render_template_version text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_artifact public.certificate_render_artifacts%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Unauthenticated';
  end if;

  if p_ttl_seconds < 60 or p_ttl_seconds > 86400 then
    raise exception 'p_ttl_seconds must be between 60 and 86400';
  end if;

  if not (
    public.can_access_certificate(p_certificate_id)
    or public.is_platform_admin()
  ) then
    raise exception 'Not authorized to access certificate %', p_certificate_id;
  end if;

  select *
  into v_artifact
  from public.certificate_render_artifacts a
  where a.certificate_id = p_certificate_id
    and a.artifact_type = p_artifact_type
    and a.artifact_status = 'active'
  order by a.version_no desc, a.generated_at desc
  limit 1;

  if not found then
    return;
  end if;

  insert into public.certificate_artifact_url_audit (
    certificate_artifact_id,
    requested_by,
    ttl_seconds,
    metadata
  )
  values (
    v_artifact.id,
    auth.uid(),
    p_ttl_seconds,
    jsonb_build_object(
      'artifact_type', p_artifact_type,
      'certificate_id', p_certificate_id
    )
  );

  return query
  select
    v_artifact.id,
    v_artifact.bucket_id,
    v_artifact.object_path,
    v_artifact.mime_type,
    p_ttl_seconds,
    v_artifact.render_template_version;
end;
$$;

drop trigger if exists tr_prepare_certificate_render_artifact on public.certificate_render_artifacts;
create trigger tr_prepare_certificate_render_artifact
before insert or update on public.certificate_render_artifacts
for each row execute function public.prepare_certificate_render_artifact();

drop trigger if exists tr_set_updated_at_certificate_render_artifacts on public.certificate_render_artifacts;
create trigger tr_set_updated_at_certificate_render_artifacts
before update on public.certificate_render_artifacts
for each row execute function public.set_updated_at();

alter table public.certificate_render_artifacts enable row level security;
alter table public.certificate_artifact_url_audit enable row level security;

-- certificate_render_artifacts policies

drop policy if exists certificate_render_artifacts_select_scoped on public.certificate_render_artifacts;
create policy certificate_render_artifacts_select_scoped on public.certificate_render_artifacts
for select to authenticated
using (
  public.can_access_certificate(certificate_id)
  or public.is_platform_admin()
);

drop policy if exists certificate_render_artifacts_insert_scoped on public.certificate_render_artifacts;
create policy certificate_render_artifacts_insert_scoped on public.certificate_render_artifacts
for insert to authenticated
with check (
  public.can_manage_certificate_artifacts(certificate_id)
);

drop policy if exists certificate_render_artifacts_update_scoped on public.certificate_render_artifacts;
create policy certificate_render_artifacts_update_scoped on public.certificate_render_artifacts
for update to authenticated
using (
  public.can_manage_certificate_artifacts(certificate_id)
)
with check (
  public.can_manage_certificate_artifacts(certificate_id)
);

drop policy if exists certificate_render_artifacts_delete_scoped on public.certificate_render_artifacts;
create policy certificate_render_artifacts_delete_scoped on public.certificate_render_artifacts
for delete to authenticated
using (
  public.can_manage_certificate_artifacts(certificate_id)
);

-- certificate_artifact_url_audit policies

drop policy if exists certificate_artifact_url_audit_select_scoped on public.certificate_artifact_url_audit;
create policy certificate_artifact_url_audit_select_scoped on public.certificate_artifact_url_audit
for select to authenticated
using (
  public.is_platform_admin()
  or exists (
    select 1
    from public.certificate_render_artifacts a
    where a.id = certificate_artifact_id
      and public.can_manage_certificate_artifacts(a.certificate_id)
  )
);

drop policy if exists certificate_artifact_url_audit_insert_scoped on public.certificate_artifact_url_audit;
create policy certificate_artifact_url_audit_insert_scoped on public.certificate_artifact_url_audit
for insert to authenticated
with check (
  public.is_platform_admin()
  or exists (
    select 1
    from public.certificate_render_artifacts a
    where a.id = certificate_artifact_id
      and (
        public.can_access_certificate(a.certificate_id)
        or public.can_manage_certificate_artifacts(a.certificate_id)
      )
  )
);

-- Storage object policies for certificate-artifacts bucket

drop policy if exists certificate_artifact_objects_select_scoped on storage.objects;
create policy certificate_artifact_objects_select_scoped on storage.objects
for select to authenticated
using (
  bucket_id = 'certificate-artifacts'
  and public.can_access_certificate(public.certificate_id_from_storage_path(name))
);

drop policy if exists certificate_artifact_objects_insert_scoped on storage.objects;
create policy certificate_artifact_objects_insert_scoped on storage.objects
for insert to authenticated
with check (
  bucket_id = 'certificate-artifacts'
  and public.can_manage_certificate_artifacts(public.certificate_id_from_storage_path(name))
);

drop policy if exists certificate_artifact_objects_update_scoped on storage.objects;
create policy certificate_artifact_objects_update_scoped on storage.objects
for update to authenticated
using (
  bucket_id = 'certificate-artifacts'
  and public.can_manage_certificate_artifacts(public.certificate_id_from_storage_path(name))
)
with check (
  bucket_id = 'certificate-artifacts'
  and public.can_manage_certificate_artifacts(public.certificate_id_from_storage_path(name))
);

drop policy if exists certificate_artifact_objects_delete_scoped on storage.objects;
create policy certificate_artifact_objects_delete_scoped on storage.objects
for delete to authenticated
using (
  bucket_id = 'certificate-artifacts'
  and public.can_manage_certificate_artifacts(public.certificate_id_from_storage_path(name))
);

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.certificate_render_artifacts;
    exception
      when duplicate_object then null;
    end;
  end if;
end $$;

grant execute on function public.certificate_id_from_storage_path(text) to anon, authenticated;
grant execute on function public.can_manage_certificate_artifacts(uuid) to authenticated;

grant execute on function public.register_certificate_render_artifact(
  uuid,
  public.certificate_artifact_type,
  integer,
  text,
  text,
  bigint,
  text,
  text,
  jsonb
) to authenticated;

grant execute on function public.get_certificate_artifact_signing_payload(
  uuid,
  public.certificate_artifact_type,
  integer
) to authenticated;
