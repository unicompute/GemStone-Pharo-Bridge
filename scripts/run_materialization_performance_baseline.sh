#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/lane_common.sh"

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/140-x64/Pharo.app/Contents/MacOS/Pharo}"
SRC_IMAGE="${1:-/Users/tariq/Documents/Pharo/images/Pharo 14.0 - clean/Pharo 14.0 - clean.image}"
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
MIXED_MAX_MS="${GBS_MATERIALIZATION_MIXED_MAX_MS:-${MATERIALIZATION_MIXED_MAX_MS:-8000}}"
BUSINESS_MAX_MS="${GBS_MATERIALIZATION_BUSINESS_MAX_MS:-${MATERIALIZATION_BUSINESS_MAX_MS:-250}}"
CLAMPED_MAX_MS="${GBS_MATERIALIZATION_CLAMPED_MAX_MS:-${MATERIALIZATION_CLAMPED_MAX_MS:-50}}"
SHALLOW_WRAPPER_MAX_MS="${GBS_MATERIALIZATION_SHALLOW_WRAPPER_MAX_MS:-${MATERIALIZATION_SHALLOW_WRAPPER_MAX_MS:-800}}"
SHALLOW_WRAPPER_LOOKUP_MISSES_MAX="${GBS_MATERIALIZATION_SHALLOW_WRAPPER_LOOKUP_MISSES_MAX:-${MATERIALIZATION_SHALLOW_WRAPPER_LOOKUP_MISSES_MAX:-600}}"
MIXED_WRAPPER_LOOKUP_MISSES_MAX="${GBS_MATERIALIZATION_MIXED_WRAPPER_LOOKUP_MISSES_MAX:-${MATERIALIZATION_MIXED_WRAPPER_LOOKUP_MISSES_MAX:-6000}}"
BUSINESS_WRAPPER_LOOKUP_MISSES_MAX="${GBS_MATERIALIZATION_BUSINESS_WRAPPER_LOOKUP_MISSES_MAX:-${MATERIALIZATION_BUSINESS_WRAPPER_LOOKUP_MISSES_MAX:-4000}}"
SHALLOW_SLOT_BATCHES_MAX="${GBS_MATERIALIZATION_SHALLOW_SLOT_BATCHES_MAX:-${MATERIALIZATION_SHALLOW_SLOT_BATCHES_MAX:-4}}"
SHALLOW_CLASS_NAME_BATCHES_MAX="${GBS_MATERIALIZATION_SHALLOW_CLASS_NAME_BATCHES_MAX:-${MATERIALIZATION_SHALLOW_CLASS_NAME_BATCHES_MAX:-4}}"
MIXED_COLLECTION_ARRAY_BATCHES_MAX="${GBS_MATERIALIZATION_MIXED_COLLECTION_ARRAY_BATCHES_MAX:-${MATERIALIZATION_MIXED_COLLECTION_ARRAY_BATCHES_MAX:-8}}"
MIXED_DICTIONARY_PAIR_BATCHES_MAX="${GBS_MATERIALIZATION_MIXED_DICTIONARY_PAIR_BATCHES_MAX:-${MATERIALIZATION_MIXED_DICTIONARY_PAIR_BATCHES_MAX:-8}}"
MIXED_SCALAR_STRING_BATCHES_MAX="${GBS_MATERIALIZATION_MIXED_SCALAR_STRING_BATCHES_MAX:-${MATERIALIZATION_MIXED_SCALAR_STRING_BATCHES_MAX:-8}}"
MIXED_SCALAR_BYTE_ARRAY_BATCHES_MAX="${GBS_MATERIALIZATION_MIXED_SCALAR_BYTE_ARRAY_BATCHES_MAX:-${MATERIALIZATION_MIXED_SCALAR_BYTE_ARRAY_BATCHES_MAX:-8}}"
SHALLOW_STRUCTURED_BYTE_FALLBACKS_MAX="${GBS_MATERIALIZATION_SHALLOW_STRUCTURED_BYTE_FALLBACKS_MAX:-${MATERIALIZATION_SHALLOW_STRUCTURED_BYTE_FALLBACKS_MAX:-0}}"
MIXED_STRUCTURED_BYTE_FALLBACKS_MAX="${GBS_MATERIALIZATION_MIXED_STRUCTURED_BYTE_FALLBACKS_MAX:-${MATERIALIZATION_MIXED_STRUCTURED_BYTE_FALLBACKS_MAX:-0}}"
SHALLOW_STRUCTURED_BYTE_FETCHES_MAX="${GBS_MATERIALIZATION_SHALLOW_STRUCTURED_BYTE_FETCHES_MAX:-${MATERIALIZATION_SHALLOW_STRUCTURED_BYTE_FETCHES_MAX:-0}}"
MIXED_STRUCTURED_BYTE_FETCHES_MAX="${GBS_MATERIALIZATION_MIXED_STRUCTURED_BYTE_FETCHES_MAX:-${MATERIALIZATION_MIXED_STRUCTURED_BYTE_FETCHES_MAX:-0}}"
SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX="${GBS_MATERIALIZATION_SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX:-${MATERIALIZATION_SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX:-0}}"
MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX="${GBS_MATERIALIZATION_MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX:-${MATERIALIZATION_MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX:-0}}"
SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN="${GBS_MATERIALIZATION_SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN:-${MATERIALIZATION_SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN:-1}}"
MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN="${GBS_MATERIALIZATION_MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN:-${MATERIALIZATION_MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN:-1}}"
SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX="${GBS_MATERIALIZATION_SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX:-${MATERIALIZATION_SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX:-4}}"
MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX="${GBS_MATERIALIZATION_MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX:-${MATERIALIZATION_MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX:-60}}"
SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX="${GBS_MATERIALIZATION_SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX:-${MATERIALIZATION_SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX:-800}}"
MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX="${GBS_MATERIALIZATION_MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX:-${MATERIALIZATION_MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX:-6000}}"
BUSINESS_STRUCTURED_BYTE_FALLBACKS_MAX="${GBS_MATERIALIZATION_BUSINESS_STRUCTURED_BYTE_FALLBACKS_MAX:-${MATERIALIZATION_BUSINESS_STRUCTURED_BYTE_FALLBACKS_MAX:-0}}"
BUSINESS_STRUCTURED_BYTE_FETCHES_MAX="${GBS_MATERIALIZATION_BUSINESS_STRUCTURED_BYTE_FETCHES_MAX:-${MATERIALIZATION_BUSINESS_STRUCTURED_BYTE_FETCHES_MAX:-0}}"
BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX="${GBS_MATERIALIZATION_BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX:-${MATERIALIZATION_BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX:-0}}"
BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN="${GBS_MATERIALIZATION_BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN:-${MATERIALIZATION_BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN:-1}}"
BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX="${GBS_MATERIALIZATION_BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX:-${MATERIALIZATION_BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX:-40}}"
BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX="${GBS_MATERIALIZATION_BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX:-${MATERIALIZATION_BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX:-4000}}"
CLAMPED_GCI_TRAVERSAL_FETCHES_MIN="${GBS_MATERIALIZATION_CLAMPED_GCI_TRAVERSAL_FETCHES_MIN:-${MATERIALIZATION_CLAMPED_GCI_TRAVERSAL_FETCHES_MIN:-1}}"
CLAMPED_GCI_TRAVERSAL_FETCHES_MAX="${GBS_MATERIALIZATION_CLAMPED_GCI_TRAVERSAL_FETCHES_MAX:-${MATERIALIZATION_CLAMPED_GCI_TRAVERSAL_FETCHES_MAX:-2}}"
CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN="${GBS_MATERIALIZATION_CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN:-${MATERIALIZATION_CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN:-1}}"
CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX="${GBS_MATERIALIZATION_CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX:-${MATERIALIZATION_CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX:-2}}"
CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX="${GBS_MATERIALIZATION_CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX:-${MATERIALIZATION_CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX:-4}}"
CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS_MAX="${GBS_MATERIALIZATION_CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS_MAX:-${MATERIALIZATION_CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS_MAX:-0}}"
CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS_MAX="${GBS_MATERIALIZATION_CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS_MAX:-${MATERIALIZATION_CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS_MAX:-0}}"
TREND_REGRESSION_PERCENT="${GBS_MATERIALIZATION_PERF_REGRESSION_PERCENT:-35}"
TREND_REGRESSION_MIN_DELTA_MS="${GBS_MATERIALIZATION_PERF_REGRESSION_MIN_DELTA_MS:-50}"

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
  local mixed_ms="${18:-0}"
  local mixed_size="${19:-0}"
  local mixed_collection_array_batches="${20:-0}"
  local mixed_dictionary_pair_batches="${21:-0}"
  local mixed_scalar_string_batches="${22:-0}"
  local mixed_scalar_byte_array_batches="${23:-0}"
  local json_payload=""
  local markdown_payload=""
  echo "MATERIALIZATION_PERF_SUMMARY result=${result} code=${code} array_ms=${array_ms} dictionary_ms=${dictionary_ms} shallow_ms=${shallow_ms} mixed_ms=${mixed_ms} business_ms=${BUSINESS_MS:-0} clamped_ms=${CLAMPED_MS:-0} array_size=${array_size} dictionary_size=${dictionary_size} shallow_size=${shallow_size} mixed_size=${mixed_size} business_size=${BUSINESS_SIZE:-0} shallow_root_ms=${shallow_root_ms} shallow_slot_ms=${shallow_slot_ms} shallow_class_name_batch_ms=${shallow_class_name_batch_ms} shallow_proxy_ms=${shallow_proxy_ms} shallow_wrapper_ms=${shallow_wrapper_ms} shallow_slot_batches=${shallow_slot_batches} shallow_class_name_batches=${shallow_class_name_batches} shallow_proxy_creations=${shallow_proxy_creations} shallow_wrapper_lookups=${shallow_wrapper_lookups} mixed_collection_array_batches=${mixed_collection_array_batches} mixed_dictionary_pair_batches=${mixed_dictionary_pair_batches} mixed_scalar_string_batches=${mixed_scalar_string_batches} mixed_scalar_byte_array_batches=${mixed_scalar_byte_array_batches} array_max_ms=${ARRAY_MAX_MS} dictionary_max_ms=${DICTIONARY_MAX_MS} shallow_max_ms=${SHALLOW_MAX_MS} mixed_max_ms=${MIXED_MAX_MS} business_max_ms=${BUSINESS_MAX_MS} clamped_max_ms=${CLAMPED_MAX_MS} shallow_wrapper_max_ms=${SHALLOW_WRAPPER_MAX_MS} threshold_file=${THRESHOLD_FILE} work_image=${WORK_IMAGE}"
  echo "MATERIALIZATION_PERF_TRANSPORT_SUMMARY shallow_structured_byte_fetches=${SHALLOW_STRUCTURED_BYTE_FETCHES:-0} shallow_structured_byte_fetches_max=${SHALLOW_STRUCTURED_BYTE_FETCHES_MAX} shallow_structured_traversal_byte_fetches=${SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES:-0} shallow_structured_traversal_byte_fetches_max=${SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX} shallow_structured_traversal_buffer_fetches=${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES:-0} shallow_structured_traversal_buffer_fetches_min=${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN} shallow_structured_traversal_buffer_fetches_max=${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX} shallow_structured_traversal_buffer_reports=${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS:-0} shallow_structured_traversal_buffer_reports_max=${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX} shallow_structured_byte_fallbacks=${SHALLOW_STRUCTURED_BYTE_FALLBACKS:-0} shallow_structured_byte_fallbacks_max=${SHALLOW_STRUCTURED_BYTE_FALLBACKS_MAX} mixed_structured_byte_fetches=${MIXED_STRUCTURED_BYTE_FETCHES:-0} mixed_structured_byte_fetches_max=${MIXED_STRUCTURED_BYTE_FETCHES_MAX} mixed_structured_traversal_byte_fetches=${MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES:-0} mixed_structured_traversal_byte_fetches_max=${MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX} mixed_structured_traversal_buffer_fetches=${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES:-0} mixed_structured_traversal_buffer_fetches_min=${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN} mixed_structured_traversal_buffer_fetches_max=${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX} mixed_structured_traversal_buffer_reports=${MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS:-0} mixed_structured_traversal_buffer_reports_max=${MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX} mixed_structured_byte_fallbacks=${MIXED_STRUCTURED_BYTE_FALLBACKS:-0} mixed_structured_byte_fallbacks_max=${MIXED_STRUCTURED_BYTE_FALLBACKS_MAX}"
  echo "MATERIALIZATION_PERF_BUSINESS_SUMMARY business_ms=${BUSINESS_MS:-0} business_size=${BUSINESS_SIZE:-0} business_max_ms=${BUSINESS_MAX_MS} business_collection_array_batches=${BUSINESS_COLLECTION_ARRAY_BATCHES:-0} business_dictionary_pair_batches=${BUSINESS_DICTIONARY_PAIR_BATCHES:-0} business_scalar_string_batches=${BUSINESS_SCALAR_STRING_BATCHES:-0} business_scalar_byte_array_batches=${BUSINESS_SCALAR_BYTE_ARRAY_BATCHES:-0} business_wrapper_fast_connector_hits=${BUSINESS_WRAPPER_FAST_CONNECTOR_HITS:-0} business_structured_byte_fetches=${BUSINESS_STRUCTURED_BYTE_FETCHES:-0} business_structured_byte_fetches_max=${BUSINESS_STRUCTURED_BYTE_FETCHES_MAX} business_structured_traversal_byte_fetches=${BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES:-0} business_structured_traversal_byte_fetches_max=${BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX} business_structured_traversal_buffer_fetches=${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES:-0} business_structured_traversal_buffer_fetches_min=${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN} business_structured_traversal_buffer_fetches_max=${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX} business_structured_traversal_buffer_reports=${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS:-0} business_structured_traversal_buffer_reports_max=${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX} business_structured_byte_fallbacks=${BUSINESS_STRUCTURED_BYTE_FALLBACKS:-0} business_structured_byte_fallbacks_max=${BUSINESS_STRUCTURED_BYTE_FALLBACKS_MAX}"
  echo "MATERIALIZATION_PERF_CLAMPED_SUMMARY clamped_ms=${CLAMPED_MS:-0} clamped_max_ms=${CLAMPED_MAX_MS} clamped_gci_traversal_fetches=${CLAMPED_GCI_TRAVERSAL_FETCHES:-0} clamped_gci_traversal_fetches_min=${CLAMPED_GCI_TRAVERSAL_FETCHES_MIN} clamped_gci_traversal_fetches_max=${CLAMPED_GCI_TRAVERSAL_FETCHES_MAX} clamped_structured_traversal_buffer_fetches=${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES:-0} clamped_structured_traversal_buffer_fetches_min=${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN} clamped_structured_traversal_buffer_fetches_max=${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX} clamped_structured_traversal_buffer_reports=${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS:-0} clamped_structured_traversal_buffer_reports_max=${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX} clamped_structured_traversal_buffer_fallbacks=${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS:-0} clamped_structured_traversal_buffer_fallbacks_max=${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS_MAX} clamped_association_pair_traversal_fallbacks=${CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS:-0} clamped_association_pair_traversal_fallbacks_max=${CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS_MAX}"
  printf -v json_payload '{"result":"%s","code":"%s","array_ms":"%s","dictionary_ms":"%s","shallow_ms":"%s","mixed_ms":"%s","business_ms":"%s","array_size":"%s","dictionary_size":"%s","shallow_size":"%s","mixed_size":"%s","business_size":"%s","shallow_root_ms":"%s","shallow_slot_ms":"%s","shallow_class_name_batch_ms":"%s","shallow_proxy_ms":"%s","shallow_wrapper_ms":"%s","shallow_slot_batches":"%s","shallow_class_name_batches":"%s","shallow_proxy_creations":"%s","shallow_wrapper_lookups":"%s","mixed_collection_array_batches":"%s","mixed_dictionary_pair_batches":"%s","mixed_scalar_string_batches":"%s","mixed_scalar_byte_array_batches":"%s","business_collection_array_batches":"%s","business_dictionary_pair_batches":"%s","business_scalar_string_batches":"%s","business_scalar_byte_array_batches":"%s","business_wrapper_fast_connector_hits":"%s","business_structured_traversal_buffer_fetches":"%s","business_structured_traversal_buffer_reports":"%s","business_structured_byte_fallbacks":"%s","array_max_ms":"%s","dictionary_max_ms":"%s","shallow_max_ms":"%s","mixed_max_ms":"%s","business_max_ms":"%s","shallow_wrapper_max_ms":"%s","threshold_file":"%s","work_image":"%s"}' \
    "$(gbs_json_escape "${result}")" \
    "$(gbs_json_escape "${code}")" \
    "$(gbs_json_escape "${array_ms}")" \
    "$(gbs_json_escape "${dictionary_ms}")" \
    "$(gbs_json_escape "${shallow_ms}")" \
    "$(gbs_json_escape "${mixed_ms}")" \
    "$(gbs_json_escape "${BUSINESS_MS:-0}")" \
    "$(gbs_json_escape "${array_size}")" \
    "$(gbs_json_escape "${dictionary_size}")" \
    "$(gbs_json_escape "${shallow_size}")" \
    "$(gbs_json_escape "${mixed_size}")" \
    "$(gbs_json_escape "${BUSINESS_SIZE:-0}")" \
    "$(gbs_json_escape "${shallow_root_ms}")" \
    "$(gbs_json_escape "${shallow_slot_ms}")" \
    "$(gbs_json_escape "${shallow_class_name_batch_ms}")" \
    "$(gbs_json_escape "${shallow_proxy_ms}")" \
    "$(gbs_json_escape "${shallow_wrapper_ms}")" \
    "$(gbs_json_escape "${shallow_slot_batches}")" \
    "$(gbs_json_escape "${shallow_class_name_batches}")" \
    "$(gbs_json_escape "${shallow_proxy_creations}")" \
    "$(gbs_json_escape "${shallow_wrapper_lookups}")" \
    "$(gbs_json_escape "${mixed_collection_array_batches}")" \
    "$(gbs_json_escape "${mixed_dictionary_pair_batches}")" \
    "$(gbs_json_escape "${mixed_scalar_string_batches}")" \
    "$(gbs_json_escape "${mixed_scalar_byte_array_batches}")" \
    "$(gbs_json_escape "${BUSINESS_COLLECTION_ARRAY_BATCHES:-0}")" \
    "$(gbs_json_escape "${BUSINESS_DICTIONARY_PAIR_BATCHES:-0}")" \
    "$(gbs_json_escape "${BUSINESS_SCALAR_STRING_BATCHES:-0}")" \
    "$(gbs_json_escape "${BUSINESS_SCALAR_BYTE_ARRAY_BATCHES:-0}")" \
    "$(gbs_json_escape "${BUSINESS_WRAPPER_FAST_CONNECTOR_HITS:-0}")" \
    "$(gbs_json_escape "${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES:-0}")" \
    "$(gbs_json_escape "${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS:-0}")" \
    "$(gbs_json_escape "${BUSINESS_STRUCTURED_BYTE_FALLBACKS:-0}")" \
    "$(gbs_json_escape "${ARRAY_MAX_MS}")" \
    "$(gbs_json_escape "${DICTIONARY_MAX_MS}")" \
    "$(gbs_json_escape "${SHALLOW_MAX_MS}")" \
    "$(gbs_json_escape "${MIXED_MAX_MS}")" \
    "$(gbs_json_escape "${BUSINESS_MAX_MS}")" \
    "$(gbs_json_escape "${SHALLOW_WRAPPER_MAX_MS}")" \
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
    "- mixed graph fetch: \`${mixed_ms} ms\` for \`${mixed_size}\` repeated nested entries" \
    "- business graph fetch: \`${BUSINESS_MS:-0} ms\` for \`${BUSINESS_SIZE:-0}\` domain entries" \
    "- shallow submetrics: root \`${shallow_root_ms} ms\`, slots \`${shallow_slot_ms} ms\`, class-name batch \`${shallow_class_name_batch_ms} ms\`, proxy construction \`${shallow_proxy_ms} ms\`, wrapper lookup \`${shallow_wrapper_ms} ms\`" \
    "- shallow call counts: slot batches \`${shallow_slot_batches}\`, class-name batches \`${shallow_class_name_batches}\`, proxy creations \`${shallow_proxy_creations}\`, wrapper lookups \`${shallow_wrapper_lookups}\`" \
    "- mixed call counts: collection-array batches \`${mixed_collection_array_batches}\`, dictionary-pair batches \`${mixed_dictionary_pair_batches}\`, string batches \`${mixed_scalar_string_batches}\`, byte-array batches \`${mixed_scalar_byte_array_batches}\`" \
    "- business call counts: collection-array batches \`${BUSINESS_COLLECTION_ARRAY_BATCHES:-0}\`, dictionary-pair batches \`${BUSINESS_DICTIONARY_PAIR_BATCHES:-0}\`, string batches \`${BUSINESS_SCALAR_STRING_BATCHES:-0}\`, byte-array batches \`${BUSINESS_SCALAR_BYTE_ARRAY_BATCHES:-0}\`, fast-wrapper hits \`${BUSINESS_WRAPPER_FAST_CONNECTOR_HITS:-0}\`" \
    "- thresholds: array \`${ARRAY_MAX_MS} ms\`, dictionary \`${DICTIONARY_MAX_MS} ms\`, shallow \`${SHALLOW_MAX_MS} ms\`, mixed \`${MIXED_MAX_MS} ms\`, business \`${BUSINESS_MAX_MS} ms\`, shallow wrapper lookup \`${SHALLOW_WRAPPER_MAX_MS} ms\`" \
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
  gbs_append_summary_line "- mixed graph fetch: \`${mixed_ms} ms\` for \`${mixed_size}\` repeated nested entries"
  gbs_append_summary_line "- business graph fetch: \`${BUSINESS_MS:-0} ms\` for \`${BUSINESS_SIZE:-0}\` domain entries"
  gbs_append_summary_line "- shallow submetrics: root \`${shallow_root_ms} ms\`, slots \`${shallow_slot_ms} ms\`, class-name batch \`${shallow_class_name_batch_ms} ms\`, proxy construction \`${shallow_proxy_ms} ms\`, wrapper lookup \`${shallow_wrapper_ms} ms\`"
  gbs_append_summary_line "- shallow call counts: slot batches \`${shallow_slot_batches}\`, class-name batches \`${shallow_class_name_batches}\`, proxy creations \`${shallow_proxy_creations}\`, wrapper lookups \`${shallow_wrapper_lookups}\`"
  gbs_append_summary_line "- mixed call counts: collection-array batches \`${mixed_collection_array_batches}\`, dictionary-pair batches \`${mixed_dictionary_pair_batches}\`, string batches \`${mixed_scalar_string_batches}\`, byte-array batches \`${mixed_scalar_byte_array_batches}\`"
  gbs_append_summary_line "- business call counts: collection-array batches \`${BUSINESS_COLLECTION_ARRAY_BATCHES:-0}\`, dictionary-pair batches \`${BUSINESS_DICTIONARY_PAIR_BATCHES:-0}\`, string batches \`${BUSINESS_SCALAR_STRING_BATCHES:-0}\`, byte-array batches \`${BUSINESS_SCALAR_BYTE_ARRAY_BATCHES:-0}\`, fast-wrapper hits \`${BUSINESS_WRAPPER_FAST_CONNECTOR_HITS:-0}\`"
  gbs_append_summary_line "- thresholds: array \`${ARRAY_MAX_MS} ms\`, dictionary \`${DICTIONARY_MAX_MS} ms\`, shallow \`${SHALLOW_MAX_MS} ms\`, mixed \`${MIXED_MAX_MS} ms\`, business \`${BUSINESS_MAX_MS} ms\`, shallow wrapper lookup \`${SHALLOW_WRAPPER_MAX_MS} ms\`"
  gbs_append_summary_line "- threshold file: \`${THRESHOLD_FILE}\`"
}

