#!/usr/bin/env bash
set -euo pipefail

BOOKS="${1:-1200}"
FLOORS="${2:-4}"
SHELVES_PER_FLOOR="${3:-12}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$APP_DIR"

echo "Seeding full local DB with books=$BOOKS floors=$FLOORS shelves_per_floor=$SHELVES_PER_FLOOR"
flutter run \
  --dart-define=SEED_FULL_DATABASE=true \
  --dart-define=SEED_BOOKS="$BOOKS" \
  --dart-define=SEED_FLOORS="$FLOORS" \
  --dart-define=SEED_SHELVES_PER_FLOOR="$SHELVES_PER_FLOOR"
