#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REACT_ENV_FILE="$ROOT_DIR/../motibakery_react/client/.env"

if [[ ! -f "$REACT_ENV_FILE" ]]; then
  echo "React env file not found: $REACT_ENV_FILE" >&2
  exit 1
fi

supabase_url="$(grep -E '^VITE_SUPABASE_URL=' "$REACT_ENV_FILE" | head -n1 | cut -d'=' -f2-)"
supabase_anon_key="$(grep -E '^VITE_SUPABASE_ANON_KEY=' "$REACT_ENV_FILE" | head -n1 | cut -d'=' -f2-)"

if [[ -z "${supabase_url:-}" || -z "${supabase_anon_key:-}" ]]; then
  echo "Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY in $REACT_ENV_FILE" >&2
  exit 1
fi

echo "Using Supabase URL from React env: $supabase_url"
exec flutter run \
  --dart-define="SUPABASE_URL=$supabase_url" \
  --dart-define="SUPABASE_ANON_KEY=$supabase_anon_key" \
  "$@"
