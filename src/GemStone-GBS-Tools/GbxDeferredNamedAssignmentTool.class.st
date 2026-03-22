Class {
	#name : 'GbxDeferredNamedAssignmentTool',
	#superclass : 'GbxDeferredAssignmentTool',
	#instVars : [
		'name'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDeferredNamedAssignmentTool class >> target: aDelegate name: aString value: anObject [
	^ self new
		target: aDelegate;
		name: aString;
		value: anObject;
		yourself
]

{ #category : 'executing' }
GbxDeferredNamedAssignmentTool >> execute [
	"Execute the deferred named assignment"
	target ifNil: [ ^ self ].
	value ifNil: [ ^ self ].
	name ifNil: [ ^ self ].
	
	target storeValue: value atName: name.
]

{ #category : 'accessing' }
GbxDeferredNamedAssignmentTool >> name [
	^ name
]

{ #category : 'accessing' }
GbxDeferredNamedAssignmentTool >> name: aString [
	name := aString
]
