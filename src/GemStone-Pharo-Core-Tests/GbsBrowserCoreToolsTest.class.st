Class {
	#name : 'GbsBrowserCoreToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testBrowseNamedObjectCacheReportUsesSessionCacheText [
	| browser session cache |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session namedObjectCache addAll: cache.

	browser session: session.

	self assert: browser browseNamedObjectCacheReport.
	self assert: (browser lastInfoMessage includesSubstring: 'Named Object Cache').
	self assert: (browser lastInfoMessage includesSubstring: 'UserGlobals -> oop 9001')
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testBrowseTypedWrapperAutoloadReportUsesBrowserSessionRegistry [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	GbsSessionManager addConnectorClient: 'DemoClient' server: 'DemoServer' forSession: session.

	browser session: session.

	[
		self assert: browser browseTypedWrapperAutoloadReport.
		self assert: (browser lastInfoMessage includesSubstring: 'Typed Wrapper Autoload').
		self assert: (browser lastInfoMessage includesSubstring: 'DemoClient -> DemoServer')
	] ensure: [
		GbsSessionManager removeConnectorClient: 'DemoClient' server: 'DemoServer' forSession: session ]
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testBrowseTypedWrapperLifecycleReportUsesBrowserSessionReport [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #typedWrapperLifecycleReportText put: [ 'Typed Wrapper Lifecycle', String cr, String cr, 'No typed wrappers generated.' ].
	browser session: session.

	self assert: browser browseTypedWrapperLifecycleReport.
	self assert: (browser lastInfoMessage includesSubstring: 'Typed Wrapper Lifecycle')
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testBrowseStaleTypedWrapperLifecycleReportUsesStaleEntries [
	| browser session stale current |
	browser := CoreTestableGbsBrowser new.
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
	browser session: session.

	self assert: browser browseStaleTypedWrapperLifecycleReport.
	self assert: (browser lastInfoMessage includesSubstring: 'Typed Wrapper Lifecycle').
	self assert: (browser lastInfoMessage includesSubstring: 'DemoClient').
	self deny: (browser lastInfoMessage includesSubstring: 'FreshClient')
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	browser session: session.
	browser enqueueRequestAnswer: 'abc'.

	self deny: browser browsePromptedSessionStateKey.
	self assert: browser lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: browser lastInspectedOop isNil
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testBrowsePromptedSessionStateKeyUsesSessionFacade [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ GbsProxy oop: 9301 session: session ].
	browser session: session.
	browser enqueueRequestAnswer: '21'.

	self assert: browser browsePromptedSessionStateKey.
	self assert: browser lastInspectedOop equals: 9301
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testBrowsePromptedSessionStateKeysReportUsesDiagnosticsReport [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		(script includesSubstring: 'key := 21')
			ifTrue: [ ^ 'cache' ].
		self fail ].
	browser session: session.
	browser enqueueRequestAnswer: '19, 21'.

	self assert: browser browsePromptedSessionStateKeysReport.
	self assert: (browser lastInfoMessage includesSubstring: 'Session State').
	self assert: (browser lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1').
	self assert: (browser lastInfoMessage includesSubstring: 'Key 21 (Session State): ByteString')
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testBrowseObjectsInMemoryReportUsesDiagnosticsReport [
	| browser session |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'startIndex := 3').
		self assert: (script includesSubstring: 'limitValue := 2').
		^ { GbsProxy oop: 9101 session: session. GbsProxy oop: 9102 session: session } ].
	browser session: session.
	browser enqueueRequestAnswer: '3'.
	browser enqueueRequestAnswer: '2'.

	self assert: browser browseObjectsInMemoryReport.
	self assert: (browser lastInfoMessage includesSubstring: 'Objects In Memory').
	self assert: (browser lastInfoMessage includesSubstring: 'oop=9101').
	self assert: (browser lastInfoMessage includesSubstring: 'oop=9102')
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testClearNamedObjectCacheClearsSessionCache [
	| browser session cache |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session namedObjectCache addAll: cache.

	browser session: session.

	self assert: browser clearNamedObjectCache.
	self assert: browser lastInfoMessage equals: 'Named object cache cleared.'.
	self assert: session namedObjectCacheKeys equals: #()
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testAcceptTextDelegatesToCompileMethod [
	| browser |
	browser := CoreTestableGbsBrowser new.
	browser enableCompileSpy.

	self assert: (browser acceptText: 'foo ^ 1') equals: #compiled.
	self assert: browser lastCompileSource equals: 'foo ^ 1'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testBrowseClassInfoUsesRemoteClassMirrorMetadata [
	| browser session classes meta |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'superclassName').
		^ #(9001 'DemoClass' 'Object' 'Demo-Package' 'Demo-Category' 2 4) ].
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'DemoClass'.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: false.

	browser session: session.
	browser instVarNamed: 'classesList' put: classes.
	browser instVarNamed: 'metaCheckbox' put: meta.

	self assert: browser browseClassInfo.
	self assert: (browser lastInfoMessage includesSubstring: 'Class: DemoClass').
	self assert: (browser lastInfoMessage includesSubstring: 'Browser side: instance').
	self assert: (browser lastInfoMessage includesSubstring: 'Superclass: Object').
	self assert: (browser lastInfoMessage includesSubstring: 'Package: Demo-Package').
	self assert: (browser lastInfoMessage includesSubstring: 'Category: Demo-Category').
	self assert: (browser lastInfoMessage includesSubstring: 'Version: 2 of 4').
	self assert: (browser lastInfoMessage includesSubstring: 'OOP: 9001')
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testBrowseMethodInfoUsesRemoteMethodMirrorMetadata [
	| browser session classes methods meta |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'compiledMethodAt: #foo').
		^ #(9001 'DemoClass' 'foo' 'testing' 'foo ^ 1' 'Demo-Package' 'DemoClass>>foo' 1 2) ].
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'DemoClass'.
	methods := GbxFakeListPresenterForBrowser new.
	methods selectedItem: 'foo'.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: false.

	browser session: session.
	browser instVarNamed: 'classesList' put: classes.
	browser instVarNamed: 'methodsList' put: methods.
	browser instVarNamed: 'metaCheckbox' put: meta.

	self assert: browser browseMethodInfo.
	self assert: (browser lastInfoMessage includesSubstring: 'Method: DemoClass>>foo').
	self assert: (browser lastInfoMessage includesSubstring: 'Side: instance').
	self assert: (browser lastInfoMessage includesSubstring: 'Owner: DemoClass').
	self assert: (browser lastInfoMessage includesSubstring: 'Selector: foo').
	self assert: (browser lastInfoMessage includesSubstring: 'Binding: unbound').
	self assert: (browser lastInfoMessage includesSubstring: 'Arity: 0').
	self assert: (browser lastInfoMessage includesSubstring: 'Protocol: testing').
	self assert: (browser lastInfoMessage includesSubstring: 'Package: Demo-Package').
	self assert: (browser lastInfoMessage includesSubstring: 'Source location: DemoClass>>foo').
	self assert: (browser lastInfoMessage includesSubstring: 'Version: 1 of 2').
	self assert: (browser lastInfoMessage includesSubstring: 'OOP: 9001')
]

GbsBrowserCoreToolsTest >> testBrowseVersionsUsesRemoteMethodMirrorVersionEntries [
	| browser session classes methods meta text |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'respondsTo: #allVersionsOf:').
		self assert: (script includesSubstring: 'sel := #foo').
		^ {
			#('version 1' 'foo ^ 1').
			#('version 2' 'foo ^ 2') } ].
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'DemoClass'.
	methods := GbxFakeListPresenterForBrowser new.
	methods selectedItem: 'foo'.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: false.
	text := GbxFakeTextPresenterForBrowser new.

	browser session: session.
	browser instVarNamed: 'classesList' put: classes.
	browser instVarNamed: 'methodsList' put: methods.
	browser instVarNamed: 'metaCheckbox' put: meta.
	browser instVarNamed: 'sourceText' put: text.
	browser enqueueChooseAnswer: 2.

	self assert: browser browseVersions.
	self assert: text text equals: 'foo ^ 2'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testClassSelectedUsesRemoteClassMirrorProtocols [
	| browser session protocols methods text meta |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'behavior methodDict keys asSortedCollection').
		self deny: (script includesSubstring: 'behavior := cls class').
		^ {
			#('accessing' #('alpha' 'beta')).
			#('testing' #('gamma')) } ].
	protocols := GbxFakeListPresenterForBrowser new.
	methods := GbxFakeListPresenterForBrowser new.
	text := GbxFakeTextPresenterForBrowser new.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: false.

	browser session: session.
	browser instVarNamed: 'protocolsList' put: protocols.
	browser instVarNamed: 'methodsList' put: methods.
	browser instVarNamed: 'sourceText' put: text.
	browser instVarNamed: 'metaCheckbox' put: meta.

	browser classSelected: 'DemoClass'.

	self assert: protocols items asArray equals: #('-- all --' 'accessing' 'testing').
	self assert: methods items asArray equals: #().
	self assert: text text equals: ''
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testCompileMethodCompilesSelectedClassAndProtocol [
	| browser session classes protocols meta capturedScript |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script |
		capturedScript := script.
		'Success'
	].

	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'DemoClass'.
	protocols := GbxFakeListPresenterForBrowser new.
	protocols selectedItem: 'testing'.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: false.

	browser session: session.
	browser instVarNamed: 'classesList' put: classes.
	browser instVarNamed: 'protocolsList' put: protocols.
	browser instVarNamed: 'metaCheckbox' put: meta.

	browser runSuperCompileMethod: 'foo ^ 1'.
	self assert: (capturedScript includesSubstring: 'objectNamed: #DemoClass').
	self assert: (capturedScript includesSubstring: 'compileMethod: source category: #''testing''').
	self assert: browser lastInfoMessage equals: 'Compiled successfully!'.
	self assert: browser lastProtocolSelected equals: 'testing'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testGsDoItUsesSelectedTextOrWholeSource [
	| browser session text |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetchContext put: [ :script :ctx | 'ok' ].

	text := GbxFakeTextPresenterForBrowser new.
	text
		text: '1 + 1';
		selectedText: '2 + 2'.

	browser session: session.
	browser instVarNamed: 'sourceText' put: text.

	self assert: browser gsDoIt
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testGsPrintItAppendsResult [
	| browser session text |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetchContext put: [ :script :ctx | '42' ].

	text := GbxFakeTextPresenterForBrowser new.
	text text: '21+21'.

	browser session: session.
	browser instVarNamed: 'sourceText' put: text.

	self assert: browser gsPrintIt.
	self assert: (text text includesSubstring: '"42"')
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testInspectMethodUsesRemoteMethodMirror [
	| browser session classes methods meta |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'compiledMethodAt: #foo').
		^ #(9001 'DemoClass' 'foo' 'testing' 'foo ^ 1' 'Demo-Package' 'DemoClass>>foo' 1 2) ].
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'DemoClass'.
	methods := GbxFakeListPresenterForBrowser new.
	methods selectedItem: 'foo'.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: false.

	browser session: session.
	browser instVarNamed: 'classesList' put: classes.
	browser instVarNamed: 'methodsList' put: methods.
	browser instVarNamed: 'metaCheckbox' put: meta.

	self assert: browser inspectMethod.
	self assert: browser lastInspectedOop equals: 9001
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testInvokeSelectedMethodCallsClassSideMethodObject [
	| browser session classes methods meta capturedSelector capturedArguments capturedOop |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #new') ifTrue: [
			^ #(9002 'DemoClass class' 'new' 'instance creation' 'new ^ super new' 'Demo-Package' 'DemoClass class>>new' 1 2) ].
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(9001 'DemoClass' 'Object' 'Demo-Package' 'Demo-Category' 2 4) ].
		self fail ].
	session stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#created ].
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'DemoClass'.
	methods := GbxFakeListPresenterForBrowser new.
	methods selectedItem: 'new'.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: true.

	browser session: session.
	browser instVarNamed: 'classesList' put: classes.
	browser instVarNamed: 'methodsList' put: methods.
	browser instVarNamed: 'metaCheckbox' put: meta.

	self assert: browser invokeSelectedMethod.
	self assert: capturedSelector equals: #new.
	self assert: capturedArguments equals: #().
	self assert: capturedOop equals: 9001.
	self assert: (browser lastInfoMessage includesSubstring: '#created')
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testInvokeSelectedMethodPromptsForArguments [
	| browser session classes methods meta capturedSelector capturedArguments capturedOop |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #fromAmount:') ifTrue: [
			^ #(9003 'DemoMoney class' 'fromAmount:' 'instance creation' 'fromAmount: amount ^ self new' 'Demo-Package' 'DemoMoney class>>fromAmount:' 1 2) ].
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(9004 'DemoMoney' 'Object' 'Demo-Package' 'Demo-Category' 2 4) ].
		self fail ].
	session stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#created ].
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'DemoMoney'.
	methods := GbxFakeListPresenterForBrowser new.
	methods selectedItem: 'fromAmount:'.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: true.

	browser session: session.
	browser instVarNamed: 'classesList' put: classes.
	browser instVarNamed: 'methodsList' put: methods.
	browser instVarNamed: 'metaCheckbox' put: meta.
	browser enqueueRequestAnswer: '10'.

	self assert: browser invokeSelectedMethod.
	self assert: capturedSelector equals: #fromAmount:.
	self assert: capturedArguments equals: #(10).
	self assert: capturedOop equals: 9004
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testInvokeSelectedMethodRejectsInstanceSideMethods [
	| browser session classes methods meta |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'DemoClass'.
	methods := GbxFakeListPresenterForBrowser new.
	methods selectedItem: 'foo'.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: false.

	browser session: session.
	browser instVarNamed: 'classesList' put: classes.
	browser instVarNamed: 'methodsList' put: methods.
	browser instVarNamed: 'metaCheckbox' put: meta.

	self deny: browser invokeSelectedMethod.
	self assert: browser lastInfoMessage equals: 'Browser invocation only supports class-side methods. Use the debugger to bind an instance receiver.'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testLoadDictionariesUsesSessionFetchRemoteDictionaries [
	| browser session dictionaries |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #evaluate put: 'Globals, UserGlobals , Published'.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	dictionaries := GbxFakeListPresenterForBrowser new.

	browser session: session.
	browser instVarNamed: 'dictionariesList' put: dictionaries.

	browser loadDictionaries.

	self assert: dictionaries items asArray equals: #('Globals' 'UserGlobals' 'Published')
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testMethodSelectedUsesRemoteMethodMirrorSource [
	| browser session classes meta text |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'compiledMethodAt: #foo').
		^ #(9001 'DemoClass' 'foo' 'testing' 'foo ^ 1' 'Demo-Package' 'DemoClass>>foo' 1 2) ].
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'DemoClass'.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: false.
	text := GbxFakeTextPresenterForBrowser new.

	browser session: session.
	browser instVarNamed: 'classesList' put: classes.
	browser instVarNamed: 'metaCheckbox' put: meta.
	browser instVarNamed: 'sourceText' put: text.

	browser methodSelected: 'foo'.

	self assert: text text equals: 'foo ^ 1'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testOpenQueryResultsChoosesFromMultipleReferences [
	| browser |
	browser := CoreTestableGbsBrowser new.
	browser enqueueChooseAnswer: 2.

	self assert: (browser openQueryResults: #('Object>>initialize' 'Behavior>>initialize')).
	self assert: browser lastOpenedReference equals: 'Behavior>>initialize'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testProtocolSelectedUsesRemoteClassMirrorSelectors [
	| browser session classes methods meta |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script | self fail ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'behavior methodDict keys asSortedCollection').
		^ {
			#('accessing' #('alpha' 'beta')).
			#('testing' #('gamma')) } ].
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'DemoClass'.
	methods := GbxFakeListPresenterForBrowser new.
	meta := GbxFakeCheckBoxForBrowser new.
	meta state: false.

	browser session: session.
	browser instVarNamed: 'classesList' put: classes.
	browser instVarNamed: 'methodsList' put: methods.
	browser instVarNamed: 'metaCheckbox' put: meta.

	browser runSuperProtocolSelected: '-- all --'.
	self assert: methods items asArray equals: #('alpha' 'beta' 'gamma').

	browser runSuperProtocolSelected: 'testing'.
	self assert: methods items asArray equals: #('gamma')
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testQueryHierarchyImplementorsInSuperScope [
	| browser classes |
	browser := CoreTestableGbsBrowser new.
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'Object'.
	browser instVarNamed: 'classesList' put: classes.
	browser enqueueRequestAnswer: 'size'.
	browser queryResults: #('Object>>size') forMode: 'hierarchyImplementors'.

	self assert: (browser queryHierarchyImplementorsInScope: 'super').
	self assert: browser lastQueriedMode equals: 'hierarchyImplementors'.
	self assert: browser lastQueriedHierarchyScope equals: 'super'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testQueryHierarchyImplementorsUsesHierarchyMode [
	| browser classes |
	browser := CoreTestableGbsBrowser new.
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'Object'.
	browser instVarNamed: 'classesList' put: classes.
	browser enqueueRequestAnswer: 'size'.
	browser queryResults: #('Object>>size') forMode: 'hierarchyImplementors'.

	self assert: browser queryHierarchyImplementors.
	self assert: browser lastQueriedSelector equals: 'size'.
	self assert: browser lastQueriedMode equals: 'hierarchyImplementors'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testQueryHierarchyRequiresSelectedClass [
	| browser |
	browser := CoreTestableGbsBrowser new.
	browser enqueueRequestAnswer: 'size'.

	self deny: browser queryHierarchySenders.
	self assert: browser lastInfoMessage equals: 'Select a class first for hierarchy queries.'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testQueryHierarchySendersUsesHierarchyMode [
	| browser classes |
	browser := CoreTestableGbsBrowser new.
	classes := GbxFakeListPresenterForBrowser new.
	classes selectedItem: 'Object'.
	browser instVarNamed: 'classesList' put: classes.
	browser enqueueRequestAnswer: 'size'.
	browser queryResults: #('Object>>size') forMode: 'hierarchySenders'.

	self assert: browser queryHierarchySenders.
	self assert: browser lastQueriedSelector equals: 'size'.
	self assert: browser lastQueriedMode equals: 'hierarchySenders'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testQueryImplementorsUsesPromptAndOpensSingleResult [
	| browser |
	browser := CoreTestableGbsBrowser new.
	browser enqueueRequestAnswer: 'initialize'.
	browser queryResults: #('Object>>initialize') forMode: 'implementors'.

	self assert: browser queryImplementors.
	self assert: browser lastQueriedSelector equals: 'initialize'.
	self assert: browser lastQueriedMode equals: 'implementors'.
	self assert: browser lastOpenedReference equals: 'Object>>initialize'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testQueryMethodsWithStringUsesOpenQueryResultsPath [
	| browser session capturedScript |
	browser := CoreTestableGbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetch put: [ :script |
		capturedScript := script.
		'Object>>initialize', Character lf asString, 'Behavior>>initialize' ].
	browser session: session.
	browser enqueueRequestAnswer: 'init'.
	browser enqueueChooseAnswer: 1.

	self assert: browser queryMethodsWithString.
	self assert: (capturedScript includesSubstring: 'init').
	self assert: browser lastOpenedReference equals: 'Behavior>>initialize'
]

{ #category : 'tests' }
GbsBrowserCoreToolsTest >> testQueryServerMethodsWithExplicitRootClass [
	| browser session |
	browser := GbsBrowser new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'className := ''Object''').
		self assert: (script includesSubstring: 'objectNamed: className asSymbol').
		^ #('Object>>size') ].
	browser session: session.

	self assert: (browser queryServerMethodsForSelector: 'size' mode: 'hierarchyImplementors' rootClassName: 'Object') size equals: 1
]
