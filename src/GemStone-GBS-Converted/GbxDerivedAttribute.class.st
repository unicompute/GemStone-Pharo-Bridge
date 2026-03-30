Class {
	#name : 'GbxDerivedAttribute',
	#superclass : 'Object',
	#instVars : [
		'label',
		'value',
		'delegatePrintString'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxDerivedAttribute class >> label: aString value: anObject printString: aPrintString [
	^ self new
		initialize: aString value: anObject printString: aPrintString;
		yourself
]

{ #category : 'initialization' }
GbxDerivedAttribute >> initialize: aString value: anObject printString: aPrintString [
	label := aString.
	value := anObject.
	delegatePrintString := aPrintString
]

{ #category : 'printing' }
GbxDerivedAttribute >> text [
	^ delegatePrintString ifNil: [ label ifNil: [ '' ] ]
]

{ #category : 'accessing' }
GbxDerivedAttribute >> value [
	^ value
]
