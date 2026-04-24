Extension { #name : 'GBSM' }

{ #category : '*GemStone-GBS-Core' }
GBSM class >> bridgeRoot [
	^ self requireCurrentSession bridgeRoot
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> generateTypedWrapperForClient: clientClassName server: serverClassName [
	^ GbsSessionManager
		generateTypedWrapperForClient: clientClassName
		server: serverClassName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> generateTypedWrappersForConnectorPairs [
	^ GbsSessionManager generateTypedWrappersForConnectorPairs
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> commitTransactionOrSignalConflict [
	^ self requireCurrentSession commitTransactionOrSignalConflict
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> commitTransactionWithRetryCount: aRetryCount [
	^ self requireCurrentSession commitTransactionWithRetryCount: aRetryCount
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> loadedClasses [
	^ self requireCurrentSession loadedClasses
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> chunkedMigrationRunnerFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self requireCurrentSession
		chunkedMigrationRunnerFrom: aSourceClassOrName
		to: aTargetClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> smalltalk [
	^ self requireCurrentSession smalltalk
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> fetchByReference [
	^ self requireCurrentSession fetchByReference
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> fetchDeep [
	^ self requireCurrentSession fetchDeep
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> fetchLegacy [
	^ self requireCurrentSession fetchLegacy
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> fetchProfile [
	^ self requireCurrentSession fetchProfile
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> fetchProfile: aProfile [
	^ self requireCurrentSession fetchProfile: aProfile
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> fetchShallow [
	^ self requireCurrentSession fetchShallow
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namedObjectAt: aName [
	^ self requireCurrentSession namedObjectAt: aName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namedObjectAt: aName ifAbsent: aBlock [
	^ self requireCurrentSession namedObjectAt: aName ifAbsent: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> typedWrapperLifecycleEntries [
	^ GbsSessionManager
		typedWrapperLifecycleEntriesForSession: self currentSession
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> typedWrapperLifecycleObjects [
	^ GbsSessionManager
		typedWrapperLifecycleObjectsForSession: self currentSession
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> typedWrapperLifecycleReport [
	^ GbsSessionManager
		typedWrapperLifecycleReportForSession: self currentSession
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> typedWrapperLifecycleReportText [
	^ GbsSessionManager
		typedWrapperLifecycleReportTextForSession: self currentSession
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> invalidateStaleTypedWrapperClasses [
	^ GbsSessionManager
		invalidateStaleTypedWrapperClassesForSession: self currentSession
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> refreshStaleTypedWrapperClasses [
	^ GbsSessionManager
		refreshStaleTypedWrapperClassesForSession: self currentSession
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> refreshAllTypedWrapperClasses [
	^ GbsSessionManager
		refreshAllTypedWrapperClassesForSession: self currentSession
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> typedWrapperClassForServerClassNamed: serverClassName [
	^ GbsSessionManager typedWrapperClassForServerClassNamed: serverClassName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> typedWrapperAutoloadPairs [
	^ GbsSessionManager typedWrapperAutoloadPairs
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> typedWrapperAutoloadEntries [
	^ GbsSessionManager typedWrapperAutoloadEntries
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> typedWrapperAutoloadReportText [
	^ GbsSessionManager typedWrapperAutoloadReportText
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> registerTypedWrapperAutoloadClient: clientClassName server: serverClassName [
	^ GbsSessionManager
		registerTypedWrapperAutoloadClient: clientClassName
		server: serverClassName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> registerTypedWrapperAutoloadClient: clientClassName server: serverClassName forSession: aSession [
	^ GbsSessionManager
		registerTypedWrapperAutoloadClient: clientClassName
		server: serverClassName
		forSession: aSession
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> unregisterTypedWrapperAutoloadClient: clientClassName server: serverClassName [
	^ GbsSessionManager
		unregisterTypedWrapperAutoloadClient: clientClassName
		server: serverClassName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> unregisterTypedWrapperAutoloadClient: clientClassName server: serverClassName forSession: aSession [
	^ GbsSessionManager
		unregisterTypedWrapperAutoloadClient: clientClassName
		server: serverClassName
		forSession: aSession
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> clearTypedWrapperAutoloadRegistrations [
	^ GbsSessionManager clearTypedWrapperAutoloadRegistrations
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> clearTypedWrapperAutoloadRegistrationsForSession: aSession [
	^ GbsSessionManager clearTypedWrapperAutoloadRegistrationsForSession: aSession
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> typedWrapperRegistryEntries [
	^ GbsSessionManager typedWrapperRegistryEntries
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namedObjectCacheEntries [
	^ self requireCurrentSession namedObjectCacheEntries
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namedObjectAutoloadEntries [
	^ self requireCurrentSession namedObjectAutoloadEntries
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namedObjectAutoloadKeys [
	^ self requireCurrentSession namedObjectAutoloadKeys
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namedObjectAutoloadReportText [
	^ self requireCurrentSession namedObjectAutoloadReportText
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namedObjectAutoloadTargetFor: aName [
	^ self requireCurrentSession namedObjectAutoloadTargetFor: aName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namedObjectCacheKeys [
	^ self requireCurrentSession namedObjectCacheKeys
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namedObjectCacheReportText [
	^ self requireCurrentSession namedObjectCacheReportText
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> hasCachedNamedObjectNamed: aName [
	^ self requireCurrentSession hasCachedNamedObjectNamed: aName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> hasNamedObjectAutoloadNamed: aName [
	^ self requireCurrentSession hasNamedObjectAutoloadNamed: aName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> clearNamedObjectCache [
	^ self requireCurrentSession clearNamedObjectCache
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> clearNamedObjectAutoloads [
	^ self requireCurrentSession clearNamedObjectAutoloads
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> registerNamedObjectAutoload: aName [
	^ self requireCurrentSession registerNamedObjectAutoload: aName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> registerNamedObjectAutoload: localName remote: remoteName [
	^ self
		requireCurrentSession
		registerNamedObjectAutoload: localName
		remote: remoteName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> unregisterNamedObjectAutoload: aName [
	^ self requireCurrentSession unregisterNamedObjectAutoload: aName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectSpaceRepository [
	^ self requireCurrentSession objectSpaceRepository
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectForOop: anOop [
	^ self requireCurrentSession objectForOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectSpace [
	^ self requireCurrentSession objectSpace
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectSpaceDiagnostics [
	^ self requireCurrentSession objectSpaceDiagnostics
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectSpaceDiagnosticsReport [
	^ self requireCurrentSession objectSpaceDiagnosticsReport
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> defineFinalizerFor: anObject do: aBlock [
	^ self requireCurrentSession defineFinalizerFor: anObject do: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> eachObjectDo: aBlock [
	^ self requireCurrentSession eachObjectDo: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> eachObjectDo: aBlock batchSize: aSmallInteger [
	^ self requireCurrentSession eachObjectDo: aBlock batchSize: aSmallInteger
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> eachObjectOf: aClassOrName do: aBlock [
	^ self requireCurrentSession eachObjectOf: aClassOrName do: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> eachObjectOf: aClassOrName do: aBlock batchSize: aSmallInteger [
	^ self
		requireCurrentSession
		eachObjectOf: aClassOrName
		do: aBlock
		batchSize: aSmallInteger
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> allSubclassesOf: aClassOrName [
	^ self requireCurrentSession allSubclassesOf: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> allSubclassesOfNamed: aClassName [
	^ self requireCurrentSession allSubclassesOfNamed: aClassName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> instancesInMemoryOf: aClassOrName [
	^ self requireCurrentSession instancesInMemoryOf: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> instancesInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	^ self
		requireCurrentSession
		instancesInMemoryOf: aClassOrName
		from: aStartIndex
		limit: aLimit
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> instancesInMemoryOfNamed: aClassName [
	^ self requireCurrentSession instancesInMemoryOfNamed: aClassName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> hasFinalizerFor: anObject [
	^ self requireCurrentSession hasFinalizerFor: anObject
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> loadedClassesIncludingModules [
	^ self requireCurrentSession loadedClassesIncludingModules
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> loadedClassesIncludingModules: aBoolean [
	^ self requireCurrentSession loadedClassesIncludingModules: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> sessionStateAt: aKey [
	^ self requireCurrentSession sessionStateAt: aKey
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> sessionStateAt: aKey ifAbsent: aBlock [
	^ self requireCurrentSession sessionStateAt: aKey ifAbsent: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> sessionStateAt: aKey put: anObject [
	^ self requireCurrentSession sessionStateAt: aKey put: anObject
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> referencesTo: anObject [
	^ self requireCurrentSession referencesTo: anObject
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> referencesToOop: anOop [
	^ self requireCurrentSession referencesToOop: anOop
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectsInMemory [
	^ self requireCurrentSession objectsInMemory
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectsInMemoryFrom: aStartIndex limit: aLimit [
	^ self requireCurrentSession objectsInMemoryFrom: aStartIndex limit: aLimit
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectsInMemoryMatching: aBlock [
	^ self requireCurrentSession objectsInMemoryMatching: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectsInMemoryMatching: aBlock limit: aLimit batchSize: aBatchSize [
	^ self
		requireCurrentSession
		objectsInMemoryMatching: aBlock
		limit: aLimit
		batchSize: aBatchSize
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectsInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	^ self
		requireCurrentSession
		objectsInMemoryOf: aClassOrName
		from: aStartIndex
		limit: aLimit
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectsInMemoryOf: aClassOrName matching: aBlock [
	^ self
		requireCurrentSession
		objectsInMemoryOf: aClassOrName
		matching: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> objectsInMemoryOf: aClassOrName matching: aBlock limit: aLimit batchSize: aBatchSize [
	^ self
		requireCurrentSession
		objectsInMemoryOf: aClassOrName
		matching: aBlock
		limit: aLimit
		batchSize: aBatchSize
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> undefineFinalizerFor: anObject [
	^ self requireCurrentSession undefineFinalizerFor: anObject
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> classHistoryOf: aClassOrName [
	^ self requireCurrentSession classHistoryOf: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> classMethodMirrorForClass: aClassOrName selector: aSelector [
	^ self
		requireCurrentSession
		classMethodMirrorForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> classMethodMirrorForClassNamed: aClassName selector: aSelector [
	^ self
		requireCurrentSession
		classMethodMirrorForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> classMethodObjectForClass: aClassOrName selector: aSelector [
	^ self
		requireCurrentSession
		classMethodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> classUnboundMethodObjectForClass: aClassOrName selector: aSelector [
	^ self
		requireCurrentSession
		classUnboundMethodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> classMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		requireCurrentSession
		classMethodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> classUnboundMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		requireCurrentSession
		classUnboundMethodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> classMirrorOf: aClassOrName [
	^ self requireCurrentSession classMirrorOf: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> classMirrorOfNamed: aClassName [
	^ self requireCurrentSession classMirrorOfNamed: aClassName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namespaceMirrors [
	^ self requireCurrentSession namespaceMirrors
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namespaceMirrorAtSymbolListIndex: anInteger [
	^ self requireCurrentSession namespaceMirrorAtSymbolListIndex: anInteger
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> topLevelNamespaceMirror [
	^ self requireCurrentSession topLevelNamespaceMirror
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namespaceMirrorForClass: aClassOrName [
	^ self requireCurrentSession namespaceMirrorForClass: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namespaceMirrorForClassNamed: aClassName [
	^ self requireCurrentSession namespaceMirrorForClassNamed: aClassName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namespaceMirrorForObject: anObjectOrProxy [
	^ self requireCurrentSession namespaceMirrorForObject: anObjectOrProxy
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> namespaceMirrorForFullName: aString [
	^ self requireCurrentSession namespaceMirrorForFullName: aString
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> implementorMethodReferenceStringsForSelector: aSelectorOrString [
	^ self requireCurrentSession implementorMethodReferenceStringsForSelector: aSelectorOrString
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString [
	^ self requireCurrentSession
		hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString [
	^ self requireCurrentSession
		hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> methodReferenceStringsToObject: anObject [
	^ self requireCurrentSession methodReferenceStringsToObject: anObject
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> methodReferenceStringsToSymbol: aSymbolOrString [
	^ self requireCurrentSession methodReferenceStringsToSymbol: aSymbolOrString
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> senderMethodReferenceStringsForSelector: aSelectorOrString [
	^ self requireCurrentSession senderMethodReferenceStringsForSelector: aSelectorOrString
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> listInstancesOf: aClassOrName [
	^ self requireCurrentSession listInstancesOf: aClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self
		requireCurrentSession
		migrateInstancesFrom: aSourceClassOrName
		to: aTargetClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self
		requireCurrentSession
		previewMigrationFrom: aSourceClassOrName
		to: aTargetClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	^ self
		requireCurrentSession
		previewMigrationFrom: aSourceClassOrName
		to: aTargetClassOrName
		allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> previewMigrationWithSubclassesOf: aTopClassOrName [
	^ self requireCurrentSession previewMigrationWithSubclassesOf: aTopClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> previewMigrationWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	^ self
		requireCurrentSession
		previewMigrationWithSubclassesOf: aTopClassOrName
		allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	^ self
		requireCurrentSession
		migrateInstancesFrom: aSourceClassOrName
		to: aTargetClassOrName
		allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> migrateInstancesWithSubclassesOf: aTopClassOrName [
	^ self requireCurrentSession migrateInstancesWithSubclassesOf: aTopClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> migrateInstancesWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	^ self
		requireCurrentSession
		migrateInstancesWithSubclassesOf: aTopClassOrName
		allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> listInstancesOf: aClassOrName allowAbort: aBoolean [
	^ self requireCurrentSession listInstancesOf: aClassOrName allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> listInstancesOf: aClassOrName limit: aSmallInteger [
	^ self requireCurrentSession listInstancesOf: aClassOrName limit: aSmallInteger
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> listInstancesOf: aClassOrName limit: aSmallInteger allowAbort: aBoolean [
	^ self
		requireCurrentSession
		listInstancesOf: aClassOrName
		limit: aSmallInteger
		allowAbort: aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> methodMirrorForClass: aClassOrName selector: aSelector [
	^ self
		requireCurrentSession
		methodMirrorForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> methodMirrorForClassNamed: aClassName selector: aSelector [
	^ self
		requireCurrentSession
		methodMirrorForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> methodObjectForClass: aClassOrName selector: aSelector [
	^ self
		requireCurrentSession
		methodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> unboundMethodObjectForClass: aClassOrName selector: aSelector [
	^ self
		requireCurrentSession
		unboundMethodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> methodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		requireCurrentSession
		methodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> unboundMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		requireCurrentSession
		unboundMethodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GBSM class >> repository [
	^ self requireCurrentSession repository
]
