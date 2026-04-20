# Testing

This repository currently has three supported verification lanes:

1. `core-only`
2. `compatibility-only`
3. `full`

The intent is:
- `core-only` proves the bridge still loads and runs as `Pharo <-> GemStone Smalltalk` without MagLev packages
- `compatibility-only` proves deprecated aliases still behave correctly, but in isolation
- `full` proves the whole bridge, including MagLev packages and the live GemStone lane

## Quick Entry Point

```bash
make help
make verify
make artifact-freshness
```

Available wrappers:

```bash
make core-only
make compatibility-only
make full
make verify
make graph-artifacts
make artifact-freshness
```

Variables accepted by the wrappers:
- `PHARO_IMAGE`
- `PHARO_WORK_DIR`
- for the live lane: `GS_USER`, `GS_PASS`, `GS_STONE`, `GS_SERVICE`, `GS_NETLDI_HOST`, `GS_NETLDI_NAME_OR_PORT`, `GEMSTONE`

## Generated Contract Artifacts

```bash
make graph-artifacts
```

This regenerates:
- [PACKAGE-GRAPH.md](./PACKAGE-GRAPH.md)
- [PACKAGE-GRAPH.dot](./PACKAGE-GRAPH.dot)
- [PACKAGE-GRAPH.svg](./PACKAGE-GRAPH.svg)
- [VERIFICATION-LANES.md](./VERIFICATION-LANES.md)
- [DEPRECATED-ALIASES.md](./DEPRECATED-ALIASES.md)

The artifact generator runs through the clean-reload path with:
- `ARCHITECTURE_BOUNDARY_OK`
- `PACKAGE_OWNERSHIP_DRIFT_OK`
- `COMPATIBILITY_DRIFT_OK`
- `GENERATED_CONTRACT_ARTIFACTS_OK`

Freshness verification uses:

```bash
make artifact-freshness
```

and succeeds with:
- `CONTRACT_ARTIFACTS_FRESH_OK`

## Core-only Lane

```bash
make core-only
```

Direct script form:

```bash
bash ./scripts/run_core_only_clean_reload.sh "/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image" "/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean"
```

This lane:
- loads `Core-Tests`
- runs only `GemStone-Pharo-Core-Tests`
- enforces the architecture boundary
- enforces the package-ownership drift guard
- enforces the core-only package/class/selector boundary

Expected success markers:
- `ARCHITECTURE_BOUNDARY_OK`
- `PACKAGE_OWNERSHIP_DRIFT_OK`
- `BRIDGE_UNIT_REGRESSION_OK`
- `BRIDGE_CORE_ONLY_CHECK_OK`

## Compatibility-only Lane

```bash
make compatibility-only
```

Direct script form:

```bash
bash ./scripts/run_compatibility_clean_reload.sh "/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image" "/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean"
```

This lane:
- loads `Compatibility-Tests`
- runs only `GemStone-Pharo-Compatibility-Tests`
- enforces the architecture boundary
- enforces the package-ownership drift guard
- enforces the compatibility drift guard

Expected success markers:
- `ARCHITECTURE_BOUNDARY_OK`
- `PACKAGE_OWNERSHIP_DRIFT_OK`
- `COMPATIBILITY_DRIFT_OK`
- `BRIDGE_UNIT_REGRESSION_OK`
- `BRIDGE_COMPATIBILITY_CHECK_OK`

## Full Lane

```bash
make full
```

Known-good local live example:

```bash
GS_USER='DataCurator' \
GS_PASS='swordfish' \
GS_NETLDI_HOST='localhost' \
GS_NETLDI_NAME_OR_PORT='50377' \
GEMSTONE='/Users/tariq/GemStone64Bit3.7.5-arm64.Darwin' \
make full
```

Direct script form:

```bash
GS_USER='DataCurator' \
GS_PASS='swordfish' \
GS_NETLDI_HOST='localhost' \
GS_NETLDI_NAME_OR_PORT='50377' \
GEMSTONE='/Users/tariq/GemStone64Bit3.7.5-arm64.Darwin' \
./scripts/run_clean_reload_and_regressions.sh "/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image" "/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean"
```

This lane:
- performs a clean reload
- runs the full unit suite
- runs a live preflight that classifies stone/netldi status, Topaz login, and GCI login
- runs the live GemStone integration suite when login env vars are set
- enforces the architecture boundary
- enforces the package-ownership drift guard
- enforces the compatibility drift guard

Expected success markers:
- `ARCHITECTURE_BOUNDARY_OK`
- `PACKAGE_OWNERSHIP_DRIFT_OK`
- `COMPATIBILITY_DRIFT_OK`
- `BRIDGE_UNIT_REGRESSION_OK`
- `BRIDGE_LIVE_REGRESSION_OK`
- `CLEAN_RELOAD_AND_REGRESSION_RUN_DONE`

## Verify Lane

```bash
make verify
```

This runs the three supported lanes in order:
1. `core-only`
2. `compatibility-only`
3. `full`

Use it when you want one command that proves package boundaries, compatibility policy, full unit coverage, and the live GemStone lane.
It also proves the generated contract artifacts are fresh.

## Compatibility Drift Policy

Compatibility-only alias coverage belongs in `GemStone-Pharo-Compatibility-Tests`.

The main test packages:
- `GemStone-Pharo-Core-Tests`
- `GemStone-Pharo-Tests`

must not drift back toward compatibility-only assertions for legacy APIs such as:
- `persistentRoot`
- `GbsPersistentRootFacade`
- `#GbsPersistentRoot`
- `GBSM root`
- `GBSM rootAt:`
- selector sends like `#persistentRoot`
- selector sends like the old `#commit` alias

If that happens, the reload lane fails with:

```text
COMPATIBILITY_DRIFT_FAILED
```

## Package Ownership Drift Policy

The reload lanes also validate representative class and selector ownership so that:
- Smalltalk core behavior stays in `GemStone-GBS-Converted` and `GemStone-GBS-Tools`
- MagLev behavior stays in `GemStone-GBS-MagLev` and `GemStone-GBS-MagLev-Tools`
- compatibility-only coverage stays out of the main active test packages

They also validate a fuller behavior inventory for split classes, so the methods locally defined on classes such as `GbsSession`, `GbsRemoteNamespaceMirror`, `GbsBrowser`, and `GbxDebuggerService` must come from an allowed package set.

If the representative ownership checks fail, the reload lane reports:

```text
PACKAGE_OWNERSHIP_DRIFT_FAILED
```

## Package Split Reference

Production:
- `GemStone-GBS-Converted`
- `GemStone-GBS-Tools`
- `GemStone-GBS-MagLev`
- `GemStone-GBS-MagLev-Tools`

Tests:
- `GemStone-Pharo-Core-Tests`
- `GemStone-Pharo-Compatibility-Tests`
- `GemStone-Pharo-Tests`

## Active Root API

The active root API is:
- `bridgeRoot`
- `#GbsBridgeRoot`
- `GbsBridgeRootFacade`

Compatibility aliases still exist, but they should stay isolated:
- `persistentRoot`
- `#GbsPersistentRoot`
- `GbsPersistentRootFacade`
- repository convenience aliases such as `root` and `rootAt:`
