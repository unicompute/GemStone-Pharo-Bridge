#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image}"
WORK_DIR="${2:-$(dirname "${SRC_IMAGE}")}"
WORK_IMAGE="not-created"
JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"
THRESHOLD_FILE="${GBS_MATERIALIZATION_THRESHOLDS_FILE:-./scripts/materialization_performance_thresholds.env}"
if [[ -f "${THRESHOLD_FILE}" ]]; then
  # shellcheck disable=SC1090
  . "${THRESHOLD_FILE}"
fi
ARRAY_MAX_MS="${GBS_MATERIALIZATION_ARRAY_MAX_MS:-${MATERIALIZATION_ARRAY_MAX_MS:-5000}}"
DICTIONARY_MAX_MS="${GBS_MATERIALIZATION_DICTIONARY_MAX_MS:-${MATERIALIZATION_DICTIONARY_MAX_MS:-6000}}"
SHALLOW_MAX_MS="${GBS_MATERIALIZATION_SHALLOW_MAX_MS:-${MATERIALIZATION_SHALLOW_MAX_MS:-6000}}"

emit_summary() {
  local result="$1"
  local code="$2"
  local array_ms="${3:-0}"
  local dictionary_ms="${4:-0}"
  local shallow_ms="${5:-0}"
  local array_size="${6:-0}"
  local dictionary_size="${7:-0}"
  local shallow_size="${8:-0}"
  local shallow_root_ms="${9:-0}"
  local shallow_slot_ms="${10:-0}"
  local shallow_class_name_batch_ms="${11:-0}"
  local shallow_proxy_ms="${12:-0}"
  local shallow_wrapper_ms="${13:-0}"
  local shallow_slot_batches="${14:-0}"
  local shallow_class_name_batches="${15:-0}"
  local shallow_proxy_creations="${16:-0}"
  local shallow_wrapper_lookups="${17:-0}"
  local json_payload=""
  local markdown_payload=""
  echo "MATERIALIZATION_PERF_SUMMARY result=${result} code=${code} array_ms=${array_ms} dictionary_ms=${dictionary_ms} shallow_ms=${shallow_ms} array_size=${array_size} dictionary_size=${dictionary_size} shallow_size=${shallow_size} shallow_root_ms=${shallow_root_ms} shallow_slot_ms=${shallow_slot_ms} shallow_class_name_batch_ms=${shallow_class_name_batch_ms} shallow_proxy_ms=${shallow_proxy_ms} shallow_wrapper_ms=${shallow_wrapper_ms} shallow_slot_batches=${shallow_slot_batches} shallow_class_name_batches=${shallow_class_name_batches} shallow_proxy_creations=${shallow_proxy_creations} shallow_wrapper_lookups=${shallow_wrapper_lookups} array_max_ms=${ARRAY_MAX_MS} dictionary_max_ms=${DICTIONARY_MAX_MS} shallow_max_ms=${SHALLOW_MAX_MS} threshold_file=${THRESHOLD_FILE} work_image=${WORK_IMAGE}"
  printf -v json_payload '{"result":"%s","code":"%s","array_ms":"%s","dictionary_ms":"%s","shallow_ms":"%s","array_size":"%s","dictionary_size":"%s","shallow_size":"%s","shallow_root_ms":"%s","shallow_slot_ms":"%s","shallow_class_name_batch_ms":"%s","shallow_proxy_ms":"%s","shallow_wrapper_ms":"%s","shallow_slot_batches":"%s","shallow_class_name_batches":"%s","shallow_proxy_creations":"%s","shallow_wrapper_lookups":"%s","array_max_ms":"%s","dictionary_max_ms":"%s","shallow_max_ms":"%s","threshold_file":"%s","work_image":"%s"}' \
    "$(gbs_json_escape "${result}")" \
    "$(gbs_json_escape "${code}")" \
    "$(gbs_json_escape "${array_ms}")" \
    "$(gbs_json_escape "${dictionary_ms}")" \
    "$(gbs_json_escape "${shallow_ms}")" \
    "$(gbs_json_escape "${array_size}")" \
    "$(gbs_json_escape "${dictionary_size}")" \
    "$(gbs_json_escape "${shallow_size}")" \
    "$(gbs_json_escape "${shallow_root_ms}")" \
    "$(gbs_json_escape "${shallow_slot_ms}")" \
    "$(gbs_json_escape "${shallow_class_name_batch_ms}")" \
    "$(gbs_json_escape "${shallow_proxy_ms}")" \
    "$(gbs_json_escape "${shallow_wrapper_ms}")" \
    "$(gbs_json_escape "${shallow_slot_batches}")" \
    "$(gbs_json_escape "${shallow_class_name_batches}")" \
    "$(gbs_json_escape "${shallow_proxy_creations}")" \
    "$(gbs_json_escape "${shallow_wrapper_lookups}")" \
    "$(gbs_json_escape "${ARRAY_MAX_MS}")" \
    "$(gbs_json_escape "${DICTIONARY_MAX_MS}")" \
    "$(gbs_json_escape "${SHALLOW_MAX_MS}")" \
    "$(gbs_json_escape "${THRESHOLD_FILE}")" \
    "$(gbs_json_escape "${WORK_IMAGE}")"
  if [[ "${JSON_SUMMARY}" == "1" ]]; then
    printf 'MATERIALIZATION_PERF_SUMMARY_JSON %s\n' "${json_payload}"
  fi
  gbs_write_json_summary_file "materialization-performance-summary.json" "${json_payload}"
  printf -v markdown_payload '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
    '# Materialization Performance Baseline' \
    "" \
    "- result: \`${result}\`" \
    "- code: \`${code}\`" \
    "- array fetch: \`${array_ms} ms\` for \`${array_size}\` elements" \
    "- dictionary fetch: \`${dictionary_ms} ms\` for \`${dictionary_size}\` associations" \
    "- shallow nested fetch: \`${shallow_ms} ms\` for \`${shallow_size}\` nested arrays" \
    "- shallow submetrics: root \`${shallow_root_ms} ms\`, slots \`${shallow_slot_ms} ms\`, class-name batch \`${shallow_class_name_batch_ms} ms\`, proxy construction \`${shallow_proxy_ms} ms\`, wrapper lookup \`${shallow_wrapper_ms} ms\`" \
    "- shallow call counts: slot batches \`${shallow_slot_batches}\`, class-name batches \`${shallow_class_name_batches}\`, proxy creations \`${shallow_proxy_creations}\`, wrapper lookups \`${shallow_wrapper_lookups}\`" \
    "- thresholds: array \`${ARRAY_MAX_MS} ms\`, dictionary \`${DICTIONARY_MAX_MS} ms\`, shallow \`${SHALLOW_MAX_MS} ms\`" \
    "- threshold file: \`${THRESHOLD_FILE}\`" \
    "- work image: \`${WORK_IMAGE}\`" \
    "" \
    "Generated by \`make materialization-perf\`."
  gbs_write_evidence_file "materialization-performance-summary.md" "${markdown_payload}"
  gbs_append_summary_line "### Materialization Performance Baseline"
  gbs_append_summary_line "- result: \`${result}\`"
  gbs_append_summary_line "- code: \`${code}\`"
  gbs_append_summary_line "- array fetch: \`${array_ms} ms\` for \`${array_size}\` elements"
  gbs_append_summary_line "- dictionary fetch: \`${dictionary_ms} ms\` for \`${dictionary_size}\` associations"
  gbs_append_summary_line "- shallow nested fetch: \`${shallow_ms} ms\` for \`${shallow_size}\` nested arrays"
  gbs_append_summary_line "- shallow submetrics: root \`${shallow_root_ms} ms\`, slots \`${shallow_slot_ms} ms\`, class-name batch \`${shallow_class_name_batch_ms} ms\`, proxy construction \`${shallow_proxy_ms} ms\`, wrapper lookup \`${shallow_wrapper_ms} ms\`"
  gbs_append_summary_line "- shallow call counts: slot batches \`${shallow_slot_batches}\`, class-name batches \`${shallow_class_name_batches}\`, proxy creations \`${shallow_proxy_creations}\`, wrapper lookups \`${shallow_wrapper_lookups}\`"
  gbs_append_summary_line "- thresholds: array \`${ARRAY_MAX_MS} ms\`, dictionary \`${DICTIONARY_MAX_MS} ms\`, shallow \`${SHALLOW_MAX_MS} ms\`"
  gbs_append_summary_line "- threshold file: \`${THRESHOLD_FILE}\`"
}

