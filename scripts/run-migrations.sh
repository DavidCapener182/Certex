#!/usr/bin/env bash
# Run Supabase migrations in order. Requires DATABASE_URL (Supabase connection string).
# From project root: ./scripts/run-migrations.sh
# Or: DATABASE_URL='postgresql://...' ./scripts/run-migrations.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MIGRATIONS_DIR="$PROJECT_ROOT/supabase/migrations"

if [ -f "$PROJECT_ROOT/.env" ]; then
  set -a
  source "$PROJECT_ROOT/.env"
  set +a
fi

if [ -z "${DATABASE_URL}" ]; then
  echo "DATABASE_URL is not set."
  echo "Get it from: Supabase Dashboard → Project Settings → Database → Connection string (URI)."
  echo "Then run: DATABASE_URL='postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres' ./scripts/run-migrations.sh"
  exit 1
fi

# Migrations in order (exclude TEMPLATE)
MIGRATIONS=(
  "20260222143000_initial_schema.sql"
  "20260222150000_rls_and_access.sql"
  "20260222153000_rpc_and_realtime.sql"
  "20260222164000_qr_labels_and_certificate_rendering.sql"
  "20260222173000_marketplace_pricing_dispatch.sql"
  "20260222190000_certificate_artifact_storage_and_signed_url_payload.sql"
  "20260222203000_pricing_engine_quote_lock_adjustment_settlement.sql"
  "20260222224500_take_rate_floor_and_going_rate.sql"
  "20260226213000_audit_company_bidding_assignment_and_dispatch.sql"
  "20260226214000_template_studio_and_weighted_scoring.sql"
  "20260226215000_evidence_ai_provenance_and_verification.sql"
  "20260226220000_capa_finance_analytics.sql"
  "20260226221000_integrations_mobile_enterprise.sql"
  "20260226222000_quality_harness_and_release_readiness.sql"
)

echo "Running ${#MIGRATIONS[@]} migrations..."
for f in "${MIGRATIONS[@]}"; do
  path="$MIGRATIONS_DIR/$f"
  if [ ! -f "$path" ]; then
    echo "Missing: $path"
    exit 1
  fi
  echo "  → $f"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$path" -q
done
echo "Done."
