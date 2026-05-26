#!/usr/bin/env bash
# Wait until the Android emulator is booted and ready for adb commands.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" ]]; then
  export ANDROID_HOME="${ANDROID_SDK_ROOT:-}"
fi
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
export PATH="${ANDROID_HOME}/platform-tools:${PATH}"

echo "Waiting for device..."
adb wait-for-device

echo "Waiting for boot to complete..."
until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
  sleep 2
done

# Dismiss keyguard
adb shell input keyevent 82 >/dev/null 2>&1 || true

# Disable animations for faster, CI-like local runs
adb shell settings put global window_animation_scale 0 >/dev/null 2>&1 || true
adb shell settings put global transition_animation_scale 0 >/dev/null 2>&1 || true
adb shell settings put global animator_duration_scale 0 >/dev/null 2>&1 || true

echo "Device ready: $(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
