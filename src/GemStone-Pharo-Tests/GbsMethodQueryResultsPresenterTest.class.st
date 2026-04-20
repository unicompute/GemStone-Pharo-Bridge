Class {
	#name : 'GbsMethodQueryResultsPresenterTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testNormalizeReferencesFromMultilineStringWritesTranscript [
	| presenter raw normalized |
	presenter := GbsMethodQueryResultsPresenter new.
	raw := 'Object>>size', Character lf asString, 'Behavior>>new'.
	normalized := presenter normalizeReferences: raw.

	Transcript
		show: 'GbsMethodQueryResultsPresenterTest normalize multiline rawCount=2 normalizedCount=';
		show: normalized size asString;
		show: ' first=';
		show: (normalized ifEmpty: [ '<empty>' ] ifNotEmpty: [ normalized first asString ]);
		cr.

	self assert: normalized size equals: 2.
	self assert: (normalized includes: 'Object>>size').
	self assert: (normalized includes: 'Behavior>>new')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testNormalizeReferencesFromTabbedRowsWritesTranscript [
	| presenter rows normalized |
	presenter := GbsMethodQueryResultsPresenter new.
	rows := {
		'1', Character tab asString, 'Object', Character tab asString, 'size'.
		'2', Character tab asString, 'Behavior', Character tab asString, 'new'
	}.
	normalized := presenter normalizeReferences: rows.

	Transcript
		show: 'GbsMethodQueryResultsPresenterTest normalize tabbed rowCount=';
		show: rows size asString;
		show: ' normalizedCount=';
		show: normalized size asString;
		show: ' values=';
		show: normalized printString;
		cr.

	self assert: normalized size equals: 2.
	self assert: (normalized includes: 'Object>>size').
	self assert: (normalized includes: 'Behavior>>new')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testClassicLauncherQueryOrganizerParsesRowsWritesTranscript [
	| session results |
	session := MockGbsSession new.
	session stubs
		at: #executeAndFetch
		put: [ :script |
			'Object>>size', Character lf asString, 'Behavior>>new' ].

	results := GbsClassicLauncher
		queryOrganizerMethodsFor: 'size'
		mode: 'implementors'
		inSession: session.

	Transcript
		show: 'GbsMethodQueryResultsPresenterTest launcher query resultsCount=';
		show: results size asString;
		show: ' values=';
		show: results printString;
		cr.

	self assert: results size equals: 2.
	self assert: (results includes: 'Object>>size').
	self assert: (results includes: 'Behavior>>new')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testClassicLauncherReferencesQueryUsesSessionReferenceStrings [
	| session results |
	session := MockGbsSession new.
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
GbsMethodQueryResultsPresenterTest >> testClassicLauncherSelectorQueriesUseSessionReferenceStrings [
	| session implementors senders |
	session := MockGbsSession new.
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
GbsMethodQueryResultsPresenterTest >> testQueryResultsTitleIncludesSessionAndCount [
	| presenter session title |
	presenter := GbsMethodQueryResultsPresenter new.
	session := GbsSession new.
	session sessionId: 7.
	presenter session: session.

	title := presenter
		queryResultsTitleForSelector: 'size'
		modePrefix: 'Implementors of '
		count: 71.

	self assert: title equals: 'Session 7 Implementors of size (71)'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testQueryResultsTitleWithoutSessionId [
	| presenter title |
	presenter := GbsMethodQueryResultsPresenter new.
	presenter session: Object new.

	title := presenter
		queryResultsTitleForSelector: 'size'
		modePrefix: 'Senders of '
		count: 3.

	self assert: title equals: 'Senders of size (3)'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseHierarchySendersUsesFullScope [
	| presenter |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	presenter selectedReference: 'Object>>size'.

	self assert: presenter browseHierarchySendersOfSelected.
	self assert: presenter lastMode equals: 'hierarchySenders'.
	self assert: presenter lastPrefix equals: 'Hierarchy Senders of '.
	self assert: presenter lastScope equals: 'full'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseHierarchySendersUsesExplicitScope [
	| presenter |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	presenter selectedReference: 'Object>>size'.

	self assert: (presenter browseHierarchySendersOfSelectedInScope: 'sub').
	self assert: presenter lastMode equals: 'hierarchySenders'.
	self assert: presenter lastPrefix equals: 'Hierarchy Senders of '.
	self assert: presenter lastScope equals: 'sub'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseHierarchyImplementorsUsesFullScope [
	| presenter |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	presenter selectedReference: 'Object>>size'.

	self assert: presenter browseHierarchyImplementorsOfSelected.
	self assert: presenter lastMode equals: 'hierarchyImplementors'.
	self assert: presenter lastPrefix equals: 'Hierarchy Implementors of '.
	self assert: presenter lastScope equals: 'full'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseHierarchyImplementorsUsesExplicitScope [
	| presenter |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	presenter selectedReference: 'Object>>size'.

	self assert: (presenter browseHierarchyImplementorsOfSelectedInScope: 'super').
	self assert: presenter lastMode equals: 'hierarchyImplementors'.
	self assert: presenter lastPrefix equals: 'Hierarchy Implementors of '.
	self assert: presenter lastScope equals: 'super'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseReferencesUsesSelectedOwnerClassName [
	| presenter |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	presenter selectedReference: 'Object class>>new'.

	self assert: presenter browseReferencesToSelectedClass.
	self assert: presenter lastReferenceClassName equals: 'Object'
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	presenter session: session.
	presenter enqueueRequestAnswer: 'abc'.

	self deny: presenter browsePromptedSessionStateKey.
	self assert: presenter lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: presenter lastInspectedOop isNil
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowsePromptedSessionStateKeyUsesSessionFacade [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ GbsProxy oop: 9401 session: session ].
	presenter session: session.
	presenter enqueueRequestAnswer: '21'.

	self assert: presenter browsePromptedSessionStateKey.
	self assert: presenter lastInspectedOop equals: 9401
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseRubyLoadPathReportUsesRuntimeReport [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseRubyLoadPathReport.
	self assert: (presenter lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (presenter lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseRubyLoadedFeaturesReportUsesRuntimeReport [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default transientLoadedFeatures: 1'
			ifTrue: [ ^ #('json' 'set') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseRubyLoadedFeaturesReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Loaded Features').
	self assert: (presenter lastInfoMessage includesSubstring: 'json')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseRubyPersistentLoadedFeaturesReportUsesRuntimeReport [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default persistentLoadedFeatures: 1'
			ifTrue: [ ^ #('bigdecimal') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseRubyPersistentLoadedFeaturesReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Persistent Loaded Features').
	self assert: (presenter lastInfoMessage includesSubstring: 'bigdecimal')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseTopLevelAutoloadRegistrationsReportUsesRuntimeReport [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:')
			ifTrue: [ ^ { #('DemoConst' nil false nil 'demo/persistent_file' true true) } ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseTopLevelAutoloadRegistrationsReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Autoload Registrations').
	self assert: (presenter lastInfoMessage includesSubstring: 'DemoConst -> demo/persistent_file [Pending] {Transient+Persistent}')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseRubyRuntimeProvenanceGraphUsesRuntimeReport [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:') ifTrue: [ ^ #() ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseRubyRuntimeProvenanceGraph.
	self assert: (presenter lastInfoMessage includesSubstring: 'Ruby Runtime Provenance').
	self assert: (presenter lastInfoMessage includesSubstring: 'Transient Feature -> app/models/invoice.rb')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseRubyRuntimeProvenanceBrowserOpensStructuredGraph [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:') ifTrue: [ ^ #() ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.

	self assert: presenter browseRubyRuntimeProvenanceBrowser.
	self assert: presenter lastInfoMessage equals: 'Ruby Runtime Provenance'.
	self assert: presenter lastProvenanceGraph notNil.
	self assert: presenter lastProvenanceGraph browserRows size > 0
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseRubyRuntimeProvenanceActionChooserExecutesSelectedAction [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('app/models/invoice.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:') ifTrue: [ ^ #() ].
		(script includesSubstring: 'RubyContext default requireFileNamed: ''app/models/invoice.rb'' env: 1')
			ifTrue: [ ^ 'required' ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	presenter session: session.
	presenter enqueueChooseAnswer: 1.

	self assert: presenter browseRubyRuntimeProvenanceActionChooser.
	self assert: (presenter lastInfoMessage includesSubstring: 'Executed require app/models/invoice.rb => ''required''').
	self assert: (presenter lastInfoMessage includesSubstring: 'Ruby Runtime Provenance')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseSelectedMethodInfoUsesUnboundMethodObjectMetadata [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
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
GbsMethodQueryResultsPresenterTest >> testBrowseStaleTypedWrapperLifecycleReportUsesStaleEntries [
	| presenter session stale current |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
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
GbsMethodQueryResultsPresenterTest >> testBrowsePromptedSessionStateKeysReportUsesDiagnosticsReport [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
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
GbsMethodQueryResultsPresenterTest >> testBrowseObjectsInMemoryReportUsesDiagnosticsReport [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
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
GbsMethodQueryResultsPresenterTest >> testBrowseMaglevFinalizerRegistryReportUsesDiagnosticsReport [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ GbsProxy oop: 9191 session: session ].
		(script includesSubstring: 'findReferencesInMemory')
			ifTrue: [ ^ { GbsProxy oop: 9292 session: session } ].
		self fail ].
	presenter session: session.

	self assert: presenter browseMaglevFinalizerRegistryReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'MagLev Finalizer Registry oop=9191 Referencers').
	self assert: (presenter lastInfoMessage includesSubstring: 'oop=9292')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testShowSourceForReferenceUsesRemoteMethodMirrorSource [
	| presenter session text |
	presenter := GbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
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
GbsMethodQueryResultsPresenterTest >> testBrowseSelectedReferenceUsesMethodObjectWhenQueryPresent [
	| presenter session query |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
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
GbsMethodQueryResultsPresenterTest >> testShowSourceForClassSideReferenceUsesRemoteMethodMirrorSource [
	| presenter session text |
	presenter := GbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
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
GbsMethodQueryResultsPresenterTest >> testInspectSelectedMethodUsesMethodObjectOop [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
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
GbsMethodQueryResultsPresenterTest >> testInvokeSelectedMethodPromptsForArguments [
	| presenter session capturedSelector capturedArguments capturedOop |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
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

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseNamedObjectCacheReportUsesSessionCacheText [
	| presenter session cache |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session instVarNamed: 'namedObjectCache' put: cache.

	presenter session: session.

	self assert: presenter browseNamedObjectCacheReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Named Object Cache').
	self assert: (presenter lastInfoMessage includesSubstring: 'UserGlobals -> oop 9001')
]

{ #category : 'tests' }
GbsMethodQueryResultsPresenterTest >> testBrowseTypedWrapperAutoloadReportUsesPresenterSessionRegistry [
	| presenter session |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
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
GbsMethodQueryResultsPresenterTest >> testClearNamedObjectCacheClearsSessionCache [
	| presenter session cache |
	presenter := TestableGbsMethodQueryResultsPresenter new.
	session := MockGbsSession new.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session instVarNamed: 'namedObjectCache' put: cache.

	presenter session: session.

	self assert: presenter clearNamedObjectCache.
	self assert: presenter lastInfoMessage equals: 'Named object cache cleared.'.
	self assert: session namedObjectCacheKeys equals: #()
]
