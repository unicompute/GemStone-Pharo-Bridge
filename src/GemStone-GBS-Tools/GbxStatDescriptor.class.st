Class {
	#name : 'GbxStatDescriptor',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'category',
		'unit',
		'statClass',
		'type',
		'id',
		'isCounter',
		'isLargerBetter'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxStatDescriptor class >> name: nameString description: descriptionString type: typeInt isCounter: isCounterBool isLargerBetter: isLargerBetterBool unit: unitString [
	^ self new
		name: nameString
		description: descriptionString
		type: typeInt
		isCounter: isCounterBool
		isLargerBetter: isLargerBetterBool
		unit: unitString
]

{ #category : 'instance creation' }
GbxStatDescriptor class >> named: aString description: desc category: cat [
	^ self new
		name: aString;
		description: desc;
		category: cat;
		yourself
]

{ #category : 'instance creation' }
GbxStatDescriptor class >> named: aString description: desc category: cat unit: aString [
	^ self new
		name: aString;
		description: desc;
		category: cat;
		unit: aString;
		yourself
]

{ #category : 'accessing' }
GbxStatDescriptor >> category [
	^ category
]

{ #category : 'accessing' }
GbxStatDescriptor >> category: aString [
	category := aString
]

{ #category : 'accessing' }
GbxStatDescriptor >> description [
	^ description
]

{ #category : 'accessing' }
GbxStatDescriptor >> description: aString [
	description := aString
]

{ #category : 'accessing' }
GbxStatDescriptor >> id [
	^ id
]

{ #category : 'accessing' }
GbxStatDescriptor >> isByte [
	^ type = 3
]

{ #category : 'accessing' }
GbxStatDescriptor >> isLargerBetter: aBoolean [
	isLargerBetter := aBoolean
]

{ #category : 'accessing' }
GbxStatDescriptor >> isShort [
	^ type = 4
]

{ #category : 'accessing' }
GbxStatDescriptor >> name [
	^ name
]

{ #category : 'accessing' }
GbxStatDescriptor >> name: aString [
	name := aString
]

{ #category : 'initialize-release' }
GbxStatDescriptor >> name: nameString description: descriptionString type: typeInt isCounter: isCounterBool isLargerBetter: isLargerBetterBool unit: unitString [
	name := nameString.
	description := descriptionString.
	type := typeInt.
	isCounter := isCounterBool.
	isLargerBetter := isLargerBetterBool.
	unit := unitString.
	^ self
]

{ #category : 'printing' }
GbxStatDescriptor >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ': ';
		print: name
]

{ #category : 'accessing' }
GbxStatDescriptor >> printString [
	^ category
		ifNil: [ name, ': ', description ]
		ifNotNil: [ name, ' (', category, '): ', description ]
]

{ #category : 'initialize-release' }
GbxStatDescriptor >> setId: anInt [
	id ifNotNil: [ self error: 'GbxStatDescriptor>>setId initialized twice' ].
	id := anInt
]

{ #category : 'accessing' }
GbxStatDescriptor >> statClass [
	^ statClass
]

{ #category : 'accessing' }
GbxStatDescriptor >> statClass: aClass [
	statClass := aClass
]

{ #category : 'accessing' }
GbxStatDescriptor >> type [
	^ type ifNil: [ 5 ]
]

{ #category : 'accessing' }
GbxStatDescriptor >> type: anInteger [
	type := anInteger
]

{ #category : 'accessing' }
GbxStatDescriptor >> unit [
	^ unit ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxStatDescriptor >> unit: aString [
	unit := aString
]

{ #category : 'archiving' }
GbxStatDescriptor >> writeToArchiver: statArchiver [
	statArchiver writeString: name.
	statArchiver writeByte: self type.
	statArchiver writeBoolean: (isCounter ifNil: [ false ]).
	statArchiver writeBoolean: (isLargerBetter ifNil: [ false ]).
	statArchiver writeString: self unit.
	statArchiver writeString: (description ifNil: [ '' ])
]
