| result tests failures errors cls out |
[
    out := FileLocator workingDirectory / 'restart_tests.log' writeStream.
	[ Metacello new
		baseline: 'GemStonePharo';
		repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
		load: 'default' ] on: Error do: [ :ex |
			out nextPutAll: 'LOAD_ERROR: ', ex messageText; cr ].

	tests := OrderedCollection new.
	cls := Smalltalk at: #GbxDebuggerServiceTest ifAbsent: [ nil ].
	cls ifNotNil: [
		tests add: (cls selector: #testRestartSelectsExecutedCodeFrameAtLineOne) ].
	cls := Smalltalk at: #GbsRemoteDebuggerPresenterTest ifAbsent: [ nil ].
	cls ifNotNil: [
		tests add: (cls selector: #testRestartPromotesExecutedCodeFrameToTopAndSelectsSourceStart) ].

	result := TestResult new.
	tests do: [ :testCase | testCase run: result ].

	failures := result failures size.
	errors := result errors size.
	out
		nextPutAll: 'RESTART_TARGETED RUN=' , result runCount asString,
			' FAIL=' , failures asString,
			' ERR=' , errors asString;
		cr.

	failures > 0 ifTrue: [
		out nextPutAll: 'FAILURES:'; cr.
		result failures do: [ :f | out nextPutAll: f printString; cr ] ].
	errors > 0 ifTrue: [
		out nextPutAll: 'ERRORS:'; cr.
		result errors do: [ :e | out nextPutAll: e printString; cr ] ].
    out close.
] ensure: [ Smalltalk exit: ((failures ifNil: [ 0 ]) + (errors ifNil: [ 0 ]) > 0 ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
