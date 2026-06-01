Class {
	#name : 'GbxFakeUnmappedReplicator',
	#superclass : 'Object',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'instance creation' }
GbxFakeUnmappedReplicator class >> replicatorToFlush: anObject inSession: aSession [
	| replicator |
	replicator := GbxFakeStoreReplicator new.
	(aSession respondsTo: #lastCreatedReplicator:)
		ifTrue: [ aSession lastCreatedReplicator: replicator ].
	^ replicator
]
