Class {
	#name : 'GbxCollectionCache',
	#superclass : 'Object',
	#instVars : [
		'cache',
		'statistics'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'cache management' }
GbxCollectionCache >> at: key ifAbsent: aBlock [
	"Get cached value"
	^ cache at: key ifAbsent: aBlock
]

{ #category : 'cache management' }
GbxCollectionCache >> at: key put: value [
	"Put value in cache"
	^ cache at: key put: value
]

{ #category : 'cache management' }
GbxCollectionCache >> clear [
	"Clear the cache"
	cache := IdentityDictionary new.
	statistics := Dictionary new.
]

{ #category : 'accessing' }
GbxCollectionCache >> hitCount [
	^ statistics at: #hitCount ifAbsent: [ 0 ]
]

{ #category : 'initialization' }
GbxCollectionCache >> initialize [
	super initialize.
	cache := IdentityDictionary new.
	statistics := Dictionary new.
	statistics at: #hitCount put: 0.
	statistics at: #missCount put: 0.
]

{ #category : 'accessing' }
GbxCollectionCache >> missCount [
	^ statistics at: #missCount ifAbsent: [ 0 ]
]

{ #category : 'cache management' }
GbxCollectionCache >> recordHit [
	"Record a cache hit"
	statistics at: #hitCount put: (statistics at: #hitCount ifAbsent: [ 0 ]) + 1.
]

{ #category : 'cache management' }
GbxCollectionCache >> recordMiss [
	"Record a cache miss"
	statistics at: #missCount put: (statistics at: #missCount ifAbsent: [ 0 ]) + 1.
]

{ #category : 'accessing' }
GbxCollectionCache >> size [
	^ cache size
]

{ #category : 'accessing' }
GbxCollectionCache >> statistics [
	^ statistics
]
