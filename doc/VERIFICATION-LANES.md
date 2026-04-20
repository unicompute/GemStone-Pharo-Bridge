# Verification Lanes

Generated from `BaselineOfGemStonePharo` lane contracts.

## core-only

Verify the Smalltalk core without MagLev packages.

- load group: `Core-Tests`
- targets: `GemStone-Pharo-Core-Tests`
- success markers: `ARCHITECTURE_BOUNDARY_OK`, `PACKAGE_OWNERSHIP_DRIFT_OK`, `BRIDGE_UNIT_REGRESSION_OK`, `BRIDGE_CORE_ONLY_CHECK_OK`

## compatibility-only

Verify deprecated alias coverage in isolation.

- load group: `Compatibility-Tests`
- targets: `GemStone-Pharo-Compatibility-Tests`
- success markers: `ARCHITECTURE_BOUNDARY_OK`, `PACKAGE_OWNERSHIP_DRIFT_OK`, `COMPATIBILITY_DRIFT_OK`, `BRIDGE_UNIT_REGRESSION_OK`, `BRIDGE_COMPATIBILITY_CHECK_OK`

## full

Verify the full bridge, including MagLev packages and the live GemStone lane.

- load group: `Full`
- targets: `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-Compatibility-Tests`, `GemStone-Pharo-Tests`
- success markers: `ARCHITECTURE_BOUNDARY_OK`, `PACKAGE_OWNERSHIP_DRIFT_OK`, `COMPATIBILITY_DRIFT_OK`, `BRIDGE_UNIT_REGRESSION_OK`, `BRIDGE_LIVE_REGRESSION_OK`, `CLEAN_RELOAD_AND_REGRESSION_RUN_DONE`

## artifact-freshness

Verify that the generated contract artifacts are already up to date.

- load group: `default`
- targets: `doc/PACKAGE-GRAPH.md`, `doc/PACKAGE-GRAPH.dot`, `doc/PACKAGE-GRAPH.svg`, `doc/VERIFICATION-LANES.md`, `doc/DEPRECATED-ALIASES.md`
- success markers: `CONTRACT_ARTIFACTS_FRESH_OK`

## verify

Run core-only, compatibility-only, full, then artifact-freshness.

- load group: `composite`
- targets: `core-only`, `compatibility-only`, `full`, `artifact-freshness`
- success markers: `All lane success markers above`

