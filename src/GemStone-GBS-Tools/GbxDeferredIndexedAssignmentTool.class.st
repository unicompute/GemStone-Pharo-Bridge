Class {
	#name : 'GbxDeferredIndexedAssignmentTool',
	#superclass : 'GbxDeferredAssignmentTool',
	#instVars : [
		'index'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDeferredIndexedAssignmentTool class >> target: aDelegate index: anIndex value: anObject [
	^ self new
		target: aDelegate;
		index: anIndex;
		value: anObject;
		yourself
]

{ #category : 'executing' }
GbxDeferredIndexedAssignmentTool >> execute [
	"Execute the deferred indexed assignment"
	target ifNil: [ ^ self ].
	value ifNil: [ ^ self ].
	index ifNil: [ ^ self ].
	
	target storeValue: value atIndex: index.
]

{ #category : 'accessing' }
GbxDeferredIndexedAssignmentTool >> index [
	^ index
]

{ #category : 'accessing' }
GbxDeferredIndexedAssignmentTool >> index: anInteger [
	index := anInteger
]
