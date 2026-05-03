Class {
	#name : 'GbxFallbackTrackingRemoteDebugger',
	#superclass : 'GbsRemoteDebugger',
	#instVars : [
		'directRestartFallbackCalls',
		'directExecutedStepFallbackCalls',
		'directFrameStepFallbackCalls'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFallbackTrackingRemoteDebugger >> directExecutedStepFallbackCalls [
	^ directExecutedStepFallbackCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFallbackTrackingRemoteDebugger >> directFrameStepFallbackCalls [
	^ directFrameStepFallbackCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxFallbackTrackingRemoteDebugger >> directRestartFallbackCalls [
	^ directRestartFallbackCalls ifNil: [ 0 ]
]

{ #category : 'private' }
GbxFallbackTrackingRemoteDebugger >> directStepOverExecutedFrame: stepIntoBoolean [
	directExecutedStepFallbackCalls := self directExecutedStepFallbackCalls + 1.
	^ false
]

{ #category : 'private' }
GbxFallbackTrackingRemoteDebugger >> directStepWithPrimarySelector: primarySelector fallbackSelector: fallbackSelector [
	directFrameStepFallbackCalls := self directFrameStepFallbackCalls + 1.
	^ false
]

{ #category : 'private' }
GbxFallbackTrackingRemoteDebugger >> restartUsingDirectTrimFromExecutedFrame [
	directRestartFallbackCalls := self directRestartFallbackCalls + 1.
	^ false
]
