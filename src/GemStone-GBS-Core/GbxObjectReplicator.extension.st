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
	clientClass ifNil: [ ^ aReplicationScheme ].
	^ aReplicationScheme
		updateInstVarLevelsForClass: clientClass
		serverInstVarNames: self serverInstVarNames
		replicationSpec: self replicationSpec
]
