Class {
	#name : 'GbxDeferredElementsReplicatorTool',
	#superclass : 'GbxReplicator',
	#instVars : [
		'deferredAssignments'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDeferredElementsReplicatorTool class >> forCollection: aCollection [
	^ self new
		target: aCollection;
		yourself
]

{ #category : 'replication' }
GbxDeferredElementsReplicatorTool >> addDeferredAssignment: anAssignment [
	"Add a deferred assignment"
	deferredAssignments ifNil: [ deferredAssignments := OrderedCollection new ].
	deferredAssignments add: anAssignment.
]

{ #category : 'replication' }
GbxDeferredElementsReplicatorTool >> executeDeferredAssignments [
	"Execute all deferred assignments"
	
	deferredAssignments ifNil: [ ^ self ].
	
	deferredAssignments do: [ :assignment |
		assignment execute.
	].
	
	deferredAssignments := nil.
]

{ #category : 'initialization' }
GbxDeferredElementsReplicatorTool >> initialize [
	super initialize.
	deferredAssignments := nil.
]

{ #category : 'replication' }
GbxDeferredElementsReplicatorTool >> replicateElement: anElement atIndex: index [
	"Replicate an element with deferred assignment"
	| replicator replicated |
	
	replicator := self replicatorFor: anElement.
	replicated := replicator replicate.
	
	self addDeferredAssignment: (GbxDeferredIndexedAssignment
		target: target
		index: index
		value: replicated).
	
	^ replicated
]
