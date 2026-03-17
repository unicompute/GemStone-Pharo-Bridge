Class {
	#name : #'GbxB8OopArray',
	#superclass : #'GbxOopArray64',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'putting' }
GbxB8OopArray >> addUpper: upperBytes lower3: lower3
	"Given a pair of SmallIntegers, one that represent the lower three bytes of the oop number and 
	one that represents the upper two bytes, adds an 8-byte POM oop to the buffer.
	The eight bytes of the oop are:
       00 00 U1 U0 L2 L1 L0 01"
	"This version is specific to little-endian clients"
	"To avoid creating large integers, we do the writing as one 32-bit write
	(we know that the upper two bytes are always zero, so it's always a SmallInteger)
	and two 16-bit writes."
	
	| l2l1 l0 start |
	numOops >= self bufferSize ifTrue: [self grow].
	l2l1 := lower3 bitShift: -8.
	l0 := lower3 bitAnd: 16rFF.	"The 1 below is the tag byte for POM oops."
	start := numOops * 8 + 1.
	buffer unsignedLongAt: start put: upperBytes.
	buffer
		unsignedShortAt: start + 4
		put: l2l1.
	buffer
		unsignedShortAt: start + 6
		put: l0 * 16r100 + 1.
	numOops := numOops + 1

{ #category : #'private' }
GbxB8OopArray >> bufferOopClass
	
	^GbxB8BufferOop

