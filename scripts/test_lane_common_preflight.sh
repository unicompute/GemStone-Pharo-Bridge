#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

source ./scripts/lane_common.sh

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

IMAGE_DIR="${TMP_DIR}/images/Pharo 13.0 - clean"
WORK_DIR="${TMP_DIR}/work"
mkdir -p "${IMAGE_DIR}" "${WORK_DIR}"

SRC_IMAGE="${IMAGE_DIR}/Pharo 13.0 - clean.image"
SRC_CHANGES="${IMAGE_DIR}/Pharo 13.0 - clean.changes"
printf 'fake image Pharo13.1-64bit-e84a2d1.sources\n' > "${SRC_IMAGE}"
printf 'large changes placeholder\n' > "${SRC_CHANGES}"

available="$(gbs_available_bytes_for_dir "${WORK_DIR}")"
export GBS_WORK_IMAGE_MIN_FREE_BYTES="$((available + 1))"
if gbs_prepare_work_image_preflight "${SRC_IMAGE}" "${WORK_DIR}" 2>"${TMP_DIR}/preflight.err"; then
  fail "preflight unexpectedly passed with a margin larger than available disk"
fi
grep -q 'Not enough free disk space' "${TMP_DIR}/preflight.err" || fail "missing low-space diagnostic"
grep -q 'changes:' "${TMP_DIR}/preflight.err" || fail "missing .changes diagnostic"
unset GBS_WORK_IMAGE_MIN_FREE_BYTES

OTHER_IMAGE_DIR="${TMP_DIR}/images/Pharo 13.0 - other"
mkdir -p "${OTHER_IMAGE_DIR}"
printf 'sources\n' > "${OTHER_IMAGE_DIR}/Pharo13.1-64bit-e84a2d1.sources"

gbs_prepare_sources_files "${SRC_IMAGE}" "${WORK_DIR}"
[[ -e "${WORK_DIR}/Pharo13.1-64bit-e84a2d1.sources" ]] || fail "expected sources file was not prepared"

(
  unset OKZ_GEMSTONE_HOST_USERNAME OKZ_GEMSTONE_HOST_PASSWORD GS_HOST_USERNAME GS_HOST_PASSWORD GS_NETLDI_HOST_USERNAME GS_NETLDI_HOST_PASSWORD
  [[ "$(gbs_live_host_auth_status)" == "unset" ]] || fail "expected unset host auth status"
  export OKZ_GEMSTONE_HOST_USERNAME="host-user"
  [[ "$(gbs_live_host_auth_status)" == "partial" ]] || fail "expected partial host auth status"
  export OKZ_GEMSTONE_HOST_PASSWORD="host-secret"
  [[ "$(gbs_live_host_auth_status)" == "set" ]] || fail "expected set host auth status"
)

(
  unset OKZ_GEMSTONE_HOST_USERNAME OKZ_GEMSTONE_HOST_PASSWORD
  export GS_HOST_USERNAME="alias-user"
  export GS_HOST_PASSWORD="alias-secret"
  gbs_normalize_live_env_vars
  [[ "${OKZ_GEMSTONE_HOST_USERNAME}" == "alias-user" ]] || fail "expected host username alias to normalize"
  [[ "${OKZ_GEMSTONE_HOST_PASSWORD}" == "alias-secret" ]] || fail "expected host password alias to normalize"
  [[ "$(gbs_live_env_status_line)" == *"host_auth=set"* ]] || fail "expected host_auth in live env status line"
)

echo "lane_common preflight tests passed"
