#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

printf '{"result":"OK","code":"VERIFY_OK"}\n' > "${tmpdir}/verify-summary.json"
printf '{"result":"OK","code":"BOOTSTRAP_SMOKE_OK"}\n' > "${tmpdir}/bootstrap-smoke-summary.json"

output="$(GITHUB_STEP_SUMMARY="${tmpdir}/summary.md" bash ./scripts/render_lane_json_summaries.sh "${tmpdir}")"
printf '%s\n' "${output}"

grep -q '::notice title=bootstrap-smoke-summary.json::result=OK code=BOOTSTRAP_SMOKE_OK' <<< "${output}"
grep -q '::notice title=verify-summary.json::result=OK code=VERIFY_OK' <<< "${output}"
grep -q '## Lane JSON Summaries' "${tmpdir}/summary.md"
grep -q '### bootstrap-smoke-summary.json' "${tmpdir}/summary.md"
grep -q '### verify-summary.json' "${tmpdir}/summary.md"
grep -q '"code":"BOOTSTRAP_SMOKE_OK"' "${tmpdir}/summary.md"
grep -q '"code":"VERIFY_OK"' "${tmpdir}/summary.md"

echo "SUMMARY_RENDERER_TEST_OK"
