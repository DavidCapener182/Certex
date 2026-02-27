#!/usr/bin/env bash
# Repair remaining remote-only versions by parsing db push error, then push.
# Run from project root: ./scripts/repair-and-push.sh

set -e
cd "$(dirname "$0")/.."

while true; do
  echo "Running db push..."
  OUT=$(npx supabase db push 2>&1) || true
  echo "$OUT"
  if echo "$OUT" | grep -q "Finished supabase db push"; then
    echo "Success."
    exit 0
  fi
  if ! echo "$OUT" | grep -q "supabase migration repair --status reverted"; then
    echo "Unexpected output, exiting."
    exit 1
  fi
  VERSIONS=$(echo "$OUT" | sed 's/.*reverted //' | sed 's/And update.*//' | tr ' ' '\n' | grep -E '^202[0-9]{11}$' | sort -u)
  COUNT=$(echo "$VERSIONS" | grep -c . || true)
  if [ -z "$COUNT" ] || [ "$COUNT" -eq 0 ]; then
    echo "Could not parse versions, exiting."
    exit 1
  fi
  echo "Repairing $COUNT versions..."
  for v in $VERSIONS; do
    npx supabase migration repair --status reverted "$v" 2>/dev/null || true
  done
  echo "Retrying in 5s..."
  sleep 5
done
