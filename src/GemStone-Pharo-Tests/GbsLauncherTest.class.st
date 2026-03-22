Class {
	#name : 'GbsLauncherTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousCurrentSession',
		'previousSessions'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsLauncherTest >> setUp [
	super setUp.
	previousCurrentSession := GbsSessionParameters currentSession.
	previousSessions := GbsSessionParameters allSessions copy.
	GbsSessionParameters allSessions removeAll.
	GbsSessionParameters currentSession: nil
]

{ #category : 'running' }
GbsLauncherTest >> tearDown [
	GbsSessionParameters currentSession: previousCurrentSession.
	GbsSessionParameters allSessions removeAll.
	GbsSessionParameters allSessions addAll: previousSessions.
	super tearDown
]

{ #category : 'tests' }
GbsLauncherTest >> testActiveSessionParametersFallsBackToConnectedRegistryEntry [
	| connectedParam disconnectedParam launcher |
	launcher := GbsLauncher basicNew.
	connectedParam := GbsSessionParameters new.
	connectedParam gemStoneName: 'gs64stone'.
	connectedParam instVarNamed: 'sessionId' put: 123.
	disconnectedParam := GbsSessionParameters new.
	disconnectedParam gemStoneName: 'otherStone'.
	GbsSessionParameters allSessions
		add: disconnectedParam;
		add: connectedParam.
	self assert: launcher activeSessionParameters == connectedParam
]

{ #category : 'tests' }
GbsLauncherTest >> testActiveSessionParametersUsesCurrentSessionIdMatch [
	| connectedParam current launcher otherParam |
	launcher := GbsLauncher basicNew.
	otherParam := GbsSessionParameters new.
	otherParam gemStoneName: 'otherStone'.
	otherParam instVarNamed: 'sessionId' put: 7.
	connectedParam := GbsSessionParameters new.
	connectedParam gemStoneName: 'gs64stone'.
	connectedParam instVarNamed: 'sessionId' put: 123.
	GbsSessionParameters allSessions
		add: otherParam;
		add: connectedParam.
	current := MockGbsSession new.
	current sessionId: 123.
	current isLoggedIn: true.
	GbsSessionParameters currentSession: current.
	self assert: launcher activeSessionParameters == connectedParam
]

{ #category : 'tests' }
GbsLauncherTest >> testAllSessionsRemovesClosureCandidate [
	GbsSessionParameters allSessions add: [ :ignored | ignored ].
	self assert: GbsSessionParameters allSessions isEmpty
]

{ #category : 'tests' }
GbsLauncherTest >> testAdminSessionSupportResolvesLiveSessionFromParameterRecord [
	| params liveSession resolved |
	[
		GBSM reset.
		params := GbsSessionParameters new.
		params sessionId: 7.
		liveSession := GbsSessionSupportFakeLiveSession new.
		liveSession
			sessionId: 7;
			parameters: params;
			isLoggedIn: true.
		GBSM manager privAddSession: liveSession.
		GbsSessionParameters currentSession: params.

		resolved := GbsAdminSessionSupport currentUsableSession.

		self assert: resolved == liveSession.
		self assert: GbsSessionParameters currentSession == liveSession
	] ensure: [ GBSM reset ]
]

{ #category : 'tests' }
GbsLauncherTest >> testAdminSessionSupportFallsBackToConnectedRegistryEntryWhenCurrentMissing [
	| params liveSession resolved |
	[
		GBSM reset.
		params := GbsSessionParameters new.
		params sessionId: 8.
		GbsSessionParameters registerSession: params.
		liveSession := GbsSessionSupportFakeLiveSession new.
		liveSession
			sessionId: 8;
			parameters: params;
			isLoggedIn: true.
		GBSM manager privAddSession: liveSession.
		GbsSessionParameters currentSession: nil.

		resolved := GbsAdminSessionSupport currentUsableSession.

		self assert: resolved == liveSession.
		self assert: GbsSessionParameters currentSession == liveSession
	] ensure: [ GBSM reset ]
]

{ #category : 'tests' }
GbsLauncherTest >> testAdminSessionSupportResolvesCurrentFakeCandidateViaLiveSession [
	| candidate liveSession resolved |
	[
		GBSM reset.
		candidate := GbsSessionSupportFakeCandidate new.
		liveSession := GbsSessionSupportFakeLiveSession new.
		liveSession
			sessionId: 17;
			isLoggedIn: true.
		candidate liveSession: liveSession.
		GbsSessionParameters currentSession: candidate.

		resolved := GbsAdminSessionSupport currentUsableSession.

		self assert: resolved == liveSession.
		self assert: GbsSessionParameters currentSession == liveSession
	] ensure: [ GBSM reset ]
]

{ #category : 'tests' }
GbsLauncherTest >> testAdminSessionSupportFormatsSessionTitlesSafely [
	| session |
	session := GbsSessionSupportFakeLiveSession new.
	session sessionId: 12.

	self assert: (GbsAdminSessionSupport sessionIdStringFrom: nil) equals: ''.
	self assert: (GbsAdminSessionSupport sessionTitlePrefixFor: nil) equals: ''.
	self assert: (GbsAdminSessionSupport sessionIdStringFrom: session) equals: '12'.
	self assert: (GbsAdminSessionSupport sessionTitlePrefixFor: session) equals: 'Session 12 '
]

{ #category : 'tests' }
GbsLauncherTest >> testSessionManagerIgnoresDependentErrorsDuringSessionAnnouncements [
	| dependent manager session |
	[
		GBSM reset.
		manager := GBSM manager.
		dependent := GbsBrokenDependent new.
		manager addDependent: dependent.
		session := MockGbsSession new.
		session
			sessionId: 21;
			isLoggedIn: true.

		self shouldnt: [ manager currentSession: session ] raise: Error.
		self shouldnt: [ manager notifyOfAddedSession: session ] raise: Error
	] ensure: [
		GBSM removeDependent: dependent.
		GBSM reset ]
]

{ #category : 'tests' }
GbsLauncherTest >> testAdminSessionSupportResolvesRegistryFakeCandidateViaLiveSession [
	| candidate liveSession resolved |
	[
		GBSM reset.
		candidate := GbsSessionSupportFakeCandidate new.
		liveSession := GbsSessionSupportFakeLiveSession new.
		liveSession
			sessionId: 18;
			isLoggedIn: true.
		candidate liveSession: liveSession.
		GbsSessionParameters currentSession: nil.
		GbsSessionParameters registerSession: candidate.

		resolved := GbsAdminSessionSupport currentUsableSession.

		self assert: resolved == liveSession.
		self assert: GbsSessionParameters currentSession == liveSession
	] ensure: [ GBSM reset ]
]

{ #category : 'tests' }
GbsLauncherTest >> testReplicatorManagerKeepsRuntimeApiAndShape [
	self assert: (GbxReplicatorManager respondsTo: #newForSession:).
	self
		assert: GbxReplicatorManager instVarNames
		equals: #(session serverMap clientMap needServerInstVarNames replicatorsNeedingServerInstVarNames clampManager).
	self assert: (Smalltalk at: #GbxReplicatorManagerTool ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testArrayReplicatorSkipsDeferredServerInstVarFetchQueue [
	| manager replicator |
	manager := GbxReplicatorManagerInitFake new.

	replicator := GbxArrayReplicator
		forClientClass: Array
		serverClass: Object
		manager: manager.

	self assert: manager queuedReplicators isEmpty.
	self assert: replicator isComplete.
	self
		assert: (replicator instVarNamed: 'serverInstVarNames')
		equals: #().
	self
		assert: (replicator instVarNamed: 'serverToClientOffsets')
		equals: #()
]

{ #category : 'tests' }
GbsLauncherTest >> testBehaviorOopMapKeepsRuntimeApiAndToolVariants [
	self assert: (GbxBehaviorOopMap respondsTo: #newForSession:).
	self assert: GbxBehaviorOopMap superclass equals: GbxOopKeyedDictionary.
	self assert: GbxBehaviorOopMapNode superclass equals: GbxOopKeyedNode.
	self assert: GbxBehaviorMapTableSegment superclass equals: GbxHashTableSegment.
	self assert: (Smalltalk at: #GbxBehaviorOopMapTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxBehaviorOopMapNodeTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxBehaviorMapTableSegmentTool ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testGbxObjectListSupportsVariableSizedConstructors [
	| pair trio |
	self assert: GbxObjectList isVariable.

	pair := GbxObjectList with: 1 with: 2.
	self assert: pair size equals: 2.
	self assert: (pair at: 1) equals: 1.
	self assert: (pair at: 2) equals: 2.

	trio := GbxObjectList withAll: #(1 2 3).
	self assert: trio size equals: 3.
	self assert: trio asArray equals: #(1 2 3)
]

{ #category : 'tests' }
GbsLauncherTest >> testClampManagerKeepsRuntimeApiAndToolVariant [
	self assert: (GbxClampManager respondsTo: #forManager:).
	self
		assert: GbxClampManager instVarNames
		equals: #(classClamps defaultReplicationScheme identityClamps manager replicationSchemes threadSpecificSchemes).
	self assert: (Smalltalk at: #GbxClampManagerTool ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testServerMapKeepsRuntimeApiAndToolVariants [
	self assert: (GbxServerMap respondsTo: #newForSession:).
	self assert: GbxServerMap superclass equals: GbxOopKeyedDictionary.
	self assert: GbxServerMapNode superclass equals: GbxOopKeyedNode.
	self assert: GbxServerMapTableSegment superclass equals: GbxHashTableSegment.
	self assert: (Smalltalk at: #GbxServerMapTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxServerMapNodeTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxServerMapAuditResultsTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxServerMapTableSegmentTool ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testDebuggerToolClassesKeepRuntimeVariantsSeparated [
	self assert: GbxActivation superclass equals: Object.
	self assert: GbxContextInspector superclass equals: Object.
	self assert: GbxStackInspector superclass equals: GbxContextInspector.
	self assert: GbxReceiverInspector superclass equals: GbxContextInspector.
	self assert: GbxBreakPoint instVarNames equals: #(selector remoteClass stepPoint).
	self assert: (Smalltalk at: #GbxActivationTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxContextInspectorTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxStackInspectorTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxReceiverInspectorTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxBreakPointTool ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testLoggingAndDeferredToolClassesKeepRuntimeVariantsSeparated [
	self assert: GbxLogger instVarNames equals: #(filename).
	self assert: GbxDeferredAssignment instVarNames equals: #(clientOffset delegate buffer).
	self assert: GbxObjectMemoryStat superclass equals: GbxStat.
	self assert: (Smalltalk at: #GbxLoggerTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxFileLoggerTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxMemoryLoggerTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxDeferredAssignmentTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxDeferredIndexedAssignmentTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxDeferredNamedAssignmentTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxKeyValueFaulterTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxObjectMemoryStatTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxExecBlockTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxExecBlock0Tool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxExecBlock1Tool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxExecBlock2Tool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxExecBlock3Tool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxExecBlock4Tool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxExecBlock5Tool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxExecBlockNTool ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testEventDetectorKeepsRuntimeApiAndToolVariants [
	self assert: GbxEventDetector superclass equals: Object.
	self
		assert: GbxEventDetector instVarNames
		equals: #(callSequencer process runningProtect session).
	self assert: GbxWaitingEventDetector superclass equals: GbxEventDetector.
	self assert: GbxPollingEventDetector superclass equals: GbxEventDetector.
	self assert: (Smalltalk at: #GbxEventDetectorTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxWaitingEventDetectorTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxPollingEventDetectorTool ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testCompatibilityResolverAcceptsStringNames [
	self assert: (Object gbxResolve: 'GbxServerMap') equals: GbxServerMap.
	self assert: (Object gbxResolve: 'OArray' in: #SpecialGemStoneObjects) notNil.
	self assert: (Object gbxBindingFor: 'Object') notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testCoreCompatibilityAliasesAndStubsExist [
	self assert: (Smalltalk at: #LimitedPrecisionReal) equals: Float.
	self assert: (Smalltalk at: #GbxArray) equals: Array.
	self assert: (Smalltalk at: #GbxMethodErrorHolder ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #Notifier ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #ProcessHandle ifAbsent: [ nil ]) notNil.
	self assert: (GbsSession canUnderstand: #isConnected).
	self assert: LargeGrainMemoryPolicy instVarNames equals: #(memoryStatus)
]

{ #category : 'tests' }
GbsLauncherTest >> testConnectorTypesUsePerClassCaching [
	self assert: GbsNameConnector type equals: #Name.
	self assert: GbsFastConnector type equals: #Fast
]

{ #category : 'tests' }
GbsLauncherTest >> testPharoDefaultsUseBlockingRpc [
	self assert: GbsConfiguration new blockingProtocolRpc
]

{ #category : 'tests' }
GbsLauncherTest >> testDateInstVarMapDoesNotUseVisualWorksDaySlot [
	self
		assert:
			(Date instVarMap
				noneSatisfy: [ :mapping | (mapping at: 1 ifAbsent: [ nil ]) = #day ])
]

{ #category : 'tests' }
GbsLauncherTest >> testUnauthorizedReplicatorKeepsRuntimeApiAndToolVariant [
	self assert: (GbxUnauthorizedObjectReplicator respondsTo: #newForManager:).
	self assert: GbxUnauthorizedObjectReplicator superclass equals: GbxObjectReplicator.
	self assert: (Smalltalk at: #GbxUnauthorizedObjectReplicatorTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxArrayReplicatorTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxClassReplicatorTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxDeferredElementsReplicatorTool ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testBasicCacheKeepsRuntimeApiAndToolVariants [
	self assert: GbxBasicCache superclass equals: GbxCollectionCache.
	self
		assert: GbxBasicCache instVarNames
		equals: #(oopToProxy proxyToOop session hitCount missCount proxyCount maxProxies weakRegistry).
	self
		assert: GbxCollectionCache instVarNames
		equals: #(cache statistics).
	self assert: (Smalltalk at: #GbxBasicCacheTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxCollectionCacheTool ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testTraversalClassesKeepRuntimeApiAndToolVariants [
	self assert: GbxStoreTraversal superclass equals: GbxTraversal.
	self
		assert: GbxStoreTraversal instVarNames
		equals: #(session packedNotYetAccepted).
	self assert: GbxFetchTraversal superclass equals: GbxTraversal.
	self
		assert: GbxFetchTraversal instVarNames
		equals: #(serverInterface traversalCompleted).
	self assert: (Smalltalk at: #GbxStoreTraversalTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxFetchTraversalTool ifAbsent: [ nil ]) notNil.
	self
		assert: (GbxFetchTraversal class
			compiledMethodAt: #for:
			ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testStatsClassesKeepRuntimeApiAndToolVariants [
	self
		assert: (GbxStatDescriptor respondsTo: #name:description:type:isCounter:isLargerBetter:unit:).
	self
		assert: GbxStatDescriptor instVarNames
		equals: #(type id name description isCounter isLargerBetter unit category statClass).
	self
		assert: GbxStatResource instVarNames
		equals: #(instanceId stats).
	self assert: GbxStatMonitor superclass equals: Object.
	self
		assert: GbxStatMonitor instVarNames
		equals: #(process state stateChangeProtect nextResumption delay archiver sampleInterval cacheSampleIntervalMultiplier).
	self assert: (GbxStatMonitor respondsTo: #instance).
	self assert: (Smalltalk at: #GbxToolStat ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxToolStatDescriptor ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxToolStatResource ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxToolStatMonitor ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxToolSessionStatResource ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testCompatibilityBootstrapInstallsPlaceholdersAndNamespace [
	| specials |
	GbsPharoBootstrap installCompatibilityAliases.

	specials := Smalltalk at: #SpecialGemStoneObjects.
	self assert: (Smalltalk globals includesKey: #SpecialGemStoneObjects).
	self assert: (Smalltalk globals includesKey: #NotCachedToken).
	self assert: (Smalltalk globals includesKey: #GSClipboard).
	self assert: (Smalltalk globals includesKey: #OObject).
	self assert: (Smalltalk globals includesKey: #Filename).
	self assert: (Smalltalk at: #Filename) equals: GbxFilename.
	self assert: (specials isKindOf: GbsCompatibilityNamespace).
	self assert: (specials at: #NotCachedToken) equals: (Smalltalk at: #NotCachedToken)
]

{ #category : 'tests' }
GbsLauncherTest >> testCompatibilityBootstrapInitializeInstallsAliasesForDirectLoads [
	| hadFilename previousFilename hadSpecials previousSpecials |
	hadFilename := Smalltalk globals includesKey: #Filename.
	previousFilename := Smalltalk at: #Filename ifAbsent: [ nil ].
	hadSpecials := Smalltalk globals includesKey: #SpecialGemStoneObjects.
	previousSpecials := Smalltalk at: #SpecialGemStoneObjects ifAbsent: [ nil ].

	[
		Smalltalk globals removeKey: #Filename ifAbsent: [ ].
		Smalltalk globals removeKey: #SpecialGemStoneObjects ifAbsent: [ ].

		GbsPharoBootstrap initialize.

		self assert: (Smalltalk globals includesKey: #Filename).
		self assert: (Smalltalk globals includesKey: #SpecialGemStoneObjects)
	] ensure: [
		hadFilename
			ifTrue: [ Smalltalk at: #Filename put: previousFilename ]
			ifFalse: [ Smalltalk globals removeKey: #Filename ifAbsent: [ ] ].
		hadSpecials
			ifTrue: [ Smalltalk at: #SpecialGemStoneObjects put: previousSpecials ]
			ifFalse: [ Smalltalk globals removeKey: #SpecialGemStoneObjects ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsLauncherTest >> testCompatibilityBootstrapPublishesConvertedRuntimeGlobals [
	| specials |
	GbsPharoBootstrap publishConvertedRuntimeGlobals.

	specials := Smalltalk at: #SpecialGemStoneObjects.
	self assert: (Smalltalk at: #OObject) class equals: GbxKernelPomOop.
	self assert: (Smalltalk at: #ONil) class equals: GbxSpecialOop.
	self assert: (Smalltalk at: #LastKernelOopNumber) equals: 1318.
	self assert: (specials at: #OObject) equals: (Smalltalk at: #OObject).
	self assert: (specials at: 'OGemStoneErrorCategory') equals: (Smalltalk at: #OGemStoneErrorCategory)
]

{ #category : 'tests' }
GbsLauncherTest >> testBindingReferenceResolvesGlobalBindingsThroughQualifiedPaths [
	| binding hadPrevious previousValue |
	hadPrevious := Smalltalk globals includesKey: #GbsBootstrapBindingReferenceProbe.
	previousValue := Smalltalk at: #GbsBootstrapBindingReferenceProbe ifAbsent: [ nil ].
	[
		Smalltalk at: #GbsBootstrapBindingReferenceProbe put: 42.

		binding := (BindingReference pathString: 'Root.Smalltalk.GbsBootstrapBindingReferenceProbe')
			bindingOrNil.

		self assert: binding class equals: GbxNameAssociation.
		self assert: binding value equals: 42.

		binding value: 99.

	self assert: (Smalltalk at: #GbsBootstrapBindingReferenceProbe) equals: 99
	] ensure: [
		hadPrevious
			ifTrue: [ Smalltalk at: #GbsBootstrapBindingReferenceProbe put: previousValue ]
			ifFalse: [ Smalltalk globals removeKey: #GbsBootstrapBindingReferenceProbe ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsLauncherTest >> testBufferingAndLimitingStreamsProvideCompatibilityPrinting
[
	| buffered limited |
	buffered := GbxBufferingStream on: String new writeStream.
	limited := GbxLimitingStream on: buffered.
	limited
		nextPutAll: 'header';
		indentMore;
		cr;
		nextPutAll: 'item';
		flush.

	self assert: limited contents equals: 'header', String cr, String tab, 'item'.
	self
		should: [
			limited maxSize: 4.
			limited nextPutAll: 'more' ]
		raise: GbsMaxStreamSizeNotification
]

{ #category : 'tests' }
GbsLauncherTest >> testFilenameCompatibilityWrapperProvidesAliasAndFileStreams
[
	| fileName file stream |
	fileName := 'gbs-bootstrap-probe-', UUID new asString, '.txt'.
	file := (Smalltalk at: #Filename) named: fileName.
	[
		stream := file writeStream.
		stream nextPutAll: 'probe'.
		stream close.

		self assert: file class equals: GbxFilename.
		self assert: file exists.
		self assert: file asString equals: file asFileReference fullName
	] ensure: [ file asFileReference ensureDelete ]
]

{ #category : 'tests' }
GbsLauncherTest >> testConvertedCompatibilityClassesKeepExpectedSuperclassShape
[
	self assert: GbxNamedVariable superclass equals: NamedVariable.
	self assert: GbxObjectSegment superclass equals: ObjectSegment.
	self assert: GbxBasicInspector superclass equals: BasicInspector.
	self assert: GbxArrayInspector superclass equals: ArrayInspector.
	self assert: GbxKeyedElement superclass equals: KeyedElement.
	self assert: GbxExecBlock instVarNames equals: #(method session blockOop numArgs)
]

{ #category : 'tests' }
GbsLauncherTest >> testEarlyLateSystemCompatibilityStubsExist
[
	self assert: (Smalltalk at: #EarlyInterestNotificationSystem ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #FinalizationSystem ifAbsent: [ nil ]) notNil.
	self assert: (GbxEarlySystem new prerequisiteSystems includes: EarlyInterestNotificationSystem).
	self assert: (GbxLateSystem new prerequisiteSystems includes: FinalizationSystem).
	self shouldnt: [ GbxFinalizer installGbxFinalizer ] raise: Error
]

{ #category : 'tests' }
GbsLauncherTest >> testIconLibraryUsesPharoSafePlaceholderIcons
[
	self assert: GbxIconLibrary browseSystem class equals: Form.
	self assert: GbxIconLibrary browseSystem extent equals: 24@24.
	self assert: GbxIconLibrary noChanges class equals: Form.
	self assert: GbxIconLibrary noChanges extent equals: 16@16
]

{ #category : 'tests' }
GbsLauncherTest >> testRefreshWorldMenuMakesGemStoneEntryVisible
[
	| world state menu labels |
	GbsPharoBootstrap refreshWorldMenuIfPossible.
	world := Smalltalk at: #World ifAbsent: [ nil ].
	world := (world notNil and: [ world respondsTo: #currentWorld ])
		ifTrue: [ world currentWorld ]
		ifFalse: [ world ].
	state := world ifNotNil: [ world worldState ].
	menu := state ifNotNil: [ state worldMenu ].
	labels := OrderedCollection new.
	(menu respondsTo: #items)
		ifTrue: [
			menu items do: [ :item |
				(item respondsTo: #contents)
					ifTrue: [ labels add: item contents asString ] ] ].
	self assert: (labels includes: 'GemStone')
]

{ #category : 'tests' }
GbsLauncherTest >> testBootstrapInitializeMakesGemStoneEntryVisible
[
	| world state menu labels |
	GbsPharoBootstrap initialize.
	world := Smalltalk at: #World ifAbsent: [ nil ].
	world := (world notNil and: [ world respondsTo: #currentWorld ])
		ifTrue: [ world currentWorld ]
		ifFalse: [ world ].
	state := world ifNotNil: [ world worldState ].
	menu := state ifNotNil: [ state worldMenu ].
	labels := OrderedCollection new.
	(menu respondsTo: #items)
		ifTrue: [
			menu items do: [ :item |
				(item respondsTo: #contents)
					ifTrue: [ labels add: item contents asString ] ] ].
	self assert: (labels includes: 'GemStone')
]

{ #category : 'tests' }
GbsLauncherTest >> testSessionManagerStatResourceSafelyInitializesNumSessions
[
	| statResource |
	statResource := GbxSessionManagerStatResource new.
	self shouldnt: [ statResource setNumSessions ] raise: Error.
	self assert: statResource numSessions equals: 0
]
