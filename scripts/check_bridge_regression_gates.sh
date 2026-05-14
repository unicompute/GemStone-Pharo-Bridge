#!/usr/bin/env bash
set -euo pipefail

failures=0

fail() {
  printf 'BRIDGE_REGRESSION_GATE_FAIL %s\n' "$*" >&2
  failures=$((failures + 1))
}

line_count() {
  wc -l < "$1" | tr -d ' '
}

check_max_lines() {
  local file="$1"
  local max="$2"
  local label="$3"
  local count
  count="$(line_count "${file}")"
  printf 'BRIDGE_SIZE_GATE %s lines=%s max=%s file=%s\n' "${label}" "${count}" "${max}" "${file}"
  if (( count > max )); then
    fail "${label} line count ${count} exceeds ${max}: ${file}"
  fi
}

check_max_lines "src/GemStone-GBS-Tools/GbsRemoteDebugger.class.st" 1500 "GbsRemoteDebugger"
check_max_lines "src/GemStone-GBS-Tools/GbxDebuggerService.class.st" 1500 "GbxDebuggerService"
check_max_lines "src/GemStone-GBS-Core/GbsSession.extension.st" 1000 "GbsSessionCoreExtension"
check_max_lines "src/GemStone-GBS-Core/GbsSessionCommandExecutor.class.st" 200 "GbsSessionCommandExecutor"
check_max_lines "src/GemStone-GBS-Core/GbsSessionNamedObjectRegistry.class.st" 250 "GbsSessionNamedObjectRegistry"
check_max_lines "src/GemStone-GBS-Core/GbsSessionTransactionCoordinator.class.st" 200 "GbsSessionTransactionCoordinator"
check_max_lines "src/GemStone-GBS-Core/GbsSessionMaterializer.class.st" 400 "GbsSessionMaterializer"
check_max_lines "src/GemStone-GBS-Core/GbsSessionLoginCoordinator.class.st" 200 "GbsSessionLoginCoordinator"
check_max_lines "src/GemStone-GBS-Core/GbsSessionScriptMarshaller.class.st" 100 "GbsSessionScriptMarshaller"
check_max_lines "src/BaselineOfGemStonePharo/GemStonePharoContract.class.st" 600 "GemStonePharoContract"
check_max_lines "src/BaselineOfGemStonePharo/GemStonePharoDocRenderer.class.st" 1200 "GemStonePharoDocRenderer"
check_max_lines "src/BaselineOfGemStonePharo/GemStonePharoPackageContract.class.st" 900 "GemStonePharoPackageContract"
check_max_lines "src/BaselineOfGemStonePharo/GemStonePharoVerificationContract.class.st" 200 "GemStonePharoVerificationContract"

if rg -n "doesNotUnderstand:" \
  src/BaselineOfGemStonePharo/GemStonePharoDocRenderer.class.st \
  src/BaselineOfGemStonePharo/GemStonePharoPackageContract.class.st \
  src/BaselineOfGemStonePharo/GemStonePharoVerificationContract.class.st >/tmp/gbs-dnu-gate.$$; then
  cat /tmp/gbs-dnu-gate.$$
  fail "contract helper doesNotUnderstand: forwarding reappeared"
fi
rm -f /tmp/gbs-dnu-gate.$$

if rg -n "legacyCompileLookup|legacyCompileResponseForSource|legacyCorrectedCompileResponseForSource|legacyRecompileResponseForSource" src >/tmp/gbs-legacy-gate.$$; then
  cat /tmp/gbs-legacy-gate.$$
  fail "active legacy compile aliases reappeared; use compatibility* selectors"
fi
rm -f /tmp/gbs-legacy-gate.$$

if rg -n "fetchScriptUsingOriginalCompatibility:" src | grep -v "src/GemStone-GBS-Tools/GbsRemoteExecutionDispatcher.class.st" >/tmp/gbs-original-boundary-gate.$$; then
  cat /tmp/gbs-original-boundary-gate.$$
  fail "Original compatibility remote-execution fallback moved outside GbsRemoteExecutionDispatcher"
fi
rm -f /tmp/gbs-original-boundary-gate.$$

raw_script_count="$(
  { rg -n "evaluate: \\(String streamContents:|executeAndFetch: \\(String streamContents:|executeScriptAndFetchObject: \\(String streamContents:|executeScriptAndReturnOop: \\(String streamContents:" \
      src/GemStone-GBS-Core \
      src/GemStone-GBS-Core-Tools \
      src/GemStone-GBS-Tools \
      src/GemStone-GBS-MagLev \
      src/GemStone-GBS-MagLev-Tools || true; } \
    | wc -l | tr -d ' '
)"
printf 'BRIDGE_RAW_SCRIPT_GATE count=%s max=0\n' "${raw_script_count}"
if (( raw_script_count > 0 )); then
  fail "raw String streamContents remote script sites reappeared"
