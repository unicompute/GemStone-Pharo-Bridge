Extension { #name : 'GbsConfiguration' }

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration class >> bridgeSettingsRegistry [
	| registryClass |
	^ Smalltalk globals
		at: #GbsConfigurationBridgeSettings
		ifAbsentPut: [
			registryClass := Smalltalk globals at: #WeakIdentityKeyDictionary ifAbsent: [ nil ].
			registryClass ifNil: [ IdentityDictionary new ] ifNotNil: [ registryClass new ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> asyncSignalPollingEnabled [
	^ self bridgeValueAt: #asyncSignalPollingEnabled ifAbsent: false
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> asyncSignalPollingEnabled: aBoolean [
	^ self bridgeValueAt: #asyncSignalPollingEnabled put: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration class >> bridgeOnlySettingKeys [
	"Keys backed by the per-instance bridgeSettings dictionary rather than by a
	converted instance variable. The converted #valueAt:put:/#valueAt:ifAbsent:
	store into instVarNamed:, which silently no-ops for these keys (there is no
	matching ivar), so generic valueAt: access must be routed to the bridge
	accessors to share one source of truth with the typed accessors and with
	GbsReplicationPolicy reads."
	^ #( asyncSignalPollingEnabled freeOopAllocationBatchSize freeOopBatchSize
		nativeStoreTraversalShapeValidationEnabled serverMapLeafCapacity
		serverMapMode storeDirtyOnCommit storeTraversalTransport
		strictMutationProtectionEnabled )
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> bridgeSettings [
	^ self class bridgeSettingsRegistry
		at: self
		ifAbsentPut: [ Dictionary new ]
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> valueAt: ivarName ifAbsent: defaultValue [
	"Route bridge-only keys to the bridge settings dictionary; otherwise use the
	converted instance-variable behaviour."
	(self class bridgeOnlySettingKeys includes: ivarName asSymbol)
		ifTrue: [ ^ self bridgeValueAt: ivarName asSymbol ifAbsent: defaultValue ].
	^ [ self instVarNamed: ivarName ] on: Error do: [ defaultValue ]
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> valueAt: ivarName put: value [
	"Route bridge-only keys to the bridge settings dictionary; otherwise use the
	converted instance-variable behaviour."
	(self class bridgeOnlySettingKeys includes: ivarName asSymbol)
		ifTrue: [ ^ self bridgeValueAt: ivarName asSymbol put: value ].
	^ [ self instVarNamed: ivarName put: value ] on: Error do: [ value ]
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> bridgeValueAt: aKey ifAbsent: defaultValue [
	^ self bridgeSettings at: aKey ifAbsent: [ defaultValue ]
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> bridgeValueAt: aKey put: aValue [
	self bridgeSettings at: aKey put: aValue.
	^ aValue
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> freeOopBatchSize [
	^ self bridgeValueAt: #freeOopBatchSize ifAbsent: 256
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> freeOopBatchSize: anInteger [
	^ self bridgeValueAt: #freeOopBatchSize put: anInteger
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> freeOopAllocationBatchSize [
	^ self bridgeValueAt: #freeOopAllocationBatchSize ifAbsent: 2000
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> freeOopAllocationBatchSize: anInteger [
	^ self bridgeValueAt: #freeOopAllocationBatchSize put: anInteger
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> nativeStoreTraversalShapeValidationEnabled [
	^ self bridgeValueAt: #nativeStoreTraversalShapeValidationEnabled ifAbsent: true
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> nativeStoreTraversalShapeValidationEnabled: aBoolean [
	^ self bridgeValueAt: #nativeStoreTraversalShapeValidationEnabled put: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> serverMapLeafCapacity [
	^ self bridgeValueAt: #serverMapLeafCapacity ifAbsent: 300
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> serverMapLeafCapacity: anInteger [
	^ self bridgeValueAt: #serverMapLeafCapacity put: anInteger
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> serverMapMode [
	^ self bridgeValueAt: #serverMapMode ifAbsent: 'weak'
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> serverMapMode: aString [
	^ self bridgeValueAt: #serverMapMode put: aString
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> storeTraversalTransport [
	^ self bridgeValueAt: #storeTraversalTransport ifAbsent: 'script'
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> storeDirtyOnCommit [
	^ self bridgeValueAt: #storeDirtyOnCommit ifAbsent: false
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> storeDirtyOnCommit: aBoolean [
	^ self bridgeValueAt: #storeDirtyOnCommit put: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> strictMutationProtectionEnabled [
	^ self bridgeValueAt: #strictMutationProtectionEnabled ifAbsent: false
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> strictMutationProtectionEnabled: aBoolean [
	^ self bridgeValueAt: #strictMutationProtectionEnabled put: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsConfiguration >> storeTraversalTransport: aString [
	^ self bridgeValueAt: #storeTraversalTransport put: aString
]
