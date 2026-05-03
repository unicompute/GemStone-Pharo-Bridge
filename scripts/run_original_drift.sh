#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

BASE_SHA="${1:-56b6db3f57a3a9c891b8040310a3f43f8dbafbc3}"
JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"
RESULT="FAIL"
CODE="ORIGINAL_DRIFT_FAILED"
EXCEPTION_COUNT="0"
ACCEPTED_EXCEPTIONS=""

emit_summary() {
  local json_payload=""
  echo "ORIGINAL_DRIFT_SUMMARY result=${RESULT} code=${CODE} exception_count=${EXCEPTION_COUNT} base=${BASE_SHA}"
  if [[ "${JSON_SUMMARY}" == "1" ]]; then
    printf -v json_payload '{"result":"%s","code":"%s","exception_count":"%s","base":"%s","accepted_exceptions":"%s"}' \
      "$(gbs_json_escape "${RESULT}")" \
      "$(gbs_json_escape "${CODE}")" \
      "$(gbs_json_escape "${EXCEPTION_COUNT}")" \
      "$(gbs_json_escape "${BASE_SHA}")" \
      "$(gbs_json_escape "${ACCEPTED_EXCEPTIONS}")"
    printf 'ORIGINAL_DRIFT_SUMMARY_JSON %s\n' "${json_payload}"
    gbs_write_json_summary_file "original-drift-summary.json" "${json_payload}"
  fi
  gbs_append_summary_line "### Original Drift Lane"
  gbs_append_summary_line "- result: \`${RESULT}\`"
  gbs_append_summary_line "- code: \`${CODE}\`"
  gbs_append_summary_line "- exception-count: \`${EXCEPTION_COUNT}\`"
  if [[ -n "${ACCEPTED_EXCEPTIONS}" ]]; then
    gbs_append_summary_line "- accepted exceptions:"
    while IFS= read -r line; do
      [[ -n "${line}" ]] && gbs_append_summary_line "${line}"
    done <<< "${ACCEPTED_EXCEPTIONS}"
  fi
}

output="$(bash ./scripts/report_original_layer_drift.sh "${BASE_SHA}" 2>&1 || true)"
echo "${output}"

ACCEPTED_EXCEPTIONS="$(printf '%s\n' "${output}" | sed -n 's/^ORIGINAL_LAYER_DRIFT_EXPECTED file=\([^ ]*\) reason=\(.*\)$/- `\1`: \2/p')"
if [[ -n "${ACCEPTED_EXCEPTIONS}" ]]; then
  EXCEPTION_COUNT="$(printf '%s\n' "${ACCEPTED_EXCEPTIONS}" | sed '/^$/d' | wc -l | tr -d ' ')"
fi

if grep -q '^ORIGINAL_LAYER_DRIFT_EXPECTED_ONLY ' <<< "${output}"; then
  RESULT="OK"
  CODE="ORIGINAL_LAYER_DRIFT_EXPECTED_ONLY"
  emit_summary
  exit 0
fi

if grep -q '^ORIGINAL_LAYER_DRIFT_OK ' <<< "${output}"; then
  RESULT="OK"
  CODE="ORIGINAL_LAYER_DRIFT_OK"
  ACCEPTED_EXCEPTIONS=""
  EXCEPTION_COUNT="0"
  emit_summary
  exit 0
fi

emit_summary
exit 1
