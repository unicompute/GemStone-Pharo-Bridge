#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image}"
WORK_DIR="${2:-$(dirname "${SRC_IMAGE}")}"
WORK_IMAGE="not-created"
JSON_SUMMARY="${GBS_JSON_SUMMARY:-0}"
THRESHOLD_FILE="${GBS_REPLICATION_LIVE_THRESHOLDS_FILE:-./scripts/replication_live_thresholds.env}"
if [[ -f "${THRESHOLD_FILE}" ]]; then
  # shellcheck disable=SC1090
  . "${THRESHOLD_FILE}"
fi
CONNECTOR_MAX_MS="${GBS_REPLICATION_LIVE_CONNECTOR_MAX_MS:-${REPLICATION_LIVE_CONNECTOR_MAX_MS:-1000}}"
CLAMPED_MAX_MS="${GBS_REPLICATION_LIVE_CLAMPED_MAX_MS:-${REPLICATION_LIVE_CLAMPED_MAX_MS:-500}}"
DIRTY_STORE_MAX_MS="${GBS_REPLICATION_LIVE_DIRTY_STORE_MAX_MS:-${REPLICATION_LIVE_DIRTY_STORE_MAX_MS:-2000}}"
BUSINESS_DIRTY_STORE_MAX_MS="${GBS_REPLICATION_LIVE_BUSINESS_DIRTY_STORE_MAX_MS:-${REPLICATION_LIVE_BUSINESS_DIRTY_STORE_MAX_MS:-3000}}"
DOMAIN_DIRTY_STORE_MAX_MS="${GBS_REPLICATION_LIVE_DOMAIN_DIRTY_STORE_MAX_MS:-${REPLICATION_LIVE_DOMAIN_DIRTY_STORE_MAX_MS:-500}}"
CLAMPED_FETCHES_MIN="${GBS_REPLICATION_LIVE_CLAMPED_FETCHES_MIN:-${REPLICATION_LIVE_CLAMPED_FETCHES_MIN:-1}}"
CLAMPED_FETCHES_MAX="${GBS_REPLICATION_LIVE_CLAMPED_FETCHES_MAX:-${REPLICATION_LIVE_CLAMPED_FETCHES_MAX:-3}}"
CLAMPED_FALLBACKS_MAX="${GBS_REPLICATION_LIVE_CLAMPED_FALLBACKS_MAX:-${REPLICATION_LIVE_CLAMPED_FALLBACKS_MAX:-0}}"
CALLBACK_CLAMP_SPECS_MIN="${GBS_REPLICATION_LIVE_CALLBACK_CLAMP_SPECS_MIN:-${REPLICATION_LIVE_CALLBACK_CLAMP_SPECS_MIN:-1}}"
PER_INSTVAR_CLAMP_ENTRIES_MIN="${GBS_REPLICATION_LIVE_PER_INSTVAR_CLAMP_ENTRIES_MIN:-${REPLICATION_LIVE_PER_INSTVAR_CLAMP_ENTRIES_MIN:-1}}"
INHERITED_REPLICATION_SPEC_FIXTURES_MIN="${GBS_REPLICATION_LIVE_INHERITED_REPLICATION_SPEC_FIXTURES_MIN:-${REPLICATION_LIVE_INHERITED_REPLICATION_SPEC_FIXTURES_MIN:-1}}"
CONNECTOR_PAIR_COUNT_MIN="${GBS_REPLICATION_LIVE_CONNECTOR_PAIR_COUNT_MIN:-${REPLICATION_LIVE_CONNECTOR_PAIR_COUNT_MIN:-1}}"
DOMAIN_FIXTURE_COUNT_MIN="${GBS_REPLICATION_LIVE_DOMAIN_FIXTURE_COUNT_MIN:-${REPLICATION_LIVE_DOMAIN_FIXTURE_COUNT_MIN:-1}}"
DOMAIN_PER_INSTVAR_CLAMP_ENTRIES_MIN="${GBS_REPLICATION_LIVE_DOMAIN_PER_INSTVAR_CLAMP_ENTRIES_MIN:-${REPLICATION_LIVE_DOMAIN_PER_INSTVAR_CLAMP_ENTRIES_MIN:-1}}"
DOMAIN_CALLBACK_CLAMP_SPECS_MIN="${GBS_REPLICATION_LIVE_DOMAIN_CALLBACK_CLAMP_SPECS_MIN:-${REPLICATION_LIVE_DOMAIN_CALLBACK_CLAMP_SPECS_MIN:-1}}"
DOMAIN_DIRTY_OBJECTS_FLUSHED_MIN="${GBS_REPLICATION_LIVE_DOMAIN_DIRTY_OBJECTS_FLUSHED_MIN:-${REPLICATION_LIVE_DOMAIN_DIRTY_OBJECTS_FLUSHED_MIN:-2}}"
DOMAIN_NATIVE_DIRTY_STORE_FLUSHES_MIN="${GBS_REPLICATION_LIVE_DOMAIN_NATIVE_DIRTY_STORE_FLUSHES_MIN:-${REPLICATION_LIVE_DOMAIN_NATIVE_DIRTY_STORE_FLUSHES_MIN:-1}}"
DOMAIN_NATIVE_DIRTY_STORE_ENTRIES_MIN="${GBS_REPLICATION_LIVE_DOMAIN_NATIVE_DIRTY_STORE_ENTRIES_MIN:-${REPLICATION_LIVE_DOMAIN_NATIVE_DIRTY_STORE_ENTRIES_MIN:-2}}"
NATIVE_DIRTY_STORE_FLUSHES_MIN="${GBS_REPLICATION_LIVE_NATIVE_DIRTY_STORE_FLUSHES_MIN:-${REPLICATION_LIVE_NATIVE_DIRTY_STORE_FLUSHES_MIN:-1}}"
SEMANTIC_DIRTY_STORE_COMMANDS_MAX="${GBS_REPLICATION_LIVE_SEMANTIC_DIRTY_STORE_COMMANDS_MAX:-${REPLICATION_LIVE_SEMANTIC_DIRTY_STORE_COMMANDS_MAX:-0}}"
SEMANTIC_DIRTY_STORE_ENTRIES_MAX="${GBS_REPLICATION_LIVE_SEMANTIC_DIRTY_STORE_ENTRIES_MAX:-${REPLICATION_LIVE_SEMANTIC_DIRTY_STORE_ENTRIES_MAX:-0}}"
SEMANTIC_DICTIONARY_ENTRIES_MAX="${GBS_REPLICATION_LIVE_SEMANTIC_DICTIONARY_ENTRIES_MAX:-${REPLICATION_LIVE_SEMANTIC_DICTIONARY_ENTRIES_MAX:-0}}"
SEMANTIC_SET_ENTRIES_MAX="${GBS_REPLICATION_LIVE_SEMANTIC_SET_ENTRIES_MAX:-${REPLICATION_LIVE_SEMANTIC_SET_ENTRIES_MAX:-0}}"
SEMANTIC_BAG_ENTRIES_MAX="${GBS_REPLICATION_LIVE_SEMANTIC_BAG_ENTRIES_MAX:-${REPLICATION_LIVE_SEMANTIC_BAG_ENTRIES_MAX:-0}}"
DIRTY_OBJECTS_FLUSHED_MIN="${GBS_REPLICATION_LIVE_DIRTY_OBJECTS_FLUSHED_MIN:-${REPLICATION_LIVE_DIRTY_OBJECTS_FLUSHED_MIN:-3}}"
BUSINESS_DIRTY_OBJECTS_FLUSHED_MIN="${GBS_REPLICATION_LIVE_BUSINESS_DIRTY_OBJECTS_FLUSHED_MIN:-${REPLICATION_LIVE_BUSINESS_DIRTY_OBJECTS_FLUSHED_MIN:-18}}"
BUSINESS_WRITE_FIXTURE_SIZE_MIN="${GBS_REPLICATION_LIVE_BUSINESS_WRITE_FIXTURE_SIZE_MIN:-${REPLICATION_LIVE_BUSINESS_WRITE_FIXTURE_SIZE_MIN:-18}}"
EXPORT_SET_QUEUED_AFTER_MAX="${GBS_REPLICATION_LIVE_EXPORT_SET_QUEUED_AFTER_MAX:-${REPLICATION_LIVE_EXPORT_SET_QUEUED_AFTER_MAX:-0}}"
BUSINESS_EXPORT_SET_QUEUED_AFTER_MAX="${GBS_REPLICATION_LIVE_BUSINESS_EXPORT_SET_QUEUED_AFTER_MAX:-${REPLICATION_LIVE_BUSINESS_EXPORT_SET_QUEUED_AFTER_MAX:-0}}"
LIFECYCLE_NO_LONGER_QUEUED_MIN="${GBS_REPLICATION_LIVE_LIFECYCLE_NO_LONGER_QUEUED_MIN:-${REPLICATION_LIVE_LIFECYCLE_NO_LONGER_QUEUED_MIN:-1}}"
LIFECYCLE_GCED_QUEUED_MIN="${GBS_REPLICATION_LIVE_LIFECYCLE_GCED_QUEUED_MIN:-${REPLICATION_LIVE_LIFECYCLE_GCED_QUEUED_MIN:-1}}"
LIFECYCLE_NO_LONGER_ACKNOWLEDGED_MIN="${GBS_REPLICATION_LIVE_LIFECYCLE_NO_LONGER_ACKNOWLEDGED_MIN:-${REPLICATION_LIVE_LIFECYCLE_NO_LONGER_ACKNOWLEDGED_MIN:-1}}"
LIFECYCLE_GCED_ACKNOWLEDGED_MIN="${GBS_REPLICATION_LIVE_LIFECYCLE_GCED_ACKNOWLEDGED_MIN:-${REPLICATION_LIVE_LIFECYCLE_GCED_ACKNOWLEDGED_MIN:-1}}"
TREND_REGRESSION_PERCENT="${GBS_REPLICATION_LIVE_REGRESSION_PERCENT:-${REPLICATION_LIVE_REGRESSION_PERCENT:-100}}"
TREND_REGRESSION_MIN_DELTA_MS="${GBS_REPLICATION_LIVE_REGRESSION_MIN_DELTA_MS:-${REPLICATION_LIVE_REGRESSION_MIN_DELTA_MS:-250}}"

