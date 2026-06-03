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
GbsSessionMaterializer >> incrementMaterializationMetric: metricSymbol forClassName: className [
	| metrics values key count |
	metrics := self materializationMetrics.
	values := metrics at: metricSymbol ifAbsentPut: [ Dictionary new ].
	key := className ifNil: [ '<nil>' ] ifNotNil: [ className asString ].
	count := values at: key ifAbsent: [ 0 ].
	values at: key put: count + 1.
	^ values
]

{ #category : 'metrics' }
GbsSessionMaterializer >> materializationBatchSize [
	| batchSize |
	batchSize := self
		materializationLimitFromSessionSelector: #materializationBatchSize
		global: #GbsMaterializationBatchSize
		environmentName: 'GBS_MATERIALIZATION_BATCH_SIZE'
		default: 1000.
	^ batchSize <= 0 ifTrue: [ 1000 ] ifFalse: [ batchSize ]
]

{ #category : 'metrics' }
GbsSessionMaterializer >> materializationLimitFromSessionSelector: selector global: globalSymbol environmentName: environmentName default: defaultValue [
	| raw |
	raw := self materializationSessionLimitFor: selector.
	raw ifNotNil: [
		^ self normalizedMaterializationLimitFrom: raw default: defaultValue ].
	^ self
		materializationLimitFromGlobal: globalSymbol
		environmentName: environmentName
		default: defaultValue
]

{ #category : 'metrics' }
GbsSessionMaterializer >> materializationSessionLimitFor: selector [
	| parameters |
	parameters := [
		(session respondsTo: #parameters)
			ifTrue: [ session parameters ]
			ifFalse: [ nil ] ]
		on: Error
		do: [ nil ].
	parameters ifNil: [ ^ nil ].
	(parameters respondsTo: selector) ifFalse: [ ^ nil ].
	^ parameters perform: selector
]

{ #category : 'metrics' }
GbsSessionMaterializer >> normalizedMaterializationLimitFrom: rawValue default: defaultValue [
	| value |
	value := [ rawValue asInteger ]
		on: Error
		do: [ defaultValue ].
	^ value < 0 ifTrue: [ defaultValue ] ifFalse: [ value ]
]

{ #category : 'metrics' }
GbsSessionMaterializer >> materializationLimitFromGlobal: globalSymbol environmentName: environmentName default: defaultValue [
	| raw value env |
	raw := Smalltalk globals
		at: globalSymbol
		ifAbsent: [
			env := [ Smalltalk os environment ]
				on: Error
				do: [ Dictionary new ].
			env at: environmentName ifAbsent: [ defaultValue ] ].
	value := [ raw asInteger ]
		on: Error
		do: [ defaultValue ].
	^ value < 0 ifTrue: [ defaultValue ] ifFalse: [ value ]
]

{ #category : 'limits' }
GbsSessionMaterializer >> materializationMaxBatchBytes [
	^ self
		materializationLimitFromSessionSelector: #materializationMaxBatchBytes
		global: #GbsMaterializationMaxBatchBytes
		environmentName: 'GBS_MATERIALIZATION_MAX_BATCH_BYTES'
		default: 0
]

{ #category : 'limits' }
GbsSessionMaterializer >> materializationMaxDepth [
	^ self
		materializationLimitFromSessionSelector: #materializationMaxDepth
		global: #GbsMaterializationMaxDepth
		environmentName: 'GBS_MATERIALIZATION_MAX_DEPTH'
		default: 0
]

{ #category : 'limits' }
GbsSessionMaterializer >> materializationMaxFrontierOops [
	^ self
		materializationLimitFromSessionSelector: #materializationMaxFrontierOops
		global: #GbsMaterializationMaxFrontierOops
		environmentName: 'GBS_MATERIALIZATION_MAX_FRONTIER_OOPS'
		default: 0
]

{ #category : 'limits' }
GbsSessionMaterializer >> materializationMaxObjects [
	^ self
		materializationLimitFromSessionSelector: #materializationMaxObjects
		global: #GbsMaterializationMaxObjects
		environmentName: 'GBS_MATERIALIZATION_MAX_OBJECTS'
		default: 0
]

{ #category : 'limits' }
GbsSessionMaterializer >> checkMaterializationBatchBytes: byteCount label: aString [
	| maxBytes |
	maxBytes := self materializationMaxBatchBytes.
	(maxBytes > 0 and: [ byteCount > maxBytes ]) ifTrue: [
		GbsMaterializationLimitError
			signalKind: #batchBytes
			observed: byteCount
			limit: maxBytes
			label: aString ].
	^ byteCount
]

{ #category : 'limits' }
GbsSessionMaterializer >> checkMaterializationDepth: anInteger [
	| maxDepth |
	maxDepth := self materializationMaxDepth.
	(maxDepth > 0 and: [ anInteger > maxDepth ]) ifTrue: [
		GbsMaterializationLimitError
			signalKind: #depth
			observed: anInteger
			limit: maxDepth
			label: 'object graph depth' ].
	^ anInteger
]

{ #category : 'limits' }
GbsSessionMaterializer >> checkMaterializationFrontierSize: oopCount label: aString [
	| maxOops |
	maxOops := self materializationMaxFrontierOops.
	(maxOops > 0 and: [ oopCount > maxOops ]) ifTrue: [
		GbsMaterializationLimitError
			signalKind: #frontierOops
			observed: oopCount
			limit: maxOops
			label: aString ].
	^ oopCount
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

{ #category : 'cache' }
GbsSessionMaterializer >> materializedObjectCache [
	^ (session class weakRegistryNamed: #GbsSessionMaterializedObjectCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'cache' }
GbsSessionMaterializer >> materializedObjectForOop: anOop [
	^ self materializedObjectForOop: anOop ifPresent: [ :object | object ]
]

{ #category : 'cache' }
GbsSessionMaterializer >> materializedObjectForOop: anOop ifPresent: aBlock [
	| cache object |
	cache := self materializedObjectCache.
	(cache includesKey: anOop) ifTrue: [
		self incrementMaterializationMetric: #materializedObjectTraversalCacheHits.
		^ aBlock value: (cache at: anOop) ].
	object := self persistentMaterializedObjectCache at: anOop ifAbsent: [ nil ].
	object ifNotNil: [
		self incrementMaterializationMetric: #materializedObjectSessionCacheHits.
		self rememberMaterializedObjectInTraversalCache: object forOop: anOop.
		self registerMaterializedObject: object forOop: anOop.
		^ aBlock value: object ].
	^ nil
]

{ #category : 'cache' }
GbsSessionMaterializer >> rememberMaterializedObject: anObject forOop: anOop [
	self rememberMaterializedObjectInTraversalCache: anObject forOop: anOop.
	self persistentMaterializedObjectCache at: anOop put: anObject.
	self registerMaterializedObject: anObject forOop: anOop.
	^ anObject
]

{ #category : 'cache' }
GbsSessionMaterializer >> rememberMaterializedObjectInTraversalCache: anObject forOop: anOop [
	| cache maxObjects |
	cache := self materializedObjectCache.
	(cache includesKey: anOop) ifFalse: [
		maxObjects := self materializationMaxObjects.
		(maxObjects > 0 and: [ cache size + 1 > maxObjects ]) ifTrue: [
			GbsMaterializationLimitError
				signalKind: #objects
				observed: cache size + 1
				limit: maxObjects
				label: 'materialized object cache' ] ].
	cache at: anOop put: anObject.
	^ anObject
]

{ #category : 'cache' }
GbsSessionMaterializer >> registerMaterializedObject: anObject forOop: anOop [
	(session respondsTo: #registerMaterializedObject:forOop:) ifTrue: [
		session registerMaterializedObject: anObject forOop: anOop ].
	^ anObject
]

{ #category : 'cache' }
GbsSessionMaterializer >> resetMaterializedObjectCache [
	self resetMaterializedObjectTraversalCache.
	self resetPersistentMaterializedObjectCache.
	^ self materializedObjectCache
]

{ #category : 'cache' }
GbsSessionMaterializer >> resetMaterializedObjectTraversalCache [
	(session class weakRegistryNamed: #GbsSessionMaterializedObjectCaches)
		at: session
		put: Dictionary new.
	^ self materializedObjectCache
]

{ #category : 'cache' }
GbsSessionMaterializer >> persistentMaterializedObjectCache [
	^ (session class weakRegistryNamed: #GbsSessionPersistentMaterializedObjectCaches)
		at: session
		ifAbsentPut: [ self weakValueDictionary ]
]

{ #category : 'cache' }
GbsSessionMaterializer >> resetPersistentMaterializedObjectCache [
	(session class weakRegistryNamed: #GbsSessionPersistentMaterializedObjectCaches)
		at: session
		put: self weakValueDictionary.
	^ self persistentMaterializedObjectCache
]

{ #category : 'cache' }
GbsSessionMaterializer >> weakValueDictionary [
	| dictionaryClass |
	dictionaryClass := Smalltalk globals at: #WeakValueDictionary ifAbsent: [ Dictionary ].
	^ dictionaryClass new
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializationKindForClassNamed: className [
	className = 'Array' ifTrue: [ ^ #array ].
	(#('OrderedCollection' 'SortedCollection' 'Bag' 'Set' 'IdentitySet') includes: className)
		ifTrue: [ ^ #sequenceable ].
	(#('Dictionary' 'IdentityDictionary') includes: className) ifTrue: [ ^ #dictionary ].
	className = 'Association' ifTrue: [ ^ #association ].
	^ #proxy
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeSequenceableItems: items className: className [
	className = 'OrderedCollection' ifTrue: [ ^ items asOrderedCollection ].
	className = 'SortedCollection' ifTrue: [ ^ items asSortedCollection ].
	className = 'Bag' ifTrue: [
		| bag |
		bag := Bag new.
		items do: [ :each | bag add: each ].
		^ bag ].
	className = 'Set' ifTrue: [ ^ items asSet ].
	className = 'IdentitySet' ifTrue: [
		| set |
		set := IdentitySet new.
		items do: [ :each | set add: each ].
		^ set ].
	^ items
]

{ #category : 'materializing' }
GbsSessionMaterializer >> emptySequenceableCollectionForClassNamed: className [
	className = 'OrderedCollection' ifTrue: [ ^ OrderedCollection new ].
	className = 'SortedCollection' ifTrue: [ ^ SortedCollection new ].
	className = 'Bag' ifTrue: [ ^ Bag new ].
	className = 'Set' ifTrue: [ ^ Set new ].
	className = 'IdentitySet' ifTrue: [ ^ IdentitySet new ].
	^ OrderedCollection new
]

{ #category : 'materializing' }
GbsSessionMaterializer >> fillSequenceableCollection: aCollection withItems: items className: className [
	items do: [ :each | aCollection add: each ].
	^ aCollection
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeScalarOops: oopCollection classNames: classNames [
	| stringOops byteArrayOops stringValues byteArrayValues materialized |
	stringOops := OrderedCollection new.
	byteArrayOops := OrderedCollection new.
	oopCollection do: [ :oop |
		(classNames at: oop) = 'ByteArray'
			ifTrue: [ byteArrayOops add: oop ]
			ifFalse: [ stringOops add: oop ] ].
	stringValues := stringOops isEmpty
		ifTrue: [ Dictionary new ]
		ifFalse: [ self remoteStringValuesForOops: stringOops ].
	byteArrayValues := byteArrayOops isEmpty
		ifTrue: [ Dictionary new ]
		ifFalse: [ self remoteByteArrayValuesForOops: byteArrayOops ].
	materialized := Dictionary new.
	oopCollection do: [ :oop |
		| className value |
		className := classNames at: oop.
		className = 'ByteArray'
			ifTrue: [
				value := byteArrayValues
					at: oop
					ifAbsent: [
						self
							materializeByteArrayOop: oop
							withProfile: GbsProxyOnlyMaterializationProfile new
							depth: 0
							seen: IdentitySet new ] ]
			ifFalse: [
				value := stringValues
					at: oop
					ifAbsent: [ self remoteStringValueForOop: oop ].
				(className = 'Symbol' or: [ className = 'DoubleByteSymbol' ]) ifTrue: [
					value := value asSymbol ].
				className = 'DateTime' ifTrue: [
					value := DateAndTime readFrom: value readStream ] ].
		self rememberMaterializedObject: value forOop: oop.
		materialized at: oop put: value ].
	^ materialized
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeArrayOops: oopCollection withProfile: aProfile depth: anInteger seen: seenOops [
	| results assigned uniqueOops elementOopsByOop flatElementOops spans materializedFlat offset nestedProfile |
	self
		checkMaterializationFrontierSize: oopCollection size
		label: 'array batch roots'.
	results := Array new: oopCollection size.
	assigned := Array new: oopCollection size.
	1 to: assigned size do: [ :index | assigned at: index put: false ].
	uniqueOops := OrderedCollection new.
	oopCollection doWithIndex: [ :oop :index |
		(self materializedObjectForOop: oop ifPresent: [ :object |
			results at: index put: object.
			assigned at: index put: true.
			true ]) ifNil: [
			(uniqueOops includes: oop) ifFalse: [ uniqueOops add: oop ] ] ].
	uniqueOops isEmpty ifTrue: [ ^ results ].
	elementOopsByOop := self remoteArrayElementOopsForOops: uniqueOops.
	flatElementOops := OrderedCollection new.
	spans := Dictionary new.
	uniqueOops do: [ :oop |
		| elementOops materialized start |
		elementOops := elementOopsByOop
			at: oop
			ifAbsent: [ self remoteArrayElementOopsForOop: oop ].
		seenOops add: oop.
		materialized := Array new: elementOops size.
		self rememberMaterializedObject: materialized forOop: oop.
		start := flatElementOops size + 1.
		spans at: oop put: { start. elementOops size. materialized }.
		flatElementOops addAll: elementOops ].
	materializedFlat := flatElementOops isEmpty
		ifTrue: [ #() ]
		ifFalse: [
			nestedProfile := aProfile
				nestedProfileForIndexedPartOfClassNamed: 'Array'
				inSession: session
				depth: anInteger.
			self
				checkMaterializationFrontierSize: flatElementOops size
				label: 'array batch elements'.
			self
				materializeOops: flatElementOops asArray
				withProfile: nestedProfile
				depth: anInteger + 1
				seen: seenOops ].
	self withDirtyTrackingSuspendedDo: [
		uniqueOops do: [ :oop |
			| span size materialized |
			span := spans at: oop.
			offset := span first.
			size := span second.
			materialized := span third.
			1 to: size do: [ :elementIndex |
				materialized
					at: elementIndex
					put: (materializedFlat at: offset + elementIndex - 1) ] ] ].
	oopCollection doWithIndex: [ :oop :index |
		(assigned at: index) ifFalse: [
			results at: index put: (self materializedObjectForOop: oop).
			assigned at: index put: true ] ].
	^ results
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeSequenceableCollectionOops: oopCollection classNames: classNames withProfile: aProfile depth: anInteger seen: seenOops [
	| elementOopsByOop flatElementOops spans materializedFlat materializedByOop |
	self
		checkMaterializationFrontierSize: oopCollection size
		label: 'sequenceable collection batch roots'.
	elementOopsByOop := self remoteCollectionElementOopsForOops: oopCollection.
	flatElementOops := OrderedCollection new.
	spans := Dictionary new.
	oopCollection do: [ :oop |
		| elementOops start className materialized |
		elementOops := elementOopsByOop
			at: oop
			ifAbsent: [ self remoteCollectionElementOopsForOop: oop ].
		className := classNames at: oop.
		materialized := self emptySequenceableCollectionForClassNamed: className.
		self rememberMaterializedObject: materialized forOop: oop.
		seenOops add: oop.
		start := flatElementOops size + 1.
		spans at: oop put: { start. elementOops size. materialized. className }.
		flatElementOops addAll: elementOops ].
	materializedFlat := flatElementOops isEmpty
		ifTrue: [ #() ]
		ifFalse: [
			self
				checkMaterializationFrontierSize: flatElementOops size
				label: 'sequenceable collection elements'.
			self
				materializeOops: flatElementOops asArray
				withProfile: aProfile
				depth: anInteger + 1
				seen: seenOops ].
	materializedByOop := Dictionary new.
	self withDirtyTrackingSuspendedDo: [
		oopCollection do: [ :oop |
			| span size items materialized |
			span := spans at: oop.
			size := span second.
			items := Array new: size.
			1 to: size do: [ :elementIndex |
				items
					at: elementIndex
					put: (materializedFlat at: span first + elementIndex - 1) ].
			materialized := span third.
			self
				fillSequenceableCollection: materialized
				withItems: items
				className: span fourth.
			materializedByOop at: oop put: materialized ] ].
	^ materializedByOop
]

{ #category : 'materializing' }
GbsSessionMaterializer >> withDirtyTrackingSuspendedDo: aBlock [
	(session respondsTo: #withDirtyTrackingSuspendedDo:) ifTrue: [
		^ session withDirtyTrackingSuspendedDo: aBlock ].
	^ aBlock value
]

{ #category : 'cache' }
GbsSessionMaterializer >> clearTypedWrapperClassCache [
	(session class weakRegistryNamed: #GbsSessionTypedWrapperClassCaches)
		at: session
		put: Dictionary new.
	^ self typedWrapperClassCache
]

{ #category : 'cache' }
GbsSessionMaterializer >> typedWrapperClassCache [
	^ (session class weakRegistryNamed: #GbsSessionTypedWrapperClassCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'cache' }
GbsSessionMaterializer >> typedWrapperClassForServerClassName: className [
	| cache wrapperClass |
	cache := self typedWrapperClassCache.
	(cache includesKey: className) ifTrue: [
		self incrementMaterializationMetric: #wrapperCacheHits.
		self incrementMaterializationMetric: #wrapperCacheHitClassCounts forClassName: className.
		^ cache at: className ].
	wrapperClass := GbsSessionManager
		materializationFastTypedWrapperClassForServerClassNamed: className.
	wrapperClass ifNotNil: [
		self incrementMaterializationMetric: #wrapperFastConnectorHits.
		self incrementMaterializationMetric: #wrapperFastConnectorClassCounts forClassName: className.
		self incrementMaterializationMetric: #wrapperLookupTypedResults.
		self incrementMaterializationMetric: #wrapperLookupTypedClassCounts forClassName: className.
		cache at: className put: wrapperClass.
		^ wrapperClass ].
	self incrementMaterializationMetric: #wrapperLookupCalls.
	self incrementMaterializationMetric: #wrapperLookupMisses.
	self incrementMaterializationMetric: #wrapperLookupClassCounts forClassName: className.
	wrapperClass := self
		recordMillisecondsForMetric: #wrapperLookupMs
		during: [
			GbsSessionManager
				typedWrapperClassForServerClassNamed: className
				forSession: session ].
	wrapperClass
		ifNil: [
			self incrementMaterializationMetric: #wrapperLookupNilResults.
			self incrementMaterializationMetric: #wrapperLookupNilClassCounts forClassName: className ]
		ifNotNil: [
			self incrementMaterializationMetric: #wrapperLookupTypedResults.
			self incrementMaterializationMetric: #wrapperLookupTypedClassCounts forClassName: className ].
	cache at: className put: wrapperClass.
	^ wrapperClass
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeDictionaryOops: oopCollection classNames: classNames withProfile: aProfile depth: anInteger seen: seenOops [
	| associationPairsByOop dictionaries flatKeyOops flatValueOops spans keys values |
	self
		checkMaterializationFrontierSize: oopCollection size
		label: 'dictionary batch roots'.
	associationPairsByOop := self remoteDictionaryAssociationOopPairsForOops: oopCollection.
	dictionaries := Dictionary new.
	flatKeyOops := OrderedCollection new.
	flatValueOops := OrderedCollection new.
	spans := Dictionary new.
	oopCollection do: [ :oop |
		| className dictionary pairs start |
		className := classNames at: oop.
		dictionary := className = 'IdentityDictionary'
			ifTrue: [ IdentityDictionary new ]
			ifFalse: [ Dictionary new ].
		self rememberMaterializedObject: dictionary forOop: oop.
		dictionaries at: oop put: dictionary.
		seenOops add: oop.
		pairs := associationPairsByOop
			at: oop
			ifAbsent: [ self remoteDictionaryAssociationOopPairsForOop: oop ].
		start := flatKeyOops size + 1.
		spans at: oop put: { start. pairs size }.
		pairs do: [ :pair |
			flatKeyOops add: pair first.
			flatValueOops add: pair second ] ].
	keys := flatKeyOops isEmpty
		ifTrue: [ #() ]
		ifFalse: [
			self
				checkMaterializationFrontierSize: flatKeyOops size
				label: 'dictionary keys'.
			self
				materializeOops: flatKeyOops asArray
				withProfile: aProfile
				depth: anInteger + 1
				seen: seenOops ].
	values := flatValueOops isEmpty
		ifTrue: [ #() ]
		ifFalse: [
			self
				checkMaterializationFrontierSize: flatValueOops size
				label: 'dictionary values'.
			self
				materializeOops: flatValueOops asArray
				withProfile: aProfile
				depth: anInteger + 1
				seen: seenOops ].
	self withDirtyTrackingSuspendedDo: [
		oopCollection do: [ :oop |
			| span dictionary |
			span := spans at: oop.
			dictionary := dictionaries at: oop.
			1 to: span second do: [ :index |
				dictionary
					at: (keys at: span first + index - 1)
					put: (values at: span first + index - 1) ] ] ].
	^ dictionaries
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeAssociationOops: oopCollection withProfile: aProfile depth: anInteger seen: seenOops [
	| pairByOop flatKeyOops flatValueOops materializedKeys materializedValues materializedByOop associationsByOop keyProfile valueProfile |
	self
		checkMaterializationFrontierSize: oopCollection size
		label: 'association batch roots'.
	pairByOop := self remoteAssociationOopPairsForOops: oopCollection.
	flatKeyOops := OrderedCollection new.
	flatValueOops := OrderedCollection new.
	associationsByOop := Dictionary new.
	oopCollection do: [ :oop |
		| pair association |
		seenOops add: oop.
		association := Association new.
		self rememberMaterializedObject: association forOop: oop.
		associationsByOop at: oop put: association.
		pair := pairByOop
			at: oop
			ifAbsent: [ self remoteAssociationOopPairForOop: oop ].
		flatKeyOops add: pair first.
		flatValueOops add: pair second ].
	keyProfile := aProfile
		nestedProfileForNamedSlot: 1
		ofClassNamed: 'Association'
		inSession: session
		depth: anInteger.
	valueProfile := aProfile
		nestedProfileForNamedSlot: 2
		ofClassNamed: 'Association'
		inSession: session
		depth: anInteger.
	materializedKeys := flatKeyOops isEmpty
		ifTrue: [ #() ]
		ifFalse: [
			self
				checkMaterializationFrontierSize: flatKeyOops size
				label: 'association keys'.
			self
				materializeOops: flatKeyOops asArray
				withProfile: keyProfile
				depth: anInteger + 1
				seen: seenOops ].
	materializedValues := flatValueOops isEmpty
		ifTrue: [ #() ]
		ifFalse: [
			self
				checkMaterializationFrontierSize: flatValueOops size
				label: 'association values'.
			self
				materializeOops: flatValueOops asArray
				withProfile: valueProfile
				depth: anInteger + 1
				seen: seenOops ].
	materializedByOop := Dictionary new.
	self withDirtyTrackingSuspendedDo: [
		oopCollection doWithIndex: [ :oop :index |
			| association |
			association := associationsByOop at: oop.
			association
				key: (materializedKeys at: index);
				value: (materializedValues at: index).
			materializedByOop at: oop put: association ] ].
	^ materializedByOop
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeFrontierOops: oopCollection withProfile: aProfile depth: anInteger seen: seenOops [
	| results assigned missing classNames scalarOops arrayOops sequenceableOops dictionaryOops associationOops scalarObjects nestedProfile |
	self
		checkMaterializationFrontierSize: oopCollection size
		label: 'materialization frontier'.
	results := Array new: oopCollection size.
	assigned := Array new: oopCollection size.
	1 to: assigned size do: [ :index | assigned at: index put: false ].
	missing := OrderedCollection new.
	oopCollection doWithIndex: [ :oop :index |
		(self isImmediateOop: oop)
			ifTrue: [
				results at: index put: (self resultFor: oop).
				assigned at: index put: true ]
			ifFalse: [
				(self materializedObjectForOop: oop ifPresent: [ :object |
					results at: index put: object.
					assigned at: index put: true.
					true ]) ifNil: [
					(seenOops includes: oop)
						ifTrue: [
							results at: index put: (self proxyForOop: oop).
							assigned at: index put: true ]
						ifFalse: [
							(missing includes: oop) ifFalse: [ missing add: oop ] ] ] ] ].
	classNames := missing isEmpty
		ifTrue: [ Dictionary new ]
		ifFalse: [ self remoteClassNamesForOops: missing ].
	scalarOops := OrderedCollection new.
	arrayOops := OrderedCollection new.
	sequenceableOops := OrderedCollection new.
	dictionaryOops := OrderedCollection new.
	associationOops := OrderedCollection new.
	oopCollection doWithIndex: [ :oop :index |
		(assigned at: index) ifFalse: [
			| className kind |
			className := classNames at: oop ifAbsent: [ self remoteClassNameForOop: oop ].
			(aProfile shouldMaterializeScalarClassNamed: className)
				ifTrue: [
					(scalarOops includes: oop) ifFalse: [ scalarOops add: oop ] ]
				ifFalse: [
					(aProfile shouldMaterializeCollectionClassNamed: className depth: anInteger)
						ifFalse: [
							results at: index put: (self proxyForOop: oop serverClassName: className).
							assigned at: index put: true ]
						ifTrue: [
							kind := self materializationKindForClassNamed: className.
							kind = #array ifTrue: [
								(arrayOops includes: oop) ifFalse: [ arrayOops add: oop ] ].
							kind = #sequenceable ifTrue: [
								(sequenceableOops includes: oop) ifFalse: [ sequenceableOops add: oop ] ].
							kind = #dictionary ifTrue: [
								(dictionaryOops includes: oop) ifFalse: [ dictionaryOops add: oop ] ].
							kind = #association ifTrue: [
								(associationOops includes: oop) ifFalse: [ associationOops add: oop ] ].
							kind = #proxy ifTrue: [
								results at: index put: (self proxyForOop: oop serverClassName: className).
								assigned at: index put: true ] ] ] ] ].
	scalarOops isEmpty ifFalse: [
		scalarObjects := self materializeScalarOops: scalarOops classNames: classNames.
		scalarObjects associationsDo: [ :association |
			self rememberMaterializedObject: association value forOop: association key ] ].
	nestedProfile := aProfile nestedProfileForDepth: anInteger.
	arrayOops isEmpty ifFalse: [
		self
			materializeArrayOops: arrayOops asArray
			withProfile: nestedProfile
			depth: anInteger
			seen: seenOops ].
	sequenceableOops isEmpty ifFalse: [
		self
			materializeSequenceableCollectionOops: sequenceableOops asArray
			classNames: classNames
			withProfile: nestedProfile
			depth: anInteger
			seen: seenOops ].
	dictionaryOops isEmpty ifFalse: [
		self
			materializeDictionaryOops: dictionaryOops asArray
			classNames: classNames
			withProfile: nestedProfile
			depth: anInteger
			seen: seenOops ].
	associationOops isEmpty ifFalse: [
		self
			materializeAssociationOops: associationOops asArray
			withProfile: nestedProfile
			depth: anInteger
			seen: seenOops ].
	oopCollection doWithIndex: [ :oop :index |
		(assigned at: index) ifFalse: [
			self materializedObjectForOop: oop ifPresent: [ :object |
				results at: index put: object.
				assigned at: index put: true ].
			(assigned at: index) ifFalse: [
				| className |
				className := classNames at: oop ifAbsent: [ self remoteClassNameForOop: oop ].
				results at: index put: (self proxyForOop: oop serverClassName: className).
				assigned at: index put: true ] ] ].
	^ results
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
GbsSessionMaterializer >> remoteArrayElementOopsForOops: oopCollection [
	^ self remoteReader remoteArrayElementOopsForOops: oopCollection
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteAssociationOopPairsForOops: oopCollection [
	^ self remoteReader remoteAssociationOopPairsForOops: oopCollection
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteAssociationOopPairForOop: anOop [
	^ self remoteReader remoteAssociationOopPairForOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteByteArrayValuesForOops: oopCollection [
	^ self remoteReader remoteByteArrayValuesForOops: oopCollection
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
GbsSessionMaterializer >> remoteCollectionAsArrayOopsForOops: oopCollection [
	^ self remoteReader remoteCollectionAsArrayOopsForOops: oopCollection
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteCollectionElementOopsForOop: anOop [
	^ self remoteReader remoteCollectionElementOopsForOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteCollectionElementOopsForOops: oopCollection [
	^ self remoteReader remoteCollectionElementOopsForOops: oopCollection
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteDictionaryAssociationOopPairsForOop: anOop [
	^ self remoteReader remoteDictionaryAssociationOopPairsForOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteDictionaryAssociationOopPairsForOops: oopCollection [
	^ self remoteReader remoteDictionaryAssociationOopPairsForOops: oopCollection
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

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteStringValuesForOops: oopCollection [
	^ self remoteReader remoteStringValuesForOops: oopCollection
]

{ #category : 'metrics' }
GbsSessionMaterializer >> resetMaterializationMetrics [
	(session class weakRegistryNamed: #GbsSessionMaterializationMetricCaches)
		at: session
		put: Dictionary new.
	^ self materializationMetrics
]
