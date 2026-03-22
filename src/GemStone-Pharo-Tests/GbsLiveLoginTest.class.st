Class {
	#name : 'GbsLiveLoginTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousCurrentSession',
		'previousSessions',
		'session'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsLiveLoginTest >> setUp [
	super setUp.
	previousCurrentSession := GbsSessionParameters currentSession.
	previousSessions := GbsSessionParameters allSessions copy.
	GbsSessionParameters currentSession: nil.
	GbsSessionParameters allSessions removeAll.
	session := nil
]

{ #category : 'running' }
GbsLiveLoginTest >> tearDown [
	session ifNotNil: [
		[
			session hasValidSessionId
				ifTrue: [ session logout ]
		] on: Error do: [ ] ].
	GbsSessionParameters currentSession: previousCurrentSession.
	GbsSessionParameters allSessions removeAll.
	GbsSessionParameters allSessions addAll: previousSessions.
	super tearDown
]

{ #category : 'private' }
GbsLiveLoginTest >> defaultLoginParameters [
	^GbsSessionParameters new
		name: 'DataCurator@gs64stone';
		gemStoneName: 'gs64stone';
		username: 'DataCurator';
		password: 'swordfish';
		gemService: 'gemnetobject';
		yourself
]

{ #category : 'private' }
GbsLiveLoginTest >> loginSession [
	session ifNil: [ session := self defaultLoginParameters login ].
	self
		assert: session notNil
		description: 'Expected live GemStone login to succeed'.
	^session
]

{ #category : 'tests' }
GbsLiveLoginTest >> testLiveLoginRegistersUsableCurrentSession [
	| liveSession |
	liveSession := self loginSession.
	self assert: liveSession isLoggedIn.
	self assert: liveSession sessionId > 0.
	self assert: GbsSessionParameters currentSession == liveSession
]

{ #category : 'tests' }
GbsLiveLoginTest >> testLiveLoginAllowsExecuteAndUnsynchronizedEvaluate [
	| liveSession executeResult unsyncResult |
	liveSession := self loginSession.

	self
		shouldnt: [ executeResult := liveSession execute: 'Array with: 1 with: 2' ]
		raise: Error.
	self
		shouldnt: [ unsyncResult := liveSession unsynchronizedEvaluate: 'Array with: 1 with: 2' ]
		raise: Error.

	self assert: executeResult notNil.
	self assert: unsyncResult equals: #(1 2)
]

{ #category : 'tests' }
GbsLiveLoginTest >> testLiveLoginFetchesBehaviorDelegatesForClassConnectors [
	| liveSession connector delegates |
	liveSession := self loginSession.
	connector := GbsClassConnector stName: #Object gsName: #Object.

	self
		shouldnt: [
			delegates := liveSession
				fetchBehaviorDelegatesForClassConnectors: (Array with: connector) ]
		raise: Error.

	self assert: delegates size equals: 2.
	self assert: delegates first notNil.
	self assert: delegates second notNil.
	self assert: delegates first ~= liveSession oopNil.
	self assert: delegates second ~= liveSession oopNil
]
