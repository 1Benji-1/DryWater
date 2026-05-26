#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

flutter run -d linux \
  --dart-define=API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:8000}" \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:?Falta SUPABASE_URL en frontend/.env}" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY:?Falta SUPABASE_PUBLISHABLE_KEY en frontend/.env}"
