#!/usr/bin/env bash
# Measures the settings screen of the installed APK on a running device.
#
# The photo order row used to squeeze its title until it wrapped one letter per
# line (issue 05). Reading the height of the row from the view hierarchy detects
# that without comparing pixels, and the screenshots are kept for a human look.
#
# usage: device_test.sh <package>
set -euo pipefail

PACKAGE="${1:-io.github.saimonn.librephotoframe}"
ACTIVITY="$PACKAGE/.MainActivity"
CONFIG_DIR="/data/user/0/$PACKAGE/app_flutter"
OUT_DIR="artifacts"
ROW_PREFIX="Trier les photos par"

mkdir -p "$OUT_DIR"

dump() {
  adb shell rm -f /sdcard/ui.xml
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null
  # The console of the emulator returns the dump in latin-1 where the console
  # of the frame returns UTF-8, so the labels are compared on their ASCII part
  # only ("Paramètres" reads as "Paramtres" either way).
  adb shell cat /sdcard/ui.xml | tr -cd '\11\12\15\40-\176' | tr '>' '\n'
}

# "width height" of the display, in physical pixels.
size() {
  adb shell wm size | sed -n 's/.*: \([0-9]*\)x\([0-9]*\).*/\1 \2/p' | tail -1
}

# Bounds "left top right bottom" of the row whose label starts with the argument.
bounds_of() {
  dump | grep -m1 "content-desc=\"$1" \
    | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]".*/\1 \2 \3 \4/p'
}

# French has the longest labels of the four shipped languages, so a row that no
# longer fits shows up there first.
cat > "$OUT_DIR/config.json" <<'JSON'
{
  "language": "fr",
  "clock_format": "12",
  "show_clock": true,
  "show_photo_info": true,
  "screen_orientation": "portraitUp"
}
JSON

adb shell mkdir -p "$CONFIG_DIR"
adb push "$OUT_DIR/config.json" "$CONFIG_DIR/config.json" >/dev/null
owner="$(adb shell "stat -c '%u:%g' $CONFIG_DIR" | tr -d '\r')"
adb shell "chown $owner $CONFIG_DIR/config.json"

# No dialog may cover the settings screen during the measurement.
for permission in READ_MEDIA_IMAGES READ_MEDIA_VIDEO READ_MEDIA_VISUAL_USER_SELECTED READ_EXTERNAL_STORAGE POST_NOTIFICATIONS; do
  adb shell pm grant "$PACKAGE" "android.permission.$permission" || true
done

adb shell am force-stop "$PACKAGE"
adb shell input keyevent KEYCODE_WAKEUP
adb shell am start -n "$ACTIVITY" >/dev/null
# The app scans the media store and loads the first photo on start.
sleep 30

read -r width height <<<"$(size)"
adb shell input tap $((width / 2)) $((height / 2))
sleep 10

if ! dump | grep -q 'content-desc="Param'; then
  echo "The settings did not open, retrying once"
  adb shell input tap $((width / 2)) $((height / 2))
  sleep 10
fi

if ! dump | grep -q 'content-desc="Param'; then
  echo "FAIL: the settings screen did not open"
  adb exec-out screencap -p > "$OUT_DIR/no-settings.png" || true
  dump | grep -o 'content-desc="[^"]*"' | head -20
  exit 1
fi

# A row is only in the view hierarchy once the list has been scrolled to it.
for _ in $(seq 1 8); do
  if bounds_of "$ROW_PREFIX" > /dev/null; then
    break
  fi
  adb shell input swipe $((width / 2)) $((height * 3 / 4)) $((width / 2)) $((height / 4)) 500
  sleep 4
done

adb exec-out screencap -p > "$OUT_DIR/settings-fr.png" \
  || echo "WARN: no screenshot, the XML dump is the measurement"
dump > "$OUT_DIR/settings-fr.xml"

read -r left top right bottom <<<"$(bounds_of "$ROW_PREFIX")"
density="$(adb shell wm density | sed -n 's/.*: \([0-9]*\).*/\1/p' | tail -1)"
echo "Photo order row: $left $top $right $bottom, density $density"

if [[ -z "${bottom:-}" ]]; then
  echo "FAIL: the photo order row was not found in the view hierarchy"
  exit 1
fi

# Height in logical pixels: a normal row is 72 to 100, the broken one was 632.
logical_height=$(((bottom - top) * 160 / density))
echo "Photo order row height: $logical_height logical px"
if ((logical_height > 120)); then
  echo "FAIL: the photo order row is $logical_height logical px tall, the settings labels do not fit"
  exit 1
fi

echo "PASS: the settings rows fit, see $OUT_DIR/settings-fr.png"