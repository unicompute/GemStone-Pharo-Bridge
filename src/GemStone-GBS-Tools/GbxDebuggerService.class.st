"
GbxDebuggerService is the main debugger service for GemStone remote debugging in Pharo 13.
It manages the debugged process, context list, and provides all debugging operations.

Based on VisualWorks GbxDebuggerService class.
"
Class {
	#name : 'GbxDebuggerService',
	#superclass : 'Object',
	#instVars : [
		'session',
		'processOop',
		'label',
		'contextStackPolicy',
		'currentContext',
		'selectionRange',
		'sourceMap',
		'receiverInspector',
		'contextInspector',
		'stackInspector',
		'tags',
		'pendingEvents',
		'doStepIntoBlock',
		'dontUpdateInspectors',
		'lastCompileError',
		'restartHomeResetPasses',
		'restartHomeLevel',
		'restartSourceString'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDebuggerService class >> context: aContext label: aString [
	"Create a debugger service for a GemStone process context"
	^ self new
		context: aContext;
		label: aString;
		yourself
]

{ #category : 'instance creation' }
GbxDebuggerService class >> openOn: anErrorString process: processOop session: aSession [
	"Open a remote debugger on a GemStone process"
	| service |
	service := self new.
	service session: aSession.
	service processOop: processOop.
	service label: anErrorString.
	[
		service initializeForDebugging
	] on: Error do: [ :ex |
		Transcript
			show: 'GbxDebuggerService initializeForDebugging failed: ';
			show: ex messageText;
			cr
	].

	^ GbsRemoteDebugger
		openOn: anErrorString
		process: processOop
		session: aSession
		service: service
]

{ #category : 'doIt/accept/explain' }
GbxDebuggerService >> acceptTextFrom: textController [ ^ self compileController acceptTextFrom: textController ]

{ #category : 'private' }
GbxDebuggerService >> asBooleanResult: raw default: defaultBoolean [
	| value |
	value := raw.
	value ifNil: [ ^ defaultBoolean ].
	value = true ifTrue: [ ^ true ].
	value = false ifTrue: [ ^ false ].
	(value respondsTo: #asLocalString) ifTrue: [ value := value asLocalString ].
	(value respondsTo: #asString) ifFalse: [ ^ defaultBoolean ].
	value := value asString asLowercase.
	(#('true' '1' 'yes' 'ok') includes: value) ifTrue: [ ^ true ].
	(#('false' '0' 'no' 'nil' '') includes: value) ifTrue: [ ^ false ].
	^ defaultBoolean
]

{ #category : 'private' }
GbxDebuggerService >> actualServerQuickStepPointAfterRestart [ ^ self restartController actualServerQuickStepPointAfterRestart ]

{ #category : 'private' }
GbxDebuggerService >> actualServerQuickStepPointAtLevel: levelValue [ ^ self restartController actualServerQuickStepPointAtLevel: levelValue ]

{ #category : 'private-step points' }
GbxDebuggerService >> basicJumpToCaret [ ^ self stepPointController basicJumpToCaret ]

{ #category : 'actions' }
GbxDebuggerService >> basicReenterServerContext [ ^ self restartController basicReenterServerContext ]

{ #category : 'private-GS execution' }
GbxDebuggerService >> basicSendIntoServer [ ^ self serverExecutionController basicSendIntoServer ]

{ #category : 'private-GS execution' }
GbxDebuggerService >> basicServerStepInLevel: level [ ^ self serverExecutionController basicServerStepInLevel: level ]

{ #category : 'private-step points' }
GbxDebuggerService >> basicSkipToCaret [ ^ self stepPointController basicSkipToCaret ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpoint: aBreakPoint matchesSelection: anInterval [ ^ self breakpointController breakpoint: aBreakPoint matchesSelection: anInterval ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointClass [ ^ Smalltalk at: #GbxBreakPoint ifAbsent: [ nil ] ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointIntervalsInCurrentMethod [ ^ self breakpointController breakpointIntervalsInCurrentMethod ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointSummaryString [ ^ self breakpointController breakpointSummaryString ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointToRemoveIn: aTextWidget from: breakpoints [ ^ self breakpointController breakpointToRemoveIn: aTextWidget from: breakpoints ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointsInSelectedMethod [ ^ self breakpointController breakpointsInSelectedMethod ]

{ #category : 'actions-browsing' }
GbxDebuggerService >> browseClass [
	"Browse class - uses gbxBrowseClass: for server contexts"
	currentContext gbxIsServerContext ifTrue: [
		^ self gbxBrowseClass: currentContext homeReceiver
	].
	^ nil
]

{ #category : 'actions-browsing' }
GbxDebuggerService >> browseMethod [
	"Browse current method - uses gbxBrowseMethod: for server contexts"
	currentContext gbxIsServerContext ifTrue: [
		^ self gbxBrowseMethod: self selectedMethod
	].
	"For client contexts, standard browsing would be used"
	^ nil
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> browserClass [ ^ Smalltalk at: #GbxBrowser ifAbsent: [ nil ] ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointController [ ^ GbxDebuggerBreakpointController on: self ]

{ #category : 'private' }
GbxDebuggerService >> canExecuteOnDebugProcess [
	(self isSessionUsable and: [ processOop isNumber ]) ifFalse: [ ^ false ].
	^ processOop > 20
]

{ #category : 'inspector' }
GbxDebuggerService >> canInspectCurrentFrame [ ^ self inspectorController canInspectCurrentFrame ]

{ #category : 'inspector' }
GbxDebuggerService >> canInspectCurrentProcess [ ^ self inspectorController canInspectCurrentProcess ]

{ #category : 'inspector' }
GbxDebuggerService >> canInspectCurrentReceiver [ ^ self inspectorController canInspectCurrentReceiver ]

{ #category : 'testing' }
GbxDebuggerService >> canIssueContextCommand [ ^ currentContext isNotNil and: [ self isTerminated not ] ]

{ #category : 'testing' }
GbxDebuggerService >> canJumpToStepPoint [ ^ self canIssueContextCommand ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canManageBreakPoints [ ^ self breakpointController canManageBreakPoints ]

{ #category : 'testing' }
GbxDebuggerService >> canPause [ ^ self canResume ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canRemoveAllBreakPoints [ ^ self breakpointController canRemoveAllBreakPoints ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canRemoveBreakPoint [ ^ self breakpointController canRemoveBreakPoint ]

{ #category : 'testing' }
GbxDebuggerService >> canResume [ ^ self isTerminated not ]

{ #category : 'testing' }
GbxDebuggerService >> canReturnFromFrame [
	currentContext ifNil: [ ^ false ].
	(currentContext respondsTo: #gbxIsServerContext)
		ifTrue: [ currentContext gbxIsServerContext ifTrue: [ ^ false ] ].
	^ self canStepReturn
]

{ #category : 'testing' }
GbxDebuggerService >> canRunToStepPoint [ ^ self canIssueContextCommand ]

{ #category : 'testing' }
GbxDebuggerService >> canRunWithBreakAgain [ ^ self canResume and: [ self canIssueContextCommand ] ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canSetBreakPoint [ ^ self breakpointController canSetBreakPoint ]

{ #category : 'testing' }
GbxDebuggerService >> canStepInto [ ^ self canIssueContextCommand ]

{ #category : 'testing' }
GbxDebuggerService >> canStepOver [ ^ self canIssueContextCommand ]

{ #category : 'testing' }
GbxDebuggerService >> canStepReturn [ ^ self canIssueContextCommand ]

{ #category : 'testing' }
GbxDebuggerService >> canTerminate [ ^ self isTerminated not ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canToggleBreakPoint [ ^ self breakpointController canToggleBreakPoint ]

{ #category : 'evaluation' }
GbxDebuggerService >> clearCompileError [ ^ self compileController clearCompileError ]

{ #category : 'private' }
GbxDebuggerService >> compileController [ ^ GbxDebuggerCompileController on: self ]

{ #category : 'private' }
GbxDebuggerService >> compileErrorValue [ ^ lastCompileError ]

{ #category : 'private' }
GbxDebuggerService >> compileErrorValue: aString [
	lastCompileError := aString
]

{ #category : 'private-step points' }
GbxDebuggerService >> closestLeftStepPoint [ ^ self stepPointController closestLeftStepPoint ]

{ #category : 'private-step points' }
GbxDebuggerService >> closestRightStepPoint [ ^ self stepPointController closestRightStepPoint ]

{ #category : 'accessing' }
GbxDebuggerService >> contextList [
	contextStackPolicy ifNil: [ ^ #( ) ].
	^ contextStackPolicy contextList
]

{ #category : 'accessing' }
GbxDebuggerService >> contextStackPolicy [ ^ contextStackPolicy ]

{ #category : 'evaluation' }
GbxDebuggerService >> correctCurrentSelectorWithSource: sourceText [ ^ self compileController correctCurrentSelectorWithSource: sourceText ]

{ #category : 'context list' }
GbxDebuggerService >> correctSelectedContextIfGlue [
	"If the currently selected context should be hidden glue,
	change the selection to a top visible context.
	The hidden glue must be at the top of the stack, so the
	correct context to show is the top visible context."
	(contextStackPolicy isHiddenGlue: currentContext) ifTrue: [
		"It is glue - reselect top visible context"
		self recomputeContextList.
		"Top visible is likely server context, must recompute"
		self selectContextAt: 1
	]
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> currentBreakPointList [ ^ self breakpointController currentBreakPointList ]

{ #category : 'accessing' }
GbxDebuggerService >> currentContext [ ^ currentContext ]

{ #category : 'accessing' }
GbxDebuggerService >> currentContext: aContext [
	currentContext := aContext.
	self updateSourceMapFromCurrentContext
]

{ #category : 'inspector' }
GbxDebuggerService >> currentContextLevel [ ^ self inspectorController currentContextLevel ]

{ #category : 'evaluation' }
GbxDebuggerService >> currentExecutionContextOop [ ^ self inspectorController currentExecutionContextOop ]

{ #category : 'inspector' }
GbxDebuggerService >> currentFrameOop [ ^ self inspectorController currentFrameOop ]

{ #category : 'inspector' }
GbxDebuggerService >> currentProcessOop [ ^ self inspectorController currentProcessOop ]

{ #category : 'inspector' }
GbxDebuggerService >> currentReceiverOop [ ^ self inspectorController currentReceiverOop ]

{ #category : 'source code' }
GbxDebuggerService >> currentSourceSelectionInterval [ ^ self stepPointController currentSourceSelectionInterval ]

{ #category : 'source code' }
GbxDebuggerService >> currentStepPoint [ ^ self stepPointController currentStepPoint ]

{ #category : 'actions' }
GbxDebuggerService >> cutbackClientContextsAbove: gsContext [ ^ self restartController cutbackClientContextsAbove: gsContext ]

{ #category : 'actions' }
GbxDebuggerService >> cutbackGsProcessesAbove: clientContext [ ^ self restartController cutbackGsProcessesAbove: clientContext ]

{ #category : 'actions' }
GbxDebuggerService >> cutbackGsTo: gsContext [ ^ self restartController cutbackGsTo: gsContext ]

{ #category : 'actions' }
GbxDebuggerService >> cutbackTo: aContext finishWith: aBlock [ ^ self restartController cutbackTo: aContext finishWith: aBlock ]

{ #category : 'actions' }
GbxDebuggerService >> cutbackToGsContext: gsContext finishWith: finishBlockArg [
	^ self restartController
		cutbackToGsContext: gsContext
		finishWith: finishBlockArg
]

{ #category : 'actions' }
GbxDebuggerService >> cutbackToGsProcessOf: gsContext [ ^ self restartController cutbackToGsProcessOf: gsContext ]

{ #category : 'private-step points' }
GbxDebuggerService >> earliestOverlappingStepPoint [ ^ self stepPointController earliestOverlappingStepPoint ]

{ #category : 'private-step points' }
GbxDebuggerService >> earliestSelectedStepPoint [ ^ self stepPointController earliestSelectedStepPoint ]

{ #category : 'private' }
GbxDebuggerService >> effectiveServerStepLevel [ ^ self stepPointController effectiveServerStepLevel ]

{ #category : 'stack manipulation' }
GbxDebuggerService >> emergencyRestart: ex [ ^ self restartController emergencyRestart: ex ]

{ #category : 'private' }
GbxDebuggerService >> ensureRestartAtStepOne [ ^ self restartController ensureRestartAtStepOne ]

{ #category : 'evaluation' }
GbxDebuggerService >> evaluateCodeInCurrentFrame: codeString [ ^ self inspectorController evaluateCodeInCurrentFrame: codeString ]

{ #category : 'private-event processing' }
GbxDebuggerService >> eventOrder [
	"Define event processing order for debugger updates"
	^ #( #contextList #text #pc #label )
]

{ #category : 'private' }
GbxDebuggerService >> fetchRemoteScript: scriptString context: contextOop [
	^ GbsRemoteExecutionDispatcher
		fetchScript: scriptString
		in: session
		context: contextOop
]

{ #category : 'actions' }
GbxDebuggerService >> firstServerContextAbove: clientContext [
	"Return the first server context above clientContext in the logical stack."
	| ctxList gsContext i ctx numContexts |
	ctxList := self contextList.
	gsContext := nil.
	i := 1.
	ctx := nil.
	numContexts := ctxList size.
	[ i <= numContexts and: [ ctx ~~ clientContext ] ] whileTrue: [
		ctx := ctxList at: i.
		((ctx respondsTo: #gbxIsServerContext) and: [ ctx gbxIsServerContext ])
			ifTrue: [ gsContext := ctx ].
		i := i + 1
	].
	ctx == clientContext ifFalse: [ ^ nil ].
	^ gsContext
]

{ #category : 'private' }
GbxDebuggerService >> forceRestartPositionToMethodStart [ ^ self restartController forceRestartPositionToMethodStart ]

{ #category : 'private-GS execution' }
GbxDebuggerService >> gbsErrorClass [
	"Get the GbsError class for exception handling"
	^ Smalltalk at: #GbsError ifAbsent: [ Error ]
]

{ #category : 'actions-browsing' }
GbxDebuggerService >> gbxBrowseClass: aDelegate [ ^ GbxDebuggerBrowseController browseClass: aDelegate ]

{ #category : 'actions-browsing' }
GbxDebuggerService >> gbxBrowseMethod: delegate [ ^ GbxDebuggerBrowseController browseMethod: delegate ]

{ #category : 'doIt/accept/explain' }
GbxDebuggerService >> gbxMethodChanged: newSource [
	"Handle method change - cutback to home context, update source, and refresh display"
	| newContext |
	newContext := self homeContextForCutback.
	newContext ifNil: [ ^ self ].
	
	self cutbackTo: newContext
		finishWith: [
			self performDebugOperation: [
				"Simulate a return value on top client glue context so we don't underflow the stack"
				self topContext ifNotNil: [ :top | top push: nil ].
				sourceMap := newContext visibleSourceMap.
				self selectTopServerContext.
				self scheduleContextListUpdate
			]
		].
	
	currentContext gbxIsServerContext ifTrue: [
		currentContext sourceString: newSource.
		newContext sourceString: newSource
	].
	
	self scheduleTextUpdate.
	self processEvents
]

{ #category : 'doIt/accept/explain' }
GbxDebuggerService >> gbxRecompileMethod: sourceText notifying: requestor [ ^ self compileController gbxRecompileMethod: sourceText notifying: requestor ]

{ #category : 'accessing' }
GbxDebuggerService >> glueIsHidden [ ^ contextStackPolicy glueIsHidden ]

{ #category : 'accessing' }
GbxDebuggerService >> glueIsHidden: aBoolean [
	contextStackPolicy glueIsHidden: aBoolean
]

{ #category : 'evaluation' }
GbxDebuggerService >> gsDoIt: codeString [
	| raw |
	raw := self evaluateCodeInCurrentFrame: codeString.
	^ raw notNil and: [ (raw beginsWith: 'Error:') not ]
]

{ #category : 'evaluation' }
GbxDebuggerService >> gsInspectIt: codeString [
	| contextOop resultOop |
	codeString ifNil: [ ^ false ].
	self isSessionUsable ifFalse: [ ^ false ].
	contextOop := self currentExecutionContextOop.
	contextOop ifNil: [ ^ false ].
	resultOop := [
		session serverInterface
			apiGciExecuteStr: codeString
			context: contextOop
			env: 0
	] on: Error do: [ nil ].
	^ self openInspectorOnOop: resultOop
]

{ #category : 'evaluation' }
GbxDebuggerService >> gsPrintIt: codeString [
	| script |
	codeString ifNil: [ ^ nil ].
	script := '[ ', codeString, ' ] value printString'.
	^ self evaluateCodeInCurrentFrame: script
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> hasBreakPointIn: aTextWidget [ ^ self breakpointController hasBreakPointIn: aTextWidget ]

{ #category : 'testing' }
GbxDebuggerService >> hasLoopControlContext [
	"VW compatibility hook for Next Loop enablement."
	^ false
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> highlightBreakPointsIn: aText [ ^ self breakpointController highlightBreakPointsIn: aText ]

{ #category : 'doIt/accept/explain' }
GbxDebuggerService >> homeContextForCutback [
	"Get the home context for cutback operations.
	This is typically the current context or its home for blocks."
	^ currentContext
]

{ #category : 'initialization' }
GbxDebuggerService >> initialize [
	super initialize.
	tags := Set new.
	pendingEvents := OrderedCollection new.
	dontUpdateInspectors := false.
	lastCompileError := nil.
	restartHomeResetPasses := 0.
	restartHomeLevel := nil.
	restartSourceString := nil.
]

{ #category : 'initialization' }
GbxDebuggerService >> initializeForDebugging [
	"Initialize the debugger for a new debugging session"
	contextStackPolicy := GbxContextListPolicy debugger: self.
	contextStackPolicy computeContextList.
	
	contextStackPolicy contextList ifNotEmpty: [ :contexts |
		currentContext := contexts first.
	].
	self updateSourceMapFromCurrentContext.
	restartHomeLevel := self restartLevelFromServerStack.
	(restartSourceString isNil or: [ restartSourceString isEmpty ]) ifTrue: [
		restartSourceString := self sourceStringForRestartContext: currentContext
	].
]

{ #category : 'inspector' }
GbxDebuggerService >> inspectCurrentFrame [ ^ self inspectorController inspectCurrentFrame ]

{ #category : 'inspector' }
GbxDebuggerService >> inspectCurrentProcess [ ^ self inspectorController inspectCurrentProcess ]

{ #category : 'inspector' }
GbxDebuggerService >> inspectCurrentReceiver [ ^ self inspectorController inspectCurrentReceiver ]

{ #category : 'inspector' }
GbxDebuggerService >> inspectVariableNamed: aVariableName [ ^ self inspectorController inspectVariableNamed: aVariableName ]

{ #category : 'inspector' }
GbxDebuggerService >> inspectorClass [ ^ GbsInspector ]

{ #category : 'private' }
GbxDebuggerService >> inspectorController [ ^ GbxDebuggerInspectorController on: self ]

{ #category : 'private' }
GbxDebuggerService >> isCurrentExecutedCodeFrame [
	| className selectorName |
	currentContext ifNil: [ ^ false ].
	((currentContext respondsTo: #isExecutedCodeFrame)
		and: [ currentContext isExecutedCodeFrame ]) ifTrue: [ ^ true ].
	className := [ currentContext methodClassOrUnknown asString ] on: Error do: [ '' ].
	selectorName := [ currentContext selectorOrUnknown asString ] on: Error do: [ '' ].
	^ (className = 'nil' or: [ className = '<unknown>' ])
		and: [ selectorName = 'nil' or: [ selectorName = 'unboundMethod' ] ]
]

{ #category : 'private' }
GbxDebuggerService >> isExecutedCodeAtStepOne [
	^ self isCurrentExecutedCodeFrame
		and: [ (self currentStepPoint ifNil: [ 0 ]) = 1 ]
]

{ #category : 'private' }
GbxDebuggerService >> restartNeedsFreshFaultReplay [ ^ self restartController restartNeedsFreshFaultReplay ]

{ #category : 'testing' }
GbxDebuggerService >> isMethodContextSelected [
	currentContext ifNil: [ ^ false ].
	(currentContext respondsTo: #isExecutedCodeFrame)
		ifTrue: [ ^ currentContext isExecutedCodeFrame not ].
	^ true
]

{ #category : 'private' }
GbxDebuggerService >> isSessionUsable [
	| loggedIn |
	session ifNil: [ ^ false ].
	(session respondsTo: #isLoggedIn) ifFalse: [ ^ true ].
	loggedIn := [ session isLoggedIn ] on: Error do: [ false ].
	^ loggedIn = true
]

{ #category : 'process control' }
GbxDebuggerService >> isTerminated [ ^ self processController isTerminated ]

{ #category : 'process control' }
GbxDebuggerService >> jumpToStepPoint: aStepPoint [
	((aStepPoint isNumber and: [ aStepPoint > 0 ]) not) ifTrue: [ ^ false ].
	(self runDebugProcessCommand: 'jumpToStepPoint' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	(self runDebugProcessCommand: 'jumpTo' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'accessing' }
GbxDebuggerService >> label [ ^ label ]

{ #category : 'accessing' }
GbxDebuggerService >> label: aString [
	label := self presenterTextFrom: aString
]

{ #category : 'evaluation' }
GbxDebuggerService >> lastCompileError [ ^ self compileController lastCompileError ]

{ #category : 'private' }
GbxDebuggerService >> logRestartState: labelString context: aContext [
	"Restart diagnostics hook. Keep as no-op by default."
	^ self
]

{ #category : 'private' }
GbxDebuggerService >> logRestartText: aString [
	"Restart diagnostics hook. Keep as no-op by default."
	^ self
]

{ #category : 'private' }
GbxDebuggerService >> markCurrentContextAsRestarted [ ^ self restartController markCurrentContextAsRestarted ]

{ #category : 'private' }
GbxDebuggerService >> normalizeExecutedCodeSingleStepFrom: previousStepPoint [
	| currentStep target |
	(previousStepPoint isNumber and: [ previousStepPoint > 0 ]) ifFalse: [ ^ true ].
	self isCurrentExecutedCodeFrame ifFalse: [ ^ true ].
	currentStep := self currentStepPoint.
	target := previousStepPoint + 1.
	currentStep = target ifTrue: [ ^ true ].
	self
		logRestartText:
			'normalize single-step previous=', previousStepPoint asString,
			' current=', (currentStep ifNil: [ 'nil' ] ifNotNil: [ currentStep asString ]),
			' target=', target asString.
	(self jumpToStepPoint: target) ifTrue: [ ^ true ].
	(self runToStepPoint: target) ifTrue: [ ^ true ].
	^ true
]

{ #category : 'evaluation' }
GbxDebuggerService >> normalizedCompileErrorFrom: rawResult [ ^ self compileController normalizedCompileErrorFrom: rawResult ]

{ #category : 'stack accessing' }
GbxDebuggerService >> notifierStackStringOfSize: n [ ^ GbxDebuggerServicePresenter notifierStackStringOfSize: n for: self ]

{ #category : 'context list' }
GbxDebuggerService >> notifyContextChanged [
	"Notify that the context has changed"
	"UI update would happen here"
]

{ #category : 'inspector' }
GbxDebuggerService >> oopForVariableNamed: aVariableName [ ^ self inspectorController oopForVariableNamed: aVariableName ]

{ #category : 'inspector' }
GbxDebuggerService >> openInspectorOnOop: anOop [ ^ self inspectorController openInspectorOnOop: anOop ]

{ #category : 'private-inspectors' }
GbxDebuggerService >> openInspectors [ ^ self inspectorController openInspectors ]

{ #category : 'process control' }
GbxDebuggerService >> pause [ ^ self processController pause ]

{ #category : 'private-support' }
GbxDebuggerService >> pendingMessage [ ^ GbxDebuggerServicePresenter pendingMessageForContext: currentContext ]

{ #category : 'private' }
GbxDebuggerService >> presenterTextFrom: aValue [ ^ GbxDebuggerServicePresenter presenterTextFrom: aValue ]

{ #category : 'private' }
GbxDebuggerService >> processController [ ^ GbxDebuggerProcessController on: self ]

{ #category : 'private' }
GbxDebuggerService >> restartController [ ^ GbxDebuggerRestartController on: self ]

{ #category : 'private' }
GbxDebuggerService >> serverExecutionController [ ^ GbxDebuggerServerExecutionController on: self ]

{ #category : 'private' }
GbxDebuggerService >> prepareForDebugging [
	"Prepare the debugger for a new debugging session"
	self initializeForDebugging.
]

{ #category : 'private-GS execution' }
GbxDebuggerService >> privateStep [
	"Perform a private step operation.
	This is used internally for basicSendIntoServer."
	^ self stepInto
]

{ #category : 'private' }
GbxDebuggerService >> processEvents [
	"Process pending UI events"
	| events |
	events := pendingEvents asArray.
	pendingEvents removeAll.
	events do: [ :event | event value ].
]

{ #category : 'accessing' }
GbxDebuggerService >> processOop [ ^ processOop ]

{ #category : 'accessing' }
GbxDebuggerService >> processOop: anOop [
	processOop := anOop.
	restartHomeLevel := nil
]

{ #category : 'accessing' }
GbxDebuggerService >> restartSourceString [ ^ restartSourceString ifNil: [ '' ] ]

{ #category : 'accessing' }
GbxDebuggerService >> restartSourceString: aString [
	restartSourceString := aString
]

{ #category : 'variables' }
GbxDebuggerService >> receiver [
	"Get the receiver of the current context"
	currentContext ifNil: [ ^ nil ].
	^ currentContext receiver
]

{ #category : 'variables' }
GbxDebuggerService >> receiverClass [
	"Get the class of the receiver"
	currentContext ifNil: [ ^ nil ].
	^ currentContext receiverClass
]

{ #category : 'evaluation' }
GbxDebuggerService >> recompileCurrentMethodWithSource: sourceText [ ^ self compileController recompileCurrentMethodWithSource: sourceText ]

{ #category : 'context list' }
GbxDebuggerService >> recomputeContextList [ ^ GbxDebuggerServicePresenter recomputeContextListFor: self ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> removeAllBreakPoints [ ^ self breakpointController removeAllBreakPoints ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> removeBreakIn: aTextWidget [ ^ self breakpointController removeBreakIn: aTextWidget ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> removeBreakPoint [ ^ self breakpointController removeBreakPoint ]

{ #category : 'private-GS execution' }
GbxDebuggerService >> requestServerSingleStep [
	"About to send from client to server. Set the single step flag for the session."
	| sess |
	(currentContext respondsTo: #gbxPeekForReceiver) ifFalse: [ ^ self ].
	sess := currentContext gbxPeekForReceiver gbxGsDebuggerSession.
	sess ifNil: [ ^ self ].
	sess serverInterface requestSingleStep
]

{ #category : 'private-GS execution' }
GbxDebuggerService >> resetPCSelection [
	"Reset PC selection - update source map before stepping"
	self updateSourceMapFromCurrentContext
]

{ #category : 'private' }
GbxDebuggerService >> resetServerPCToStepOne [ ^ self processController resetServerPCToStepOne ]

{ #category : 'process control' }
GbxDebuggerService >> restart [ ^ self restartController restart ]

{ #category : 'private' }
GbxDebuggerService >> restartLevelFromServerStack [ ^ self processController restartLevelFromServerStack ]

{ #category : 'private' }
GbxDebuggerService >> resolvedRestartHomeLevel [
	| resolved |
	(restartHomeLevel isNumber and: [ restartHomeLevel > 0 ]) ifTrue: [ ^ restartHomeLevel ].
	resolved := self restartLevelFromServerStack.
	(resolved isNumber and: [ resolved > 0 ]) ifTrue: [
		restartHomeLevel := resolved.
		^ resolved
	].
	resolved := self currentContextLevel.
	(resolved isNumber and: [ resolved > 0 ]) ifTrue: [ ^ resolved ].
	^ 1
]

{ #category : 'private' }
GbxDebuggerService >> restartTargetContext [ ^ self restartController restartTargetContext ]

{ #category : 'private' }
GbxDebuggerService >> sourceStringForRestartContext: aContext [ ^ self restartController sourceStringForRestartContext: aContext ]

{ #category : 'process control' }
GbxDebuggerService >> resume [ ^ self processController resume ]

{ #category : 'process control' }
GbxDebuggerService >> returnFromFrame [
	self canReturnFromFrame ifFalse: [ ^ false ].
	^ self stepReturn
]

{ #category : 'private' }
GbxDebuggerService >> runDebugProcessCommand: commandName recompute: shouldRecompute [
	^ self processController
		runDebugProcessCommand: commandName
		recompute: shouldRecompute
]

{ #category : 'private' }
GbxDebuggerService >> runDebugProcessCommand: commandName withInteger: anInteger recompute: shouldRecompute [
	^ self processController
		runDebugProcessCommand: commandName
		withInteger: anInteger
		recompute: shouldRecompute
]

{ #category : 'process control' }
GbxDebuggerService >> runToStepPoint: aStepPoint [ ^ self processController runToStepPoint: aStepPoint ]

{ #category : 'process control' }
GbxDebuggerService >> runWithBreakAgain [ ^ self processController runWithBreakAgain ]

{ #category : 'private-event processing' }
GbxDebuggerService >> scheduleContextListUpdate [
	"Schedule a full context list recomputation and update"
	self recomputeContextList
]

{ #category : 'private-event processing' }
GbxDebuggerService >> scheduleLabelUpdate [
	"Schedule debugger label update"
	"UI would refresh the debugger title/label"
]

{ #category : 'private-event processing' }
GbxDebuggerService >> schedulePCUpdate [
	"Schedule program counter (source highlight) update"
	"UI would refresh the source code highlighting"
	self updateSourceMapFromCurrentContext
]

{ #category : 'private-event processing' }
GbxDebuggerService >> schedulePrecomputedContextListUpdate [
	self updatePrecomputedContextList
]

{ #category : 'private-event processing' }
GbxDebuggerService >> scheduleTextUpdate [
	"Schedule source text display update"
	"UI would refresh the source code display"
	self notifyContextChanged
]

{ #category : 'context list' }
GbxDebuggerService >> selectContext: aContext [
	"Select a specific context"
	currentContext == aContext ifTrue: [ ^ self ].
	currentContext := aContext.
	self updateSourceMapFromCurrentContext.
	self notifyContextChanged.
]

{ #category : 'context list' }
GbxDebuggerService >> selectContextAt: anIndex [
	"Select a context by index in the context list"
	| contexts |
	contexts := self contextList.
	anIndex <= contexts size ifTrue: [
		currentContext := contexts at: anIndex.
		self updateSourceMapFromCurrentContext.
		self notifyContextChanged.
	].
]

{ #category : 'private' }
GbxDebuggerService >> selectRestartTargetContext [
	| target |
	target := self restartTargetContext.
	target ifNil: [ ^ self ].
	self selectContext: target
]

{ #category : 'context list' }
GbxDebuggerService >> selectTopServerContext [
	"The stack has changed. Recompute and select the top GemStone context.
	Then refresh the displayed list without a second recompute."
	| topServer |
	contextStackPolicy ifNil: [ ^ self ].
	contextStackPolicy computeContextList.
	topServer := self restartTargetContext.
	topServer ifNil: [
		topServer := (contextStackPolicy respondsTo: #topServerContext)
			ifTrue: [ contextStackPolicy topServerContext ]
			ifFalse: [ nil ]
	].
	topServer ifNil: [
		topServer := contextStackPolicy contextList
			ifEmpty: [ nil ]
			ifNotEmpty: [ :contexts | contexts first ]
	].
	topServer ifNotNil: [ self selectContext: topServer ].
	self schedulePrecomputedContextListUpdate
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> selectedMethodClassName [ ^ self breakpointController selectedMethodClassName ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> selectedMethodSelector [ ^ self breakpointController selectedMethodSelector ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> selectionIntervalForTextWidget: aTextWidget [ ^ self breakpointController selectionIntervalForTextWidget: aTextWidget ]

{ #category : 'private' }
GbxDebuggerService >> serverStepOverFrameLevel: levelValue [ ^ self processController serverStepOverFrameLevel: levelValue ]

{ #category : 'private' }
GbxDebuggerService >> serverStepWithSelectorChain: selectorChain level: levelValue [
	^ self processController
		serverStepWithSelectorChain: selectorChain
		level: levelValue
]

{ #category : 'accessing' }
GbxDebuggerService >> selectionRange [ ^ selectionRange ]

{ #category : 'accessing' }
GbxDebuggerService >> selectionRange: anInterval [
	selectionRange := anInterval
]

{ #category : 'accessing' }
GbxDebuggerService >> session [ ^ session ]

{ #category : 'accessing' }
GbxDebuggerService >> session: aSession [
	session := aSession
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> setBreakPoint [ ^ self breakpointController setBreakPoint ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> setBreakPointIn: aTextWidget [ ^ self breakpointController setBreakPointIn: aTextWidget ]

{ #category : 'source code' }
GbxDebuggerService >> sourceCode [
	currentContext ifNil: [ ^ '' ].
	^ currentContext sourceCode
]

{ #category : 'source code' }
GbxDebuggerService >> sourceMap [
	"Get the source map for highlighting"
	currentContext ifNil: [ sourceMap := #( ). ^ sourceMap ].
	sourceMap ifNil: [ self updateSourceMapFromCurrentContext ].
	^ sourceMap
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> sourceMatchesCurrentMethodIn: aTextWidget [ ^ self breakpointController sourceMatchesCurrentMethodIn: aTextWidget ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> sourceOffsetForBreakPoint: aBreakPoint [ ^ self breakpointController sourceOffsetForBreakPoint: aBreakPoint ]

{ #category : 'private' }
GbxDebuggerService >> stepController [ ^ GbxDebuggerStepController on: self ]

{ #category : 'private' }
GbxDebuggerService >> stepPointController [ ^ GbxDebuggerStepPointController on: self ]

{ #category : 'actions' }
GbxDebuggerService >> stackForCopy [
	| cp |
	cp := Smalltalk at: #GbxContextDumpPolicy ifAbsent: [ ^ self stackForCopySimple ].
	cp := cp new.
	cp stack: contextStackPolicy contextList.
	cp errorMessage: label.
	^ cp copyStackString
]

{ #category : 'actions' }
GbxDebuggerService >> stackForCopySimple [ ^ GbxDebuggerServicePresenter stackForCopySimpleFor: self ]

{ #category : 'stepping' }
GbxDebuggerService >> step [ ^ self stepController step ]

{ #category : 'private-GS execution' }
GbxDebuggerService >> stepOutOfServerIntoClient [ ^ self serverExecutionController stepOutOfServerIntoClient ]

{ #category : 'stepping' }
GbxDebuggerService >> stepOver [ ^ self stepController stepOver ]

{ #category : 'stepping' }
GbxDebuggerService >> stepInto [ ^ self stepController stepInto ]

{ #category : 'stepping' }
GbxDebuggerService >> stepReturn [ ^ self stepController stepReturn ]

{ #category : 'stepping' }
GbxDebuggerService >> stepUntilPC: stopPC [ ^ self stepController stepUntilPC: stopPC ]

{ #category : 'private' }
GbxDebuggerService >> synchronizeServerProgramCounterAfterRestart [ ^ self restartController synchronizeServerProgramCounterAfterRestart ]

{ #category : 'variables' }
GbxDebuggerService >> tempNamesAndValues [
	"Get temp variable names and values for current context"
	currentContext ifNil: [ ^ #( ) ].
	^ currentContext tempNamesAndValues
]

{ #category : 'process control' }
GbxDebuggerService >> terminate [ ^ self processController terminate ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> toggleBreakPoint [ ^ self breakpointController toggleBreakPoint ]

{ #category : 'breakpoint support' }
GbxDebuggerService >> toggleBreakPointIn: aTextWidget [ ^ self breakpointController toggleBreakPointIn: aTextWidget ]

{ #category : 'private' }
GbxDebuggerService >> toggleGlueHiding [
	self glueIsHidden: self glueIsHidden not.
	self recomputeContextList.
]

{ #category : 'accessing' }
GbxDebuggerService >> topContext [ ^ thisContext sender ]

{ #category : 'private-event processing' }
GbxDebuggerService >> updatePrecomputedContextList [
	self updateStackList: self contextList
]

{ #category : 'source code' }
GbxDebuggerService >> updateSourceMapFromCurrentContext [
	sourceMap := currentContext
		ifNil: [ #( ) ]
		ifNotNil: [
			[ currentContext visibleSourceMap ] on: Error do: [ #( ) ]
		].
	self currentSourceSelectionInterval.
]

{ #category : 'context list' }
GbxDebuggerService >> updateStackList: aList [
]
