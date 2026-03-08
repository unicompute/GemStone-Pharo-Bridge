Class {
	#name : 'GbsRemoteDebuggerPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'debugger',
		'service'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsRemoteDebuggerPresenterTest >> setUp [
	super setUp.
	debugger := GbsRemoteDebugger new.
	service := GbxFakeServiceForRemoteDebugger new.
	debugger service: service.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectReceiverDelegatesToService [
	self assert: debugger inspectReceiver.
	self assert: service inspectReceiverCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectProcessDelegatesToService [
	self assert: debugger inspectProcess.
	self assert: service inspectProcessCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectFrameDelegatesToService [
	self assert: debugger inspectFrame.
	self assert: service inspectFrameCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectReceiverReturnsFalseWhenServiceRaises [
	service raiseOnInspectReceiver: true.

	self deny: debugger inspectReceiver.
	self assert: service inspectReceiverCalls equals: 0.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectVariableDelegatesSelectedVariableNameToService [
	| fakeTable |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable selectedItem: #('a' '10').
	debugger instVarNamed: 'variablesTable' put: fakeTable.

	self assert: debugger inspectVariable.
	self assert: service inspectVariableCalls equals: 1.
	self assert: service lastInspectedVariableName equals: 'a'
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testInspectVariableReturnsFalseWhenNoSelection [
	| fakeTable |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	debugger instVarNamed: 'variablesTable' put: fakeTable.

	self deny: debugger inspectVariable.
	self assert: service inspectVariableCalls equals: 0
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testSetBreakPointDelegatesToService [
	self assert: debugger setBreakPoint.
	self assert: service setBreakPointCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testToggleBreakPointDelegatesToService [
	self assert: debugger toggleBreakPoint.
	self assert: service toggleBreakPointCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testGsDoItDelegatesToService [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: '1 + 1'.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger gsDoIt.
	self assert: service gsDoItCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testGsPrintItDelegatesToServiceAndAppendsResult [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: '21+21'.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger gsPrintIt.
	self assert: service gsPrintItCalls equals: 1.
	self assert: (fakeText text includesSubstring: '"42"').
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testGsInspectItDelegatesToService [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'Array new'.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger gsInspectIt.
	self assert: service gsInspectItCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testAcceptSourceEditsDelegatesRecompileWithCurrentText [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'foo ^ 1'.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger acceptSourceEdits.
	self assert: service recompileCalls equals: 1.
	self assert: service lastRecompiledSource equals: 'foo ^ 1'
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testAcceptSourceEditsShowsCompileErrorWhenRecompileFails [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'foo ^'.
	debugger instVarNamed: 'sourceText' put: fakeText.
	service
		recompileShouldSucceed: false;
		lastCompileError: 'Syntax error near ^'.

	self deny: debugger acceptSourceEdits.
	self assert: (fakeText text includesSubstring: 'Compile error: Syntax error near ^')
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRemoveBreakPointDelegatesToService [
	self assert: debugger removeBreakPoint.
	self assert: service removeBreakPointCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRemoveAllBreakPointsDelegatesToService [
	self assert: debugger removeAllBreakPoints equals: 1.
	self assert: service removeAllBreakPointsCalls equals: 1.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testApplySourceMapHighlightSelectsIntervalOnSourceText [
	| fakeText context |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'abcde'.
	service sourceMap: { 1 -> (2 to: 4) }.
	debugger instVarNamed: 'sourceText' put: fakeText.
	context := GbxActivation new.

	debugger applySourceMapHighlightFor: context.

	self assert: fakeText selectionInterval equals: (2 to: 4).
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testApplySourceMapHighlightFallsBackToDisplayedLineNumber [
	| fakeText context |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'aa', String lf, 'bb', String lf, 'cc'.
	service sourceMap: #().
	debugger instVarNamed: 'sourceText' put: fakeText.

	context := GbxActivation new.
	context
		methodClass: 'nil';
		selector: #nil;
		ipOffset: 2;
		sourceString: ''.

	debugger applySourceMapHighlightFor: context.

	self assert: fakeText selectionInterval equals: (4 to: 5)
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testContextSelectedFetchesFullSourceForSingleLineNilFrame [
	| mockSession fakeText fakeTable context rendered |
	mockSession := MockGbsSession new.
	mockSession stubs
		at: #evaluate
		put: ' | a b |<LF>a := 10.<LF>b := 0.<LF><LF>a / b'.

	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	context := GbxFakeContextForRemoteDebugger new
		methodClass: 'nil';
		sourceString: '| a b |';
		processOop: 222;
		level: 8;
		tempNamesAndValues: (Dictionary new
			at: 'a' put: '10';
			at: 'b' put: '0';
			yourself);
		yourself.

	debugger session: mockSession.
	debugger instVarNamed: 'sourceText' put: fakeText.
	debugger instVarNamed: 'variablesTable' put: fakeTable.

	debugger contextSelected: context.

	rendered := fakeText text.
	self assert: (rendered includes: Character lf).
	self assert: (rendered includesSubstring: 'a / b').
	self assert: context sourceString equals: rendered.
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testContextSelectedDoesNotRaiseWhenSourceAndVariableWidgetsAreMissing [
	| context |
	context := GbxFakeContextForRemoteDebugger new
		methodClass: 'nil';
		sourceString: '| a |';
		processOop: 222;
		level: 1;
		tempNamesAndValues: Dictionary new;
		yourself.

	self shouldnt: [ debugger contextSelected: context ] raise: Error
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testStepIntoDoesNotRaiseWhenServiceDoesNotImplementStepInto [
	self shouldnt: [ debugger stepInto ] raise: Error
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testStackReportStringIncludesAllContextPrintStrings [
	| ctx1 ctx2 report |
	ctx1 := Object new.
	ctx2 := Object new.
	debugger instVarNamed: 'contextList' put: { ctx1. ctx2 }.

	report := debugger stackReportString.

	self assert: (report includesSubstring: ctx1 printString).
	self assert: (report includesSubstring: ctx2 printString)
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testToggleGlueHidingDelegatesToService [
	self assert: debugger toggleGlueHiding.
	self assert: service toggleGlueHidingCalls equals: 1
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testCorrectSelectorDelegatesToService [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'foo: x ^ x + 1'.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger correctSelector.
	self assert: service correctSelectorCalls equals: 1.
	self assert: service lastRecompiledSource equals: 'foo: x ^ x + 1'
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRestartDelegatesToService [
	self assert: debugger restart.
	self assert: service restartCalls equals: 1
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRestartPromotesExecutedCodeFrameToTopAndSelectsSourceStart [
	| fakeText fakeList nonExecuted executed |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: ''.
	debugger instVarNamed: 'sourceText' put: fakeText.
	debugger instVarNamed: 'variablesTable' put: GbxFakeTablePresenterForRemoteDebugger new.
	debugger instVarNamed: 'receiverInfoTable' put: GbxFakeTablePresenterForRemoteDebugger new.
	debugger instVarNamed: 'frameInfoTable' put: GbxFakeTablePresenterForRemoteDebugger new.
	debugger instVarNamed: 'processInfoTable' put: GbxFakeTablePresenterForRemoteDebugger new.
	fakeList := GbxFakeListPresenterForRemoteDebugger new.
	debugger instVarNamed: 'stackList' put: fakeList.

	nonExecuted := GbxActivation new.
	nonExecuted
		processOop: 111;
		level: 1;
		initializeFromClass: 'SmallInteger'
			selector: #/
			source: '1+1.', String lf, '1/0'
			contextOop: 111;
		quickStepPoint: 3;
		sourceOffsets: #(1 6 7);
		ipOffset: 2.

	executed := GbxActivation new.
	executed
		processOop: 111;
		level: 2;
		initializeFromClass: 'nil'
			selector: #unboundMethod
			source: '1+1.', String lf, '1/0'
			contextOop: 111;
		quickStepPoint: 3;
		sourceOffsets: #(1 6 7);
		ipOffset: 2.

	service contextList: { nonExecuted. executed }.
	self assert: debugger restart.

	self assert: service restartCalls equals: 1.
	self assert: (debugger instVarNamed: 'contextList') first printString equals: 'GS: Executed code @1 line 1'.
	self assert: fakeList selectedIndex equals: 1.
	self assert: fakeText selectionInterval equals: (1 to: 1)
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testMoveSourceCursorToStartSelectsFirstCharacter [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: '1+1.', String lf, '1/0'.
	fakeText selectionInterval: (5 to: 5).
	debugger instVarNamed: 'sourceText' put: fakeText.

	debugger moveSourceCursorToStart.

	self assert: fakeText selectionInterval equals: (1 to: 1)
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testPauseProcessDelegatesToService [
	self assert: debugger pauseProcess.
	self assert: service pauseCalls equals: 1
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testRunToCaretUsesSelectedStepPoint [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'abcde'.
	fakeText selectionInterval: (3 to: 3).
	service sourceMap: { 2 -> (2 to: 4) }.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger runToCaret.
	self assert: service runToStepPointCalls equals: 1.
	self assert: service lastStepPoint equals: 2
]

{ #category : 'tests' }
GbsRemoteDebuggerPresenterTest >> testJumpToCaretUsesSelectedStepPoint [
	| fakeText |
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.
	fakeText text: 'abcde'.
	fakeText selectionInterval: (3 to: 3).
	service sourceMap: { 4 -> (2 to: 4) }.
	debugger instVarNamed: 'sourceText' put: fakeText.

	self assert: debugger jumpToCaret.
	self assert: service jumpToStepPointCalls equals: 1.
	self assert: service lastStepPoint equals: 4
]
