#!/usr/bin/env bash
# Run inside android-emulator-runner (one script invocation — exports persist).
# Expects TEST_PASSWORD_B64 and TEST_SEED_PHRASE_B64 from the Prepare test credentials step.

set -euo pipefail

export PATH="${HOME}/.maestro/bin:${PATH}"

if [[ -z "${TEST_PASSWORD_B64:-}" || -z "${TEST_SEED_PHRASE_B64:-}" ]]; then
  echo "ERROR: TEST_PASSWORD_B64 or TEST_SEED_PHRASE_B64 is not set"
  exit 1
fi

export TEST_PASSWORD="$(printf '%s' "${TEST_PASSWORD_B64}" | base64 -d)"
export TEST_SEED_PHRASE="$(printf '%s' "${TEST_SEED_PHRASE_B64}" | base64 -d)"

if [[ -z "${TEST_PASSWORD}" || -z "${TEST_SEED_PHRASE}" ]]; then
  echo "ERROR: decoded credentials are empty"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

adb install -r apps/metamask.apk
mkdir -p maestro-ci-output

maestro test \
  maestro/flows/01-import-wallet.yaml \
  maestro/flows/02-login-with-password.yaml \
  -e "TEST_PASSWORD=${TEST_PASSWORD}" \
  -e "TEST_SEED_PHRASE=${TEST_SEED_PHRASE}" \
  --test-output-dir maestro-ci-output \
  --debug-output maestro-ci-output \
  --format html \
  --output maestro-ci-output/report.html

cp -a "${HOME}/.maestro/tests/." maestro-ci-output/maestro-debug/ 2>/dev/null || true