emit_summary() {
  local result="$1"
  local code="$2"
  local connector_ms="${3:-0}"
  local clamped_ms="${4:-0}"
  local dirty_store_ms="${5:-0}"
  local clamped_fetches="${6:-0}"
  local clamped_fallbacks="${7:-0}"
  local native_flushes="${8:-0}"
  local semantic_commands="${9:-0}"
  local semantic_entries="${10:-0}"
  local semantic_dictionary_entries="${11:-0}"
  local semantic_set_entries="${12:-0}"
  local semantic_bag_entries="${13:-0}"
  local dirty_objects="${14:-0}"
  local export_before="${15:-0}"
  local export_after="${16:-0}"
  local business_dirty_store_ms="${17:-0}"
  local business_dirty_objects="${18:-0}"
  local business_fixture_size="${19:-0}"
  local business_export_after="${20:-0}"
  local callback_clamp_specs="${CALLBACK_CLAMP_SPECS:-0}"
  local per_instvar_clamp_entries="${PER_INSTVAR_CLAMP_ENTRIES:-0}"
  local inherited_replication_spec_fixtures="${INHERITED_REPLICATION_SPEC_FIXTURES:-0}"
  local connector_pair_count="${CONNECTOR_PAIR_COUNT:-0}"
  local domain_fixture_count="${DOMAIN_FIXTURE_COUNT:-0}"
  local domain_per_instvar_clamp_entries="${DOMAIN_PER_INSTVAR_CLAMP_ENTRIES:-0}"
  local domain_callback_clamp_specs="${DOMAIN_CALLBACK_CLAMP_SPECS:-0}"
  local domain_dirty_store_ms="${DOMAIN_DIRTY_STORE_MS:-0}"
  local domain_dirty_objects="${DOMAIN_DIRTY_OBJECTS:-0}"
  local domain_native_flushes="${DOMAIN_NATIVE_FLUSHES:-0}"
  local domain_native_entries="${DOMAIN_NATIVE_ENTRIES:-0}"
  local lifecycle_no_longer_queued="${LIFECYCLE_NO_LONGER_QUEUED:-0}"
  local lifecycle_gced_queued="${LIFECYCLE_GCED_QUEUED:-0}"
  local lifecycle_no_longer_acknowledged="${LIFECYCLE_NO_LONGER_ACKNOWLEDGED:-0}"
  local lifecycle_gced_acknowledged="${LIFECYCLE_GCED_ACKNOWLEDGED:-0}"
  local json_payload markdown_payload
  echo "REPLICATION_LIVE_SUMMARY result=${result} code=${code} connector_ms=${connector_ms} clamped_ms=${clamped_ms} dirty_store_ms=${dirty_store_ms} business_dirty_store_ms=${business_dirty_store_ms} domain_dirty_store_ms=${domain_dirty_store_ms} callback_clamp_specs=${callback_clamp_specs} per_instvar_clamp_entries=${per_instvar_clamp_entries} inherited_replication_spec_fixtures=${inherited_replication_spec_fixtures} connector_pair_count=${connector_pair_count} domain_fixture_count=${domain_fixture_count} domain_per_instvar_clamp_entries=${domain_per_instvar_clamp_entries} domain_callback_clamp_specs=${domain_callback_clamp_specs} domain_dirty_objects_flushed=${domain_dirty_objects} domain_native_dirty_store_flushes=${domain_native_flushes} domain_native_dirty_store_entries=${domain_native_entries} clamped_traversal_fetches=${clamped_fetches} clamped_traversal_fallbacks=${clamped_fallbacks} native_dirty_store_flushes=${native_flushes} semantic_dirty_store_commands=${semantic_commands} semantic_dirty_store_entries=${semantic_entries} semantic_dictionary_entries=${semantic_dictionary_entries} semantic_set_entries=${semantic_set_entries} semantic_bag_entries=${semantic_bag_entries} dirty_objects_flushed=${dirty_objects} business_dirty_objects_flushed=${business_dirty_objects} business_write_fixture_size=${business_fixture_size} export_set_queued_before=${export_before} export_set_queued_after=${export_after} lifecycle_no_longer_queued=${lifecycle_no_longer_queued} lifecycle_gced_queued=${lifecycle_gced_queued} lifecycle_no_longer_acknowledged=${lifecycle_no_longer_acknowledged} lifecycle_gced_acknowledged=${lifecycle_gced_acknowledged} business_export_set_queued_after=${business_export_after} connector_max_ms=${CONNECTOR_MAX_MS} clamped_max_ms=${CLAMPED_MAX_MS} dirty_store_max_ms=${DIRTY_STORE_MAX_MS} business_dirty_store_max_ms=${BUSINESS_DIRTY_STORE_MAX_MS} domain_dirty_store_max_ms=${DOMAIN_DIRTY_STORE_MAX_MS} threshold_file=${THRESHOLD_FILE} work_image=${WORK_IMAGE}"
  printf -v json_payload '{"result":"%s","code":"%s","connector_ms":"%s","clamped_ms":"%s","dirty_store_ms":"%s","business_dirty_store_ms":"%s","domain_dirty_store_ms":"%s","callback_clamp_specs":"%s","per_instvar_clamp_entries":"%s","inherited_replication_spec_fixtures":"%s","connector_pair_count":"%s","domain_fixture_count":"%s","domain_per_instvar_clamp_entries":"%s","domain_callback_clamp_specs":"%s","domain_dirty_objects_flushed":"%s","domain_native_dirty_store_flushes":"%s","domain_native_dirty_store_entries":"%s","clamped_traversal_fetches":"%s","clamped_traversal_fallbacks":"%s","native_dirty_store_flushes":"%s","semantic_dirty_store_commands":"%s","semantic_dirty_store_entries":"%s","semantic_dictionary_entries":"%s","semantic_set_entries":"%s","semantic_bag_entries":"%s","dirty_objects_flushed":"%s","business_dirty_objects_flushed":"%s","business_write_fixture_size":"%s","export_set_queued_before":"%s","export_set_queued_after":"%s","lifecycle_no_longer_queued":"%s","lifecycle_gced_queued":"%s","lifecycle_no_longer_acknowledged":"%s","lifecycle_gced_acknowledged":"%s","business_export_set_queued_after":"%s","connector_max_ms":"%s","clamped_max_ms":"%s","dirty_store_max_ms":"%s","business_dirty_store_max_ms":"%s","domain_dirty_store_max_ms":"%s","threshold_file":"%s","work_image":"%s"}' \
    "$(gbs_json_escape "${result}")" \
    "$(gbs_json_escape "${code}")" \
    "$(gbs_json_escape "${connector_ms}")" \
    "$(gbs_json_escape "${clamped_ms}")" \
    "$(gbs_json_escape "${dirty_store_ms}")" \
    "$(gbs_json_escape "${business_dirty_store_ms}")" \
    "$(gbs_json_escape "${domain_dirty_store_ms}")" \
    "$(gbs_json_escape "${callback_clamp_specs}")" \
    "$(gbs_json_escape "${per_instvar_clamp_entries}")" \
    "$(gbs_json_escape "${inherited_replication_spec_fixtures}")" \
    "$(gbs_json_escape "${connector_pair_count}")" \
    "$(gbs_json_escape "${domain_fixture_count}")" \
    "$(gbs_json_escape "${domain_per_instvar_clamp_entries}")" \
    "$(gbs_json_escape "${domain_callback_clamp_specs}")" \
    "$(gbs_json_escape "${domain_dirty_objects}")" \
    "$(gbs_json_escape "${domain_native_flushes}")" \
    "$(gbs_json_escape "${domain_native_entries}")" \
    "$(gbs_json_escape "${clamped_fetches}")" \
    "$(gbs_json_escape "${clamped_fallbacks}")" \
    "$(gbs_json_escape "${native_flushes}")" \
    "$(gbs_json_escape "${semantic_commands}")" \
    "$(gbs_json_escape "${semantic_entries}")" \
    "$(gbs_json_escape "${semantic_dictionary_entries}")" \
    "$(gbs_json_escape "${semantic_set_entries}")" \
    "$(gbs_json_escape "${semantic_bag_entries}")" \
    "$(gbs_json_escape "${dirty_objects}")" \
    "$(gbs_json_escape "${business_dirty_objects}")" \
    "$(gbs_json_escape "${business_fixture_size}")" \
    "$(gbs_json_escape "${export_before}")" \
    "$(gbs_json_escape "${export_after}")" \
    "$(gbs_json_escape "${lifecycle_no_longer_queued}")" \
    "$(gbs_json_escape "${lifecycle_gced_queued}")" \
    "$(gbs_json_escape "${lifecycle_no_longer_acknowledged}")" \
    "$(gbs_json_escape "${lifecycle_gced_acknowledged}")" \
    "$(gbs_json_escape "${business_export_after}")" \
    "$(gbs_json_escape "${CONNECTOR_MAX_MS}")" \
    "$(gbs_json_escape "${CLAMPED_MAX_MS}")" \
    "$(gbs_json_escape "${DIRTY_STORE_MAX_MS}")" \
    "$(gbs_json_escape "${BUSINESS_DIRTY_STORE_MAX_MS}")" \
    "$(gbs_json_escape "${DOMAIN_DIRTY_STORE_MAX_MS}")" \
    "$(gbs_json_escape "${THRESHOLD_FILE}")" \
    "$(gbs_json_escape "${WORK_IMAGE}")"
  if [[ "${JSON_SUMMARY}" == "1" ]]; then
    printf 'REPLICATION_LIVE_SUMMARY_JSON %s\n' "${json_payload}"
  fi
  gbs_write_json_summary_file "replication-live-summary.json" "${json_payload}"
  printf -v markdown_payload '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' \
    '# Replication Live Validation' \
    "" \
    "- result: \`${result}\`" \
    "- code: \`${code}\`" \
    "- connector install: \`${connector_ms} ms\`" \
    "- strict parity fixtures: callback clamp specs \`${callback_clamp_specs}\`, per-instvar entries \`${per_instvar_clamp_entries}\`, inherited spec fixtures \`${inherited_replication_spec_fixtures}\`" \
    "- connector manager report: connector pairs \`${connector_pair_count}\`" \
    "- migration-domain fixture: fixtures \`${domain_fixture_count}\`, callback specs \`${domain_callback_clamp_specs}\`, per-instvar entries \`${domain_per_instvar_clamp_entries}\`, native dirty-store \`${domain_dirty_store_ms} ms\`, native flushes \`${domain_native_flushes}\`, native entries \`${domain_native_entries}\`, dirty objects \`${domain_dirty_objects}\`" \
    "- clamped traversal fetch: \`${clamped_ms} ms\`, GciClampedTrav calls \`${clamped_fetches}\`, fallbacks \`${clamped_fallbacks}\`" \
    "- dirty-store flush: \`${dirty_store_ms} ms\`, native flushes \`${native_flushes}\`, semantic commands \`${semantic_commands}\`, semantic entries \`${semantic_entries}\`, dirty objects \`${dirty_objects}\`" \
    "- semantic collection entries: Dictionary \`${semantic_dictionary_entries}\`, Set \`${semantic_set_entries}\`, Bag \`${semantic_bag_entries}\`" \
    "- business dirty-store flush: \`${business_dirty_store_ms} ms\`, dirty objects \`${business_dirty_objects}\`, fixture size \`${business_fixture_size}\`" \
    "- export-set queues: before \`${export_before}\`, after \`${export_after}\`, business after \`${business_export_after}\`" \
    "- lifecycle counters: no-longer queued \`${lifecycle_no_longer_queued}\`, gced queued \`${lifecycle_gced_queued}\`, no-longer acknowledged \`${lifecycle_no_longer_acknowledged}\`, gced acknowledged \`${lifecycle_gced_acknowledged}\`" \
    "- thresholds: connector \`${CONNECTOR_MAX_MS} ms\`, clamped \`${CLAMPED_MAX_MS} ms\`, dirty-store \`${DIRTY_STORE_MAX_MS} ms\`, business dirty-store \`${BUSINESS_DIRTY_STORE_MAX_MS} ms\`, domain dirty-store \`${DOMAIN_DIRTY_STORE_MAX_MS} ms\`" \
    "- threshold file: \`${THRESHOLD_FILE}\`" \
    "- work image: \`${WORK_IMAGE}\`" \
    "" \
    "Generated by \`make replication-live\`."
  gbs_write_evidence_file "replication-live-summary.md" "${markdown_payload}"
  gbs_append_summary_line "### Replication Live Validation"
  gbs_append_summary_line "- result: \`${result}\`"
  gbs_append_summary_line "- code: \`${code}\`"
  gbs_append_summary_line "- connector install: \`${connector_ms} ms\`"
  gbs_append_summary_line "- strict parity fixtures: callback clamp specs \`${callback_clamp_specs}\`, per-instvar entries \`${per_instvar_clamp_entries}\`, inherited spec fixtures \`${inherited_replication_spec_fixtures}\`"
  gbs_append_summary_line "- connector manager report: connector pairs \`${connector_pair_count}\`"
  gbs_append_summary_line "- migration-domain fixture: fixtures \`${domain_fixture_count}\`, callback specs \`${domain_callback_clamp_specs}\`, per-instvar entries \`${domain_per_instvar_clamp_entries}\`, native dirty-store \`${domain_dirty_store_ms} ms\`, native flushes \`${domain_native_flushes}\`, native entries \`${domain_native_entries}\`, dirty objects \`${domain_dirty_objects}\`"
  gbs_append_summary_line "- clamped traversal fetch: \`${clamped_ms} ms\`, GciClampedTrav calls \`${clamped_fetches}\`, fallbacks \`${clamped_fallbacks}\`"
  gbs_append_summary_line "- dirty-store flush: \`${dirty_store_ms} ms\`, native flushes \`${native_flushes}\`, semantic commands \`${semantic_commands}\`, semantic entries \`${semantic_entries}\`, dirty objects \`${dirty_objects}\`"
  gbs_append_summary_line "- semantic collection entries: Dictionary \`${semantic_dictionary_entries}\`, Set \`${semantic_set_entries}\`, Bag \`${semantic_bag_entries}\`"
  gbs_append_summary_line "- business dirty-store flush: \`${business_dirty_store_ms} ms\`, dirty objects \`${business_dirty_objects}\`, fixture size \`${business_fixture_size}\`"
  gbs_append_summary_line "- export-set queues: before \`${export_before}\`, after \`${export_after}\`, business after \`${business_export_after}\`"
  gbs_append_summary_line "- lifecycle counters: no-longer queued \`${lifecycle_no_longer_queued}\`, gced queued \`${lifecycle_gced_queued}\`, no-longer acknowledged \`${lifecycle_no_longer_acknowledged}\`, gced acknowledged \`${lifecycle_gced_acknowledged}\`"
  gbs_append_summary_line "- thresholds: connector \`${CONNECTOR_MAX_MS} ms\`, clamped \`${CLAMPED_MAX_MS} ms\`, dirty-store \`${DIRTY_STORE_MAX_MS} ms\`, business dirty-store \`${BUSINESS_DIRTY_STORE_MAX_MS} ms\`, domain dirty-store \`${DOMAIN_DIRTY_STORE_MAX_MS} ms\`"
}

