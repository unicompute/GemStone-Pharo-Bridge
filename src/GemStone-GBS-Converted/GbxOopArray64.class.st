Class {
	#name : 'GbxOopArray64',
	#superclass : 'GbxOopArray',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxOopArray64 >> bufferSize
[
	"Return the size of the allocated buffer in oops, assuming it's all mine, i.e. that I was created with size:."
	
	^buffer basicSize bitShift: -3
]

{ #category : 'random-access putting' }
GbxOopArray64 >> oopAt: idx putDelegate: aDelegate
[
	"Put the oop value of aDelegate at 1-based index <idx>. 

	Used for packing store traversals. Does not update numOops, which is for the other usage pattern."
	
	| firstOffset |
	firstOffset := offset + ((idx - 1) * 8).
	buffer
		gbxReplaceBytesFrom: firstOffset
		to: firstOffset + 7
		with: aDelegate
		startingAt: 5
]

{ #category : 'random-access putting' }
GbxOopArray64 >> oopAt: idx put: anInteger
[
	"Put the oop value <anInteger> at index <idx>.  This method takes care of platform specific access
	and conversion from 1-based Smalltalk indexes to 0-base C indexes.

	Used for packing store traversals. Does not update numOops, which is for the other usage pattern."
	
	buffer
		unsignedLongLongAt: offset + ((idx - 1) * 8)
		put: anInteger
]

{ #category : 'printing' }
GbxOopArray64 >> printValueAt: idx on: aStream
[
	"Return the oop value from 1-based index <idx>. "
	
	aStream nextPutAll: '16r'.
	(buffer unsignedLongLongAt: (idx - 1) * 8 + offset) printOn: aStream base:
			16.
	aStream space
]

{ #category : 'adding' }
GbxOopArray64 >> addFromDelegate: delegate
[
	"Given a delegate of the same endianness as the oop buffer, adds an 8-byte POM oop to the buffer."
	
	| start |
	numOops >= self bufferSize ifTrue: [self grow].
	start := numOops * 8 + 1.
	buffer
		gbxReplaceBytesFrom: start
		to: start + 7
		with: delegate
		startingAt: 5.
	numOops := numOops + 1
]

{ #category : 'constants' }
GbxOopArray64 >> bytesPerOop
[
	
	^8
]

