Class {
	#name : 'GbsSessionCoreTest',
	#superclass : 'TestCase',
	#instVars : [
		'session',
		'previousObjectSpaceFinalizationRegistry'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GbsSessionCoreTest >> materializationMockSession [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script | | result |
		result := nil.
		(script includesSubstring: 'class name asString') ifTrue: [
			(script includesSubstring: '9000') ifTrue: [ result := 'Array' ].
			(script includesSubstring: '9016') ifTrue: [ result := 'Array' ].
			(script includesSubstring: '9040') ifTrue: [ result := 'String' ].
			(script includesSubstring: '9056') ifTrue: [ result := 'String' ].
			(script includesSubstring: '9064') ifTrue: [ result := 'String' ] ].
		(script includesSubstring: ') asString') ifTrue: [
			(script includesSubstring: '9040') ifTrue: [ result := 'vip' ].
			(script includesSubstring: '9056') ifTrue: [ result := 'gold' ].
			(script includesSubstring: '9064') ifTrue: [ result := 'paid' ] ].
		result ifNil: [ self fail ].
		result ].
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script | | result |
		result := nil.
		(script includesSubstring: '9000') ifTrue: [ result := 2 ].
		(script includesSubstring: '9016') ifTrue: [ result := 2 ].
		result ifNil: [ self fail ].
		result ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script | | result |
		result := nil.
		(script includesSubstring: '9000') ifTrue: [
			(script includesSubstring: 'at: 1') ifTrue: [ result := 9040 ].
			(script includesSubstring: 'at: 2') ifTrue: [ result := 9016 ] ].
		(script includesSubstring: '9016') ifTrue: [
			(script includesSubstring: 'at: 1') ifTrue: [ result := 9056 ].
			(script includesSubstring: 'at: 2') ifTrue: [ result := 9064 ] ].
		result ifNil: [ self fail ].
		result ].
	^ mockSession
]

