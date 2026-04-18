Class {
	#name : 'GbsInspectorTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'integration tests' }
GbsInspectorTest >> testFetchAndParseLiveInstanceVariables [
	| session targetOop rawData parsedItems |
	
	session := GbsLiveSessionTestSupport ensureSharedSession.
	session ifNil: [
		self skip: GbsLiveSessionTestSupport unavailableReason ].
	
	"1. Fetch a raw oop for a guaranteed global object"
	targetOop := session serverInterface
		apiGciExecuteStr: 'UserGlobals'
		context: 20
		env: 0.
	
	"2. Safely verify GemStone returned a real object"
	self assert: targetOop isNotNil description: 'GemStone returned a compile error (nil)'.
	self assert: targetOop > 20 description: 'Execution failed to return a valid OOP'.
	
	"3. Fetch the reflection string"
	rawData := GbsInspector fetchReflectionStringFor: targetOop session: session.
	
	"4. Parse the reflection string"
	parsedItems := GbsInspector parseReflectionString: rawData.
	
	"5. Verify the parsed Array is perfectly formatted for the UI table"
	self assert: parsedItems isNotEmpty.
	self assert: parsedItems first first isString. "The variable name"
	self assert: parsedItems first second isString. "The variable value string"
	self assert: parsedItems first third isInteger. "The child OOP for diving"
]

{ #category : 'tests' }
GbsInspectorTest >> testGsPrintItUsesProvidedEvaluationContextOop [
	| inspector session seenContext value |
	session := MockGbsSession new.
	session isLoggedIn: true.
	session sessionOop: 1.
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			seenContext := ctx.
			'42' ].

	inspector := GbsInspector new.
	inspector inspectOop: 123 session: session context: 456.
	value := inspector gsPrintIt: '21+21'.

	self assert: value equals: '42'.
	self assert: seenContext equals: 456
]

{ #category : 'tests' }
GbsInspectorTest >> testGsDoItUsesSessionOopWhenNoEvaluationContextProvided [
	| inspector session seenContext ok |
	session := MockGbsSession new.
	session isLoggedIn: true.
	session sessionOop: 777.
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			seenContext := ctx.
			'true' ].

	inspector := GbsInspector new.
	inspector inspectOop: 123 session: session context: nil.
	ok := inspector gsDoIt: '1+1'.

	self assert: ok.
	self assert: seenContext equals: 777
]

{ #category : 'tests' }
GbsInspectorTest >> testSelectedInspectableOopPrefersSelectedTableRow [
	| inspector fakeTable |
	inspector := GbsInspector new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable selectedItem: { 'child'. 'aChild'. 456 }.

	inspector instVarNamed: 'oop' put: 123.
	inspector instVarNamed: 'stateTable' put: fakeTable.

	self assert: inspector selectedInspectableOop equals: 456
]

{ #category : 'tests' }
GbsInspectorTest >> testBrowseReferencersInMemoryUsesSessionFacadeAndOpensSingleResult [
	| inspector session fakeTable |
	inspector := TestableGbsInspector new.
	session := MockGbsSession new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable selectedItem: { 'child'. 'aChild'. 456 }.
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: script equals: '((Object _objectForOop: 456)) findReferencesInMemory asArray'.
			^ { GbsProxy oop: 9001 session: session } ].

	inspector instVarNamed: 'session' put: session.
	inspector instVarNamed: 'oop' put: 123.
	inspector instVarNamed: 'stateTable' put: fakeTable.

	self assert: inspector browseReferencersInMemory.
	self assert: inspector lastOpenedOop equals: 9001
]

{ #category : 'tests' }
GbsInspectorTest >> testBrowseReferencersInMemoryInformsWhenNoneFound [
	| inspector session |
	inspector := TestableGbsInspector new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script | #() ].

	inspector instVarNamed: 'session' put: session.
	inspector instVarNamed: 'oop' put: 123.

	self deny: inspector browseReferencersInMemory.
	self assert: inspector lastInfoMessage equals: 'No in-memory referencers found.'
]

{ #category : 'tests' }
GbsInspectorTest >> testBrowsePromptedSessionStateKeyInformsWhenUnset [
	| inspector session |
	inspector := TestableGbsInspector new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ nil ].

	inspector instVarNamed: 'session' put: session.
	inspector enqueueRequestAnswer: '21'.

	self deny: inspector browsePromptedSessionStateKey.
	self assert: inspector lastInfoMessage equals: 'Session state key 21 is not set.'.
	self assert: inspector lastOpenedOop isNil
]

{ #category : 'tests' }
GbsInspectorTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| inspector session |
	inspector := TestableGbsInspector new.
	session := MockGbsSession new.

	inspector instVarNamed: 'session' put: session.
	inspector enqueueRequestAnswer: 'abc'.

	self deny: inspector browsePromptedSessionStateKey.
	self assert: inspector lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: inspector lastOpenedOop isNil
]

{ #category : 'tests' }
GbsInspectorTest >> testBrowsePromptedSessionStateKeyUsesSessionAndOpensInspector [
	| inspector session registry |
	inspector := TestableGbsInspector new.
	session := MockGbsSession new.
	registry := GbsProxy oop: 8181 session: session.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ registry ].

	inspector instVarNamed: 'session' put: session.
	inspector enqueueRequestAnswer: '21'.

	self assert: inspector browsePromptedSessionStateKey.
	self assert: inspector lastOpenedOop equals: 8181
]

{ #category : 'tests' }
GbsInspectorTest >> testInvokeSelectedObjectMethodPromptsForSelectorAndArguments [
	| inspector session fakeTable capturedSelector capturedArguments capturedOop |
	inspector := TestableGbsInspector new.
	session := MockGbsSession new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable selectedItem: { 'child'. 'anInvoice'. 456 }.
	session stubs at: #executeAndFetch put: [ :script |
		self assert: (script includesSubstring: 'Object _objectForOop: 456').
		'Invoice' ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #applyDiscount:') ifTrue: [
			^ #(9004 'Invoice' 'applyDiscount:' 'pricing' 'applyDiscount: percent ^ total * percent' 'Billing-Core' 'Invoice>>applyDiscount:' 3 4) ].
		self fail ].
	session stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#discounted ].

	inspector instVarNamed: 'session' put: session.
	inspector instVarNamed: 'oop' put: 123.
	inspector instVarNamed: 'stateTable' put: fakeTable.
	inspector enqueueRequestAnswer: 'applyDiscount:'.
	inspector enqueueRequestAnswer: '15'.

	self assert: inspector invokeSelectedObjectMethod.
	self assert: capturedSelector equals: #applyDiscount:.
	self assert: capturedArguments equals: #(15).
	self assert: capturedOop equals: 456.
	self assert: (inspector lastInfoMessage includesSubstring: '#discounted')
]
