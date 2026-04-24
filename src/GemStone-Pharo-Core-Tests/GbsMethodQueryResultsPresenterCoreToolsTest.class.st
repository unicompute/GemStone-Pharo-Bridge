Class {
	#name : 'GbsMethodQueryResultsPresenterCoreToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	presenter session: session.
	presenter enqueueRequestAnswer: 'abc'.

	self deny: presenter browsePromptedSessionStateKey.
	self assert: presenter lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: presenter lastInspectedOop isNil
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testBrowsePromptedSessionStateKeyUsesSessionFacade [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ GbsProxy oop: 9401 session: session ].
	presenter session: session.
	presenter enqueueRequestAnswer: '21'.

	self assert: presenter browsePromptedSessionStateKey.
	self assert: presenter lastInspectedOop equals: 9401
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testBrowseStaleTypedWrapperLifecycleReportUsesStaleEntries [
	| presenter session stale current |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	stale := GbsTypedWrapperLifecycleEntry
		wrapperClass: GbsTypedProxy
		clientName: 'DemoClient'
		serverName: 'DemoServer'
		source: 'remote'
		localVersion: 1
		localNumberOfVersions: 1
		remoteVersion: 2
		remoteNumberOfVersions: 2
		status: #stale.
	current := GbsTypedWrapperLifecycleEntry
		wrapperClass: GbsTypedProxy
		clientName: 'FreshClient'
		serverName: 'FreshServer'
		source: 'remote'
		localVersion: 1
		localNumberOfVersions: 1
		remoteVersion: 1
		remoteNumberOfVersions: 1
		status: #current.
	session stubs at: #typedWrapperLifecycleReport put: [
		GbsTypedWrapperLifecycleReport entries: { stale. current } ].
	presenter session: session.

	self assert: presenter browseStaleTypedWrapperLifecycleReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Typed Wrapper Lifecycle').
	self assert: (presenter lastInfoMessage includesSubstring: 'DemoClient').
	self deny: (presenter lastInfoMessage includesSubstring: 'FreshClient')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testBrowsePromptedSessionStateKeysReportUsesDiagnosticsReport [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		(script includesSubstring: 'key := 21')
			ifTrue: [ ^ 'cache' ].
		self fail ].
	presenter session: session.
	presenter enqueueRequestAnswer: '19, 21'.

	self assert: presenter browsePromptedSessionStateKeysReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Session State').
	self assert: (presenter lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1').
	self assert: (presenter lastInfoMessage includesSubstring: 'Key 21 (Session State): ByteString')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testBrowseObjectsInMemoryReportUsesDiagnosticsReport [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'startIndex := 3').
		self assert: (script includesSubstring: 'limitValue := 2').
		^ { GbsProxy oop: 9101 session: session. GbsProxy oop: 9102 session: session } ].
	presenter session: session.
	presenter enqueueRequestAnswer: '3'.
	presenter enqueueRequestAnswer: '2'.

	self assert: presenter browseObjectsInMemoryReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Objects In Memory').
	self assert: (presenter lastInfoMessage includesSubstring: 'oop=9101').
	self assert: (presenter lastInfoMessage includesSubstring: 'oop=9102')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testBrowseNamedObjectCacheReportUsesSessionCacheText [
	| presenter session cache |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session namedObjectCache addAll: cache.

	presenter session: session.

	self assert: presenter browseNamedObjectCacheReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Named Object Cache').
	self assert: (presenter lastInfoMessage includesSubstring: 'UserGlobals -> oop 9001')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testBrowseTypedWrapperAutoloadReportUsesPresenterSessionRegistry [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	GbsSessionManager addConnectorClient: 'DemoClient' server: 'DemoServer' forSession: session.

	presenter session: session.

	[
		self assert: presenter browseTypedWrapperAutoloadReport.
		self assert: (presenter lastInfoMessage includesSubstring: 'Typed Wrapper Autoload').
		self assert: (presenter lastInfoMessage includesSubstring: 'DemoClient -> DemoServer')
	] ensure: [
		GbsSessionManager removeConnectorClient: 'DemoClient' server: 'DemoServer' forSession: session ]
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testClearNamedObjectCacheClearsSessionCache [
	| presenter session cache |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session namedObjectCache addAll: cache.

	presenter session: session.

	self assert: presenter clearNamedObjectCache.
	self assert: presenter lastInfoMessage equals: 'Named object cache cleared.'.
	self assert: session namedObjectCacheKeys equals: #()
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testClassicLauncherReferencesQueryUsesSessionReferenceStrings [
	| session results |
	session := CoreMockGbsSession new.
	session stubs
		at: #executeAndFetch
		put: [ :script | self fail: 'References query should use methodReferenceStringsToSymbol:.' ].
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: (script includesSubstring: 'organizer referencesTo: #Invoice').
			^ #('Invoice>>totalPrice' 'Invoice class>>new') ].

	results := GbsClassicLauncher
		queryOrganizerMethodsFor: 'Invoice'
		mode: 'references'
		inSession: session.

	self assert: results equals: #('Invoice>>totalPrice' 'Invoice class>>new')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testClassicLauncherSelectorQueriesUseSessionReferenceStrings [
	| session implementors senders |
	session := CoreMockGbsSession new.
	session stubs
		at: #executeAndFetch
		put: [ :script | self fail: 'Selector queries should use repository-backed method reference strings.' ].
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			(script includesSubstring: 'organizer implementorsOf: #size') ifTrue: [
				^ #('Object>>size') ].
			(script includesSubstring: 'organizer sendersOf: ''size''') ifTrue: [
				^ #('Behavior>>new') ].
			self fail ].

	implementors := GbsClassicLauncher
		queryOrganizerMethodsFor: 'size'
		mode: 'implementors'
		inSession: session.
	senders := GbsClassicLauncher
		queryOrganizerMethodsFor: 'size'
		mode: 'senders'
		inSession: session.

	self assert: implementors equals: #('Object>>size').
	self assert: senders equals: #('Behavior>>new')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testBrowseReferencesUsesSelectedOwnerClassName [
	| presenter |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	presenter selectedReference: 'Object class>>new'.

	self assert: presenter browseReferencesToSelectedClass.
	self assert: presenter lastReferenceClassName equals: 'Object'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testBrowseSelectedMethodInfoUsesUnboundMethodObjectMetadata [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #at:put:')
			ifTrue: [ ^ #(9001 'Object' 'at:put:' 'accessing' 'at: index put: value' 'Kernel' 'Object>>at:put:' 2 4) ].
		self fail ].
	presenter
		session: session;
		selectedReference: 'Object>>at:put:'.

	self assert: presenter browseSelectedMethodInfo.
	self assert: (presenter lastInfoMessage includesSubstring: 'Binding: unbound').
	self assert: (presenter lastInfoMessage includesSubstring: 'Arity: 2').
	self assert: (presenter lastInfoMessage includesSubstring: 'Protocol: accessing')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testShowSourceForReferenceUsesRemoteMethodMirrorSource [
	| presenter session text |
	presenter := GbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'compiledMethodAt: #size').
		^ #(9001 'Object' 'size' 'accessing' 'size ^ 1' 'Kernel' 'Object>>size' 1 1) ].
	text := GbxFakeTextPresenterForBrowser new.

	presenter session: session.
	presenter instVarNamed: 'sourceText' put: text.

	presenter showSourceForReference: 'Object>>size'.

	self assert: text text equals: 'size ^ 1'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testBrowseSelectedReferenceUsesMethodObjectWhenQueryPresent [
	| presenter session query |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #size') ifTrue: [
			^ #(9001 'Object' 'size' 'accessing' 'size ^ 1' 'Kernel' 'Object>>size' 1 1) ].
		self fail ].
	query := GbsNamespaceScopedMethodQuery
		session: session
		namespace: nil
		mode: #implementors
		queryValue: 'size'
		references: #('Object>>size')
		title: 'Namespace Implementors of size'.
	presenter
		session: session;
		methodQuery: query;
		selectedReference: 'Object>>size'.

	self assert: presenter browseSelectedReference.
	self assert: presenter lastBrowsedReference isNil.
	self assert: presenter lastBrowsedMethodObject notNil.
	self assert: presenter lastBrowsedMethodObject ownerName equals: 'Object'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testShowSourceForClassSideReferenceUsesRemoteMethodMirrorSource [
	| presenter session text |
	presenter := GbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'behavior := cls class').
		self assert: (script includesSubstring: 'compiledMethodAt: #new').
		^ #(9002 'Object class' 'new' 'instance creation' 'new ^ self basicNew' 'Kernel' 'Object class>>new' 1 1) ].
	text := GbxFakeTextPresenterForBrowser new.

	presenter session: session.
	presenter instVarNamed: 'sourceText' put: text.

	presenter showSourceForReference: 'Object class>>new'.

	self assert: text text equals: 'new ^ self basicNew'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testInspectSelectedMethodUsesMethodObjectOop [
	| presenter session |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #size') ifTrue: [
			^ #(9001 'Object' 'size' 'accessing' 'size ^ 1' 'Kernel' 'Object>>size' 1 1) ].
		self fail ].

	presenter session: session.
	presenter selectedReference: 'Object>>size'.

	self assert: presenter inspectSelectedMethod.
	self assert: presenter lastInspectedOop equals: 9001
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterCoreToolsTest >> testInvokeSelectedMethodPromptsForArguments [
	| presenter session capturedSelector capturedArguments capturedOop |
	presenter := CoreTestableGbsMethodQueryResultsPresenter new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #fromAmount:') ifTrue: [
			^ #(9002 'Money class' 'fromAmount:' 'instance creation' 'fromAmount: amount ^ self new' 'Kernel' 'Money class>>fromAmount:' 1 2) ].
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(9003 'Money' 'Object' 'Kernel' 'Finance' 2 4) ].
		self fail ].
	session stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#created ].

	presenter session: session.
	presenter selectedReference: 'Money class>>fromAmount:'.
	presenter enqueueRequestAnswer: '10'.

	self assert: presenter invokeSelectedMethod.
	self assert: capturedSelector equals: #fromAmount:.
	self assert: capturedArguments equals: #(10).
	self assert: capturedOop equals: 9003.
	self assert: (presenter lastInfoMessage includesSubstring: '#created')
]
