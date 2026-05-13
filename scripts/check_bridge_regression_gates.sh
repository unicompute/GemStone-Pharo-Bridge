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

if rg -n "loadedClassesIncludingModulesScript|objectsInMemoryScript|referencesToScriptFor|sessionStateAtScriptFor|sessionStateAtPutScriptFor" \
  src/GemStone-GBS-Core/GbsObjectSpaceFacade.class.st >/tmp/gbs-object-space-helper-gate.$$; then
  cat /tmp/gbs-object-space-helper-gate.$$
  fail "legacy ObjectSpace script-helper method reappeared; use typed GbsRemoteCommand constructors"
fi
rm -f /tmp/gbs-object-space-helper-gate.$$

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

if (( failures > 0 )); then
  printf 'BRIDGE_REGRESSION_GATES_FAIL failures=%s\n' "${failures}" >&2
  exit 1
fi

printf 'BRIDGE_REGRESSION_GATES_OK\n'
