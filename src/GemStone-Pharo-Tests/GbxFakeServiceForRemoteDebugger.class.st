Class {
	#name : 'GbxFakeServiceForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'inspectReceiverCalls',
		'inspectProcessCalls',
		'inspectFrameCalls',
		'setBreakPointCalls',
		'removeBreakPointCalls',
		'removeAllBreakPointsCalls',
		'sourceMap'
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

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> setBreakPointIn: aTextWidget [
	setBreakPointCalls := self setBreakPointCalls + 1.
	^ true
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> removeBreakIn: aTextWidget [
	removeBreakPointCalls := self removeBreakPointCalls + 1.
	^ true
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> removeAllBreakPoints [
	removeAllBreakPointsCalls := self removeAllBreakPointsCalls + 1.
	^ 1
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> setBreakPointCalls [
	^ setBreakPointCalls ifNil: [ 0 ]
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> removeBreakPointCalls [
	^ removeBreakPointCalls ifNil: [ 0 ]
]

{ #category : 'breakpoint support' }
GbxFakeServiceForRemoteDebugger >> removeAllBreakPointsCalls [
	^ removeAllBreakPointsCalls ifNil: [ 0 ]
]

{ #category : 'source map' }
GbxFakeServiceForRemoteDebugger >> sourceMap [
	^ sourceMap ifNil: [ #( ) ]
]

{ #category : 'source map' }
GbxFakeServiceForRemoteDebugger >> sourceMap: aCollection [
	sourceMap := aCollection
]
