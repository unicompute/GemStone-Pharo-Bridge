#!/usr/bin/env bash
set -euo pipefail

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo}"
WORK_IMAGE="${1:?usage: run_live_preflight.sh <work-image>}"
STONE="${GS_STONE:-gs64stone}"
USER_NAME="${GS_USER:-}"
PASSWORD="${GS_PASS:-}"
SERVICE_NAME="${GS_SERVICE:-gemnetobject}"
NETLDI_HOST="${GS_NETLDI_HOST:-}"
NETLDI_NAME_OR_PORT="${GS_NETLDI_NAME_OR_PORT:-}"
GEMSTONE_HOME="${GEMSTONE:-}"

classify_topaz_failure() {
  local output="$1"
  local lowered
  lowered="$(printf '%s' "${output}" | tr '[:upper:]' '[:lower:]')"
  if [[ "${lowered}" == *"invalid or expired"* || "${lowered}" == *"invalid password"* || "${lowered}" == *"invalid userid"* || "${lowered}" == *"invalid user"* ]]; then
    echo "LIVE_PREFLIGHT_AUTH_FAILED"
  elif [[ "${lowered}" == *"netldi"* || "${lowered}" == *"unable to connect"* || "${lowered}" == *"cannot connect"* || "${lowered}" == *"connection refused"* ]]; then
    echo "LIVE_PREFLIGHT_ROUTE_FAILED"
  elif [[ "${lowered}" == *"stone"* && "${lowered}" == *"does not exist"* ]]; then
    echo "LIVE_PREFLIGHT_STONE_NOT_FOUND"
  else
    echo "LIVE_PREFLIGHT_TOPAZ_LOGIN_FAILED"
  fi
}

classify_gci_failure() {
  local output="$1"
  local lowered
  lowered="$(printf '%s' "${output}" | tr '[:upper:]' '[:lower:]')"
  if [[ "${lowered}" == *"invalid or expired"* || "${lowered}" == *"invalid password"* || "${lowered}" == *"invalid credentials"* ]]; then
    echo "LIVE_PREFLIGHT_GCI_AUTH_FAILED"
  elif [[ "${lowered}" == *"netldi"* || "${lowered}" == *"gemnetobject"* || "${lowered}" == *"cannot connect"* || "${lowered}" == *"not accessible"* ]]; then
    echo "LIVE_PREFLIGHT_GCI_ROUTE_FAILED"
  elif [[ "${lowered}" == *"stone"* && "${lowered}" == *"does not exist"* ]]; then
    echo "LIVE_PREFLIGHT_GCI_STONE_NOT_FOUND"
  else
    echo "LIVE_PREFLIGHT_GCI_LOGIN_FAILED"
  fi
}

if [[ -z "${USER_NAME}" || -z "${PASSWORD}" ]]; then
  echo "LIVE_PREFLIGHT_SKIPPED: set GS_USER and GS_PASS to run preflight"
  exit 0
fi

echo "LIVE_PREFLIGHT_BEGIN stone=${STONE} service=${SERVICE_NAME} host=${NETLDI_HOST:-'(implicit)'} net=${NETLDI_NAME_OR_PORT:-'(implicit)'}"

gslist_bin="${GEMSTONE_HOME:+${GEMSTONE_HOME}/bin/gslist}"
if [[ -z "${GEMSTONE_HOME}" || ! -x "${gslist_bin}" ]]; then
  gslist_bin="$(command -v gslist || true)"
fi

if [[ -n "${gslist_bin}" ]]; then
  gslist_output="$("${gslist_bin}" -lcv 2>&1 || true)"
  echo "${gslist_output}"
  if grep -Eq "^OK[[:space:]].*[[:space:]]Stone[[:space:]]+${STONE}$" <<< "${gslist_output}"; then
    echo "LIVE_PREFLIGHT_STONE_OK ${STONE}"
  else
    echo "LIVE_PREFLIGHT_STONE_STATUS_UNKNOWN ${STONE}"
  fi
  if grep -Eq "^OK[[:space:]].*[[:space:]]Netldi[[:space:]]+" <<< "${gslist_output}"; then
    echo "LIVE_PREFLIGHT_NETLDI_OK"
  else
    echo "LIVE_PREFLIGHT_NETLDI_STATUS_UNKNOWN"
  fi
else
  echo "LIVE_PREFLIGHT_GSLIST_UNAVAILABLE"
fi

topaz_bin="${GEMSTONE_HOME:+${GEMSTONE_HOME}/bin/topaz}"
if [[ -z "${GEMSTONE_HOME}" || ! -x "${topaz_bin}" ]]; then
  topaz_bin="$(command -v topaz || true)"
fi

if [[ -n "${topaz_bin}" ]]; then
  topaz_set_command="set user ${USER_NAME} pass ${PASSWORD} gems ${STONE}"
  if [[ -n "${NETLDI_HOST}" && -n "${NETLDI_NAME_OR_PORT}" ]]; then
    topaz_set_command="${topaz_set_command} netldi ${NETLDI_HOST}#${NETLDI_NAME_OR_PORT}"
  fi
  topaz_output="$(
    printf '%s\nlogin\nlogout\nquit\n' "${topaz_set_command}" \
      | "${topaz_bin}" -l 2>&1 || true
  )"
  echo "${topaz_output}"
  if grep -qi "login failed" <<< "${topaz_output}"; then
    classify_topaz_failure "${topaz_output}"
    exit 1
  fi
  echo "LIVE_PREFLIGHT_TOPAZ_LOGIN_OK"
else
  echo "LIVE_PREFLIGHT_TOPAZ_UNAVAILABLE"
fi

mkdir -p /tmp/pharo-clean-auto/home
probe_output="$(
  HOME=/tmp/pharo-clean-auto/home \
  GS_STONE="${STONE}" \
  GS_USER="${USER_NAME}" \
  GS_PASS="${PASSWORD}" \
  GS_SERVICE="${SERVICE_NAME}" \
  GS_NETLDI_HOST="${NETLDI_HOST}" \
  GS_NETLDI_NAME_OR_PORT="${NETLDI_NAME_OR_PORT}" \
  "${VM}" --headless "${WORK_IMAGE}" st "/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/probe_live_login.st" 2>&1 || true
)"
echo "${probe_output}"
if grep -q "PROBE_LOGIN_OK" <<< "${probe_output}"; then
  echo "LIVE_PREFLIGHT_GCI_LOGIN_OK"
  echo "LIVE_PREFLIGHT_OK"
  exit 0
fi

classify_gci_failure "${probe_output}"
exit 1
