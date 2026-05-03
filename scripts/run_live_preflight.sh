#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
WORK_IMAGE="${1:?usage: run_live_preflight.sh <work-image>}"
JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"

extract_summary_field() {
  local field="$1"
  printf '%s\n' "${output}" | sed -n "s/.* ${field}=\\([^ ]*\\).*/\\1/p" | tail -1
}

output="$(HOME=/tmp/pharo-clean-auto/home GBS_WORK_IMAGE="${WORK_IMAGE}" "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/run_live_preflight_via_runner.st" 2>&1 || true)"
echo "${output}"

summary_line="$(printf '%s\n' "${output}" | grep 'LIVE_PREFLIGHT_SUMMARY result=' | tail -1 || true)"
json_payload="$(printf '%s\n' "${output}" | sed -n 's/^LIVE_PREFLIGHT_SUMMARY_JSON //p' | tail -1)"

if [[ -z "${summary_line}" ]]; then
  echo "LIVE_PREFLIGHT_SUMMARY result=FAIL code=LIVE_PREFLIGHT_RUNNER_FAILED stone=${GS_STONE:-gs64stone} service=${GS_SERVICE:-gemnetobject} host=${GS_NETLDI_HOST:-implicit} net=${GS_NETLDI_NAME_OR_PORT:-implicit} stone_status=unknown netldi_status=unknown topaz=failed gci=failed"
  exit 1
fi

RESULT="$(extract_summary_field result)"
CODE="$(extract_summary_field code)"
STONE="$(extract_summary_field stone)"
SERVICE_NAME="$(extract_summary_field service)"
HOST_VALUE="$(extract_summary_field host)"
NET_VALUE="$(extract_summary_field net)"
STONE_STATUS="$(extract_summary_field stone_status)"
NETLDI_STATUS="$(extract_summary_field netldi_status)"
TOPAZ_STATUS="$(extract_summary_field topaz)"
GCI_STATUS="$(extract_summary_field gci)"

if [[ "${JSON_SUMMARY}" == "1" && -n "${json_payload}" ]]; then
  gbs_write_json_summary_file "live-preflight-summary.json" "${json_payload}"
fi

gbs_append_summary_line "#### Live Preflight"
gbs_append_summary_line "- result: \`${RESULT}\`"
gbs_append_summary_line "- code: \`${CODE}\`"
gbs_append_summary_line "- stone: \`${STONE}\`"
gbs_append_summary_line "- service: \`${SERVICE_NAME}\`"
gbs_append_summary_line "- host: \`${HOST_VALUE}\`"
gbs_append_summary_line "- net: \`${NET_VALUE}\`"
gbs_append_summary_line "- stone-status: \`${STONE_STATUS}\`"
gbs_append_summary_line "- netldi-status: \`${NETLDI_STATUS}\`"
gbs_append_summary_line "- topaz: \`${TOPAZ_STATUS}\`"
gbs_append_summary_line "- gci: \`${GCI_STATUS}\`"

if [[ "${CODE}" == "LIVE_PREFLIGHT_OK" || "${CODE}" == "LIVE_PREFLIGHT_SKIPPED" ]]; then
  exit 0
fi
exit 1