extract_summary_field() {
  local line="$1"
  local field="$2"
  printf '%s\n' "${line}" | sed -n "s/.* ${field}=\\([^ ]*\\).*/\\1/p" | tail -1
}

emit_current_failure_summary() {
  local code="$1"
  emit_summary "FAIL" "${code}" "${CONNECTOR_MS:-0}" "${CLAMPED_MS:-0}" "${DIRTY_STORE_MS:-0}" "${CLAMPED_FETCHES:-0}" "${CLAMPED_FALLBACKS:-0}" "${NATIVE_FLUSHES:-0}" "${SEMANTIC_COMMANDS:-0}" "${SEMANTIC_ENTRIES:-0}" "${SEMANTIC_DICTIONARY_ENTRIES:-0}" "${SEMANTIC_SET_ENTRIES:-0}" "${SEMANTIC_BAG_ENTRIES:-0}" "${DIRTY_OBJECTS:-0}" "${EXPORT_BEFORE:-0}" "${EXPORT_AFTER:-0}" "${BUSINESS_DIRTY_STORE_MS:-0}" "${BUSINESS_DIRTY_OBJECTS:-0}" "${BUSINESS_WRITE_FIXTURE_SIZE:-0}" "${BUSINESS_EXPORT_AFTER:-0}"
}

