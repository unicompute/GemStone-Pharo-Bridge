Class {
	#name : 'GbxFakeServiceForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'inspectReceiverCalls',
		'inspectProcessCalls',
		'inspectFrameCalls'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'actions' }
GbxFakeServiceForRemoteDebugger >> inspectCurrentReceiver [
	inspectReceiverCalls := self inspectReceiverCalls + 1.
	^ true
]

{ #category : 'actions' }
GbxFakeServiceForRemoteDebugger >> inspectCurrentProcess [
	inspectProcessCalls := self inspectProcessCalls + 1.
	^ true
]

{ #category : 'actions' }
GbxFakeServiceForRemoteDebugger >> inspectCurrentFrame [
	inspectFrameCalls := self inspectFrameCalls + 1.
	^ true
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> inspectReceiverCalls [
	^ inspectReceiverCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> inspectProcessCalls [
	^ inspectProcessCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFakeServiceForRemoteDebugger >> inspectFrameCalls [
	^ inspectFrameCalls ifNil: [ 0 ]
]
