Class {
	#name : 'GbxDebuggerServiceLiveTest',
	#superclass : 'TestCase',
	#instVars : [
		'session',
		'service',
		'debugger'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'private' }
GbxDebuggerServiceLiveTest >> assertExecutedCodeStep: expectedStep line: expectedLine [
	| context |
	context := self executedCodeContext.
	self assert: context notNil description: 'Expected an executed-code frame in the live debugger stack'.
	self assert: context quickStepPoint equals: expectedStep.
	self assert: context displayedLineNumber equals: expectedLine.
]

{ #category : 'private' }
GbxDebuggerServiceLiveTest >> buildHeadlessDebuggerForFaultingScript: sourceString [
	| error processOop debuggerService |
	error := nil.
	[
		session evaluate: sourceString.
		self fail: 'Expected the script to raise a GemStone debugger error'
	] on: GbsError do: [ :ex |
		error := ex
	].

	processOop := self processOopFromError: error.
	self assert: (processOop isNumber and: [ processOop > 20 ])
		description: 'Expected a live GemStone process OOP for debugger restart testing'.

	debuggerService := GbxDebuggerService new.
	debuggerService
		session: session;
		processOop: processOop;
		label: error messageText;
		restartSourceString: sourceString.
	debuggerService initializeForDebugging.
	service := debuggerService.

	debugger := GbsRemoteDebugger new.
	debugger service: service.
	debugger session: session.
	debugger instVarNamed: 'stackList' put: GbxFakeListPresenterForRemoteDebugger new.
	debugger instVarNamed: 'sourceText' put: GbxFakeTextPresenterForRemoteDebugger new.
	debugger instVarNamed: 'variablesTable' put: GbxFakeTablePresenterForRemoteDebugger new.
	debugger instVarNamed: 'receiverInfoTable' put: GbxFakeTablePresenterForRemoteDebugger new.
	debugger instVarNamed: 'frameInfoTable' put: GbxFakeTablePresenterForRemoteDebugger new.
	debugger instVarNamed: 'processInfoTable' put: GbxFakeTablePresenterForRemoteDebugger new.
	debugger processOop: processOop.
	debugger setInitialSourceCode: sourceString.
	^ debugger
]

{ #category : 'private' }
GbxDebuggerServiceLiveTest >> executedCodeContext [
	| contexts |
	debugger ifNil: [ ^ nil ].
	(service notNil
		and: [ service currentContext notNil
		and: [ (service currentContext respondsTo: #isExecutedCodeFrame)
		and: [ service currentContext isExecutedCodeFrame ] ] ])
		ifTrue: [ ^ service currentContext ].
	contexts := debugger instVarNamed: 'contextList'.
	^ contexts
		detect: [ :each |
			(each respondsTo: #isExecutedCodeFrame)
				and: [ each isExecutedCodeFrame ] ]
		ifNone: [ nil ]
]

{ #category : 'private' }
GbxDebuggerServiceLiveTest >> hasUsableLiveSession: aSession [
	^ GbsLiveSessionTestSupport sessionIsUsable: aSession
]

{ #category : 'private' }
GbxDebuggerServiceLiveTest >> processOopFromError: anError [
	| serverProcess exceptionOop tagged |
	anError ifNil: [ ^ nil ].
	serverProcess := (anError respondsTo: #serverProcessOop)
		ifTrue: [ anError serverProcessOop ]
		ifFalse: [ nil ].
	(serverProcess isNumber and: [ serverProcess > 20 ]) ifTrue: [ ^ serverProcess ].
	tagged := (anError respondsTo: #tag)
		ifTrue: [ anError tag ]
		ifFalse: [ nil ].
	(tagged isNumber and: [ tagged > 20 ]) ifTrue: [ ^ tagged ].
	exceptionOop := (anError respondsTo: #exceptionOop)
		ifTrue: [ anError exceptionOop ]
		ifFalse: [ nil ].
	^ (exceptionOop isNumber and: [ exceptionOop > 20 ])
		ifTrue: [ exceptionOop ]
		ifFalse: [ nil ]
]

{ #category : 'private' }
GbxDebuggerServiceLiveTest >> requireLiveConnectedSession [
	session ifNil: [ self skip: GbsLiveSessionTestSupport unavailableReason ]
]

{ #category : 'private' }
GbxDebuggerServiceLiveTest >> withRemoteDebuggerSessionForFaultingScript: sourceString do: aBlock [
	| remoteDebugger |
	remoteDebugger := nil.
	^ [
		remoteDebugger := self buildHeadlessDebuggerForFaultingScript: sourceString.
		aBlock value: remoteDebugger
	] ensure: [
		remoteDebugger ifNotNil: [
			[ remoteDebugger terminate ] on: Error do: [ ] ].
		service ifNotNil: [
			([ service isTerminated ] on: Error do: [ false ]) ifFalse: [
				Transcript show: 'LIVE_DEBUGGER_CLEANUP_WARN debug process termination could not be verified'; cr ] ].
		session ifNotNil: [
			[ session abortTransaction ] on: Error do: [ ] ] ]
]

{ #category : 'running' }
GbxDebuggerServiceLiveTest >> setUp [
	super setUp.
	session := GbsLiveSessionTestSupport ensureSharedSession.
	(self hasUsableLiveSession: session) ifFalse: [ session := nil ].
	service := nil.
	debugger := nil.
]

{ #category : 'running' }
GbxDebuggerServiceLiveTest >> tearDown [
	debugger ifNotNil: [
		[ debugger terminate ] on: Error do: [ ].
		debugger := nil
	].
	service ifNotNil: [
		[ service terminate ] on: Error do: [ ].
		service := nil
	].
	session ifNotNil: [
		[ session abortTransaction ] on: Error do: [ ].
	].
	session := nil.
	super tearDown.
]

{ #category : 'integration tests' }
GbxDebuggerServiceLiveTest >> testDebuggerAcceptanceOpensShowsStackSourceProxyAndAbortCleansTransaction [
	| contexts sourcePresenter sourceText proxy probeExists |
	self requireLiveConnectedSession.

	self withRemoteDebuggerSessionForFaultingScript: '1 / 0' do: [ :remoteDebugger |
		debugger := remoteDebugger.

		contexts := debugger instVarNamed: 'contextList'.
		self assert: contexts notEmpty description: 'Expected live debugger stack frames for 1 / 0'.

		sourcePresenter := debugger instVarNamed: 'sourceText'.
		sourceText := sourcePresenter text.
		self assert: sourceText notEmpty description: 'Expected source lookup to populate the debugger source pane'.
		self
			assert: ((sourceText includesSubstring: '1 / 0') or: [ sourceText includesSubstring: '1/0' ])
			description: 'Expected debugger source lookup to include the faulting expression'.

		proxy := session proxyForOop: debugger processOop.
		self assert: proxy oop equals: debugger processOop.

		session withGemStoneTransactionDo: [
			session
				execute: 'UserGlobals removeKey: #GbsDebuggerAcceptanceDirtyProbe ifAbsent: [ ]. true' ].
		session
			execute: 'UserGlobals at: #GbsDebuggerAcceptanceDirtyProbe put: ''dirty''. true'.
		session abortTransaction.
		probeExists := session evaluate: 'UserGlobals includesKey: #GbsDebuggerAcceptanceDirtyProbe'.
		self deny: probeExists description: 'Expected abortTransaction to remove uncommitted live debugger probe state' ]
]

{ #category : 'integration tests' }
GbxDebuggerServiceLiveTest >> testRepeatedRestartResetsExecutedCodeToStepOneForMultiStatementScript [
	| executed restarted |
	self requireLiveConnectedSession.

	self
		withRemoteDebuggerSessionForFaultingScript:
			'1/1.', String lf, String lf, '1/2.', String lf, String lf, '1/0'
		do: [ :remoteDebugger |
			debugger := remoteDebugger.

			restarted := debugger restart.
			restarted ifFalse: [
				Transcript
					show: 'LIVE_RESTART_DIAG sourceSize=', service restartSourceString size asString,
						' processOop=', debugger processOop printString,
						' canExecute=', service canExecuteOnDebugProcess printString,
						' restartHomeLevel=', service resolvedRestartHomeLevel printString;
					cr ].
			self assert: restarted description: 'First restart should succeed'.
			self assertExecutedCodeStep: 1 line: 1.

			self assert: debugger stepOver description: 'Step after first restart should advance from the restart anchor'.
			executed := self executedCodeContext.
			self assert: executed notNil.
			self assert: executed quickStepPoint > 1.
			self assert: executed displayedLineNumber < 5.

			self assert: debugger restart description: 'Second restart should also reset the executed frame'.
			self assertExecutedCodeStep: 1 line: 1.

			self assert: debugger stepOver description: 'Step after second restart should again advance from step 1'.
			executed := self executedCodeContext.
			self assert: executed notNil.
			self assert: executed quickStepPoint > 1.
			self assert: executed displayedLineNumber < 5 ]
]
