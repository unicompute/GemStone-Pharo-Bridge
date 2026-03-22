Class {
	#name : 'GbxSkewedFaultingReplicatorTool',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxSkewedFaultingReplicatorTool >> replicate [
	"Replicate with skewed faulting (lazy load elements)"
	| replicator replicated |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	replicator := GbxDeferredElementsReplicatorTool forCollection: target.
	replicator session: session.
	replicated := replicator replicate.
	
	^ replicated.
]
