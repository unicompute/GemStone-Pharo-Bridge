Class {
	#name : 'GbxStat',
	#superclass : 'Object',
	#instVars : [
		'description',
		'lastArchivedValue',
		'value'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

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
	value := initialValue.
	^ self
]

{ #category : 'accessing' }
GbxStat >> incValue: aDelta [
	value := self value + aDelta
]

{ #category : 'accessing' }
GbxStat >> name [
	^ description ifNil: [ nil ] ifNotNil: [ description name ]
]

{ #category : 'instance creation' }
GbxStat class >> newWithDescription: aGbxStatDescription value: initialValue [
	^ self basicNew description: aGbxStatDescription value: initialValue
]

{ #category : 'printing' }
GbxStat >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' named: '.
	description name printOn: aStream.
	aStream nextPutAll: ' value: '.
	self value printOn: aStream
]

{ #category : 'accessing' }
GbxStat >> setValue: aNumber [
	value := aNumber
]

{ #category : 'accessing' }
GbxStat >> value [
	^ value ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxStat >> value: aNumber [
	value := aNumber
]

{ #category : 'archiving' }
GbxStat >> writeSampleTo: statArchive [
	| valueToWrite |

	lastArchivedValue isNil
		ifTrue: [ valueToWrite := self value ]
		ifFalse: [
			valueToWrite := self value - lastArchivedValue.
			valueToWrite = 0 ifTrue: [ ^ self ] ].
	statArchive writeByte: description id.
	lastArchivedValue := self value.
	description isByte
		ifTrue: [ ^ statArchive writeByte: valueToWrite ].
	description isShort
		ifTrue: [ ^ statArchive writeShort: valueToWrite ].
	statArchive writeCompressedNumber: valueToWrite
]
