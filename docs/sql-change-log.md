# SQL Change Log

## Applied in baseline

1. `20260222143000_initial_schema.sql`
- Core multi-tenant entities, inspection workflow tables, certificates, evidence, offline sync, analytics snapshots.
- Status triggers for assets and certificates.
- Performance indexes.

2. `20260222150000_rls_and_access.sql`
- RBAC helper functions.
- RLS enabled for all business tables.
- Role-scoped policies by tenant and workflow context.

3. `20260222153000_rpc_and_realtime.sql`
- RPCs for share links, verification, notifications, audit logging, snapshot refresh.
- Certificate status-change audit trigger.
- Realtime publication setup.

4. `20260222164000_qr_labels_and_certificate_rendering.sql`
- QR label entities for assets and scan telemetry.
- Certificate rendering metadata columns.
- `resolve_asset_qr_token(...)` lookup RPC.
- RLS and realtime publication coverage for QR entities.

5. `20260222173000_marketplace_pricing_dispatch.sql`
- Marketplace data model for scope templates, quote snapshots, dispatch attempts, and offer acceptance.
- Provider rate cards and availability windows for pricing/dispatch logic.
- Pricing and dispatch RPCs:
  - `calculate_marketplace_quote(...)`
  - `send_marketplace_offer(...)`
  - `accept_marketplace_offer(...)`
- RLS and realtime publication coverage for marketplace tables.

6. `20260222190000_certificate_artifact_storage_and_signed_url_payload.sql`
- Supabase Storage bucket provisioning for certificate render artifacts.
- `certificate_render_artifacts` registry table + URL request audit table.
- Storage RLS policies tied to certificate access (`storage.objects` policies for `certificate-artifacts` bucket).
- Artifact RPCs:
  - `register_certificate_render_artifact(...)`
  - `get_certificate_artifact_signing_payload(...)`
- API integration contract: call `get_certificate_artifact_signing_payload(...)`, then issue Storage signed URL in backend/API.

7. `20260222203000_pricing_engine_quote_lock_adjustment_settlement.sql`
- Pricing engine schema for immutable quote versions, line items, quote lock records, adjustment events, and settlement ledger entries.
- New enums: `price_quote_status`, `pricing_adjustment_type`, `settlement_status`.
- Quote/settlement RPCs:
  - `create_price_quote(...)`
  - `lock_price_quote(...)`
  - `apply_price_adjustment(...)`
  - `upsert_settlement_ledger_for_request(...)`
- Realtime publication + RLS coverage for quote/lock/adjustment/settlement entities.

8. `20260222224500_take_rate_floor_and_going_rate.sql`
- Replaces hard 30%-40% cap with a minimum-take model: floor at 30% (and 40% minimum for expedite quote RPC paths).
- Raises take-rate defaults to go-rate pricing posture (`0.45`) while preserving floor constraints.
- Clamps existing `provider_rate_cards.platform_fee_pct` and `price_quotes.effective_take_rate` to a minimum of `0.30`.
- Updates pricing RPC defaults/fallbacks:
  - `calculate_marketplace_quote(...)`
  - `create_price_quote(...)`
  - `apply_price_adjustment(...)`

## Next migrations (planned)

- `*_auth_invites_and_org_onboarding.sql`
- `*_pdf_export_jobs_and_artifacts.sql`
- `*_document_ingestion_and_parsing_queue.sql`
- `*_analytics_materialized_views.sql`
- `*_pagination_indexes_tuning.sql`
- `*_postgis_map_support.sql`

Each future feature must include one new SQL migration and an entry in this file.
