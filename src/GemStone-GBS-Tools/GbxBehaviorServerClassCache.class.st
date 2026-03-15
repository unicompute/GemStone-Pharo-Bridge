Class {
	#name : 'GbxBehaviorServerClassCache',
	#superclass : 'GbxBehaviorServerCache',
	#instVars : [
		'classMap',
		'maxSize',
		'evictionCount'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxBehaviorServerClassCache class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'instance creation' }
GbxBehaviorServerClassCache class >> on: aSession maxSize: anInteger [
	^ self new
		session: aSession;
		maxSize: anInteger;
		yourself
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> at: anOop ifAbsent: aBlock [
	"Get cached class for an OOP with LRU eviction"
	| behavior |
	
	behavior := classMap at: anOop ifAbsent: nil.
	behavior ifNotNil: [
		hitCount := hitCount + 1.
		"Move to end for LRU"
		classMap removeKey: anOop.
		classMap at: anOop put: behavior.
		^ behavior
	].
	
	missCount := missCount + 1.
	behavior := aBlock value.
	
	"Add to cache with eviction if needed"
	self addClass: behavior forOop: anOop.
	^ behavior
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> addClass: aBehavior forOop: anOop [
	"Add a class to cache with eviction"
	
	classMap size >= maxSize ifTrue: [
		"Evict oldest (first) entry"
		classMap isEmpty ifFalse: [
			classMap removeKey: classMap keys first.
			evictionCount := evictionCount + 1.
		].
	].
	
	classMap at: anOop put: aBehavior.
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> classMap [
	^ classMap ifNil: [ classMap := Dictionary new ]
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> clear [
	"Clear the cache"
	classMap := Dictionary new.
	hitCount := 0.
	missCount := 0.
	evictionCount := 0.
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> evictionCount [
	^ evictionCount ifNil: [ 0 ]
]

{ #category : 'initialization' }
GbxBehaviorServerClassCache >> initialize [
	super initialize.
	classMap := Dictionary new.
	maxSize := 1000.
	evictionCount := 0.
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> maxSize [
	^ maxSize
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> maxSize: anInteger [
	maxSize := anInteger
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> printString [
	^ 'ClassCache (size: ', classMap size asString, '/', maxSize asString,
	  ', hits: ', hitCount asString, ', misses: ', missCount asString,
	  ', evictions: ', evictionCount asString, ')'
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> size [
	^ classMap size
]
