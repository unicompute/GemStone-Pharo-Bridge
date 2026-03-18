Class {
	#name : 'GbxStat',
	#superclass : 'Object',
	#instVars : [
		'name',
		'value',
		'delta',
		'lastValue',
		'timestamp',
		'description',
		'lastArchivedValue'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxStat class >> named: aString [
	^ self new
		name: aString;
		yourself
]

{ #category : 'instance creation' }
GbxStat class >> named: aString value: aNumber [
	^ self new
		name: aString;
		value: aNumber;
		yourself
]

{ #category : 'instance creation' }
GbxStat class >> newWithDescription: aGbxStatDescription value: initialValue [
	^ self basicNew
		description: aGbxStatDescription
		value: initialValue
]

{ #category : 'comparing' }
GbxStat >> = anObject [
	^ (anObject isKindOf: GbxStat)
		and: [ self name = anObject name ]
]

{ #category : 'archiving' }
GbxStat >> closedArchive [
	lastArchivedValue := nil
]

{ #category : 'accessing' }
GbxStat >> description [
	^ description
]

{ #category : 'initialize-release' }
GbxStat >> description: aGbxStatDescription value: initialValue [
	description := aGbxStatDescription.
	name ifNil: [ name := aGbxStatDescription name ].
	value := initialValue.
	^ self
]

{ #category : 'accessing' }
GbxStat >> delta [
	^ delta ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxStat >> delta: aNumber [
	delta := aNumber
]

{ #category : 'accessing' }
GbxStat >> hash [
	^ self name hash
]

{ #category : 'accessing' }
GbxStat >> incValue: aDelta [
	value := self value + aDelta
]

{ #category : 'accessing' }
GbxStat >> lastValue [
	^ lastValue
]

{ #category : 'accessing' }
GbxStat >> lastValue: aNumber [
	lastValue := aNumber
]

{ #category : 'accessing' }
GbxStat >> name [
	^ name ifNil: [ description ifNil: [ nil ] ifNotNil: [ description name ] ]
]

{ #category : 'accessing' }
GbxStat >> name: aString [
	name := aString
]

{ #category : 'printing' }
GbxStat >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' named: '.
	self name printOn: aStream.
	aStream nextPutAll: ' value: '.
	self value printOn: aStream
]

{ #category : 'accessing' }
GbxStat >> printString [
	^ self name, ': ', self value asString, ' (Δ', self delta asString, ')'
]

{ #category : 'accessing' }
GbxStat >> reset [
	"Reset the stat to zero"
	lastValue := value.
	value := 0.
	delta := 0.
	timestamp := DateAndTime now.
]

{ #category : 'accessing' }
GbxStat >> timestamp [
	^ timestamp
]

{ #category : 'accessing' }
GbxStat >> timestamp: aDateAndTime [
	timestamp := aDateAndTime
]

{ #category : 'accessing' }
GbxStat >> update [
	"Update the stat value and calculate delta"
	lastValue := value.
	delta := 0.
	timestamp := DateAndTime now.
]

{ #category : 'accessing' }
GbxStat >> updateValue: aNumber [
	"Update the stat value and calculate delta"
	lastValue := value.
	value := aNumber.
	delta := ((value isNumber and: [ lastValue isNumber ])
		ifTrue: [ value - lastValue ]
		ifFalse: [ 0 ]).
	timestamp := DateAndTime now.
]

{ #category : 'accessing' }
GbxStat >> value [
	^ value ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxStat >> value: aNumber [
	value := aNumber
]

{ #category : 'accessing' }
GbxStat >> setValue: newValue [
	value := newValue
]

{ #category : 'archiving' }
GbxStat >> writeSampleTo: statArchive [
	| valueToWrite type |
	description ifNil: [ ^ self ].
	lastArchivedValue isNil
		ifTrue: [ valueToWrite := self value ]
		ifFalse: [
			valueToWrite := self value - lastArchivedValue.
			valueToWrite = 0 ifTrue: [ ^ self ] ].
	statArchive writeByte: description id.
	lastArchivedValue := self value.
	type := description type.
	type = 3
		ifTrue: [ ^ statArchive writeByte: valueToWrite ].
	type = 4
		ifTrue: [ ^ statArchive writeShort: valueToWrite ].
	statArchive writeCompressedNumber: valueToWrite
]
