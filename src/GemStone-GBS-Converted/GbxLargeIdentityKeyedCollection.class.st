Class {
	#name : 'GbxLargeIdentityKeyedCollection',
	#superclass : 'Object',
	#instVars : [
		'keys',
		'values',
		'owner',
		'tableSize',
		'storage'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'adding' }
GbxLargeIdentityKeyedCollection >> addAll: aCollection [
	aCollection keysAndValuesDo: [ :key :value | storage at: key put: value ].
	^ aCollection
]

{ #category : 'converting' }
GbxLargeIdentityKeyedCollection >> asDictionary [
	^ storage copy
]

{ #category : 'enumeration' }
GbxLargeIdentityKeyedCollection >> do: aBlock [
	storage valuesDo: aBlock
]

{ #category : 'finalization' }
GbxLargeIdentityKeyedCollection >> encourageFinalization [
	^ self
]

{ #category : 'finalization' }
GbxLargeIdentityKeyedCollection >> finalizeCritical: aBlock [
	^ aBlock value
]

{ #category : 'key comparison' }
GbxLargeIdentityKeyedCollection >> hashForKey: aKey [
	^ aKey identityHash
]

{ #category : 'initialization' }
GbxLargeIdentityKeyedCollection >> initialize [
	super initialize.
	storage := IdentityDictionary new.
	tableSize := 0
]

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> keyAt: index [
	^ storage keys
		at: index
		ifAbsent: [ nil ]
]

{ #category : 'printing' }
GbxLargeIdentityKeyedCollection >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ' size: ';
		print: storage size
]

{ #category : 'removing' }
GbxLargeIdentityKeyedCollection >> removeKey: key [
	^ storage removeKey: key ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> size [
	^ storage size
]

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> species [
	^ self class
]

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> storage [
	^ storage
]

{ #category : 'testing' }
GbxLargeIdentityKeyedCollection >> valueClass [
	^ Object
]
