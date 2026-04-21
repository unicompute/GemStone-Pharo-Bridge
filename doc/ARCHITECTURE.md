# Architecture

This document is the human-facing architecture guide for the steady-state bridge. The substantive package, load-group, and guard summary below is generated from `GemStonePharoContract`.

<!-- BEGIN GENERATED:ARCHITECTURE-BODY -->
This section is generated from `GemStonePharoContract`.

## Design Goal

- `Pharo <-> GemStone Smalltalk` is the primary layer
- MagLev/Ruby behavior is optional
- legacy alias surface stays absent from production

## Package Layers

- core production: `GemStone-GBS-Converted`, `GemStone-GBS-Tools`
- optional MagLev production: `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`
- active tests: `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-Tests`

## Active Root API

- `bridgeRoot`
- `#GbsBridgeRoot`
- `GbsBridgeRootFacade`

## Verification Guards

- `ARCHITECTURE_BOUNDARY_OK`
- `PACKAGE_OWNERSHIP_DRIFT_OK`
- `NO_COMPAT_SOURCE_SCAN_OK`
- `NO_COMPATIBILITY_PROOF_OK`

## Review Artifacts

- [PACKAGE-GRAPH.md](./PACKAGE-GRAPH.md)
- [OWNERSHIP-CONTRACT.md](./OWNERSHIP-CONTRACT.md)
- [RELOAD-POLICY.md](./RELOAD-POLICY.md)
- [LIVE-PREFLIGHT-POLICY.md](./LIVE-PREFLIGHT-POLICY.md)
<!-- END GENERATED:ARCHITECTURE-BODY -->
