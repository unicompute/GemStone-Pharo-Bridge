Class {
	#name : 'GbsWorkspaceTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousSession'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsWorkspaceTest >> setUp [
	super setUp.
	previousSession := GbsSessionParameters currentSession
]

{ #category : 'running' }
GbsWorkspaceTest >> tearDown [
	GbsSessionParameters currentSession: previousSession.
	super tearDown
]

{ #category : 'tests' }
GbsWorkspaceTest >> testDoItHandlesGemStoneError [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	
	"1. Give the workspace code so it doesn't exit early"
	workspace textEditor text: '1 / 0'.
	
	"2. Inject our manual mock session globally"
	mockSession stubs
		at: #execute
		put: [ :script |
			(GbsError new
				messageText: 'boom';
				tag: 20;
				serverProcessOop: 222;
				exceptionOop: 333;
				yourself) signal ].
	GbsSessionParameters currentSession: mockSession.
	
	"3. Action: Run the workspace evaluation"
	workspace doIt.
	
	"4. Assertion: Verify the error was caught and routed to the debugger method"
	self assert: workspace debuggerOpened.
	self assert: workspace lastOpenedProcessOop equals: 222.
]

{ #category : 'tests' }
GbsWorkspaceTest >> testDoItPrefersServerProcessOopOverTag [
	| workspace mockSession |

	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	workspace textEditor text: '1 / 0'.

	mockSession stubs
		at: #execute
		put: [ :script |
			(GbsError new
				messageText: 'boom';
				tag: 111;
				serverProcessOop: 222;
				exceptionOop: 333;
				yourself) signal ].

	GbsSessionParameters currentSession: mockSession.

	workspace doIt.

	self assert: workspace debuggerOpened.
	self assert: workspace lastOpenedProcessOop equals: 222.
]

{ #category : 'tests' }
GbsWorkspaceTest >> testDoItOpensDebuggerWithServerProcessOopWhenProbeIsFalse [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	workspace textEditor text: '1 / 0'.

	mockSession stubs
		at: #execute
		put: [ :script |
			(GbsError new
				messageText: 'boom';
				tag: 20;
				serverProcessOop: 222;
				exceptionOop: nil;
				yourself) signal ].
	mockSession stubs
		at: #evaluate
		put: false.

	GbsSessionParameters currentSession: mockSession.

	workspace doIt.

	self assert: workspace debuggerOpened.
	self assert: workspace lastOpenedProcessOop equals: 222.
]

{ #category : 'tests' }
GbsWorkspaceTest >> testDoItDoesNotProbeOrOpenDebuggerForLocalError [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.

	workspace textEditor text: '1 / 0'.

	mockSession stubs
		at: #execute
		put: [ :script | (GbsError new messageText: 'Not logged in to GemStone.'; tag: 222; yourself) signal ].
	mockSession stubs
		at: #evaluate
		put: [ self fail: 'Workspace should not evaluate server probe for local/non-remote errors.' ].
	GbsSessionParameters currentSession: mockSession.

	workspace doIt.

	self deny: workspace debuggerOpened.
]

{ #category : 'tests' }
GbsWorkspaceTest >> testGsActionAliasesRouteToPrimaryActions [
	| workspace |
	workspace := TestableGbsWorkspaceActions new.

	self assert: workspace gsDoIt.
	self assert: workspace didDoIt.

	self assert: workspace gsInspectIt.
	self assert: workspace didInspectIt.

	self assert: workspace gsPrintIt.
	self assert: workspace didPrintIt
]

{ #category : 'tests' }
GbsWorkspaceTest >> testInspectItUsesExecuteScriptAndReturnOop [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	workspace textEditor text: '42'.

	mockSession stubs
		at: #executeScriptAndReturnOop
		put: [ :script |
			self assert: script equals: '[ 42 ] value'.
			9001 ].
	mockSession stubs
		at: #apiGciExecuteStrContextEnv
		put: [ :script :context :env |
			self fail: 'Workspace inspectIt should use executeScriptAndReturnOop, not serverInterface.' ].
	GbsSessionParameters currentSession: mockSession.

	workspace inspectIt.

	self assert: workspace lastInspectedOop equals: 9001.
	self assert: workspace lastInspectedSession == mockSession
]

{ #category : 'tests' }
GbsWorkspaceTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	GbsSessionParameters currentSession: mockSession.
	workspace enqueueRequestAnswer: 'abc'.

	self deny: workspace browsePromptedSessionStateKey.
	self assert: workspace lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: workspace lastInspectedOop isNil
]

{ #category : 'tests' }
GbsWorkspaceTest >> testBrowsePromptedSessionStateKeyUsesSessionFacade [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession stubs
		at: #executeScriptAndFetchObject
		put: [ :script |
			self assert: (script includesSubstring: 'key := 21').
			^ GbsProxy oop: 9601 session: mockSession ].
	GbsSessionParameters currentSession: mockSession.
	workspace enqueueRequestAnswer: '21'.

	self assert: workspace browsePromptedSessionStateKey.
	self assert: workspace lastInspectedOop equals: 9601.
	self assert: workspace lastInspectedSession == mockSession
]

{ #category : 'tests' }
GbsWorkspaceTest >> testBrowseRubyLoadPathReportUsesRuntimeReport [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseRubyLoadPathReport.
	self assert: (workspace lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (workspace lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbsWorkspaceTest >> testBrowseRubyLoadedFeaturesReportUsesRuntimeReport [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default transientLoadedFeatures: 1'
			ifTrue: [ ^ #('json' 'set') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseRubyLoadedFeaturesReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'Loaded Features').
	self assert: (workspace lastInfoMessage includesSubstring: 'json')
]

{ #category : 'tests' }
GbsWorkspaceTest >> testBrowseRubyPersistentLoadedFeaturesReportUsesRuntimeReport [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default persistentLoadedFeatures: 1'
			ifTrue: [ ^ #('bigdecimal') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseRubyPersistentLoadedFeaturesReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'Persistent Loaded Features').
	self assert: (workspace lastInfoMessage includesSubstring: 'bigdecimal')
]

{ #category : 'tests' }
GbsWorkspaceTest >> testBrowseTypedWrapperLifecycleReportUsesSessionLifecycleReport [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession stubs at: #typedWrapperLifecycleReportText put: [
		'Typed Wrapper Lifecycle', String cr, String cr, 'ClientThing' ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseTypedWrapperLifecycleReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'Typed Wrapper Lifecycle').
	self assert: (workspace lastInfoMessage includesSubstring: 'ClientThing')
]

{ #category : 'tests' }
GbsWorkspaceTest >> testBrowseStaleTypedWrapperLifecycleReportUsesSessionLifecycleReport [
	| workspace mockSession staleEntry |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
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
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseStaleTypedWrapperLifecycleReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'ClientThing').
	self assert: (workspace lastInfoMessage includesSubstring: 'stale')
]

{ #category : 'tests' }
GbsWorkspaceTest >> testBrowseTopLevelAutoloadRegistrationsReportUsesRuntimeReport [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:')
			ifTrue: [ ^ { #('DemoConst' 'demo/file' false nil) } ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseTopLevelAutoloadRegistrationsReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'Autoload Registrations').
	self assert: (workspace lastInfoMessage includesSubstring: 'DemoConst -> demo/file [Pending]')
]

{ #category : 'tests' }
GbsWorkspaceTest >> testBrowsePromptedSessionStateKeysReportUsesDiagnosticsFacade [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ (IdentityDictionary new at: #lazyThing put: 'registered'; yourself) ].
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.
	workspace enqueueRequestAnswer: '19, 21'.

	self assert: workspace browsePromptedSessionStateKeysReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'Key 19 (MagLev Finalizer Registry)').
	self assert: (workspace lastInfoMessage includesSubstring: 'Key 21 (Session State)')
]

{ #category : 'tests' }
GbsWorkspaceTest >> testBrowseObjectsInMemoryReportUsesDiagnosticsFacade [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _listInstancesInMemory:')
			ifTrue: [ ^ { GbsProxy oop: 9201 session: mockSession. GbsProxy oop: 9202 session: mockSession } ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.
	workspace
		enqueueRequestAnswer: '1';
		enqueueRequestAnswer: '2'.

	self assert: workspace browseObjectsInMemoryReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'Objects In Memory').
	self assert: (workspace lastInfoMessage includesSubstring: 'oop=9201')
]

{ #category : 'tests' }
GbsWorkspaceTest >> testBrowseMaglevFinalizerRegistryReportUsesDiagnosticsFacade [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ GbsProxy oop: 9001 session: mockSession ].
		(script includesSubstring: 'findReferencesInMemory') ifTrue: [
			^ { GbsProxy oop: 9101 session: mockSession } ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseMaglevFinalizerRegistryReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'MagLev Finalizer Registry oop=9001 Referencers').
	self assert: (workspace lastInfoMessage includesSubstring: 'oop=9101')
]
