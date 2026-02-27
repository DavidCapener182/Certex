# Next-Level Migration Pack (Items 2-15)

This pack is prepared so Supabase can be enabled and migrated immediately.

Naming convention for sharded deployment:
- All physical tables created by this pack are prefixed and quoted as `public."InCert-<logical_name>"`.
- The table names listed below are logical names for readability.
- RPC/function names remain unprefixed in `public`.

## Feature Mapping

1. **2. Audit company operating model**
   - Migration: `20260226213000_audit_company_bidding_assignment_and_dispatch.sql`
   - Tables: `audit_company_profiles`, `audit_company_auditors`, `marketplace_job_assignments`
   - RPCs: `assign_marketplace_job_auditor(...)`

2. **3. Competitive bids + smart award rules**
   - Migration: `20260226213000_audit_company_bidding_assignment_and_dispatch.sql`
   - Tables: `marketplace_bids`, `marketplace_bid_line_items`, `marketplace_award_rules`
   - RPCs: `submit_marketplace_bid(...)`, `award_marketplace_bid(...)`

3. **4. Template Studio + weighted scoring**
   - Migration: `20260226214000_template_studio_and_weighted_scoring.sql`
   - Tables: `inspection_template_definitions`, `inspection_template_versions`, `inspection_template_sections`, `inspection_template_controls`, `inspection_template_conditions`, `inspection_template_scoring_bands`, `inspection_template_publish_events`
   - RPCs: `publish_inspection_template_version(...)`

4. **5. AI evidence QA**
   - Migration: `20260226215000_evidence_ai_provenance_and_verification.sql`
   - Tables: `evidence_ai_jobs`, `evidence_ai_extractions`
   - RPCs: `enqueue_evidence_ai_job(...)`

5. **6. Tamper-proof provenance chain**
   - Migration: `20260226215000_evidence_ai_provenance_and_verification.sql`
   - Tables: `evidence_provenance_events`, `evidence_review_decisions`
   - RPCs: `append_evidence_provenance(...)`, `record_evidence_review_decision(...)`

6. **7. CAPA workflow**
   - Migration: `20260226220000_capa_finance_analytics.sql`
   - Tables: `capa_actions`, `capa_action_updates`, `capa_action_evidence`
   - RPCs: `create_capa_action(...)`

7. **8. Finance automation**
   - Migration: `20260226220000_capa_finance_analytics.sql`
   - Tables: `finance_invoices`, `finance_invoice_line_items`, `finance_payout_batches`, `finance_payout_batch_items`, `finance_payment_events`
   - RPCs: `generate_invoice_for_request(...)`

8. **9. Live performance + risk analytics**
   - Migration: `20260226220000_capa_finance_analytics.sql`
   - Tables: `analytics_kpi_snapshots`, `analytics_provider_scorecards`, `analytics_risk_signals`
   - RPCs: `refresh_org_kpi_snapshot(...)`

9. **10. API + webhooks + integration jobs**
   - Migration: `20260226221000_integrations_mobile_enterprise.sql`
   - Tables: `api_clients`, `api_client_secrets`, `webhook_endpoints`, `webhook_delivery_events`, `integration_sync_jobs`
   - RPCs: `enqueue_webhook_delivery(...)`, `rotate_api_client_secret(...)`

10. **11. Mobile auditor hardening**
    - Migration: `20260226221000_integrations_mobile_enterprise.sql`
    - Tables: `mobile_devices`, `mobile_audit_sessions`, `mobile_sync_conflicts`
    - RPCs: `open_mobile_audit_session(...)`

11. **12. Regulator/insurer verification portal flow**
    - Migration: `20260226215000_evidence_ai_provenance_and_verification.sql`
    - Tables: `regulator_verification_requests`, `regulator_verification_events`

12. **13. Dispatch intelligence and SLA telemetry**
    - Migration: `20260226213000_audit_company_bidding_assignment_and_dispatch.sql`
    - Tables: `dispatch_sla_events`, `dispatch_route_estimates`

13. **14. Enterprise controls + security events**
    - Migration: `20260226221000_integrations_mobile_enterprise.sql`
    - Tables: `enterprise_sso_providers`, `enterprise_domain_claims`, `enterprise_access_policies`, `enterprise_security_events`
    - RPCs: `log_enterprise_security_event(...)`

14. **15. Quality harness + release readiness**
    - Migration: `20260226222000_quality_harness_and_release_readiness.sql`
    - Tables: `qa_test_suites`, `qa_test_cases`, `qa_test_runs`, `qa_test_run_results`, `release_gates`, `release_gate_results`
    - RPCs: `start_qa_test_run(...)`, `record_qa_test_case_result(...)`, `finalize_qa_test_run(...)`

## Notes

- All migrations were added as new files only (no historical migration rewrites).
- Each migration includes RLS enablement and scoped policies.
- Realtime publications were added for key operational tables.
- RPC grants were added for `authenticated` role where needed.
