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
GbsLauncherTest >> testBehaviorOopMapKeepsRuntimeApiAndToolVariants [
	self assert: (GbxBehaviorOopMap respondsTo: #newForSession:).
	self assert: GbxBehaviorOopMap superclass equals: GbxOopKeyedDictionary.
	self assert: GbxBehaviorOopMapNode superclass equals: GbxOopKeyedNode.
	self assert: (Smalltalk at: #GbxBehaviorOopMapTool ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxBehaviorOopMapNodeTool ifAbsent: [ nil ]) notNil
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
GbsLauncherTest >> testSessionManagerStatResourceSafelyInitializesNumSessions
[
	| statResource |
	statResource := GbxSessionManagerStatResource new.
	self shouldnt: [ statResource setNumSessions ] raise: Error.
	self assert: statResource numSessions equals: 0
]
