| result tests failures errors cls |
[
	[ Metacello new
		baseline: 'GemStonePharo';
		repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
		load: 'default' ] on: Error do: [ :ex |
			Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

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
	Transcript
		show: 'RESTART_TARGETED RUN=' , result runCount asString,
			' FAIL=' , failures asString,
			' ERR=' , errors asString;
		cr.

	failures > 0 ifTrue: [
		Transcript show: 'FAILURES:'; cr.
		result failures do: [ :f | Transcript show: f printString; cr ] ].
	errors > 0 ifTrue: [
		Transcript show: 'ERRORS:'; cr.
		result errors do: [ :e | Transcript show: e printString; cr ] ].
] ensure: [ Smalltalk snapshot: false andQuit: true ].
