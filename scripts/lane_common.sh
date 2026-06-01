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

gbs_file_size_bytes() {
  local file="${1:-}"
  if [[ -z "${file}" || ! -f "${file}" ]]; then
    printf '0\n'
    return 0
  fi
  stat -f '%z' "${file}" 2>/dev/null || stat -c '%s' "${file}" 2>/dev/null || wc -c < "${file}"
}

gbs_available_bytes_for_dir() {
  local dir="${1:-.}"
  mkdir -p "${dir}"
  df -Pk "${dir}" | awk 'NR == 2 { printf "%.0f\n", $4 * 1024 }'
}

gbs_human_bytes() {
  local bytes="${1:-0}"
  awk -v bytes="${bytes}" 'BEGIN {
    split("B KiB MiB GiB TiB", units, " ");
    value = bytes + 0;
    unit = 1;
    while (value >= 1024 && unit < 5) {
      value = value / 1024;
      unit++;
    }
    printf "%.1f %s", value, units[unit];
  }'
}

gbs_expected_sources_name_for_image() {
  local src_image="${1:-}"
  local expected="${GBS_EXPECTED_SOURCES_NAME:-}"
  if [[ -n "${expected}" ]]; then
    printf '%s\n' "${expected}"
    return 0
  fi
  [[ -n "${src_image}" && -f "${src_image}" ]] || return 0
  strings "${src_image}" 2>/dev/null \
    | grep -Eo 'Pharo[^[:space:]/]+\.sources' \
    | tail -1
}

gbs_find_sources_file_named() {
  local src_dir="${1:-}"
  local expected="${2:-}"
  local image_root candidate
  [[ -n "${src_dir}" && -n "${expected}" ]] || return 0
  if [[ -f "${src_dir}/${expected}" ]]; then
    printf '%s\n' "${src_dir}/${expected}"
    return 0
  fi
  image_root="$(dirname "${src_dir}")"
  candidate="$(find "${image_root}" -maxdepth 3 -name "${expected}" -type f -print -quit 2>/dev/null || true)"
  [[ -n "${candidate}" ]] && printf '%s\n' "${candidate}"
}

gbs_first_available_sources_file() {
  local work_dir="${1:-}"
  local src_dir="${2:-}"
  local image_root candidate
  for candidate in "${work_dir}"/Pharo*.sources "${src_dir}"/Pharo*.sources; do
    [[ -f "${candidate}" ]] || continue
    printf '%s\n' "${candidate}"
    return 0
  done
  image_root="$(dirname "${src_dir}")"
  candidate="$(find "${image_root}" -maxdepth 3 -name 'Pharo*.sources' -type f -print -quit 2>/dev/null || true)"
  [[ -n "${candidate}" ]] && printf '%s\n' "${candidate}"
}

gbs_prepare_sources_files() {
  local src_image="$1"
  local work_dir="$2"
  local src_dir expected candidate src_dir_real work_dir_real

  src_dir="$(dirname "${src_image}")"
  src_dir_real="$(cd "${src_dir}" && pwd -P)"
  work_dir_real="$(cd "${work_dir}" && pwd -P)"
  if [[ "${src_dir_real}" != "${work_dir_real}" ]] && ls "${src_dir}"/Pharo*.sources >/dev/null 2>&1; then
    cp -f "${src_dir}"/Pharo*.sources "${work_dir}/" || true
  fi

  expected="$(gbs_expected_sources_name_for_image "${src_image}")"
  [[ -n "${expected}" ]] || return 0
  [[ -f "${work_dir}/${expected}" ]] && return 0

  candidate="$(gbs_find_sources_file_named "${src_dir}" "${expected}")"
  if [[ -z "${candidate}" ]]; then
    candidate="$(gbs_first_available_sources_file "${work_dir}" "${src_dir}")"
  fi
  [[ -n "${candidate}" ]] || return 0

  ln -sf "${candidate}" "${work_dir}/${expected}" 2>/dev/null || cp -f "${candidate}" "${work_dir}/${expected}" || true
}

gbs_prepare_work_image_preflight() {
  local src_image="$1"
  local work_dir="$2"
  local src_dir src_changes source_file src_dir_real work_dir_real
  local image_size changes_size sources_size required margin available

  if [[ ! -f "${src_image}" ]]; then
    echo "Pharo source image does not exist: ${src_image}" >&2
    return 1
  fi

  src_dir="$(dirname "${src_image}")"
  src_changes="${src_image%.image}.changes"
  image_size="$(gbs_file_size_bytes "${src_image}")"
  changes_size="$(gbs_file_size_bytes "${src_changes}")"
  sources_size=0
  src_dir_real="$(cd "${src_dir}" && pwd -P)"
  work_dir_real="$(cd "${work_dir}" && pwd -P)"
  if [[ "${src_dir_real}" != "${work_dir_real}" ]]; then
    for source_file in "${src_dir}"/Pharo*.sources; do
      [[ -f "${source_file}" ]] || continue
      sources_size=$((sources_size + $(gbs_file_size_bytes "${source_file}")))
    done
  fi
  margin="${GBS_WORK_IMAGE_MIN_FREE_BYTES:-268435456}"
  required=$((image_size + changes_size + sources_size + margin))
  available="$(gbs_available_bytes_for_dir "${work_dir}")"

  if (( available < required )); then
    {
      echo "Not enough free disk space to prepare the Pharo work image."
      echo "  work dir: ${work_dir}"
      echo "  available: $(gbs_human_bytes "${available}")"
      echo "  required:  $(gbs_human_bytes "${required}")"
      echo "  image:     $(gbs_human_bytes "${image_size}") ${src_image}"
      if [[ -f "${src_changes}" ]]; then
        echo "  changes:   $(gbs_human_bytes "${changes_size}") ${src_changes}"
      fi
      echo "  sources:   $(gbs_human_bytes "${sources_size}")"
      echo "  margin:    $(gbs_human_bytes "${margin}")"
      echo "Free space, reduce the source .changes file, choose another PHARO_WORK_DIR, or set GBS_WORK_IMAGE_MIN_FREE_BYTES for this lane."
    } >&2
    return 1
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
  gbs_prepare_work_image_preflight "${src_image}" "${work_dir}"
  mkdir -p "${work_dir}/pharo-local/ombu-sessions"
  mkdir -p /tmp/pharo-clean-auto/home
  cp -f "${src_image}" "${work_image}"
  if [[ -f "${src_changes}" ]]; then
    cp -f "${src_changes}" "${work_changes}"
  fi
  gbs_prepare_sources_files "${src_image}" "${work_dir}"

  printf '%s\n' "${work_image}"
}