fi

if rg -n "rootScript|containerScript|ensuringContainerScript|associationsScript|atScriptFor:|atPutScriptFor:|ensureNamespaceScriptFor:|includesKeyScriptFor:|keysScript|namespaceExistsScriptFor:|removeKeyScriptFor:|sizeScript" \
  src/GemStone-GBS-Core/GbsRepositoryRootFacade.class.st \
  src/GemStone-GBS-Core/GbsSymbolDictionaryFacade.class.st \
  src/GemStone-GBS-Core/GbsBridgeRootFacade.class.st >/tmp/gbs-core-facade-helper-gate.$$; then
  cat /tmp/gbs-core-facade-helper-gate.$$
  fail "legacy Core facade script-helper method reappeared; use typed GbsRemoteCommand constructors"
fi
rm -f /tmp/gbs-core-facade-helper-gate.$$

if rg -n "executeScriptAndFetchObject: \\(self|executeScriptAndReturnOop: \\(self|executeScriptAndFetchObject: .*Script|executeScriptAndReturnOop: .*Script" \
  src/GemStone-GBS-Core/GbsRepositoryRootFacade.class.st \
  src/GemStone-GBS-Core/GbsSymbolDictionaryFacade.class.st \
  src/GemStone-GBS-Core/GbsBridgeRootFacade.class.st >/tmp/gbs-core-facade-execution-gate.$$; then
  cat /tmp/gbs-core-facade-execution-gate.$$
  fail "Core facade direct self-built script execution reappeared; use fetchRemoteCommand:/returnRemoteCommandOop:"
fi
rm -f /tmp/gbs-core-facade-execution-gate.$$

if rg -n "loadedClassesIncludingModulesScript|objectsInMemoryScript|referencesToScriptFor|sessionStateAtScriptFor|sessionStateAtPutScriptFor|allSubclassesScriptFor|instancesInMemoryScriptFor|countInstancesScriptFor|instanceOopsScriptFor|classExpressionFor:" \
  src/GemStone-GBS-Core/GbsObjectSpaceFacade.class.st \
  src/GemStone-GBS-Core/GbsObjectSpaceRepositoryFacade.class.st >/tmp/gbs-object-space-helper-gate.$$; then
  cat /tmp/gbs-object-space-helper-gate.$$
  fail "legacy ObjectSpace script-helper method reappeared; use typed GbsRemoteCommand constructors"
fi
rm -f /tmp/gbs-object-space-helper-gate.$$

if rg -n "executeScriptAndFetchObject:|executeScriptAndReturnOop:|marshalArgumentToScript:" \
  src/GemStone-GBS-Core/GbsObjectSpaceFacade.class.st \
  src/GemStone-GBS-Core/GbsObjectSpaceRepositoryFacade.class.st >/tmp/gbs-object-space-execution-gate.$$; then
  cat /tmp/gbs-object-space-execution-gate.$$
  fail "ObjectSpace direct remote script execution reappeared; use fetchRemoteCommand:/typed GbsRemoteCommand"
fi
rm -f /tmp/gbs-object-space-execution-gate.$$

if rg -n "classExpressionFor:|listInstanceOopsScript|migrateChunkScriptForOops:|executeScriptAndFetchObject:|marshalArgumentToScript:" \
  src/GemStone-GBS-Core/GbsChunkedMigrationRunner.class.st >/tmp/gbs-chunked-migration-script-gate.$$; then
  cat /tmp/gbs-chunked-migration-script-gate.$$
  fail "Chunked migration reintroduced script helper/direct execution; use class-reference GbsRemoteCommand helpers"
fi
rm -f /tmp/gbs-chunked-migration-script-gate.$$

if rg -n "versionEntriesScript|executeScriptAndFetchObject:|classExpressionFor:" \
  src/GemStone-GBS-Core/GbsClassHistoryFacade.class.st >/tmp/gbs-class-history-script-gate.$$; then
  cat /tmp/gbs-class-history-script-gate.$$
  fail "Class history facade reintroduced version-entry script helper/direct execution; use class-reference GbsRemoteCommand helpers"
fi
rm -f /tmp/gbs-class-history-script-gate.$$

