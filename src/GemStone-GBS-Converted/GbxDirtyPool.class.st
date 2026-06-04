Class {
	#name : 'GbxDirtyPool',
	#superclass : 'Object',
	#instVars : [
		'session',
		'dirtyStack',
		'dirtyAwaitingPacking',
		'activeStoreTraversals'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxDirtyPool class >> forSession: aSession [
	^ self new
		initializeForSession: aSession;
		yourself
]

{ #category : 'store traversals' }
GbxDirtyPool >> activeStoreTraversals [
	^ activeStoreTraversals
]

{ #category : 'store traversals' }
GbxDirtyPool >> addStoreTraversal: aTraversal [
	activeStoreTraversals add: aTraversal.
	^ aTraversal
]

{ #category : 'dirty tracking' }
GbxDirtyPool >> dirtyAwaitingPacking [
	^ dirtyAwaitingPacking
]

{ #category : 'initialization' }
GbxDirtyPool >> initializeForSession: aSession [
	session := aSession.
	dirtyStack := OrderedCollection new.
	dirtyAwaitingPacking := IdentitySet new.
	activeStoreTraversals := IdentitySet new
]

{ #category : 'store traversals' }
GbxDirtyPool >> removeStoreTraversal: aTraversal [
	activeStoreTraversals remove: aTraversal ifAbsent: [ ].
	^ aTraversal
]

{ #category : 'accessing' }
GbxDirtyPool >> session [
	^ session
]

{ #category : 'dirty tracking' }
GbxDirtyPool >> setAsideDirtyWhile: aBlock [
	"Run aBlock with an empty top dirty pool so any objects it dirties (for example while resolving an
	unmapped-class replicator during a flush) are isolated from the in-progress dirty set. After the block,
	if the nested pool is non-empty it is flushed to the server in its own pass; the previous dirty pool is
	then restored. Mirrors VisualWorks GbxDirtyPool>>setAsideDirtyWhile:."
	| previous result |
	previous := dirtyAwaitingPacking.
	dirtyStack add: previous.
	dirtyAwaitingPacking := IdentitySet new.
	^ [
		result := aBlock value.
		dirtyAwaitingPacking isEmpty ifFalse: [ self flushSetAsideDirty ].
		result
	] ensure: [
		dirtyAwaitingPacking := previous.
		dirtyStack removeLast ]
]

{ #category : 'dirty tracking' }
GbxDirtyPool >> flushSetAsideDirty [
	"Flush the objects that were dirtied inside the current set-aside frame. Guarded so a session without a
	materialized-object flush path (or a flush error) does not break the surrounding set-aside restore."
	(session notNil and: [ session respondsTo: #flushDirtyMaterializedObjects ]) ifFalse: [ ^ self ].
	[ session flushDirtyMaterializedObjects ] on: Error do: [ :ex | ^ self ].
	^ self
]
