Class {
	#name : 'GbxDynamicInstVarAttribute',
	#superclass : 'GbxDerivedAttribute',
	#instVars : [
		'object'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxDynamicInstVarAttribute class >> label: aString value: anObject printString: aPrintString object: anOwner [
	^ self new
		initialize: aString value: anObject printString: aPrintString object: anOwner;
		yourself
]

{ #category : 'initialization' }
GbxDynamicInstVarAttribute >> initialize: aString value: anObject printString: aPrintString object: anOwner [
	super initialize: aString value: anObject printString: aPrintString.
	object := anOwner
]

{ #category : 'testing' }
GbxDynamicInstVarAttribute >> isReadOnly [
	^ false
]

{ #category : 'accessing' }
GbxDynamicInstVarAttribute >> value: anObject [
	value := anObject.
	^ anObject
]
