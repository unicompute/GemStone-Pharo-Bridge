Class {
	#name : 'GbxObjectMemoryStat',
	#superclass : 'GbxStat',
	#instVars : [
		'selector'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxObjectMemoryStat >> description: aStatDescriptor [
	description := aStatDescriptor.
	^ self
]

{ #category : 'instance creation' }
GbxObjectMemoryStat class >> newFor: aSelector [
	^ self basicNew selector: aSelector
]

{ #category : 'instance creation' }
GbxObjectMemoryStat class >> newWithDescription: aDescription [
	^ self basicNew description: aDescription
]

{ #category : 'archiving' }
GbxObjectMemoryStat >> numericValueFrom: anObjectMemory [
	| rawValue |

	(anObjectMemory isNil or: [ (anObjectMemory respondsTo: self selector) not ])
		ifTrue: [ ^ 0 ].
	rawValue := anObjectMemory perform: self selector.
	^ rawValue ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> selector [
	selector ifNil: [ selector := description name asSymbol ].
	^ selector
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> selector: aSelector [
	selector := aSelector.
	^ self
]

{ #category : 'archiving' }
GbxObjectMemoryStat >> writeSampleFrom: anObjectMemory to: statArchive [
	| valueToWrite |

	value := self numericValueFrom: anObjectMemory.
	lastArchivedValue isNil
		ifTrue: [ valueToWrite := value ]
		ifFalse: [
			valueToWrite := value - lastArchivedValue.
			valueToWrite = 0 ifTrue: [ ^ self ] ].
	statArchive writeByte: description id.
	lastArchivedValue := value.
	description isByte
		ifTrue: [ ^ statArchive writeByte: valueToWrite ].
	description isShort
		ifTrue: [ ^ statArchive writeShort: valueToWrite ].
	statArchive writeCompressedNumber: valueToWrite
]
