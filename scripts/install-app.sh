#!/usr/bin/env bash
# Install the pinned MetaMask APK onto the connected emulator/device.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" ]]; then
  export ANDROID_HOME="${ANDROID_SDK_ROOT:-}"
fi
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
export PATH="${ANDROID_HOME}/platform-tools:${PATH}"

if [[ ! -f "${APK_PATH}" ]]; then
  echo "ERROR: APK not found at ${APK_PATH}"
  echo "Place a fixed MetaMask APK there. See apps/README.md"
  exit 1
fi

DEVICE_COUNT="$(adb devices | grep -c 'device$' || true)"
if [[ "${DEVICE_COUNT}" -lt 1 ]]; then
  echo "ERROR: No adb device connected. Run start-emulator.sh and wait-for-device.sh first."
  exit 1
fi

echo "Installing ${APK_PATH} ..."
adb install -r "${APK_PATH}"
echo "Installed ${APP_ID}"
