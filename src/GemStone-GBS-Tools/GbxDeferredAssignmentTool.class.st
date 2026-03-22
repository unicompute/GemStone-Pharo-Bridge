Class {
	#name : 'GbxDeferredAssignmentTool',
	#superclass : 'Object',
	#instVars : [
		'target',
		'value',
		'session'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDeferredAssignmentTool class >> target: aDelegate value: anObject [
	^ self new
		target: aDelegate;
		value: anObject;
		yourself
]

{ #category : 'executing' }
GbxDeferredAssignmentTool >> execute [
	"Execute the deferred assignment"
	target ifNil: [ ^ self ].
	value ifNil: [ ^ self ].
	
	target storeValue: value.
]

{ #category : 'accessing' }
GbxDeferredAssignmentTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxDeferredAssignmentTool >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxDeferredAssignmentTool >> target [
	^ target
]

{ #category : 'accessing' }
GbxDeferredAssignmentTool >> target: aDelegate [
	target := aDelegate
]

{ #category : 'accessing' }
GbxDeferredAssignmentTool >> value [
	^ value
]

{ #category : 'accessing' }
GbxDeferredAssignmentTool >> value: anObject [
	value := anObject
]
