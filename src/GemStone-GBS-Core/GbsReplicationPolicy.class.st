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
		'storeDirtyOnCommit',
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

{ #category : 'configuration metadata' }
GbsReplicationPolicy class >> addSetting: key category: category default: defaultValue legalValues: legalValues help: helpText to: specs [
	specs add: (Dictionary new
		at: #key put: key;
		at: #category put: category;
		at: #default put: defaultValue;
		at: #legalValues put: legalValues;
		at: #help put: helpText;
		yourself)
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

{ #category : 'configuration metadata' }
GbsReplicationPolicy class >> settingSpecificationAt: aSymbol [
	^ self settingSpecifications
		detect: [ :each | (each at: #key) = aSymbol ]
		ifNone: [ nil ]
]

{ #category : 'configuration metadata' }
GbsReplicationPolicy class >> defaultValueForSetting: aSymbol [
	^ (self settingSpecificationAt: aSymbol)
		ifNil: [ nil ]
		ifNotNil: [ :spec | spec at: #default ]
]

{ #category : 'configuration metadata' }
GbsReplicationPolicy class >> helpForSetting: aSymbol [
	^ (self settingSpecificationAt: aSymbol)
		ifNil: [ '' ]
		ifNotNil: [ :spec | spec at: #help ]
]

{ #category : 'configuration metadata' }
GbsReplicationPolicy class >> legalValuesForSetting: aSymbol [
	^ (self settingSpecificationAt: aSymbol)
		ifNil: [ #() ]
		ifNotNil: [ :spec | spec at: #legalValues ]
]

{ #category : 'configuration metadata' }
GbsReplicationPolicy class >> settingSpecifications [
	| specs |
	specs := OrderedCollection new.
	self addSetting: #autoMarkDirty category: #replication default: true legalValues: #(true false) help: 'Automatically mark replicated client objects dirty when bridge mutation hooks see a local write.' to: specs.
	self addSetting: #blockReplicationPolicy category: #replication default: 'replicate' legalValues: #('replicate' 'callback' 'stub' 'none') help: 'Default replication behavior for block-like server objects.' to: specs.
	self addSetting: #defaultFaultPolicy category: #replication default: 'lazy' legalValues: #('lazy' 'immediate' 'eager' 'none') help: 'Default policy used when a proxy or stub is faulted into a local replicate.' to: specs.
	self addSetting: #faultLevelRpc category: #replication default: 4 legalValues: #() help: 'Fallback RPC fault level used by compatibility paths that ask the server to expand object graphs.' to: specs.
	self addSetting: #freeSlotsOnStubbing category: #lifecycle default: true legalValues: #(true false) help: 'Clear local object slots when a materialized object is replaced with a stub.' to: specs.
	self addSetting: #storeDirtyOnCommit category: #replication default: false legalValues: #(true false) help: 'Flush dirty replicated objects and pending export-set releases before a successful GemStone commit.' to: specs.
	self addSetting: #storeTraversalTransport category: #replication default: 'script' legalValues: #('script' 'binary' 'binaryRequired') help: 'Transport used for dirty writes: script fallback, native binary when possible, or native binary required.' to: specs.
	self addSetting: #serverMapMode category: #lifecycle default: 'weak' legalValues: #('weak' 'strong') help: 'Client-side server map retention mode. Native store traversal temporarily uses a strong window even when the steady-state map is weak.' to: specs.
	self addSetting: #freeOopBatchSize category: #lifecycle default: 256 legalValues: #() help: 'Maximum number of pending no-longer-replicated or GCed OOPs drained in one lifecycle batch.' to: specs.
	self addSetting: #traversalBufferSize category: #performance default: 250000 legalValues: #() help: 'Preferred traversal buffer size for native materialization and store traversal paths.' to: specs.
	self addSetting: #asyncSignalPollingEnabled category: #signals default: false legalValues: #(true false) help: 'Start a background GemStone signal poller after login.' to: specs.
	self addSetting: #eventPollingFrequency category: #signals default: 300 legalValues: #() help: 'Delay in milliseconds between background GemStone signal polls.' to: specs.
	self addSetting: #eventPriority category: #signals default: 3 legalValues: #() help: 'Pharo process priority used by the background GemStone signal poller.' to: specs.
	^ specs asArray
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
		at: #storeDirtyOnCommit put: self storeDirtyOnCommit;
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
	storeDirtyOnCommit := self valueAt: #storeDirtyOnCommit fromConfiguration: aConfiguration default: false.
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
			storeDirtyOnCommit
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
GbsReplicationPolicy >> storeDirtyOnCommit [
	^ storeDirtyOnCommit
]

{ #category : 'accessing' }
GbsReplicationPolicy >> storeDirtyOnCommit: aBoolean [
	storeDirtyOnCommit := aBoolean
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
