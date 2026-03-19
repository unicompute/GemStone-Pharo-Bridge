Class {
	#name : 'Gbx8BufferOop',
	#superclass : 'GbxBufferOop',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
Gbx8BufferOop >> isEightByte
[
	^true
]

{ #category : 'comparing' }
Gbx8BufferOop >> sameOopAs: otherOop
[
	8
		to: 1
		by: -1
		do: [:i | (self oopByteAt: i) == (otherOop oopByteAt: i) ifFalse: [^false]].
	^true
]

{ #category : 'enumerating' }
Gbx8BufferOop >> increment
[
	"Increment my offset to point at the next oop in memory."

	offset := offset + 8
]

{ #category : 'printing' }
Gbx8BufferOop >> printOn: aStream
[
	| value |
	aStream nextPutAll: self class name.
	aStream nextPutAll: '{16r'.
	value := buffer unsignedLongLongAt: offset.
	value printOn: aStream base: 16.
	aStream nextPut: $}
]

{ #category : 'converting' }
Gbx8BufferOop >> asNewDelegateInSession: aSession
[
	| del |
	del := self delegateClass new.
	del
		gbxReplaceBytesFrom: 5 to: 12 with: buffer startingAt: offset;
		session: aSession.
	^del
]

{ #category : 'constants' }
Gbx8BufferOop >> bytesPerOop
[
	^8
]

{ #category : 'oop access' }
Gbx8BufferOop >> copyOopTo: delegate
[
	delegate gbxReplaceBytesFrom: 5 to: 12 with: buffer startingAt: offset
]

{ #category : 'oop access' }
Gbx8BufferOop >> oopByteAt: byteOffset put: byteValue
[
	^self subclassResponsibility
]

{ #category : 'oop access' }
Gbx8BufferOop >> copyOopFrom: delegate
[
	buffer
		gbxReplaceBytesFrom: offset
		to: offset + 7
		with: delegate
		startingAt: 5
]
