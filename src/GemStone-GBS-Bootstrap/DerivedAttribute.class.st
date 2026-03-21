Class {
	#name : 'DerivedAttribute',
	#superclass : 'Object',
	#instVars : [
		'label',
		'value',
		'object'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
DerivedAttribute >> label: aString value: anObject printString: aPrintString
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
DerivedAttribute >> initialize: aLabel value: anObject printString: aPrintString
[
	label := aLabel.
	value := anObject
]

{ #category : 'accessing' }
DerivedAttribute >> text
[
	"VisualWorks compatibility stub"
	^''
]

{ #category : 'accessing' }
DerivedAttribute >> value
[
	^value
]

{ #category : 'accessing' }
DerivedAttribute >> label
[
	^label
]

{ #category : 'accessing' }
DerivedAttribute >> label: aString
[
	label := aString
]

{ #category : 'accessing' }
DerivedAttribute >> object
[
	^object
]

{ #category : 'accessing' }
DerivedAttribute >> object: anObject
[
	object := anObject
]
