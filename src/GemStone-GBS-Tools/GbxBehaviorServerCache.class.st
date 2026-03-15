Class {
	#name : 'GbxBehaviorServerCache',
	#superclass : 'Object',
	#instVars : [
		'session',
		'behaviorMap',
		'hitCount',
		'missCount'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxBehaviorServerCache class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> at: anOop ifAbsent: aBlock [
	"Get cached behavior for an OOP"
	| behavior |
	
	behavior := behaviorMap at: anOop ifAbsent: nil.
	behavior ifNotNil: [
		hitCount := hitCount + 1.
		^ behavior
	].
	
	missCount := missCount + 1.
	^ aBlock value
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> at: anOop put: aBehavior [
	"Cache a behavior for an OOP"
	behaviorMap at: anOop put: aBehavior.
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> behaviorMap [
	^ behaviorMap ifNil: [ behaviorMap := Dictionary new ]
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> clear [
	"Clear the cache"
	behaviorMap := Dictionary new.
	hitCount := 0.
	missCount := 0.
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> hitCount [
	^ hitCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> hitRatio [
	| total |
	total := hitCount + missCount.
	total = 0 ifTrue: [ ^ 0 ].
	^ hitCount / total
]

{ #category : 'initialization' }
GbxBehaviorServerCache >> initialize [
	super initialize.
	behaviorMap := Dictionary new.
	hitCount := 0.
	missCount := 0.
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> missCount [
	^ missCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> printString [
	^ 'BehaviorCache (hits: ', hitCount asString, ', misses: ', missCount asString,
	  ', ratio: ', (self hitRatio * 100) asString, '%)'
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> session [
	^ session
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> size [
	^ behaviorMap size
]