print_materialization_live_excerpt() {
  local output="$1"
  if [[ "${GBS_VERBOSE_LIVE_OUTPUT:-0}" == "1" ]]; then
    printf '%s\n' "${output}"
    return 0
  fi
  printf '%s\n' "${output}" | grep -E '^(Using work image:|LIVE_PREFLIGHT_(BEGIN|SUMMARY|OK|FAIL|SKIP|STONE_OK|NETLDI_OK|TOPAZ_LOGIN_OK|GCI_LOGIN_OK|MISSING_ENV)|PROBE_(CONFIG|LOGIN_OK|EVAL_RESULT)|MATERIALIZATION_PERF_(BASELINE|SUMMARY|TRANSPORT_SUMMARY|BUSINESS_SUMMARY|CLAMPED_SUMMARY|BASELINE_OK))' || true
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
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_${label}_METRIC" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance metric ${label} is not a non-negative integer: ${value}" >&2
    exit 1
  fi
  if [[ ! "${max}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_${label}_THRESHOLD" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance threshold ${label} is not a non-negative integer: ${max}" >&2
    exit 1
  fi
  if (( value > max )); then
    emit_summary "FAIL" "MATERIALIZATION_PERF_${label}_THRESHOLD_EXCEEDED" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance metric ${label}=${value}ms exceeded threshold ${max}ms." >&2
    exit 1
  fi
}

check_count_threshold() {
  local label="$1"
  local value="$2"
  local max="$3"
  if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_${label}_COUNT" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance count ${label} is not a non-negative integer: ${value}" >&2
    exit 1
  fi
  if [[ ! "${max}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_${label}_COUNT_THRESHOLD" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance count threshold ${label} is not a non-negative integer: ${max}" >&2
    exit 1
  fi
  if (( value > max )); then
    emit_summary "FAIL" "MATERIALIZATION_PERF_${label}_COUNT_THRESHOLD_EXCEEDED" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance count ${label}=${value} exceeded threshold ${max}." >&2
    exit 1
  fi
}

check_count_floor() {
  local label="$1"
  local value="$2"
  local min="$3"
  if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_${label}_COUNT" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance count ${label} is not a non-negative integer: ${value}" >&2
    exit 1
  fi
  if [[ ! "${min}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_${label}_COUNT_THRESHOLD" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance count threshold ${label} is not a non-negative integer: ${min}" >&2
    exit 1
  fi
  if (( value < min )); then
    emit_summary "FAIL" "MATERIALIZATION_PERF_${label}_COUNT_BELOW_THRESHOLD" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance count ${label}=${value} was below required threshold ${min}." >&2
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

check_trend_metric() {
  local label="$1"
  local current="$2"
  local previous="$3"
  local percent_allowed absolute_allowed allowed
  [[ "${previous}" =~ ^[0-9]+$ ]] || return 0
  [[ "${current}" =~ ^[0-9]+$ ]] || return 0
  (( previous > 0 )) || return 0
  if [[ ! "${TREND_REGRESSION_PERCENT}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_TREND_PERCENT" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance trend percent is not a non-negative integer: ${TREND_REGRESSION_PERCENT}" >&2
    exit 1
  fi
  if [[ ! "${TREND_REGRESSION_MIN_DELTA_MS}" =~ ^[0-9]+$ ]]; then
    emit_summary "FAIL" "MATERIALIZATION_PERF_BAD_TREND_MIN_DELTA" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance minimum trend delta is not a non-negative integer: ${TREND_REGRESSION_MIN_DELTA_MS}" >&2
    exit 1
  fi
  percent_allowed=$(( previous + (previous * TREND_REGRESSION_PERCENT / 100) ))
  absolute_allowed=$(( previous + TREND_REGRESSION_MIN_DELTA_MS ))
  allowed="${percent_allowed}"
  if (( absolute_allowed > allowed )); then
    allowed="${absolute_allowed}"
  fi
  if (( current > allowed )); then
    emit_summary "FAIL" "MATERIALIZATION_PERF_${label}_TREND_REGRESSION" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS:-0}" "${SHALLOW_SLOT_MS:-0}" "${SHALLOW_CLASS_NAME_BATCH_MS:-0}" "${SHALLOW_PROXY_MS:-0}" "${SHALLOW_WRAPPER_MS:-0}" "${SHALLOW_SLOT_BATCHES:-0}" "${SHALLOW_CLASS_NAME_BATCHES:-0}" "${SHALLOW_PROXY_CREATIONS:-0}" "${SHALLOW_WRAPPER_LOOKUPS:-0}" "${MIXED_MS:-0}" "${MIXED_SIZE:-0}" "${MIXED_COLLECTION_ARRAY_BATCHES:-0}" "${MIXED_DICTIONARY_PAIR_BATCHES:-0}" "${MIXED_SCALAR_STRING_BATCHES:-0}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
    echo "Materialization performance trend regression ${label}: current=${current}ms previous=${previous}ms allowed=${allowed}ms (${TREND_REGRESSION_PERCENT}% or +${TREND_REGRESSION_MIN_DELTA_MS}ms)." >&2
    exit 1
  fi
}

check_trend_regression() {
  local trend_file previous_line
  local previous_array previous_dictionary previous_shallow previous_mixed previous_business previous_root previous_slot previous_class_name previous_proxy previous_wrapper
  trend_file="$(trend_file_path)"
  [[ -n "${trend_file}" && -f "${trend_file}" ]] || return 0
  previous_line="$(grep -v '^[[:space:]]*$' "${trend_file}" | tail -1 || true)"
  [[ -n "${previous_line}" ]] || return 0
  previous_array="$(json_line_number_field "${previous_line}" array_ms)"
  previous_dictionary="$(json_line_number_field "${previous_line}" dictionary_ms)"
  previous_shallow="$(json_line_number_field "${previous_line}" shallow_ms)"
  previous_mixed="$(json_line_number_field "${previous_line}" mixed_ms)"
  previous_business="$(json_line_number_field "${previous_line}" business_ms)"
  previous_root="$(json_line_number_field "${previous_line}" shallow_root_ms)"
  previous_slot="$(json_line_number_field "${previous_line}" shallow_slot_ms)"
  previous_class_name="$(json_line_number_field "${previous_line}" shallow_class_name_batch_ms)"
  previous_proxy="$(json_line_number_field "${previous_line}" shallow_proxy_ms)"
  previous_wrapper="$(json_line_number_field "${previous_line}" shallow_wrapper_ms)"
  check_trend_metric "ARRAY" "${ARRAY_MS}" "${previous_array}"
  check_trend_metric "DICTIONARY" "${DICTIONARY_MS}" "${previous_dictionary}"
  check_trend_metric "SHALLOW" "${SHALLOW_MS}" "${previous_shallow}"
  check_trend_metric "MIXED" "${MIXED_MS}" "${previous_mixed}"
  check_trend_metric "BUSINESS" "${BUSINESS_MS}" "${previous_business}"
  check_trend_metric "SHALLOW_ROOT" "${SHALLOW_ROOT_MS}" "${previous_root}"
  check_trend_metric "SHALLOW_SLOT" "${SHALLOW_SLOT_MS}" "${previous_slot}"
  check_trend_metric "SHALLOW_CLASS_NAME_BATCH" "${SHALLOW_CLASS_NAME_BATCH_MS}" "${previous_class_name}"
  check_trend_metric "SHALLOW_PROXY" "${SHALLOW_PROXY_MS}" "${previous_proxy}"
  check_trend_metric "SHALLOW_WRAPPER" "${SHALLOW_WRAPPER_MS}" "${previous_wrapper}"
  gbs_append_summary_line "- trend comparison: previous sample from \`${trend_file}\`, threshold \`${TREND_REGRESSION_PERCENT}%\` or \`+${TREND_REGRESSION_MIN_DELTA_MS} ms\`, whichever is larger"
}

write_trend_sample() {
  local trend_file timestamp
  trend_file="$(trend_file_path)"
  [[ -n "${trend_file}" ]] || return 0
  mkdir -p "$(dirname "${trend_file}")"
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf '{"timestamp":"%s","array_ms":%s,"dictionary_ms":%s,"shallow_ms":%s,"mixed_ms":%s,"business_ms":%s,"shallow_root_ms":%s,"shallow_slot_ms":%s,"shallow_class_name_batch_ms":%s,"shallow_proxy_ms":%s,"shallow_wrapper_ms":%s,"shallow_slot_batches":%s,"shallow_class_name_batches":%s,"shallow_proxy_creations":%s,"shallow_wrapper_lookups":%s,"mixed_collection_array_batches":%s,"mixed_dictionary_pair_batches":%s,"mixed_scalar_string_batches":%s,"mixed_scalar_byte_array_batches":%s,"business_collection_array_batches":%s,"business_dictionary_pair_batches":%s,"business_scalar_string_batches":%s,"business_scalar_byte_array_batches":%s,"business_wrapper_fast_connector_hits":%s,"shallow_structured_byte_fetches":%s,"shallow_structured_traversal_byte_fetches":%s,"shallow_structured_traversal_buffer_fetches":%s,"shallow_structured_traversal_buffer_reports":%s,"shallow_structured_byte_fallbacks":%s,"mixed_structured_byte_fetches":%s,"mixed_structured_traversal_byte_fetches":%s,"mixed_structured_traversal_buffer_fetches":%s,"mixed_structured_traversal_buffer_reports":%s,"mixed_structured_byte_fallbacks":%s,"business_structured_byte_fetches":%s,"business_structured_traversal_byte_fetches":%s,"business_structured_traversal_buffer_fetches":%s,"business_structured_traversal_buffer_reports":%s,"business_structured_byte_fallbacks":%s,"array_max_ms":%s,"dictionary_max_ms":%s,"shallow_max_ms":%s,"mixed_max_ms":%s,"business_max_ms":%s}\n' \
    "${timestamp}" \
    "${ARRAY_MS}" \
    "${DICTIONARY_MS}" \
    "${SHALLOW_MS}" \
    "${MIXED_MS}" \
    "${BUSINESS_MS}" \
    "${SHALLOW_ROOT_MS}" \
    "${SHALLOW_SLOT_MS}" \
    "${SHALLOW_CLASS_NAME_BATCH_MS}" \
    "${SHALLOW_PROXY_MS}" \
    "${SHALLOW_WRAPPER_MS}" \
    "${SHALLOW_SLOT_BATCHES}" \
    "${SHALLOW_CLASS_NAME_BATCHES}" \
    "${SHALLOW_PROXY_CREATIONS}" \
    "${SHALLOW_WRAPPER_LOOKUPS}" \
    "${MIXED_COLLECTION_ARRAY_BATCHES}" \
    "${MIXED_DICTIONARY_PAIR_BATCHES}" \
    "${MIXED_SCALAR_STRING_BATCHES}" \
    "${MIXED_SCALAR_BYTE_ARRAY_BATCHES}" \
    "${BUSINESS_COLLECTION_ARRAY_BATCHES}" \
    "${BUSINESS_DICTIONARY_PAIR_BATCHES}" \
    "${BUSINESS_SCALAR_STRING_BATCHES}" \
    "${BUSINESS_SCALAR_BYTE_ARRAY_BATCHES}" \
    "${BUSINESS_WRAPPER_FAST_CONNECTOR_HITS}" \
    "${SHALLOW_STRUCTURED_BYTE_FETCHES}" \
    "${SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES}" \
    "${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}" \
    "${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS}" \
    "${SHALLOW_STRUCTURED_BYTE_FALLBACKS}" \
    "${MIXED_STRUCTURED_BYTE_FETCHES}" \
    "${MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES}" \
    "${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}" \
    "${MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS}" \
    "${MIXED_STRUCTURED_BYTE_FALLBACKS}" \
    "${BUSINESS_STRUCTURED_BYTE_FETCHES}" \
    "${BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES}" \
    "${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}" \
    "${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS}" \
    "${BUSINESS_STRUCTURED_BYTE_FALLBACKS}" \
    "${ARRAY_MAX_MS}" \
    "${DICTIONARY_MAX_MS}" \
    "${SHALLOW_MAX_MS}" \
    "${MIXED_MAX_MS}" \
    "${BUSINESS_MAX_MS}" >> "${trend_file}"
  gbs_append_summary_line "- trend sample: \`${trend_file}\`"
}

write_trend_report() {
  local trend_file report_file line timestamp array dictionary shallow mixed business root slot class_name proxy wrapper
  trend_file="$(trend_file_path)"
  [[ -n "${trend_file}" && -f "${trend_file}" ]] || return 0
  report_file="${GBS_MATERIALIZATION_PERF_REPORT:-$(dirname "${trend_file}")/materialization-performance-trend-report.md}"
  mkdir -p "$(dirname "${report_file}")"
  {
    printf '# Materialization Performance Trend\n\n'
    printf 'Regression threshold: `%s%%` over the previous sample or `+%s ms`, whichever is larger.\n\n' "${TREND_REGRESSION_PERCENT}" "${TREND_REGRESSION_MIN_DELTA_MS}"
    printf '| Timestamp | Array | Dictionary | Shallow | Mixed | Business | Root | Slots | Class Names | Proxy | Wrapper |\n'
    printf '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n'
    grep -v '^[[:space:]]*$' "${trend_file}" | tail -20 | while IFS= read -r line; do
      timestamp="$(json_line_string_field "${line}" timestamp)"
      array="$(json_line_number_field "${line}" array_ms)"
      dictionary="$(json_line_number_field "${line}" dictionary_ms)"
      shallow="$(json_line_number_field "${line}" shallow_ms)"
      mixed="$(json_line_number_field "${line}" mixed_ms)"
      business="$(json_line_number_field "${line}" business_ms)"
      root="$(json_line_number_field "${line}" shallow_root_ms)"
      slot="$(json_line_number_field "${line}" shallow_slot_ms)"
      class_name="$(json_line_number_field "${line}" shallow_class_name_batch_ms)"
      proxy="$(json_line_number_field "${line}" shallow_proxy_ms)"
      wrapper="$(json_line_number_field "${line}" shallow_wrapper_ms)"
      printf '| %s | %s ms | %s ms | %s ms | %s ms | %s ms | %s ms | %s ms | %s ms | %s ms | %s ms |\n' \
        "${timestamp:-unknown}" \
        "${array:-0}" \
        "${dictionary:-0}" \
        "${shallow:-0}" \
        "${mixed:-0}" \
        "${business:-0}" \
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
print_materialization_live_excerpt "${preflight_output}"
gbs_write_evidence_file "materialization-performance-preflight.log" "${preflight_output}"
if ! grep -q "LIVE_PREFLIGHT_SUMMARY result=OK code=LIVE_PREFLIGHT_OK" <<< "${preflight_output}"; then
  emit_summary "FAIL" "MATERIALIZATION_PERF_PREFLIGHT_FAILED"
  echo "Live preflight failed or skipped; refusing to benchmark materialization against an unknown GemStone session." >&2
  exit 1
fi

perf_output="$(HOME=/tmp/pharo-clean-auto/home GBS_WORK_IMAGE="${WORK_IMAGE}" "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/run_materialization_performance_baseline.st" 2>&1 || true)"
print_materialization_live_excerpt "${perf_output}"
gbs_write_evidence_file "materialization-performance-baseline.log" "${perf_output}"

summary_line="$(printf '%s\n' "${perf_output}" | grep 'MATERIALIZATION_PERF_BASELINE result=' | tail -1 || true)"
if [[ -z "${summary_line}" ]]; then
  emit_summary "FAIL" "MATERIALIZATION_PERF_RUNNER_FAILED"
  [[ "${GBS_VERBOSE_LIVE_OUTPUT:-0}" == "1" ]] || printf '%s\n' "${perf_output}" >&2
  echo "Materialization performance runner did not emit MATERIALIZATION_PERF_BASELINE." >&2
  exit 1
fi

RESULT="$(extract_summary_field "${summary_line}" result)"
CODE="$(extract_summary_field "${summary_line}" code)"
ARRAY_MS="$(extract_summary_field "${summary_line}" array_ms)"
DICTIONARY_MS="$(extract_summary_field "${summary_line}" dictionary_ms)"
SHALLOW_MS="$(extract_summary_field "${summary_line}" shallow_ms)"
MIXED_MS="$(extract_summary_field "${summary_line}" mixed_ms)"
BUSINESS_MS="$(extract_summary_field "${summary_line}" business_ms)"
CLAMPED_MS="$(extract_summary_field "${summary_line}" clamped_ms)"
ARRAY_SIZE="$(extract_summary_field "${summary_line}" array_size)"
DICTIONARY_SIZE="$(extract_summary_field "${summary_line}" dictionary_size)"
SHALLOW_SIZE="$(extract_summary_field "${summary_line}" shallow_size)"
MIXED_SIZE="$(extract_summary_field "${summary_line}" mixed_size)"
BUSINESS_SIZE="$(extract_summary_field "${summary_line}" business_size)"
SHALLOW_ROOT_MS="$(extract_summary_field "${summary_line}" shallow_root_ms)"
SHALLOW_SLOT_MS="$(extract_summary_field "${summary_line}" shallow_slot_ms)"
SHALLOW_CLASS_NAME_BATCH_MS="$(extract_summary_field "${summary_line}" shallow_class_name_batch_ms)"
SHALLOW_PROXY_MS="$(extract_summary_field "${summary_line}" shallow_proxy_ms)"
SHALLOW_WRAPPER_MS="$(extract_summary_field "${summary_line}" shallow_wrapper_ms)"
SHALLOW_SLOT_BATCHES="$(extract_summary_field "${summary_line}" shallow_slot_batches)"
SHALLOW_CLASS_NAME_BATCHES="$(extract_summary_field "${summary_line}" shallow_class_name_batches)"
SHALLOW_PROXY_CREATIONS="$(extract_summary_field "${summary_line}" shallow_proxy_creations)"
SHALLOW_WRAPPER_LOOKUPS="$(extract_summary_field "${summary_line}" shallow_wrapper_lookups)"
SHALLOW_WRAPPER_CACHE_HITS="$(extract_summary_field "${summary_line}" shallow_wrapper_cache_hits)"
SHALLOW_WRAPPER_LOOKUP_MISSES="$(extract_summary_field "${summary_line}" shallow_wrapper_lookup_misses)"
SHALLOW_WRAPPER_FAST_CONNECTOR_HITS="$(extract_summary_field "${summary_line}" shallow_wrapper_fast_connector_hits)"
SHALLOW_WRAPPER_TYPED_RESULTS="$(extract_summary_field "${summary_line}" shallow_wrapper_typed_results)"
SHALLOW_WRAPPER_NIL_RESULTS="$(extract_summary_field "${summary_line}" shallow_wrapper_nil_results)"
MIXED_COLLECTION_ARRAY_BATCHES="$(extract_summary_field "${summary_line}" mixed_collection_array_batches)"
MIXED_DICTIONARY_PAIR_BATCHES="$(extract_summary_field "${summary_line}" mixed_dictionary_pair_batches)"
MIXED_SCALAR_STRING_BATCHES="$(extract_summary_field "${summary_line}" mixed_scalar_string_batches)"
MIXED_SCALAR_BYTE_ARRAY_BATCHES="$(extract_summary_field "${summary_line}" mixed_scalar_byte_array_batches)"
MIXED_WRAPPER_CACHE_HITS="$(extract_summary_field "${summary_line}" mixed_wrapper_cache_hits)"
MIXED_WRAPPER_LOOKUP_MISSES="$(extract_summary_field "${summary_line}" mixed_wrapper_lookup_misses)"
MIXED_WRAPPER_FAST_CONNECTOR_HITS="$(extract_summary_field "${summary_line}" mixed_wrapper_fast_connector_hits)"
MIXED_WRAPPER_TYPED_RESULTS="$(extract_summary_field "${summary_line}" mixed_wrapper_typed_results)"
MIXED_WRAPPER_NIL_RESULTS="$(extract_summary_field "${summary_line}" mixed_wrapper_nil_results)"
SHALLOW_STRUCTURED_BYTE_FETCHES="$(extract_summary_field "${summary_line}" shallow_structured_byte_fetches)"
SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES="$(extract_summary_field "${summary_line}" shallow_structured_traversal_byte_fetches)"
SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES="$(extract_summary_field "${summary_line}" shallow_structured_traversal_buffer_fetches)"
SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS="$(extract_summary_field "${summary_line}" shallow_structured_traversal_buffer_reports)"
SHALLOW_STRUCTURED_BYTE_FALLBACKS="$(extract_summary_field "${summary_line}" shallow_structured_byte_fallbacks)"
MIXED_STRUCTURED_BYTE_FETCHES="$(extract_summary_field "${summary_line}" mixed_structured_byte_fetches)"
MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES="$(extract_summary_field "${summary_line}" mixed_structured_traversal_byte_fetches)"
MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES="$(extract_summary_field "${summary_line}" mixed_structured_traversal_buffer_fetches)"
MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS="$(extract_summary_field "${summary_line}" mixed_structured_traversal_buffer_reports)"
MIXED_STRUCTURED_BYTE_FALLBACKS="$(extract_summary_field "${summary_line}" mixed_structured_byte_fallbacks)"
BUSINESS_COLLECTION_ARRAY_BATCHES="$(extract_summary_field "${summary_line}" business_collection_array_batches)"
BUSINESS_DICTIONARY_PAIR_BATCHES="$(extract_summary_field "${summary_line}" business_dictionary_pair_batches)"
BUSINESS_SCALAR_STRING_BATCHES="$(extract_summary_field "${summary_line}" business_scalar_string_batches)"
BUSINESS_SCALAR_BYTE_ARRAY_BATCHES="$(extract_summary_field "${summary_line}" business_scalar_byte_array_batches)"
BUSINESS_WRAPPER_CACHE_HITS="$(extract_summary_field "${summary_line}" business_wrapper_cache_hits)"
BUSINESS_WRAPPER_LOOKUP_MISSES="$(extract_summary_field "${summary_line}" business_wrapper_lookup_misses)"
BUSINESS_WRAPPER_FAST_CONNECTOR_HITS="$(extract_summary_field "${summary_line}" business_wrapper_fast_connector_hits)"
BUSINESS_STRUCTURED_BYTE_FETCHES="$(extract_summary_field "${summary_line}" business_structured_byte_fetches)"
BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES="$(extract_summary_field "${summary_line}" business_structured_traversal_byte_fetches)"
BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES="$(extract_summary_field "${summary_line}" business_structured_traversal_buffer_fetches)"
BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS="$(extract_summary_field "${summary_line}" business_structured_traversal_buffer_reports)"
BUSINESS_STRUCTURED_BYTE_FALLBACKS="$(extract_summary_field "${summary_line}" business_structured_byte_fallbacks)"
CLAMPED_GCI_TRAVERSAL_FETCHES="$(extract_summary_field "${summary_line}" clamped_gci_traversal_fetches)"
CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES="$(extract_summary_field "${summary_line}" clamped_structured_traversal_buffer_fetches)"
CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS="$(extract_summary_field "${summary_line}" clamped_structured_traversal_buffer_reports)"
CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS="$(extract_summary_field "${summary_line}" clamped_structured_traversal_buffer_fallbacks)"
CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS="$(extract_summary_field "${summary_line}" clamped_association_pair_traversal_fallbacks)"

MIXED_MS="${MIXED_MS:-0}"
BUSINESS_MS="${BUSINESS_MS:-0}"
CLAMPED_MS="${CLAMPED_MS:-0}"
MIXED_SIZE="${MIXED_SIZE:-0}"
BUSINESS_SIZE="${BUSINESS_SIZE:-0}"
SHALLOW_ROOT_MS="${SHALLOW_ROOT_MS:-0}"
SHALLOW_SLOT_MS="${SHALLOW_SLOT_MS:-0}"
SHALLOW_CLASS_NAME_BATCH_MS="${SHALLOW_CLASS_NAME_BATCH_MS:-0}"
SHALLOW_PROXY_MS="${SHALLOW_PROXY_MS:-0}"
SHALLOW_WRAPPER_MS="${SHALLOW_WRAPPER_MS:-0}"
SHALLOW_SLOT_BATCHES="${SHALLOW_SLOT_BATCHES:-0}"
SHALLOW_CLASS_NAME_BATCHES="${SHALLOW_CLASS_NAME_BATCHES:-0}"
SHALLOW_PROXY_CREATIONS="${SHALLOW_PROXY_CREATIONS:-0}"
SHALLOW_WRAPPER_LOOKUPS="${SHALLOW_WRAPPER_LOOKUPS:-0}"
SHALLOW_WRAPPER_CACHE_HITS="${SHALLOW_WRAPPER_CACHE_HITS:-0}"
SHALLOW_WRAPPER_LOOKUP_MISSES="${SHALLOW_WRAPPER_LOOKUP_MISSES:-0}"
SHALLOW_WRAPPER_FAST_CONNECTOR_HITS="${SHALLOW_WRAPPER_FAST_CONNECTOR_HITS:-0}"
SHALLOW_WRAPPER_TYPED_RESULTS="${SHALLOW_WRAPPER_TYPED_RESULTS:-0}"
SHALLOW_WRAPPER_NIL_RESULTS="${SHALLOW_WRAPPER_NIL_RESULTS:-0}"
MIXED_COLLECTION_ARRAY_BATCHES="${MIXED_COLLECTION_ARRAY_BATCHES:-0}"
MIXED_DICTIONARY_PAIR_BATCHES="${MIXED_DICTIONARY_PAIR_BATCHES:-0}"
MIXED_SCALAR_STRING_BATCHES="${MIXED_SCALAR_STRING_BATCHES:-0}"
MIXED_SCALAR_BYTE_ARRAY_BATCHES="${MIXED_SCALAR_BYTE_ARRAY_BATCHES:-0}"
MIXED_WRAPPER_CACHE_HITS="${MIXED_WRAPPER_CACHE_HITS:-0}"
MIXED_WRAPPER_LOOKUP_MISSES="${MIXED_WRAPPER_LOOKUP_MISSES:-0}"
MIXED_WRAPPER_FAST_CONNECTOR_HITS="${MIXED_WRAPPER_FAST_CONNECTOR_HITS:-0}"
MIXED_WRAPPER_TYPED_RESULTS="${MIXED_WRAPPER_TYPED_RESULTS:-0}"
MIXED_WRAPPER_NIL_RESULTS="${MIXED_WRAPPER_NIL_RESULTS:-0}"
SHALLOW_STRUCTURED_BYTE_FETCHES="${SHALLOW_STRUCTURED_BYTE_FETCHES:-0}"
SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES="${SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES:-0}"
SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES="${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES:-0}"
SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS="${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS:-0}"
SHALLOW_STRUCTURED_BYTE_FALLBACKS="${SHALLOW_STRUCTURED_BYTE_FALLBACKS:-0}"
MIXED_STRUCTURED_BYTE_FETCHES="${MIXED_STRUCTURED_BYTE_FETCHES:-0}"
MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES="${MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES:-0}"
MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES="${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES:-0}"
MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS="${MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS:-0}"
MIXED_STRUCTURED_BYTE_FALLBACKS="${MIXED_STRUCTURED_BYTE_FALLBACKS:-0}"
BUSINESS_COLLECTION_ARRAY_BATCHES="${BUSINESS_COLLECTION_ARRAY_BATCHES:-0}"
BUSINESS_DICTIONARY_PAIR_BATCHES="${BUSINESS_DICTIONARY_PAIR_BATCHES:-0}"
BUSINESS_SCALAR_STRING_BATCHES="${BUSINESS_SCALAR_STRING_BATCHES:-0}"
BUSINESS_SCALAR_BYTE_ARRAY_BATCHES="${BUSINESS_SCALAR_BYTE_ARRAY_BATCHES:-0}"
BUSINESS_WRAPPER_CACHE_HITS="${BUSINESS_WRAPPER_CACHE_HITS:-0}"
BUSINESS_WRAPPER_LOOKUP_MISSES="${BUSINESS_WRAPPER_LOOKUP_MISSES:-0}"
BUSINESS_WRAPPER_FAST_CONNECTOR_HITS="${BUSINESS_WRAPPER_FAST_CONNECTOR_HITS:-0}"
BUSINESS_STRUCTURED_BYTE_FETCHES="${BUSINESS_STRUCTURED_BYTE_FETCHES:-0}"
BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES="${BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES:-0}"
BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES="${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES:-0}"
BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS="${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS:-0}"
BUSINESS_STRUCTURED_BYTE_FALLBACKS="${BUSINESS_STRUCTURED_BYTE_FALLBACKS:-0}"
CLAMPED_GCI_TRAVERSAL_FETCHES="${CLAMPED_GCI_TRAVERSAL_FETCHES:-0}"
CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES="${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES:-0}"
CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS="${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS:-0}"
CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS="${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS:-0}"
CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS="${CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS:-0}"

if [[ "${RESULT}" == "OK" && "${CODE}" == "MATERIALIZATION_PERF_OK" ]]; then
  check_latency_threshold "ARRAY" "${ARRAY_MS}" "${ARRAY_MAX_MS}"
  check_latency_threshold "DICTIONARY" "${DICTIONARY_MS}" "${DICTIONARY_MAX_MS}"
  check_latency_threshold "SHALLOW" "${SHALLOW_MS}" "${SHALLOW_MAX_MS}"
  check_latency_threshold "MIXED" "${MIXED_MS}" "${MIXED_MAX_MS}"
  check_latency_threshold "BUSINESS" "${BUSINESS_MS}" "${BUSINESS_MAX_MS}"
  check_latency_threshold "CLAMPED" "${CLAMPED_MS}" "${CLAMPED_MAX_MS}"
  check_latency_threshold "SHALLOW_WRAPPER" "${SHALLOW_WRAPPER_MS}" "${SHALLOW_WRAPPER_MAX_MS}"
  check_count_threshold "SHALLOW_WRAPPER_LOOKUP_MISSES" "${SHALLOW_WRAPPER_LOOKUP_MISSES}" "${SHALLOW_WRAPPER_LOOKUP_MISSES_MAX}"
  check_count_threshold "MIXED_WRAPPER_LOOKUP_MISSES" "${MIXED_WRAPPER_LOOKUP_MISSES}" "${MIXED_WRAPPER_LOOKUP_MISSES_MAX}"
  check_count_threshold "BUSINESS_WRAPPER_LOOKUP_MISSES" "${BUSINESS_WRAPPER_LOOKUP_MISSES}" "${BUSINESS_WRAPPER_LOOKUP_MISSES_MAX}"
  check_count_threshold "SHALLOW_SLOT_BATCHES" "${SHALLOW_SLOT_BATCHES}" "${SHALLOW_SLOT_BATCHES_MAX}"
  check_count_threshold "SHALLOW_CLASS_NAME_BATCHES" "${SHALLOW_CLASS_NAME_BATCHES}" "${SHALLOW_CLASS_NAME_BATCHES_MAX}"
  check_count_threshold "MIXED_COLLECTION_ARRAY_BATCHES" "${MIXED_COLLECTION_ARRAY_BATCHES}" "${MIXED_COLLECTION_ARRAY_BATCHES_MAX}"
  check_count_threshold "MIXED_DICTIONARY_PAIR_BATCHES" "${MIXED_DICTIONARY_PAIR_BATCHES}" "${MIXED_DICTIONARY_PAIR_BATCHES_MAX}"
  check_count_threshold "MIXED_SCALAR_STRING_BATCHES" "${MIXED_SCALAR_STRING_BATCHES}" "${MIXED_SCALAR_STRING_BATCHES_MAX}"
  check_count_threshold "MIXED_SCALAR_BYTE_ARRAY_BATCHES" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES_MAX}"
  check_count_threshold "SHALLOW_STRUCTURED_BYTE_FALLBACKS" "${SHALLOW_STRUCTURED_BYTE_FALLBACKS}" "${SHALLOW_STRUCTURED_BYTE_FALLBACKS_MAX}"
  check_count_threshold "MIXED_STRUCTURED_BYTE_FALLBACKS" "${MIXED_STRUCTURED_BYTE_FALLBACKS}" "${MIXED_STRUCTURED_BYTE_FALLBACKS_MAX}"
  check_count_threshold "SHALLOW_STRUCTURED_BYTE_FETCHES" "${SHALLOW_STRUCTURED_BYTE_FETCHES}" "${SHALLOW_STRUCTURED_BYTE_FETCHES_MAX}"
  check_count_threshold "MIXED_STRUCTURED_BYTE_FETCHES" "${MIXED_STRUCTURED_BYTE_FETCHES}" "${MIXED_STRUCTURED_BYTE_FETCHES_MAX}"
  check_count_threshold "SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES" "${SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES}" "${SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX}"
  check_count_threshold "MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES" "${MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES}" "${MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX}"
  check_count_floor "SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES" "${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}" "${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN}"
  check_count_floor "MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES" "${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}" "${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN}"
  check_count_threshold "SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES" "${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}" "${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX}"
  check_count_threshold "MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES" "${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}" "${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX}"
  check_count_threshold "SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS" "${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS}" "${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX}"
  check_count_threshold "MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS" "${MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS}" "${MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX}"
  check_count_threshold "BUSINESS_STRUCTURED_BYTE_FALLBACKS" "${BUSINESS_STRUCTURED_BYTE_FALLBACKS}" "${BUSINESS_STRUCTURED_BYTE_FALLBACKS_MAX}"
  check_count_threshold "BUSINESS_STRUCTURED_BYTE_FETCHES" "${BUSINESS_STRUCTURED_BYTE_FETCHES}" "${BUSINESS_STRUCTURED_BYTE_FETCHES_MAX}"
  check_count_threshold "BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES" "${BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES}" "${BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX}"
  check_count_floor "BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES" "${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}" "${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN}"
  check_count_threshold "BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES" "${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}" "${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX}"
  check_count_threshold "BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS" "${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS}" "${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX}"
  check_count_floor "CLAMPED_GCI_TRAVERSAL_FETCHES" "${CLAMPED_GCI_TRAVERSAL_FETCHES}" "${CLAMPED_GCI_TRAVERSAL_FETCHES_MIN}"
  check_count_threshold "CLAMPED_GCI_TRAVERSAL_FETCHES" "${CLAMPED_GCI_TRAVERSAL_FETCHES}" "${CLAMPED_GCI_TRAVERSAL_FETCHES_MAX}"
  check_count_floor "CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES" "${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}" "${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN}"
  check_count_threshold "CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES" "${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}" "${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX}"
  check_count_threshold "CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS" "${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS}" "${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX}"
  check_count_threshold "CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS" "${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS}" "${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS_MAX}"
  check_count_threshold "CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS" "${CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS}" "${CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS_MAX}"
  gbs_append_summary_line "- round-trip count thresholds: shallow slots \`${SHALLOW_SLOT_BATCHES_MAX}\`, shallow class names \`${SHALLOW_CLASS_NAME_BATCHES_MAX}\`, mixed collection arrays \`${MIXED_COLLECTION_ARRAY_BATCHES_MAX}\`, mixed dictionary pairs \`${MIXED_DICTIONARY_PAIR_BATCHES_MAX}\`, mixed string batches \`${MIXED_SCALAR_STRING_BATCHES_MAX}\`, mixed byte-array batches \`${MIXED_SCALAR_BYTE_ARRAY_BATCHES_MAX}\`"
  gbs_append_summary_line "- structured transport thresholds: old byte fetches shallow/mixed/business \`${SHALLOW_STRUCTURED_BYTE_FETCHES_MAX}/${MIXED_STRUCTURED_BYTE_FETCHES_MAX}/${BUSINESS_STRUCTURED_BYTE_FETCHES_MAX}\`, traversal-byte fetches shallow/mixed/business \`${SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX}/${MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX}/${BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES_MAX}\`, traversal-buffer fetches shallow \`${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN}-${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX}\`, mixed \`${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN}-${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX}\`, business \`${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN}-${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX}\`, reports shallow/mixed/business \`${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX}/${MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX}/${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX}\`, fallbacks shallow/mixed/business \`${SHALLOW_STRUCTURED_BYTE_FALLBACKS_MAX}/${MIXED_STRUCTURED_BYTE_FALLBACKS_MAX}/${BUSINESS_STRUCTURED_BYTE_FALLBACKS_MAX}\`"
  gbs_append_summary_line "- clamped traversal thresholds: elapsed \`${CLAMPED_MAX_MS} ms\`, GciClampedTrav fetches \`${CLAMPED_GCI_TRAVERSAL_FETCHES_MIN}-${CLAMPED_GCI_TRAVERSAL_FETCHES_MAX}\`, traversal-buffer fetches \`${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MIN}-${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES_MAX}\`, reports \`${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS_MAX}\`, fallbacks \`${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS_MAX}\`, association fallback \`${CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS_MAX}\`"
  gbs_append_summary_line "- structured transport: shallow traversal-buffer fetches \`${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}\`, reports \`${SHALLOW_STRUCTURED_TRAVERSAL_BUFFER_REPORTS}\`, GCI-byte fetches \`${SHALLOW_STRUCTURED_BYTE_FETCHES}\`, traversal-byte fetches \`${SHALLOW_STRUCTURED_TRAVERSAL_BYTE_FETCHES}\`, fallbacks \`${SHALLOW_STRUCTURED_BYTE_FALLBACKS}/${SHALLOW_STRUCTURED_BYTE_FALLBACKS_MAX}\`; mixed traversal-buffer fetches \`${MIXED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}\`, reports \`${MIXED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS}\`, GCI-byte fetches \`${MIXED_STRUCTURED_BYTE_FETCHES}\`, traversal-byte fetches \`${MIXED_STRUCTURED_TRAVERSAL_BYTE_FETCHES}\`, fallbacks \`${MIXED_STRUCTURED_BYTE_FALLBACKS}/${MIXED_STRUCTURED_BYTE_FALLBACKS_MAX}\`; business traversal-buffer fetches \`${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}\`, reports \`${BUSINESS_STRUCTURED_TRAVERSAL_BUFFER_REPORTS}\`, GCI-byte fetches \`${BUSINESS_STRUCTURED_BYTE_FETCHES}\`, traversal-byte fetches \`${BUSINESS_STRUCTURED_TRAVERSAL_BYTE_FETCHES}\`, fallbacks \`${BUSINESS_STRUCTURED_BYTE_FALLBACKS}/${BUSINESS_STRUCTURED_BYTE_FALLBACKS_MAX}\`"
  gbs_append_summary_line "- clamped traversal: elapsed \`${CLAMPED_MS} ms\`, GciClampedTrav fetches \`${CLAMPED_GCI_TRAVERSAL_FETCHES}\`, traversal-buffer fetches \`${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FETCHES}\`, reports \`${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_REPORTS}\`, fallbacks \`${CLAMPED_STRUCTURED_TRAVERSAL_BUFFER_FALLBACKS}\`, association fallback \`${CLAMPED_ASSOCIATION_PAIR_TRAVERSAL_FALLBACKS}\`"
  gbs_append_summary_line "- wrapper lookup profile: shallow lookups \`${SHALLOW_WRAPPER_LOOKUPS}\`, misses \`${SHALLOW_WRAPPER_LOOKUP_MISSES}/${SHALLOW_WRAPPER_LOOKUP_MISSES_MAX}\`, hits \`${SHALLOW_WRAPPER_CACHE_HITS}\`, fast connector hits \`${SHALLOW_WRAPPER_FAST_CONNECTOR_HITS}\`, typed \`${SHALLOW_WRAPPER_TYPED_RESULTS}\`, nil \`${SHALLOW_WRAPPER_NIL_RESULTS}\`; mixed misses \`${MIXED_WRAPPER_LOOKUP_MISSES}/${MIXED_WRAPPER_LOOKUP_MISSES_MAX}\`, hits \`${MIXED_WRAPPER_CACHE_HITS}\`, fast connector hits \`${MIXED_WRAPPER_FAST_CONNECTOR_HITS}\`, typed \`${MIXED_WRAPPER_TYPED_RESULTS}\`, nil \`${MIXED_WRAPPER_NIL_RESULTS}\`; business misses \`${BUSINESS_WRAPPER_LOOKUP_MISSES}/${BUSINESS_WRAPPER_LOOKUP_MISSES_MAX}\`, hits \`${BUSINESS_WRAPPER_CACHE_HITS}\`, fast connector hits \`${BUSINESS_WRAPPER_FAST_CONNECTOR_HITS}\`"
  check_trend_regression
  emit_summary "OK" "MATERIALIZATION_PERF_OK" "${ARRAY_MS}" "${DICTIONARY_MS}" "${SHALLOW_MS}" "${ARRAY_SIZE}" "${DICTIONARY_SIZE}" "${SHALLOW_SIZE}" "${SHALLOW_ROOT_MS}" "${SHALLOW_SLOT_MS}" "${SHALLOW_CLASS_NAME_BATCH_MS}" "${SHALLOW_PROXY_MS}" "${SHALLOW_WRAPPER_MS}" "${SHALLOW_SLOT_BATCHES}" "${SHALLOW_CLASS_NAME_BATCHES}" "${SHALLOW_PROXY_CREATIONS}" "${SHALLOW_WRAPPER_LOOKUPS}" "${MIXED_MS}" "${MIXED_SIZE}" "${MIXED_COLLECTION_ARRAY_BATCHES}" "${MIXED_DICTIONARY_PAIR_BATCHES}" "${MIXED_SCALAR_STRING_BATCHES}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES}"
  write_trend_sample
  write_trend_report
  echo "MATERIALIZATION_PERF_BASELINE_OK"
  exit 0
fi

emit_summary "FAIL" "${CODE:-MATERIALIZATION_PERF_FAILED}" "${ARRAY_MS:-0}" "${DICTIONARY_MS:-0}" "${SHALLOW_MS:-0}" "${ARRAY_SIZE:-0}" "${DICTIONARY_SIZE:-0}" "${SHALLOW_SIZE:-0}" "${SHALLOW_ROOT_MS}" "${SHALLOW_SLOT_MS}" "${SHALLOW_CLASS_NAME_BATCH_MS}" "${SHALLOW_PROXY_MS}" "${SHALLOW_WRAPPER_MS}" "${SHALLOW_SLOT_BATCHES}" "${SHALLOW_CLASS_NAME_BATCHES}" "${SHALLOW_PROXY_CREATIONS}" "${SHALLOW_WRAPPER_LOOKUPS}" "${MIXED_MS}" "${MIXED_SIZE}" "${MIXED_COLLECTION_ARRAY_BATCHES}" "${MIXED_DICTIONARY_PAIR_BATCHES}" "${MIXED_SCALAR_STRING_BATCHES}" "${MIXED_SCALAR_BYTE_ARRAY_BATCHES}"
exit 1
