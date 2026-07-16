#!/usr/bin/env bash
set -euo pipefail

REPO="${GBS_GITHUB_REPO:-unicompute/GemStone-Pharo-Bridge}"
RUNNER_DIR="${GBS_RUNNER_DIR:-/Users/tariq/src/actions-runner-gemstone-pharo-bridge}"
RUNNER_NAME="${GBS_RUNNER_NAME:-gemstone-pharo-bridge-local-arm64}"
RUNNER_LABELS="${GBS_RUNNER_LABELS:-self-hosted,macOS,ARM64,gemstone-pharo-bridge}"
RUNNER_WORK="${GBS_RUNNER_WORK:-_work}"

PHARO_IMAGE_VALUE="${PHARO_IMAGE:-/Users/tariq/Documents/Pharo/images/Pharo 14.0 - clean/Pharo 14.0 - clean.image}"
PHARO_WORK_DIR_VALUE="${PHARO_WORK_DIR:-/Users/tariq/Documents/Pharo/images/Pharo 14.0 - clean}"
GEMSTONE_VALUE="${GEMSTONE:-/Users/tariq/GemStone64Bit3.7.5-arm64.Darwin}"
GS_STONE_VALUE="${GS_STONE:-gs64stone}"
GS_SERVICE_VALUE="${GS_SERVICE:-gemnetobject}"
GS_NETLDI_HOST_VALUE="${GS_NETLDI_HOST:-localhost}"
GS_NETLDI_NAME_OR_PORT_VALUE="${GS_NETLDI_NAME_OR_PORT:-netldi}"
OKZ_GEMSTONE_HOST_USERNAME_VALUE="${OKZ_GEMSTONE_HOST_USERNAME:-${GS_HOST_USERNAME:-}}"
OKZ_GEMSTONE_HOST_PASSWORD_VALUE="${OKZ_GEMSTONE_HOST_PASSWORD:-${GS_HOST_PASSWORD:-}}"

DO_CHECK=0
DO_SET_VARS=0
DO_SET_SECRETS=0
DO_CONFIGURE=0
DO_INSTALL_SERVICE=0
DO_START_SERVICE=0
DO_REPLACE=0

usage() {
  cat <<'USAGE'
Usage: scripts/setup_github_self_hosted_runner.sh [options]

Options:
  --check             Print current repo variables/secrets/runners.
  --set-vars          Set non-secret GitHub Actions variables for live CI.
  --set-secrets       Set GS_USER/GS_PASS secrets and optional host-auth secrets from the current environment.
  --configure-runner  Download/configure a local self-hosted runner for this repo.
  --install-service   Install the configured runner as a macOS LaunchAgent.
  --start-service     Start the LaunchAgent runner service.
  --replace           Replace an existing runner config in the runner directory.
  --all               Run --set-vars --set-secrets --configure-runner --install-service --start-service.

Environment overrides:
  GBS_GITHUB_REPO, GBS_RUNNER_DIR, GBS_RUNNER_NAME, GBS_RUNNER_LABELS, GBS_RUNNER_WORK
  PHARO_IMAGE, PHARO_WORK_DIR, GEMSTONE, GS_STONE, GS_SERVICE, GS_NETLDI_HOST, GS_NETLDI_NAME_OR_PORT
  GS_USER, GS_PASS, optional OKZ_GEMSTONE_HOST_USERNAME, OKZ_GEMSTONE_HOST_PASSWORD

This script never prints passwords. If --set-secrets is used, GS_USER and GS_PASS must already be exported.
USAGE
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 2
  }
}

set_repo_variable() {
  local name="$1"
  local value="$2"
  gh variable set "$name" --repo "$REPO" --body "$value" >/dev/null
  echo "SET_REPO_VARIABLE ${name}"
}

set_repo_secret_from_env() {
  local name="$1"
  local value="${!name:-}"
  [[ -n "${value}" ]] || {
    echo "Missing ${name}; export it before --set-secrets." >&2
    exit 2
  }
  printf '%s' "$value" | gh secret set "$name" --repo "$REPO" >/dev/null
  echo "SET_REPO_SECRET ${name}"
}

set_repo_optional_secret() {
  local name="$1"
  local value="$2"
  if [[ -z "${value}" ]]; then
    echo "SKIP_REPO_SECRET ${name} unset"
    return 0
  fi
  printf '%s' "$value" | gh secret set "$name" --repo "$REPO" >/dev/null
  echo "SET_REPO_SECRET ${name}"
}

latest_runner_version() {
  local tag
  tag="$(gh api repos/actions/runner/releases/latest --jq '.tag_name')"
  printf '%s\n' "${tag#v}"
}

