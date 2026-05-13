Class {
	#name : 'GbsRemoteDebuggerRestartController',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerRestartController class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'accessing' }
GbsRemoteDebuggerRestartController >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerRestartController >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'restart' }
GbsRemoteDebuggerRestartController >> restart [
	| didRestart |
	didRestart := self restartUsingCurrentProcessAndRefresh.
	(didRestart and: [ self restartNeedsServerRewind ])
		ifTrue: [ ^ self restartUsingFreshFaultedProcess ].
	^ didRestart
]

{ #category : 'restart' }
GbsRemoteDebuggerRestartController >> restartNeedsServerRewind [
	| replayNeeded executed step |
	replayNeeded := debugger
		safeServiceCall: [ debugger service restartNeedsFreshFaultReplay ]
		default: nil.
	replayNeeded ifNotNil: [ ^ replayNeeded ].
	(debugger contextList isNil or: [ debugger contextList isEmpty ]) ifTrue: [ ^ false ].
	executed := debugger contextList
		detect: [ :ctx |
			(ctx respondsTo: #isExecutedCodeFrame)
				and: [ ctx isExecutedCodeFrame ] ]
		ifNone: [ nil ].
	executed ifNil: [ ^ false ].
	step := (executed respondsTo: #quickStepPoint)
		ifTrue: [ [ executed quickStepPoint asInteger ] on: Error do: [ 0 ] ]
		ifFalse: [ 0 ].
	^ step > 1
]

{ #category : 'restart' }
GbsRemoteDebuggerRestartController >> restartReplayContext [
	| contexts |
	contexts := debugger contextList ifNil: [ #() ].
	^ contexts
		detect: [ :ctx |
			(ctx respondsTo: #isExecutedCodeFrame)
				and: [ ctx isExecutedCodeFrame ] ]
		ifNone: [
			(debugger service notNil and: [ debugger service respondsTo: #contextList ])
				ifTrue: [
					(debugger service contextList ifNil: [ #() ])
						detect: [ :ctx |
							(ctx respondsTo: #isExecutedCodeFrame)
								and: [ ctx isExecutedCodeFrame ] ]
						ifNone: [ nil ] ]
				ifFalse: [ nil ] ]
]

{ #category : 'restart' }
GbsRemoteDebuggerRestartController >> restartReplaySourceCode [
	| context source |
	source := (debugger service notNil and: [ debugger service respondsTo: #restartSourceString ])
		ifTrue: [ [ debugger service restartSourceString ] on: Error do: [ '' ] ]
		ifFalse: [ '' ].
	(source isString and: [ source isEmpty not ]) ifTrue: [ ^ source ].
	context := self restartReplayContext.
	context ifNotNil: [
		source := (context respondsTo: #sourceString)
			ifTrue: [ [ context sourceString ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		(source isString and: [ source isEmpty not ]) ifTrue: [ ^ source ].
		source := (context respondsTo: #sourceCode)
			ifTrue: [ [ context sourceCode ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		(source isString and: [ source isEmpty not ]) ifTrue: [ ^ source ] ].
	^ self restartReplaySourceText
]

{ #category : 'restart' }
GbsRemoteDebuggerRestartController >> restartReplaySourceText [
	debugger sourceTextPresenter ifNil: [ ^ '' ].
	^ (debugger sourceTextPresenter respondsTo: #text)
		ifTrue: [ [ debugger sourceTextPresenter text asString ] on: Error do: [ '' ] ]
		ifFalse: [ '' ]
]

{ #category : 'restart' }
GbsRemoteDebuggerRestartController >> restartUsingCurrentProcessAndRefresh [
	| didRestart hasServiceRestart |
	hasServiceRestart := debugger service notNil and: [ debugger service respondsTo: #restart ].
	didRestart := hasServiceRestart
		ifTrue: [ debugger safeServiceCall: [ debugger service restart ] default: false ]
		ifFalse: [ debugger restartUsingDirectTrimFromExecutedFrame ].
	didRestart ifTrue: [
		debugger fetchStackFrames.
		debugger ensureServerPCToStepOneAfterRestart.
		debugger fetchStackFrames.
		debugger normalizeRestartSelectionAndPosition ].
	^ didRestart
]

{ #category : 'restart' }
GbsRemoteDebuggerRestartController >> restartUsingFreshFaultedProcess [
	| code errorText newProcessOop didRestart |
	debugger session ifNil: [ ^ false ].
	code := self restartReplaySourceCode.
	code isEmpty ifTrue: [ ^ false ].
	errorText := nil.
	newProcessOop := nil.
	[
		debugger session execute: code.
		^ false
	] on: GbsError do: [ :ex |
		errorText := debugger presenterTextFrom: ex messageText.
		newProcessOop := debugger processOopFromGbsError: ex ].
	((newProcessOop isNumber and: [ newProcessOop > 20 ]) not) ifTrue: [ ^ false ].
	debugger safeServiceCall: [ debugger service terminate ] default: false.
	debugger processOop: newProcessOop.
	debugger label: errorText.
	debugger service ifNotNil: [
		(debugger service respondsTo: #processOop:)
			ifTrue: [ debugger service processOop: newProcessOop ].
		(debugger service respondsTo: #label:)
			ifTrue: [ debugger service label: errorText ].
		(debugger service respondsTo: #initializeForDebugging)
			ifTrue: [ debugger service initializeForDebugging ] ].
	didRestart := self restartUsingCurrentProcessAndRefresh.
	^ didRestart
]
