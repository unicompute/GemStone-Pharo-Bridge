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
	| size localArray |
	size := self remoteSizeForOop: anOop.
	localArray := Array new: size.
	1 to: size do: [ :index |
		localArray
			at: index
			put: (self
				fetchObject: (self remoteArrayElementOopAt: index ofOop: anOop)
				withProfile: aProfile
				depth: anInteger + 1
				seen: seenOops) ].
	^ localArray
]

{ #category : 'materializing' }
GbsSessionMaterializer >> materializeAssociationOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	| pair |
	pair := self
		materializeArrayOop: (self remoteAssociationPairOopFor: anOop)
		withProfile: aProfile
		depth: anInteger
		seen: seenOops.
	^ Association
		key: (pair at: 1 ifAbsent: [ nil ])
		value: (pair at: 2 ifAbsent: [ nil ])
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
	| associations dictionary |
	associations := self
		materializeArrayOop: (self remoteDictionaryAssociationsAsArrayOop: anOop)
		withProfile: aProfile
		depth: anInteger
		seen: seenOops.
	dictionary := useIdentity
		ifTrue: [ IdentityDictionary new ]
		ifFalse: [ Dictionary new ].
	associations do: [ :each |
		dictionary
			at: each key
			put: each value ].
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
	wrapperClass := GbsSessionManager typedWrapperClassForServerClassNamed: aClassName.
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
	^ session
		returnRemoteCommandBody: 'object at: index'
		literalBindings: (Dictionary new
			at: 'index' put: anInteger;
			yourself)
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteAssociationPairOopFor: anOop [
	^ session
		returnRemoteCommandBody: 'Array with: assoc key with: assoc value'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'assoc' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteClassNameForOop: anOop [
	^ session
		fetchRemoteCommandBody: 'object class name asString'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
		context: 20
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteCollectionAsArrayOop: anOop [
	^ session
		returnRemoteCommandBody: 'object asArray'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteDictionaryAssociationsAsArrayOop: anOop [
	^ session
		returnRemoteCommandBody: 'object associations asArray'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteSizeForOop: anOop [
	^ session fetchRemoteCommand: (GbsRemoteCommand
		blockBody: 'object size'
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself))
]

{ #category : 'remote access' }
GbsSessionMaterializer >> remoteStringValueForOop: anOop [
	^ session
		fetchRemoteCommandBody: 'object asString'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
		context: 20
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
