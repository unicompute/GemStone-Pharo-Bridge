Class {
	#name : 'GbxTraversalBuffer64',
	#superclass : 'GbxTraversalBuffer',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxTraversalBuffer64 >> sizeInBytesOfReport
[
	"Return the size in bytes of the current report. Only valid after the report's header has been filled in."

	^Gbx8ObjectReport fixedSize + (self wordAlign: objectReport valueBuffSize)
]

{ #category : 'support' }
GbxTraversalBuffer64 >> wordAlign: integerOffset
[
	"Answer the smallest 64-bit aligned address >= integerOffset"
	"WARNING: Does not work with offsets outside of (or approaching the limits of) SmallInteger range.
	Use only on offsets, not actual addresses."
	
	^integerOffset + 7 bitAnd: 16rFFFFFF8
]

{ #category : 'private' }
GbxTraversalBuffer64 >> objRepTypeClass
[

	^EndianDetector isBigEndian
		ifTrue: [GbxB8v3ObjectReport]
		ifFalse: [GbxL8v3ObjectReport]
]

{ #category : 'private' }
GbxTraversalBuffer64 >> headerSize
[
	"Answer the number of bytes in the buffer before the first object report"
	
	^16
]

{ #category : 'private' }
GbxTraversalBuffer64 >> allocatedBytes: numBytes
[
	"The first eight bytes of the trav buffer are the number of bytes allocated."
	
	data unsignedLongLongAt: 1 put: numBytes
]

{ #category : 'private' }
GbxTraversalBuffer64 >> usedBytes: numBytes
[
	"Store the number of bytes used into the buffer's header. Bytes should represent only
	the bytes used for object reports, and should not include the bytes in the buffer header."
	
	data unsignedLongLongAt: 9 put: numBytes
]

{ #category : 'private' }
GbxTraversalBuffer64 >> allocatedBytes
[
	"The first eight bytes of the trav buffer are the number of bytes allocated."
	
	^data unsignedLongLongAt: 1
]

{ #category : 'private' }
GbxTraversalBuffer64 >> usedBytes
[
	
	^data unsignedLongLongAt: 9
]
