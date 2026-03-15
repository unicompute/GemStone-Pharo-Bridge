Class {
	#name : 'GbxSkewedFaultingReplicator',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxSkewedFaultingReplicator >> replicate [
	"Replicate with skewed faulting (lazy load elements)"
	| replicator replicated |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	replicator := GbxDeferredElementsReplicator forCollection: target.
	replicator session: session.
	replicated := replicator replicate.
	
	^ replicated.
]
