#!/bin/sh
set -a && source "$(dirname "$0")/.env" && set +a
flutter run \
  --dart-define=STRAVA_CLIENT_ID="$STRAVA_CLIENT_ID" \
  --dart-define=STRAVA_CLIENT_SECRET="$STRAVA_CLIENT_SECRET" \
  "$@"
