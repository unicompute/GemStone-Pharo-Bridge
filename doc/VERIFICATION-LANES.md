# Verification Lanes

Generated from `GemStonePharoContract` lane contracts.

## core-only

Verify the Smalltalk core without optional MagLev production packages and without deleted legacy surface.

- load group: `Core-Tests`
- targets: `GemStone-Pharo-Core-Tests`
- success markers: `ARCHITECTURE_BOUNDARY_OK`, `PACKAGE_OWNERSHIP_DRIFT_OK`, `NO_COMPAT_SOURCE_SCAN_OK`, `NO_COMPATIBILITY_PROOF_OK`, `BRIDGE_UNIT_REGRESSION_OK`, `BRIDGE_CORE_ONLY_CHECK_OK`

## bootstrap-smoke

Prove that a clean image can micro-bootstrap the helper package and load the requested group before post-load checks run.

- load group: `Core-Tests`
- targets: `GemStonePharoReloadBootstrapper`, `GemStonePharoReloadRunner`, `GemStone-Pharo-Core-Tests`
- success markers: `CORE_ONLY_CLEAN_RELOAD_DONE`, `BOOTSTRAP_SMOKE_OK`, `BOOTSTRAP_SMOKE_DONE`

## original-tests

Verify the original/base production and original/base test layer without the generic Core or optional MagLev overlays. This lane proves the base unit layer only.

- load group: `Original-Tests`
- targets: `GemStone-Pharo-Tests`
- success markers: `ARCHITECTURE_BOUNDARY_OK`, `NO_COMPAT_SOURCE_SCAN_OK`, `NO_COMPATIBILITY_PROOF_OK`, `BRIDGE_UNIT_REGRESSION_OK`, `ORIGINAL_TESTS_CHECK_OK`

## full

Verify the steady-state developer load plus the live GemStone lane.

- load group: `Full`
- targets: `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-MagLev-Tests`, `GemStone-Pharo-Tests`
- success markers: `ARCHITECTURE_BOUNDARY_OK`, `PACKAGE_OWNERSHIP_DRIFT_OK`, `NO_COMPAT_SOURCE_SCAN_OK`, `NO_COMPATIBILITY_PROOF_OK`, `BRIDGE_UNIT_REGRESSION_OK`, `BRIDGE_LIVE_REGRESSION_OK`, `CLEAN_RELOAD_AND_REGRESSION_RUN_DONE`

## artifact-freshness

Verify that the generated contract artifacts and marker-managed doc sections are already up to date.

- load group: `default`
- targets: `README.md`, `doc/ARCHITECTURE.md`, `doc/GemStone-Pharo-Bridge-User-Manual.html`, `doc/PACKAGE-GRAPH.md`, `doc/PACKAGE-GRAPH.dot`, `doc/PACKAGE-GRAPH.svg`, `doc/LIVE-PREFLIGHT-POLICY.md`, `doc/RELOAD-POLICY.md`, `doc/TESTING.md`, `doc/USER-MANUAL-REFERENCE.html`, `doc/OWNERSHIP-CONTRACT.md`, `doc/VERIFICATION-LANES.md`
- success markers: `NO_COMPAT_SOURCE_SCAN_OK`, `CONTRACT_ARTIFACTS_FRESH_OK`

## verify

Run core-only, bootstrap-smoke, original-tests, full, artifact-freshness, then the summary-renderer smoke check.

- load group: `composite`
- targets: `core-only`, `bootstrap-smoke`, `original-tests`, `full`, `artifact-freshness`, `summary-renderer`
- success markers: `All lane success markers above`

## Expected Original-layer Test Exceptions

`make original-drift` currently reports the original/base production layer as clean and accepts only these test-layer exceptions:
- `src/GemStone-Pharo-Tests/GbsTranscriptTest.class.st`
  Keeps a pragmatic runtime-dependent transcript skip for the current live GemStone runtime.
- `src/GemStone-Pharo-Tests/MockGbsSession.class.st`
  Keeps a test-only login-failure shortcut so the restored base GbsSession production file stays clean.
