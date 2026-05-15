Class {
	#name : 'GbsRemoteDebuggerExecutionController',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerExecutionController class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'accessing' }
GbsRemoteDebuggerExecutionController >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerExecutionController >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> abortGemStoneTransaction [
	debugger session ifNil: [ ^ false ].
	(([ debugger session inTransaction ] on: Exception do: [ true ]) = false)
		ifTrue: [ ^ true ].
	^ [ debugger session abortTransaction. true ]
		on: Exception
		do: [ :ex |
			Transcript
				show: 'GemStone abortTransaction failed: ';
				show: (([ ex messageText ] on: Exception do: [ ex printString ]) ifNil: [ ex printString ]) asString;
				cr.
			false ]
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> closeRemoteDebuggerSession [
	| leaked |
	debugger safeServiceCall: [ debugger service terminate ] default: false.
	self abortGemStoneTransaction.
	leaked := self remoteDebugProcessStillActive.
	leaked ifTrue: [
		(UIManager default respondsTo: #inform:)
			ifTrue: [ UIManager default inform: 'GemStone debug process still appears active after cleanup.' ] ].
	debugger withWindowDo: [ :window | window close ].
	^ leaked not
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> jumpToCaret [
	| stepPoint didJump |
	stepPoint := debugger selectedStepPointFromCaret.
	stepPoint ifNil: [ ^ false ].
	didJump := debugger safeServiceCall: [ debugger service jumpToStepPoint: stepPoint ] default: false.
	didJump ifTrue: [ debugger fetchStackFrames ].
	^ didJump
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> pauseProcess [
	| didPause |
	didPause := debugger safeServiceCall: [ debugger service pause ] default: false.
	didPause ifTrue: [
		debugger fetchStackFrames.
		debugger normalizePauseLandingSelection ].
	^ didPause
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> resume [
	debugger safeServiceCall: [ debugger service resume ] default: false.
	debugger withWindowDo: [ :window | window close ]
]

{ #category : 'private' }
GbsRemoteDebuggerExecutionController >> remoteDebugProcessStillActive [
	debugger service ifNil: [ ^ false ].
	(debugger service respondsTo: #isTerminated) ifFalse: [ ^ false ].
	^ [ debugger service isTerminated not ] on: Error do: [ false ]
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> returnFromFrame [
	(debugger service notNil and: [ debugger service respondsTo: #returnFromFrame ]) ifTrue: [
		| didReturn |
		didReturn := debugger safeServiceCall: [ debugger service returnFromFrame ] default: false.
		didReturn ifTrue: [ debugger fetchStackFrames ].
		^ didReturn ].
	^ self stepReturn
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> runToCaret [
	| stepPoint didRun |
	stepPoint := debugger selectedStepPointFromCaret.
	stepPoint ifNil: [ ^ false ].
	didRun := debugger safeServiceCall: [ debugger service runToStepPoint: stepPoint ] default: false.
	didRun ifTrue: [ debugger fetchStackFrames ].
	^ didRun
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> runUntilReturn [
	^ self stepReturn
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> runWithBreakAgain [
	| didRun |
	didRun := debugger safeServiceCall: [
		(debugger service respondsTo: #runWithBreakAgain)
			ifTrue: [ debugger service runWithBreakAgain ]
			ifFalse: [ debugger service resume ] ]
		default: false.
	didRun ifTrue: [ debugger fetchStackFrames ].
	^ didRun
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> step [
	| didStep hasServiceStep |
	hasServiceStep := debugger service notNil and: [ debugger service respondsTo: #step ].
	didStep := hasServiceStep
		ifTrue: [ debugger safeServiceCall: [ debugger service step ] default: false ]
		ifFalse: [ false ].
	(hasServiceStep not and: [ didStep not ]) ifTrue: [ ^ self stepInto ].
	didStep ifTrue: [ debugger fetchStackFrames ].
	^ didStep
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> stepInto [
	| didStep hasServiceStep |
	hasServiceStep := debugger service notNil and: [ debugger service respondsTo: #stepInto ].
	didStep := hasServiceStep
		ifTrue: [ debugger safeServiceCall: [ debugger service stepInto ] default: false ]
		ifFalse: [ false ].
	didStep ifFalse: [
		debugger currentSelectedContextIsExecutedCodeFrame
			ifTrue: [
				debugger resetServerPCToStepOneIfNeeded.
				didStep := debugger directStepOverExecutedFrame: true ]
			ifFalse: [
				didStep := debugger
					directStepWithPrimarySelector: '_stepIntoInFrame:'
					fallbackSelector: nil ] ].
	didStep ifTrue: [ debugger fetchStackFrames ].
	^ didStep
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> stepOver [
	| didStep hasServiceStep |
	hasServiceStep := debugger service notNil and: [ debugger service respondsTo: #stepOver ].
	didStep := hasServiceStep
		ifTrue: [ debugger safeServiceCall: [ debugger service stepOver ] default: false ]
		ifFalse: [ false ].
	didStep ifFalse: [
		debugger currentSelectedContextIsExecutedCodeFrame
			ifTrue: [
				debugger resetServerPCToStepOneIfNeeded.
				didStep := debugger directStepOverExecutedFrame: false ]
			ifFalse: [
				didStep := debugger
					directStepWithPrimarySelector: '_stepOverInFrame:'
					fallbackSelector: nil ] ].
	didStep ifTrue: [ debugger fetchStackFrames ].
	^ didStep
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> stepReturn [
	| didStep |
	didStep := debugger safeServiceCall: [ debugger service stepReturn ] default: false.
	didStep ifTrue: [ debugger fetchStackFrames ].
	^ didStep
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> terminate [
	debugger safeServiceCall: [ debugger service terminate ] default: false.
	debugger service ifNotNil: [
		[ debugger service processOop: nil ] on: Exception do: [ ].
		[ debugger service instVarNamed: 'processOop' put: nil ] on: Exception do: [ ] ].
	[ debugger processOopSilently: nil ] on: Exception do: [ ].
	self abortGemStoneTransaction.
	debugger withWindowDo: [ :window | window close ]
]

{ #category : 'actions' }
GbsRemoteDebuggerExecutionController >> withRemoteDebuggerSessionDo: aBlock [
	^ [ aBlock value: debugger ]
		ensure: [ self closeRemoteDebuggerSession ]
]
