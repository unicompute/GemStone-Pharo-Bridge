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
