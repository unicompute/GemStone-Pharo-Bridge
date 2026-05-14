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
GbsWorkspaceCoreActionsTest >> testDoAbortUsesSafeTransactionAbort [
	| workspace mockSession abortCalls |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	abortCalls := 0.
	mockSession stubs
		at: #gciAbort
		put: [
			abortCalls := abortCalls + 1.
			1 ].
	GbsSessionParameters currentSession: mockSession.

	workspace doAbort.

	self assert: abortCalls equals: 1.
	self assert: workspace lastInfoMessage equals: 'GemStone: Aborted and Synced to latest state.'
]

{ #category : 'tests' }
GbsWorkspaceCoreActionsTest >> testDoCommitUsesCommitOrSignalConflict [
	| workspace mockSession commitCalls |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	commitCalls := 0.
	mockSession stubs
		at: #gciCommit
		put: [
			commitCalls := commitCalls + 1.
			1 ].
	GbsSessionParameters currentSession: mockSession.

	workspace doCommit.

	self assert: commitCalls equals: 1.
	self assert: workspace lastInfoMessage equals: 'GemStone: Commit Successful!'
]

{ #category : 'tests' }
GbsWorkspaceCoreActionsTest >> testDoCommitReportsConflictFromSignal [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #gciCommit put: [ 0 ].
	GbsSessionParameters currentSession: mockSession.

	workspace doCommit.

	self assert: (workspace lastInfoMessage includesSubstring: 'Commit Failed (Conflict)')
]

{ #category : 'tests' }
GbsWorkspaceCoreActionsTest >> testDoItFallsBackToExceptionOopWhenServerProcessIsUnavailable [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	workspace textEditor text: 'Object error: ''boom'''.
	mockSession stubs
		at: #execute
		put: [ :script |
			self assert: script equals: 'Object error: ''boom'''.
			(GbsError new
				messageText: 'boom';
				tag: 20;
				serverProcessOop: 20;
				exceptionOop: 9301;
				yourself) signal ].
	GbsSessionParameters currentSession: mockSession.

	workspace doIt.

	self assert: workspace debuggerOpened.
	self assert: workspace lastOpenedProcessOop equals: 9301
]

{ #category : 'tests' }
GbsWorkspaceCoreActionsTest >> testDoItOpensRemoteDebuggerForGemStoneExceptionMetadata [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	workspace textEditor text: '1 / 0'.
	mockSession stubs
		at: #execute
		put: [ :script |
			self assert: script equals: '1 / 0'.
			(GbsError new
				messageText: 'ZeroDivide';
				tag: 20;
				serverProcessOop: 9201;
				exceptionOop: 9301;
				yourself) signal ].
	GbsSessionParameters currentSession: mockSession.

	workspace doIt.

	self assert: workspace debuggerOpened.
	self assert: workspace lastOpenedProcessOop equals: 9201
]

{ #category : 'tests' }
GbsWorkspaceCoreActionsTest >> testDoItReportsErrorWhenNoRemoteDebugMetadataExists [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	workspace textEditor text: '1 / 0'.
	mockSession stubs
		at: #execute
		put: [ :script |
			(GbsError new
				messageText: 'local transport failure';
				tag: 20;
				serverProcessOop: 20;
				exceptionOop: nil;
				yourself) signal ].
	GbsSessionParameters currentSession: mockSession.

	workspace doIt.

	self deny: workspace debuggerOpened.
	self assert: workspace lastInfoMessage equals: 'GemStone Error: local transport failure'
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
GbsWorkspaceCoreActionsTest >> testInspectItUsesWorkspaceExecutionApi [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	workspace textEditor text: '42'.

	mockSession stubs
		at: #executeWorkspaceScriptAndReturnOop
		put: [ :script |
			self assert: script equals: '[ 42 ] value'.
			9001 ].
	mockSession stubs
		at: #executeScriptAndReturnOop
		put: [ :script |
			self fail: 'Workspace inspectIt should use executeWorkspaceScriptAndReturnOop:.' ].
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