if rg -n "loadedClassesScript|migrateInstancesScript|previewMigrationScript|methodReferenceStringsScript|classMetadataScript|methodMetadataScript|versionEntriesScript|protocolEntriesScript|namespaceMirrorEntriesScript" \
  src/GemStone-GBS-Core/GbsRepositoryFacade.class.st \
  src/GemStone-GBS-Core/GbsRemoteClassMirror.class.st \
  src/GemStone-GBS-Core/GbsRemoteMethodMirror.class.st \
  src/GemStone-GBS-Core/GbsRemoteNamespaceMirror.class.st >/tmp/gbs-core-repository-mirror-helper-gate.$$; then
  cat /tmp/gbs-core-repository-mirror-helper-gate.$$
  fail "legacy Repository/mirror script-helper method reappeared; use typed GbsRemoteCommand constructors"
fi
rm -f /tmp/gbs-core-repository-mirror-helper-gate.$$

if rg -n "constantEntriesScript|namespaceMetadataScript|compatibilityScript: self constantEntriesScript" \
  src/GemStone-GBS-Core/GbsRemoteNamespaceMirror.class.st \
  src/GemStone-GBS-MagLev/GbsRemoteNamespaceMirror.extension.st >/tmp/gbs-namespace-shim-gate.$$; then
  cat /tmp/gbs-namespace-shim-gate.$$
  fail "namespace mirror script shim reappeared; fetch command bodies through fetchNamespaceBody:/GbsRemoteCommand"
fi
rm -f /tmp/gbs-namespace-shim-gate.$$

if rg -n "executeScriptAndFetchObject:|executeScriptAndReturnOop:|marshalArgumentToScript:" \
  src/GemStone-GBS-Core/GbsRepositoryFacade.class.st \
  src/GemStone-GBS-Core/GbsRemoteClassMirror.class.st \
  src/GemStone-GBS-Core/GbsRemoteMethodMirror.class.st \
  src/GemStone-GBS-Core/GbsRemoteNamespaceMirror.class.st >/tmp/gbs-core-repository-mirror-execution-gate.$$; then
  cat /tmp/gbs-core-repository-mirror-execution-gate.$$
  fail "Repository/mirror direct remote script execution reappeared; use fetchRemoteCommand:/typed GbsRemoteCommand"
fi
rm -f /tmp/gbs-core-repository-mirror-execution-gate.$$

if rg -n "associationsScript|atScriptFor:|atPutScriptFor:|includesKeyScriptFor:|keysScript|removeKeyScriptFor:|rootScript|executeScriptAndFetchObject:|marshalArgumentToScript:" \
  src/GemStone-GBS-MagLev/GbsMaglevSymbolDictionaryFacade.class.st >/tmp/gbs-maglev-symbol-dictionary-script-gate.$$; then
  cat /tmp/gbs-maglev-symbol-dictionary-script-gate.$$
  fail "MagLev symbol dictionary facade reintroduced script helper/direct execution; use typed GbsRemoteCommand constructors"
fi
rm -f /tmp/gbs-maglev-symbol-dictionary-script-gate.$$

if rg -n "addEntryScriptUsingSelector|entriesScript|executeScriptAndFetchObject:|marshalArgumentToScript:" \
  src/GemStone-GBS-MagLev/GbsObjectLogFacade.class.st >/tmp/gbs-maglev-object-log-script-gate.$$; then
  cat /tmp/gbs-maglev-object-log-script-gate.$$
  fail "MagLev ObjectLog facade reintroduced script helper/direct execution; use typed GbsRemoteCommand constructors"
fi
rm -f /tmp/gbs-maglev-object-log-script-gate.$$

if rg -n "evaluationScriptFor|bindingScriptForBody|executeScriptAndFetchObject:|executeScriptAndReturnOop:|marshalArgumentToScript:" \
  src/GemStone-GBS-MagLev/GbsRemoteBindingObject.class.st >/tmp/gbs-maglev-binding-script-gate.$$; then
  cat /tmp/gbs-maglev-binding-script-gate.$$
  fail "MagLev binding object reintroduced script helper/direct execution; use typed GbsRemoteCommand constructors"
fi
rm -f /tmp/gbs-maglev-binding-script-gate.$$

if rg -n "metadataScript|executeScriptAndFetchObject:" \
  src/GemStone-GBS-MagLev/GbsRemoteProcObject.class.st >/tmp/gbs-maglev-proc-script-gate.$$; then
  cat /tmp/gbs-maglev-proc-script-gate.$$
  fail "MagLev remote proc object reintroduced metadata script/direct execution; use typed GbsRemoteCommand constructors"
fi
rm -f /tmp/gbs-maglev-proc-script-gate.$$

