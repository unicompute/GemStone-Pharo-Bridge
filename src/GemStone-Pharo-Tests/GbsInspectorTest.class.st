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
	self assert: session isNotNil description: 'You must be logged into GemStone to run this test!'.
	
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
