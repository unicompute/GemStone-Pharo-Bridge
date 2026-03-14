Class {
	#name : 'GbsWorkspaceTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousSession',
		'previousSessions'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsWorkspaceTest >> setUp [
	super setUp.
	previousSession := GbsSessionParameters currentSession.
	previousSessions := GbsSessionParameters allSessions copy.
	GbsSessionParameters allSessions removeAll
]

{ #category : 'running' }
GbsWorkspaceTest >> tearDown [
	GbsSessionParameters currentSession: previousSession.
	GbsSessionParameters allSessions removeAll.
	GbsSessionParameters allSessions addAll: previousSessions.
	super tearDown
]

{ #category : 'tests' }
GbsWorkspaceTest >> testDoItHandlesGemStoneError [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	
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
GbsWorkspaceTest >> testBestDebugProcessOopPrefersCandidateWithStack [
	| workspace mockSession err resolved |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	err := GbsError new
		messageText: 'boom';
		tag: 333;
		serverProcessOop: 222;
		exceptionOop: 444;
		yourself.

	mockSession stubs
		at: #executeAndFetchContext
		put: [ :script :context |
			(script includesSubstring: 'Object _objectForOop: 333')
				ifTrue: [ 'true' ]
				ifFalse: [ 'false' ] ].

	resolved := workspace
		bestDebugProcessOopFromError: err
		session: mockSession.

	self assert: resolved equals: 333.
]

{ #category : 'tests' }
GbsWorkspaceTest >> testDoItPrefersServerProcessOopOverTag [
	| workspace mockSession |

	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
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
GbsWorkspaceTest >> testDoItUsesResolvedProcessCandidateWithStack [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	workspace textEditor text: '1 / 0'.

	mockSession stubs
		at: #execute
		put: [ :script |
			(GbsError new
				messageText: 'boom';
				tag: 333;
				serverProcessOop: 222;
				exceptionOop: 444;
				yourself) signal ].
	mockSession stubs
		at: #executeAndFetchContext
		put: [ :script :context |
			(script includesSubstring: 'Object _objectForOop: 333')
				ifTrue: [ 'true' ]
				ifFalse: [ 'false' ] ].
	GbsSessionParameters currentSession: mockSession.

	workspace doIt.

	self assert: workspace debuggerOpened.
	self assert: workspace lastOpenedProcessOop equals: 333.
]

{ #category : 'tests' }
GbsWorkspaceTest >> testDoItOpensDebuggerWithServerProcessOopWhenProbeIsFalse [
	| workspace mockSession |
	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
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
	mockSession isLoggedIn: true.

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
