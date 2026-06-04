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
GbsSession >> loginCoordinator [
	^ GbsSessionLoginCoordinator on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializer [
	^ GbsSessionMaterializer on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializationBatchSize [
	^ self materializer materializationBatchSize
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializationMetrics [
	^ self materializer materializationMetrics
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializationTraversalReportsForOops: oopCollection level: traversalLevel label: labelString [
	^ (GbsMaterializationTraversalBufferReader on: self)
		reportsForOops: oopCollection
		level: traversalLevel
		label: labelString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> resetMaterializationMetrics [
	^ self materializer resetMaterializationMetrics
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializedObjectForOop: anOop [
	^ self materializer materializedObjectForOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializedObjectForOop: anOop ifPresent: aBlock [
	^ self materializer materializedObjectForOop: anOop ifPresent: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> rememberMaterializedObject: anObject forOop: anOop [
	^ self materializer rememberMaterializedObject: anObject forOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> resetMaterializedObjectCache [
	^ self materializer resetMaterializedObjectCache
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> forgetMaterializedObjectForOop: anOop [
	^ self materializer forgetMaterializedObjectForOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> dirtyMaterializedObjectOops [
	^ GbsMaterializedObjectDirtyTracker dirtyOopsForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> isMaterializedObjectDirty: anObject [
	^ GbsMaterializedObjectDirtyTracker isObject: anObject dirtyInSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> registerMaterializedObject: anObject forOop: anOop [
	^ GbsMaterializedObjectDirtyTracker registerObject: anObject oop: anOop session: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> registerNewMaterializedObject: anObject [
	^ GbsMaterializedObjectDirtyTracker registerNewObject: anObject session: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> freeOopStream [
	^ (self class weakRegistryNamed: #GbsSessionFreeOopStreams)
		at: self
		ifAbsentPut: [ GbxFreeOopStream for: self ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> getFreeOop [
	^ self freeOopStream nextFreeOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> getFreeOops: numberOfOops [
	numberOfOops <= 0 ifTrue: [ ^ #() ].
	self serverInterface ifNil: [ self error: 'No server interface is available for free OOP allocation.' ].
	^ self serverInterface getFreeOops: numberOfOops
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> createObjectClass: aClassNameOrBehaviorOrOop values: values [
	"VW-compatible object creation from a free OOP. Creates a server object of the given class with the
	given values, using the default cluster bucket and temporary (non-permanent) space. Answers a proxy
	to the new server object. See createObjectClass:values:clusterBucket:permanent: for full semantics."
	^ self
		createObjectClass: aClassNameOrBehaviorOrOop
		values: values
		clusterBucket: 0
		permanent: false
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> createObjectClass: aClassNameOrBehaviorOrOop values: values clusterBucket: clusterBucket permanent: makePermanent [
	"VW-compatible object creation from a free OOP (GbsSession/Delegate>>createObjectClass:values:...).
	Allocates a fresh server object identifier with GciGetFreeOop, then creates the object via
	GciCreateOopObj (pointer/Nsc classes) or GciCreateByteObj (byte classes). values is either a Smalltalk
	byte object (for byte-format classes) or a collection of values for pointer/Nsc classes; pointer values
	may be proxies, already-mapped replicates, immediates, or forward references to other free OOPs.
	Answers a proxy to the newly created server object, which is added to the export set by GciCreate."
	| serverInterface classOop objId resultOop |
	serverInterface := self serverInterface.
	serverInterface ifNil: [ self error: 'No server interface is available for object creation.' ].
	(serverInterface supportsObjectCreationTransport) ifFalse: [
		GbsError signal: 'GCI object-creation transport is not available for this session.' ].
	classOop := self serverClassOopForObjectCreation: aClassNameOrBehaviorOrOop.
	classOop ifNil: [
		GbsError signal: 'Cannot create object: no server class OOP resolved for ', aClassNameOrBehaviorOrOop printString, '.' ].
	objId := self getFreeOop.
	(values isKindOf: ByteArray) ifTrue: [
		resultOop := serverInterface
			createByteObjectOfClass: classOop
			objId: objId
			bytes: values
			clusterId: clusterBucket
			permanent: makePermanent.
		^ self proxyForOop: resultOop ].
	resultOop := serverInterface
		createOopObjectOfClass: classOop
		objId: objId
		oopValues: (values collect: [ :each | self serverOopForCreationValue: each ])
		clusterId: clusterBucket
		permanent: makePermanent.
	^ self proxyForOop: resultOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> serverClassOopForObjectCreation: aClassNameOrBehaviorOrOop [
	"Resolve a class name, behavior, proxy, or OOP to an unsigned server class OOP for object creation."
	| name |
	aClassNameOrBehaviorOrOop ifNil: [ ^ nil ].
	aClassNameOrBehaviorOrOop isInteger ifTrue: [ ^ aClassNameOrBehaviorOrOop ].
	((aClassNameOrBehaviorOrOop respondsTo: #oop) and: [ aClassNameOrBehaviorOrOop oop notNil ]) ifTrue: [
		^ aClassNameOrBehaviorOrOop oop ].
	name := ((aClassNameOrBehaviorOrOop isString) or: [ aClassNameOrBehaviorOrOop isSymbol ])
		ifTrue: [ aClassNameOrBehaviorOrOop asString ]
		ifFalse: [
			((aClassNameOrBehaviorOrOop isKindOf: Behavior)
				or: [ (aClassNameOrBehaviorOrOop respondsTo: #isBehavior) and: [ aClassNameOrBehaviorOrOop isBehavior ] ])
				ifTrue: [ aClassNameOrBehaviorOrOop name asString ]
				ifFalse: [ aClassNameOrBehaviorOrOop asString ] ].
	^ (GbsDirtyReplicateStoreTraversal forSession: self) classOopForServerBehavior: name
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> serverOopForCreationValue: aValue [
	"Map a client value to an unsigned server OOP suitable as a GciCreateOopObj slot value. Handles nil,
	booleans, SmallIntegers, Characters, proxies/replicates already mapped to OOPs, and scalar (String/
	Symbol) values via native scalar OOP resolution. Forward references to other newly allocated free OOPs
	are honored because such objects are registered with the materialized-object tracker."
	| oop |
	aValue isNil ifTrue: [ ^ 20 ].
	aValue == true ifTrue: [ ^ 268 ].
	aValue == false ifTrue: [ ^ 12 ].
	(aValue isInteger and: [ aValue between: -1152921504606846976 and: 1152921504606846975 ]) ifTrue: [
		^ self unsignedOopForSignedOop: (aValue bitShift: 3) + 2 ].
	(aValue isCharacter) ifTrue: [
		^ self unsignedOopForSignedOop: (aValue codePoint bitShift: 3) + 6 ].
	oop := [ GbsMaterializedObjectDirtyTracker oopForObject: aValue inSession: self ] on: Error do: [ nil ].
	oop ifNotNil: [ ^ oop ].
	((aValue respondsTo: #oop) and: [ aValue oop notNil ]) ifTrue: [ ^ aValue oop ].
	(aValue isString or: [ aValue isSymbol ]) ifTrue: [
		oop := self scalarServerOopForCreationValue: aValue.
		oop ifNotNil: [ ^ oop ] ].
	GbsError signal: 'Cannot create object: value ', aValue printString, ' cannot be resolved to a server OOP.'
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> scalarServerOopForCreationValue: aValue [
	"Resolve a String/Symbol value to a server OOP via the native GCI scalar-resolution path used by the
	dirty-store traversal buffer."
	| serverInterface oop |
	serverInterface := self serverInterface.
	((serverInterface respondsTo: #supportsNativeScalarOopResolution)
		and: [ serverInterface supportsNativeScalarOopResolution ]) ifFalse: [ ^ nil ].
	oop := [
		aValue isSymbol
			ifTrue: [ serverInterface apiGciNewSymbol: aValue asString ]
			ifFalse: [ serverInterface apiGciNewString: aValue asString ] ]
		on: Error
		do: [ ^ nil ].
	((oop isNil) or: [ oop asInteger = 1 ]) ifTrue: [ ^ nil ].
	^ self unsignedOopForSignedOop: oop asInteger
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> unsignedOopForSignedOop: anInteger [
	anInteger >= 0 ifTrue: [ ^ anInteger ].
	^ (1 bitShift: 64) + anInteger
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> flushDirtyMaterializedObjects [
	^ GbsMaterializedObjectDirtyTracker flushDirtyForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> dirtyStoreTraversalReport [
	^ GbsDirtyReplicateStoreTraversal dirtyStoreTraversalReportForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> eventController [
	^ GbsSessionEventController forSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> eventControllerReport [
	^ self eventController eventReport
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> eventControllerReportText [
	^ self eventController eventReportText
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> nativeMaterializationTraversalCapabilityReport [
	self serverInterface ifNil: [ self error: 'No server interface is available for materialization traversal.' ].
	^ self serverInterface nativeMaterializationTraversalCapabilityReport
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> nativeStoreTraversalCapabilityReport [
	self serverInterface ifNil: [ self error: 'No server interface is available for store traversal.' ].
	^ self serverInterface nativeStoreTraversalCapabilityReport
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> resetDirtyStoreTraversalReport [
	^ GbsDirtyReplicateStoreTraversal resetDirtyStoreTraversalReportForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> resetMaterializedObjectDirtyTracking [
	^ GbsMaterializedObjectDirtyTracker resetForSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> withDirtyTrackingSuspendedDo: aBlock [
	^ GbsMaterializedObjectDirtyTracker withSuspendedForSession: self do: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> faultObjectForOop: anOop [
	^ GbsSessionLifecycleManager faultObjectForOop: anOop inSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> faultObjectForOop: anOop toLevel: levelOrNil [
	^ GbsSessionLifecycleManager
		faultObjectForOop: anOop
		level: levelOrNil
		inSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> faultProxy: aProxy [
	^ GbsSessionLifecycleManager faultProxy: aProxy inSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> faultProxy: aProxy toLevel: levelOrNil [
	^ GbsSessionLifecycleManager
		faultProxy: aProxy
		level: levelOrNil
		inSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> faultFetchObjectForOop: anOop level: levelOrNil [
	^ self materializer fetchObject: anOop toLevel: levelOrNil
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> stubMaterializedObject: anObject [
	^ GbsSessionLifecycleManager stubObject: anObject inSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> stubMaterializedObjectForOop: anOop [
	^ GbsSessionLifecycleManager stubObjectForOop: anOop inSession: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> scriptMarshaller [
	^ GbsSessionScriptMarshaller on: self
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> forwardRemoteMessage: aMessage forOop: targetOop [
	| script argStrings argsArrayString |
	aMessage arguments isEmpty ifTrue: [
		script := '(Object _objectForOop: ', targetOop printString, ') perform: #', aMessage selector asString.
		^ self evaluate: script ].

	argStrings := [
		aMessage arguments collect: [ :each | self marshalArgumentToScript: each ] ]
		on: Error
		do: [ :ex |
				self error: ((ex messageText ifNil: [ ex printString ]) asString withBlanksTrimmed),
				' Forwarded selector: ', aMessage selector asString,
				' Target oop: ', targetOop asString ].
	argsArrayString := '{ ', (' . ' join: argStrings), ' }'.
	script := '(Object _objectForOop: ', targetOop printString, ') perform: #', aMessage selector asString, ' withArguments: ', argsArrayString.
	^ self evaluate: script
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
	^ self commandExecutor fetchRemoteCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary context: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchRemoteScript: scriptString context: anOop [
	^ self commandExecutor fetchRemoteScript: scriptString context: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> returnRemoteCommandOop: aRemoteCommand [
	^ self commandExecutor returnRemoteCommandOop: aRemoteCommand
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> returnRemoteCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary [
	^ self commandExecutor returnRemoteCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> serverObjectCanUnderstand: aSelector [
	^ self
		fetchRemoteCommand: (GbsRemoteCommand
			blockBody: 'Object canUnderstand: selector'
			literalBindings: (Dictionary new
				at: 'selector' put: aSelector asSymbol;
				yourself)
			oopBindings: Dictionary new)
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> serverBehavior: aBehaviorOrName canUnderstand: aSelector [
	| behaviorName |
	behaviorName := (aBehaviorOrName respondsTo: #name)
		ifTrue: [ aBehaviorOrName name asString ]
		ifFalse: [ aBehaviorOrName asString ].
	^ self
		serverBehaviorNamed: behaviorName
		canUnderstand: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> serverBehaviorNamed: behaviorName canUnderstand: aSelector [
	^ self
		fetchRemoteCommand: (GbsRemoteCommand
			blockBody: '| behavior |
behavior := System myUserProfile symbolList objectNamed: behaviorName asSymbol.
behavior ifNil: [
	behavior := GsSession currentSession resolveSymbol: behaviorName asSymbol ].
behavior notNil and: [ behavior canUnderstand: selector ]'
			literalBindings: (Dictionary new
				at: 'behaviorName' put: behaviorName asString;
				at: 'selector' put: aSelector asSymbol;
				yourself)
			oopBindings: Dictionary new)
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
	^ self materializer materializeRuntimeValue: anObject
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
	^ self materializer fetchObject: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchObject: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	^ self materializer fetchObject: anOop withProfile: aProfile depth: anInteger seen: seenOops
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchProfile [
	^ self materializer fetchProfile
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchProfile: aProfile [
	^ self materializer fetchProfile: aProfile
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> loginStone: stoneName user: username password: password [
	^ self loginCoordinator loginStone: stoneName user: username password: password
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> interpretErrorMessage: aString errorNumber: anErrorNumber [
	^ self loginCoordinator interpretErrorMessage: aString errorNumber: anErrorNumber
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> marshalArgumentToScript: anObject visited: visited [
	^ self scriptMarshaller marshalArgumentToScript: anObject visited: visited
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> resultFor: anOop [
	^ self materializer resultFor: anOop
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
GbsSession >> typedWrapperCompatibilityReportText [
	^ GbsSessionManager typedWrapperCompatibilityReportTextForSession: self
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
	^ self materializer fetchByReference
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchDeep [
	^ self materializer fetchDeep
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchLegacy [
	^ self materializer fetchLegacy
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> fetchShallow [
	^ self materializer fetchShallow
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializationProfile [
	^ self materializer materializationProfile
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializationProfile: aProfile [
	^ self materializer materializationProfile: aProfile
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> supportsMaterializationTraversalBufferTransport [
	^ (GbsMaterializationTraversalBufferReader on: self) isAvailable
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> withMaterializationProfile: aProfile do: aBlock [
	^ self materializer withMaterializationProfile: aProfile do: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> isImmediateOop: anOop [
	^ self materializer isImmediateOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializeArrayOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	^ self materializer materializeArrayOop: anOop withProfile: aProfile depth: anInteger seen: seenOops
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializeAssociationOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	^ self materializer materializeAssociationOop: anOop withProfile: aProfile depth: anInteger seen: seenOops
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializeByteArrayOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	^ self materializer materializeByteArrayOop: anOop withProfile: aProfile depth: anInteger seen: seenOops
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializeDictionaryOop: anOop identityKeys: useIdentity withProfile: aProfile depth: anInteger seen: seenOops [
	^ self materializer materializeDictionaryOop: anOop identityKeys: useIdentity withProfile: aProfile depth: anInteger seen: seenOops
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> materializeSequenceableCollectionOop: anOop using: aBlock withProfile: aProfile depth: anInteger seen: seenOops [
	^ self materializer materializeSequenceableCollectionOop: anOop using: aBlock withProfile: aProfile depth: anInteger seen: seenOops
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> proxyForOop: anOop [
	^ self materializer proxyForOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> proxyForOop: anOop serverClassName: aClassName [
	^ self materializer proxyForOop: anOop serverClassName: aClassName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> proxyForOop: anOop usingClass: proxyClass [
	^ self materializer proxyForOop: anOop usingClass: proxyClass
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> cachedProxyForOop: anOop [
	^ self materializer cachedProxyForOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> clearProxyCache [
	^ self materializer clearProxyCache
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> proxyCache [
	^ self materializer proxyCache
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteArrayElementOopAt: anInteger ofOop: anOop [
	^ self materializer remoteArrayElementOopAt: anInteger ofOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteAssociationPairOopFor: anOop [
	^ self materializer remoteAssociationPairOopFor: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteClassNameForOop: anOop [
	^ self materializer remoteClassNameForOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteCollectionAsArrayOop: anOop [
	^ self materializer remoteCollectionAsArrayOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteDictionaryAssociationsAsArrayOop: anOop [
	^ self materializer remoteDictionaryAssociationsAsArrayOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteSizeForOop: anOop [
	^ self materializer remoteSizeForOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> remoteStringValueForOop: anOop [
	^ self materializer remoteStringValueForOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectForOop: anOop [
	^ self materializer objectForOop: anOop
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
	^ self objectSpace eachObjectOf: aClassOrName do: aBlock batchSize: aSmallInteger
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
	^ self objectSpace instancesInMemoryOf: aClassOrName from: aStartIndex limit: aLimit
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
	^ self objectSpace objectsInMemoryMatching: aBlock limit: aLimit batchSize: aBatchSize
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectsInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	^ self objectSpace objectsInMemoryOf: aClassOrName from: aStartIndex limit: aLimit
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectsInMemoryOf: aClassOrName matching: aBlock [
	^ self objectSpace objectsInMemoryOf: aClassOrName matching: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> objectsInMemoryOf: aClassOrName matching: aBlock limit: aLimit batchSize: aBatchSize [
	^ self objectSpace objectsInMemoryOf: aClassOrName matching: aBlock limit: aLimit batchSize: aBatchSize
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
	^ self repository classMethodMirrorForClass: aClassOrName selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classMethodMirrorForClassNamed: aClassName selector: aSelector [
	^ self repository classMethodMirrorForClassNamed: aClassName selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classMethodObjectForClass: aClassOrName selector: aSelector [
	^ self repository classMethodObjectForClass: aClassOrName selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classUnboundMethodObjectForClass: aClassOrName selector: aSelector [
	^ self repository classUnboundMethodObjectForClass: aClassOrName selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self repository classMethodObjectForClassNamed: aClassName selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> classUnboundMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self repository classUnboundMethodObjectForClassNamed: aClassName selector: aSelector
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
	^ self repository hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString includeClassSide: includeClassSideBoolean [
	^ self repository hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString includeClassSide: includeClassSideBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString [
	^ self repository hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString includeClassSide: includeClassSideBoolean [
	^ self repository hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString includeClassSide: includeClassSideBoolean
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
	^ self repository listInstancesOf: aClassOrName limit: aSmallInteger allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self repository migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self repository previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	^ self repository previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> previewMigrationWithSubclassesOf: aTopClassOrName [
	^ self repository previewMigrationWithSubclassesOf: aTopClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> previewMigrationWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	^ self repository previewMigrationWithSubclassesOf: aTopClassOrName allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	^ self repository migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> migrateInstancesWithSubclassesOf: aTopClassOrName [
	^ self repository migrateInstancesWithSubclassesOf: aTopClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> migrateInstancesWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	^ self repository migrateInstancesWithSubclassesOf: aTopClassOrName allowAbort: aBoolean
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
	^ self repository methodMirrorForClass: aClassOrName selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> methodMirrorForClassNamed: aClassName selector: aSelector [
	^ self repository methodMirrorForClassNamed: aClassName selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> methodObjectForClass: aClassOrName selector: aSelector [
	^ self repository methodObjectForClass: aClassOrName selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> unboundMethodObjectForClass: aClassOrName selector: aSelector [
	^ self repository unboundMethodObjectForClass: aClassOrName selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> methodObjectForClassNamed: aClassName selector: aSelector [
	^ self repository methodObjectForClassNamed: aClassName selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> unboundMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self repository unboundMethodObjectForClassNamed: aClassName selector: aSelector
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
	self resetConnectionStateAfterLogout.
	GbsProxyLifecycle invalidateSession: self.
	self clearProxyCache.
	self resetMaterializedObjectDirtyTracking.
	self resetMaterializedObjectCache.
	self materializer clearRemoteClassNameCache.
	self resetMaterializationMetrics.
	GbsReplicationPolicy resetForSession: self.
	GbsSessionManager clearTypedWrapperFreshnessCacheForSession: self.
	self clearNamedObjectCache.
	GbsSessionManager clearTypedWrapperAutoloadRegistrationsForSession: self.
	self invalidateRepositoryRoots
]
