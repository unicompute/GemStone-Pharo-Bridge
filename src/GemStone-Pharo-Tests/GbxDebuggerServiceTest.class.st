Class {
	#name : 'GbxDebuggerServiceTest',
	#superclass : 'TestCase',
	#instVars : [
		'service',
		'session',
		'context'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbxDebuggerServiceTest >> setUp [
	super setUp.
	GbxFakeInspectorForService reset.
	GbxFakeBreakPointForService reset.
	GbxFakeBrowserForService reset.
	session := MockGbsSession new.
	session
		isLoggedIn: true;
		sessionOop: 1.
	service := GbxTestableDebuggerService new.
	service session: session.
	context := GbxFakeActivationForService new.
	context
		processOop: 111;
		level: 3;
		selector: #foo;
		methodClass: 'DemoClass';
		sourceString: 'foo ^ 1';
		sourceOffsets: #(10 20 30);
		quickStepPoint: 2;
		visibleSourceMap: { 1 -> (10 to: 10). 2 -> (20 to: 20). 3 -> (30 to: 30) }.
	service currentContext: context.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentProcessUsesContextProcessOop [
	| opened |
	opened := service inspectCurrentProcess.

	self assert: opened.
	self assert: GbxFakeInspectorForService lastOop equals: 111.
	self assert: GbxFakeInspectorForService lastSession == session.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentReceiverUsesDetailedReportOop [
	| opened |
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			(script includesSubstring: '_gsiDebuggerDetailedReportAt:')
				ifTrue: [ '222' ]
				ifFalse: [ '0' ] ].

	opened := service inspectCurrentReceiver.

	self assert: opened.
	self assert: GbxFakeInspectorForService lastOop equals: 222.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentFrameUsesFrameContentsOop [
	| opened |
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			(script includesSubstring: '_frameContentsAt:')
				ifTrue: [ '333' ]
				ifFalse: [ '0' ] ].

	opened := service inspectCurrentFrame.

	self assert: opened.
	self assert: GbxFakeInspectorForService lastOop equals: 333.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectVariableNamedUsesServerFrameLocalOop [
	| opened |
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			(script includesSubstring: 'idx := 0')
				ifTrue: [ '444' ]
				ifFalse: [ '0' ] ].

	opened := service inspectVariableNamed: 'a'.

	self assert: opened.
	self assert: GbxFakeInspectorForService lastOop equals: 444
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectVariableNamedReturnsFalseWhenUnresolvable [
	session stubs at: #executeAndFetchContext put: [ :script :ctx | '0' ].

	self deny: (service inspectVariableNamed: 'a')
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentReceiverReturnsFalseWhenNoContext [
	service currentContext: nil.

	self deny: service inspectCurrentReceiver.
	self assert: GbxFakeInspectorForService lastOop isNil.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testBreakpointsInSelectedMethodFiltersBySelectorAndClass [
	| match noMatchSelector noMatchClass found |
	match := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	noMatchSelector := GbxFakeBreakPointForService
		selector: #bar
		remoteClass: 'DemoClass'
		stepPoint: 2.
	noMatchClass := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'OtherClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { match. noMatchSelector. noMatchClass }.

	found := service breakpointsInSelectedMethod.
	self assert: found size equals: 1.
	self assert: found first == match.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testSetBreakPointInDelegatesToBrowserClass [
	| widget |
	widget := GbxFakeTextWidgetForService new.
	widget
		selectionInterval: (1 to: 1);
		text: 'foo ^ 1'.

	self assert: (service setBreakPointIn: widget).
	self assert: GbxFakeBrowserForService lastBreakView == widget.
	self assert: GbxFakeBrowserForService lastModel == context.
	self assert: GbxFakeBrowserForService lastMethod equals: #foo.
	self assert: GbxFakeBrowserForService lastClass equals: 'DemoClass'.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testSetBreakPointInDoesNotDuplicateWhenBreakpointAlreadyAtCurrentStepPoint [
	| existing |
	existing := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { existing }.

	self deny: (service setBreakPointIn: nil).
	self assert: GbxFakeBrowserForService setBreakCalls equals: 0
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRemoveBreakPointClearsFirstMatchingBreakpoint [
	| bp1 bp2 |
	bp1 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 1.
	bp2 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { bp1. bp2 }.

	self assert: service removeBreakPoint.
	self deny: bp1 cleared.
	self assert: bp2 cleared.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRemoveBreakInClearsBreakpointMatchingSelectionOffset [
	| bp1 bp2 widget |
	bp1 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 1.
	bp2 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { bp1. bp2 }.

	widget := GbxFakeTextWidgetForService new.
	widget selectionInterval: (19 to: 21). "Matches stepPoint 2 => offset 20"

	self assert: (service removeBreakIn: widget).
	self deny: bp1 cleared.
	self assert: bp2 cleared.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRemoveBreakPointUsesCurrentStepPointWhenNoSelection [
	| bp1 bp2 |
	bp1 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 1.
	bp2 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { bp1. bp2 }.

	self assert: service removeBreakPoint.
	self deny: bp1 cleared.
	self assert: bp2 cleared.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRemoveAllBreakPointsClearsAllMatching [
	| bp1 bp2 removedCount |
	bp1 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 1.
	bp2 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { bp1. bp2 }.

	removedCount := service removeAllBreakPoints.
	self assert: removedCount equals: 2.
	self assert: bp1 cleared.
	self assert: bp2 cleared.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testCanRemoveBreakPointReflectsExistingMethodBreakpoints [
	| bp |
	self deny: service canRemoveBreakPoint.

	bp := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { bp }.

	self assert: service canRemoveBreakPoint.
	self assert: service canRemoveAllBreakPoints.
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testCanSetBreakPointIsFalseWhenBreakpointAtCurrentStepPoint [
	| bp |
	bp := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { bp }.

	self deny: service canSetBreakPoint
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testToggleBreakPointRemovesWhenCurrentStepPointAlreadyHasBreakpoint [
	| bp |
	bp := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 2.
	GbxFakeBreakPointForService breakPointList: { bp }.

	self assert: service toggleBreakPoint.
	self assert: bp cleared.
	self assert: GbxFakeBrowserForService setBreakCalls equals: 0
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testToggleBreakPointSetsWhenNoBreakpointAtCurrentStepPoint [
	| bp |
	bp := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 1.
	GbxFakeBreakPointForService breakPointList: { bp }.

	self assert: service toggleBreakPoint.
	self assert: GbxFakeBrowserForService setBreakCalls equals: 1
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testCurrentSourceSelectionIntervalUsesCurrentStepPoint [
	| interval |
	interval := service currentSourceSelectionInterval.

	self assert: interval equals: (20 to: 20)
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testCurrentSourceSelectionIntervalFallsBackToFirstWhenStepPointMissing [
	| interval |
	context quickStepPoint: 999.

	interval := service currentSourceSelectionInterval.

	self assert: interval equals: (10 to: 10)
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testSetBreakPointInReturnsFalseWhenSourceWasEdited [
	| widget |
	widget := GbxFakeTextWidgetForService new.
	widget
		selectionInterval: (1 to: 1);
		text: 'edited source text'.

	self deny: (service setBreakPointIn: widget).
	self assert: GbxFakeBrowserForService setBreakCalls equals: 0
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRecompileCurrentMethodWithSourceReturnsTrueOnOk [
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			(script includesSubstring: 'compileMethod:')
				ifTrue: [ 'OK' ]
				ifFalse: [ '0' ] ].

	self assert: (service recompileCurrentMethodWithSource: 'foo ^ 1')
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRecompileCurrentMethodWithSourceStoresCompileErrorOnFailure [
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx | 'ERROR|Syntax error near ''^''' ].

	self deny: (service recompileCurrentMethodWithSource: 'foo ^').
	self assert: service lastCompileError equals: 'Syntax error near ''^'''
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testGsPrintItEvaluatesInCurrentContext [
	| result |
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			(script includesSubstring: 'printString')
				ifTrue: [ '42' ]
				ifFalse: [ '0' ] ].

	result := service gsPrintIt: '21+21'.
	self assert: result equals: '42'
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testInspectCurrentProcessReturnsFalseWhenSessionNotUsable [
	session isLoggedIn: false.

	self deny: service inspectCurrentProcess.
	self assert: GbxFakeInspectorForService lastOop isNil
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testBreakpointIntervalsInCurrentMethodUsesSourceOffsets [
	| bp1 bp2 intervals |
	bp1 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 1.
	bp2 := GbxFakeBreakPointForService
		selector: #foo
		remoteClass: 'DemoClass'
		stepPoint: 3.
	GbxFakeBreakPointForService breakPointList: { bp1. bp2 }.

	intervals := service breakpointIntervalsInCurrentMethod.

	self assert: intervals size equals: 2.
	self assert: intervals first equals: (10 to: 10).
	self assert: intervals second equals: (30 to: 30)
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testStepIntoReturnsFalseWhenNoUsableProcessOop [
	service processOop: 20.

	self deny: service stepInto
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testStepIntoReturnsFalseWhenExecutionErrors [
	session stubs at: #executeAndFetchContext put: [ :script :ctx | Error signal: 'boom' ].
	service processOop: 111.

	self deny: service stepInto
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRestartUsesTrimStackToLevelCommand [
	| scripts didRestart |
	scripts := OrderedCollection new.
	service processOop: 111.
	service instVarNamed: 'contextStackPolicy' put: (GbxFakeContextListPolicyForService new contextList: { context }; yourself).
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			scripts add: script.
			(script includesSubstring: '_trimStackToLevel:')
				ifTrue: [ 'true' ]
				ifFalse: [ '' ] ].

	didRestart := service restart.

	self assert: didRestart.
	self assert: (scripts anySatisfy: [ :each | each includesSubstring: '_trimStackToLevel:' ])
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRestartReturnsFalseWhenTrimStackFails [
	service processOop: 111.
	service instVarNamed: 'contextStackPolicy' put: (GbxFakeContextListPolicyForService new contextList: { context }; yourself).
	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			(script includesSubstring: '_trimStackToLevel:')
				ifTrue: [ 'false' ]
				ifFalse: [ '' ] ].

	self deny: service restart
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testRestartSelectsExecutedCodeFrameAtLineOne [
	| oldContext nonExecuted restartedExecuted fakePolicy didRestart |
	oldContext := self
		makeActivationMethodClass: nil
		selector: nil
		stepPoint: 3
		sourceOffsets: #(1 6 7)
		source: '1+1.', String lf, String lf, '1/0'.
	nonExecuted := self
		makeActivationMethodClass: 'SmallInteger'
		selector: #/
		stepPoint: 3
		sourceOffsets: #(1 6 7)
		source: '1+1.', String lf, String lf, '1/0'.
	restartedExecuted := self
		makeActivationMethodClass: nil
		selector: nil
		stepPoint: 1
		sourceOffsets: #(1 6 7)
		source: '1+1.', String lf, String lf, '1/0'.

	service currentContext: oldContext.
	service processOop: 111.
	fakePolicy := GbxFakeContextListPolicyForService new.
	fakePolicy contextList: { nonExecuted. restartedExecuted }.
	service instVarNamed: 'contextStackPolicy' put: fakePolicy.

	session stubs
		at: #executeAndFetchContext
		put: [ :script :ctx |
			(script includesSubstring: '_trimStackToLevel:')
				ifTrue: [ 'true' ]
				ifFalse: [ '' ] ].

	didRestart := service restart.

	self assert: didRestart.
	self assert: service currentContext == restartedExecuted.
	self assert: service currentContext printString equals: 'GS: Executed code @1 line 1'
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testCutbackToGsProcessOfTerminatesProcessAndClearsErrorSession [
	| gsContext fakeError |
	gsContext := GbxFakeActivationForService new.
	gsContext
		processOop: 111;
		level: 2.
	fakeError := GbxFakeGbsErrorForService new.
	fakeError session: session.
	gsContext gbsError: fakeError.

	self assert: (service cutbackToGsProcessOf: gsContext).
	self assert: gsContext terminateCalled.
	self assert: fakeError session isNil
]

{ #category : 'tests' }
GbxDebuggerServiceTest >> testCutbackGsProcessesAboveUsesFirstServerContextAndTerminatesIt [
	| clientContext serverContext policy fakeError |
	clientContext := Object new.
	serverContext := GbxFakeActivationForService new.
	serverContext
		processOop: 111;
		level: 2.
	fakeError := GbxFakeGbsErrorForService new.
	fakeError session: session.
	serverContext gbsError: fakeError.

	policy := GbxFakeContextListPolicyForService new.
	policy contextList: { serverContext. clientContext }.
	service instVarNamed: 'contextStackPolicy' put: policy.

	service cutbackGsProcessesAbove: clientContext.
	self assert: serverContext terminateCalled.
	self assert: fakeError session isNil
]

{ #category : 'private' }
GbxDebuggerServiceTest >> makeActivationMethodClass: className selector: selectorSymbol stepPoint: step sourceOffsets: offsets source: sourceText [
	| activation |
	activation := GbxActivation new.
	activation
		processOop: 111;
		level: 8;
		methodClass: className;
		selector: selectorSymbol;
		sourceString: sourceText;
		sourceOffsets: offsets;
		quickStepPoint: step.
	^ activation
]
