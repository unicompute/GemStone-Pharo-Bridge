| loadFailed supportClass connectorClass clampSyncClass replicationPolicyClass lifecycleManagerClass session millisecondsToRun metricValue phase fixtureKey cleanupFixture manager connector replicator connectorReport connectorPairCount scheme clampSpecOop transitiveSpec connectorMs clampedOop clampedResult clampedMs clampedMetrics callbackSelector callbackBehaviorName callbackScheme callbackClampSpecOop callbackVerifiedOop callbackVerified perInstvarClampEntries callbackClampSpecs inheritedFixtureClass pointerReplicatorClass inheritedConnector inheritedReplicator inheritedScheme inheritedLevels inheritedReplicationSpecFixtures policy previousTransport previousProfile nativeStoreSupported dirtyRootOop dirtyRoot releaseNoLongerOop releaseGcedOop releaseGcedObject releaseNoLongerObject exportBefore exportAfter lifecycleReport lifecycleNoLongerQueued lifecycleGcedQueued lifecycleNoLongerAcknowledged lifecycleGcedAcknowledged dirtyStoreMs flushed dirtyStoreReport semanticDirtyStoreCommands semanticDirtyStoreEntries semanticDictionaryEntries semanticSetEntries semanticBagEntries verified verifiedOop nativeDirtyStoreFlushes clampedFetches clampedFallbacks dirtyObjectsFlushed businessRootOop businessRoot businessFixtureSize businessDirtyObjectsFlushed businessDirtyStoreMs businessFlushed businessExportAfter businessVerifiedOop businessVerified |
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
      session := supportClass ensureSharedSession.
      (supportClass sessionIsUsable: session) ifFalse: [
        Error signal: supportClass unavailableReason ].
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

        phase := 'connector-install'.
        manager := session replicatorManager.
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
        connectorReport := manager connectorManagerReport.
        connectorPairCount := connectorReport at: #connectorPairCount ifAbsent: [ 0 ].
        connectorPairCount <= 0 ifTrue: [
          Error signal: 'Replicator manager report did not expose the installed connector pair.' ].
        scheme := manager currentReplicationScheme.
        scheme hasServerClampMetadata ifFalse: [
          Error signal: 'Installed connector did not update clamp metadata.' ].
        transitiveSpec := scheme transitiveClosureSpecForReplicationSpec: connector replicationSpec.
        transitiveSpec = #(
          #(#key #replicate)
          #(#value #replicate))
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
        inheritedScheme := manager replicationSchemeForSet: #customerReplicationSpec.
        inheritedLevels := inheritedScheme instVarLevelsForClass: inheritedFixtureClass.
        inheritedLevels = { 0. false. nil } ifFalse: [
          Error signal: 'Inherited VisualWorks replication spec did not hydrate expected per-instvar levels.' ].
        inheritedReplicationSpecFixtures := 1.

        phase := 'dirty-store-fixture'.
        nativeStoreSupported := session serverInterface supportsDirtyStoreTraversalBufferTransport == true.
        nativeStoreSupported ifFalse: [
          Error signal: 'GemStone server interface does not expose native dirty-store traversal buffer transport.' ].
        policy := replicationPolicyClass forSession: session.
        previousTransport := policy storeTraversalTransport.
        previousProfile := session fetchProfile.
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
        semanticDirtyStoreCommands <= 0 ifTrue: [
          Error signal: 'Dirty-store traversal did not use the semantic collection command path.' ].
        semanticDirtyStoreEntries < 3 ifTrue: [
          Error signal: 'Dirty-store traversal did not report all semantic Dictionary/Set/Bag entries.' ].
        ((semanticDictionaryEntries <= 0) or: [
          (semanticSetEntries <= 0) or: [ semanticBagEntries <= 0 ] ]) ifTrue: [
          Error signal: 'Dirty-store traversal did not exercise dictionary, set, and bag semantic entries.' ].
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
root := Array new: 12.
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
        businessFixtureSize = 12 ifFalse: [
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
	status'
          literalBindings: Dictionary new
          oopBindings: (Dictionary new
            at: 'object' put: businessRootOop;
            yourself).
        businessVerified := session resultFor: businessVerifiedOop.
        businessVerified = 23 ifFalse: [
          Error signal: 'Business dirty-store traversal did not update the remote fixture status=', businessVerified asString, ' oop=', businessVerifiedOop asString, ' (31=array 32=association 33=ordered).' ].

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
