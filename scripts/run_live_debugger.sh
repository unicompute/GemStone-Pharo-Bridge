#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/140-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 14.0 - clean/Pharo 14.0 - clean.image}"
WORK_DIR="${2:-$(dirname "${SRC_IMAGE}")}"
WORK_IMAGE="not-created"
JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"

emit_summary() {
  local result="$1"
  local code="$2"
  local run_count="${3:-0}"
  local failures="${4:-0}"
  local errors="${5:-0}"
  local json_payload=""
  echo "LIVE_DEBUGGER_LANE_SUMMARY result=${result} code=${code} run=${run_count} failures=${failures} errors=${errors} work_image=${WORK_IMAGE}"
  if [[ "${JSON_SUMMARY}" == "1" ]]; then
    printf -v json_payload '{"result":"%s","code":"%s","run":"%s","failures":"%s","errors":"%s","work_image":"%s"}' \
      "$(gbs_json_escape "${result}")" \
      "$(gbs_json_escape "${code}")" \
      "$(gbs_json_escape "${run_count}")" \
      "$(gbs_json_escape "${failures}")" \
      "$(gbs_json_escape "${errors}")" \
      "$(gbs_json_escape "${WORK_IMAGE}")"
    printf 'LIVE_DEBUGGER_LANE_SUMMARY_JSON %s\n' "${json_payload}"
    gbs_write_json_summary_file "live-debugger-summary.json" "${json_payload}"
  fi
  gbs_append_summary_line "### Live Debugger Lane"
  gbs_append_summary_line "- result: \`${result}\`"
  gbs_append_summary_line "- code: \`${code}\`"
  gbs_append_summary_line "- run: \`${run_count}\`"
  gbs_append_summary_line "- failures: \`${failures}\`"
  gbs_append_summary_line "- errors: \`${errors}\`"
}

extract_summary_field() {
  local line="$1"
  local field="$2"
  printf '%s\n' "${line}" | sed -n "s/.* ${field}=\\([^ ]*\\).*/\\1/p" | tail -1
}

MISSING_LIVE_ENV="$(gbs_missing_required_live_env_vars)"
if [[ -n "${MISSING_LIVE_ENV}" ]]; then
  emit_summary "FAIL" "LIVE_DEBUGGER_MISSING_ENV"
  gbs_append_summary_line "- live env: \`$(gbs_live_env_status_line "${MISSING_LIVE_ENV}")\`"
  echo "Missing required live debugger environment: ${MISSING_LIVE_ENV}" >&2
  echo "Set the missing variables before running make live-debugger." >&2
  exit 2
fi

WORK_IMAGE="$(gbs_prepare_work_image "${SRC_IMAGE}" "${WORK_DIR}" "livedebugger")"
gbs_register_work_image_cleanup "${WORK_IMAGE}"

echo "Using work image: ${WORK_IMAGE}"
preflight_output="$(bash ./scripts/run_live_preflight.sh "${WORK_IMAGE}" 2>&1 || true)"
echo "${preflight_output}"
gbs_write_evidence_file "live-debugger-preflight.log" "${preflight_output}"
if ! grep -q "LIVE_PREFLIGHT_SUMMARY result=OK code=LIVE_PREFLIGHT_OK" <<< "${preflight_output}"; then
  emit_summary "FAIL" "LIVE_DEBUGGER_PREFLIGHT_FAILED"
  echo "Live debugger preflight failed or skipped; refusing to run debugger acceptance tests against an unknown GemStone session." >&2
  exit 1
fi

debugger_output="$(HOME=/tmp/pharo-clean-auto/home GBS_WORK_IMAGE="${WORK_IMAGE}" GBS_LOAD_GROUP=default GBS_RELOAD_CHECK_MODE=default "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/run_live_debugger_regressions.st" 2>&1 || true)"
echo "${debugger_output}"
gbs_write_evidence_file "live-debugger-regression.log" "${debugger_output}"

summary_line="$(printf '%s\n' "${debugger_output}" | grep 'LIVE_DEBUGGER_SUMMARY result=' | tail -1 || true)"
if [[ -z "${summary_line}" ]]; then
  emit_summary "FAIL" "LIVE_DEBUGGER_RUNNER_FAILED"
  echo "Live debugger runner did not emit LIVE_DEBUGGER_SUMMARY." >&2
  exit 1
fi

if grep -q "LIVE_DEBUGGER_CLEANUP_WARN" <<< "${debugger_output}"; then
  emit_summary "FAIL" "LIVE_DEBUGGER_CLEANUP_WARN"
  echo "Live debugger cleanup warning detected; refusing to accept leaked or unverifiable debug process cleanup." >&2
  exit 1
fi

if grep -q "GBS_REMOTE_PROCESS_COMMAND_ERROR" <<< "${debugger_output}"; then
  emit_summary "FAIL" "LIVE_DEBUGGER_PROCESS_COMMAND_ERROR"
  echo "Live debugger remote process command error detected." >&2
  exit 1
fi

RESULT="$(extract_summary_field "${summary_line}" result)"
CODE="$(extract_summary_field "${summary_line}" code)"
RUN_COUNT="$(extract_summary_field "${summary_line}" run)"
FAILURES="$(extract_summary_field "${summary_line}" failures)"
ERRORS="$(extract_summary_field "${summary_line}" errors)"

if [[ "${RESULT}" == "OK" && "${CODE}" == "LIVE_DEBUGGER_OK" ]]; then
  emit_summary "OK" "LIVE_DEBUGGER_OK" "${RUN_COUNT}" "${FAILURES}" "${ERRORS}"
  echo "LIVE_DEBUGGER_CHECK_OK"
  exit 0
fi

emit_summary "FAIL" "${CODE:-LIVE_DEBUGGER_FAILED}" "${RUN_COUNT:-0}" "${FAILURES:-0}" "${ERRORS:-0}"
exit 1
