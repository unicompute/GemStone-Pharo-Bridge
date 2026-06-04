Class {
	#name : 'GbsMaterializedObjectDirtyTracker',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> canTrackObject: anObject [
	anObject ifNil: [ ^ false ].
	(anObject isKindOf: Association) ifTrue: [ ^ true ].
	(anObject isKindOf: Dictionary) ifTrue: [ ^ true ].
	(anObject isKindOf: Bag) ifTrue: [ ^ true ].
	(anObject isKindOf: Set) ifTrue: [ ^ true ].
	(anObject isKindOf: OrderedCollection) ifTrue: [ ^ true ].
	(anObject isKindOf: Array) ifTrue: [ ^ true ].
	^ self hasTrackableNamedSlots: anObject
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> hasTrackableNamedSlots: anObject [
	| names |
	anObject ifNil: [ ^ false ].
	(anObject class respondsTo: #allInstVarNames) ifFalse: [ ^ false ].
	names := [ anObject class allInstVarNames ] on: Error do: [ #() ].
	^ names isEmpty not
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> clearDirtyForSession: aSession [
	^ aSession dirtyPool clearDirty
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> clearDirtyObjects: objects forSession: aSession [
	^ aSession dirtyPool clearDirtyObjects: objects
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> dirtyObjectsForSession: aSession [
	^ aSession dirtyPool dirtyAwaitingPacking copy
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> dirtyOopsForSession: aSession [
	| oops |
	oops := OrderedCollection new.
	(self dirtyObjectsForSession: aSession) do: [ :each |
		| oop |
		oop := self oopForObject: each inSession: aSession.
		oop ifNotNil: [ oops add: oop ] ].
	^ oops asArray
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> assertMutationAllowedFor: anObject slot: slotIndex inSession: aSession noModError: noModError [
	| reason |
	reason := self mutationDeniedReasonFor: anObject slot: slotIndex inSession: aSession.
	reason ifNil: [ ^ anObject ].
	noModError ifNotNil: [
		(noModError respondsTo: #value) ifTrue: [ noModError value ].
		(noModError isString) ifTrue: [ GbsError signal: noModError ] ].
	GbsError signal: reason
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> flushDirtyForSession: aSession [
	^ GbsDirtyReplicateStoreTraversal flushSession: aSession
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> delegateForObject: anObject [
	(self sessionTrackingObject: anObject) ifNil: [ ^ nil ].
	^ self
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> isObject: anObject dirtyInSession: aSession [
	^ aSession dirtyPool isDirty: anObject
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> isSuspendedForSession: aSession [
	^ (self suspensionCountForSession: aSession) > 0
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> markObject: anObject dirtyInSession: aSession [
	(self isSuspendedForSession: aSession) ifTrue: [ ^ anObject ].
	(self policyAllowsAutoMarkDirtyFor: anObject inSession: aSession) ifFalse: [ ^ anObject ].
	(self oopForObject: anObject inSession: aSession) ifNil: [ ^ anObject ].
	aSession dirtyPool markDirty: anObject.
	^ anObject
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> markObject: anObject dirtyAtNamedSlot: slotIndex inSession: aSession [
	(self shouldIgnoreDirtyMarkFor: anObject namedSlot: slotIndex inSession: aSession) ifTrue: [
		^ anObject ].
	^ self markObject: anObject dirtyInSession: aSession
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> markStDirty: anObject [
	| session |
	session := self sessionTrackingObject: anObject.
	session ifNotNil: [
		self markObject: anObject dirtyInSession: session ].
	^ anObject
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> mutationDeniedReasonFor: anObject slot: slotIndex inSession: aSession [
	| manager scheme selector slotReason |
	aSession ifNil: [ ^ nil ].
	(self strictMutationProtectionEnabledForSession: aSession) ifFalse: [ ^ nil ].
	(self oopForObject: anObject inSession: aSession) ifNil: [ ^ nil ].
	manager := [ GbxClampManager forSession: aSession ] on: Error do: [ nil ].
	manager ifNil: [ ^ nil ].
	scheme := manager replicationSchemeFor: anObject.
	scheme ifNil: [ ^ nil ].
	selector := (scheme respondsTo: #selector)
		ifTrue: [ scheme selector ]
		ifFalse: [ nil ].
	((scheme respondsTo: #isStub) and: [ scheme isStub ]) ifTrue: [
		^ self mutationDeniedTextForScheme: selector slot: slotIndex ].
	((scheme respondsTo: #isNone) and: [ scheme isNone ]) ifTrue: [
		^ self mutationDeniedTextForScheme: selector slot: slotIndex ].
	slotReason := self
		mutationDeniedSlotReasonFor: anObject
		slot: slotIndex
		scheme: scheme
		inSession: aSession.
	slotReason ifNotNil: [
		^ self
			mutationDeniedTextForScheme: selector
			slot: slotIndex
			detail: slotReason ].
	^ nil
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> mutationDeniedSlotReasonFor: anObject slot: slotIndex scheme: aScheme inSession: aSession [
	| replicator |
	replicator := self replicatorForObject: anObject inSession: aSession.
	(self
		replicator: replicator
		deniesMutationOfSlot: slotIndex
		inObject: anObject
		scheme: aScheme) ifTrue: [
		^ 'slot is clamped as a stub or forwarder' ].
	(self replicatorUsesInstVarMap: replicator) ifFalse: [
		(self scheme: aScheme deniesMutationOfSlot: slotIndex inObject: anObject) ifTrue: [
			^ 'slot is clamped as a stub or forwarder' ] ].
	(self shouldIgnoreDirtyMarkFor: anObject namedSlot: slotIndex inSession: aSession) ifTrue: [
		^ 'slot is not mapped to the server object' ].
	^ nil
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> mutationDeniedTextForScheme: schemeSelector slot: slotIndex [
	^ self mutationDeniedTextForScheme: schemeSelector slot: slotIndex detail: nil
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> mutationDeniedTextForScheme: schemeSelector slot: slotIndex detail: detailString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Cannot modify a ';
			nextPutAll: (schemeSelector ifNil: [ 'non-replicated' ] ifNotNil: [ schemeSelector asString ]);
			nextPutAll: ' replicated object while strict mutation protection is enabled'.
		slotIndex ifNotNil: [
			stream
				nextPutAll: ' (slot ';
				nextPutAll: slotIndex asString;
				nextPutAll: ')' ].
		detailString ifNotNil: [
			stream
				nextPutAll: ': ';
				nextPutAll: detailString ].
		stream nextPut: $. ]
]

{ #category : 'registries' }
GbsMaterializedObjectDirtyTracker class >> newIdentityRegistry [
	| registryClass |
	registryClass := Smalltalk globals at: #WeakIdentityKeyDictionary ifAbsent: [ nil ].
	registryClass ifNotNil: [ ^ registryClass new ].
	^ IdentityDictionary new
]

{ #category : 'registries' }
GbsMaterializedObjectDirtyTracker class >> objectOopRegistryForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionMaterializedObjectOopRegistries)
		at: aSession
		ifAbsentPut: [ self newIdentityRegistry ]
]

{ #category : 'registries' }
GbsMaterializedObjectDirtyTracker class >> oopForObject: anObject inSession: aSession [
	^ (self objectOopRegistryForSession: aSession)
		at: anObject
		ifAbsent: [ nil ]
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> policyAllowsAutoMarkDirtyFor: anObject inSession: aSession [
	| manager scheme |
	(self policyAllowsAutoMarkDirtyForSession: aSession) ifFalse: [ ^ false ].
	manager := [ GbxClampManager forSession: aSession ] on: Error do: [ nil ].
	manager ifNil: [ ^ true ].
	scheme := manager replicationSchemeFor: anObject.
	scheme ifNil: [ ^ true ].
	(scheme respondsTo: #shouldAutoMarkDirty) ifFalse: [ ^ true ].
	^ scheme shouldAutoMarkDirty
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> policyAllowsAutoMarkDirtyForSession: aSession [
	| policy |
	policy := [ GbsReplicationPolicy forSession: aSession ] on: Error do: [ nil ].
	policy ifNil: [ ^ true ].
	(policy respondsTo: #autoMarkDirty) ifFalse: [ ^ true ].
	^ policy autoMarkDirty ~~ false
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> scheme: aScheme deniesIndexableMutationOfClass: aClass [
	| levels indexedLevel |
	(aScheme respondsTo: #shouldProxyIndexedInstvarsOfClass:) ifTrue: [
		(aScheme shouldProxyIndexedInstvarsOfClass: aClass) ifTrue: [ ^ true ] ].
	(aScheme respondsTo: #instVarLevelsForClass:) ifFalse: [ ^ false ].
	levels := [ aScheme instVarLevelsForClass: aClass ] on: Error do: [ #() ].
	levels ifNil: [ ^ false ].
	levels isEmpty ifTrue: [ ^ false ].
	indexedLevel := levels last.
	^ indexedLevel == false or: [ indexedLevel = 0 ]
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> scheme: aScheme deniesMutationOfSlot: slotIndex inObject: anObject [
	| namedSize levels level |
	slotIndex ifNil: [ ^ false ].
	slotIndex isInteger ifFalse: [
		^ self
			scheme: aScheme
			deniesIndexableMutationOfClass: anObject class ].
	namedSize := [ anObject class instSize ] on: Error do: [ 0 ].
	slotIndex > namedSize ifTrue: [
		^ self
			scheme: aScheme
			deniesIndexableMutationOfClass: anObject class ].
	(aScheme respondsTo: #shouldProxyNamedSlot:ofClass:) ifTrue: [
		(aScheme shouldProxyNamedSlot: slotIndex ofClass: anObject class) ifTrue: [ ^ true ] ].
	(aScheme respondsTo: #instVarLevelsForClass:) ifFalse: [ ^ false ].
	levels := [ aScheme instVarLevelsForClass: anObject class ] on: Error do: [ #() ].
	levels ifNil: [ ^ false ].
	(slotIndex between: 1 and: levels size) ifFalse: [ ^ false ].
	level := levels at: slotIndex.
	^ level == false or: [ level = 0 ]
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> strictMutationProtectionEnabledForSession: aSession [
	| policy |
	policy := [ GbsReplicationPolicy forSession: aSession ] on: Error do: [ nil ].
	policy ifNil: [ ^ false ].
	(policy respondsTo: #strictMutationProtectionEnabled) ifFalse: [ ^ false ].
	^ policy strictMutationProtectionEnabled == true
]

{ #category : 'private' }
GbsMaterializedObjectDirtyTracker class >> replicatorForObject: anObject inSession: aSession [
	(aSession notNil and: [ aSession respondsTo: #replicatorForClient:ifAbsent: ]) ifFalse: [
		^ nil ].
	^ [ aSession
		replicatorForClient: anObject
		ifAbsent: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> replicator: aReplicator deniesMutationOfSlot: slotIndex inObject: anObject scheme: aScheme [
	| replicationSpec spec instVarName |
	aReplicator ifNil: [ ^ false ].
	replicationSpec := self replicationSpecForReplicator: aReplicator scheme: aScheme.
	(replicationSpec isSymbol or: [ replicationSpec isNil ]) ifTrue: [ ^ false ].
	slotIndex ifNil: [ ^ false ].
	slotIndex isInteger ifFalse: [
		spec := self replicationSpec: replicationSpec forInstVarName: 'indexable_part'.
		^ self replicationSpecDeniesMutation: spec ].
	instVarName := self instVarNameAt: slotIndex forReplicator: aReplicator object: anObject.
	instVarName ifNil: [ ^ false ].
	spec := self replicationSpec: replicationSpec forInstVarName: instVarName.
	^ self replicationSpecDeniesMutation: spec
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> replicatorUsesInstVarMap: aReplicator [
	aReplicator ifNil: [ ^ false ].
	(aReplicator respondsTo: #usesInstVarMap) ifFalse: [ ^ false ].
	^ [ aReplicator usesInstVarMap ] on: Error do: [ false ]
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> replicationSpec: replicationSpec forInstVarName: instVarName [
	replicationSpec do: [ :specArray |
		(specArray size >= 2 and: [ specArray first asString = instVarName asString ]) ifTrue: [
			^ specArray ] ].
	^ nil
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> replicationSpecDeniesMutation: specArray [
	| operator |
	(specArray isNil or: [ specArray size < 2 ]) ifTrue: [ ^ false ].
	operator := specArray second asSymbol.
	^ operator = #forwarder or: [ operator = #stub ]
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> replicationSpecForReplicator: aReplicator scheme: aScheme [
	(aReplicator respondsTo: #replicationSpecForScheme:) ifTrue: [
		^ [ aReplicator replicationSpecForScheme: aScheme ] on: Error do: [ nil ] ].
	(aReplicator respondsTo: #replicationSpec) ifTrue: [
		^ [ aReplicator replicationSpec ] on: Error do: [ nil ] ].
	^ nil
]

{ #category : 'registries' }
GbsMaterializedObjectDirtyTracker class >> registerObject: anObject forSession: aSession [
	self sessionRegistry at: anObject put: aSession.
	^ anObject
]

{ #category : 'registries' }
GbsMaterializedObjectDirtyTracker class >> registerObject: anObject oop: anOop session: aSession [
	(self canTrackObject: anObject) ifFalse: [ ^ anObject ].
	(self objectOopRegistryForSession: aSession) at: anObject put: anOop.
	GbsSessionLifecycleManager rememberObject: anObject oop: anOop session: aSession.
	self registerObject: anObject forSession: aSession.
	^ anObject
]

{ #category : 'registries' }
GbsMaterializedObjectDirtyTracker class >> registerNewObject: anObject session: aSession [
	(self canTrackObject: anObject) ifFalse: [ ^ anObject ].
	self registerObject: anObject forSession: aSession.
	aSession dirtyPool markDirty: anObject.
	^ anObject
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> resetForSession: aSession [
	^ self resetForSession: aSession preserveLifecycleCounters: false
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> resetAfterTransactionForSession: aSession reason: reasonSymbol [
	self resetForSession: aSession preserveLifecycleCounters: true.
	GbsSessionLifecycleManager resetAfterTransactionForSession: aSession reason: reasonSymbol.
	^ aSession
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> resetForSession: aSession preserveLifecycleCounters: preserveCounters [
	| registry |
	registry := (aSession class weakRegistryNamed: #GbsSessionMaterializedObjectOopRegistries)
		at: aSession
		ifAbsent: [ nil ].
	registry ifNotNil: [
		registry keysDo: [ :each | self unregisterObject: each ] ].
	(aSession class weakRegistryNamed: #GbsSessionMaterializedObjectOopRegistries)
		removeKey: aSession
		ifAbsent: [ ].
	(aSession class weakRegistryNamed: #GbsSessionDirtyTrackingSuspensionCounts)
		removeKey: aSession
		ifAbsent: [ ].
	(aSession class weakRegistryNamed: #GbsSessionDirtyPools)
		removeKey: aSession
		ifAbsent: [ ].
	GbsDirtyReplicateStoreTraversal resetDirtyStoreTraversalReportForSession: aSession.
	preserveCounters
		ifTrue: [ GbsSessionLifecycleManager resetTrackedObjectsForSession: aSession preserveCounters: true ]
		ifFalse: [ GbsSessionLifecycleManager resetForSession: aSession ].
	^ aSession
]

{ #category : 'registries' }
GbsMaterializedObjectDirtyTracker class >> sessionRegistry [
	^ Smalltalk globals
		at: #GbsMaterializedObjectSessionRegistry
		ifAbsentPut: [ self newIdentityRegistry ]
]

{ #category : 'registries' }
GbsMaterializedObjectDirtyTracker class >> sessionRegistryIfPresent [
	^ Smalltalk globals
		at: #GbsMaterializedObjectSessionRegistry
		ifAbsent: [ nil ]
]

{ #category : 'registries' }
GbsMaterializedObjectDirtyTracker class >> sessionTrackingObject: anObject [
	| registry |
	registry := self sessionRegistryIfPresent.
	registry ifNil: [ ^ nil ].
	^ registry at: anObject ifAbsent: [ nil ]
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> shouldIgnoreDirtyMarkFor: anObject namedSlot: slotIndex inSession: aSession [
	| replicator offsets |
	slotIndex ifNil: [ ^ false ].
	slotIndex isInteger ifFalse: [ ^ false ].
	replicator := self replicatorForObject: anObject inSession: aSession.
	(replicator notNil and: [
		(replicator respondsTo: #usesInstVarMap)
			and: [ replicator usesInstVarMap ] ]) ifFalse: [
		^ false ].
	(replicator respondsTo: #serverToClientOffsets) ifFalse: [ ^ false ].
	offsets := [ replicator serverToClientOffsets ] on: Error do: [ #() ].
	offsets isEmpty ifTrue: [ ^ false ].
	^ (offsets includes: slotIndex) not
]

{ #category : 'testing' }
GbsMaterializedObjectDirtyTracker class >> instVarNameAt: slotIndex forReplicator: aReplicator object: anObject [
	| clientClass names |
	clientClass := (aReplicator respondsTo: #clientClass)
		ifTrue: [ aReplicator clientClass ]
		ifFalse: [ anObject class ].
	clientClass ifNil: [ clientClass := anObject class ].
	(clientClass respondsTo: #allInstVarNames) ifFalse: [ ^ nil ].
	names := [ clientClass allInstVarNames ] on: Error do: [ #() ].
	^ (names at: slotIndex ifAbsent: [ nil ])
		ifNil: [ nil ]
		ifNotNil: [ :name | name asString ]
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> suspensionCount: anInteger forSession: aSession [
	| registry |
	registry := aSession class weakRegistryNamed: #GbsSessionDirtyTrackingSuspensionCounts.
	anInteger <= 0
		ifTrue: [ registry removeKey: aSession ifAbsent: [ ] ]
		ifFalse: [ registry at: aSession put: anInteger ].
	^ anInteger
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> suspensionCountForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionDirtyTrackingSuspensionCounts)
		at: aSession
		ifAbsent: [ 0 ]
]

{ #category : 'registries' }
GbsMaterializedObjectDirtyTracker class >> unregisterObject: anObject [
	self sessionRegistryIfPresent
		ifNotNil: [ :registry | registry removeKey: anObject ifAbsent: [ ] ].
	^ anObject
]

{ #category : 'registries' }
GbsMaterializedObjectDirtyTracker class >> unregisterObject: anObject inSession: aSession [
	| registry |
	registry := (aSession class weakRegistryNamed: #GbsSessionMaterializedObjectOopRegistries)
		at: aSession
		ifAbsent: [ nil ].
	registry ifNotNil: [
		registry removeKey: anObject ifAbsent: [ ] ].
	[ aSession dirtyPool clearDirtyObjects: { anObject } ]
		on: Error
		do: [ :ex | nil ].
	self unregisterObject: anObject.
	^ anObject
]

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> withSuspendedForSession: aSession do: aBlock [
	| previous |
	previous := self suspensionCountForSession: aSession.
	self suspensionCount: previous + 1 forSession: aSession.
	^ [ aBlock value ] ensure: [
		self suspensionCount: previous forSession: aSession ]
]
