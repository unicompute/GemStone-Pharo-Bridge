Class {
	#name : 'GbsSessionManagerCoreTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousFastRegistry',
		'previousConnectionRegistry',
		'previousInvalidActionRegistry',
		'previousPostConnectActionRegistry',
		'previousSessionConnectorRegistry',
		'previousConnectorObjectRegistry',
		'previousConnectorClassMappingRegistry',
		'previousTypedWrapperRegistry',
		'previousTypedWrapperAutoloadRegistry',
		'previousSessionTypedWrapperAutoloadRegistry',
		'previousTypedWrapperAutoloadPairRegistry',
		'previousSessionTypedWrapperAutoloadPairRegistry',
		'previousCurrentSession',
		'previousParameterCurrentSession',
		'previousObjectSpaceFinalizationRegistry'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GbsSessionManagerCoreTest >> setUp [
	super setUp.
	previousFastRegistry := GbsSessionManager fastConnectorRegistry copy.
	previousConnectionRegistry := (Smalltalk globals at: #GbsConnectorConnectionRegistry ifAbsent: [ Dictionary new ]) copy.
	previousInvalidActionRegistry := (Smalltalk globals at: #GbsConnectorInvalidActionRegistry ifAbsent: [ Dictionary new ]) copy.
	previousPostConnectActionRegistry := (Smalltalk globals at: #GbsConnectorPostConnectActionRegistry ifAbsent: [ Dictionary new ]) copy.
	previousSessionConnectorRegistry := (Smalltalk globals at: #GbsSessionConnectorRegistry ifAbsent: [ Dictionary new ]) copy.
	previousConnectorObjectRegistry := (Smalltalk globals at: #GbsConnectorObjectRegistry ifAbsent: [ Dictionary new ]) copy.
	previousConnectorClassMappingRegistry := (Smalltalk globals at: #GbsConnectorClassMappingRegistry ifAbsent: [ Dictionary new ]) copy.
	previousTypedWrapperRegistry := (Smalltalk globals at: #GbsTypedWrapperRegistry ifAbsent: [ Dictionary new ]) copy.
	previousTypedWrapperAutoloadRegistry := (Smalltalk globals at: #GbsTypedWrapperAutoloadRegistry ifAbsent: [ Dictionary new ]) copy.
	previousSessionTypedWrapperAutoloadRegistry := (Smalltalk globals at: #GbsSessionTypedWrapperAutoloadRegistry ifAbsent: [ Dictionary new ]) copy.
	previousTypedWrapperAutoloadPairRegistry := (Smalltalk globals at: #GbsTypedWrapperAutoloadPairRegistry ifAbsent: [ OrderedCollection new ]) copy.
	previousSessionTypedWrapperAutoloadPairRegistry := (Smalltalk globals at: #GbsSessionTypedWrapperAutoloadPairRegistry ifAbsent: [ Dictionary new ]) copy.
	previousCurrentSession := GBSM currentSession.
	previousParameterCurrentSession := GbsSessionParameters currentSession.
	previousObjectSpaceFinalizationRegistry := Smalltalk globals
		at: #GbsObjectSpaceFinalizationRegistry
		ifAbsent: [ nil ].
	GBSM currentSession: nil.
	GbsSessionParameters currentSession: nil.
	GbsObjectSpaceFacade resetFinalizationRegistry
]

{ #category : 'running' }
GbsSessionManagerCoreTest >> tearDown [
	GbsSessionManager fastConnectorRegistry: previousFastRegistry.
	Smalltalk globals at: #GbsConnectorConnectionRegistry put: previousConnectionRegistry.
	Smalltalk globals at: #GbsConnectorInvalidActionRegistry put: previousInvalidActionRegistry.
	Smalltalk globals at: #GbsConnectorPostConnectActionRegistry put: previousPostConnectActionRegistry.
	Smalltalk globals at: #GbsSessionConnectorRegistry put: previousSessionConnectorRegistry.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: previousConnectorObjectRegistry.
	Smalltalk globals at: #GbsConnectorClassMappingRegistry put: previousConnectorClassMappingRegistry.
	Smalltalk globals at: #GbsTypedWrapperRegistry put: previousTypedWrapperRegistry.
	Smalltalk globals at: #GbsTypedWrapperAutoloadRegistry put: previousTypedWrapperAutoloadRegistry.
	Smalltalk globals at: #GbsSessionTypedWrapperAutoloadRegistry put: previousSessionTypedWrapperAutoloadRegistry.
	Smalltalk globals at: #GbsTypedWrapperAutoloadPairRegistry put: previousTypedWrapperAutoloadPairRegistry.
	Smalltalk globals at: #GbsSessionTypedWrapperAutoloadPairRegistry put: previousSessionTypedWrapperAutoloadPairRegistry.
	GBSM currentSession: previousCurrentSession.
	GbsSessionParameters currentSession: previousParameterCurrentSession.
	previousObjectSpaceFinalizationRegistry
		ifNil: [ Smalltalk globals removeKey: #GbsObjectSpaceFinalizationRegistry ifAbsent: [ ] ]
		ifNotNil: [ Smalltalk globals at: #GbsObjectSpaceFinalizationRegistry put: previousObjectSpaceFinalizationRegistry ].
	super tearDown
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMRepositoryAndObjectSpaceDelegatesToCurrentSession [
	| mockSession repository objectSpace |
	mockSession := CoreMockGbsSession new.
	GBSM currentSession: mockSession.

	repository := GBSM repository.
	objectSpace := GBSM objectSpace.

	self assert: repository class equals: GbsRepositoryFacade.
	self assert: repository session == mockSession.
	self assert: objectSpace class equals: GbsObjectSpaceFacade.
	self assert: objectSpace session == mockSession
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMObjectSpaceDelegatesToCurrentSession [
	| mockSession loaded subclasses instances references paged filtered |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script = 'SystemRepository _loadedClasses: false') ifTrue: [ ^ #('Invoice') ].
		(script includesSubstring: 'cls allSubclasses asArray') ifTrue: [ ^ #(SubclassOne) ].
		(script includesSubstring: 'SystemRepository _listInstancesInMemory: { cls }') ifTrue: [ ^ #(11 12) ].
		(script includesSubstring: 'findReferencesInMemory asArray') ifTrue: [ ^ #(31 32) ].
		(script includesSubstring: 'startIndex := 2') ifTrue: [ ^ #(12 13) ].
		(script includesSubstring: 'startIndex := 1') ifTrue: [ ^ #(11 12) ].
		(script includesSubstring: 'startIndex := 3') ifTrue: [ ^ #(13 14) ].
		self fail ].
	GBSM currentSession: mockSession.

	loaded := GBSM loadedClassesIncludingModules: false.
	subclasses := GBSM allSubclassesOfNamed: 'Invoice'.
	instances := GBSM instancesInMemoryOfNamed: 'Invoice'.
	references := GBSM referencesToOop: 4242.
	paged := GBSM objectsInMemoryFrom: 2 limit: 2.
	filtered := GBSM
		objectsInMemoryMatching: [ :each | each odd ]
		limit: 2
		batchSize: 2.

	self assert: loaded equals: #('Invoice').
	self assert: subclasses equals: #(SubclassOne).
	self assert: instances equals: #(11 12).
	self assert: references equals: #(31 32).
	self assert: paged equals: #(12 13).
	self assert: filtered equals: #(11 13)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMSessionStateDelegatesToCurrentSession [
	| mockSession stored finalizerRegistry |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System sessionStateAt: key put: value')
			ifTrue: [ ^ 'cached-value' ].
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ 'finalizer-registry' ].
		self fail ].
	GBSM currentSession: mockSession.

	stored := GBSM sessionStateAt: 21 put: 'cached-value'.
	finalizerRegistry := GBSM maglevFinalizerRegistry.

	self assert: stored equals: 'cached-value'.
	self assert: finalizerRegistry equals: 'finalizer-registry'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMEachObjectAndFinalizerDelegatesToCurrentSession [
	| mockSession seen target group |
	mockSession := CoreMockGbsSession new.
	seen := OrderedCollection new.
	target := Object new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _loadedClasses: false') ifTrue: [ ^ #(21 22) ].
		self fail ].
	GBSM currentSession: mockSession.

	GBSM eachObjectDo: [ :each |
		seen add: each ].
	group := GBSM
		defineFinalizerFor: target
		do: [ :each | each ].

	self assert: seen asArray equals: #(21 22).
	self assert: group size equals: 1.
	self assert: (GBSM hasFinalizerFor: target).

	GBSM undefineFinalizerFor: target.
	self deny: (GBSM hasFinalizerFor: target)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMFetchProfileDelegatesToCurrentSession [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	GBSM currentSession: mockSession.

	GBSM fetchByReference.
	self assert: GBSM fetchProfile class equals: GbsProxyOnlyMaterializationProfile.

	GBSM fetchDeep.
	self assert: GBSM fetchProfile class equals: GbsDeepMaterializationProfile
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMTypedWrapperDelegatesToSessionManager [
	| wrapperClass |
	wrapperClass := GBSM
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.

	self assert: (GBSM typedWrapperClassForServerClassNamed: 'ByteArray') == wrapperClass
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMNamedObjectAtDelegatesToCurrentSession [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 1004 session: mockSession ].
	GBSM currentSession: mockSession.

	result := GBSM namedObjectAt: 'UserGlobals'.

	self assert: result oop equals: 1004
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMNamedObjectCacheInspectionDelegatesToCurrentSession [
	| mockSession report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 1004 session: mockSession ].
	GBSM currentSession: mockSession.

	GBSM namedObjectAt: #UserGlobals.
	report := GBSM namedObjectCacheReportText.

	self assert: GBSM namedObjectCacheKeys equals: #(UserGlobals).
	self assert: (GBSM hasCachedNamedObjectNamed: 'UserGlobals').
	self assert: (report includesSubstring: 'UserGlobals').

	GBSM clearNamedObjectCache.

	self assert: GBSM namedObjectCacheKeys isEmpty
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMNamedObjectAutoloadDelegatesToCurrentSession [
	| mockSession report |
	mockSession := CoreMockGbsSession new.
	GBSM currentSession: mockSession.

	GBSM registerNamedObjectAutoload: #UG remote: #UserGlobals.
	report := GBSM namedObjectAutoloadReportText.

	self assert: GBSM namedObjectAutoloadKeys equals: #(UG).
	self assert: (GBSM hasNamedObjectAutoloadNamed: #UG).
	self assert: (GBSM namedObjectAutoloadTargetFor: #UG) equals: #UserGlobals.
	self assert: (report includesSubstring: 'UG -> UserGlobals').

	GBSM clearNamedObjectAutoloads.

	self assert: GBSM namedObjectAutoloadKeys isEmpty
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMBridgeRootAndListInstancesDelegatesToCurrentSession [
	| mockSession rootResult listResult |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'SystemRepository listInstances: { cls }') ifTrue: [ ^ #(1 2) ].
		nil ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		(script includesSubstring: '#GbsBridgeRoot') ifTrue: [ ^ 2001 ].
		self fail ].
	GBSM currentSession: mockSession.

	rootResult := GBSM bridgeRoot.
	listResult := GBSM listInstancesOf: 'Invoice'.

	self assert: rootResult class equals: GbsBridgeRootFacade.
	self assert: rootResult session == mockSession.
	self assert: rootResult proxy oop equals: 2001.
	self assert: listResult equals: #(1 2)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMClassHistoryAndMigrationDelegatesToCurrentSession [
	| mockSession history migrated |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'Invoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'fromClass migrateInstances: instances to: toClass') ifTrue: [ ^ 3 ].
		nil ].
	GBSM currentSession: mockSession.

	history := GBSM classHistoryOf: 'Invoice'.
	migrated := GBSM migrateInstancesFrom: 'OldInvoice' to: 'Invoice'.

	self assert: history class equals: GbsClassHistoryFacade.
	self assert: history canMigrateInstances.
	self assert: migrated equals: 3
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMRemoteMirrorDelegatesToCurrentSession [
	| mockSession classMirror methodMirror |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(1001 'Invoice' 'Object' 'Billing-Core' 'Billing-Models' 2 3) ].
		(script includesSubstring: 'compiledMethodAt: #totalPrice') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	GBSM currentSession: mockSession.

	classMirror := GBSM classMirrorOf: 'Invoice'.
	methodMirror := GBSM
		methodMirrorForClass: 'Invoice'
		selector: #totalPrice.

	self assert: classMirror name equals: 'Invoice'.
	self assert: classMirror superclassName equals: 'Object'.
	self assert: classMirror packageName equals: 'Billing-Core'.
	self assert: classMirror version equals: 2.
	self assert: methodMirror exists.
	self assert: methodMirror ownerName equals: 'Invoice'.
	self assert: methodMirror protocol equals: 'pricing'.
	self assert: methodMirror packageName equals: 'Billing-Core'.
	self assert: methodMirror sourceLocation equals: 'Invoice>>totalPrice'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMMethodObjectDelegatesToCurrentSession [
	| mockSession methodObject |
	mockSession := CoreMockGbsSession new.
	GBSM currentSession: mockSession.

	methodObject := GBSM
		methodObjectForClass: 'Invoice'
		selector: #totalPrice.

	self assert: methodObject session == mockSession.
	self assert: methodObject selector equals: #totalPrice.
	self deny: methodObject classSide
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMMethodReferenceStringsDelegateToCurrentSession [
	| mockSession references |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'organizer referencesTo: #Invoice').
		^ #('Invoice>>totalPrice' 'Invoice class>>new') ].
	GBSM currentSession: mockSession.

	references := GBSM methodReferenceStringsToSymbol: 'Invoice'.

	self assert: references equals: #('Invoice>>totalPrice' 'Invoice class>>new')
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMSelectorReferenceQueriesDelegateToCurrentSession [
	| mockSession implementors senders |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'organizer implementorsOf: #size') ifTrue: [
			^ #('Object>>size') ].
		(script includesSubstring: 'organizer sendersOf: ''size''') ifTrue: [
			^ #('Behavior>>new') ].
		self fail ].
	GBSM currentSession: mockSession.

	implementors := GBSM implementorMethodReferenceStringsForSelector: 'size'.
	senders := GBSM senderMethodReferenceStringsForSelector: 'size'.

	self assert: implementors equals: #('Object>>size').
	self assert: senders equals: #('Behavior>>new')
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGBSMMigrationPreviewDelegatesToCurrentSession [
	| mockSession plan |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'SystemRepository listInstances: { fromClass }') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].
		self fail ].
	GBSM currentSession: mockSession.

	plan := GBSM
		previewMigrationFrom: 'OldInvoice'
		to: 'Invoice'.

	self assert: plan class equals: GbsMigrationPlan.
	self assert: plan totalInstanceCount equals: 4.
	self assert: plan entries first targetName equals: 'Invoice'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testFastConnectorRegistryAutoloadsWhenGlobalRegistryIsMissing [
	| registry |
	Smalltalk globals removeKey: #GbsFastConnectorRegistry ifAbsent: [ ].

	registry := GbsSessionManager fastConnectorRegistry.

	self assert: registry notNil.
	self assert: (registry at: 'ByteString' ifAbsent: [ nil ]) equals: 'String'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testFastConnectorRegistryStaysEmptyWhenExplicitlyReset [
	GbsSessionManager fastConnectorRegistry: Dictionary new.

	self assert: GbsSessionManager fastConnectorRegistry isEmpty
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGenerateTypedWrapperForConnectorPairCreatesSubclass [
	| wrapperClass |
	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.

	self assert: (wrapperClass inheritsFrom: GbsTypedProxy).
	self assert: wrapperClass clientBehaviorName equals: 'ByteArray'.
	self assert: wrapperClass serverBehaviorName equals: 'ByteArray'.
	self assert: (GbsSessionManager typedWrapperClassForServerClassNamed: 'ByteArray') == wrapperClass
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLookupAutoloadsKnownServerClassWithoutExplicitBootstrap [
	| wrapperClass |
	Smalltalk globals removeKey: #GbsFastConnectorRegistry ifAbsent: [ ].
	Smalltalk globals at: #GbsTypedWrapperRegistry put: Dictionary new.

	wrapperClass := GbsSessionManager typedWrapperClassForServerClassNamed: 'Dictionary'.

	self assert: wrapperClass notNil.
	self assert: (wrapperClass inheritsFrom: GbsTypedProxy).
	self assert: wrapperClass clientBehaviorName equals: 'Dictionary'.
	self assert: wrapperClass serverBehaviorName equals: 'Dictionary'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperAutoloadPairsIncludeSessionScopedConnectorPairs [
	| params session pairs |
	params := GbsSessionParameters new.
	params username: 'DataCurator'.
	params gemStoneName: 'gs64stone'.
	session := CoreMockGbsSession new.
	session parameters: params.
	GbsSessionManager fastConnectorRegistry: Dictionary new.
	GbsSessionManager
		addConnectorClient: 'ByteArray'
		server: 'RemoteLedger'
		forSession: session.

	pairs := GbsSessionManager typedWrapperAutoloadPairsForSession: session.

	self assert: (pairs anySatisfy: [ :pair |
		{ (pair at: 1 ifAbsent: [ '' ]). (pair at: 2 ifAbsent: [ '' ]) } asSet
			= #('ByteArray' 'RemoteLedger') asSet ])
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testExplicitTypedWrapperAutoloadRegistrationAppearsInEntriesAndReport [
	| entries report row |
	GbsSessionManager clearTypedWrapperAutoloadRegistrations.
	GbsSessionManager
		registerTypedWrapperAutoloadClient: 'Money'
		server: 'RemoteMoney'.

	entries := GbsSessionManager typedWrapperAutoloadEntries.
	report := GbsSessionManager typedWrapperAutoloadReportText.
	row := entries
		detect: [ :each | (each at: 1) = 'Money' and: [ (each at: 2) = 'RemoteMoney' ] ]
		ifNone: [ nil ].

	self assert: row notNil.
	self assert: (row at: 3) equals: 'global'.
	self assert: (row at: 4) equals: 'explicit'.
	self assert: (report includesSubstring: 'Money -> RemoteMoney').
	self assert: (report includesSubstring: 'explicit')
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testExplicitTypedWrapperAutoloadRemovalIsScopedToExplicitRegistry [
	| pairs |
	GbsSessionManager fastConnectorRegistry: Dictionary new.
	GbsSessionManager
		addConnectorClient: 'ByteArray'
		server: 'RemoteLedger'.
	GbsSessionManager
		registerTypedWrapperAutoloadClient: 'Money'
		server: 'RemoteMoney'.

	GbsSessionManager
		unregisterTypedWrapperAutoloadClient: 'Money'
		server: 'RemoteMoney'.
	pairs := GbsSessionManager typedWrapperAutoloadPairs.

	self deny: (pairs anySatisfy: [ :pair |
		{ (pair at: 1 ifAbsent: [ '' ]). (pair at: 2 ifAbsent: [ '' ]) } asSet
			= #('Money' 'RemoteMoney') asSet ]).
	self assert: (pairs anySatisfy: [ :pair |
		{ (pair at: 1 ifAbsent: [ '' ]). (pair at: 2 ifAbsent: [ '' ]) } asSet
			= #('ByteArray' 'RemoteLedger') asSet ])
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLookupAutoloadsSessionScopedConnectorPair [
	| params session wrapperClass |
	params := GbsSessionParameters new.
	params username: 'DataCurator'.
	params gemStoneName: 'gs64stone'.
	session := CoreMockGbsSession new.
	session parameters: params.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ #(5001 'RemoteLedger' 'Object' nil nil 2 4) ].
		(script includesSubstring: 'behavior := cls.') ifTrue: [
			self assert: (script includesSubstring: '''RemoteLedger''').
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GbsSessionManager fastConnectorRegistry: Dictionary new.
	GbsSessionManager
		addConnectorClient: 'ByteArray'
		server: 'RemoteLedger'
		forSession: session.
	GBSM currentSession: session.

	wrapperClass := GbsSessionManager typedWrapperClassForServerClassNamed: 'RemoteLedger'.

	self assert: wrapperClass notNil.
	self assert: wrapperClass clientBehaviorName equals: 'ByteArray'.
	self assert: wrapperClass serverBehaviorName equals: 'RemoteLedger'.
	self assert: wrapperClass generatedForwardingSource equals: #remote.
	self assert: (wrapperClass generatedForwardingSelectors includes: #approvePayment:)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperRegistryEntriesAndReportTextExposeAutoloadState [
	| wrapperClass entries report row |
	GbsSessionManager fastConnectorRegistry: (Dictionary new
		at: 'ByteArray' put: 'ByteArray';
		at: 'ByteArray' put: 'ByteArray';
		yourself).
	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.

	entries := GbsSessionManager typedWrapperRegistryEntries.
	report := GbsSessionManager typedWrapperAutoloadReportText.
	row := entries
		detect: [ :each | (each at: 1) = 'ByteArray' and: [ (each at: 2) = 'ByteArray' ] ]
		ifNone: [ nil ].

	self assert: row notNil.
	self assert: (row at: 3) equals: wrapperClass name asString.
	self assert: ((row at: 4) isString).
	self assert: (row at: 5).
	self assert: (report includesSubstring: 'ByteArray -> ByteArray').
	self assert: (report includesSubstring: wrapperClass name asString)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGeneratedTypedWrapperCompilesForwardingMethods [
	| wrapperClass |
	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.

	self assert: (wrapperClass methodDict includesKey: #add:).
	self assert: (wrapperClass methodDict includesKey: #size).
	self assert: (wrapperClass generatedForwardingSelectors includes: #add:).
	self assert: (wrapperClass generatedForwardingSelectors includes: #size).
	self deny: (wrapperClass generatedForwardingSelectors includes: #isNil)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGenerateTypedWrapperUsesRemoteMirrorSelectorsWhenCurrentSessionAvailable [
	| wrapperClass mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ #(5001 'RemoteLedger' 'Object' nil nil 2 4) ].
		(script includesSubstring: 'behavior := cls.') ifTrue: [
			self assert: (script includesSubstring: '''RemoteLedger''').
			^ #(
				#('accessing' #('size' 'ticketReference'))
				#('payments' #('payeeName:' 'applyAmount:currency:'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.

	self assert: (wrapperClass generatedForwardingSelectors includes: #ticketReference).
	self assert: (wrapperClass generatedForwardingSelectors includes: #payeeName:).
	self assert: (wrapperClass generatedForwardingSelectors includes: #applyAmount:currency:).
	self deny: (wrapperClass generatedForwardingSelectors includes: #add:).
	self assert: wrapperClass generatedForwardingSource equals: #remote.
	self assert: wrapperClass generatedForwardingProtocols first first equals: 'accessing'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGeneratedTypedWrapperMethodForwardsThroughSession [
	| wrapperClass proxy mockSession capturedSelector capturedArguments capturedOop result |
	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#forwarded ].
	proxy := wrapperClass oop: 1234 session: mockSession.

	result := proxy add: 2.

	self assert: result equals: #forwarded.
	self assert: capturedSelector equals: #add:.
	self assert: capturedArguments equals: #(2).
	self assert: capturedOop equals: 1234
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGenerateTypedWrappersForConnectorPairsUsesConnectorRegistry [
	| wrappers |
	GbsSessionManager fastConnectorRegistry: (Dictionary new
		at: 'ByteArray' put: 'ByteArray';
		yourself).

	wrappers := GbsSessionManager generateTypedWrappersForConnectorPairs.

	self assert: wrappers size equals: 1.
	self assert: ((GbsSessionManager typedWrapperClassForServerClassNamed: 'ByteArray')
		serverBehaviorName) equals: 'ByteArray'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLookupRefreshesExistingWrapperFromRemoteMetadata [
	| initialWrapper refreshedWrapper mockSession |
	initialWrapper := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	self assert: initialWrapper generatedForwardingSource equals: #client.

	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ #(5001 'RemoteLedger' 'Object' nil nil 2 4) ].
		(script includesSubstring: 'behavior := cls.') ifTrue: [
			self assert: (script includesSubstring: '''RemoteLedger''').
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.
	GbsSessionManager fastConnectorRegistry: (Dictionary new
		at: 'ByteArray' put: 'RemoteLedger';
		at: 'RemoteLedger' put: 'ByteArray';
		yourself).

	refreshedWrapper := GbsSessionManager typedWrapperClassForServerClassNamed: 'RemoteLedger'.

	self assert: refreshedWrapper == initialWrapper.
	self assert: refreshedWrapper generatedForwardingSource equals: #remote.
	self assert: (refreshedWrapper generatedForwardingSelectors includes: #approvePayment:).
	self assert: (refreshedWrapper generatedForwardingSelectors includes: #cancelPayment).
	self deny: (refreshedWrapper generatedForwardingSelectors includes: #add:)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testGeneratedTypedWrapperStoresRemoteVersionMetadata [
	| wrapperClass mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ #(5001 'RemoteLedger' 'Object' nil nil 2 4) ].
		(script includesSubstring: 'behavior methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.

	self assert: wrapperClass generatedForwardingSource equals: #remote.
	self assert: wrapperClass serverBehaviorVersion equals: 2.
	self assert: wrapperClass serverBehaviorNumberOfVersions equals: 4
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLookupRefreshesRemoteWrapperWhenVersionMetadataChanges [
	| mockSession wrapperClass version |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'behavior methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	self assert: wrapperClass serverBehaviorNumberOfVersions equals: 4.

	version := 3.
	wrapperClass := GbsSessionManager typedWrapperClassForServerClassNamed: 'RemoteLedger'.

	self assert: wrapperClass serverBehaviorNumberOfVersions equals: 5.
	self assert: wrapperClass generatedForwardingSource equals: #remote
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLifecycleEntriesReflectCurrentAndStaleStatus [
	| mockSession wrapperClass version currentRow staleRow |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'behavior methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	currentRow := (GbsSessionManager typedWrapperLifecycleEntriesForSession: mockSession)
		detect: [ :each | each third = wrapperClass name asString ].

	version := 3.
	staleRow := (GbsSessionManager typedWrapperLifecycleEntriesForSession: mockSession)
		detect: [ :each | each third = wrapperClass name asString ].

	self assert: (currentRow at: 9) equals: 'current'.
	self assert: (staleRow at: 5) equals: 2.
	self assert: (staleRow at: 6) equals: 4.
	self assert: (staleRow at: 7) equals: 3.
	self assert: (staleRow at: 8) equals: 5.
	self assert: (staleRow at: 9) equals: 'stale'
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedWrapperLifecycleReportObjectExposesStructuredEntries [
	| mockSession wrapperClass version report entry |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'behavior methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	version := 3.
	report := GbsSessionManager typedWrapperLifecycleReportForSession: mockSession.
	entry := report entries
		detect: [ :each | each wrapperClass == wrapperClass ]
		ifNone: [ nil ].

	self assert: report entries isEmpty not.
	self assert: report entries first class equals: GbsTypedWrapperLifecycleEntry.
	self assert: entry notNil.
	self assert: entry status equals: #stale.
	self assert: (report staleEntries includes: entry).
	self assert: (report text includesSubstring: 'Typed Wrapper Lifecycle')
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testTypedProxyLifecycleHelpersExposeStructuredStatus [
	| mockSession wrapperClass version entry |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'behavior methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	version := 3.
	entry := wrapperClass lifecycleEntryForSession: mockSession.

	self assert: entry notNil.
	self assert: (wrapperClass lifecycleStatusForSession: mockSession) equals: #stale.
	self assert: (wrapperClass isLifecycleStaleForSession: mockSession)
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testInvalidateStaleTypedWrapperClassesClearsLocalVersionMetadataButKeepsLookupViable [
	| mockSession wrapperClass version |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs
		at: #gciAbort put: 1;
		at: #executeScriptAndFetchObject
		put: [ :script |
			(script includesSubstring: 'history :=') ifTrue: [
				^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
			(script includesSubstring: 'behavior methodDict keys asSortedCollection') ifTrue: [
				^ #(
					#('accessing' #('size'))
					#('payments' #('approvePayment:' 'cancelPayment'))) ].
			self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	version := 3.

	mockSession abortTransaction.

	self assert: wrapperClass serverBehaviorVersion isNil.
	self assert: wrapperClass serverBehaviorNumberOfVersions isNil.
	wrapperClass := GbsSessionManager typedWrapperClassForServerClassNamed: 'RemoteLedger'.
	self assert: wrapperClass serverBehaviorVersion equals: 3.
	self assert: wrapperClass serverBehaviorNumberOfVersions equals: 5
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testRefreshStaleTypedWrapperClassesForSessionRegeneratesWrapperMetadata [
	| mockSession wrapperClass version refreshed |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
		(script includesSubstring: 'behavior methodDict keys asSortedCollection') ifTrue: [
			^ #(
				#('accessing' #('size'))
				#('payments' #('approvePayment:' 'cancelPayment'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	version := 4.

	refreshed := GbsSessionManager refreshStaleTypedWrapperClassesForSession: mockSession.

	self assert: refreshed size equals: 1.
	self assert: refreshed first == wrapperClass.
	self assert: wrapperClass serverBehaviorVersion equals: 4.
	self assert: wrapperClass serverBehaviorNumberOfVersions equals: 6
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testRefreshAllTypedWrapperClassesForSessionRegeneratesAllRemoteWrappers [
	| mockSession firstWrapper secondWrapper version refreshed |
	version := 2.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'history :=') ifTrue: [
			(script includesSubstring: '''RemoteLedger''') ifTrue: [ ^ { 5001. 'RemoteLedger'. 'Object'. nil. nil. version. version + 2 } ].
			(script includesSubstring: '''RemoteInvoice''') ifTrue: [ ^ { 5002. 'RemoteInvoice'. 'Object'. nil. nil. version + 1. version + 3 } ] ].
		(script includesSubstring: 'behavior methodDict keys asSortedCollection') ifTrue: [
			^ #(#('accessing' #('size'))) ].
		self fail ].
	GBSM currentSession: mockSession.

	firstWrapper := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	secondWrapper := GbsSessionManager
		generateTypedWrapperForClient: 'Array'
		server: 'RemoteInvoice'.
	version := 5.
	refreshed := GbsSessionManager refreshAllTypedWrapperClassesForSession: mockSession.

	self assert: refreshed includes: firstWrapper.
	self assert: refreshed includes: secondWrapper.
	self assert: firstWrapper serverBehaviorVersion equals: 5.
	self assert: secondWrapper serverBehaviorVersion equals: 6
]

{ #category : 'tests' }
GbsSessionManagerCoreTest >> testResetAfterLogoutClearsSessionTypedWrapperAutoloadRegistrations [
	| mockSession sessionKey |
	mockSession := CoreMockGbsSession new.
	sessionKey := GbsSessionManager sessionKeyForSessionObject: mockSession.

	GbsSessionManager
		registerTypedWrapperAutoloadClient: 'ByteArray'
		server: 'RemoteLedger'
		forSession: mockSession.
	self
		assert: ((GbsSessionManager sessionTypedWrapperExplicitAutoloadPairRegistry
			at: sessionKey
			ifAbsent: [ #() ]) size)
		equals: 1.

	mockSession resetAfterLogout.

	self
		assert: ((GbsSessionManager sessionTypedWrapperExplicitAutoloadRegistry
			at: sessionKey
			ifAbsent: [ Dictionary new ]) isEmpty).
	self
		assert: ((GbsSessionManager sessionTypedWrapperExplicitAutoloadPairRegistry
			at: sessionKey
			ifAbsent: [ #() ]) isEmpty)
]