if rg -n "marshalArgumentToScript:|String streamContents:|executeAndFetchObjectIn:|executeAndReturnOopIn:" \
  src/GemStone-GBS-MagLev/GbsRcHash.class.st \
  src/GemStone-GBS-MagLev/GbsRcQueue.class.st \
  src/GemStone-GBS-MagLev/GbsRcCounter.class.st \
  src/GemStone-GBS-MagLev/GbsMaglevRuntimeProxy.class.st >/tmp/gbs-maglev-rc-wrapper-script-gate.$$; then
  cat /tmp/gbs-maglev-rc-wrapper-script-gate.$$
  fail "MagLev Rc wrapper/base proxy reintroduced argument interpolation or direct command execution; use bound GbsRemoteCommand/session helpers"
fi
rm -f /tmp/gbs-maglev-rc-wrapper-script-gate.$$

if rg -n "executeScriptAndFetchObject:|executeScriptAndReturnOop:|marshalArgumentToScript:|String streamContents:" \
  src/GemStone-GBS-MagLev/GbsRemoteNamespaceMirror.extension.st >/tmp/gbs-maglev-namespace-autoload-script-gate.$$; then
  cat /tmp/gbs-maglev-namespace-autoload-script-gate.$$
  fail "MagLev namespace autoload mirror reintroduced direct script builders/execution; use namespace-scoped GbsRemoteCommand helpers"
fi
rm -f /tmp/gbs-maglev-namespace-autoload-script-gate.$$

if rg -n "executeScriptAndFetchObject:|executeScriptAndReturnOop:|executeAndFetchObjectIn:|executeAndReturnOopIn:" \
  src/GemStone-GBS-MagLev/GbsSession.extension.st >/tmp/gbs-maglev-session-direct-execution-gate.$$; then
  cat /tmp/gbs-maglev-session-direct-execution-gate.$$
  fail "MagLev session facade reintroduced direct remote execution; use fetchRemoteCommand:/returnRemoteCommandOop:"
fi
rm -f /tmp/gbs-maglev-session-direct-execution-gate.$$

if rg -n "executeAndFetchObjectIn:|executeAndReturnOopIn:|executeScriptAndFetchObject:|executeScriptAndReturnOop:" \
  src/GemStone-GBS-MagLev/GbsSharedCounter.class.st \
  src/GemStone-GBS-MagLev/GbsRemoteMethodObject.extension.st >/tmp/gbs-maglev-small-wrapper-direct-execution-gate.$$; then
  cat /tmp/gbs-maglev-small-wrapper-direct-execution-gate.$$
  fail "MagLev small wrappers reintroduced direct command execution; use session command helpers"
fi
rm -f /tmp/gbs-maglev-small-wrapper-direct-execution-gate.$$

if rg -n "correctedCompileScriptForSource|recompileScriptForSource|executeCompileScript:|escapedSourceText:|marshalArgumentToScript:|classExpression" \
  src/GemStone-GBS-Core/GbsRemoteUnboundMethodObject.class.st >/tmp/gbs-core-unbound-method-script-gate.$$; then
  cat /tmp/gbs-core-unbound-method-script-gate.$$
  fail "Remote unbound method compile path reintroduced script construction; use repository class-reference commands"
fi
rm -f /tmp/gbs-core-unbound-method-script-gate.$$

if rg -n "levelValue asString|escapedName|fallbackText|session evaluate: \\(self fullSourceFallback|executeScriptAndReturnOop: \\(self remoteScriptBuilder|executeScriptAndFetchObject: \\(self remoteScriptBuilder" \
  src/GemStone-GBS-Core/GbsRemoteDebugProcessFacade.class.st \
  src/GemStone-GBS-Core/GbsSession.extension.st >/tmp/gbs-core-bound-debug-session-gate.$$; then
  cat /tmp/gbs-core-bound-debug-session-gate.$$
  fail "Core debug/session helper reintroduced direct value interpolation; use bound GbsRemoteCommand helpers"
fi
rm -f /tmp/gbs-core-bound-debug-session-gate.$$

if rg -n "String streamContents:" \
  src/GemStone-GBS-Core/GbsRepositoryFacade.class.st \
  src/GemStone-GBS-Core/GbsRemoteClassMirror.class.st \
  src/GemStone-GBS-Core/GbsRemoteMethodMirror.class.st >/tmp/gbs-core-repository-mirror-stream-gate.$$; then
  cat /tmp/gbs-core-repository-mirror-stream-gate.$$
  fail "Repository/class/method mirrors reintroduced String streamContents script builders"
fi
rm -f /tmp/gbs-core-repository-mirror-stream-gate.$$

