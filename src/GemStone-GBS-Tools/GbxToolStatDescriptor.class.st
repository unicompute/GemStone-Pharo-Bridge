Class {
	#name : 'GbxToolStatDescriptor',
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
GbxToolStatDescriptor class >> name: nameString description: descriptionString type: typeInt isCounter: isCounterBool isLargerBetter: isLargerBetterBool unit: unitString [
	^ self new
		name: nameString
		description: descriptionString
		type: typeInt
		isCounter: isCounterBool
		isLargerBetter: isLargerBetterBool
		unit: unitString
]

{ #category : 'instance creation' }
GbxToolStatDescriptor class >> named: aString description: desc category: cat [
	^ self new
		name: aString;
		description: desc;
		category: cat;
		yourself
]

{ #category : 'instance creation' }
GbxToolStatDescriptor class >> named: aString description: desc category: cat unit: aString [
	^ self new
		name: aString;
		description: desc;
		category: cat;
		unit: aString;
		yourself
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> category [
	^ category
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> category: aString [
	category := aString
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> description [
	^ description
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> description: aString [
	description := aString
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> id [
	^ id
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> isByte [
	^ type = 3
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> isLargerBetter: aBoolean [
	isLargerBetter := aBoolean
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> isShort [
	^ type = 4
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> name [
	^ name
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> name: aString [
	name := aString
]

{ #category : 'initialize-release' }
GbxToolStatDescriptor >> name: nameString description: descriptionString type: typeInt isCounter: isCounterBool isLargerBetter: isLargerBetterBool unit: unitString [
	name := nameString.
	description := descriptionString.
	type := typeInt.
	isCounter := isCounterBool.
	isLargerBetter := isLargerBetterBool.
	unit := unitString.
	^ self
]

{ #category : 'printing' }
GbxToolStatDescriptor >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ': ';
		print: name
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> printString [
	^ category
		ifNil: [ name, ': ', description ]
		ifNotNil: [ name, ' (', category, '): ', description ]
]

{ #category : 'initialize-release' }
GbxToolStatDescriptor >> setId: anInt [
	id ifNotNil: [ self error: 'GbxToolStatDescriptor>>setId initialized twice' ].
	id := anInt
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> statClass [
	^ statClass
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> statClass: aClass [
	statClass := aClass
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> type [
	^ type ifNil: [ 5 ]
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> type: anInteger [
	type := anInteger
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> unit [
	^ unit ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxToolStatDescriptor >> unit: aString [
	unit := aString
]

{ #category : 'archiving' }
GbxToolStatDescriptor >> writeToArchiver: statArchiver [
	statArchiver writeString: name.
	statArchiver writeByte: self type.
	statArchiver writeBoolean: (isCounter ifNil: [ false ]).
	statArchiver writeBoolean: (isLargerBetter ifNil: [ false ]).
	statArchiver writeString: self unit.
	statArchiver writeString: (description ifNil: [ '' ])
]
