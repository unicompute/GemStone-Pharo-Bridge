Class {
	#name : 'GbsSessionTest',
	#superclass : 'TestCase',
	#instVars : [
		'session',
		'previousObjectSpaceFinalizationRegistry'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsSessionTest >> setUp [
    super setUp.
	previousObjectSpaceFinalizationRegistry := Smalltalk globals
		at: #GbsObjectSpaceFinalizationRegistry
		ifAbsent: [ nil ].
	GbsObjectSpaceFacade resetFinalizationRegistry.
    session := GbsSession new.
]

{ #category : 'running' }
GbsSessionTest >> tearDown [
	GbsSession notificationActions removeAll.
	GbsSession sessionSignalActions removeAll.
	GbsSession signaledAbortActions removeAll.
	previousObjectSpaceFinalizationRegistry
		ifNil: [ Smalltalk globals removeKey: #GbsObjectSpaceFinalizationRegistry ifAbsent: [ ] ]
		ifNotNil: [ Smalltalk globals at: #GbsObjectSpaceFinalizationRegistry put: previousObjectSpaceFinalizationRegistry ].
	super tearDown
]

{ #category : 'running' }
GbsSessionTest >> materializationMockSession [
	| mockSession |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testAbortTransaction [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciAbort put: 1.
	
	self assert: mockSession abortTransaction equals: true.
]

{ #category : 'running' }
GbsSessionTest >> testCommitTransaction [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciCommit put: 1.
	
	self assert: mockSession commitTransaction equals: true.
]

{ #category : 'tests' }
GbsSessionTest >> testCommitTransactionFailure [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciCommit put: 0.
	
	self deny: mockSession commitTransaction.
]

{ #category : 'tests' }
GbsSessionTest >> testDefaultFetchProfileIsLegacy [
	self assert: session fetchProfile class equals: GbsLegacyMaterializationProfile
]

{ #category : 'running' }
GbsSessionTest >> testExecuteStringReturnsUnboxedObject [
	| mockSession result |
	mockSession := MockGbsSession new.
	
	"1. Force the mock into the instance variable so it isn't nil!"
	mockSession instVarNamed: 'serverInterface' put: mockSession.
	
	"2. Stub the FFI call to return 268 (which GbsSession checks for 'true')"
	mockSession stubs at: #apiGciExecute put: 268. 
	
	result := mockSession execute: '2 > 1'.
	
	self assert: result equals: true.
]

{ #category : 'tests' }
GbsSessionTest >> testExecuteSignalsErrorWhenNotLoggedIn [
	self
		should: [ session execute: '1 + 1' ]
		raise: GbsError
]

{ #category : 'tests' }
GbsSessionTest >> testExecuteStringSignalsError [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #execute put: [ :script |
		GbsError signal: 'MessageNotUnderstood: #foo' ].
		
	self 
		should: [ mockSession execute: 'Object foo' ]
		raise: GbsError
		withExceptionDo: [ :ex | self assert: ex messageText equals: 'MessageNotUnderstood: #foo' ]
]

{ #category : 'tests' }
GbsSessionTest >> testFetchClassesInDictionary [
	| mockSession classNames |
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: 'Object,String,Array'.
	
	classNames := mockSession fetchRemoteClassNamesIn: 'UserGlobals'.
	
	self assert: (classNames isKindOf: Collection).
	self assert: classNames first equals: 'Object'.
]

{ #category : 'tests' }
GbsSessionTest >> testFetchByReferenceUsesTypedWrapperForKnownCollectionClass [
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
GbsSessionTest >> testFetchByReferenceUsesTypedWrapperWithoutExplicitFastConnectorBootstrap [
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
GbsSessionTest >> testFetchDeepMaterializesNestedArraysRecursively [
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
GbsSessionTest >> testFetchLegacyMaterializesArraysRecursively [
	| mockSession result |
	mockSession := self materializationMockSession.

	result := mockSession fetchObject: 9000.

	self assert: result equals: #('vip' #('gold' 'paid'))
]

{ #category : 'tests' }
GbsSessionTest >> testFetchShallowLeavesNestedArrayAsProxy [
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
GbsSessionTest >> testLoginFailureSignalsError [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #gciInit put: true.
	mockSession stubs at: #gciLogin put: false.
	mockSession stubs at: #gciErr put: [ :errStruct | errStruct message: 'Login failed: Invalid password' ].
		
	self 
		should: [ mockSession loginStone: 'gs64stone' user: 'DataCurator' password: 'wrongpassword' ]
		raise: GbsError
		withExceptionDo: [ :ex | self assert: ex messageText equals: 'Login failed: Invalid password' ].
]

{ #category : 'tests' }
GbsSessionTest >> testWithMaterializationProfileRestoresPreviousProfile [
	| insideProfile |
	session withMaterializationProfile: GbsProxyOnlyMaterializationProfile new do: [
		insideProfile := session fetchProfile class ].

	self assert: insideProfile equals: GbsProxyOnlyMaterializationProfile.
	self assert: session fetchProfile class equals: GbsLegacyMaterializationProfile
]

{ #category : 'tests' }
GbsSessionTest >> testLoginSuccess [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #gciInit put: true.
	mockSession stubs at: #gciLogin put: true.

	mockSession loginStone: 'gs64stone' user: 'DataCurator' password: 'swordfish'.
	self assert: mockSession isLoggedIn.
]

{ #category : 'tests' }
GbsSessionTest >> testNamedForwarderAccessorsUseSessionForwarderFor [
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

	globals := mockSession globals.
	published := mockSession published.
	userClasses := mockSession userClasses.
	userGlobals := mockSession userGlobals.

	self assert: globals oop equals: 1001.
	self assert: published oop equals: 1002.
	self assert: userClasses oop equals: 1003.
	self assert: userGlobals oop equals: 1004
]

{ #category : 'tests' }
GbsSessionTest >> testNamedObjectAtIfAbsentEvaluatesFallback [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#MissingThing').
		nil ].

	result := mockSession namedObjectAt: #MissingThing ifAbsent: [ #fallback ].

	self assert: result equals: #fallback
]

{ #category : 'tests' }
GbsSessionTest >> testNamedObjectAtNormalizesStringNames [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 4444 session: mockSession ].

	result := mockSession namedObjectAt: 'UserGlobals'.

	self assert: result oop equals: 4444
]

{ #category : 'tests' }
GbsSessionTest >> testNamedObjectAtCachesResolvedNamedRoots [
	| mockSession first second calls |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testNamedObjectCacheInspectionAndClear [
	| mockSession report entries |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testNamedObjectAutoloadAliasResolvesRemoteNameAndCachesAlias [
	| mockSession first second calls |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testNamedObjectAutoloadInspectionAndClear [
	| mockSession report entries |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testSessionForwarderForUsesNamedObjectCache [
	| mockSession first second calls |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceFacadeRetainsSession [
	| mockSession facade |
	mockSession := MockGbsSession new.

	facade := mockSession objectSpace.

	self assert: facade class equals: GbsObjectSpaceFacade.
	self assert: facade session == mockSession
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceAllSubclassesOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'cls allSubclasses asArray').
		self assert: (script includesSubstring: '''Invoice''').
		#(SubclassOne SubclassTwo) ].

	result := mockSession objectSpace allSubclassesOfNamed: 'Invoice'.

	self assert: result equals: #(SubclassOne SubclassTwo)
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceInstancesInMemoryOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'SystemRepository _listInstancesInMemory: { cls }').
		self assert: (script includesSubstring: '''Invoice''').
		#(11 12) ].

	result := mockSession objectSpace instancesInMemoryOfNamed: 'Invoice'.

	self assert: result equals: #(11 12)
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceLoadedClassesIncludingModulesBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: script equals: 'SystemRepository _loadedClasses: true'.
		#('Invoice' 'Payments') ].

	result := mockSession objectSpace loadedClassesIncludingModules.

	self assert: result equals: #('Invoice' 'Payments')
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceSessionStateAtBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceSessionStateAtPutBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceReferencesToBuildsExpectedScript [
	| mockSession proxy result |
	mockSession := MockGbsSession new.
	proxy := GbsProxy oop: 4242 session: mockSession.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: script equals: '((Object _objectForOop: 4242)) findReferencesInMemory asArray'.
		^ #(9001 9002) ].

	result := mockSession objectSpace referencesTo: proxy.

	self assert: result equals: #(9001 9002)
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceReferencesToOopBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: script equals: '((Object _objectForOop: 4242)) findReferencesInMemory asArray'.
		^ #(9001) ].

	result := mockSession objectSpace referencesToOop: 4242.

	self assert: result equals: #(9001)
]

{ #category : 'tests' }
GbsSessionTest >> testObjectFinalizerExecutesAllActionsWithTarget [
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
GbsSessionTest >> testObjectSpaceDefineAndUndefineFinalizerUsesSharedRegistry [
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
GbsSessionTest >> testObjectSpaceEachObjectDoBuildsExpectedScript [
	| mockSession seen |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceObjectsInMemoryFromLimitBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceInstancesInMemoryOfNamedFromLimitBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceEachObjectDoBatchSizeUsesPagedFetches [
	| mockSession seen |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceObjectsInMemoryMatchingFiltersIncrementally [
	| mockSession result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryClassMirrorOfNamedBuildsExpectedScripts [
	| mockSession mirror |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryMethodMirrorForClassNamedBuildsExpectedScript [
	| mockSession instanceMirror classMirror |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryMethodObjectBindsAndInvokesThroughSession [
	| mockSession methodObject bound receiver capturedSelector capturedArguments capturedOop result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryMethodObjectEqualityHashAndBindingIdentity [
	| mockSession sameMethod sameMethodAgain boundSameReceiver boundSameReceiverAgain boundOtherReceiver receiverOne receiverTwo |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryClassMethodObjectUsesClassProxyWhenUnbound [
	| mockSession methodObject capturedSelector capturedArguments capturedOop result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryMethodObjectValueConvenienceAndPrintString [
	| mockSession methodObject bound receiver capturedSelector capturedArguments capturedOop result printed |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryMethodObjectParityDelegatesMirrorMetadata [
	| mockSession methodObject |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryUnboundMethodObjectDelegatesMirrorMetadataAndCanBind [
	| mockSession methodObject bound receiver |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryUnboundInstanceMethodObjectSignalsError [
	| mockSession methodObject |
	mockSession := MockGbsSession new.
	methodObject := mockSession
		methodObjectForClassNamed: 'Invoice'
		selector: #totalPrice.

	self
		should: [ methodObject call ]
		raise: Error
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryMethodReferenceStringsQueriesBuildExpectedScripts [
	| mockSession symbolResult objectResult proxy |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryMethodSelectorReferenceQueriesBuildExpectedScripts [
	| mockSession implementors senders |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryHierarchyMethodReferenceQueriesBuildExpectedScripts [
	| mockSession implementors senders |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceLoadedClassesIncludingModulesFalseBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: script equals: 'SystemRepository _loadedClasses: false'.
		#('Invoice') ].

	result := mockSession objectSpace loadedClassesIncludingModules: false.

	self assert: result equals: #('Invoice')
]

{ #category : 'tests' }
GbsSessionTest >> testObjectForOopUsesReferenceSemantics [
	| proxy |
	proxy := session objectForOop: 1001.

	self assert: proxy class equals: GbsProxy.
	self assert: proxy oop equals: 1001.
	self assert: proxy session == session
]

{ #category : 'tests' }
GbsSessionTest >> testProxyForOopServerClassNameUsesTypedWrapperWhenConnectorExists [
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
GbsSessionTest >> testProxyIdentityMapReturnsSameProxyForRepeatedResultFor [
	| first second |
	first := session resultFor: 1001.
	second := session resultFor: 1001.

	self assert: first == second
]

{ #category : 'tests' }
GbsSessionTest >> testProxyIdentityMapReusesTypedWrapperForRepeatedTypedLookup [
	| first second |
	GbsSessionManager initializeFastConnectors.
	first := session proxyForOop: 1001 serverClassName: 'Dictionary'.
	second := session proxyForOop: 1001 serverClassName: 'Dictionary'.

	self assert: first == second.
	self assert: (first isKindOf: GbsTypedProxy)
]

{ #category : 'tests' }
GbsSessionTest >> testProxyIdentityMapKeepsFirstProxyWhenPlainLookupPrecedesTypedLookup [
	| plain typed |
	GbsSessionManager initializeFastConnectors.
	plain := session resultFor: 1001.
	typed := session proxyForOop: 1001 serverClassName: 'Dictionary'.

	self assert: plain == typed.
	self assert: typed class equals: GbsProxy
]

{ #category : 'tests' }
GbsSessionTest >> testProxyIdentityMapKeepsTypedWrapperWhenTypedLookupPrecedesPlainLookup [
	| typed plain |
	GbsSessionManager initializeFastConnectors.
	typed := session proxyForOop: 1001 serverClassName: 'Dictionary'.
	plain := session resultFor: 1001.

	self assert: typed == plain.
	self assert: (plain isKindOf: GbsTypedProxy)
]

{ #category : 'tests' }
GbsSessionTest >> testFetchByReferenceFallsBackToPlainProxyForUnknownClass [
	| mockSession result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testClassHistoryFacadeBuildsExpectedVersionEntries [
	| mockSession holders |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testClassHistoryFacadeCanMigrateWhenMultipleVersionsExist [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'cls classHistory').
		#(
			#(1000 'Invoice' 1 2)
			#(1008 'Invoice' 2 2)) ].

	result := (mockSession classHistoryOf: 'Invoice') canMigrateInstances.

	self assert: result
]

{ #category : 'tests' }
GbsSessionTest >> testClassHistoryFacadePreviewMigrationToBuildsExpectedPlan [
	| mockSession plan entry |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testClassHistoryFacadePreviewOldVersionsToLatestBuildsExpectedPlan [
	| mockSession plan |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testClassHistoryFacadeExecutePreviewPlanDelegatesToMigrationOperation [
	| mockSession plan result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testClassHistoryFacadeRemoveOldVersionBindingsFromLocalDictionary [
	| mockSession history dictionary removed |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testMigrationPlanImpactSummaryStringIncludesScopeAndEntries [
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
GbsSessionTest >> testClassVersionBrowserPreviewMigrationToLatestBuildsExpectedPlan [
	| mockSession browser plan |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testClassVersionBrowserExecutePreviewPlanAndRemoveOldBindings [
	| mockSession browser plan result dictionary removed |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryAllInstancesOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'cls allInstances').
		self assert: (script includesSubstring: 'objectNamed: name asSymbol').
		self assert: (script includesSubstring: '''Invoice''').
		#(1 2 3) ].

	result := mockSession repository allInstancesOfNamed: 'Invoice'.

	self assert: result equals: #(1 2 3)
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryListInstancesOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'SystemRepository listInstances: { cls }').
		self assert: (script includesSubstring: '''Invoice''').
		#(3 4 5) ].

	result := mockSession repository listInstancesOfNamed: 'Invoice'.

	self assert: result equals: #(3 4 5)
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryListInstancesOfNamedWithLimitBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'limit: 25').
		#(7 8) ].

	result := mockSession repository listInstancesOfNamed: 'Invoice' limit: 25.

	self assert: result equals: #(7 8)
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryListInstancesRefusesAbortWhenSessionIsDirty [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit')
			ifTrue: [ ^ true ].
		self fail ].

	self
		should: [ mockSession repository listInstancesOfNamed: 'Invoice' ]
		raise: GbsError
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryListInstancesAllowsAbortWhenSessionIsDirty [
	| mockSession aborted result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryMigrateInstancesFromToBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryPreviewMigrationFromToBuildsExpectedPlan [
	| mockSession plan entry |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryPreviewMigrationWithSubclassesBuildsExpectedPlan [
	| mockSession plan |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryMigrateInstancesWithSubclassesBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryAllInstancesOopOfNamedUsesRawServerOop [
	| mockSession oop |
	mockSession := MockGbsSession new.
	mockSession stubs at: #apiGciExecuteStrContextEnv put: [ :script :context :env |
		self assert: context equals: 20.
		self assert: env equals: 0.
		self assert: (script includesSubstring: 'cls allInstances').
		9876 ].

	oop := mockSession repository allInstancesOopOfNamed: 'Invoice'.

	self assert: oop equals: 9876
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryClassHistoryOfRetainsSessionAndReference [
	| mockSession history |
	mockSession := MockGbsSession new.

	history := mockSession repository classHistoryOf: 'Invoice'.

	self assert: history class equals: GbsClassHistoryFacade.
	self assert: history session == mockSession.
	self assert: history classReference equals: 'Invoice'
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryFacadeRetainsSession [
	| mockSession facade |
	mockSession := MockGbsSession new.

	facade := mockSession repository.

	self assert: facade class equals: GbsRepositoryFacade.
	self assert: facade session == mockSession
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryRootReturnsRootFacade [
	| mockSession root |
	mockSession := MockGbsSession new.

	root := mockSession repository root.

	self assert: root class equals: GbsRepositoryRootFacade.
	self assert: root session == mockSession.
	self assert: root rootKey equals: #GbsBridgeRoot.
	self assert: root path isEmpty
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryRootFacadeIsMemoizedUntilInvalidation [
	| mockSession first second third |
	mockSession := MockGbsSession new.

	first := mockSession repository root.
	second := mockSession repository root.
	mockSession invalidateRepositoryRoots.
	third := mockSession repository root.

	self assert: first == second.
	self deny: third == first
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryLoadedClassesUsesVisibleBehaviorScript [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'value isBehavior').
		#('Account' 'Invoice') ].

	result := mockSession repository loadedClasses.

	self assert: result equals: #('Account' 'Invoice')
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryRootAtIfAbsentEvaluatesFallback [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#GbsBridgeRoot').
		self assert: (script includesSubstring: 'at: key ifAbsent: [ nil ]').
		nil ].

	result := mockSession repository rootAt: #missing ifAbsent: [ #fallback ].

	self assert: result equals: #fallback
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryRootAtPutBuildsExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryRootProxyUsesRootScriptAndReturnsProxy [
	| mockSession root result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: '#GbsBridgeRoot').
		2001 ].
	root := mockSession repository root.

	result := root proxy.

	self assert: result oop equals: 2001.
	self assert: result session == mockSession
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryRootProxyRefreshesAfterInvalidation [
	| mockSession root first second oops |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryRootKeysBuildExpectedScript [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#GbsBridgeRoot').
		self assert: (script includesSubstring: 'container keys asArray').
		#(#tickets #users) ].

	result := mockSession repository root keys.

	self assert: result equals: #(#tickets #users)
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryRootEnsureNamespaceAtReturnsNestedFacade [
	| mockSession namespace |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryRootNamespaceFacadeUsesSessionCache [
	| mockSession first second |
	mockSession := MockGbsSession new.

	first := (mockSession repository root) namespaceFacadeAt: #tickets.
	second := (mockSession repository root) namespaceFacadeAt: #tickets.

	self assert: first == second.
	self assert: first path equals: #(#tickets)
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryRootNamespaceAtIfAbsentEvaluatesFallback [
	| mockSession result |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRepositoryRootWithReadLockDoLocksAndUnlocksContainer [
	| mockSession root scripts result seenFacade seenProxy |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testCommitTransactionInvalidatesRepositoryRoots [
	| mockSession first second |
	mockSession := MockGbsSession new.
	first := mockSession repository root.

	self assert: mockSession commitTransaction.
	second := mockSession repository root.

	self deny: second == first.
	self assert: mockSession repositoryRootLifecycleVersion equals: 1
]

{ #category : 'tests' }
GbsSessionTest >> testAbortTransactionInvalidatesRepositoryRoots [
	| mockSession first second |
	mockSession := MockGbsSession new.
	first := mockSession repository root.

	self assert: mockSession abortTransaction.
	second := mockSession repository root.

	self deny: second == first.
	self assert: mockSession repositoryRootLifecycleVersion equals: 1
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptBuildsDictionaryExpression [
	| script |
	script := session
		marshalArgumentToScript: (Dictionary new
			at: 'name' put: 'Tariq';
			at: 'amount' put: 100;
			yourself).

	self assert: (script includesSubstring: 'Dictionary new').
	self assert: (script includesSubstring: 'at: ''name'' put: ''Tariq''').
	self assert: (script includesSubstring: 'at: ''amount'' put: 100')
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptBuildsIdentityDictionaryExpression [
	| script |
	script := session
		marshalArgumentToScript: (IdentityDictionary new
			at: #ticket put: 'vip';
			yourself).

	self assert: (script includesSubstring: 'IdentityDictionary new').
	self assert: (script includesSubstring: 'at: #ticket put: ''vip''')
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptBuildsNestedCollectionExpression [
	| object script |
	object := OrderedCollection new
		add: (Association key: #name value: 'Tariq');
		add: #(1 2 3);
		yourself.
	script := session marshalArgumentToScript: object.

	self assert: (script includesSubstring: 'OrderedCollection new').
	self assert: (script includesSubstring: 'Association key: #name value: ''Tariq''').
	self assert: (script includesSubstring: 'Array new: 3')
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptBuildsRepeatedBagExpression [
	| bag script |
	bag := Bag new.
	bag add: 'vip'.
	bag add: 'vip'.
	script := session marshalArgumentToScript: bag.

	self assert: (script includesSubstring: 'Bag new').
	self assert: (script includesSubstring: 'add: ''vip''; add: ''vip''')
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptRejectsCyclicCollections [
	| object |
	object := OrderedCollection new.
	object add: object.

	self
		should: [ session marshalArgumentToScript: object ]
		raise: Error
]

{ #category : 'tests' }
GbsSessionTest >> testMarshalArgumentToScriptBuildsSortedCollectionExpression [
	| script |
	script := session
		marshalArgumentToScript: (SortedCollection new
			add: 3;
			add: 1;
			add: 2;
			yourself).

	self assert: (script includesSubstring: 'SortedCollection new').
	self assert: (script includesSubstring: 'add: 1').
	self assert: (script includesSubstring: 'add: 2').
	self assert: (script includesSubstring: 'add: 3')
]

{ #category : 'tests' }
GbsSessionTest >> testExecuteScriptAndReturnOopUsesServerInterface [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #apiGciExecuteStrContextEnv put: [ :script :context :env |
		self assert: script equals: '42'.
		self assert: context equals: 20.
		self assert: env equals: 0.
		123456 ].

	result := mockSession executeScriptAndReturnOop: '42'.

	self assert: result equals: 123456
]

{ #category : 'tests' }
GbsSessionTest >> testLogoutSuccess [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciLogout put: 1.
	
	mockSession logout.
	self deny: mockSession isLoggedIn.
]

{ #category : 'tests' }
GbsSessionTest >> testLogoutClearsProxyIdentityMap [
	| mockSession proxy |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciLogout put: nil.
	proxy := mockSession resultFor: 1001.

	self assert: (mockSession cachedProxyForOop: 1001) == proxy.

	mockSession logout.

	self assert: (mockSession cachedProxyForOop: 1001) isNil
]

{ #category : 'tests' }
GbsSessionTest >> testLogoutClearsAttachedParameterState [
	| mockSession params |
	mockSession := MockGbsSession new.
	mockSession
		instVarNamed: 'isLoggedIn' put: true;
		sessionId: 77;
		sessionOop: 77.
	mockSession stubs at: #gciLogout put: nil.
	params := GbsSessionParameters new.
	params sessionId: 77.
	params class currentSession: mockSession.
	params class registerSession: params.
	mockSession parameters: params.

	mockSession logout.

	self deny: mockSession isLoggedIn.
	self assert: mockSession sessionId isNil.
	self assert: mockSession sessionOop isNil.
	self assert: params sessionId isNil.
	self assert: params class currentSession isNil.
	self deny: (params class allSessions includes: params)
]

{ #category : 'tests' }
GbsSessionTest >> testLogoutTreatsNilFfiReturnAsSuccess [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciLogout put: nil.

	mockSession logout.

	self deny: mockSession isLoggedIn
]

{ #category : 'tests' }
GbsSessionTest >> testPollingLifecycle [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciPollForSignal put: 0.
	
	mockSession startPolling.
	self deny: mockSession isPolling.
	
	mockSession stopPolling.
	self deny: mockSession isPolling.
]

{ #category : 'running' }
GbsSessionTest >> testResultForComplexObjectReturnsProxy [

  | result |
  "1000 is not a special tag, should result in a GbsProxy"
  result := session resultFor: 1000.
  self assert: ( result isKindOf: GbsProxy ).
  self assert: result oop equals: 1000.
  self assert: result session equals: session
]

{ #category : 'running' }
GbsSessionTest >> testResultForPrimitives [
  "Verify Tag mapping per GS64 3.7 Programming Guide"

  self assert: ( session resultFor: 20 ) isNil.
  self assert: ( session resultFor: 28 ).
  self deny: ( session resultFor: 12 ).
  self assert: ( session resultFor: 82 ) equals: 10.
  "$A (65): (65 << 3) + 6 = 526"
	self assert: ( session resultFor: 526 ) equals: $A
]

{ #category : 'tests' }
GbsSessionTest >> testSessionForwarderForSignalsWhenMissing [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObjectResult put: nil.

	self
		should: [ mockSession sessionForwarderFor: #MissingThing ]
		raise: Error
]

{ #category : 'tests' }
GbsSessionTest >> testSessionForwarderForUsesResolveSymbolAndAnswersProxy [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#UserGlobals')
			ifTrue: [ GbsProxy oop: 4242 session: mockSession ]
			ifFalse: [ nil ] ].

	result := mockSession sessionForwarderFor: #UserGlobals.

	self assert: (result isKindOf: GbsProxy).
	self assert: result oop equals: 4242.
	self assert: result session equals: mockSession
]

{ #category : 'tests' }
GbsSessionTest >> testForwardRemoteMessageMaterializesLocalDictionaryArguments [
	| mockSession proxy capturedScript result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: [ :script |
		capturedScript := script.
		true ].
	proxy := GbsProxy oop: 4242 session: mockSession.

	result := proxy
		at: #MyTestDict
		put: (Dictionary new
			at: 'name' put: 'Tariq';
			at: 'amount' put: 100;
			yourself).

	self assert: result.
	self assert: (capturedScript includesSubstring: 'perform: #at:put:').
	self assert: (capturedScript includesSubstring: 'Dictionary new').
	self assert: (capturedScript includesSubstring: 'at: ''name'' put: ''Tariq''').
	self assert: (capturedScript includesSubstring: 'at: ''amount'' put: 100')
]

{ #category : 'running' }
GbsSessionTest >> testSignalTriggersNotification [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #gciPollForSignal put: 4.
	
	self should: [ mockSession checkSignals ] raise: TransactionBacklog
]

{ #category : 'tests' }
GbsSessionTest >> testUncachedForwarderAtIfAbsentReturnsFallbackWhenMissing [
	| mockSession result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObjectResult put: nil.

	result := mockSession
		uncachedForwarderAt: #MissingThing
		ifAbsent: [ #fallback ].

	self assert: result equals: #fallback
]

{ #category : 'tests' }
GbsSessionTest >> testBeginTransactionAndTransactionModeUseRemoteSystemCalls [
	| mockSession beginScript modeScript inTransactionScript setModeScript |
	mockSession := MockGbsSession new.

	beginScript := mockSession systemCallScriptForSelector: #beginTransaction arguments: #().
	modeScript := mockSession systemCallScriptForSelector: #transactionMode arguments: #().
	inTransactionScript := mockSession systemCallScriptForSelector: #inTransaction arguments: #().
	setModeScript := mockSession systemCallScriptForSelector: #transactionMode: arguments: { #manualBegin }.

	mockSession stubs at: #executeResult put: true.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = modeScript ifTrue: [ ^ #autoBegin ].
		script = inTransactionScript ifTrue: [ ^ false ].
		nil ].

	self assert: mockSession beginTransaction == mockSession.
	self assert: mockSession transactionMode equals: #autoBegin.
	self deny: mockSession inTransaction.
	self assert: (mockSession transactionMode: #manualBegin) == mockSession.
]

{ #category : 'tests' }
GbsSessionTest >> testHandleInterSessionSignalMessageRunsInstalledActionForFirstAndPolledSignals [
	| mockSession firstSignal createdScript pollScript handled queuedSignals |
	mockSession := MockGbsSession new.
	firstSignal := Object new.
	handled := OrderedCollection new.
	queuedSignals := OrderedCollection with: #second with: nil.

	createdScript := mockSession legacyInterSessionSignalScriptForExceptionOop: 77.
	pollScript := mockSession legacyInterSessionSignalPollScript.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = createdScript ifTrue: [ ^ firstSignal ].
		script = pollScript ifTrue: [ ^ queuedSignals removeFirst ].
		nil ].

	mockSession sessionSignalAction: [ :signal | handled add: signal ].
	mockSession handleInterSessionSignalMessage: 'signal' exceptionOop: 77.

	self assert: handled asArray equals: { firstSignal. #second }
]

{ #category : 'tests' }
GbsSessionTest >> testHandleObjectsCommittedNotificationMessageRunsInstalledActionWithIdentitySet [
	| mockSession changedObjects handled signaledObjectsScript |
	mockSession := MockGbsSession new.
	changedObjects := { Object new. Object new }.
	signaledObjectsScript := mockSession systemCallScriptForSelector: #signaledObjects arguments: #().
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = signaledObjectsScript ifTrue: [ ^ changedObjects ].
		nil ].

	mockSession notificationAction: [ :objects | handled := objects ].
	mockSession handleObjectsCommittedNotificationMessage: 'changed'.

	self assert: handled class equals: IdentitySet.
	self assert: handled size equals: 2.
	self assert: (handled includes: changedObjects first).
	self assert: (handled includes: changedObjects second)
]

{ #category : 'tests' }
GbsSessionTest >> testLockQueriesAndSignalSendUseCompatibilityScripts [
	| mockSession systemLocksScript |
	mockSession := MockGbsSession new.
	systemLocksScript := 'System systemLocks associations asArray'.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = (mockSession systemCallScriptForSelector: #lockOwners: arguments: { #seat42 }) ifTrue: [ ^ #(11 12) ].
		script = (mockSession systemCallScriptForSelector: #lockKind: arguments: { #seat42 }) ifTrue: [ ^ #write ].
		script = (mockSession systemCallScriptForSelector: #sessionLocks arguments: #()) ifTrue: [ ^ { #(r1 r2). #(w1). #() } ].
		script = systemLocksScript ifTrue: [ ^ { (Association key: 11 value: { #(read1). #(write1). #() }) } ].
		script = (mockSession systemCallScriptForSelector: #_sendSignal:toSess:withMessage: arguments: { 15. -42. 'hello' }) ifTrue: [ ^ true ].
		nil ].

	self assert: (mockSession lockOwners: #seat42) equals: #(11 12).
	self assert: (mockSession lockKind: #seat42) equals: #write.
	self assert: (mockSession sessionLocks) equals: { #(r1 r2). #(w1). #() }.
	self assert: (mockSession systemLocks at: 11) equals: { #(read1). #(write1). #() }.
	self assert: (mockSession sendSignal: 15 to: -42 withMessage: 'hello')
]

{ #category : 'tests' }
GbsSessionTest >> testReadAndWriteLockUseCompatibilityScripts [
	| mockSession scripts |
	mockSession := MockGbsSession new.
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

{ #category : 'tests' }
GbsSessionTest >> testNotificationActionEnablesAndDisablesRemoteSignalWhenLoggedIn [
	| mockSession block scripts |
	mockSession := MockGbsSession new.
	block := [ :objects | objects ].
	scripts := OrderedCollection new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script | scripts add: script. true ].

	mockSession notificationAction: block.
	self assert: mockSession notificationAction == block.
	mockSession notificationAction: nil.

	self assert: mockSession notificationAction isNil.
	self
		assert: scripts asArray
		equals: {
			mockSession systemCallScriptForSelector: #enableSignaledObjectsError arguments: #().
			mockSession systemCallScriptForSelector: #disableSignaledObjectsError arguments: #() }
]

{ #category : 'tests' }
GbsSessionTest >> testHandleSignaledAbortErrorMessageRunsInstalledAction [
	| mockSession handled |
	mockSession := MockGbsSession new.
	handled := false.

	mockSession signaledAbortAction: [ handled := true ].
	mockSession handleSignaledAbortErrorMessage: 'sigAbort'.

	self assert: handled
]

{ #category : 'tests' }
GbsSessionTest >> testHandleSignaledAbortErrorMessageSignalsWhenNoActionInstalled [
	| mockSession |
	mockSession := MockGbsSession new.

	self
		should: [ mockSession handleSignaledAbortErrorMessage: 'sigAbort' ]
		raise: GbsRtErrSignalAbort
]

{ #category : 'tests' }
GbsSessionTest >> testSessionSignalActionEnablesAndDisablesRemoteSignalWhenLoggedIn [
	| mockSession block scripts |
	mockSession := MockGbsSession new.
	block := [ :signal | signal ].
	scripts := OrderedCollection new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script | scripts add: script. true ].

	mockSession sessionSignalAction: block.
	self assert: mockSession sessionSignalAction == block.
	mockSession sessionSignalAction: nil.

	self assert: mockSession sessionSignalAction isNil.
	self
		assert: scripts asArray
		equals: {
			mockSession systemCallScriptForSelector: #enableSignaledGemStoneSessionError arguments: #().
			mockSession systemCallScriptForSelector: #disableSignaledGemStoneSessionError arguments: #() }
]

{ #category : 'tests' }
GbsSessionTest >> testSignaledAbortActionStoresAndClearsBlock [
	| mockSession block |
	mockSession := MockGbsSession new.
	block := [ #aborted ].

	mockSession signaledAbortAction: block.
	self assert: mockSession signaledAbortAction == block.

	mockSession signaledAbortAction: nil.
	self assert: mockSession signaledAbortAction isNil
]

{ #category : 'tests' }
GbsSessionTest >> testSignaledAbortActionEnablesAndDisablesRemoteSignalWhenLoggedIn [
	| mockSession block scripts |
	mockSession := MockGbsSession new.
	block := [ #aborted ].
	scripts := OrderedCollection new.
	mockSession stubs at: #evaluate put: [ :script | scripts add: script. true ].

	mockSession signaledAbortAction: block.
	mockSession signaledAbortAction: nil.

	self assert: scripts asArray equals: #('System enableSignaledAbortError' 'System disableSignaledAbortError')
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryNamespaceMirrorsBuildExpectedMetadataAndConstants [
	| mockSession mirrors first topLevel constants autoloads |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(
				#(1 5001 'UserGlobals' nil 'SymbolDictionary' nil)
				#(2 5002 'Globals' nil 'SymbolDictionary' nil)) ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [
				(script includesSubstring: 'rubyAutoloadFileFor:')
					ifTrue: [ ^ 'lib/lazy_thing.rb' ].
				(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
					ifTrue: [ ^ #(
						#('LazyThing' 'lib/lazy_thing.rb' nil 9101)) ].
				(script includesSubstring: '_rubyConstants asArray')
					ifTrue: [ ^ #(
						#('Invoice' 1001 'Class' nil 'Invoice' 'Accounting::Invoice')
						#('LazyThing' nil nil 'lib/lazy_thing.rb' nil nil)) ].
				^ #(7001 nil nil 'RubyNameSpace' 'Object') ].
		self fail ].

	mirrors := mockSession namespaceMirrors.
	first := mirrors first.
	topLevel := mockSession topLevelNamespaceMirror.
	constants := topLevel constantMirrors.
	autoloads := topLevel autoloadMirrors.

	self assert: mirrors size equals: 2.
	self assert: first class equals: GbsRemoteNamespaceMirror.
	self assert: first index equals: 1.
	self assert: first name equals: 'UserGlobals'.
	self assert: first displayName equals: 'UserGlobals'.
	self assert: first className equals: 'SymbolDictionary'.
	self assert: first oop equals: 5001.
	self assert: first proxy oop equals: 5001.
	self assert: topLevel exists.
	self assert: topLevel moduleName equals: 'Object'.
	self assert: topLevel displayName equals: 'Object'.
	self assert: constants size equals: 2.
	self assert: autoloads size equals: 1.
	self assert: constants first name equals: 'Invoice'.
	self assert: constants first valueName equals: 'Invoice'.
	self assert: constants first valueFullName equals: 'Accounting::Invoice'.
	self assert: constants first browsableName equals: 'Accounting::Invoice'.
	self deny: constants first isAutoload.
	self assert: autoloads first class equals: GbsRemoteAutoloadMirror.
	self assert: autoloads first name equals: 'LazyThing'.
	self assert: autoloads first autoloadFile equals: 'lib/lazy_thing.rb'.
	self assert: autoloads first rawState isNil.
	self assert: autoloads first oop equals: 9101.
	self assert: autoloads first proxy oop equals: 9101.
	self assert: autoloads first stateLabel equals: 'Loading'.
	self assert: constants second isAutoload.
	self assert: constants second autoloadFile equals: 'lib/lazy_thing.rb'.
	self assert: constants second browsableName equals: 'LazyThing'.
	self assert: (topLevel autoloadFileFor: #LazyThing) equals: 'lib/lazy_thing.rb'
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryNamespaceMirrorRegisterAutoloadBuildsExpectedScript [
	| mockSession namespace result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'rubyAutoload: name asSymbol file: file')
			ifTrue: [
				self assert: (script includesSubstring: 'Object nameSpace: 1').
				self assert: (script includesSubstring: '''LazyThing''').
				self assert: (script includesSubstring: '''lib/lazy_thing.rb''').
				^ 'lib/lazy_thing.rb' ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [ ^ #(7001 nil nil 'RubyNameSpace' 'Object') ].
		self fail ].

	namespace := mockSession topLevelNamespaceMirror.
	result := namespace
		registerAutoload: #LazyThing
		file: 'lib/lazy_thing.rb'.

	self assert: result equals: 'lib/lazy_thing.rb'
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryNamespaceMirrorForObjectBuildsExactObjectExpression [
	| mockSession proxy namespace |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '[:value | value] value:').
		self assert: (script includesSubstring: '_objectForOop: 7101').
		self deny: (script includesSubstring: 'nameSpace: 1').
		^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
	proxy := GbsProxy oop: 7101 session: mockSession.

	namespace := mockSession namespaceMirrorForObject: proxy.

	self assert: namespace oop equals: 8001.
	self assert: namespace displayName equals: 'Accounting'
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryNamespaceMirrorParentNamespaceUsesContainingNamespaceExpression [
	| mockSession namespace parent |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '[:value | value] value:')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		(script includesSubstring: 'cls ifNil: [ nil ] ifNotNil: [ cls nameSpace: 1 ]')
			ifTrue: [
				self assert: (script includesSubstring: '_objectForOop: 8101').
				^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
		self fail ].
	namespace := mockSession namespaceMirrorForObject: (GbsProxy oop: 8101 session: mockSession).

	parent := namespace parentNamespaceMirror.

	self assert: parent notNil.
	self assert: parent oop equals: 8001.
	self assert: parent displayName equals: 'Accounting'
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryNamespaceMirrorForFullNameBuildsPathLookupExpression [
	| mockSession namespace |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'findTokens: ''::''').
		self assert: (script includesSubstring: 'current := Object nameSpace: 1').
		self assert: (script includesSubstring: '''Accounting::Invoice''').
		^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].

	namespace := mockSession namespaceMirrorForFullName: 'Accounting::Invoice'.

	self assert: namespace oop equals: 8101.
	self assert: namespace displayName equals: 'Accounting::Invoice'
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryNamespaceMirrorRemoveAutoloadBuildsExpectedScript [
	| mockSession namespace result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: name asSymbol env: 1')
			ifTrue: [
				self assert: (script includesSubstring: 'removeConst: name asSymbol env: 1').
				self assert: (script includesSubstring: 'Object nameSpace: 1').
				self assert: (script includesSubstring: '''LazyThing''').
				^ true ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [ ^ #(7001 nil nil 'RubyNameSpace' 'Object') ].
		self fail ].

	namespace := mockSession topLevelNamespaceMirror.
	result := namespace removeAutoload: #LazyThing.

	self assert: result equals: true
]

{ #category : 'tests' }
GbsSessionTest >> testRubyLoadRequireAndLoadedFeaturesBuildExpectedScripts [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib' 'app/models') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		script = 'RubyContext clear_persistent_LOADED_FEATURES' ifTrue: [ ^ true ].
		(script includesSubstring: 'RubyContext default requireFileNamed: ''foo'' env: 1')
			ifTrue: [ ^ true ].
		(script includesSubstring: 'RubyContext default loadFileNamed: ''bar.rb'' env: 1')
			ifTrue: [ ^ 'loaded' ].
		self fail ].

	self assert: mockSession rubyLoadPath equals: #('lib' 'app/models').
	self assert: mockSession rubyLoadedFeatures equals: #('foo.rb').
	self assert: mockSession rubyPersistentLoadedFeatures equals: #('persisted.rb').
	self assert: (mockSession rubyRequireFileNamed: 'foo') equals: true.
	self assert: (mockSession rubyLoadFileNamed: 'bar.rb') equals: 'loaded'.
	self assert: mockSession clearPersistentRubyLoadedFeatures equals: true
]

{ #category : 'tests' }
GbsSessionTest >> testRubyRuntimeFacadeReportIncludesAutoloadRegistrationsAndSessionStateSummary [
	| mockSession namespace report |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib' 'app/models') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [ ^ #(#('LazyThing' 'lib/lazy_thing.rb' false 9101)) ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 nil nil 'RubyNameSpace' 'Object').

	report := String streamContents: [ :stream |
		mockSession rubyRuntime
			appendRuntimeReportOn: stream
			namespace: namespace
			selectedConstant: nil
			selectedAutoload: nil ].

	self assert: (report includesSubstring: 'Autoload Registrations').
	self assert: (report includesSubstring: 'LazyThing -> lib/lazy_thing.rb [Pending]').
	self assert: (report includesSubstring: '$LOAD_PATH').
	self assert: (report includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1')
]

{ #category : 'tests' }
GbsSessionTest >> testRubyRuntimeFacadeReportObjectExposesStructuredEntries [
	| mockSession namespace report |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib' 'app/models') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [ ^ #(#('LazyThing' 'lib/lazy_thing.rb' false 9101)) ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 nil nil 'RubyNameSpace' 'Object').

	report := mockSession rubyRuntime
		reportForNamespace: namespace
		selectedConstant: nil
		selectedAutoload: nil.

	self assert: report loadPathEntries size equals: 2.
	self assert: report loadedFeatureEntries size equals: 1.
	self assert: report persistentLoadedFeatureEntries size equals: 1.
	self assert: report autoloadRegistrations size equals: 1.
	self assert: report sessionStateSlots size equals: 1.
	self assert: report loadPathEntries first class equals: GbsRubyLoadPathEntry.
	self assert: report loadedFeatureEntries first class equals: GbsRubyLoadedFeatureEntry.
	self assert: report persistentLoadedFeatureEntries first isPersistent.
	self assert: report sessionStateSlots first class equals: GbsFinalizerRegistrySessionStateSlot.
	self assert: report sections size equals: 5.
	self assert: report sections first title equals: 'Autoload Registrations'.
	self assert: (report text includesSubstring: 'Ruby Runtime')
]

{ #category : 'tests' }
GbsSessionTest >> testRubyRuntimeFacadeAutoloadRegistrationEntriesExposeLifecycleMetadata [
	| mockSession namespace entries entry |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [ ^ #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true)) ].
		(script includesSubstring: 'System sessionStateAt: key')
			ifTrue: [ ^ nil ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'Object nameSpace: 1'
		symbolListIndex: nil
		metadata: #(7001 nil nil 'RubyNameSpace' 'Object').

	entries := mockSession rubyRuntime autoloadRegistrationEntriesForNamespace: namespace.
	entry := entries first.

	self assert: entries size equals: 1.
	self assert: entry autoloadFile equals: 'lib/lazy_thing.rb'.
	self assert: entry persistentAutoloadFile equals: 'lib/lazy_thing.rb'.
	self assert: entry isTransientCached.
	self assert: entry hasPersistentRegistration.
	self assert: entry registrationStateLabel equals: 'Transient+Persistent'.
	self assert: (entry displayString includesSubstring: '{Transient+Persistent}')
]

{ #category : 'tests' }
GbsSessionTest >> testRubyRuntimeEntriesExposeFileProvenanceMetadata [
	| loadPathEntry featureEntry autoloadEntry autoload |
	loadPathEntry := GbsRubyLoadPathEntry path: '/opt/demo/lib'.
	featureEntry := GbsRubyLoadedFeatureEntry feature: 'app/models/invoice.rb' persistent: true.
	autoload := GbsRemoteAutoloadMirror
		on: (GbsRemoteNamespaceMirror topLevelOn: MockGbsSession new)
		metadata: #('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true).
	autoloadEntry := GbsRubyAutoloadRegistrationEntry on: autoload.

	self assert: loadPathEntry provenanceLabel equals: 'Absolute Load Path'.
	self assert: loadPathEntry rootComponent equals: 'opt'.
	self assert: loadPathEntry pathComponents equals: #('opt' 'demo' 'lib').
	self assert: featureEntry provenanceLabel equals: 'Persistent Feature'.
	self assert: featureEntry isRubySource.
	self assert: featureEntry rootComponent equals: 'app'.
	self assert: autoloadEntry autoloadFile equals: 'lib/lazy_thing.rb'.
	self assert: autoloadEntry recoveryStateLabel equals: 'Recoverable'.
	self assert: autoloadEntry provenanceLabel equals: 'Transient+Persistent'.
	self assert: autoloadEntry isRubySource.
	self assert: autoloadEntry pathComponents equals: #('lib' 'lazy_thing.rb')
]

{ #category : 'tests' }
GbsSessionTest >> testRemoteAutoloadMirrorRecoverRegistrationUsesPersistentFallback [
	| mockSession namespace autoload result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: name asSymbol env: 1') ifFalse: [ self fail ].
		self assert: (script includesSubstring: 'persistCopy').
		self assert: (script includesSubstring: 'rubyAutoload: name asSymbol file: fileName').
		^ 'lib/lazy_thing.rb' ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace instVarNamed: 'autoloadEntries' put: #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true)).
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true).

	result := autoload recoverRegistration.

	self assert: result equals: 'lib/lazy_thing.rb'.
	self assert: (namespace instVarNamed: 'autoloadEntries') isNil
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeReportTextSummarizesWellKnownSessionState [
	| mockSession report |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System sessionStateAt: key')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		self fail ].

	report := mockSession objectSpaceDiagnostics reportText.

	self assert: (report includesSubstring: 'Session State').
	self assert: (report includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1')
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeSupportsArbitraryKeysWithSlotObjects [
	| mockSession diagnostics slot report |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeSupportsNamedSlotAliases [
	| mockSession diagnostics slot report |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		self fail ].
	diagnostics := mockSession objectSpaceDiagnostics.

	slot := diagnostics slotNamed: 'maglev_finalizer_registry'.
	report := diagnostics reportTextForSlotNames: #('ruby finalizers').

	self assert: (diagnostics slotKeyNamed: 'maglev_finalizer_registry') equals: 19.
	self assert: (diagnostics slotKeyNamed: 'ruby finalizers') equals: 19.
	self assert: slot key equals: 19.
	self assert: slot label equals: 'MagLev Finalizer Registry'.
	self assert: (report includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1')
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeExpandsAliasPrefixesAndAliasNames [
	| mockSession diagnostics slot |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeReportObjectSeparatesWellKnownAndCustomSlots [
	| mockSession report |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceDiagnosticsFinalizerRegistryReportIncludesReferencers [
	| mockSession report |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ GbsProxy oop: 9001 session: mockSession ].
		(script includesSubstring: 'findReferencesInMemory') ifTrue: [
			^ { GbsProxy oop: 9101 session: mockSession } ].
		self fail ].

	report := mockSession objectSpaceDiagnostics finalizerRegistryReport.

	self assert: report referencers size equals: 1.
	self assert: report referencers first oop equals: 9101.
	self assert: (report text includesSubstring: 'MagLev Finalizer Registry oop=9001 Referencers').
	self assert: (report text includesSubstring: 'oop=9101')
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceDiagnosticsObjectsInMemoryReportUsesStructuredObjects [
	| mockSession report |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testRemoteNamespaceMirrorScopedSelectorQueryFiltersGlobalResultsByNamespace [
	| mockSession namespace implementors senders references query |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'implementorsOf:')
			ifTrue: [ ^ #('Accounting::Invoice>>size' 'Other::Thing>>size') ].
		(script includesSubstring: 'selectorsReferTo:')
			ifTrue: [ ^ #('Accounting::Invoice>>size' 'Other::Thing>>size') ].
		(script includesSubstring: 'referencesTo:')
			ifTrue: [ ^ #('Accounting::Invoice>>size' 'Other::Thing>>size') ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: '[:value | value] value: nil'
		symbolListIndex: nil
		metadata: #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module').

	implementors := namespace implementorMethodReferenceStringsForSelector: #size.
	senders := namespace senderMethodReferenceStringsForSelector: #size.
	references := namespace methodReferenceStringsToSymbol: 'Invoice'.
	query := namespace implementorsQueryForSelector: #size.

	self assert: implementors equals: #('Accounting::Invoice>>size').
	self assert: senders equals: #('Accounting::Invoice>>size').
	self assert: references equals: #('Accounting::Invoice>>size').
	self assert: query class equals: GbsNamespaceScopedMethodQuery.
	self assert: query references equals: #('Accounting::Invoice>>size').
	self assert: (query title includesSubstring: 'Namespace Implementors of size')
]

{ #category : 'tests' }
GbsSessionTest >> testProcObjectForOopExposesMetadataAndInvocation [
	| mockSession proc result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifTrue: [ ^ #('ExecBlock2' 2 true 'demo.rb:12' 'proc { |a, b| a + b }') ].
		self fail ].
	mockSession stubs at: #forwardRemoteMessage put: [ :message :targetOop |
		self assert: message selector equals: #call.
		self assert: message arguments asArray equals: #(1 2).
		self assert: targetOop equals: 9001.
		^ 'ok' ].

	proc := mockSession procObjectForOop: 9001.
	result := proc value: 1 value: 2.

	self assert: proc exists.
	self assert: proc isExecBlock.
	self assert: proc arity equals: 2.
	self assert: proc bindingDisplayString equals: 'execBlock'.
	self assert: proc sourceLocation equals: 'demo.rb:12'.
	self assert: proc sourceCode equals: 'proc { |a, b| a + b }'.
	self assert: result equals: 'ok'
]

{ #category : 'tests' }
GbsSessionTest >> testRemoteMethodObjectToProcBuildsRemoteProcObject [
	| mockSession methodObject proc |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'receiver := Object _objectForOop: 9001')
			ifTrue: [
				self assert: (script includesSubstring: 'receiver method: #foo').
				^ '9101' ].
		(script includesSubstring: 'Object _objectForOop: 9101')
			ifTrue: [ ^ #('Proc' 0 false 'demo.rb:1' 'proc { foo }') ].
		self fail ].
	methodObject := (GbsRemoteMethodObject
		on: mockSession
		class: 'DemoClass'
		selector: #foo
		classSide: false)
			bindTo: (GbsProxy oop: 9001 session: mockSession).

	proc := methodObject toProc.

	self assert: proc class equals: GbsRemoteProcObject.
	self assert: proc oop equals: 9101.
	self assert: proc isExecBlock not
]

{ #category : 'tests' }
GbsSessionTest >> testRubyRuntimeEntryRelativeActionsNormalizeAgainstFeaturePath [
	| mockSession entry required loaded |
	required := false.
	loaded := false.
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'requireFileNamed:')
			ifTrue: [
				required := true.
				self assert: (script includesSubstring: 'app/shared.rb').
				self deny: (script includesSubstring: '../shared.rb').
				^ 'required' ].
		(script includesSubstring: 'loadFileNamed:')
			ifTrue: [
				loaded := true.
				self assert: (script includesSubstring: 'support/bootstrap.rb').
				self deny: (script includesSubstring: '../../support/bootstrap.rb').
				^ 'loaded' ].
		self fail ].
	entry := GbsRubyLoadedFeatureEntry feature: 'app/models/invoice.rb'.

	self assert: (entry requireRelative: '../shared.rb' using: mockSession rubyRuntime) equals: 'required'.
	self assert: (entry loadRelative: '../../support/bootstrap.rb' using: mockSession rubyRuntime) equals: 'loaded'.
	self assert: required.
	self assert: loaded
]

{ #category : 'tests' }
GbsSessionTest >> testRemoteAutoloadMirrorResetAndRetryRegistrationUseLifecycleScripts [
	| mockSession namespace autoload resetResult retryResult |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Array with: fileName with: fileWasReset')
			ifTrue: [
				self assert: (script includesSubstring: 'Autoload registration is not recoverable.').
				^ #('lib/lazy_thing.rb' true) ].
		(script includesSubstring: 'removeConst: name asSymbol')
			ifTrue: [
				self assert: (script includesSubstring: 'transientNameSpaceForStore: false').
				^ 'lib/lazy_thing.rb' ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	namespace instVarNamed: 'autoloadEntries' put: #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true)).
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true).

	resetResult := autoload resetRegistration.
	retryResult := autoload retryRegistration.

	self assert: autoload canResetRegistration.
	self assert: autoload canRetryRegistration.
	self assert: autoload retryStateLabel equals: 'Recoverable'.
	self assert: resetResult equals: 'lib/lazy_thing.rb'.
	self assert: retryResult first equals: 'lib/lazy_thing.rb'.
	self assert: retryResult second equals: true.
	self assert: (namespace instVarNamed: 'autoloadEntries') isNil
]

{ #category : 'tests' }
GbsSessionTest >> testProcObjectForOopSpecializesExecBlocksAndEnforcesArity [
	| mockSession proc |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifTrue: [ ^ #('ExecBlock2' 2 true 'demo.rb:12' 'proc { |a, b| a + b }') ].
		self fail ].

	proc := mockSession procObjectForOop: 9001.

	self assert: proc class equals: GbsRemoteExecBlockObject.
	self assert: proc isExecBlock.
	self assert: proc isLambdaLike.
	self should: [ proc value: 1 ] raise: Error
]

{ #category : 'tests' }
GbsSessionTest >> testProcBindingObjectExposesReceiverAndCapturedLocals [
	| mockSession proc binding associations |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifTrue: [
				^ #('Proc' 1 false 'demo.rb:12' 'proc { |invoice| invoice total }' 9101 #('invoice' 'count') #(9201 nil) #('a DemoInvoice' '42')) ].
		self fail ].

	proc := mockSession procObjectForOop: 9001.
	binding := proc bindingObject.
	associations := binding localAssociations.

	self assert: binding receiverOop equals: 9101.
	self assert: binding receiverProxy oop equals: 9101.
	self assert: binding hasCapturedLocals.
	self assert: proc hasCapturedLocals.
	self assert: proc localNames equals: #('invoice' 'count').
	self assert: associations first key equals: 'invoice'.
	self assert: associations first value oop equals: 9201.
	self assert: associations second key equals: 'count'.
	self assert: associations second value equals: '42'.
	self assert: (mockSession bindingObjectForProcOop: 9001) class equals: GbsRemoteBindingObject
]

{ #category : 'tests' }
GbsSessionTest >> testProcBindingObjectEvaluatesRubySourceAndLocals [
	| mockSession proc binding |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifFalse: [ self fail ].
		(script includesSubstring: 'perform: #eval withArguments:')
			ifTrue: [
				self assert: (script includesSubstring: '''demo.rb''').
				self assert: (script includesSubstring: '12 }').
				(script includesSubstring: '''invoice''')
					ifTrue: [ ^ 42 ].
				^ 57 ].
		^ #('Proc' 1 false 'demo.rb:12' 'proc { |invoice| invoice total }' 9101 #('invoice' 'count') #(9201 nil) #('a DemoInvoice' '42')) ].

	proc := mockSession procObjectForOop: 9001.
	binding := proc bindingObject.

	self assert: (binding evaluate: 'invoice.total + count') equals: 57.
	self assert: (binding localValueNamed: 'invoice') equals: 42.
	self assert: binding lexicalScopeNames equals: #('invoice' 'count').
	self assert: binding lexicalScopeAssociations size equals: 2
]

{ #category : 'tests' }
GbsSessionTest >> testProcBindingObjectSupportsLocalMutationAndLexicalMetadata [
	| mockSession proc binding |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifFalse: [ self fail ].
		(script includesSubstring: 'binding lexicalPath')
			ifTrue: [ ^ '#(''Demo'' ''Closures'')' ].
		(script includesSubstring: 'binding methodDefTarget')
			ifTrue: [ ^ 'Demo::Closures' ].
		(script includesSubstring: 'binding forModuleEval')
			ifTrue: [ ^ true ].
		(script includesSubstring: 'perform: #eval withArguments:')
			ifTrue: [
				(script includesSubstring: 'invoice = (99)')
					ifTrue: [ ^ 99 ].
				^ 57 ].
		^ #('Proc' 1 false 'demo.rb:12' 'proc { invoice }' 9101 #('invoice') #(9201) #('a DemoInvoice')) ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: 'binding methodDefTarget').
		^ 9301 ].

	proc := mockSession procObjectForOop: 9001.
	binding := proc bindingObject.

	self assert: binding selfProxy oop equals: 9101.
	self assert: binding forModuleEval.
	self assert: binding lexicalPathDisplayString equals: '#(''Demo'' ''Closures'')'.
	self assert: binding methodDefTargetDisplayString equals: 'Demo::Closures'.
	self assert: binding methodDefTargetProxy oop equals: 9301.
	self assert: (binding setLocalNamed: 'invoice' to: 99) equals: 99
]

{ #category : 'tests' }
GbsSessionTest >> testProcBindingObjectBuildsClosureIdentityAndText [
	| mockSession proc binding |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'Object _objectForOop: 9001')
			ifFalse: [ self fail ].
		(script includesSubstring: 'binding lexicalPath')
			ifTrue: [ ^ '#(''Demo'' ''Closures'')' ].
		(script includesSubstring: 'binding methodDefTarget')
			ifTrue: [ ^ 'Demo::Closures' ].
		(script includesSubstring: 'binding forModuleEval')
			ifTrue: [ ^ true ].
		^ #('Proc' 1 false 'demo.rb:12' 'proc { invoice }' 9101 #('invoice') #(9201) #('a DemoInvoice')) ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script | 9301 ].

	proc := mockSession procObjectForOop: 9001.
	binding := proc bindingObject.

	self assert: (binding closureIdentityString includesSubstring: 'binding@demo.rb:12').
	self assert: (binding text includesSubstring: 'Lexical Path: #(''Demo'' ''Closures'')').
	self assert: (binding text includesSubstring: 'Method Target: Demo::Closures').
	self assert: (binding text includesSubstring: 'Receiver OOP: 9101').
	self assert: (proc text includesSubstring: 'Proc [arity=1]').
	self assert: (proc text includesSubstring: 'invoice =>')
]

{ #category : 'tests' }
GbsSessionTest >> testRubyRuntimeReportBuildsProvenanceGraphAndRelativeActions [
	| mockSession namespace graph entry action |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('config/boot.rb') ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [ ^ #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true)) ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.

	graph := (mockSession rubyRuntime
		reportForNamespace: namespace
		selectedConstant: nil
		selectedAutoload: nil) provenanceGraph.
	entry := GbsRubyLoadedFeatureEntry feature: 'app/models/invoice.rb'.
	action := entry requireRelativeActionFor: '../shared.rb' using: mockSession rubyRuntime.

	self assert: graph links size equals: 4.
	self assert: (graph text includesSubstring: 'Absolute Load Path -> /opt/demo/lib').
	self assert: (graph text includesSubstring: 'Transient Feature -> app/models/invoice.rb').
	self assert: (graph text includesSubstring: 'LazyThing -> lib/lazy_thing.rb').
	self assert: action actionLabel equals: 'require_relative'.
	self assert: action resolvedPath equals: 'app/shared.rb'
]

{ #category : 'tests' }
GbsSessionTest >> testRubyRuntimeReportBuildsProvenanceActionsForFeaturesAndAutoloadRecovery [
	| mockSession namespace graph |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('config/boot.rb') ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [
				^ #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true 'Persistent registration can recover lib/lazy_thing.rb' 'Reset transient cache, then recover persistent registration.' 'Transient Cache + Persistent Registration')) ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.

	graph := (mockSession rubyRuntime
		reportForNamespace: namespace
		selectedConstant: nil
		selectedAutoload: nil) provenanceGraph.

	self assert: graph actions size equals: 8.
	self assert: (graph text includesSubstring: 'Actions').
	self assert: (graph text includesSubstring: 'require app/models/invoice.rb').
	self assert: (graph text includesSubstring: 'load config/boot.rb').
	self assert: (graph text includesSubstring: 'recover autoload LazyThing').
	self assert: (graph text includesSubstring: 'reset autoload LazyThing').
	self assert: (graph text includesSubstring: 'retry autoload [transient-reset] LazyThing').
	self assert: (graph text includesSubstring: 'retry autoload [persistent-after-reset] LazyThing')
]

{ #category : 'tests' }
GbsSessionTest >> testRubyRuntimeProvenanceGraphNavigatesEntryLinksAndActions [
	| mockSession namespace report graph featureEntry autoloadEntry |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('config/boot.rb') ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil: each env: 1')
			ifTrue: [
				^ #(#('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true 'Persistent registration can recover lib/lazy_thing.rb' 'Reset transient cache, then recover persistent registration.' 'Transient Cache + Persistent Registration' 'A transient cache entry remains from a failed or interrupted autoload attempt.' 'lib/lazy_thing.rb' 'persistent-after-reset')) ].
		self fail ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.
	report := mockSession rubyRuntime
		reportForNamespace: namespace
		selectedConstant: nil
		selectedAutoload: nil.
	graph := report provenanceGraph.
	featureEntry := report loadedFeatureEntries first.
	autoloadEntry := report autoloadRegistrations first.

	self assert: (graph linksForEntry: featureEntry) size equals: 1.
	self assert: (graph actionsForEntry: featureEntry) size equals: 2.
	self assert: (graph actionsForEntry: autoloadEntry) size equals: 4.
	self assert: (graph entriesForSourceLabel: 'Transient Feature') size equals: 1.
	self assert: ((graph linksToTargetLabel: 'lib/lazy_thing.rb') anySatisfy: [ :each | each entry = autoloadEntry ])
]

{ #category : 'tests' }
GbsSessionTest >> testRemoteAutoloadMirrorFailureStateLabelsDifferentiatePendingAndRecoverableFailure [
	| namespace pending recoverable cached recoverableEntry |
	namespace := GbsRemoteNamespaceMirror topLevelOn: MockGbsSession new.
	pending := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' 'lib/lazy_thing.rb' false 9101 nil false false).
	recoverable := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' nil false 9101 'lib/lazy_thing.rb' false true).
	cached := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' nil false 9101 nil true false).
	recoverableEntry := GbsRubyAutoloadRegistrationEntry on: recoverable.

	self assert: pending failureStateLabel equals: 'Awaiting First Load'.
	self deny: pending hasFailedRegistration.
	self assert: recoverable failureStateLabel equals: 'Persistent Recovery Required'.
	self assert: recoverable hasFailedRegistration.
	self assert: cached failureStateLabel equals: 'Transient Cache Reset Required'.
	self assert: (recoverableEntry displayString includesSubstring: '<Persistent Recovery Required>')
]

{ #category : 'tests' }
GbsSessionTest >> testRemoteAutoloadMirrorExposesFailureDetailAndRetryDetail [
	| namespace autoload entry |
	namespace := GbsRemoteNamespaceMirror topLevelOn: MockGbsSession new.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: #('LazyThing' nil false 9101 'lib/lazy_thing.rb' true true 'Persistent registration can recover lib/lazy_thing.rb' 'Reset transient cache, then recover persistent registration.' 'Transient Cache + Persistent Registration' 'A transient cache entry remains from a failed or interrupted autoload attempt.' 'lib/lazy_thing.rb' 'persistent-after-reset').
	entry := GbsRubyAutoloadRegistrationEntry on: autoload.

	self assert: autoload failureDetail equals: 'Persistent registration can recover lib/lazy_thing.rb'.
	self assert: autoload retryDetailLabel equals: 'Reset transient cache, then recover persistent registration.'.
	self assert: autoload failureSourceLabel equals: 'Transient Cache + Persistent Registration'.
	self assert: autoload failureMessage equals: 'A transient cache entry remains from a failed or interrupted autoload attempt.'.
	self assert: autoload lastAttemptedFile equals: 'lib/lazy_thing.rb'.
	self assert: autoload retrySourceKind equals: 'persistent-after-reset'.
	self assert: autoload retrySourceChoices equals: #('transient-reset' 'persistent-after-reset').
	self assert: entry failureDetail equals: autoload failureDetail.
	self assert: entry failureMessage equals: autoload failureMessage.
	self assert: entry retryDetailLabel equals: autoload retryDetailLabel.
	self assert: entry retrySourceKind equals: autoload retrySourceKind.
	self assert: (entry displayString includesSubstring: 'Persistent registration can recover lib/lazy_thing.rb')
]

{ #category : 'tests' }
GbsSessionTest >> testRemoteAutoloadFailureBuildsExceptionObjectAndBacktrace [
	| session namespace autoload failure exception metadata |
	session := MockGbsSession new.
	namespace := GbsRemoteNamespaceMirror topLevelOn: session.
	metadata := {
		'LazyThing'.
		nil.
		false.
		9101.
		'lib/lazy_thing.rb'.
		true.
		true.
		'Persistent registration can recover lib/lazy_thing.rb'.
		'Reset transient cache, then recover persistent registration.'.
		'Transient Cache + Persistent Registration'.
		'autoload failed'.
		'lib/lazy_thing.rb'.
		'persistent-after-reset'.
		9501.
		'LazyThingError: boom', String lf, 'demo.rb:12' }.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: metadata.
	failure := autoload failure.
	exception := failure exceptionObject.

	self assert: failure retrySourceChoices equals: #('transient-reset' 'persistent-after-reset').
	self assert: failure retrySourceKind equals: 'persistent-after-reset'.
	self assert: exception oop equals: 9501.
	self assert: exception hasRemoteObject.
	self assert: exception hasBacktrace.
	self assert: exception backtraceText equals: 'LazyThingError: boom', String lf, 'demo.rb:12'.
	self assert: exception backtraceLines asArray equals: #('LazyThingError: boom' 'demo.rb:12').
	self assert: exception backtraceLines last equals: 'demo.rb:12'.
	self assert: failure failureBacktraceText equals: exception backtraceText.
	self assert: (exception text includesSubstring: 'Backtrace').
	self assert: (exception text includesSubstring: 'demo.rb:12')
]

{ #category : 'tests' }
GbsSessionTest >> testRemoteAutoloadFailureBuildsBacktraceEntryObjectsAndRetryActions [
	| session namespace autoload failure entry |
	session := MockGbsSession new.
	namespace := GbsRemoteNamespaceMirror topLevelOn: session.
	autoload := GbsRemoteAutoloadMirror
		on: namespace
		metadata: {
			'LazyThing'. nil. false. 9101. 'lib/lazy_thing.rb'. true. true.
			'Persistent registration can recover lib/lazy_thing.rb'.
			'Reset transient cache, then recover persistent registration.'.
			'Transient Cache + Persistent Registration'.
			'autoload failed'.
			'lib/lazy_thing.rb'.
			'persistent-after-reset'.
			9501.
			'LazyThingError: boom', String lf, 'demo.rb:12', String lf, 'lib/lazy_thing.rb:3' }.
	failure := autoload failure.
	entry := GbsRubyAutoloadRegistrationEntry on: autoload.

	self assert: failure backtraceEntries size equals: 3.
	self assert: failure backtraceEntries second fileName equals: 'demo.rb'.
	self assert: failure backtraceEntries second lineNumber equals: 12.
	self assert: failure retryActionChoices size equals: 2.
	self assert: entry failureBacktraceEntries last fileName equals: 'lib/lazy_thing.rb'
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryNamespaceMirrorAutoloadEntriesScriptIncludesFailureExceptionMetadata [
	| mockSession namespace |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#lastException').
		self assert: (script includesSubstring: '#lastExceptionBacktrace').
		^ #() ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.

	self assert: namespace autoloadMirrors equals: #()
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryNamespaceMirrorRetryAutoloadUsingSourceKindBuildsExpectedScript [
	| mockSession namespace result |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'selectedSource := sourceKind').
		self assert: (script includesSubstring: '''persistent-after-reset''').
		self assert: (script includesSubstring: 'selectedSource = ''transient-reset''').
		self assert: (script includesSubstring: 'selectedSource = ''persistent-after-reset''').
		^ #('lib/lazy_thing.rb' true 'persistent-after-reset') ].
	namespace := GbsRemoteNamespaceMirror topLevelOn: mockSession.

	result := namespace
		retryAutoload: 'LazyThing'
		usingSourceKind: 'persistent-after-reset'.

	self assert: result third equals: 'persistent-after-reset'
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeDiscoversOccupiedSlotsAndParsesNamedAliases [
	| mockSession diagnostics discovered slot |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeSupportsRegisteredWellKnownSlots [
	| mockSession diagnostics slot report |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		GbsObjectSpaceDiagnosticsFacade
			registerWellKnownSessionStateSlotKey: 21
			label: 'Ruby Thread Cache'
			aliases: #('rubythreadcache' 'threadcache').
		mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeBatchRegistersSlotsAndTracksDiscoverySource [
	| mockSession diagnostics registeredSlot discoveredSlot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		GbsObjectSpaceDiagnosticsFacade registerWellKnownSessionStateSlots: {
			{ 21. 'Ruby Thread Cache'. #('rubythreadcache' 'threadcache') }.
			{ 22. 'Ruby Fiber Registry'. #('rubyfiberregistry' 'fiberregistry') } }.
		mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeBuildsTypedWellKnownSlotsWithTags [
	| mockSession diagnostics slot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		mockSession := MockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 19') ifTrue: [ ^ #(1 2 3) ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.
		slot := diagnostics slotNamed: 'maglev finalizer registry'.

		self assert: slot class equals: GbsFinalizerRegistrySessionStateSlot.
		self assert: slot isWellKnown.
		self assert: slot discoverySource equals: #registered.
		self assert: (slot hasTag: #maglev).
		self assert: (slot hasTag: #finalizerRegistry)
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeBuildsTypedCacheAndRegistrySlots [
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
		mockSession := MockGbsSession new.
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
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeInfersTypedSlotsForDiscoveredValues [
	| mockSession diagnostics registrySlot cacheSlot threadSlot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		GbsObjectSpaceDiagnosticsFacade
			registerWellKnownThreadStateSessionStateSlotKey: 25
			label: 'Ruby Thread State'
			aliases: #('rubythreadstate' 'threadstate')
			tags: #(#ruby #thread).
		mockSession := MockGbsSession new.
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
GbsSessionTest >> testSessionMethodsAccessorUsesSymbolDictionaryFacade [
	| mockSession result |
	mockSession := MockGbsSession new.

	result := mockSession sessionMethods.

	self assert: result class equals: GbsSymbolDictionaryFacade.
	self assert: result name equals: 'SessionMethods'
]

{ #category : 'tests' }
GbsSessionTest >> testMaglevFacadeExposesBridgeRootAndSharedCounters [
	| mockSession maglev sharedCounter |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'System transactionLevel' ifTrue: [ ^ 2 ].
		script = 'System sharedCounter: 3' ifTrue: [ ^ 41 ].
		script = 'System sharedCounter: 3 incrementBy: 2' ifTrue: [ ^ 43 ].
		self fail ].

	maglev := mockSession maglev.
	sharedCounter := maglev sharedCounterAt: 3.

	self assert: maglev bridgeRoot class equals: GbsBridgeRootFacade.
	self assert: maglev transactionLevel equals: 2.
	self assert: sharedCounter value equals: 41.
	self assert: (sharedCounter incrementBy: 2) equals: 43
]

{ #category : 'tests' }
GbsSessionTest >> testMaglevBridgeRootMaterializesRcAndProcEntries [
	| mockSession root counter proc |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'clsName :=') ifTrue: [ ^ #('Proc' 1 false nil nil nil #() #() #()) ].
		(script includesSubstring: '#counter') ifTrue: [ ^ GbsProxy oop: 7001 session: mockSession ].
		(script includesSubstring: '#job') ifTrue: [ ^ GbsProxy oop: 7002 session: mockSession ].
		(script includesSubstring: '#missing') ifTrue: [ ^ nil ].
		self fail ].
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: '7001') ifTrue: [ ^ 'RcCounter' ].
		(script includesSubstring: '7002') ifTrue: [ ^ 'Proc' ].
		self fail ].

	root := mockSession maglev bridgeRoot.
	counter := root at: #counter.
	proc := root at: #job.

	self assert: counter class equals: GbsRcCounter.
	self assert: proc class equals: GbsRemoteProcObject.
	self assert: (root at: #missing ifAbsent: [ #fallback ]) equals: #fallback
]

{ #category : 'tests' }
GbsSessionTest >> testObjectLogFacadeMapsEntriesAndMaterializesPayloads [
	| mockSession entries entry |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'ObjectLogEntry objectLog') ifTrue: [
			^ { { 1. 4. 'Saved object'. 1234. '2026-01-01T10:00:00Z'. 'runtime'. true. 7101. 'a counter' } } ].
		self fail ].
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: '7101') ifTrue: [ ^ 'RcCounter' ].
		self fail ].

	entries := mockSession objectLog entries.
	entry := entries first.

	self assert: entries size equals: 1.
	self assert: entry priorityLabel equals: 'INFO'.
	self assert: entry label equals: 'Saved object'.
	self assert: entry object class equals: GbsRcCounter.
	self assert: (mockSession objectLog reportText includesSubstring: 'Saved object')
]

{ #category : 'tests' }
GbsSessionTest >> testChunkedMigrationRunnerBuildsMaglevAlignedScripts [
	| mockSession runner prepareScript chunkScript |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testChunkedMigrationRunnerPrepareCheckpointReplaysAcrossCommitConflict [
	| mockSession runner result listCount checkpointWriteCount commits |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testCommitTransactionWithRetryCountSignalsConflictAfterExhaustion [
	| mockSession commitCount |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testMaglevFacadeExposesSymbolDictionaryFacades [
	| mockSession maglev |
	mockSession := MockGbsSession new.
	maglev := mockSession maglev.

	self assert: maglev globals class equals: GbsSymbolDictionaryFacade.
	self assert: maglev globals name equals: 'Globals'.
	self assert: maglev published class equals: GbsSymbolDictionaryFacade.
	self assert: maglev published name equals: 'Published'.
	self assert: maglev userGlobals class equals: GbsSymbolDictionaryFacade.
	self assert: maglev userGlobals name equals: 'UserGlobals'.
	self assert: maglev sessionMethods class equals: GbsSymbolDictionaryFacade.
	self assert: maglev sessionMethods name equals: 'SessionMethods'
]

{ #category : 'tests' }
GbsSessionTest >> testSmalltalkFacadeExposesBridgeRootAndSymbolDictionaries [
	| mockSession facade |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testMaterializeMaglevRuntimeValueMapsGsDictionaryAndGenericObject [
	| mockSession dictionary object |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: '7201') ifTrue: [ ^ 'StringKeyValueDictionary' ].
		(script includesSubstring: '7202') ifTrue: [ ^ 'RubyServiceThing' ].
		self fail ].

	dictionary := mockSession materializeMaglevRuntimeValue: (GbsProxy oop: 7201 session: mockSession).
	object := mockSession materializeMaglevRuntimeValue: (GbsProxy oop: 7202 session: mockSession).

	self assert: dictionary class equals: GbsGsDictionary.
	self assert: object class equals: GbsGsObject.
	self assert: object oop equals: 7202
]

{ #category : 'tests' }
GbsSessionTest >> testObjectLogFacadeWritesTaggedEntriesAndCommits [
	| mockSession commitCount |
	mockSession := MockGbsSession new.
	commitCount := 0.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'ObjectLogEntry info:') ifTrue: [
			self assert: (script includesSubstring: '''Tagged entry''').
			self assert: (script includesSubstring: 'entry tag:').
			self assert: (script includesSubstring: '''runtime''').
			^ true ].
		self fail ].
	mockSession stubs at: #gciCommit put: [
		commitCount := commitCount + 1.
		1 ].

	self assert: (mockSession objectLog info: 'Tagged entry' object: nil tag: 'runtime').
	self assert: commitCount equals: 1
]

{ #category : 'tests' }
GbsSessionTest >> testFetchTranscriptLogsUsesSessionTempsFallbackScript [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		self assert: (script includesSubstring: 'Transcript respondsTo: #fetchAndClear').
		self assert: (script includesSubstring: '#PharoTranscriptLog').
		self assert: (script includesSubstring: 'SessionTemps current at: #PharoTranscriptLog put: OrderedCollection new').
		^ 'TDD Hello', String cr ].

	self assert: (mockSession fetchTranscriptLogs includesSubstring: 'TDD Hello')
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceDiagnosticsFacadeRegistersMaglevCompilerAndStackSlots [
	| mockSession diagnostics compilerSlot targetStackSlot evalArgsSlot currentTargetSlot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		mockSession := MockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 1') ifTrue: [ ^ 'compiler-state' ].
			(script includesSubstring: 'key := 3') ifTrue: [ ^ #(1 2 3) ].
			(script includesSubstring: 'key := 6') ifTrue: [ ^ #(4 5) ].
			(script includesSubstring: 'key := 7') ifTrue: [ ^ 'method-target' ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.
		compilerSlot := diagnostics slotNamed: 'ruby compiler state'.
		targetStackSlot := diagnostics slotNamed: 'ruby method definition target stack'.
		evalArgsSlot := diagnostics slotNamed: 'ruby eval arguments stack'.
		currentTargetSlot := diagnostics slotNamed: 'ruby current method definition target'.

		self assert: compilerSlot class equals: GbsCompilerStateSessionStateSlot.
		self assert: targetStackSlot class equals: GbsStackSessionStateSlot.
		self assert: evalArgsSlot class equals: GbsStackSessionStateSlot.
		self assert: currentTargetSlot class equals: GbsThreadStateSessionStateSlot
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]

{ #category : 'tests' }
GbsSessionTest >> testObjectSpaceRepositoryFacadeCountsOopsAndBuildsReport [
	| mockSession repository report |
	mockSession := MockGbsSession new.
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
GbsSessionTest >> testWithCommitRetryCountReplaysBlockAcrossCommitConflict [
	| mockSession attempts commits result |
	mockSession := MockGbsSession new.
	attempts := 0.
	commits := #(0 1) readStream.
	mockSession stubs at: #gciCommit put: [ commits next ].

	result := mockSession withCommitRetryCount: 1 do: [
		attempts := attempts + 1.
		attempts ].

	self assert: result equals: 2.
	self assert: attempts equals: 2
]
