#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image}"
WORK_DIR="${2:-$(dirname "${SRC_IMAGE}")}"
WORK_IMAGE="not-created"
JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"
OPEN_MAX_MS="${GBS_DEBUGGER_OPEN_MAX_MS:-8000}"
STACK_FETCH_MAX_MS="${GBS_DEBUGGER_STACK_FETCH_MAX_MS:-4000}"
SOURCE_LOOKUP_MAX_MS="${GBS_DEBUGGER_SOURCE_LOOKUP_MAX_MS:-4000}"
PROXY_INSPECT_MAX_MS="${GBS_DEBUGGER_PROXY_INSPECT_MAX_MS:-4000}"
TREND_REGRESSION_PERCENT="${GBS_DEBUGGER_PERF_REGRESSION_PERCENT:-35}"

emit_summary() {
  local result="$1"
  local code="$2"
  local open_ms="${3:-0}"
  local stack_fetch_ms="${4:-0}"
  local source_lookup_ms="${5:-0}"
  local proxy_inspect_ms="${6:-0}"
  local json_payload=""
  echo "DEBUGGER_PERF_SUMMARY result=${result} code=${code} open_ms=${open_ms} stack_fetch_ms=${stack_fetch_ms} source_lookup_ms=${source_lookup_ms} proxy_inspect_ms=${proxy_inspect_ms} work_image=${WORK_IMAGE}"
  if [[ "${JSON_SUMMARY}" == "1" ]]; then
    printf -v json_payload '{"result":"%s","code":"%s","open_ms":"%s","stack_fetch_ms":"%s","source_lookup_ms":"%s","proxy_inspect_ms":"%s","work_image":"%s"}' \
      "$(gbs_json_escape "${result}")" \
      "$(gbs_json_escape "${code}")" \
      "$(gbs_json_escape "${open_ms}")" \
      "$(gbs_json_escape "${stack_fetch_ms}")" \
      "$(gbs_json_escape "${source_lookup_ms}")" \
      "$(gbs_json_escape "${proxy_inspect_ms}")" \
      "$(gbs_json_escape "${WORK_IMAGE}")"
    printf 'DEBUGGER_PERF_SUMMARY_JSON %s\n' "${json_payload}"
    gbs_write_json_summary_file "debugger-performance-summary.json" "${json_payload}"
  fi
  gbs_append_summary_line "### Debugger Performance Baseline"
  gbs_append_summary_line "- result: \`${result}\`"
  gbs_append_summary_line "- code: \`${code}\`"
  gbs_append_summary_line "- open debugger: \`${open_ms} ms\`"
  gbs_append_summary_line "- stack fetch: \`${stack_fetch_ms} ms\`"
  gbs_append_summary_line "- source lookup: \`${source_lookup_ms} ms\`"
  gbs_append_summary_line "- proxy inspection: \`${proxy_inspect_ms} ms\`"
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
    emit_summary "FAIL" "DEBUGGER_PERF_BAD_${label}_METRIC" "${OPEN_MS:-0}" "${STACK_FETCH_MS:-0}" "${SOURCE_LOOKUP_MS:-0}" "${PROXY_INSPECT_MS:-0}"
    echo "Debugger performance metric ${label} is not a non-negative integer: ${value}" >&2
    exit 1
  fi
  if [[ ! "${max}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "DEBUGGER_PERF_BAD_${label}_THRESHOLD" "${OPEN_MS:-0}" "${STACK_FETCH_MS:-0}" "${SOURCE_LOOKUP_MS:-0}" "${PROXY_INSPECT_MS:-0}"
    echo "Debugger performance threshold ${label} is not a non-negative integer: ${max}" >&2
    exit 1
  fi
  if (( value > max )); then
    emit_summary "FAIL" "DEBUGGER_PERF_${label}_THRESHOLD_EXCEEDED" "${OPEN_MS:-0}" "${STACK_FETCH_MS:-0}" "${SOURCE_LOOKUP_MS:-0}" "${PROXY_INSPECT_MS:-0}"
    echo "Debugger performance metric ${label}=${value}ms exceeded threshold ${max}ms." >&2
    exit 1
  fi
}

trend_file_path() {
  local trend_file="${GBS_DEBUGGER_PERF_TRENDS:-}"
  if [[ -z "${trend_file}" ]]; then
    [[ -n "${GBS_EVIDENCE_DIR:-}" ]] || return 0
    trend_file="${GBS_EVIDENCE_DIR}/debugger-performance-trends.jsonl"
  fi
  printf '%s\n' "${trend_file}"
}

json_line_number_field() {
  local line="$1"
  local field="$2"
  printf '%s\n' "${line}" | sed -n "s/.*\"${field}\":\\([0-9][0-9]*\\).*/\\1/p" | tail -1
}

json_line_string_field() {
  local line="$1"
  local field="$2"
  printf '%s\n' "${line}" | sed -n "s/.*\"${field}\":\"\\([^\"]*\\)\".*/\\1/p" | tail -1
}

check_trend_metric() {
  local label="$1"
  local current="$2"
  local previous="$3"
  local allowed
  [[ "${previous}" =~ ^[0-9]+$ ]] || return 0
  [[ "${current}" =~ ^[0-9]+$ ]] || return 0
  (( previous > 0 )) || return 0
  allowed=$(( previous + (previous * TREND_REGRESSION_PERCENT / 100) ))
  if (( current > allowed )); then
    emit_summary "FAIL" "DEBUGGER_PERF_${label}_TREND_REGRESSION" "${OPEN_MS:-0}" "${STACK_FETCH_MS:-0}" "${SOURCE_LOOKUP_MS:-0}" "${PROXY_INSPECT_MS:-0}"
    echo "Debugger performance trend regression ${label}: current=${current}ms previous=${previous}ms allowed=${allowed}ms (${TREND_REGRESSION_PERCENT}%)." >&2
    exit 1
  fi
}

check_trend_regression() {
  local trend_file previous_line previous_open previous_stack previous_source previous_proxy
  trend_file="$(trend_file_path)"
  [[ -n "${trend_file}" && -f "${trend_file}" ]] || return 0
  previous_line="$(grep -v '^[[:space:]]*$' "${trend_file}" | tail -1 || true)"
  [[ -n "${previous_line}" ]] || return 0
  previous_open="$(json_line_number_field "${previous_line}" open_ms)"
  previous_stack="$(json_line_number_field "${previous_line}" stack_fetch_ms)"
  previous_source="$(json_line_number_field "${previous_line}" source_lookup_ms)"
  previous_proxy="$(json_line_number_field "${previous_line}" proxy_inspect_ms)"
  check_trend_metric "OPEN" "${OPEN_MS}" "${previous_open}"
  check_trend_metric "STACK_FETCH" "${STACK_FETCH_MS}" "${previous_stack}"
  check_trend_metric "SOURCE_LOOKUP" "${SOURCE_LOOKUP_MS}" "${previous_source}"
  check_trend_metric "PROXY_INSPECT" "${PROXY_INSPECT_MS}" "${previous_proxy}"
  gbs_append_summary_line "- trend comparison: previous sample from \`${trend_file}\`, threshold \`${TREND_REGRESSION_PERCENT}%\`"
}

write_trend_sample() {
  local trend_file
  local timestamp
  trend_file="$(trend_file_path)"
  [[ -n "${trend_file}" ]] || return 0
  mkdir -p "$(dirname "${trend_file}")"
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf '{"timestamp":"%s","open_ms":%s,"stack_fetch_ms":%s,"source_lookup_ms":%s,"proxy_inspect_ms":%s,"open_max_ms":%s,"stack_fetch_max_ms":%s,"source_lookup_max_ms":%s,"proxy_inspect_max_ms":%s}\n' \
    "${timestamp}" \
    "${OPEN_MS}" \
    "${STACK_FETCH_MS}" \
    "${SOURCE_LOOKUP_MS}" \
    "${PROXY_INSPECT_MS}" \
    "${OPEN_MAX_MS}" \
    "${STACK_FETCH_MAX_MS}" \
    "${SOURCE_LOOKUP_MAX_MS}" \
    "${PROXY_INSPECT_MAX_MS}" >> "${trend_file}"
  gbs_append_summary_line "- trend sample: \`${trend_file}\`"
}

write_trend_report() {
  local trend_file report_file line timestamp open stack source proxy
  trend_file="$(trend_file_path)"
  [[ -n "${trend_file}" && -f "${trend_file}" ]] || return 0
  report_file="${GBS_DEBUGGER_PERF_REPORT:-$(dirname "${trend_file}")/debugger-performance-trend-report.md}"
  mkdir -p "$(dirname "${report_file}")"
  {
    printf '# Debugger Performance Trend\n\n'
    printf 'Regression threshold: `%s%%` over the previous sample.\n\n' "${TREND_REGRESSION_PERCENT}"
    printf '| Timestamp | Open Debugger | Stack Fetch | Source Lookup | Proxy Inspect |\n'
    printf '| --- | ---: | ---: | ---: | ---: |\n'
    grep -v '^[[:space:]]*$' "${trend_file}" | tail -20 | while IFS= read -r line; do
      timestamp="$(json_line_string_field "${line}" timestamp)"
      open="$(json_line_number_field "${line}" open_ms)"
      stack="$(json_line_number_field "${line}" stack_fetch_ms)"
      source="$(json_line_number_field "${line}" source_lookup_ms)"
      proxy="$(json_line_number_field "${line}" proxy_inspect_ms)"
      printf '| %s | %s ms | %s ms | %s ms | %s ms |\n' \
        "${timestamp:-unknown}" \
        "${open:-0}" \
        "${stack:-0}" \
        "${source:-0}" \
        "${proxy:-0}"
    done
  } > "${report_file}"
  gbs_append_summary_line "- trend report: \`${report_file}\`"
}

MISSING_LIVE_ENV="$(gbs_missing_required_live_env_vars)"
if [[ -n "${MISSING_LIVE_ENV}" ]]; then
  emit_summary "FAIL" "DEBUGGER_PERF_MISSING_ENV"
  gbs_append_summary_line "- live env: \`$(gbs_live_env_status_line "${MISSING_LIVE_ENV}")\`"
  echo "Missing required debugger performance environment: ${MISSING_LIVE_ENV}" >&2
  echo "Set the missing variables before running make debugger-perf." >&2
  exit 2
fi

WORK_IMAGE="$(gbs_prepare_work_image "${SRC_IMAGE}" "${WORK_DIR}" "debuggerperf")"
gbs_register_work_image_cleanup "${WORK_IMAGE}"

echo "Using work image: ${WORK_IMAGE}"
preflight_output="$(bash ./scripts/run_live_preflight.sh "${WORK_IMAGE}" 2>&1 || true)"
echo "${preflight_output}"
gbs_write_evidence_file "debugger-performance-preflight.log" "${preflight_output}"
if ! grep -q "LIVE_PREFLIGHT_SUMMARY result=OK code=LIVE_PREFLIGHT_OK" <<< "${preflight_output}"; then
  emit_summary "FAIL" "DEBUGGER_PERF_PREFLIGHT_FAILED"
  echo "Live debugger preflight failed or skipped; refusing to benchmark against an unknown GemStone session." >&2
  exit 1
fi

perf_output="$(HOME=/tmp/pharo-clean-auto/home GBS_WORK_IMAGE="${WORK_IMAGE}" "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/run_debugger_performance_baseline.st" 2>&1 || true)"
echo "${perf_output}"
gbs_write_evidence_file "debugger-performance-baseline.log" "${perf_output}"

summary_line="$(printf '%s\n' "${perf_output}" | grep 'DEBUGGER_PERF_BASELINE result=' | tail -1 || true)"
if [[ -z "${summary_line}" ]]; then
  emit_summary "FAIL" "DEBUGGER_PERF_RUNNER_FAILED"
  echo "Debugger performance runner did not emit DEBUGGER_PERF_BASELINE." >&2
  exit 1
fi

RESULT="$(extract_summary_field "${summary_line}" result)"
CODE="$(extract_summary_field "${summary_line}" code)"
OPEN_MS="$(extract_summary_field "${summary_line}" open_ms)"
STACK_FETCH_MS="$(extract_summary_field "${summary_line}" stack_fetch_ms)"
SOURCE_LOOKUP_MS="$(extract_summary_field "${summary_line}" source_lookup_ms)"
PROXY_INSPECT_MS="$(extract_summary_field "${summary_line}" proxy_inspect_ms)"

if [[ "${RESULT}" == "OK" && "${CODE}" == "DEBUGGER_PERF_OK" ]]; then
  check_latency_threshold "OPEN" "${OPEN_MS}" "${OPEN_MAX_MS}"
  check_latency_threshold "STACK_FETCH" "${STACK_FETCH_MS}" "${STACK_FETCH_MAX_MS}"
  check_latency_threshold "SOURCE_LOOKUP" "${SOURCE_LOOKUP_MS}" "${SOURCE_LOOKUP_MAX_MS}"
  check_latency_threshold "PROXY_INSPECT" "${PROXY_INSPECT_MS}" "${PROXY_INSPECT_MAX_MS}"
  check_trend_regression
  write_trend_sample
  write_trend_report
  emit_summary "OK" "DEBUGGER_PERF_OK" "${OPEN_MS}" "${STACK_FETCH_MS}" "${SOURCE_LOOKUP_MS}" "${PROXY_INSPECT_MS}"
  echo "DEBUGGER_PERF_BASELINE_OK"
  exit 0
fi

emit_summary "FAIL" "${CODE:-DEBUGGER_PERF_FAILED}" "${OPEN_MS:-0}" "${STACK_FETCH_MS:-0}" "${SOURCE_LOOKUP_MS:-0}" "${PROXY_INSPECT_MS:-0}"
exit 1
