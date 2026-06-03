Extension { #name : 'GbxObjectReplicator' }

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator class >> forClientClass: clientBehavior serverClass: serverBehavior manager: aReplicatorManager [
	^ self new
		manager: aReplicatorManager;
		session: aReplicatorManager session;
		clientClass: clientBehavior;
		serverClass: serverBehavior;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> clientClass [
	^ clientClass
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> clientClass: aClassOrName [
	clientClass := aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> initializeServerOffsets [
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> dirtyStoreKindFor: anObject inTraversal: aTraversal [
	^ aTraversal defaultKindForObject: anObject
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> dirtyStoreServerClassOopFor: anObject inTraversal: aTraversal [
	self serverClass ifNil: [ ^ nil ].
	^ aTraversal classOopForServerBehavior: self serverClass
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> packDirtyReferentsOf: anObject inTraversal: aTraversal [
	^ aTraversal defaultDirtyReferentsOf: anObject
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> store: anObject inTraversal: aTraversal [
	^ aTraversal dirtyStoreEntryFor: anObject replicator: self
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> isComplete [
	^ true
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> replicationSpec [
	^ (clientClass respondsTo: #replicationSpec)
		ifTrue: [ clientClass replicationSpec ]
		ifFalse: [ #() ]
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> replicationSpecForScheme: aReplicationScheme [
	| selector |
	clientClass ifNil: [ ^ #() ].
	aReplicationScheme ifNil: [ ^ self replicationSpec ].
	(aReplicationScheme respondsTo: #selector) ifFalse: [ ^ self replicationSpec ].
	selector := aReplicationScheme selector.
	(selector = #replicate or: [ selector = #replicationSpec ]) ifTrue: [
		^ self replicationSpec ].
	(clientClass respondsTo: selector) ifTrue: [
		^ clientClass perform: selector ].
	^ self replicationSpec
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> serverClass [
	^ serverClass
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> serverClass: aClassOrName [
	serverClass := aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> serverInstVarNames [
	^ #()
]

{ #category : '*GemStone-GBS-Core' }
GbxObjectReplicator >> updateInstVarLevelsOfScheme: aReplicationScheme [
	| replicationSpec |
	clientClass ifNil: [ ^ aReplicationScheme ].
	replicationSpec := self replicationSpecForScheme: aReplicationScheme.
	replicationSpec = #callback ifTrue: [
		aReplicationScheme removeArtefactsForClass: clientClass.
		aReplicationScheme
			updateForClampingByCallback: true
			inSession: self session
			serverBehavior: self serverClass.
		^ aReplicationScheme ].
	^ aReplicationScheme
		updateInstVarLevelsForClass: clientClass
		serverInstVarNames: self serverInstVarNames
		replicationSpec: replicationSpec
]
