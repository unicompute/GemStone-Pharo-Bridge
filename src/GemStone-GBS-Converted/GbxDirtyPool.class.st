Class {
	#name : 'GbxDirtyPool',
	#superclass : 'Object',
	#instVars : [
		'session',
		'dirtyStack',
		'dirtyAwaitingPacking',
		'activeStoreTraversals',
		'flushingSetAside'
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
	unmapped-class replicator during a flush) are isolated from the in-progress dirty set. On normal
	completion, objects dirtied inside the block are flushed in their own pass; the previous dirty pool is
	then restored. If the block raises (a failed flush), the objects it dirtied are carried back into the
	restored pool so they stay dirty for the next flush cycle. Mirrors VisualWorks
	GbxDirtyPool>>setAsideDirtyWhile:."
	| previous |
	previous := dirtyAwaitingPacking.
	dirtyStack add: previous.
	dirtyAwaitingPacking := IdentitySet new.
	^ [
		| result |
		result := aBlock value.
		dirtyAwaitingPacking isEmpty ifFalse: [ self flushSetAsideDirty ].
		result
	] ensure: [
		"Carry back whatever is still in the set-aside pool: on the error path the block's dirties were never
		flushed; on the normal path flushSetAsideDirty drained its snapshot and anything left was re-dirtied
		during that flush. Either way these must survive into the restored pool rather than be re-flushed,
		which would loop forever for an object that re-dirties itself."
		previous addAll: dirtyAwaitingPacking.
		dirtyAwaitingPacking := previous.
		dirtyStack removeLast ]
]

{ #category : 'dirty tracking' }
GbxDirtyPool >> flushSetAsideDirty [
	"Flush, in their own pass, the objects dirtied inside the current set-aside frame. Reentrancy-guarded:
	the flush re-enters setAsideDirtyWhile:, and if its objects re-dirty themselves they would otherwise be
	flushed again forever. While a set-aside flush is already in progress this is a no-op, so re-dirtied
	objects simply accumulate in the set-aside pool and are carried back by setAsideDirtyWhile:. Also guarded
	so a session without a materialized-object flush path (or a flush error) does not break the surrounding
	set-aside restore."
	flushingSetAside == true ifTrue: [ ^ self ].
	(session notNil and: [ session respondsTo: #flushDirtyMaterializedObjects ]) ifFalse: [ ^ self ].
	flushingSetAside := true.
	[ [ session flushDirtyMaterializedObjects ] on: Error do: [ :ex | ^ self ] ]
		ensure: [ flushingSetAside := false ].
	^ self
]
