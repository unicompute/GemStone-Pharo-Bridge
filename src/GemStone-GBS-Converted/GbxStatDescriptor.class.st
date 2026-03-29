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
		'unit'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxStatDescriptor class >> name: aName description: aDescription type: aType isCounter: isCounterBool isLargerBetter: isLargerBool unit: aUnit [
	^ self new
		name: aName;
		description: aDescription;
		type: aType;
		isCounter: isCounterBool;
		isLargerBetter: isLargerBool;
		unit: aUnit;
		yourself
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
GbxStatDescriptor >> id: anInteger [
	id := anInteger
]

{ #category : 'accessing' }
GbxStatDescriptor >> isCounter [
	^ isCounter
]

{ #category : 'accessing' }
GbxStatDescriptor >> isCounter: aBoolean [
	isCounter := aBoolean
]

{ #category : 'accessing' }
GbxStatDescriptor >> isLargerBetter [
	^ isLargerBetter
]

{ #category : 'accessing' }
GbxStatDescriptor >> isLargerBetter: aBoolean [
	isLargerBetter := aBoolean
]

{ #category : 'accessing' }
GbxStatDescriptor >> name [
	^ name
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

{ #category : 'accessing' }
GbxStatDescriptor >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxStatDescriptor >> setId: anInteger [
	id ifNotNil: [ self error: 'GbxStatDescriptor>>setId initialized twice' ].
	id := anInteger
]

{ #category : 'accessing' }
GbxStatDescriptor >> type [
	^ type ifNil: [ GbxStatArchiver TypeInt32 ]
]

{ #category : 'accessing' }
GbxStatDescriptor >> type: anInteger [
	type := anInteger
]

{ #category : 'accessing' }
GbxStatDescriptor >> unit [
	^ unit
]

{ #category : 'accessing' }
GbxStatDescriptor >> unit: aString [
	unit := aString
]

{ #category : 'accessing' }
GbxStatDescriptor >> isByte [
	^ self type = GbxStatArchiver TypeByte8
]

{ #category : 'accessing' }
GbxStatDescriptor >> isShort [
	^ self type = GbxStatArchiver TypeShort16
]

{ #category : 'printing' }
GbxStatDescriptor >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ': ';
		print: name
]

{ #category : 'archiving' }
GbxStatDescriptor >> writeToArchiver: statArchiver [
	statArchiver
		writeString: name;
		writeByte: self type;
		writeBoolean: (isCounter ifNil: [ false ]);
		writeBoolean: (isLargerBetter ifNil: [ false ]);
		writeString: self unit;
		writeString: (description ifNil: [ '' ])
]
