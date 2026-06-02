Class {
	#name : 'GbsSessionLifecycleManager',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'free oops' }
GbsSessionLifecycleManager class >> drainFreeOopsForSession: aSession limit: anInteger [
	| queue drained limit |
	queue := self freeOopQueueForSession: aSession.
	drained := OrderedCollection new.
	limit := anInteger ifNil: [ self freeOopDrainLimitForSession: aSession ].
	[ drained size < limit and: [ queue isEmpty not ] ] whileTrue: [
		drained add: queue removeFirst ].
	^ drained asArray
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
GbsSessionLifecycleManager class >> freeOopQueueForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionFreeOopQueues)
		at: aSession
		ifAbsentPut: [ OrderedCollection new ]
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
	(self freeOopQueueForSession: aSession) add: anOop.
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

{ #category : 'server map' }
GbsSessionLifecycleManager class >> objectForOop: anOop inSession: aSession [
	^ (self serverMapForSession: aSession)
		at: anOop
		ifAbsent: [ nil ]
]

{ #category : 'server map' }
GbsSessionLifecycleManager class >> rememberObject: anObject oop: anOop session: aSession [
	(anObject isNil or: [ anOop isNil ]) ifTrue: [ ^ anObject ].
	(self serverMapForSession: aSession) at: anOop put: anObject.
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
