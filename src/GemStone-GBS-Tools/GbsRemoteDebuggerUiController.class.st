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
		add: debugger variablesTablePresenter;
		add: debugger receiverInfoTablePresenter;
		yourself.
	varsRight := SpPanedLayout newHorizontal
		add: debugger frameInfoTablePresenter;
		add: debugger processInfoTablePresenter;
		yourself.
	varsAll := SpPanedLayout newHorizontal
		add: varsLeft;
		add: varsRight;
		yourself.
	sourceAndVars := SpPanedLayout newVertical
		add: debugger sourceTextPresenter;
		add: varsAll;
		yourself.
	^ SpBoxLayout newVertical
		spacing: 5;
		add: debugger mainMenuPresenter expand: false;
		add: debugger errorMessageLabelPresenter expand: false;
		add: (self executionButtonLayoutFor: debugger) expand: false;
		add: (self inspectionButtonLayoutFor: debugger) expand: false;
		add: (SpPanedLayout newVertical
			add: debugger stackListPresenter;
			add: sourceAndVars;
			yourself);
		yourself
]

{ #category : 'layout' }
GbsRemoteDebuggerUiController class >> executionButtonLayoutFor: debugger [
	^ SpBoxLayout newHorizontal
		spacing: 5;
		add: debugger stepIntoButtonPresenter;
		add: debugger stepButtonPresenter;
		add: debugger stepOverButtonPresenter;
		add: debugger restartButtonPresenter;
		add: debugger resumeButtonPresenter;
		add: debugger runUntilReturnButtonPresenter;
		add: debugger runWithBreakAgainButtonPresenter;
		add: debugger runToCaretButtonPresenter;
		add: debugger jumpToCaretButtonPresenter;
		add: debugger returnButtonPresenter;
		add: debugger pauseButtonPresenter;
		add: debugger terminateButtonPresenter;
		yourself
]

{ #category : 'layout' }
GbsRemoteDebuggerUiController class >> inspectionButtonLayoutFor: debugger [
	^ SpBoxLayout newHorizontal
		spacing: 5;
		add: debugger inspectReceiverButtonPresenter;
		add: debugger inspectProcessButtonPresenter;
		add: debugger inspectFrameButtonPresenter;
		add: debugger inspectStackButtonPresenter;
		add: debugger inspectVariableButtonPresenter;
		yourself
]

{ #category : 'updating' }
GbsRemoteDebuggerUiController class >> refreshUiStateFor: debugger [
	self updateButton: debugger stepIntoButtonPresenter enabled: debugger canStepInto.
	self updateButton: debugger stepButtonPresenter enabled: debugger canStepInto.
	self updateButton: debugger stepOverButtonPresenter enabled: debugger canStepOver.
	self updateButton: debugger stepReturnButtonPresenter enabled: debugger canStepReturn.
	self updateButton: debugger restartButtonPresenter enabled: debugger canRestartExecution.
	self updateButton: debugger resumeButtonPresenter enabled: debugger canResumeExecution.
	self updateButton: debugger runUntilReturnButtonPresenter enabled: debugger canStepReturn.
	self updateButton: debugger runWithBreakAgainButtonPresenter enabled: debugger canRunWithBreakAgainExecution.
	self updateButton: debugger runToCaretButtonPresenter enabled: debugger canRunToCaret.
	self updateButton: debugger jumpToCaretButtonPresenter enabled: debugger canJumpToCaret.
	self updateButton: debugger returnButtonPresenter enabled: debugger canReturnFromFrameExecution.
	self updateButton: debugger pauseButtonPresenter enabled: debugger canPauseExecution.
	self updateButton: debugger terminateButtonPresenter enabled: debugger canTerminateExecution.
	self updateButton: debugger inspectReceiverButtonPresenter enabled: debugger canInspectReceiver.
	self updateButton: debugger inspectProcessButtonPresenter enabled: debugger canInspectProcess.
	self updateButton: debugger inspectFrameButtonPresenter enabled: debugger canInspectFrame.
	self updateButton: debugger inspectStackButtonPresenter enabled: debugger canInspectStack.
	self updateButton: debugger inspectVariableButtonPresenter enabled: debugger canInspectVariable
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