replication_required_live_env_vars() {
  printf '%s\n' \
    GS_USER \
    GS_PASS \
    GEMSTONE
}

replication_missing_required_live_env_vars() {
  local var missing=""
  while IFS= read -r var; do
    [[ -n "${var}" ]] || continue
    if [[ -z "${!var:-}" ]]; then
      if [[ -n "${missing}" ]]; then
        missing="${missing},${var}"
      else
        missing="${var}"
      fi
    fi
  done < <(replication_required_live_env_vars)
  printf '%s\n' "${missing}"
}

print_replication_live_excerpt() {
  local output="$1"
  if [[ "${GBS_VERBOSE_LIVE_OUTPUT:-0}" == "1" ]]; then
    printf '%s\n' "${output}"
    return 0
  fi
  printf '%s\n' "${output}" | grep -E '^(Using work image:|LIVE_PREFLIGHT_(BEGIN|SUMMARY|OK|FAIL|SKIP|STONE_OK|NETLDI_OK|TOPAZ_LOGIN_OK|GCI_LOGIN_OK|MISSING_ENV)|PROBE_(CONFIG|LOGIN_OK|EVAL_RESULT)|REPLICATION_LIVE_(VALIDATION|SUMMARY))' || true
}

check_latency_threshold() {
  local label="$1"
  local value="$2"
  local max="$3"
  if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
    emit_current_failure_summary "REPLICATION_LIVE_BAD_${label}_METRIC"
    echo "Replication live metric ${label} is not a non-negative integer: ${value}" >&2
    exit 1
  fi
  if [[ ! "${max}" =~ ^[0-9]+$ ]]; then
    emit_current_failure_summary "REPLICATION_LIVE_BAD_${label}_THRESHOLD"
    echo "Replication live threshold ${label} is not a non-negative integer: ${max}" >&2
    exit 1
  fi
  if (( value > max )); then
    emit_current_failure_summary "REPLICATION_LIVE_${label}_THRESHOLD_EXCEEDED"
    echo "Replication live metric ${label}=${value}ms exceeded threshold ${max}ms." >&2
    exit 1
  fi
}

