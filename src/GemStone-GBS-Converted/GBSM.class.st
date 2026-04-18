Class {
	#name : 'GBSM',
	#superclass : 'Object',
	#classInstVars : [
		'CurrentSession',
		'MainStatsEnabled',
		'CacheStatsEnabled',
		'ManagerStatResource',
		'ClientMap',
		'MemoryPolicy',
		'SessionsInInteractionCount'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'statistics' }
GBSM class >> cacheSampleIntervalMultiplier [
	^ GbxStatMonitor instance cacheSampleIntervalMultiplier
]

{ #category : 'statistics' }
GBSM class >> cacheSampleIntervalMultiplier: anInteger [
	GbxStatMonitor instance cacheSampleIntervalMultiplier: anInteger
]

{ #category : 'statistics' }
GBSM class >> cacheStatsEnabled [
	^ CacheStatsEnabled ifNil: [ CacheStatsEnabled := false ]
]

{ #category : 'statistics' }
GBSM class >> cacheStatsEnabled: aBoolean [
	CacheStatsEnabled := aBoolean
]

{ #category : 'accessing' }
GBSM class >> clientMap [
	^ ClientMap
]

{ #category : 'accessing' }
GBSM class >> clientMap: anObject [
	ClientMap := anObject
]

{ #category : 'accessing' }
GBSM class >> currentSession [
    ^ GbsSessionParameters currentSession
		ifNil: [ CurrentSession ]
]

{ #category : 'accessing' }
GBSM class >> currentSession: aSession [
    CurrentSession := aSession.
	GbsSessionParameters currentSession: aSession.
	^ aSession
]

{ #category : 'named-objects' }
GBSM class >> globals [
	^ self requireCurrentSession globals
]

{ #category : 'repository' }
GBSM class >> loadedClasses [
	^ self requireCurrentSession loadedClasses
]

{ #category : 'materialization' }
GBSM class >> fetchByReference [
	^ self requireCurrentSession fetchByReference
]

{ #category : 'materialization' }
GBSM class >> fetchDeep [
	^ self requireCurrentSession fetchDeep
]

{ #category : 'materialization' }
GBSM class >> fetchLegacy [
	^ self requireCurrentSession fetchLegacy
]

{ #category : 'materialization' }
GBSM class >> fetchProfile [
	^ self requireCurrentSession fetchProfile
]

{ #category : 'materialization' }
GBSM class >> fetchProfile: aProfile [
	^ self requireCurrentSession fetchProfile: aProfile
]

{ #category : 'materialization' }
GBSM class >> fetchShallow [
	^ self requireCurrentSession fetchShallow
]

{ #category : 'typed wrappers' }
GBSM class >> generateTypedWrapperForClient: clientClassName server: serverClassName [
	^ GbsSessionManager
		generateTypedWrapperForClient: clientClassName
		server: serverClassName
]

{ #category : 'typed wrappers' }
GBSM class >> generateTypedWrappersForConnectorPairs [
	^ GbsSessionManager generateTypedWrappersForConnectorPairs
]

{ #category : 'repository' }
GBSM class >> classHistoryOf: aClassOrName [
	^ self requireCurrentSession classHistoryOf: aClassOrName
]

{ #category : 'repository' }
GBSM class >> classMethodMirrorForClass: aClassOrName selector: aSelector [
	^ self
		requireCurrentSession
		classMethodMirrorForClass: aClassOrName
		selector: aSelector
]

{ #category : 'repository' }
GBSM class >> classMethodObjectForClass: aClassOrName selector: aSelector [
	^ self
		requireCurrentSession
		classMethodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : 'repository' }
GBSM class >> classMethodMirrorForClassNamed: aClassName selector: aSelector [
	^ self
		requireCurrentSession
		classMethodMirrorForClassNamed: aClassName
		selector: aSelector
]

{ #category : 'repository' }
GBSM class >> classMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		requireCurrentSession
		classMethodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : 'repository' }
GBSM class >> classMirrorOf: aClassOrName [
	^ self requireCurrentSession classMirrorOf: aClassOrName
]

{ #category : 'repository' }
GBSM class >> classMirrorOfNamed: aClassName [
	^ self requireCurrentSession classMirrorOfNamed: aClassName
]

{ #category : 'repository' }
GBSM class >> namespaceMirrors [
	^ self requireCurrentSession namespaceMirrors
]

{ #category : 'repository' }
GBSM class >> namespaceMirrorAtSymbolListIndex: anInteger [
	^ self requireCurrentSession namespaceMirrorAtSymbolListIndex: anInteger
]

{ #category : 'repository' }
GBSM class >> topLevelNamespaceMirror [
	^ self requireCurrentSession topLevelNamespaceMirror
]

{ #category : 'repository' }
GBSM class >> namespaceMirrorForClass: aClassOrName [
	^ self requireCurrentSession namespaceMirrorForClass: aClassOrName
]

{ #category : 'repository' }
GBSM class >> namespaceMirrorForClassNamed: aClassName [
	^ self requireCurrentSession namespaceMirrorForClassNamed: aClassName
]

{ #category : 'repository' }
GBSM class >> namespaceMirrorForObject: anObjectOrProxy [
	^ self requireCurrentSession namespaceMirrorForObject: anObjectOrProxy
]

{ #category : 'repository' }
GBSM class >> namespaceMirrorForFullName: aString [
	^ self requireCurrentSession namespaceMirrorForFullName: aString
]

{ #category : 'repository' }
GBSM class >> implementorMethodReferenceStringsForSelector: aSelectorOrString [
	^ self requireCurrentSession implementorMethodReferenceStringsForSelector: aSelectorOrString
]

{ #category : 'repository' }
GBSM class >> hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString [
	^ self requireCurrentSession
		hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
]

{ #category : 'repository' }
GBSM class >> hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString [
	^ self requireCurrentSession
		hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
]

{ #category : 'repository' }
GBSM class >> methodReferenceStringsToObject: anObject [
	^ self requireCurrentSession methodReferenceStringsToObject: anObject
]

{ #category : 'repository' }
GBSM class >> methodReferenceStringsToSymbol: aSymbolOrString [
	^ self requireCurrentSession methodReferenceStringsToSymbol: aSymbolOrString
]

{ #category : 'repository' }
GBSM class >> senderMethodReferenceStringsForSelector: aSelectorOrString [
	^ self requireCurrentSession senderMethodReferenceStringsForSelector: aSelectorOrString
]

{ #category : 'repository' }
GBSM class >> listInstancesOf: aClassOrName [
	^ self requireCurrentSession listInstancesOf: aClassOrName
]

{ #category : 'repository' }
GBSM class >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self
		requireCurrentSession
		migrateInstancesFrom: aSourceClassOrName
		to: aTargetClassOrName
]

{ #category : 'repository' }
GBSM class >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self
		requireCurrentSession
		previewMigrationFrom: aSourceClassOrName
		to: aTargetClassOrName
]

{ #category : 'repository' }
GBSM class >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	^ self
		requireCurrentSession
		previewMigrationFrom: aSourceClassOrName
		to: aTargetClassOrName
		allowAbort: aBoolean
]

{ #category : 'repository' }
GBSM class >> previewMigrationWithSubclassesOf: aTopClassOrName [
	^ self requireCurrentSession previewMigrationWithSubclassesOf: aTopClassOrName
]

{ #category : 'repository' }
GBSM class >> previewMigrationWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	^ self
		requireCurrentSession
		previewMigrationWithSubclassesOf: aTopClassOrName
		allowAbort: aBoolean
]

{ #category : 'repository' }
GBSM class >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	^ self
		requireCurrentSession
		migrateInstancesFrom: aSourceClassOrName
		to: aTargetClassOrName
		allowAbort: aBoolean
]

{ #category : 'repository' }
GBSM class >> migrateInstancesWithSubclassesOf: aTopClassOrName [
	^ self requireCurrentSession migrateInstancesWithSubclassesOf: aTopClassOrName
]

{ #category : 'repository' }
GBSM class >> migrateInstancesWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	^ self
		requireCurrentSession
		migrateInstancesWithSubclassesOf: aTopClassOrName
		allowAbort: aBoolean
]

{ #category : 'repository' }
GBSM class >> listInstancesOf: aClassOrName allowAbort: aBoolean [
	^ self requireCurrentSession listInstancesOf: aClassOrName allowAbort: aBoolean
]

{ #category : 'repository' }
GBSM class >> listInstancesOf: aClassOrName limit: aSmallInteger [
	^ self requireCurrentSession listInstancesOf: aClassOrName limit: aSmallInteger
]

{ #category : 'repository' }
GBSM class >> listInstancesOf: aClassOrName limit: aSmallInteger allowAbort: aBoolean [
	^ self
		requireCurrentSession
		listInstancesOf: aClassOrName
		limit: aSmallInteger
		allowAbort: aBoolean
]

{ #category : 'repository' }
GBSM class >> methodMirrorForClass: aClassOrName selector: aSelector [
	^ self
		requireCurrentSession
		methodMirrorForClass: aClassOrName
		selector: aSelector
]

{ #category : 'repository' }
GBSM class >> methodObjectForClass: aClassOrName selector: aSelector [
	^ self
		requireCurrentSession
		methodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : 'repository' }
GBSM class >> methodMirrorForClassNamed: aClassName selector: aSelector [
	^ self
		requireCurrentSession
		methodMirrorForClassNamed: aClassName
		selector: aSelector
]

{ #category : 'repository' }
GBSM class >> methodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		requireCurrentSession
		methodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : 'named-objects' }
GBSM class >> namedObjectAt: aName [
	^ self requireCurrentSession namedObjectAt: aName
]

{ #category : 'named-objects' }
GBSM class >> namedObjectAt: aName ifAbsent: aBlock [
	^ self requireCurrentSession namedObjectAt: aName ifAbsent: aBlock
]

{ #category : 'named-objects' }
GBSM class >> namedObjectCacheEntries [
	^ self requireCurrentSession namedObjectCacheEntries
]

{ #category : 'named-objects' }
GBSM class >> namedObjectAutoloadEntries [
	^ self requireCurrentSession namedObjectAutoloadEntries
]

{ #category : 'named-objects' }
GBSM class >> namedObjectAutoloadKeys [
	^ self requireCurrentSession namedObjectAutoloadKeys
]

{ #category : 'named-objects' }
GBSM class >> namedObjectAutoloadReportText [
	^ self requireCurrentSession namedObjectAutoloadReportText
]

{ #category : 'maglev-runtime' }
GBSM class >> rubyLoadPath [
	^ self requireCurrentSession rubyLoadPath
]

{ #category : 'maglev-runtime' }
GBSM class >> rubyLoadedFeatures [
	^ self requireCurrentSession rubyLoadedFeatures
]

{ #category : 'maglev-runtime' }
GBSM class >> rubyPersistentLoadedFeatures [
	^ self requireCurrentSession rubyPersistentLoadedFeatures
]

{ #category : 'maglev-runtime' }
GBSM class >> rubyRequireFileNamed: aString [
	^ self requireCurrentSession rubyRequireFileNamed: aString
]

{ #category : 'maglev-runtime' }
GBSM class >> rubyLoadFileNamed: aString [
	^ self requireCurrentSession rubyLoadFileNamed: aString
]

{ #category : 'maglev-runtime' }
GBSM class >> clearPersistentRubyLoadedFeatures [
	^ self requireCurrentSession clearPersistentRubyLoadedFeatures
]

{ #category : 'maglev-runtime' }
GBSM class >> rubyRuntime [
	^ self requireCurrentSession rubyRuntime
]

{ #category : 'named-objects' }
GBSM class >> namedObjectAutoloadTargetFor: aName [
	^ self requireCurrentSession namedObjectAutoloadTargetFor: aName
]

{ #category : 'named-objects' }
GBSM class >> namedObjectCacheKeys [
	^ self requireCurrentSession namedObjectCacheKeys
]

{ #category : 'named-objects' }
GBSM class >> namedObjectCacheReportText [
	^ self requireCurrentSession namedObjectCacheReportText
]

{ #category : 'named-objects' }
GBSM class >> hasCachedNamedObjectNamed: aName [
	^ self requireCurrentSession hasCachedNamedObjectNamed: aName
]

{ #category : 'named-objects' }
GBSM class >> hasNamedObjectAutoloadNamed: aName [
	^ self requireCurrentSession hasNamedObjectAutoloadNamed: aName
]

{ #category : 'named-objects' }
GBSM class >> clearNamedObjectCache [
	^ self requireCurrentSession clearNamedObjectCache
]

{ #category : 'named-objects' }
GBSM class >> clearNamedObjectAutoloads [
	^ self requireCurrentSession clearNamedObjectAutoloads
]

{ #category : 'named-objects' }
GBSM class >> registerNamedObjectAutoload: aName [
	^ self requireCurrentSession registerNamedObjectAutoload: aName
]

{ #category : 'named-objects' }
GBSM class >> registerNamedObjectAutoload: localName remote: remoteName [
	^ self
		requireCurrentSession
		registerNamedObjectAutoload: localName
		remote: remoteName
]

{ #category : 'named-objects' }
GBSM class >> unregisterNamedObjectAutoload: aName [
	^ self requireCurrentSession unregisterNamedObjectAutoload: aName
]

{ #category : 'object space' }
GBSM class >> objectForOop: anOop [
	^ self requireCurrentSession objectForOop: anOop
]

{ #category : 'object space' }
GBSM class >> objectSpace [
	^ self requireCurrentSession objectSpace
]

{ #category : 'object space' }
GBSM class >> objectSpaceDiagnostics [
	^ self requireCurrentSession objectSpaceDiagnostics
]

{ #category : 'object space' }
GBSM class >> defineFinalizerFor: anObject do: aBlock [
	^ self requireCurrentSession defineFinalizerFor: anObject do: aBlock
]

{ #category : 'object space' }
GBSM class >> eachObjectDo: aBlock [
	^ self requireCurrentSession eachObjectDo: aBlock
]

{ #category : 'object space' }
GBSM class >> eachObjectDo: aBlock batchSize: aSmallInteger [
	^ self requireCurrentSession eachObjectDo: aBlock batchSize: aSmallInteger
]

{ #category : 'object space' }
GBSM class >> eachObjectOf: aClassOrName do: aBlock [
	^ self requireCurrentSession eachObjectOf: aClassOrName do: aBlock
]

{ #category : 'object space' }
GBSM class >> eachObjectOf: aClassOrName do: aBlock batchSize: aSmallInteger [
	^ self
		requireCurrentSession
		eachObjectOf: aClassOrName
		do: aBlock
		batchSize: aSmallInteger
]

{ #category : 'object space' }
GBSM class >> allSubclassesOf: aClassOrName [
	^ self requireCurrentSession allSubclassesOf: aClassOrName
]

{ #category : 'object space' }
GBSM class >> allSubclassesOfNamed: aClassName [
	^ self requireCurrentSession allSubclassesOfNamed: aClassName
]

{ #category : 'object space' }
GBSM class >> instancesInMemoryOf: aClassOrName [
	^ self requireCurrentSession instancesInMemoryOf: aClassOrName
]

{ #category : 'object space' }
GBSM class >> instancesInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	^ self
		requireCurrentSession
		instancesInMemoryOf: aClassOrName
		from: aStartIndex
		limit: aLimit
]

{ #category : 'object space' }
GBSM class >> instancesInMemoryOfNamed: aClassName [
	^ self requireCurrentSession instancesInMemoryOfNamed: aClassName
]

{ #category : 'object space' }
GBSM class >> hasFinalizerFor: anObject [
	^ self requireCurrentSession hasFinalizerFor: anObject
]

{ #category : 'object space' }
GBSM class >> loadedClassesIncludingModules [
	^ self requireCurrentSession loadedClassesIncludingModules
]

{ #category : 'object space' }
GBSM class >> loadedClassesIncludingModules: aBoolean [
	^ self requireCurrentSession loadedClassesIncludingModules: aBoolean
]

{ #category : 'object space' }
GBSM class >> sessionStateAt: aKey [
	^ self requireCurrentSession sessionStateAt: aKey
]

{ #category : 'object space' }
GBSM class >> sessionStateAt: aKey ifAbsent: aBlock [
	^ self requireCurrentSession sessionStateAt: aKey ifAbsent: aBlock
]

{ #category : 'object space' }
GBSM class >> sessionStateAt: aKey put: anObject [
	^ self requireCurrentSession sessionStateAt: aKey put: anObject
]

{ #category : 'object space' }
GBSM class >> maglevFinalizerRegistry [
	^ self requireCurrentSession maglevFinalizerRegistry
]

{ #category : 'object space' }
GBSM class >> referencesTo: anObject [
	^ self requireCurrentSession referencesTo: anObject
]

{ #category : 'object space' }
GBSM class >> referencesToOop: anOop [
	^ self requireCurrentSession referencesToOop: anOop
]

{ #category : 'object space' }
GBSM class >> objectsInMemory [
	^ self requireCurrentSession objectsInMemory
]

{ #category : 'object space' }
GBSM class >> objectsInMemoryFrom: aStartIndex limit: aLimit [
	^ self requireCurrentSession objectsInMemoryFrom: aStartIndex limit: aLimit
]

{ #category : 'object space' }
GBSM class >> objectsInMemoryMatching: aBlock [
	^ self requireCurrentSession objectsInMemoryMatching: aBlock
]

{ #category : 'object space' }
GBSM class >> objectsInMemoryMatching: aBlock limit: aLimit batchSize: aBatchSize [
	^ self
		requireCurrentSession
		objectsInMemoryMatching: aBlock
		limit: aLimit
		batchSize: aBatchSize
]

{ #category : 'object space' }
GBSM class >> objectsInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	^ self
		requireCurrentSession
		objectsInMemoryOf: aClassOrName
		from: aStartIndex
		limit: aLimit
]

{ #category : 'object space' }
GBSM class >> objectsInMemoryOf: aClassOrName matching: aBlock [
	^ self
		requireCurrentSession
		objectsInMemoryOf: aClassOrName
		matching: aBlock
]

{ #category : 'object space' }
GBSM class >> objectsInMemoryOf: aClassOrName matching: aBlock limit: aLimit batchSize: aBatchSize [
	^ self
		requireCurrentSession
		objectsInMemoryOf: aClassOrName
		matching: aBlock
		limit: aLimit
		batchSize: aBatchSize
]

{ #category : 'object space' }
GBSM class >> undefineFinalizerFor: anObject [
	^ self requireCurrentSession undefineFinalizerFor: anObject
]

{ #category : 'typed wrappers' }
GBSM class >> typedWrapperClassForServerClassNamed: serverClassName [
	^ GbsSessionManager typedWrapperClassForServerClassNamed: serverClassName
]

{ #category : 'typed wrappers' }
GBSM class >> typedWrapperAutoloadPairs [
	^ GbsSessionManager typedWrapperAutoloadPairs
]

{ #category : 'typed wrappers' }
GBSM class >> typedWrapperAutoloadEntries [
	^ GbsSessionManager typedWrapperAutoloadEntries
]

{ #category : 'typed wrappers' }
GBSM class >> typedWrapperAutoloadReportText [
	^ GbsSessionManager typedWrapperAutoloadReportText
]

{ #category : 'typed wrappers' }
GBSM class >> registerTypedWrapperAutoloadClient: clientClassName server: serverClassName [
	^ GbsSessionManager
		registerTypedWrapperAutoloadClient: clientClassName
		server: serverClassName
]

{ #category : 'typed wrappers' }
GBSM class >> registerTypedWrapperAutoloadClient: clientClassName server: serverClassName forSession: aSession [
	^ GbsSessionManager
		registerTypedWrapperAutoloadClient: clientClassName
		server: serverClassName
		forSession: aSession
]

{ #category : 'typed wrappers' }
GBSM class >> unregisterTypedWrapperAutoloadClient: clientClassName server: serverClassName [
	^ GbsSessionManager
		unregisterTypedWrapperAutoloadClient: clientClassName
		server: serverClassName
]

{ #category : 'typed wrappers' }
GBSM class >> unregisterTypedWrapperAutoloadClient: clientClassName server: serverClassName forSession: aSession [
	^ GbsSessionManager
		unregisterTypedWrapperAutoloadClient: clientClassName
		server: serverClassName
		forSession: aSession
]

{ #category : 'typed wrappers' }
GBSM class >> clearTypedWrapperAutoloadRegistrations [
	^ GbsSessionManager clearTypedWrapperAutoloadRegistrations
]

{ #category : 'typed wrappers' }
GBSM class >> clearTypedWrapperAutoloadRegistrationsForSession: aSession [
	^ GbsSessionManager clearTypedWrapperAutoloadRegistrationsForSession: aSession
]

{ #category : 'typed wrappers' }
GBSM class >> typedWrapperRegistryEntries [
	^ GbsSessionManager typedWrapperRegistryEntries
]

{ #category : 'named-objects' }
GBSM class >> published [
	^ self requireCurrentSession published
]

{ #category : 'repository' }
GBSM class >> repository [
	^ self requireCurrentSession repository
]

{ #category : 'repository' }
GBSM class >> root [
	^ self requireCurrentSession root
]

{ #category : 'repository' }
GBSM class >> rootAt: aKey [
	^ self requireCurrentSession rootAt: aKey
]

{ #category : 'repository' }
GBSM class >> rootAt: aKey ifAbsent: aBlock [
	^ self requireCurrentSession rootAt: aKey ifAbsent: aBlock
]

{ #category : 'repository' }
GBSM class >> rootAt: aKey put: aValue [
	^ self requireCurrentSession rootAt: aKey put: aValue
]

{ #category : 'named-objects' }
GBSM class >> requireCurrentSession [
	^ self currentSession
		ifNil: [ self error: 'No current GemStone session' ]
]

{ #category : 'interactions' }
GBSM class >> beginInteraction [
	self sessionsInInteractionCount: self sessionsInInteractionCount + 1
]

{ #category : 'interactions' }
GBSM class >> endInteraction [
	self sessionsInInteractionCount: (self sessionsInInteractionCount - 1 max: 0)
]

{ #category : 'interactions' }
GBSM class >> hasSessionsInInteractions [
	^ self sessionsInInteractionCount > 0
]

{ #category : 'accessing' }
GBSM class >> loggedInSessions [
	^ GbsSessionManager loggedInSessions
]

{ #category : 'statistics' }
GBSM class >> mainStatsEnabled [
	^ MainStatsEnabled ifNil: [ MainStatsEnabled := false ]
]

{ #category : 'statistics' }
GBSM class >> mainStatsEnabled: aBoolean [
	MainStatsEnabled := aBoolean
]

{ #category : 'accessing' }
GBSM class >> memoryPolicy [
	^ MemoryPolicy
]

{ #category : 'accessing' }
GBSM class >> memoryPolicy: anObject [
	MemoryPolicy := anObject
]

{ #category : 'cleanup' }
GBSM class >> reset [
    CurrentSession := nil.
	GbsSessionParameters currentSession: nil.
	MainStatsEnabled := false.
	CacheStatsEnabled := false.
	ManagerStatResource := nil.
	ClientMap := nil.
	MemoryPolicy := nil.
	SessionsInInteractionCount := 0
]

{ #category : 'ui' }
GBSM class >> showBusyWhile: aBlock [
	^ aBlock value
]

{ #category : 'statistics' }
GBSM class >> statMonitorRunning [
	^ GbxStatMonitor instance isProcessRunning
]

{ #category : 'statistics' }
GBSM class >> statMonitorRunning: aBoolean [
	aBoolean
		ifTrue: [ GbxStatMonitor instance startProcess ]
		ifFalse: [ GbxStatMonitor instance stopProcess ]
]

{ #category : 'statistics' }
GBSM class >> statResource [
	^ ManagerStatResource ifNil: [ ManagerStatResource := GbxSessionManagerStatResource new ]
]

{ #category : 'statistics' }
GBSM class >> statSampleInterval [
	^ GbxStatMonitor instance sampleInterval
]

{ #category : 'statistics' }
GBSM class >> statSampleInterval: milliseconds [
	GbxStatMonitor instance sampleInterval: milliseconds
]

{ #category : 'statistics' }
GBSM class >> statsEnabled [
	^ self mainStatsEnabled or: [ self cacheStatsEnabled ]
]

{ #category : 'statistics' }
GBSM class >> statsEnabled: aBoolean [
	self
		mainStatsEnabled: aBoolean;
		cacheStatsEnabled: aBoolean;
		statMonitorRunning: aBoolean
]

{ #category : 'named-objects' }
GBSM class >> sessionForwarderFor: aSymbol [
	^ self requireCurrentSession sessionForwarderFor: aSymbol
]

{ #category : 'interactions' }
GBSM class >> sessionsInInteractionCount [
	^ SessionsInInteractionCount ifNil: [ SessionsInInteractionCount := 0 ]
]

{ #category : 'interactions' }
GBSM class >> sessionsInInteractionCount: anInteger [
	SessionsInInteractionCount := anInteger max: 0
]

{ #category : 'named-objects' }
GBSM class >> userClasses [
	^ self requireCurrentSession userClasses
]

{ #category : 'named-objects' }
GBSM class >> userGlobals [
	^ self requireCurrentSession userGlobals
]
