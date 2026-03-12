Class {
	#name : 'GbsConfiguration',
	#superclass : 'Object',
	#instVars : [
		'alwaysUseGemCursor',
		'assertionChecks',
		'autoMarkDirty',
		'backupPolling',
		'blockReplicationEnabled',
		'blockReplicationPolicy',
		'blockingProtocolRpc',
		'bulkLoad',
		'clampByCallback',
		'clientMapCapacity',
		'clientMapFinalizerPriority',
		'confirm',
		'connectVerification',
		'connectorNilling',
		'connectorConnectionState',
		'connectorRowSettings',
		'defaultFaultPolicy',
		'deprecationWarnings',
		'eventPollingFrequency',
		'eventPriority',
		'faultLevelLnk',
		'faultLevelRpc',
		'forwarderDebugging',
		'freeSlotsOnStubbing',
		'fullCompression',
		'gcedObjBufferSize',
		'generateClassConnectors',
		'generateClientClasses',
		'generateServerClasses',
		'initialDirtyPoolSize',
		'libraryName',
		'removeInvalidConnectors',
		'replicateExceptions',
		'serverMapLeafCapacity',
		'stubDebugging',
		'traversalBufferSize',
		'useGbsMemoryPolicy',
		'useDiagnosticSpecialConverter',
		'verbose',
		'socketWaitTimeout',
		'postConnectAction'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbsConfiguration class >> current [
	^ Smalltalk globals
		at: #GbsCurrentConfiguration
		ifAbsentPut: [ self new initializeDefaults; yourself ]
]

{ #category : 'accessing' }
GbsConfiguration class >> current: aConfiguration [
	Smalltalk globals at: #GbsCurrentConfiguration put: aConfiguration
]

{ #category : 'actions' }
GbsConfiguration class >> generateClassConnectors [
	| cfg |
	cfg := self current.
	cfg valueAt: #generateClassConnectors put: true.
	(Smalltalk at: #GbsSessionManager ifAbsent: [ nil ])
		ifNotNil: [ :mgr |
			(mgr respondsTo: #generateClassConnectors)
				ifTrue: [ mgr generateClassConnectors ]
				ifFalse: [
					(mgr respondsTo: #initializeFastConnectors)
						ifTrue: [ mgr initializeFastConnectors ] ] ].
	^ true
]

{ #category : 'actions' }
GbsConfiguration class >> removeInvalidConnectors [
	| cfg |
	cfg := self current.
	cfg valueAt: #removeInvalidConnectors put: true.
	(Smalltalk at: #GbsSessionManager ifAbsent: [ nil ])
		ifNotNil: [ :mgr |
			(mgr respondsTo: #removeInvalidConnectors)
				ifTrue: [ mgr removeInvalidConnectors ] ].
	^ true
]

{ #category : 'initialization' }
GbsConfiguration >> initializeDefaults [
	libraryName ifNil: [ libraryName := '' ].
	bulkLoad ifNil: [ bulkLoad := false ].
	initialDirtyPoolSize ifNil: [ initialDirtyPoolSize := 157 ].
	connectorNilling ifNil: [ connectorNilling := true ].
	connectVerification ifNil: [ connectVerification := true ].
	removeInvalidConnectors ifNil: [ removeInvalidConnectors := true ].
	connectorConnectionState ifNil: [ connectorConnectionState := 'connected' ].
	connectorRowSettings ifNil: [ connectorRowSettings := Dictionary new ].
	generateClassConnectors ifNil: [ generateClassConnectors := true ].
	generateClientClasses ifNil: [ generateClientClasses := true ].
	generateServerClasses ifNil: [ generateServerClasses := true ].
	assertionChecks ifNil: [ assertionChecks := false ].
	forwarderDebugging ifNil: [ forwarderDebugging := false ].
	stubDebugging ifNil: [ stubDebugging := false ].
	autoMarkDirty ifNil: [ autoMarkDirty := true ].
	blockReplicationEnabled ifNil: [ blockReplicationEnabled := true ].
	blockReplicationPolicy ifNil: [ blockReplicationPolicy := 'replicate' ].
	defaultFaultPolicy ifNil: [ defaultFaultPolicy := 'lazy' ].
	faultLevelRpc ifNil: [ faultLevelRpc := 4 ].
	freeSlotsOnStubbing ifNil: [ freeSlotsOnStubbing := true ].
	blockingProtocolRpc ifNil: [ blockingProtocolRpc := false ].
	socketWaitTimeout ifNil: [ socketWaitTimeout := 10 ].
	fullCompression ifNil: [ fullCompression := false ].
	traversalBufferSize ifNil: [ traversalBufferSize := 250000 ].
	eventPollingFrequency ifNil: [ eventPollingFrequency := 300 ].
	eventPriority ifNil: [ eventPriority := 3 ].
	confirm ifNil: [ confirm := true ].
	verbose ifNil: [ verbose := true ].
	postConnectAction ifNil: [ postConnectAction := 'none' ]
]

{ #category : 'accessing' }
GbsConfiguration >> valueAt: ivarName ifAbsent: defaultValue [
	^ [ self instVarNamed: ivarName ]
		on: Error
		do: [ defaultValue ]
]

{ #category : 'accessing' }
GbsConfiguration >> valueAt: ivarName put: value [
	^ [ self instVarNamed: ivarName put: value ]
		on: Error
		do: [ value ]
]