check_count_threshold() {
  local label="$1"
  local value="$2"
  local max="$3"
  if [[ ! "${value}" =~ ^[0-9]+$ || ! "${max}" =~ ^[0-9]+$ ]]; then
    emit_current_failure_summary "REPLICATION_LIVE_BAD_${label}_COUNT"
    echo "Replication live count ${label} or threshold is not a non-negative integer: value=${value} max=${max}" >&2
    exit 1
  fi
  if (( value > max )); then
    emit_current_failure_summary "REPLICATION_LIVE_${label}_COUNT_THRESHOLD_EXCEEDED"
    echo "Replication live count ${label}=${value} exceeded threshold ${max}." >&2
    exit 1
  fi
}

check_count_minimum() {
  local label="$1"
  local value="$2"
  local min="$3"
  if [[ ! "${value}" =~ ^[0-9]+$ || ! "${min}" =~ ^[0-9]+$ ]]; then
    emit_current_failure_summary "REPLICATION_LIVE_BAD_${label}_MIN_COUNT"
    echo "Replication live count ${label} or minimum is not a non-negative integer: value=${value} min=${min}" >&2
    exit 1
  fi
  if (( value < min )); then
    emit_current_failure_summary "REPLICATION_LIVE_${label}_COUNT_BELOW_MINIMUM"
    echo "Replication live count ${label}=${value} was below required minimum ${min}." >&2
    exit 1
  fi
}

trend_file_path() {
  local trend_file="${GBS_REPLICATION_LIVE_TRENDS:-}"
  if [[ -z "${trend_file}" ]]; then
    [[ -n "${GBS_EVIDENCE_DIR:-}" ]] || return 0
    trend_file="${GBS_EVIDENCE_DIR}/replication-live-trends.jsonl"
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
  local percent_allowed absolute_allowed allowed
  [[ "${previous}" =~ ^[0-9]+$ ]] || return 0
  [[ "${current}" =~ ^[0-9]+$ ]] || return 0
  (( previous > 0 )) || return 0
  if [[ ! "${TREND_REGRESSION_PERCENT}" =~ ^[0-9]+$ ]]; then
    emit_current_failure_summary "REPLICATION_LIVE_BAD_TREND_PERCENT"
    echo "Replication live trend percent is not a non-negative integer: ${TREND_REGRESSION_PERCENT}" >&2
    exit 1
  fi
  if [[ ! "${TREND_REGRESSION_MIN_DELTA_MS}" =~ ^[0-9]+$ ]]; then
    emit_current_failure_summary "REPLICATION_LIVE_BAD_TREND_MIN_DELTA"
    echo "Replication live minimum trend delta is not a non-negative integer: ${TREND_REGRESSION_MIN_DELTA_MS}" >&2
    exit 1
  fi
  percent_allowed=$(( previous + (previous * TREND_REGRESSION_PERCENT / 100) ))
  absolute_allowed=$(( previous + TREND_REGRESSION_MIN_DELTA_MS ))
  allowed="${percent_allowed}"
  if (( absolute_allowed > allowed )); then
    allowed="${absolute_allowed}"
  fi
  if (( current > allowed )); then
    emit_current_failure_summary "REPLICATION_LIVE_${label}_TREND_REGRESSION"
    echo "Replication live trend regression ${label}: current=${current}ms previous=${previous}ms allowed=${allowed}ms (${TREND_REGRESSION_PERCENT}% or +${TREND_REGRESSION_MIN_DELTA_MS}ms)." >&2
    exit 1
  fi
}

check_trend_regression() {
  local trend_file previous_line previous_connector previous_clamped previous_dirty previous_business previous_domain
  trend_file="$(trend_file_path)"
  [[ -n "${trend_file}" && -f "${trend_file}" ]] || return 0
  previous_line="$(grep -v '^[[:space:]]*$' "${trend_file}" | tail -1 || true)"
  [[ -n "${previous_line}" ]] || return 0
  previous_connector="$(json_line_number_field "${previous_line}" connector_ms)"
  previous_clamped="$(json_line_number_field "${previous_line}" clamped_ms)"
  previous_dirty="$(json_line_number_field "${previous_line}" dirty_store_ms)"
  previous_business="$(json_line_number_field "${previous_line}" business_dirty_store_ms)"
  previous_domain="$(json_line_number_field "${previous_line}" domain_dirty_store_ms)"
  check_trend_metric "CONNECTOR" "${CONNECTOR_MS}" "${previous_connector}"
  check_trend_metric "CLAMPED" "${CLAMPED_MS}" "${previous_clamped}"
  check_trend_metric "DIRTY_STORE" "${DIRTY_STORE_MS}" "${previous_dirty}"
  check_trend_metric "BUSINESS_DIRTY_STORE" "${BUSINESS_DIRTY_STORE_MS}" "${previous_business}"
  check_trend_metric "DOMAIN_DIRTY_STORE" "${DOMAIN_DIRTY_STORE_MS}" "${previous_domain}"
  gbs_append_summary_line "- trend comparison: previous sample from \`${trend_file}\`, threshold \`${TREND_REGRESSION_PERCENT}%\` or \`+${TREND_REGRESSION_MIN_DELTA_MS} ms\`, whichever is larger"
}

write_trend_sample() {
  local trend_file timestamp
  trend_file="$(trend_file_path)"
  [[ -n "${trend_file}" ]] || return 0
  mkdir -p "$(dirname "${trend_file}")"
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf '{"timestamp":"%s","connector_ms":%s,"clamped_ms":%s,"dirty_store_ms":%s,"business_dirty_store_ms":%s,"domain_dirty_store_ms":%s,"callback_clamp_specs":%s,"per_instvar_clamp_entries":%s,"inherited_replication_spec_fixtures":%s,"connector_pair_count":%s,"domain_fixture_count":%s,"domain_per_instvar_clamp_entries":%s,"domain_callback_clamp_specs":%s,"domain_dirty_objects_flushed":%s,"domain_native_dirty_store_flushes":%s,"domain_native_dirty_store_entries":%s,"clamped_traversal_fetches":%s,"clamped_traversal_fallbacks":%s,"native_dirty_store_flushes":%s,"semantic_dirty_store_commands":%s,"semantic_dirty_store_entries":%s,"semantic_dictionary_entries":%s,"semantic_set_entries":%s,"semantic_bag_entries":%s,"dirty_objects_flushed":%s,"business_dirty_objects_flushed":%s,"business_write_fixture_size":%s,"export_set_queued_after":%s,"lifecycle_no_longer_queued":%s,"lifecycle_gced_queued":%s,"lifecycle_no_longer_acknowledged":%s,"lifecycle_gced_acknowledged":%s,"business_export_set_queued_after":%s,"connector_max_ms":%s,"clamped_max_ms":%s,"dirty_store_max_ms":%s,"business_dirty_store_max_ms":%s,"domain_dirty_store_max_ms":%s}\n' \
    "${timestamp}" \
    "${CONNECTOR_MS}" \
    "${CLAMPED_MS}" \
    "${DIRTY_STORE_MS}" \
    "${BUSINESS_DIRTY_STORE_MS}" \
    "${DOMAIN_DIRTY_STORE_MS}" \
    "${CALLBACK_CLAMP_SPECS}" \
    "${PER_INSTVAR_CLAMP_ENTRIES}" \
    "${INHERITED_REPLICATION_SPEC_FIXTURES}" \
    "${CONNECTOR_PAIR_COUNT}" \
    "${DOMAIN_FIXTURE_COUNT}" \
    "${DOMAIN_PER_INSTVAR_CLAMP_ENTRIES}" \
    "${DOMAIN_CALLBACK_CLAMP_SPECS}" \
    "${DOMAIN_DIRTY_OBJECTS}" \
    "${DOMAIN_NATIVE_FLUSHES}" \
    "${DOMAIN_NATIVE_ENTRIES}" \
    "${CLAMPED_FETCHES}" \
    "${CLAMPED_FALLBACKS}" \
    "${NATIVE_FLUSHES}" \
    "${SEMANTIC_COMMANDS}" \
    "${SEMANTIC_ENTRIES}" \
    "${SEMANTIC_DICTIONARY_ENTRIES}" \
    "${SEMANTIC_SET_ENTRIES}" \
    "${SEMANTIC_BAG_ENTRIES}" \
    "${DIRTY_OBJECTS}" \
    "${BUSINESS_DIRTY_OBJECTS}" \
    "${BUSINESS_WRITE_FIXTURE_SIZE}" \
    "${EXPORT_AFTER}" \
    "${LIFECYCLE_NO_LONGER_QUEUED}" \
    "${LIFECYCLE_GCED_QUEUED}" \
    "${LIFECYCLE_NO_LONGER_ACKNOWLEDGED}" \
    "${LIFECYCLE_GCED_ACKNOWLEDGED}" \
    "${BUSINESS_EXPORT_AFTER}" \
    "${CONNECTOR_MAX_MS}" \
    "${CLAMPED_MAX_MS}" \
    "${DIRTY_STORE_MAX_MS}" \
    "${BUSINESS_DIRTY_STORE_MAX_MS}" \
    "${DOMAIN_DIRTY_STORE_MAX_MS}" >> "${trend_file}"
  gbs_append_summary_line "- trend sample: \`${trend_file}\`"
}

