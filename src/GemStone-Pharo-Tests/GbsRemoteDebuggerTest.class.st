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
	"Validate the error-driven oop that the remote debugger actually uses."
	| raisedError processOop |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].
	self assert: processOop notNil.
	self deny: processOop equals: 0.
	self deny: processOop equals: 20.
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
	| raisedError processOop service contexts topContext sourceCode |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.
	service initializeForDebugging.

	contexts := service contextList.
	self assert: contexts notEmpty.
	topContext := contexts first.
	sourceCode := topContext sourceCode.
	self assert: sourceCode notNil.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextMethod [
	| raisedError processOop service contexts topContext |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.
	service initializeForDebugging.

	contexts := service contextList.
	self assert: contexts notEmpty.
	topContext := contexts first.
	self assert: topContext gsMethodIdOrUnknown ~= '<unknown>'.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextSelector [
	| raisedError processOop service contexts topContext |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.
	service initializeForDebugging.

	contexts := service contextList.
	self assert: contexts notEmpty.
	topContext := contexts first.
	self deny: topContext selectorOrUnknown equals: #unboundMethod.
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
	| raisedError processOop service contexts summary |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.
	service initializeForDebugging.

	contexts := service contextList.
	self assert: contexts notEmpty.
	summary := contexts collect: [ :ctx | ctx printString ].
	self assert: summary notEmpty.
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
