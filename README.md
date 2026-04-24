![Icebeg import](https://github.com/unicompute/GemStone-Pharo-Bridge/blob/master/doc/iceberg.png)

# GemStone-Pharo-Bridge

`GemStone-Pharo-Bridge` is a Smalltalk-first bridge between Pharo and GemStone/S.

The summary below is generated from `GemStonePharoContract`. Refresh it with `make graph-artifacts`, and use `make verify` to prove the repo, load groups, and generated docs are still in sync.

<!-- BEGIN GENERATED:README-BODY -->
## Steady-state Contract Summary

This section is generated from `GemStonePharoContract` and rewritten by `make graph-artifacts`.

### Package Layout

- original/base production: `GemStone-GBS-Converted`, `GemStone-GBS-Tools`
- generic overlay production: `GemStone-GBS-Core`, `GemStone-GBS-Core-Tools`
- optional MagLev production: `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- test layers: `GemStone-Pharo-Tests`, `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-MagLev-Tests`

### Active Root API

- `bridgeRoot`
- `#GbsBridgeRoot`
- `GbsBridgeRootFacade`

### Baseline Groups

- `Original`, `Original-Tests`
- `Core-Only`, `Core`, `Core-Tools`, `Core-Tests`
- `MagLev-Core`, `MagLev-Tools`, `MagLev`
- `Tools`, `All-Tests`, `Tests`, `Full`, `default`

See [doc/PACKAGE-GRAPH.md](doc/PACKAGE-GRAPH.md) for the exact package graph and group membership.

### Verification Lanes

Top-level `make verify` sequencing is owned by `GemStonePharoVerifyRunner`; lane-local unit/live/preflight execution is owned by `GemStonePharoVerificationRunner`.

- `core-only`
  Verify the Smalltalk core without optional MagLev production packages and without deleted legacy surface.
  load group: `Core-Tests`
- `bootstrap-smoke`
  Prove that a clean image can micro-bootstrap the helper package and load the requested group before post-load checks run.
  load group: `Core-Tests`
- `original-tests`
  Verify the original/base production and original/base test layer without the generic Core or optional MagLev overlays. This lane proves the base unit layer only.
  load group: `Original-Tests`
- `full`
  Verify the steady-state developer load plus the live GemStone lane.
  load group: `Full`
- `artifact-freshness`
  Verify that the generated contract artifacts and marker-managed doc sections are already up to date.
  load group: `default`
- `verify`
  Run core-only, bootstrap-smoke, original-tests, full, artifact-freshness, then the summary-renderer smoke check.
  load group: `composite`

### Expected Original-layer Test Exceptions

`make original-drift` reports the original/base production layer as clean and currently accepts only these test-layer exceptions:
- `src/GemStone-Pharo-Tests/GbsTranscriptTest.class.st`
  Keeps a pragmatic runtime-dependent transcript skip for the current live GemStone runtime.
- `src/GemStone-Pharo-Tests/MockGbsSession.class.st`
  Keeps a test-only login-failure shortcut so the restored base GbsSession production file stays clean.

### Generated Contract Artifacts

Standalone generated artifacts:
- [doc/PACKAGE-GRAPH.md](doc/PACKAGE-GRAPH.md)
- [doc/PACKAGE-GRAPH.dot](doc/PACKAGE-GRAPH.dot)
- [doc/PACKAGE-GRAPH.svg](doc/PACKAGE-GRAPH.svg)
- [doc/LIVE-PREFLIGHT-POLICY.md](doc/LIVE-PREFLIGHT-POLICY.md)
- [doc/RELOAD-POLICY.md](doc/RELOAD-POLICY.md)
- [doc/USER-MANUAL-REFERENCE.html](doc/USER-MANUAL-REFERENCE.html)
- [doc/OWNERSHIP-CONTRACT.md](doc/OWNERSHIP-CONTRACT.md)
- [doc/VERIFICATION-LANES.md](doc/VERIFICATION-LANES.md)

In-place generated doc sections:
- [`README.md`](README.md)
- [`doc/TESTING.md`](doc/TESTING.md)
- [`doc/ARCHITECTURE.md`](doc/ARCHITECTURE.md)
- [`doc/GemStone-Pharo-Bridge-User-Manual.html`](doc/GemStone-Pharo-Bridge-User-Manual.html)

### Boundary Guards

- `ARCHITECTURE_BOUNDARY_OK`
  Package graph, load-group membership, and forbidden reverse dependencies match the contract.
- `PACKAGE_OWNERSHIP_DRIFT_OK`
  Representative class, selector, and split-behavior ownership stay in their allowed packages.
- `NO_COMPAT_SOURCE_SCAN_OK`
  Deleted legacy surface is absent from the active source roots, scripts, and selected docs.
- `NO_COMPATIBILITY_PROOF_OK`
  Deleted package, class, selector, and method-package ownership surface is absent from the loaded image.

CI uses the same steady-state gate through `make verify` in `.github/workflows/verify.yml`.
<!-- END GENERATED:README-BODY -->
