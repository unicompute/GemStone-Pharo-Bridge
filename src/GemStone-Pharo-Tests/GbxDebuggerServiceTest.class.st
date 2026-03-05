Class {
	#name : 'GbxDebuggerServiceTest',
	#superclass : 'TestCase',
	#instVars : [
		'service',
		'session',
		'context'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbxDebuggerServiceTest >> setUp [
	super setUp.
	GbxFakeInspectorForService reset.
	session := MockGbsSession new.
	service := GbxTestableDebuggerService new.
	service session: session.
	context := GbxFakeActivationForService new.
	context
		processOop: 111;
		level: 3.
	service currentContext: context.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentProcessUsesContextProcessOop [
	| opened |
	opened := service inspectCurrentProcess.

	self assert: opened.
	self assert: GbxFakeInspectorForService lastOop equals: 111.
	self assert: GbxFakeInspectorForService lastSession == session.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentReceiverUsesDetailedReportOop [
	| opened |
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			(script includesSubstring: '_gsiDebuggerDetailedReportAt:')
				ifTrue: [ '222' ]
				ifFalse: [ '0' ] ].

	opened := service inspectCurrentReceiver.

	self assert: opened.
	self assert: GbxFakeInspectorForService lastOop equals: 222.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentFrameUsesFrameContentsOop [
	| opened |
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			(script includesSubstring: '_frameContentsAt:')
				ifTrue: [ '333' ]
				ifFalse: [ '0' ] ].

	opened := service inspectCurrentFrame.

	self assert: opened.
	self assert: GbxFakeInspectorForService lastOop equals: 333.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentReceiverReturnsFalseWhenNoContext [
	service currentContext: nil.

	self deny: service inspectCurrentReceiver.
	self assert: GbxFakeInspectorForService lastOop isNil.
]
