Class {
	#name : 'GbxToolStat',
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
GbxToolStat class >> named: aString [
	^ self new
		name: aString;
		yourself
]

{ #category : 'instance creation' }
GbxToolStat class >> named: aString value: aNumber [
	^ self new
		name: aString;
		value: aNumber;
		yourself
]

{ #category : 'instance creation' }
GbxToolStat class >> newWithDescription: aGbxStatDescription value: initialValue [
	^ self basicNew
		description: aGbxStatDescription
		value: initialValue
]

{ #category : 'comparing' }
GbxToolStat >> = anObject [
	^ (anObject isKindOf: GbxToolStat)
		and: [ self name = anObject name ]
]

{ #category : 'archiving' }
GbxToolStat >> closedArchive [
	lastArchivedValue := nil
]

{ #category : 'accessing' }
GbxToolStat >> delta [
	^ delta ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxToolStat >> delta: aNumber [
	delta := aNumber
]

{ #category : 'accessing' }
GbxToolStat >> description [
	^ description
]

{ #category : 'initialize-release' }
GbxToolStat >> description: aGbxStatDescription value: initialValue [
	description := aGbxStatDescription.
	name ifNil: [ name := aGbxStatDescription name ].
	value := initialValue.
	^ self
]

{ #category : 'accessing' }
GbxToolStat >> hash [
	^ self name hash
]

{ #category : 'accessing' }
GbxToolStat >> incValue: aDelta [
	value := self value + aDelta
]

{ #category : 'accessing' }
GbxToolStat >> lastValue [
	^ lastValue
]

{ #category : 'accessing' }
GbxToolStat >> lastValue: aNumber [
	lastValue := aNumber
]

{ #category : 'accessing' }
GbxToolStat >> name [
	^ name ifNil: [ description ifNil: [ nil ] ifNotNil: [ description name ] ]
]

{ #category : 'accessing' }
GbxToolStat >> name: aString [
	name := aString
]

{ #category : 'printing' }
GbxToolStat >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' named: '.
	self name printOn: aStream.
	aStream nextPutAll: ' value: '.
	self value printOn: aStream
]

{ #category : 'accessing' }
GbxToolStat >> printString [
	^ self name, ': ', self value asString, ' (Δ', self delta asString, ')'
]

{ #category : 'accessing' }
GbxToolStat >> reset [
	"Reset the stat to zero"
	lastValue := value.
	value := 0.
	delta := 0.
	timestamp := DateAndTime now.
]

{ #category : 'accessing' }
GbxToolStat >> setValue: newValue [
	value := newValue
]

{ #category : 'accessing' }
GbxToolStat >> timestamp [
	^ timestamp
]

{ #category : 'accessing' }
GbxToolStat >> timestamp: aDateAndTime [
	timestamp := aDateAndTime
]

{ #category : 'accessing' }
GbxToolStat >> update [
	"Update the stat value and calculate delta"
	lastValue := value.
	delta := 0.
	timestamp := DateAndTime now.
]

{ #category : 'accessing' }
GbxToolStat >> updateValue: aNumber [
	"Update the stat value and calculate delta"
	lastValue := value.
	value := aNumber.
	delta := ((value isNumber and: [ lastValue isNumber ])
		ifTrue: [ value - lastValue ]
		ifFalse: [ 0 ]).
	timestamp := DateAndTime now.
]

{ #category : 'accessing' }
GbxToolStat >> value [
	^ value ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxToolStat >> value: aNumber [
	value := aNumber
]

{ #category : 'archiving' }
GbxToolStat >> writeSampleTo: statArchive [
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
