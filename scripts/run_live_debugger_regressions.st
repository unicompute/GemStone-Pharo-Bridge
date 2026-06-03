| classes suite result failures errors loadFailed flattenTest protocolOf replayTest |
[
  loadFailed := false.
  [
    | bootstrapperClass tonelRepository |
    bootstrapperClass := Smalltalk at: #GemStonePharoReloadBootstrapper ifAbsent: [ nil ].
    bootstrapperClass ifNil: [
      tonelRepository := [ MCRepository fromUrl: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src' ]
        on: Error
        do: [ :ex | Error signal: ex messageText ].
      (tonelRepository versionFrom: 'BaselineOfGemStonePharo') load.
      bootstrapperClass := Smalltalk at: #GemStonePharoReloadBootstrapper ifAbsent: [ nil ] ].
    bootstrapperClass
      ifNil: [ Error signal: 'Missing GemStonePharoReloadBootstrapper after baseline load' ]
      ifNotNil: [
        bootstrapperClass
          runBootstrapReloadOnEnvironment: Smalltalk os environment
          log: [ :line | Transcript show: line; cr ] ] ] on: Error do: [ :ex |
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

	    flattenTest := [ :candidate :collection |
	      (candidate isKindOf: TestSuite)
	        ifTrue: [ candidate tests do: [ :each | flattenTest value: each value: collection ] ]
	        ifFalse: [ collection add: candidate ] ].

	    protocolOf := [ :testCase |
	      [
	        | method protocol |
	        method := testCase class >> testCase selector.
	        protocol := method protocol.
	        protocol ifNil: [
	          nil
	        ] ifNotNil: [
	          (protocol respondsTo: #name)
	            ifTrue: [ protocol name asString ]
	            ifFalse: [ protocol asString ] ] ]
	        on: Error
	        do: [
	          [ testCase class organization categoryOfElement: testCase selector ]
	            on: Error
	            do: [ nil ] ] ].

	    replayTest := [ :testCase :label |
	      Transcript
	        show: label, '-DETAIL ', testCase class name, '>>', testCase selector asString;
	        cr.
	      [
	        testCase setUp.
	        [
	          testCase perform: testCase selector.
	          Transcript show: '  replay-result=unexpected-pass'; cr ]
	          on: Exception
	          do: [ :ex |
	            | message context depth |
	            message := [ ex messageText ] on: Error do: [ ex printString ].
	            message := message
	              ifNil: [ ex printString ]
	              ifNotNil: [ message asString ].
	            Transcript show: '  exception-class=', ex class name; cr.
	            Transcript show: '  message=', message asString withBlanksTrimmed; cr.
	            context := [ ex signalerContext ] on: Error do: [ nil ].
	            depth := 0.
	            [ context notNil and: [ depth < 12 ] ] whileTrue: [
	              Transcript
	                show: '  stack', depth asString, '=',
	                  ([ context printString ] on: Error do: [ 'unprintable context' ]);
	                cr.
	              context := [ context sender ] on: Error do: [ nil ].
	              depth := depth + 1 ] ] ]
	        ensure: [
	          [ testCase tearDown ] on: Exception do: [ :ex |
	            Transcript
	              show: '  teardown-error=',
	                (([ ex messageText ] on: Error do: [ ex printString ]) ifNil: [ ex printString ]);
	              cr ] ] ].

	    suite := OrderedCollection new.
	    classes do: [ :sym |
	      | cls |
	      cls := Smalltalk at: sym ifAbsent: [ nil ].
	      cls ifNotNil: [
	        cls suite tests do: [ :candidate |
	          | flattened |
	          flattened := OrderedCollection new.
	          flattenTest value: candidate value: flattened.
	          flattened do: [ :testCase |
	            (protocolOf value: testCase) = 'integration tests'
	              ifTrue: [ suite add: testCase ] ] ] ] ].

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
	      result failures do: [ :f |
	        Transcript show: f printString; cr.
	        (f respondsTo: #failureString) ifTrue: [
	          | details |
	          details := [ f failureString ] on: Error do: [ :ex | ex messageText ].
	          details ifNotNil: [
	            details isEmpty ifFalse: [ Transcript show: details; cr ] ] ].
	        Transcript show: '  failure-class=', f class name; cr.
	        f class allInstVarNames withIndexDo: [ :name :index |
	          Transcript
	            show: '  ', name asString, '=',
	              ([ (f instVarAt: index) printString ] on: Error do: [ :ex | ex messageText ]);
	            cr ].
	        replayTest value: f value: 'FAILURE' ].
	    ].

	    errors > 0 ifTrue: [
	      Transcript show: 'ERRORS:'; cr.
	      result errors do: [ :e |
	        Transcript show: e printString; cr.
	        (e respondsTo: #failureString) ifTrue: [
	          | details |
	          details := [ e failureString ] on: Error do: [ :ex | ex messageText ].
	          details ifNotNil: [
	            details isEmpty ifFalse: [ Transcript show: details; cr ] ] ].
	        Transcript show: '  error-class=', e class name; cr.
	        e class allInstVarNames withIndexDo: [ :name :index |
	          Transcript
	            show: '  ', name asString, '=',
	              ([ (e instVarAt: index) printString ] on: Error do: [ :ex | ex messageText ]);
	            cr ].
	        replayTest value: e value: 'ERROR' ].
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
