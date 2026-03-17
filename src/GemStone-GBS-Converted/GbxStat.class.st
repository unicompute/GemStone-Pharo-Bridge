Class {
	#name : 'GbxStat',
	#superclass : 'Object',
	#instVars : [
		'description',
		'lastArchivedValue',
		'value'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxStat >> incValue: delta
[

	value := value + delta
]

{ #category : 'accessing' }
GbxStat >> lastArchivedValue
[
	^lastArchivedValue
]

{ #category : 'accessing' }
GbxStat >> setValue: newValue
[

	value := newValue
]

{ #category : 'accessing' }
GbxStat >> value
[
	^value
]

{ #category : 'accessing' }
GbxStat >> description
[
	^description
]

{ #category : 'printing' }
GbxStat >> printOn: aStream
[

	super printOn: aStream.
	aStream nextPutAll: ' named: '.
	description name printOn: aStream.
	aStream nextPutAll: ' value: '.
	value printOn: aStream
]

{ #category : 'archiving' }
GbxStat >> closedArchive
[

	"Since GbxStat instances are cached across archives, lastArchivedValue needs to be 
	 set to nil after archive is closed."
	lastArchivedValue := nil
]

{ #category : 'archiving' }
GbxStat >> writeSampleTo: statArchive
[
	"The value to archive is the delta from the last archived value (unless this is the first write).
	If the delta is 0, don't archive it."

	| valueToWrite |
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

{ #category : 'initialize-release' }
GbxStat >> description: aGbxStatDescription value: initialValue
[
	description := aGbxStatDescription.
	value := initialValue
]

{ #category : 'instance creation' }
GbxStat class >> newWithDescription: aGbxStatDescription value: initialValue
[
	"Answer a newly created and initialized instance."

	^self basicNew description: aGbxStatDescription value: initialValue
]

{ #category : 'instance creation' }
GbxStat class >> new
[
	"Answer a newly created and initialized instance."

	^self shouldNotImplement
]

