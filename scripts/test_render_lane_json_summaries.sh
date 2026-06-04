#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

printf '{"result":"OK","code":"VERIFY_OK"}\n' > "${tmpdir}/verify-summary.json"
printf '{"result":"OK","code":"BOOTSTRAP_SMOKE_OK"}\n' > "${tmpdir}/bootstrap-smoke-summary.json"
printf '{"result":"OK","code":"ORIGINAL_CHECK_OK"}\n' > "${tmpdir}/original-summary.json"
printf '{"result":"OK","code":"ORIGINAL_LAYER_DRIFT_EXPECTED_ONLY","accepted_exceptions":"- `src/GemStone-Pharo-Tests/GciError.extension.st`: tiny test-only GciError number accessor shim\\n- `src/GemStone-Pharo-Tests/MockGbsSession.class.st`: narrow interpretLoginError override"}\n' > "${tmpdir}/original-drift-summary.json"
printf '{"result":"FAIL","code":"FULL_FAILED"}\n' > "${tmpdir}/full-summary.json"
printf '{"result":"OK","code":"FULL_LANE_OK","reload":"ok","unit":"ok","preflight":"ok","live":"ok"}\n' > "${tmpdir}/full-lane-summary.json"
printf '{"result":"OK","code":"LIVE_PREFLIGHT_OK","stone_status":"ok","netldi_status":"ok","topaz":"ok","gci":"ok","host_auth":"set"}\n' > "${tmpdir}/live-preflight-summary.json"
printf '{"result":"OK","code":"LIVE_DEBUGGER_OK","run":"12","failures":"0","errors":"0"}\n' > "${tmpdir}/live-debugger-summary.json"
printf '{"result":"OK","code":"DEBUGGER_PERF_OK","open_ms":"10","stack_fetch_ms":"20","source_lookup_ms":"30","proxy_inspect_ms":"40"}\n' > "${tmpdir}/debugger-performance-summary.json"
printf '{"result":"SKIP","code":"MATERIALIZATION_PERF_SKIPPED_MISSING_ENV","missing":"GS_USER GS_PASS","live_target":"pharo13-gemstone37"}\n' > "${tmpdir}/materialization-performance-summary.json"
printf '{"result":"OK","code":"REPLICATION_LIVE_OK","connector_ms":"1","clamped_ms":"2","dirty_store_ms":"3","business_dirty_store_ms":"4","domain_dirty_store_ms":"5","dirty_store_transport_supported":"1","dirty_store_report_shape_supported":"1","dirty_store_functions_supported":"1","dirty_store_oop_width":"64","native_dirty_store_flushes":"2","semantic_dirty_store_commands":"0","semantic_dictionary_entries":"0","semantic_set_entries":"0","semantic_bag_entries":"0","threshold_file":"./scripts/replication_live_thresholds.env"}\n' > "${tmpdir}/replication-live-summary.json"

output="$(GITHUB_STEP_SUMMARY="${tmpdir}/summary.md" bash ./scripts/render_lane_json_summaries.sh "${tmpdir}")"

grep -q '::notice title=bootstrap-smoke-summary.json::result=OK code=BOOTSTRAP_SMOKE_OK' <<< "${output}"
grep -q '::notice title=original-summary.json::result=OK code=ORIGINAL_CHECK_OK' <<< "${output}"
grep -q '::notice title=original-drift-summary.json::result=OK code=ORIGINAL_LAYER_DRIFT_EXPECTED_ONLY' <<< "${output}"
grep -q '::error title=full-summary.json::result=FAIL code=FULL_FAILED' <<< "${output}"
grep -q '::notice title=verify-summary.json::result=OK code=VERIFY_OK' <<< "${output}"
grep -q '::warning title=materialization-performance-summary.json::result=SKIP code=MATERIALIZATION_PERF_SKIPPED_MISSING_ENV' <<< "${output}"
grep -q '::notice title=replication-live-summary.json::result=OK code=REPLICATION_LIVE_OK' <<< "${output}"
grep -q '## Lane JSON Summaries' "${tmpdir}/summary.md"
grep -q '| Lane | Result | Code |' "${tmpdir}/summary.md"
grep -q '### bootstrap-smoke-summary.json' "${tmpdir}/summary.md"
grep -q '### original-summary.json' "${tmpdir}/summary.md"
grep -q '### original-drift-summary.json' "${tmpdir}/summary.md"
grep -q '### full-summary.json' "${tmpdir}/summary.md"
grep -q '### full-lane-summary.json' "${tmpdir}/summary.md"
grep -q '### verify-summary.json' "${tmpdir}/summary.md"
grep -q '### materialization-performance-summary.json' "${tmpdir}/summary.md"
grep -q '### replication-live-summary.json' "${tmpdir}/summary.md"
grep -q '| `bootstrap-smoke-summary.json` | `OK` | `BOOTSTRAP_SMOKE_OK` |' "${tmpdir}/summary.md"
grep -q '| `original-summary.json` | `OK` | `ORIGINAL_CHECK_OK` |' "${tmpdir}/summary.md"
grep -q '| `original-drift-summary.json` | `OK` | `ORIGINAL_LAYER_DRIFT_EXPECTED_ONLY` |' "${tmpdir}/summary.md"
grep -q '| `full-summary.json` | `FAIL` | `FULL_FAILED` |' "${tmpdir}/summary.md"
grep -q '| `materialization-performance-summary.json` | `SKIP` | `MATERIALIZATION_PERF_SKIPPED_MISSING_ENV` |' "${tmpdir}/summary.md"
grep -q -- '- key metrics: `reload`=`ok`, `unit`=`ok`, `preflight`=`ok`, `live`=`ok`' "${tmpdir}/summary.md"
grep -q -- '- key metrics: `run`=`12`, `failures`=`0`, `errors`=`0`' "${tmpdir}/summary.md"
grep -q -- '- key metrics: `missing`=`GS_USER GS_PASS`, `live_target`=`pharo13-gemstone37`' "${tmpdir}/summary.md"
grep -q -- '- key metrics: `connector_ms`=`1`, `clamped_ms`=`2`, `dirty_store_ms`=`3`' "${tmpdir}/summary.md"
grep -q -- '`dirty_store_transport_supported`=`1`, `dirty_store_report_shape_supported`=`1`, `dirty_store_functions_supported`=`1`, `dirty_store_oop_width`=`64`' "${tmpdir}/summary.md"
grep -q -- '- accepted exceptions:' "${tmpdir}/summary.md"
grep -q '`src/GemStone-Pharo-Tests/GciError.extension.st`' "${tmpdir}/summary.md"
grep -q '`src/GemStone-Pharo-Tests/MockGbsSession.class.st`' "${tmpdir}/summary.md"
grep -q '"code":"BOOTSTRAP_SMOKE_OK"' "${tmpdir}/summary.md"
grep -q '"code":"VERIFY_OK"' "${tmpdir}/summary.md"

