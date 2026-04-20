#!/usr/bin/env bash
set -euo pipefail

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image}"
SRC_DIR="$(dirname "${SRC_IMAGE}")"
SRC_BASE="$(basename "${SRC_IMAGE}" .image)"
WORK_DIR="${2:-${SRC_DIR}}"
WORK_IMAGE="${WORK_DIR}/${SRC_BASE} - coreonly.image"
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

reload_output="$(HOME=/tmp/pharo-clean-auto/home GBS_LOAD_GROUP='Core-Tests' GBS_RELOAD_CHECK_MODE='core-only' "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/clean_reload_gemstone.st" 2>&1 || true)"
echo "${reload_output}"
if grep -q "LOAD_ERROR" <<< "${reload_output}" || grep -q "CORE_ONLY_CHECK_FAIL" <<< "${reload_output}" || grep -q "CORE_ONLY_CLEAN_RELOAD_FAILED" <<< "${reload_output}" || grep -q "ARCHITECTURE_BOUNDARY_FAILED" <<< "${reload_output}" || grep -q "PACKAGE_OWNERSHIP_DRIFT_FAILED" <<< "${reload_output}"; then
  echo "Core-only clean reload check failed." >&2
  exit 1
fi

unit_output="$(HOME=/tmp/pharo-clean-auto/home GBS_LOAD_GROUP='Core-Tests' GBS_TEST_PACKAGES='GemStone-Pharo-Core-Tests' GBS_TEST_LANE=unit "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/run_all_package_regressions.st" 2>&1 || true)"
echo "${unit_output}"
if grep -q "LOAD_ERROR" <<< "${unit_output}" || grep -q "BRIDGE_UNIT_REGRESSION_FAILED" <<< "${unit_output}"; then
  echo "Core-only unit regression run failed." >&2
  exit 1
fi

echo "BRIDGE_CORE_ONLY_CHECK_OK"
