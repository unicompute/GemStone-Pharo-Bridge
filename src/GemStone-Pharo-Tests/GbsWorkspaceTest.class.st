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
GbsWorkspaceTest >> testStackCandidateProbeUsesBoundCommand [
	| workspace mockSession capturedScript capturedContext answer |

	workspace := TestableGbsWorkspace new.
	mockSession := MockGbsSession new.
	mockSession stubs
		at: #evaluate
		put: [ self fail: 'Stack candidate probing should use a bound remote command, not evaluate:.' ].
	mockSession stubs
		at: #executeAndFetchContext
		put: [ :script :context |
			capturedScript := script.
			capturedContext := context.
			'true' ].

	answer := workspace isDebuggerStackCandidateOop: 9001 session: mockSession.

	self assert: answer.
	self assert: capturedContext equals: 20.
	self assert: (capturedScript includesSubstring: 'value: (Object _objectForOop: 9001)').
	self deny: (capturedScript includesSubstring: 'obj := Object _objectForOop:')
]

{ #category : 'integration tests' }
GbsWorkspaceTest >> testLiveDoItOpensRemoteDebuggerForDivideByZero [
	| workspace liveSession |
	liveSession := GbsLiveSessionTestSupport ensureSharedSession.
	(GbsLiveSessionTestSupport sessionIsUsable: liveSession)
		ifFalse: [ self skip: GbsLiveSessionTestSupport unavailableReason ].

	[
		GbsSessionParameters currentSession: liveSession.
		workspace := TestableGbsWorkspace new.
		workspace textEditor text: '1 / 0'.
		workspace doIt.

		self assert: workspace debuggerOpened.
		self
			assert: (workspace lastOpenedProcessOop isNumber
				and: [ workspace lastOpenedProcessOop > 20 ])
			description: 'Expected workspace live 1 / 0 to expose a GemStone debug process OOP'
	] ensure: [
		[ liveSession abortTransaction ] on: Error do: [ ] ]
]
