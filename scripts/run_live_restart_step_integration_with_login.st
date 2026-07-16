| env envAtAny stone user pass serviceName netldiHost netldiNameOrPort hostUser hostPassword params session code processOop debugger service listPresenter textPresenter tablePresenter topAfterRestart topAfterStep |
[
	[ Metacello new
		baseline: 'GemStonePharo';
		repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
		load: 'default' ] on: Error do: [ :ex |
			Transcript show: 'LOAD_ERROR: ', ex messageText; cr.
			Smalltalk snapshot: false andQuit: true ].

	env := [ OSEnvironment current ] on: Error do: [ Dictionary new ].
	envAtAny := [ :keys :default | | value |
		value := default.
		keys do: [ :key | | raw |
			value = default ifTrue: [
				raw := [ env at: key ifAbsent: [ nil ] ] on: Error do: [ nil ].
				raw ifNotNil: [
					raw := [ raw asString trimBoth ] on: Error do: [ '' ].
					raw isEmpty ifFalse: [ value := raw ] ] ] ].
		value ].
	stone := envAtAny value: #('GS_STONE') value: 'gs64stone'.
	user := envAtAny value: #('GS_USER' 'GS_USERNAME') value: ''.
	pass := envAtAny value: #('GS_PASS' 'GS_PASSWORD') value: ''.
	serviceName := envAtAny value: #('GS_SERVICE') value: 'gemnetobject'.
	netldiHost := envAtAny value: #('GS_NETLDI_HOST' 'GS_HOST') value: ''.
	netldiNameOrPort := envAtAny value: #('GS_NETLDI_NAME_OR_PORT' 'GS_NETLDI') value: ''.
	hostUser := envAtAny value: #('OKZ_GEMSTONE_HOST_USERNAME' 'GS_HOST_USERNAME' 'GS_NETLDI_HOST_USERNAME') value: ''.
	hostPassword := envAtAny value: #('OKZ_GEMSTONE_HOST_PASSWORD' 'GS_HOST_PASSWORD' 'GS_NETLDI_HOST_PASSWORD') value: ''.

	(user isEmpty or: [ pass isEmpty ]) ifTrue: [
		Transcript show: 'ERROR: set GS_USER and GS_PASS environment variables'; cr.
		Smalltalk snapshot: false andQuit: true
	].

	params := GbsSessionParameters new.
	params
		gemStoneName: stone;
		username: user;
		password: pass;
		gemService: serviceName.
	netldiHost isEmpty ifFalse: [ params netldiHostOrIp: netldiHost ].
	netldiNameOrPort isEmpty ifFalse: [ params netldiNameOrPort: netldiNameOrPort ].
	hostUser isEmpty ifFalse: [ params hostUsername: hostUser ].
	hostPassword isEmpty ifFalse: [ params hostPassword: hostPassword ].

	session := [ params login ] on: Error do: [ :ex |
		Transcript show: 'LOGIN_ERROR: ', ex messageText; cr.
		nil
	].
	(session isNil or: [ (session respondsTo: #isLoggedIn) and: [ session isLoggedIn ~= true ] ]) ifTrue: [
		Transcript show: 'ERROR: login failed'; cr.
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

	Transcript show: 'LIVE_RESTART_STEP_LOGIN_OK'; cr.
	Transcript show: 'After restart: ', topAfterRestart; cr.
	Transcript show: 'After first step: ', topAfterStep; cr.
] ensure: [
	[ GbsSessionParameters currentSession ifNotNil: [ :s | s logout ] ] on: Error do: [ ].
	Smalltalk snapshot: false andQuit: true
].
