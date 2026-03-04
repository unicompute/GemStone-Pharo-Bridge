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

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextOopIsValid [
	"Test that we can fetch a valid context OOP from GemStone"
	| contextOop |
	
	session ifNil: [ self skip: 'No session' ].
	
	"Execute code that will give us a context"
	contextOop := session evaluate: 'Processor activeProcess topContext asOop'.
	
	self deny: contextOop equals: 20.
	self deny: contextOop equals: nil.
	self assert: contextOop isNumber.
	
	Transcript show: 'Context OOP: ', contextOop asString; cr.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextHasSender [
	"Test that we can walk the context sender chain"
	| contextOop hasSender |
	
	session ifNil: [ self skip: 'No session' ].
	
	contextOop := session evaluate: 'Processor activeProcess topContext asOop'.
	
	hasSender := session evaluate: '[
		| ctx |
		ctx := Object _objectForOop: ', contextOop asString, '.
		ctx sender notNil
	] value'.
	
	Transcript show: 'Context has sender: ', hasSender asString; cr.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextSourceCode [
	"Test that we can fetch source code from a context"
	| contextOop sourceCode |
	
	session ifNil: [ self skip: 'No session' ].
	
	contextOop := session evaluate: 'Processor activeProcess topContext asOop'.
	
	sourceCode := session evaluate: '[
		| ctx |
		ctx := Object _objectForOop: ', contextOop asString, '.
		ctx sourceCode
	] value'.
	
	Transcript show: 'Source code: ', sourceCode; cr.
	
	self deny: sourceCode equals: nil.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextMethod [
	"Test that we can fetch method from a context"
	| contextOop methodName |
	
	session ifNil: [ self skip: 'No session' ].
	
	contextOop := session evaluate: 'Processor activeProcess topContext asOop'.
	
	methodName := session evaluate: '[
		| ctx |
		ctx := Object _objectForOop: ', contextOop asString, '.
		ctx method ifNil: [ ''nil'' ] ifNotNil: [ :m | m selector asString ]
	] value'.
	
	Transcript show: 'Method: ', methodName; cr.
	
	self deny: methodName equals: 'nil'.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextSelector [
	"Test that we can fetch selector from a context"
	| contextOop selector |
	
	session ifNil: [ self skip: 'No session' ].
	
	contextOop := session evaluate: 'Processor activeProcess topContext asOop'.
	
	selector := session evaluate: '[
		| ctx |
		ctx := Object _objectForOop: ', contextOop asString, '.
		ctx selector ifNil: [ ''nil'' ] ifNotNil: [ :s | s asString ]
	] value'.
	
	Transcript show: 'Selector: ', selector; cr.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testErrorContextFetch [
	"Test fetching context from an actual error"
	| contextOop script |
	
	session ifNil: [ self skip: 'No session' ].
	
	"Execute code that will error and capture the context"
	script := '[
		[ 1 / 0 ] on: Error do: [ :ex |
			| ctx |
			ctx := Processor activeProcess topContext.
			[ ctx notNil and: [ ctx selector == #divide: ] ] whileTrue: [
				ctx := ctx sender.
			].
			ctx asOop
		]
	] value'.
	
	contextOop := session evaluate: script.
	
	Transcript show: 'Error context OOP: ', contextOop asString; cr.
	
	contextOop ifNotNil: [
		"Try to get source code"
		| sourceCode |
		sourceCode := session evaluate: '[
			| ctx |
			ctx := Object _objectForOop: ', contextOop asString, '.
			ctx sourceCode
		] value'.
		
		Transcript show: 'Error context source: ', sourceCode; cr.
	].
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testSimpleStackWalk [
	"Test walking the sender chain from an error context"
	| script result |
	
	session ifNil: [ self skip: 'No session' ].
	
	script := '[
		| ctx stream depth |
		[ 1 / 0 ] on: Error do: [ :ex |
			ctx := Processor activeProcess topContext.
		].
		stream := WriteStream on: String new.
		depth := 0.
		[ ctx notNil and: [ depth < 10 ] ] whileTrue: [
			depth := depth + 1.
			stream 
				nextPutAll: depth asString; tab;
				nextPutAll: (ctx selector ifNil: [''<no selector>'' ] ifNotNil: [ :s | s asString ]); tab;
				nextPutAll: (ctx method ifNil: [''<no method>'' ] ifNotNil: [ :m | m selector asString ]);
				lf.
			ctx := ctx sender.
		].
		stream contents
	] value'.
	
	result := session evaluate: script.
	
	Transcript show: 'Stack walk result: ', result; cr.
	
	self deny: result isNil.
	self deny: result isEmpty.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testZeroDivideErrorCarriesServerProcessOop [
	| raisedError |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	self assert: (raisedError respondsTo: #serverProcessOop).
	self assert: raisedError serverProcessOop isNotNil.
	self deny: raisedError serverProcessOop equals: 0.
	self deny: raisedError serverProcessOop equals: 20.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testZeroDivideBuildsNonEmptyContextListFromDebuggerService [
	| raisedError processOop service contexts |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].
	self assert: processOop notNil.
	self deny: processOop equals: 20.

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.
	service initializeForDebugging.

	contexts := service contextList.
	self assert: contexts notEmpty.
]
