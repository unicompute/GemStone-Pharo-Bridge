Class {
	#name : 'GbxLargeIdentityDictionary',
	#superclass : 'GbxLargeIdentityKeyedCollection',
	#instVars : [
		'weakness',
		'numElements',
		'buckets',
		'accessProtect',
		'removalSelector',
		'reduceAfter',
		'initialBucketSize',
		'bucketSlotsGrown'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxLargeIdentityDictionary >> accessProtect [
	^ accessProtect
]

{ #category : 'private - accessing' }
GbxLargeIdentityDictionary >> basicAt: key otherwise: absentBlock [
	^ storage at: key ifAbsent: absentBlock
]

{ #category : 'enumeration' }
GbxLargeIdentityDictionary >> basicKeysAndValuesDo: aBlock [
	storage keysAndValuesDo: aBlock
]

{ #category : 'testing' }
GbxLargeIdentityDictionary >> basicHasValidSize [
	^ true
]

{ #category : 'accessing' }
GbxLargeIdentityDictionary >> bucketSlotsGrown [
	^ bucketSlotsGrown ifNil: [ 0 ]
]

{ #category : 'key comparing' }
GbxLargeIdentityDictionary >> compare: keyA with: keyB [
	^ keyA == keyB
]

{ #category : 'testing' }
GbxLargeIdentityDictionary >> hasCriticalAccess [
	^ accessProtect notNil
]

{ #category : 'initialization' }
GbxLargeIdentityDictionary >> initialize [
	super initialize.
	weakness := #none.
	numElements := 0.
	bucketSlotsGrown := 0.
	accessProtect := Semaphore forMutualExclusion
]

{ #category : 'accessing' }
GbxLargeIdentityDictionary >> keysAndValuesDo: aBlock [
	storage keysAndValuesDo: aBlock
]

{ #category : 'testing' }
GbxLargeIdentityDictionary >> maximumBucketSlotGrowth [
	^ 0
]

{ #category : 'instance creation' }
GbxLargeIdentityDictionary class >> new: initialSize [
	^ self new
]

{ #category : 'instance creation' }
GbxLargeIdentityDictionary class >> newWeakValues: initialSize [
	^ (self new: initialSize)
		weakness: #values;
		yourself
]

{ #category : 'private' }
GbxLargeIdentityDictionary >> primRemoveKeySafelyAt: key [
	^ self removeKey: key
]

{ #category : 'testing' }
GbxLargeIdentityDictionary >> reductionDenominator [
	^ 2
]

{ #category : 'removing' }
GbxLargeIdentityDictionary >> removeKey: key [
	| removed |

	removed := storage removeKey: key ifAbsent: [ nil ].
	removed ifNotNil: [ numElements := storage size ].
	^ removed
]

{ #category : 'inspecting' }
GbxLargeIdentityDictionary >> statistics [
	^ Dictionary new
		at: #size put: storage size;
		at: #bucketSlotsGrown put: self bucketSlotsGrown;
		at: #weakness put: weakness;
		yourself
]

{ #category : 'accessing' }
GbxLargeIdentityDictionary >> at: key ifAbsent: absentBlock [
	^ storage at: key ifAbsent: absentBlock
]

{ #category : 'adding' }
GbxLargeIdentityDictionary >> at: key put: value [
	storage at: key put: value.
	numElements := storage size.
	^ value
]

{ #category : 'private - accessing' }
GbxLargeIdentityDictionary >> at: key otherwise: absentBlock [
	^ self at: key ifAbsent: absentBlock
]

{ #category : 'accessing' }
GbxLargeIdentityDictionary >> weakness [
	^ weakness
]

{ #category : 'accessing' }
GbxLargeIdentityDictionary >> weakness: aSymbol [
	weakness := aSymbol
]

{ #category : 'protection' }
GbxLargeIdentityDictionary >> writeCritical: aBlock [
	^ accessProtect critical: aBlock
]
