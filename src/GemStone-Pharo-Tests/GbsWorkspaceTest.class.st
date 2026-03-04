Class {
	#name : 'GbsWorkspaceTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

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
		put: [ :script | (GbsError new messageText: 'boom'; tag: 20; yourself) signal ].
	GbsSessionParameters classPool at: #CurrentSession put: mockSession.
	
	"3. Action: Run the workspace evaluation"
	workspace doIt.
	
	"4. Assertion: Verify the error was caught and routed to the debugger method"
	self assert: workspace debuggerOpened.
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

	GbsSessionParameters classPool at: #CurrentSession put: mockSession.

	workspace doIt.

	self assert: workspace debuggerOpened.
	self assert: workspace lastOpenedProcessOop equals: 222.
]
