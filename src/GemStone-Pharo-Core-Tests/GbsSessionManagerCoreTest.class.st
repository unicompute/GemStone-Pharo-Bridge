Class {
	#name : 'GbsSessionManagerCoreTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousFastRegistry',
		'previousConnectionRegistry',
		'previousInvalidActionRegistry',
		'previousPostConnectActionRegistry',
		'previousSessionConnectorRegistry',
		'previousConnectorObjectRegistry',
		'previousConnectorClassMappingRegistry',
		'previousTypedWrapperRegistry',
		'previousTypedWrapperAutoloadRegistry',
		'previousSessionTypedWrapperAutoloadRegistry',
		'previousTypedWrapperAutoloadPairRegistry',
		'previousSessionTypedWrapperAutoloadPairRegistry',
		'previousCurrentSession',
		'previousParameterCurrentSession',
		'previousObjectSpaceFinalizationRegistry'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GbsSessionManagerCoreTest >> setUp [
	super setUp.
	previousFastRegistry := GbsSessionManager fastConnectorRegistry copy.
	previousConnectionRegistry := (Smalltalk globals at: #GbsConnectorConnectionRegistry ifAbsent: [ Dictionary new ]) copy.
	previousInvalidActionRegistry := (Smalltalk globals at: #GbsConnectorInvalidActionRegistry ifAbsent: [ Dictionary new ]) copy.
	previousPostConnectActionRegistry := (Smalltalk globals at: #GbsConnectorPostConnectActionRegistry ifAbsent: [ Dictionary new ]) copy.
	previousSessionConnectorRegistry := (Smalltalk globals at: #GbsSessionConnectorRegistry ifAbsent: [ Dictionary new ]) copy.
	previousConnectorObjectRegistry := (Smalltalk globals at: #GbsConnectorObjectRegistry ifAbsent: [ Dictionary new ]) copy.
	previousConnectorClassMappingRegistry := (Smalltalk globals at: #GbsConnectorClassMappingRegistry ifAbsent: [ Dictionary new ]) copy.
	previousTypedWrapperRegistry := (Smalltalk globals at: #GbsTypedWrapperRegistry ifAbsent: [ Dictionary new ]) copy.
	previousTypedWrapperAutoloadRegistry := (Smalltalk globals at: #GbsTypedWrapperAutoloadRegistry ifAbsent: [ Dictionary new ]) copy.
	previousSessionTypedWrapperAutoloadRegistry := (Smalltalk globals at: #GbsSessionTypedWrapperAutoloadRegistry ifAbsent: [ Dictionary new ]) copy.
	previousTypedWrapperAutoloadPairRegistry := (Smalltalk globals at: #GbsTypedWrapperAutoloadPairRegistry ifAbsent: [ OrderedCollection new ]) copy.
	previousSessionTypedWrapperAutoloadPairRegistry := (Smalltalk globals at: #GbsSessionTypedWrapperAutoloadPairRegistry ifAbsent: [ Dictionary new ]) copy.
	previousCurrentSession := GBSM currentSession.
	previousParameterCurrentSession := GbsSessionParameters currentSession.
	previousObjectSpaceFinalizationRegistry := Smalltalk globals
		at: #GbsObjectSpaceFinalizationRegistry
		ifAbsent: [ nil ].
	GBSM currentSession: nil.
	GbsSessionParameters currentSession: nil.
	GbsObjectSpaceFacade resetFinalizationRegistry
]

{ #category : 'running' }
GbsSessionManagerCoreTest >> tearDown [
	GbsSessionManager fastConnectorRegistry: previousFastRegistry.
	Smalltalk globals at: #GbsConnectorConnectionRegistry put: previousConnectionRegistry.
	Smalltalk globals at: #GbsConnectorInvalidActionRegistry put: previousInvalidActionRegistry.
	Smalltalk globals at: #GbsConnectorPostConnectActionRegistry put: previousPostConnectActionRegistry.
	Smalltalk globals at: #GbsSessionConnectorRegistry put: previousSessionConnectorRegistry.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: previousConnectorObjectRegistry.
	Smalltalk globals at: #GbsConnectorClassMappingRegistry put: previousConnectorClassMappingRegistry.
	Smalltalk globals at: #GbsTypedWrapperRegistry put: previousTypedWrapperRegistry.
	Smalltalk globals at: #GbsTypedWrapperAutoloadRegistry put: previousTypedWrapperAutoloadRegistry.
	Smalltalk globals at: #GbsSessionTypedWrapperAutoloadRegistry put: previousSessionTypedWrapperAutoloadRegistry.
	Smalltalk globals at: #GbsTypedWrapperAutoloadPairRegistry put: previousTypedWrapperAutoloadPairRegistry.
	Smalltalk globals at: #GbsSessionTypedWrapperAutoloadPairRegistry put: previousSessionTypedWrapperAutoloadPairRegistry.
	GBSM currentSession: previousCurrentSession.
	GbsSessionParameters currentSession: previousParameterCurrentSession.
	previousObjectSpaceFinalizationRegistry
		ifNil: [ Smalltalk globals removeKey: #GbsObjectSpaceFinalizationRegistry ifAbsent: [ ] ]
		ifNotNil: [ Smalltalk globals at: #GbsObjectSpaceFinalizationRegistry put: previousObjectSpaceFinalizationRegistry ].
	super tearDown
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMRepositoryAndObjectSpaceDelegatesToCurrentSession [
	| mockSession repository objectSpace |
	mockSession := CoreMockGbsSession new.
	GBSM currentSession: mockSession.

	repository := GBSM repository.
	objectSpace := GBSM objectSpace.

	self assert: repository class equals: GbsRepositoryFacade.
	self assert: repository session == mockSession.
	self assert: objectSpace class equals: GbsObjectSpaceFacade.
	self assert: objectSpace session == mockSession
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMObjectSpaceDelegatesToCurrentSession [
	| mockSession loaded subclasses instances references paged filtered |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		((script includesSubstring: 'SystemRepository _loadedClasses: includeModules')
			and: [ script includesSubstring: 'includeModules := false' ]) ifTrue: [ ^ #('Invoice') ].
		(script includesSubstring: 'cls allSubclasses asArray') ifTrue: [ ^ #(SubclassOne) ].
		(script includesSubstring: 'SystemRepository _listInstancesInMemory: { cls }') ifTrue: [ ^ #(11 12) ].
		(script includesSubstring: 'findReferencesInMemory asArray') ifTrue: [ ^ #(31 32) ].
		(script includesSubstring: 'startIndex := 2') ifTrue: [ ^ #(12 13) ].
		(script includesSubstring: 'startIndex := 1') ifTrue: [ ^ #(11 12) ].
		(script includesSubstring: 'startIndex := 3') ifTrue: [ ^ #(13 14) ].
		self fail ].
	GBSM currentSession: mockSession.

	loaded := GBSM loadedClassesIncludingModules: false.
	subclasses := GBSM allSubclassesOfNamed: 'Invoice'.
	instances := GBSM instancesInMemoryOfNamed: 'Invoice'.
	references := GBSM referencesToOop: 4242.
	paged := GBSM objectsInMemoryFrom: 2 limit: 2.
	filtered := GBSM
		objectsInMemoryMatching: [ :each | each odd ]
		limit: 2
		batchSize: 2.

	self assert: loaded equals: #('Invoice').
	self assert: subclasses equals: #(SubclassOne).
	self assert: instances equals: #(11 12).
	self assert: references equals: #(31 32).
	self assert: paged equals: #(12 13).
	self assert: filtered equals: #(11 13)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMSessionStateDelegatesToCurrentSession [
	| mockSession stored finalizerRegistry |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System sessionStateAt: key put: value')
			ifTrue: [ ^ 'cached-value' ].
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ 'finalizer-registry' ].
		self fail ].
	GBSM currentSession: mockSession.

	stored := GBSM sessionStateAt: 21 put: 'cached-value'.
	finalizerRegistry := GBSM maglevFinalizerRegistry.

	self assert: stored equals: 'cached-value'.
	self assert: finalizerRegistry equals: 'finalizer-registry'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMEachObjectAndFinalizerDelegatesToCurrentSession [
	| mockSession seen target group |
	mockSession := CoreMockGbsSession new.
	seen := OrderedCollection new.
	target := Object new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _loadedClasses: false') ifTrue: [ ^ #(21 22) ].
		self fail ].
	GBSM currentSession: mockSession.

	GBSM eachObjectDo: [ :each |
		seen add: each ].
	group := GBSM
		defineFinalizerFor: target
		do: [ :each | each ].

	self assert: seen asArray equals: #(21 22).
	self assert: group size equals: 1.
	self assert: (GBSM hasFinalizerFor: target).

	GBSM undefineFinalizerFor: target.
	self deny: (GBSM hasFinalizerFor: target)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMFetchProfileDelegatesToCurrentSession [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	GBSM currentSession: mockSession.

	GBSM fetchByReference.
	self assert: GBSM fetchProfile class equals: GbsProxyOnlyMaterializationProfile.

	GBSM fetchDeep.
	self assert: GBSM fetchProfile class equals: GbsDeepMaterializationProfile
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMTypedWrapperDelegatesToSessionManager [
	| wrapperClass |
	wrapperClass := GBSM
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.

	self assert: (GBSM typedWrapperClassForServerClassNamed: 'ByteArray') == wrapperClass
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testClientClassConnectorInstallsReplicatorAndSessionConnectorPair [
	| mockSession manager connector replicator pairs |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector client: Array server: 'RemoteArray'.

	replicator := manager installClientClassConnector: connector.
	pairs := GbsSessionManager connectorPairsForSession: mockSession.

	self assert: replicator class equals: GbxObjectReplicator.
	self assert: replicator manager == manager.
	self assert: replicator session == mockSession.
	self assert: replicator clientClass == Array.
	self assert: replicator serverClass equals: 'RemoteArray'.
	self assert: (manager replicatorForClientBehavior: Array ifAbsent: [ nil ]) == replicator.
	self assert: (manager replicatorForServerBehavior: 'RemoteArray' ifAbsent: [ nil ]) == replicator.
	self deny: manager needsServerInstVarNames.
	manager markServerInstVarNamesNeededByReplicator: replicator.
	self assert: manager needsServerInstVarNames.
	self assert: manager replicatorsNeedingServerInstVarNames equals: { replicator }.
	self assert: (pairs anySatisfy: [ :pair |
		pair first = 'Array' and: [ pair second = 'RemoteArray' ] ])
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerCompatibilityAliasesInstallAndReportConnectorState [
	| mockSession manager connector replicator report text removed |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := manager
		clientClassConnectorForClientBehavior: Association
		serverBehavior: 'RemoteAssociation'.
	self assert: connector clientBehavior == Association.
	self assert: connector serverBehavior equals: 'RemoteAssociation'.

	replicator := manager
		installClientClassConnectorForClientBehavior: Association
		serverBehavior: 'RemoteAssociation'
		replicationSpec: #(#(#key #replicate))
		serverInstVarNames: #('key' 'value').
	manager markServerInstVarNamesNeededByReplicator: replicator.
	report := manager connectorManagerReport.
	text := manager connectorManagerReportText.

	self assert: (report at: #clientMapSize) equals: 1.
	self assert: (report at: #serverMapSize) equals: 1.
	self assert: (report at: #replicatorCount) equals: 1.
	self assert: (report at: #connectorPairCount) >= 1.
	self assert: (report at: #needsServerInstVarNames).
	self assert: (report at: #deferredServerInstVarReplicatorCount) equals: 1.
	self assert: ((report at: #clientBehaviorNames) includes: 'Association').
	self assert: ((report at: #serverBehaviorNames) includes: 'RemoteAssociation').
	self assert: (text includesSubstring: 'Replicator Manager').
	self assert: (text includesSubstring: 'clientBehaviorNames=Association').
	self assert: (text includesSubstring: 'serverBehaviorNames=RemoteAssociation').

	removed := manager
		removeClientClassConnectorForClientBehavior: Association
		serverBehavior: 'RemoteAssociation'.
	self assert: removed == replicator.
	self assert: (manager connectorManagerReport at: #replicatorCount) equals: 0
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testClientClassConnectorUpdatesClampMetadata [
	| mockSession manager connector levels |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: Association
		server: 'RemoteAssociation'
		replicationSpec: #(
			#(#key #forwarder)
			#(#value #min 2))
		serverInstVarNames: #('key' 'value').

	manager installClientClassConnector: connector.
	levels := manager currentReplicationScheme instVarLevelsForClass: Association.

	self assert: levels equals: { false. -2. nil }.
	self assert: (manager currentReplicationScheme shouldProxyNamedSlot: 1 ofClass: Association).
	self deny: (manager currentReplicationScheme shouldProxyNamedSlot: 2 ofClass: Association)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testClampManagerForSessionSharesReplicatorManagerClampMetadata [
	| mockSession manager connector sessionClamp levels |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: Association
		server: 'RemoteAssociation'
		replicationSpec: #(
			#(#key #forwarder)
			#(#value #min 2))
		serverInstVarNames: #('key' 'value').

	manager installClientClassConnector: connector.
	sessionClamp := GbxClampManager forSession: mockSession.
	levels := sessionClamp currentReplicationScheme instVarLevelsForClass: Association.

	self assert: sessionClamp == manager clampManager.
	self assert: levels equals: { false. -2. nil }
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testClientClassConnectorCallbackReplicationSpecEnablesServerClampCallback [
	| mockSession manager connector scheme |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: Association
		server: 'RemoteAssociation'
		replicationSpec: #callback
		serverInstVarNames: #('key' 'value').

	manager installClientClassConnector: connector.
	scheme := manager currentReplicationScheme.

	self
		assert: scheme clamp instVarLevelsSelector
		equals: #replicateGbsClampCallback.
	self assert: scheme hasServerClampMetadata.
	self assert: (scheme serverClampSpecificationFingerprint includes: #replicateGbsClampCallback)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testClientClassConnectorReinstallForSameClientRemovesOldServerMappingAliasesAndPair [
	| mockSession manager firstConnector secondConnector firstReplicator secondReplicator pairs scheme |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	firstConnector := GbsClientClassConnector
		client: Association
		server: 'RemoteAssociationA'
		replicationSpec: #(#(#key #forwarder))
		serverInstVarNames: #('key' 'value').
	secondConnector := GbsClientClassConnector
		client: Association
		server: 'RemoteAssociationB'
		replicationSpec: #(#(#value #forwarder))
		serverInstVarNames: #('key' 'value').

	firstReplicator := manager installClientClassConnector: firstConnector.
	manager
		setReplicatorForClient: OrderedCollection
		sameAsReplicatorForClient: Association.
	manager markServerInstVarNamesNeededByReplicator: firstReplicator.
	self assert: manager needsServerInstVarNames.

	secondReplicator := manager installClientClassConnector: secondConnector.
	pairs := GbsSessionManager connectorPairsForSession: mockSession.
	scheme := manager currentReplicationScheme.

	self deny: firstReplicator == secondReplicator.
	self assert: (manager replicatorForClientBehavior: Association ifAbsent: [ nil ]) == secondReplicator.
	self assert: (manager replicatorForServerBehavior: 'RemoteAssociationB' ifAbsent: [ nil ]) == secondReplicator.
	self assert: (manager replicatorForServerBehavior: 'RemoteAssociationA' ifAbsent: [ nil ]) isNil.
	self assert: (manager replicatorForClientBehavior: OrderedCollection ifAbsent: [ nil ]) isNil.
	self deny: manager needsServerInstVarNames.
	self assert: (scheme instVarLevelsForClass: Association) equals: { nil. false. nil }.
	self deny: (scheme shouldProxyNamedSlot: 1 ofClass: Association).
	self assert: (scheme shouldProxyNamedSlot: 2 ofClass: Association).
	self deny: (pairs anySatisfy: [ :pair |
		(pair includes: 'Association') and: [ pair includes: 'RemoteAssociationA' ] ]).
	self assert: (pairs anySatisfy: [ :pair |
		(pair includes: 'Association') and: [ pair includes: 'RemoteAssociationB' ] ])
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testClientClassConnectorReinstallForSameServerRemovesOldClientMappingAndPair [
	| mockSession manager firstConnector secondConnector secondReplicator pairs |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	firstConnector := GbsClientClassConnector
		client: Array
		server: 'RemoteShared'
		replicationSpec: #(#(#indexable_part #forwarder))
		serverInstVarNames: #().
	secondConnector := GbsClientClassConnector
		client: Association
		server: 'RemoteShared'
		replicationSpec: #(#(#key #replicate) #(#value #replicate))
		serverInstVarNames: #('key' 'value').

	manager installClientClassConnector: firstConnector.
	secondReplicator := manager installClientClassConnector: secondConnector.
	pairs := GbsSessionManager connectorPairsForSession: mockSession.

	self assert: (manager replicatorForClientBehavior: Array ifAbsent: [ nil ]) isNil.
	self assert: (manager replicatorForClientBehavior: Association ifAbsent: [ nil ]) == secondReplicator.
	self assert: (manager replicatorForServerBehavior: 'RemoteShared' ifAbsent: [ nil ]) == secondReplicator.
	self deny: (pairs anySatisfy: [ :pair |
		(pair includes: 'Array') and: [ pair includes: 'RemoteShared' ] ]).
	self assert: (pairs anySatisfy: [ :pair |
		(pair includes: 'Association') and: [ pair includes: 'RemoteShared' ] ])
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerSecondaryClientMappingSharesPrimaryReplicator [
	| mockSession manager replicator secondary |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	replicator := manager mapReplicatorForClientBehavior: Array serverBehavior: 'RemoteArray'.

	secondary := manager
		setReplicatorForClient: OrderedCollection
		sameAsReplicatorForClient: Array.

	self assert: secondary == replicator.
	self assert: (manager replicatorForClientBehavior: Array ifAbsent: [ nil ]) == replicator.
	self assert: (manager replicatorForClientBehavior: OrderedCollection ifAbsent: [ nil ]) == replicator.
	self assert: (manager replicatorForServerBehavior: 'RemoteArray' ifAbsent: [ nil ]) == replicator.
	self assert: manager currentReplicators equals: { replicator }.
	self assert: manager numberOfReplicators equals: 1
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testClientClassConnectorAliasesSubclassesAndDedupesClassVersionRefresh [
	| mockSession manager connector replicator baseline report |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: CoreGbsMigrationDomainMappedOrder
		server: 'GbsMigrationLiveMappedOrder'
		replicationSpec: CoreGbsMigrationDomainMappedOrder migrationDomainReplicationSpec
		serverInstVarNames: CoreGbsMigrationDomainMappedOrder migrationDomainServerInstVarNames.
	connector
		includeSubclasses: true;
		replicatorClass: CoreGbsCountingReplicator.

	replicator := manager installClientClassConnector: connector.
	report := manager connectorManagerReport.
	baseline := replicator serverOffsetRefreshCount.

	self assert: (manager
		replicatorForClientBehavior: CoreGbsMigrationDomainMappedOrder
		ifAbsent: [ nil ]) == replicator.
	self assert: (manager
		replicatorForClientBehavior: CoreGbsMigrationDomainInheritedMappedOrder
		ifAbsent: [ nil ]) == replicator.
	self assert: manager currentReplicators equals: { replicator }.
	self assert: manager numberOfReplicators equals: 1.
	self assert: (report at: #clientMapSize) >= 2.
	self assert: (report at: #clientAliasCount) >= 1.

	manager changedSelector: #classVersion inClass: CoreGbsMigrationDomainMappedOrder.

	self assert: replicator serverOffsetRefreshCount equals: baseline + 1.

	manager
		removeReplicatorForClientBehavior: CoreGbsMigrationDomainMappedOrder
		andServerBehavior: 'GbsMigrationLiveMappedOrder'.
	self assert: (manager
		replicatorForClientBehavior: CoreGbsMigrationDomainMappedOrder
		ifAbsent: [ nil ]) isNil.
	self assert: (manager
		replicatorForClientBehavior: CoreGbsMigrationDomainInheritedMappedOrder
		ifAbsent: [ nil ]) isNil
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerRemovingPrimaryRemovesSecondaryMappingsAndDeferredInstvarRequest [
	| mockSession manager connector replicator removed |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: Array
		server: 'RemoteArray'
		replicationSpec: #(#(#indexable_part #forwarder))
		serverInstVarNames: #().

	replicator := manager installClientClassConnector: connector.
	manager
		setReplicatorForClient: OrderedCollection
		sameAsReplicatorForClient: Array.
	manager markServerInstVarNamesNeededByReplicator: replicator.
	self assert: manager needsServerInstVarNames.

	removed := manager
		removeReplicatorForClientBehavior: Array
		andServerBehavior: 'RemoteArray'.

	self assert: removed == replicator.
	self assert: (manager replicatorForClientBehavior: Array ifAbsent: [ nil ]) isNil.
	self assert: (manager replicatorForClientBehavior: OrderedCollection ifAbsent: [ nil ]) isNil.
	self assert: (manager replicatorForServerBehavior: 'RemoteArray' ifAbsent: [ nil ]) isNil.
	self deny: manager needsServerInstVarNames.
	self assert: manager replicatorsNeedingServerInstVarNames isEmpty.
	self assert: manager currentReplicators isEmpty
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerRemovingServerBehaviorRemovesClientAliases [
	| mockSession manager replicator removed |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	replicator := manager mapReplicatorForClientBehavior: Array serverBehavior: 'RemoteArray'.
	manager
		setReplicatorForClient: OrderedCollection
		sameAsReplicatorForClient: Array.

	removed := manager removeReplicatorForServerBehavior: 'RemoteArray'.

	self assert: removed == replicator.
	self assert: (manager replicatorForClientBehavior: Array ifAbsent: [ nil ]) isNil.
	self assert: (manager replicatorForClientBehavior: OrderedCollection ifAbsent: [ nil ]) isNil.
	self assert: (manager replicatorForServerBehavior: 'RemoteArray' ifAbsent: [ nil ]) isNil
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerNamedReplicationSchemeHydratesExistingReplicators [
	| mockSession manager connector scheme |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: CoreGbsReplicationSpecFixture
		server: 'RemoteFixture'
		replicationSpec: nil
		serverInstVarNames: #('key' 'value').
	connector replicatorClass: GbxPointerObjectReplicator.

	manager installClientClassConnector: connector.
	scheme := manager replicationSchemeForSet: #customerReplicationSpec.

	self
		assert: (scheme instVarLevelsForClass: CoreGbsReplicationSpecFixture)
		equals: { 0. false. nil }.
	self deny: (scheme shouldProxyNamedSlot: 1 ofClass: CoreGbsReplicationSpecFixture).
	self assert: (scheme shouldProxyNamedSlot: 2 ofClass: CoreGbsReplicationSpecFixture)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerNamedReplicationSchemeUsesInheritedSpecSelector [
	| mockSession manager connector scheme |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: CoreGbsInheritedReplicationSpecFixture
		server: 'RemoteInheritedFixture'
		replicationSpec: nil
		serverInstVarNames: #('key' 'value').
	connector replicatorClass: GbxPointerObjectReplicator.

	manager installClientClassConnector: connector.
	scheme := manager replicationSchemeForSet: #customerReplicationSpec.

	self
		assert: (scheme instVarLevelsForClass: CoreGbsInheritedReplicationSpecFixture)
		equals: { 0. false. nil }.
	self deny: (scheme shouldProxyNamedSlot: 1 ofClass: CoreGbsInheritedReplicationSpecFixture).
	self assert: (scheme shouldProxyNamedSlot: 2 ofClass: CoreGbsInheritedReplicationSpecFixture)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerNamedCallbackSchemeInstallsServerCallbackSelector [
	| mockSession manager connector scheme |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: CoreGbsReplicationSpecFixture
		server: 'RemoteFixture'
		replicationSpec: nil
		serverInstVarNames: #('key' 'value').
	connector replicatorClass: GbxPointerObjectReplicator.

	manager installClientClassConnector: connector.
	scheme := manager replicationSchemeForSet: #callbackReplicationSpec.

	self
		assert: scheme clamp instVarLevelsSelector
		equals: #callbackReplicationSpecGbsClampCallback.
	self assert: scheme hasServerClampMetadata.
	self assert: (scheme instVarLevelsForClass: CoreGbsReplicationSpecFixture) isNil
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerMigrationDomainSpecCoversForwarderMinMaxStubNilAndCallback [
	| mockSession manager connector scheme callbackScheme closure |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: CoreGbsMigrationDomainOrder
		server: 'GbsMigrationLiveOrder'
		replicationSpec: CoreGbsMigrationDomainOrder migrationDomainReplicationSpec
		serverInstVarNames: CoreGbsMigrationDomainOrder migrationDomainServerInstVarNames.
	connector replicatorClass: GbxPointerObjectReplicator.

	manager installClientClassConnector: connector.
	scheme := manager currentReplicationScheme.
	closure := scheme transitiveClosureSpecForReplicationSpec:
		CoreGbsMigrationDomainOrder migrationDomainReplicationSpec.

	self
		assert: (scheme instVarLevelsForClass: CoreGbsMigrationDomainOrder)
		equals: { false. -2. 1. nil. 0. nil }.
	self assert: (scheme shouldProxyNamedSlot: 1 ofClass: CoreGbsMigrationDomainOrder).
	self deny: (scheme shouldProxyNamedSlot: 2 ofClass: CoreGbsMigrationDomainOrder).
	self deny: (scheme shouldProxyIndexedInstvarsOfClass: CoreGbsMigrationDomainOrder).
	self
		assert: closure
		equals: #(
			#(#customer #forwarder)
			#(#indexable_part #replicate)).

	callbackScheme := manager replicationSchemeForSet: #migrationDomainCallbackReplicationSpec.
	self
		assert: callbackScheme clamp instVarLevelsSelector
		equals: #migrationDomainCallbackReplicationSpecGbsClampCallback.
	self assert: callbackScheme hasServerClampMetadata.
	self assert: (callbackScheme instVarLevelsForClass: CoreGbsMigrationDomainOrder) isNil
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerMigrationDomainInstVarMapRemapsClampAndDirtyStoreOrder [
	| mockSession manager connector replicator scheme order traversal mappings dirtyBuffer reader |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: CoreGbsMigrationDomainMappedOrder
		server: 'GbsMigrationLiveMappedOrder'
		replicationSpec: CoreGbsMigrationDomainMappedOrder migrationDomainReplicationSpec
		serverInstVarNames: CoreGbsMigrationDomainMappedOrder migrationDomainServerInstVarNames.
	connector replicatorClass: GbxPointerObjectReplicator.

	replicator := manager installClientClassConnector: connector.
	scheme := manager currentReplicationScheme.

	self assert: replicator serverToClientOffsets equals: { 1. 2. nil. 3. 5 }.
	self
		assert: (scheme instVarLevelsForClass: CoreGbsMigrationDomainMappedOrder)
		equals: { false. -2. false. 1. 0. nil }.
	self assert: (scheme shouldProxyNamedSlot: 1 ofClass: CoreGbsMigrationDomainMappedOrder).
	self deny: (scheme shouldProxyNamedSlot: 2 ofClass: CoreGbsMigrationDomainMappedOrder).
	self deny: (scheme shouldProxyNamedSlot: 3 ofClass: CoreGbsMigrationDomainMappedOrder).
	self deny: (scheme shouldProxyIndexedInstvarsOfClass: CoreGbsMigrationDomainMappedOrder).

	order := CoreGbsMigrationDomainMappedOrder basicNew.
	order
		instVarAt: 1 put: 11;
		instVarAt: 2 put: 22;
		instVarAt: 3 put: 33;
		instVarAt: 4 put: 44;
		instVarAt: 5 put: 55.
	mockSession rememberMaterializedObject: order forOop: 9700.
	traversal := GbsDirtyReplicateStoreTraversal forSession: mockSession.
	mappings := traversal namedSlotFlushMappingsForObject: order.
	self assert: mappings equals: {
		{ 1. 1 }.
		{ 2. 2 }.
		{ 4. 3 }.
		{ 5. 5 } }.
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9700. order. #namedObject } }
		session: mockSession.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: oop equals: 9700.
		7700 ].
	reader := GbsMaterializationTraversalBufferReader on: mockSession.

	dirtyBuffer
		withNativeTraversalBufferOn: mockSession
		do: [ :nativeBuffer | | report |
			report := reader reportAt: nativeBuffer offset: 9.
			self assert: report oop equals: 9700.
			self assert: report classOop equals: 7700.
			self assert: report namedSize equals: 5.
			self assert: report indexedSize equals: 0.
			self assert: report valueOops equals: #(90 178 1 266 442) ]
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerMigrationDomainNilMappedClientSlotDoesNotDirtyReplicate [
	| mockSession manager connector order |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: CoreGbsMigrationDomainMappedOrder
		server: 'GbsMigrationLiveMappedOrder'
		replicationSpec: CoreGbsMigrationDomainMappedOrder migrationDomainReplicationSpec
		serverInstVarNames: CoreGbsMigrationDomainMappedOrder migrationDomainServerInstVarNames.
	connector replicatorClass: GbxPointerObjectReplicator.
	manager installClientClassConnector: connector.

	order := CoreGbsMigrationDomainMappedOrder basicNew.
	mockSession rememberMaterializedObject: order forOop: 9816.
	order gbsInstVarAt: 4 put: #clientOnlyCache.
	self assert: (order instVarAt: 4) equals: #clientOnlyCache.
	self deny: (mockSession isMaterializedObjectDirty: order).
	self assert: mockSession dirtyMaterializedObjectOops isEmpty.

	order gbsInstVarAt: 3 put: 777.
	self assert: (order instVarAt: 3) equals: 777.
	self assert: (mockSession isMaterializedObjectDirty: order).
	self assert: mockSession dirtyMaterializedObjectOops equals: #(9816)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerMigrationDomainInheritedInstVarMapExtendsSuperMap [
	| mockSession manager connector replicator scheme order dirtyBuffer reader |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: CoreGbsMigrationDomainInheritedMappedOrder
		server: 'GbsMigrationLiveInheritedMappedOrder'
		replicationSpec: CoreGbsMigrationDomainInheritedMappedOrder migrationDomainReplicationSpec
		serverInstVarNames: CoreGbsMigrationDomainInheritedMappedOrder migrationDomainServerInstVarNames.
	connector replicatorClass: GbxPointerObjectReplicator.

	replicator := manager installClientClassConnector: connector.
	scheme := manager currentReplicationScheme.
	self assert: replicator serverToClientOffsets equals: { 1. 2. nil. 3. 5. 6. nil }.
	self
		assert: (scheme instVarLevelsForClass: CoreGbsMigrationDomainInheritedMappedOrder)
		equals: { false. -2. false. 1. 0. -1. false. nil }.
	self assert: (scheme shouldProxyNamedSlot: 1 ofClass: CoreGbsMigrationDomainInheritedMappedOrder).
	self deny: (scheme shouldProxyNamedSlot: 3 ofClass: CoreGbsMigrationDomainInheritedMappedOrder).
	self deny: (scheme shouldProxyNamedSlot: 7 ofClass: CoreGbsMigrationDomainInheritedMappedOrder).

	order := CoreGbsMigrationDomainInheritedMappedOrder basicNew.
	order
		instVarAt: 1 put: 11;
		instVarAt: 2 put: 22;
		instVarAt: 3 put: 33;
		instVarAt: 4 put: 44;
		instVarAt: 5 put: 55;
		instVarAt: 6 put: 66;
		instVarAt: 7 put: 77.
	mockSession rememberMaterializedObject: order forOop: 9912.
	order gbsInstVarAt: 7 put: #clientMemo.
	self deny: (mockSession isMaterializedObjectDirty: order).
	order gbsInstVarAt: 6 put: 99.
	self assert: (mockSession isMaterializedObjectDirty: order).
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9912. order. #namedObject } }
		session: mockSession.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: oop equals: 9912.
		8800 ].
	reader := GbsMaterializationTraversalBufferReader on: mockSession.
	dirtyBuffer
		withNativeTraversalBufferOn: mockSession
		do: [ :nativeBuffer | | report |
			report := reader reportAt: nativeBuffer offset: 9.
			self assert: report oop equals: 9912.
			self assert: report classOop equals: 8800.
			self assert: report namedSize equals: 7.
			self assert: report indexedSize equals: 0.
			self assert: report valueOops equals: #(90 178 1 266 442 794 1) ]
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerMigrationDomainMappedLifecycleRefreshesClassVersionAndClearsDirtyState [
	| mockSession manager connector replicator scheme order oldManager |
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciCommit put: 1.
	mockSession stubs at: #gciAbort put: 1.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: CoreGbsMigrationDomainInheritedMappedOrder
		server: 'GbsMigrationLiveInheritedMappedOrder'
		replicationSpec: CoreGbsMigrationDomainInheritedMappedOrder migrationDomainReplicationSpec
		serverInstVarNames: CoreGbsMigrationDomainInheritedMappedOrder migrationDomainServerInstVarNames.
	connector replicatorClass: GbxPointerObjectReplicator.

	replicator := manager installClientClassConnector: connector.
	scheme := manager currentReplicationScheme.
	self assert: replicator serverToClientOffsets equals: { 1. 2. nil. 3. 5. 6. nil }.

	replicator serverInstVarNames: #('buyer' 'items' 'amount' 'audit' 'urgency' 'serverAudit').
	manager changedSelector: #classVersion inClass: CoreGbsMigrationDomainInheritedMappedOrder.
	self assert: replicator serverToClientOffsets equals: { 1. 2. 3. 5. 6. nil }.
	self
		assert: (scheme instVarLevelsForClass: CoreGbsMigrationDomainInheritedMappedOrder)
		equals: { false. -2. 1. 0. -1. false. nil }.

	order := CoreGbsMigrationDomainInheritedMappedOrder basicNew.
	mockSession rememberMaterializedObject: order forOop: 9928.
	order gbsInstVarAt: 6 put: 10.
	self assert: (mockSession isMaterializedObjectDirty: order).
	self assert: (mockSession materializedObjectForOop: 9928) == order.

	self assert: mockSession commitTransaction.
	self assert: mockSession dirtyMaterializedObjectOops isEmpty.
	self assert: (mockSession materializedObjectForOop: 9928) isNil.
	self assert: mockSession replicatorManager == manager.
	self assert: (manager replicatorForClientBehavior: CoreGbsMigrationDomainInheritedMappedOrder ifAbsent: [ nil ]) == replicator.

	mockSession rememberMaterializedObject: order forOop: 9944.
	order gbsInstVarAt: 6 put: 11.
	self assert: (mockSession isMaterializedObjectDirty: order).
	self assert: mockSession abortTransaction.
	self assert: mockSession dirtyMaterializedObjectOops isEmpty.
	self assert: (mockSession materializedObjectForOop: 9944) isNil.
	self assert: mockSession replicatorManager == manager.

	mockSession rememberMaterializedObject: order forOop: 9960.
	order gbsInstVarAt: 6 put: 12.
	self assert: (mockSession isMaterializedObjectDirty: order).
	oldManager := mockSession replicatorManager.
	mockSession resetAfterLogout.
	self assert: mockSession dirtyMaterializedObjectOops isEmpty.
	self assert: (mockSession materializedObjectForOop: 9960) isNil.
	self deny: mockSession replicatorManager == oldManager.
	self assert: (mockSession replicatorManager
		replicatorForClientBehavior: CoreGbsMigrationDomainInheritedMappedOrder
		ifAbsent: [ nil ]) isNil
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerClassVersionChangeRefreshesSubclassReplicatorAndClampMetadata [
	| mockSession manager connector replicator scheme |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: CoreGbsInheritedReplicationSpecFixture
		server: 'RemoteInheritedFixture'
		replicationSpec: #(
			#(#key #forwarder)
			#(#value #min 2))
		serverInstVarNames: #('key' 'value').
	connector replicatorClass: CoreGbsCountingReplicator.

	replicator := manager installClientClassConnector: connector.
	scheme := manager currentReplicationScheme.
	self assert: replicator serverOffsetRefreshCount equals: 0.
	self
		assert: (scheme instVarLevelsForClass: CoreGbsInheritedReplicationSpecFixture)
		equals: { false. -2. nil }.

	manager changedSelector: #classVersion inClass: CoreGbsReplicationSpecFixture.

	self assert: replicator serverOffsetRefreshCount equals: 1.
	self
		assert: (scheme instVarLevelsForClass: CoreGbsInheritedReplicationSpecFixture)
		equals: { false. -2. nil }
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testClassConnectorConnectsThroughReplicatorManager [
	| mockSession connector manager replicator pairs connectResult |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'RemoteArray').
		'RemoteArray' ].
	manager := mockSession replicatorManager.
	connector := GbsClassConnector
		stName: 'Array'
		gsName: 'RemoteArray'
		dictionaryName: 'UserGlobals'.

	connectResult := connector connectInSession: mockSession ifFail: [ :ex |
		self fail: ex messageText ].
	replicator := manager replicatorForClientBehavior: Array ifAbsent: [ nil ].
	pairs := GbsSessionManager connectorPairsForSession: mockSession.

	self assert: connectResult.
	self assert: replicator notNil.
	self assert: replicator clientClass == Array.
	self assert: replicator serverClass equals: 'RemoteArray'.
	self deny: manager needsServerInstVarNames.
	self assert: (connector isConnectedInSession: mockSession).
	self assert: (pairs anySatisfy: [ :pair |
		pair first = 'Array' and: [ pair second = 'RemoteArray' ] ])
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testClassConnectorConnectRegistersConcreteConnectorObjectActionAndReportState [
	| mockSession connector manager report registered connectResult |
	GbsSessionManager resetConnectorState.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script | 'RemoteArray' ].
	manager := mockSession replicatorManager.
	connector := GbsClassConnector
		stName: 'Array'
		gsName: 'RemoteArray'
		dictionaryName: 'UserGlobals'.
	connector postConnectAction: 'updateST'.

	connectResult := connector connectInSession: mockSession ifFail: [ :ex |
		self fail: ex messageText ].
	registered := GbsSessionManager
		connectorObjectForClient: 'Array'
		server: 'RemoteArray'.
	report := manager connectorManagerReport.

	self assert: connectResult.
	self assert: registered == connector.
	self assert: (report at: #connectorPairCount) equals: 1.
	self assert: (report at: #connectedConnectorPairCount) equals: 1.
	self assert: (report at: #disconnectedConnectorPairCount) equals: 0.
	self assert: ((report at: #connectorConnectionStates) includes: 'Array->RemoteArray connected postConnect=updateST')
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testClassConnectorSubclassPolicyInstallsClampAndCleansConnectorLifecycle [
	| mockSession connector manager replicator scheme report connectResult sessionKey connectionKey |
	GbsSessionManager resetConnectorState.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'GbsMigrationLiveOrder').
		'GbsMigrationLiveOrder' ].
	manager := mockSession replicatorManager.
	connector := CoreGbsMigrationDomainClassConnector
		stName: 'CoreGbsMigrationDomainOrder'
		gsName: 'GbsMigrationLiveOrder'
		dictionaryName: 'UserGlobals'.
	connector postConnectAction: 'updateST'.

	connectResult := connector connectInSession: mockSession ifFail: [ :ex |
		self fail: ex messageText ].
	replicator := manager
		replicatorForClientBehavior: CoreGbsMigrationDomainOrder
		ifAbsent: [ nil ].
	scheme := manager currentReplicationScheme.
	report := manager connectorManagerReport.
	sessionKey := GbsSessionManager sessionKeyForSessionObject: mockSession.
	connectionKey := GbsSessionManager
		connectorConnectionKeyForClient: 'CoreGbsMigrationDomainOrder'
		server: 'GbsMigrationLiveOrder'
		session: sessionKey.

	self assert: connectResult.
	self assert: (GbsSessionManager
		connectorObjectForClient: 'CoreGbsMigrationDomainOrder'
		server: 'GbsMigrationLiveOrder') == connector.
	self
		assert: (GbsSessionManager
			postConnectActionForConnectorClient: 'CoreGbsMigrationDomainOrder'
			server: 'GbsMigrationLiveOrder')
		equals: 'updateST'.
	self assert: (GbsSessionManager
		isConnectorClient: 'CoreGbsMigrationDomainOrder'
		server: 'GbsMigrationLiveOrder'
		connectedInSession: sessionKey).
	self assert: replicator class equals: GbxPointerObjectReplicator.
	self assert: replicator clientClass == CoreGbsMigrationDomainOrder.
	self assert: replicator serverClass equals: 'GbsMigrationLiveOrder'.
	self deny: manager needsServerInstVarNames.
	self
		assert: (scheme instVarLevelsForClass: CoreGbsMigrationDomainOrder)
		equals: { false. -2. 1. nil. 0. nil }.
	self assert: (scheme shouldProxyNamedSlot: 1 ofClass: CoreGbsMigrationDomainOrder).
	self deny: (scheme shouldProxyNamedSlot: 2 ofClass: CoreGbsMigrationDomainOrder).
	self assert: (report at: #connectorPairCount) equals: 1.

	connector disconnectInSession: mockSession.

	self assert: (manager
		replicatorForClientBehavior: CoreGbsMigrationDomainOrder
		ifAbsent: [ nil ]) isNil.
	self assert: (manager
		replicatorForServerBehavior: 'GbsMigrationLiveOrder'
		ifAbsent: [ nil ]) isNil.
	self assert: (scheme instVarLevelsForClass: CoreGbsMigrationDomainOrder) isNil.
	self deny: (connector isConnectedInSession: mockSession).
	self deny: (GbsSessionManager connectorConnectionRegistry includesKey: connectionKey).
	self
		assert: (GbsSessionManager
			postConnectActionForConnectorClient: 'CoreGbsMigrationDomainOrder'
			server: 'GbsMigrationLiveOrder')
		equals: 'none'.
	self deny: ((GbsSessionManager connectorPairsForSession: mockSession) anySatisfy: [ :pair |
		pair first = 'CoreGbsMigrationDomainOrder'
			and: [ pair second = 'GbsMigrationLiveOrder' ] ])
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testClassConnectorDisconnectRemovesReplicatorAndSessionPair [
	| mockSession connector manager connectResult |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script | 'RemoteArray' ].
	manager := mockSession replicatorManager.
	connector := GbsClassConnector stName: 'Array' gsName: 'RemoteArray'.

	connectResult := connector connectInSession: mockSession ifFail: [ :ex |
		self fail: ex messageText ].
	self assert: connectResult.
	self assert: (manager replicatorForClientBehavior: Array ifAbsent: [ nil ]) notNil.

	[ connector disconnectInSession: mockSession ]
		on: Error
		do: [ :ex | self fail: 'Disconnect raised ', ex class name, ': ', ex messageText ].

	self assert: (manager replicatorForClientBehavior: Array ifAbsent: [ nil ]) isNil.
	self assert: (manager replicatorForServerBehavior: 'RemoteArray' ifAbsent: [ nil ]) isNil.
	self deny: (connector isConnectedInSession: mockSession).
	self deny: ((GbsSessionManager connectorPairsForSession: mockSession) anySatisfy: [ :pair |
		pair first = 'Array' and: [ pair second = 'RemoteArray' ] ])
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerDirectRemoveClearsSessionConnectorPairAndConnectionState [
	| mockSession connector manager sessionKey connectionKey connectResult |
	GbsSessionManager resetConnectorState.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script | 'RemoteArray' ].
	manager := mockSession replicatorManager.
	connector := GbsClassConnector stName: 'Array' gsName: 'RemoteArray'.
	connectResult := connector connectInSession: mockSession ifFail: [ :ex |
		self fail: ex messageText ].
	sessionKey := GbsSessionManager sessionKeyForSessionObject: mockSession.
	connectionKey := GbsSessionManager
		connectorConnectionKeyForClient: 'Array'
		server: 'RemoteArray'
		session: sessionKey.

	self assert: connectResult.
	self assert: (GbsSessionManager connectorConnectionRegistry includesKey: connectionKey).

	manager
		removeClientClassConnectorForClientBehavior: Array
		serverBehavior: 'RemoteArray'.

	self assert: (manager connectorManagerReport at: #connectorPairCount) equals: 0.
	self deny: (GbsSessionManager connectorConnectionRegistry includesKey: connectionKey).
	self deny: ((GbsSessionManager connectorPairsForSession: mockSession) anySatisfy: [ :pair |
		pair first = 'Array' and: [ pair second = 'RemoteArray' ] ])
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerRemoveConnectorClearsClampMetadata [
	| mockSession manager connector scheme |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: Association
		server: 'RemoteAssociation'
		replicationSpec: #(
			#(#key #forwarder)
			#(#value #min 2))
		serverInstVarNames: #('key' 'value').

	manager installClientClassConnector: connector.
	scheme := manager currentReplicationScheme.
	self assert: (scheme instVarLevelsForClass: Association) notNil.

	manager
		removeReplicatorForClientBehavior: Association
		andServerBehavior: 'RemoteAssociation'.

	self assert: (scheme instVarLevelsForClass: Association) isNil.
	self assert: (manager replicatorForClientBehavior: Association ifAbsent: [ nil ]) isNil.
	self assert: (manager replicatorForServerBehavior: 'RemoteAssociation' ifAbsent: [ nil ]) isNil
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testReplicatorManagerRemoveConnectorClearsClampMetadataInAllSchemes [
	| mockSession manager connector defaultScheme namedScheme |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager.
	connector := GbsClientClassConnector
		client: CoreGbsReplicationSpecFixture
		server: 'RemoteFixture'
		replicationSpec: CoreGbsReplicationSpecFixture replicationSpec
		serverInstVarNames: #('key' 'value').
	connector replicatorClass: GbxPointerObjectReplicator.

	manager installClientClassConnector: connector.
	defaultScheme := manager currentReplicationScheme.
	namedScheme := manager replicationSchemeForSet: #customerReplicationSpec.
	self assert: (defaultScheme instVarLevelsForClass: CoreGbsReplicationSpecFixture) notNil.
	self assert: (namedScheme instVarLevelsForClass: CoreGbsReplicationSpecFixture) notNil.

	manager
		removeReplicatorForClientBehavior: CoreGbsReplicationSpecFixture
		andServerBehavior: 'RemoteFixture'.

	self assert: (defaultScheme instVarLevelsForClass: CoreGbsReplicationSpecFixture) isNil.
	self assert: (namedScheme instVarLevelsForClass: CoreGbsReplicationSpecFixture) isNil
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testSessionReplicatorManagerCompatibilityWrappersDelegateToManager [
	| mockSession replicator |
	mockSession := CoreMockGbsSession new.
	replicator := GbxObjectReplicator
		forClientClass: Array
		serverClass: 'RemoteArray'
		manager: mockSession replicatorManager.

	mockSession
		connectReplicator: replicator
		toClientBehavior: Array
		andServerBehavior: 'RemoteArray'.

	self assert: (mockSession replicatorForClientBehavior: Array ifAbsent: [ nil ]) == replicator.
	self assert: (mockSession replicatorForServerBehavior: 'RemoteArray' ifAbsent: [ nil ]) == replicator.
	mockSession disconnectReplicatorForClientBehavior: Array andServerBehavior: 'RemoteArray'.
	self assert: (mockSession replicatorForClientBehavior: Array ifAbsent: [ nil ]) isNil
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMNamedObjectAtDelegatesToCurrentSession [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 1004 session: mockSession ].
	GBSM currentSession: mockSession.

	result := GBSM namedObjectAt: 'UserGlobals'.

	self assert: result oop equals: 1004
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMNamedObjectCacheInspectionDelegatesToCurrentSession [
	| mockSession report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 1004 session: mockSession ].
	GBSM currentSession: mockSession.

	GBSM namedObjectAt: #UserGlobals.
	report := GBSM namedObjectCacheReportText.

	self assert: GBSM namedObjectCacheKeys equals: #(UserGlobals).
	self assert: (GBSM hasCachedNamedObjectNamed: 'UserGlobals').
	self assert: (report includesSubstring: 'UserGlobals').

	GBSM clearNamedObjectCache.

	self assert: GBSM namedObjectCacheKeys isEmpty
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMNamedObjectAutoloadDelegatesToCurrentSession [
	| mockSession report |
	mockSession := CoreMockGbsSession new.
	GBSM currentSession: mockSession.

	GBSM registerNamedObjectAutoload: #UG remote: #UserGlobals.
	report := GBSM namedObjectAutoloadReportText.

	self assert: GBSM namedObjectAutoloadKeys equals: #(UG).
	self assert: (GBSM hasNamedObjectAutoloadNamed: #UG).
	self assert: (GBSM namedObjectAutoloadTargetFor: #UG) equals: #UserGlobals.
	self assert: (report includesSubstring: 'UG -> UserGlobals').

	GBSM clearNamedObjectAutoloads.

	self assert: GBSM namedObjectAutoloadKeys isEmpty
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMBridgeRootAndListInstancesDelegatesToCurrentSession [
	| mockSession rootResult listResult |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'SystemRepository listInstances: { cls }') ifTrue: [ ^ #(1 2) ].
		nil ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		((script includesSubstring: '#GbsBridgeRoot')
			or: [ script includesSubstring: '''GbsBridgeRoot'' asSymbol' ]) ifTrue: [ ^ 2001 ].
		self fail ].
	GBSM currentSession: mockSession.

	rootResult := GBSM bridgeRoot.
	listResult := GBSM listInstancesOf: 'Invoice'.

	self assert: rootResult class equals: GbsBridgeRootFacade.
	self assert: rootResult session == mockSession.
	self assert: rootResult proxy oop equals: 2001.
	self assert: listResult equals: #(1 2)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMClassHistoryAndMigrationDelegatesToCurrentSession [
	| mockSession history migrated |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'Invoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'fromClass migrateInstances: instances to: toClass') ifTrue: [ ^ 3 ].
		nil ].
	GBSM currentSession: mockSession.

	history := GBSM classHistoryOf: 'Invoice'.
	migrated := GBSM migrateInstancesFrom: 'OldInvoice' to: 'Invoice'.

	self assert: history class equals: GbsClassHistoryFacade.
	self assert: history canMigrateInstances.
	self assert: migrated equals: 3
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMRemoteMirrorDelegatesToCurrentSession [
	| mockSession classMirror methodMirror |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(1001 'Invoice' 'Object' 'Billing-Core' 'Billing-Models' 2 3) ].
		(script includesSubstring: 'value: (''totalPrice'' asSymbol)') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	GBSM currentSession: mockSession.

	classMirror := GBSM classMirrorOf: 'Invoice'.
	methodMirror := GBSM
		methodMirrorForClass: 'Invoice'
		selector: #totalPrice.

	self assert: classMirror name equals: 'Invoice'.
	self assert: classMirror superclassName equals: 'Object'.
	self assert: classMirror packageName equals: 'Billing-Core'.
	self assert: classMirror version equals: 2.
	self assert: methodMirror exists.
	self assert: methodMirror ownerName equals: 'Invoice'.
	self assert: methodMirror protocol equals: 'pricing'.
	self assert: methodMirror packageName equals: 'Billing-Core'.
	self assert: methodMirror sourceLocation equals: 'Invoice>>totalPrice'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMMethodObjectDelegatesToCurrentSession [
	| mockSession methodObject |
	mockSession := CoreMockGbsSession new.
	GBSM currentSession: mockSession.

	methodObject := GBSM
		methodObjectForClass: 'Invoice'
		selector: #totalPrice.

	self assert: methodObject session == mockSession.
	self assert: methodObject selector equals: #totalPrice.
	self deny: methodObject classSide
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMMethodReferenceStringsDelegateToCurrentSession [
	| mockSession references |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'organizer referencesTo: symbolValue').
		self assert: (script includesSubstring: 'value: (''Invoice'' asSymbol)').
		^ #('Invoice>>totalPrice' 'Invoice class>>new') ].
	GBSM currentSession: mockSession.

	references := GBSM methodReferenceStringsToSymbol: 'Invoice'.

	self assert: references equals: #('Invoice>>totalPrice' 'Invoice class>>new')
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMSelectorReferenceQueriesDelegateToCurrentSession [
	| mockSession implementors senders |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		((script includesSubstring: 'organizer implementorsOf: selectorValue')
			and: [ script includesSubstring: 'value: (''size'' asSymbol)' ]) ifTrue: [
			^ #('Object>>size') ].
		((script includesSubstring: 'organizer sendersOf: selectorValue')
			and: [ script includesSubstring: 'value: ''size''' ]) ifTrue: [
			^ #('Behavior>>new') ].
		self fail ].
	GBSM currentSession: mockSession.

	implementors := GBSM implementorMethodReferenceStringsForSelector: 'size'.
	senders := GBSM senderMethodReferenceStringsForSelector: 'size'.

	self assert: implementors equals: #('Object>>size').
	self assert: senders equals: #('Behavior>>new')
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMMigrationPreviewDelegatesToCurrentSession [
	| mockSession plan |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'SystemRepository listInstances: { fromClass }') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].
		self fail ].
	GBSM currentSession: mockSession.

	plan := GBSM
		previewMigrationFrom: 'OldInvoice'
		to: 'Invoice'.

	self assert: plan class equals: GbsMigrationPlan.
	self assert: plan totalInstanceCount equals: 4.
	self assert: plan entries first targetName equals: 'Invoice'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testFastConnectorRegistryAutoloadsWhenGlobalRegistryIsMissing [
	| registry |
	Smalltalk globals removeKey: #GbsFastConnectorRegistry ifAbsent: [ ].

	registry := GbsSessionManager fastConnectorRegistry.

	self assert: registry notNil.
	self assert: (registry at: 'ByteString' ifAbsent: [ nil ]) equals: 'String'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testFastConnectorRegistryStaysEmptyWhenExplicitlyReset [
	GbsSessionManager fastConnectorRegistry: Dictionary new.

	self assert: GbsSessionManager fastConnectorRegistry isEmpty
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGenerateTypedWrapperForConnectorPairCreatesSubclass [
	| wrapperClass |
	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.

	self assert: (wrapperClass inheritsFrom: GbsTypedProxy).
	self assert: wrapperClass clientBehaviorName equals: 'ByteArray'.
	self assert: wrapperClass serverBehaviorName equals: 'ByteArray'.
	self assert: (GbsSessionManager typedWrapperClassForServerClassNamed: 'ByteArray') == wrapperClass
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLookupAutoloadsKnownServerClassWithoutExplicitBootstrap [
	| wrapperClass |
	Smalltalk globals removeKey: #GbsFastConnectorRegistry ifAbsent: [ ].
	Smalltalk globals at: #GbsTypedWrapperRegistry put: Dictionary new.

	wrapperClass := GbsSessionManager typedWrapperClassForServerClassNamed: 'Dictionary'.

	self assert: wrapperClass notNil.
	self assert: (wrapperClass inheritsFrom: GbsTypedProxy).
	self assert: wrapperClass clientBehaviorName equals: 'Dictionary'.
	self assert: wrapperClass serverBehaviorName equals: 'Dictionary'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperAutoloadPairsIncludeSessionScopedConnectorPairs [
	| params session pairs |
	params := GbsSessionParameters new.
	params username: 'DataCurator'.
	params gemStoneName: 'gs64stone'.
	session := CoreMockGbsSession new.
	session parameters: params.
	GbsSessionManager fastConnectorRegistry: Dictionary new.
	GbsSessionManager
		addConnectorClient: 'ByteArray'
		server: 'RemoteLedger'
		forSession: session.

	pairs := GbsSessionManager typedWrapperAutoloadPairsForSession: session.

	self assert: (pairs anySatisfy: [ :pair |
		{ (pair at: 1 ifAbsent: [ '' ]). (pair at: 2 ifAbsent: [ '' ]) } asSet
			= #('ByteArray' 'RemoteLedger') asSet ])
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testExplicitTypedWrapperAutoloadRegistrationAppearsInEntriesAndReport [
	| entries report row |
	GbsSessionManager clearTypedWrapperAutoloadRegistrations.
	GbsSessionManager
		registerTypedWrapperAutoloadClient: 'Money'
		server: 'RemoteMoney'.

	entries := GbsSessionManager typedWrapperAutoloadEntries.
	report := GbsSessionManager typedWrapperAutoloadReportText.
	row := entries
		detect: [ :each | (each at: 1) = 'Money' and: [ (each at: 2) = 'RemoteMoney' ] ]
		ifNone: [ nil ].

	self assert: row notNil.
	self assert: (row at: 3) equals: 'global'.
	self assert: (row at: 4) equals: 'explicit'.
	self assert: (report includesSubstring: 'Money -> RemoteMoney').
	self assert: (report includesSubstring: 'explicit')
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testExplicitTypedWrapperAutoloadRemovalIsScopedToExplicitRegistry [
	| pairs |
	GbsSessionManager fastConnectorRegistry: Dictionary new.
	GbsSessionManager
		addConnectorClient: 'ByteArray'
		server: 'RemoteLedger'.
	GbsSessionManager
		registerTypedWrapperAutoloadClient: 'Money'
		server: 'RemoteMoney'.

	GbsSessionManager
		unregisterTypedWrapperAutoloadClient: 'Money'
		server: 'RemoteMoney'.
	pairs := GbsSessionManager typedWrapperAutoloadPairs.

	self deny: (pairs anySatisfy: [ :pair |
		{ (pair at: 1 ifAbsent: [ '' ]). (pair at: 2 ifAbsent: [ '' ]) } asSet
			= #('Money' 'RemoteMoney') asSet ]).
	self assert: (pairs anySatisfy: [ :pair |
		{ (pair at: 1 ifAbsent: [ '' ]). (pair at: 2 ifAbsent: [ '' ]) } asSet
			= #('ByteArray' 'RemoteLedger') asSet ])
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLookupAutoloadsSessionScopedConnectorPair [
	| params session wrapperClass |
	params := GbsSessionParameters new.
	params username: 'DataCurator'.
	params gemStoneName: 'gs64stone'.
	session := CoreMockGbsSession new.
	session parameters: params.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ #(5001 'RemoteLedger' 'Object' nil nil 2 4) ].
		(script includesSubstring: 'behavior := cls.') ifTrue: [
			self assert: (script includesSubstring: '''RemoteLedger''').
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GbsSessionManager fastConnectorRegistry: Dictionary new.
	GbsSessionManager
		addConnectorClient: 'ByteArray'
		server: 'RemoteLedger'
		forSession: session.
	GBSM currentSession: session.

	wrapperClass := GbsSessionManager typedWrapperClassForServerClassNamed: 'RemoteLedger'.

	self assert: wrapperClass notNil.
	self assert: wrapperClass clientBehaviorName equals: 'ByteArray'.
	self assert: wrapperClass serverBehaviorName equals: 'RemoteLedger'.
	self assert: wrapperClass generatedForwardingSource equals: #remote.
	self assert: (wrapperClass generatedForwardingSelectors includes: #approvePayment:)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLookupForSessionDoesNotDependOnCurrentSession [
	| targetSession currentSession wrapperClass |
	targetSession := CoreMockGbsSession new.
	currentSession := CoreMockGbsSession new.
	GbsSessionManager clearAllTypedWrapperClasses.
	GbsSessionManager fastConnectorRegistry: Dictionary new.
	GbsSessionManager
		registerTypedWrapperAutoloadClient: 'ByteArray'
		server: 'RemoteSessionScopedLedger'
		forSession: targetSession.
	GbsSessionParameters currentSession: currentSession.

	wrapperClass := GbsSessionManager
		typedWrapperClassForServerClassNamed: 'RemoteSessionScopedLedger'
		forSession: targetSession.

	self assert: wrapperClass notNil.
	self assert: wrapperClass clientBehaviorName equals: 'ByteArray'.
	self assert: wrapperClass serverBehaviorName equals: 'RemoteSessionScopedLedger'.
	self assert: GbsSessionParameters currentSession == currentSession
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLookupForSessionPrefersSessionScopedAutoloadOverExistingServerWrapper [
	| targetSession existingWrapper wrapperClass |
	targetSession := CoreMockGbsSession new.
	GbsSessionManager clearAllTypedWrapperClasses.
	GbsSessionManager fastConnectorRegistry: Dictionary new.
	existingWrapper := GbsSessionManager
		generateTypedWrapperForClient: 'Array'
		server: 'RemoteSessionScopedShared'.
	GbsSessionManager
		registerTypedWrapperAutoloadClient: 'ByteArray'
		server: 'RemoteSessionScopedShared'
		forSession: targetSession.

	wrapperClass := GbsSessionManager
		typedWrapperClassForServerClassNamed: 'RemoteSessionScopedShared'
		forSession: targetSession.

	self deny: wrapperClass == existingWrapper.
	self assert: wrapperClass clientBehaviorName equals: 'ByteArray'.
	self assert: wrapperClass serverBehaviorName equals: 'RemoteSessionScopedShared'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testProxyMaterializationUsesSessionScopedTypedWrapperWhenCurrentSessionDiffers [
	| targetSession currentSession proxy |
	targetSession := CoreMockGbsSession new.
	currentSession := CoreMockGbsSession new.
	GbsSessionManager clearAllTypedWrapperClasses.
	GbsSessionManager fastConnectorRegistry: Dictionary new.
	GbsSessionManager
		registerTypedWrapperAutoloadClient: 'ByteArray'
		server: 'RemoteSessionScopedProxy'
		forSession: targetSession.
	GbsSessionParameters currentSession: currentSession.

	proxy := targetSession
		proxyForOop: 1001
		serverClassName: 'RemoteSessionScopedProxy'.

	self assert: (proxy isKindOf: GbsTypedProxy).
	self assert: proxy clientBehaviorName equals: 'ByteArray'.
	self assert: proxy serverBehaviorName equals: 'RemoteSessionScopedProxy'.
	self assert: proxy session == targetSession.
	self assert: GbsSessionParameters currentSession == currentSession
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperRegistryEntriesAndReportTextExposeAutoloadState [
	| wrapperClass entries report row |
	GbsSessionManager fastConnectorRegistry: (Dictionary new
		at: 'ByteArray' put: 'ByteArray';
		at: 'ByteArray' put: 'ByteArray';
		yourself).
	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.

	entries := GbsSessionManager typedWrapperRegistryEntries.
	report := GbsSessionManager typedWrapperAutoloadReportText.
	row := entries
		detect: [ :each | (each at: 1) = 'ByteArray' and: [ (each at: 2) = 'ByteArray' ] ]
		ifNone: [ nil ].

	self assert: row notNil.
	self assert: (row at: 3) equals: wrapperClass name asString.
	self assert: ((row at: 4) isString).
	self assert: (row at: 5).
	self assert: (report includesSubstring: 'ByteArray -> ByteArray').
	self assert: (report includesSubstring: wrapperClass name asString)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGeneratedTypedWrapperCompilesForwardingMethods [
	| wrapperClass |
	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.

	self assert: (wrapperClass methodDict includesKey: #add:).
	self assert: (wrapperClass methodDict includesKey: #size).
	self assert: (wrapperClass generatedForwardingSelectors includes: #add:).
	self assert: (wrapperClass generatedForwardingSelectors includes: #size).
	self deny: (wrapperClass generatedForwardingSelectors includes: #isNil)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGenerateTypedWrapperUsesRemoteMirrorSelectorsWhenCurrentSessionAvailable [
	| wrapperClass mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ #(5001 'RemoteLedger' 'Object' nil nil 2 4) ].
		(script includesSubstring: 'behavior := cls.') ifTrue: [
			self assert: (script includesSubstring: '''RemoteLedger''').
			^ #(
				#('accessing' #('size' 'ticketReference'))
				#('payments' #('payeeName:' 'applyAmount:currency:'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.

	self assert: (wrapperClass generatedForwardingSelectors includes: #ticketReference).
	self assert: (wrapperClass generatedForwardingSelectors includes: #payeeName:).
	self assert: (wrapperClass generatedForwardingSelectors includes: #applyAmount:currency:).
	self deny: (wrapperClass generatedForwardingSelectors includes: #add:).
	self assert: wrapperClass generatedForwardingSource equals: #remote.
	self assert: wrapperClass generatedForwardingProtocols first first equals: 'accessing'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGeneratedTypedWrapperMethodForwardsThroughSession [
	| wrapperClass proxy mockSession capturedSelector capturedArguments capturedOop result |
	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#forwarded ].
	proxy := wrapperClass oop: 1234 session: mockSession.

	result := proxy add: 2.

	self assert: result equals: #forwarded.
	self assert: capturedSelector equals: #add:.
	self assert: capturedArguments equals: #(2).
	self assert: capturedOop equals: 1234
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGenerateTypedWrappersForConnectorPairsUsesConnectorRegistry [
	| wrappers |
	GbsSessionManager fastConnectorRegistry: (Dictionary new
		at: 'ByteArray' put: 'ByteArray';
		yourself).

	wrappers := GbsSessionManager generateTypedWrappersForConnectorPairs.

	self assert: wrappers size equals: 1.
	self assert: ((GbsSessionManager typedWrapperClassForServerClassNamed: 'ByteArray')
		serverBehaviorName) equals: 'ByteArray'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLookupRefreshesExistingWrapperFromRemoteMetadata [
	| initialWrapper refreshedWrapper mockSession |
	initialWrapper := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	self assert: initialWrapper generatedForwardingSource equals: #client.

	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ #(5001 'RemoteLedger' 'Object' nil nil 2 4) ].
		(script includesSubstring: 'behavior := cls.') ifTrue: [
			self assert: (script includesSubstring: '''RemoteLedger''').
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.
	GbsSessionManager fastConnectorRegistry: (Dictionary new
		at: 'ByteArray' put: 'RemoteLedger';
		at: 'RemoteLedger' put: 'ByteArray';
		yourself).

	refreshedWrapper := GbsSessionManager typedWrapperClassForServerClassNamed: 'RemoteLedger'.

	self assert: refreshedWrapper == initialWrapper.
	self assert: refreshedWrapper generatedForwardingSource equals: #remote.
	self assert: (refreshedWrapper generatedForwardingSelectors includes: #approvePayment:).
	self assert: (refreshedWrapper generatedForwardingSelectors includes: #cancelPayment).
	self deny: (refreshedWrapper generatedForwardingSelectors includes: #add:)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGeneratedTypedWrapperStoresRemoteVersionMetadata [
	| wrapperClass mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ #(5001 'RemoteLedger' 'Object' nil nil 2 4) ].
		(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.

	self assert: wrapperClass generatedForwardingSource equals: #remote.
	self assert: wrapperClass serverBehaviorVersion equals: 2.
	self assert: wrapperClass serverBehaviorNumberOfVersions equals: 4
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLookupRefreshesRemoteWrapperWhenVersionMetadataChanges [
	| mockSession wrapperClass version |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	self assert: wrapperClass serverBehaviorNumberOfVersions equals: 4.

	version := 3.
	wrapperClass := GbsSessionManager typedWrapperClassForServerClassNamed: 'RemoteLedger'.

	self assert: wrapperClass serverBehaviorNumberOfVersions equals: 5.
	self assert: wrapperClass generatedForwardingSource equals: #remote
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperFreshnessChecksAreCachedUntilTransactionBoundary [
	| mockSession wrapperClass version mirrorFetches |
	version := 2.
	mirrorFetches := 0.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			mirrorFetches := mirrorFetches + 1.
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	self deny: (GbsSessionManager
		shouldRefreshTypedWrapperClass: wrapperClass
		server: 'RemoteLedger'
		session: mockSession).
	self deny: (GbsSessionManager
		shouldRefreshTypedWrapperClass: wrapperClass
		server: 'RemoteLedger'
		session: mockSession).
	self assert: mirrorFetches equals: 2.

	mockSession commitTransaction.
	self deny: (GbsSessionManager
		shouldRefreshTypedWrapperClass: wrapperClass
		server: 'RemoteLedger'
		session: mockSession).
	self assert: mirrorFetches equals: 3.

	mockSession abortTransaction.
	self deny: (GbsSessionManager
		shouldRefreshTypedWrapperClass: wrapperClass
		server: 'RemoteLedger'
		session: mockSession).
	self assert: mirrorFetches equals: 4
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLifecycleEntriesReflectCurrentAndStaleStatus [
	| mockSession wrapperClass version currentRow staleRow |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	currentRow := (GbsSessionManager typedWrapperLifecycleEntriesForSession: mockSession)
		detect: [ :each | each third = wrapperClass name asString ].

	version := 3.
	GbsSessionManager clearTypedWrapperFreshnessCacheForSession: mockSession.
	staleRow := (GbsSessionManager typedWrapperLifecycleEntriesForSession: mockSession)
		detect: [ :each | each third = wrapperClass name asString ].

	self assert: (currentRow at: 9) equals: 'current'.
	self assert: (staleRow at: 5) equals: 2.
	self assert: (staleRow at: 6) equals: 4.
	self assert: (staleRow at: 7) equals: 3.
	self assert: (staleRow at: 8) equals: 5.
	self assert: (staleRow at: 9) equals: 'stale'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLifecycleReportObjectExposesStructuredEntries [
	| mockSession wrapperClass version report entry |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	version := 3.
	GbsSessionManager clearTypedWrapperFreshnessCacheForSession: mockSession.
	report := GbsSessionManager typedWrapperLifecycleReportForSession: mockSession.
	entry := report entries
		detect: [ :each | each wrapperClass == wrapperClass ]
		ifNone: [ nil ].

	self assert: report entries isEmpty not.
	self assert: report entries first class equals: GbsTypedWrapperLifecycleEntry.
	self assert: entry notNil.
	self assert: entry status equals: #stale.
	self assert: (report staleEntries includes: entry).
	self assert: (report text includesSubstring: 'Typed Wrapper Lifecycle')
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperCompatibilityReportShowsCachedFreshnessDecision [
	| mockSession wrapperClass version report |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	version := 4.
	GbsSessionManager clearTypedWrapperFreshnessCacheForSession: mockSession.
	report := GbsSessionManager typedWrapperCompatibilityReportTextForSession: mockSession.

	self assert: (report includesSubstring: 'Typed Wrapper Compatibility').
	self assert: (report includesSubstring: wrapperClass name asString).
	self assert: (report includesSubstring: 'RemoteLedger').
	self assert: (report includesSubstring: '4/6').
	self assert: (report includesSubstring: 'true').
	self assert: (report includesSubstring: 'server version differs').
	self assert: (mockSession typedWrapperCompatibilityReportText includesSubstring: 'Cached Freshness')
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedProxyLifecycleHelpersExposeStructuredStatus [
	| mockSession wrapperClass version entry |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	version := 3.
	GbsSessionManager clearTypedWrapperFreshnessCacheForSession: mockSession.
	entry := wrapperClass lifecycleEntryForSession: mockSession.

	self assert: entry notNil.
	self assert: (wrapperClass lifecycleStatusForSession: mockSession) equals: #stale.
	self assert: (wrapperClass isLifecycleStaleForSession: mockSession)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testInvalidateStaleTypedWrapperClassesClearsLocalVersionMetadataButKeepsLookupViable [
	| mockSession wrapperClass version |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs
		at: #gciAbort put: 1;
		at: #executeScriptAndFetchObject
		put: [ :script |
			(script includesSubstring: 'history :=') ifTrue: [
				^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
			(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
				^ #(
					#('accessing' #('size'))
					#('payments' #('approvePayment:' 'cancelPayment'))) ].
			self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	version := 3.

	mockSession abortTransaction.

	self assert: wrapperClass serverBehaviorVersion isNil.
	self assert: wrapperClass serverBehaviorNumberOfVersions isNil.
	wrapperClass := GbsSessionManager typedWrapperClassForServerClassNamed: 'RemoteLedger'.
	self assert: wrapperClass serverBehaviorVersion equals: 3.
	self assert: wrapperClass serverBehaviorNumberOfVersions equals: 5
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testRefreshStaleTypedWrapperClassesForSessionRegeneratesWrapperMetadata [
	| mockSession wrapperClass version refreshed |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	version := 4.

	refreshed := GbsSessionManager refreshStaleTypedWrapperClassesForSession: mockSession.

	self assert: refreshed size equals: 1.
	self assert: refreshed first == wrapperClass.
	self assert: wrapperClass serverBehaviorVersion equals: 4.
	self assert: wrapperClass serverBehaviorNumberOfVersions equals: 6
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testRefreshAllTypedWrapperClassesForSessionRegeneratesAllRemoteWrappers [
	| mockSession firstWrapper secondWrapper version refreshed |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			(script includesSubstring: '''RemoteLedger''') ifTrue: [ ^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
			(script includesSubstring: '''RemoteInvoice''') ifTrue: [ ^ { 5002. 'RemoteInvoice'. 'Object'. nil. nil. version + 1. version + 3 } ] ].
		(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
			^ #(#('accessing' #('size'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	firstWrapper := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	secondWrapper := GbsSessionManager
		generateTypedWrapperForClient: 'Array'
		server: 'RemoteInvoice'.
	version := 5.
	refreshed := GbsSessionManager refreshAllTypedWrapperClassesForSession: mockSession.

	self assert: refreshed includes: firstWrapper.
	self assert: refreshed includes: secondWrapper.
	self assert: firstWrapper serverBehaviorVersion equals: 5.
	self assert: secondWrapper serverBehaviorVersion equals: 6
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testResetAfterLogoutClearsSessionTypedWrapperAutoloadRegistrations [
	| mockSession sessionKey |
	mockSession := CoreMockGbsSession new.
	sessionKey := GbsSessionManager sessionKeyForSessionObject: mockSession.

	GbsSessionManager
		registerTypedWrapperAutoloadClient: 'ByteArray'
		server: 'RemoteLedger'
		forSession: mockSession.
	self
		assert: ((GbsSessionManager sessionTypedWrapperExplicitAutoloadPairRegistry
			at: sessionKey
			ifAbsent: [ #() ]) size)
		equals: 1.

	mockSession resetAfterLogout.

	self
		assert: ((GbsSessionManager sessionTypedWrapperExplicitAutoloadRegistry
			at: sessionKey
			ifAbsent: [ Dictionary new ]) isEmpty).
	self
		assert: ((GbsSessionManager sessionTypedWrapperExplicitAutoloadPairRegistry
			at: sessionKey
			ifAbsent: [ #() ]) isEmpty)
]
