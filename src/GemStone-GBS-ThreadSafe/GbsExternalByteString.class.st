"
A C, null-terminated byte string allocated on the C heap. Caller must free it
(track it with a GbsMemoryTracker). Ported from PharoGemStoneFFI
(GsExternalByteString).

Replaces the manual unsignedByteAt:put: null-termination loops in the bridge's
legacy executeAndFetchString:/fetchString:.
"
Class {
	#name : 'GbsExternalByteString',
	#superclass : 'FFIExternalArray',
	#category : 'GemStone-GBS-ThreadSafe',
	#package : 'GemStone-GBS-ThreadSafe'
}

{ #category : 'instance creation' }
GbsExternalByteString class >> new [
	"Use new: or newWithNull:"
	^ self shouldNotImplement
]

{ #category : 'instance creation' }
GbsExternalByteString class >> new: aSize [
	"Create a buffer of exactly aSize bytes. Does NOT reserve a byte for a
	trailing NULL -- use newWithNull: for that."
	^ self externalNewType: 'char' size: aSize
]

{ #category : 'instance creation' }
GbsExternalByteString class >> newFromByteString: aByteString [
	"Create an external C string copied from aByteString with a trailing NULL.
	Caller must free the result."
	| sz result |
	sz := aByteString size.
	result := self newWithNull: sz.
	1 to: sz do: [ :n | result at: n put: (aByteString at: n) ].
	result at: sz + 1 put: Character null.
	^ result
]

{ #category : 'instance creation' }
GbsExternalByteString class >> newWithNull: aSize [
	"Create a buffer with room for aSize bytes plus a terminating NULL."
	^ self new: aSize + 1
]

{ #category : 'converting' }
GbsExternalByteString >> asByteArrayOfSize: aSize [
	| result |
	aSize > self size ifTrue: [
		^ self error: ('Attempt to create a ByteArray larger than my size ('
			, aSize asString , ' > ' , self size asString , ')') ].
	result := ByteArray new: aSize.
	1 to: aSize do: [ :e | result at: e put: (self at: e) asInteger ].
	^ result
]

{ #category : 'converting' }
GbsExternalByteString >> asByteStringOfSize: requestedSize [
	"Answer a ByteString of min(my size, requestedSize) bytes."
	| resultSize result |
	resultSize := requestedSize min: self size.
	result := ByteString new: resultSize.
	1 to: resultSize do: [ :i | result at: i put: (self at: i) ].
	^ result
]

{ #category : 'accessing' }
GbsExternalByteString >> sizeNoNull [
	^ size - 1
]
