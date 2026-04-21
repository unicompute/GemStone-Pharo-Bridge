#!/usr/bin/env bash
set -euo pipefail

SUMMARY_DIR="${1:-${GBS_JSON_SUMMARY_DIR:-}}"
SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-${GBS_SUMMARY_FILE:-}}"

json_field() {
  local file="$1"
  local key="$2"
  sed -nE "s/.*\"${key}\":\"([^\"]*)\".*/\\1/p" "${file}" | head -n 1
}

if [[ -z "${SUMMARY_DIR}" || ! -d "${SUMMARY_DIR}" ]]; then
  exit 0
fi

if [[ -n "${SUMMARY_FILE}" ]]; then
  {
    echo
    echo "## Lane JSON Summaries"
    for file in "${SUMMARY_DIR}"/*.json; do
      [[ -e "${file}" ]] || continue
      name="$(basename "${file}")"
      result="$(json_field "${file}" result)"
      code="$(json_field "${file}" code)"
      echo "### ${name}"
      [[ -n "${result}" ]] && echo "- result: \`${result}\`"
      [[ -n "${code}" ]] && echo "- code: \`${code}\`"
      echo '```json'
      cat "${file}"
      echo
      echo '```'
    done
  } >> "${SUMMARY_FILE}"
fi

for file in "${SUMMARY_DIR}"/*.json; do
  [[ -e "${file}" ]] || continue
  name="$(basename "${file}")"
  result="$(json_field "${file}" result)"
  code="$(json_field "${file}" code)"
  printf '::notice title=%s::result=%s code=%s\n' "${name}" "${result:-unknown}" "${code:-unknown}"
done