bootstrap_line="$(grep -n '### bootstrap-smoke-summary.json' "${tmpdir}/summary.md" | cut -d: -f1)"
original_line="$(grep -n '### original-summary.json' "${tmpdir}/summary.md" | cut -d: -f1)"
original_drift_line="$(grep -n '### original-drift-summary.json' "${tmpdir}/summary.md" | cut -d: -f1)"
full_line="$(grep -n '### full-summary.json' "${tmpdir}/summary.md" | cut -d: -f1)"
full_lane_line="$(grep -n '### full-lane-summary.json' "${tmpdir}/summary.md" | cut -d: -f1)"
verify_line="$(grep -n '### verify-summary.json' "${tmpdir}/summary.md" | cut -d: -f1)"
live_preflight_line="$(grep -n '### live-preflight-summary.json' "${tmpdir}/summary.md" | cut -d: -f1)"
replication_line="$(grep -n '### replication-live-summary.json' "${tmpdir}/summary.md" | cut -d: -f1)"

[[ "${bootstrap_line}" -lt "${original_line}" ]]
[[ "${original_line}" -lt "${original_drift_line}" ]]
[[ "${original_drift_line}" -lt "${full_line}" ]]
[[ "${full_line}" -lt "${full_lane_line}" ]]
[[ "${full_lane_line}" -lt "${verify_line}" ]]
[[ "${verify_line}" -lt "${live_preflight_line}" ]]
[[ "${live_preflight_line}" -lt "${replication_line}" ]]

cat > "${tmpdir}/fake-vm.sh" <<'EOF'
#!/usr/bin/env bash
cat <<'OUT'
VERIFY_SUMMARY_JSON {"result":"OK","code":"VERIFY_OK","core_only":"ok","bootstrap_smoke":"ok","original":"ok","original_drift":"ok","original_tests":"ok","full":"ok","artifact_freshness":"ok","summary_renderer":"ok"}
VERIFY_SUMMARY result=OK code=VERIFY_OK core_only=ok bootstrap_smoke=ok original=ok original_drift=ok original_tests=ok full=ok artifact_freshness=ok summary_renderer=ok
OUT
EOF
chmod +x "${tmpdir}/fake-vm.sh"
: > "${tmpdir}/fake.image"

verify_output="$(
  PHARO_VM="${tmpdir}/fake-vm.sh" \
  GBS_JSON_SUMMARY=1 \
  GBS_JSON_SUMMARY_DIR="${tmpdir}/verify-json" \
  GBS_SUMMARY_FILE="${tmpdir}/verify-summary.md" \
  bash ./scripts/run_verify.sh "${tmpdir}/fake.image" "${tmpdir}"
)"
printf '%s\n' "${verify_output}"

grep -q 'VERIFY_SUMMARY result=OK code=VERIFY_OK core_only=ok bootstrap_smoke=ok original=ok original_drift=ok original_tests=ok full=ok artifact_freshness=ok summary_renderer=ok' <<< "${verify_output}"
grep -q -- '- original: `ok`' "${tmpdir}/verify-summary.md"
grep -q -- '- original-drift: `ok`' "${tmpdir}/verify-summary.md"
grep -q -- '- original-tests: `ok`' "${tmpdir}/verify-summary.md"
grep -q '"original_drift":"ok"' "${tmpdir}/verify-json/verify-summary.json"

echo "SUMMARY_RENDERER_TEST_OK"
