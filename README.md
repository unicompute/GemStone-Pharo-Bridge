![Icebeg import](https://github.com/unicompute/GemStone-Pharo-Bridge/blob/master/doc/iceberg.png)

# GemStone-Pharo-Bridge

`GemStone-Pharo-Bridge` is now structured as a Smalltalk-first bridge between Pharo and GemStone/S.

The codebase has an explicit split between:
- core `Pharo <-> GemStone Smalltalk`
- optional MagLev/Ruby extensions
- compatibility-only test coverage for older API aliases

## Package Layout

Production packages:
- `GemStone-GBS-Converted`
  Smalltalk core bridge, repository access, session transport, generic mirrors, core facades, and tools-facing support
- `GemStone-GBS-Tools`
  generic Pharo tools and presenters for the Smalltalk core
- `GemStone-GBS-MagLev`
  optional MagLev/Ruby runtime surface: runtime loading, autoload, proc/binding support, ObjectLog, RC wrappers, MagLev facades
- `GemStone-GBS-MagLev-Tools`
  optional MagLev/Ruby tool integration

Test packages:
- `GemStone-Pharo-Core-Tests`
  Smalltalk-core tests only
- `GemStone-Pharo-Compatibility-Tests`
  compatibility-only tests for deprecated aliases such as `persistentRoot` and `commit`
- `GemStone-Pharo-Tests`
  active full bridge tests, including MagLev-aware behavior

## Root API Policy

The active root API is:
- `bridgeRoot`
- `#GbsBridgeRoot`
- `GbsBridgeRootFacade`

Compatibility aliases still exist:
- `persistentRoot`
- `#GbsPersistentRoot`
- `GbsPersistentRootFacade`
- repository convenience aliases such as `root` and `rootAt:`

Those compatibility names are intentionally not part of the active Smalltalk-core API shape anymore.

## Baseline Groups

Defined in [src/BaselineOfGemStonePharo/BaselineOfGemStonePharo.class.st](src/BaselineOfGemStonePharo/BaselineOfGemStonePharo.class.st):

- `Core-Only`
  loads only `GemStone-GBS-Converted`
- `Core`
  loads the Smalltalk core plus generic tools
- `Core-Tools`
  explicit generic-tools-capable core load
- `Core-Tests`
  loads the Smalltalk core plus `GemStone-GBS-Tools` and `GemStone-Pharo-Core-Tests`
- `Compatibility-Tests`
  loads compatibility coverage on top of core and MagLev support
- `MagLev-Core`
  loads the optional MagLev runtime layer without MagLev-specific tools
- `MagLev-Tools`
  loads the optional MagLev runtime plus MagLev-specific tool integration
- `MagLev`
  compatibility alias for the MagLev runtime plus tool layer
- `Tools`
  compatibility alias for the generic tools-capable load
- `All-Tests`
  loads all test packages without changing production-group intent
- `Tests`
  compatibility alias for all test packages
- `Full`
  explicit full developer load
- `default`
  compatibility alias for `Full`

## Verification Lanes

The quickest entry points are now:

```bash
make help
make verify
make graph-artifacts
make artifact-freshness
```

A shorter lane-focused reference also lives in [doc/TESTING.md](doc/TESTING.md).

A package-boundary reference also lives in [doc/ARCHITECTURE.md](doc/ARCHITECTURE.md).

Generated contract artifacts live in:
- [doc/PACKAGE-GRAPH.md](doc/PACKAGE-GRAPH.md)
- [doc/PACKAGE-GRAPH.dot](doc/PACKAGE-GRAPH.dot)
- [doc/PACKAGE-GRAPH.svg](doc/PACKAGE-GRAPH.svg)
- [doc/VERIFICATION-LANES.md](doc/VERIFICATION-LANES.md)
- [doc/DEPRECATED-ALIASES.md](doc/DEPRECATED-ALIASES.md)

### 1. Core-only lane

Use this to verify that the bridge still loads as `Pharo <-> GemStone Smalltalk` without the MagLev packages:

```bash
make core-only
```

Equivalent direct script form:

```bash
bash ./scripts/run_core_only_clean_reload.sh "/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image" "/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean"
```

This lane:
- loads `Core-Tests`
- enforces the architecture boundary
- enforces the package-ownership drift guard
- enforces the core-only absence checks
- runs only `GemStone-Pharo-Core-Tests`

### 2. Compatibility-only lane

Use this to verify deprecated alias coverage in isolation:

```bash
make compatibility-only
```

Equivalent direct script form:

```bash
bash ./scripts/run_compatibility_clean_reload.sh "/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image" "/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean"
```

This lane:
- loads `Compatibility-Tests`
- enforces the architecture boundary
- enforces the package-ownership drift guard
- runs only `GemStone-Pharo-Compatibility-Tests`
- enforces the compatibility drift guard

### 3. Full unit/live lane

Use this to verify the complete bridge, including MagLev packages and the live GemStone integration lane:

```bash
make full
```

That runs the full lane and only enables the live integration pass when the GemStone login env vars are set.

Example with the known-good local live settings:

```bash
GS_USER='DataCurator' \
GS_PASS='swordfish' \
GS_NETLDI_HOST='localhost' \
GS_NETLDI_NAME_OR_PORT='50377' \
GEMSTONE='/Users/tariq/GemStone64Bit3.7.5-arm64.Darwin' \
make full
```

This lane:
- performs a fresh clean reload
- enforces the architecture boundary
- enforces the package-ownership drift guard
- enforces the compatibility drift guard
- runs a live preflight that classifies stone/netldi status, Topaz login, and GCI login before the live test suite
- runs the full unit suite
- runs the live GemStone integration suite when login env vars are present

`make verify` runs the three supported lanes in order, then checks generated artifact freshness:
- `core-only`
- `compatibility-only`
- `full`
- `artifact-freshness`

## Generated Contract Artifacts

Use this when you want the current baseline contract rendered as reviewable docs:

```bash
make graph-artifacts
make artifact-freshness
```

`make graph-artifacts` regenerates:
- [doc/PACKAGE-GRAPH.md](doc/PACKAGE-GRAPH.md)
- [doc/PACKAGE-GRAPH.dot](doc/PACKAGE-GRAPH.dot)
- [doc/PACKAGE-GRAPH.svg](doc/PACKAGE-GRAPH.svg)
- [doc/VERIFICATION-LANES.md](doc/VERIFICATION-LANES.md)
- [doc/DEPRECATED-ALIASES.md](doc/DEPRECATED-ALIASES.md)

The generator runs through the same clean-reload script that enforces:
- `ARCHITECTURE_BOUNDARY_OK`
- `PACKAGE_OWNERSHIP_DRIFT_OK`
- `COMPATIBILITY_DRIFT_OK`

`make artifact-freshness` verifies that those generated files are already up to date and fails with:
- `CONTRACT_ARTIFACTS_FRESH_FAILED`

## Compatibility Drift Policy

The clean reload script enforces a boundary:
- `GemStone-Pharo-Core-Tests` and `GemStone-Pharo-Tests` must not drift back to compatibility-only root aliases
- compatibility-only root assertions belong in `GemStone-Pharo-Compatibility-Tests`
- staged retirement of the remaining aliases is tracked in [doc/DEPRECATED-ALIASES.md](doc/DEPRECATED-ALIASES.md)

The current drift guard blocks:
- textual references such as `persistentRoot`, `GbsPersistentRootFacade`, and `#GbsPersistentRoot`
- selector sends like `#persistentRoot` and the older `#commit` alias
- broader alias snippets such as `GBSM root`, `GBSM rootAt:`, `smalltalk root`, and `maglev root`

If one of those is added back to the wrong package, the reload lane fails with:
- `COMPATIBILITY_DRIFT_FAILED`

## Ownership And Boundary Guards

The reload lanes also enforce:
- `ARCHITECTURE_BOUNDARY_OK`
- `PACKAGE_OWNERSHIP_DRIFT_OK`

The package-ownership guard checks representative classes and selectors so that:
- core behavior stays in `GemStone-GBS-Converted` and `GemStone-GBS-Tools`
- MagLev behavior stays in `GemStone-GBS-MagLev` and `GemStone-GBS-MagLev-Tools`
- compatibility-only coverage stays out of the active test packages

It also checks a fuller behavior inventory for split classes such as `GbsSession`, `GbsRemoteNamespaceMirror`, `GbsBrowser`, and `GbxDebuggerService`, so every locally defined method on those behaviors must come from an allowed package.

## Live GemStone Notes

Known-good local live settings:

```bash
GS_USER='DataCurator'
GS_PASS='swordfish'
GS_NETLDI_HOST='localhost'
GS_NETLDI_NAME_OR_PORT='50377'
GEMSTONE='/Users/tariq/GemStone64Bit3.7.5-arm64.Darwin'
```

The full lane has explicit support for:
- `GS_STONE`
- `GS_SERVICE`
- `GS_NETLDI_HOST`
- `GS_NETLDI_NAME_OR_PORT`

## Current Intent

The project direction is:
- keep the Smalltalk core loadable and testable without MagLev
- keep MagLev/Ruby features as optional extension packages
- keep deprecated aliases explicit, narrow, and isolated
