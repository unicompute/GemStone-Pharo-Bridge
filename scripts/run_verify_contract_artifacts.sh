#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image}"
WORK_DIR="${2:-$(dirname "${SRC_IMAGE}")}"
WORK_IMAGE="$(gbs_prepare_work_image "${SRC_IMAGE}" "${WORK_DIR}" "artifactcheck")"
JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"

emit_summary() {
  local result="$1"
  local code="$2"
  local json_payload=""
  if [[ "${JSON_SUMMARY}" == "1" ]]; then
    printf -v json_payload '{"result":"%s","code":"%s","work_image":"%s"}' \
      "$(gbs_json_escape "${result}")" \
      "$(gbs_json_escape "${code}")" \
      "$(gbs_json_escape "${WORK_IMAGE}")"
    printf 'ARTIFACT_FRESHNESS_SUMMARY_JSON %s\n' "${json_payload}"
    gbs_write_json_summary_file "artifact-freshness-summary.json" "${json_payload}"
  fi
  gbs_append_summary_line "### Artifact Freshness"
  gbs_append_summary_line "- result: \`${result}\`"
  gbs_append_summary_line "- code: \`${code}\`"
}

echo "Using work image: ${WORK_IMAGE}"

artifact_output="$(HOME=/tmp/pharo-clean-auto/home GBS_LOAD_GROUP=default GBS_RELOAD_CHECK_MODE=default GBS_VERIFY_CONTRACT_ARTIFACTS=1 "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/clean_reload_gemstone.st" 2>&1 || true)"
echo "${artifact_output}"
if grep -q "LOAD_ERROR" <<< "${artifact_output}" \
  || grep -q "ARCHITECTURE_BOUNDARY_FAILED" <<< "${artifact_output}" \
  || grep -q "PACKAGE_OWNERSHIP_DRIFT_FAILED" <<< "${artifact_output}" \
  || grep -q "NO_COMPAT_SOURCE_SCAN_FAILED" <<< "${artifact_output}" \
  || grep -q "NO_COMPATIBILITY_PROOF_FAILED" <<< "${artifact_output}" \
  || ! grep -q "CONTRACT_ARTIFACTS_FRESH_OK" <<< "${artifact_output}"; then
  emit_summary "FAIL" "CONTRACT_ARTIFACTS_FRESH_FAILED"
  echo "Contract artifact freshness check failed." >&2
  exit 1
fi

emit_summary "OK" "CONTRACT_ARTIFACTS_FRESH_OK"
echo "CONTRACT_ARTIFACT_FRESHNESS_CHECK_OK"
