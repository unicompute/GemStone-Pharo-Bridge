Extension { #name : 'GbsSessionMaterializer' }

{ #category : 'metrics' }
GbsSessionMaterializer >> incrementMaterializationMetric: aSymbol [
	^ self incrementMaterializationMetric: aSymbol by: 1
]

{ #category : 'metrics' }
GbsSessionMaterializer >> incrementMaterializationMetric: aSymbol by: anInteger [
	| metrics value |
	metrics := self materializationMetrics.
	value := metrics at: aSymbol ifAbsent: [ 0 ].
	metrics at: aSymbol put: value + anInteger.
	^ metrics at: aSymbol
]

{ #category : 'metrics' }
GbsSessionMaterializer >> materializationBatchSize [
	| raw value env |
	raw := Smalltalk globals
		at: #GbsMaterializationBatchSize
		ifAbsent: [
			env := [ Smalltalk os environment ]
				on: Error
				do: [ Dictionary new ].
			env at: 'GBS_MATERIALIZATION_BATCH_SIZE' ifAbsent: [ 1000 ] ].
	value := [ raw asInteger ]
		on: Error
		do: [ 1000 ].
	^ value <= 0 ifTrue: [ 1000 ] ifFalse: [ value ]
]

{ #category : 'metrics' }
GbsSessionMaterializer >> materializationMetrics [
	^ (session class weakRegistryNamed: #GbsSessionMaterializationMetricCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'metrics' }
GbsSessionMaterializer >> recordMillisecondsForMetric: aSymbol during: aBlock [
	| start result elapsed |
	start := Time millisecondClockValue.
	[
		result := aBlock value
	] ensure: [
		elapsed := Time millisecondClockValue - start.
		elapsed < 0 ifTrue: [ elapsed := elapsed + 86400000 ].
		self incrementMaterializationMetric: aSymbol by: elapsed ].
	^ result
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteArrayElementOopAt: anInteger ofOop: anOop [
	^ self remoteReader remoteArrayElementOopAt: anInteger ofOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteArrayElementOopsForOop: anOop [
	^ self remoteReader remoteArrayElementOopsForOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteAssociationOopPairForOop: anOop [
	^ self remoteReader remoteAssociationOopPairForOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteAssociationPairOopFor: anOop [
	^ self remoteReader remoteAssociationPairOopFor: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteClassNameForOop: anOop [
	^ self remoteReader remoteClassNameForOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteClassNamesForOops: oopCollection [
	^ self remoteReader remoteClassNamesForOops: oopCollection
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteCollectionAsArrayOop: anOop [
	^ self remoteReader remoteCollectionAsArrayOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteDictionaryAssociationOopPairsForOop: anOop [
	^ self remoteReader remoteDictionaryAssociationOopPairsForOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteDictionaryAssociationsAsArrayOop: anOop [
	^ self remoteReader remoteDictionaryAssociationsAsArrayOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteSizeForOop: anOop [
	^ self remoteReader remoteSizeForOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteStringValueForOop: anOop [
	^ self remoteReader remoteStringValueForOop: anOop
]

{ #category : 'metrics' }
GbsSessionMaterializer >> resetMaterializationMetrics [
	(session class weakRegistryNamed: #GbsSessionMaterializationMetricCaches)
		at: session
		put: Dictionary new.
	^ self materializationMetrics
]
