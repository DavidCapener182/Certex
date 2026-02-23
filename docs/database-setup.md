# Database Setup (Supabase)

## 1) Apply migrations

Run migrations in order from `supabase/migrations`:

1. `20260222143000_initial_schema.sql`
2. `20260222150000_rls_and_access.sql`
3. `20260222153000_rpc_and_realtime.sql`
4. `20260222164000_qr_labels_and_certificate_rendering.sql`
5. `20260222173000_marketplace_pricing_dispatch.sql`
6. `20260222190000_certificate_artifact_storage_and_signed_url_payload.sql`
7. `20260222203000_pricing_engine_quote_lock_adjustment_settlement.sql`
8. `20260222224500_take_rate_floor_and_going_rate.sql`

Use either:

- Supabase SQL editor (paste file contents in order), or
- Supabase CLI (`supabase db push`) if configured.

## 2) Seed minimum org + role data

After creating an auth user, add at least one org and membership:

```sql
insert into public.organizations (name, slug, org_type)
values ('Acme Logistics', 'acme-logistics', 'operator')
returning id;

insert into public.organization_memberships (organization_id, user_id, role, is_default)
values ('<org_uuid>', '<auth_user_uuid>', 'dutyholder_admin', true);
```

## 3) Verify RLS quickly

As authenticated user with dutyholder role, verify:

```sql
select * from public.assets limit 10;
select * from public.certificates limit 10;
```

As a different user without membership, those should return no rows.

## 4) Verify share link flow

```sql
select *
from public.create_share_link(
  '<org_uuid>'::uuid,
  'certificate',
  '<certificate_uuid>'::uuid,
  48,
  '{"read_only": true}'::jsonb
);
```

Use returned `token`:

```sql
select * from public.verify_share_token('<token_here>');
```

## 5) Realtime checks

Ensure these tables are in `supabase_realtime` publication:

- `public.notifications`
- `public.inspection_jobs`
- `public.certificates`
- `public.inspection_requests`
- `public.assets`
- `public.marketplace_requests`
- `public.marketplace_dispatch_attempts`

## 6) Marketplace pricing and dispatch checks

Quote preview check:

```sql
select *
from public.calculate_marketplace_quote(
  'LOLER',
  'manchester',
  2.5,
  'restricted',
  18,
  'none',
  false,
  0.45
);
```

Dispatch offer check:

```sql
select public.send_marketplace_offer(
  '<inspection_request_uuid>'::uuid,
  '<provider_org_uuid>'::uuid,
  90,
  88.5,
  315,
  'manual_dispatch'
);
```

Accept offer check:

```sql
select public.accept_marketplace_offer('<dispatch_attempt_uuid>'::uuid);
```

## 7) Certificate artifact storage + signed-url payload checks

Register a rendered PDF artifact:

```sql
select public.register_certificate_render_artifact(
  '<certificate_uuid>'::uuid,
  'pdf',
  1,
  '<certificate_uuid>/v1/certificate.pdf',
  'application/pdf',
  152340,
  'abc123sha256',
  'certex_html_v2',
  '{"source":"renderer-service"}'::jsonb
);
```

Get signing payload for API:

```sql
select *
from public.get_certificate_artifact_signing_payload(
  '<certificate_uuid>'::uuid,
  'pdf',
  3600
);
```

API flow:
- Call `get_certificate_artifact_signing_payload(...)` in backend/API.
- Use returned `bucket_id`, `object_path`, and `expires_in_seconds` with Supabase Storage SDK `createSignedUrl(...)`.
- Return the signed URL to the client.

## 8) Pricing engine quote/lock/adjustment/settlement checks

Create a quote:

```sql
select public.create_price_quote(
  '<inspection_request_uuid>'::uuid,
  '<provider_org_uuid>'::uuid,
  null,
  null,
  480,
  96,
  576,
  410,
  82,
  70,
  14,
  0.1458,
  'GBP',
  now() + interval '24 hours',
  '{"route_miles": 28}'::jsonb,
  '["ASAP dispatch","Weekday access"]'::jsonb,
  '[{"code":"LABOUR","amount_ex_vat":320},{"code":"PLATFORM_FEE","amount_ex_vat":70}]'::jsonb
);
```

Lock the quote:

```sql
select public.lock_price_quote('<quote_uuid>'::uuid, 'BOOK-123', 'quote_accept');
```

Apply an adjustment:

```sql
select public.apply_price_adjustment(
  '<inspection_request_uuid>'::uuid,
  'scope_up',
  'scope_change_up',
  65,
  'job-log://evidence/123'
);
```

Upsert settlement ledger:

```sql
select public.upsert_settlement_ledger_for_request(
  '<inspection_request_uuid>'::uuid,
  'scheduled',
  'EVIDENCE_ISSUED'
);
```
