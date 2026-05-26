#!/usr/bin/env bash
# Full local run: start emulator → install app → run Maestro scenarios → stop emulator.
#
# Usage: ./scripts/run-scenarios.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

cleanup() {
  echo ""
  echo "=== Shutting down emulator ==="
  "${SCRIPT_DIR}/stop-emulator.sh" || true
}
trap cleanup EXIT

echo "=== Starting emulator ==="
"${SCRIPT_DIR}/start-emulator.sh"

echo "=== Waiting for device ==="
"${SCRIPT_DIR}/wait-for-device.sh"

echo "=== Installing MetaMask APK ==="
adb uninstall "${APP_ID}" 2>/dev/null || true
"${SCRIPT_DIR}/install-app.sh"

echo "=== Running Maestro scenarios ==="
"${SCRIPT_DIR}/run-maestro.sh"

echo ""
echo "=== All scenarios finished successfully ==="
