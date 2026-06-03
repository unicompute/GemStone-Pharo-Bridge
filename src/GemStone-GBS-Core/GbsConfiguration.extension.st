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
GbsConfiguration >> bridgeSettings [
	^ self class bridgeSettingsRegistry
		at: self
		ifAbsentPut: [ Dictionary new ]
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
GbsConfiguration >> storeTraversalTransport: aString [
	^ self bridgeValueAt: #storeTraversalTransport put: aString
]
