#!/usr/bin/env bash
# scripts/screenshots.sh
#
# Helper for capturing App Store screenshots in the Flutter iOS simulator.
#
# Apple requires:
#   - 6.9" iPhone: 1320 x 2868 px (iPhone 16 Pro Max, iPhone 17 Pro Max)
#     Minimum 3 screenshots, maximum 10. This is the ONLY required size
#     since April 2025.
#   - 6.5" iPhone (optional, 1284 x 2778): for older devices. Apple will
#     scale 6.9" screenshots down automatically if you skip this.
#   - 13" iPad (optional, 2064 x 2752): only if you support iPad.
#
# Workflow:
#   1. ./scripts/screenshots.sh boot      # boots the right simulator
#   2. ./scripts/screenshots.sh run       # builds + installs + launches the app
#   3. Navigate the app manually. When on a screen you want to capture:
#        ./scripts/screenshots.sh shot <name>
#      e.g. ./scripts/screenshots.sh shot 01_dashboard
#   4. ./scripts/screenshots.sh list      # shows what you've captured
#   5. Screenshots are saved to ./screenshots/6.9/ in the correct size.
#
# Requirements:
#   - Xcode with iOS 18+ simulators installed
#   - Flutter in PATH
#   - ImageMagick (`brew install imagemagick`) for the resize step

set -euo pipefail

# -- configuration -----------------------------------------------------
SIMULATOR_NAME="iPhone 16 Pro Max"
OUTPUT_DIR="screenshots/6.9"
TARGET_WIDTH=1320
TARGET_HEIGHT=2868

# The status bar override ("9:41", full battery, full signal) — Apple
# strongly prefers clean status bars on marketing screenshots.
STATUS_BAR_TIME="9:41"

# ----------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

mkdir -p "$OUTPUT_DIR"

# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------

get_device_udid() {
  xcrun simctl list devices available \
    | grep -E "^\s*${SIMULATOR_NAME} \(" \
    | head -n1 \
    | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' \
    || true
}

require_udid() {
  local udid
  udid="$(get_device_udid)"
  if [ -z "$udid" ]; then
    echo "ERROR: Simulator '$SIMULATOR_NAME' not found."
    echo "Available simulators:"
    xcrun simctl list devices available | grep "iPhone"
    exit 1
  fi
  echo "$udid"
}

require_imagemagick() {
  if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
    echo "ERROR: ImageMagick is required. Install with: brew install imagemagick"
    exit 1
  fi
}

# ----------------------------------------------------------------------
# Commands
# ----------------------------------------------------------------------

cmd_boot() {
  local udid
  udid="$(require_udid)"
  echo "Booting $SIMULATOR_NAME ($udid)..."

  # Boot if not already booted
  if ! xcrun simctl list devices | grep "$udid" | grep -q Booted; then
    xcrun simctl boot "$udid"
  fi
  open -a Simulator

  # Wait for boot to finish, then apply clean status bar
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl status_bar "$udid" override \
    --time "$STATUS_BAR_TIME" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --batteryState charged \
    --batteryLevel 100

  echo "Simulator ready."
}

cmd_run() {
  local udid
  udid="$(require_udid)"
  echo "Building and launching app on $udid..."
  flutter run -d "$udid" --release
}

cmd_shot() {
  require_imagemagick

  local name="${1:-}"
  if [ -z "$name" ]; then
    echo "Usage: $0 shot <name>"
    echo "Example: $0 shot 01_dashboard"
    exit 1
  fi

  local udid
  udid="$(require_udid)"

  local raw_path="${OUTPUT_DIR}/${name}.raw.png"
  local final_path="${OUTPUT_DIR}/${name}.png"

  echo "Capturing simulator screen..."
  xcrun simctl io "$udid" screenshot "$raw_path"

  # simctl captures at device resolution with Retina scaling.
  # Force exact App Store dimensions (resize, no crop, no aspect-ratio lock).
  local magick_cmd
  if command -v magick >/dev/null 2>&1; then
    magick_cmd="magick"
  else
    magick_cmd="convert"
  fi

  echo "Resizing to ${TARGET_WIDTH}x${TARGET_HEIGHT}..."
  $magick_cmd "$raw_path" \
    -resize "${TARGET_WIDTH}x${TARGET_HEIGHT}!" \
    -quality 95 \
    "$final_path"

  rm "$raw_path"

  local size
  size=$($magick_cmd identify -format "%wx%h" "$final_path")
  echo "Saved: $final_path ($size)"
}

cmd_list() {
  echo "Screenshots in $OUTPUT_DIR:"
  if [ -d "$OUTPUT_DIR" ]; then
    ls -lh "$OUTPUT_DIR" 2>/dev/null || echo "  (empty)"
  else
    echo "  (directory does not exist yet)"
  fi
}

cmd_clean_status() {
  local udid
  udid="$(require_udid)"
  xcrun simctl status_bar "$udid" clear
  echo "Status bar override cleared."
}

cmd_help() {
  cat <<EOF
Usage: $0 <command> [args]

Commands:
  boot              Boot the $SIMULATOR_NAME simulator and apply a clean
                    status bar (9:41, full battery, full wifi).
  run               flutter run --release on the simulator.
  shot <name>       Capture the current simulator screen, resize to
                    ${TARGET_WIDTH}x${TARGET_HEIGHT} and save to ${OUTPUT_DIR}/<name>.png
  list              List captured screenshots.
  clean-status      Remove the status bar override (restores live clock).

Workflow:
  $0 boot
  $0 run
  # navigate the app to the first screen you want
  $0 shot 01_welcome
  # navigate to next screen
  $0 shot 02_dashboard
  # ...
  $0 list

Recommended captures for App Store (pick the 3-5 best):
  01_welcome        — app first-launch / hero screen
  02_goal_setup     — goal selection UI
  03_dashboard      — daily overview with the AI plan
  04_plan           — weekly plan breakdown
  05_chat           — AI coach chat
  06_strava         — Strava integration settings
EOF
}

# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------
case "${1:-help}" in
  boot)          cmd_boot ;;
  run)           cmd_run ;;
  shot)          shift; cmd_shot "${1:-}" ;;
  list)          cmd_list ;;
  clean-status)  cmd_clean_status ;;
  help|--help|-h) cmd_help ;;
  *)
    echo "Unknown command: $1"
    echo ""
    cmd_help
    exit 1
    ;;
esac
