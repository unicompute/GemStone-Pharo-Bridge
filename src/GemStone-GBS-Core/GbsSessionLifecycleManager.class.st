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
GbsSessionLifecycleManager class >> drainExportSetReleaseOopsForSession: aSession limit: anInteger [
	^ Dictionary new
		at: #noLongerReplicated put: (self drainNoLongerReplicatedOopsForSession: aSession limit: anInteger);
		at: #gced put: (self drainGcedOopsForSession: aSession limit: anInteger);
		yourself
]

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> drainGcedOopsForSession: aSession limit: anInteger [
	| queue drained limit |
	queue := self gcedOopQueueForSession: aSession.
	drained := OrderedCollection new.
	limit := anInteger ifNil: [ self freeOopDrainLimitForSession: aSession ].
	[ drained size < limit and: [ queue isEmpty not ] ] whileTrue: [
		drained add: queue removeFirst ].
	^ drained asArray
]

{ #category : 'export set' }
GbsSessionLifecycleManager class >> drainNoLongerReplicatedOopsForSession: aSession limit: anInteger [
	| queue drained limit |
	queue := self noLongerReplicatedOopQueueForSession: aSession.
	drained := OrderedCollection new.
	limit := anInteger ifNil: [ self freeOopDrainLimitForSession: aSession ].
	[ drained size < limit and: [ queue isEmpty not ] ] whileTrue: [
		drained add: queue removeFirst ].
	^ drained asArray
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
	map := self serverMapForSession: aSession.
	object := map at: anOop ifAbsent: [ nil ].
	map removeKey: anOop ifAbsent: [ ].
	object ifNotNil: [
		self unregisterFinalizerForObject: object session: aSession.
		GbsMaterializedObjectDirtyTracker
			unregisterObject: object
			inSession: aSession ].
	reasonSymbol = #gced
		ifTrue: [ self noteGcedOop: anOop forSession: aSession ]
		ifFalse: [ self noteNoLongerReplicatedOop: anOop forSession: aSession ].
	^ object
]

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> freeOopDrainLimitForSession: aSession [
	| policy |
	policy := [ GbsReplicationPolicy forSession: aSession ] on: Error do: [ nil ].
	(policy notNil and: [ policy respondsTo: #freeOopBatchSize ]) ifTrue: [
		^ policy freeOopBatchSize max: 0 ].
	^ 256
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
	^ Dictionary new
		at: #serverMapSize put: (self serverMapSizeForSession: aSession);
		at: #gcedOopQueueSize put: (self pendingGcedOopCountForSession: aSession);
		at: #noLongerReplicatedOopQueueSize put: (self pendingNoLongerReplicatedOopCountForSession: aSession);
		at: #freeOopDrainLimit put: (self freeOopDrainLimitForSession: aSession);
		yourself
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
GbsSessionLifecycleManager class >> noteGcedOop: anOop forSession: aSession [
	^ self noteOop: anOop inQueue: (self gcedOopQueueForSession: aSession)
]

{ #category : 'export set' }
GbsSessionLifecycleManager class >> noteNoLongerReplicatedOop: anOop forSession: aSession [
	^ self noteOop: anOop inQueue: (self noLongerReplicatedOopQueueForSession: aSession)
]

{ #category : 'private' }
GbsSessionLifecycleManager class >> noteOop: anOop inQueue: aCollection [
	(self isExportableOop: anOop) ifFalse: [ ^ nil ].
	(aCollection includes: anOop) ifFalse: [ aCollection add: anOop ].
	^ anOop
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
GbsSessionLifecycleManager class >> pendingGcedOopCountForSession: aSession [
	^ (self gcedOopQueueForSession: aSession) size
]

{ #category : 'diagnostics' }
GbsSessionLifecycleManager class >> pendingNoLongerReplicatedOopCountForSession: aSession [
	^ (self noLongerReplicatedOopQueueForSession: aSession) size
]

{ #category : 'finalization' }
GbsSessionLifecycleManager class >> deactivateFinalizerToken: aToken session: aSession [
	(self activeFinalizerTokensForSessionIfPresent: aSession)
		ifNotNil: [ :tokens | tokens remove: aToken ifAbsent: [ ] ].
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
	^ anObject
]

{ #category : 'finalization' }
GbsSessionLifecycleManager class >> noteFinalizedObject: anObject oop: anOop session: aSession token: aToken [
	| tokens |
	tokens := self activeFinalizerTokensForSessionIfPresent: aSession.
	tokens ifNil: [ ^ nil ].
	(tokens includes: aToken) ifFalse: [ ^ nil ].
	tokens remove: aToken ifAbsent: [ ].
	^ self
		forgetObjectForOop: anOop
		inSession: aSession
		reason: #gced
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> rememberObject: anObject oop: anOop session: aSession [
	(anObject isNil or: [ anOop isNil ]) ifTrue: [ ^ anObject ].
	(self isExportableOop: anOop) ifFalse: [ ^ anObject ].
	(self serverMapForSession: aSession) at: anOop put: anObject.
	(GbsMaterializedObjectDirtyTracker canTrackObject: anObject) ifTrue: [
		self registerFinalizerForObject: anObject oop: anOop session: aSession ].
	^ anObject
]

{ #category : 'lifecycle' }
GbsSessionLifecycleManager class >> resetForSession: aSession [
	(aSession class weakRegistryNamed: #GbsSessionServerMaps)
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
	GbsSessionEventController resetForSession: aSession.
	GbxClampManager resetForSession: aSession.
	^ aSession
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> serverMapForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionServerMaps)
		at: aSession
		ifAbsentPut: [ self newServerMapForSession: aSession ]
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
	^ anObject
]
