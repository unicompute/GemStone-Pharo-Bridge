#!/usr/bin/env bash
set -euo pipefail

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - qwen/Pharo 13.0 - qwen.image}"
SRC_DIR="$(dirname "${SRC_IMAGE}")"
SRC_BASE="$(basename "${SRC_IMAGE}" .image)"
WORK_DIR="${2:-${SRC_DIR}}"
WORK_IMAGE="${WORK_DIR}/${SRC_BASE} - cleanreload.image"
SRC_CHANGES="${SRC_IMAGE%.image}.changes"
WORK_CHANGES="${WORK_IMAGE%.image}.changes"

mkdir -p "${WORK_DIR}"
mkdir -p "${WORK_DIR}/pharo-local/ombu-sessions"
mkdir -p /tmp/pharo-clean-auto/home
cp -f "${SRC_IMAGE}" "${WORK_IMAGE}"
if [[ -f "${SRC_CHANGES}" ]]; then
  cp -f "${SRC_CHANGES}" "${WORK_CHANGES}"
fi

if ls "${SRC_DIR}"/Pharo*.sources >/dev/null 2>&1; then
  cp -f "${SRC_DIR}"/Pharo*.sources "${WORK_DIR}/" || true
fi

echo "Using work image: ${WORK_IMAGE}"

reload_output="$(HOME=/tmp/pharo-clean-auto/home "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/clean_reload_gemstone.st" 2>&1 || true)"
echo "${reload_output}"
if grep -q "LOAD_ERROR" <<< "${reload_output}"; then
  echo "Clean reload failed." >&2
  exit 1
fi

unit_output="$(HOME=/tmp/pharo-clean-auto/home GBS_TEST_LANE=unit "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/run_all_package_regressions.st" 2>&1 || true)"
echo "${unit_output}"
if grep -q "LOAD_ERROR" <<< "${unit_output}" || grep -q "BRIDGE_UNIT_REGRESSION_FAILED" <<< "${unit_output}"; then
  echo "Unit regression run failed." >&2
  exit 1
fi

if [[ -n "${GS_USER:-}" && -n "${GS_PASS:-}" ]]; then
  live_output="$(HOME=/tmp/pharo-clean-auto/home GBS_TEST_LANE=live GS_STONE="${GS_STONE:-gs64stone}" GS_USER="${GS_USER}" GS_PASS="${GS_PASS}" GS_SERVICE="${GS_SERVICE:-gemnetobject}" "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/run_all_package_regressions.st" 2>&1 || true)"
  echo "${live_output}"
  if grep -q "LOAD_ERROR" <<< "${live_output}" || grep -q "BRIDGE_LIVE_REGRESSION_FAILED" <<< "${live_output}"; then
    echo "Live regression run failed." >&2
    exit 1
  fi
else
  echo "LIVE_REGRESSION_SKIPPED: set GS_USER and GS_PASS to run integration lane"
fi

echo "CLEAN_RELOAD_AND_REGRESSION_RUN_DONE"
