Class {
	#name : 'GbxStatDescriptor',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'category',
		'unit',
		'statClass'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

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
GbxStatDescriptor >> name [
	^ name
]

{ #category : 'accessing' }
GbxStatDescriptor >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxStatDescriptor >> printString [
	^ name, ' (', category, '): ', description
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
GbxStatDescriptor >> unit [
	^ unit ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxStatDescriptor >> unit: aString [
	unit := aString
]
