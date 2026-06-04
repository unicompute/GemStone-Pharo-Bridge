| loadFailed supportClass connectorClass clampSyncClass replicationPolicyClass lifecycleManagerClass dirtyTrackerClass session millisecondsToRun metricValue phase fixtureKey cleanupFixture manager connector replicator connectorPairCount connectorLifecycleReport scheme clampSpecOop connectorMs clampedOop clampedResult clampedMs clampedMetrics callbackSelector callbackBehaviorName domainBehaviorName domainCustomerBehaviorName applicationCallbackBehaviorName domainFixtureClass domainScheme domainCallbackScheme domainCallbackSpecOop domainCallbackVerifiedOop domainCallbackVerified domainOrderOop domainCustomerOop domainLineItemsOop domainOrder domainCustomerProxy domainLineItems domainDirtyObjectsFlushed domainDirtyStoreMs domainFlushed domainDirtyStoreReport domainNativeDirtyStoreFlushes domainNativeDirtyStoreEntries domainVerifiedOop domainVerified domainFixtureCount domainPerInstvarClampEntries domainCallbackClampSpecs mappedDomainBehaviorName inheritedMappedDomainBehaviorName mappedDomainFixtureClass mappedDomainReplicator mappedDomainScheme mappedDomainOrderOop mappedDomainCustomerOop mappedDomainLineItemsOop mappedDomainOrder mappedDomainCustomerProxy mappedDomainLineItems mappedDomainDirtyObjectsFlushed mappedDomainDirtyStoreMs mappedDomainFlushed mappedDomainDirtyStoreReport mappedDomainVerifiedOop mappedDomainVerified domainFaultReleaseBefore domainFaultReleaseQueued domainFaultReleaseAfterFault domainFaultIdentityCleared domainFaultIdentityRestored mappedDomainFaultProxy mappedDomainFaultRefetched callbackScheme callbackClampSpecOop callbackVerifiedOop callbackVerified perInstvarClampEntries callbackClampSpecs inheritedFixtureClass pointerReplicatorClass inheritedConnector inheritedReplicator inheritedReplicationSpecFixtures policy previousTransport previousProfile dirtyRootOop dirtyRoot releaseNoLongerOop releaseGcedOop releaseNoLongerObject releaseGcedObject exportBefore exportAfter lifecycleReport lifecycleNoLongerQueued lifecycleGcedQueued lifecycleNoLongerAcknowledged lifecycleGcedAcknowledged dirtyStoreMs flushed dirtyStoreReport semanticDirtyStoreCommands semanticDirtyStoreEntries semanticDictionaryEntries semanticSetEntries semanticBagEntries verified verifiedOop nativeDirtyStoreFlushes clampedFetches clampedFallbacks dirtyObjectsFlushed businessRootOop businessRoot businessFixtureSize businessDirtyObjectsFlushed businessDirtyStoreMs businessFlushed businessExportAfter businessVerifiedOop businessVerified |
[
  loadFailed := false.
  cleanupFixture := [ ].
  [ Metacello new
      baseline: 'GemStonePharo';
      repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
      load: 'default' ] on: Error do: [ :ex |
        loadFailed := true.
        Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

  loadFailed ifTrue: [
    Transcript
      show: 'REPLICATION_LIVE_VALIDATION result=FAIL code=REPLICATION_LIVE_LOAD_FAILED connector_ms=0 clamped_ms=0 dirty_store_ms=0';
      cr ] ifFalse: [
    [
      millisecondsToRun := [ :block |
        | start elapsed |
        start := Time millisecondClockValue.
        block value.
        elapsed := Time millisecondClockValue - start.
        elapsed < 0 ifTrue: [ elapsed := elapsed + 86400000 ].
        elapsed ].
      metricValue := [ :metrics :key |
        metrics at: key ifAbsent: [ 0 ] ].
      phase := 'initializing'.
      fixtureKey := #GbsReplicationLiveValidationFixture.

      supportClass := Smalltalk
        at: #GbsLiveSessionTestSupport
        ifAbsent: [ Smalltalk at: #CoreGbsLiveSessionTestSupport ifAbsent: [ nil ] ].
      supportClass ifNil: [
        Error signal: 'Missing live session support class.' ].
      connectorClass := Smalltalk at: #GbsClientClassConnector ifAbsent: [ nil ].
      connectorClass ifNil: [
        Error signal: 'Missing client class connector class.' ].
      clampSyncClass := Smalltalk at: #GbsServerClampSpecificationSynchronizer ifAbsent: [ nil ].
      clampSyncClass ifNil: [
        Error signal: 'Missing server clamp specification synchronizer class.' ].
      replicationPolicyClass := Smalltalk at: #GbsReplicationPolicy ifAbsent: [ nil ].
      replicationPolicyClass ifNil: [
        Error signal: 'Missing replication policy class.' ].
      lifecycleManagerClass := Smalltalk at: #GbsSessionLifecycleManager ifAbsent: [ nil ].
      lifecycleManagerClass ifNil: [
        Error signal: 'Missing session lifecycle manager class.' ].
      dirtyTrackerClass := Smalltalk at: #GbsMaterializedObjectDirtyTracker ifAbsent: [ nil ].
      dirtyTrackerClass ifNil: [
        Error signal: 'Missing materialized object dirty tracker class.' ].
      session := supportClass ensureSharedSession.
      (supportClass sessionIsUsable: session) ifFalse: [
        Error signal: supportClass unavailableReason ].
      Smalltalk globals
        at: #GbsReplicationLiveNativeCapabilityMetrics
        put: (Dictionary new
          at: #materializationTraversalTransportSupported
            put: ((session nativeMaterializationTraversalCapabilityReport
              at: #materializationTraversalBufferTransportSupported
              ifAbsent: [ false ]) ifTrue: [ 1 ] ifFalse: [ 0 ]);
          at: #materializationReportShapeSupported
            put: ((session nativeMaterializationTraversalCapabilityReport
              at: #materializationTraversalReportShapeSupported
              ifAbsent: [ false ]) ifTrue: [ 1 ] ifFalse: [ 0 ]);
          at: #materializationOopWidth
            put: (session nativeMaterializationTraversalCapabilityReport at: #oopWidth ifAbsent: [ 0 ]);
          yourself).
      cleanupFixture := [
        session ifNotNil: [
          callbackBehaviorName ifNotNil: [
            [ session
                fetchRemoteCommandBody: '| tempDict |
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
tempDict ifNotNil: [
	tempDict removeKey: behaviorName asSymbol ifAbsent: [ nil ] ].
true'
                literalBindings: (Dictionary new
                  at: 'behaviorName' put: callbackBehaviorName;
                  yourself)
                oopBindings: Dictionary new
                context: 20 ]
              on: Error
              do: [ ] ].
          domainBehaviorName ifNotNil: [
            [ session
                fetchRemoteCommandBody: '| tempDict |
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
tempDict ifNotNil: [
	tempDict removeKey: behaviorName asSymbol ifAbsent: [ nil ] ].
true'
                literalBindings: (Dictionary new
                  at: 'behaviorName' put: domainBehaviorName;
                  yourself)
                oopBindings: Dictionary new
                context: 20 ]
              on: Error
              do: [ ] ].
          domainCustomerBehaviorName ifNotNil: [
            [ session
                fetchRemoteCommandBody: '| tempDict |
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
tempDict ifNotNil: [
	tempDict removeKey: behaviorName asSymbol ifAbsent: [ nil ] ].
true'
                literalBindings: (Dictionary new
                  at: 'behaviorName' put: domainCustomerBehaviorName;
                  yourself)
                oopBindings: Dictionary new
                context: 20 ]
              on: Error
              do: [ ] ].
          applicationCallbackBehaviorName ifNotNil: [
            [ session
                fetchRemoteCommandBody: '| tempDict |
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
tempDict ifNotNil: [
	tempDict removeKey: behaviorName asSymbol ifAbsent: [ nil ] ].
true'
                literalBindings: (Dictionary new
                  at: 'behaviorName' put: applicationCallbackBehaviorName;
                  yourself)
                oopBindings: Dictionary new
                context: 20 ]
              on: Error
              do: [ ] ].
          mappedDomainBehaviorName ifNotNil: [
            [ session
                fetchRemoteCommandBody: '| tempDict |
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
tempDict ifNotNil: [
	tempDict removeKey: behaviorName asSymbol ifAbsent: [ nil ] ].
true'
                literalBindings: (Dictionary new
                  at: 'behaviorName' put: mappedDomainBehaviorName;
                  yourself)
                oopBindings: Dictionary new
                context: 20 ]
              on: Error
              do: [ ] ].
          inheritedMappedDomainBehaviorName ifNotNil: [
            [ session
                fetchRemoteCommandBody: '| tempDict |
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
tempDict ifNotNil: [
	tempDict removeKey: behaviorName asSymbol ifAbsent: [ nil ] ].
true'
                literalBindings: (Dictionary new
                  at: 'behaviorName' put: inheritedMappedDomainBehaviorName;
                  yourself)
                oopBindings: Dictionary new
                context: 20 ]
              on: Error
              do: [ ] ].
          [ session
              fetchRemoteCommandBody: 'UserGlobals removeKey: fixtureKey ifAbsent: [ nil ]. nil'
              literalBindings: (Dictionary new
                at: 'fixtureKey' put: fixtureKey;
                yourself)
              oopBindings: Dictionary new
              context: 20 ]
            on: Error
            do: [ ] ] ].

      [
        phase := 'cleanup-before-fixtures'.
        cleanupFixture value.
        [ session abortTransaction ] on: Error do: [ ].
        [ session checkForError ] on: Error do: [ ].
        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        session resetMaterializedObjectDirtyTracking.
        session fetchDeep.
        domainFaultReleaseQueued := 0.
        domainFaultReleaseAfterFault := 0.
        domainFaultIdentityCleared := 0.
        domainFaultIdentityRestored := 0.
        Smalltalk globals
          at: #GbsReplicationLiveStrictParityMetrics
          put: (Dictionary new
            at: #domainCallbackTraversalFixtures put: 0;
            at: #domainFaultLifecycleFixtures put: 0;
            at: #domainMappedLifecycleFixtures put: 0;
            at: #connectorClassVersionReportCount put: 0;
            at: #connectorClassVersionMismatchCount put: 0;
            at: #connectorClassVersionUnknownCount put: 0;
            at: #connectorClassVersionErrorCount put: 0;
            yourself).

        manager := session replicatorManager.

        phase := 'migration-domain-mapped-lifecycle-commit'.
        mappedDomainFixtureClass := Smalltalk
          at: #CoreGbsMigrationDomainInheritedMappedOrder
          ifAbsent: [ Error signal: 'Missing inherited mapped migration-domain order fixture class.' ].
        pointerReplicatorClass := Smalltalk
          at: #GbxPointerObjectReplicator
          ifAbsent: [ Error signal: 'Missing pointer-object replicator class.' ].
        connector := connectorClass
          client: mappedDomainFixtureClass
          server: 'GbsMigrationLiveCommitMappedOrder'
          replicationSpec: mappedDomainFixtureClass migrationDomainReplicationSpec
          serverInstVarNames: mappedDomainFixtureClass migrationDomainServerInstVarNames.
        connector replicatorClass: pointerReplicatorClass.
        mappedDomainReplicator := manager installClientClassConnector: connector.
        mappedDomainOrder := mappedDomainFixtureClass basicNew.
        session rememberMaterializedObject: mappedDomainOrder forOop: 11008.
        mappedDomainOrder gbsInstVarAt: 6 put: 1.
        (session dirtyMaterializedObjectOops includes: 11008) ifFalse: [
          Error signal: 'Mapped lifecycle commit fixture did not mark the mapped object dirty.' ].
        (session materializedObjectForOop: 11008) == mappedDomainOrder ifFalse: [
          Error signal: 'Mapped lifecycle commit fixture was not present in the materialized identity cache before commit.' ].
        session commitTransaction ifFalse: [
          Error signal: 'Mapped lifecycle commit fixture could not commit the live session.' ].
        session dirtyMaterializedObjectOops isEmpty ifFalse: [
          Error signal: 'Mapped lifecycle commit did not clear dirty materialized objects.' ].
        (session materializedObjectForOop: 11008) isNil ifFalse: [
          Error signal: 'Mapped lifecycle commit did not clear materialized identity cache.' ].
        (manager replicatorForClientBehavior: mappedDomainFixtureClass ifAbsent: [ nil ]) == mappedDomainReplicator ifFalse: [
          Error signal: 'Mapped lifecycle commit unexpectedly discarded the live mapped replicator.' ].
        (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
          at: #domainMappedLifecycleFixtures
          put: (metricValue
            value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
            value: #domainMappedLifecycleFixtures) + 1.

        phase := 'connector-install'.
        connector := connectorClass
          client: Association
          server: Association
          replicationSpec: #(
            #(#key #replicate)
            #(#value #replicate)
            #(#address #min 1)
            #(#notes #stub))
          serverInstVarNames: #('key' 'value').
        connectorMs := millisecondsToRun value: [
          replicator := manager installClientClassConnector: connector ].
        replicator ifNil: [ Error signal: 'Client class connector did not install a replicator.' ].
        (manager replicatorForClientBehavior: Association ifAbsent: [ nil ]) == replicator
          ifFalse: [ Error signal: 'Installed connector is missing from the client replicator map.' ].
        (manager serverMap at: Association ifAbsent: [ nil ]) == replicator
          ifFalse: [ Error signal: 'Installed connector is missing from the server replicator map.' ].
        connectorPairCount := (manager connectorManagerReport)
          at: #connectorPairCount
          ifAbsent: [ 0 ].
        connectorPairCount <= 0 ifTrue: [
          Error signal: 'Replicator manager report did not expose the installed connector pair.' ].
        scheme := manager currentReplicationScheme.
        scheme hasServerClampMetadata ifFalse: [
          Error signal: 'Installed connector did not update clamp metadata.' ].
        ((scheme transitiveClosureSpecForReplicationSpec: connector replicationSpec) = #(
          #(#key #replicate)
          #(#value #replicate)))
            ifFalse: [ Error signal: 'VisualWorks transitive closure replication spec filtering failed.' ].

        phase := 'server-clamp-sync'.
        clampSpecOop := clampSyncClass
          clampSpecOopForScheme: scheme
          session: session.
        (clampSpecOop isNil or: [ clampSpecOop <= 20 ]) ifTrue: [
          Error signal: 'Server clamp specification was not installed.' ].
        perInstvarClampEntries := scheme serverClampInstVarLevelEntries size.
        perInstvarClampEntries <= 0 ifTrue: [
          Error signal: 'Per-instvar clamp metadata was not populated for the migration connector fixture.' ].

        phase := 'callback-clamp-sync'.
        callbackSelector := #gbsMigrationReplicationSpecGbsClampCallback.
        callbackBehaviorName := 'GbsReplicationLiveCallbackFixture'.
        session
          fetchRemoteCommandBody: '| tempDict callbackClass |
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
tempDict ifNil: [
	tempDict := SymbolDictionary new name: #PharoSessionGlobals.
	System myUserProfile insertDictionary: tempDict at: 1 ].
callbackClass := tempDict at: behaviorName asSymbol ifAbsent: [ nil ].
(callbackClass isNil or: [ callbackClass isBehavior not ]) ifTrue: [
	callbackClass := Object subclass: behaviorName
		instVarNames: #()
		classVars: #()
		classInstVars: #()
		poolDictionaries: #()
		inDictionary: tempDict
		options: #().
	tempDict at: behaviorName asSymbol put: callbackClass ].
callbackClass compileMethod: source category: #''gbs-live-validation''.
true'
          literalBindings: (Dictionary new
            at: 'behaviorName' put: callbackBehaviorName;
            at: 'source' put: 'gbsMigrationReplicationSpecGbsClampCallback
	^ nil';
            yourself)
          oopBindings: Dictionary new
          context: 20.
        callbackScheme := manager replicationSchemeForSet: #gbsMigrationReplicationSpec.
        callbackScheme
          updateForClampingByCallback: true
          inSession: session
          serverBehavior: callbackBehaviorName.
        callbackClampSpecOop := clampSyncClass
          clampSpecOopForScheme: callbackScheme
          session: session.
        (callbackClampSpecOop isNil or: [ callbackClampSpecOop <= 20 ]) ifTrue: [
          Error signal: 'Callback clamp specification was not installed.' ].
        callbackVerifiedOop := session
          returnRemoteCommandBody: '| spec selector status |
spec := object.
status := 17.
selector := nil.
[ selector := spec instVarLevelsSelector ] on: Error do: [ :ignored |
  [ selector := spec instVarAt: 5 ] on: Error do: [ :ignored2 | nil ] ].
selector = expectedSelector ifFalse: [ status := 18 ].
status'
          literalBindings: (Dictionary new
            at: 'expectedSelector' put: callbackSelector;
            yourself)
          oopBindings: (Dictionary new
            at: 'object' put: callbackClampSpecOop;
            yourself).
        callbackVerified := session resultFor: callbackVerifiedOop.
        callbackVerified = 17 ifFalse: [
          Error signal: 'Callback clamp specification did not retain the expected server callback selector.' ].
        callbackClampSpecs := 1.

        phase := 'clamped-fixture'.
        clampedOop := session
          returnRemoteCommandBody: '| fixture association |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
association := Association key: 101 value: 202.
fixture at: #clamped put: association.
association'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            yourself)
          oopBindings: Dictionary new.
        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        session fetchDeep.
        phase := 'clamped-fetch'.
        clampedMs := millisecondsToRun value: [
          clampedResult := session fetchObject: clampedOop ].
        clampedMetrics := session materializationMetrics copy.
        ((clampedResult key = 101)
          and: [ clampedResult value = 202 ]) ifFalse: [
            Error signal: 'Clamped Association materialization produced an unexpected result.' ].
        clampedFetches := metricValue value: clampedMetrics value: #clampedTraversalBufferFetchCalls.
        clampedFallbacks := metricValue value: clampedMetrics value: #structuredTraversalBufferFallbacks.
        clampedFetches <= 0 ifTrue: [
          Error signal: 'Clamped connector materialization did not use GciClampedTrav.' ].
        clampedFallbacks = 0 ifFalse: [
          Error signal: 'Clamped connector materialization fell back from traversal-buffer transport.' ].

        phase := 'inherited-replication-spec-fixture'.
        inheritedFixtureClass := Smalltalk
          at: #CoreGbsInheritedReplicationSpecFixture
          ifAbsent: [ Error signal: 'Missing inherited replication-spec fixture class.' ].
        pointerReplicatorClass := Smalltalk
          at: #GbxPointerObjectReplicator
          ifAbsent: [ Error signal: 'Missing pointer-object replicator class.' ].
        inheritedConnector := connectorClass
          client: inheritedFixtureClass
          server: 'RemoteInheritedMigrationFixture'
          replicationSpec: nil
          serverInstVarNames: #('key' 'value').
        inheritedConnector replicatorClass: pointerReplicatorClass.
        inheritedReplicator := manager installClientClassConnector: inheritedConnector.
        inheritedReplicator ifNil: [
          Error signal: 'Inherited replication-spec fixture did not install a replicator.' ].
        ((manager replicationSchemeForSet: #customerReplicationSpec)
          instVarLevelsForClass: inheritedFixtureClass) = { 0. false. nil } ifFalse: [
          Error signal: 'Inherited VisualWorks replication spec did not hydrate expected per-instvar levels.' ].
        inheritedReplicationSpecFixtures := 1.

        phase := 'dirty-store-fixture'.
        session serverInterface supportsDirtyStoreTraversalBufferTransport == true ifFalse: [
          Error signal: 'GemStone server interface does not expose native dirty-store traversal buffer transport.' ].
        policy := replicationPolicyClass forSession: session.
        previousTransport := policy storeTraversalTransport.
        previousProfile := session fetchProfile.

        phase := 'migration-domain-server-fixture'.
        domainBehaviorName := 'GbsMigrationLiveOrder'.
        domainCustomerBehaviorName := 'GbsMigrationLiveCustomer'.
        applicationCallbackBehaviorName := 'GbsMigrationLiveInsuranceClaim'.
        domainFixtureClass := Smalltalk
          at: #CoreGbsMigrationDomainOrder
          ifAbsent: [ Error signal: 'Missing migration-domain order fixture class.' ].
        session
          fetchRemoteCommandBody: '| tempDict orderClass customerClass claimClass orderName customerName claimName |
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
tempDict ifNil: [
	tempDict := SymbolDictionary new name: #PharoSessionGlobals.
	System myUserProfile insertDictionary: tempDict at: 1 ].
orderName := orderClassName asSymbol.
customerName := customerClassName asSymbol.
claimName := claimClassName asSymbol.
tempDict removeKey: orderName ifAbsent: [ nil ].
tempDict removeKey: customerName ifAbsent: [ nil ].
tempDict removeKey: claimName ifAbsent: [ nil ].
customerClass := Object subclass: customerClassName
	instVarNames: #(''name'' ''tier'')
	classVars: #()
	classInstVars: #()
	poolDictionaries: #()
	inDictionary: tempDict
	options: #().
orderClass := Object subclass: orderClassName
	instVarNames: #(''customer'' ''lineItems'' ''total'' ''transientCache'' ''auditTrail'')
	classVars: #()
	classInstVars: #()
	poolDictionaries: #()
	inDictionary: tempDict
	options: #().
claimClass := Object subclass: claimClassName
	instVarNames: #(''claimNumber'' ''policy'' ''claimant'' ''documents'' ''severity'' ''riskProfile'' ''payload'' ''workflowState'')
	classVars: #()
	classInstVars: #()
	poolDictionaries: #()
	inDictionary: tempDict
	options: #().
tempDict at: customerName put: customerClass.
tempDict at: orderName put: orderClass.
tempDict at: claimName put: claimClass.
Object compileMethod: objectCallbackSource category: #''gbs-live-validation''.
orderClass compileMethod: callbackSource category: #''gbs-live-validation''.
claimClass compileMethod: claimCallbackSource category: #''gbs-live-validation''.
true'
          literalBindings: (Dictionary new
            at: 'orderClassName' put: domainBehaviorName;
            at: 'customerClassName' put: domainCustomerBehaviorName;
            at: 'claimClassName' put: applicationCallbackBehaviorName;
            at: 'objectCallbackSource' put: 'migrationDomainCallbackReplicationSpecGbsClampCallback
	^ nil';
            at: 'callbackSource' put: 'migrationDomainCallbackReplicationSpecGbsClampCallback
	^ (self instVarAt: 3) = 999
		ifTrue: [ #(false -1 0 nil 0 nil) ]
		ifFalse: [ #(false -2 1 nil 0 nil) ]';
            at: 'claimCallbackSource' put: 'migrationDomainCallbackReplicationSpecGbsClampCallback
	^ (self instVarAt: 5) = #critical
		ifTrue: [ #(false -2 1 0 nil -1 0 1 nil) ]
		ifFalse: [ #(false 0 0 0 nil 0 0 0 nil) ]';
            yourself)
          oopBindings: Dictionary new
          context: 20.

        phase := 'migration-domain-connector'.
        connector := connectorClass
          client: domainFixtureClass
          server: domainBehaviorName
          replicationSpec: domainFixtureClass migrationDomainReplicationSpec
          serverInstVarNames: domainFixtureClass migrationDomainServerInstVarNames.
        connector replicatorClass: pointerReplicatorClass.
        phase := 'migration-domain-connector-install'.
        manager installClientClassConnector: connector.
        phase := 'migration-domain-connector-levels'.
        domainScheme := manager currentReplicationScheme.
        (domainScheme instVarLevelsForClass: domainFixtureClass) = { false. -2. 1. nil. 0. nil } ifFalse: [
          Error signal: 'Migration-domain per-instvar levels did not match VW policy shape.' ].
        (domainScheme shouldProxyNamedSlot: 1 ofClass: domainFixtureClass) ifFalse: [
          Error signal: 'Migration-domain customer slot was not marked as a forwarder.' ].
        (domainScheme shouldProxyNamedSlot: 2 ofClass: domainFixtureClass) ifTrue: [
          Error signal: 'Migration-domain line item slot was unexpectedly marked as a forwarder.' ].
        ((domainScheme transitiveClosureSpecForReplicationSpec: domainFixtureClass migrationDomainReplicationSpec)
          = #(
            #(#customer #forwarder)
            #(#indexable_part #replicate))) ifFalse: [
              Error signal: 'Migration-domain transitive closure spec did not match VW filtering rules.' ].
        phase := 'migration-domain-connector-clamp-entries'.
        domainPerInstvarClampEntries := domainScheme serverClampInstVarLevelEntries size.
        domainPerInstvarClampEntries <= perInstvarClampEntries ifTrue: [
          Error signal: 'Migration-domain connector did not add server clamp instvar entries.' ].
        phase := 'migration-domain-callback-scheme'.
        domainCallbackScheme := manager replicationSchemeForSet: #migrationDomainCallbackReplicationSpec.
        phase := 'migration-domain-callback-clamp-spec'.
        domainCallbackSpecOop := clampSyncClass
          clampSpecOopForScheme: domainCallbackScheme
          session: session.
        (domainCallbackSpecOop isNil or: [ domainCallbackSpecOop <= 20 ]) ifTrue: [
          Error signal: 'Migration-domain callback clamp specification was not installed.' ].
        phase := 'migration-domain-callback-clamp-verify'.
        domainCallbackVerifiedOop := session
          returnRemoteCommandBody: '| spec selector status |
spec := object.
status := 43.
selector := nil.
[ selector := spec instVarLevelsSelector ] on: Error do: [ :ignored |
  [ selector := spec instVarAt: 5 ] on: Error do: [ :ignored2 | nil ] ].
selector = expectedSelector ifFalse: [ status := 44 ].
status'
          literalBindings: (Dictionary new
            at: 'expectedSelector' put: #migrationDomainCallbackReplicationSpecGbsClampCallback;
            yourself)
          oopBindings: (Dictionary new
            at: 'object' put: domainCallbackSpecOop;
            yourself).
        domainCallbackVerified := session resultFor: domainCallbackVerifiedOop.
        domainCallbackVerified = 43 ifFalse: [
          Error signal: 'Migration-domain callback clamp specification did not retain the expected selector.' ].
        domainCallbackClampSpecs := 1.

        phase := 'migration-domain-callback-dynamic-traversal'.
        clampedOop := session
          returnRemoteCommandBody: '| fixture tempDict orderClass customerClass customer lines order |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
orderClass := tempDict at: orderClassName asSymbol.
customerClass := tempDict at: customerClassName asSymbol.
customer := customerClass new.
customer
	instVarAt: 1 put: #callbackCustomer;
	instVarAt: 2 put: 5.
lines := OrderedCollection new.
lines add: 8; add: 9.
order := orderClass new.
order
	instVarAt: 1 put: customer;
	instVarAt: 2 put: lines;
	instVarAt: 3 put: 999;
	instVarAt: 4 put: Dictionary new;
	instVarAt: 5 put: #callback.
fixture at: #domainCallbackOrder put: order.
order'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            at: 'orderClassName' put: domainBehaviorName;
            at: 'customerClassName' put: domainCustomerBehaviorName;
            yourself)
          oopBindings: Dictionary new.
        domainCallbackVerifiedOop := session
          returnRemoteCommandBody: '| levels status |
levels := object migrationDomainCallbackReplicationSpecGbsClampCallback.
status := 76.
(levels = #(false -1 0 nil 0 nil)) ifFalse: [ status := 77 ].
status'
          literalBindings: Dictionary new
          oopBindings: (Dictionary new
            at: 'object' put: clampedOop;
            yourself).
        domainCallbackVerified := session resultFor: domainCallbackVerifiedOop.
        domainCallbackVerified = 76 ifFalse: [
          Error signal: 'Migration-domain callback method did not return the dynamic traversal levels for the live object.' ].
        session resetMaterializationMetrics.
        manager
          usingReplicationSpecSet: #migrationDomainCallbackReplicationSpec
          do: [
            clampedResult := (((Smalltalk at: #GbsMaterializationTraversalBufferReader) on: session)
              reportsForOops: { clampedOop }
              level: 1
              label: 'migration-domain-callback-traversal')
                at: clampedOop
                ifAbsent: [ nil ] ].
        clampedFetches := metricValue value: session materializationMetrics value: #clampedTraversalBufferFetchCalls.
        clampedFallbacks := metricValue value: session materializationMetrics value: #structuredTraversalBufferFallbacks.
        clampedFetches <= 0 ifTrue: [
          Error signal: 'Migration-domain callback traversal did not use clamped traversal-buffer transport.' ].
        clampedFallbacks = 0 ifFalse: [
          Error signal: 'Migration-domain callback traversal fell back from traversal-buffer transport.' ].
        (clampedResult isNil or: [ clampedResult oop ~= clampedOop ]) ifTrue: [
          Error signal: 'Migration-domain callback traversal did not return an object report for the live callback fixture.' ].
        (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
          at: #domainCallbackTraversalFixtures
          put: (metricValue
            value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
            value: #domainCallbackTraversalFixtures) + 1.
        domainFixtureCount := 1.

        phase := 'migration-domain-application-callback-traversal'.
        clampedOop := session
          returnRemoteCommandBody: '| fixture tempDict claimClass claim documents payload risk workflow |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
claimClass := tempDict at: claimClassName asSymbol.
documents := OrderedCollection new.
documents
	add: (Association key: #estimate value: 42500);
	add: (Association key: #adjuster value: #assigned).
payload := ByteArray new: 4.
payload
	at: 1 put: 1;
	at: 2 put: 127;
	at: 3 put: 128;
	at: 4 put: 255.
risk := Dictionary new.
risk
	at: #score put: 91;
	at: #flags put: #(fire largeLoss manualReview).
workflow := Array with: #opened with: #fieldInspection with: #reserveReview.
claim := claimClass new.
claim
	instVarAt: 1 put: #CLM20260603;
	instVarAt: 2 put: #POLICY778;
	instVarAt: 3 put: #businessAccount;
	instVarAt: 4 put: documents;
	instVarAt: 5 put: #critical;
	instVarAt: 6 put: risk;
	instVarAt: 7 put: payload;
	instVarAt: 8 put: workflow.
fixture at: #applicationCallbackClaim put: claim.
claim'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            at: 'claimClassName' put: applicationCallbackBehaviorName;
            yourself)
          oopBindings: Dictionary new.
        domainCallbackVerifiedOop := session
          returnRemoteCommandBody: '| levels status |
levels := object migrationDomainCallbackReplicationSpecGbsClampCallback.
status := 86.
(levels = #(false -2 1 0 nil -1 0 1 nil)) ifFalse: [ status := 87 ].
status'
          literalBindings: Dictionary new
          oopBindings: (Dictionary new
            at: 'object' put: clampedOop;
            yourself).
        domainCallbackVerified := session resultFor: domainCallbackVerifiedOop.
        domainCallbackVerified = 86 ifFalse: [
          Error signal: 'Application-domain callback method did not return the expected dynamic traversal levels for the live claim fixture.' ].
        session resetMaterializationMetrics.
        manager
          usingReplicationSpecSet: #migrationDomainCallbackReplicationSpec
          do: [
            clampedResult := (((Smalltalk at: #GbsMaterializationTraversalBufferReader) on: session)
              reportsForOops: { clampedOop }
              level: 1
              label: 'migration-domain-application-callback-traversal')
                at: clampedOop
                ifAbsent: [ nil ] ].
        clampedFetches := metricValue value: session materializationMetrics value: #clampedTraversalBufferFetchCalls.
        clampedFallbacks := metricValue value: session materializationMetrics value: #structuredTraversalBufferFallbacks.
        clampedFetches <= 0 ifTrue: [
          Error signal: 'Application-domain callback traversal did not use clamped traversal-buffer transport.' ].
        clampedFallbacks = 0 ifFalse: [
          Error signal: 'Application-domain callback traversal fell back from traversal-buffer transport.' ].
        (clampedResult isNil or: [ clampedResult oop ~= clampedOop ]) ifTrue: [
          Error signal: 'Application-domain callback traversal did not return an object report for the live claim fixture.' ].
        (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
          at: #domainCallbackTraversalFixtures
          put: (metricValue
            value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
            value: #domainCallbackTraversalFixtures) + 1.
        domainFixtureCount := domainFixtureCount + 1.

        phase := 'migration-domain-dirty-store-fixture'.
        domainOrderOop := session
          returnRemoteCommandBody: '| fixture tempDict orderClass customerClass order customer lines |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
orderClass := tempDict at: orderClassName asSymbol.
customerClass := tempDict at: customerClassName asSymbol.
customer := customerClass new.
customer
	instVarAt: 1 put: #customerA;
	instVarAt: 2 put: 2.
lines := OrderedCollection new.
lines add: 1; add: 2.
order := orderClass new.
order
	instVarAt: 1 put: customer;
	instVarAt: 2 put: lines;
	instVarAt: 3 put: 123;
	instVarAt: 4 put: Dictionary new;
	instVarAt: 5 put: #created.
fixture
	at: #domainCustomer put: customer;
	at: #domainOrder put: order.
order'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            at: 'orderClassName' put: domainBehaviorName;
            at: 'customerClassName' put: domainCustomerBehaviorName;
            yourself)
          oopBindings: Dictionary new.
        domainCustomerOop := session
          returnRemoteCommandBody: '(UserGlobals at: fixtureKey) at: #domainCustomer'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            yourself)
          oopBindings: Dictionary new.
        domainLineItemsOop := session
          returnRemoteCommandBody: '((UserGlobals at: fixtureKey) at: #domainOrder) instVarAt: 2'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            yourself)
          oopBindings: Dictionary new.
        session resetMaterializedObjectDirtyTracking.
        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        session fetchDeep.
        domainLineItems := session fetchObject: domainLineItemsOop.
        domainCustomerProxy := session
          proxyForOop: domainCustomerOop
          serverClassName: domainCustomerBehaviorName.
        domainOrder := domainFixtureClass basicNew.
        domainOrder
          instVarAt: 1 put: domainCustomerProxy;
          instVarAt: 2 put: domainLineItems;
          instVarAt: 3 put: 987;
          instVarAt: 4 put: nil;
          instVarAt: 5 put: #validated.
        dirtyTrackerClass
          registerObject: domainOrder
          oop: domainOrderOop
          session: session.
        domainLineItems add: 3.
        dirtyTrackerClass
          markObject: domainLineItems
          dirtyInSession: session.
        dirtyTrackerClass
          markObject: domainOrder
          dirtyInSession: session.
        domainDirtyObjectsFlushed := session dirtyMaterializedObjectOops size.
        domainDirtyObjectsFlushed < 2 ifTrue: [
          Error signal: 'Migration-domain dirty-store fixture did not mark the order and line-items dirty.' ].
        policy storeTraversalTransport: 'binaryRequired'.
        domainDirtyStoreMs := millisecondsToRun value: [
          domainFlushed := session flushDirtyMaterializedObjects ].
        domainDirtyStoreReport := session dirtyStoreTraversalReport.
        domainNativeDirtyStoreFlushes := metricValue value: domainDirtyStoreReport value: #nativeFlushCount.
        domainNativeDirtyStoreEntries := metricValue value: domainDirtyStoreReport value: #nativeEntryCount.
        domainNativeDirtyStoreFlushes <= 0 ifTrue: [
          Error signal: 'Migration-domain dirty-store flush did not use native traversal buffers.' ].
        domainNativeDirtyStoreEntries < 2 ifTrue: [
          Error signal: 'Migration-domain dirty-store flush did not encode the named object and line-items natively.' ].
        domainFlushed size < 2 ifTrue: [
          Error signal: 'Migration-domain dirty-store traversal flushed fewer objects than expected.' ].
        domainVerifiedOop := session
          returnRemoteCommandBody: '| order status |
order := object.
status := 47.
(order class name asString = orderClassName) ifFalse: [ status := 48 ].
(status = 47 and: [ (order instVarAt: 1) class name asString = customerClassName ]) ifFalse: [
  status = 47 ifTrue: [ status := 49 ] ].
(status = 47 and: [ (order instVarAt: 2) asArray = #(1 2 3) ]) ifFalse: [
  status = 47 ifTrue: [ status := 50 ] ].
(status = 47 and: [ (order instVarAt: 3) = 987 ]) ifFalse: [
  status = 47 ifTrue: [ status := 51 ] ].
(status = 47 and: [ (order instVarAt: 4) isNil ]) ifFalse: [
  status = 47 ifTrue: [ status := 52 ] ].
(status = 47 and: [ (order instVarAt: 5) = #validated ]) ifFalse: [
  status = 47 ifTrue: [ status := 53 ] ].
status'
          literalBindings: (Dictionary new
            at: 'orderClassName' put: domainBehaviorName;
            at: 'customerClassName' put: domainCustomerBehaviorName;
            yourself)
          oopBindings: (Dictionary new
            at: 'object' put: domainOrderOop;
            yourself).
        domainVerified := session resultFor: domainVerifiedOop.
        domainVerified = 47 ifFalse: [
          Error signal: 'Migration-domain dirty-store validation failed status=', domainVerified asString, ' oop=', domainVerifiedOop asString, ' (48=class 49=customer 50=lineItems 51=total 52=cache 53=auditTrail).' ].

        phase := 'migration-domain-instvar-map-fixture'.
        mappedDomainBehaviorName := 'GbsMigrationLiveMappedOrder'.
        mappedDomainFixtureClass := Smalltalk
          at: #CoreGbsMigrationDomainMappedOrder
          ifAbsent: [ Error signal: 'Missing mapped migration-domain order fixture class.' ].
        session
          fetchRemoteCommandBody: '| tempDict orderClass orderName |
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
tempDict ifNil: [
	tempDict := SymbolDictionary new name: #PharoSessionGlobals.
	System myUserProfile insertDictionary: tempDict at: 1 ].
orderName := orderClassName asSymbol.
tempDict removeKey: orderName ifAbsent: [ nil ].
orderClass := Object subclass: orderClassName
	instVarNames: #(''buyer'' ''items'' ''transientCache'' ''amount'' ''audit'')
	classVars: #()
	classInstVars: #()
	poolDictionaries: #()
	inDictionary: tempDict
	options: #().
tempDict at: orderName put: orderClass.
true'
          literalBindings: (Dictionary new
            at: 'orderClassName' put: mappedDomainBehaviorName;
            yourself)
          oopBindings: Dictionary new
          context: 20.
        connector := connectorClass
          client: mappedDomainFixtureClass
          server: mappedDomainBehaviorName
          replicationSpec: mappedDomainFixtureClass migrationDomainReplicationSpec
          serverInstVarNames: mappedDomainFixtureClass migrationDomainServerInstVarNames.
        connector replicatorClass: pointerReplicatorClass.
        mappedDomainReplicator := manager installClientClassConnector: connector.
        mappedDomainScheme := manager currentReplicationScheme.
        (mappedDomainScheme instVarLevelsForClass: mappedDomainFixtureClass) = { false. -2. false. 1. 0. nil } ifFalse: [
          Error signal: 'Mapped migration-domain per-instvar levels did not match VW instVarMap policy shape.' ].
        ((mappedDomainReplicator respondsTo: #serverToClientOffsets)
          and: [ mappedDomainReplicator serverToClientOffsets = { 1. 2. nil. 3. 5 } ]) ifFalse: [
            Error signal: 'Mapped migration-domain server-to-client offsets did not match VW instVarMap semantics.' ].
        (mappedDomainScheme shouldProxyNamedSlot: 1 ofClass: mappedDomainFixtureClass) ifFalse: [
          Error signal: 'Mapped migration-domain buyer slot was not marked as a forwarder.' ].
        (mappedDomainScheme shouldProxyNamedSlot: 3 ofClass: mappedDomainFixtureClass) ifTrue: [
          Error signal: 'Mapped migration-domain unmapped cache slot was unexpectedly marked as a forwarder.' ].
        domainFixtureCount := domainFixtureCount + 1.
        domainPerInstvarClampEntries := mappedDomainScheme serverClampInstVarLevelEntries size.

        phase := 'migration-domain-server-named-instvar-spec'.
        connector := connectorClass
          client: mappedDomainFixtureClass
          server: mappedDomainBehaviorName
          replicationSpec: #(
            #(#buyer #forwarder)
            #(#items #min 2)
            #(#amount #max 1)
            #(#audit #stub)
            #(#indexable_part #replicate))
          serverInstVarNames: mappedDomainFixtureClass migrationDomainServerInstVarNames.
        connector replicatorClass: pointerReplicatorClass.
        mappedDomainReplicator := manager installClientClassConnector: connector.
        mappedDomainScheme := manager currentReplicationScheme.
        (mappedDomainScheme instVarLevelsForClass: mappedDomainFixtureClass) = { false. -2. false. 1. 0. nil } ifFalse: [
          Error signal: 'Mapped migration-domain server-named per-instvar levels did not match VW instVarMap policy shape.' ].
        ((mappedDomainReplicator respondsTo: #serverToClientOffsets)
          and: [ mappedDomainReplicator serverToClientOffsets = { 1. 2. nil. 3. 5 } ]) ifFalse: [
            Error signal: 'Mapped migration-domain server-named spec changed server-to-client offsets unexpectedly.' ].
        (mappedDomainScheme shouldProxyNamedSlot: 1 ofClass: mappedDomainFixtureClass) ifFalse: [
          Error signal: 'Mapped migration-domain server-named buyer slot was not marked as a forwarder.' ].
        (mappedDomainScheme shouldProxyNamedSlot: 3 ofClass: mappedDomainFixtureClass) ifTrue: [
          Error signal: 'Mapped migration-domain server-named unmapped cache slot was unexpectedly marked as a forwarder.' ].
        domainFixtureCount := domainFixtureCount + 1.
        domainPerInstvarClampEntries := mappedDomainScheme serverClampInstVarLevelEntries size.

        phase := 'migration-domain-instvar-map-dirty-store'.
        mappedDomainOrderOop := session
          returnRemoteCommandBody: '| fixture tempDict orderClass customerClass order customer lines |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
orderClass := tempDict at: orderClassName asSymbol.
customerClass := tempDict at: customerClassName asSymbol.
customer := customerClass new.
customer
	instVarAt: 1 put: #customerB;
	instVarAt: 2 put: 3.
lines := OrderedCollection new.
lines add: 1; add: 2.
order := orderClass new.
order
	instVarAt: 1 put: customer;
	instVarAt: 2 put: lines;
	instVarAt: 3 put: Dictionary new;
	instVarAt: 4 put: 321;
	instVarAt: 5 put: #created.
fixture
	at: #mappedDomainCustomer put: customer;
	at: #mappedDomainOrder put: order.
order'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            at: 'orderClassName' put: mappedDomainBehaviorName;
            at: 'customerClassName' put: domainCustomerBehaviorName;
            yourself)
          oopBindings: Dictionary new.
        mappedDomainCustomerOop := session
          returnRemoteCommandBody: '(UserGlobals at: fixtureKey) at: #mappedDomainCustomer'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            yourself)
          oopBindings: Dictionary new.
        mappedDomainLineItemsOop := session
          returnRemoteCommandBody: '((UserGlobals at: fixtureKey) at: #mappedDomainOrder) instVarAt: 2'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            yourself)
          oopBindings: Dictionary new.
        session resetMaterializedObjectDirtyTracking.
        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        session fetchDeep.
        mappedDomainLineItems := session fetchObject: mappedDomainLineItemsOop.
        mappedDomainCustomerProxy := session
          proxyForOop: mappedDomainCustomerOop
          serverClassName: domainCustomerBehaviorName.
        mappedDomainOrder := mappedDomainFixtureClass basicNew.
        mappedDomainOrder
          instVarAt: 1 put: mappedDomainCustomerProxy;
          instVarAt: 2 put: mappedDomainLineItems;
          instVarAt: 3 put: 321;
          instVarAt: 4 put: nil;
          instVarAt: 5 put: #created.
        dirtyTrackerClass
          registerObject: mappedDomainOrder
          oop: mappedDomainOrderOop
          session: session.
        mappedDomainOrder gbsInstVarAt: 4 put: #clientOnlyCache.
        session dirtyMaterializedObjectOops isEmpty ifFalse: [
          Error signal: 'Mapped migration-domain client-only instVarMap slot was marked dirty.' ].
        mappedDomainOrder gbsInstVarAt: 3 put: 654.
        mappedDomainOrder gbsInstVarAt: 5 put: #mappedValidated.
        (session dirtyMaterializedObjectOops includes: mappedDomainOrderOop) ifFalse: [
          Error signal: 'Mapped migration-domain server-mapped slot did not mark the order dirty.' ].
        mappedDomainLineItems add: 4.
        dirtyTrackerClass
          markObject: mappedDomainLineItems
          dirtyInSession: session.
        mappedDomainDirtyObjectsFlushed := session dirtyMaterializedObjectOops size.
        mappedDomainDirtyObjectsFlushed < 2 ifTrue: [
          Error signal: 'Mapped migration-domain dirty-store fixture did not mark the order and line-items dirty.' ].
        mappedDomainDirtyStoreMs := millisecondsToRun value: [
          mappedDomainFlushed := session flushDirtyMaterializedObjects ].
        mappedDomainDirtyStoreReport := session dirtyStoreTraversalReport.
        domainDirtyStoreMs := domainDirtyStoreMs + mappedDomainDirtyStoreMs.
        domainFlushed := domainFlushed, mappedDomainFlushed.
        domainDirtyObjectsFlushed := domainDirtyObjectsFlushed + mappedDomainDirtyObjectsFlushed.
        domainNativeDirtyStoreFlushes := domainNativeDirtyStoreFlushes
          + (metricValue value: mappedDomainDirtyStoreReport value: #nativeFlushCount).
        domainNativeDirtyStoreEntries := domainNativeDirtyStoreEntries
          + (metricValue value: mappedDomainDirtyStoreReport value: #nativeEntryCount).
        mappedDomainVerifiedOop := session
          returnRemoteCommandBody: '| order status |
order := object.
status := 57.
(order class name asString = orderClassName) ifFalse: [ status := 58 ].
(status = 57 and: [ (order instVarAt: 1) class name asString = customerClassName ]) ifFalse: [
  status = 57 ifTrue: [ status := 59 ] ].
(status = 57 and: [ (order instVarAt: 2) asArray = #(1 2 4) ]) ifFalse: [
  status = 57 ifTrue: [ status := 60 ] ].
(status = 57 and: [ (order instVarAt: 3) isKindOf: Dictionary ]) ifFalse: [
  status = 57 ifTrue: [ status := 61 ] ].
(status = 57 and: [ (order instVarAt: 4) = 654 ]) ifFalse: [
  status = 57 ifTrue: [ status := 62 ] ].
(status = 57 and: [ (order instVarAt: 5) = #mappedValidated ]) ifFalse: [
  status = 57 ifTrue: [ status := 63 ] ].
status'
          literalBindings: (Dictionary new
            at: 'orderClassName' put: mappedDomainBehaviorName;
            at: 'customerClassName' put: domainCustomerBehaviorName;
            yourself)
          oopBindings: (Dictionary new
            at: 'object' put: mappedDomainOrderOop;
            yourself).
        mappedDomainVerified := session resultFor: mappedDomainVerifiedOop.
        mappedDomainVerified = 57 ifFalse: [
          Error signal: 'Mapped migration-domain dirty-store validation failed status=', mappedDomainVerified asString, ' oop=', mappedDomainVerifiedOop asString, ' (58=class 59=customer 60=items 61=unmapped 62=amount 63=audit).' ].

        phase := 'migration-domain-mapped-fault-stub-lifecycle'.
        domainFaultReleaseBefore := session objectSpace pendingNoLongerReplicatedOopCount.
        mappedDomainFaultProxy := session stubMaterializedObjectForOop: mappedDomainOrderOop.
        domainFaultReleaseQueued := session objectSpace pendingNoLongerReplicatedOopCount - domainFaultReleaseBefore.
        domainFaultReleaseQueued <= 0 ifTrue: [
          Error signal: 'Mapped migration-domain stubbing did not queue a no-longer-replicated release.' ].
        (session materializer materializedObjectForOop: mappedDomainOrderOop) isNil ifFalse: [
          Error signal: 'Mapped migration-domain stubbing did not clear materialized identity cache.' ].
        domainFaultIdentityCleared := 1.
        mappedDomainFaultRefetched := mappedDomainFaultProxy fault.
        domainFaultReleaseAfterFault := session objectSpace pendingNoLongerReplicatedOopCount - domainFaultReleaseBefore.
        domainFaultReleaseAfterFault = 0 ifFalse: [
          Error signal: 'Mapped migration-domain fault did not cancel the pending no-longer-replicated release.' ].
        mappedDomainFaultRefetched == mappedDomainOrder ifTrue: [
          Error signal: 'Mapped migration-domain fault reused the stubbed materialized object.' ].
        mappedDomainFaultRefetched class == mappedDomainFixtureClass ifFalse: [
          Error signal: 'Mapped migration-domain fault did not materialize the connector client class.' ].
        (((mappedDomainFaultRefetched instVarAt: 1) respondsTo: #oop) and: [
          (mappedDomainFaultRefetched instVarAt: 1) respondsTo: #session ]) ifFalse: [
          Error signal: 'Mapped migration-domain fault did not preserve the forwarder slot as a proxy.' ].
        (mappedDomainFaultRefetched instVarAt: 2) asArray = #(1 2 4) ifFalse: [
          Error signal: 'Mapped migration-domain fault did not materialize line items from the live server object.' ].
        (mappedDomainFaultRefetched instVarAt: 3) = 654 ifFalse: [
          Error signal: 'Mapped migration-domain fault did not restore the mapped amount slot.' ].
        (mappedDomainFaultRefetched instVarAt: 4) isNil ifFalse: [
          Error signal: 'Mapped migration-domain fault populated an unmapped client-only slot.' ].
        (mappedDomainFaultRefetched instVarAt: 5) = #mappedValidated ifFalse: [
          Error signal: 'Mapped migration-domain fault did not restore the mapped audit slot.' ].
        (session materializer materializedObjectForOop: mappedDomainOrderOop) == mappedDomainFaultRefetched ifFalse: [
          Error signal: 'Mapped migration-domain fault did not restore materialized identity cache.' ].
        domainFaultIdentityRestored := 1.
        (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
          at: #domainFaultLifecycleFixtures
          put: (metricValue
            value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
            value: #domainFaultLifecycleFixtures) + 1.
        domainFixtureCount := domainFixtureCount + 1.
        session resetMaterializedObjectDirtyTracking.

        phase := 'migration-domain-inherited-instvar-map-fixture'.
        inheritedMappedDomainBehaviorName := 'GbsMigrationLiveInheritedMappedOrder'.
        mappedDomainFixtureClass := Smalltalk
          at: #CoreGbsMigrationDomainInheritedMappedOrder
          ifAbsent: [ Error signal: 'Missing inherited mapped migration-domain order fixture class.' ].
        session
          fetchRemoteCommandBody: '| tempDict orderClass orderName |
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
tempDict ifNil: [
	tempDict := SymbolDictionary new name: #PharoSessionGlobals.
	System myUserProfile insertDictionary: tempDict at: 1 ].
orderName := orderClassName asSymbol.
tempDict removeKey: orderName ifAbsent: [ nil ].
orderClass := Object subclass: orderClassName
	instVarNames: #(''buyer'' ''items'' ''transientCache'' ''amount'' ''audit'' ''urgency'' ''serverAudit'')
	classVars: #()
	classInstVars: #()
	poolDictionaries: #()
	inDictionary: tempDict
	options: #().
tempDict at: orderName put: orderClass.
true'
          literalBindings: (Dictionary new
            at: 'orderClassName' put: inheritedMappedDomainBehaviorName;
            yourself)
          oopBindings: Dictionary new
          context: 20.
        connector := connectorClass
          client: mappedDomainFixtureClass
          server: inheritedMappedDomainBehaviorName
          replicationSpec: mappedDomainFixtureClass migrationDomainReplicationSpec
          serverInstVarNames: mappedDomainFixtureClass migrationDomainServerInstVarNames.
        connector replicatorClass: pointerReplicatorClass.
        mappedDomainReplicator := manager installClientClassConnector: connector.
        mappedDomainScheme := manager currentReplicationScheme.
        (mappedDomainScheme instVarLevelsForClass: mappedDomainFixtureClass) = { false. -2. false. 1. 0. -1. false. nil } ifFalse: [
          Error signal: 'Inherited mapped migration-domain per-instvar levels did not match VW instVarMap policy shape.' ].
        ((mappedDomainReplicator respondsTo: #serverToClientOffsets)
          and: [ mappedDomainReplicator serverToClientOffsets = { 1. 2. nil. 3. 5. 6. nil } ]) ifFalse: [
            Error signal: 'Inherited mapped migration-domain server-to-client offsets did not match VW instVarMap semantics.' ].
        (mappedDomainScheme shouldProxyNamedSlot: 1 ofClass: mappedDomainFixtureClass) ifFalse: [
          Error signal: 'Inherited mapped migration-domain buyer slot was not marked as a forwarder.' ].
        ((mappedDomainScheme shouldProxyNamedSlot: 3 ofClass: mappedDomainFixtureClass) or: [
          mappedDomainScheme shouldProxyNamedSlot: 7 ofClass: mappedDomainFixtureClass ]) ifTrue: [
          Error signal: 'Inherited mapped migration-domain unmapped slot was unexpectedly marked as a forwarder.' ].
        domainFixtureCount := domainFixtureCount + 1.
        domainPerInstvarClampEntries := mappedDomainScheme serverClampInstVarLevelEntries size.

        phase := 'migration-domain-inherited-instvar-map-dirty-store'.
        mappedDomainOrderOop := session
          returnRemoteCommandBody: '| fixture tempDict orderClass customerClass order customer lines |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
tempDict := System myUserProfile symbolList
	detect: [ :each |
		(each respondsTo: #name)
			and: [ each name = #PharoSessionGlobals ] ]
	ifNone: [ nil ].
orderClass := tempDict at: orderClassName asSymbol.
customerClass := tempDict at: customerClassName asSymbol.
customer := customerClass new.
customer
	instVarAt: 1 put: #customerC;
	instVarAt: 2 put: 4.
lines := OrderedCollection new.
lines add: 5; add: 6.
order := orderClass new.
order
	instVarAt: 1 put: customer;
	instVarAt: 2 put: lines;
	instVarAt: 3 put: Dictionary new;
	instVarAt: 4 put: 111;
	instVarAt: 5 put: #created;
	instVarAt: 6 put: 1;
	instVarAt: 7 put: #serverOnly.
fixture
	at: #inheritedMappedDomainCustomer put: customer;
	at: #inheritedMappedDomainOrder put: order.
order'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            at: 'orderClassName' put: inheritedMappedDomainBehaviorName;
            at: 'customerClassName' put: domainCustomerBehaviorName;
            yourself)
          oopBindings: Dictionary new.
        mappedDomainCustomerOop := session
          returnRemoteCommandBody: '(UserGlobals at: fixtureKey) at: #inheritedMappedDomainCustomer'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            yourself)
          oopBindings: Dictionary new.
        mappedDomainLineItemsOop := session
          returnRemoteCommandBody: '((UserGlobals at: fixtureKey) at: #inheritedMappedDomainOrder) instVarAt: 2'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            yourself)
          oopBindings: Dictionary new.
        session resetMaterializedObjectDirtyTracking.
        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        session fetchDeep.
        mappedDomainLineItems := session fetchObject: mappedDomainLineItemsOop.
        mappedDomainCustomerProxy := session
          proxyForOop: mappedDomainCustomerOop
          serverClassName: domainCustomerBehaviorName.
        mappedDomainOrder := mappedDomainFixtureClass basicNew.
        mappedDomainOrder
          instVarAt: 1 put: mappedDomainCustomerProxy;
          instVarAt: 2 put: mappedDomainLineItems;
          instVarAt: 3 put: 111;
          instVarAt: 4 put: nil;
          instVarAt: 5 put: #created;
          instVarAt: 6 put: 1;
          instVarAt: 7 put: nil.
        dirtyTrackerClass
          registerObject: mappedDomainOrder
          oop: mappedDomainOrderOop
          session: session.
        mappedDomainOrder gbsInstVarAt: 7 put: #clientMemo.
        session dirtyMaterializedObjectOops isEmpty ifFalse: [
          Error signal: 'Inherited mapped migration-domain client-only instVarMap slot was marked dirty.' ].
        mappedDomainOrder gbsInstVarAt: 3 put: 777.
        mappedDomainOrder gbsInstVarAt: 5 put: #inheritedValidated.
        mappedDomainOrder gbsInstVarAt: 6 put: 9.
        (session dirtyMaterializedObjectOops includes: mappedDomainOrderOop) ifFalse: [
          Error signal: 'Inherited mapped migration-domain server-mapped slot did not mark the order dirty.' ].
        mappedDomainLineItems add: 7.
        dirtyTrackerClass
          markObject: mappedDomainLineItems
          dirtyInSession: session.
        mappedDomainDirtyObjectsFlushed := session dirtyMaterializedObjectOops size.
        mappedDomainDirtyObjectsFlushed < 2 ifTrue: [
          Error signal: 'Inherited mapped migration-domain dirty-store fixture did not mark the order and line-items dirty.' ].
        mappedDomainDirtyStoreMs := millisecondsToRun value: [
          mappedDomainFlushed := session flushDirtyMaterializedObjects ].
        mappedDomainDirtyStoreReport := session dirtyStoreTraversalReport.
        domainDirtyStoreMs := domainDirtyStoreMs + mappedDomainDirtyStoreMs.
        domainFlushed := domainFlushed, mappedDomainFlushed.
        domainDirtyObjectsFlushed := domainDirtyObjectsFlushed + mappedDomainDirtyObjectsFlushed.
        domainNativeDirtyStoreFlushes := domainNativeDirtyStoreFlushes
          + (metricValue value: mappedDomainDirtyStoreReport value: #nativeFlushCount).
        domainNativeDirtyStoreEntries := domainNativeDirtyStoreEntries
          + (metricValue value: mappedDomainDirtyStoreReport value: #nativeEntryCount).
        mappedDomainVerifiedOop := session
          returnRemoteCommandBody: '| order status |
order := object.
status := 67.
(order class name asString = orderClassName) ifFalse: [ status := 68 ].
(status = 67 and: [ (order instVarAt: 1) class name asString = customerClassName ]) ifFalse: [
  status = 67 ifTrue: [ status := 69 ] ].
(status = 67 and: [ (order instVarAt: 2) asArray = #(5 6 7) ]) ifFalse: [
  status = 67 ifTrue: [ status := 70 ] ].
(status = 67 and: [ (order instVarAt: 3) isKindOf: Dictionary ]) ifFalse: [
  status = 67 ifTrue: [ status := 71 ] ].
(status = 67 and: [ (order instVarAt: 4) = 777 ]) ifFalse: [
  status = 67 ifTrue: [ status := 72 ] ].
(status = 67 and: [ (order instVarAt: 5) = #inheritedValidated ]) ifFalse: [
  status = 67 ifTrue: [ status := 73 ] ].
(status = 67 and: [ (order instVarAt: 6) = 9 ]) ifFalse: [
  status = 67 ifTrue: [ status := 74 ] ].
(status = 67 and: [ (order instVarAt: 7) = #serverOnly ]) ifFalse: [
  status = 67 ifTrue: [ status := 75 ] ].
status'
          literalBindings: (Dictionary new
            at: 'orderClassName' put: inheritedMappedDomainBehaviorName;
            at: 'customerClassName' put: domainCustomerBehaviorName;
            yourself)
          oopBindings: (Dictionary new
            at: 'object' put: mappedDomainOrderOop;
            yourself).
        mappedDomainVerified := session resultFor: mappedDomainVerifiedOop.
        mappedDomainVerified = 67 ifFalse: [
          Error signal: 'Inherited mapped migration-domain dirty-store validation failed status=', mappedDomainVerified asString, ' oop=', mappedDomainVerifiedOop asString, ' (68=class 69=customer 70=items 71=unmapped 72=amount 73=audit 74=urgency 75=serverAudit).' ].
        session resetMaterializedObjectDirtyTracking.

        phase := 'migration-domain-mapped-class-version-refresh'.
        mappedDomainReplicator serverInstVarNames: #('buyer' 'items' 'amount' 'audit' 'urgency' 'serverAudit').
        manager changedSelector: #classVersion inClass: mappedDomainFixtureClass.
        ((mappedDomainReplicator respondsTo: #serverToClientOffsets)
          and: [ mappedDomainReplicator serverToClientOffsets = { 1. 2. 3. 5. 6. nil } ]) ifFalse: [
            Error signal: 'Inherited mapped migration-domain class-version refresh did not update server-to-client offsets.' ].
        mappedDomainScheme := manager currentReplicationScheme.
        (mappedDomainScheme instVarLevelsForClass: mappedDomainFixtureClass) = { false. -2. 1. 0. -1. false. nil } ifFalse: [
          Error signal: 'Inherited mapped migration-domain class-version refresh did not update clamp levels.' ].
        connectorLifecycleReport := manager connectorLifecycleReport.
        (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
          at: #connectorClassVersionReportCount
          put: (connectorLifecycleReport at: #classVersionReportCount ifAbsent: [ 0 ]);
          at: #connectorClassVersionMismatchCount
          put: (connectorLifecycleReport at: #classVersionMismatchCount ifAbsent: [ 0 ]);
          at: #connectorClassVersionUnknownCount
          put: (connectorLifecycleReport at: #classVersionUnknownCount ifAbsent: [ 0 ]);
          at: #connectorClassVersionErrorCount
          put: (connectorLifecycleReport at: #classVersionErrorCount ifAbsent: [ 0 ]).
        (metricValue
          value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
          value: #connectorClassVersionReportCount) <= 0 ifTrue: [
          Error signal: 'Connector lifecycle report did not include class-version reports after class-version refresh.' ].
        (metricValue
          value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
          value: #connectorClassVersionErrorCount) = 0 ifFalse: [
          Error signal: 'Connector lifecycle report contained class-version errors after class-version refresh.' ].

        phase := 'dirty-store-fixture'.
        dirtyRootOop := session
          returnRemoteCommandBody: '| fixture root array association ordered dictionary set bag releaseNoLonger releaseGced |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
array := Array with: 1 with: 2 with: nil.
association := Association key: #status value: 2.
ordered := OrderedCollection new.
ordered add: 10; add: 20.
dictionary := Dictionary new.
dictionary at: #customer put: 3.
set := Set new.
set add: 11; add: 12.
bag := Bag new.
bag add: 13 withOccurrences: 2.
root := Array new: 6.
root
  at: 1 put: array;
  at: 2 put: association;
  at: 3 put: ordered;
  at: 4 put: dictionary;
  at: 5 put: set;
  at: 6 put: bag.
releaseNoLonger := Array with: 99.
releaseGced := Array with: 100.
fixture
  at: #dirtyRoot put: root;
  at: #releaseNoLonger put: releaseNoLonger;
  at: #releaseGced put: releaseGced.
root'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            yourself)
          oopBindings: Dictionary new.
        releaseNoLongerOop := session
          returnRemoteCommandBody: '(UserGlobals at: fixtureKey) at: #releaseNoLonger'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            yourself)
          oopBindings: Dictionary new.
        releaseGcedOop := session
          returnRemoteCommandBody: '(UserGlobals at: fixtureKey) at: #releaseGced'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            yourself)
          oopBindings: Dictionary new.
        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        session fetchDeep.
        dirtyRoot := session fetchObject: dirtyRootOop.
        releaseNoLongerObject := session fetchObject: releaseNoLongerOop.
        releaseGcedObject := session fetchObject: releaseGcedOop.
        releaseNoLongerObject ifNil: [ Error signal: 'No-longer-replicated release candidate did not materialize.' ].
        releaseGcedObject ifNil: [ Error signal: 'GCed release candidate did not materialize.' ].
        session objectSpace forgetObjectForOop: releaseNoLongerOop.
        lifecycleManagerClass
          forgetObjectForOop: releaseGcedOop
          inSession: session
          reason: #gced.
        exportBefore := session objectSpace pendingExportSetReleaseOopCount.
        exportBefore < 2 ifTrue: [
          Error signal: 'Export-set release queues were not populated before dirty-store flush.' ].

        phase := 'dirty-store-flush'.
        policy storeTraversalTransport: 'binaryRequired'.
        previousProfile ifNotNil: [ session fetchProfile: previousProfile ].
        (dirtyRoot at: 1) at: 2 put: 42.
        (dirtyRoot at: 2) value: 77.
        (dirtyRoot at: 3) add: 30.
        ((dirtyRoot at: 4)
          associationAt: #customer
          ifAbsent: [ Error signal: 'Dictionary association missing from dirty-store fixture.' ])
            value: 44.
        (dirtyRoot at: 5) add: 13.
        (dirtyRoot at: 6) add: 14.
        (Smalltalk at: #GbsMaterializedObjectDirtyTracker)
          markObject: (dirtyRoot at: 4)
          dirtyInSession: session.
        (Smalltalk at: #GbsMaterializedObjectDirtyTracker)
          markObject: (dirtyRoot at: 5)
          dirtyInSession: session.
        (Smalltalk at: #GbsMaterializedObjectDirtyTracker)
          markObject: (dirtyRoot at: 6)
          dirtyInSession: session.
        dirtyObjectsFlushed := session dirtyMaterializedObjectOops size.
        dirtyObjectsFlushed < 6 ifTrue: [
          Error signal: 'Expected at least six dirty materialized objects before flush.' ].
        dirtyStoreMs := millisecondsToRun value: [
          flushed := session flushDirtyMaterializedObjects ].
        dirtyStoreReport := session dirtyStoreTraversalReport.
        nativeDirtyStoreFlushes := metricValue value: dirtyStoreReport value: #nativeFlushCount.
        semanticDirtyStoreCommands := metricValue value: dirtyStoreReport value: #semanticCommandCount.
        semanticDirtyStoreEntries := metricValue value: dirtyStoreReport value: #semanticEntryCount.
        semanticDictionaryEntries := metricValue value: dirtyStoreReport value: #semanticDictionaryEntryCount.
        semanticSetEntries := metricValue value: dirtyStoreReport value: #semanticSetEntryCount.
        semanticBagEntries := metricValue value: dirtyStoreReport value: #semanticBagEntryCount.
        flushed size < 6 ifTrue: [
          Error signal: 'Dirty-store traversal flushed fewer objects than expected.' ].
        nativeDirtyStoreFlushes <= 0 ifTrue: [
          Error signal: 'Dirty-store traversal did not use the native store traversal buffer.' ].
        semanticDirtyStoreCommands = 0 ifFalse: [
          Error signal: 'Dirty-store traversal unexpectedly used semantic collection commands.' ].
        semanticDirtyStoreEntries = 0 ifFalse: [
          Error signal: 'Dirty-store traversal unexpectedly reported semantic collection entries.' ].
        ((semanticDictionaryEntries = 0)
          and: [ semanticSetEntries = 0
          and: [ semanticBagEntries = 0 ] ]) ifFalse: [
          Error signal: 'Dirty-store traversal unexpectedly fell back for Dictionary, Set, or Bag entries.' ].
        exportAfter := session objectSpace pendingExportSetReleaseOopCount.
        exportAfter = 0 ifFalse: [
          Error signal: 'Export-set release queues were not acknowledged after native dirty-store flush.' ].
        lifecycleReport := session objectSpace lifecycleReport.
        lifecycleNoLongerQueued := lifecycleReport at: #noLongerReplicatedOopsQueuedCount ifAbsent: [ 0 ].
        lifecycleGcedQueued := lifecycleReport at: #gcedOopsQueuedCount ifAbsent: [ 0 ].
        lifecycleNoLongerAcknowledged := lifecycleReport at: #noLongerReplicatedOopsAcknowledgedCount ifAbsent: [ 0 ].
        lifecycleGcedAcknowledged := lifecycleReport at: #gcedOopsAcknowledgedCount ifAbsent: [ 0 ].
        ((lifecycleNoLongerAcknowledged <= 0) or: [ lifecycleGcedAcknowledged <= 0 ]) ifTrue: [
          Error signal: 'Lifecycle report did not record export-set acknowledgement counters.' ].
        verifiedOop := session
          returnRemoteCommandBody: '| root status |
	root := object.
	status := 7.
	(((root at: 1) at: 2) = 42) ifFalse: [ status := 11 ].
	(status = 7 and: [ (root at: 2) value = 77 ]) ifFalse: [
	  status = 7 ifTrue: [ status := 12 ] ].
	(status = 7 and: [ (root at: 3) asArray = #(10 20 30) ]) ifFalse: [
	  status = 7 ifTrue: [ status := 13 ] ].
	(status = 7 and: [ ((root at: 4) at: #customer) = 44 ]) ifFalse: [
	  status = 7 ifTrue: [ status := 14 ] ].
	(status = 7 and: [ (root at: 5) includes: 13 ]) ifFalse: [
	  status = 7 ifTrue: [ status := 15 ] ].
	(status = 7 and: [ ((root at: 6) occurrencesOf: 14) = 1 ]) ifFalse: [
	  status = 7 ifTrue: [ status := 16 ] ].
	status'
          literalBindings: Dictionary new
	          oopBindings: (Dictionary new
	            at: 'object' put: dirtyRootOop;
	            yourself)
	          .
        verified := session resultFor: verifiedOop.
        verified = 7 ifFalse: [
          Error signal: 'Dirty-store traversal did not update the remote fixture status=', verified asString, ' oop=', verifiedOop asString, ' (11=array 12=association 13=ordered 14=dictionary 15=set 16=bag).' ].

        phase := 'business-dirty-store-fixture'.
        session resetMaterializedObjectDirtyTracking.
        businessRootOop := session
          returnRemoteCommandBody: '| fixture root |
fixture := UserGlobals at: fixtureKey ifAbsentPut: [ Dictionary new ].
root := Array new: 18.
1 to: 4 do: [ :index |
  root
    at: index
    put: (Array with: index with: index + 10 with: nil) ].
5 to: 8 do: [ :index |
  root
    at: index
    put: (Association key: index value: index + 20) ].
9 to: 12 do: [ :index |
  | ordered |
  ordered := OrderedCollection new.
  ordered add: index; add: index + 30.
  root at: index put: ordered ].
13 to: 14 do: [ :index |
  | dictionary |
  dictionary := Dictionary new.
  dictionary at: #business put: index + 40.
  root at: index put: dictionary ].
15 to: 16 do: [ :index |
  | set |
  set := Set new.
  set add: index + 50.
  root at: index put: set ].
17 to: 18 do: [ :index |
  | bag |
  bag := Bag new.
  bag add: index + 60 withOccurrences: 2.
  root at: index put: bag ].
fixture at: #businessDirtyRoot put: root.
root'
          literalBindings: (Dictionary new
            at: 'fixtureKey' put: fixtureKey;
            yourself)
          oopBindings: Dictionary new.
        [ session clearProxyCache. session clearRemoteClassNameCache ] on: Error do: [ ].
        session fetchDeep.
        businessRoot := session fetchObject: businessRootOop.
        businessFixtureSize := businessRoot size.
        businessFixtureSize = 18 ifFalse: [
          Error signal: 'Business dirty-store fixture did not materialize the expected root size.' ].

        phase := 'business-dirty-store-flush'.
        1 to: 4 do: [ :index |
          (businessRoot at: index)
            at: 3
            put: index + 100 ].
        5 to: 8 do: [ :index |
          (businessRoot at: index)
            value: index + 200 ].
        9 to: 12 do: [ :index |
          (businessRoot at: index)
            add: index + 300 ].
        13 to: 14 do: [ :index |
          (((businessRoot at: index)
            associationAt: #business
            ifAbsent: [ Error signal: 'Business dictionary association missing.' ])
              value: index + 400).
          dirtyTrackerClass
            markObject: (businessRoot at: index)
            dirtyInSession: session ].
        15 to: 16 do: [ :index |
          (businessRoot at: index)
            add: index + 500 ].
        17 to: 18 do: [ :index |
          (businessRoot at: index)
            add: index + 600 ].
        businessDirtyObjectsFlushed := session dirtyMaterializedObjectOops size.
        businessDirtyObjectsFlushed < businessFixtureSize ifTrue: [
          Error signal: 'Expected the business dirty-store fixture to mark all roots dirty before flush.' ].
        businessDirtyStoreMs := millisecondsToRun value: [
          businessFlushed := session flushDirtyMaterializedObjects ].
        businessFlushed size < businessFixtureSize ifTrue: [
          Error signal: 'Business dirty-store traversal flushed fewer objects than expected.' ].
        businessExportAfter := session objectSpace pendingExportSetReleaseOopCount.
        businessExportAfter = 0 ifFalse: [
          Error signal: 'Export-set release queues were not empty after business dirty-store flush.' ].
        businessVerifiedOop := session
          returnRemoteCommandBody: '| root status |
	root := object.
	status := 23.
	1 to: 4 do: [ :index |
	  (status = 23 and: [ ((root at: index) at: 3) = (index + 100) ]) ifFalse: [
	    status = 23 ifTrue: [ status := 31 ] ] ].
	5 to: 8 do: [ :index |
	  (status = 23 and: [ (root at: index) value = (index + 200) ]) ifFalse: [
	    status = 23 ifTrue: [ status := 32 ] ] ].
	9 to: 12 do: [ :index |
	  (status = 23 and: [ ((root at: index) asArray last) = (index + 300) ]) ifFalse: [
	    status = 23 ifTrue: [ status := 33 ] ] ].
	13 to: 14 do: [ :index |
	  (status = 23 and: [ ((root at: index) at: #business) = (index + 400) ]) ifFalse: [
	    status = 23 ifTrue: [ status := 34 ] ] ].
	15 to: 16 do: [ :index |
	  (status = 23 and: [ (root at: index) includes: index + 500 ]) ifFalse: [
	    status = 23 ifTrue: [ status := 35 ] ] ].
	17 to: 18 do: [ :index |
	  (status = 23 and: [ ((root at: index) occurrencesOf: index + 600) = 1 ]) ifFalse: [
	    status = 23 ifTrue: [ status := 36 ] ] ].
	status'
          literalBindings: Dictionary new
          oopBindings: (Dictionary new
            at: 'object' put: businessRootOop;
            yourself).
        businessVerified := session resultFor: businessVerifiedOop.
        businessVerified = 23 ifFalse: [
          Error signal: 'Business dirty-store traversal did not update the remote fixture status=', businessVerified asString, ' oop=', businessVerifiedOop asString, ' (31=array 32=association 33=ordered 34=dictionary 35=set 36=bag).' ].

        phase := 'migration-domain-mapped-lifecycle-abort'.
        session resetMaterializedObjectDirtyTracking.
        mappedDomainOrder := mappedDomainFixtureClass basicNew.
        mappedDomainOrder
          instVarAt: 1 put: mappedDomainCustomerProxy;
          instVarAt: 2 put: mappedDomainLineItems;
          instVarAt: 3 put: 777;
          instVarAt: 4 put: nil;
          instVarAt: 5 put: #inheritedValidated;
          instVarAt: 6 put: 9;
          instVarAt: 7 put: nil.
        session rememberMaterializedObject: mappedDomainOrder forOop: mappedDomainOrderOop.
        mappedDomainOrder gbsInstVarAt: 6 put: 10.
        (session dirtyMaterializedObjectOops includes: mappedDomainOrderOop) ifFalse: [
          Error signal: 'Mapped lifecycle fixture did not mark the refreshed mapped object dirty.' ].
        (session materializedObjectForOop: mappedDomainOrderOop) == mappedDomainOrder ifFalse: [
          Error signal: 'Mapped lifecycle fixture was not present in the materialized identity cache before abort.' ].
        session abortTransaction.
        session dirtyMaterializedObjectOops isEmpty ifFalse: [
          Error signal: 'Mapped lifecycle abort did not clear dirty materialized objects.' ].
        (session materializedObjectForOop: mappedDomainOrderOop) isNil ifFalse: [
          Error signal: 'Mapped lifecycle abort did not clear materialized identity cache.' ].
        (manager replicatorForClientBehavior: mappedDomainFixtureClass ifAbsent: [ nil ]) == mappedDomainReplicator ifFalse: [
          Error signal: 'Mapped lifecycle abort unexpectedly discarded the live mapped replicator.' ].
        (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
          at: #domainMappedLifecycleFixtures
          put: (metricValue
            value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
            value: #domainMappedLifecycleFixtures) + 1.

        phase := 'migration-domain-mapped-lifecycle-reconnect'.
        mappedDomainOrder := mappedDomainFixtureClass basicNew.
        session rememberMaterializedObject: mappedDomainOrder forOop: 11120.
        mappedDomainOrder gbsInstVarAt: 6 put: 12.
        (session dirtyMaterializedObjectOops includes: 11120) ifFalse: [
          Error signal: 'Mapped lifecycle reconnect fixture did not mark the mapped object dirty before logout.' ].
        (session materializedObjectForOop: 11120) == mappedDomainOrder ifFalse: [
          Error signal: 'Mapped lifecycle reconnect fixture was not present in the materialized identity cache before logout.' ].
        session logout.
        session dirtyMaterializedObjectOops isEmpty ifFalse: [
          Error signal: 'Mapped lifecycle logout did not clear dirty materialized objects.' ].
        (session materializedObjectForOop: 11120) isNil ifFalse: [
          Error signal: 'Mapped lifecycle logout did not clear materialized identity cache.' ].
        clampedResult := supportClass ensureSharedSession.
        (supportClass sessionIsUsable: clampedResult) ifFalse: [
          Error signal: 'Mapped lifecycle reconnect did not acquire a usable live session.' ].
        clampedResult == session ifTrue: [
          Error signal: 'Mapped lifecycle reconnect reused the logged-out live session object.' ].
        session := clampedResult.
        manager := session replicatorManager.
        (manager replicatorForClientBehavior: mappedDomainFixtureClass ifAbsent: [ nil ]) isNil ifFalse: [
          Error signal: 'Mapped lifecycle reconnect retained the stale mapped replicator in the new live session.' ].
        (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
          at: #domainMappedLifecycleFixtures
          put: (metricValue
            value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics)
            value: #domainMappedLifecycleFixtures) + 1.

        Transcript
          show: 'REPLICATION_LIVE_VALIDATION result=OK code=REPLICATION_LIVE_OK',
            ' connector_ms=', connectorMs asString,
            ' clamped_ms=', clampedMs asString,
            ' dirty_store_ms=', dirtyStoreMs asString,
            ' business_dirty_store_ms=', businessDirtyStoreMs asString,
            ' callback_clamp_specs=', callbackClampSpecs asString,
            ' per_instvar_clamp_entries=', perInstvarClampEntries asString,
            ' inherited_replication_spec_fixtures=', inheritedReplicationSpecFixtures asString,
            ' connector_pair_count=', connectorPairCount asString,
            ' domain_fixture_count=', domainFixtureCount asString,
            ' domain_per_instvar_clamp_entries=', domainPerInstvarClampEntries asString,
            ' domain_callback_clamp_specs=', domainCallbackClampSpecs asString,
            ' domain_callback_traversal_fixtures=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #domainCallbackTraversalFixtures) asString,
            ' domain_fault_lifecycle_fixtures=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #domainFaultLifecycleFixtures) asString,
            ' domain_mapped_lifecycle_fixtures=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #domainMappedLifecycleFixtures) asString,
            ' connector_class_version_reports=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #connectorClassVersionReportCount) asString,
            ' connector_class_version_mismatches=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #connectorClassVersionMismatchCount) asString,
            ' connector_class_version_unknowns=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #connectorClassVersionUnknownCount) asString,
            ' connector_class_version_errors=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #connectorClassVersionErrorCount) asString,
            ' materialization_traversal_transport_supported=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveNativeCapabilityMetrics ifAbsent: [ Dictionary new ]) value: #materializationTraversalTransportSupported) asString,
            ' materialization_report_shape_supported=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveNativeCapabilityMetrics ifAbsent: [ Dictionary new ]) value: #materializationReportShapeSupported) asString,
            ' materialization_oop_width=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveNativeCapabilityMetrics ifAbsent: [ Dictionary new ]) value: #materializationOopWidth) asString,
            ' domain_dirty_store_ms=', domainDirtyStoreMs asString,
            ' domain_dirty_objects_flushed=', domainFlushed size asString,
            ' domain_native_dirty_store_flushes=', domainNativeDirtyStoreFlushes asString,
            ' domain_native_dirty_store_entries=', domainNativeDirtyStoreEntries asString,
            ' domain_fault_release_queued=', domainFaultReleaseQueued asString,
            ' domain_fault_release_after_fault=', domainFaultReleaseAfterFault asString,
            ' domain_fault_identity_cleared=', domainFaultIdentityCleared asString,
            ' domain_fault_identity_restored=', domainFaultIdentityRestored asString,
            ' clamped_traversal_fetches=', clampedFetches asString,
            ' clamped_traversal_fallbacks=', clampedFallbacks asString,
            ' native_dirty_store_flushes=', nativeDirtyStoreFlushes asString,
            ' semantic_dirty_store_commands=', semanticDirtyStoreCommands asString,
            ' semantic_dirty_store_entries=', semanticDirtyStoreEntries asString,
            ' semantic_dictionary_entries=', semanticDictionaryEntries asString,
            ' semantic_set_entries=', semanticSetEntries asString,
            ' semantic_bag_entries=', semanticBagEntries asString,
            ' dirty_objects_flushed=', flushed size asString,
            ' business_dirty_objects_flushed=', businessFlushed size asString,
            ' business_write_fixture_size=', businessFixtureSize asString,
            ' export_set_queued_before=', exportBefore asString,
            ' export_set_queued_after=', exportAfter asString,
            ' lifecycle_no_longer_queued=', lifecycleNoLongerQueued asString,
            ' lifecycle_gced_queued=', lifecycleGcedQueued asString,
            ' lifecycle_no_longer_acknowledged=', lifecycleNoLongerAcknowledged asString,
            ' lifecycle_gced_acknowledged=', lifecycleGcedAcknowledged asString,
            ' business_export_set_queued_after=', businessExportAfter asString,
            ' clamp_spec_oop=', clampSpecOop asString;
          cr ]
        ensure: [
          policy ifNotNil: [ policy storeTraversalTransport: previousTransport ].
          previousProfile ifNotNil: [ session fetchProfile: previousProfile ].
          [ session resetMaterializedObjectDirtyTracking ] on: Error do: [ ].
          cleanupFixture value.
          [ session abortTransaction ] on: Error do: [ ].
          [ supportClass releaseOwnedSession ] on: Error do: [ ] ] ]
    on: Error do: [ :ex |
      Transcript
        show: 'REPLICATION_LIVE_VALIDATION result=FAIL code=REPLICATION_LIVE_RUN_FAILED',
          ' connector_ms=', (connectorMs ifNil: [ 0 ]) asString,
          ' clamped_ms=', (clampedMs ifNil: [ 0 ]) asString,
          ' dirty_store_ms=', (dirtyStoreMs ifNil: [ 0 ]) asString,
          ' business_dirty_store_ms=', (businessDirtyStoreMs ifNil: [ 0 ]) asString,
          ' callback_clamp_specs=', (callbackClampSpecs ifNil: [ 0 ]) asString,
          ' per_instvar_clamp_entries=', (perInstvarClampEntries ifNil: [ 0 ]) asString,
          ' inherited_replication_spec_fixtures=', (inheritedReplicationSpecFixtures ifNil: [ 0 ]) asString,
          ' connector_pair_count=', (connectorPairCount ifNil: [ 0 ]) asString,
          ' domain_fixture_count=', (domainFixtureCount ifNil: [ 0 ]) asString,
          ' domain_per_instvar_clamp_entries=', (domainPerInstvarClampEntries ifNil: [ 0 ]) asString,
          ' domain_callback_clamp_specs=', (domainCallbackClampSpecs ifNil: [ 0 ]) asString,
          ' domain_callback_traversal_fixtures=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #domainCallbackTraversalFixtures) asString,
          ' domain_fault_lifecycle_fixtures=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #domainFaultLifecycleFixtures) asString,
          ' domain_mapped_lifecycle_fixtures=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #domainMappedLifecycleFixtures) asString,
          ' connector_class_version_reports=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #connectorClassVersionReportCount) asString,
          ' connector_class_version_mismatches=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #connectorClassVersionMismatchCount) asString,
          ' connector_class_version_unknowns=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #connectorClassVersionUnknownCount) asString,
          ' connector_class_version_errors=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveStrictParityMetrics ifAbsent: [ Dictionary new ]) value: #connectorClassVersionErrorCount) asString,
          ' materialization_traversal_transport_supported=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveNativeCapabilityMetrics ifAbsent: [ Dictionary new ]) value: #materializationTraversalTransportSupported) asString,
          ' materialization_report_shape_supported=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveNativeCapabilityMetrics ifAbsent: [ Dictionary new ]) value: #materializationReportShapeSupported) asString,
          ' materialization_oop_width=', (metricValue value: (Smalltalk globals at: #GbsReplicationLiveNativeCapabilityMetrics ifAbsent: [ Dictionary new ]) value: #materializationOopWidth) asString,
          ' domain_dirty_store_ms=', (domainDirtyStoreMs ifNil: [ 0 ]) asString,
          ' domain_dirty_objects_flushed=', (domainDirtyObjectsFlushed ifNil: [ 0 ]) asString,
          ' domain_native_dirty_store_flushes=', (domainNativeDirtyStoreFlushes ifNil: [ 0 ]) asString,
          ' domain_native_dirty_store_entries=', (domainNativeDirtyStoreEntries ifNil: [ 0 ]) asString,
          ' domain_fault_release_queued=', (domainFaultReleaseQueued ifNil: [ 0 ]) asString,
          ' domain_fault_release_after_fault=', (domainFaultReleaseAfterFault ifNil: [ 0 ]) asString,
          ' domain_fault_identity_cleared=', (domainFaultIdentityCleared ifNil: [ 0 ]) asString,
          ' domain_fault_identity_restored=', (domainFaultIdentityRestored ifNil: [ 0 ]) asString,
          ' clamped_traversal_fetches=', (clampedFetches ifNil: [ 0 ]) asString,
          ' clamped_traversal_fallbacks=', (clampedFallbacks ifNil: [ 0 ]) asString,
          ' native_dirty_store_flushes=', (nativeDirtyStoreFlushes ifNil: [ 0 ]) asString,
          ' semantic_dirty_store_commands=', (semanticDirtyStoreCommands ifNil: [ 0 ]) asString,
          ' semantic_dirty_store_entries=', (semanticDirtyStoreEntries ifNil: [ 0 ]) asString,
          ' semantic_dictionary_entries=', (semanticDictionaryEntries ifNil: [ 0 ]) asString,
          ' semantic_set_entries=', (semanticSetEntries ifNil: [ 0 ]) asString,
          ' semantic_bag_entries=', (semanticBagEntries ifNil: [ 0 ]) asString,
          ' dirty_objects_flushed=', (dirtyObjectsFlushed ifNil: [ 0 ]) asString,
          ' business_dirty_objects_flushed=', (businessDirtyObjectsFlushed ifNil: [ 0 ]) asString,
          ' business_write_fixture_size=', (businessFixtureSize ifNil: [ 0 ]) asString,
          ' export_set_queued_before=', (exportBefore ifNil: [ 0 ]) asString,
          ' export_set_queued_after=', (exportAfter ifNil: [ 0 ]) asString,
          ' lifecycle_no_longer_queued=', (lifecycleNoLongerQueued ifNil: [ 0 ]) asString,
          ' lifecycle_gced_queued=', (lifecycleGcedQueued ifNil: [ 0 ]) asString,
          ' lifecycle_no_longer_acknowledged=', (lifecycleNoLongerAcknowledged ifNil: [ 0 ]) asString,
          ' lifecycle_gced_acknowledged=', (lifecycleGcedAcknowledged ifNil: [ 0 ]) asString,
          ' business_export_set_queued_after=', (businessExportAfter ifNil: [ 0 ]) asString,
          ' message=';
        show: (ex messageText ifNil: [ ex printString ]) asString withBlanksTrimmed;
        show: ' phase=';
        show: (phase ifNil: [ 'unknown' ]);
        cr ] ].
] ensure: [ Smalltalk snapshot: false andQuit: true ].
