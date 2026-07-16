#!/usr/bin/env bash
# Replication performance baseline lane.
#
# Reuses the replication-live validation runner (run_replication_live_validation.st) -- which already times
# connector install, clamped traversal, dirty-store flush, business-batch flush, and domain flush -- and
# layers a performance gate on top: per-metric max-ms thresholds plus trend-regression detection against a
# stored baseline (a JSONL trend file). This complements make replication-live (correctness) with a perf gate
# without duplicating the fixture logic.
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/140-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 14.0 - clean/Pharo 14.0 - clean.image}"
WORK_DIR="${2:-$(dirname "${SRC_IMAGE}")}"
WORK_IMAGE="not-created"
VALIDATION_ST="$(dirname "$0")/run_replication_live_validation.st"
THRESHOLD_FILE="${GBS_REPLICATION_PERF_THRESHOLDS_FILE:-./scripts/replication_performance_thresholds.env}"
if [[ -f "${THRESHOLD_FILE}" ]]; then
  # shellcheck disable=SC1090
  . "${THRESHOLD_FILE}"
fi

CONNECTOR_MAX_MS="${GBS_REPLICATION_PERF_CONNECTOR_MAX_MS:-${REPLICATION_PERF_CONNECTOR_MAX_MS:-1500}}"
CLAMPED_MAX_MS="${GBS_REPLICATION_PERF_CLAMPED_MAX_MS:-${REPLICATION_PERF_CLAMPED_MAX_MS:-800}}"
DIRTY_STORE_MAX_MS="${GBS_REPLICATION_PERF_DIRTY_STORE_MAX_MS:-${REPLICATION_PERF_DIRTY_STORE_MAX_MS:-2500}}"
BUSINESS_DIRTY_STORE_MAX_MS="${GBS_REPLICATION_PERF_BUSINESS_DIRTY_STORE_MAX_MS:-${REPLICATION_PERF_BUSINESS_DIRTY_STORE_MAX_MS:-3500}}"
DOMAIN_DIRTY_STORE_MAX_MS="${GBS_REPLICATION_PERF_DOMAIN_DIRTY_STORE_MAX_MS:-${REPLICATION_PERF_DOMAIN_DIRTY_STORE_MAX_MS:-800}}"
TREND_REGRESSION_PERCENT="${GBS_REPLICATION_PERF_REGRESSION_PERCENT:-35}"
TREND_REGRESSION_MIN_DELTA_MS="${GBS_REPLICATION_PERF_REGRESSION_MIN_DELTA_MS:-50}"

CONNECTOR_MS=0
CLAMPED_MS=0
DIRTY_STORE_MS=0
BUSINESS_DIRTY_STORE_MS=0
DOMAIN_DIRTY_STORE_MS=0

emit_summary() {
  local result="$1" code="$2"
  echo "REPLICATION_PERF_SUMMARY result=${result} code=${code}" \
    "connector_ms=${CONNECTOR_MS} clamped_ms=${CLAMPED_MS} dirty_store_ms=${DIRTY_STORE_MS}" \
    "business_dirty_store_ms=${BUSINESS_DIRTY_STORE_MS} domain_dirty_store_ms=${DOMAIN_DIRTY_STORE_MS}" \
    "connector_max_ms=${CONNECTOR_MAX_MS} clamped_max_ms=${CLAMPED_MAX_MS} dirty_store_max_ms=${DIRTY_STORE_MAX_MS}" \
    "business_dirty_store_max_ms=${BUSINESS_DIRTY_STORE_MAX_MS} domain_dirty_store_max_ms=${DOMAIN_DIRTY_STORE_MAX_MS}" \
    "trend_percent=${TREND_REGRESSION_PERCENT} trend_min_delta_ms=${TREND_REGRESSION_MIN_DELTA_MS}" \
    "threshold_file=${THRESHOLD_FILE} work_image=${WORK_IMAGE}"
}

summary_field() {
  # summary_field "<summary line>" <field>
  printf '%s\n' "$1" | grep -oE "$2=[0-9]+" | head -1 | cut -d= -f2
}

