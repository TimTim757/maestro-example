#!/usr/bin/env bash
# Start Maestro Studio with TEST_* vars from .env.local exported into the shell.
# Studio does not read .env.local or scripts/run-maestro.sh -e flags by itself.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

if [[ -z "${TEST_PASSWORD}" || -z "${TEST_SEED_PHRASE}" ]]; then
  echo "ERROR: TEST_PASSWORD and TEST_SEED_PHRASE must be set in .env.local (see .env.example)."
  exit 1
fi

export TEST_PASSWORD TEST_SEED_PHRASE

if ! command -v maestro >/dev/null 2>&1; then
  export PATH="${HOME}/.maestro/bin:${PATH}"
fi

DEVICE_COUNT="$(adb devices 2>/dev/null | grep -c 'device$' || true)"
if [[ "${DEVICE_COUNT}" -lt 1 ]]; then
  echo "WARNING: No adb device. Start the emulator first (./scripts/start-emulator.sh)."
fi

echo "Starting Maestro Studio with TEST_PASSWORD and TEST_SEED_PHRASE from .env.local."
echo "If variables are still empty in Studio, add them under Env → Manage Environments."
echo "Close Studio before running: ./scripts/run-maestro.sh"
echo ""

cd "${REPO_ROOT}"
exec maestro studio
