![Iceberg import](https://github.com/unicompute/GemStone-Pharo-Bridge/blob/master/doc/iceberg.png)

# GemStone-Pharo-Bridge

`GemStone-Pharo-Bridge` is a Smalltalk-first bridge between Pharo and
GemStone/S. It keeps the original GBS surface usable, adds a generic Core
overlay, and optionally loads MagLev-specific tools and runtime helpers.

Use this README for the common paths. The generated contract documents in
[`doc/`](doc/) keep the full load matrix, package graph, verification lanes, and
ownership rules.

<!-- BEGIN GENERATED:README-BODY -->
## Quick Start

Load the MagLev production stack from a local checkout:

```smalltalk
Metacello new
  baseline: 'GemStonePharo';
  repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
  load: 'MagLev'.
```

Load the same stack from GitHub:

```smalltalk
Metacello new
  baseline: 'GemStonePharo';
  repository: 'github://unicompute/GemStone-Pharo-Bridge:maglev/src';
  load: 'MagLev'.
```

Use `load: 'MagLev-Tools'` for interactive developer tooling, including
the GemStone workspace, remote debugger, inspectors, transcript, ObjectLog,
and MagLev-aware method browsers. Use `load: 'Full'` when you also want
the developer/test stack, including the MagLev-aware test packages.

## Load Groups

- `Original`: original/base production packages only
- `Original-Tests`: original/base production plus original/base tests
- `Core`, `Core-Tools`, `Core-Tests`: original/base plus the generic Smalltalk overlay
- `MagLev`: production MagLev runtime, excluding debugger/tool UI packages
- `MagLev-Tools`: MagLev runtime plus workspace, debugger, inspectors, ObjectLog, and developer UI tools
- `Full`: full developer stack, including all tests

The active root API is `bridgeRoot`, `#GbsBridgeRoot`, and
`GbsBridgeRootFacade`.

See [doc/LOAD-MATRIX.md](doc/LOAD-MATRIX.md) for exact group membership and
[doc/PACKAGE-GRAPH.md](doc/PACKAGE-GRAPH.md) for package ownership.

## Clean Switching

Use a fresh image or the clean-reload scripts when switching between Original,
Core, and MagLev loads. Do not incrementally load `Original` and then `MagLev`
into the same already-mutated image.

Common entry points:

```bash
make original PHARO_IMAGE="..." PHARO_WORK_DIR="..."
make original-tests PHARO_IMAGE="..." PHARO_WORK_DIR="..."
make full PHARO_IMAGE="..." PHARO_WORK_DIR="..." GS_USER=... GS_PASS=... GS_NETLDI_HOST=... GS_NETLDI_NAME_OR_PORT=... GEMSTONE=...
make verify PHARO_IMAGE="..." PHARO_WORK_DIR="..."
```

## Session Examples

The classic GBS session style still works:

```smalltalk
| session dict |
session := GbsSessionParameters new
            name: 'Simple Session';
            gemStoneName: 'gs64stone';
            username: 'DataCurator';
            password: '...';
            login.

dict := Dictionary new.
dict at: 'name' put: 'Tariq'.
dict at: 'amount' put: 100.
dict at: 'currency' put: 'GBP'.

session userGlobals at: #MyTestDict put: dict.
session commit.

session disconnect.
```

For new code, prefer the bridge root and explicit transaction behavior:

```smalltalk
| session payload |
session := GbsSessionParameters new
    name: 'MagLev Session';
    gemStoneName: 'gs64stone';
    username: 'DataCurator';
    password: '...';
    netldiHostOrIp: 'localhost';
    netldiNameOrPort: '50377';
    login.

[
    payload := Dictionary new
        at: 'name' put: 'Tariq';
        at: 'amount' put: 100;
        at: 'currency' put: 'GBP';
        yourself.

    session bridgeRoot at: #MyTestDict put: payload.
    session commitTransactionOrSignalConflict
] ensure: [
    session disconnect
].
```

Prefer `commitTransactionOrSignalConflict` or
`commitTransactionWithRetryCount:` over the older `commit` alias when you want
explicit transaction behavior.

## Verification

- `make core-only`: verify the Smalltalk core without optional MagLev packages
- `make original`: prove the original/base production layer reloads cleanly
- `make original-tests`: verify original/base production plus original/base tests
- `make full`: run the full developer load and live GemStone lane when credentials are present
- `make verify`: run all maintained lanes and artifact freshness checks

The live lanes use `GS_USER`, `GS_PASS`, `GS_STONE`, `GS_SERVICE`,
`GS_NETLDI_HOST`, `GS_NETLDI_NAME_OR_PORT`, and `GEMSTONE` when supplied.

## More Documentation

- [doc/MAGLEV-BRANCH-USAGE.md](doc/MAGLEV-BRANCH-USAGE.md): practical MagLev load and session examples
- [doc/LOAD-MATRIX.md](doc/LOAD-MATRIX.md): load groups and switch recipes
- [doc/VERIFICATION-LANES.md](doc/VERIFICATION-LANES.md): maintained verification lanes
- [doc/ARCHITECTURE.md](doc/ARCHITECTURE.md): architecture notes
- [doc/OWNERSHIP-CONTRACT.md](doc/OWNERSHIP-CONTRACT.md): package and selector ownership contract
- [doc/RELOAD-POLICY.md](doc/RELOAD-POLICY.md): reload policy and generated-artifact expectations
<!-- END GENERATED:README-BODY -->
