Class {
	#name : 'GbsPlaygroundActionsTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousSession'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsPlaygroundActionsTest >> setUp [
	super setUp.
	previousSession := GbsSessionParameters currentSession.
	TestableGbsPlaygroundActions resetHarness
]

{ #category : 'running' }
GbsPlaygroundActionsTest >> tearDown [
	GbsSessionParameters currentSession: previousSession.
	super tearDown
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsInspectItUsesExecuteScriptAndReturnOop [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	presenter selectedText: '42'.

	session stubs
		at: #executeScriptAndReturnOop
		put: [ :script |
			self assert: script equals: '42'.
			9001 ].
	session stubs
		at: #apiGciExecuteStrContextEnv
		put: [ :script :context :env |
			self fail: 'Playground inspectIt should use executeScriptAndReturnOop, not serverInterface.' ].
	GbsSessionParameters currentSession: session.

	TestableGbsPlaygroundActions gsInspectItIn: presenter.

	self assert: TestableGbsPlaygroundActions lastInspectedOop equals: 9001.
	self assert: TestableGbsPlaygroundActions lastInspectedSession == session
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsInspectSessionStateKeyRejectsNonNumericInput [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	GbsSessionParameters currentSession: session.
	TestableGbsPlaygroundActions enqueueRequestAnswer: 'abc'.

	self deny: (TestableGbsPlaygroundActions gsInspectSessionStateKeyIn: presenter).
	self assert: TestableGbsPlaygroundActions lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: TestableGbsPlaygroundActions lastInspectedOop isNil
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsInspectSessionStateKeyUsesSessionFacade [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: (script includesSubstring: 'key := 21').
			^ GbsProxy oop: 9701 session: session ].
	GbsSessionParameters currentSession: session.
	TestableGbsPlaygroundActions enqueueRequestAnswer: '21'.

	self assert: (TestableGbsPlaygroundActions gsInspectSessionStateKeyIn: presenter).
	self assert: TestableGbsPlaygroundActions lastInspectedOop equals: 9701.
	self assert: TestableGbsPlaygroundActions lastInspectedSession == session
]
