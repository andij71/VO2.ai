#!/usr/bin/env bash
# Build a release IPA archive for App Store / TestFlight upload.
#
# Reuses the same .env file as run.sh — single source of truth for build-time
# secrets (STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET).
#
# Output:
#   build/ios/archive/Runner.xcarchive  ← open in Xcode Organizer to distribute
#   build/ios/ipa/                      ← .ipa export (export-method dependent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
cd "$APP_DIR"

if [[ ! -f .env ]]; then
  echo "❌ .env missing. Copy .env.sample → .env and fill in your Strava credentials."
  echo "   Get them at https://www.strava.com/settings/api"
  exit 1
fi

# Source .env the same way run.sh does
set -a
# shellcheck disable=SC1091
source .env
set +a

if [[ -z "${STRAVA_CLIENT_ID:-}" || -z "${STRAVA_CLIENT_SECRET:-}" ]]; then
  echo "❌ STRAVA_CLIENT_ID or STRAVA_CLIENT_SECRET not set in .env"
  exit 1
fi

echo "🔨 Building release IPA…"
flutter pub get
flutter build ipa --release \
  --dart-define=STRAVA_CLIENT_ID="$STRAVA_CLIENT_ID" \
  --dart-define=STRAVA_CLIENT_SECRET="$STRAVA_CLIENT_SECRET" \
  "$@"

echo ""
echo "✅ Build complete."
echo "   Archive: build/ios/archive/Runner.xcarchive"
echo "   IPA:     build/ios/ipa/"
echo ""
echo "Next: Xcode → Window → Organizer → select archive → Distribute App → App Store Connect."
