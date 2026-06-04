Class {
	#name : 'GbsSessionLifecycleManager',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> drainFreeOopsForSession: aSession limit: anInteger [
	^ self drainGcedOopsForSession: aSession limit: anInteger
]

{ #category : 'export set' }
GbsSessionLifecycleManager class >> acknowledgeNoLongerReplicatedOops: oopCollection forSession: aSession [
	| acknowledged |
	acknowledged := self
		acknowledgeOops: oopCollection
		inQueue: (self noLongerReplicatedOopQueueForSession: aSession)
		label: 'No-longer-replicated'.
	self
		incrementLifecycleCounter: #noLongerReplicatedOopsAcknowledgedCount
		by: acknowledged size
		forSession: aSession.
	^ acknowledged
]

{ #category : 'export set' }
GbsSessionLifecycleManager class >> cancelNoLongerReplicatedOop: anOop forSession: aSession [
	| removed |
	removed := self removeOop: anOop fromQueue: (self noLongerReplicatedOopQueueForSession: aSession).
	removed ifTrue: [
		self incrementLifecycleCounter: #noLongerReplicatedOopsCancelledCount forSession: aSession ].
	^ removed
]

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> acknowledgeGcedOops: oopCollection forSession: aSession [
	| acknowledged |
	acknowledged := self
		acknowledgeOops: oopCollection
		inQueue: (self gcedOopQueueForSession: aSession)
		label: 'GCed'.
	self
		incrementLifecycleCounter: #gcedOopsAcknowledgedCount
		by: acknowledged size
		forSession: aSession.
	^ acknowledged
]

{ #category : 'export set' }
GbsSessionLifecycleManager class >> drainExportSetReleaseOopsForSession: aSession limit: anInteger [
	self incrementLifecycleCounter: #exportSetDrainCallCount forSession: aSession.
	^ Dictionary new
		at: #noLongerReplicated put: (self drainNoLongerReplicatedOopsForSession: aSession limit: anInteger);
		at: #gced put: (self drainGcedOopsForSession: aSession limit: anInteger);
		yourself
]

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> drainGcedOopsForSession: aSession limit: anInteger [
	| queue drained |
	queue := self gcedOopQueueForSession: aSession.
	drained := self
		pendingOopsInQueue: queue
		limit: (self normalizedDrainLimit: anInteger forSession: aSession).
	self removeFirst: drained size fromQueue: queue.
	self
		incrementLifecycleCounter: #gcedOopsDrainedCount
		by: drained size
		forSession: aSession.
	^ drained
]

{ #category : 'export set' }
GbsSessionLifecycleManager class >> drainNoLongerReplicatedOopsForSession: aSession limit: anInteger [
	| queue drained |
	queue := self noLongerReplicatedOopQueueForSession: aSession.
	drained := self
		pendingOopsInQueue: queue
		limit: (self normalizedDrainLimit: anInteger forSession: aSession).
	self removeFirst: drained size fromQueue: queue.
	self
		incrementLifecycleCounter: #noLongerReplicatedOopsDrainedCount
		by: drained size
		forSession: aSession.
	^ drained
]

{ #category : 'export set' }
GbsSessionLifecycleManager class >> flushExportSetReleaseOopsForSession: aSession limit: anInteger [
	| released pendingNoLonger |
	self incrementLifecycleCounter: #exportSetFlushCallCount forSession: aSession.
	released := self flushGcedOopsForSession: aSession limit: anInteger.
	pendingNoLonger := self pendingNoLongerReplicatedOopsForSession: aSession limit: anInteger.
	self
		lifecycleCounterAt: #lastExportSetGcedReleasedCount
		put: released size
		forSession: aSession.
	self
		lifecycleCounterAt: #lastExportSetNoLongerPendingCount
		put: pendingNoLonger size
		forSession: aSession.
	self
		lifecycleCounterAt: #lastExportSetGcedQueueSize
		put: (self pendingGcedOopCountForSession: aSession)
		forSession: aSession.
	self
		lifecycleCounterAt: #lastExportSetNoLongerQueueSize
		put: (self pendingNoLongerReplicatedOopCountForSession: aSession)
		forSession: aSession.
	^ Dictionary new
		at: #gcedReleased put: released;
		at: #noLongerReplicatedPending put: pendingNoLonger;
		at: #gcedOopQueueSize put: (self pendingGcedOopCountForSession: aSession);
		at: #noLongerReplicatedOopQueueSize put: (self pendingNoLongerReplicatedOopCountForSession: aSession);
		yourself
]

{ #category : 'export set' }
GbsSessionLifecycleManager class >> flushAllExportSetReleaseOopsForSession: aSession limit: anInteger [
	| releaseBatch noLongerReplicated gced allOops |
	self incrementLifecycleCounter: #exportSetFlushAllCallCount forSession: aSession.
	releaseBatch := self pendingExportSetReleaseOopsForSession: aSession limit: anInteger.
	noLongerReplicated := releaseBatch at: #noLongerReplicated ifAbsent: [ #() ].
	gced := releaseBatch at: #gced ifAbsent: [ #() ].
	allOops := noLongerReplicated asArray, gced asArray.
	allOops isEmpty ifFalse: [
		self releaseOops: allOops forSession: aSession.
		self acknowledgeNoLongerReplicatedOops: noLongerReplicated forSession: aSession.
		self acknowledgeGcedOops: gced forSession: aSession ].
	self
		lifecycleCounterAt: #lastExportSetAllReleasedCount
		put: allOops size
		forSession: aSession.
	self
		lifecycleCounterAt: #lastExportSetNoLongerReleasedCount
		put: noLongerReplicated size
		forSession: aSession.
	self
		lifecycleCounterAt: #lastExportSetGcedReleasedCount
		put: gced size
		forSession: aSession.
	self
		lifecycleCounterAt: #lastExportSetGcedQueueSize
		put: (self pendingGcedOopCountForSession: aSession)
		forSession: aSession.
	self
		lifecycleCounterAt: #lastExportSetNoLongerQueueSize
		put: (self pendingNoLongerReplicatedOopCountForSession: aSession)
		forSession: aSession.
	^ Dictionary new
		at: #noLongerReplicatedReleased put: noLongerReplicated;
		at: #gcedReleased put: gced;
		at: #releasedOops put: allOops;
		at: #gcedOopQueueSize put: (self pendingGcedOopCountForSession: aSession);
		at: #noLongerReplicatedOopQueueSize put: (self pendingNoLongerReplicatedOopCountForSession: aSession);
		yourself
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> exportSetReleaseFlushReportTextFor: aDictionary [
	| gcedReleased noLongerReplicatedPending |
	gcedReleased := aDictionary at: #gcedReleased ifAbsent: [ #() ].
	noLongerReplicatedPending := aDictionary at: #noLongerReplicatedPending ifAbsent: [ #() ].
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Export Set Release Flush';
			cr;
			cr.
		stream
			nextPutAll: 'gcedReleased=';
			nextPutAll: gcedReleased size printString;
			cr.
		stream
			nextPutAll: 'gcedReleasedOops=';
			nextPutAll: (self oopCollectionString: gcedReleased);
			cr.
		stream
			nextPutAll: 'noLongerReplicatedPending=';
			nextPutAll: noLongerReplicatedPending size printString;
			cr.
		stream
			nextPutAll: 'noLongerReplicatedPendingOops=';
			nextPutAll: (self oopCollectionString: noLongerReplicatedPending);
			cr.
		self writeReportKey: #gcedOopQueueSize from: aDictionary on: stream.
		self writeReportKey: #noLongerReplicatedOopQueueSize from: aDictionary on: stream ]
]

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> flushGcedOopsForSession: aSession limit: anInteger [
	| queue released |
	self incrementLifecycleCounter: #gcedFlushCallCount forSession: aSession.
	queue := self gcedOopQueueForSession: aSession.
	released := self
		pendingOopsInQueue: queue
		limit: (self normalizedDrainLimit: anInteger forSession: aSession).
	released isEmpty ifTrue: [ ^ released ].
	self releaseOops: released forSession: aSession.
	self removeFirst: released size fromQueue: queue.
	^ released
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> forgetObject: anObject inSession: aSession [
	^ self
		forgetObject: anObject
		inSession: aSession
		reason: #noLongerReplicated
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> forgetObject: anObject inSession: aSession reason: reasonSymbol [
	| oop |
	oop := GbsMaterializedObjectDirtyTracker
		oopForObject: anObject
		inSession: aSession.
	oop ifNil: [ ^ nil ].
	^ self
		forgetObjectForOop: oop
		inSession: aSession
		reason: reasonSymbol
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> forgetObjectForOop: anOop inSession: aSession [
	^ self
		forgetObjectForOop: anOop
		inSession: aSession
		reason: #noLongerReplicated
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> forgetObjectForOop: anOop inSession: aSession reason: reasonSymbol [
	| map object |
	self incrementLifecycleCounter: #forgetRequestedOopCount forSession: aSession.
	self recordServerMapTombstoneOop: anOop reason: reasonSymbol forSession: aSession.
	map := self serverMapForSession: aSession.
	object := map at: anOop ifAbsent: [ nil ].
	map removeKey: anOop ifAbsent: [ ].
	self forgetMaterializedObjectForOop: anOop inSession: aSession.
	object ifNotNil: [
		self incrementLifecycleCounter: #forgottenMaterializedObjectCount forSession: aSession.
		self unregisterFinalizerForObject: object session: aSession.
		GbsMaterializedObjectDirtyTracker
			unregisterObject: object
			inSession: aSession ].
	reasonSymbol = #gced
		ifTrue: [
			self incrementLifecycleCounter: #gcedForgetRequestedOopCount forSession: aSession.
			self noteGcedOop: anOop forSession: aSession ]
		ifFalse: [
			self incrementLifecycleCounter: #noLongerReplicatedForgetRequestedOopCount forSession: aSession.
			self noteNoLongerReplicatedOop: anOop forSession: aSession ].
	^ object
]

{ #category : 'faulting' }
GbsSessionLifecycleManager class >> faultObjectForOop: anOop inSession: aSession [
	| oldObject refreshedObject |
	(self faultingAllowedForSession: aSession) ifFalse: [
		GbsError signal: 'Faulting is disabled by the session replication policy.' ].
	oldObject := self objectForOop: anOop inSession: aSession.
	self invokePreFaultHookFor: oldObject inSession: aSession.
	self forgetMaterializedObjectForOop: anOop inSession: aSession.
	refreshedObject := aSession fetchObject: anOop.
	self incrementLifecycleCounter: #faultedObjectCount forSession: aSession.
	self invokePostFaultHookFor: refreshedObject inSession: aSession.
	^ refreshedObject
]

{ #category : 'faulting' }
GbsSessionLifecycleManager class >> faultProxy: aProxy inSession: aSession [
	(aProxy respondsTo: #session) ifFalse: [
		GbsError signal: 'Cannot fault an object without a GemStone session.' ].
	aProxy session == aSession ifFalse: [
		GbsError signal: 'Cannot fault a proxy from a different GemStone session.' ].
	^ self faultObjectForOop: aProxy oop inSession: aSession
]

{ #category : 'faulting' }
GbsSessionLifecycleManager class >> faultingAllowedForSession: aSession [
	| policy |
	policy := [ GbsReplicationPolicy forSession: aSession ] on: Error do: [ nil ].
	policy ifNil: [ ^ true ].
	(policy respondsTo: #defaultFaultPolicySymbol) ifFalse: [ ^ true ].
	^ policy defaultFaultPolicySymbol ~= #none
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> forgetMaterializedObjectForOop: anOop inSession: aSession [
	| materializer |
	materializer := [ aSession materializer ] on: Error do: [ nil ].
	(materializer notNil and: [ materializer respondsTo: #forgetMaterializedObjectForOop: ])
		ifTrue: [ materializer forgetMaterializedObjectForOop: anOop ].
	^ anOop
]

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> freeOopDrainLimitForSession: aSession [
	| policy |
	policy := [ GbsReplicationPolicy forSession: aSession ] on: Error do: [ nil ].
	(policy notNil and: [ policy respondsTo: #freeOopBatchSize ]) ifTrue: [
		^ policy freeOopBatchSize max: 0 ].
	^ 256
]

{ #category : 'stubbing' }
GbsSessionLifecycleManager class >> freeSlotsOf: anObject inSession: aSession [
	(aSession notNil and: [ aSession respondsTo: #withDirtyTrackingSuspendedDo: ])
		ifTrue: [
			^ aSession withDirtyTrackingSuspendedDo: [
				self freeSlotsOfObject: anObject ] ].
	^ self freeSlotsOfObject: anObject
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> freeSlotsOfObject: anObject [
	anObject ifNil: [ ^ anObject ].
	(anObject isKindOf: Association) ifTrue: [
		anObject key: nil value: nil.
		^ anObject ].
	(anObject isKindOf: Array) ifTrue: [
		1 to: anObject size do: [ :index |
			anObject basicAt: index put: nil ].
		^ anObject ].
	((anObject isKindOf: Dictionary)
		or: [ (anObject isKindOf: Set)
		or: [ (anObject isKindOf: Bag)
		or: [ anObject isKindOf: OrderedCollection ] ] ]) ifTrue: [
			anObject removeAll.
			^ anObject ].
	(anObject class respondsTo: #allInstVarNames) ifTrue: [
		1 to: anObject class allInstVarNames size do: [ :index |
			anObject instVarAt: index put: nil ] ].
	^ anObject
]

{ #category : 'registries' }
GbsSessionLifecycleManager class >> activeFinalizerTokensForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionLifecycleFinalizerTokens)
		at: aSession
		ifAbsentPut: [ IdentitySet new ]
]

{ #category : 'registries' }
GbsSessionLifecycleManager class >> activeFinalizerTokensForSessionIfPresent: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionLifecycleFinalizerTokens)
		at: aSession
		ifAbsent: [ nil ]
]

{ #category : 'registries' }
GbsSessionLifecycleManager class >> freeOopQueueForSession: aSession [
	^ self gcedOopQueueForSession: aSession
]

{ #category : 'registries' }
GbsSessionLifecycleManager class >> finalizedObjectOopRegistryForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionFinalizedObjectOopRegistries)
		at: aSession
		ifAbsentPut: [ self newIdentityRegistry ]
]

{ #category : 'registries' }
GbsSessionLifecycleManager class >> finalizedObjectOopRegistryForSessionIfPresent: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionFinalizedObjectOopRegistries)
		at: aSession
		ifAbsent: [ nil ]
]

{ #category : 'registries' }
GbsSessionLifecycleManager class >> gcedOopQueueForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionGcedOopQueues)
		at: aSession
		ifAbsentPut: [ OrderedCollection new ]
]

{ #category : 'testing' }
GbsSessionLifecycleManager class >> isExportableOop: anOop [
	anOop ifNil: [ ^ false ].
	anOop = 20 ifTrue: [ ^ false ].
	(anOop = 28 or: [ anOop = 268 ]) ifTrue: [ ^ false ].
	(anOop = 12 or: [ anOop = 140 ]) ifTrue: [ ^ false ].
	((anOop bitAnd: 7) = 2 or: [ (anOop bitAnd: 7) = 6 ]) ifTrue: [ ^ false ].
	^ true
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> lifecycleReportForSession: aSession [
	| report |
	report := Dictionary new
		at: #serverMapSize put: (self serverMapSizeForSession: aSession);
		at: #serverMapTombstoneCount put: (self serverMapTombstonesForSession: aSession) size;
		at: #packedButNotAcceptedCount put: (self packedButNotAcceptedOopsForSession: aSession) size;
		at: #serverMapMode put: (self serverMapModeForSession: aSession);
		at: #gcedOopQueueSize put: (self pendingGcedOopCountForSession: aSession);
		at: #noLongerReplicatedOopQueueSize put: (self pendingNoLongerReplicatedOopCountForSession: aSession);
		at: #exportSetReleaseOopQueueSize put: (self pendingExportSetReleaseOopCountForSession: aSession);
		at: #freeOopDrainLimit put: (self freeOopDrainLimitForSession: aSession);
		at: #releaseOopsTransportAvailable put: (self releaseOopsTransportAvailableForSession: aSession);
		at: #noLongerReplicatedStoreTraversalTransportAvailable put: (self noLongerReplicatedStoreTraversalTransportAvailableForSession: aSession);
		yourself.
	(self lifecycleCountersForSession: aSession) keysAndValuesDo: [ :key :value |
		report at: key put: value ].
	^ report
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> lifecycleReportTextForSession: aSession [
	| report |
	report := self lifecycleReportForSession: aSession.
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Session Lifecycle';
			cr;
			cr.
		#(
			serverMapMode
			serverMapSize
			serverMapTombstoneCount
			packedButNotAcceptedCount
			gcedOopQueueSize
			noLongerReplicatedOopQueueSize
			exportSetReleaseOopQueueSize
			freeOopDrainLimit
			releaseOopsTransportAvailable
			noLongerReplicatedStoreTraversalTransportAvailable) do: [ :key |
				self writeReportKey: key from: report on: stream ].
		stream cr.
		stream nextPutAll: 'Lifecycle Counters'; cr.
		self lifecycleReportCounterKeys do: [ :key |
			self writeReportKey: key from: report on: stream ] ]
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> lifecycleReportCounterKeys [
	^ #(
		rememberedOopCount
		remappedOopCount
		forgetRequestedOopCount
		forgottenMaterializedObjectCount
		noLongerReplicatedForgetRequestedOopCount
		gcedForgetRequestedOopCount
		noLongerReplicatedOopsQueuedCount
		gcedOopsQueuedCount
		noLongerReplicatedOopsCancelledCount
		noLongerReplicatedOopsAcknowledgedCount
		gcedOopsAcknowledgedCount
		noLongerReplicatedOopsDrainedCount
		gcedOopsDrainedCount
		exportSetDrainCallCount
		exportSetFlushCallCount
		exportSetFlushAllCallCount
		gcedFlushCallCount
		releaseOopsCallCount
		releaseOopsReleasedCount
		releaseOopsFailureCount
		finalizerRegisteredCount
		finalizerDeactivatedCount
		finalizerUnregisteredCount
		finalizedObjectNotificationCount
		ignoredFinalizerNotificationCount
		faultedObjectCount
		preFaultHookCount
		postFaultHookCount
		preStubHookCount
		postStubHookCount
		stubbedObjectCount
		freeSlotsOnStubbingSkippedByObjectCount
		serverMapStrongWindowEnterCount
		serverMapStrongWindowExitCount
		serverMapTombstoneCount
		allocatedFreeOopCount
		packedButNotAcceptedOopCount
		packedAcceptedOopCount
		transactionPrepareForCommitCallCount
		transactionDirtyFlushBeforeCommitCount
		transactionExportSetFlushBeforeCommitCount
		transactionPrepareForCommitFailureCount
		transactionResetCount
		transactionCommitResetCount
		transactionAbortResetCount
		lastExportSetAllReleasedCount
		lastExportSetNoLongerReleasedCount
		lastExportSetGcedReleasedCount
		lastExportSetNoLongerPendingCount
		lastExportSetGcedQueueSize
		lastExportSetNoLongerQueueSize)
]

{ #category : 'registries' }
GbsSessionLifecycleManager class >> lifecycleCountersForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionLifecycleCounters)
		at: aSession
		ifAbsentPut: [ self newLifecycleCounters ]
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> lifecycleCounterAt: aSymbol put: anInteger forSession: aSession [
	(self lifecycleCountersForSession: aSession)
		at: aSymbol
		put: anInteger.
	^ anInteger
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> incrementLifecycleCounter: aSymbol forSession: aSession [
	^ self incrementLifecycleCounter: aSymbol by: 1 forSession: aSession
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> incrementLifecycleCounter: aSymbol by: anInteger forSession: aSession [
	| counters value |
	anInteger = 0 ifTrue: [ ^ self lifecycleCountersForSession: aSession ].
	counters := self lifecycleCountersForSession: aSession.
	value := (counters at: aSymbol ifAbsent: [ 0 ]) + anInteger.
	counters at: aSymbol put: value.
	^ value
]

{ #category : 'registries' }
GbsSessionLifecycleManager class >> newIdentityRegistry [
	| registryClass |
	registryClass := Smalltalk globals at: #WeakIdentityKeyDictionary ifAbsent: [ nil ].
	registryClass ifNotNil: [ ^ registryClass new ].
	^ IdentityDictionary new
]

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> noteFreeOop: anOop forSession: aSession [
	^ self noteGcedOop: anOop forSession: aSession
]

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> noteAllocatedFreeOop: anOop forSession: aSession [
	(self isExportableOop: anOop) ifFalse: [ ^ nil ].
	self incrementLifecycleCounter: #allocatedFreeOopCount forSession: aSession.
	^ anOop
]

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> noteGcedOop: anOop forSession: aSession [
	| queue wasPending result |
	queue := self gcedOopQueueForSession: aSession.
	wasPending := queue includes: anOop.
	result := self noteOop: anOop inQueue: queue.
	(result notNil and: [ wasPending not ]) ifTrue: [
		self incrementLifecycleCounter: #gcedOopsQueuedCount forSession: aSession ].
	^ result
]

{ #category : 'export set' }
GbsSessionLifecycleManager class >> noteNoLongerReplicatedOop: anOop forSession: aSession [
	| queue wasPending result |
	queue := self noLongerReplicatedOopQueueForSession: aSession.
	wasPending := queue includes: anOop.
	result := self noteOop: anOop inQueue: queue.
	(result notNil and: [ wasPending not ]) ifTrue: [
		self incrementLifecycleCounter: #noLongerReplicatedOopsQueuedCount forSession: aSession ].
	^ result
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> newLifecycleCounters [
	| counters |
	counters := Dictionary new.
	self lifecycleReportCounterKeys do: [ :key |
		counters at: key put: 0 ].
	^ counters
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> noteOop: anOop inQueue: aCollection [
	(self isExportableOop: anOop) ifFalse: [ ^ nil ].
	(aCollection includes: anOop) ifFalse: [ aCollection add: anOop ].
	^ anOop
]

{ #category : 'testing' }
GbsSessionLifecycleManager class >> noLongerReplicatedStoreTraversalTransportAvailableForSession: aSession [
	| server |
	server := [ aSession serverInterface ] on: Error do: [ ^ false ].
	(server respondsTo: #storeTraversalBuffer:releasingNoLongerReplicatedOops:) ifFalse: [ ^ false ].
	(server respondsTo: #supportsNoLongerReplicatedStoreTraversalTransport) ifFalse: [ ^ false ].
	^ server supportsNoLongerReplicatedStoreTraversalTransport == true
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> oopCollectionString: aCollection [
	aCollection isEmpty ifTrue: [ ^ 'none' ].
	^ String streamContents: [ :stream |
		aCollection doWithIndex: [ :oop :index |
			index > 1 ifTrue: [ stream nextPutAll: ', ' ].
			stream nextPutAll: oop printString ] ]
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> normalizedDrainLimit: anInteger forSession: aSession [
	| limit |
	limit := anInteger ifNil: [ self freeOopDrainLimitForSession: aSession ].
	^ limit max: 0
]

{ #category : 'registries' }
GbsSessionLifecycleManager class >> newServerMapForSession: aSession [
	| policy mode registryClass |
	policy := [ GbsReplicationPolicy forSession: aSession ] on: Error do: [ nil ].
	mode := (policy notNil and: [ policy respondsTo: #serverMapMode ])
		ifTrue: [
			(policy respondsTo: #serverMapModeSymbol)
				ifTrue: [ policy serverMapModeSymbol ]
				ifFalse: [ policy serverMapMode asSymbol ] ]
		ifFalse: [ #weak ].
	mode = #weak ifTrue: [
		registryClass := Smalltalk globals at: #WeakValueDictionary ifAbsent: [ nil ].
		registryClass ifNotNil: [ ^ registryClass new ] ].
	^ Dictionary new
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> withStrongServerMapForSession: aSession do: aBlock [
	| registry previous strong |
	registry := aSession class weakRegistryNamed: #GbsSessionServerMaps.
	previous := registry
		at: aSession
		ifAbsent: [ nil ].
	previous ifNil: [ ^ aBlock value ].
	(self isWeakServerMap: previous) ifFalse: [ ^ aBlock value ].
	strong := Dictionary new.
	self copyLiveEntriesFrom: previous to: strong.
	registry at: aSession put: strong.
	self incrementLifecycleCounter: #serverMapStrongWindowEnterCount forSession: aSession.
	^ [
		aBlock value
	] ensure: [
		| restored |
		restored := self newServerMapForSession: aSession.
		self copyLiveEntriesFrom: strong to: restored.
		registry at: aSession put: restored.
		self incrementLifecycleCounter: #serverMapStrongWindowExitCount forSession: aSession ]
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> copyLiveEntriesFrom: sourceMap to: targetMap [
	sourceMap keysAndValuesDo: [ :oop :object |
		object ifNotNil: [
			targetMap at: oop put: object ] ].
	^ targetMap
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> isWeakServerMap: aMap [
	^ aMap class name includesSubstring: 'Weak'
]

{ #category : 'registries' }
GbsSessionLifecycleManager class >> noLongerReplicatedOopQueueForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionNoLongerReplicatedOopQueues)
		at: aSession
		ifAbsentPut: [ OrderedCollection new ]
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> objectForOop: anOop inSession: aSession [
	^ (self serverMapForSession: aSession)
		at: anOop
		ifAbsent: [ nil ]
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> pendingGcedOopsForSession: aSession limit: anInteger [
	^ self
		pendingOopsInQueue: (self gcedOopQueueForSession: aSession)
		limit: (self normalizedDrainLimit: anInteger forSession: aSession)
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> pendingExportSetReleaseOopCountForSession: aSession [
	^ (self pendingGcedOopCountForSession: aSession)
		+ (self pendingNoLongerReplicatedOopCountForSession: aSession)
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> pendingExportSetReleaseOopsForSession: aSession limit: anInteger [
	^ Dictionary new
		at: #noLongerReplicated put: (self pendingNoLongerReplicatedOopsForSession: aSession limit: anInteger);
		at: #gced put: (self pendingGcedOopsForSession: aSession limit: anInteger);
		at: #gcedOopQueueSize put: (self pendingGcedOopCountForSession: aSession);
		at: #noLongerReplicatedOopQueueSize put: (self pendingNoLongerReplicatedOopCountForSession: aSession);
		yourself
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> pendingGcedOopCountForSession: aSession [
	^ (self gcedOopQueueForSession: aSession) size
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> pendingNoLongerReplicatedOopsForSession: aSession limit: anInteger [
	^ self
		pendingOopsInQueue: (self noLongerReplicatedOopQueueForSession: aSession)
		limit: (self normalizedDrainLimit: anInteger forSession: aSession)
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> pendingNoLongerReplicatedOopCountForSession: aSession [
	^ (self noLongerReplicatedOopQueueForSession: aSession) size
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> pendingOopsInQueue: queue limit: limit [
	| count pending |
	count := queue size min: limit.
	count <= 0 ifTrue: [ ^ #() ].
	pending := Array new: count.
	1 to: count do: [ :index |
		pending at: index put: (queue at: index) ].
	^ pending
]

{ #category : 'finalization' }
GbsSessionLifecycleManager class >> deactivateFinalizerToken: aToken session: aSession [
	(self activeFinalizerTokensForSessionIfPresent: aSession)
		ifNotNil: [ :tokens | tokens remove: aToken ifAbsent: [ ] ].
	self incrementLifecycleCounter: #finalizerDeactivatedCount forSession: aSession.
	^ aToken
]

{ #category : 'finalization' }
GbsSessionLifecycleManager class >> registerFinalizerForObject: anObject oop: anOop session: aSession [
	| registry previous token |
	(self isExportableOop: anOop) ifFalse: [ ^ anObject ].
	registry := self finalizedObjectOopRegistryForSession: aSession.
	previous := registry at: anObject ifAbsent: [ nil ].
	(previous notNil and: [ previous first = anOop ]) ifTrue: [ ^ anObject ].
	previous ifNotNil: [ self deactivateFinalizerToken: previous session: aSession ].
	token := { anOop }.
	registry at: anObject put: token.
	(self activeFinalizerTokensForSession: aSession) add: token.
	aSession objectSpace
		defineFinalizerFor: anObject
		do: [ :finalizedObject |
			self
				noteFinalizedObject: finalizedObject
				oop: anOop
				session: aSession
				token: token ].
	self incrementLifecycleCounter: #finalizerRegisteredCount forSession: aSession.
	^ anObject
]

{ #category : 'finalization' }
GbsSessionLifecycleManager class >> noteFinalizedObject: anObject oop: anOop session: aSession token: aToken [
	| tokens |
	tokens := self activeFinalizerTokensForSessionIfPresent: aSession.
	tokens ifNil: [
		self incrementLifecycleCounter: #ignoredFinalizerNotificationCount forSession: aSession.
		^ nil ].
	(tokens includes: aToken) ifFalse: [
		self incrementLifecycleCounter: #ignoredFinalizerNotificationCount forSession: aSession.
		^ nil ].
	tokens remove: aToken ifAbsent: [ ].
	self incrementLifecycleCounter: #finalizedObjectNotificationCount forSession: aSession.
	^ self
		forgetObjectForOop: anOop
		inSession: aSession
		reason: #gced
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> rememberObject: anObject oop: anOop session: aSession [
	| map replacing |
	(anObject isNil or: [ anOop isNil ]) ifTrue: [ ^ anObject ].
	(self isExportableOop: anOop) ifFalse: [ ^ anObject ].
	self cancelNoLongerReplicatedOop: anOop forSession: aSession.
	map := self serverMapForSession: aSession.
	replacing := map includesKey: anOop.
	map at: anOop put: anObject.
	self incrementLifecycleCounter: #rememberedOopCount forSession: aSession.
	replacing ifTrue: [
		self incrementLifecycleCounter: #remappedOopCount forSession: aSession ].
	(GbsMaterializedObjectDirtyTracker canTrackObject: anObject) ifTrue: [
		self registerFinalizerForObject: anObject oop: anOop session: aSession ].
	^ anObject
]

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> releaseOops: oopArray forSession: aSession [
	(self releaseOopsTransportAvailableForSession: aSession) ifFalse: [
		GbsError signal: 'GCI release-oops transport is not available for this session.' ].
	[
		aSession serverInterface releaseOops: oopArray.
		(aSession respondsTo: #checkForError) ifTrue: [ aSession checkForError ] ]
		on: Error
		do: [ :ex |
			self incrementLifecycleCounter: #releaseOopsFailureCount forSession: aSession.
			ex pass ].
	self incrementLifecycleCounter: #releaseOopsCallCount forSession: aSession.
	self
		incrementLifecycleCounter: #releaseOopsReleasedCount
		by: oopArray size
		forSession: aSession.
	^ oopArray
]

{ #category : 'testing' }
GbsSessionLifecycleManager class >> releaseOopsTransportAvailableForSession: aSession [
	| server |
	server := [ aSession serverInterface ] on: Error do: [ ^ false ].
	(server respondsTo: #releaseOops:) ifFalse: [ ^ false ].
	(server respondsTo: #supportsReleaseOopsTransport) ifTrue: [
		^ server supportsReleaseOopsTransport == true ].
	^ true
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> removeOop: anOop fromQueue: queue [
	| removed |
	removed := false.
	[ queue includes: anOop ] whileTrue: [
		queue remove: anOop ifAbsent: [ ].
		removed := true ].
	^ removed
]

{ #category : 'faulting' }
GbsSessionLifecycleManager class >> invokePreFaultHookFor: anObject inSession: aSession [
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #preFaultInSession:) ifTrue: [
		self incrementLifecycleCounter: #preFaultHookCount forSession: aSession.
		^ anObject preFaultInSession: aSession ].
	(anObject respondsTo: #preFault) ifTrue: [
		self incrementLifecycleCounter: #preFaultHookCount forSession: aSession.
		^ anObject preFault ].
	^ nil
]

{ #category : 'faulting' }
GbsSessionLifecycleManager class >> invokePostFaultHookFor: anObject inSession: aSession [
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #postFaultInSession:) ifTrue: [
		self incrementLifecycleCounter: #postFaultHookCount forSession: aSession.
		^ anObject postFaultInSession: aSession ].
	(anObject respondsTo: #postFault) ifTrue: [
		self incrementLifecycleCounter: #postFaultHookCount forSession: aSession.
		^ anObject postFault ].
	^ nil
]

{ #category : 'stubbing' }
GbsSessionLifecycleManager class >> invokePreStubHookFor: anObject inSession: aSession [
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #preStubInSession:) ifTrue: [
		self incrementLifecycleCounter: #preStubHookCount forSession: aSession.
		^ anObject preStubInSession: aSession ].
	(anObject respondsTo: #preStub) ifTrue: [
		self incrementLifecycleCounter: #preStubHookCount forSession: aSession.
		^ anObject preStub ].
	^ nil
]

{ #category : 'stubbing' }
GbsSessionLifecycleManager class >> invokePostStubHookFor: anObject inSession: aSession [
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #postStubInSession:) ifTrue: [
		self incrementLifecycleCounter: #postStubHookCount forSession: aSession.
		^ anObject postStubInSession: aSession ].
	(anObject respondsTo: #postStub) ifTrue: [
		self incrementLifecycleCounter: #postStubHookCount forSession: aSession.
		^ anObject postStub ].
	^ nil
]

{ #category : 'stubbing' }
GbsSessionLifecycleManager class >> shouldFreeSlotsOnStubbingForSession: aSession [
	| policy |
	policy := [ GbsReplicationPolicy forSession: aSession ] on: Error do: [ nil ].
	policy ifNil: [ ^ true ].
	(policy respondsTo: #freeSlotsOnStubbing) ifFalse: [ ^ true ].
	^ policy freeSlotsOnStubbing ~~ false
]

{ #category : 'stubbing' }
GbsSessionLifecycleManager class >> shouldFreeSlotsOnStubbingFor: anObject inSession: aSession [
	| classSide objectPolicy |
	anObject ifNil: [ ^ self shouldFreeSlotsOnStubbingForSession: aSession ].
	classSide := anObject class class.
	(classSide includesSelector: #freeSlotsOnStubbing) ifTrue: [
		objectPolicy := [ anObject freeSlotsOnStubbing ] on: Error do: [ nil ].
		objectPolicy == false ifTrue: [
			self incrementLifecycleCounter: #freeSlotsOnStubbingSkippedByObjectCount forSession: aSession.
			^ false ].
		objectPolicy == true ifTrue: [ ^ true ] ].
	^ self shouldFreeSlotsOnStubbingForSession: aSession
]

{ #category : 'stubbing' }
GbsSessionLifecycleManager class >> stubObject: anObject inSession: aSession [
	| oop |
	oop := GbsMaterializedObjectDirtyTracker
		oopForObject: anObject
		inSession: aSession.
	oop ifNil: [
		GbsError signal: 'Object is not a replicated materialized object in this session.' ].
	^ self stubObjectForOop: oop inSession: aSession
]

{ #category : 'stubbing' }
GbsSessionLifecycleManager class >> stubObjectForOop: anOop inSession: aSession [
	| object |
	object := self objectForOop: anOop inSession: aSession.
	object
		ifNil: [ self forgetMaterializedObjectForOop: anOop inSession: aSession ]
		ifNotNil: [
			self incrementLifecycleCounter: #stubbedObjectCount forSession: aSession.
			self invokePreStubHookFor: object inSession: aSession.
			self
				forgetObjectForOop: anOop
				inSession: aSession
				reason: #noLongerReplicated.
			self invokePostStubHookFor: object inSession: aSession.
			(self shouldFreeSlotsOnStubbingFor: object inSession: aSession) ifTrue: [
				self freeSlotsOf: object inSession: aSession ] ].
	^ aSession objectForOop: anOop
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> reportValueString: anObject [
	anObject ifNil: [ ^ 'nil' ].
	anObject == true ifTrue: [ ^ 'true' ].
	anObject == false ifTrue: [ ^ 'false' ].
	anObject isSymbol ifTrue: [ ^ anObject asString ].
	^ anObject printString
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> removeFirst: count fromQueue: queue [
	count timesRepeat: [
		queue isEmpty ifFalse: [ queue removeFirst ] ].
	^ queue
]

{ #category : 'lifecycle' }
GbsSessionLifecycleManager class >> resetForSession: aSession [
	self resetTrackedObjectsForSession: aSession preserveCounters: false.
	GbsSessionEventController resetForSession: aSession.
	GbxClampManager resetForSession: aSession.
	^ aSession
]

{ #category : 'lifecycle' }
GbsSessionLifecycleManager class >> resetAfterTransactionForSession: aSession reason: reasonSymbol [
	self resetTrackedObjectsForSession: aSession preserveCounters: true.
	self incrementLifecycleCounter: #transactionResetCount forSession: aSession.
	reasonSymbol = #commit ifTrue: [
		self incrementLifecycleCounter: #transactionCommitResetCount forSession: aSession ].
	reasonSymbol = #abort ifTrue: [
		self incrementLifecycleCounter: #transactionAbortResetCount forSession: aSession ].
	^ aSession
]

{ #category : 'lifecycle' }
GbsSessionLifecycleManager class >> resetTrackedObjectsForSession: aSession preserveCounters: preserveCounters [
	(aSession class weakRegistryNamed: #GbsSessionServerMaps)
		removeKey: aSession
		ifAbsent: [ ].
	(aSession class weakRegistryNamed: #GbsSessionServerMapTombstones)
		removeKey: aSession
		ifAbsent: [ ].
	(aSession class weakRegistryNamed: #GbsSessionPackedButNotAcceptedOops)
		removeKey: aSession
		ifAbsent: [ ].
	(aSession class weakRegistryNamed: #GbsSessionFreeOopStreams)
		removeKey: aSession
		ifAbsent: [ ].
	(aSession class weakRegistryNamed: #GbsSessionFreeOopQueues)
		removeKey: aSession
		ifAbsent: [ ].
	(aSession class weakRegistryNamed: #GbsSessionGcedOopQueues)
		removeKey: aSession
		ifAbsent: [ ].
	(aSession class weakRegistryNamed: #GbsSessionNoLongerReplicatedOopQueues)
		removeKey: aSession
		ifAbsent: [ ].
	(aSession class weakRegistryNamed: #GbsSessionFinalizedObjectOopRegistries)
		removeKey: aSession
		ifAbsent: [ ].
	(aSession class weakRegistryNamed: #GbsSessionLifecycleFinalizerTokens)
		removeKey: aSession
		ifAbsent: [ ].
	preserveCounters ifFalse: [
		(aSession class weakRegistryNamed: #GbsSessionLifecycleCounters)
			removeKey: aSession
			ifAbsent: [ ] ].
	^ aSession
]

{ #category : 'transactions' }
GbsSessionLifecycleManager class >> prepareForCommitInSession: aSession [
	| policy dirtyObjects releaseSummary |
	self incrementLifecycleCounter: #transactionPrepareForCommitCallCount forSession: aSession.
	policy := [ GbsReplicationPolicy forSession: aSession ] on: Error do: [ nil ].
	(policy notNil and: [ policy storeDirtyOnCommit == true ]) ifFalse: [ ^ Dictionary new ].
	^ [
		dirtyObjects := [ GbsMaterializedObjectDirtyTracker dirtyObjectsForSession: aSession ]
			on: Error
			do: [ #() ].
		dirtyObjects isEmpty ifFalse: [
			aSession flushDirtyMaterializedObjects.
			self incrementLifecycleCounter: #transactionDirtyFlushBeforeCommitCount forSession: aSession ].
		releaseSummary := Dictionary new.
		(self pendingExportSetReleaseOopCountForSession: aSession) > 0 ifTrue: [
			releaseSummary := self flushAllExportSetReleaseOopsForSession: aSession limit: nil.
			self incrementLifecycleCounter: #transactionExportSetFlushBeforeCommitCount forSession: aSession ].
		releaseSummary ]
			on: Error
			do: [ :ex |
				self incrementLifecycleCounter: #transactionPrepareForCommitFailureCount forSession: aSession.
				ex pass ]
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> serverMapForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionServerMaps)
		at: aSession
		ifAbsentPut: [ self newServerMapForSession: aSession ]
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> serverMapTombstonesForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionServerMapTombstones)
		at: aSession
		ifAbsentPut: [ OrderedCollection new ]
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> recordServerMapTombstoneOop: anOop reason: reasonSymbol forSession: aSession [
	(self isExportableOop: anOop) ifFalse: [ ^ nil ].
	(self serverMapTombstonesForSession: aSession)
		add: (Dictionary new
			at: #oop put: anOop;
			at: #reason put: reasonSymbol;
			yourself).
	self incrementLifecycleCounter: #serverMapTombstoneCount forSession: aSession.
	^ anOop
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> packedButNotAcceptedOopsForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionPackedButNotAcceptedOops)
		at: aSession
		ifAbsentPut: [ OrderedCollection new ]
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> notePackedDirtyStoreEntries: entries forSession: aSession [
	| queue |
	queue := self packedButNotAcceptedOopsForSession: aSession.
	entries do: [ :entry |
		| oop |
		oop := entry first.
		(self isExportableOop: oop) ifTrue: [
			(queue includes: oop) ifFalse: [
				queue add: oop.
				self incrementLifecycleCounter: #packedButNotAcceptedOopCount forSession: aSession ] ] ].
	^ queue asArray
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> acknowledgePackedDirtyStoreEntries: entries forSession: aSession [
	| queue accepted |
	queue := self packedButNotAcceptedOopsForSession: aSession.
	accepted := OrderedCollection new.
	entries do: [ :entry |
		| oop |
		oop := entry first.
		(queue remove: oop ifAbsent: [ nil ]) ifNotNil: [
			accepted add: oop ] ].
	self
		incrementLifecycleCounter: #packedAcceptedOopCount
		by: accepted size
		forSession: aSession.
	^ accepted asArray
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> serverMapModeForSession: aSession [
	| policy |
	policy := [ GbsReplicationPolicy forSession: aSession ] on: Error do: [ nil ].
	(policy notNil and: [ policy respondsTo: #serverMapModeSymbol ]) ifTrue: [
		^ policy serverMapModeSymbol ].
	(policy notNil and: [ policy respondsTo: #serverMapMode ]) ifTrue: [
		^ policy serverMapMode asSymbol ].
	^ #weak
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> serverMapSizeForSession: aSession [
	^ (self serverMapForSession: aSession) size
]

{ #category : 'finalization' }
GbsSessionLifecycleManager class >> unregisterFinalizerForObject: anObject session: aSession [
	| token |
	(self finalizedObjectOopRegistryForSessionIfPresent: aSession)
		ifNotNil: [ :registry |
			token := registry removeKey: anObject ifAbsent: [ nil ] ].
	token ifNotNil: [ self deactivateFinalizerToken: token session: aSession ].
	token ifNotNil: [
		self incrementLifecycleCounter: #finalizerUnregisteredCount forSession: aSession ].
	^ anObject
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> acknowledgeOops: oopCollection inQueue: queue label: labelString [
	oopCollection isEmpty ifTrue: [ ^ oopCollection ].
	oopCollection doWithIndex: [ :oop :index |
		(queue size < index or: [ (queue at: index) ~= oop ]) ifTrue: [
			GbsError signal: labelString, ' OOP queue changed before acknowledgement.' ] ].
	self removeFirst: oopCollection size fromQueue: queue.
	^ oopCollection
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> writeReportKey: aSymbol from: aDictionary on: aStream [
	aStream
		nextPutAll: aSymbol asString;
		nextPutAll: '=';
		nextPutAll: (self reportValueString: (aDictionary at: aSymbol ifAbsent: [ nil ]));
		cr
]
