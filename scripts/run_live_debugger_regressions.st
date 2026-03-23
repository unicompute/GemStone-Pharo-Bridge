| classes criticalFiles forceLoadFile reader result suite failures errors testFiles testPackageDir |
[
  forceLoadFile := [ :file |
    [
      (reader new parseTonelFile: file) do: [ :definition | definition load ]
    ] on: Error do: [ :ex |
      Transcript
        show: 'FORCE_LOAD_WARN: ';
        show: file basename;
        show: ' :: ';
        show: ex messageText;
        cr
    ]
  ].

  [ Metacello new
      baseline: 'GemStonePharo';
      repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
      load: 'full' ] on: Error do: [ :ex |
        Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

  reader := Smalltalk at: #TonelReader ifAbsent: [ nil ].
  reader ifNotNil: [
    criticalFiles := #(
      '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Bootstrap/GbxAbstractProxy.class.st'
      '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsError.class.st'
      '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsForwarder.class.st'
      '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsObject.class.st'
      '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsSession.class.st'
      '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsSessionManager.class.st'
      '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbsStackDumper.class.st'
      '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Converted/GbxCPrimInterface.class.st'
      '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbxContextListPolicy.class.st'
      '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbxDebuggerService.class.st'
      '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbsRemoteDebugger.class.st'
    ).
    criticalFiles do: [ :pathString | forceLoadFile value: pathString asFileReference ].

    testPackageDir := '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-Pharo-Tests' asFileReference.
    testPackageDir exists ifTrue: [
      testFiles := (testPackageDir children
        select: [ :each | each extension = 'st' and: [ each basename ~= 'package.st' ] ])
          asSortedCollection: [ :a :b |
            | aIsTest bIsTest |
            aIsTest := a basename endsWith: 'Test.class.st'.
            bIsTest := b basename endsWith: 'Test.class.st'.
            aIsTest = bIsTest
              ifTrue: [ a basename <= b basename ]
              ifFalse: [ aIsTest not ]
          ].
      2 timesRepeat: [ testFiles do: [ :file | forceLoadFile value: file ] ]
    ]
  ].

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
