Class {
	#name : 'GbsRuntime',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'lifecycle' }
GbsRuntime class >> gbxResolve: aSymbol [
	^ Smalltalk globals at: aSymbol ifAbsent: [ nil ]
]

{ #category : 'lifecycle' }
GbsRuntime class >> loaded [
	self initializeClasses.
	((self gbxResolve: #GbsSessionManager) respondsTo: #initializeFastConnectors)
		ifTrue: [ (self gbxResolve: #GbsSessionManager) initializeFastConnectors ].
]

{ #category : 'lifecycle' }
GbsRuntime class >> removing [
	| mgr |
	mgr := self gbxResolve: #GbsSessionManager.
	(mgr notNil and: [ mgr respondsTo: #gbsRemoving ])
		ifTrue: [ mgr gbsRemoving ].
]

{ #category : 'lifecycle' }
GbsRuntime class >> startUp [
	| mgr |
	mgr := self gbxResolve: #GbsSessionManager.
	(mgr notNil and: [ mgr respondsTo: #gbsImageStartup ])
		ifTrue: [ mgr gbsImageStartup ]
		ifFalse: [
			(mgr notNil and: [ mgr respondsTo: #initializeFastConnectors ])
				ifTrue: [ mgr initializeFastConnectors ] ].
]

{ #category : 'lifecycle' }
GbsRuntime class >> exiting [
	| gbsm |
	gbsm := self gbxResolve: #GBSM.
	(gbsm notNil and: [ gbsm respondsTo: #aboutToQuit ])
		ifTrue: [ gbsm aboutToQuit ].
]

{ #category : 'lifecycle' }
GbsRuntime class >> initializeClasses [
	| initialized |
	initialized := OrderedCollection new.
	(Smalltalk allClasses
		select: [ :each |
			| nm |
			nm := each name asString.
			(nm beginsWith: 'Gbs') or: [ nm beginsWith: 'Gbx' ] ])
		do: [ :each |
			(each class includesSelector: #initialize) ifTrue: [
				[ each initialize. initialized add: each ]
					on: Error
					do: [ :ex | ] ] ].
	^ initialized
]

{ #category : 'lifecycle' }
GbsRuntime class >> packagerIncludeClasses [
	| base |
	base := self gbxResolve: #GbsException.
	base ifNil: [ ^ #() ].
	^ base withAllSubclasses
]

{ #category : 'lifecycle' }
GbsRuntime class >> packagerIncludeSelectors [
	^ #(
		abort
		beginTransaction
		commit
		commitTransaction
		logout
		run
		assertionChecks
		assertionChecks:
		autoMarkDirty
		autoMarkDirty:
		blockReplicationPolicy
		blockReplicationPolicy:
		blockingProtocolRpc
		blockingProtocolRpc:
		bulkLoad
		bulkLoad:
		connectorNilling
		connectorNilling:
		connectVerification
		connectVerification:
		defaultFaultPolicy
		defaultFaultPolicy:
		eventPollingFrequency
		eventPollingFrequency:
		eventPriority
		eventPriority:
		faultLevelRpc
		faultLevelRpc:
		forwarderDebugging
		forwarderDebugging:
		freeSlotsOnStubbing
		freeSlotsOnStubbing:
		generateClassConnectors
		generateClassConnectors:
		generateClientClasses
		generateClientClasses:
		generateServerClasses
		generateServerClasses:
		initialDirtyPoolSize
		initialDirtyPoolSize:
		removeInvalidConnectors
		removeInvalidConnectors:
		stubDebugging
		stubDebugging:
		traversalBufferSize
		traversalBufferSize:
		verbose
		verbose:
	)
]

{ #category : 'lifecycle' }
GbsRuntime class >> reportInstances [
	| classes total |
	total := 0.
	classes := Smalltalk allClasses
		select: [ :each |
			| nm |
			nm := each name asString.
			(nm beginsWith: 'Gbs') or: [ nm beginsWith: 'Gbx' ] ].
	classes asSortedCollection: [ :a :b | a name <= b name ] do: [ :each |
		| count |
		count := [ each allInstances size ] on: Error do: [ 0 ].
		count > 0 ifTrue: [ total := total + count ] ].
	^ total
]
