#!/usr/bin/env bash
# Builds the database from scratch, then runs every query and saves results as CSV.
# Usage: DATABASE_URL=postgresql://user:pass@host:5432/db ./scripts/run_all.sh
set -euo pipefail
cd "$(dirname "$0")/.."
DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/portfolio}"
PSQL=(psql "$DB_URL" -v ON_ERROR_STOP=1 -q -X)

echo "Building schema, seed data and views..."
for f in sql/*.sql; do "${PSQL[@]}" -f "$f"; done

echo "Running analysis queries..."
mkdir -p results
for f in queries/*.sql; do
  out="results/$(basename "$f" .sql).csv"
  "${PSQL[@]}" --csv -f "$f" > "$out"
  echo "  ✓ $(basename "$f")  →  $out"
done
echo "Done."
