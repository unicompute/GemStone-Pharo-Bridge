Class {
	#name : 'GbxTraversalBuffer6432',
	#superclass : 'GbxTraversalBuffer64',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private' }
GbxTraversalBuffer6432 >> allocatedBytes
[
	"The first eight bytes of the trav buffer are the number of bytes allocated."
	
	^data unsignedLongAt: 1
]

{ #category : 'private' }
GbxTraversalBuffer6432 >> usedBytes
[
	
	^data unsignedLongAt: 5
]

{ #category : 'private' }
GbxTraversalBuffer6432 >> allocatedBytes: numBytes
[
	"The first eight bytes of the trav buffer are the number of bytes allocated."
	
	data unsignedLongAt: 1 put: numBytes
]

{ #category : 'private' }
GbxTraversalBuffer6432 >> headerSize
[
	"Answer the number of bytes in the buffer before the first object report"
	
	^8
]

{ #category : 'private' }
GbxTraversalBuffer6432 >> usedBytes: numBytes
[
	"Store the number of bytes used into the buffer's header. Bytes should represent only
	the bytes used for object reports, and should not include the bytes in the buffer header."
	
	data unsignedLongAt: 5 put: numBytes
]

