| classes suite result failures errors loadFailed |
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
      show: 'LIVE_DEBUGGER_SUMMARY result=FAIL code=LIVE_DEBUGGER_LOAD_FAILED run=0 failures=0 errors=1';
      cr ] ifFalse: [
    classes := {
      #GbsWorkspaceTest.
      #GbsRemoteDebuggerTest.
      #GbxDebuggerServiceLiveTest.
      #GbsTranscriptTest
    }.

    suite := OrderedCollection new.
    classes do: [ :sym |
      | cls |
      cls := Smalltalk at: sym ifAbsent: [ nil ].
      cls ifNotNil: [
        cls suite tests do: [ :testCase |
          | method |
          method := cls lookupSelector: testCase selector.
          (method notNil and: [ method protocol asString = 'integration tests' ])
            ifTrue: [ suite add: testCase ] ] ] ].

    result := TestResult new.
    suite do: [ :testCase | testCase run: result ].

    failures := result failures size.
    errors := result errors size.
    Transcript
      show: 'DEBUGGER_REGRESSION RUN=' , result runCount asString,
        ' FAIL=' , failures asString,
        ' ERR=' , errors asString;
      cr.

    failures > 0 ifTrue: [
      Transcript show: 'FAILURES:'; cr.
      result failures do: [ :f | Transcript show: f printString; cr ].
    ].

    errors > 0 ifTrue: [
      Transcript show: 'ERRORS:'; cr.
      result errors do: [ :e | Transcript show: e printString; cr ].
    ].

    suite isEmpty
      ifTrue: [
        Transcript
          show: 'LIVE_DEBUGGER_SUMMARY result=FAIL code=LIVE_DEBUGGER_NO_TESTS run=0 failures=0 errors=0';
          cr ]
      ifFalse: [
        Transcript
          show: 'LIVE_DEBUGGER_SUMMARY result=',
            ((failures = 0 and: [ errors = 0 ]) ifTrue: [ 'OK' ] ifFalse: [ 'FAIL' ]),
            ' code=',
            ((failures = 0 and: [ errors = 0 ]) ifTrue: [ 'LIVE_DEBUGGER_OK' ] ifFalse: [ 'LIVE_DEBUGGER_FAILED' ]),
            ' run=', result runCount asString,
            ' failures=', failures asString,
            ' errors=', errors asString;
          cr ] ].
] ensure: [ Smalltalk snapshot: false andQuit: true ].
