#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"
MISSING_LIVE_ENV="$(gbs_missing_required_live_env_vars)"
STATUS_LINE="$(gbs_live_env_status_line "${MISSING_LIVE_ENV}")"

emit_live_env_summary() {
  local result="$1"
  local code="$2"
  local json_payload=""
  echo "LIVE_ENV_SUMMARY result=${result} code=${code} ${STATUS_LINE}"
  if [[ "${JSON_SUMMARY}" == "1" ]]; then
    printf -v json_payload '{"result":"%s","code":"%s","required":"%s","missing":"%s","stone":"%s","service":"%s","host":"%s","net":"%s","gemstone":"%s"}' \
      "$(gbs_json_escape "${result}")" \
      "$(gbs_json_escape "${code}")" \
      "$(gbs_required_live_env_vars | paste -sd, -)" \
      "$(gbs_json_escape "${MISSING_LIVE_ENV:-none}")" \
      "$(gbs_json_escape "${GS_STONE:-gs64stone}")" \
      "$(gbs_json_escape "${GS_SERVICE:-gemnetobject}")" \
      "$(gbs_json_escape "${GS_NETLDI_HOST:-unset}")" \
      "$(gbs_json_escape "${GS_NETLDI_NAME_OR_PORT:-unset}")" \
      "$(gbs_json_escape "${GEMSTONE:-unset}")"
    printf 'LIVE_ENV_SUMMARY_JSON %s\n' "${json_payload}"
    gbs_write_json_summary_file "live-env-summary.json" "${json_payload}"
  fi
  gbs_append_summary_line "### Live GemStone Environment"
  gbs_append_summary_line "- result: \`${result}\`"
  gbs_append_summary_line "- code: \`${code}\`"
  gbs_append_summary_line "- ${STATUS_LINE}"
}

if [[ -n "${MISSING_LIVE_ENV}" ]]; then
  emit_live_env_summary "FAIL" "LIVE_ENV_MISSING_REQUIRED"
  echo "Missing required live GemStone environment: ${MISSING_LIVE_ENV}" >&2
  exit 2
fi

emit_live_env_summary "OK" "LIVE_ENV_READY"
exit 0