write_trend_report() {
  local trend_file report_file line timestamp connector clamped dirty business domain dirty_objects business_objects domain_objects fixture_size fallbacks semantic_commands semantic_entries
  trend_file="$(trend_file_path)"
  [[ -n "${trend_file}" && -f "${trend_file}" ]] || return 0
  report_file="${GBS_REPLICATION_LIVE_REPORT:-$(dirname "${trend_file}")/replication-live-trend-report.md}"
  mkdir -p "$(dirname "${report_file}")"
  {
    printf '# Replication Live Trend\n\n'
    printf 'Regression threshold: `%s%%` over the previous sample or `+%s ms`, whichever is larger.\n\n' "${TREND_REGRESSION_PERCENT}" "${TREND_REGRESSION_MIN_DELTA_MS}"
    printf '| Timestamp | Connector | Clamped | Dirty Store | Business Dirty Store | Domain Dirty Store | Semantic Commands | Semantic Entries | Dirty Objects | Business Objects | Domain Objects | Fixture Size | Fallbacks |\n'
    printf '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n'
    grep -v '^[[:space:]]*$' "${trend_file}" | tail -20 | while IFS= read -r line; do
      timestamp="$(json_line_string_field "${line}" timestamp)"
      connector="$(json_line_number_field "${line}" connector_ms)"
      clamped="$(json_line_number_field "${line}" clamped_ms)"
      dirty="$(json_line_number_field "${line}" dirty_store_ms)"
      business="$(json_line_number_field "${line}" business_dirty_store_ms)"
      domain="$(json_line_number_field "${line}" domain_dirty_store_ms)"
      semantic_commands="$(json_line_number_field "${line}" semantic_dirty_store_commands)"
      semantic_entries="$(json_line_number_field "${line}" semantic_dirty_store_entries)"
      dirty_objects="$(json_line_number_field "${line}" dirty_objects_flushed)"
      business_objects="$(json_line_number_field "${line}" business_dirty_objects_flushed)"
      domain_objects="$(json_line_number_field "${line}" domain_dirty_objects_flushed)"
      fixture_size="$(json_line_number_field "${line}" business_write_fixture_size)"
      fallbacks="$(json_line_number_field "${line}" clamped_traversal_fallbacks)"
      printf '| %s | %s ms | %s ms | %s ms | %s ms | %s ms | %s | %s | %s | %s | %s | %s | %s |\n' \
        "${timestamp:-unknown}" \
        "${connector:-0}" \
        "${clamped:-0}" \
        "${dirty:-0}" \
        "${business:-0}" \
        "${domain:-0}" \
        "${semantic_commands:-0}" \
        "${semantic_entries:-0}" \
        "${dirty_objects:-0}" \
        "${business_objects:-0}" \
        "${domain_objects:-0}" \
        "${fixture_size:-0}" \
        "${fallbacks:-0}"
    done
  } > "${report_file}"
  gbs_append_summary_line "- trend report: \`${report_file}\`"
}

replication_preflight_failure_code() {
  local preflight_summary="$1"
  local preflight_code="$2"
  local host_auth="$3"
  if [[ "${preflight_code}" == "LIVE_PREFLIGHT_GCI_ROUTE_FAILED" && "${host_auth}" == "unset" ]]; then
    printf '%s\n' "REPLICATION_LIVE_GCI_HOST_AUTH_REQUIRED"
    return 0
  fi
  printf '%s\n' "REPLICATION_LIVE_PREFLIGHT_FAILED"
}

print_replication_preflight_failure_hint() {
  local preflight_code="$1"
  local host_auth="$2"
  if [[ "${preflight_code}" == "LIVE_PREFLIGHT_GCI_ROUTE_FAILED" && "${host_auth}" == "unset" ]]; then
    {
      echo "Live preflight reached GemStone with Topaz, but Pharo GCI could not route through netldi."
      echo "Host authentication is unset. Set OKZ_GEMSTONE_HOST_USERNAME and OKZ_GEMSTONE_HOST_PASSWORD,"
      echo "or aliases GS_HOST_USERNAME and GS_HOST_PASSWORD, then rerun make replication-live."
    } >&2
    return 0
  fi
  echo "Live preflight failed or skipped; refusing to validate replication paths against an unknown GemStone session." >&2
}

MISSING_LIVE_ENV="$(replication_missing_required_live_env_vars)"
if [[ -n "${MISSING_LIVE_ENV}" ]]; then
  emit_summary "FAIL" "REPLICATION_LIVE_MISSING_ENV"
  gbs_append_summary_line "- live env: \`required=$(replication_required_live_env_vars | paste -sd, -) missing=${MISSING_LIVE_ENV}\`"
  echo "Missing required replication live environment: ${MISSING_LIVE_ENV}" >&2
  echo "Set the missing variables before running make replication-live." >&2
  exit 2
fi

WORK_IMAGE="$(gbs_prepare_work_image "${SRC_IMAGE}" "${WORK_DIR}" "replicationlive")"
gbs_register_work_image_cleanup "${WORK_IMAGE}"

