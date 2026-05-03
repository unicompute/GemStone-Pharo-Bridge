Class {
	#name : 'GbxTrippyCoreToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbxTrippyCoreToolsTest >> testBrowseObjectsInMemoryReportUsesDiagnosticsFacade [
	| trippy session |
	trippy := CoreTestableGbxTrippy new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _listInstancesInMemory:')
			ifTrue: [ ^ { GbsProxy oop: 9201 session: session. GbsProxy oop: 9202 session: session } ].
		self fail ].

	trippy session: session.
	trippy
		enqueueRequestAnswer: '1';
		enqueueRequestAnswer: '2'.

	self assert: trippy browseObjectsInMemoryReport.
	self assert: (trippy lastInfoMessage includesSubstring: 'Objects In Memory').
	self assert: (trippy lastInfoMessage includesSubstring: 'oop=9201')
]

{ #category : 'tests' }
GbxTrippyCoreToolsTest >> testBrowsePromptedSessionStateKeyInformsWhenUnset [
	| trippy session |
	trippy := CoreTestableGbxTrippy new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ nil ].

	trippy session: session.
	trippy enqueueRequestAnswer: '21'.

	self deny: trippy browsePromptedSessionStateKey.
	self assert: trippy lastInfoMessage equals: 'Session state key 21 is not set.'.
	self assert: trippy lastOpenedOop isNil
]

{ #category : 'tests' }
GbxTrippyCoreToolsTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| trippy session |
	trippy := CoreTestableGbxTrippy new.
	session := CoreMockGbsSession new.
	trippy session: session.
	trippy enqueueRequestAnswer: 'abc'.

	self deny: trippy browsePromptedSessionStateKey.
	self assert: trippy lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: trippy lastOpenedOop isNil
]

{ #category : 'tests' }
GbxTrippyCoreToolsTest >> testBrowsePromptedSessionStateKeyUsesSessionAndOpensTrippy [
	| trippy session registry |
	trippy := CoreTestableGbxTrippy new.
	session := CoreMockGbsSession new.
	registry := GbsProxy oop: 8181 session: session.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ registry ].

	trippy session: session.
	trippy enqueueRequestAnswer: '21'.

	self assert: trippy browsePromptedSessionStateKey.
	self assert: trippy lastOpenedOop equals: 8181
]

{ #category : 'tests' }
GbxTrippyCoreToolsTest >> testBrowsePromptedSessionStateKeysReportUsesDiagnosticsFacade [
	| trippy session |
	trippy := CoreTestableGbxTrippy new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ (IdentityDictionary new at: #lazyThing put: 'registered'; yourself) ].
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].

	trippy session: session.
	trippy enqueueRequestAnswer: '19, 21'.

	self assert: trippy browsePromptedSessionStateKeysReport.
	self assert: (trippy lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry)').
	self assert: (trippy lastInfoMessage includesSubstring: 'Key 21 (Session State)')
]

{ #category : 'tests' }
GbxTrippyCoreToolsTest >> testBrowseReferencersInMemoryInformsWhenNoneFound [
	| trippy session |
	trippy := CoreTestableGbxTrippy new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script | #() ].

	trippy session: session.
	trippy instVarNamed: 'currentOop' put: 123.

	self deny: trippy browseReferencersInMemory.
	self assert: trippy lastInfoMessage equals: 'No in-memory referencers found.'
]

{ #category : 'tests' }
GbxTrippyCoreToolsTest >> testBrowseReferencersInMemoryUsesSessionFacadeAndOpensSingleResult [
	| trippy session table |
	trippy := CoreTestableGbxTrippy new.
	session := CoreMockGbsSession new.
	table := GbxFakeTablePresenterForRemoteDebugger new.
	table selectedItem: { 'child'. 'Array'. 'value'. 456 }.
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: session materializationProfile class equals: GbsShallowMaterializationProfile.
			self assert: script equals: '((Object _objectForOop: 456)) findReferencesInMemory asArray'.
			^ { GbsProxy oop: 9001 session: session } ].

	trippy session: session.
	trippy instVarNamed: 'currentOop' put: 123.
	trippy instVarNamed: 'objectTable' put: table.

	self assert: trippy browseReferencersInMemory.
	self assert: trippy lastOpenedOop equals: 9001
]

{ #category : 'tests' }
GbxTrippyCoreToolsTest >> testBrowseStaleTypedWrapperLifecycleReportUsesSessionLifecycleReport [
	| trippy session staleEntry |
	trippy := CoreTestableGbxTrippy new.
	session := CoreMockGbsSession new.
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
	session stubs at: #typedWrapperLifecycleReport put: [
		self assert: session materializationProfile class equals: GbsShallowMaterializationProfile.
		GbsTypedWrapperLifecycleReport entries: { staleEntry } ].

	trippy session: session.

	self assert: trippy browseStaleTypedWrapperLifecycleReport.
	self assert: (trippy lastInfoMessage includesSubstring: 'ClientThing').
	self assert: (trippy lastInfoMessage includesSubstring: 'stale')
]

{ #category : 'tests' }
GbxTrippyCoreToolsTest >> testGoBackAndForwardTrackNavigationHistory [
	| trippy |
	trippy := CoreTestableGbxTrippy new.

	trippy inspectOop: 10.
	trippy navigateTo: { 'child'. 'Array'. 'value'. 20 }.
	trippy navigateTo: { 'grandchild'. 'Array'. 'value'. 30 }.

	self assert: trippy currentOop equals: 30.
	self assert: (trippy instVarNamed: 'navigationStack') asArray equals: #(10 20 30).
	self assert: (trippy instVarNamed: 'forwardStack') isEmpty.

	trippy goBack.
	self assert: trippy currentOop equals: 20.
	self assert: (trippy instVarNamed: 'navigationStack') asArray equals: #(10 20).
	self assert: (trippy instVarNamed: 'forwardStack') asArray equals: #(30).

	trippy goForward.
	self assert: trippy currentOop equals: 30.
	self assert: (trippy instVarNamed: 'navigationStack') asArray equals: #(10 20 30).
	self assert: (trippy instVarNamed: 'forwardStack') isEmpty.
	self assert: trippy showCurrentObjectCalls equals: 5
]

{ #category : 'tests' }
GbxTrippyCoreToolsTest >> testNavigateToClearsForwardHistory [
	| trippy |
	trippy := CoreTestableGbxTrippy new.

	trippy inspectOop: 10.
	trippy navigateTo: { 'child'. 'Array'. 'value'. 20 }.
	trippy navigateTo: { 'grandchild'. 'Array'. 'value'. 30 }.
	trippy goBack.
	trippy navigateTo: { 'replacement'. 'Array'. 'value'. 40 }.

	self assert: trippy currentOop equals: 40.
	self assert: (trippy instVarNamed: 'navigationStack') asArray equals: #(10 20 40).
	self assert: (trippy instVarNamed: 'forwardStack') isEmpty
]
