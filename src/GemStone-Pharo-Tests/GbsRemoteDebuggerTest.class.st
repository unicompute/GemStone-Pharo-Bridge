Class {
	#name : 'GbsRemoteDebuggerTest',
	#superclass : 'TestCase',
	#instVars : [
		'session'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsRemoteDebuggerTest >> setUp [
	super setUp.
	session := GbsSessionParameters currentSession.
	(self hasUsableLiveSession: session) ifFalse: [ session := nil ]
]

{ #category : 'running' }
GbsRemoteDebuggerTest >> tearDown [
	session := nil.
	super tearDown.
]

{ #category : 'private' }
GbsRemoteDebuggerTest >> hasUsableLiveSession: aSession [
	aSession ifNil: [ ^ false ].
	(aSession respondsTo: #evaluate:) ifFalse: [ ^ false ].
	(aSession respondsTo: #isConnected) ifFalse: [ ^ false ].
	([ aSession isConnected = true ] on: Error do: [ false ]) ifFalse: [ ^ false ].
	(aSession respondsTo: #isLoggedIn)
		ifFalse: [ ^ false ].
	^ [ aSession isLoggedIn = true ] on: Error do: [ false ]
]

{ #category : 'private' }
GbsRemoteDebuggerTest >> requireLiveConnectedSession [
	session ifNil: [ self skip: 'Requires an active GemStone session' ]
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testSessionIsConnected [
	"Test that we have a valid session before running other tests"
	
	self requireLiveConnectedSession.
	
	self assert: session isLoggedIn description: 'Session should be logged in'.
	self assert: session isConnected description: 'Session should be connected'.
	self deny: session sessionOop = 0 description: 'Session should have valid OOP'.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testSimpleExecution [
	"Test 1: Simple execution should not raise errors"
	| result |
	
	self requireLiveConnectedSession.
	
	result := session evaluate: '1 + 1'.
	
	self assert: result = 2.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testDivisionByZeroRaisesError [
	"Test 2: Division by zero should raise GbsError"
	
	self requireLiveConnectedSession.
	
	self should: [ session evaluate: '1 / 0' ] raise: GbsError.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testVariableAssignment [
	"Test 3: Variable assignment and retrieval"
	| result |
	
	self requireLiveConnectedSession.
	
	result := session evaluate: '| x | x := 42. x'.
	
	self assert: result = 42.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testBlockExecution [
	"Test 4: Block execution with arguments"
	| result |
	
	self requireLiveConnectedSession.
	
	result := session evaluate: '[:x :y | x + y] value: 5 value: 10'.
	
	self assert: result = 15.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testStringUppercase [
	"Test 5: String operations"
	| result |
	
	self requireLiveConnectedSession.
	
	result := session evaluate: '''hello'' uppercase'.
	
	self assert: result = 'HELLO'.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testArrayAccess [
	"Test 6: Array access"
	| result |
	
	self requireLiveConnectedSession.
	
	result := session evaluate: '#(1 2 3) at: 2'.
	
	self assert: result = 2.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testArrayOutOfBoundsRaisesError [
	"Test 7: Array out of bounds should raise error"
	
	self requireLiveConnectedSession.
	
	self should: [ session evaluate: '#(1 2 3) at: 10' ] raise: GbsError.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testMessageNotUnderstoodRaisesError [
	"Test 8: Message not understood should raise error"
	
	self requireLiveConnectedSession.
	
	self should: [ session evaluate: 'Object thisMessageDoesNotExist' ] raise: GbsError.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testMultiStatementExecution [
	"Test 9: Multiple statements"
	| result |
	
	self requireLiveConnectedSession.
	
	result := session evaluate: '| a b | a := 10. b := 20. a + b'.
	
	self assert: result = 30.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testNestedBlockExecution [
	"Test 10: Nested blocks"
	| result |
	
	self requireLiveConnectedSession.
	
	result := session evaluate: '[ [ 42 ] value ] value'.
	
	self assert: result = 42.
]
