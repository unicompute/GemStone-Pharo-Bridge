Class {
	#name : 'GbsSymbolListBrowserPresenterCoreToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListCapabilityPredicatesTrackSelectionState [
	| presenter fakeUsers fakeDicts fakeEntries |
	presenter := GbsSymbolListBrowserPresenter new.
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeEntries := GbxFakeListPresenterForBrowser new.

	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.

	self deny: presenter canOperateOnSelectedUser.
	self deny: presenter canOperateOnSelectedDictionary.
	self deny: presenter canOperateOnSelectedEntry.

	fakeUsers selectedItem: 'DataCurator'.
	self assert: presenter canOperateOnSelectedUser.
	self deny: presenter canOperateOnSelectedDictionary.

	fakeDicts selectedItem: 'UserGlobals'.
	self assert: presenter canOperateOnSelectedDictionary.
	self deny: presenter canOperateOnSelectedEntry.

	fakeEntries selectedItem: 'MyKey'.
	self assert: presenter canOperateOnSelectedEntry
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListParsedStructuredPreviewMaterializesCollectionRows [
	| presenter result |
	presenter := GbsSymbolListBrowserPresenter new.

	result := presenter parsedStructuredPreviewFrom: 'collection', String lf, '1', Character tab asString, 'alpha', String lf, '2', Character tab asString, 'beta'.

	self assert: (result at: #kind) equals: 'collection'.
	self assert: (result at: #rows) equals: { { '1'. 'alpha' }. { '2'. 'beta' } }
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListParsedStructuredPreviewMaterializesDictionaryRows [
	| presenter result |
	presenter := GbsSymbolListBrowserPresenter new.

	result := presenter parsedStructuredPreviewFrom: 'dictionary', String lf, 'users', Character tab asString, '#(''alice'' ''bob'')', String lf, 'count', Character tab asString, '2'.

	self assert: (result at: #kind) equals: 'dictionary'.
	self assert: (result at: #rows) equals: { { 'users'. '#(''alice'' ''bob'')' }. { 'count'. '2' } }
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListParsedStructuredPreviewTreatsPlainStringsAsScalarRows [
	| presenter result |
	presenter := GbsSymbolListBrowserPresenter new.

	result := presenter parsedStructuredPreviewFrom: 'string', String lf, 'plain text value'.

	self assert: (result at: #kind) equals: 'string'.
	self assert: (result at: #rows) equals: { { 'Value'. 'plain text value' } }.
	self assert: (result at: #value) equals: 'plain text value'
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListShowEntryForKeyPopulatesStructuredPreviewRows [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeSelection fakeValue |
	presenter := GbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: 'entryKey := dict keys detect:')
			ifTrue: [ ^ 'dictionary', String lf, 'mediaAssets', Character tab asString, 'aDictionary()', String lf, 'users', Character tab asString, 'aDictionary(...)' ].
		'' ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'UserGlobals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeEntries selectedItem: 'OkzZuluSeasideState'.
	fakeSelection := GbxFakeTextPresenterForRemoteDebugger new.
	fakeValue := GbxFakeListPresenterForBrowser new.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'selectionField' put: fakeSelection.
	presenter instVarNamed: 'valueText' put: fakeValue.

	presenter showEntryForKey: 'OkzZuluSeasideState'.

	self assert: fakeSelection text equals: 'OkzZuluSeasideState'.
	self assert: fakeValue items equals: { { 'mediaAssets'. 'aDictionary()' }. { 'users'. 'aDictionary(...)' } }
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListCanOperateOnSelectedPreviewRowRequiresStructuredSelection [
	| presenter fakeValue |
	presenter := GbsSymbolListBrowserPresenter new.
	fakeValue := GbxFakeTablePresenterForRemoteDebugger new.
	fakeValue selectedItem: { 'mediaAssets'. 'aDictionary()' }.

	presenter instVarNamed: 'valueText' put: fakeValue.
	presenter instVarNamed: 'currentPreview' put: (Dictionary new at: #kind put: 'dictionary'; yourself).
	self assert: presenter canOperateOnSelectedPreviewRow.

	presenter instVarNamed: 'currentPreview' put: (Dictionary new at: #kind put: 'string'; yourself).
	self deny: presenter canOperateOnSelectedPreviewRow
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListStructuredPreviewForSelectedPreviewRowUsesSelectedRowLabel [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeValue result |
	presenter := GbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: 'path := #((''dictionary'' ''users''))')
			ifTrue: [ ^ 'collection', String lf, '1', Character tab asString, 'alice', String lf, '2', Character tab asString, 'bob' ].
		'' ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'UserGlobals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeEntries selectedItem: 'OkzZuluSeasideState'.
	fakeValue := GbxFakeTablePresenterForRemoteDebugger new.
	fakeValue selectedItem: { 'users'. 'aDictionary(...)' }.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'valueText' put: fakeValue.
	presenter instVarNamed: 'currentPreview' put: (Dictionary new at: #kind put: 'dictionary'; yourself).

	result := presenter structuredPreviewForSelectedPreviewRowInEntryKey: 'OkzZuluSeasideState'.

	self assert: (result at: #kind) equals: 'collection'.
	self assert: (result at: #rows) equals: { { '1'. 'alice' }. { '2'. 'bob' } }
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListBrowseReferencersForSelectedEntryUsesSessionFacadeAndOpensSingleResult [
	| presenter mockSession fakeUsers fakeDicts fakeEntries |
	presenter := CoreTestableGbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		self assert: (script includesSubstring: '(Reflection oopOf: value) asString').
		self assert: (script includesSubstring: 'each asString = ''OkzZuluSeasideState''').
		'9001' ].
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: mockSession materializationProfile class equals: GbsShallowMaterializationProfile.
		self assert: script equals: '((Object _objectForOop: 9001)) findReferencesInMemory asArray'.
		^ { GbsProxy oop: 9100 session: mockSession } ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'UserGlobals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeEntries selectedItem: 'OkzZuluSeasideState'.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.

	self assert: presenter browseReferencersForSelectedEntry.
	self assert: presenter lastOpenedOop equals: 9100
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListBrowseSessionStateAtKeyUsesSessionFacadeAndOpensInspector [
	| presenter mockSession |
	presenter := CoreTestableGbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ GbsProxy oop: 9201 session: mockSession ].

	presenter instVarNamed: 'session' put: mockSession.

	self assert: (presenter browseSessionStateAtKey: 21).
	self assert: presenter lastOpenedOop equals: 9201
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| presenter mockSession |
	presenter := CoreTestableGbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.

	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueRequestAnswer: 'abc'.

	self deny: presenter browsePromptedSessionStateKey.
	self assert: presenter lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: presenter lastOpenedOop isNil
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListBrowsePromptedSessionStateKeyUsesPromptedValue [
	| presenter mockSession |
	presenter := CoreTestableGbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ GbsProxy oop: 9301 session: mockSession ].

	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueRequestAnswer: '21'.

	self assert: presenter browsePromptedSessionStateKey.
	self assert: presenter lastOpenedOop equals: 9301
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListBrowseStaleTypedWrapperLifecycleReportShowsStaleEntries [
	| presenter mockSession staleEntry |
	presenter := CoreTestableGbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	staleEntry := GbsTypedWrapperLifecycleEntry
		wrapperClass: nil
		clientName: 'ClientThing'
		serverName: 'ServerThing'
		source: 'autoload'
		localVersion: 1
		localNumberOfVersions: 1
		remoteVersion: 2
		remoteNumberOfVersions: 2
		status: #stale.
	mockSession stubs at: #typedWrapperLifecycleReport put: [
		GbsTypedWrapperLifecycleReport entries: { staleEntry } ].

	presenter instVarNamed: 'session' put: mockSession.

	self assert: presenter browseStaleTypedWrapperLifecycleReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'ClientThing').
	self assert: (presenter lastInfoMessage includesSubstring: 'stale')
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListBrowsePromptedSessionStateKeysReportUsesDiagnosticsFacade [
	| presenter mockSession |
	presenter := CoreTestableGbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ (IdentityDictionary new at: #lazyThing put: 'registered'; yourself) ].
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].

	presenter instVarNamed: 'session' put: mockSession.
	presenter enqueueRequestAnswer: '19, 21'.

	self assert: presenter browsePromptedSessionStateKeysReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry)').
	self assert: (presenter lastInfoMessage includesSubstring: 'Key 21 (Session State)')
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListBrowseObjectsInMemoryReportUsesDiagnosticsFacade [
	| presenter mockSession |
	presenter := CoreTestableGbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _listInstancesInMemory:')
			ifTrue: [ ^ { GbsProxy oop: 9201 session: mockSession. GbsProxy oop: 9202 session: mockSession } ].
		self fail ].

	presenter instVarNamed: 'session' put: mockSession.
	presenter
		enqueueRequestAnswer: '1';
		enqueueRequestAnswer: '2'.

	self assert: presenter browseObjectsInMemoryReport.
	self assert: (presenter lastInfoMessage includesSubstring: 'Objects In Memory').
	self assert: (presenter lastInfoMessage includesSubstring: 'oop=9201')
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListBrowseReferencersForSelectedPreviewValueUsesNestedPath [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeValue |
	presenter := CoreTestableGbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		self assert: (script includesSubstring: 'path := #((''dictionary'' ''users''))').
		'9002' ].
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: script equals: '((Object _objectForOop: 9002)) findReferencesInMemory asArray'.
		^ { GbsProxy oop: 9200 session: mockSession } ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'UserGlobals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeEntries selectedItem: 'OkzZuluSeasideState'.
	fakeValue := GbxFakeTablePresenterForRemoteDebugger new.
	fakeValue selectedItem: { 'users'. 'aDictionary(...)' }.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'valueText' put: fakeValue.
	presenter instVarNamed: 'currentPreview' put: (Dictionary new at: #kind put: 'dictionary'; yourself).

	self assert: presenter browseReferencersForSelectedPreviewValue.
	self assert: presenter lastOpenedOop equals: 9200
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListRefreshDictionariesPreservesSelectedDictionary [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeSelection fakeValue |
	presenter := GbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #evaluate put: [ :script |
		(script includesSubstring: 'symbolList')
			ifTrue: [ ^ 'UserGlobals', Character tab asString, 'Globals', Character tab asString, 'Published' ].
		'' ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'Globals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeSelection := GbxFakeTextPresenterForRemoteDebugger new.
	fakeValue := GbxFakeListPresenterForBrowser new.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'selectionField' put: fakeSelection.
	presenter instVarNamed: 'valueText' put: fakeValue.

	presenter refreshDictionariesFor: 'DataCurator'.

	self assert: fakeDicts selectedItem equals: 'Globals'
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListRefreshEntriesPreservesSelectedEntry [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeSelection fakeValue |
	presenter := GbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #evaluate put: [ :script |
		(script includesSubstring: 'keys asSortedCollection')
			ifTrue: [ ^ 'KeyA', Character tab asString, '1', String lf, 'KeyB', Character tab asString, '2' ].
		'' ].
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: 'each asString = ''KeyB''')
			ifTrue: [ ^ 'dictionary', String lf, 'users', Character tab asString, 'aDictionary(...)' ].
		'' ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeUsers selectedItem: 'DataCurator'.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeDicts selectedItem: 'UserGlobals'.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeEntries selectedItem: 'KeyB'.
	fakeSelection := GbxFakeTextPresenterForRemoteDebugger new.
	fakeValue := GbxFakeTablePresenterForRemoteDebugger new.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'selectionField' put: fakeSelection.
	presenter instVarNamed: 'valueText' put: fakeValue.

	presenter refreshEntriesForDictionary: 'UserGlobals'.

	self assert: fakeEntries selectedItem equals: 'KeyB'.
	self assert: fakeSelection text equals: 'KeyB'.
	self assert: fakeValue items equals: { { 'users'. 'aDictionary(...)' } }
]

{ #category : 'tests' }
GbsSymbolListBrowserPresenterCoreToolsTest >> testSymbolListRefreshUsersShowsSelectedDictionaryValuesOnOpen [
	| presenter mockSession fakeUsers fakeDicts fakeEntries fakeSelection fakeValue |
	presenter := GbsSymbolListBrowserPresenter new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #evaluate put: [ :script |
		self assert: mockSession materializationProfile class equals: GbsShallowMaterializationProfile.
		(script includesSubstring: 'users do:')
			ifTrue: [ ^ 'DataCurator', Character tab asString, 'SystemUser' ].
		(script includesSubstring: '1 to: sl size do:')
			ifTrue: [ ^ 'UserGlobals', Character tab asString, 'Globals' ].
		(script includesSubstring: 'keys asSortedCollection')
			ifTrue: [ ^ 'OkzZuluSeasideState', Character tab asString, 'aDictionary(...)', String lf, 'OtherEntry', Character tab asString, '123' ].
		'' ].
	mockSession stubs at: #executeAndFetch put: [ :script |
		self assert: mockSession materializationProfile class equals: GbsShallowMaterializationProfile.
		(script includesSubstring: 'each asString = ''OkzZuluSeasideState''')
			ifTrue: [ ^ 'dictionary', String lf, 'users', Character tab asString, 'aDictionary(...)', String lf, 'events', Character tab asString, 'aDictionary(...)' ].
		'' ].
	fakeUsers := GbxFakeListPresenterForBrowser new.
	fakeDicts := GbxFakeListPresenterForBrowser new.
	fakeEntries := GbxFakeListPresenterForBrowser new.
	fakeSelection := GbxFakeTextPresenterForRemoteDebugger new.
	fakeValue := GbxFakeTablePresenterForRemoteDebugger new.

	presenter instVarNamed: 'session' put: mockSession.
	presenter instVarNamed: 'targetUserName' put: 'DataCurator'.
	presenter instVarNamed: 'userDropList' put: fakeUsers.
	presenter instVarNamed: 'dictionariesList' put: fakeDicts.
	presenter instVarNamed: 'entriesList' put: fakeEntries.
	presenter instVarNamed: 'selectionField' put: fakeSelection.
	presenter instVarNamed: 'valueText' put: fakeValue.

	presenter refreshUsers.

	self assert: fakeUsers selectedItem equals: 'DataCurator'.
	self assert: fakeDicts selectedItem equals: 'UserGlobals'.
	self assert: fakeEntries selectedItem equals: 'OkzZuluSeasideState'.
	self assert: fakeSelection text equals: 'OkzZuluSeasideState'.
	self assert: fakeValue items equals: { { 'users'. 'aDictionary(...)' }. { 'events'. 'aDictionary(...)' } }
]
