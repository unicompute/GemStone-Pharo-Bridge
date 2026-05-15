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

gbs_write_evidence_file() {
  local filename="${1:-}"
  local payload="${2:-}"
  local evidence_dir="${GBS_EVIDENCE_DIR:-${GBS_JSON_SUMMARY_DIR:-}}"
  if [[ -n "${evidence_dir}" && -n "${filename}" ]]; then
    mkdir -p "${evidence_dir}"
    printf '%s\n' "${payload}" > "${evidence_dir}/${filename}"
  fi
}

gbs_normalize_live_env_vars() {
  export GS_USER="${GS_USER:-${GS_USERNAME:-}}"
  export GS_PASS="${GS_PASS:-${GS_PASSWORD:-}}"
  export GS_NETLDI_HOST="${GS_NETLDI_HOST:-${GS_HOST:-}}"
  export GS_NETLDI_NAME_OR_PORT="${GS_NETLDI_NAME_OR_PORT:-${GS_NETLDI:-}}"
}

gbs_required_live_env_vars() {
  printf '%s\n' \
    GS_USER \
    GS_PASS \
    GEMSTONE \
    GS_NETLDI_HOST \
    GS_NETLDI_NAME_OR_PORT
}

gbs_missing_required_live_env_vars() {
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
  done < <(gbs_required_live_env_vars)
  printf '%s\n' "${missing}"
}

gbs_live_env_status_line() {
  local missing="${1:-$(gbs_missing_required_live_env_vars)}"
  printf 'required=%s missing=%s stone=%s service=%s host=%s net=%s gemstone=%s\n' \
    "$(gbs_required_live_env_vars | paste -sd, -)" \
    "${missing:-none}" \
    "${GS_STONE:-gs64stone}" \
    "${GS_SERVICE:-gemnetobject}" \
    "${GS_NETLDI_HOST:-unset}" \
    "${GS_NETLDI_NAME_OR_PORT:-unset}" \
    "${GEMSTONE:-unset}"
}

gbs_normalize_live_env_vars

gbs_cleanup_registered_work_images() {
  local image
  if [[ "${GBS_KEEP_WORK_IMAGES:-0}" == "1" ]]; then
    if [[ -n "${GBS_WORK_IMAGES_TO_CLEAN:-}" ]]; then
      printf 'Keeping Pharo work images because GBS_KEEP_WORK_IMAGES=1\n' >&2
    fi
    return 0
  fi

  while IFS= read -r image; do
    [[ -n "${image}" ]] || continue
    rm -f "${image}" "${image%.image}.changes"
  done <<< "${GBS_WORK_IMAGES_TO_CLEAN:-}"
}

gbs_register_work_image_cleanup() {
  local work_image="${1:-}"
  [[ -n "${work_image}" ]] || return 0
  if [[ -n "${GBS_WORK_IMAGES_TO_CLEAN:-}" ]]; then
    GBS_WORK_IMAGES_TO_CLEAN="${GBS_WORK_IMAGES_TO_CLEAN}"$'\n'"${work_image}"
  else
    GBS_WORK_IMAGES_TO_CLEAN="${work_image}"
  fi
  trap gbs_cleanup_registered_work_images EXIT
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
