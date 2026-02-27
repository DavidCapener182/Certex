# InCert Implementation Roadmap

## Current baseline (completed in this repo)

- Frontend app scaffolded with React + Vite + Tailwind.
- Database foundation migrations created:
  - `supabase/migrations/20260222143000_initial_schema.sql`
  - `supabase/migrations/20260222150000_rls_and_access.sql`
  - `supabase/migrations/20260222153000_rpc_and_realtime.sql`
  - `supabase/migrations/20260222164000_qr_labels_and_certificate_rendering.sql`
  - `supabase/migrations/20260222173000_marketplace_pricing_dispatch.sql`
  - `supabase/migrations/20260222190000_certificate_artifact_storage_and_signed_url_payload.sql`
  - `supabase/migrations/20260222203000_pricing_engine_quote_lock_adjustment_settlement.sql`
  - `supabase/migrations/20260222224500_take_rate_floor_and_going_rate.sql`

## Next-wave SQL pack prepared (ready to run once Supabase is connected)

- `supabase/migrations/20260226213000_audit_company_bidding_assignment_and_dispatch.sql`
  - Covers: audit company operating model, competitive bids, assignment flow, dispatch SLA telemetry.
- `supabase/migrations/20260226214000_template_studio_and_weighted_scoring.sql`
  - Covers: bespoke template studio, conditional controls, weighted scoring bands, publish/version workflows.
- `supabase/migrations/20260226215000_evidence_ai_provenance_and_verification.sql`
  - Covers: AI evidence extraction queue, provenance chain events, review decisions, regulator verification workflow.
- `supabase/migrations/20260226220000_capa_finance_analytics.sql`
  - Covers: CAPA/remediation lifecycle, invoice + payout automation, KPI + risk analytics snapshots.
- `supabase/migrations/20260226221000_integrations_mobile_enterprise.sql`
  - Covers: integrations/API/webhooks, mobile session hardening + conflict tracking, SSO + enterprise security controls.
- `supabase/migrations/20260226222000_quality_harness_and_release_readiness.sql`
  - Covers: QA run telemetry, release gate tracking, readiness scoring foundations.

## Post-research slice implemented

- Marketplace scope builder now captures template, complexity, equipment, travel, and urgency at job creation.
- Instant quote breakdown (labour/travel/equipment/expedite/platform fee) is modeled in UI and schema.
- Dispatch workflow now supports:
  - offer state (`offered`)
  - offer expiry windows
  - deterministic re-offer path
  - explicit offer acceptance before job start
- Provider rate cards, provider availability windows, marketplace request records, and dispatch attempts are available in Supabase with RLS and realtime.
- New RPCs in place for top-priority flow:
  - `calculate_marketplace_quote(...)`
  - `send_marketplace_offer(...)`
  - `accept_marketplace_offer(...)`
- Pricing engine now tracks immutable quote versions, quote locks, adjustment events, and settlement ledger records.
- Platform take-rate now uses floor-based enforcement (30% minimum, higher by scope), with pricing aligned to going-rate charge logic and customer-paid VAT.
- Certificate render artifacts are now modeled for Storage-backed PDF/HTML/SVG snapshots, with signing-payload RPC for API URL issuance.
- Scan lookup now supports camera-based barcode/QR detection using `BarcodeDetector` + live camera input.

## Guiding architecture

- Database: PostgreSQL (Supabase)
- Auth: Supabase Auth + `organization_memberships` role model
- Security: RLS on all business tables
- Files: Supabase Storage for evidence blobs and certificate PDFs
- API: Supabase RPC + server-side orchestration (Edge Functions or Node backend)
- Realtime: Supabase Realtime over `notifications`, `inspection_jobs`, `certificates`, `assets`

## Delivery phases

### Phase 1: Real backend and persistence (now -> next sprint)

1. Wire frontend data layer to Supabase.
2. Replace in-memory asset/certificate/provider reads with live queries.
3. Add server-side write paths for:
   - add asset
   - request inspection
   - create share link
4. Add environment config (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`).

SQL impact now:
- already covered by the six baseline migrations.

### Phase 2: Authentication + RBAC

1. Build auth pages (sign in, invite acceptance).
2. Route by role:
   - Dutyholder: dashboard/register/vault/network
   - Inspector: mobile-first job checklist + upload
   - Auditor: read-only vault and verification views
3. Add org-switcher and role-aware navigation.
4. Enforce role checks both in UI and via RLS.

Planned SQL updates when features expand:
- add invite and session audit entities (new migration).
- add role-grant workflow RPCs (new migration).

### Phase 3: Real PDF generation and exports

1. Add backend PDF service (React-PDF or Puppeteer service) for:
   - single certificate export
   - multi-certificate audit pack
2. Store generated PDFs in storage and index in `evidence_files`.
3. Record hash and signing metadata on export.

Planned SQL migration:
- export jobs table + PDF artefact metadata fields.

### Phase 4: Form validation and error handling

1. Add React Hook Form + Zod for Add Asset and Dispatch forms.
2. Validate IDs, date windows, and required fields inline.
3. Add structured API error responses and retry-safe UI.

Planned SQL migration:
- stronger constraints/checks and optional domain types.

### Phase 5: Drag-and-drop document upload

1. Add secure upload zone in Evidence Vault.
2. Upload raw provider PDFs to storage + `evidence_files` row.
3. Parse metadata (certificate number, dates, asset id) asynchronously.
4. Human review queue for low-confidence parsing.

Planned SQL migration:
- ingestion queue + parse result/status tables.

### Phase 6: Interactive analytics and charting

1. Add Recharts dashboard widgets.
2. Trend compliance over time by regime/site/asset class.
3. Defect severity and repeat-failure analysis.

Planned SQL migration:
- time-series snapshot tables/materialized views and indexes.

### Phase 7: Offline mode (PWA)

1. Add service worker and offline cache strategy.
2. Inspector checklist works offline.
3. Sync queue flushes when online; conflict handling with server timestamps.

SQL support already added:
- `offline_sync_batches`, `offline_sync_items`.

### Phase 8: Pagination and infinite scroll

1. Convert Asset Register and Vault to cursor-based pagination.
2. Add server-side filtering and search.
3. Virtualized lists for large result sets.

Planned SQL migration:
- additional compound indexes for sort/filter combinations discovered in telemetry.

### Phase 9: Realtime notifications

1. Subscribe to `notifications` and `inspection_jobs` channels.
2. Emit toasts and badge counts from live events.
3. Add read/unread sync and delivery state.

SQL support already added:
- notifications table + realtime publication + helper RPCs.

### Phase 10: Interactive map integration

1. Add Mapbox map for assets/providers.
2. Distance-aware provider suggestions for dispatch.
3. Geo filters and route previews.

Planned SQL migration:
- PostGIS extension + geometry columns + geo indexes.

## Definition of done per feature

- UI implemented with loading/error/empty states.
- API path implemented and tested.
- SQL migration added for data-model/security changes.
- RLS policies validated with role-based test matrix.
- Audit logging present for sensitive actions.

## Ongoing SQL update policy

For every future feature, create a new migration in `supabase/migrations`.
Do not modify previously applied migration files; append new migrations only.
