Class {
	#name : 'GbxDeferredNamedAssignment',
	#superclass : 'GbxDeferredAssignment',
	#instVars : [
		'name'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDeferredNamedAssignment class >> target: aDelegate name: aString value: anObject [
	^ self new
		target: aDelegate;
		name: aString;
		value: anObject;
		yourself
]

{ #category : 'executing' }
GbxDeferredNamedAssignment >> execute [
	"Execute the deferred named assignment"
	target ifNil: [ ^ self ].
	value ifNil: [ ^ self ].
	name ifNil: [ ^ self ].
	
	target storeValue: value atName: name.
]

{ #category : 'accessing' }
GbxDeferredNamedAssignment >> name [
	^ name
]

{ #category : 'accessing' }
GbxDeferredNamedAssignment >> name: aString [
	name := aString
]
