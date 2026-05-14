Extension { #name : 'GbsSession' }

{ #category : '*GemStone-GBS-Core' }
GbsSession >> bridgeRoot [
	^ GbsBridgeRootFacade on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteScriptBuilder [
	^ self commandExecutor remoteScriptBuilder
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> commandExecutor [
	^ GbsSessionCommandExecutor on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> executeRemoteCommand: aRemoteCommand [
	^ self commandExecutor executeRemoteCommand: aRemoteCommand
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchRemoteCommand: aRemoteCommand [
	^ self commandExecutor fetchRemoteCommand: aRemoteCommand
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchRemoteCommand: aRemoteCommand context: anOop [
	^ self commandExecutor fetchRemoteCommand: aRemoteCommand context: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchRemoteCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary context: anOop [
	^ self commandExecutor
		fetchRemoteCommandBody: bodyString
		literalBindings: literalDictionary
		oopBindings: oopDictionary
		context: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchRemoteScript: scriptString context: anOop [
	^ self commandExecutor fetchRemoteScript: scriptString context: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteCommand: aString [
	^ self commandExecutor remoteCommand: aString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> returnRemoteCommandOop: aRemoteCommand [
	^ self commandExecutor returnRemoteCommandOop: aRemoteCommand
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> returnRemoteCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary [
	^ self commandExecutor
		returnRemoteCommandBody: bodyString
		literalBindings: literalDictionary
		oopBindings: oopDictionary
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> abortTransaction [
	^ self transactionCoordinator abortTransaction
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> needsCommit [
	^ self transactionCoordinator needsCommit
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializeRuntimeValue: anObject [
	anObject ifNil: [ ^ nil ].
	^ anObject
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> smalltalk [
	^ GbsSmalltalkFacade on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> symbolDictionaryNamed: aName [
	^ GbsSymbolDictionaryFacade on: self name: aName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> loadedClasses [
	^ self repository loadedClasses
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectAt: aName [
	^ self namedObjectRegistry namedObjectAt: aName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectAt: aName ifAbsent: aBlock [
	^ self namedObjectRegistry namedObjectAt: aName ifAbsent: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectRegistry [
	^ GbsSessionNamedObjectRegistry on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectCache [
	^ self namedObjectRegistry namedObjectCache
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> clearNamedObjectCache [
	^ self namedObjectRegistry clearNamedObjectCache
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectAutoloadRegistry [
	^ self namedObjectRegistry namedObjectAutoloadRegistry
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> clearNamedObjectAutoloads [
	^ self namedObjectRegistry clearNamedObjectAutoloads
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> readLock: anObject [
	^ self transactionCoordinator readLock: anObject
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> writeLock: anObject [
	^ self transactionCoordinator writeLock: anObject
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> registerNamedObjectAutoload: aName [
	^ self namedObjectRegistry registerNamedObjectAutoload: aName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> registerNamedObjectAutoload: localName remote: remoteName [
	^ self namedObjectRegistry registerNamedObjectAutoload: localName remote: remoteName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> unregisterNamedObjectAutoload: aName [
	^ self namedObjectRegistry unregisterNamedObjectAutoload: aName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> hasNamedObjectAutoloadNamed: aName [
	^ self namedObjectRegistry hasNamedObjectAutoloadNamed: aName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectAutoloadTargetFor: aName [
	^ self namedObjectRegistry namedObjectAutoloadTargetFor: aName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectAutoloadEntries [
	^ self namedObjectRegistry namedObjectAutoloadEntries
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectAutoloadKeys [
	^ self namedObjectRegistry namedObjectAutoloadKeys
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectAutoloadReportText [
	^ self namedObjectRegistry namedObjectAutoloadReportText
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> hasCachedNamedObjectNamed: aName [
	^ self namedObjectRegistry hasCachedNamedObjectNamed: aName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> normalizedNamedObjectName: aName [
	^ self namedObjectRegistry normalizedNamedObjectName: aName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectCacheEntries [
	^ self namedObjectRegistry namedObjectCacheEntries
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectCacheKeys [
	^ self namedObjectRegistry namedObjectCacheKeys
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namedObjectCacheReportText [
	^ self namedObjectRegistry namedObjectCacheReportText
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> executeScriptAndReturnOop: aString [
	^ self commandExecutor executeScriptAndReturnOop: aString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> executeWorkspaceScriptAndReturnOop: aString [
	^ self commandExecutor executeWorkspaceScriptAndReturnOop: aString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchTranscriptLogs [
	^ self commandExecutor fetchTranscriptLogs
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchObject: anOop [
	^ self
		fetchObject: anOop
		withProfile: self materializationProfile
		depth: 0
		seen: IdentitySet new
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchObject: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	^ aProfile
		materializeOop: anOop
		inSession: self
		depth: anInteger
		seen: seenOops
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchProfile [
	^ self materializationProfile
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchProfile: aProfile [
	^ self materializationProfile: aProfile
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> loginStone: stoneName user: username password: password [
	"Initializes GCI and attempts to log into the specified Stone"

	| initSuccess loginSuccess errorStruct interpretedError |
	initSuccess := self gciInit.
	initSuccess ifFalse: [ ^ GbsError signal: 'Failed to initialize GemStone GCI library.' ].
	loginSuccess := self
		gciLoginStone: stoneName
		hostUser: ''
		hostPass: ''
		gsUser: username
		gsPass: password.
	loginSuccess ifFalse: [
		errorStruct := GciError new.
		(self gciErr: errorStruct) ifTrue: [
			Transcript show: '[GemStone Login Error]'; cr.
			Transcript show: '  Stone: ', stoneName; cr.
			Transcript show: '  User: ', username; cr.
			Transcript
				show: '  Error Number: ';
				show: ([ errorStruct number printString ] on: Exception do: [ 'n/a' ]);
				cr.
			Transcript
				show: '  Error Message: ';
				show: ([ errorStruct message ] on: Exception do: [ 'Unknown login failure' ]);
				cr.
			interpretedError := self interpretLoginError: errorStruct.
			Transcript show: '  Interpreted: ', interpretedError; cr; cr.
			self signalError: errorStruct.
			^ GbsError signal: interpretedError ].
		^ GbsError signal: 'Unknown login failure. Please check your GemStone connection parameters.' ].
	isLoggedIn := true
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> interpretErrorMessage: aString errorNumber: anErrorNumber [
	"Interpret error messages and provide user-friendly explanations for common issues"
	| errorMsgLower originalMsg |
	originalMsg := aString isString
		ifTrue: [ aString ]
		ifFalse: [
			[ aString asString ]
				on: Error
				do: [ 'Unknown error' ] ].
	errorMsgLower := originalMsg asLowercase.
	(errorMsgLower includesSubstring: 'connection refused') ifTrue: [
		^ 'Cannot connect to GemStone netldi daemon.

The netldi is not running or not accessible.

To fix this, start netldi on the GemStone server:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'no such') ifTrue: [
		((errorMsgLower includesSubstring: 'stn')
			or: [ errorMsgLower includesSubstring: 'stone' ]) ifTrue: [
			^ 'Cannot find the GemStone stone.

Please check that the stone exists and netldi is running.

To start the stone and netldi:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ] ].
	(errorMsgLower includesSubstring: 'netldi') ifTrue: [
		^ 'GemStone netldi daemon is not running or not accessible.

To fix this, start netldi on the GemStone server:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'gemnetobject') ifTrue: [
		^ 'Cannot connect to gemnetobject service.

Please ensure the GemStone service is running.

To start netldi:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'login') ifTrue: [
		((errorMsgLower includesSubstring: 'fail')
			or: [ (errorMsgLower includesSubstring: 'denied')
			or: [ errorMsgLower includesSubstring: 'disabled' ] ]) ifTrue: [
			^ 'GemStone login failed.

Please check your username and password, or verify that logins are enabled.

Original error: ', originalMsg ] ].
	(errorMsgLower includesSubstring: 'shutdown') ifTrue: [
		^ 'GemStone is shutting down.

Please wait for it to fully stop and restart it.

To restart:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'timeout') ifTrue: [
		^ 'Connection to GemStone timed out.

Please check network connectivity and that netldi is running.

To start netldi:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
	(anErrorNumber notNil and: [ anErrorNumber ~= 0 ]) ifTrue: [
		^ 'GemStone error ', anErrorNumber asString, ': ', originalMsg ].
	originalMsg isEmpty ifTrue: [
		^ 'Login failed. Please check your GemStone connection parameters.

Common issues:
• netldi is not running - start with: startnetldi -a <stone_name> -g <username>
• Stone name is incorrect
• Network connectivity issues' ].
	^ originalMsg
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> marshalArgumentToScript: anObject visited: visited [
	"If the argument is another proxy, preserve its remote identity before
	asking any generic type questions that could forward remotely."
	(anObject isKindOf: GbsProxy) ifTrue: [
		^ '(Object _objectForOop: ', anObject oop asString, ')' ].

	anObject isInteger ifTrue: [ ^ anObject asString ].
	anObject isFloat ifTrue: [ ^ anObject printString ].
	anObject class == Fraction ifTrue: [
		^ '(', anObject numerator printString, ' / ', anObject denominator printString, ')' ].
	anObject isSymbol ifTrue: [ ^ '#', anObject asString ].
	anObject == true ifTrue: [ ^ 'true' ].
	anObject == false ifTrue: [ ^ 'false' ].
	anObject ifNil: [ ^ 'nil' ].
	anObject isCharacter ifTrue: [
		^ '(Character value: ', anObject asInteger printString, ')' ].
	anObject isString ifTrue: [ ^ self marshalStringLiteralToScript: anObject ].
	^ self marshalComplexArgumentToScript: anObject visited: visited
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> resultFor: anOop [
	"Identify special GemStone OOP tags (GS64 3.7 Programming Guide)"
	anOop = 20 ifTrue: [ ^ nil ].
	(anOop = 28 or: [ anOop = 268 ]) ifTrue: [ ^ true ].
	(anOop = 12 or: [ anOop = 140 ]) ifTrue: [ ^ false ].
	(anOop bitAnd: 7) = 2 ifTrue: [ ^ (anOop bitShift: -3) ].
	(anOop bitAnd: 7) = 6 ifTrue: [ ^ Character codePoint: (anOop bitShift: -3) ].
	^ self proxyForOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> typedWrapperLifecycleEntries [
	^ GbsSessionManager typedWrapperLifecycleEntriesForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> typedWrapperLifecycleObjects [
	^ GbsSessionManager typedWrapperLifecycleObjectsForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> typedWrapperLifecycleReport [
	^ GbsSessionManager typedWrapperLifecycleReportForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> typedWrapperLifecycleReportText [
	^ GbsSessionManager typedWrapperLifecycleReportTextForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> invalidateStaleTypedWrapperClasses [
	^ GbsSessionManager invalidateStaleTypedWrapperClassesForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> refreshStaleTypedWrapperClasses [
	^ GbsSessionManager refreshStaleTypedWrapperClassesForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> refreshAllTypedWrapperClasses [
	^ GbsSessionManager refreshAllTypedWrapperClassesForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> sessionForwarderFor: aSymbol [
	"Answer an explicit forwarder/proxy for the named GemStone object in the current session."
	^ self
		namedObjectAt: aSymbol
		ifAbsent: [ self error: aSymbol printString , ' not defined' ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchByReference [
	self materializationProfile: GbsProxyOnlyMaterializationProfile new.
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchDeep [
	self materializationProfile: GbsDeepMaterializationProfile new.
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchLegacy [
	self materializationProfile: GbsLegacyMaterializationProfile new.
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchShallow [
	self materializationProfile: GbsShallowMaterializationProfile new.
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializationProfile [
	^ (self class weakRegistryNamed: #GbsSessionMaterializationProfiles)
		at: self
		ifAbsentPut: [ GbsLegacyMaterializationProfile new ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializationProfile: aProfile [
	| profile |
	profile := aProfile ifNil: [ GbsLegacyMaterializationProfile new ].
	(self class weakRegistryNamed: #GbsSessionMaterializationProfiles)
		at: self
		put: profile.
	^ profile
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> withMaterializationProfile: aProfile do: aBlock [
	| previousProfile result |
	previousProfile := self materializationProfile.
	self materializationProfile: aProfile.
	result := [ aBlock value ] ensure: [ self materializationProfile: previousProfile ].
	^ result
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> isImmediateOop: anOop [
	anOop = 20 ifTrue: [ ^ true ].
	(anOop = 28 or: [ anOop = 268 ]) ifTrue: [ ^ true ].
	(anOop = 12 or: [ anOop = 140 ]) ifTrue: [ ^ true ].
	((anOop bitAnd: 7) = 2 or: [ (anOop bitAnd: 7) = 6 ]) ifTrue: [ ^ true ].
	^ false
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializeArrayOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
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

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializeAssociationOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
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

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializeByteArrayOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	| bytes |
	bytes := self
		materializeArrayOop: (self remoteCollectionAsArrayOop: anOop)
		withProfile: aProfile
		depth: anInteger
		seen: seenOops.
	^ ByteArray withAll: bytes
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializeDictionaryOop: anOop identityKeys: useIdentity withProfile: aProfile depth: anInteger seen: seenOops [
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

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializeSequenceableCollectionOop: anOop using: aBlock withProfile: aProfile depth: anInteger seen: seenOops [
	| localArray |
	localArray := self
		materializeArrayOop: (self remoteCollectionAsArrayOop: anOop)
		withProfile: aProfile
		depth: anInteger
		seen: seenOops.
	^ aBlock value: localArray
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> proxyForOop: anOop [
	^ self proxyForOop: anOop usingClass: GbsProxy
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> proxyForOop: anOop serverClassName: aClassName [
	| cachedProxy wrapperClass |
	cachedProxy := self cachedProxyForOop: anOop.
	cachedProxy ifNotNil: [ ^ cachedProxy ].
	wrapperClass := GbsSessionManager typedWrapperClassForServerClassNamed: aClassName.
	wrapperClass ifNil: [ ^ self proxyForOop: anOop ].
	^ self proxyForOop: anOop usingClass: wrapperClass
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> proxyForOop: anOop usingClass: proxyClass [
	| cachedProxy proxy |
	cachedProxy := self cachedProxyForOop: anOop.
	cachedProxy ifNotNil: [ ^ cachedProxy ].
	proxy := proxyClass oop: anOop session: self.
	self proxyCache at: anOop put: { proxy }.
	^ proxy
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> cachedProxyForOop: anOop [
	| entry |
	entry := self proxyCache at: anOop ifAbsent: [ nil ].
	entry ifNil: [ ^ nil ].
	^ entry first
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> clearProxyCache [
	(self class weakRegistryNamed: #GbsSessionProxyCaches)
		at: self
		put: WeakValueDictionary new.
	^ self proxyCache
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> proxyCache [
	^ (self class weakRegistryNamed: #GbsSessionProxyCaches)
		at: self
		ifAbsentPut: [ WeakValueDictionary new ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteArrayElementOopAt: anInteger ofOop: anOop [
	^ self
		returnRemoteCommandBody: 'object at: index'
		literalBindings: (Dictionary new
			at: 'index' put: anInteger;
			yourself)
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteAssociationPairOopFor: anOop [
	^ self
		returnRemoteCommandBody: 'Array with: assoc key with: assoc value'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'assoc' put: anOop;
			yourself)
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteClassNameForOop: anOop [
	^ self
		fetchRemoteCommandBody: 'object class name asString'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
		context: 20
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteCollectionAsArrayOop: anOop [
	^ self
		returnRemoteCommandBody: 'object asArray'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteDictionaryAssociationsAsArrayOop: anOop [
	^ self
		returnRemoteCommandBody: 'object associations asArray'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteSizeForOop: anOop [
	^ self fetchRemoteCommand: (GbsRemoteCommand
		blockBody: 'object size'
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself))
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteStringValueForOop: anOop [
	^ self
		fetchRemoteCommandBody: 'object asString'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
		context: 20
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectForOop: anOop [
	^ self resultFor: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectSpace [
	^ GbsObjectSpaceFacade on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectSpaceDiagnostics [
	^ GbsObjectSpaceDiagnosticsFacade on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectSpaceDiagnosticsReport [
	^ self objectSpaceDiagnostics report
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectSpaceRepository [
	^ GbsObjectSpaceRepositoryFacade on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> defineFinalizerFor: anObject do: aBlock [
	^ self objectSpace defineFinalizerFor: anObject do: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> eachObjectDo: aBlock [
	^ self objectSpace eachObjectDo: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> eachObjectDo: aBlock batchSize: aSmallInteger [
	^ self objectSpace eachObjectDo: aBlock batchSize: aSmallInteger
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> eachObjectOf: aClassOrName do: aBlock [
	^ self objectSpace eachObjectOf: aClassOrName do: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> eachObjectOf: aClassOrName do: aBlock batchSize: aSmallInteger [
	^ self
		objectSpace
		eachObjectOf: aClassOrName
		do: aBlock
		batchSize: aSmallInteger
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> allSubclassesOf: aClassOrName [
	^ self objectSpace allSubclassesOf: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> allSubclassesOfNamed: aClassName [
	^ self objectSpace allSubclassesOfNamed: aClassName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> instancesInMemoryOf: aClassOrName [
	^ self objectSpace instancesInMemoryOf: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> instancesInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	^ self
		objectSpace
		instancesInMemoryOf: aClassOrName
		from: aStartIndex
		limit: aLimit
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> instancesInMemoryOfNamed: aClassName [
	^ self objectSpace instancesInMemoryOfNamed: aClassName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> hasFinalizerFor: anObject [
	^ self objectSpace hasFinalizerFor: anObject
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> loadedClassesIncludingModules [
	^ self objectSpace loadedClassesIncludingModules
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> loadedClassesIncludingModules: aBoolean [
	^ self objectSpace loadedClassesIncludingModules: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> sessionStateAt: aKey [
	^ self objectSpace sessionStateAt: aKey
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> sessionStateAt: aKey ifAbsent: aBlock [
	^ self objectSpace sessionStateAt: aKey ifAbsent: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> sessionStateAt: aKey put: anObject [
	^ self objectSpace sessionStateAt: aKey put: anObject
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> referencesTo: anObject [
	^ self objectSpace referencesTo: anObject
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> referencesToOop: anOop [
	^ self objectSpace referencesToOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectsInMemory [
	^ self objectSpace objectsInMemory
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectsInMemoryFrom: aStartIndex limit: aLimit [
	^ self objectSpace objectsInMemoryFrom: aStartIndex limit: aLimit
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectsInMemoryMatching: aBlock [
	^ self objectSpace objectsInMemoryMatching: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectsInMemoryMatching: aBlock limit: aLimit batchSize: aBatchSize [
	^ self
		objectSpace
		objectsInMemoryMatching: aBlock
		limit: aLimit
		batchSize: aBatchSize
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectsInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	^ self
		objectSpace
		objectsInMemoryOf: aClassOrName
		from: aStartIndex
		limit: aLimit
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectsInMemoryOf: aClassOrName matching: aBlock [
	^ self
		objectSpace
		objectsInMemoryOf: aClassOrName
		matching: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectsInMemoryOf: aClassOrName matching: aBlock limit: aLimit batchSize: aBatchSize [
	^ self
		objectSpace
		objectsInMemoryOf: aClassOrName
		matching: aBlock
		limit: aLimit
		batchSize: aBatchSize
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> undefineFinalizerFor: anObject [
	^ self objectSpace undefineFinalizerFor: anObject
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classHistoryOf: aClassOrName [
	^ self repository classHistoryOf: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> commitTransaction [
	^ self transactionCoordinator commitTransaction
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> commitTransactionOrSignalConflict [
	^ self transactionCoordinator commitTransactionOrSignalConflict
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> commitTransactionWithRetryCount: aRetryCount [
	^ self transactionCoordinator commitTransactionWithRetryCount: aRetryCount
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> withCommitRetryCount: aRetryCount do: aBlock [
	^ self transactionCoordinator withCommitRetryCount: aRetryCount do: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> withGemStoneTransactionDo: aBlock [
	^ self transactionCoordinator withGemStoneTransactionDo: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> withGemStoneTransactionRetryCount: aRetryCount do: aBlock [
	^ self transactionCoordinator withGemStoneTransactionRetryCount: aRetryCount do: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> transactionCoordinator [
	^ GbsSessionTransactionCoordinator on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classMethodMirrorForClass: aClassOrName selector: aSelector [
	^ self
		repository
		classMethodMirrorForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classMethodMirrorForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		classMethodMirrorForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classMethodObjectForClass: aClassOrName selector: aSelector [
	^ self
		repository
		classMethodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classUnboundMethodObjectForClass: aClassOrName selector: aSelector [
	^ self
		repository
		classUnboundMethodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		classMethodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classUnboundMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		classUnboundMethodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classMirrorOf: aClassOrName [
	^ self repository classMirrorOf: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classMirrorOfNamed: aClassName [
	^ self repository classMirrorOfNamed: aClassName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namespaceMirrors [
	^ self repository namespaceMirrors
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namespaceMirrorAtSymbolListIndex: anInteger [
	^ self repository namespaceMirrorAtSymbolListIndex: anInteger
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> topLevelNamespaceMirror [
	^ self repository topLevelNamespaceMirror
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namespaceMirrorForClass: aClassOrName [
	^ self repository namespaceMirrorForClass: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namespaceMirrorForClassNamed: aClassName [
	^ self repository namespaceMirrorForClassNamed: aClassName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namespaceMirrorForObject: anObjectOrProxy [
	^ self repository namespaceMirrorForObject: anObjectOrProxy
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> namespaceMirrorForFullName: aString [
	^ self repository namespaceMirrorForFullName: aString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> implementorMethodReferenceStringsForSelector: aSelectorOrString [
	^ self repository implementorMethodReferenceStringsForSelector: aSelectorOrString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString [
	^ self repository
		hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString includeClassSide: includeClassSideBoolean [
	^ self repository
		hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
		includeClassSide: includeClassSideBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString [
	^ self repository
		hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString includeClassSide: includeClassSideBoolean [
	^ self repository
		hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
		includeClassSide: includeClassSideBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> methodReferenceStringsToObject: anObject [
	^ self repository methodReferenceStringsToObject: anObject
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> methodReferenceStringsToSymbol: aSymbolOrString [
	^ self repository methodReferenceStringsToSymbol: aSymbolOrString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> senderMethodReferenceStringsForSelector: aSelectorOrString [
	^ self repository senderMethodReferenceStringsForSelector: aSelectorOrString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> listInstancesOf: aClassOrName [
	^ self repository listInstancesOf: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> listInstancesOf: aClassOrName allowAbort: aBoolean [
	^ self repository listInstancesOf: aClassOrName allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> listInstancesOf: aClassOrName limit: aSmallInteger [
	^ self repository listInstancesOf: aClassOrName limit: aSmallInteger
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> listInstancesOf: aClassOrName limit: aSmallInteger allowAbort: aBoolean [
	^ self
		repository
		listInstancesOf: aClassOrName
		limit: aSmallInteger
		allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self
		repository
		migrateInstancesFrom: aSourceClassOrName
		to: aTargetClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self
		repository
		previewMigrationFrom: aSourceClassOrName
		to: aTargetClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	^ self
		repository
		previewMigrationFrom: aSourceClassOrName
		to: aTargetClassOrName
		allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> previewMigrationWithSubclassesOf: aTopClassOrName [
	^ self repository previewMigrationWithSubclassesOf: aTopClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> previewMigrationWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	^ self
		repository
		previewMigrationWithSubclassesOf: aTopClassOrName
		allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	^ self
		repository
		migrateInstancesFrom: aSourceClassOrName
		to: aTargetClassOrName
		allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> migrateInstancesWithSubclassesOf: aTopClassOrName [
	^ self repository migrateInstancesWithSubclassesOf: aTopClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> migrateInstancesWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	^ self
		repository
		migrateInstancesWithSubclassesOf: aTopClassOrName
		allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> chunkedMigrationRunnerFrom: aSourceClassOrName to: aTargetClassOrName [
	^ GbsChunkedMigrationRunner
		on: self
		source: aSourceClassOrName
		target: aTargetClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> invalidateRepositoryRoots [
	| versions caches |
	versions := self class weakRegistryNamed: #GbsSessionRepositoryRootLifecycleVersions.
	caches := self class weakRegistryNamed: #GbsSessionRepositoryRootCaches.
	versions at: self put: self repositoryRootLifecycleVersion + 1.
	caches at: self put: Dictionary new.
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> methodMirrorForClass: aClassOrName selector: aSelector [
	^ self
		repository
		methodMirrorForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> methodMirrorForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		methodMirrorForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> methodObjectForClass: aClassOrName selector: aSelector [
	^ self
		repository
		methodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> unboundMethodObjectForClass: aClassOrName selector: aSelector [
	^ self
		repository
		unboundMethodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> methodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		methodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> unboundMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		unboundMethodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> repository [
	^ GbsRepositoryFacade on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> repositoryRootCache [
	^ (self class weakRegistryNamed: #GbsSessionRepositoryRootCaches)
		at: self
		ifAbsentPut: [ Dictionary new ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> repositoryRootFacadeForKey: aRootKey path: aCollection [
	| normalizedPath cacheKey facade |
	normalizedPath := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ].
	cacheKey := { aRootKey. normalizedPath }.
	facade := self repositoryRootCache at: cacheKey ifAbsent: [ nil ].
	facade ifNotNil: [ ^ facade ].
	facade := GbsRepositoryRootFacade
		on: self
		rootKey: aRootKey
		path: normalizedPath.
	self repositoryRootCache at: cacheKey put: facade.
	^ facade
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> repositoryRootLifecycleVersion [
	^ (self class weakRegistryNamed: #GbsSessionRepositoryRootLifecycleVersions)
		at: self
		ifAbsent: [ 0 ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> resetAfterLogout [
	self stopPolling.
	isLoggedIn := false.
	sessionOop := nil.
	sessionId := nil.
	self clearProxyCache.
	self clearNamedObjectCache.
	GbsSessionManager clearTypedWrapperAutoloadRegistrationsForSession: self.
	self invalidateRepositoryRoots.
	parameters ifNotNil: [
		parameters sessionId: nil.
		parameters class currentSession == self ifTrue: [
			parameters class currentSession: nil ].
		parameters class unregisterSession: parameters ]
]
