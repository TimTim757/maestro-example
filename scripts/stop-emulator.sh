#!/usr/bin/env bash
# Stop the Android emulator started for Maestro tests.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" ]]; then
  export ANDROID_HOME="${ANDROID_SDK_ROOT:-}"
fi
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
export PATH="${ANDROID_HOME}/platform-tools:${PATH}"

if adb devices 2>/dev/null | grep -qE 'emulator-[0-9]+\s+device'; then
  echo "Stopping emulator (adb emu kill)..."
  adb emu kill || true
  # Wait until device disappears
  for _ in $(seq 1 30); do
    if ! adb devices 2>/dev/null | grep -qE 'emulator-[0-9]+\s+device'; then
      echo "Emulator stopped."
      exit 0
    fi
    sleep 1
  done
  echo "WARNING: Emulator may still be shutting down."
else
  echo "No running emulator found."
fi
