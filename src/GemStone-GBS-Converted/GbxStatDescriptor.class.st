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

{ #category : 'accessing' }
GbxStatDescriptor >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxStatDescriptor >> setId: anInteger [
	id := anInteger
]

{ #category : 'accessing' }
GbxStatDescriptor >> type [
	^ type
]

{ #category : 'accessing' }
GbxStatDescriptor >> type: aSymbol [
	type := aSymbol
]

{ #category : 'accessing' }
GbxStatDescriptor >> unit [
	^ unit
]

{ #category : 'accessing' }
GbxStatDescriptor >> unit: aString [
	unit := aString
]
