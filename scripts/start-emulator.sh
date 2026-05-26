#!/usr/bin/env bash
# Start a pinned Android SDK emulator for Maestro tests.
# Requires ANDROID_HOME or ANDROID_SDK_ROOT. Run wait-for-device.sh after boot starts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" ]]; then
  echo "ERROR: ANDROID_HOME or ANDROID_SDK_ROOT must be set."
  echo "Install Android Studio / command-line tools and export ANDROID_HOME."
  exit 1
fi

export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT}}"
# shellcheck source=android-sdk-path.sh
source "${SCRIPT_DIR}/android-sdk-path.sh"
_require_sdkmanager  # also sets JAVA_HOME via _setup_java

echo "Installing Android SDK components (API ${ANDROID_API_LEVEL})..."
echo "System image: ${ANDROID_SYSTEM_IMAGE}"
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager --install \
  "platform-tools" \
  "emulator" \
  "platforms;android-${ANDROID_API_LEVEL}" \
  "${ANDROID_SYSTEM_IMAGE}"

if ! avdmanager list avd | grep -q "Name: ${AVD_NAME}"; then
  echo "Creating AVD: ${AVD_NAME}"
  echo "no" | avdmanager create avd \
    -n "${AVD_NAME}" \
    -k "${ANDROID_SYSTEM_IMAGE}" \
    -d "${EMULATOR_PROFILE}" \
    --force
else
  echo "AVD already exists: ${AVD_NAME}"
fi

# Kill any existing emulator with the same AVD name (best effort)
adb devices 2>/dev/null | grep emulator || true

echo "Starting emulator in background..."
emulator -avd "${AVD_NAME}" -no-snapshot-save -no-boot-anim &
EMULATOR_PID=$!

echo "Emulator started (PID ${EMULATOR_PID})."
echo "Next: ./scripts/wait-for-device.sh"
echo ""
echo "Note: Hardware acceleration (KVM on Linux, Hypervisor on macOS) greatly speeds boot."
