# Debugging Resident GemStone Code From Pharo

This runbook covers the optional debugger tooling used to debug resident GemStone code from Pharo through GemStone-Pharo-Bridge. It is intended for development and CI evidence lanes, not production runtime loading.

## Debugger Architecture

The debugger tooling is split so production-safe bridge code stays separate from UI-heavy MagLev tools:

- `GbsRemoteCommand` and `GbsRemoteScriptBuilder` are the standard remote execution layer. They centralize command construction, literal/OOP binding, and session execution through `fetchRemoteCommand:`.
- `GbxDebuggerService` owns the live GemStone debug process: context discovery, stepping, restart/replay, breakpoint state, and compilation. Inspector-facing operations live in `GbxDebuggerInspectorController`.
- `GbsRemoteDebugger` is the Spec presenter. It wires the window, buttons, menus, and high-level user actions, while focused helpers handle stack fetching, stack navigation, source lookup, context presentation, source-pane actions, menus, inspector actions, and process control.
- `GbsRemoteExecutionDispatcher` is the only Original compatibility boundary for remote fetch fallback. Core/MagLev paths use `GbsRemoteCommand`; Original-only fallback remains isolated there.
- `GbsRemoteDebuggerSourcePaneController` owns source text rendering, source-map highlighting, caret selection, compile-error highlighting, and source editing.
- `GbsRemoteDebuggerContextPresenter` owns selected-frame presentation: source refresh, temporary variables, receiver metadata, frame metadata, and process metadata.
- Debugger lifecycle cleanup is exposed through `withRemoteDebuggerSessionDo:`. It terminates the debug process, aborts the GemStone transaction, closes the window, and reports a leaked debug process when GemStone can still see one.

Keep this tooling optional. Core/MagLev runtime groups should provide session, transaction, proxy, and command APIs; `MagLev-Tools` or `Full` should provide debugger presenters, inspectors, workspaces, and live CI evidence lanes.

## Required Environment

Set live GemStone credentials before running live debugger lanes:

```sh
export GS_USER='DataCurator'
export GS_PASS='...'
export GEMSTONE='/path/to/GemStone64Bit'
export GS_STONE='gs64stone'
export GS_SERVICE='gemstone'
export GS_NETLDI_HOST='localhost'
export GS_NETLDI_NAME_OR_PORT='netldi'
```

The scripts also accept these aliases and normalize them before preflight: `GS_USERNAME` for `GS_USER`, `GS_PASSWORD` for `GS_PASS`, `GS_HOST` for `GS_NETLDI_HOST`, and `GS_NETLDI` for `GS_NETLDI_NAME_OR_PORT`.

The lane also respects:

```sh
export GBS_JSON_SUMMARY=1
export GBS_JSON_SUMMARY_DIR="$PWD/tmp/debugger-json"
export GBS_EVIDENCE_DIR="$PWD/tmp/debugger-evidence"
export GBS_KEEP_WORK_IMAGES=1
```

Use `GBS_KEEP_WORK_IMAGES=1` only when debugging failed lanes. Otherwise the scripts delete temporary `.image` and `.changes` files automatically.

## Commands

Check whether the live environment is ready without launching Pharo:

```sh
make live-env-check
```

This emits `LIVE_ENV_SUMMARY`. If `GBS_JSON_SUMMARY=1` is set, it also writes `live-env-summary.json`.

Run the live debugger acceptance lane:

```sh
make live-debugger
```

This validates credentials, stone, and netldi first, then runs the debugger/workspace live tests. Expected evidence files are:

```text
live-debugger-preflight.log
live-debugger-regression.log
live-debugger-summary.json
```

Run the debugger performance baseline:

```sh
make debugger-perf
```

This records latency for:

```text
open debugger
stack fetch
source lookup
proxy inspection
```

Default thresholds are intentionally conservative:

```sh
export GBS_DEBUGGER_OPEN_MAX_MS=10000
export GBS_DEBUGGER_STACK_FETCH_MAX_MS=5000
export GBS_DEBUGGER_SOURCE_LOOKUP_MAX_MS=5000
export GBS_DEBUGGER_PROXY_INSPECT_MAX_MS=5000
export GBS_DEBUGGER_PERF_REGRESSION_PERCENT=50
export GBS_DEBUGGER_PERF_TRENDS="$PWD/tmp/debugger-performance-trends.jsonl"
```

Lower them after collecting stable CI baselines. `GBS_DEBUGGER_PERF_TRENDS` should point to a persisted path on the self-hosted runner if you want cross-run trend comparison. Without it, the lane still writes a JSONL sample into the evidence directory, but that directory is normally per-run.

## What The Live Lane Proves

The live lane exercises the same operational path a developer uses manually:

```smalltalk
session evaluate: '1 / 0'
```

The expected behavior is:

```text
1. GemStone raises a GbsError with a usable server process OOP.
2. GbsRemoteDebugger opens on that process.
3. Stack frames are visible.
4. Source lookup includes the faulting expression.
5. A returned GemStone proxy can be inspected safely.
6. abortTransaction removes dirty probe state.
7. debugger/session cleanup terminates the debug process and aborts dirty transaction state.
```

## Failure Modes

`LIVE_DEBUGGER_MISSING_ENV` means one or more required live variables is missing: `GS_USER`, `GS_PASS`, `GEMSTONE`, `GS_NETLDI_HOST`, or `GS_NETLDI_NAME_OR_PORT`.

`DEBUGGER_PERF_MISSING_ENV` means the same live GemStone environment is missing before collecting performance evidence.

`LIVE_DEBUGGER_PREFLIGHT_FAILED` means the credentials, stone, or netldi configuration did not pass the live preflight. Fix the GemStone connection before inspecting debugger failures.

`LIVE_DEBUGGER_RUNNER_FAILED` means the Pharo runner did not emit the expected summary line. Check `live-debugger-regression.log`.

`DEBUGGER_PERF_*_THRESHOLD_EXCEEDED` means a measured latency exceeded the configured threshold. Compare the evidence log against the previous baseline before changing code or raising limits.

## Cleanup Rules

The live tests use `withRemoteDebuggerSessionForFaultingScript:do:` so every acceptance test has an explicit cleanup boundary:

```smalltalk
self
  withRemoteDebuggerSessionForFaultingScript: '1 / 0'
  do: [ :debugger |
    self assert: (debugger instVarNamed: 'contextList') notEmpty ].
```

The cleanup boundary terminates the debugger process, verifies the process is terminated when GemStone can report it, and aborts the session transaction.

## Production Loading

Do not load debugger UI tooling in production runtime paths. Keep production on the Core/MagLev runtime groups and load MagLev-Tools or Full only in development, diagnostics, or CI evidence lanes.
