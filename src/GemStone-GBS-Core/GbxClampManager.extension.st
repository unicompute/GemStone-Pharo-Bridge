Extension { #name : 'GbxClampManager' }

{ #category : '*GemStone-GBS-Core' }
GbxClampManager class >> forSession: aSession [
	| replicatorManager clampManager |
	replicatorManager := [ aSession replicatorManager ] on: Error do: [ nil ].
	clampManager := replicatorManager ifNotNil: [
		[ replicatorManager clampManager ] on: Error do: [ nil ] ].
	clampManager ifNotNil: [ ^ clampManager ].
	^ (aSession class weakRegistryNamed: #GbsSessionClampManagers)
		at: aSession
		ifAbsentPut: [ self new ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager class >> forManager: aReplicatorManager [
	^ self new
		initializeForManager: aReplicatorManager;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager class >> resetForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionClampManagers)
		removeKey: aSession
		ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> clampClass: aClass toScheme: aScheme [
	classClamps at: aClass put: aScheme.
	^ aScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> clampObject: anObject toScheme: aScheme [
	identityClamps at: anObject put: aScheme.
	^ aScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> classClamps [
	^ classClamps
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> changedClampByCallback [
	self knownReplicationSchemes do: [ :scheme |
		scheme
			updateForClampingByCallback: true
			inSession: self session ].
	^ self currentReplicationScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> changedSelector: aSelector forReplicator: aReplicator [
	| scheme |
	aSelector = #instancesAreForwarders ifTrue: [
		^ self updateClassClampForReplicator: aReplicator ].
	(self selectorRequiresClampMetadataRefresh: aSelector) ifTrue: [
		^ self updateClampsForReplicators: { aReplicator } ].
	scheme := self replicationSchemeNamed: aSelector.
	scheme ifNotNil: [
		^ self updateInstVarLevelsOfScheme: scheme forReplicators: { aReplicator } ].
	(#(replicationSpec transitiveClosureSpec) includes: aSelector) ifTrue: [
		^ self updateClassClampForReplicator: aReplicator ].
	^ aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> currentReplicationScheme [
	^ self threadSpecificReplicationScheme ifNil: [ self defaultReplicationScheme ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> defaultReplicationScheme [
	^ defaultReplicationScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> defaultReplicationScheme: aScheme [
	defaultReplicationScheme := aScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> defaultReplicationSpecSet [
	^ self defaultReplicationScheme selector
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> defaultReplicationSpecSet: aSymbol [
	defaultReplicationScheme := self replicationSchemeForSet: aSymbol.
	^ defaultReplicationScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> endingInteraction [
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> identityClamps [
	^ identityClamps
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> initialize [
	super initialize.
	classClamps := IdentityDictionary new.
	identityClamps := IdentityDictionary new.
	replicationSchemes := Dictionary new.
	threadSpecificSchemes := Dictionary new.
	defaultReplicationScheme := GbxReplicationScheme replicate
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> initializeForManager: aReplicatorManager [
	self initialize.
	manager := aReplicatorManager
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> invalidateSchemeWithSelector: aSelector [
	| scheme |
	scheme := replicationSchemes removeKey: aSelector ifAbsent: [ ^ false ].
	defaultReplicationScheme == scheme ifTrue: [
		defaultReplicationScheme := self replicationSchemeForSet: #replicate ].
	scheme invalidate.
	^ true
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> manager [
	^ manager
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> replicationSchemeFor: anObject [
	^ identityClamps
		at: anObject
		ifAbsent: [
			classClamps
				at: anObject class
				ifAbsent: [ defaultReplicationScheme ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> replicationSchemeNamed: aKey [
	^ replicationSchemes
		at: aKey
		ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> replicationSchemeNamed: aKey put: aScheme [
	replicationSchemes at: aKey put: aScheme.
	^ aScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> replicationSchemeForSet: setSelector [
	| scheme |
	setSelector ifNil: [ ^ GbxNullReplicationScheme new ].
	scheme := replicationSchemes at: setSelector ifAbsent: [ nil ].
	scheme ifNotNil: [ ^ scheme ].
	scheme := GbxReplicationScheme selector: setSelector.
	replicationSchemes at: setSelector put: scheme.
	manager ifNotNil: [
		self
			updateInstVarLevelsOfScheme: scheme
			forReplicators: manager currentReplicators ].
	^ scheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> release [
	classClamps removeAll.
	identityClamps removeAll.
	replicationSchemes removeAll.
	threadSpecificSchemes removeAll.
	manager := nil
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> removeClampsForReplicator: aReplicator [
	| clientClass serverClass |
	clientClass := self clientClassForReplicator: aReplicator.
	serverClass := self serverClassForReplicator: aReplicator.
	serverClass ifNotNil: [ classClamps removeKey: serverClass ifAbsent: [ ] ].
	clientClass ifNotNil: [
		classClamps removeKey: clientClass ifAbsent: [ ].
		identityClamps removeKey: clientClass ifAbsent: [ ].
		self knownReplicationSchemes do: [ :scheme |
			scheme removeArtefactsForClass: clientClass ] ].
	^ aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> session [
	manager ifNil: [ ^ nil ].
	^ manager session
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> startingInteraction [
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> threadSpecificReplicationScheme [
	^ threadSpecificSchemes
		at: Processor activeProcess
		ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> updateClassClampForReplicator: aReplicator [
	| clientClass serverClass scheme |
	scheme := self currentReplicationScheme.
	clientClass := self clientClassForReplicator: aReplicator.
	serverClass := self serverClassForReplicator: aReplicator.
	(self replicatorUsesClassClamp: aReplicator) ifTrue: [
				serverClass ifNotNil: [ classClamps at: serverClass put: scheme ].
				scheme removeArtefactsForClass: clientClass.
				^ scheme ].
	serverClass ifNotNil: [ classClamps removeKey: serverClass ifAbsent: [ ] ].
	(aReplicator respondsTo: #updateInstVarLevelsOfScheme:) ifTrue: [
		aReplicator updateInstVarLevelsOfScheme: scheme ].
	^ scheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> updateClampsForReplicators: aCollection [
	aCollection do: [ :each | self updateClassClampForReplicator: each ].
	self knownReplicationSchemes do: [ :scheme |
		self updateInstVarLevelsOfScheme: scheme forReplicators: aCollection ].
	^ aCollection
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> unclampClass: aClass [
	^ classClamps removeKey: aClass ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> unclampObject: anObject [
	^ identityClamps removeKey: anObject ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampManager >> usingReplicationSpecSet: setSelector do: aBlock [
	| key previous hadPrevious scheme |
	key := Processor activeProcess.
	hadPrevious := threadSpecificSchemes includesKey: key.
	previous := threadSpecificSchemes at: key ifAbsent: [ nil ].
	scheme := self replicationSchemeForSet: setSelector.
	threadSpecificSchemes at: key put: scheme.
	^ [ aBlock value ] ensure: [
		hadPrevious
			ifTrue: [ threadSpecificSchemes at: key put: previous ]
			ifFalse: [ threadSpecificSchemes removeKey: key ifAbsent: [ ] ] ]
]

{ #category : '*GemStone-GBS-Core-private' }
GbxClampManager >> clientClassForReplicator: aReplicator [
	^ (aReplicator respondsTo: #clientClass)
		ifTrue: [ aReplicator clientClass ]
		ifFalse: [ nil ]
]

{ #category : '*GemStone-GBS-Core-private' }
GbxClampManager >> knownReplicationSchemes [
	| schemes |
	schemes := OrderedCollection new.
	defaultReplicationScheme ifNotNil: [ schemes add: defaultReplicationScheme ].
	replicationSchemes do: [ :scheme |
		(schemes anySatisfy: [ :each | each == scheme ])
			ifFalse: [ schemes add: scheme ] ].
	^ schemes asArray
]

{ #category : '*GemStone-GBS-Core-private' }
GbxClampManager >> replicatorUsesClassClamp: aReplicator [
	| clientClass |
	clientClass := self clientClassForReplicator: aReplicator.
	clientClass ifNil: [ ^ false ].
	(clientClass respondsTo: #instancesAreForwarders) ifFalse: [ ^ false ].
	^ [ clientClass instancesAreForwarders ] on: Error do: [ false ]
]

{ #category : '*GemStone-GBS-Core-private' }
GbxClampManager >> selectorRequiresClampMetadataRefresh: aSelector [
	^ #(
		instVarMap
		instVarNames
		allInstVarNames
		classVersion
		classHistory
		classFormat
		instanceVariables) includes: aSelector
]

{ #category : '*GemStone-GBS-Core-private' }
GbxClampManager >> serverClassForReplicator: aReplicator [
	^ (aReplicator respondsTo: #serverClass)
		ifTrue: [ aReplicator serverClass ]
		ifFalse: [ nil ]
]

{ #category : '*GemStone-GBS-Core-private' }
GbxClampManager >> updateInstVarLevelsOfScheme: aScheme forReplicators: replicators [
	replicators do: [ :replicator |
		| clientClass |
		clientClass := self clientClassForReplicator: replicator.
		(self replicatorUsesClassClamp: replicator)
			ifTrue: [
				clientClass ifNotNil: [
					aScheme removeArtefactsForClass: clientClass ] ]
			ifFalse: [
				(replicator respondsTo: #updateInstVarLevelsOfScheme:) ifTrue: [
					replicator updateInstVarLevelsOfScheme: aScheme ] ] ].
	^ aScheme
]
