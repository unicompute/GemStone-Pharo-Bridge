Class {
	#name : 'GbxL8BufferOop',
	#superclass : 'Gbx8BufferOop',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'constants' }
GbxL8BufferOop >> delegateClass
[
	^GbxL8Delegate
]

{ #category : 'oop access' }
GbxL8BufferOop >> oopByteAt: byteOffset
[
	^buffer byteAt: offset + 8 - byteOffset
]

{ #category : 'oop access' }
GbxL8BufferOop >> oopNumberLower3
[
	^(buffer byteAt: offset + 3) * 16r10000
		+ ((buffer byteAt: offset + 2) * 16r100)
		+ (buffer byteAt: offset + 1)
]

{ #category : 'oop access' }
GbxL8BufferOop >> oopNumberHighBytes
[
	^(buffer byteAt: offset + 5) * 16r100 + (buffer byteAt: offset + 4)
]

{ #category : 'oop access' }
GbxL8BufferOop >> oopShortAt: shortOffset
[
	| byteOffset |
	byteOffset := 8 - (shortOffset * 2).
	^(buffer byteAt: offset + byteOffset + 1) * 16r100
		+ (buffer byteAt: offset + byteOffset)
]

{ #category : 'oop access' }
GbxL8BufferOop >> oopNumberAt: byteOffset
[
	^buffer byteAt: offset + 6 - byteOffset
]

{ #category : 'oop access' }
GbxL8BufferOop >> oopByteAt: byteOffset put: byteValue
[
	^buffer
		byteAt: offset + 8 - byteOffset
		put: byteValue
]