echo "Using work image: ${WORK_IMAGE}"
preflight_output="$(bash ./scripts/run_live_preflight.sh "${WORK_IMAGE}" 2>&1 || true)"
print_replication_live_excerpt "${preflight_output}"
gbs_write_evidence_file "replication-live-preflight.log" "${preflight_output}"
if ! grep -q "LIVE_PREFLIGHT_SUMMARY result=OK code=LIVE_PREFLIGHT_OK" <<< "${preflight_output}"; then
  preflight_summary_line="$(printf '%s\n' "${preflight_output}" | grep 'LIVE_PREFLIGHT_SUMMARY result=' | tail -1 || true)"
  PREFLIGHT_CODE="$(extract_summary_field "${preflight_summary_line}" code)"
  PREFLIGHT_HOST_AUTH="$(extract_summary_field "${preflight_summary_line}" host_auth)"
  [[ -n "${PREFLIGHT_CODE}" ]] || PREFLIGHT_CODE="LIVE_PREFLIGHT_RUNNER_FAILED"
  [[ -n "${PREFLIGHT_HOST_AUTH}" ]] || PREFLIGHT_HOST_AUTH="$(gbs_live_host_auth_status)"
  emit_summary "FAIL" "$(replication_preflight_failure_code "${preflight_summary_line}" "${PREFLIGHT_CODE}" "${PREFLIGHT_HOST_AUTH}")"
  print_replication_preflight_failure_hint "${PREFLIGHT_CODE}" "${PREFLIGHT_HOST_AUTH}"
  exit 1
fi

validation_output="$(HOME=/tmp/pharo-clean-auto/home GBS_WORK_IMAGE="${WORK_IMAGE}" "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/run_replication_live_validation.st" 2>&1 || true)"
print_replication_live_excerpt "${validation_output}"
gbs_write_evidence_file "replication-live-validation.log" "${validation_output}"

summary_line="$(printf '%s\n' "${validation_output}" | grep '^REPLICATION_LIVE_VALIDATION result=' | tail -1 || true)"
if [[ -z "${summary_line}" ]]; then
  emit_summary "FAIL" "REPLICATION_LIVE_RUNNER_FAILED"
  echo "Replication live runner did not emit REPLICATION_LIVE_VALIDATION." >&2
  exit 1
fi

RESULT="$(extract_summary_field "${summary_line}" result)"
CODE="$(extract_summary_field "${summary_line}" code)"
CONNECTOR_MS="$(extract_summary_field "${summary_line}" connector_ms)"
CLAMPED_MS="$(extract_summary_field "${summary_line}" clamped_ms)"
DIRTY_STORE_MS="$(extract_summary_field "${summary_line}" dirty_store_ms)"
BUSINESS_DIRTY_STORE_MS="$(extract_summary_field "${summary_line}" business_dirty_store_ms)"
DOMAIN_DIRTY_STORE_MS="$(extract_summary_field "${summary_line}" domain_dirty_store_ms)"
CLAMPED_FETCHES="$(extract_summary_field "${summary_line}" clamped_traversal_fetches)"
CLAMPED_FALLBACKS="$(extract_summary_field "${summary_line}" clamped_traversal_fallbacks)"
CALLBACK_CLAMP_SPECS="$(extract_summary_field "${summary_line}" callback_clamp_specs)"
PER_INSTVAR_CLAMP_ENTRIES="$(extract_summary_field "${summary_line}" per_instvar_clamp_entries)"
INHERITED_REPLICATION_SPEC_FIXTURES="$(extract_summary_field "${summary_line}" inherited_replication_spec_fixtures)"
CONNECTOR_PAIR_COUNT="$(extract_summary_field "${summary_line}" connector_pair_count)"
DOMAIN_FIXTURE_COUNT="$(extract_summary_field "${summary_line}" domain_fixture_count)"
DOMAIN_PER_INSTVAR_CLAMP_ENTRIES="$(extract_summary_field "${summary_line}" domain_per_instvar_clamp_entries)"
DOMAIN_CALLBACK_CLAMP_SPECS="$(extract_summary_field "${summary_line}" domain_callback_clamp_specs)"
DOMAIN_DIRTY_OBJECTS="$(extract_summary_field "${summary_line}" domain_dirty_objects_flushed)"
DOMAIN_NATIVE_FLUSHES="$(extract_summary_field "${summary_line}" domain_native_dirty_store_flushes)"
DOMAIN_NATIVE_ENTRIES="$(extract_summary_field "${summary_line}" domain_native_dirty_store_entries)"
NATIVE_FLUSHES="$(extract_summary_field "${summary_line}" native_dirty_store_flushes)"
SEMANTIC_COMMANDS="$(extract_summary_field "${summary_line}" semantic_dirty_store_commands)"
SEMANTIC_ENTRIES="$(extract_summary_field "${summary_line}" semantic_dirty_store_entries)"
SEMANTIC_DICTIONARY_ENTRIES="$(extract_summary_field "${summary_line}" semantic_dictionary_entries)"
SEMANTIC_SET_ENTRIES="$(extract_summary_field "${summary_line}" semantic_set_entries)"
SEMANTIC_BAG_ENTRIES="$(extract_summary_field "${summary_line}" semantic_bag_entries)"
DIRTY_OBJECTS="$(extract_summary_field "${summary_line}" dirty_objects_flushed)"
BUSINESS_DIRTY_OBJECTS="$(extract_summary_field "${summary_line}" business_dirty_objects_flushed)"
BUSINESS_WRITE_FIXTURE_SIZE="$(extract_summary_field "${summary_line}" business_write_fixture_size)"
EXPORT_BEFORE="$(extract_summary_field "${summary_line}" export_set_queued_before)"
EXPORT_AFTER="$(extract_summary_field "${summary_line}" export_set_queued_after)"
LIFECYCLE_NO_LONGER_QUEUED="$(extract_summary_field "${summary_line}" lifecycle_no_longer_queued)"
LIFECYCLE_GCED_QUEUED="$(extract_summary_field "${summary_line}" lifecycle_gced_queued)"
LIFECYCLE_NO_LONGER_ACKNOWLEDGED="$(extract_summary_field "${summary_line}" lifecycle_no_longer_acknowledged)"
LIFECYCLE_GCED_ACKNOWLEDGED="$(extract_summary_field "${summary_line}" lifecycle_gced_acknowledged)"
BUSINESS_EXPORT_AFTER="$(extract_summary_field "${summary_line}" business_export_set_queued_after)"

if [[ "${RESULT}" != "OK" ]]; then
  emit_summary "FAIL" "${CODE:-REPLICATION_LIVE_FAILED}" "${CONNECTOR_MS:-0}" "${CLAMPED_MS:-0}" "${DIRTY_STORE_MS:-0}" "${CLAMPED_FETCHES:-0}" "${CLAMPED_FALLBACKS:-0}" "${NATIVE_FLUSHES:-0}" "${SEMANTIC_COMMANDS:-0}" "${SEMANTIC_ENTRIES:-0}" "${SEMANTIC_DICTIONARY_ENTRIES:-0}" "${SEMANTIC_SET_ENTRIES:-0}" "${SEMANTIC_BAG_ENTRIES:-0}" "${DIRTY_OBJECTS:-0}" "${EXPORT_BEFORE:-0}" "${EXPORT_AFTER:-0}" "${BUSINESS_DIRTY_STORE_MS:-0}" "${BUSINESS_DIRTY_OBJECTS:-0}" "${BUSINESS_WRITE_FIXTURE_SIZE:-0}" "${BUSINESS_EXPORT_AFTER:-0}"
  echo "Replication live validation failed: ${summary_line}" >&2
  exit 1
fi

