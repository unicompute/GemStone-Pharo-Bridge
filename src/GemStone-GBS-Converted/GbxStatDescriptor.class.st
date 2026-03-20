Class {
	#name : 'GbxStatDescriptor',
	#superclass : 'Object',
	#instVars : [
		'type',
		'id',
		'name',
		'description',
		'isCounter',
		'isLargerBetter',
		'unit',
		'category',
		'statClass'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxStatDescriptor >> isByte
[

	^type = 3
]

{ #category : 'accessing' }
GbxStatDescriptor >> id
[
	"The id of this descriptor in its stat resource"
	^id
]

{ #category : 'accessing' }
GbxStatDescriptor >> isShort
[

	^type = 4
]

{ #category : 'accessing' }
GbxStatDescriptor >> name
[

	^name
]

{ #category : 'accessing' }
GbxStatDescriptor >> name: aString
[
	name := aString
]

{ #category : 'accessing' }
GbxStatDescriptor >> unit
[
	^ unit ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxStatDescriptor >> unit: aString
[
	unit := aString
]

{ #category : 'accessing' }
GbxStatDescriptor >> description
[
	^ description
]

{ #category : 'accessing' }
GbxStatDescriptor >> isLargerBetter: aBoolean
[
	isLargerBetter := aBoolean
]

{ #category : 'accessing' }
GbxStatDescriptor >> category
[
	^ category
]

{ #category : 'accessing' }
GbxStatDescriptor >> category: aString
[
	category := aString
]

{ #category : 'accessing' }
GbxStatDescriptor >> description: aString
[
	description := aString
]

{ #category : 'accessing' }
GbxStatDescriptor >> isCounter
[
	^ isCounter ifNil: [ false ]
]

{ #category : 'accessing' }
GbxStatDescriptor >> isCounter: aBoolean
[
	isCounter := aBoolean
]

{ #category : 'accessing' }
GbxStatDescriptor >> isLargerBetter
[
	^ isLargerBetter ifNil: [ false ]
]

{ #category : 'accessing' }
GbxStatDescriptor >> statClass
[
	^ statClass
]

{ #category : 'accessing' }
GbxStatDescriptor >> statClass: aClass
[
	statClass := aClass
]

{ #category : 'accessing' }
GbxStatDescriptor >> type
[
	^ type ifNil: [ 5 ]
]

{ #category : 'accessing' }
GbxStatDescriptor >> type: anInteger
[
	type := anInteger
]

{ #category : 'printing' }
GbxStatDescriptor >> printOn: aStream
[
	super printOn: aStream.
	aStream
		nextPutAll: ': ';
		print: name
]

{ #category : 'printing' }
GbxStatDescriptor >> printString
[
	^ category
		ifNil: [ name, ': ', description ]
		ifNotNil: [ name, ' (', category, '): ', description ]
]

{ #category : 'archiving' }
GbxStatDescriptor >> writeToArchiver: statArchiver 
[
	statArchiver writeString: name.
	"Data type code"
	statArchiver writeByte: type.
	"isCounter"
	statArchiver writeBoolean: isCounter.
	"isLargerBetter"
	statArchiver writeBoolean: isLargerBetter.
	"Unit"
	statArchiver writeString: unit.
	"Description"
	statArchiver writeString: description
]

{ #category : 'initialize-release' }
GbxStatDescriptor >> name: nameString description: descriptionString type: typeInt isCounter: isCounterBool isLargerBetter: isLargerBetterBool unit: unitString
[
	name := nameString.
	description := descriptionString.
	type := typeInt.
	isCounter := isCounterBool.
	isLargerBetter := isLargerBetterBool.
	unit := unitString
]

{ #category : 'initialize-release' }
GbxStatDescriptor >> setId: anInt 
[
	"Set id to a zero-based offset into a stat resource's descriptor collection"

	id ifNotNil: [ self error: 'GbxStatDescriptor>>setId initialized twice' ].
	id := anInt
]

{ #category : 'initialize-release' }
GbxStatDescriptor class >> name: nameString description: descriptionString type: typeInt isCounter: isCounterBool isLargerBetter: isLargerBetterBool unit: unitString
[
	^super new
		name: nameString
		description: descriptionString
		type: typeInt
		isCounter: isCounterBool
		isLargerBetter: isLargerBetterBool
		unit: unitString;
		yourself
]

{ #category : 'instance creation' }
GbxStatDescriptor class >> named: aString description: desc category: cat
[
	^ self new
		name: aString;
		description: desc;
		category: cat;
		yourself
]

{ #category : 'instance creation' }
GbxStatDescriptor class >> named: aString description: desc category: cat unit: aString
[
	^ self new
		name: aString;
		description: desc;
		category: cat;
		unit: aString;
		yourself
]
