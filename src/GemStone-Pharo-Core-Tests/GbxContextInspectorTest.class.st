Class {
	#name : 'GbxContextInspectorTest',
	#superclass : 'TestCase',
	#instVars : [
		'inspector',
		'service',
		'context'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GbxContextInspectorTest >> setUp [
	super setUp.
	service := GbxFakeServiceForContextInspector new.
	context := GbxFakeServerContextForInspector new.
	context
		tempNamesAndValues: (Dictionary new
			at: 'self' put: 'receiver';
			at: 'a' put: 10;
			at: 'b' put: 0;
			yourself);
		argNames: #('a' 'b');
		processOop: 222.
	inspector := GbxContextInspector new.
	inspector
		service: service;
		object: context.
]

{ #category : 'tests' }
GbxContextInspectorTest >> testEvaluateTextRoutesThroughServiceForServerContext [
	| value |
	service result: '42'.
	value := inspector
		evaluateText: '21 * 2'
		from: nil
		ifFail: [ self fail: 'expected server eval' ].
	self assert: value equals: '42'.
	self assert: service lastCode equals: '21 * 2'
]

{ #category : 'tests' }
GbxContextInspectorTest >> testEvaluateTextRunsFailBlockWhenServiceFails [
	| failed |
	failed := false.
	service result: nil.
	inspector evaluateText: '1 / 0' from: nil ifFail: [ failed := true ].
	self assert: failed
]

{ #category : 'tests' }
GbxContextInspectorTest >> testFieldListUsesTempNamesAndValuesKeys [
	| names |
	names := inspector fieldList.
	self assert: (names includes: 'a').
	self assert: (names includes: 'b').
	self assert: (names includes: 'self')
]

{ #category : 'tests' }
GbxContextInspectorTest >> testStackInspectorStackStringAtFormatsNameAndValue [
	| stackInspectorClass stackInspector line |
	stackInspectorClass := Smalltalk at: #GbxStackInspector ifAbsent: [ self fail: 'GbxStackInspector missing' ].
	stackInspector := stackInspectorClass new.
	stackInspector
		service: service;
		object: context.
	line := stackInspector stackStringAt: 1.
	self assert: (line includesSubstring: 'a:')
]

{ #category : 'tests' }
GbxContextInspectorTest >> testReceiverInspectorExposesReceiverFields [
	| receiverInspectorClass receiverInspector |
	receiverInspectorClass := Smalltalk at: #GbxReceiverInspector ifAbsent: [ self fail: 'GbxReceiverInspector missing' ].
	receiverInspector := receiverInspectorClass new.
	receiverInspector
		service: service;
		object: context.
	self assert: (receiverInspector fieldList includes: 'self').
	self assert: (receiverInspector fieldList includes: 'self oop').
	self assert: (receiverInspector fieldValueAtName: 'self') equals: 'DemoReceiver'.
	self assert: (receiverInspector fieldValueAtName: 'self oop') equals: '12345'
]
