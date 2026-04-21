#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
PHARO_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image}"
PHARO_WORK_DIR="${2:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean}"
JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"

extract_summary_field() {
  local field="$1"
  printf '%s\n' "${output}" | sed -n "s/.* ${field}=\\([^ ]*\\).*/\\1/p" | tail -1
}

output="$(HOME=/tmp/pharo-clean-auto/home GBS_VERIFY_IMAGE="${PHARO_IMAGE}" GBS_VERIFY_WORK_DIR="${PHARO_WORK_DIR}" "${VM}" --headless "${PHARO_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/run_verify_via_runner.st" 2>&1 || true)"
echo "${output}"

summary_line="$(printf '%s\n' "${output}" | grep 'VERIFY_SUMMARY result=' | tail -1 || true)"
json_payload="$(printf '%s\n' "${output}" | sed -n 's/^VERIFY_SUMMARY_JSON //p' | tail -1)"

if [[ -z "${summary_line}" ]]; then
  echo "VERIFY_SUMMARY result=FAIL code=VERIFY_RUNNER_FAILED core_only=failed bootstrap_smoke=skipped full=skipped artifact_freshness=skipped summary_renderer=skipped"
  exit 1
fi

RESULT="$(extract_summary_field result)"
CODE="$(extract_summary_field code)"
CORE_STATUS="$(extract_summary_field core_only)"
BOOTSTRAP_STATUS="$(extract_summary_field bootstrap_smoke)"
FULL_STATUS="$(extract_summary_field full)"
ARTIFACT_STATUS="$(extract_summary_field artifact_freshness)"
RENDERER_STATUS="$(extract_summary_field summary_renderer)"

if [[ "${JSON_SUMMARY}" == "1" && -n "${json_payload}" ]]; then
  gbs_write_json_summary_file "verify-summary.json" "${json_payload}"
fi

gbs_append_summary_line "## Verify Summary"
gbs_append_summary_line "- result: \`${RESULT}\`"
gbs_append_summary_line "- code: \`${CODE}\`"
gbs_append_summary_line "- core-only: \`${CORE_STATUS}\`"
gbs_append_summary_line "- bootstrap-smoke: \`${BOOTSTRAP_STATUS}\`"
gbs_append_summary_line "- full: \`${FULL_STATUS}\`"
gbs_append_summary_line "- artifact-freshness: \`${ARTIFACT_STATUS}\`"
gbs_append_summary_line "- summary-renderer: \`${RENDERER_STATUS}\`"

if [[ "${RESULT}" == "OK" ]]; then
  exit 0
fi
exit 1
