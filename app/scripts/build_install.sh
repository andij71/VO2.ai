#!/usr/bin/env bash
# Build a release iOS app and install it on a connected device.
#
# Usage:
#   ./scripts/build_install.sh          # build + install
#   ./scripts/build_install.sh --debug  # debug build + install

set -euo pipefail

DEVICE_ID="00008140-001104AA1450801C"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
cd "$APP_DIR"

if [[ ! -f .env ]]; then
  echo "❌ .env missing. Copy .env.sample → .env and fill in your Strava credentials."
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

if [[ -z "${STRAVA_CLIENT_ID:-}" || -z "${STRAVA_CLIENT_SECRET:-}" ]]; then
  echo "❌ STRAVA_CLIENT_ID or STRAVA_CLIENT_SECRET not set in .env"
  exit 1
fi

MODE="--release"
if [[ "${1:-}" == "--debug" ]]; then
  MODE=""
  shift
fi

echo "🔨 Building iOS app…"
flutter build ios $MODE \
  --dart-define=STRAVA_CLIENT_ID="$STRAVA_CLIENT_ID" \
  --dart-define=STRAVA_CLIENT_SECRET="$STRAVA_CLIENT_SECRET" \
  "$@"

echo "📲 Installing on device $DEVICE_ID"
flutter install --device-id="$DEVICE_ID"

echo ""
echo "✅ Installed on device."