trend_file_path() {
  local f="${GBS_REPLICATION_PERF_TRENDS:-}"
  if [[ -z "${f}" && -n "${GBS_EVIDENCE_DIR:-}" ]]; then
    f="${GBS_EVIDENCE_DIR}/replication-performance-trends.jsonl"
  fi
  printf '%s\n' "${f}"
}

check_threshold() {
  # check_threshold <label> <current> <max>
  local label="$1" current="$2" max="$3"
  [[ "${current}" =~ ^[0-9]+$ ]] || return 0
  if (( current > max )); then
    emit_summary "FAIL" "REPLICATION_PERF_${label}_THRESHOLD"
    echo "Replication performance threshold exceeded ${label}: ${current}ms > ${max}ms." >&2
    exit 1
  fi
}

check_trend() {
  # check_trend <label> <current> <previous>
  local label="$1" current="$2" previous="$3" percent_allowed absolute_allowed allowed
  [[ "${previous}" =~ ^[0-9]+$ ]] || return 0
  [[ "${current}" =~ ^[0-9]+$ ]] || return 0
  (( previous > 0 )) || return 0
  percent_allowed=$(( previous + (previous * TREND_REGRESSION_PERCENT / 100) ))
  absolute_allowed=$(( previous + TREND_REGRESSION_MIN_DELTA_MS ))
  allowed="${percent_allowed}"
  (( absolute_allowed > allowed )) && allowed="${absolute_allowed}"
  if (( current > allowed )); then
    emit_summary "FAIL" "REPLICATION_PERF_${label}_TREND_REGRESSION"
    echo "Replication performance trend regression ${label}: current=${current}ms previous=${previous}ms allowed=${allowed}ms (${TREND_REGRESSION_PERCENT}% or +${TREND_REGRESSION_MIN_DELTA_MS}ms)." >&2
    exit 1
  fi
}

# --- live env preflight (mirror replication-live) ---
gbs_normalize_live_env_vars
MISSING_LIVE_ENV="$(gbs_missing_required_live_env_vars)"
if [[ -n "${MISSING_LIVE_ENV}" ]]; then
  emit_summary "FAIL" "REPLICATION_PERF_MISSING_ENV"
  echo "Missing required replication live environment: ${MISSING_LIVE_ENV}" >&2
  exit 2
fi

WORK_IMAGE="$(gbs_prepare_work_image "${SRC_IMAGE}" "${WORK_DIR}" "replicationperf")"
gbs_register_work_image_cleanup "${WORK_IMAGE}"
echo "Using work image: ${WORK_IMAGE}"

VALIDATION_OUTPUT="$(HOME=/tmp/pharo-clean-auto/home GBS_WORK_IMAGE="${WORK_IMAGE}" "${VM}" --headless "${WORK_IMAGE}" st "${VALIDATION_ST}" 2>&1 || true)"
gbs_write_evidence_file "replication-performance-validation.log" "${VALIDATION_OUTPUT}"

SUMMARY_LINE="$(printf '%s\n' "${VALIDATION_OUTPUT}" | grep '^REPLICATION_LIVE_VALIDATION result=' | tail -1 || true)"
if [[ -z "${SUMMARY_LINE}" ]]; then
  emit_summary "FAIL" "REPLICATION_PERF_RUNNER_FAILED"
  echo "Replication performance runner did not emit REPLICATION_LIVE_VALIDATION." >&2
  exit 1
fi
RESULT="$(printf '%s\n' "${SUMMARY_LINE}" | grep -oE 'result=[A-Z]+' | head -1 | cut -d= -f2)"
if [[ "${RESULT}" != "OK" ]]; then
  CONNECTOR_MS="$(summary_field "${SUMMARY_LINE}" connector_ms)"; CONNECTOR_MS="${CONNECTOR_MS:-0}"
  emit_summary "FAIL" "REPLICATION_PERF_VALIDATION_FAILED"
  echo "Replication validation did not pass: ${SUMMARY_LINE}" >&2
  exit 1
