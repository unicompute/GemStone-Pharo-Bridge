#!/usr/bin/env bash
# Worker-fault live lane (Phase-1 hardening A6): loads the bridge from tonel
# into a throwaway copy of a clean image and runs the worker fault suites
# (GbsWorkerFaultLiveTest thread-safe path, GbsLegacyWorkerFaultLiveTest
# legacy path) against the live stone. Without GS_USER/GS_PASS the live
# tests skip and the lane still passes (same convention as the other lanes).
set -euo pipefail

VM="${PHARO_VM:-/Users/tariq/Documents/Pharo/vms/140-x64/Pharo.app/Contents/MacOS/Pharo}"
CLEAN_IMAGE="${1:?usage: run_worker_fault_live.sh <clean-image>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

WORK="$(mktemp -d /tmp/gbs-worker-fault-XXXXXX)"
trap 'rm -rf "${WORK}"' EXIT

cp "${CLEAN_IMAGE}" "${WORK}/fault.image"
# Pharo 14 refuses a zero-byte .changes ("Cannot open non source file"), so
# the real one is copied. Point CLEAN_IMAGE at a clean image: a long-lived
# image's accumulated .changes can be multi-GB.
cp "${CLEAN_IMAGE%.image}.changes" "${WORK}/fault.changes"
IMAGE_DIR="$(dirname "${CLEAN_IMAGE}")"
cp "${IMAGE_DIR}"/*.sources "${WORK}/" 2>/dev/null || true
cp "${IMAGE_DIR}/pharo.version" "${WORK}/" 2>/dev/null || true

output="$("${VM}" --headless "${WORK}/fault.image" st "${SCRIPT_DIR}/run_worker_fault_live.st" 2>&1 || true)"
printf '%s\n' "${output}" | grep -E "WORKER-FAULT-SUITE|WORKER-FAULT-TOTAL|WORKER-FAULT-RESULT|FAIL:|ERR:" || true

if ! printf '%s\n' "${output}" | grep -q "WORKER-FAULT-RESULT ok"; then
  echo "WORKER_FAULT_LANE_FAIL"
  exit 1
fi
