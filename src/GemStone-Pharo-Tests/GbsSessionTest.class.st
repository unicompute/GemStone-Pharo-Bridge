Class {
	#name : 'GbsSessionTest',
	#superclass : 'TestCase',
	#instVars : [
		'session'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsSessionTest >> setUp [
    super setUp.
    session := GbsSession new.
]

{ #category : 'running' }
GbsSessionTest >> testAbortTransaction [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciAbort put: 1.
	
	self assert: mockSession abortTransaction equals: true.
]

{ #category : 'running' }
GbsSessionTest >> testCommitTransaction [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciCommit put: 1.
	
	self assert: mockSession commitTransaction equals: true.
]

{ #category : 'tests' }
GbsSessionTest >> testCommitTransactionFailure [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciCommit put: 0.
	
	self deny: mockSession commitTransaction.
]

{ #category : 'running' }
GbsSessionTest >> testExecuteStringReturnsUnboxedObject [
	| mockSession result |
	mockSession := MockGbsSession new.
	
	"1. Force the mock into the instance variable so it isn't nil!"
	mockSession instVarNamed: 'serverInterface' put: mockSession.
	
	"2. Stub the FFI call to return 268 (which GbsSession checks for 'true')"
	mockSession stubs at: #apiGciExecute put: 268. 
	
	result := mockSession execute: '2 > 1'.
	
	self assert: result equals: true.
]

{ #category : 'tests' }
GbsSessionTest >> testExecuteStringSignalsError [
	| mockSession |
	mockSession := MockGbsSession new.
	
	"1. Force the mock into the instance variable so it isn't nil!"
	mockSession instVarNamed: 'serverInterface' put: mockSession.
	
	"2. Insert the error block into the stubs dictionary"
	mockSession stubs at: #executeError put: [ GbsError signal: 'MessageNotUnderstood: #foo' ].
		
	self 
		should: [ mockSession execute: 'Object foo' ]
		raise: GbsError
		withExceptionDo: [ :ex | self assert: ex messageText equals: 'MessageNotUnderstood: #foo' ]
]

{ #category : 'tests' }
GbsSessionTest >> testFetchClassesInDictionary [
	| mockSession classNames |
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: 'Object,String,Array'.
	
	classNames := mockSession fetchRemoteClassNamesIn: 'UserGlobals'.
	
	self assert: (classNames isKindOf: Collection).
	self assert: classNames first equals: 'Object'.
]

{ #category : 'tests' }
GbsSessionTest >> testLoginFailureSignalsError [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #gciInit put: true.
	mockSession stubs at: #gciLogin put: false.
	mockSession stubs at: #gciErr put: [ :errStruct | errStruct message: 'Login failed: Invalid password' ].
		
	self 
		should: [ mockSession loginStone: 'gs64stone' user: 'DataCurator' password: 'wrongpassword' ]
		raise: GbsError
		withExceptionDo: [ :ex | self assert: ex messageText equals: 'Login failed: Invalid password' ].
]

{ #category : 'tests' }
GbsSessionTest >> testLoginSuccess [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #gciInit put: true.
	mockSession stubs at: #gciLogin put: true.

	mockSession loginStone: 'gs64stone' user: 'DataCurator' password: 'swordfish'.
	self assert: mockSession isLoggedIn.
]

{ #category : 'tests' }
GbsSessionTest >> testLogoutSuccess [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciLogout put: 1.
	
	mockSession logout.
	self deny: mockSession isLoggedIn.
]

{ #category : 'tests' }
GbsSessionTest >> testPollingLifecycle [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciPollForSignal put: 0.
	
	mockSession startPolling.
	self assert: mockSession isPolling.
	
	mockSession stopPolling.
	self deny: mockSession isPolling.
]

{ #category : 'running' }
GbsSessionTest >> testResultForComplexObjectReturnsProxy [

  | result |
  "1000 is not a special tag, should result in a GbsProxy"
  result := session resultFor: 1000.
  self assert: ( result isKindOf: GbsProxy ).
  self assert: result oop equals: 1000.
  self assert: result session equals: session
]

{ #category : 'running' }
GbsSessionTest >> testResultForPrimitives [
  "Verify Tag mapping per GS64 3.7 Programming Guide"

  self assert: ( session resultFor: 20 ) isNil.
  self assert: ( session resultFor: 28 ).
  self deny: ( session resultFor: 12 ).
  self assert: ( session resultFor: 82 ) equals: 10.
  "$A (65): (65 << 3) + 6 = 526"
  self assert: ( session resultFor: 526 ) equals: $A
]

{ #category : 'running' }
GbsSessionTest >> testSignalTriggersNotification [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #gciPollForSignal put: 4.
	
	self should: [ mockSession checkSignals ] raise: TransactionBacklog
]
