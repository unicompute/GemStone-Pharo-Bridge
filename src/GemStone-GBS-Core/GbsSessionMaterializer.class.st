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
	^ self proxyCache
]

{ #category : 'cache' }
GbsSessionMaterializer >> clearRemoteClassNameCache [
	^ self remoteReader clearRemoteClassNameCache
]

{ #category : 'fetching' }
GbsSessionMaterializer >> fetchObject: anOop [
	^ self
		fetchObject: anOop
		withProfile: self materializationProfile
		depth: 0
		seen: IdentitySet new
]

{ #category : 'fetching' }
GbsSessionMaterializer >> fetchObject: anOop withProfile: aProfile depth: anInteger seen: seenOops [
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
	| elementOops localArray |
	elementOops := self remoteArrayElementOopsForOop: anOop.
	localArray := Array new: elementOops size.
	elementOops doWithIndex: [ :elementOop :index |
		localArray
			at: index
			put: (self
				fetchObject: elementOop
				withProfile: aProfile
				depth: anInteger + 1
				seen: seenOops) ].
	^ localArray
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeAssociationOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	| pair |
	pair := self remoteAssociationOopPairForOop: anOop.
	^ Association
		key: (self
			fetchObject: (pair at: 1)
			withProfile: aProfile
			depth: anInteger + 1
			seen: seenOops)
		value: (self
			fetchObject: (pair at: 2)
			withProfile: aProfile
			depth: anInteger + 1
			seen: seenOops)
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeByteArrayOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	| bytes |
	bytes := self
		materializeArrayOop: (self remoteCollectionAsArrayOop: anOop)
		withProfile: aProfile
		depth: anInteger
		seen: seenOops.
	^ ByteArray withAll: bytes
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeDictionaryOop: anOop identityKeys: useIdentity withProfile: aProfile depth: anInteger seen: seenOops [
	| associationPairs dictionary |
	associationPairs := self remoteDictionaryAssociationOopPairsForOop: anOop.
	dictionary := useIdentity
		ifTrue: [ IdentityDictionary new ]
		ifFalse: [ Dictionary new ].
	associationPairs do: [ :each |
		dictionary
			at: (self
				fetchObject: (each at: 1)
				withProfile: aProfile
				depth: anInteger + 1
				seen: seenOops)
			put: (self
				fetchObject: (each at: 2)
				withProfile: aProfile
				depth: anInteger + 1
				seen: seenOops) ].
	^ dictionary
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
	wrapperClass := GbsSessionManager
		typedWrapperClassForServerClassNamed: aClassName
		forSession: session.
	wrapperClass ifNil: [ ^ self proxyForOop: anOop ].
	^ self proxyForOop: anOop usingClass: wrapperClass
]

{ #category : 'proxies' }
GbsSessionMaterializer >> proxyForOop: anOop usingClass: proxyClass [
	| cachedProxy proxy |
	cachedProxy := self cachedProxyForOop: anOop.
	cachedProxy ifNotNil: [ ^ cachedProxy ].
	proxy := proxyClass oop: anOop session: session.
	self proxyCache at: anOop put: { proxy }.
	^ proxy
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
GbsSessionMaterializer >> remoteReader [
	^ GbsSessionMaterializationRemoteReader on: session
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteSizeForOop: anOop [
	^ self remoteReader remoteSizeForOop: anOop
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteStringValueForOop: anOop [
	^ self remoteReader remoteStringValueForOop: anOop
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
