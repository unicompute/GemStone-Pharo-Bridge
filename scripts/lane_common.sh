#!/usr/bin/env bash

gbs_json_escape() {
  local value="${1:-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "${value}"
}

gbs_append_summary_line() {
  local line="${1:-}"
  if [[ -n "${GBS_SUMMARY_FILE:-}" ]]; then
    printf '%s\n' "${line}" >> "${GBS_SUMMARY_FILE}"
  fi
}

gbs_write_json_summary_file() {
  local filename="${1:-}"
  local payload="${2:-}"
  if [[ -n "${GBS_JSON_SUMMARY_DIR:-}" && -n "${filename}" ]]; then
    mkdir -p "${GBS_JSON_SUMMARY_DIR}"
    printf '%s\n' "${payload}" > "${GBS_JSON_SUMMARY_DIR}/${filename}"
  fi
}

gbs_prepare_work_image() {
  local src_image="$1"
  local work_dir="$2"
  local suffix="$3"
  local src_dir src_base work_image src_changes work_changes

  src_dir="$(dirname "${src_image}")"
  src_base="$(basename "${src_image}" .image)"
  work_image="${work_dir}/${src_base} - ${suffix}.image"
  src_changes="${src_image%.image}.changes"
  work_changes="${work_image%.image}.changes"

  mkdir -p "${work_dir}"
  mkdir -p "${work_dir}/pharo-local/ombu-sessions"
  mkdir -p /tmp/pharo-clean-auto/home
  cp -f "${src_image}" "${work_image}"
  if [[ -f "${src_changes}" ]]; then
    cp -f "${src_changes}" "${work_changes}"
  fi
  if ls "${src_dir}"/Pharo*.sources >/dev/null 2>&1; then
    cp -f "${src_dir}"/Pharo*.sources "${work_dir}/" || true
  fi

  printf '%s\n' "${work_image}"
}
