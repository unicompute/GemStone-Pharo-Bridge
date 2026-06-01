#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image}"
WORK_DIR="${2:-$(dirname "${SRC_IMAGE}")}"
WORK_IMAGE="not-created"
JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"
ARRAY_MAX_MS="${GBS_MATERIALIZATION_ARRAY_MAX_MS:-5000}"
DICTIONARY_MAX_MS="${GBS_MATERIALIZATION_DICTIONARY_MAX_MS:-6000}"
SHALLOW_MAX_MS="${GBS_MATERIALIZATION_SHALLOW_MAX_MS:-6000}"

emit_summary() {
  local result="$1"
  local code="$2"
  local array_ms="${3:-0}"
  local dictionary_ms="${4:-0}"
  local shallow_ms="${5:-0}"
  local array_size="${6:-0}"
  local dictionary_size="${7:-0}"
  local shallow_size="${8:-0}"
  local json_payload=""
  echo "MATERIALIZATION_PERF_SUMMARY result=${result} code=${code} array_ms=${array_ms} dictionary_ms=${dictionary_ms} shallow_ms=${shallow_ms} array_size=${array_size} dictionary_size=${dictionary_size} shallow_size=${shallow_size} work_image=${WORK_IMAGE}"
  if [[ "${JSON_SUMMARY}" == "1" ]]; then
    printf -v json_payload '{"result":"%s","code":"%s","array_ms":"%s","dictionary_ms":"%s","shallow_ms":"%s","array_size":"%s","dictionary_size":"%s","shallow_size":"%s","work_image":"%s"}' \
      "$(gbs_json_escape "${result}")" \
      "$(gbs_json_escape "${code}")" \
      "$(gbs_json_escape "${array_ms}")" \
      "$(gbs_json_escape "${dictionary_ms}")" \
      "$(gbs_json_escape "${shallow_ms}")" \
      "$(gbs_json_escape "${array_size}")" \
      "$(gbs_json_escape "${dictionary_size}")" \
      "$(gbs_json_escape "${shallow_size}")" \
      "$(gbs_json_escape "${WORK_IMAGE}")"
    printf 'MATERIALIZATION_PERF_SUMMARY_JSON %s\n' "${json_payload}"
    gbs_write_json_summary_file "materialization-performance-summary.json" "${json_payload}"
  fi
  gbs_append_summary_line "### Materialization Performance Baseline"
  gbs_append_summary_line "- result: \`${result}\`"
  gbs_append_summary_line "- code: \`${code}\`"
  gbs_append_summary_line "- array fetch: \`${array_ms} ms\` for \`${array_size}\` elements"
  gbs_append_summary_line "- dictionary fetch: \`${dictionary_ms} ms\` for \`${dictionary_size}\` associations"
  gbs_append_summary_line "- shallow nested fetch: \`${shallow_ms} ms\` for \`${shallow_size}\` nested arrays"
}

extract_summary_field() {
  local line="$1"
  local field="$2"
  printf '%s\n' "${line}" | sed -n "s/.* ${field}=\\([^ ]*\\).*/\\1/p" | tail -1
}

check_latency_threshold() {
  local label="$1"
  local value="$2"
  local max="$3"
  if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_${label}_METRIC" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}"
    echo "Materialization performance metric ${label} is not a non-negative integer: ${value}" >&2
    exit 1
  fi
  if [[ ! "${max}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_${label}_THRESHOLD" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}"
    echo "Materialization performance threshold ${label} is not a non-negative integer: ${max}" >&2
    exit 1
  fi
  if (( value > max )); then
    emit_summary "FAIL" "MATERIALIZATION_PERF_${label}_THRESHOLD_EXCEEDED" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}"
    echo "Materialization performance metric ${label}=${value}ms exceeded threshold ${max}ms." >&2
    exit 1
  fi
}

MISSING_LIVE_ENV="$(gbs_missing_required_live_env_vars)"
if [[ -n "${MISSING_LIVE_ENV}" ]]; then
  emit_summary "FAIL" "MATERIALIZATION_PERF_MISSING_ENV"
  gbs_append_summary_line "- live env: \`$(gbs_live_env_status_line "${MISSING_LIVE_ENV}")\`"
  echo "Missing required materialization performance environment: ${MISSING_LIVE_ENV}" >&2
  echo "Set the missing variables before running make materialization-perf." >&2
  exit 2
fi

WORK_IMAGE="$(gbs_prepare_work_image "${SRC_IMAGE}" "${WORK_DIR}" "materializationperf")"
gbs_register_work_image_cleanup "${WORK_IMAGE}"

echo "Using work image: ${WORK_IMAGE}"
preflight_output="$(bash ./scripts/run_live_preflight.sh "${WORK_IMAGE}" 2>&1 || true)"
echo "${preflight_output}"
gbs_write_evidence_file "materialization-performance-preflight.log" "${preflight_output}"
if ! grep -q "LIVE_PREFLIGHT_SUMMARY result=OK code=LIVE_PREFLIGHT_OK" <<< "${preflight_output}"; then
  emit_summary "FAIL" "MATERIALIZATION_PERF_PREFLIGHT_FAILED"
  echo "Live preflight failed or skipped; refusing to benchmark materialization against an unknown GemStone session." >&2
  exit 1
fi

perf_output="$(HOME=/tmp/pharo-clean-auto/home GBS_WORK_IMAGE="${WORK_IMAGE}" "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/run_materialization_performance_baseline.st" 2>&1 || true)"
echo "${perf_output}"
gbs_write_evidence_file "materialization-performance-baseline.log" "${perf_output}"

summary_line="$(printf '%s\n' "${perf_output}" | grep 'MATERIALIZATION_PERF_BASELINE result=' | tail -1 || true)"
if [[ -z "${summary_line}" ]]; then
  emit_summary "FAIL" "MATERIALIZATION_PERF_RUNNER_FAILED"
  echo "Materialization performance runner did not emit MATERIALIZATION_PERF_BASELINE." >&2
  exit 1
fi

RESULT="$(extract_summary_field "${summary_line}" result)"
CODE="$(extract_summary_field "${summary_line}" code)"
ARRAY_MS="$(extract_summary_field "${summary_line}" array_ms)"
DICTIONARY_MS="$(extract_summary_field "${summary_line}" dictionary_ms)"
SHALLOW_MS="$(extract_summary_field "${summary_line}" shallow_ms)"
ARRAY_SIZE="$(extract_summary_field "${summary_line}" array_size)"
DICTIONARY_SIZE="$(extract_summary_field "${summary_line}" dictionary_size)"
SHALLOW_SIZE="$(extract_summary_field "${summary_line}" shallow_size)"

if [[ "${RESULT}" == "OK" && "${CODE}" == "MATERIALIZATION_PERF_OK" ]]; then
  check_latency_threshold "ARRAY" "${ARRAY_MS}" "${ARRAY_MAX_MS}"
  check_latency_threshold "DICTIONARY" "${DICTIONARY_MS}" "${DICTIONARY_MAX_MS}"
  check_latency_threshold "SHALLOW" "${SHALLOW_MS}" "${SHALLOW_MAX_MS}"
  emit_summary "OK" "MATERIALIZATION_PERF_OK" "${ARRAY_MS}" "${DICTIONARY_MS}" "${SHALLOW_MS}" "${ARRAY_SIZE}" "${DICTIONARY_SIZE}" "${SHALLOW_SIZE}"
  echo "MATERIALIZATION_PERF_BASELINE_OK"
  exit 0
fi

emit_summary "FAIL" "${CODE:-MATERIALIZATION_PERF_FAILED}" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}"
exit 1