check_latency_threshold "CONNECTOR" "${CONNECTOR_MS}" "${CONNECTOR_MAX_MS}"
check_latency_threshold "CLAMPED" "${CLAMPED_MS}" "${CLAMPED_MAX_MS}"
check_latency_threshold "DIRTY_STORE" "${DIRTY_STORE_MS}" "${DIRTY_STORE_MAX_MS}"
check_latency_threshold "BUSINESS_DIRTY_STORE" "${BUSINESS_DIRTY_STORE_MS}" "${BUSINESS_DIRTY_STORE_MAX_MS}"
check_latency_threshold "DOMAIN_DIRTY_STORE" "${DOMAIN_DIRTY_STORE_MS}" "${DOMAIN_DIRTY_STORE_MAX_MS}"
check_count_minimum "CLAMPED_FETCHES" "${CLAMPED_FETCHES}" "${CLAMPED_FETCHES_MIN}"
check_count_threshold "CLAMPED_FETCHES" "${CLAMPED_FETCHES}" "${CLAMPED_FETCHES_MAX}"
check_count_threshold "CLAMPED_FALLBACKS" "${CLAMPED_FALLBACKS}" "${CLAMPED_FALLBACKS_MAX}"
check_count_minimum "CALLBACK_CLAMP_SPECS" "${CALLBACK_CLAMP_SPECS}" "${CALLBACK_CLAMP_SPECS_MIN}"
check_count_minimum "PER_INSTVAR_CLAMP_ENTRIES" "${PER_INSTVAR_CLAMP_ENTRIES}" "${PER_INSTVAR_CLAMP_ENTRIES_MIN}"
check_count_minimum "INHERITED_REPLICATION_SPEC_FIXTURES" "${INHERITED_REPLICATION_SPEC_FIXTURES}" "${INHERITED_REPLICATION_SPEC_FIXTURES_MIN}"
check_count_minimum "CONNECTOR_PAIR_COUNT" "${CONNECTOR_PAIR_COUNT}" "${CONNECTOR_PAIR_COUNT_MIN}"
check_count_minimum "DOMAIN_FIXTURE_COUNT" "${DOMAIN_FIXTURE_COUNT}" "${DOMAIN_FIXTURE_COUNT_MIN}"
check_count_minimum "DOMAIN_PER_INSTVAR_CLAMP_ENTRIES" "${DOMAIN_PER_INSTVAR_CLAMP_ENTRIES}" "${DOMAIN_PER_INSTVAR_CLAMP_ENTRIES_MIN}"
check_count_minimum "DOMAIN_CALLBACK_CLAMP_SPECS" "${DOMAIN_CALLBACK_CLAMP_SPECS}" "${DOMAIN_CALLBACK_CLAMP_SPECS_MIN}"
check_count_minimum "DOMAIN_DIRTY_OBJECTS_FLUSHED" "${DOMAIN_DIRTY_OBJECTS}" "${DOMAIN_DIRTY_OBJECTS_FLUSHED_MIN}"
check_count_minimum "DOMAIN_NATIVE_DIRTY_STORE_FLUSHES" "${DOMAIN_NATIVE_FLUSHES}" "${DOMAIN_NATIVE_DIRTY_STORE_FLUSHES_MIN}"
check_count_minimum "DOMAIN_NATIVE_DIRTY_STORE_ENTRIES" "${DOMAIN_NATIVE_ENTRIES}" "${DOMAIN_NATIVE_DIRTY_STORE_ENTRIES_MIN}"
check_count_minimum "NATIVE_DIRTY_STORE_FLUSHES" "${NATIVE_FLUSHES}" "${NATIVE_DIRTY_STORE_FLUSHES_MIN}"
check_count_threshold "SEMANTIC_DIRTY_STORE_COMMANDS" "${SEMANTIC_COMMANDS}" "${SEMANTIC_DIRTY_STORE_COMMANDS_MAX}"
check_count_threshold "SEMANTIC_DIRTY_STORE_ENTRIES" "${SEMANTIC_ENTRIES}" "${SEMANTIC_DIRTY_STORE_ENTRIES_MAX}"
check_count_threshold "SEMANTIC_DICTIONARY_ENTRIES" "${SEMANTIC_DICTIONARY_ENTRIES}" "${SEMANTIC_DICTIONARY_ENTRIES_MAX}"
check_count_threshold "SEMANTIC_SET_ENTRIES" "${SEMANTIC_SET_ENTRIES}" "${SEMANTIC_SET_ENTRIES_MAX}"
check_count_threshold "SEMANTIC_BAG_ENTRIES" "${SEMANTIC_BAG_ENTRIES}" "${SEMANTIC_BAG_ENTRIES_MAX}"
check_count_minimum "DIRTY_OBJECTS_FLUSHED" "${DIRTY_OBJECTS}" "${DIRTY_OBJECTS_FLUSHED_MIN}"
check_count_minimum "BUSINESS_DIRTY_OBJECTS_FLUSHED" "${BUSINESS_DIRTY_OBJECTS}" "${BUSINESS_DIRTY_OBJECTS_FLUSHED_MIN}"
check_count_minimum "BUSINESS_WRITE_FIXTURE_SIZE" "${BUSINESS_WRITE_FIXTURE_SIZE}" "${BUSINESS_WRITE_FIXTURE_SIZE_MIN}"
check_count_threshold "EXPORT_SET_QUEUED_AFTER" "${EXPORT_AFTER}" "${EXPORT_SET_QUEUED_AFTER_MAX}"
check_count_minimum "LIFECYCLE_NO_LONGER_QUEUED" "${LIFECYCLE_NO_LONGER_QUEUED}" "${LIFECYCLE_NO_LONGER_QUEUED_MIN}"
check_count_minimum "LIFECYCLE_GCED_QUEUED" "${LIFECYCLE_GCED_QUEUED}" "${LIFECYCLE_GCED_QUEUED_MIN}"
check_count_minimum "LIFECYCLE_NO_LONGER_ACKNOWLEDGED" "${LIFECYCLE_NO_LONGER_ACKNOWLEDGED}" "${LIFECYCLE_NO_LONGER_ACKNOWLEDGED_MIN}"
check_count_minimum "LIFECYCLE_GCED_ACKNOWLEDGED" "${LIFECYCLE_GCED_ACKNOWLEDGED}" "${LIFECYCLE_GCED_ACKNOWLEDGED_MIN}"
check_count_threshold "BUSINESS_EXPORT_SET_QUEUED_AFTER" "${BUSINESS_EXPORT_AFTER}" "${BUSINESS_EXPORT_SET_QUEUED_AFTER_MAX}"
check_trend_regression
write_trend_sample
write_trend_report

emit_summary "OK" "REPLICATION_LIVE_OK" "${CONNECTOR_MS}" "${CLAMPED_MS}" "${DIRTY_STORE_MS}" "${CLAMPED_FETCHES}" "${CLAMPED_FALLBACKS}" "${NATIVE_FLUSHES}" "${SEMANTIC_COMMANDS}" "${SEMANTIC_ENTRIES}" "${SEMANTIC_DICTIONARY_ENTRIES}" "${SEMANTIC_SET_ENTRIES}" "${SEMANTIC_BAG_ENTRIES}" "${DIRTY_OBJECTS}" "${EXPORT_BEFORE}" "${EXPORT_AFTER}" "${BUSINESS_DIRTY_STORE_MS}" "${BUSINESS_DIRTY_OBJECTS}" "${BUSINESS_WRITE_FIXTURE_SIZE}" "${BUSINESS_EXPORT_AFTER}"
echo "REPLICATION_LIVE_OK"
