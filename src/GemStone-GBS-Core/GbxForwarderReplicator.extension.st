Extension { #name : 'GbxForwarderReplicator' }

{ #category : '*GemStone-GBS-Core' }
GbxForwarderReplicator class >> forClientClass: clientBehavior serverClass: serverBehavior manager: aReplicatorManager [
	^ self new
		manager: aReplicatorManager;
		session: aReplicatorManager session;
		clientClass: clientBehavior;
		serverClass: serverBehavior;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbxForwarderReplicator >> clientClass [
	^ clientClass
]

{ #category : '*GemStone-GBS-Core' }
GbxForwarderReplicator >> clientClass: aClassOrName [
	clientClass := aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbxForwarderReplicator >> serverClass [
	^ serverClass
]

{ #category : '*GemStone-GBS-Core' }
GbxForwarderReplicator >> serverClass: aClassOrName [
	serverClass := aClassOrName
]
