Class {
	#name : #'GbxL8Delegate',
	#superclass : #'Gbx8Delegate',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'private - oop access' }
GbxL8Delegate >> oopNumberHighBytes
	"Returns the SmallInteger representation of the 1 or 2 most significant bytes
	 of the oop number (all but the lower three).  For 4 byte oops this is byte 1 (the most 
	 significant byte).  For 8 byte oops, it's bytes 3-4.  This value is used as an index in the
	top level of the serverMap."

	^(self basicAt: 10) * 16r100 + (self basicAt: 9)

{ #category : #'oop access' }
GbxL8Delegate >> oopByteAt: byteOffset 
	"Return the byte of the oop at the given byteOffset, starting from the 
	 high order byte.  For example, (aDelegate oopAt: 1) returns the most 
	 significant byte of the receiver's oop."

	^self basicAt: 13 - byteOffset

{ #category : #'oop access' }
GbxL8Delegate >> oopNumberAt: byteOffset 
	"Return the byte of the oop at the given byteOffset, starting from the 
	 first used high order byte.  For 4 byte oops, this is identical to oopAt:.
	 For 8 byte oops, the two highest order bytes are always 0, so for
	 example, (aDelegate oopNumberAt: 1) is equivalent to (aDelegate oopAt: 3)"

	^self basicAt: 11 - byteOffset

{ #category : #'oop access' }
GbxL8Delegate >> oopNumberLower3
	"Returns the SmallInteger representation of the 3 least significant bytes
	 of the oop number.  For 4 byte oops this is bytes 2-4 (all but the most 
	 significant byte).  For 8 byte oops, it's bytes 5-7 (byte 8 doesn't count
	 because it only contains flags).  This value is used as the key in the
	 hash dictionary that is the bottom tier of the gs-to-st cache."
	
	^(self basicAt: 8) * 16r10000 + ((self basicAt: 7) * 16r100)
		+ (self basicAt: 6)

{ #category : #'oop access' }
GbxL8Delegate >> oopByteAt: byteOffset put: byteValue 
	"Set the byte of the oop at the given byteOffset, starting from the 
	 high order byte.  For example, (aDelegate oopAt: 1 put: 42) sets the most 
	 significant byte of the receiver's oop."

	^self basicAt: 13 - byteOffset put: byteValue

{ #category : #'constants' }
GbxL8Delegate class >> bytesPerOop
	^8

