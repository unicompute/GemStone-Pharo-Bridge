#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image}"
WORK_DIR="${2:-$(dirname "${SRC_IMAGE}")}"
WORK_IMAGE="$(gbs_prepare_work_image "${SRC_IMAGE}" "${WORK_DIR}" "graphartifacts")"

echo "Using work image: ${WORK_IMAGE}"

artifact_output="$(HOME=/tmp/pharo-clean-auto/home GBS_LOAD_GROUP=default GBS_RELOAD_CHECK_MODE=default GBS_GENERATE_CONTRACT_ARTIFACTS=1 "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/clean_reload_gemstone.st" 2>&1 || true)"
echo "${artifact_output}"
if grep -q "LOAD_ERROR" <<< "${artifact_output}" \
  || grep -q "ARCHITECTURE_BOUNDARY_FAILED" <<< "${artifact_output}" \
  || grep -q "PACKAGE_OWNERSHIP_DRIFT_FAILED" <<< "${artifact_output}" \
  || grep -q "NO_COMPAT_SOURCE_SCAN_FAILED" <<< "${artifact_output}" \
  || grep -q "NO_COMPATIBILITY_PROOF_FAILED" <<< "${artifact_output}" \
  || ! grep -q "GENERATED_CONTRACT_ARTIFACTS_OK" <<< "${artifact_output}"; then
  echo "Contract artifact generation failed." >&2
  exit 1
fi
