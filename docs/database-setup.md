# Database Setup (Supabase)

**Project ref (shared database):** `wngqphzpxhderwfjjzla` · [Dashboard](https://app.supabase.com/project/wngqphzpxhderwfjjzla)

To get the database working you need to **run the migrations** using one of the options below. If your project is not yet linked to Supabase or you don’t have a database URL, use Option A or B first.

## 0) Run migrations (choose one)

### Option A — Supabase CLI (recommended)

1. Log in (once): `npx supabase login`
2. Link (use shared DB password when prompted, or set `SUPABASE_DB_PASSWORD`): `npx supabase link --project-ref wngqphzpxhderwfjjzla`
3. Push migrations: `npx supabase db push`

### Option B — Script with direct database URL

1. In Supabase Dashboard go to **Project Settings → Database**. Under **Connection string** choose **URI** and copy it (use the pooler port **6543** for server-side).
2. Create a `.env` in the project root (optional) and set:
   ```bash
   DATABASE_URL="postgresql://postgres.[ref]:[YOUR-PASSWORD]@aws-0-[region].pooler.supabase.com:6543/postgres"
   ```
   Or export `DATABASE_URL` in your shell.
3. From the project root run (requires `psql` installed):
   ```bash
   ./scripts/run-migrations.sh
   ```

### Option C — Supabase SQL Editor

In **Supabase Dashboard → SQL Editor**, run each migration file in order (copy-paste contents). Run them one after another; do not skip files.

---

## 1) Migration files (in order)

From `supabase/migrations`:

1. `20260222143000_initial_schema.sql`
2. `20260222150000_rls_and_access.sql`
3. `20260222153000_rpc_and_realtime.sql`
4. `20260222164000_qr_labels_and_certificate_rendering.sql`
5. `20260222173000_marketplace_pricing_dispatch.sql`
6. `20260222190000_certificate_artifact_storage_and_signed_url_payload.sql`
7. `20260222203000_pricing_engine_quote_lock_adjustment_settlement.sql`
8. `20260222224500_take_rate_floor_and_going_rate.sql`
9. `20260226213000_audit_company_bidding_assignment_and_dispatch.sql`
10. `20260226214000_template_studio_and_weighted_scoring.sql`
11. `20260226215000_evidence_ai_provenance_and_verification.sql`
12. `20260226220000_capa_finance_analytics.sql`
13. `20260226221000_integrations_mobile_enterprise.sql`
14. `20260226222000_quality_harness_and_release_readiness.sql`

Note:
- The six `2026022621...` / `2026022622...` migrations create physical tables with quoted `InCert-` prefixes (for example `public."InCert-marketplace_bids"`).
- RPC function names remain in `public` without prefix.

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
  'incert_html_v2',
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

## 9) Next-wave checks (audit companies, templates, evidence QA, finance, integrations)

Submit a bid:

```sql
select public.submit_marketplace_bid(
  '<inspection_request_uuid>'::uuid,
  '<provider_org_uuid>'::uuid,
  525.00,
  105.00,
  18,
  'Can deploy within 18 hours',
  '[{"code":"LABOUR","description":"Inspection labour","amount_ex_vat":420},{"code":"TRAVEL","description":"Mileage","amount_ex_vat":105}]'::jsonb
);
```

Publish a template version:

```sql
select public.publish_inspection_template_version(
  '<template_version_uuid>'::uuid,
  'Initial published release'
);
```

Queue AI evidence processing:

```sql
select public.enqueue_evidence_ai_job(
  '<evidence_file_uuid>'::uuid,
  'gpt-5-mini'
);
```

Create CAPA action:

```sql
select public.create_capa_action(
  '<inspection_finding_uuid>'::uuid,
  'Replace failed relief valve',
  'high',
  current_date + 14,
  'Immediate engineering replacement required'
);
```

Generate invoice:

```sql
select public.generate_invoice_for_request(
  '<inspection_request_uuid>'::uuid,
  true
);
```

Start QA run:

```sql
select public.start_qa_test_run(
  '<qa_test_suite_uuid>'::uuid,
  '<organization_uuid>'::uuid,
  'manual',
  null,
  'main'
);
```
