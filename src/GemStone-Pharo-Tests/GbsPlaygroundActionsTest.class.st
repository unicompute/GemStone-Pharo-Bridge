Class {
	#name : 'GbsPlaygroundActionsTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousSession'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsPlaygroundActionsTest >> setUp [
	super setUp.
	previousSession := GbsSessionParameters currentSession.
	TestableGbsPlaygroundActions resetHarness
]

{ #category : 'running' }
GbsPlaygroundActionsTest >> tearDown [
	GbsSessionParameters currentSession: previousSession.
	super tearDown
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsInspectItUsesExecuteScriptAndReturnOop [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	presenter selectedText: '42'.

	session stubs
		at: #executeScriptAndReturnOop
		put: [ :script |
			self assert: script equals: '42'.
			9001 ].
	session stubs
		at: #apiGciExecuteStrContextEnv
		put: [ :script :context :env |
			self fail: 'Playground inspectIt should use executeScriptAndReturnOop, not serverInterface.' ].
	GbsSessionParameters currentSession: session.

	TestableGbsPlaygroundActions gsInspectItIn: presenter.

	self assert: TestableGbsPlaygroundActions lastInspectedOop equals: 9001.
	self assert: TestableGbsPlaygroundActions lastInspectedSession == session
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsInspectSessionStateKeyRejectsNonNumericInput [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	GbsSessionParameters currentSession: session.
	TestableGbsPlaygroundActions enqueueRequestAnswer: 'abc'.

	self deny: (TestableGbsPlaygroundActions gsInspectSessionStateKeyIn: presenter).
	self assert: TestableGbsPlaygroundActions lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: TestableGbsPlaygroundActions lastInspectedOop isNil
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsInspectSessionStateKeyUsesSessionFacade [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	session stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: (script includesSubstring: 'key := 21').
			^ GbsProxy oop: 9701 session: session ].
	GbsSessionParameters currentSession: session.
	TestableGbsPlaygroundActions enqueueRequestAnswer: '21'.

	self assert: (TestableGbsPlaygroundActions gsInspectSessionStateKeyIn: presenter).
	self assert: TestableGbsPlaygroundActions lastInspectedOop equals: 9701.
	self assert: TestableGbsPlaygroundActions lastInspectedSession == session
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsBrowseRubyLoadPathReportUsesRuntimeReport [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: session.

	self assert: (TestableGbsPlaygroundActions gsBrowseRubyLoadPathReportIn: presenter).
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsBrowseRubyLoadedFeaturesReportUsesRuntimeReport [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default transientLoadedFeatures: 1'
			ifTrue: [ ^ #('json' 'set') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: session.

	self assert: (TestableGbsPlaygroundActions gsBrowseRubyLoadedFeaturesReportIn: presenter).
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'Loaded Features').
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'json')
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsBrowseRubyPersistentLoadedFeaturesReportUsesRuntimeReport [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default persistentLoadedFeatures: 1'
			ifTrue: [ ^ #('bigdecimal') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: session.

	self assert: (TestableGbsPlaygroundActions gsBrowseRubyPersistentLoadedFeaturesReportIn: presenter).
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'Persistent Loaded Features').
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'bigdecimal')
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsBrowseTypedWrapperLifecycleReportUsesSessionLifecycleReport [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	session stubs at: #typedWrapperLifecycleReportText put: [
		'Typed Wrapper Lifecycle', String cr, String cr, 'ClientThing' ].
	GbsSessionParameters currentSession: session.

	self assert: (TestableGbsPlaygroundActions gsBrowseTypedWrapperLifecycleReportIn: presenter).
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'Typed Wrapper Lifecycle').
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'ClientThing')
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsBrowseStaleTypedWrapperLifecycleReportUsesSessionLifecycleReport [
	| session presenter staleEntry |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
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
		GbsTypedWrapperLifecycleReport entries: { staleEntry } ].
	GbsSessionParameters currentSession: session.

	self assert: (TestableGbsPlaygroundActions gsBrowseStaleTypedWrapperLifecycleReportIn: presenter).
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'ClientThing').
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'stale')
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsBrowseTopLevelAutoloadRegistrationsReportUsesRuntimeReport [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:')
			ifTrue: [ ^ { #('DemoConst' 'demo/file' false nil) } ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: session.

	self assert: (TestableGbsPlaygroundActions gsBrowseTopLevelAutoloadRegistrationsReportIn: presenter).
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'Autoload Registrations').
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'DemoConst -> demo/file [Pending]')
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsBrowseSessionStateKeysReportUsesDiagnosticsFacade [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ (IdentityDictionary new at: #lazyThing put: 'registered'; yourself) ].
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].
	GbsSessionParameters currentSession: session.
	TestableGbsPlaygroundActions enqueueRequestAnswer: '19, 21'.

	self assert: (TestableGbsPlaygroundActions gsBrowseSessionStateKeysReportIn: presenter).
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry)').
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'Key 21 (Session State)')
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsBrowseObjectsInMemoryReportUsesDiagnosticsFacade [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _listInstancesInMemory:')
			ifTrue: [ ^ { GbsProxy oop: 9201 session: session. GbsProxy oop: 9202 session: session } ].
		self fail ].
	GbsSessionParameters currentSession: session.
	TestableGbsPlaygroundActions
		enqueueRequestAnswer: '1';
		enqueueRequestAnswer: '2'.

	self assert: (TestableGbsPlaygroundActions gsBrowseObjectsInMemoryReportIn: presenter).
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'Objects In Memory').
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'oop=9201')
]

{ #category : 'tests' }
GbsPlaygroundActionsTest >> testGsBrowseMaglevFinalizerRegistryReportUsesDiagnosticsFacade [
	| session presenter |
	session := MockGbsSession new.
	presenter := MockGbsPlaygroundPresenter new.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ GbsProxy oop: 9001 session: session ].
		(script includesSubstring: 'findReferencesInMemory') ifTrue: [
			^ { GbsProxy oop: 9101 session: session } ].
		self fail ].
	GbsSessionParameters currentSession: session.

	self assert: (TestableGbsPlaygroundActions gsBrowseMaglevFinalizerRegistryReportIn: presenter).
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'MagLev Finalizer Registry oop=9001 Referencers').
	self assert: (TestableGbsPlaygroundActions lastInfoMessage includesSubstring: 'oop=9101')
]
