# Ownership Contract

Generated from `GemStonePharoContract` ownership, lane, and no-compatibility contracts.

## Regression Lane Policy

- `all`
  label: `BRIDGE_REGRESSION`
  selection: `all`
  live lane: `false`
- `unit`
  label: `BRIDGE_UNIT_REGRESSION`
  selection: `excludeIntegration`
  live lane: `false`
- `live`
  label: `BRIDGE_LIVE_REGRESSION`
  selection: `onlyIntegration`
  live lane: `true`

- integration protocols: `integration tests`

## Ownership Families

- `convertedOnly` -> `GemStone-GBS-Converted`
- `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `coreTestsOnly` -> `GemStone-Pharo-Core-Tests`
- `maglevOnly` -> `GemStone-GBS-MagLev`
- `maglevToolsOnly` -> `GemStone-GBS-MagLev-Tools`
- `toolsOnly` -> `GemStone-GBS-Tools`
- `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`

## Split Behavior Ownership

- `GbsBridgeRootFacade` instance side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsBrowser` instance side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsClassicLauncher` instance side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsFinalizerRegistrySessionStateSlot` instance side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsInspector` instance side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsMaglevFacade` instance side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsMaglevRuntimeProxy` instance side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsMethodQueryResultsPresenter` instance side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsNamespaceScopedMethodQuery` instance side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsNamespacesPresenter` instance side -> `maglevToolsOnly` -> `GemStone-GBS-MagLev-Tools`
- `GbsObjectSpaceDiagnosticsFacade` instance side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsObjectSpaceFacade` instance side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsObjectLogEntry` instance side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsObjectLogFacade` instance side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsRemoteAutoloadMirror` instance side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsRemoteClassMirror` instance side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsRemoteConstantMirror` instance side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsRemoteDebugger` instance side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsRemoteMethodMirror` instance side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsRemoteMethodObject` instance side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror` instance side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsRepositoryFacade` instance side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsRepositoryRootFacade` instance side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsRubyRuntimeFacade` instance side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsSession` instance side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsSmalltalkFacade` instance side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbxActivationTest` instance side -> `coreTestsOnly` -> `GemStone-Pharo-Core-Tests`
- `GciErrorTest` instance side -> `coreTestsOnly` -> `GemStone-Pharo-Core-Tests`
- `GbsStructuredValueInspectorPresenter` instance side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsSymbolListBrowserPresenter` instance side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsWorkspace` instance side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbxDebuggerService` instance side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbxTrippy` instance side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsBridgeRootFacade` class side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsBrowser` class side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsClassicLauncher` class side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsFinalizerRegistrySessionStateSlot` class side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsInspector` class side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsMaglevFacade` class side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsMaglevRuntimeProxy` class side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsMethodQueryResultsPresenter` class side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsNamespaceScopedMethodQuery` class side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsNamespacesPresenter` class side -> `maglevToolsOnly` -> `GemStone-GBS-MagLev-Tools`
- `GbsObjectSpaceDiagnosticsFacade` class side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsObjectSpaceFacade` class side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsObjectLogEntry` class side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsObjectLogFacade` class side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsRemoteAutoloadMirror` class side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsRemoteClassMirror` class side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsRemoteConstantMirror` class side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsRemoteDebugger` class side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsRemoteMethodMirror` class side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsRemoteMethodObject` class side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror` class side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsRepositoryFacade` class side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsRepositoryRootFacade` class side -> `convertedOnly` -> `GemStone-GBS-Converted`
- `GbsRubyRuntimeFacade` class side -> `maglevOnly` -> `GemStone-GBS-MagLev`
- `GbsSession` class side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsSmalltalkFacade` class side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbxActivationTest` class side -> `coreTestsOnly` -> `GemStone-Pharo-Core-Tests`
- `GciErrorTest` class side -> `coreTestsOnly` -> `GemStone-Pharo-Core-Tests`
- `GbsStructuredValueInspectorPresenter` class side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsSymbolListBrowserPresenter` class side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbsWorkspace` class side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbxDebuggerService` class side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GbxTrippy` class side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`
- `GBSM` class side -> `convertedWithMaglev` -> `GemStone-GBS-Converted`, `GemStone-GBS-MagLev`
- `GbsPlaygroundActions` class side -> `toolsWithMaglevTools` -> `GemStone-GBS-Tools`, `GemStone-GBS-MagLev-Tools`

## Explicit Class Ownership

- `GbsRemoteUnboundMethodObject` -> `GemStone-GBS-Converted`
- `GbsRcCounter` -> `GemStone-GBS-MagLev`
- `GbsRcHash` -> `GemStone-GBS-MagLev`
- `GbsRcQueue` -> `GemStone-GBS-MagLev`
- `GbsSharedCounter` -> `GemStone-GBS-MagLev`
- `GbsGsObject` -> `GemStone-GBS-MagLev`
- `GbsGsDictionary` -> `GemStone-GBS-MagLev`
- `GbxExecBlock` -> `GemStone-GBS-MagLev`
- `GbxExecBlock0` -> `GemStone-GBS-MagLev`
- `GbxExecBlock1` -> `GemStone-GBS-MagLev`
- `GbxExecBlock2` -> `GemStone-GBS-MagLev`
- `GbxExecBlock3` -> `GemStone-GBS-MagLev`
- `GbxExecBlock4` -> `GemStone-GBS-MagLev`
- `GbxExecBlock5` -> `GemStone-GBS-MagLev`
- `GbxExecBlockN` -> `GemStone-GBS-MagLev`
- `GbsStDBbadAtRuby` -> `GemStone-GBS-MagLev`
- `GbsStDBnoRuby` -> `GemStone-GBS-MagLev`
- `GbsErrRubySystemExitErr` -> `GemStone-GBS-MagLev`

## Explicit Selector Ownership

- `GbsSession>>#bridgeRoot` -> `GemStone-GBS-Converted`
- `GbsSession>>#commitTransactionWithRetryCount:` -> `GemStone-GBS-Converted`
- `GbsSession>>#objectSpaceDiagnostics` -> `GemStone-GBS-Converted`
- `GbsSmalltalkFacade>>#bridgeRoot` -> `GemStone-GBS-Converted`
- `GbsRemoteNamespaceMirror>>#constantEntries` -> `GemStone-GBS-Converted`
- `GbsRemoteMethodMirror>>#asMethodObject` -> `GemStone-GBS-Converted`
- `GbsRemoteMethodMirror>>#asUnboundMethodObject` -> `GemStone-GBS-Converted`
- `GbsRemoteClassMirror>>#methodObjectAt:` -> `GemStone-GBS-Converted`
- `GbsRemoteClassMirror>>#classMethodObjectAt:` -> `GemStone-GBS-Converted`
- `GbsNamespaceScopedMethodQuery>>#methodObjectForReference:` -> `GemStone-GBS-Converted`
- `GbsNamespaceScopedMethodQuery>>#methodObjects` -> `GemStone-GBS-Converted`
- `GbsBrowser>>#browseNamedObjectCacheReport` -> `GemStone-GBS-Tools`
- `GbsInspector>>#browseTypedWrapperLifecycleReport` -> `GemStone-GBS-Tools`
- `GbsMethodQueryResultsPresenter>>#browseObjectsInMemoryReport` -> `GemStone-GBS-Tools`
- `GbxDebuggerService>>#basicReenterServerContext` -> `GemStone-GBS-Tools`
- `GbsSession>>#objectLog` -> `GemStone-GBS-MagLev`
- `GbsSession>>#sessionMethods` -> `GemStone-GBS-MagLev`
- `GbsSession>>#materializeMaglevRuntimeValue:` -> `GemStone-GBS-MagLev`
- `GbsSession>>#gsDictionaryForOop:` -> `GemStone-GBS-MagLev`
- `GbsSession>>#gsObjectForOop:` -> `GemStone-GBS-MagLev`
- `GbsSession>>#rcCounterForOop:` -> `GemStone-GBS-MagLev`
- `GbsSession>>#rcHashForOop:` -> `GemStone-GBS-MagLev`
- `GbsSession>>#rcQueueForOop:` -> `GemStone-GBS-MagLev`
- `GbsSession>>#rubyRuntime` -> `GemStone-GBS-MagLev`
- `GbsSmalltalkFacade>>#objectLog` -> `GemStone-GBS-MagLev`
- `GbsObjectSpaceFacade>>#maglevFinalizerRegistry` -> `GemStone-GBS-MagLev`
- `GbsObjectSpaceDiagnosticsFacade>>#maglevFinalizerRegistry` -> `GemStone-GBS-MagLev`
- `GbsObjectSpaceDiagnosticsFacade>>#finalizerRegistryReport` -> `GemStone-GBS-MagLev`
- `GbsObjectSpaceDiagnosticsFacade>>#finalizerRegistrySlot` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#autoloadMirrors` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#autoloadEntries` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#autoloadFileFor:` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#loadFileNamed:` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#loadedFeatures` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#loadPath` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#persistentLoadedFeatures` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#registerAutoload:file:` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#removeAutoload:` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#requireFileNamed:` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#retryAutoload:` -> `GemStone-GBS-MagLev`
- `GbsRemoteNamespaceMirror>>#supportsAutoload` -> `GemStone-GBS-MagLev`
- `GbsRemoteConstantMirror>>#autoloadFile` -> `GemStone-GBS-MagLev`
- `GbsRemoteConstantMirror>>#isAutoload` -> `GemStone-GBS-MagLev`
- `GbsBrowser>>#addExtensionSessionMenuItemsTo:` -> `GemStone-GBS-MagLev-Tools`
- `GbsBrowser>>#browseRubyLoadPathReport` -> `GemStone-GBS-MagLev-Tools`
- `GbsClassicLauncher>>#addExtensionSessionMenuItemsTo:` -> `GemStone-GBS-MagLev-Tools`
- `GbsInspector>>#addExtensionReportOptionsToLabels:actions:` -> `GemStone-GBS-MagLev-Tools`
- `GbsMethodQueryResultsPresenter>>#addExtensionSessionMenuItemsTo:` -> `GemStone-GBS-MagLev-Tools`
- `GbsRemoteDebugger>>#addExtensionMethodMenuItemsTo:` -> `GemStone-GBS-MagLev-Tools`
- `GbsRemoteDebugger>>#addExtensionSessionMenuItemsTo:` -> `GemStone-GBS-MagLev-Tools`
- `GbsRemoteDebugger>>#browseRubyLoadPathReport` -> `GemStone-GBS-MagLev-Tools`
- `GbsWorkspace>>#addExtensionWorkspaceMenuItemsTo:` -> `GemStone-GBS-MagLev-Tools`
- `GbsStructuredValueInspectorPresenter>>#addExtensionEntryMenuItemsTo:` -> `GemStone-GBS-MagLev-Tools`
- `GbsSymbolListBrowserPresenter>>#addExtensionEntryMenuItemsTo:` -> `GemStone-GBS-MagLev-Tools`
- `GbsSymbolListBrowserPresenter>>#addExtensionPreviewMenuItemsTo:` -> `GemStone-GBS-MagLev-Tools`
- `GbsSymbolListBrowserPresenter>>#configureExtensionStructuredInspector:` -> `GemStone-GBS-MagLev-Tools`
- `GbxTrippy>>#addExtensionReportOptionsToLabels:actions:` -> `GemStone-GBS-MagLev-Tools`