fi

CONNECTOR_MS="$(summary_field "${SUMMARY_LINE}" connector_ms)"; CONNECTOR_MS="${CONNECTOR_MS:-0}"
CLAMPED_MS="$(summary_field "${SUMMARY_LINE}" clamped_ms)"; CLAMPED_MS="${CLAMPED_MS:-0}"
DIRTY_STORE_MS="$(summary_field "${SUMMARY_LINE}" dirty_store_ms)"; DIRTY_STORE_MS="${DIRTY_STORE_MS:-0}"
BUSINESS_DIRTY_STORE_MS="$(summary_field "${SUMMARY_LINE}" business_dirty_store_ms)"; BUSINESS_DIRTY_STORE_MS="${BUSINESS_DIRTY_STORE_MS:-0}"
DOMAIN_DIRTY_STORE_MS="$(summary_field "${SUMMARY_LINE}" domain_dirty_store_ms)"; DOMAIN_DIRTY_STORE_MS="${DOMAIN_DIRTY_STORE_MS:-0}"

# --- absolute thresholds ---
check_threshold "CONNECTOR" "${CONNECTOR_MS}" "${CONNECTOR_MAX_MS}"
check_threshold "CLAMPED" "${CLAMPED_MS}" "${CLAMPED_MAX_MS}"
check_threshold "DIRTY_STORE" "${DIRTY_STORE_MS}" "${DIRTY_STORE_MAX_MS}"
check_threshold "BUSINESS_DIRTY_STORE" "${BUSINESS_DIRTY_STORE_MS}" "${BUSINESS_DIRTY_STORE_MAX_MS}"
check_threshold "DOMAIN_DIRTY_STORE" "${DOMAIN_DIRTY_STORE_MS}" "${DOMAIN_DIRTY_STORE_MAX_MS}"

# --- trend regression vs baseline ---
TREND_FILE="$(trend_file_path)"
if [[ -n "${TREND_FILE}" && -f "${TREND_FILE}" ]]; then
  PREV_LINE="$(grep -v '^[[:space:]]*$' "${TREND_FILE}" | tail -1 || true)"
  if [[ -n "${PREV_LINE}" ]]; then
    check_trend "CONNECTOR" "${CONNECTOR_MS}" "$(printf '%s' "${PREV_LINE}" | grep -oE '"connector_ms":[0-9]+' | cut -d: -f2)"
    check_trend "CLAMPED" "${CLAMPED_MS}" "$(printf '%s' "${PREV_LINE}" | grep -oE '"clamped_ms":[0-9]+' | cut -d: -f2)"
    check_trend "DIRTY_STORE" "${DIRTY_STORE_MS}" "$(printf '%s' "${PREV_LINE}" | grep -oE '"dirty_store_ms":[0-9]+' | cut -d: -f2)"
    check_trend "BUSINESS_DIRTY_STORE" "${BUSINESS_DIRTY_STORE_MS}" "$(printf '%s' "${PREV_LINE}" | grep -oE '"business_dirty_store_ms":[0-9]+' | cut -d: -f2)"
    check_trend "DOMAIN_DIRTY_STORE" "${DOMAIN_DIRTY_STORE_MS}" "$(printf '%s' "${PREV_LINE}" | grep -oE '"domain_dirty_store_ms":[0-9]+' | cut -d: -f2)"
  fi
fi
if [[ -n "${TREND_FILE}" ]]; then
  mkdir -p "$(dirname "${TREND_FILE}")"
  printf '{"connector_ms":%s,"clamped_ms":%s,"dirty_store_ms":%s,"business_dirty_store_ms":%s,"domain_dirty_store_ms":%s}\n' \
    "${CONNECTOR_MS}" "${CLAMPED_MS}" "${DIRTY_STORE_MS}" "${BUSINESS_DIRTY_STORE_MS}" "${DOMAIN_DIRTY_STORE_MS}" >> "${TREND_FILE}"
fi

emit_summary "OK" "REPLICATION_PERF_OK"
