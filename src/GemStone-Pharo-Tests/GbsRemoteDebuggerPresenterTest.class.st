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
