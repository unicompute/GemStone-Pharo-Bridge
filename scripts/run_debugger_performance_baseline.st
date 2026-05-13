| loadFailed test debugger contexts context source proxy openStart openMs stackStart stackMs sourceStart sourceMs proxyStart proxyMs |
[
  loadFailed := false.
  [ Metacello new
      baseline: 'GemStonePharo';
      repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
      load: 'default' ] on: Error do: [ :ex |
        loadFailed := true.
        Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

  loadFailed ifTrue: [
    Transcript
      show: 'DEBUGGER_PERF_BASELINE result=FAIL code=DEBUGGER_PERF_LOAD_FAILED open_ms=0 stack_fetch_ms=0 source_lookup_ms=0 proxy_inspect_ms=0';
      cr ] ifFalse: [
    [
      test := GbxDebuggerServiceLiveTest selector: #testDebuggerAcceptanceOpensShowsStackSourceProxyAndAbortCleansTransaction.
      test setUp.
      [
        openStart := Time millisecondClockValue.
        debugger := test buildHeadlessDebuggerForFaultingScript: '1 / 0'.
        openMs := Time millisecondClockValue - openStart.

        stackStart := Time millisecondClockValue.
        contexts := debugger fetchContextsDirectly.
        stackMs := Time millisecondClockValue - stackStart.
        contexts isEmpty ifTrue: [ contexts := debugger instVarNamed: 'contextList' ].
        context := contexts isEmpty ifTrue: [ nil ] ifFalse: [ contexts first ].

        sourceStart := Time millisecondClockValue.
        source := debugger fetchFullSourceFor: context.
        sourceMs := Time millisecondClockValue - sourceStart.

        proxyStart := Time millisecondClockValue.
        proxy := (test instVarNamed: 'session') proxyForOop: debugger processOop.
        proxy printString.
        proxyMs := Time millisecondClockValue - proxyStart.

        Transcript
          show: 'DEBUGGER_PERF_BASELINE result=OK code=DEBUGGER_PERF_OK',
            ' open_ms=', openMs asString,
            ' stack_fetch_ms=', stackMs asString,
            ' source_lookup_ms=', sourceMs asString,
            ' proxy_inspect_ms=', proxyMs asString;
          cr.
        (source isNil or: [ source isEmpty ]) ifTrue: [
          Transcript show: 'DEBUGGER_PERF_WARNING source lookup returned empty text'; cr ].
      ] ensure: [
        [ test tearDown ] on: Error do: [ :ignored | ] ]
    ] on: Error do: [ :ex |
      Transcript
        show: 'DEBUGGER_PERF_BASELINE result=FAIL code=DEBUGGER_PERF_RUN_FAILED open_ms=0 stack_fetch_ms=0 source_lookup_ms=0 proxy_inspect_ms=0 message=';
        show: (ex messageText ifNil: [ ex printString ]) withBlanksTrimmed;
        cr ] ].
] ensure: [ Smalltalk snapshot: false andQuit: true ].
