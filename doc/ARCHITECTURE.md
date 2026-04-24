# Architecture

This document is the human-facing architecture guide for the steady-state bridge. The substantive package, load-group, and guard summary below is generated from `GemStonePharoContract`.

<!-- BEGIN GENERATED:ARCHITECTURE-BODY -->
This section is generated from `GemStonePharoContract`.

## Design Goal

- `56b6db3...` original production/test packages remain the base layer
- `Pharo <-> GemStone Smalltalk` is the primary layer
- MagLev/Ruby behavior is optional
- legacy alias surface stays absent from production

## Package Layers

- original/base production: `GemStone-GBS-Converted`, `GemStone-GBS-Tools`
- generic overlay production: `GemStone-GBS-Core`, `GemStone-GBS-Core-Tools`
- optional MagLev production: `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- test layers: `GemStone-Pharo-Tests`, `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-MagLev-Tests`

## Active Root API

- `bridgeRoot`
- `#GbsBridgeRoot`
- `GbsBridgeRootFacade`

## Verification Guards

- `ARCHITECTURE_BOUNDARY_OK`
- `PACKAGE_OWNERSHIP_DRIFT_OK`
- `NO_COMPAT_SOURCE_SCAN_OK`
- `NO_COMPATIBILITY_PROOF_OK`

## Expected Original-layer Test Exceptions

The original/base production layer is clean. `make original-drift` currently reports only these accepted test-layer exceptions:
- `src/GemStone-Pharo-Tests/GbsTranscriptTest.class.st`
  Keeps a pragmatic runtime-dependent transcript skip for the current live GemStone runtime.
- `src/GemStone-Pharo-Tests/MockGbsSession.class.st`
  Keeps a test-only login-failure shortcut so the restored base GbsSession production file stays clean.

## Review Artifacts

- [PACKAGE-GRAPH.md](./PACKAGE-GRAPH.md)
- [OWNERSHIP-CONTRACT.md](./OWNERSHIP-CONTRACT.md)
- [RELOAD-POLICY.md](./RELOAD-POLICY.md)
- [LIVE-PREFLIGHT-POLICY.md](./LIVE-PREFLIGHT-POLICY.md)
<!-- END GENERATED:ARCHITECTURE-BODY -->
