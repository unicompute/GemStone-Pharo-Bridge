Class {
	#name : 'GbsReplicationPolicy',
	#superclass : 'Object',
	#instVars : [
		'autoMarkDirty',
		'blockReplicationPolicy',
		'defaultFaultPolicy',
		'asyncSignalPollingEnabled',
		'eventPollingFrequency',
		'eventPriority',
		'faultLevelRpc',
		'freeOopBatchSize',
		'freeSlotsOnStubbing',
		'serverMapMode',
		'storeTraversalTransport',
		'traversalBufferSize'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsReplicationPolicy class >> default [
	^ self new initializeDefaults
]

{ #category : 'instance creation' }
GbsReplicationPolicy class >> forSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionReplicationPolicies)
		at: aSession
		ifAbsentPut: [ self default ]
]

{ #category : 'instance creation' }
GbsReplicationPolicy class >> forSession: aSession put: aPolicy [
	^ (aSession class weakRegistryNamed: #GbsSessionReplicationPolicies)
		at: aSession
		put: aPolicy
]

{ #category : 'instance creation' }
GbsReplicationPolicy class >> fromConfiguration: aConfiguration [
	^ self new
		initializeFromConfiguration: aConfiguration;
		yourself
]

{ #category : 'instance creation' }
GbsReplicationPolicy class >> resetForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionReplicationPolicies)
		removeKey: aSession
		ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbsReplicationPolicy >> asyncSignalPollingEnabled [
	^ asyncSignalPollingEnabled
]

{ #category : 'accessing' }
GbsReplicationPolicy >> asyncSignalPollingEnabled: aBoolean [
	asyncSignalPollingEnabled := aBoolean
]

{ #category : 'diagnostics' }
GbsReplicationPolicy >> asDictionary [
	^ Dictionary new
		at: #autoMarkDirty put: self autoMarkDirty;
		at: #blockReplicationPolicy put: self blockReplicationPolicy;
		at: #defaultFaultPolicy put: self defaultFaultPolicy;
		at: #asyncSignalPollingEnabled put: self asyncSignalPollingEnabled;
		at: #eventPollingFrequency put: self eventPollingFrequency;
		at: #eventPriority put: self eventPriority;
		at: #faultLevelRpc put: self faultLevelRpc;
		at: #freeOopBatchSize put: self freeOopBatchSize;
		at: #freeSlotsOnStubbing put: self freeSlotsOnStubbing;
		at: #serverMapMode put: self serverMapMode;
		at: #storeTraversalTransport put: self storeTraversalTransport;
		at: #traversalBufferSize put: self traversalBufferSize;
		yourself
]

{ #category : 'accessing' }
GbsReplicationPolicy >> autoMarkDirty [
	^ autoMarkDirty
]

{ #category : 'accessing' }
GbsReplicationPolicy >> autoMarkDirty: aBoolean [
	autoMarkDirty := aBoolean
]

{ #category : 'accessing' }
GbsReplicationPolicy >> blockReplicationPolicy [
	^ blockReplicationPolicy
]

{ #category : 'accessing' }
GbsReplicationPolicy >> blockReplicationPolicy: aString [
	self
		validatePolicyValue: aString
		allowed: #(#replicate #callback #stub #none)
		label: 'Block replication policy'.
	blockReplicationPolicy := aString
]

{ #category : 'accessing' }
GbsReplicationPolicy >> blockReplicationPolicySymbol [
	^ self
		normalizedPolicySymbolFrom: blockReplicationPolicy
		allowed: #(#replicate #callback #stub #none)
		default: #replicate
]

{ #category : 'accessing' }
GbsReplicationPolicy >> defaultFaultPolicy [
	^ defaultFaultPolicy
]

{ #category : 'accessing' }
GbsReplicationPolicy >> defaultFaultPolicy: aString [
	self
		validatePolicyValue: aString
		allowed: #(#lazy #immediate #eager #none)
		label: 'Default fault policy'.
	defaultFaultPolicy := aString
]

{ #category : 'accessing' }
GbsReplicationPolicy >> defaultFaultPolicySymbol [
	| symbol |
	symbol := self
		normalizedPolicySymbolFrom: defaultFaultPolicy
		allowed: #(#lazy #immediate #eager #none)
		default: #lazy.
	symbol = #eager ifTrue: [ ^ #immediate ].
	^ symbol
]

{ #category : 'accessing' }
GbsReplicationPolicy >> eventPollingFrequency [
	^ eventPollingFrequency
]

{ #category : 'accessing' }
GbsReplicationPolicy >> eventPollingFrequency: anInteger [
	eventPollingFrequency := anInteger
]

{ #category : 'accessing' }
GbsReplicationPolicy >> eventPriority [
	^ eventPriority
]

{ #category : 'accessing' }
GbsReplicationPolicy >> eventPriority: anInteger [
	eventPriority := anInteger
]

{ #category : 'accessing' }
GbsReplicationPolicy >> faultLevelRpc [
	^ faultLevelRpc
]

{ #category : 'accessing' }
GbsReplicationPolicy >> faultLevelRpc: anInteger [
	faultLevelRpc := anInteger
]

{ #category : 'accessing' }
GbsReplicationPolicy >> freeOopBatchSize [
	^ freeOopBatchSize
]

{ #category : 'accessing' }
GbsReplicationPolicy >> freeOopBatchSize: anInteger [
	freeOopBatchSize := anInteger
]

{ #category : 'accessing' }
GbsReplicationPolicy >> freeSlotsOnStubbing [
	^ freeSlotsOnStubbing
]

{ #category : 'accessing' }
GbsReplicationPolicy >> freeSlotsOnStubbing: aBoolean [
	freeSlotsOnStubbing := aBoolean
]

{ #category : 'initialization' }
GbsReplicationPolicy >> initializeDefaults [
	^ self initializeFromConfiguration: ([ GbsConfiguration current ] on: Error do: [ nil ])
]

{ #category : 'initialization' }
GbsReplicationPolicy >> initializeFromConfiguration: aConfiguration [
	autoMarkDirty := self valueAt: #autoMarkDirty fromConfiguration: aConfiguration default: true.
	blockReplicationPolicy := self valueAt: #blockReplicationPolicy fromConfiguration: aConfiguration default: 'replicate'.
	defaultFaultPolicy := self valueAt: #defaultFaultPolicy fromConfiguration: aConfiguration default: 'lazy'.
	asyncSignalPollingEnabled := self valueAt: #asyncSignalPollingEnabled fromConfiguration: aConfiguration default: false.
	eventPollingFrequency := self valueAt: #eventPollingFrequency fromConfiguration: aConfiguration default: 300.
	eventPriority := self valueAt: #eventPriority fromConfiguration: aConfiguration default: 3.
	faultLevelRpc := self valueAt: #faultLevelRpc fromConfiguration: aConfiguration default: 4.
	freeOopBatchSize := self valueAt: #freeOopBatchSize fromConfiguration: aConfiguration default: 256.
	freeSlotsOnStubbing := self valueAt: #freeSlotsOnStubbing fromConfiguration: aConfiguration default: true.
	serverMapMode := self valueAt: #serverMapMode fromConfiguration: aConfiguration default: 'weak'.
	storeTraversalTransport := self valueAt: #storeTraversalTransport fromConfiguration: aConfiguration default: 'script'.
	traversalBufferSize := self valueAt: #traversalBufferSize fromConfiguration: aConfiguration default: 250000.
	^ self
]

{ #category : 'accessing' }
GbsReplicationPolicy >> serverMapMode [
	^ serverMapMode
]

{ #category : 'accessing' }
GbsReplicationPolicy >> serverMapMode: aString [
	self
		validatePolicyValue: aString
		allowed: #(#weak #strong)
		label: 'Server map mode'.
	serverMapMode := aString
]

{ #category : 'accessing' }
GbsReplicationPolicy >> serverMapModeSymbol [
	^ self
		normalizedPolicySymbolFrom: serverMapMode
		allowed: #(#weak #strong)
		default: #weak
]

{ #category : 'diagnostics' }
GbsReplicationPolicy >> reportText [
	| report |
	report := self asDictionary.
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Replication Policy'; cr; cr.
		#(
			autoMarkDirty
			blockReplicationPolicy
			defaultFaultPolicy
			faultLevelRpc
			freeSlotsOnStubbing
			storeTraversalTransport
			serverMapMode
			freeOopBatchSize
			traversalBufferSize
			asyncSignalPollingEnabled
			eventPollingFrequency
			eventPriority) do: [ :key |
				stream
					nextPutAll: key asString;
					nextPutAll: '=';
					nextPutAll: (self reportValueString: (report at: key));
					cr ] ]
]

{ #category : 'private' }
GbsReplicationPolicy >> reportValueString: anObject [
	anObject ifNil: [ ^ 'nil' ].
	anObject == true ifTrue: [ ^ 'true' ].
	anObject == false ifTrue: [ ^ 'false' ].
	anObject isSymbol ifTrue: [ ^ anObject asString ].
	^ anObject printString
]

{ #category : 'accessing' }
GbsReplicationPolicy >> storeTraversalTransport [
	^ storeTraversalTransport
]

{ #category : 'accessing' }
GbsReplicationPolicy >> storeTraversalTransport: aString [
	self
		validatePolicyValue: aString
		allowed: #(#script #binary #binaryRequired)
		label: 'Store traversal transport'.
	storeTraversalTransport := aString
]

{ #category : 'accessing' }
GbsReplicationPolicy >> storeTraversalTransportSymbol [
	^ self
		normalizedPolicySymbolFrom: storeTraversalTransport
		allowed: #(#script #binary #binaryRequired)
		default: #script
]

{ #category : 'accessing' }
GbsReplicationPolicy >> traversalBufferSize [
	^ traversalBufferSize
]

{ #category : 'accessing' }
GbsReplicationPolicy >> traversalBufferSize: anInteger [
	traversalBufferSize := anInteger
]

{ #category : 'private' }
GbsReplicationPolicy >> normalizedPolicySymbolFrom: aValue allowed: allowedSymbols default: defaultSymbol [
	| symbol |
	aValue ifNil: [ ^ defaultSymbol ].
	symbol := aValue asSymbol.
	(allowedSymbols includes: symbol) ifFalse: [ ^ defaultSymbol ].
	^ symbol
]

{ #category : 'private' }
GbsReplicationPolicy >> valueAt: selector fromConfiguration: aConfiguration default: defaultValue [
	aConfiguration ifNil: [ ^ defaultValue ].
	(aConfiguration respondsTo: selector) ifTrue: [
		^ [ aConfiguration perform: selector ] on: Error do: [ defaultValue ] ].
	(aConfiguration respondsTo: #valueAt:ifAbsent:) ifTrue: [
		^ aConfiguration valueAt: selector ifAbsent: defaultValue ].
	^ defaultValue
]

{ #category : 'private' }
GbsReplicationPolicy >> validatePolicyValue: aValue allowed: allowedSymbols label: labelString [
	| symbol |
	aValue ifNil: [ ^ self ].
	symbol := aValue asSymbol.
	(allowedSymbols includes: symbol) ifTrue: [ ^ self ].
	self error: labelString, ' must be one of ', allowedSymbols printString
]
