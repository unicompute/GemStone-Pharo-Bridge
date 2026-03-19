Class {
	#name : 'GbxBufferOop',
	#superclass : 'Object',
	#instVars : [
		'buffer',
		'offset'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxBufferOop class >> fromBuffer: anUninterpretedBytes offset: byteOffset
[
	"The oop is 4 or 8 bytes starting at byteOffset into anUninterpretedBytes."

	| inst |
	inst := self new.
	inst setBufferTo: anUninterpretedBytes.
	inst setOffsetTo: byteOffset.
	^inst
]

{ #category : 'oop access' }
GbxBufferOop >> oopNumberHighBytes
[
	^self subclassResponsibility
]

{ #category : 'oop access' }
GbxBufferOop >> oopNumberLower3
[
	^self subclassResponsibility
]

{ #category : 'comparing' }
GbxBufferOop >> = otherOop
[
	otherOop class == self class ifFalse: [^false].
	^self sameOopAs: otherOop
]

{ #category : 'comparing' }
GbxBufferOop >> sameOopAs: otherOop
[
	^self subclassResponsibility
]

{ #category : 'accessing' }
GbxBufferOop >> buffer
[
	^buffer
]

{ #category : 'accessing' }
GbxBufferOop >> offset
[
	^offset
]

{ #category : 'accessing' }
GbxBufferOop >> setOffsetTo: byteOffset
[
	"Offset is 1-based."

	offset := byteOffset
]

{ #category : 'accessing' }
GbxBufferOop >> setBufferTo: anUninterpretedBytes
[
	buffer := anUninterpretedBytes.
	self setOffsetTo: 1
]

{ #category : 'converting' }
GbxBufferOop >> asGSObjectInSession: aSession
[
	"Sender must hold the session's sessionProtect."

	^(aSession isSpecialOop: self)
		ifTrue: [self asNewDelegateInSession: aSession]
		ifFalse: [aSession delegateForOop: self]
]

{ #category : 'converting' }
GbxBufferOop >> asNewDelegateInSession: aSession
[
	^self subclassResponsibility
]

{ #category : 'constants' }
GbxBufferOop >> bytesPerOop
[
	^self subclassResponsibility
]

{ #category : 'constants' }
GbxBufferOop >> delegateClass
[
	^self subclassResponsibility
]

{ #category : 'gemstone private' }
GbxBufferOop >> gbxExistingOrSpecialDelegateInSession: aSession
[
	"Sender must hold the session's sessionProtect."

	^(aSession isSpecialOop: self)
		ifTrue: [self asNewDelegateInSession: aSession]
		ifFalse: [nil]
]
