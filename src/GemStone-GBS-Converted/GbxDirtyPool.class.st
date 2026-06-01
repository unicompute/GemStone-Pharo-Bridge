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
	| previous result |
	dirtyStack add: dirtyAwaitingPacking.
	previous := dirtyAwaitingPacking.
	dirtyAwaitingPacking := IdentitySet new.
	result := [ aBlock value ] ensure: [
		dirtyAwaitingPacking := previous.
		dirtyStack removeLast ].
	^ result
]
