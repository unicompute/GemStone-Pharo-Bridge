Class {
	#name : 'GbxDeferredElementsReplicator',
	#superclass : 'GbxReplicator',
	#instVars : [
		'deferredAssignments'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDeferredElementsReplicator class >> forCollection: aCollection [
	^ self new
		target: aCollection;
		yourself
]

{ #category : 'replication' }
GbxDeferredElementsReplicator >> addDeferredAssignment: anAssignment [
	"Add a deferred assignment"
	deferredAssignments ifNil: [ deferredAssignments := OrderedCollection new ].
	deferredAssignments add: anAssignment.
]

{ #category : 'replication' }
GbxDeferredElementsReplicator >> executeDeferredAssignments [
	"Execute all deferred assignments"
	
	deferredAssignments ifNil: [ ^ self ].
	
	deferredAssignments do: [ :assignment |
		assignment execute.
	].
	
	deferredAssignments := nil.
]

{ #category : 'initialization' }
GbxDeferredElementsReplicator >> initialize [
	super initialize.
	deferredAssignments := nil.
]

{ #category : 'replication' }
GbxDeferredElementsReplicator >> replicateElement: anElement atIndex: index [
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
