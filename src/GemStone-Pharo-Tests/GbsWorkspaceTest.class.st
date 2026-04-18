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
