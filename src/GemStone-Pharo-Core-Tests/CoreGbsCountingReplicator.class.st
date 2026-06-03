Class {
	#name : 'CoreGbsCountingReplicator',
	#superclass : 'GbxPointerObjectReplicator',
	#instVars : [
		'serverOffsetRefreshCount',
		'storeCount',
		'dirtyReferentPackCount',
		'dirtyStoreClassOop'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'initialization' }
CoreGbsCountingReplicator >> initialize [
	super initialize.
	serverOffsetRefreshCount := 0.
	storeCount := 0.
	dirtyReferentPackCount := 0
]

{ #category : 'initialization' }
CoreGbsCountingReplicator >> initializeServerOffsets [
	serverOffsetRefreshCount := self serverOffsetRefreshCount + 1.
	^ super initializeServerOffsets
]

{ #category : 'accessing' }
CoreGbsCountingReplicator >> serverOffsetRefreshCount [
	^ serverOffsetRefreshCount ifNil: [ 0 ]
]

{ #category : 'dirty store traversal' }
CoreGbsCountingReplicator >> store: anObject inTraversal: aTraversal [
	storeCount := self storeCount + 1.
	^ super store: anObject inTraversal: aTraversal
]

{ #category : 'dirty store traversal' }
CoreGbsCountingReplicator >> packDirtyReferentsOf: anObject inTraversal: aTraversal [
	dirtyReferentPackCount := self dirtyReferentPackCount + 1.
	^ super packDirtyReferentsOf: anObject inTraversal: aTraversal
]

{ #category : 'dirty store traversal' }
CoreGbsCountingReplicator >> dirtyStoreServerClassOopFor: anObject inTraversal: aTraversal [
	dirtyStoreClassOop ifNotNil: [ ^ dirtyStoreClassOop ].
	^ super dirtyStoreServerClassOopFor: anObject inTraversal: aTraversal
]

{ #category : 'accessing' }
CoreGbsCountingReplicator >> storeCount [
	^ storeCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoreGbsCountingReplicator >> dirtyReferentPackCount [
	^ dirtyReferentPackCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoreGbsCountingReplicator >> dirtyStoreClassOop: anInteger [
	dirtyStoreClassOop := anInteger
]
