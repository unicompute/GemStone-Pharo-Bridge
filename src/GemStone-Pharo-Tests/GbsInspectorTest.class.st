Class {
	#name : 'GbsInspectorTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbsInspectorTest >> testFetchAndParseLiveInstanceVariables [
	| session targetOop rawData parsedItems |
	
	session := GbsSessionParameters currentSession.
	(session isNil or: [ session isConnected not ]) ifTrue: [
		self skip: 'Requires an active GemStone session' ].
	
	"1. Use a guaranteed global object that cannot fail to compile"
	targetOop := session execute: 'UserGlobals'.
	
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
