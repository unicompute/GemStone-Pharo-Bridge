# Architecture

This document describes the current package boundary and layering model for `GemStone-Pharo-Bridge`.

Generated contract artifacts that mirror this document live in:
- [PACKAGE-GRAPH.md](./PACKAGE-GRAPH.md)
- [PACKAGE-GRAPH.dot](./PACKAGE-GRAPH.dot)
- [PACKAGE-GRAPH.svg](./PACKAGE-GRAPH.svg)
- [VERIFICATION-LANES.md](./VERIFICATION-LANES.md)
- [DEPRECATED-ALIASES.md](./DEPRECATED-ALIASES.md)

## Design Goal

The bridge is now organized around a Smalltalk-first core:

- `Pharo <-> GemStone Smalltalk` is the primary architectural layer
- MagLev/Ruby behavior is an optional extension layer
- deprecated aliases are isolated in a compatibility test layer

That means:
- the core must load and test without MagLev packages
- MagLev features should not leak back into the core by default
- compatibility coverage should stay explicit and narrow

## Package Layers

### Core production

- `GemStone-GBS-Converted`
  - session transport
  - repository access
  - generic mirrors
  - root facades
  - object-space and wrapper lifecycle support
  - generic bridge behavior
- `GemStone-GBS-Tools`
  - generic Pharo tools and presenters
  - tool-side extension points
  - Smalltalk-core workflows

### Optional MagLev production

- `GemStone-GBS-MagLev`
  - Ruby runtime loading and provenance
  - namespace autoload
  - proc / exec-block / binding support
  - ObjectLog
  - RC wrappers and MagLev runtime proxies
  - MagLev facade and convenience entry points
- `GemStone-GBS-MagLev-Tools`
  - MagLev-specific browser, debugger, workspace, namespace, and inspector actions
  - presenter extensions for the optional runtime layer

### Test layers

- `GemStone-Pharo-Core-Tests`
  - Smalltalk-core-only tests
- `GemStone-Pharo-Compatibility-Tests`
  - compatibility-only alias tests
- `GemStone-Pharo-Tests`
  - active full bridge tests, including MagLev-aware behavior

## Dependency Direction

The intended direction is:

```text
GemStone-GBS-Converted
  -> GemStone-GBS-Tools
  -> GemStone-Pharo-Core-Tests

GemStone-GBS-Converted
  -> GemStone-GBS-MagLev
  -> GemStone-GBS-MagLev-Tools

GemStone-Pharo-Core-Tests
  -> GemStone-Pharo-Compatibility-Tests
  -> GemStone-Pharo-Tests
```

Important constraints:
- `GemStone-GBS-Converted` must not require MagLev packages
- `GemStone-GBS-Tools` should stay generic and use extension points rather than MagLev-named hooks
- `GemStone-Pharo-Core-Tests` should not assert compatibility-only aliases

## Baseline Groups

Defined in `BaselineOfGemStonePharo`:

- `Core-Only`
  strict core load for boundary checks
- `Core`
  Smalltalk core plus generic tools
- `Core-Tools`
  explicit generic-tools-capable core load
- `Core-Tests`
  Smalltalk-core verification lane
- `Compatibility-Tests`
  compatibility-only verification lane
- `MagLev-Core`
  optional MagLev runtime without MagLev-specific tools
- `MagLev-Tools`
  MagLev runtime plus MagLev-specific tool integration
- `MagLev`
  compatibility alias for the MagLev production stack
- `Tools`
  compatibility alias for the generic tools-capable load
- `All-Tests`
  all test packages
- `Tests`
  compatibility alias for all test packages
- `Full`
  explicit full developer load
- `default`
  compatibility alias for `Full`

## Active API vs Compatibility API

### Active root API

The active root API is:
- `bridgeRoot`
- `#GbsBridgeRoot`
- `GbsBridgeRootFacade`

This is the preferred Smalltalk-core surface.

### Compatibility aliases

Older names still exist:
- `persistentRoot`
- `#GbsPersistentRoot`
- `GbsPersistentRootFacade`
- the older `commit` alias
- repository convenience aliases such as `root` and `rootAt:`

These are compatibility surfaces, not active architecture.

## Extension Model

The generic tools no longer call `respondsTo: #addMaglev...` style hooks directly.

Instead:
- core tools define neutral extension points
- MagLev packages implement those extension points
- the core remains loadable without the optional layer

This keeps `GemStone-GBS-Tools` generic while still allowing MagLev-specific UI actions.

## Root Policy

Repository and root behavior now center on `bridgeRoot`.

The bridge currently keeps compatibility with the old root key by aliasing:
- primary: `#GbsBridgeRoot`
- compatibility alias: `#GbsPersistentRoot`

New code should target `bridgeRoot`.

## Compatibility Policy

Compatibility-only assertions belong in:
- `GemStone-Pharo-Compatibility-Tests`

They should not drift into:
- `GemStone-Pharo-Core-Tests`
- `GemStone-Pharo-Tests`

The clean reload script enforces this boundary with a compatibility drift guard that checks:
- textual references to legacy root names
- selector sends like `#persistentRoot`
- selector sends like the old `#commit` alias
- broader alias snippets such as `GBSM root`, `GBSM rootAt:`, `smalltalk root`, and `maglev root`

The staged retirement plan for the remaining aliases lives in:
- [DEPRECATED-ALIASES.md](./DEPRECATED-ALIASES.md)

## Architecture And Ownership Guards

The clean reload script also enforces:
- `ARCHITECTURE_BOUNDARY_OK`
- `PACKAGE_OWNERSHIP_DRIFT_OK`

The architecture guard verifies:
- expected `requires:` edges for the documented package layers
- expected load-group membership, including dependency closure for the active lane
- absence of forbidden reverse dependencies

The ownership guard verifies representative class and selector ownership so that:
- core classes and selectors remain in `GemStone-GBS-Converted` or `GemStone-GBS-Tools`
- MagLev classes and selectors remain in `GemStone-GBS-MagLev` or `GemStone-GBS-MagLev-Tools`
- compatibility-only coverage stays out of the active test layers
- broader core package scans catch MagLev class/selector drift without flagging valid core autoload helpers

It also enforces a fuller behavior inventory for split behaviors. For classes extended across packages, such as `GbsSession`, `GbsSmalltalkFacade`, `GbsRemoteNamespaceMirror`, `GbsBrowser`, `GbsRemoteDebugger`, and `GbxDebuggerService`, every locally defined method must belong to one of the explicitly allowed packages for that behavior.

## Verification Model

There are four supported entry points:

1. `core-only`
2. `compatibility-only`
3. `full`
4. `artifact-freshness`
5. `verify`

`verify` runs the first four in order.

See:
- [README.md](../README.md)
- [TESTING.md](./TESTING.md)

## What Belongs In Core

Examples of core responsibilities:
- session login and GCI transport
- repository access
- generic method/class/namespace mirrors
- generic tool presenters
- generic symbol dictionary access
- `bridgeRoot`

## What Belongs In MagLev

Examples of MagLev responsibilities:
- Ruby runtime load path and loaded-feature behavior
- autoload semantics
- ObjectLog
- proc / binding / exec-block behavior
- RC wrappers and MagLev runtime proxies
- `SessionMethods`
- MagLev-specific menus, reports, and presenters

## Current Boundary Rule Of Thumb

When adding code:

- if it makes sense for plain GemStone Smalltalk, keep it in core
- if it depends on Ruby/MagLev semantics, keep it in the MagLev packages
- if it only protects older names or older call patterns, keep it in compatibility tests
