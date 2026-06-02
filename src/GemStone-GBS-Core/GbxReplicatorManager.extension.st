Extension { #name : 'GbxReplicatorManager' }

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> currentReplicationScheme [
	^ self clampManager currentReplicationScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> defaultReplicationSpecSet [
	^ self clampManager defaultReplicationSpecSet
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> defaultReplicationSpecSet: aSymbol [
	^ self clampManager defaultReplicationSpecSet: aSymbol
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> identityClamps [
	^ self clampManager identityClamps
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> invalidateSchemeWithSelector: aSelector [
	^ self clampManager invalidateSchemeWithSelector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> newClampManagerFor: aSession [
	| clampClass |
	aSession ifNil: [ ^ nil ].
	clampClass := (aSession respondsTo: #clampManagerClass)
		ifTrue: [ aSession clampManagerClass ]
		ifFalse: [ GbxClampManager ].
	^ clampClass forManager: self
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> replicationSchemeForSet: setSymbol [
	^ self clampManager replicationSchemeForSet: setSymbol
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> usingReplicationSpecSet: setSymbol do: aBlock [
	^ self clampManager usingReplicationSpecSet: setSymbol do: aBlock
]
