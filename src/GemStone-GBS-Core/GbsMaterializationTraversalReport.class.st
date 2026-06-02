Class {
	#name : 'GbsMaterializationTraversalReport',
	#superclass : 'Object',
	#instVars : [
		'oop',
		'classOop',
		'objectFormat',
		'byteSwizzle',
		'indexedSize',
		'namedSize',
		'firstOffset',
		'valueBytes',
		'valueOops'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> byteSwizzle [
	^ byteSwizzle ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> byteSwizzle: anInteger [
	byteSwizzle := anInteger
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> classOop [
	^ classOop
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> classOop: anInteger [
	classOop := anInteger
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> firstOffset [
	^ firstOffset
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> firstOffset: anInteger [
	firstOffset := anInteger
]

{ #category : 'testing' }
GbsMaterializationTraversalReport >> hasByteValue [
	^ objectFormat = 1
]

{ #category : 'testing' }
GbsMaterializationTraversalReport >> hasOopValue [
	^ objectFormat = 0 or: [ objectFormat = 2 ]
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> indexedSize [
	^ indexedSize
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> indexedSize: anInteger [
	indexedSize := anInteger
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> namedSize [
	^ namedSize
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> namedSize: anInteger [
	namedSize := anInteger
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> objectFormat [
	^ objectFormat
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> objectFormat: anInteger [
	objectFormat := anInteger
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> oop [
	^ oop
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> oop: anInteger [
	oop := anInteger
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> valueBytes [
	^ valueBytes ifNil: [ ByteArray new ]
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> valueBytes: aByteArray [
	valueBytes := aByteArray
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> valueOops [
	^ valueOops ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsMaterializationTraversalReport >> valueOops: anArray [
	valueOops := anArray
]
