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

{ #category : 'printing' }
GbxStatDescriptor >> printOn: aStream 
[
	super printOn: aStream.
	aStream
		nextPutAll: ': ';
		print: name
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
		unit: unitString
]
