Extension { #name : 'GbsSession' }

{ #category : '*GemStone-GBS-Core' }
GbsSession >> clientClassConnectorForClientBehavior: clientBehavior serverBehavior: serverBehavior [
	^ self replicatorManager
		clientClassConnectorForClientBehavior: clientBehavior
		serverBehavior: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> connectReplicator: aReplicator toClientBehavior: clientBehavior andServerBehavior: serverBehavior [
	^ self replicatorManager
		atClient: clientBehavior
		andServer: serverBehavior
		put: aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> connectReplicator: aReplicator toServerBehavior: serverBehavior [
	^ self replicatorManager connectReplicator: aReplicator toServerBehavior: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> disconnectReplicatorForClientBehavior: clientBehavior andServerBehavior: serverBehavior [
	^ self replicatorManager
		removeReplicatorForClientBehavior: clientBehavior
		andServerBehavior: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> disconnectReplicatorForServerBehavior: serverBehavior [
	^ self replicatorManager removeReplicatorForServerBehavior: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> installClientClassConnectorForClientBehavior: clientBehavior serverBehavior: serverBehavior replicationSpec: aReplicationSpec serverInstVarNames: instVarNames [
	^ self replicatorManager
		installClientClassConnectorForClientBehavior: clientBehavior
		serverBehavior: serverBehavior
		replicationSpec: aReplicationSpec
		serverInstVarNames: instVarNames
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> mappedClientClass: clientBehavior toServer: serverBehavior [
	^ self replicatorManager
		mapReplicatorForClientBehavior: clientBehavior
		serverBehavior: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> replicatorManagerReport [
	^ self replicatorManager connectorManagerReport
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> replicatorManagerReportText [
	^ self replicatorManager connectorManagerReportText
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> replicatorForClient: anObject ifAbsent: aBlock [
	^ self
		replicatorForClientBehavior: anObject class
		ifAbsent: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> setReplicatorForClient: secondaryBehavior sameAsReplicatorForClient: primaryBehavior [
	^ self replicatorManager
		setReplicatorForClient: secondaryBehavior
		sameAsReplicatorForClient: primaryBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> updateClassClampForReplicator: aReplicator [
	^ self replicatorManager updateClassClampForReplicator: aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> updateInstVarNamesAndClamps [
	^ self replicatorManager updateInstVarNamesAndClamps
]
