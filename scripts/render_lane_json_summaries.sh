#!/usr/bin/env bash
set -euo pipefail

SUMMARY_DIR="${1:-${GBS_JSON_SUMMARY_DIR:-}}"
SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-${GBS_SUMMARY_FILE:-}}"
PREFERRED_FILES=(
  "core-only-summary.json"
  "bootstrap-smoke-summary.json"
  "original-summary.json"
  "original-drift-summary.json"
  "original-tests-summary.json"
  "full-summary.json"
  "artifact-freshness-summary.json"
  "verify-summary.json"
)

json_field() {
  local file="$1"
  local key="$2"
  sed -nE "s/.*\"${key}\":\"([^\"]*)\".*/\\1/p" "${file}" | head -n 1
}

json_unescaped_multiline_field() {
  local file="$1"
  local key="$2"
  local raw
  raw="$(json_field "${file}" "${key}")"
  [[ -z "${raw}" ]] && return 0
  printf '%b' "${raw}"
}

print_file_list() {
  local file basename

  for basename in "${PREFERRED_FILES[@]}"; do
    file="${SUMMARY_DIR}/${basename}"
    if [[ -f "${file}" ]]; then
      printf '%s\n' "${file}"
    fi
  done

  for file in "${SUMMARY_DIR}"/*.json; do
    [[ -e "${file}" ]] || continue
    basename="$(basename "${file}")"
    if ! is_preferred_file "${basename}"; then
      printf '%s\n' "${file}"
    fi
  done
}

is_preferred_file() {
  local candidate="$1"
  local preferred
  for preferred in "${PREFERRED_FILES[@]}"; do
    [[ "${preferred}" == "${candidate}" ]] && return 0
  done
  return 1
}

annotation_level_for() {
  local result="$1"
  case "${result}" in
    OK) echo "notice" ;;
    FAIL) echo "error" ;;
    *) echo "warning" ;;
  esac
}

if [[ -z "${SUMMARY_DIR}" || ! -d "${SUMMARY_DIR}" ]]; then
  exit 0
fi

if [[ -n "${SUMMARY_FILE}" ]]; then
  {
    echo
    echo "## Lane JSON Summaries"
    echo
    echo "| Lane | Result | Code |"
    echo "| --- | --- | --- |"
    while IFS= read -r file; do
      [[ -e "${file}" ]] || continue
      name="$(basename "${file}")"
      result="$(json_field "${file}" result)"
      code="$(json_field "${file}" code)"
      echo "| \`${name}\` | \`${result:-unknown}\` | \`${code:-unknown}\` |"
    done < <(print_file_list)
    echo
    while IFS= read -r file; do
      [[ -e "${file}" ]] || continue
      name="$(basename "${file}")"
      result="$(json_field "${file}" result)"
      code="$(json_field "${file}" code)"
      accepted_exceptions="$(json_unescaped_multiline_field "${file}" accepted_exceptions)"
      echo "### ${name}"
      [[ -n "${result}" ]] && echo "- result: \`${result}\`"
      [[ -n "${code}" ]] && echo "- code: \`${code}\`"
      if [[ -n "${accepted_exceptions}" ]]; then
        echo "- accepted exceptions:"
        printf '%s\n' "${accepted_exceptions}"
      fi
      echo '```json'
      cat "${file}"
      echo
      echo '```'
    done < <(print_file_list)
  } >> "${SUMMARY_FILE}"
fi

while IFS= read -r file; do
  [[ -e "${file}" ]] || continue
  name="$(basename "${file}")"
  result="$(json_field "${file}" result)"
  code="$(json_field "${file}" code)"
  level="$(annotation_level_for "${result:-unknown}")"
  printf '::%s title=%s::result=%s code=%s\n' "${level}" "${name}" "${result:-unknown}" "${code:-unknown}"
done < <(print_file_list)
