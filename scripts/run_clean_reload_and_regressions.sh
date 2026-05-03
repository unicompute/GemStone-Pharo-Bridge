#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - qwen/Pharo 13.0 - qwen.image}"
JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"
RELOAD_STATUS="pending"
UNIT_STATUS="pending"
PREFLIGHT_STATUS="skipped"
LIVE_STATUS="skipped"
WORK_DIR="${2:-$(dirname "${SRC_IMAGE}")}"
WORK_IMAGE="$(gbs_prepare_work_image "${SRC_IMAGE}" "${WORK_DIR}" "cleanreload")"

emit_summary() {
  local result="$1"
  local code="$2"
  local json_payload=""
  echo "CLEAN_RELOAD_AND_REGRESSION_SUMMARY result=${result} code=${code} reload=${RELOAD_STATUS} unit=${UNIT_STATUS} preflight=${PREFLIGHT_STATUS} live=${LIVE_STATUS} work_image=${WORK_IMAGE}"
  if [[ "${JSON_SUMMARY}" == "1" ]]; then
    printf -v json_payload '{"result":"%s","code":"%s","reload":"%s","unit":"%s","preflight":"%s","live":"%s","work_image":"%s"}' \
      "$(gbs_json_escape "${result}")" \
      "$(gbs_json_escape "${code}")" \
      "$(gbs_json_escape "${RELOAD_STATUS}")" \
      "$(gbs_json_escape "${UNIT_STATUS}")" \
      "$(gbs_json_escape "${PREFLIGHT_STATUS}")" \
      "$(gbs_json_escape "${LIVE_STATUS}")" \
      "$(gbs_json_escape "${WORK_IMAGE}")"
    printf 'CLEAN_RELOAD_AND_REGRESSION_SUMMARY_JSON %s\n' "${json_payload}"
    gbs_write_json_summary_file "full-lane-summary.json" "${json_payload}"
  fi
  gbs_append_summary_line "### Full Lane"
  gbs_append_summary_line "- result: \`${result}\`"
  gbs_append_summary_line "- code: \`${code}\`"
  gbs_append_summary_line "- reload: \`${RELOAD_STATUS}\`"
  gbs_append_summary_line "- unit: \`${UNIT_STATUS}\`"
  gbs_append_summary_line "- preflight: \`${PREFLIGHT_STATUS}\`"
  gbs_append_summary_line "- live: \`${LIVE_STATUS}\`"
}

extract_summary_code() {
  local output="$1"
  printf '%s\n' "${output}" | sed -n 's/.* code=\([^ ]*\).*/\1/p' | tail -1
}

extract_summary_status() {
  local output="$1"
  local field="$2"
  printf '%s\n' "${output}" | sed -n "s/.* ${field}=\\([^ ]*\\).*/\\1/p" | tail -1
}

echo "Using work image: ${WORK_IMAGE}"

reload_output="$(HOME=/tmp/pharo-clean-auto/home GBS_WORK_IMAGE="${WORK_IMAGE}" GBS_VERIFY_LANE='full' "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/clean_reload_gemstone.st" 2>&1 || true)"
echo "${reload_output}"
if grep -q "LOAD_ERROR" <<< "${reload_output}" || grep -q "NO_COMPAT_SOURCE_SCAN_FAILED" <<< "${reload_output}" || grep -q "NO_COMPATIBILITY_PROOF_FAILED" <<< "${reload_output}" || grep -q "ARCHITECTURE_BOUNDARY_FAILED" <<< "${reload_output}" || grep -q "PACKAGE_OWNERSHIP_DRIFT_FAILED" <<< "${reload_output}"; then
  RELOAD_STATUS="failed"
  emit_summary "FAIL" "CLEAN_RELOAD_FAILED"
  echo "Clean reload failed." >&2
  exit 1
fi
RELOAD_STATUS="ok"
UNIT_STATUS="$(extract_summary_status "${reload_output}" "unit")"
PREFLIGHT_STATUS="$(extract_summary_status "${reload_output}" "preflight")"
LIVE_STATUS="$(extract_summary_status "${reload_output}" "live")"
UNIT_STATUS="${UNIT_STATUS:-pending}"
PREFLIGHT_STATUS="${PREFLIGHT_STATUS:-skipped}"
LIVE_STATUS="${LIVE_STATUS:-skipped}"
if grep -q "CLEAN_RELOAD_AND_REGRESSION_SUMMARY result=FAIL" <<< "${reload_output}" || ! grep -q "CLEAN_RELOAD_AND_REGRESSION_RUN_DONE" <<< "${reload_output}"; then
  emit_summary "FAIL" "$(extract_summary_code "${reload_output}")"
  echo "In-process post-reload verification run failed." >&2
  exit 1
fi

emit_summary "OK" "CLEAN_RELOAD_AND_REGRESSION_RUN_DONE"
echo "CLEAN_RELOAD_AND_REGRESSION_RUN_DONE"
