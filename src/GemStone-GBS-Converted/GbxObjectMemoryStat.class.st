Class {
	#name : 'GbxObjectMemoryStat',
	#superclass : 'GbxStat',
	#instVars : [
		'selector'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'archiving' }
GbxObjectMemoryStat >> writeSampleFrom: anObjectMemory to: statArchive
[
	"Descriptor number"
	"The value to archive is the delta from the last archived value (unless this is the first write).
	If the delta is 0, don't archive it."

	| valueToWrite |
	value := self numericValueFrom: anObjectMemory.
	lastArchivedValue isNil
		ifTrue: [valueToWrite := value]
		ifFalse: 
			[valueToWrite := value - lastArchivedValue.
			valueToWrite == 0 ifTrue: [^self]].
	statArchive writeByte: description id.
	lastArchivedValue := value.
	"Write the value in a format according to its type - see GFS_File_Format.doc"
	description isByte
		ifTrue: [statArchive writeByte: valueToWrite]
		ifFalse: 
			[description isShort
				ifTrue: [statArchive writeShort: valueToWrite]
				ifFalse: [statArchive writeCompressedNumber: valueToWrite]]
]

{ #category : 'archiving' }
GbxObjectMemoryStat >> numericValueFrom: anObjectMemory
[
	"Deprecated values such as #enumerationCallsPerMillisecond may answer nil
	on newer VMs that do not update the stat. However, we still want the stat
	on older VMs that do support the statistic."

	| rawValue |
	rawValue := anObjectMemory perform: self selector.
	^rawValue == nil 
		ifTrue: [0] 
		ifFalse: [rawValue]
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> selector
[

	selector == nil ifTrue: [selector := description name asSymbol].
	^selector
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> description: aStatDescriptor
[

	description := aStatDescriptor
]

{ #category : 'instance creation' }
GbxObjectMemoryStat class >> newFor: selector
[

	^self basicNew
		selector: selector;
		yourself
]

{ #category : 'instance creation' }
GbxObjectMemoryStat class >> newWithDescription: description
[

	^self basicNew
		description: description;
		yourself
]
