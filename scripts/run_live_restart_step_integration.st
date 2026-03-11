| session code processOop debugger service listPresenter textPresenter tablePresenter topAfterRestart topAfterStep |
[
	[ Metacello new
		baseline: 'GemStonePharo';
		repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
		load: 'default' ] on: Error do: [ :ex |
			Transcript show: 'LOAD_ERROR: ', ex messageText; cr.
			Smalltalk snapshot: false andQuit: true ].

	session := GbsSessionParameters currentSession.
	(session isNil or: [ (session respondsTo: #isLoggedIn) and: [ session isLoggedIn ~= true ] ]) ifTrue: [
		Transcript show: 'SKIP: no logged in GemStone session'; cr.
		Smalltalk snapshot: false andQuit: true
	].

	code := '| a b |', String lf, String lf,
		'a := 10.', String lf,
		'b := 0.', String lf, String lf,
		'a / b'.

	processOop := nil.
	[
		session execute: code.
		Error signal: 'Expected ZeroDivide was not raised'
	] on: GbsError do: [ :ex |
		processOop := (ex respondsTo: #serverProcessOop)
			ifTrue: [ ex serverProcessOop ]
			ifFalse: [ nil ].
		((processOop isNumber and: [ processOop > 20 ]) not) ifTrue: [
			processOop := (ex respondsTo: #exceptionOop)
				ifTrue: [ ex exceptionOop ]
				ifFalse: [ nil ]
		]
	].

	((processOop isNumber and: [ processOop > 20 ]) not) ifTrue: [
		Error signal: 'Could not resolve remote debugger process oop'
	].

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.

	debugger := GbsRemoteDebugger new.
	debugger
		session: session;
		processOop: processOop;
		service: service.

	listPresenter := GbxFakeListPresenterForRemoteDebugger new.
	textPresenter := GbxFakeTextPresenterForRemoteDebugger new.
	textPresenter text: code.
	tablePresenter := GbxFakeTablePresenterForRemoteDebugger new.
	debugger instVarNamed: 'stackList' put: listPresenter.
	debugger instVarNamed: 'sourceText' put: textPresenter.
	debugger instVarNamed: 'variablesTable' put: tablePresenter.
	debugger instVarNamed: 'receiverInfoTable' put: tablePresenter.
	debugger instVarNamed: 'frameInfoTable' put: tablePresenter.
	debugger instVarNamed: 'processInfoTable' put: tablePresenter.

	debugger fetchStackFrames.
	((debugger instVarNamed: 'contextList') isEmpty) ifTrue: [
		Error signal: 'No stack frames captured before restart'
	].

	(debugger restart) ifFalse: [ Error signal: 'Restart returned false' ].
	topAfterRestart := (debugger instVarNamed: 'contextList') first printString.
	(topAfterRestart beginsWith: 'GS: Executed code @1 line 1') ifFalse: [
		Error signal: 'Restart top frame mismatch: ', topAfterRestart
	].

	(debugger stepOver) ifFalse: [ Error signal: 'StepOver returned false after restart' ].
	topAfterStep := (debugger instVarNamed: 'contextList') first printString.
	(topAfterStep beginsWith: 'GS: Executed code @2') ifFalse: [
		Error signal: 'First step mismatch (expected step 2): ', topAfterStep
	].

	Transcript show: 'LIVE_RESTART_STEP_OK'; cr.
	Transcript show: 'After restart: ', topAfterRestart; cr.
	Transcript show: 'After first step: ', topAfterStep; cr.
] ensure: [ Smalltalk snapshot: false andQuit: true ].
