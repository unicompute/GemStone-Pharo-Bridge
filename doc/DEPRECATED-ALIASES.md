# Deprecated Aliases

Generated from `BaselineOfGemStonePharo` deprecated alias contracts.

| Alias | Replacement | Stage | Removal plan |
| --- | --- | --- | --- |
| `GbsSession>>commit` | `commitTransaction` | `compatibility-only` | Warn on use now; remove after another stable window. |
| `GbsSession>>persistentRoot` | `bridgeRoot` | `compatibility-only` | Warn on use now; keep only for compatibility callers. |
| `GbsSession>>root` | `repository root` | `compatibility-only` | Warn on use now; active tests must not call it. |
| `GbsSession>>rootAt:` | `repository rootAt:` | `compatibility-only` | Warn on use now; active tests must not call it. |
| `GbsSession>>rootAt:ifAbsent:` | `repository rootAt:ifAbsent:` | `compatibility-only` | Warn on use now; active tests must not call it. |
| `GbsSession>>rootAt:put:` | `repository rootAt:put:` | `compatibility-only` | Warn on use now; active tests must not call it. |
| `GbsSmalltalkFacade>>root` | `bridgeRoot` | `compatibility-only` | Warn on use now; keep only for compatibility callers. |
| `GbsSmalltalkFacade>>persistentRoot` | `bridgeRoot` | `compatibility-only` | Warn on use now; keep only for compatibility callers. |
| `GbsMaglevFacade>>root` | `bridgeRoot` | `compatibility-only` | Warn on use now; keep only for compatibility callers. |
| `GbsMaglevFacade>>persistentRoot` | `bridgeRoot` | `compatibility-only` | Warn on use now; keep only for compatibility callers. |
| `GBSM class>>persistentRoot` | `bridgeRoot` | `compatibility-only` | Warn on use now; keep only for compatibility callers. |
| `GBSM class>>root` | `repository root` | `compatibility-only` | Warn on use now; active tests must not call it. |
| `GBSM class>>rootAt:` | `repository rootAt:` | `compatibility-only` | Warn on use now; active tests must not call it. |
| `GBSM class>>rootAt:ifAbsent:` | `repository rootAt:ifAbsent:` | `compatibility-only` | Warn on use now; active tests must not call it. |
| `GBSM class>>rootAt:put:` | `repository rootAt:put:` | `compatibility-only` | Warn on use now; active tests must not call it. |
| `GbsPersistentRootFacade` | `GbsBridgeRootFacade` | `legacy-compatibility-class` | Keep only until selector aliases are retired. |
| `#GbsPersistentRoot` | `#GbsBridgeRoot` | `legacy-compatibility-key` | Keep only until the compatibility facade is retired. |
