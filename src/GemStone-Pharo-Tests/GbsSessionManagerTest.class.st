Class {
	#name : 'GbsSessionManagerTest',
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
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsSessionManagerTest >> setUp [
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
GbsSessionManagerTest >> tearDown [
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
GbsSessionManagerTest >> testDateAndTimeSerialization [

  | pharoDate serializedArray |
  "1. Setup: Create a specific DateAndTime in Pharo""Feb 20, 2026 at 13:42:46 with 0 offset"
  pharoDate := DateAndTime
                 year: 2026
                 month: 2
                 day: 20
                 hour: 13
                 minute: 42
                 second: 46
                 offset: 0 hours.

  "2. Execute: Convert it to the bridge format (This will fail MNU)"
  serializedArray := pharoDate asGemStonePrimitiveArray.

  "3. Assertions: Check that it decomposed into a standard Array"
  self assert: ( serializedArray isKindOf: Array ).
  self assert: serializedArray size equals: 7.

  "4. Assertions: Verify the exact data layout expected by the server"
  self assert: ( serializedArray at: 1 ) equals: 2026. "Year"
  self assert: ( serializedArray at: 2 ) equals: 2. "Month"
  self assert: ( serializedArray at: 3 ) equals: 20. "Day"
  self assert: ( serializedArray at: 4 ) equals: 13. "Hour"
  self assert: ( serializedArray at: 5 ) equals: 42. "Minute"
  self assert: ( serializedArray at: 6 ) equals: 46. "Second"
  self assert: ( serializedArray at: 7 ) equals: 0 "Offset in seconds"
]

{ #category : 'tests' }
GbsSessionManagerTest >> testFastConnectorRegistryMapping [
    | sessionManager registry |
    
    "1. Setup"
    sessionManager := GbsSessionManager new.
    sessionManager initializeFastConnectors.
    
    "2. Fetch the registry (This will initially fail because it doesn't exist)"
    registry := sessionManager fastConnectorRegistry.
    
    "3. Assertions: Verify registry exists"
    self assert: registry isNotNil.
    self assert: (registry isKindOf: Dictionary).
    
    "4. Assertions: Verify Client -> Server mapping"
    self assert: (registry at: #ByteString) equals: #String.
    self assert: (registry at: #Array) equals: #Array.
    self assert: (registry at: #DateAndTime) equals: #DateTime.
    
    "5. Assertions: Verify Server -> Client mapping"
    self assert: (registry at: #String) equals: #ByteString.
    self assert: (registry at: #DateTime) equals: #DateAndTime.
]

{ #category : 'tests' }
GbsSessionManagerTest >> testWideStringSerialization [
    | pharoWideString serializedBytes |
    
    "1. Setup: Create a WideString (an emoji forces Pharo to use WideString)"
    pharoWideString := 'Hello 🌍'.
    (pharoWideString respondsTo: #asGemStoneUTF8Bytes) ifFalse: [
        self skip: 'GemStone UTF8 extension not loaded for WideString' ].
    
    "2. Execute: Convert it to the bridge format (This will fail MNU)"
    serializedBytes := pharoWideString asGemStoneUTF8Bytes.
    
    "3. Assertions: Check that it decomposed into a standard ByteArray"
    self assert: (pharoWideString isKindOf: WideString).
    self assert: (serializedBytes isKindOf: ByteArray).
    
    "4. Assertions: Verify the exact UTF-8 byte layout expected by the server"
    "The word 'Hello ' is 6 bytes. The '🌍' emoji is 4 bytes in UTF-8: 240 159 140 141"
	self assert: serializedBytes size equals: 10.
	self assert: (serializedBytes copyFrom: 7 to: 10) asArray equals: #(240 159 140 141).
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMCurrentSessionFallsBackToSessionParametersCurrentSession [
	| session |
	session := MockGbsSession new.
	GBSM currentSession: nil.
	GbsSessionParameters currentSession: session.

	self assert: GBSM currentSession == session
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMCurrentSessionSetterUpdatesSessionParameters [
	| session |
	session := MockGbsSession new.

	GBSM currentSession: session.

	self assert: GBSM currentSession == session.
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMNamedObjectAccessorsDelegateToCurrentSession [
	| mockSession globals published userClasses userGlobals mapping |
	mockSession := MockGbsSession new.
	mapping := Dictionary new
		at: '#Globals' put: 1001;
		at: '#Published' put: 1002;
		at: '#UserClasses' put: 1003;
		at: '#UserGlobals' put: 1004;
		yourself.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script | | match |
		match := mapping keys
			detect: [ :each | script includesSubstring: each ]
			ifNone: [ nil ].
		match
			ifNil: [ nil ]
			ifNotNil: [ GbsProxy oop: (mapping at: match) session: mockSession ] ].
	GBSM currentSession: mockSession.

	globals := GBSM globals.
	published := GBSM published.
	userClasses := GBSM userClasses.
	userGlobals := GBSM userGlobals.

	self assert: globals oop equals: 1001.
	self assert: published oop equals: 1002.
	self assert: userClasses oop equals: 1003.
	self assert: userGlobals oop equals: 1004.
	self assert: (GBSM currentSession userGlobals) oop equals: 1004.
	self assert: (GBSM sessionForwarderFor: #UserGlobals) oop equals: 1004
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMRepositoryAndObjectSpaceDelegatesToCurrentSession [
	| mockSession repository objectSpace |
	mockSession := MockGbsSession new.
	GBSM currentSession: mockSession.

	repository := GBSM repository.
	objectSpace := GBSM objectSpace.

	self assert: repository class equals: GbsRepositoryFacade.
	self assert: repository session == mockSession.
	self assert: objectSpace class equals: GbsObjectSpaceFacade.
	self assert: objectSpace session == mockSession
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMMaglevAndObjectLogDelegatesToCurrentSession [
	| mockSession |
	mockSession := MockGbsSession new.
	GBSM currentSession: mockSession.

	self assert: GBSM smalltalk class equals: GbsSmalltalkFacade.
	self assert: GBSM smalltalk session == mockSession.
	self assert: GBSM maglev class equals: GbsMaglevFacade.
	self assert: GBSM maglev session == mockSession.
	self assert: GBSM objectLog class equals: GbsObjectLogFacade.
	self assert: GBSM objectLog session == mockSession
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMSessionMethodsDelegatesToCurrentSession [
	| mockSession result |
	mockSession := MockGbsSession new.
	GBSM currentSession: mockSession.

	result := GBSM sessionMethods.

	self assert: result class equals: GbsSymbolDictionaryFacade.
	self assert: result name equals: 'SessionMethods'
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMObjectSpaceDelegatesToCurrentSession [
	| mockSession loaded subclasses instances references paged filtered |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testGBSMSessionStateDelegatesToCurrentSession [
	| mockSession stored finalizerRegistry |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testGBSMEachObjectAndFinalizerDelegatesToCurrentSession [
	| mockSession seen target group |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testGBSMFetchProfileDelegatesToCurrentSession [
	| mockSession |
	mockSession := MockGbsSession new.
	GBSM currentSession: mockSession.

	GBSM fetchByReference.
	self assert: GBSM fetchProfile class equals: GbsProxyOnlyMaterializationProfile.

	GBSM fetchDeep.
	self assert: GBSM fetchProfile class equals: GbsDeepMaterializationProfile
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMTypedWrapperDelegatesToSessionManager [
	| wrapperClass |
	wrapperClass := GBSM
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.

	self assert: (GBSM typedWrapperClassForServerClassNamed: 'ByteArray') == wrapperClass
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMNamedObjectAtDelegatesToCurrentSession [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 1004 session: mockSession ].
	GBSM currentSession: mockSession.

	result := GBSM namedObjectAt: 'UserGlobals'.

	self assert: result oop equals: 1004
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMNamedObjectCacheInspectionDelegatesToCurrentSession [
	| mockSession report |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testGBSMNamedObjectAutoloadDelegatesToCurrentSession [
	| mockSession report |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testGBSMBridgeRootAndListInstancesDelegatesToCurrentSession [
	| mockSession rootResult listResult |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testGBSMClassHistoryAndMigrationDelegatesToCurrentSession [
	| mockSession history migrated |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testGBSMRemoteMirrorDelegatesToCurrentSession [
	| mockSession classMirror methodMirror |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testGBSMMethodObjectDelegatesToCurrentSession [
	| mockSession methodObject |
	mockSession := MockGbsSession new.
	GBSM currentSession: mockSession.

	methodObject := GBSM
		methodObjectForClass: 'Invoice'
		selector: #totalPrice.

	self assert: methodObject session == mockSession.
	self assert: methodObject selector equals: #totalPrice.
	self deny: methodObject classSide
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMMethodReferenceStringsDelegateToCurrentSession [
	| mockSession references |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'organizer referencesTo: #Invoice').
		^ #('Invoice>>totalPrice' 'Invoice class>>new') ].
	GBSM currentSession: mockSession.

	references := GBSM methodReferenceStringsToSymbol: 'Invoice'.

	self assert: references equals: #('Invoice>>totalPrice' 'Invoice class>>new')
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMSelectorReferenceQueriesDelegateToCurrentSession [
	| mockSession implementors senders |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testGBSMMigrationPreviewDelegatesToCurrentSession [
	| mockSession plan |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testConnectorPairsReflectAddAndRemoveConnector [
	| pairs |
	GbsSessionManager fastConnectorRegistry: Dictionary new.
	GbsSessionManager addConnectorClient: 'ByteString' server: 'String'.

	pairs := GbsSessionManager connectorPairs.
	self assert: (pairs anySatisfy: [ :pair |
		(pair at: 1 ifAbsent: [ '' ]) = 'ByteString'
			and: [ (pair at: 2 ifAbsent: [ '' ]) = 'String' ] ]).

	GbsSessionManager removeConnectorClient: 'ByteString' server: 'String'.
	pairs := GbsSessionManager connectorPairs.
	self deny: (pairs anySatisfy: [ :pair |
		(pair at: 1 ifAbsent: [ '' ]) = 'ByteString'
			and: [ (pair at: 2 ifAbsent: [ '' ]) = 'String' ] ])
]

{ #category : 'tests' }
GbsSessionManagerTest >> testRemoveInvalidConnectorsDropsUnknownClientMappings [
	| registry |
	registry := Dictionary new.
	registry
		at: 'UnknownClientClass' put: 'UnknownServerClass';
		at: 'UnknownServerClass' put: 'UnknownClientClass';
		at: 'ByteString' put: 'String';
		at: 'String' put: 'ByteString'.
	GbsSessionManager fastConnectorRegistry: registry.

	GbsSessionManager removeInvalidConnectors.

	registry := GbsSessionManager fastConnectorRegistry.
	self deny: (registry includesKey: 'UnknownClientClass').
	self deny: (registry includesKey: 'UnknownServerClass').
	self assert: (registry at: 'ByteString' ifAbsent: [ nil ]) equals: 'String'
]

{ #category : 'tests' }
GbsSessionManagerTest >> testClassSideFastConnectorRegistryRoundTrip [
	| registry |
	registry := Dictionary new
		at: 'ByteString' put: 'String';
		at: 'String' put: 'ByteString';
		yourself.

	GbsSessionManager fastConnectorRegistry: registry.

	self assert: (GbsSessionManager fastConnectorRegistry at: 'ByteString') equals: 'String'.
	self assert: (GbsSessionManager fastConnectorRegistry at: 'String') equals: 'ByteString'
]

{ #category : 'tests' }
GbsSessionManagerTest >> testClassSideInitializeFastConnectorsPopulatesRegistry [
	| registry |
	GbsSessionManager fastConnectorRegistry: Dictionary new.

	GbsSessionManager initializeFastConnectors.

	registry := GbsSessionManager fastConnectorRegistry.
	self assert: registry notNil.
	self assert: (registry isKindOf: Dictionary).
	self assert: (registry at: 'ByteString' ifAbsent: [ nil ]) equals: 'String'
]

{ #category : 'tests' }
GbsSessionManagerTest >> testFastConnectorRegistryAutoloadsWhenGlobalRegistryIsMissing [
	| registry |
	Smalltalk globals removeKey: #GbsFastConnectorRegistry ifAbsent: [ ].

	registry := GbsSessionManager fastConnectorRegistry.

	self assert: registry notNil.
	self assert: (registry at: 'ByteString' ifAbsent: [ nil ]) equals: 'String'
]

{ #category : 'tests' }
GbsSessionManagerTest >> testFastConnectorRegistryStaysEmptyWhenExplicitlyReset [
	GbsSessionManager fastConnectorRegistry: Dictionary new.

	self assert: GbsSessionManager fastConnectorRegistry isEmpty
]

{ #category : 'tests' }
GbsSessionManagerTest >> testConnectorConnectionStateDefaultsToConnected [
	Smalltalk globals at: #GbsConnectorConnectionRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: Dictionary new.
	self assert: (GbsSessionManager
		isConnectorClient: 'ByteArray'
		server: 'ByteArray'
		connectedInSession: 'DataCurator@gs64stone')
]

{ #category : 'tests' }
GbsSessionManagerTest >> testConnectorConnectionStateCanBeUpdatedPerSessionAndConnector [
	GbsSessionManager
		setConnectorClient: 'ByteArray'
		server: 'ByteArray'
		connected: false
		inSession: 'DataCurator@gs64stone'.

	self deny: (GbsSessionManager
		isConnectorClient: 'ByteArray'
		server: 'ByteArray'
		connectedInSession: 'DataCurator@gs64stone').
	self assert: (GbsSessionManager
		isConnectorClient: 'ByteArray'
		server: 'ByteArray'
		connectedInSession: 'OtherUser@gs64stone')
]

{ #category : 'tests' }
GbsSessionManagerTest >> testInvalidPostConnectActionsPerConnectorRoundTrip [
	| invalid |
	GbsSessionManager
		setInvalidPostConnectActions: #('updateGS' 'forwarder')
		forConnectorClient: 'ByteArray'
		server: 'ByteArray'.

	invalid := GbsSessionManager
		invalidPostConnectActionsForConnectorClient: 'ByteArray'
		server: 'ByteArray'.
	self assert: (invalid includes: 'updategs').
	self assert: (invalid includes: 'forwarder').
	self deny: (invalid includes: 'none')
]

{ #category : 'tests' }
GbsSessionManagerTest >> testConnectorObjectForClientServerReturnsWrapper [
	| connector |
	connector := GbsSessionManager connectorObjectForClient: 'ByteArray' server: 'ByteArray'.
	self assert: connector notNil.
	self assert: (connector isKindOf: GbsConnector).
	self assert: (connector respondsTo: #stDescription).
	self assert: (connector respondsTo: #gsDescription).
	self assert: connector stDescription equals: 'ByteArray'.
	self assert: connector gsDescription equals: 'ByteArray'
]

{ #category : 'tests' }
GbsSessionManagerTest >> testSetInvalidPostConnectActionsUpdatesWrapper [
	| wrapper |
	wrapper := GbsSessionManager connectorObjectForClient: 'ByteArray' server: 'ByteArray'.
	GbsSessionManager
		setInvalidPostConnectActions: #('updateGS' 'forwarder')
		forConnectorClient: 'ByteArray'
		server: 'ByteArray'.
	self assert: (wrapper invalidPostConnectActions includes: 'updategs').
	self assert: (wrapper invalidPostConnectActions includes: 'forwarder')
]

{ #category : 'tests' }
GbsSessionManagerTest >> testSetPostConnectActionPersistsAndSurvivesConnectorRebuild [
	| wrapper |
	GbsSessionManager
		setPostConnectAction: 'forwarder'
		forConnectorClient: 'ByteArray'
		server: 'ByteArray'.

	self
		assert: (GbsSessionManager
			postConnectActionForConnectorClient: 'ByteArray'
			server: 'ByteArray')
		equals: 'forwarder'.

	GbsSessionManager rebuildConnectorObjectRegistry.
	wrapper := GbsSessionManager connectorObjectForClient: 'ByteArray' server: 'ByteArray'.
	self assert: wrapper postConnectAction equals: 'forwarder'
]

{ #category : 'tests' }
GbsSessionManagerTest >> testSessionConnectorPairsAreScopedPerSession [
	| s1 s2 p1 p2 pairs1 pairs2 |
	p1 := GbsSessionParameters new.
	p1 username: 'DataCurator'.
	p1 gemStoneName: 'gs64stone'.
	s1 := MockGbsSession new.
	s1 parameters: p1.

	p2 := GbsSessionParameters new.
	p2 username: 'GcUser'.
	p2 gemStoneName: 'gs64stone'.
	s2 := MockGbsSession new.
	s2 parameters: p2.

	GbsSessionManager addConnectorClient: 'Character' server: 'Character' forSession: s1.
	GbsSessionManager addConnectorClient: 'Date' server: 'Date' forSession: s2.

	pairs1 := GbsSessionManager connectorPairsForSession: s1.
	pairs2 := GbsSessionManager connectorPairsForSession: s2.

	self assert: (pairs1 anySatisfy: [ :pair |
		{ (pair at: 1 ifAbsent: [ '' ]). (pair at: 2 ifAbsent: [ '' ]) } asSet = #('Character') asSet ]).
	self deny: (pairs1 anySatisfy: [ :pair |
		{ (pair at: 1 ifAbsent: [ '' ]). (pair at: 2 ifAbsent: [ '' ]) } asSet = #('Date') asSet ]).
	self assert: (pairs2 anySatisfy: [ :pair |
		{ (pair at: 1 ifAbsent: [ '' ]). (pair at: 2 ifAbsent: [ '' ]) } asSet = #('Date') asSet ])
]

{ #category : 'tests' }
GbsSessionManagerTest >> testSessionConnectorPairsKeepUnknownClassNames [
	| s1 p1 pairs |
	p1 := GbsSessionParameters new.
	p1 username: 'DataCurator'.
	p1 gemStoneName: 'gs64stone'.
	s1 := MockGbsSession new.
	s1 parameters: p1.

	GbsSessionManager addConnectorClient: 'ABC' server: 'XyzServer' forSession: s1.
	pairs := GbsSessionManager connectorPairsForSession: s1.

	self assert: (pairs anySatisfy: [ :pair |
		| names |
		names := { (pair at: 1 ifAbsent: [ '' ]). (pair at: 2 ifAbsent: [ '' ]) } asSet.
		names = #('ABC' 'XyzServer') asSet ])
]

{ #category : 'tests' }
GbsSessionManagerTest >> testConnectorClassForFastPairDefaultsToFastConnector [
	self
		assert: (GbsSessionManager connectorClassForClient: 'ByteArray' server: 'ByteArray')
		equals: GbsFastConnector
]

{ #category : 'tests' }
GbsSessionManagerTest >> testConnectorClassOverridePerPair [
	GbsSessionManager
		setConnectorClass: GbsNameConnector
		forClient: 'ByteArray'
		server: 'ByteArray'.

	self
		assert: (GbsSessionManager connectorClassForClient: 'ByteArray' server: 'ByteArray')
		equals: GbsNameConnector.

	GbsSessionManager clearConnectorClassForClient: 'ByteArray' server: 'ByteArray'.
	self
		assert: (GbsSessionManager connectorClassForClient: 'ByteArray' server: 'ByteArray')
		equals: GbsFastConnector
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGenerateTypedWrapperForConnectorPairCreatesSubclass [
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
GbsSessionManagerTest >> testTypedWrapperLookupAutoloadsKnownServerClassWithoutExplicitBootstrap [
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
GbsSessionManagerTest >> testTypedWrapperAutoloadPairsIncludeSessionScopedConnectorPairs [
	| params session pairs |
	params := GbsSessionParameters new.
	params username: 'DataCurator'.
	params gemStoneName: 'gs64stone'.
	session := MockGbsSession new.
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
GbsSessionManagerTest >> testExplicitTypedWrapperAutoloadRegistrationAppearsInEntriesAndReport [
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
GbsSessionManagerTest >> testExplicitTypedWrapperAutoloadRemovalIsScopedToExplicitRegistry [
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
GbsSessionManagerTest >> testTypedWrapperLookupAutoloadsSessionScopedConnectorPair [
	| params session wrapperClass |
	params := GbsSessionParameters new.
	params username: 'DataCurator'.
	params gemStoneName: 'gs64stone'.
	session := MockGbsSession new.
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
GbsSessionManagerTest >> testTypedWrapperRegistryEntriesAndReportTextExposeAutoloadState [
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
GbsSessionManagerTest >> testGeneratedTypedWrapperCompilesForwardingMethods [
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
GbsSessionManagerTest >> testGenerateTypedWrapperUsesRemoteMirrorSelectorsWhenCurrentSessionAvailable [
	| wrapperClass mockSession |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testGeneratedTypedWrapperMethodForwardsThroughSession [
	| wrapperClass proxy mockSession capturedSelector capturedArguments capturedOop result |
	wrapperClass := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'ByteArray'.
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testGenerateTypedWrappersForConnectorPairsUsesConnectorRegistry [
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
GbsSessionManagerTest >> testTypedWrapperLookupRefreshesExistingWrapperFromRemoteMetadata [
	| initialWrapper refreshedWrapper mockSession |
	initialWrapper := GbsSessionManager
		generateTypedWrapperForClient: 'ByteArray'
		server: 'RemoteLedger'.
	self assert: initialWrapper generatedForwardingSource equals: #client.

	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testInstanceConnectorDelegatesToClassSideForPairs [
	| manager |
	manager := GbsSessionManager new.
	GbsSessionManager fastConnectorRegistry: Dictionary new.
	manager addConnectorClient: 'ABC' server: 'XyzServer'.

	self assert: (manager connectorPairs anySatisfy: [ :pair |
		(pair at: 1 ifAbsent: [ '' ]) = 'ABC'
			and: [ (pair at: 2 ifAbsent: [ '' ]) = 'XyzServer' ] ])
]

{ #category : 'tests' }
GbsSessionManagerTest >> testInstanceConnectorDelegatesConnectionState [
	| manager |
	manager := GbsSessionManager new.
	manager
		setConnectorClient: 'ByteArray'
		server: 'ByteArray'
		connected: false
		inSession: 'DataCurator@gs64stone'.

	self deny: (manager
		isConnectorClient: 'ByteArray'
		server: 'ByteArray'
		connectedInSession: 'DataCurator@gs64stone')
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMNamespaceAndRubyRuntimeDelegatesToCurrentSession [
	| mockSession namespaces topLevel exactNamespace namedNamespace loadPath loadedFeatures |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(#(1 5001 'UserGlobals' nil 'SymbolDictionary' nil)) ].
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		(script includesSubstring: 'findTokens: ''::''')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		(script includesSubstring: '[:value | value] value:')
			ifTrue: [ ^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [ ^ #(7001 nil nil 'RubyNameSpace' 'Object') ].
		self fail ].
	GBSM currentSession: mockSession.

	namespaces := GBSM namespaceMirrors.
	topLevel := GBSM topLevelNamespaceMirror.
	exactNamespace := GBSM namespaceMirrorForObject: (GbsProxy oop: 7101 session: mockSession).
	namedNamespace := GBSM namespaceMirrorForFullName: 'Accounting::Invoice'.
	loadPath := GBSM rubyLoadPath.
	loadedFeatures := GBSM rubyLoadedFeatures.

	self assert: namespaces size equals: 1.
	self assert: namespaces first displayName equals: 'UserGlobals'.
	self assert: topLevel moduleName equals: 'Object'.
	self assert: exactNamespace displayName equals: 'Accounting'.
	self assert: namedNamespace displayName equals: 'Accounting::Invoice'.
	self assert: loadPath equals: #('lib').
	self assert: loadedFeatures equals: #('foo.rb')
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGBSMRuntimeAndObjectSpaceFacadeDelegatesToCurrentSession [
	| mockSession runtime diagnostics |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		self fail ].
	GBSM currentSession: mockSession.

	runtime := GBSM rubyRuntime.
	diagnostics := GBSM objectSpaceDiagnostics.

	self assert: runtime loadPath equals: #('lib').
	self assert: runtime loadedFeatures equals: #('foo.rb').
	self assert: runtime persistentLoadedFeatures equals: #('persisted.rb').
	self assert: runtime reportSections size equals: 4.
	self assert: diagnostics report class equals: GbsObjectSpaceDiagnosticsReport.
	self assert: (diagnostics reportText includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1')
]

{ #category : 'tests' }
GbsSessionManagerTest >> testGeneratedTypedWrapperStoresRemoteVersionMetadata [
	| wrapperClass mockSession |
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testTypedWrapperLookupRefreshesRemoteWrapperWhenVersionMetadataChanges [
	| mockSession wrapperClass version |
	version := 2.
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testTypedWrapperLifecycleEntriesReflectCurrentAndStaleStatus [
	| mockSession wrapperClass version currentRow staleRow |
	version := 2.
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testTypedWrapperLifecycleReportObjectExposesStructuredEntries [
	| mockSession wrapperClass version report entry |
	version := 2.
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testTypedProxyLifecycleHelpersExposeStructuredStatus [
	| mockSession wrapperClass version entry |
	version := 2.
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testInvalidateStaleTypedWrapperClassesClearsLocalVersionMetadataButKeepsLookupViable [
	| mockSession wrapperClass version |
	version := 2.
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testRefreshStaleTypedWrapperClassesForSessionRegeneratesWrapperMetadata [
	| mockSession wrapperClass version refreshed |
	version := 2.
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testRefreshAllTypedWrapperClassesForSessionRegeneratesAllRemoteWrappers [
	| mockSession firstWrapper secondWrapper version refreshed |
	version := 2.
	mockSession := MockGbsSession new.
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
GbsSessionManagerTest >> testResetAfterLogoutClearsSessionTypedWrapperAutoloadRegistrations [
	| mockSession sessionKey |
	mockSession := MockGbsSession new.
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
