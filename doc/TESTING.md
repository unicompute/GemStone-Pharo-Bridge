# Testing

This guide keeps only the minimal hand-written entry context. The lane descriptions, guard list, and artifact references below are generated from `GemStonePharoContract`.

<!-- BEGIN GENERATED:TESTING-BODY -->
This section is generated from `GemStonePharoContract`.

## Verification Entry Points

- `core-only`
  Verify the Smalltalk core without optional MagLev production packages and without deleted legacy surface.
  load group: `Core-Tests`
  targets: `GemStone-Pharo-Core-Tests`
  success markers: `ARCHITECTURE_BOUNDARY_OK`, `PACKAGE_OWNERSHIP_DRIFT_OK`, `NO_COMPAT_SOURCE_SCAN_OK`, `NO_COMPATIBILITY_PROOF_OK`, `BRIDGE_UNIT_REGRESSION_OK`, `BRIDGE_CORE_ONLY_CHECK_OK`
- `bootstrap-smoke`
  Prove that a clean image can micro-bootstrap the helper package and load the requested group before post-load checks run.
  load group: `Core-Tests`
  targets: `GemStonePharoReloadBootstrapper`, `GemStonePharoReloadRunner`, `GemStone-Pharo-Core-Tests`
  success markers: `CORE_ONLY_CLEAN_RELOAD_DONE`, `BOOTSTRAP_SMOKE_OK`, `BOOTSTRAP_SMOKE_DONE`
- `full`
  Verify the steady-state developer load plus the live GemStone lane.
  load group: `Full`
  targets: `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-Tests`
  success markers: `ARCHITECTURE_BOUNDARY_OK`, `PACKAGE_OWNERSHIP_DRIFT_OK`, `NO_COMPAT_SOURCE_SCAN_OK`, `NO_COMPATIBILITY_PROOF_OK`, `BRIDGE_UNIT_REGRESSION_OK`, `BRIDGE_LIVE_REGRESSION_OK`, `CLEAN_RELOAD_AND_REGRESSION_RUN_DONE`
- `artifact-freshness`
  Verify that the generated contract artifacts and marker-managed doc sections are already up to date.
  load group: `default`
  targets: `README.md`, `doc/ARCHITECTURE.md`, `doc/GemStone-Pharo-Bridge-User-Manual.html`, `doc/PACKAGE-GRAPH.md`, `doc/PACKAGE-GRAPH.dot`, `doc/PACKAGE-GRAPH.svg`, `doc/LIVE-PREFLIGHT-POLICY.md`, `doc/RELOAD-POLICY.md`, `doc/TESTING.md`, `doc/USER-MANUAL-REFERENCE.html`, `doc/OWNERSHIP-CONTRACT.md`, `doc/VERIFICATION-LANES.md`
  success markers: `NO_COMPAT_SOURCE_SCAN_OK`, `CONTRACT_ARTIFACTS_FRESH_OK`
- `verify`
  Run core-only, bootstrap-smoke, full, artifact-freshness, then the summary-renderer smoke check.
  load group: `composite`
  targets: `core-only`, `bootstrap-smoke`, `full`, `artifact-freshness`, `summary-renderer`
  success markers: `All lane success markers above`

## Wrapper Entry Points

```bash
make help
make core-only
make full
make verify
make graph-artifacts
make artifact-freshness
```

Top-level verify sequencing is owned by `GemStonePharoVerifyRunner`. Requested unit/live/preflight orchestration within the full lane is owned by `GemStonePharoVerificationRunner` and can run in the same process as the clean reload proof.

Accepted environment variables:
- `GBS_LOAD_GROUP`
  Metacello load group to reload before post-load checks run. Defaults to `default`.
- `GBS_RELOAD_CHECK_MODE`
  Reload proof mode. Defaults to `default` and supports `core-only`.
- `GBS_VERIFY_LANE`
  Optional verification lane to run in the same Smalltalk process after the reload proof. Supports `core-only` and `full`.
- `GBS_GENERATE_CONTRACT_ARTIFACTS`
  When `1`, regenerate the contract-driven documentation after reload.
- `GBS_VERIFY_CONTRACT_ARTIFACTS`
  When `1`, verify that the contract-driven documentation is already fresh.
- `GS_USER`
  GemStone login user used by both the Topaz and GCI probes.
- `GS_PASS`
  GemStone login password used by both the Topaz and GCI probes.
- `GS_STONE`
  Optional stone name override. Defaults to `gs64stone`.
- `GS_SERVICE`
  Optional service name override. Defaults to `gemnetobject`.
- `GS_NETLDI_HOST`
  Optional explicit host for netldi routing.
- `GS_NETLDI_NAME_OR_PORT`
  Optional explicit netldi name or port, for example `gs64ldi` or `50377`.
- `GEMSTONE`
  Optional explicit GemStone client home used by the GCI probe.

## Generated Contract Artifacts

- [PACKAGE-GRAPH.md](./PACKAGE-GRAPH.md)
- [PACKAGE-GRAPH.dot](./PACKAGE-GRAPH.dot)
- [PACKAGE-GRAPH.svg](./PACKAGE-GRAPH.svg)
- [LIVE-PREFLIGHT-POLICY.md](./LIVE-PREFLIGHT-POLICY.md)
- [RELOAD-POLICY.md](./RELOAD-POLICY.md)
- [USER-MANUAL-REFERENCE.html](./USER-MANUAL-REFERENCE.html)
- [OWNERSHIP-CONTRACT.md](./OWNERSHIP-CONTRACT.md)
- [VERIFICATION-LANES.md](./VERIFICATION-LANES.md)

## Machine-readable Summaries

- set `GBS_JSON_SUMMARY=1` to emit JSON summaries from the lane scripts and `make verify`
- set `GBS_JSON_SUMMARY_DIR=/path/to/output` to persist per-lane JSON files

## Steady-state Guards

- `ARCHITECTURE_BOUNDARY_OK`
  Package graph, load-group membership, and forbidden reverse dependencies match the contract.
- `PACKAGE_OWNERSHIP_DRIFT_OK`
  Representative class, selector, and split-behavior ownership stay in their allowed packages.
- `NO_COMPAT_SOURCE_SCAN_OK`
  Deleted legacy surface is absent from the active source roots, scripts, and selected docs.
- `NO_COMPATIBILITY_PROOF_OK`
  Deleted package, class, selector, and method-package ownership surface is absent from the loaded image.

The active root API throughout the test and reload lanes is `bridgeRoot`.
<!-- END GENERATED:TESTING-BODY -->