extract_summary_field() {
  local line="$1"
  local field="$2"
  printf '%s\n' "${line}" | sed -n "s/.* ${field}=\\([^ ]*\\).*/\\1/p" | tail -1
}

materialization_required_live_env_vars() {
  printf '%s\n' \
    GS_USER \
    GS_PASS \
    GEMSTONE
}

materialization_missing_required_live_env_vars() {
  local var
  local missing=""
  while IFS= read -r var; do
    [[ -n "${var}" ]] || continue
    if [[ -z "${!var:-}" ]]; then
      if [[ -n "${missing}" ]]; then
        missing="${missing},${var}"
      else
        missing="${var}"
      fi
    fi
  done < <(materialization_required_live_env_vars)
  printf '%s\n' "${missing}"
}

materialization_live_env_status_line() {
  local missing="${1:-$(materialization_missing_required_live_env_vars)}"
  printf 'required=%s missing=%s stone=%s service=%s host=%s net=%s gemstone=%s\n' \
    "$(materialization_required_live_env_vars | paste -sd, -)" \
    "${missing:-none}" \
    "${GS_STONE:-gs64stone}" \
    "${GS_SERVICE:-gemnetobject}" \
    "${GS_NETLDI_HOST:-implicit}" \
    "${GS_NETLDI_NAME_OR_PORT:-implicit}" \
    "${GEMSTONE:-unset}"
}

