Class {
	#name : 'GbsSessionMaterializer',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsSessionMaterializer class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'cache' }
GbsSessionMaterializer >> cachedProxyForOop: anOop [
	| entry |
	entry := self proxyCache at: anOop ifAbsent: [ nil ].
	entry ifNil: [ ^ nil ].
	^ entry first
]

{ #category : 'cache' }
GbsSessionMaterializer >> clearProxyCache [
	(session class weakRegistryNamed: #GbsSessionProxyCaches)
		at: session
		put: WeakValueDictionary new.
	self clearTypedWrapperClassCache.
	^ self proxyCache
]

{ #category : 'cache' }
GbsSessionMaterializer >> clearRemoteClassNameCache [
	^ self remoteReader clearRemoteClassNameCache
]

{ #category : 'fetching' }
GbsSessionMaterializer >> fetchObject: anOop [
	self resetMaterializedObjectCache.
	self resetMaterializationMetrics.
	self incrementMaterializationMetric: #rootFetches.
	^ [
		self
			recordMillisecondsForMetric: #rootFetchMs
			during: [
				self
					recordMillisecondsForMetric: #fetchTotalMs
					during: [
						self
							fetchObject: anOop
							withProfile: self materializationProfile
							depth: 0
							seen: IdentitySet new ] ]
	] ensure: [ self resetMaterializedObjectCache ]
]

{ #category : 'fetching' }
GbsSessionMaterializer >> fetchObject: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	self checkMaterializationDepth: anInteger.
	^ aProfile
		materializeOop: anOop
		inSession: session
		depth: anInteger
		seen: seenOops
]

{ #category : 'profiles' }
GbsSessionMaterializer >> fetchByReference [
	self materializationProfile: GbsProxyOnlyMaterializationProfile new.
	^ session
]

{ #category : 'profiles' }
GbsSessionMaterializer >> fetchDeep [
	self materializationProfile: GbsDeepMaterializationProfile new.
	^ session
]

{ #category : 'profiles' }
GbsSessionMaterializer >> fetchLegacy [
	self materializationProfile: GbsLegacyMaterializationProfile new.
	^ session
]

{ #category : 'profiles' }
GbsSessionMaterializer >> fetchProfile [
	^ self materializationProfile
]

{ #category : 'profiles' }
GbsSessionMaterializer >> fetchProfile: aProfile [
	^ self materializationProfile: aProfile
]

{ #category : 'profiles' }
GbsSessionMaterializer >> fetchShallow [
	self materializationProfile: GbsShallowMaterializationProfile new.
	^ session
]

{ #category : 'testing' }
GbsSessionMaterializer >> isImmediateOop: anOop [
	anOop = 20 ifTrue: [ ^ true ].
	(anOop = 28 or: [ anOop = 268 ]) ifTrue: [ ^ true ].
	(anOop = 12 or: [ anOop = 140 ]) ifTrue: [ ^ true ].
	((anOop bitAnd: 7) = 2 or: [ (anOop bitAnd: 7) = 6 ]) ifTrue: [ ^ true ].
	^ false
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeArrayOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	| elementOops materialized materializedElements |
	self materializedObjectForOop: anOop ifPresent: [ :object | ^ object ].
	elementOops := self remoteArrayElementOopsForOop: anOop.
	materialized := Array new: elementOops size.
	self rememberMaterializedObject: materialized forOop: anOop.
	seenOops add: anOop.
	materializedElements := self
		materializeOops: elementOops
		withProfile: aProfile
		depth: anInteger + 1
		seen: seenOops.
	1 to: elementOops size do: [ :index |
		materialized at: index put: (materializedElements at: index) ].
	^ materialized
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeAssociationOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	| pair materialized association |
	self materializedObjectForOop: anOop ifPresent: [ :object | ^ object ].
	pair := self remoteAssociationOopPairForOop: anOop.
	seenOops add: anOop.
	materialized := self
		materializeOops: pair
		withProfile: aProfile
		depth: anInteger + 1
		seen: seenOops.
	association := Association
		key: materialized first
		value: materialized second.
	self rememberMaterializedObject: association forOop: anOop.
	^ association
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeByteArrayOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	| bytes byteArray |
	self materializedObjectForOop: anOop ifPresent: [ :object | ^ object ].
	bytes := self
		materializeArrayOop: (self remoteCollectionAsArrayOop: anOop)
		withProfile: aProfile
		depth: anInteger
		seen: seenOops.
	byteArray := ByteArray withAll: bytes.
	self rememberMaterializedObject: byteArray forOop: anOop.
	^ byteArray
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeDictionaryOop: anOop identityKeys: useIdentity withProfile: aProfile depth: anInteger seen: seenOops [
	| associationPairs dictionary keyOops valueOops keys values |
	self materializedObjectForOop: anOop ifPresent: [ :object | ^ object ].
	associationPairs := self remoteDictionaryAssociationOopPairsForOop: anOop.
	dictionary := useIdentity
		ifTrue: [ IdentityDictionary new ]
		ifFalse: [ Dictionary new ].
	self rememberMaterializedObject: dictionary forOop: anOop.
	seenOops add: anOop.
	keyOops := associationPairs collect: [ :each | each at: 1 ].
	valueOops := associationPairs collect: [ :each | each at: 2 ].
	keys := self
		materializeOops: keyOops
		withProfile: aProfile
		depth: anInteger + 1
		seen: seenOops.
	values := self
		materializeOops: valueOops
		withProfile: aProfile
		depth: anInteger + 1
		seen: seenOops.
	1 to: associationPairs size do: [ :index |
		dictionary
			at: (keys at: index)
			put: (values at: index) ].
	^ dictionary
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeOops: oopCollection withProfile: aProfile depth: anInteger seen: seenOops [
	self checkMaterializationDepth: anInteger.
	(aProfile isKindOf: GbsProxyOnlyMaterializationProfile) ifTrue: [
		^ self materializeProxyOnlyOops: oopCollection withProfile: aProfile ].
	^ self
		materializeFrontierOops: oopCollection
		withProfile: aProfile
		depth: anInteger
		seen: seenOops
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeProxyOnlyOops: oopCollection withProfile: aProfile [
	| results assigned missing classNames |
	results := Array new: oopCollection size.
	assigned := Array new: oopCollection size.
	1 to: assigned size do: [ :index | assigned at: index put: false ].
	missing := OrderedCollection new.
	self incrementMaterializationMetric: #proxyBatchItems by: oopCollection size.
	oopCollection doWithIndex: [ :oop :index |
		(self isImmediateOop: oop)
			ifTrue: [
				results at: index put: (self resultFor: oop).
				assigned at: index put: true ]
			ifFalse: [
				| cachedProxy |
				cachedProxy := self cachedProxyForOop: oop.
				cachedProxy
					ifNotNil: [
						self incrementMaterializationMetric: #proxyCacheHits.
						results at: index put: cachedProxy.
						assigned at: index put: true ]
					ifNil: [
						(missing includes: oop) ifFalse: [
							missing add: oop ] ] ] ].
	classNames := missing isEmpty
		ifTrue: [ Dictionary new ]
		ifFalse: [ self remoteClassNamesForOops: missing ].
	oopCollection doWithIndex: [ :oop :index |
		(assigned at: index) ifFalse: [
			| className object |
			className := classNames at: oop ifAbsent: [ nil ].
			object := (className notNil and: [ aProfile shouldMaterializeScalarClassNamed: className ])
				ifTrue: [
					aProfile
						materializeScalarClassNamed: className
						oop: oop
						inSession: session ]
				ifFalse: [
					className
						ifNil: [ self proxyForOop: oop ]
						ifNotNil: [
							| wrapperClass |
							wrapperClass := self typedWrapperClassForServerClassName: className.
							wrapperClass
								ifNil: [ self proxyForOop: oop ]
								ifNotNil: [ self proxyForOop: oop usingClass: wrapperClass ] ] ].
			results at: index put: object.
			assigned at: index put: true ] ].
	^ results
]

{ #category : 'profiles' }
GbsSessionMaterializer >> materializationProfile [
	^ (session class weakRegistryNamed: #GbsSessionMaterializationProfiles)
		at: session
		ifAbsentPut: [ GbsLegacyMaterializationProfile new ]
]

{ #category : 'profiles' }
GbsSessionMaterializer >> materializationProfile: aProfile [
	| profile |
	profile := aProfile ifNil: [ GbsLegacyMaterializationProfile new ].
	(session class weakRegistryNamed: #GbsSessionMaterializationProfiles)
		at: session
		put: profile.
	^ profile
]

{ #category : 'runtime' }
GbsSessionMaterializer >> materializeRuntimeValue: anObject [
	anObject ifNil: [ ^ nil ].
	^ anObject
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeSequenceableCollectionOop: anOop using: aBlock withProfile: aProfile depth: anInteger seen: seenOops [
	| localArray |
	localArray := self
		materializeArrayOop: (self remoteCollectionAsArrayOop: anOop)
		withProfile: aProfile
		depth: anInteger
		seen: seenOops.
	^ aBlock value: localArray
]

{ #category : 'runtime' }
GbsSessionMaterializer >> objectForOop: anOop [
	^ self resultFor: anOop
]

{ #category : 'cache' }
GbsSessionMaterializer >> proxyCache [
	^ (session class weakRegistryNamed: #GbsSessionProxyCaches)
		at: session
		ifAbsentPut: [ WeakValueDictionary new ]
]

{ #category : 'proxies' }
GbsSessionMaterializer >> proxyForOop: anOop [
	^ self proxyForOop: anOop usingClass: GbsProxy
]

{ #category : 'proxies' }
GbsSessionMaterializer >> proxyForOop: anOop serverClassName: aClassName [
	| cachedProxy wrapperClass |
	cachedProxy := self cachedProxyForOop: anOop.
	cachedProxy ifNotNil: [ ^ cachedProxy ].
	wrapperClass := self typedWrapperClassForServerClassName: aClassName.
	wrapperClass ifNil: [ ^ self proxyForOop: anOop ].
	^ self proxyForOop: anOop usingClass: wrapperClass
]

{ #category : 'proxies' }
GbsSessionMaterializer >> proxyForOop: anOop usingClass: proxyClass [
	| cachedProxy proxy |
	cachedProxy := self cachedProxyForOop: anOop.
	cachedProxy ifNotNil: [
		self incrementMaterializationMetric: #proxyCacheHits.
		^ cachedProxy ].
	^ self
		recordMillisecondsForMetric: #proxyConstructionMs
		during: [
			proxy := proxyClass oop: anOop session: session.
			self proxyCache at: anOop put: { proxy }.
			self incrementMaterializationMetric: #proxyCreations.
			proxy ]
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteReader [
	^ GbsSessionMaterializationRemoteReader on: session
]

{ #category : 'runtime' }
GbsSessionMaterializer >> resultFor: anOop [
	anOop = 20 ifTrue: [ ^ nil ].
	(anOop = 28 or: [ anOop = 268 ]) ifTrue: [ ^ true ].
	(anOop = 12 or: [ anOop = 140 ]) ifTrue: [ ^ false ].
	(anOop bitAnd: 7) = 2 ifTrue: [ ^ (anOop bitShift: -3) ].
	(anOop bitAnd: 7) = 6 ifTrue: [ ^ Character codePoint: (anOop bitShift: -3) ].
	^ self proxyForOop: anOop
]

{ #category : 'accessing' }
GbsSessionMaterializer >> session [
	^ session
]

{ #category : 'accessing' }
GbsSessionMaterializer >> session: aSession [
	session := aSession
]

{ #category : 'profiles' }
GbsSessionMaterializer >> withMaterializationProfile: aProfile do: aBlock [
	| previousProfile result |
	previousProfile := self materializationProfile.
	self materializationProfile: aProfile.
	result := [ aBlock value ] ensure: [ self materializationProfile: previousProfile ].
	^ result
]
