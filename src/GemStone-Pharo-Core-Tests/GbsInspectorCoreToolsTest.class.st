Class {
	#name : 'GbsInspectorCoreToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbsInspectorCoreToolsTest >> testBrowsePromptedSessionStateKeyInformsWhenUnset [
	| inspector session |
	inspector := CoreTestableGbsInspector new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ nil ].

	inspector instVarNamed: 'session' put: session.
	inspector enqueueRequestAnswer: '21'.

	self deny: inspector browsePromptedSessionStateKey.
	self assert: inspector lastInfoMessage equals: 'Session state key 21 is not set.'.
	self assert: inspector lastOpenedOop isNil
]

{ #category : 'tests' }
GbsInspectorCoreToolsTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| inspector session |
	inspector := CoreTestableGbsInspector new.
	session := CoreMockGbsSession new.

	inspector instVarNamed: 'session' put: session.
	inspector enqueueRequestAnswer: 'abc'.

	self deny: inspector browsePromptedSessionStateKey.
	self assert: inspector lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: inspector lastOpenedOop isNil
]

{ #category : 'tests' }
GbsInspectorCoreToolsTest >> testBrowsePromptedSessionStateKeyUsesSessionAndOpensInspector [
	| inspector session registry |
	inspector := CoreTestableGbsInspector new.
	session := CoreMockGbsSession new.
	registry := GbsProxy oop: 8181 session: session.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'key := 21').
		^ registry ].

	inspector instVarNamed: 'session' put: session.
	inspector enqueueRequestAnswer: '21'.

	self assert: inspector browsePromptedSessionStateKey.
	self assert: inspector lastOpenedOop equals: 8181
]

{ #category : 'tests' }
GbsInspectorCoreToolsTest >> testBrowsePromptedSessionStateKeysReportUsesDiagnosticsFacade [
	| inspector session |
	inspector := CoreTestableGbsInspector new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ (IdentityDictionary new at: #lazyThing put: 'registered'; yourself) ].
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].

	inspector instVarNamed: 'session' put: session.
	inspector enqueueRequestAnswer: '19, 21'.

	self assert: inspector browsePromptedSessionStateKeysReport.
	self assert: (inspector lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry)').
	self assert: (inspector lastInfoMessage includesSubstring: 'Key 21 (Session State)')
]

{ #category : 'tests' }
GbsInspectorCoreToolsTest >> testBrowseObjectsInMemoryReportUsesDiagnosticsFacade [
	| inspector session |
	inspector := CoreTestableGbsInspector new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _listInstancesInMemory:')
			ifTrue: [ ^ { GbsProxy oop: 9201 session: session. GbsProxy oop: 9202 session: session } ].
		self fail ].

	inspector instVarNamed: 'session' put: session.
	inspector
		enqueueRequestAnswer: '1';
		enqueueRequestAnswer: '2'.

	self assert: inspector browseObjectsInMemoryReport.
	self assert: (inspector lastInfoMessage includesSubstring: 'Objects In Memory').
	self assert: (inspector lastInfoMessage includesSubstring: 'oop=9201')
]

{ #category : 'tests' }
GbsInspectorCoreToolsTest >> testBrowseStaleTypedWrapperLifecycleReportUsesSessionLifecycleReport [
	| inspector session staleEntry |
	inspector := CoreTestableGbsInspector new.
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

	inspector instVarNamed: 'session' put: session.

	self assert: inspector browseStaleTypedWrapperLifecycleReport.
	self assert: (inspector lastInfoMessage includesSubstring: 'ClientThing').
	self assert: (inspector lastInfoMessage includesSubstring: 'stale')
]

{ #category : 'tests' }
GbsInspectorCoreToolsTest >> testBrowseTypedWrapperLifecycleReportUsesSessionLifecycleText [
	| inspector session |
	inspector := CoreTestableGbsInspector new.
	session := CoreMockGbsSession new.
	session stubs at: #typedWrapperLifecycleReportText put: [
		self assert: session materializationProfile class equals: GbsShallowMaterializationProfile.
		'Typed Wrapper Lifecycle', String cr, String cr, 'No typed wrappers generated.' ].

	inspector instVarNamed: 'session' put: session.

	self assert: inspector browseTypedWrapperLifecycleReport.
	self assert: (inspector lastInfoMessage includesSubstring: 'Typed Wrapper Lifecycle')
]

{ #category : 'tests' }
GbsInspectorCoreToolsTest >> testSelectedInspectableOopPrefersSelectedTableRow [
	| inspector fakeTable |
	inspector := GbsInspector new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable selectedItem: { 'child'. 'aChild'. 456 }.

	inspector instVarNamed: 'oop' put: 123.
	inspector instVarNamed: 'stateTable' put: fakeTable.

	self assert: inspector selectedInspectableOop equals: 456
]

{ #category : 'tests' }
GbsInspectorCoreToolsTest >> testBrowseReferencersInMemoryUsesSessionFacadeAndOpensSingleResult [
	| inspector session fakeTable |
	inspector := CoreTestableGbsInspector new.
	session := CoreMockGbsSession new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable selectedItem: { 'child'. 'aChild'. 456 }.
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: session materializationProfile class equals: GbsShallowMaterializationProfile.
			self assert: script equals: '((Object _objectForOop: 456)) findReferencesInMemory asArray'.
			^ { GbsProxy oop: 9001 session: session } ].

	inspector instVarNamed: 'session' put: session.
	inspector instVarNamed: 'oop' put: 123.
	inspector instVarNamed: 'stateTable' put: fakeTable.

	self assert: inspector browseReferencersInMemory.
	self assert: inspector lastOpenedOop equals: 9001
]

{ #category : 'tests' }
GbsInspectorCoreToolsTest >> testBrowseReferencersInMemoryInformsWhenNoneFound [
	| inspector session |
	inspector := CoreTestableGbsInspector new.
	session := CoreMockGbsSession new.
	session stubs at: #executeScriptAndFetchObject put: [ :script | #() ].

	inspector instVarNamed: 'session' put: session.
	inspector instVarNamed: 'oop' put: 123.

	self deny: inspector browseReferencersInMemory.
	self assert: inspector lastInfoMessage equals: 'No in-memory referencers found.'
]

{ #category : 'tests' }
GbsInspectorCoreToolsTest >> testInvokeSelectedObjectMethodPromptsForSelectorAndArguments [
	| inspector session fakeTable capturedSelector capturedArguments capturedOop |
	inspector := CoreTestableGbsInspector new.
	session := CoreMockGbsSession new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable selectedItem: { 'child'. 'anInvoice'. 456 }.
	session stubs at: #executeAndFetch put: [ :script |
		self assert: (script includesSubstring: 'Object _objectForOop: 456').
		'Invoice' ].
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'compiledMethodAt: #applyDiscount:') ifTrue: [
			^ #(9004 'Invoice' 'applyDiscount:' 'pricing' 'applyDiscount: percent ^ total * percent' 'Billing-Core' 'Invoice>>applyDiscount:' 3 4) ].
		self fail ].
	session stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#discounted ].

	inspector instVarNamed: 'session' put: session.
	inspector instVarNamed: 'oop' put: 123.
	inspector instVarNamed: 'stateTable' put: fakeTable.
	inspector enqueueRequestAnswer: 'applyDiscount:'.
	inspector enqueueRequestAnswer: '15'.

	self assert: inspector invokeSelectedObjectMethod.
	self assert: capturedSelector equals: #applyDiscount:.
	self assert: capturedArguments equals: #(15).
	self assert: capturedOop equals: 456.
	self assert: (inspector lastInfoMessage includesSubstring: '#discounted')
]