ensure_runner_files() {
  local version archive url
  mkdir -p "$RUNNER_DIR"
  if [[ -x "${RUNNER_DIR}/config.sh" ]]; then
    echo "RUNNER_FILES_EXIST ${RUNNER_DIR}"
    return 0
  fi
  version="${GBS_RUNNER_VERSION:-$(latest_runner_version)}"
  archive="${RUNNER_DIR}/actions-runner-osx-arm64-${version}.tar.gz"
  url="https://github.com/actions/runner/releases/download/v${version}/actions-runner-osx-arm64-${version}.tar.gz"
  echo "DOWNLOADING_ACTIONS_RUNNER version=${version}"
  curl -fsSL "$url" -o "$archive"
  tar -xzf "$archive" -C "$RUNNER_DIR"
}

configure_runner() {
  local token
  local config_args=()
  ensure_runner_files
  if [[ -f "${RUNNER_DIR}/.runner" && "$DO_REPLACE" -eq 0 ]]; then
    echo "RUNNER_ALREADY_CONFIGURED ${RUNNER_DIR}; use --replace to reconfigure."
    return 0
  fi
  [[ "$DO_REPLACE" -eq 1 ]] && config_args+=(--replace)
  token="$(gh api -X POST "repos/${REPO}/actions/runners/registration-token" --jq '.token')"
  config_args+=(
    --url "https://github.com/${REPO}"
    --token "$token"
    --name "$RUNNER_NAME"
    --labels "$RUNNER_LABELS"
    --work "$RUNNER_WORK"
    --unattended
  )
  (
    cd "$RUNNER_DIR"
    ./config.sh "${config_args[@]}"
  )
  echo "RUNNER_CONFIGURED name=${RUNNER_NAME} dir=${RUNNER_DIR}"
}

install_service() {
  (cd "$RUNNER_DIR" && ./svc.sh install)
  echo "RUNNER_SERVICE_INSTALLED ${RUNNER_NAME}"
}

start_service() {
  (cd "$RUNNER_DIR" && ./svc.sh start)
  echo "RUNNER_SERVICE_STARTED ${RUNNER_NAME}"
}

check_state() {
  echo "CHECK_REPO ${REPO}"
  echo "CHECK_VARIABLES"
  gh variable list --repo "$REPO" || true
  echo "CHECK_SECRETS"
  gh secret list --repo "$REPO" || true
  echo "CHECK_REPOSITORY_RUNNERS"
  gh api "repos/${REPO}/actions/runners" --jq '.runners[]? | [.name, .status, (.labels | map(.name) | join(","))] | @tsv' || true
}

if [[ "$#" -eq 0 ]]; then
  usage
  exit 0
fi

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --check) DO_CHECK=1 ;;
    --set-vars) DO_SET_VARS=1 ;;
    --set-secrets) DO_SET_SECRETS=1 ;;
    --configure-runner) DO_CONFIGURE=1 ;;
    --install-service) DO_INSTALL_SERVICE=1 ;;
    --start-service) DO_START_SERVICE=1 ;;
    --replace) DO_REPLACE=1 ;;
    --all)
      DO_SET_VARS=1
      DO_SET_SECRETS=1
      DO_CONFIGURE=1
      DO_INSTALL_SERVICE=1
      DO_START_SERVICE=1
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

require_command gh

if [[ "$DO_CHECK" -eq 1 ]]; then
  check_state
fi

if [[ "$DO_SET_VARS" -eq 1 ]]; then
  set_repo_variable PHARO_IMAGE "$PHARO_IMAGE_VALUE"
  set_repo_variable PHARO_WORK_DIR "$PHARO_WORK_DIR_VALUE"
  set_repo_variable GEMSTONE "$GEMSTONE_VALUE"
  set_repo_variable GS_STONE "$GS_STONE_VALUE"
  set_repo_variable GS_SERVICE "$GS_SERVICE_VALUE"
  set_repo_variable GS_NETLDI_HOST "$GS_NETLDI_HOST_VALUE"
  set_repo_variable GS_NETLDI_NAME_OR_PORT "$GS_NETLDI_NAME_OR_PORT_VALUE"
fi

if [[ "$DO_SET_SECRETS" -eq 1 ]]; then
  set_repo_secret_from_env GS_USER
  set_repo_secret_from_env GS_PASS
  set_repo_optional_secret OKZ_GEMSTONE_HOST_USERNAME "$OKZ_GEMSTONE_HOST_USERNAME_VALUE"
  set_repo_optional_secret OKZ_GEMSTONE_HOST_PASSWORD "$OKZ_GEMSTONE_HOST_PASSWORD_VALUE"
fi

if [[ "$DO_CONFIGURE" -eq 1 ]]; then
  require_command curl
  require_command tar
  configure_runner
fi

if [[ "$DO_INSTALL_SERVICE" -eq 1 ]]; then
  install_service
fi

if [[ "$DO_START_SERVICE" -eq 1 ]]; then
  start_service
fi
