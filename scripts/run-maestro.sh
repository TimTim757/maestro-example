#!/usr/bin/env bash
# Install Maestro CLI if needed, then run all flows in maestro/flows/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" ]]; then
  export ANDROID_HOME="${ANDROID_SDK_ROOT:-}"
fi
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
export PATH="${ANDROID_HOME}/platform-tools:${PATH}"

install_maestro() {
  if command -v maestro >/dev/null 2>&1; then
    return 0
  fi
  echo "Maestro not found. Installing version ${MAESTRO_VERSION} ..."
  export MAESTRO_VERSION
  curl -Ls "https://get.maestro.mobile.dev" | bash
  export PATH="${HOME}/.maestro/bin:${PATH}"
}

install_maestro
export PATH="${HOME}/.maestro/bin:${PATH}"

if ! command -v maestro >/dev/null 2>&1; then
  echo "ERROR: maestro CLI is not available on PATH."
  exit 1
fi

DEVICE_COUNT="$(adb devices | grep -c 'device$' || true)"
if [[ "${DEVICE_COUNT}" -lt 1 ]]; then
  echo "ERROR: No adb device connected."
  exit 1
fi

if [[ "${DEVICE_COUNT}" -gt 1 ]]; then
  echo "WARNING: Multiple devices connected. Maestro will use the default device."
fi

if [[ -z "${TEST_PASSWORD}" ]]; then
  echo "ERROR: TEST_PASSWORD is not set. Add it to .env.local (see .env.example)."
  exit 1
fi
if [[ -z "${TEST_SEED_PHRASE}" ]]; then
  echo "ERROR: TEST_SEED_PHRASE is not set. Add it to .env.local (see .env.example)."
  exit 1
fi

MAESTRO_ENV_ARGS=(
  -e "TEST_PASSWORD=${TEST_PASSWORD}"
  -e "TEST_SEED_PHRASE=${TEST_SEED_PHRASE}"
)

FLOW_01="${REPO_ROOT}/maestro/flows/01-import-wallet.yaml"
FLOW_02="${REPO_ROOT}/maestro/flows/02-login-with-password.yaml"

echo "Running Maestro scenarios (version $(maestro --version 2>/dev/null || echo unknown)) ..."
echo "  1/2 ${FLOW_01##*/}"
echo "  2/2 ${FLOW_02##*/} (starts only after 1 succeeds)"
echo "Credentials loaded from .env.local (values not printed)."
cd "${REPO_ROOT}"

echo ""
echo "=== Scenario 1/2: import wallet ==="
maestro test "${FLOW_01}" "${MAESTRO_ENV_ARGS[@]}"

echo ""
echo "=== Scenario 2/2: log in with password ==="
maestro test "${FLOW_02}" "${MAESTRO_ENV_ARGS[@]}"
