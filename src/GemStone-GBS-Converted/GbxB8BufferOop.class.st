Class {
	#name : 'GbxB8BufferOop',
	#superclass : 'Gbx8BufferOop',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'constants' }
GbxB8BufferOop >> delegateClass
[
	^GbxB8Delegate
]

{ #category : 'oop access' }
GbxB8BufferOop >> oopNumberHighBytes
[
	^(buffer byteAt: offset + 2) * 16r100 + (buffer byteAt: offset + 3)
]

{ #category : 'oop access' }
GbxB8BufferOop >> oopShortAt: shortOffset
[
	| byteOffset |
	byteOffset := 2 * (shortOffset - 1).
	^(buffer byteAt: offset + byteOffset) * 16r100
		+ (buffer byteAt: offset + byteOffset + 1)
]

{ #category : 'oop access' }
GbxB8BufferOop >> oopNumberAt: byteOffset
[
	^buffer byteAt: offset + 1 + byteOffset
]

{ #category : 'oop access' }
GbxB8BufferOop >> oopByteAt: byteOffset put: byteValue
[
	^buffer
		byteAt: offset - 1 + byteOffset
		put: byteValue
]

{ #category : 'oop access' }
GbxB8BufferOop >> oopByteAt: byteOffset
[
	^buffer byteAt: offset - 1 + byteOffset
]

{ #category : 'oop access' }
GbxB8BufferOop >> oopNumberLower3
[
	^(buffer byteAt: offset + 4) * 16r10000
		+ ((buffer byteAt: offset + 5) * 16r100)
		+ (buffer byteAt: offset + 6)
]