if rg -l "executeAndFetch:" \
  src/GemStone-GBS-Core \
  src/GemStone-GBS-MagLev \
  | grep -vxF "src/GemStone-GBS-Core/GbsRemoteCommand.class.st" >/tmp/gbs-core-direct-fetch-gate.$$; then
  cat /tmp/gbs-core-direct-fetch-gate.$$
  fail "direct executeAndFetch: appeared in Core/MagLev outside GbsRemoteCommand; use command/session helpers"
fi
rm -f /tmp/gbs-core-direct-fetch-gate.$$

if rg -n "executeAndFetch:" \
  src/GemStone-GBS-Tools/GbsRemoteDebugger*.class.st \
  src/GemStone-GBS-Tools/GbxDebugger*.class.st >/tmp/gbs-debugger-direct-fetch-gate.$$; then
  cat /tmp/gbs-debugger-direct-fetch-gate.$$
  fail "direct executeAndFetch: reappeared in debugger service/controller paths; use GbsRemoteCommand"
fi
rm -f /tmp/gbs-debugger-direct-fetch-gate.$$

if rg -n "String streamContents:|executeDebugScript:" \
  src/GemStone-GBS-Tools/GbxDebuggerProcessController.class.st \
  src/GemStone-GBS-Tools/GbxDebuggerRestartController.class.st >/tmp/gbs-debugger-controller-command-gate.$$; then
  cat /tmp/gbs-debugger-controller-command-gate.$$
  fail "debugger restart/process controllers reintroduced raw script builders; use GbsRemoteExecutionDispatcher bound command APIs"
fi
rm -f /tmp/gbs-debugger-controller-command-gate.$$

if rg -l "executeAndFetch:" \
  src/GemStone-GBS-Tools \
  src/GemStone-GBS-Core-Tools \
  src/GemStone-GBS-MagLev-Tools \
  | grep -vxF "src/GemStone-GBS-Tools/GbsRemoteExecutionDispatcher.class.st" >/tmp/gbs-tool-direct-fetch-gate.$$; then
  cat /tmp/gbs-tool-direct-fetch-gate.$$
  fail "direct executeAndFetch: appeared in a tool package outside GbsRemoteExecutionDispatcher; use GbsRemoteCommand"
fi
rm -f /tmp/gbs-tool-direct-fetch-gate.$$

if rg -n "GbsRemoteCommand script:|remoteCommand:" \
  src/GemStone-GBS-Tools \
  src/GemStone-GBS-Core-Tools \
  src/GemStone-GBS-MagLev-Tools >/tmp/gbs-tool-freeform-command-gate.$$; then
  cat /tmp/gbs-tool-freeform-command-gate.$$
  fail "free-form GbsRemoteCommand script usage appeared in tool paths; use bound command APIs or GbsRemoteExecutionDispatcher compatibility"
fi
rm -f /tmp/gbs-tool-freeform-command-gate.$$

if rg -n "executeScriptAndReturnOop:|apiGciExecuteStr:" \
  src/GemStone-GBS-Tools/GbsPlaygroundActions.class.st \
  src/GemStone-GBS-Tools/GbsWorkspace.class.st \
  src/GemStone-GBS-Core-Tools/GbsPlaygroundActions.extension.st \
  src/GemStone-GBS-Core-Tools/GbsWorkspace.extension.st >/tmp/gbs-workspace-execution-api-gate.$$; then
  cat /tmp/gbs-workspace-execution-api-gate.$$
  fail "workspace/playground inspect path bypassed executeWorkspaceScriptAndReturnOop:"
fi
rm -f /tmp/gbs-workspace-execution-api-gate.$$

if rg -n "instVarNamed:" \
  src/GemStone-GBS-Tools/GbsRemoteDebuggerUiController.class.st \
  src/GemStone-GBS-Tools/GbxDebuggerServicePresenter.class.st \
  src/GemStone-GBS-Tools/GbsRemoteDebuggerStackNavigator.class.st \
  src/GemStone-GBS-Tools/GbsRemoteDebuggerContextPresenter.class.st >/tmp/gbs-debugger-helper-ivar-gate.$$; then
  cat /tmp/gbs-debugger-helper-ivar-gate.$$
  fail "debugger helper classes reintroduced instVarNamed: coupling; use explicit presenter/controller APIs"
fi
rm -f /tmp/gbs-debugger-helper-ivar-gate.$$

if (( failures > 0 )); then
  printf 'BRIDGE_REGRESSION_GATES_FAIL failures=%s\n' "${failures}" >&2
  exit 1
fi

printf 'BRIDGE_REGRESSION_GATES_OK\n'
