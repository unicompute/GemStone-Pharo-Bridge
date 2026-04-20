#!/usr/bin/env bash
set -euo pipefail

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image}"
SRC_DIR="$(dirname "${SRC_IMAGE}")"
SRC_BASE="$(basename "${SRC_IMAGE}" .image)"
WORK_DIR="${2:-${SRC_DIR}}"
WORK_IMAGE="${WORK_DIR}/${SRC_BASE} - graphartifacts.image"
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

artifact_output="$(HOME=/tmp/pharo-clean-auto/home GBS_LOAD_GROUP=default GBS_RELOAD_CHECK_MODE=default GBS_GENERATE_CONTRACT_ARTIFACTS=1 "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/clean_reload_gemstone.st" 2>&1 || true)"
echo "${artifact_output}"
if grep -q "LOAD_ERROR" <<< "${artifact_output}" || ! grep -q "GENERATED_CONTRACT_ARTIFACTS_OK" <<< "${artifact_output}"; then
  echo "Contract artifact generation failed." >&2
  exit 1
fi
