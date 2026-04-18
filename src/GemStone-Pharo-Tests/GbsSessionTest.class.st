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
	self assert: root rootKey equals: #GbsPersistentRoot.
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
		self assert: (script includesSubstring: '#GbsPersistentRoot').
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
		self assert: (script includesSubstring: '#GbsPersistentRoot').
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
		self assert: (script includesSubstring: '#GbsPersistentRoot').
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
		self assert: (script includesSubstring: '#GbsPersistentRoot').
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
		self assert: (script includesSubstring: '#GbsPersistentRoot').
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
	self assert: namespace rootKey equals: #GbsPersistentRoot.
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
GbsSessionTest >> testRepositoryRootLockQueriesReturnDefaultsForMissingNamespace [
	| mockSession root |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: '#GbsPersistentRoot').
		0 ].
	root := GbsRepositoryRootFacade
		on: mockSession
		rootKey: #GbsPersistentRoot
		path: #(#tickets).

	self assert: root lockKind equals: #none.
	self assert: root lockOwners equals: #().
	self assert: root removeLock == root
]

{ #category : 'tests' }
GbsSessionTest >> testRepositoryRootWithReadLockDoLocksAndUnlocksContainer [
	| mockSession root scripts result seenFacade seenProxy |
	mockSession := MockGbsSession new.
	scripts := OrderedCollection new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: '#GbsPersistentRoot').
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
GbsSessionTest >> testRepositoryRootWithWriteLockDoEnsuresNamespaceBeforeLocking [
	| mockSession root scripts result seenFacade seenProxy |
	mockSession := MockGbsSession new.
	scripts := OrderedCollection new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: '#GbsPersistentRoot').
		self assert: (script includesSubstring: 'ifAbsentPut: [ Dictionary new ]').
		self assert: (script includesSubstring: '#tickets').
		5001 ].
	mockSession stubs at: #execute put: [ :script |
		scripts add: script.
		true ].
	root := GbsRepositoryRootFacade
		on: mockSession
		rootKey: #GbsPersistentRoot
		path: #(#tickets).

	result := root withWriteLockDo: [ :facade :proxy |
		seenFacade := facade.
		seenProxy := proxy.
		#done ].

	self assert: result equals: #done.
	self assert: seenFacade == root.
	self assert: seenProxy oop equals: 5001.
	self assert: scripts size equals: 2.
	self assert: (scripts first includesSubstring: 'System perform: #writeLock:').
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
GbsSessionTest >> testRemoteNamespaceMirrorScopedSelectorQueryFiltersGlobalResultsByNamespace [
	| mockSession namespace implementors senders references |
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

	self assert: implementors equals: #('Accounting::Invoice>>size').
	self assert: senders equals: #('Accounting::Invoice>>size').
	self assert: references equals: #('Accounting::Invoice>>size')
]
