Class {
	#name : 'GbxFakeStoreTraversalSession',
	#superclass : 'Object',
	#instVars : [
		'addedTraversals',
		'lastCreatedReplicator',
		'removedTraversals',
		'replicators',
		'setAsideCount',
		'storedBuffers'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'replication' }
GbxFakeStoreTraversalSession >> addReplicator: aReplicator forClient: aBehavior [
	replicators at: aBehavior put: aReplicator
]

{ #category : 'replication' }
GbxFakeStoreTraversalSession >> addStoreTraversal: aTraversal [
	addedTraversals add: aTraversal.
	^ aTraversal
]

{ #category : 'accessing' }
GbxFakeStoreTraversalSession >> addedTraversals [
	^ addedTraversals
]

{ #category : 'initialization' }
GbxFakeStoreTraversalSession >> initialize [
	super initialize.
	addedTraversals := OrderedCollection new.
	removedTraversals := OrderedCollection new.
	replicators := IdentityDictionary new.
	setAsideCount := 0.
	storedBuffers := OrderedCollection new
]

{ #category : 'accessing' }
GbxFakeStoreTraversalSession >> lastCreatedReplicator [
	^ lastCreatedReplicator
]

{ #category : 'accessing' }
GbxFakeStoreTraversalSession >> lastCreatedReplicator: aReplicator [
	lastCreatedReplicator := aReplicator
]

{ #category : 'replication' }
GbxFakeStoreTraversalSession >> removeStoreTraversal: aTraversal [
	removedTraversals add: aTraversal.
	^ aTraversal
]

{ #category : 'accessing' }
GbxFakeStoreTraversalSession >> removedTraversals [
	^ removedTraversals
]

{ #category : 'replication' }
GbxFakeStoreTraversalSession >> replicatorForClientBehavior: aBehavior ifAbsent: aBlock [
	^ replicators at: aBehavior ifAbsent: aBlock
]

{ #category : 'replication' }
GbxFakeStoreTraversalSession >> setAsideDirtyWhile: aBlock [
	setAsideCount := setAsideCount + 1.
	^ aBlock value
]

{ #category : 'accessing' }
GbxFakeStoreTraversalSession >> setAsideCount [
	^ setAsideCount
]

{ #category : 'replication' }
GbxFakeStoreTraversalSession >> storeTraversalBuffer: aBuffer [
	storedBuffers add: aBuffer.
	^ true
]

{ #category : 'accessing' }
GbxFakeStoreTraversalSession >> storedBuffers [
	^ storedBuffers
]