## No-compatibility Static Scan

Production source roots:
- `src/GemStone-GBS-Converted`
- `src/GemStone-GBS-Tools`
- `src/GemStone-GBS-MagLev`
- `src/GemStone-GBS-MagLev-Tools`

Secondary source files:
- `.github/workflows/verify.yml`
- `README.md`
- `doc/ARCHITECTURE.md`
- `doc/GemStone-Pharo-Bridge-User-Manual.html`
- `doc/LIVE-PREFLIGHT-POLICY.md`
- `doc/PACKAGE-GRAPH.dot`
- `doc/PACKAGE-GRAPH.md`
- `doc/PACKAGE-GRAPH.svg`
- `doc/RELOAD-POLICY.md`
- `doc/TESTING.md`
- `doc/USER-MANUAL-REFERENCE.html`
- `doc/VERIFICATION-LANES.md`
- `Makefile`
- `scripts/lane_common.sh`
- `scripts/check_bootstrap_smoke_group.st`
- `scripts/generate_contract_artifacts.st`
- `scripts/micro_bootstrap_reload.st`
- `scripts/probe_live_login.st`
- `scripts/run_all_package_regressions.st`
- `scripts/run_bootstrap_smoke.sh`
- `scripts/run_clean_reload_and_regressions.sh`
- `scripts/run_core_only_clean_reload.sh`
- `scripts/run_generate_contract_artifacts.sh`
- `scripts/run_live_preflight.sh`
- `scripts/run_live_preflight_via_runner.st`
- `scripts/render_lane_json_summaries.sh`
- `scripts/test_render_lane_json_summaries.sh`
- `scripts/run_verify.sh`
- `scripts/run_verify_via_runner.st`
- `scripts/run_verify_contract_artifacts.sh`

Representative forbidden snippets:
- `GbsPersistentRootFacade`
- `GbsRootCompatibilityTest`
- `GemStone-GBS-Compatibility`
- `GemStone-Pharo-Compatibility-Tests`
- `persistentRoot`
- `rootAt:`
