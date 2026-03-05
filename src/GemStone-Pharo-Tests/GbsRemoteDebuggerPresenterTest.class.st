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
