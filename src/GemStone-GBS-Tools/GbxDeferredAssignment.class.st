Class {
	#name : 'GbxDeferredAssignment',
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
GbxDeferredAssignment class >> target: aDelegate value: anObject [
	^ self new
		target: aDelegate;
		value: anObject;
		yourself
]

{ #category : 'executing' }
GbxDeferredAssignment >> execute [
	"Execute the deferred assignment"
	target ifNil: [ ^ self ].
	value ifNil: [ ^ self ].
	
	target storeValue: value.
]

{ #category : 'accessing' }
GbxDeferredAssignment >> session [
	^ session
]

{ #category : 'accessing' }
GbxDeferredAssignment >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxDeferredAssignment >> target [
	^ target
]

{ #category : 'accessing' }
GbxDeferredAssignment >> target: aDelegate [
	target := aDelegate
]

{ #category : 'accessing' }
GbxDeferredAssignment >> value [
	^ value
]

{ #category : 'accessing' }
GbxDeferredAssignment >> value: anObject [
	value := anObject
]
