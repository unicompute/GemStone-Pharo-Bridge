# Original Compatibility Boundary

The bridge keeps the `Original` and `Original-Tests` load groups working for base-layer compatibility, but Core and MagLev tooling must not drift back into Original-only fallback execution.

## Allowed Fallback Point

`GbsRemoteExecutionDispatcher class >> fetchScriptUsingOriginalCompatibility:in:context:` is the explicit fallback boundary.

That method exists because the `Original` load group intentionally omits `GbsRemoteCommand`. When Core is loaded, callers should go through `fetchScript:in:context:` or `fetchCommandBody:literalBindings:oopBindings:in:context:` so the dispatcher uses `GbsRemoteCommand` through `fetchRemoteCommand:context:`.

## Rules

- New debugger, workspace, browser, inspector, and MagLev tooling should prefer `GbsRemoteCommand` or a facade that dispatches through it.
- Direct `executeAndFetch:` in debugger service/controller paths is forbidden by `make regression-gates`.
- Direct `executeAndFetch:` in tool packages is allowed only inside `GbsRemoteExecutionDispatcher`; all browser, inspector, workspace, launcher, and presenter tools must route through `GbsRemoteCommand` via the dispatcher.
- Raw `String streamContents:` remote-script execution in Core, tool, and MagLev paths is forbidden by `make regression-gates`.
- Compatibility selectors should be named `compatibility*`, not `legacy*`, when they remain active behavior.
- Do not add new Original fallback methods outside `GbsRemoteExecutionDispatcher` without updating this document and the regression gate.

## CI Enforcement

Run:

```sh
make regression-gates
```

The gate verifies debugger size targets, raw script execution patterns, active legacy alias names, contract helper forwarding, and debugger direct-fetch regressions.

The current size gates are:

```text
GbsRemoteDebugger <= 1700 lines
GbxDebuggerService <= 1700 lines
```

The next planned gates are:

```text
GbsRemoteDebugger <= 1500 lines
GbxDebuggerService <= 1500 lines
```
