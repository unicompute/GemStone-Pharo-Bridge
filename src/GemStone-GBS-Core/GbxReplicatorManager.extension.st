Extension { #name : 'GbxReplicatorManager' }

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> currentReplicationScheme [
	^ self clampManager currentReplicationScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> clientClassConnectorForClient: clientClassOrName server: serverClassOrName [
	^ GbsClientClassConnector
		client: clientClassOrName
		server: serverClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> changedSelector: aSelector inClass: aClass [
	| behavior |
	behavior := (aClass respondsTo: #soleInstance)
		ifTrue: [ aClass soleInstance ]
		ifFalse: [ aClass ].
	aClass withAllSubclasses do: [ :class |
		| replicator mappedBehavior |
		mappedBehavior := (class respondsTo: #soleInstance)
			ifTrue: [ class soleInstance ]
			ifFalse: [ class ].
		replicator := self replicatorForClientBehavior: mappedBehavior ifAbsent: [ nil ].
		replicator ifNotNil: [
			aSelector = #instVarMap ifTrue: [
				(replicator respondsTo: #initializeServerOffsets) ifTrue: [
					replicator initializeServerOffsets ] ].
			(self clampManager respondsTo: #changedSelector:forReplicator:) ifTrue: [
				self clampManager changedSelector: aSelector forReplicator: replicator ] ] ].
	^ behavior
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectReplicator: aReplicator toServerBehavior: serverBehavior [
	serverMap at: serverBehavior put: aReplicator.
	^ aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> defaultReplicationSpecSet [
	^ self clampManager defaultReplicationSpecSet
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> defaultReplicationSpecSet: aSymbol [
	^ self clampManager defaultReplicationSpecSet: aSymbol
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> identityClamps [
	^ self clampManager identityClamps
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> mapReplicatorForClientBehavior: clientBehavior serverBehavior: serverBehavior [
	| replicator |
	replicator := (self replicatorClassForClientBehavior: clientBehavior) new.
	(replicator respondsTo: #manager:) ifTrue: [ replicator manager: self ].
	(replicator respondsTo: #session:) ifTrue: [ replicator session: self session ].
	(replicator respondsTo: #clientClass:) ifTrue: [ replicator clientClass: clientBehavior ].
	(replicator respondsTo: #serverClass:) ifTrue: [ replicator serverClass: serverBehavior ].
	self atClient: clientBehavior andServer: serverBehavior put: replicator.
	self updateClassClampForReplicator: replicator.
	^ replicator
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> installClientClassConnector: aConnector [
	^ aConnector installInReplicatorManager: self
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> markServerInstVarNamesNeededByReplicator: aReplicator [
	^ self serverInstVarNamesNeededByReplicator: aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> needsServerInstVarNames [
	^ needServerInstVarNames == true
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> invalidateSchemeWithSelector: aSelector [
	^ self clampManager invalidateSchemeWithSelector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> newClampManagerFor: aSession [
	| clampClass |
	aSession ifNil: [ ^ nil ].
	clampClass := (aSession respondsTo: #clampManagerClass)
		ifTrue: [ aSession clampManagerClass ]
		ifFalse: [ GbxClampManager ].
	^ clampClass forManager: self
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> replicationSchemeForSet: setSymbol [
	^ self clampManager replicationSchemeForSet: setSymbol
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> replicatorClassForClientBehavior: clientBehavior [
	((clientBehavior respondsTo: #instancesAreForwarders)
		and: [ [ clientBehavior instancesAreForwarders ] on: Error do: [ false ] ]) ifTrue: [
			^ Smalltalk globals at: #GbxForwarderReplicator ifAbsent: [ self defaultReplicatorClass ] ].
	(clientBehavior respondsTo: #gbsReplicatorClassInSession:) ifTrue: [
		^ clientBehavior gbsReplicatorClassInSession: self session ].
	^ self defaultReplicatorClass
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> replicatorsNeedingServerInstVarNames [
	^ replicatorsNeedingServerInstVarNames asArray
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> serverMap [
	^ serverMap
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> setReplicatorForClient: secondaryBehavior sameAsReplicatorForClient: primaryBehavior [
	| replicator |
	replicator := self
		replicatorForClientBehavior: primaryBehavior
		ifAbsent: [ self error: 'Attempted second mapping without first mapping present.' ].
	self atClient: secondaryBehavior put: replicator.
	^ replicator
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> updateClassClampForReplicator: aReplicator [
	(self clampManager respondsTo: #updateClassClampForReplicator:) ifTrue: [
		^ self clampManager updateClassClampForReplicator: aReplicator ].
	^ aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> usingReplicationSpecSet: setSymbol do: aBlock [
	^ self clampManager usingReplicationSpecSet: setSymbol do: aBlock
]
