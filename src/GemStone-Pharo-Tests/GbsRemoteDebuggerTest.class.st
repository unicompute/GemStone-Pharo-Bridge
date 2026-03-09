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
]

{ #category : 'running' }
GbsRemoteDebuggerTest >> tearDown [
	session := nil.
	super tearDown.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testSessionIsConnected [
	"Test that we have a valid session before running other tests"
	
	session ifNil: [
		self skip: 'No GemStone session available - please login first'
	].
	
	self assert: session isLoggedIn description: 'Session should be logged in'.
	self deny: session sessionOop = 0 description: 'Session should have valid OOP'.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testSimpleExecution [
	"Test 1: Simple execution should not raise errors"
	| result |
	
	session ifNil: [ self skip: 'No session' ].
	session isLoggedIn ifFalse: [ self skip: 'Not logged in' ].
	
	result := session evaluate: '1 + 1'.
	
	self assert: result = 2.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testDivisionByZeroRaisesError [
	"Test 2: Division by zero should raise GbsError"
	
	session ifNil: [ self skip: 'No session' ].
	session isLoggedIn ifFalse: [ self skip: 'Not logged in' ].
	
	self should: [ session evaluate: '1 / 0' ] raise: GbsError.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testVariableAssignment [
	"Test 3: Variable assignment and retrieval"
	| result |
	
	session ifNil: [ self skip: 'No session' ].
	session isLoggedIn ifFalse: [ self skip: 'Not logged in' ].
	
	result := session evaluate: '| x | x := 42. x'.
	
	self assert: result = 42.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testBlockExecution [
	"Test 4: Block execution with arguments"
	| result |
	
	session ifNil: [ self skip: 'No session' ].
	session isLoggedIn ifFalse: [ self skip: 'Not logged in' ].
	
	result := session evaluate: '[:x :y | x + y] value: 5 value: 10'.
	
	self assert: result = 15.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testStringUppercase [
	"Test 5: String operations"
	| result |
	
	session ifNil: [ self skip: 'No session' ].
	session isLoggedIn ifFalse: [ self skip: 'Not logged in' ].
	
	result := session evaluate: '''hello'' uppercase'.
	
	self assert: result = 'HELLO'.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testArrayAccess [
	"Test 6: Array access"
	| result |
	
	session ifNil: [ self skip: 'No session' ].
	session isLoggedIn ifFalse: [ self skip: 'Not logged in' ].
	
	result := session evaluate: '#(1 2 3) at: 2'.
	
	self assert: result = 2.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testArrayOutOfBoundsRaisesError [
	"Test 7: Array out of bounds should raise error"
	
	session ifNil: [ self skip: 'No session' ].
	session isLoggedIn ifFalse: [ self skip: 'Not logged in' ].
	
	self should: [ session evaluate: '#(1 2 3) at: 10' ] raise: GbsError.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testMessageNotUnderstoodRaisesError [
	"Test 8: Message not understood should raise error"
	
	session ifNil: [ self skip: 'No session' ].
	session isLoggedIn ifFalse: [ self skip: 'Not logged in' ].
	
	self should: [ session evaluate: 'Object thisMessageDoesNotExist' ] raise: GbsError.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testMultiStatementExecution [
	"Test 9: Multiple statements"
	| result |
	
	session ifNil: [ self skip: 'No session' ].
	session isLoggedIn ifFalse: [ self skip: 'Not logged in' ].
	
	result := session evaluate: '| a b | a := 10. b := 20. a + b'.
	
	self assert: result = 30.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testNestedBlockExecution [
	"Test 10: Nested blocks"
	| result |
	
	session ifNil: [ self skip: 'No session' ].
	session isLoggedIn ifFalse: [ self skip: 'Not logged in' ].
	
	result := session evaluate: '[ [ 42 ] value ] value'.
	
	self assert: result = 42.
]
