Class {
	#name : 'GbsRemoteDebuggerPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'debugger',
		'service'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsRemoteDebuggerPresenterTest >> setUp [
	super setUp.
	debugger := GbsRemoteDebugger new.
	service := GbxFakeServiceForRemoteDebugger new.
	debugger service: service.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectReceiverDelegatesToService [
	self assert: debugger inspectReceiver.
	self assert: service inspectReceiverCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectProcessDelegatesToService [
	self assert: debugger inspectProcess.
	self assert: service inspectProcessCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectFrameDelegatesToService [
	self assert: debugger inspectFrame.
	self assert: service inspectFrameCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testSetBreakPointDelegatesToService [
	self assert: debugger setBreakPoint.
	self assert: service setBreakPointCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRemoveBreakPointDelegatesToService [
	self assert: debugger removeBreakPoint.
	self assert: service removeBreakPointCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRemoveAllBreakPointsDelegatesToService [
	self assert: debugger removeAllBreakPoints equals: 1.
	self assert: service removeAllBreakPointsCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testApplySourceMapHighlightSelectsIntervalOnSourceText [
	| fakeText context |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'abcde'.
	service sourceMap: { 1 -> (2 to: 4) }.
	debugger instVarNamed: 'sourceText' put: fakeText.
	context := GbxActivation new.

	debugger applySourceMapHighlightFor: context.

	self assert: fakeText selectionInterval equals: (2 to: 4).
]
