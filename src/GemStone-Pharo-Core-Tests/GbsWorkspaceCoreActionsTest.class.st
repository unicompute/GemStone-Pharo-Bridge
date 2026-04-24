Class {
	#name : 'GbsWorkspaceCoreActionsTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousSession'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GbsWorkspaceCoreActionsTest >> setUp [
	super setUp.
	previousSession := GbsSessionParameters currentSession
]

{ #category : 'running' }
GbsWorkspaceCoreActionsTest >> tearDown [
	GbsSessionParameters currentSession: previousSession.
	super tearDown
]

{ #category : 'tests' }
GbsWorkspaceCoreActionsTest >> testGsActionAliasesRouteToPrimaryActions [
	| workspace |
	workspace := CoreTestableGbsWorkspaceActions new.

	self assert: workspace gsDoIt.
	self assert: workspace didDoIt.

	self assert: workspace gsInspectIt.
	self assert: workspace didInspectIt.

	self assert: workspace gsPrintIt.
	self assert: workspace didPrintIt
]

{ #category : 'tests' }
GbsWorkspaceCoreActionsTest >> testInspectItUsesExecuteScriptAndReturnOop [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
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
GbsWorkspaceCoreActionsTest >> testBrowsePromptedSessionStateKeyRejectsNonNumericInput [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	GbsSessionParameters currentSession: mockSession.
	workspace enqueueRequestAnswer: 'abc'.

	self deny: workspace browsePromptedSessionStateKey.
	self assert: workspace lastInfoMessage equals: 'Enter a numeric session state key.'.
	self assert: workspace lastInspectedOop isNil
]

{ #category : 'tests' }
GbsWorkspaceCoreActionsTest >> testBrowsePromptedSessionStateKeyUsesSessionFacade [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
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
GbsWorkspaceCoreActionsTest >> testBrowseTypedWrapperLifecycleReportUsesSessionLifecycleReport [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #typedWrapperLifecycleReportText put: [
		'Typed Wrapper Lifecycle', String cr, String cr, 'ClientThing' ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseTypedWrapperLifecycleReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'Typed Wrapper Lifecycle').
	self assert: (workspace lastInfoMessage includesSubstring: 'ClientThing')
]

{ #category : 'tests' }
GbsWorkspaceCoreActionsTest >> testBrowseStaleTypedWrapperLifecycleReportUsesSessionLifecycleReport [
	| workspace mockSession staleEntry |
	workspace := CoreTestableGbsWorkspace new.
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
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseStaleTypedWrapperLifecycleReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'ClientThing').
	self assert: (workspace lastInfoMessage includesSubstring: 'stale')
]

{ #category : 'tests' }
GbsWorkspaceCoreActionsTest >> testBrowsePromptedSessionStateKeysReportUsesDiagnosticsFacade [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
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
GbsWorkspaceCoreActionsTest >> testBrowseObjectsInMemoryReportUsesDiagnosticsFacade [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
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
