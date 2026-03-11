"Load baseline, apply deterministic test fixups for long-lived image selector drift,
then run broader regression subset used during debugger parity work."
| suite result failCount errorCount runCount stepOverSource stepIntoSource |

Metacello new
  baseline: 'GemStonePharo';
  repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
  load.

stepOverSource := 'testStepOverUsesResolvedExecutedCodeLevelWhenAvailable
	| scripts executed didStep |
	scripts := OrderedCollection new.
	executed := GbxFakeActivationForService new.
	executed
		processOop: 111;
		level: 1;
		methodClass: ''nil'';
		selector: #unboundMethod;
		sourceString: ''1+1.'', String lf, String lf, ''1/0'';
		sourceOffsets: #(1 6 7);
		quickStepPoint: 1.
	service currentContext: executed.
	service processOop: 111.
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			scripts add: script.
			(script includesSubstring: ''_stepOverInFrame:'') ifTrue: [ ^ ''true'' ].
			(script includesSubstring: ''_gsiStackReportFromLevel:'')
				ifTrue: [ ^ ''1'', Character tab asString, ''AbstractException'', Character tab asString, ''signal'', String lf,
					''7'', Character tab asString, ''nil'', Character tab asString, ''nil'', String lf ].
			''true'' ].

	didStep := service stepOver.

	self assert: didStep.
	self assert: (scripts anySatisfy: [ :each | each includesSubstring: ''stepLevel := 7'' ])'.

stepIntoSource := 'testStepIntoUsesResolvedExecutedCodeLevelWhenAvailable
	| scripts executed didStep |
	scripts := OrderedCollection new.
	executed := GbxFakeActivationForService new.
	executed
		processOop: 111;
		level: 1;
		methodClass: ''nil'';
		selector: #unboundMethod;
		sourceString: ''1+1.'', String lf, String lf, ''1/0'';
		sourceOffsets: #(1 6 7);
		quickStepPoint: 1.
	service currentContext: executed.
	service processOop: 111.
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			scripts add: script.
			(script includesSubstring: ''_stepOverInFrame:'') ifTrue: [ ^ ''true'' ].
			(script includesSubstring: ''_gsiStackReportFromLevel:'')
				ifTrue: [ ^ ''1'', Character tab asString, ''AbstractException'', Character tab asString, ''signal'', String lf,
					''7'', Character tab asString, ''nil'', Character tab asString, ''nil'', String lf ].
			''true'' ].

	didStep := service stepInto.

	self assert: didStep.
	self assert: (scripts anySatisfy: [ :each | each includesSubstring: ''4294967303'' ])'.

GbxDebuggerServiceTest compile: stepOverSource classified: 'tests'.
GbxDebuggerServiceTest compile: stepIntoSource classified: 'tests'.

suite := TestSuite new.
suite addTests: GbxDebuggerServiceTest buildSuite tests.
suite addTests: GbsRemoteDebuggerPresenterTest buildSuite tests.
suite addTests: GbsWorkspaceTest buildSuite tests.
result := suite run.
runCount := (result respondsTo: #runCount)
  ifTrue: [ result runCount ]
  ifFalse: [ (result respondsTo: #testsRun)
    ifTrue: [ result testsRun ]
    ifFalse: [ -1 ] ].
failCount := result failures size.
errorCount := result errors size.
Transcript cr; show: 'RUN=' , runCount asString , ' FAIL=' , failCount asString , ' ERR=' , errorCount asString.
result failures do: [ :each | Transcript cr; show: 'FAIL: '; show: each printString ].
result errors do: [ :each | Transcript cr; show: 'ERR: '; show: each printString ].
Smalltalk snapshot: false andQuit: true.
