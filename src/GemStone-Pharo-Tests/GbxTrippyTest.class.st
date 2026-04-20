Class {
	#name : 'GbxTrippyTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbxTrippyTest >> testGoBackAndForwardTrackNavigationHistory [
	| trippy |
	trippy := GbxTestableTrippy new.

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
GbxTrippyTest >> testNavigateToClearsForwardHistory [
	| trippy |
	trippy := GbxTestableTrippy new.

	trippy inspectOop: 10.
	trippy navigateTo: { 'child'. 'Array'. 'value'. 20 }.
	trippy navigateTo: { 'grandchild'. 'Array'. 'value'. 30 }.
	trippy goBack.
	trippy navigateTo: { 'replacement'. 'Array'. 'value'. 40 }.

	self assert: trippy currentOop equals: 40.
	self assert: (trippy instVarNamed: 'navigationStack') asArray equals: #(10 20 40).
	self assert: (trippy instVarNamed: 'forwardStack') isEmpty
]

{ #category : 'tests' }
GbxTrippyTest >> testBrowseReferencersInMemoryUsesSessionFacadeAndOpensSingleResult [
	| trippy session table |
	trippy := GbxTestableTrippy new.
	session := MockGbsSession new.
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
GbxTrippyTest >> testBrowseReferencersInMemoryInformsWhenNoneFound [
	| trippy session |
	trippy := GbxTestableTrippy new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script | #() ].

	trippy session: session.
	trippy instVarNamed: 'currentOop' put: 123.

	self deny: trippy browseReferencersInMemory.
	self assert: trippy lastInfoMessage equals: 'No in-memory referencers found.'
]

{ #category : 'tests' }
GbxTrippyTest >> testBrowsePromptedSessionStateKeyInformsWhenUnset [
	| trippy session |
	trippy := GbxTestableTrippy new.
	session := MockGbsSession new.
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
GbxTrippyTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| trippy session |
	trippy := GbxTestableTrippy new.
	session := MockGbsSession new.
	trippy session: session.
	trippy enqueueRequestAnswer: 'abc'.

	self deny: trippy browsePromptedSessionStateKey.
	self assert: trippy lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: trippy lastOpenedOop isNil
]

{ #category : 'tests' }
GbxTrippyTest >> testBrowsePromptedSessionStateKeyUsesSessionAndOpensTrippy [
	| trippy session registry |
	trippy := GbxTestableTrippy new.
	session := MockGbsSession new.
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
GbxTrippyTest >> testBrowseRubyLoadPathReportUsesRuntimeReport [
	| trippy session |
	trippy := GbxTestableTrippy new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: session materializationProfile class equals: GbsShallowMaterializationProfile.
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].

	trippy session: session.

	self assert: trippy browseRubyLoadPathReport.
	self assert: (trippy lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (trippy lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbxTrippyTest >> testBrowseStaleTypedWrapperLifecycleReportUsesSessionLifecycleReport [
	| trippy session staleEntry |
	trippy := GbxTestableTrippy new.
	session := MockGbsSession new.
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
GbxTrippyTest >> testBrowsePromptedSessionStateKeysReportUsesDiagnosticsFacade [
	| trippy session |
	trippy := GbxTestableTrippy new.
	session := MockGbsSession new.
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
GbxTrippyTest >> testBrowseObjectsInMemoryReportUsesDiagnosticsFacade [
	| trippy session |
	trippy := GbxTestableTrippy new.
	session := MockGbsSession new.
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
GbxTrippyTest >> testBrowseMaglevFinalizerRegistryReportUsesDiagnosticsFacade [
	| trippy session |
	trippy := GbxTestableTrippy new.
	session := MockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ GbsProxy oop: 9001 session: session ].
		(script includesSubstring: 'findReferencesInMemory') ifTrue: [
			^ { GbsProxy oop: 9101 session: session } ].
		self fail ].

	trippy session: session.

	self assert: trippy browseMaglevFinalizerRegistryReport.
	self assert: (trippy lastInfoMessage includesSubstring: 'MagLev Finalizer Registry oop=9001 Referencers').
	self assert: (trippy lastInfoMessage includesSubstring: 'oop=9101')
]
