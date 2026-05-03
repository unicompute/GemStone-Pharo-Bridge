#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image}"
WORK_DIR="${2:-$(dirname "${SRC_IMAGE}")}"
WORK_IMAGE="$(gbs_prepare_work_image "${SRC_IMAGE}" "${WORK_DIR}" "coreonly")"
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
    printf 'CORE_ONLY_SUMMARY_JSON %s\n' "${json_payload}"
    gbs_write_json_summary_file "core-only-summary.json" "${json_payload}"
  fi
  gbs_append_summary_line "### Core-only Lane"
  gbs_append_summary_line "- result: \`${result}\`"
  gbs_append_summary_line "- code: \`${code}\`"
}

extract_summary_code() {
  local output="$1"
  printf '%s\n' "${output}" | sed -n 's/.* code=\([^ ]*\).*/\1/p' | tail -1
}

echo "Using work image: ${WORK_IMAGE}"

reload_output="$(HOME=/tmp/pharo-clean-auto/home GBS_WORK_IMAGE="${WORK_IMAGE}" GBS_LOAD_GROUP='Core-Tests' GBS_RELOAD_CHECK_MODE='core-only' GBS_VERIFY_LANE='core-only' "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/clean_reload_gemstone.st" 2>&1 || true)"
echo "${reload_output}"
if grep -q "LOAD_ERROR" <<< "${reload_output}" || grep -q "CORE_ONLY_CHECK_FAIL" <<< "${reload_output}" || grep -q "CORE_ONLY_CLEAN_RELOAD_FAILED" <<< "${reload_output}" || grep -q "ARCHITECTURE_BOUNDARY_FAILED" <<< "${reload_output}" || grep -q "PACKAGE_OWNERSHIP_DRIFT_FAILED" <<< "${reload_output}" || grep -q "NO_COMPAT_SOURCE_SCAN_FAILED" <<< "${reload_output}" || grep -q "NO_COMPATIBILITY_PROOF_FAILED" <<< "${reload_output}" || grep -q "CORE_ONLY_VERIFICATION_SUMMARY result=FAIL" <<< "${reload_output}" || ! grep -q "BRIDGE_CORE_ONLY_CHECK_OK" <<< "${reload_output}"; then
  emit_summary "FAIL" "$(extract_summary_code "${reload_output}")"
  echo "Core-only clean reload or verification failed." >&2
  exit 1
fi

emit_summary "OK" "BRIDGE_CORE_ONLY_CHECK_OK"
echo "BRIDGE_CORE_ONLY_CHECK_OK"
