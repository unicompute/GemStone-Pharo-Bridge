| classes suite result failures errors |
[
  [ Metacello new
      baseline: 'GemStonePharo';
      repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
      load: 'default' ] on: Error do: [ :ex |
        Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

  classes := {
    #GbsWorkspaceTest.
    #GbsRemoteDebuggerPresenterTest.
    #GbxDebuggerServiceTest.
    #GbxContextListPolicyTest.
    #GbxActivationTest
  }.

  suite := OrderedCollection new.
  classes do: [ :sym |
    | cls |
    cls := Smalltalk at: sym ifAbsent: [ nil ].
    cls ifNotNil: [ suite addAll: (cls suite tests) ].
  ].

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
] ensure: [ Smalltalk snapshot: false andQuit: true ].
