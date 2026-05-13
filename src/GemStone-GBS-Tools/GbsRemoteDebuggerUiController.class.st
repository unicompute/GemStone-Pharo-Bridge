Class {
	#name : 'GbsRemoteDebuggerUiController',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'layout' }
GbsRemoteDebuggerUiController class >> defaultLayoutFor: debugger [
	| varsLeft varsRight varsAll sourceAndVars |
	varsLeft := SpPanedLayout newHorizontal
		add: (debugger instVarNamed: 'variablesTable');
		add: (debugger instVarNamed: 'receiverInfoTable');
		yourself.
	varsRight := SpPanedLayout newHorizontal
		add: (debugger instVarNamed: 'frameInfoTable');
		add: (debugger instVarNamed: 'processInfoTable');
		yourself.
	varsAll := SpPanedLayout newHorizontal
		add: varsLeft;
		add: varsRight;
		yourself.
	sourceAndVars := SpPanedLayout newVertical
		add: (debugger instVarNamed: 'sourceText');
		add: varsAll;
		yourself.
	^ SpBoxLayout newVertical
		spacing: 5;
		add: (debugger instVarNamed: 'mainMenu') expand: false;
		add: (debugger instVarNamed: 'errorMessageLabel') expand: false;
		add: (self executionButtonLayoutFor: debugger) expand: false;
		add: (self inspectionButtonLayoutFor: debugger) expand: false;
		add: (SpPanedLayout newVertical
			add: (debugger instVarNamed: 'stackList');
			add: sourceAndVars;
			yourself);
		yourself
]

{ #category : 'layout' }
GbsRemoteDebuggerUiController class >> executionButtonLayoutFor: debugger [
	^ SpBoxLayout newHorizontal
		spacing: 5;
		add: (debugger instVarNamed: 'stepIntoButton');
		add: (debugger instVarNamed: 'stepButton');
		add: (debugger instVarNamed: 'stepOverButton');
		add: (debugger instVarNamed: 'restartButton');
		add: (debugger instVarNamed: 'resumeButton');
		add: (debugger instVarNamed: 'runUntilReturnButton');
		add: (debugger instVarNamed: 'runWithBreakAgainButton');
		add: (debugger instVarNamed: 'runToCaretButton');
		add: (debugger instVarNamed: 'jumpToCaretButton');
		add: (debugger instVarNamed: 'returnButton');
		add: (debugger instVarNamed: 'pauseButton');
		add: (debugger instVarNamed: 'terminateButton');
		yourself
]

{ #category : 'layout' }
GbsRemoteDebuggerUiController class >> inspectionButtonLayoutFor: debugger [
	^ SpBoxLayout newHorizontal
		spacing: 5;
		add: (debugger instVarNamed: 'inspectReceiverButton');
		add: (debugger instVarNamed: 'inspectProcessButton');
		add: (debugger instVarNamed: 'inspectFrameButton');
		add: (debugger instVarNamed: 'inspectStackButton');
		add: (debugger instVarNamed: 'inspectVariableButton');
		yourself
]

{ #category : 'updating' }
GbsRemoteDebuggerUiController class >> refreshUiStateFor: debugger [
	self updateButton: (debugger instVarNamed: 'stepIntoButton') enabled: debugger canStepInto.
	self updateButton: (debugger instVarNamed: 'stepButton') enabled: debugger canStepInto.
	self updateButton: (debugger instVarNamed: 'stepOverButton') enabled: debugger canStepOver.
	self updateButton: (debugger instVarNamed: 'stepReturnButton') enabled: debugger canStepReturn.
	self updateButton: (debugger instVarNamed: 'restartButton') enabled: debugger canRestartExecution.
	self updateButton: (debugger instVarNamed: 'resumeButton') enabled: debugger canResumeExecution.
	self updateButton: (debugger instVarNamed: 'runUntilReturnButton') enabled: debugger canStepReturn.
	self updateButton: (debugger instVarNamed: 'runWithBreakAgainButton') enabled: debugger canRunWithBreakAgainExecution.
	self updateButton: (debugger instVarNamed: 'runToCaretButton') enabled: debugger canRunToCaret.
	self updateButton: (debugger instVarNamed: 'jumpToCaretButton') enabled: debugger canJumpToCaret.
	self updateButton: (debugger instVarNamed: 'returnButton') enabled: debugger canReturnFromFrameExecution.
	self updateButton: (debugger instVarNamed: 'pauseButton') enabled: debugger canPauseExecution.
	self updateButton: (debugger instVarNamed: 'terminateButton') enabled: debugger canTerminateExecution.
	self updateButton: (debugger instVarNamed: 'inspectReceiverButton') enabled: debugger canInspectReceiver.
	self updateButton: (debugger instVarNamed: 'inspectProcessButton') enabled: debugger canInspectProcess.
	self updateButton: (debugger instVarNamed: 'inspectFrameButton') enabled: debugger canInspectFrame.
	self updateButton: (debugger instVarNamed: 'inspectStackButton') enabled: debugger canInspectStack.
	self updateButton: (debugger instVarNamed: 'inspectVariableButton') enabled: debugger canInspectVariable
]

{ #category : 'converting' }
GbsRemoteDebuggerUiController class >> presenterTextFrom: aValue [
	aValue ifNil: [ ^ '' ].
	(aValue isString or: [ aValue isSymbol ]) ifTrue: [ ^ aValue asString ].
	(aValue respondsTo: #asLocalString) ifTrue: [ ^ aValue asLocalString asString ].
	(aValue respondsTo: #asString) ifTrue: [ ^ aValue asString ].
	^ aValue printString
]

{ #category : 'updating' }
GbsRemoteDebuggerUiController class >> updateButton: aButton enabled: enabledBoolean [
	aButton ifNil: [ ^ self ].
	(aButton respondsTo: #enabled:)
		ifTrue: [ [ aButton enabled: enabledBoolean ] on: Error do: [ ] ]
]