{ #category : 'running' }
GbsSessionCoreTest >> setUp [
	super setUp.
	previousObjectSpaceFinalizationRegistry := Smalltalk globals
		at: #GbsObjectSpaceFinalizationRegistry
		ifAbsent: [ nil ].
	GbsObjectSpaceFacade resetFinalizationRegistry.
	session := GbsSession new
]

{ #category : 'running' }
GbsSessionCoreTest >> tearDown [
	GbsSession notificationActions removeAll.
	GbsSession sessionSignalActions removeAll.
	GbsSession signaledAbortActions removeAll.
	previousObjectSpaceFinalizationRegistry
		ifNil: [ Smalltalk globals removeKey: #GbsObjectSpaceFinalizationRegistry ifAbsent: [ ] ]
		ifNotNil: [ Smalltalk globals at: #GbsObjectSpaceFinalizationRegistry put: previousObjectSpaceFinalizationRegistry ].
	super tearDown
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDefaultFetchProfileIsLegacy [
	self assert: session fetchProfile class equals: GbsLegacyMaterializationProfile
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchByReferenceUsesTypedWrapperForKnownCollectionClass [
	| mockSession result |
	mockSession := self materializationMockSession.
	GbsSessionManager initializeFastConnectors.
	mockSession fetchByReference.

	result := mockSession fetchObject: 9000.

	self assert: (result isKindOf: GbsTypedProxy).
	self assert: result clientBehaviorName equals: 'Array'.
	self assert: result oop equals: 9000
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchByReferenceUsesTypedWrapperWithoutExplicitFastConnectorBootstrap [
	| mockSession result previousRegistry |
	previousRegistry := Smalltalk globals at: #GbsFastConnectorRegistry ifAbsent: [ nil ].
	[
		Smalltalk globals removeKey: #GbsFastConnectorRegistry ifAbsent: [ ].
		mockSession := self materializationMockSession.
		mockSession fetchByReference.

		result := mockSession fetchObject: 9000.

		self assert: (result isKindOf: GbsTypedProxy).
		self assert: result clientBehaviorName equals: 'Array'
	] ensure: [
		previousRegistry
			ifNil: [ Smalltalk globals removeKey: #GbsFastConnectorRegistry ifAbsent: [ ] ]
			ifNotNil: [ Smalltalk globals at: #GbsFastConnectorRegistry put: previousRegistry ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchByReferenceFallsBackToPlainProxyForUnknownClass [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: 'class name asString')
			ifTrue: [ 'Invoice' ]
			ifFalse: [ self fail ] ].
	mockSession fetchByReference.

	result := mockSession fetchObject: 9500.

	self assert: result class equals: GbsProxy.
	self assert: result oop equals: 9500
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepMaterializesNestedArraysRecursively [
	| mockSession result nested |
	mockSession := self materializationMockSession.
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.
	nested := result at: 2.

	self assert: result class equals: Array.
	self assert: (result at: 1) equals: 'vip'.
	self assert: nested class equals: Array.
	self assert: nested equals: #('gold' 'paid')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchLegacyMaterializesArraysRecursively [
	| mockSession result |
	mockSession := self materializationMockSession.

	result := mockSession fetchObject: 9000.

	self assert: result equals: #('vip' #('gold' 'paid'))
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchShallowLeavesNestedArrayAsProxy [
	| mockSession result nested |
	mockSession := self materializationMockSession.
	GbsSessionManager initializeFastConnectors.
	mockSession fetchShallow.

	result := mockSession fetchObject: 9000.
	nested := result at: 2.

	self assert: result class equals: Array.
	self assert: (result at: 1) equals: 'vip'.
	self assert: (nested isKindOf: GbsTypedProxy).
	self assert: nested oop equals: 9016
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectAtCachesResolvedNamedRoots [
	| mockSession first second calls |
	mockSession := CoreMockGbsSession new.
	calls := 0.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		calls := calls + 1.
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 4444 session: mockSession ].

	first := mockSession namedObjectAt: #UserGlobals.
	second := mockSession namedObjectAt: 'UserGlobals'.

	self assert: first == second.
	self assert: calls equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectAtIfAbsentEvaluatesFallback [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#MissingThing').
		nil ].

	result := mockSession namedObjectAt: #MissingThing ifAbsent: [ #fallback ].

	self assert: result equals: #fallback
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectAtNormalizesStringNames [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 4444 session: mockSession ].

	result := mockSession namedObjectAt: 'UserGlobals'.

	self assert: result oop equals: 4444
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectAutoloadAliasResolvesRemoteNameAndCachesAlias [
	| mockSession first second calls |
	mockSession := CoreMockGbsSession new.
	calls := 0.
	mockSession registerNamedObjectAutoload: #UG remote: #UserGlobals.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		calls := calls + 1.
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 5555 session: mockSession ].

	first := mockSession namedObjectAt: #UG.
	second := mockSession namedObjectAt: #UserGlobals.

	self assert: first == second.
	self assert: calls equals: 1.
	self assert: (mockSession hasCachedNamedObjectNamed: #UG).
	self assert: (mockSession hasCachedNamedObjectNamed: #UserGlobals)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectAutoloadInspectionAndClear [
	| mockSession report entries |
	mockSession := CoreMockGbsSession new.
	mockSession registerNamedObjectAutoload: #UG remote: #UserGlobals.
	mockSession registerNamedObjectAutoload: #ROOT remote: #Globals.

	entries := mockSession namedObjectAutoloadEntries.
	report := mockSession namedObjectAutoloadReportText.

	self assert: mockSession namedObjectAutoloadKeys equals: #(ROOT UG).
	self assert: entries size equals: 2.
	self assert: (mockSession hasNamedObjectAutoloadNamed: #UG).
	self assert: (mockSession namedObjectAutoloadTargetFor: #ROOT) equals: #Globals.
	self assert: (report includesSubstring: 'UG -> UserGlobals').
	self assert: (report includesSubstring: 'ROOT -> Globals').

	mockSession unregisterNamedObjectAutoload: #UG.
	self deny: (mockSession hasNamedObjectAutoloadNamed: #UG).

	mockSession clearNamedObjectAutoloads.
	self assert: mockSession namedObjectAutoloadKeys isEmpty.
	self assert: mockSession namedObjectAutoloadReportText equals: 'No named-object autoload registrations.'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectCacheInspectionAndClear [
	| mockSession report entries |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 4444 session: mockSession ].

	mockSession namedObjectAt: #UserGlobals.
	entries := mockSession namedObjectCacheEntries.
	report := mockSession namedObjectCacheReportText.

	self assert: mockSession namedObjectCacheKeys equals: #(UserGlobals).
	self assert: entries size equals: 1.
	self assert: entries first key equals: #UserGlobals.
	self assert: (mockSession hasCachedNamedObjectNamed: 'UserGlobals').
	self assert: (report includesSubstring: 'UserGlobals').
	self assert: (report includesSubstring: '4444').

	mockSession clearNamedObjectCache.

	self assert: mockSession namedObjectCacheKeys isEmpty.
	self deny: (mockSession hasCachedNamedObjectNamed: #UserGlobals).
	self assert: mockSession namedObjectCacheReportText equals: 'No named objects cached.'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectForOopUsesReferenceSemantics [
	| proxy |
	proxy := session objectForOop: 1001.

	self assert: proxy class equals: GbsProxy.
	self assert: proxy oop equals: 1001.
	self assert: proxy session == session
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyForOopServerClassNameUsesTypedWrapperWhenConnectorExists [
	| proxy |
	GbsSessionManager initializeFastConnectors.
	proxy := session
		proxyForOop: 1001
		serverClassName: 'Dictionary'.

	self assert: (proxy isKindOf: GbsTypedProxy).
	self assert: proxy clientBehaviorName equals: 'Dictionary'.
	self assert: proxy oop equals: 1001.
	self assert: proxy session == session
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyIdentityMapKeepsFirstProxyWhenPlainLookupPrecedesTypedLookup [
	| plain typed |
	GbsSessionManager initializeFastConnectors.
	plain := session resultFor: 1001.
	typed := session proxyForOop: 1001 serverClassName: 'Dictionary'.

	self assert: plain == typed.
	self assert: typed class equals: GbsProxy
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyIdentityMapKeepsTypedWrapperWhenTypedLookupPrecedesPlainLookup [
	| typed plain |
	GbsSessionManager initializeFastConnectors.
	typed := session proxyForOop: 1001 serverClassName: 'Dictionary'.
	plain := session resultFor: 1001.

	self assert: typed == plain.
	self assert: (plain isKindOf: GbsTypedProxy)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyIdentityMapReturnsSameProxyForRepeatedResultFor [
	| first second |
	first := session resultFor: 1001.
	second := session resultFor: 1001.

	self assert: first == second
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyIdentityMapReusesTypedWrapperForRepeatedTypedLookup [
	| first second |
	GbsSessionManager initializeFastConnectors.
	first := session proxyForOop: 1001 serverClassName: 'Dictionary'.
	second := session proxyForOop: 1001 serverClassName: 'Dictionary'.

	self assert: first == second.
	self assert: (first isKindOf: GbsTypedProxy)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionForwarderForUsesNamedObjectCache [
	| mockSession first second calls |
	mockSession := CoreMockGbsSession new.
	calls := 0.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		calls := calls + 1.
		self assert: (script includesSubstring: '#Globals').
		GbsProxy oop: 1001 session: mockSession ].

	first := mockSession sessionForwarderFor: #Globals.
	second := mockSession sessionForwarderFor: #Globals.

	self assert: first == second.
	self assert: calls equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testWithMaterializationProfileRestoresPreviousProfile [
	| insideProfile |
	session withMaterializationProfile: GbsProxyOnlyMaterializationProfile new do: [
		insideProfile := session fetchProfile class ].

	self assert: insideProfile equals: GbsProxyOnlyMaterializationProfile.
	self assert: session fetchProfile class equals: GbsLegacyMaterializationProfile
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectFinalizerExecutesAllActionsWithTarget [
	| target finalizer seen |
	target := Object new.
	seen := OrderedCollection new.
	finalizer := GbsObjectFinalizer on: target.
	finalizer
		addAction: [ :each | seen add: each ];
		addAction: [ :each | seen add: each class name ].

	finalizer finalize.

	self assert: seen first == target.
	self assert: seen second equals: 'Object'.
	self assert: finalizer size equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceAllSubclassesOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'cls allSubclasses asArray').
		self assert: (script includesSubstring: '''Invoice''').
		#(SubclassOne SubclassTwo) ].

	result := mockSession objectSpace allSubclassesOfNamed: 'Invoice'.

	self assert: result equals: #(SubclassOne SubclassTwo)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDefineAndUndefineFinalizerUsesSharedRegistry [
	| target first second group |
	target := Object new.
	first := [ :each | each ].
	second := [ :each | each class ].

	group := session
		defineFinalizerFor: target
		do: first.
	self assert: (session hasFinalizerFor: target).
	self assert: group size equals: 1.

	group := session
		defineFinalizerFor: target
		do: second.
	self assert: group size equals: 2.
	self assert: (session objectSpace finalizerFor: target) == group.

	session undefineFinalizerFor: target.
	self deny: (session hasFinalizerFor: target)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeSupportsArbitraryKeysWithSlotObjects [
	| mockSession diagnostics slot report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].
	diagnostics := mockSession objectSpaceDiagnostics.

	slot := diagnostics slotAtKey: 21 label: 'Custom Slot'.
	report := diagnostics reportTextForKeys: #(21).

	self assert: slot key equals: 21.
	self assert: slot label equals: 'Custom Slot'.
	self assert: slot size equals: 3.
	self assert: (diagnostics reportSlotsForKeys: #(21)) size equals: 1.
	self assert: (report includesSubstring: 'Key 21 (Session State): Array size=3')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeExpandsAliasPrefixesAndAliasNames [
	| mockSession diagnostics slot |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [ ^ IdentityDictionary new ].
		self fail ].
	diagnostics := mockSession objectSpaceDiagnostics.
	slot := diagnostics slotNamed: 'slot 19'.

	self assert: (diagnostics slotKeyNamed: 'slot 19') equals: 19.
	self assert: (diagnostics slotKeyNamed: 'session.state.19') equals: 19.
	self assert: (diagnostics slotKeyNamed: 'ruby main thread finalizers') equals: 19.
	self assert: (diagnostics slotAliasNamesAtKey: 19) notEmpty.
	self assert: (slot hasAliasNamed: 'rubymainthreadfinalizers').
	self assert: (slot aliasNames includes: 'maglevfinalizerregistry')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeReportObjectSeparatesWellKnownAndCustomSlots [
	| mockSession report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [ ^ (IdentityDictionary new at: #lazy put: true; yourself) ].
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].

	report := mockSession objectSpaceDiagnostics reportForKeys: #(19 21).

	self assert: report slots size equals: 2.
	self assert: report wellKnownSlots size equals: 1.
	self assert: report customSlots size equals: 1.
	self assert: (report text includesSubstring: 'Well-Known Session State').
	self assert: (report text includesSubstring: 'Custom Session State')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsObjectsInMemoryReportUsesStructuredObjects [
	| mockSession report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _listInstancesInMemory:')
			ifTrue: [ ^ { GbsProxy oop: 9201 session: mockSession. GbsProxy oop: 9202 session: mockSession } ].
		self fail ].

	report := mockSession objectSpaceDiagnostics objectsInMemoryReportFrom: 1 limit: 2.

	self assert: report objects size equals: 2.
	self assert: report objects first oop equals: 9201.
	self assert: (report text includesSubstring: 'Objects In Memory').
	self assert: (report text includesSubstring: 'oop=9201')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeDiscoversOccupiedSlotsAndParsesNamedAliases [
	| mockSession diagnostics discovered slot |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazy put: true;
				yourself) ].
		(script includesSubstring: 'key := 20')
			ifTrue: [ ^ nil ].
		(script includesSubstring: 'key := 21')
			ifTrue: [ ^ #(1 2 3) ].
		self fail ].
	diagnostics := mockSession objectSpaceDiagnostics.

	slot := diagnostics slotNamed: 'session.state.21'.
	discovered := diagnostics occupiedSlotsFrom: 19 to: 21.

	self assert: slot key equals: 21.
	self assert: slot exists.
	self assert: (diagnostics slotNamed: 'slot 19') key equals: 19.
	self assert: discovered size equals: 2.
	self assert: (discovered collect: [ :each | each key ]) equals: #(19 21).
	self assert: ((diagnostics occupiedSlotsReportTextFrom: 19 to: 21)
		includesSubstring: 'Key 21 (Session State): Array size=3')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeSupportsRegisteredWellKnownSlots [
	| mockSession diagnostics slot report |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		GbsObjectSpaceDiagnosticsFacade
			registerWellKnownSessionStateSlotKey: 21
			label: 'Ruby Thread Cache'
			aliases: #('rubythreadcache' 'threadcache').
		mockSession := CoreMockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2) ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.

		slot := diagnostics slotNamed: 'Ruby Thread Cache'.
		report := diagnostics reportTextForSlotNames: #('thread cache').

		self assert: (diagnostics slotKeyNamed: 'ruby_thread_cache') equals: 21.
		self assert: (diagnostics slotKeyNamed: 'Ruby Thread Cache') equals: 21.
		self assert: slot label equals: 'Ruby Thread Cache'.
		self assert: (report includesSubstring: 'Key 21 (Ruby Thread Cache): Array size=2')
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeBatchRegistersSlotsAndTracksDiscoverySource [
	| mockSession diagnostics registeredSlot discoveredSlot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		GbsObjectSpaceDiagnosticsFacade registerWellKnownSessionStateSlots: {
			{ 21. 'Ruby Thread Cache'. #('rubythreadcache' 'threadcache') }.
			{ 22. 'Ruby Fiber Registry'. #('rubyfiberregistry' 'fiberregistry') } }.
		mockSession := CoreMockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2) ].
			(script includesSubstring: 'key := 23') ifTrue: [ ^ 'dynamic-slot' ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.

		registeredSlot := diagnostics slotNamed: 'thread cache'.
		discoveredSlot := diagnostics slotAtKey: 23.

		self assert: (diagnostics slotKeyNamed: 'fiber registry') equals: 22.
		self assert: registeredSlot isWellKnown.
		self assert: registeredSlot discoverySource equals: #registered.
		self deny: discoveredSlot isWellKnown.
		self assert: discoveredSlot discoverySource equals: #discovered
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeBuildsTypedCacheAndRegistrySlots [
	| mockSession diagnostics cacheSlot registrySlot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		GbsObjectSpaceDiagnosticsFacade
			registerWellKnownCacheSessionStateSlotKey: 21
			label: 'Ruby Thread Cache'
			aliases: #('threadcache')
			tags: #(#ruby #cache).
		GbsObjectSpaceDiagnosticsFacade
			registerWellKnownRegistrySessionStateSlotKey: 22
			label: 'Ruby Fiber Registry'
			aliases: #('fiberregistry')
			tags: #(#ruby #registry).
		mockSession := CoreMockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2) ].
			(script includesSubstring: 'key := 22') ifTrue: [ ^ (IdentityDictionary new at: #fiber put: 1; yourself) ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.
		cacheSlot := diagnostics slotNamed: 'thread cache'.
		registrySlot := diagnostics slotNamed: 'fiber registry'.

		self assert: cacheSlot class equals: GbsCacheSessionStateSlot.
		self assert: cacheSlot isCacheSlot.
		self assert: cacheSlot slotKind equals: #cache.
		self assert: (cacheSlot hasTag: #cache).
		self assert: registrySlot class equals: GbsRegistrySessionStateSlot.
		self assert: registrySlot isRegistrySlot.
		self assert: registrySlot slotKind equals: #registry.
		self assert: (registrySlot hasTag: #registry)
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeInfersTypedSlotsForDiscoveredValues [
	| mockSession diagnostics registrySlot cacheSlot threadSlot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		GbsObjectSpaceDiagnosticsFacade
			registerWellKnownThreadStateSessionStateSlotKey: 25
			label: 'Ruby Thread State'
			aliases: #('rubythreadstate' 'threadstate')
			tags: #(#ruby #thread).
		mockSession := CoreMockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 23') ifTrue: [ ^ IdentityDictionary new ].
			(script includesSubstring: 'key := 24') ifTrue: [ ^ #(1 2 3) ].
			(script includesSubstring: 'key := 25') ifTrue: [ ^ 'thread-state' ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.

		registrySlot := diagnostics slotAtKey: 23 label: 'Session Registry'.
		cacheSlot := diagnostics slotAtKey: 24 label: 'Session Cache'.
		threadSlot := diagnostics slotNamed: 'threadstate'.

		self assert: registrySlot class equals: GbsRegistrySessionStateSlot.
		self assert: cacheSlot class equals: GbsCacheSessionStateSlot.
		self assert: threadSlot class equals: GbsThreadStateSessionStateSlot.
		self assert: (threadSlot hasTag: #thread)
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceEachObjectDoBatchSizeUsesPagedFetches [
	| mockSession seen |
	mockSession := CoreMockGbsSession new.
	seen := OrderedCollection new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'startIndex := 1')
			ifTrue: [ ^ #(11 12) ].
		(script includesSubstring: 'startIndex := 3')
			ifTrue: [ ^ #(13) ].
		self fail ].

	mockSession eachObjectDo: [ :each |
		seen add: each ] batchSize: 2.

	self assert: seen asArray equals: #(11 12 13)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceEachObjectDoBuildsExpectedScript [
	| mockSession seen |
	mockSession := CoreMockGbsSession new.
	seen := OrderedCollection new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'SystemRepository _loadedClasses: false').
		self assert: (script includesSubstring: 'SystemRepository _listInstancesInMemory: classes').
		#(11 12 13) ].

	mockSession eachObjectDo: [ :each |
		seen add: each ].

	self assert: seen asArray equals: #(11 12 13)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceFacadeRetainsSession [
	| mockSession facade |
	mockSession := CoreMockGbsSession new.

	facade := mockSession objectSpace.

	self assert: facade class equals: GbsObjectSpaceFacade.
	self assert: facade session == mockSession
]

{ #category : 'tests' }
GbsSessionCoreTest >> testChunkedMigrationRunnerBuildsMaglevAlignedScripts [
	| mockSession runner prepareScript chunkScript |
	mockSession := CoreMockGbsSession new.
	runner := GbsChunkedMigrationRunner
		on: mockSession
		source: #LegacyPoint
		target: #Point.
	prepareScript := runner listInstanceOopsScript.
	chunkScript := runner migrateChunkScriptForOops: #(101 102 103).

	self assert: (prepareScript includesSubstring: 'SystemRepository listInstances').
	self assert: (prepareScript includesSubstring: 'LegacyPoint').
	self assert: (chunkScript includesSubstring: 'migrateInstances: instances asArray to: toClass').
	self assert: (chunkScript includesSubstring: '101').
	self assert: (chunkScript includesSubstring: 'Point')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testChunkedMigrationRunnerPrepareCheckpointReplaysAcrossCommitConflict [
	| mockSession runner result listCount checkpointWriteCount commits |
	mockSession := CoreMockGbsSession new.
	listCount := 0.
	checkpointWriteCount := 0.
	commits := #(0 1) readStream.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository listInstances') ifTrue: [
			listCount := listCount + 1.
			^ #(101 102) ].
		(script includesSubstring: 'gbsMigration:LegacyPoint->Point') ifTrue: [
			checkpointWriteCount := checkpointWriteCount + 1.
			^ #(101 102) ].
		self fail ].
	mockSession stubs at: #gciCommit put: [ commits next ].
	runner := GbsChunkedMigrationRunner
		on: mockSession
		source: #LegacyPoint
		target: #Point.

	result := runner prepareCheckpoint.

	self assert: (result at: #remaining) equals: 2.
	self assert: (result at: #committed) equals: true.
	self assert: listCount equals: 2.
	self assert: checkpointWriteCount equals: 2
]

{ #category : 'tests' }
GbsSessionCoreTest >> testCommitTransactionWithRetryCountSignalsConflictAfterExhaustion [
	| mockSession commitCount |
	mockSession := CoreMockGbsSession new.
	commitCount := 0.
	mockSession stubs at: #gciCommit put: [
		commitCount := commitCount + 1.
		0 ].

	self
		should: [ mockSession commitTransactionWithRetryCount: 1 ]
		raise: GbsCommitConflictError.
	self assert: commitCount equals: 2
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSmalltalkFacadeExposesBridgeRootAndSymbolDictionaries [
	| mockSession facade |
	mockSession := CoreMockGbsSession new.
	facade := mockSession smalltalk.

	self assert: facade class equals: GbsSmalltalkFacade.
	self assert: mockSession bridgeRoot class equals: GbsBridgeRootFacade.
	self assert: mockSession bridgeRoot rootKey equals: #GbsBridgeRoot.
	self assert: facade bridgeRoot class equals: GbsBridgeRootFacade.
	self assert: facade bridgeRoot rootKey equals: #GbsBridgeRoot.
	self assert: facade globals class equals: GbsSymbolDictionaryFacade.
	self assert: facade published class equals: GbsSymbolDictionaryFacade.
	self assert: facade userGlobals class equals: GbsSymbolDictionaryFacade.
	self deny: (facade respondsTo: #sessionMethods)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchTranscriptLogsUsesSessionTempsFallbackScript [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		self assert: (script includesSubstring: 'Transcript respondsTo: #fetchAndClear').
		self assert: (script includesSubstring: '#PharoTranscriptLog').
		self assert: (script includesSubstring: 'UserGlobals at: #PharoTranscriptLog put: OrderedCollection new').
		^ 'TDD Hello', String cr ].

	self assert: (mockSession fetchTranscriptLogs includesSubstring: 'TDD Hello')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceRepositoryFacadeCountsOopsAndBuildsReport [
	| mockSession repository report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository listInstances') ifTrue: [
			(script includesSubstring: 'instances size') ifTrue: [ ^ 3 ].
			(script includesSubstring: 'collect: [ :each | each asOop ]') ifTrue: [ ^ #(101 102 103) ] ].
		self fail ].
	repository := mockSession objectSpaceRepository.
	report := repository reportTextFor: #LegacyPoint.

	self assert: (repository countInstancesOf: #LegacyPoint) equals: 3.
	self assert: (repository instanceOopsOf: #LegacyPoint) equals: #(101 102 103).
	self assert: (report includesSubstring: 'ObjectSpace::Repository').
	self assert: (report includesSubstring: 'LegacyPoint').
	self assert: (report includesSubstring: '#(101 102 103)')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceInstancesInMemoryOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'SystemRepository _listInstancesInMemory: { cls }').
		self assert: (script includesSubstring: '''Invoice''').
		#(11 12) ].

	result := mockSession objectSpace instancesInMemoryOfNamed: 'Invoice'.

	self assert: result equals: #(11 12)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceInstancesInMemoryOfNamedFromLimitBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'SystemRepository _listInstancesInMemory: { cls }').
		self assert: (script includesSubstring: '''Invoice''').
		self assert: (script includesSubstring: 'startIndex := 2').
		self assert: (script includesSubstring: 'limitValue := 1').
		#(12) ].

	result := mockSession
		objectSpace
		instancesInMemoryOf: 'Invoice'
		from: 2
		limit: 1.

	self assert: result equals: #(12)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceLoadedClassesIncludingModulesBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: script equals: 'SystemRepository _loadedClasses: true'.
		#('Invoice' 'Payments') ].

	result := mockSession objectSpace loadedClassesIncludingModules.

	self assert: result equals: #('Invoice' 'Payments')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceLoadedClassesIncludingModulesFalseBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: script equals: 'SystemRepository _loadedClasses: false'.
		#('Invoice') ].

	result := mockSession objectSpace loadedClassesIncludingModules: false.

	self assert: result equals: #('Invoice')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceObjectsInMemoryFromLimitBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'startIndex := 3').
		self assert: (script includesSubstring: 'limitValue := 2').
		self assert: (script includesSubstring: 'skipCount := startIndex - 1').
		self assert: (script includesSubstring: 'takeCount := limitValue').
		#(21 22) ].

	result := mockSession objectSpace objectsInMemoryFrom: 3 limit: 2.

	self assert: result equals: #(21 22)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceObjectsInMemoryMatchingFiltersIncrementally [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'startIndex := 1')
			ifTrue: [ ^ #(11 12) ].
		(script includesSubstring: 'startIndex := 3')
			ifTrue: [ ^ #(13 14) ].
		self fail ].

	result := mockSession
		objectsInMemoryMatching: [ :each | each odd ]
		limit: 2
		batchSize: 2.

	self assert: result equals: #(11 13)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceReferencesToBuildsExpectedScript [
	| mockSession proxy result |
	mockSession := CoreMockGbsSession new.
	proxy := GbsProxy oop: 4242 session: mockSession.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: script equals: '((Object _objectForOop: 4242)) findReferencesInMemory asArray'.
		^ #(9001 9002) ].

	result := mockSession objectSpace referencesTo: proxy.

	self assert: result equals: #(9001 9002)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceReferencesToOopBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: script equals: '((Object _objectForOop: 4242)) findReferencesInMemory asArray'.
		^ #(9001) ].

	result := mockSession objectSpace referencesToOop: 4242.

	self assert: result equals: #(9001)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceSessionStateAtBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '(System respondsTo: #sessionStateAt:)').
		self assert: (script includesSubstring: 'System sessionStateAt: key').
		self assert: (script includesSubstring: 'key := 19').
		^ 'finalizer-registry' ].

	result := mockSession objectSpace sessionStateAt: 19.

	self assert: result equals: 'finalizer-registry'.
	self assert: mockSession maglevFinalizerRegistry equals: 'finalizer-registry'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceSessionStateAtPutBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '(System respondsTo: #sessionStateAt:put:)').
		self assert: (script includesSubstring: 'System sessionStateAt: key put: value').
		self assert: (script includesSubstring: 'key := 21').
		self assert: (script includesSubstring: 'value := ''cached-value''').
		^ 'cached-value' ].

	result := mockSession
		objectSpace
		sessionStateAt: 21
		put: 'cached-value'.

	self assert: result equals: 'cached-value'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testWithCommitRetryCountReplaysBlockAcrossCommitConflict [
	| mockSession attempts commits result |
	mockSession := CoreMockGbsSession new.
	attempts := 0.
	commits := #(0 1) readStream.
	mockSession stubs at: #gciCommit put: [ commits next ].

	result := mockSession withCommitRetryCount: 1 do: [
		attempts := attempts + 1.
		attempts ].

	self assert: result equals: 2.
	self assert: attempts equals: 2
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryClassMirrorOfNamedBuildsExpectedScripts [
	| mockSession mirror |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(1001 'Invoice' 'Object' 'Billing-Core' 'Billing-Models' 2 3) ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'Invoice' 1 3)
				#(1001 'Invoice' 2 3)
				#(1002 'Invoice' 3 3)) ].
		(script includesSubstring: 'behavior := cls class') ifTrue: [
			^ #(#('initialization' #('new')) #('testing' #('canOpen'))) ].
		(script includesSubstring: 'behavior := cls.') ifTrue: [
			^ #(#('accessing' #('amount' 'currency')) #('testing' #('isPaid'))) ].
		self fail ].

	mirror := mockSession classMirrorOfNamed: 'Invoice'.

	self assert: mirror exists.
	self assert: mirror name equals: 'Invoice'.
	self assert: mirror superclassName equals: 'Object'.
	self assert: mirror oop equals: 1001.
	self assert: mirror proxy oop equals: 1001.
	self assert: mirror packageName equals: 'Billing-Core'.
	self assert: mirror categoryName equals: 'Billing-Models'.
	self assert: mirror version equals: 2.
	self assert: mirror numberOfVersions equals: 3.
	self assert: mirror instanceProtocols equals: #(#('accessing' #('amount' 'currency')) #('testing' #('isPaid'))).
	self assert: mirror classProtocols equals: #(#('initialization' #('new')) #('testing' #('canOpen'))).
	self assert: mirror instanceSelectors equals: #(amount currency isPaid).
	self assert: mirror classSelectors equals: #(new canOpen).
	self assert: (mirror protocolForSelector: #currency) equals: 'accessing'.
	self assert: (mirror classProtocolForSelector: #new) equals: 'initialization'.
	self assert: mirror classHistory size equals: 3.
	self assert: mirror classHistory selectedVersionName equals: 'Invoice'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodMirrorForClassNamedBuildsExpectedScript [
	| mockSession instanceMirror classMirror |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		(script includesSubstring: 'compiledMethodAt: #new') ifTrue: [
			^ #(2002 'Invoice class' 'new' 'instance creation' 'new ^ super new' 'Billing-Core' 'Invoice class>>new' 1 2) ].
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(1001 'Invoice' 'Object' 'Billing-Core' 'Billing-Models' 2 3) ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'Invoice' 1 3)
				#(1001 'Invoice' 2 3)
				#(1002 'Invoice' 3 3)) ].
		self fail ].

	instanceMirror := mockSession
		methodMirrorForClassNamed: 'Invoice'
		selector: #totalPrice.
	classMirror := (mockSession classMirrorOfNamed: 'Invoice')
		classMethodMirrorAt: #new.

	self assert: instanceMirror exists.
	self assert: instanceMirror selector equals: #totalPrice.
	self assert: instanceMirror ownerName equals: 'Invoice'.
	self assert: instanceMirror protocol equals: 'pricing'.
	self assert: instanceMirror sourceCode equals: 'totalPrice ^ amount'.
	self assert: instanceMirror packageName equals: 'Billing-Core'.
	self assert: instanceMirror sourceLocation equals: 'Invoice>>totalPrice'.
	self assert: instanceMirror version equals: 3.
	self assert: instanceMirror numberOfVersions equals: 4.
	self assert: instanceMirror classMirror packageName equals: 'Billing-Core'.
	self assert: instanceMirror classHistory size equals: 3.
	self assert: instanceMirror oop equals: 2001.
	self assert: instanceMirror proxy oop equals: 2001.
	self assert: classMirror exists.
	self assert: classMirror classSide.
	self assert: classMirror ownerName equals: 'Invoice class'.
	self assert: classMirror protocol equals: 'instance creation'.
	self assert: classMirror sourceCode equals: 'new ^ super new'.
	self assert: classMirror packageName equals: 'Billing-Core'.
	self assert: classMirror sourceLocation equals: 'Invoice class>>new'.
	self assert: classMirror version equals: 1.
	self assert: classMirror numberOfVersions equals: 2.
	self assert: classMirror oop equals: 2002
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodObjectBindsAndInvokesThroughSession [
	| mockSession methodObject bound receiver capturedSelector capturedArguments capturedOop result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	mockSession stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#forwarded ].
	methodObject := mockSession
		methodObjectForClassNamed: 'Invoice'
		selector: #totalPrice.
	receiver := GbsProxy oop: 9001 session: mockSession.

	self deny: methodObject isBound.
	bound := methodObject bindTo: receiver.
	result := bound callWithArguments: #(5 'GBP').

	self assert: result equals: #forwarded.
	self deny: methodObject isBound.
	self assert: bound isBound.
	self assert: bound selector equals: #totalPrice.
	self assert: bound protocol equals: 'pricing'.
	self assert: bound sourceCode equals: 'totalPrice ^ amount'.
	self assert: bound receiver oop equals: 9001.
	self assert: capturedSelector equals: #totalPrice.
	self assert: capturedArguments equals: #(5 'GBP').
	self assert: capturedOop equals: 9001.
	self deny: bound unbind isBound
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodObjectEqualityHashAndBindingIdentity [
	| mockSession sameMethod sameMethodAgain boundSameReceiver boundSameReceiverAgain boundOtherReceiver receiverOne receiverTwo |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].

	sameMethod := mockSession methodObjectForClassNamed: 'Invoice' selector: #totalPrice.
	sameMethodAgain := mockSession methodObjectForClassNamed: 'Invoice' selector: #totalPrice.
	receiverOne := GbsProxy oop: 9001 session: mockSession.
	receiverTwo := GbsProxy oop: 9002 session: mockSession.
	boundSameReceiver := sameMethod bindTo: receiverOne.
	boundSameReceiverAgain := sameMethodAgain bindTo: receiverOne.
	boundOtherReceiver := sameMethod bindTo: receiverTwo.

	self assert: sameMethod equals: sameMethodAgain.
	self assert: sameMethod hash equals: sameMethodAgain hash.
	self assert: boundSameReceiver equals: boundSameReceiverAgain.
	self assert: boundSameReceiver hash equals: boundSameReceiverAgain hash.
	self deny: sameMethod equals: boundSameReceiver.
	self deny: boundSameReceiver equals: boundOtherReceiver
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryClassMethodObjectUsesClassProxyWhenUnbound [
	| mockSession methodObject capturedSelector capturedArguments capturedOop result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #new') ifTrue: [
			^ #(2002 'Invoice class' 'new' 'instance creation' 'new ^ super new' 'Billing-Core' 'Invoice class>>new' 1 2) ].
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(1001 'Invoice' 'Object' 'Billing-Core' 'Billing-Models' 2 3) ].
		self fail ].
	mockSession stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#created ].
	methodObject := mockSession
		classMethodObjectForClassNamed: 'Invoice'
		selector: #new.

	result := methodObject call.

	self assert: result equals: #created.
	self deny: methodObject isBound.
	self assert: methodObject ownerName equals: 'Invoice class'.
	self assert: capturedSelector equals: #new.
	self assert: capturedArguments equals: #().
	self assert: capturedOop equals: 1001
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodObjectValueConvenienceAndPrintString [
	| mockSession methodObject bound receiver capturedSelector capturedArguments capturedOop result printed |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #applyDiscount:currency:') ifTrue: [
			^ #(2003 'Invoice' 'applyDiscount:currency:' 'pricing' 'applyDiscount: percent currency: code ^ total' 'Billing-Core' 'Invoice>>applyDiscount:currency:' 2 4) ].
		self fail ].
	mockSession stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#discounted ].
	methodObject := mockSession
		methodObjectForClassNamed: 'Invoice'
		selector: #applyDiscount:currency:.
	receiver := GbsProxy oop: 9001 session: mockSession.
	bound := methodObject bindTo: receiver.

	result := bound value: 5 value: 'GBP'.
	printed := bound printString.

	self assert: result equals: #discounted.
	self assert: bound argumentCount equals: 2.
	self assert: bound isInstanceSide.
	self deny: bound isClassSide.
	self assert: capturedSelector equals: #applyDiscount:currency:.
	self assert: capturedArguments equals: #(5 'GBP').
	self assert: capturedOop equals: 9001.
	self assert: (printed includesSubstring: 'Invoice>>applyDiscount:currency:').
	self assert: (printed includesSubstring: '@9001')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodObjectParityDelegatesMirrorMetadata [
	| mockSession methodObject |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #new') ifTrue: [
			^ #(2002 'Invoice class' 'new' 'instance creation' 'new ^ super new' 'Billing-Core' 'Invoice class>>new' 1 2) ].
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(1001 'Invoice' 'Object' 'Billing-Core' 'Billing-Models' 2 3) ].
		self fail ].
	methodObject := mockSession
		classMethodObjectForClassNamed: 'Invoice'
		selector: #new.

	self assert: methodObject categoryName equals: 'instance creation'.
	self assert: methodObject packageName equals: 'Billing-Core'.
	self assert: methodObject version equals: 1.
	self assert: methodObject numberOfVersions equals: 2.
	self assert: methodObject ownerProxy oop equals: 1001.
	self assert: methodObject name equals: 'Invoice class>>new'.
	self assert: (methodObject displayString includesSubstring: 'Invoice class>>new')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryUnboundMethodObjectDelegatesMirrorMetadataAndCanBind [
	| mockSession methodObject bound receiver |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].

	methodObject := mockSession
		unboundMethodObjectForClassNamed: 'Invoice'
		selector: #totalPrice.
	receiver := GbsProxy oop: 9001 session: mockSession.
	bound := methodObject bindTo: receiver.

	self deny: methodObject isBound.
	self assert: methodObject ownerName equals: 'Invoice'.
	self assert: methodObject selector equals: #totalPrice.
	self assert: methodObject categoryName equals: 'pricing'.
	self assert: methodObject packageName equals: 'Billing-Core'.
	self assert: methodObject version equals: 3.
	self assert: methodObject numberOfVersions equals: 4.
	self assert: methodObject receiver isNil.
	self assert: (methodObject displayString includesSubstring: 'Invoice>>totalPrice').
	self assert: methodObject unbind == methodObject.
	self assert: bound isBound.
	self assert: bound receiver oop equals: 9001
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryUnboundInstanceMethodObjectSignalsError [
	| mockSession methodObject |
	mockSession := CoreMockGbsSession new.
	methodObject := mockSession
		methodObjectForClassNamed: 'Invoice'
		selector: #totalPrice.

	self
		should: [ methodObject call ]
		raise: Error
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodReferenceStringsQueriesBuildExpectedScripts [
	| mockSession symbolResult objectResult proxy |
	mockSession := CoreMockGbsSession new.
	proxy := GbsProxy oop: 9001 session: mockSession.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'organizer referencesTo: #Invoice') ifTrue: [
			^ #('Invoice>>totalPrice' 'Invoice class>>new') ].
		(script includesSubstring: 'organizer referencesToObject: (Object _objectForOop: 9001)') ifTrue: [
			self assert: (script includesSubstring: 'theNonMetaClass').
			^ #('Order>>invoice') ].
		self fail ].

	symbolResult := mockSession methodReferenceStringsToSymbol: 'Invoice'.
	objectResult := mockSession methodReferenceStringsToObject: proxy.

	self assert: symbolResult equals: #('Invoice>>totalPrice' 'Invoice class>>new').
	self assert: objectResult equals: #('Order>>invoice')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodSelectorReferenceQueriesBuildExpectedScripts [
	| mockSession implementors senders |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'organizer implementorsOf: #size') ifTrue: [
			^ #('Object>>size' 'Behavior>>size') ].
		(script includesSubstring: 'organizer sendersOf: ''size''') ifTrue: [
			^ #('Collection>>includes:' 'Behavior>>new') ].
		self fail ].

	implementors := mockSession implementorMethodReferenceStringsForSelector: 'size'.
	senders := mockSession senderMethodReferenceStringsForSelector: 'size'.

	self assert: implementors equals: #('Object>>size' 'Behavior>>size').
	self assert: senders equals: #('Collection>>includes:' 'Behavior>>new')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryHierarchyMethodReferenceQueriesBuildExpectedScripts [
	| mockSession implementors senders |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'className := ''Object''') ifFalse: [ self fail ].
		(script includesSubstring: 'objectNamed: className asSymbol') ifFalse: [ self fail ].
		(script includesSubstring: 'scope = ''super''') ifFalse: [ self fail ].
		(script includesSubstring: 'cls class includesSelector: sel') ifTrue: [
			self assert: (script includesSubstring: 'stream nextPutAll: cls name asString; nextPutAll: '' class>>''').
			^ #('Object>>size' 'Object class>>new') ].
		(script includesSubstring: 'cls whichSelectorsReferTo: sel') ifTrue: [
			self deny: (script includesSubstring: 'cls class whichSelectorsReferTo: sel').
			^ #('Collection>>includes:') ].
		self fail ].

	implementors := mockSession
		hierarchyImplementorMethodReferenceStringsForSelector: 'size'
		rootClassName: 'Object'
		scope: 'super'
		includeClassSide: true.
	senders := mockSession
		hierarchySenderMethodReferenceStringsForSelector: 'size'
		rootClassName: 'Object'
		scope: 'super'.

	self assert: implementors equals: #('Object>>size' 'Object class>>new').
	self assert: senders equals: #('Collection>>includes:')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadeBuildsExpectedVersionEntries [
	| mockSession holders |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'cls classHistory').
		self assert: (script includesSubstring: '''Invoice''').
		#(
			#(1000 'Invoice' 1 2)
			#(1008 'Invoice' 2 2)) ].

	holders := (mockSession classHistoryOf: 'Invoice') holders.

	self assert: holders size equals: 2.
	self assert: holders first name equals: 'Invoice'.
	self assert: holders first proxy oop equals: 1008.
	self assert: holders first version equals: 2.
	self assert: holders second proxy oop equals: 1000
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadeCanMigrateWhenMultipleVersionsExist [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'cls classHistory').
		#(
			#(1000 'Invoice' 1 2)
			#(1008 'Invoice' 2 2)) ].

	result := (mockSession classHistoryOf: 'Invoice') canMigrateInstances.

	self assert: result
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadePreviewMigrationToBuildsExpectedPlan [
	| mockSession plan entry |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'compiledMethodAt:') ifTrue: [ self fail ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: 'SystemRepository listInstances: { fromClass }') ifTrue: [
			self assert: (script includesSubstring: '''Invoice''').
			^ #(
				#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].
		self fail ].

	plan := (mockSession classHistoryOf: 'OldInvoice')
		previewMigrationTo: 'Invoice'.
	entry := plan entries first.

	self assert: plan class equals: GbsMigrationPlan.
	self deny: plan includesSubclasses.
	self assert: plan totalInstanceCount equals: 4.
	self assert: plan affectedClassCount equals: 1.
	self assert: entry sourceName equals: 'OldInvoice'.
	self assert: entry sourceVersion equals: 1.
	self assert: entry sourceNumberOfVersions equals: 2.
	self assert: entry targetName equals: 'Invoice'.
	self assert: entry targetProxy oop equals: 1008.
	self assert: entry instanceCount equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadePreviewOldVersionsToLatestBuildsExpectedPlan [
	| mockSession plan |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'Invoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: 'withAllSubclasses') ifTrue: [
			^ #(
				#(1000 'Invoice' 1 2 1008 'Invoice' 0)
				#(1010 'OldReceipt' 1 3 1018 'Receipt' 5)) ].
		self fail ].

	plan := (mockSession classHistoryOf: 'Invoice')
		previewOldVersionsToLatest.

	self assert: plan includesSubclasses.
	self assert: plan entries size equals: 2.
	self assert: plan totalInstanceCount equals: 5.
	self assert: plan affectedClassCount equals: 1.
	self assert: plan hasAffectedInstances.
	self assert: (plan sourceNames includes: 'Invoice').
	self assert: (plan sourceNames includes: 'OldReceipt').
	self assert: (plan targetNames includes: 'Receipt')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadeExecutePreviewPlanDelegatesToMigrationOperation [
	| mockSession plan result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: 'SystemRepository listInstances: { fromClass }') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].
		(script includesSubstring: 'fromClass migrateInstances: instances to: toClass') ifTrue: [
			^ 4 ].
		self fail ].

	plan := (mockSession classHistoryOf: 'OldInvoice')
		previewMigrationTo: 'Invoice'.
	result := (mockSession classHistoryOf: 'OldInvoice')
		executePreviewPlan: plan.

	self assert: result equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadeRemoveOldVersionBindingsFromLocalDictionary [
	| mockSession history dictionary removed |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		self fail ].

	history := mockSession classHistoryOf: 'OldInvoice'.
	dictionary := Dictionary new
		at: 'OldInvoice' put: #old;
		at: 'Invoice' put: #current;
		yourself.
	removed := history removeOldVersionBindingsFrom: dictionary.

	self assert: removed equals: #('OldInvoice').
	self deny: (dictionary includesKey: 'OldInvoice').
	self assert: (dictionary at: 'Invoice') equals: #current
]

{ #category : 'tests' }
GbsSessionCoreTest >> testMigrationPlanImpactSummaryStringIncludesScopeAndEntries [
	| plan summary |
	plan := GbsMigrationPlan new
		entries: {
			(GbsMigrationPlanEntry
				sourceName: 'OldReceipt'
				proxy: nil
				version: 1
				numberOfVersions: 3
				targetName: 'Receipt'
				targetProxy: nil
				count: 5).
			(GbsMigrationPlanEntry
				sourceName: 'Invoice'
				proxy: nil
				version: 1
				numberOfVersions: 2
				targetName: 'Invoice'
				targetProxy: nil
				count: 0) };
		includesSubclasses: true;
		yourself.

	summary := plan impactSummaryString.

	self assert: (summary includesSubstring: '5 instances across 1 classes').
	self assert: (summary includesSubstring: 'including subclasses').
	self assert: (summary includesSubstring: 'OldReceipt -> Receipt (5 instances)')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassVersionBrowserPreviewMigrationToLatestBuildsExpectedPlan [
	| mockSession browser plan |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: 'SystemRepository listInstances: { fromClass }') ifTrue: [
			self assert: (script includesSubstring: '1008').
			^ #(
				#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].
		self fail ].

	browser := GbxClassVersionBrowser new
		classHistory: (mockSession classHistoryOf: 'OldInvoice');
		yourself.
	plan := browser previewMigrationToLatestAllowAbort: false.

	self assert: plan class equals: GbsMigrationPlan.
	self deny: plan includesSubclasses.
	self assert: plan totalInstanceCount equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassVersionBrowserExecutePreviewPlanAndRemoveOldBindings [
	| mockSession browser plan result dictionary removed |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: 'SystemRepository listInstances: { fromClass }') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].
		(script includesSubstring: 'fromClass migrateInstances: instances to: toClass') ifTrue: [
			^ 4 ].
		self fail ].

	browser := GbxClassVersionBrowser new
		classHistory: (mockSession classHistoryOf: 'OldInvoice');
		yourself.
	plan := browser previewMigrationToLatestAllowAbort: false.
	result := browser executePreviewPlan: plan allowAbort: false.
	dictionary := Dictionary new
		at: 'OldInvoice' put: #old;
		at: 'Invoice' put: #current;
		yourself.
	removed := browser removeOldVersionBindingsFrom: dictionary.

	self assert: result equals: 4.
	self assert: removed equals: #('OldInvoice').
	self deny: (dictionary includesKey: 'OldInvoice')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryAllInstancesOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'cls allInstances').
		self assert: (script includesSubstring: 'objectNamed: name asSymbol').
		self assert: (script includesSubstring: '''Invoice''').
		#(1 2 3) ].

	result := mockSession repository allInstancesOfNamed: 'Invoice'.

	self assert: result equals: #(1 2 3)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryListInstancesOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'SystemRepository listInstances: { cls }').
		self assert: (script includesSubstring: '''Invoice''').
		#(3 4 5) ].

	result := mockSession repository listInstancesOfNamed: 'Invoice'.

	self assert: result equals: #(3 4 5)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryListInstancesOfNamedWithLimitBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'limit: 25').
		#(7 8) ].

	result := mockSession repository listInstancesOfNamed: 'Invoice' limit: 25.

	self assert: result equals: #(7 8)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryListInstancesRefusesAbortWhenSessionIsDirty [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit')
			ifTrue: [ ^ true ].
		self fail ].

	self
		should: [ mockSession repository listInstancesOfNamed: 'Invoice' ]
		raise: GbsError
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryListInstancesAllowsAbortWhenSessionIsDirty [
	| mockSession aborted result |
	mockSession := CoreMockGbsSession new.
	aborted := false.
	mockSession stubs at: #gciAbort put: [ aborted := true. 1 ].
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit')
			ifTrue: [ ^ true ].
		self assert: aborted.
		self assert: (script includesSubstring: 'SystemRepository listInstances: { cls }').
		#(11 12) ].

	result := mockSession repository listInstancesOfNamed: 'Invoice' allowAbort: true.

	self assert: aborted.
	self assert: result equals: #(11 12)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMigrateInstancesFromToBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'SystemRepository listInstances: { fromClass }').
		self assert: (script includesSubstring: 'fromClass migrateInstances: instances to: toClass').
		self assert: (script includesSubstring: '''OldInvoice''').
		self assert: (script includesSubstring: '''Invoice''').
		4 ].

	result := mockSession migrateInstancesFrom: 'OldInvoice' to: 'Invoice'.

	self assert: result equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryPreviewMigrationFromToBuildsExpectedPlan [
	| mockSession plan entry |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'SystemRepository listInstances: { fromClass }').
		self assert: (script includesSubstring: '''OldInvoice''').
		self assert: (script includesSubstring: '''Invoice''').
		#(
			#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].

	plan := mockSession repository
		previewMigrationFrom: 'OldInvoice'
		to: 'Invoice'.
	entry := plan entries first.

	self assert: plan class equals: GbsMigrationPlan.
	self deny: plan includesSubclasses.
	self assert: plan totalInstanceCount equals: 4.
	self assert: entry sourceName equals: 'OldInvoice'.
	self assert: entry targetName equals: 'Invoice'.
	self assert: entry instanceCount equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryPreviewMigrationWithSubclassesBuildsExpectedPlan [
	| mockSession plan |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'withAllSubclasses').
		self assert: (script includesSubstring: 'SystemRepository listInstances: oldClasses asArray').
		#(
			#(1000 'OldInvoice' 1 2 1008 'Invoice' 0)
			#(1010 'OldReceipt' 1 3 1018 'Receipt' 5)) ].

	plan := mockSession repository previewMigrationWithSubclassesOf: 'Invoice'.

	self assert: plan includesSubclasses.
	self assert: plan entries size equals: 2.
	self assert: plan totalInstanceCount equals: 5.
	self assert: plan affectedClassCount equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMigrateInstancesWithSubclassesBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'withAllSubclasses').
		self assert: (script includesSubstring: 'SystemRepository listInstances: oldClasses asArray').
		self assert: (script includesSubstring: '''Invoice''').
		6 ].

	result := mockSession migrateInstancesWithSubclassesOf: 'Invoice'.

	self assert: result equals: 6
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryAllInstancesOopOfNamedUsesRawServerOop [
	| mockSession oop |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #apiGciExecuteStrContextEnv put: [ :script :context :env |
		self assert: context equals: 20.
		self assert: env equals: 0.
		self assert: (script includesSubstring: 'cls allInstances').
		9876 ].

	oop := mockSession repository allInstancesOopOfNamed: 'Invoice'.

	self assert: oop equals: 9876
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryClassHistoryOfRetainsSessionAndReference [
	| mockSession history |
	mockSession := CoreMockGbsSession new.

	history := mockSession repository classHistoryOf: 'Invoice'.

	self assert: history class equals: GbsClassHistoryFacade.
	self assert: history session == mockSession.
	self assert: history classReference equals: 'Invoice'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryFacadeRetainsSession [
	| mockSession facade |
	mockSession := CoreMockGbsSession new.

	facade := mockSession repository.

	self assert: facade class equals: GbsRepositoryFacade.
	self assert: facade session == mockSession
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootReturnsRootFacade [
	| mockSession root |
	mockSession := CoreMockGbsSession new.

	root := mockSession repository root.

	self assert: root class equals: GbsRepositoryRootFacade.
	self assert: root session == mockSession.
	self assert: root rootKey equals: #GbsBridgeRoot.
	self assert: root path isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootFacadeIsMemoizedUntilInvalidation [
	| mockSession first second third |
	mockSession := CoreMockGbsSession new.

	first := mockSession repository root.
	second := mockSession repository root.
	mockSession invalidateRepositoryRoots.
	third := mockSession repository root.

	self assert: first == second.
	self deny: third == first
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryLoadedClassesUsesVisibleBehaviorScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'value isBehavior').
		#('Account' 'Invoice') ].

	result := mockSession repository loadedClasses.

	self assert: result equals: #('Account' 'Invoice')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootAtIfAbsentEvaluatesFallback [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#GbsBridgeRoot').
		self assert: (script includesSubstring: 'at: key ifAbsent: [ nil ]').
		nil ].

	result := mockSession repository rootAt: #missing ifAbsent: [ #fallback ].

	self assert: result equals: #fallback
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootAtPutBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#GbsBridgeRoot').
		self assert: (script includesSubstring: 'container at: key put: value').
		self assert: (script includesSubstring: '#ticket').
		self assert: (script includesSubstring: '''vip''').
		'vip' ].

	result := mockSession repository rootAt: #ticket put: 'vip'.

	self assert: result equals: 'vip'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootProxyUsesRootScriptAndReturnsProxy [
	| mockSession root result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: '#GbsBridgeRoot').
		2001 ].
	root := mockSession repository root.

	result := root proxy.

	self assert: result oop equals: 2001.
	self assert: result session == mockSession
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootProxyRefreshesAfterInvalidation [
	| mockSession root first second oops |
	mockSession := CoreMockGbsSession new.
	oops := #(2001 2002) readStream.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: '#GbsBridgeRoot').
		oops next ].
	root := mockSession repository root.

	first := root proxy.
	mockSession invalidateRepositoryRoots.
	second := root proxy.

	self assert: first oop equals: 2001.
	self assert: second oop equals: 2002.
	self deny: second == first
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootKeysBuildExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#GbsBridgeRoot').
		self assert: (script includesSubstring: 'container keys asArray').
		#(#tickets #users) ].

	result := mockSession repository root keys.

	self assert: result equals: #(#tickets #users)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootEnsureNamespaceAtReturnsNestedFacade [
	| mockSession namespace |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: 'at: key ifAbsentPut: [ Dictionary new ]').
		self assert: (script includesSubstring: '#tickets').
		3001 ].

	namespace := (mockSession repository root) ensureNamespaceAt: #tickets.

	self assert: namespace class equals: GbsRepositoryRootFacade.
	self assert: namespace rootKey equals: #GbsBridgeRoot.
	self assert: namespace path equals: #(#tickets)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootNamespaceFacadeUsesSessionCache [
	| mockSession first second |
	mockSession := CoreMockGbsSession new.

	first := (mockSession repository root) namespaceFacadeAt: #tickets.
	second := (mockSession repository root) namespaceFacadeAt: #tickets.

	self assert: first == second.
	self assert: first path equals: #(#tickets)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootNamespaceAtIfAbsentEvaluatesFallback [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'value isKindOf: Dictionary').
		self assert: (script includesSubstring: '#tickets').
		false ].

	result := (mockSession repository root)
		namespaceAt: #tickets
		ifAbsent: [ #fallback ].

	self assert: result equals: #fallback
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootWithReadLockDoLocksAndUnlocksContainer [
	| mockSession root scripts result seenFacade seenProxy |
	mockSession := CoreMockGbsSession new.
	scripts := OrderedCollection new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: '#GbsBridgeRoot').
		4001 ].
	mockSession stubs at: #execute put: [ :script |
		scripts add: script.
		true ].
	root := mockSession repository root.

	result := root withReadLockDo: [ :facade :proxy |
		seenFacade := facade.
		seenProxy := proxy.
		#done ].

	self assert: result equals: #done.
	self assert: seenFacade == root.
	self assert: seenProxy oop equals: 4001.
	self assert: scripts size equals: 2.
	self assert: (scripts first includesSubstring: 'System perform: #readLock:').
	self assert: (scripts second includesSubstring: 'System perform: #removeLock:')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testCommitTransactionInvalidatesRepositoryRoots [
	| mockSession first second |
	mockSession := CoreMockGbsSession new.
	first := mockSession repository root.

	self assert: mockSession commitTransaction.
	second := mockSession repository root.

	self deny: second == first.
	self assert: mockSession repositoryRootLifecycleVersion equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testAbortTransactionInvalidatesRepositoryRoots [
	| mockSession first second |
	mockSession := CoreMockGbsSession new.
	first := mockSession repository root.

	self assert: mockSession abortTransaction.
	second := mockSession repository root.

	self deny: second == first.
	self assert: mockSession repositoryRootLifecycleVersion equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testExecuteScriptAndReturnOopUsesServerInterface [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #apiGciExecuteStrContextEnv put: [ :script :context :env |
		self assert: script equals: '42'.
		self assert: context equals: 20.
		self assert: env equals: 0.
		123456 ].

	result := mockSession executeScriptAndReturnOop: '42'.

	self assert: result equals: 123456
]

{ #category : 'tests' }
GbsSessionCoreTest >> testLogoutClearsProxyIdentityMap [
	| mockSession proxy |
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciLogout put: nil.
	proxy := mockSession resultFor: 1001.

	self assert: (mockSession cachedProxyForOop: 1001) == proxy.

	mockSession logout.

	self assert: (mockSession cachedProxyForOop: 1001) isNil
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReadAndWriteLockUseCompatibilityScripts [
	| mockSession scripts |
	mockSession := CoreMockGbsSession new.
	scripts := OrderedCollection new.
	mockSession stubs at: #execute put: [ :script |
		scripts add: script.
		true ].

	self assert: (mockSession readLock: #seat42) == mockSession.
	self assert: (mockSession writeLock: #seat42) == mockSession.
	self
		assert: scripts asArray
		equals: {
			(mockSession systemCallScriptForSelector: #readLock: arguments: { #seat42 }).
			(mockSession systemCallScriptForSelector: #writeLock: arguments: { #seat42 }) }
]
