Class {
	#name : 'GbxDerivedAttribute',
	#superclass : 'DerivedAttribute',
	#instVars : [
		'delegatePrintString'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'initialize-release' }
GbxDerivedAttribute >> initialize: aString value: anObject printString: aString2
[
	label := aString.
	value := anObject.
	delegatePrintString := aString2
]

{ #category : 'accessing' }
GbxDerivedAttribute >> value
[

	^value isNil ifTrue: [Tools.Trippy.Inspector wrappedOrNot: value] ifFalse: [value]
]

{ #category : 'private' }
GbxDerivedAttribute >> text
[
	^delegatePrintString
]

{ #category : 'instance creation' }
GbxDerivedAttribute class >> label: aString value: anObject printString: aString2
[
	^self new initialize: aString value: anObject printString: aString2
]

