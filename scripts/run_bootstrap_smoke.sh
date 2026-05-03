#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image}"
WORK_DIR="${2:-$(dirname "${SRC_IMAGE}")}"
WORK_IMAGE="$(gbs_prepare_work_image "${SRC_IMAGE}" "${WORK_DIR}" "bootstrapsmoke")"
JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"
LOAD_GROUP="${GBS_BOOTSTRAP_SMOKE_LOAD_GROUP:-Core-Tests}"
RELOAD_MODE="${GBS_BOOTSTRAP_SMOKE_RELOAD_MODE:-core-only}"

emit_summary() {
  local result="$1"
  local code="$2"
  local json_payload=""
  echo "BOOTSTRAP_SMOKE_SUMMARY result=${result} code=${code} load_group=${LOAD_GROUP} reload_mode=${RELOAD_MODE} work_image=${WORK_IMAGE}"
  if [[ "${JSON_SUMMARY}" == "1" ]]; then
    printf -v json_payload '{"result":"%s","code":"%s","load_group":"%s","reload_mode":"%s","work_image":"%s"}' \
      "$(gbs_json_escape "${result}")" \
      "$(gbs_json_escape "${code}")" \
      "$(gbs_json_escape "${LOAD_GROUP}")" \
      "$(gbs_json_escape "${RELOAD_MODE}")" \
      "$(gbs_json_escape "${WORK_IMAGE}")"
    printf 'BOOTSTRAP_SMOKE_SUMMARY_JSON %s\n' "${json_payload}"
    gbs_write_json_summary_file "bootstrap-smoke-summary.json" "${json_payload}"
  fi
  gbs_append_summary_line "### Bootstrap Smoke"
  gbs_append_summary_line "- result: \`${result}\`"
  gbs_append_summary_line "- code: \`${code}\`"
  gbs_append_summary_line "- load-group: \`${LOAD_GROUP}\`"
  gbs_append_summary_line "- reload-mode: \`${RELOAD_MODE}\`"
}

echo "Using work image: ${WORK_IMAGE}"

reload_output="$(HOME=/tmp/pharo-clean-auto/home GBS_LOAD_GROUP="${LOAD_GROUP}" GBS_RELOAD_CHECK_MODE="${RELOAD_MODE}" "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/clean_reload_gemstone.st" 2>&1 || true)"
echo "${reload_output}"
if grep -q "LOAD_ERROR" <<< "${reload_output}" \
  || grep -q "ARCHITECTURE_BOUNDARY_FAILED" <<< "${reload_output}" \
  || grep -q "PACKAGE_OWNERSHIP_DRIFT_FAILED" <<< "${reload_output}" \
  || grep -q "NO_COMPAT_SOURCE_SCAN_FAILED" <<< "${reload_output}" \
  || grep -q "NO_COMPATIBILITY_PROOF_FAILED" <<< "${reload_output}" \
  || grep -q "CORE_ONLY_CLEAN_RELOAD_FAILED" <<< "${reload_output}"; then
  emit_summary "FAIL" "BOOTSTRAP_SMOKE_RELOAD_FAILED"
  echo "Bootstrap smoke reload phase failed." >&2
  exit 1
fi

probe_output="$(HOME=/tmp/pharo-clean-auto/home GBS_LOAD_GROUP="${LOAD_GROUP}" "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/check_bootstrap_smoke_group.st" 2>&1 || true)"
if grep -q "BOOTSTRAP_SMOKE_FAILED" <<< "${probe_output}" || ! grep -q "BOOTSTRAP_SMOKE_OK" <<< "${probe_output}"; then
  for attempt in 2 3; do
    sleep 1
    probe_output="$(HOME=/tmp/pharo-clean-auto/home GBS_LOAD_GROUP="${LOAD_GROUP}" "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/check_bootstrap_smoke_group.st" 2>&1 || true)"
    if ! grep -q "BOOTSTRAP_SMOKE_FAILED" <<< "${probe_output}" && grep -q "BOOTSTRAP_SMOKE_OK" <<< "${probe_output}"; then
      break
    fi
  done
fi
echo "${probe_output}"
if grep -q "BOOTSTRAP_SMOKE_FAILED" <<< "${probe_output}" || ! grep -q "BOOTSTRAP_SMOKE_OK" <<< "${probe_output}"; then
  emit_summary "FAIL" "BOOTSTRAP_SMOKE_PROBE_FAILED"
  echo "Bootstrap smoke probe phase failed." >&2
  exit 1
fi

emit_summary "OK" "BOOTSTRAP_SMOKE_OK"
echo "BOOTSTRAP_SMOKE_DONE"