check_latency_threshold() {
  local label="$1"
  local value="$2"
  local max="$3"
  if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_${label}_METRIC" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}"
    echo "Materialization performance metric ${label} is not a non-negative integer: ${value}" >&2
    exit 1
  fi
  if [[ ! "${max}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_${label}_THRESHOLD" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}"
    echo "Materialization performance threshold ${label} is not a non-negative integer: ${max}" >&2
    exit 1
  fi
  if (( value > max )); then
    emit_summary "FAIL" "MATERIALIZATION_PERF_${label}_THRESHOLD_EXCEEDED" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}"
    echo "Materialization performance metric ${label}=${value}ms exceeded threshold ${max}ms." >&2
    exit 1
  fi
}

trend_file_path() {
  local trend_file="${GBS_MATERIALIZATION_PERF_TRENDS:-}"
  if [[ -z "${trend_file}" ]]; then
    [[ -n "${GBS_EVIDENCE_DIR:-}" ]] || return 0
    trend_file="${GBS_EVIDENCE_DIR}/materialization-performance-trends.jsonl"
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

write_trend_sample() {
  local trend_file timestamp
  trend_file="$(trend_file_path)"
  [[ -n "${trend_file}" ]] || return 0
  mkdir -p "$(dirname "${trend_file}")"
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf '{"timestamp":"%s","array_ms":%s,"dictionary_ms":%s,"shallow_ms":%s,"shallow_root_ms":%s,"shallow_slot_ms":%s,"shallow_class_name_batch_ms":%s,"shallow_proxy_ms":%s,"shallow_wrapper_ms":%s,"shallow_slot_batches":%s,"shallow_class_name_batches":%s,"shallow_proxy_creations":%s,"shallow_wrapper_lookups":%s,"array_max_ms":%s,"dictionary_max_ms":%s,"shallow_max_ms":%s}\n' \
    "${timestamp}" \
    "${ARRAY_MS}" \
    "${DICTIONARY_MS}" \
    "${SHALLOW_MS}" \
    "${SHALLOW_ROOT_MS}" \
    "${SHALLOW_SLOT_MS}" \
    "${SHALLOW_CLASS_NAME_BATCH_MS}" \
    "${SHALLOW_PROXY_MS}" \
    "${SHALLOW_WRAPPER_MS}" \
    "${SHALLOW_SLOT_BATCHES}" \
    "${SHALLOW_CLASS_NAME_BATCHES}" \
    "${SHALLOW_PROXY_CREATIONS}" \
    "${SHALLOW_WRAPPER_LOOKUPS}" \
    "${ARRAY_MAX_MS}" \
    "${DICTIONARY_MAX_MS}" \
    "${SHALLOW_MAX_MS}" >> "${trend_file}"
  gbs_append_summary_line "- trend sample: \`${trend_file}\`"
}

write_trend_report() {
  local trend_file report_file line timestamp array dictionary shallow root slot class_name proxy wrapper
  trend_file="$(trend_file_path)"
  [[ -n "${trend_file}" && -f "${trend_file}" ]] || return 0
  report_file="${GBS_MATERIALIZATION_PERF_REPORT:-$(dirname "${trend_file}")/materialization-performance-trend-report.md}"
  mkdir -p "$(dirname "${report_file}")"
  {
    printf '# Materialization Performance Trend\n\n'
    printf '| Timestamp | Array | Dictionary | Shallow | Root | Slots | Class Names | Proxy | Wrapper |\n'
    printf '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n'
    grep -v '^[[:space:]]*$' "${trend_file}" | tail -20 | while IFS= read -r line; do
      timestamp="$(json_line_string_field "${line}" timestamp)"
      array="$(json_line_number_field "${line}" array_ms)"
      dictionary="$(json_line_number_field "${line}" dictionary_ms)"
      shallow="$(json_line_number_field "${line}" shallow_ms)"
      root="$(json_line_number_field "${line}" shallow_root_ms)"
      slot="$(json_line_number_field "${line}" shallow_slot_ms)"
      class_name="$(json_line_number_field "${line}" shallow_class_name_batch_ms)"
      proxy="$(json_line_number_field "${line}" shallow_proxy_ms)"
      wrapper="$(json_line_number_field "${line}" shallow_wrapper_ms)"
      printf '| %s | %s ms | %s ms | %s ms | %s ms | %s ms | %s ms | %s ms | %s ms |\n' \
        "${timestamp:-unknown}" \
        "${array:-0}" \
        "${dictionary:-0}" \
        "${shallow:-0}" \
        "${root:-0}" \
        "${slot:-0}" \
        "${class_name:-0}" \
        "${proxy:-0}" \
        "${wrapper:-0}"
    done
  } > "${report_file}"
  gbs_append_summary_line "- trend report: \`${report_file}\`"
}

MISSING_LIVE_ENV="$(materialization_missing_required_live_env_vars)"
if [[ -n "${MISSING_LIVE_ENV}" ]]; then
  emit_summary "FAIL" "MATERIALIZATION_PERF_MISSING_ENV"
  gbs_append_summary_line "- live env: \`$(materialization_live_env_status_line "${MISSING_LIVE_ENV}")\`"
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
SHALLOW_ROOT_MS="$(extract_summary_field "${summary_line}" shallow_root_ms)"
SHALLOW_SLOT_MS="$(extract_summary_field "${summary_line}" shallow_slot_ms)"
SHALLOW_CLASS_NAME_BATCH_MS="$(extract_summary_field "${summary_line}" shallow_class_name_batch_ms)"
SHALLOW_PROXY_MS="$(extract_summary_field "${summary_line}" shallow_proxy_ms)"
SHALLOW_WRAPPER_MS="$(extract_summary_field "${summary_line}" shallow_wrapper_ms)"
SHALLOW_SLOT_BATCHES="$(extract_summary_field "${summary_line}" shallow_slot_batches)"
SHALLOW_CLASS_NAME_BATCHES="$(extract_summary_field "${summary_line}" shallow_class_name_batches)"
SHALLOW_PROXY_CREATIONS="$(extract_summary_field "${summary_line}" shallow_proxy_creations)"
SHALLOW_WRAPPER_LOOKUPS="$(extract_summary_field "${summary_line}" shallow_wrapper_lookups)"

SHALLOW_ROOT_MS="${SHALLOW_ROOT_MS:-0}"
SHALLOW_SLOT_MS="${SHALLOW_SLOT_MS:-0}"
SHALLOW_CLASS_NAME_BATCH_MS="${SHALLOW_CLASS_NAME_BATCH_MS:-0}"
SHALLOW_PROXY_MS="${SHALLOW_PROXY_MS:-0}"
SHALLOW_WRAPPER_MS="${SHALLOW_WRAPPER_MS:-0}"
SHALLOW_SLOT_BATCHES="${SHALLOW_SLOT_BATCHES:-0}"
SHALLOW_CLASS_NAME_BATCHES="${SHALLOW_CLASS_NAME_BATCHES:-0}"
SHALLOW_PROXY_CREATIONS="${SHALLOW_PROXY_CREATIONS:-0}"
SHALLOW_WRAPPER_LOOKUPS="${SHALLOW_WRAPPER_LOOKUPS:-0}"

if [[ "${RESULT}" == "OK" && "${CODE}" == "MATERIALIZATION_PERF_OK" ]]; then
  check_latency_threshold "ARRAY" "${ARRAY_MS}" "${ARRAY_MAX_MS}"
  check_latency_threshold "DICTIONARY" "${DICTIONARY_MS}" "${DICTIONARY_MAX_MS}"
  check_latency_threshold "SHALLOW" "${SHALLOW_MS}" "${SHALLOW_MAX_MS}"
  emit_summary "OK" "MATERIALIZATION_PERF_OK" "${ARRAY_MS}" "${DICTIONARY_MS}" "${SHALLOW_MS}" "${ARRAY_SIZE}" "${DICTIONARY_SIZE}" "${SHALLOW_SIZE}" "${SHALLOW_ROOT_MS}" "${SHALLOW_SLOT_MS}" "${SHALLOW_CLASS_NAME_BATCH_MS}" "${SHALLOW_PROXY_MS}" "${SHALLOW_WRAPPER_MS}" "${SHALLOW_SLOT_BATCHES}" "${SHALLOW_CLASS_NAME_BATCHES}" "${SHALLOW_PROXY_CREATIONS}" "${SHALLOW_WRAPPER_LOOKUPS}"
  write_trend_sample
  write_trend_report
  echo "MATERIALIZATION_PERF_BASELINE_OK"
  exit 0
fi

emit_summary "FAIL" "${CODE:-MATERIALIZATION_PERF_FAILED}" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS}" "${SHALLOW_SLOT_MS}" "${SHALLOW_CLASS_NAME_BATCH_MS}" "${SHALLOW_PROXY_MS}" "${SHALLOW_WRAPPER_MS}" "${SHALLOW_SLOT_BATCHES}" "${SHALLOW_CLASS_NAME_BATCHES}" "${SHALLOW_PROXY_CREATIONS}" "${SHALLOW_WRAPPER_LOOKUPS}"
exit 1
