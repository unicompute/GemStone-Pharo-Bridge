Class {
	#name : 'GbxDeferredIndexedAssignment',
	#superclass : 'GbxDeferredAssignment',
	#instVars : [
		'index'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDeferredIndexedAssignment class >> target: aDelegate index: anIndex value: anObject [
	^ self new
		target: aDelegate;
		index: anIndex;
		value: anObject;
		yourself
]

{ #category : 'executing' }
GbxDeferredIndexedAssignment >> execute [
	"Execute the deferred indexed assignment"
	target ifNil: [ ^ self ].
	value ifNil: [ ^ self ].
	index ifNil: [ ^ self ].
	
	target storeValue: value atIndex: index.
]

{ #category : 'accessing' }
GbxDeferredIndexedAssignment >> index [
	^ index
]

{ #category : 'accessing' }
GbxDeferredIndexedAssignment >> index: anInteger [
	index := anInteger
]
