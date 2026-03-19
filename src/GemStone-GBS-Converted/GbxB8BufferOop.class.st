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
	^(buffer basicAt: offset + 2) * 16r100 + (buffer basicAt: offset + 3)
]

{ #category : 'oop access' }
GbxB8BufferOop >> oopShortAt: shortOffset
[
	| byteOffset |
	byteOffset := 2 * (shortOffset - 1).
	^(buffer basicAt: offset + byteOffset) * 16r100
		+ (buffer basicAt: offset + byteOffset + 1)
]

{ #category : 'oop access' }
GbxB8BufferOop >> oopNumberAt: byteOffset
[
	^buffer basicAt: offset + 1 + byteOffset
]

{ #category : 'oop access' }
GbxB8BufferOop >> oopByteAt: byteOffset put: byteValue
[
	^buffer
		basicAt: offset - 1 + byteOffset
		put: byteValue
]

{ #category : 'oop access' }
GbxB8BufferOop >> oopByteAt: byteOffset
[
	^buffer basicAt: offset - 1 + byteOffset
]

{ #category : 'oop access' }
GbxB8BufferOop >> oopNumberLower3
[
	^(buffer basicAt: offset + 4) * 16r10000
		+ ((buffer basicAt: offset + 5) * 16r100)
		+ (buffer basicAt: offset + 6)
]
