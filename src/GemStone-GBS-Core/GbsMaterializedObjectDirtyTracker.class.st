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
	^ false
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
GbsMaterializedObjectDirtyTracker class >> markStDirty: anObject [
	| session |
	session := self sessionTrackingObject: anObject.
	session ifNotNil: [
		self markObject: anObject dirtyInSession: session ].
	^ anObject
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

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> resetForSession: aSession [
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
	GbsSessionLifecycleManager resetForSession: aSession.
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

{ #category : 'dirty tracking' }
GbsMaterializedObjectDirtyTracker class >> withSuspendedForSession: aSession do: aBlock [
	| previous |
	previous := self suspensionCountForSession: aSession.
	self suspensionCount: previous + 1 forSession: aSession.
	^ [ aBlock value ] ensure: [
		self suspensionCount: previous forSession: aSession ]
]
