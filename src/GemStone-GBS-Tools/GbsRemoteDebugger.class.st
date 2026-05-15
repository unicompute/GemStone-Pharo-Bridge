"A remote debugger for GemStone server execution from Pharo."
Class {
	#name : 'GbsRemoteDebugger',
	#superclass : 'SpPresenter',
	#instVars : [
		'service',
		'session',
		'processOop',
		'mainMenu',
		'contextList',
		'bookmarkContextIndex',
		'selectedContextIndex',
		'stackList',
		'sourceText',
		'variablesTable',
		'receiverInfoTable',
		'frameInfoTable',
		'processInfoTable',
		'stepOverButton',
		'stepIntoButton',
		'stepButton',
		'stepReturnButton',
		'restartButton',
		'resumeButton',
		'runUntilReturnButton',
		'runWithBreakAgainButton',
		'runToCaretButton',
		'jumpToCaretButton',
		'returnButton',
		'pauseButton',
		'terminateButton',
		'inspectReceiverButton',
		'inspectProcessButton',
		'inspectFrameButton',
		'inspectStackButton',
		'inspectVariableButton',
		'errorMessageLabel',
		'glueIsHidden',
		'stackData'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebugger class >> openOn: anErrorString process: processOop session: aSession [
	| service |
	service := GbxDebuggerService new.
	service session: aSession.
	service processOop: processOop.
	service label: anErrorString.
	service initializeForDebugging.

	^ self
		openOn: anErrorString
		process: processOop
		session: aSession
		service: service
]

{ #category : 'instance creation' }
GbsRemoteDebugger class >> openOn: anErrorString process: processOop session: aSession service: aService [
	| debugger |
	[aService glueIsHidden: false] on: Error do: [ ].
	debugger := self new.
	debugger service: aService.
	debugger session: aSession.
	debugger open.
	debugger label: anErrorString.
	debugger processOop: processOop.
	debugger withWindowDo: [ :win | win title: 'GemStone Remote Debugger' ].
	^ debugger
]

{ #category : 'actions' }
GbsRemoteDebugger >> abortGemStoneTransaction [ ^ self executionController abortGemStoneTransaction ]

{ #category : 'actions' }
GbsRemoteDebugger >> acceptSourceEdits [ ^ self sourcePaneController acceptSourceEdits ]

{ #category : 'private' }
GbsRemoteDebugger >> applyBreakpointEmphasisFor: aContext [ ^ self sourcePaneController applyBreakpointEmphasisFor: aContext ]

{ #category : 'private' }
GbsRemoteDebugger >> applySourceMapHighlightFor: aContext [ ^ self sourcePaneController applySourceMapHighlightFor: aContext ]

{ #category : 'private' }
GbsRemoteDebugger >> bookmarkContext [ ^ self stackNavigator bookmarkContext ]

{ #category : 'private' }
GbsRemoteDebugger >> browseLocalHierarchyImplementors [ ^ self methodNavigator browseLocalHierarchyImplementors ]

{ #category : 'private' }
GbsRemoteDebugger >> browseLocalHierarchyImplementorsFor: aSelector [ ^ self methodNavigator browseLocalHierarchyImplementorsFor: aSelector ]

{ #category : 'private' }
GbsRemoteDebugger >> browseLocalHierarchySenders [ ^ self methodNavigator browseLocalHierarchySenders ]

{ #category : 'private' }
GbsRemoteDebugger >> browseLocalHierarchySendersFor: aSelector [ ^ self methodNavigator browseLocalHierarchySendersFor: aSelector ]

{ #category : 'private' }
GbsRemoteDebugger >> browseLocalImplementors [ ^ self methodNavigator browseLocalImplementors ]

{ #category : 'private' }
GbsRemoteDebugger >> browseLocalImplementorsFor: aSelector [ ^ self methodNavigator browseLocalImplementorsFor: aSelector ]

{ #category : 'private' }
GbsRemoteDebugger >> browseLocalSenders [ ^ self methodNavigator browseLocalSenders ]

{ #category : 'private' }
GbsRemoteDebugger >> browseLocalSendersFor: aSelector [ ^ self methodNavigator browseLocalSendersFor: aSelector ]

{ #category : 'private' }
GbsRemoteDebugger >> browseSelectedMethod [ ^ self methodNavigator browseSelectedMethod ]

{ #category : 'menus' }
GbsRemoteDebugger >> buildMenuBar [ ^ self menuBuilder buildMenuBar ]

{ #category : 'private' }
GbsRemoteDebugger >> canAcceptRecompile [ ^ self safeServiceCall: [ service currentContext notNil ] default: false ]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectFrame [ ^ self inspectorActions canInspectFrame ]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectProcess [ ^ self inspectorActions canInspectProcess ]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectReceiver [ ^ self inspectorActions canInspectReceiver ]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectStack [ ^ self inspectorActions canInspectStack ]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectVariable [ ^ self inspectorActions canInspectVariable ]

{ #category : 'private' }
GbsRemoteDebugger >> canJumpToCaret [
	^ (self safeServiceCall: [ (service respondsTo: #canJumpToStepPoint)
		ifTrue: [ service canJumpToStepPoint ]
		ifFalse: [ self canStepInto ] ] default: false)
		and: [ self selectedStepPointFromCaret notNil ]
]

{ #category : 'private' }
GbsRemoteDebugger >> canPauseExecution [
	^ self safeServiceCall: [ (service respondsTo: #canPause)
		ifTrue: [ service canPause ]
		ifFalse: [ true ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canRemoveAllBreakpoints [ ^ self safeServiceCall: [ service canRemoveAllBreakPoints ] default: false ]

{ #category : 'private' }
GbsRemoteDebugger >> canRemoveBreakpoint [ ^ self safeServiceCall: [ service canRemoveBreakPoint ] default: false ]

{ #category : 'private' }
GbsRemoteDebugger >> canRestartExecution [ ^ self canStepInto ]

{ #category : 'private' }
GbsRemoteDebugger >> canResumeExecution [
	^ self safeServiceCall: [ (service respondsTo: #canResume)
		ifTrue: [ service canResume ]
		ifFalse: [ true ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canReturnFromFrameExecution [
	^ self safeServiceCall: [ (service respondsTo: #canReturnFromFrame)
		ifTrue: [ service canReturnFromFrame ]
		ifFalse: [ self canStepReturn ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canRunToCaret [
	^ (self safeServiceCall: [ (service respondsTo: #canRunToStepPoint)
		ifTrue: [ service canRunToStepPoint ]
		ifFalse: [ self canStepInto ] ] default: false)
		and: [ self selectedStepPointFromCaret notNil ]
]

{ #category : 'private' }
GbsRemoteDebugger >> canRunWithBreakAgainExecution [
	^ self safeServiceCall: [ (service respondsTo: #canRunWithBreakAgain)
		ifTrue: [ service canRunWithBreakAgain ]
		ifFalse: [ self canResumeExecution ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canSetBreakpoint [ ^ self safeServiceCall: [ service canSetBreakPoint ] default: false ]

{ #category : 'private' }
GbsRemoteDebugger >> canStepInto [
	^ self safeServiceCall: [ (service respondsTo: #canStepInto)
		ifTrue: [ service canStepInto ]
		ifFalse: [ service currentContext notNil ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canStepOver [
	^ self safeServiceCall: [ (service respondsTo: #canStepOver)
		ifTrue: [ service canStepOver ]
		ifFalse: [ service currentContext notNil ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canStepReturn [
	^ self safeServiceCall: [ (service respondsTo: #canStepReturn)
		ifTrue: [ service canStepReturn ]
		ifFalse: [ service currentContext notNil ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canTerminateExecution [
	^ self safeServiceCall: [ (service respondsTo: #canTerminate)
		ifTrue: [ service canTerminate ]
		ifFalse: [ true ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canToggleBreakpoint [ ^ self safeServiceCall: [ service canToggleBreakPoint ] default: false ]

{ #category : 'private' }
GbsRemoteDebugger >> chooseMethodReferenceFrom: references title: aTitle [
	| labels index |
	(references isCollection and: [ references isEmpty not ]) ifFalse: [ ^ nil ].
	labels := references collect: [ :each | each asString ].
	index := UIManager default chooseFrom: labels title: aTitle.
	index = 0 ifTrue: [ ^ nil ].
	^ labels at: index
]

{ #category : 'private' }
GbsRemoteDebugger >> clearBookmarkContext [ ^ self stackNavigator clearBookmarkContext ]

{ #category : 'private' }
GbsRemoteDebugger >> clearServiceCompileError [
	service ifNil: [ ^ self ].
	(service respondsTo: #clearCompileError)
		ifTrue: [ [ service clearCompileError ] on: Error do: [ ] ].
]

{ #category : 'private' }
GbsRemoteDebugger >> clearSourceHighlight [ ^ self sourcePaneController clearSourceHighlight ]

{ #category : 'private' }
GbsRemoteDebugger >> configureMenuItem: aMenuGroup named: labelText action: actionBlock enabled: enabledBoolean [
	aMenuGroup addItem: [ :item |
		item
			name: labelText;
			action: [ enabledBoolean ifTrue: [ actionBlock value ] ].
		(item respondsTo: #enabled:)
			ifTrue: [ item enabled: enabledBoolean ] ].
]

{ #category : 'actions' }
GbsRemoteDebugger >> contextSelected: selectedItem [ ^ self contextPresenter contextSelected: selectedItem ]

{ #category : 'private' }
GbsRemoteDebugger >> copyStackReport [
	| report |
	report := self stackReportString.
	report isEmpty ifTrue: [ ^ false ].
	Clipboard clipboardText: report.
	^ true
]

{ #category : 'menus' }
GbsRemoteDebugger >> correctMenu [ ^ self menuBuilder correctMenu ]

{ #category : 'private' }
GbsRemoteDebugger >> correctSelector [
	| code ok |
	service ifNil: [ ^ false ].
	code := self selectedSourceOrAll.
	code isEmpty ifTrue: [ ^ false ].
	ok := self safeServiceCall: [ service correctCurrentSelectorWithSource: code ] default: false.
	ok ifTrue: [
		self clearServiceCompileError.
		self fetchStackFrames
	] ifFalse: [
		self showCompileErrorInSourcePane
	].
	^ ok
]

{ #category : 'accessing' }
GbsRemoteDebugger >> contextList [ ^ contextList ]

{ #category : 'accessing' }
GbsRemoteDebugger >> contextList: aCollection [
	contextList := aCollection
]

{ #category : 'private' }
GbsRemoteDebugger >> contextPresenter [ ^ GbsRemoteDebuggerContextPresenter on: self ]

{ #category : 'private' }
GbsRemoteDebugger >> currentSelectedContextIsExecutedCodeFrame [ ^ self stackNavigator currentSelectedContextIsExecutedCodeFrame ]

{ #category : 'private' }
GbsRemoteDebugger >> currentSelectedFrameLevel [ ^ self stackNavigator currentSelectedFrameLevel ]

{ #category : 'layout' }
GbsRemoteDebugger >> defaultLayout [ ^ GbsRemoteDebuggerUiController defaultLayoutFor: self ]

{ #category : 'private' }
GbsRemoteDebugger >> directStepOverExecutedFrame: stepIntoBoolean [ ^ self processControl directStepOverExecutedFrame: stepIntoBoolean ]

{ #category : 'private' }
GbsRemoteDebugger >> directStepWithPrimarySelector: primarySelector fallbackSelector: fallbackSelector [
	^ self processControl
		directStepWithPrimarySelector: primarySelector
		fallbackSelector: fallbackSelector
]

{ #category : 'menus' }
GbsRemoteDebugger >> editMenu [ ^ self menuBuilder editMenu ]

{ #category : 'private' }
GbsRemoteDebugger >> ensureServerPCToStepOneAfterRestart [ ^ self processControl ensureServerPCToStepOneAfterRestart ]

{ #category : 'menus' }
GbsRemoteDebugger >> executeMenu [ ^ self menuBuilder executeMenu ]

{ #category : 'actions' }
GbsRemoteDebugger >> fetchContextsDirectly [ ^ (GbsRemoteDebuggerStackFetcher on: self) fetchContextsDirectly ]

{ #category : 'private' }
GbsRemoteDebugger >> fetchFullSourceFor: aContext [ ^ (GbsRemoteDebuggerSourceResolver on: self) fetchFullSourceFor: aContext ]

{ #category : 'private' }
GbsRemoteDebugger >> fetchRemoteScript: scriptString context: contextOop [
	^ GbsRemoteExecutionDispatcher
		fetchScript: scriptString
		in: session
		context: contextOop
]

{ #category : 'private' }
GbsRemoteDebugger >> executionController [ ^ GbsRemoteDebuggerExecutionController on: self ]

{ #category : 'actions' }
GbsRemoteDebugger >> fetchStackFrames [ ^ self stackLoader fetchStackFrames ]

{ #category : 'actions' }
GbsRemoteDebugger >> fetchStackFramesFromData [ ^ self stackLoader fetchStackFramesFromData ]

{ #category : 'private' }
GbsRemoteDebugger >> firstUserContextIndex [ ^ self stackNavigator preferredInitialContextIndex ]

{ #category : 'private' }
GbsRemoteDebugger >> forceExecutedFrameToStepOneAfterRestart [ ^ self processControl forceExecutedFrameToStepOneAfterRestart ]

{ #category : 'private' }
GbsRemoteDebugger >> forceServerJumpToStepPoint1 [ ^ self processControl forceServerJumpToStepPoint1 ]

{ #category : 'private' }
GbsRemoteDebugger >> formatSource [ ^ self sourcePaneController formatSource ]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllHierarchyImplementors [ ^ self methodNavigator gsBrowseAllHierarchyImplementors ]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllHierarchyImplementorsFor: aSelector [ ^ self methodNavigator gsBrowseAllHierarchyImplementorsFor: aSelector ]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllHierarchyReferences [ ^ self methodNavigator gsBrowseAllHierarchyReferences ]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllHierarchyReferencesFor: aSelector [ ^ self methodNavigator gsBrowseAllHierarchyReferencesFor: aSelector ]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllImplementors [ ^ self methodNavigator gsBrowseAllImplementors ]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllImplementorsFor: aSelector [ ^ self methodNavigator gsBrowseAllImplementorsFor: aSelector ]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllReferences [ ^ self methodNavigator gsBrowseAllReferences ]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllReferencesFor: aSelector [ ^ self methodNavigator gsBrowseAllReferencesFor: aSelector ]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseQueryFor: aSelector hierarchyOnly: hierarchyOnly senders: sendersOnly [
	^ self methodNavigator
		gsBrowseQueryFor: aSelector
		hierarchyOnly: hierarchyOnly
		senders: sendersOnly
]

{ #category : 'private' }
GbsRemoteDebugger >> gsDebugIt [
	| code errorText processCandidate debugger |
	session ifNil: [ ^ false ].
	code := self selectedSourceOrAll.
	code isEmpty ifTrue: [ ^ false ].
	^ [ 
		session execute: code.
		true
	] on: GbsError do: [ :ex |
		errorText := ex messageText.
		processCandidate := self processOopFromGbsError: ex.
		(processCandidate isNumber and: [ processCandidate > 20 ])
			ifTrue: [
				debugger := self class
					openOn: errorText
					process: processCandidate
					session: session.
				debugger setInitialSourceCode: code.
				true
			]
			ifFalse: [ UIManager default inform: errorText. false ]
	]
]

{ #category : 'actions' }
GbsRemoteDebugger >> gsDoIt [
	| code |
	service ifNil: [ ^ false ].
	code := self selectedSourceOrAll.
	^ [ service gsDoIt: code ] on: Error do: [ false ]
]

{ #category : 'menus' }
GbsRemoteDebugger >> gsHierarchyImplementorsQuerySubMenu [ ^ self selectorQuerySubMenuUsing: [ :sel | self gsBrowseAllHierarchyImplementorsFor: sel ] ]

{ #category : 'menus' }
GbsRemoteDebugger >> gsHierarchySendersQuerySubMenu [ ^ self selectorQuerySubMenuUsing: [ :sel | self gsBrowseAllHierarchyReferencesFor: sel ] ]

{ #category : 'menus' }
GbsRemoteDebugger >> gsImplementorsQuerySubMenu [ ^ self selectorQuerySubMenuUsing: [ :sel | self gsBrowseAllImplementorsFor: sel ] ]

{ #category : 'actions' }
GbsRemoteDebugger >> gsInspectIt [
	| code |
	service ifNil: [ ^ false ].
	code := self selectedSourceOrAll.
	^ [ service gsInspectIt: code ] on: Error do: [ false ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> gsPrintIt [
	| code result currentText |
	service ifNil: [ ^ false ].
	code := self selectedSourceOrAll.
	result := [ service gsPrintIt: code ] on: Error do: [ nil ].
	result ifNil: [ ^ false ].
	currentText := (sourceText respondsTo: #text) ifTrue: [ sourceText text asString ] ifFalse: [ '' ].
	(sourceText respondsTo: #text:)
		ifTrue: [ sourceText text: currentText, ' "', result asString, '"' ].
	^ true
]

{ #category : 'menus' }
GbsRemoteDebugger >> gsSendersQuerySubMenu [ ^ self selectorQuerySubMenuUsing: [ :sel | self gsBrowseAllReferencesFor: sel ] ]

{ #category : 'private' }
GbsRemoteDebugger >> highlightSourceLineFromCompileError: errorMessage [ ^ self sourcePaneController highlightSourceLineFromCompileError: errorMessage ]

{ #category : 'private' }
GbsRemoteDebugger >> informUnsupported: aString [
	(UIManager default respondsTo: #inform:)
		ifTrue: [ UIManager default inform: aString ].
	^ false
]

{ #category : 'initialization' }
GbsRemoteDebugger >> initializePresenters [
	mainMenu := self buildMenuBar.
	errorMessageLabel := self newLabel.
	errorMessageLabel addStyle: 'danger'.

	stepOverButton := self newButton 
		label: 'Step Over'; 
		action: [ self stepOver ].
	stepIntoButton := self newButton 
		label: 'Step Into'; 
		action: [ self stepInto ].
	stepButton := self newButton
		label: 'Step';
		action: [ self step ].
	stepReturnButton := self newButton 
		label: 'Step Return';
		action: [ self stepReturn ].
	restartButton := self newButton
		label: 'Restart';
		action: [ self restart ].
	resumeButton := self newButton 
		label: 'Run';
		action: [ self resume ].
	runUntilReturnButton := self newButton
		label: 'Run until Return';
		action: [ self runUntilReturn ].
	runWithBreakAgainButton := self newButton
		label: 'Run with Break Again';
		action: [ self runWithBreakAgain ].
	runToCaretButton := self newButton
		label: 'Run to Caret';
		action: [ self runToCaret ].
	jumpToCaretButton := self newButton
		label: 'Jump to Caret';
		action: [ self jumpToCaret ].
	returnButton := self newButton
		label: 'Return...';
		action: [ self returnFromFrame ].
	pauseButton := self newButton
		label: 'Pause';
		action: [ self pauseProcess ].
	terminateButton := self newButton 
		label: 'Terminate'; 
		action: [ self terminate ].
	inspectReceiverButton := self newButton
		label: 'Inspect Receiver';
		action: [ self inspectReceiver ].
	inspectProcessButton := self newButton
		label: 'Inspect Process';
		action: [ self inspectProcess ].
	inspectFrameButton := self newButton
		label: 'Inspect Context';
		action: [ self inspectFrame ].
	inspectStackButton := self newButton
		label: 'Inspect Stack';
		action: [ self inspectStack ].
	inspectVariableButton := self newButton
		label: 'Inspect Variable';
		action: [ self inspectVariable ].

	stackList := self newList.
	stackList whenSelectionChangedDo: [ :selection |
		| index |
		index := (selection respondsTo: #selectedIndex)
			ifTrue: [ selection selectedIndex ifNil: [ 0 ] ]
			ifFalse: [ 0 ].
		(index > 0 and: [ contextList notNil and: [ index <= contextList size ] ])
			ifTrue: [ self contextSelected: (contextList at: index) ]
			ifFalse: [ self contextSelected: selection selectedItem ]
	].

	sourceText := self newText.
	sourceText contextMenu: [ self sourceMenu ].

	variablesTable := self newTable.
	variablesTable
		addColumn: (SpStringTableColumn title: 'Name' evaluated: [ :item | item first ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :item | item second ]).
	(variablesTable respondsTo: #whenActivatedDo:)
		ifTrue: [ variablesTable whenActivatedDo: [ self inspectVariable ] ].
	(variablesTable respondsTo: #whenDoubleClickDo:)
		ifTrue: [ variablesTable whenDoubleClickDo: [ self inspectVariable ] ].

	receiverInfoTable := self newTable.
	receiverInfoTable
		addColumn: (SpStringTableColumn title: 'Receiver' evaluated: [ :item | item first ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :item | item second ]).

	frameInfoTable := self newTable.
	frameInfoTable
		addColumn: (SpStringTableColumn title: 'Frame' evaluated: [ :item | item first ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :item | item second ]).

	processInfoTable := self newTable.
	processInfoTable
		addColumn: (SpStringTableColumn title: 'Process' evaluated: [ :item | item first ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :item | item second ]).

	glueIsHidden := true.
	bookmarkContextIndex := nil.
	self refreshUiState.
]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectFrame [ ^ self inspectorActions inspectFrame ]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectProcess [ ^ self inspectorActions inspectProcess ]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectReceiver [ ^ self inspectorActions inspectReceiver ]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectStack [ ^ self inspectorActions inspectStack ]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectVariable [ ^ self inspectorActions inspectVariable ]

{ #category : 'private' }
GbsRemoteDebugger >> inspectorActions [ ^ GbsRemoteDebuggerInspectorActions on: self ]

{ #category : 'private' }
GbsRemoteDebugger >> integerFromSourceMapKey: rawKey [
	| value |
	rawKey ifNil: [ ^ nil ].
	value := rawKey.
	(value respondsTo: #asLocalString) ifTrue: [ value := value asLocalString ].
	^ [ value asString asInteger ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbsRemoteDebugger >> isExecutedCodeFrame: aContext [ ^ self stackNavigator isExecutedCodeFrame: aContext ]

{ #category : 'private' }
GbsRemoteDebugger >> isLikelyUserFrame: aContext [ ^ self stackNavigator isLikelyUserFrame: aContext ]

{ #category : 'private' }
GbsRemoteDebugger >> jumpToCaret [ ^ self executionController jumpToCaret ]

{ #category : 'accessing' }
GbsRemoteDebugger >> label: aString [
	errorMessageLabel ifNotNil: [ errorMessageLabel label: (self presenterTextFrom: aString) ]
]

{ #category : 'private' }
GbsRemoteDebugger >> localBehaviorFromServerClassName: classNameString [ ^ self methodNavigator localBehaviorFromServerClassName: classNameString ]

{ #category : 'private' }
GbsRemoteDebugger >> localDebugIt [
	| code |
	code := self selectedSourceOrAll.
	code isEmpty ifTrue: [ ^ false ].
	^ [ Smalltalk compiler evaluate: code. true ]
		on: Error
		do: [ :ex | ex pass ]
]

{ #category : 'private' }
GbsRemoteDebugger >> localDoIt [
	| code |
	code := self selectedSourceOrAll.
	code isEmpty ifTrue: [ ^ false ].
	[ Smalltalk compiler evaluate: code ] on: Error do: [ :ex | ^ false ].
	^ true
]

{ #category : 'menus' }
GbsRemoteDebugger >> localHierarchyImplementorsQuerySubMenu [ ^ self selectorQuerySubMenuUsing: [ :sel | self browseLocalHierarchyImplementorsFor: sel ] ]

{ #category : 'menus' }
GbsRemoteDebugger >> localHierarchySendersQuerySubMenu [ ^ self selectorQuerySubMenuUsing: [ :sel | self browseLocalHierarchySendersFor: sel ] ]

{ #category : 'menus' }
GbsRemoteDebugger >> localImplementorsQuerySubMenu [ ^ self selectorQuerySubMenuUsing: [ :sel | self browseLocalImplementorsFor: sel ] ]

{ #category : 'private' }
GbsRemoteDebugger >> localInspectIt [
	| code value |
	code := self selectedSourceOrAll.
	code isEmpty ifTrue: [ ^ false ].
	value := [ Smalltalk compiler evaluate: code ] on: Error do: [ :ex | ^ false ].
	value inspect.
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> localPrintIt [
	| code value currentText |
	code := self selectedSourceOrAll.
	code isEmpty ifTrue: [ ^ false ].
	value := [ Smalltalk compiler evaluate: code ] on: Error do: [ :ex | ^ false ].
	currentText := (sourceText respondsTo: #text)
		ifTrue: [ sourceText text asString ]
		ifFalse: [ '' ].
	(sourceText respondsTo: #text:)
		ifTrue: [ sourceText text: currentText, ' "', value printString, '"' ].
	^ true
]

{ #category : 'menus' }
GbsRemoteDebugger >> localSendersQuerySubMenu [ ^ self selectorQuerySubMenuUsing: [ :sel | self browseLocalSendersFor: sel ] ]

{ #category : 'menus' }
GbsRemoteDebugger >> methodMenu [ ^ self menuBuilder methodMenu ]

{ #category : 'private' }
GbsRemoteDebugger >> menuBuilder [ ^ GbsRemoteDebuggerMenuBuilder on: self ]

{ #category : 'private' }
GbsRemoteDebugger >> methodNavigator [ ^ GbsRemoteDebuggerMethodNavigator on: self ]

{ #category : 'private' }
GbsRemoteDebugger >> sourcePaneController [ ^ GbsRemoteDebuggerSourcePaneController on: self ]

{ #category : 'private' }
GbsRemoteDebugger >> moveSourceCursorToStart [ ^ self sourcePaneController moveSourceCursorToStart ]

{ #category : 'private' }
GbsRemoteDebugger >> normalizePauseLandingSelection [ ^ self stackNavigator normalizePauseLandingSelection ]

{ #category : 'private' }
GbsRemoteDebugger >> normalizeRestartSelectionAndPosition [ ^ self stackNavigator normalizeRestartSelectionAndPosition ]

{ #category : 'private' }
GbsRemoteDebugger >> openServerMethodReference: aReferenceString [ ^ self methodNavigator openServerMethodReference: aReferenceString ]

{ #category : 'private' }
GbsRemoteDebugger >> pauseProcess [ ^ self executionController pauseProcess ]

{ #category : 'private' }
GbsRemoteDebugger >> placeCaretAt: anIndex inTextPresenter: aTextPresenter [ ^ self sourcePaneController placeCaretAt: anIndex inTextPresenter: aTextPresenter ]

{ #category : 'private' }
GbsRemoteDebugger >> preferredInitialContextIndex [ ^ self stackNavigator preferredInitialContextIndex ]

{ #category : 'accessing' }
GbsRemoteDebugger >> processOop [ ^ processOop ]

{ #category : 'accessing' }
GbsRemoteDebugger >> processOop: anOop [
	processOop := anOop.
	stackList ifNotNil: [ self fetchStackFrames ].
]

{ #category : 'private' }
GbsRemoteDebugger >> processOopSilently: anOop [
	processOop := anOop
]

{ #category : 'private' }
GbsRemoteDebugger >> processOopFromGbsError: anError [ ^ self processControl processOopFromGbsError: anError ]

{ #category : 'private' }
GbsRemoteDebugger >> processControl [ ^ GbsRemoteDebuggerProcessControl on: self ]

{ #category : 'private' }
GbsRemoteDebugger >> presenterTextFrom: aValue [ ^ GbsRemoteDebuggerUiController presenterTextFrom: aValue ]

{ #category : 'private' }
GbsRemoteDebugger >> refreshUiState [ ^ GbsRemoteDebuggerUiController refreshUiStateFor: self ]

{ #category : 'private' }
GbsRemoteDebugger >> reinforceSourceCaretVisibility [ ^ self sourcePaneController reinforceSourceCaretVisibility ]

{ #category : 'actions' }
GbsRemoteDebugger >> removeAllBreakPoints [
	service ifNil: [ ^ 0 ].
	^ self withBreakpointRefresh: [ service removeAllBreakPoints ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> removeBreakPoint [
	service ifNil: [ ^ false ].
	^ self withBreakpointRefresh: [ service removeBreakIn: sourceText ]
]

{ #category : 'private' }
GbsRemoteDebugger >> resetServerPCToStepOneIfNeeded [
	"Reset server PC to step 1 if we're in an executed code frame.
	This ensures stepping starts from the beginning of the method."
	| context |
	contextList ifNil: [ ^ false ].
	contextList ifEmpty: [ ^ false ].
	
	context := contextList
		detect: [ :each |
			(each respondsTo: #isExecutedCodeFrame)
				and: [ each isExecutedCodeFrame ] ]
		ifNone: [ nil ].
	context ifNil: [ ^ false ].
	
	"Force server to jump to step 1"
	^ self forceServerJumpToStepPoint1
]

{ #category : 'private' }
GbsRemoteDebugger >> resolveDebugProcessOopFromCurrentProcessOop [ ^ self processControl resolveDebugProcessOopFromCurrentProcessOop ]

{ #category : 'private' }
GbsRemoteDebugger >> resolveExecutedFrameLevelFromServer [ ^ self processControl resolveExecutedFrameLevelFromServer ]

{ #category : 'private' }
GbsRemoteDebugger >> restart [ ^ self restartController restart ]

{ #category : 'private' }
GbsRemoteDebugger >> restartUsingDirectTrimFromExecutedFrame [ ^ self processControl restartUsingDirectTrimFromExecutedFrame ]

{ #category : 'private' }
GbsRemoteDebugger >> restartController [ ^ GbsRemoteDebuggerRestartController on: self ]

{ #category : 'actions' }
GbsRemoteDebugger >> resume [ ^ self executionController resume ]

{ #category : 'private' }
GbsRemoteDebugger >> returnFromFrame [ ^ self executionController returnFromFrame ]

{ #category : 'private' }
GbsRemoteDebugger >> runToCaret [ ^ self executionController runToCaret ]

{ #category : 'actions' }
GbsRemoteDebugger >> runUntilReturn [ ^ self executionController runUntilReturn ]

{ #category : 'actions' }
GbsRemoteDebugger >> runWithBreakAgain [ ^ self executionController runWithBreakAgain ]

{ #category : 'private' }
GbsRemoteDebugger >> safeServiceCall: aBlock default: defaultValue [
	service ifNil: [ ^ defaultValue ].
	^ [ aBlock value ] on: Error do: [ defaultValue ]
]

{ #category : 'private' }
GbsRemoteDebugger >> selectAndRevealFrom: startIndex to: endIndex inTextPresenter: aTextPresenter [
	^ self sourcePaneController
		selectAndRevealFrom: startIndex
		to: endIndex
		inTextPresenter: aTextPresenter
]

{ #category : 'private' }
GbsRemoteDebugger >> selectHomeContext [ ^ self stackNavigator selectHomeContext ]

{ #category : 'private' }
GbsRemoteDebugger >> selectLineNumber: lineNumber inTextPresenter: aTextPresenter [ ^ self sourcePaneController selectLineNumber: lineNumber inTextPresenter: aTextPresenter ]

{ #category : 'private' }
GbsRemoteDebugger >> selectedContextForInspector [ ^ self contextPresenter selectedContextForInspector ]

{ #category : 'private' }
GbsRemoteDebugger >> selectedServerClassName [ ^ self methodNavigator selectedServerClassName ]

{ #category : 'private' }
GbsRemoteDebugger >> selectedServerMethodReference [ ^ self methodNavigator selectedServerMethodReference ]

{ #category : 'private' }
GbsRemoteDebugger >> selectedServerSelector [ ^ self methodNavigator selectedServerSelector ]

{ #category : 'private' }
GbsRemoteDebugger >> selectedSourceOrAll [ ^ self sourcePaneController selectedSourceOrAll ]

{ #category : 'private' }
GbsRemoteDebugger >> selectedStepPointFromCaret [ ^ self sourcePaneController selectedStepPointFromCaret ]

{ #category : 'private' }
GbsRemoteDebugger >> selectedVariableName [ ^ self contextPresenter selectedVariableName ]

{ #category : 'menus' }
GbsRemoteDebugger >> selectorCandidatesForQueryMenus [ ^ self methodNavigator selectorCandidatesForQueryMenus ]

{ #category : 'menus' }
GbsRemoteDebugger >> selectorQuerySubMenuUsing: aBlock [ ^ self methodNavigator selectorQuerySubMenuUsing: aBlock ]

{ #category : 'private' }
GbsRemoteDebugger >> serverMethodReferencesFor: aSelector hierarchyOnly: hierarchyOnly senders: sendersOnly [
	^ self methodNavigator
		serverMethodReferencesFor: aSelector
		hierarchyOnly: hierarchyOnly
		senders: sendersOnly
]

{ #category : 'accessing' }
GbsRemoteDebugger >> service [ ^ service ]

{ #category : 'accessing' }
GbsRemoteDebugger >> service: aService [
	service := aService
]

{ #category : 'accessing' }
GbsRemoteDebugger >> session [ ^ session ]

{ #category : 'accessing' }
GbsRemoteDebugger >> session: aSession [
	session := aSession
]

{ #category : 'actions' }
GbsRemoteDebugger >> setBreakPoint [
	service ifNil: [ ^ false ].
	^ self withBreakpointRefresh: [ service setBreakPointIn: sourceText ]
]

{ #category : 'private' }
GbsRemoteDebugger >> setFrameInfoItems: aCollection [
	frameInfoTable ifNil: [ ^ self ].
	(frameInfoTable respondsTo: #items:)
		ifTrue: [ [ frameInfoTable items: aCollection ] on: Error do: [ ] ].
]

{ #category : 'accessing' }
GbsRemoteDebugger >> setInitialSourceCode: aString [ ^ self sourcePaneController setInitialSourceCode: aString ]

{ #category : 'private' }
GbsRemoteDebugger >> setProcessInfoItems: aCollection [
	processInfoTable ifNil: [ ^ self ].
	(processInfoTable respondsTo: #items:)
		ifTrue: [ [ processInfoTable items: aCollection ] on: Error do: [ ] ].
]

{ #category : 'private' }
GbsRemoteDebugger >> setReceiverInfoItems: aCollection [
	receiverInfoTable ifNil: [ ^ self ].
	(receiverInfoTable respondsTo: #items:)
		ifTrue: [ [ receiverInfoTable items: aCollection ] on: Error do: [ ] ].
]

{ #category : 'private' }
GbsRemoteDebugger >> setSourceText: aString [ ^ self sourcePaneController setSourceText: aString ]

{ #category : 'private' }
GbsRemoteDebugger >> setVariableTableItems: aCollection [
	variablesTable ifNil: [ ^ self ].
	(variablesTable respondsTo: #items:)
		ifTrue: [
			[ variablesTable items: aCollection ] on: Error do: [ ]
		].
]

{ #category : 'private' }
GbsRemoteDebugger >> showCompileErrorInSourcePane [ ^ self sourcePaneController showCompileErrorInSourcePane ]

{ #category : 'private' }
GbsRemoteDebugger >> showContainingPackage [ ^ self methodNavigator showContainingPackage ]

{ #category : 'private' }
GbsRemoteDebugger >> showMoreContexts [
	self fetchStackFrames.
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> sourceMapFor: aContext [ ^ self sourcePaneController sourceMapFor: aContext ]

{ #category : 'private' }
GbsRemoteDebugger >> sourceMenu [ ^ self menuBuilder sourceMenu ]

{ #category : 'accessing' }
GbsRemoteDebugger >> sourceTextPresenter [ ^ sourceText ]

{ #category : 'accessing' }
GbsRemoteDebugger >> stackData: anArray [
	stackData := anArray.
	stackList ifNotNil: [ self fetchStackFrames ].
]

{ #category : 'accessing' }
GbsRemoteDebugger >> stackData [ ^ stackData ]

{ #category : 'private' }
GbsRemoteDebugger >> stackLoader [ ^ GbsRemoteDebuggerStackLoader on: self ]

{ #category : 'accessing' }
GbsRemoteDebugger >> stackListPresenter [ ^ stackList ]

{ #category : 'menus' }
GbsRemoteDebugger >> stackMenu [ ^ self menuBuilder stackMenu ]

{ #category : 'private' }
GbsRemoteDebugger >> stackNavigator [ ^ GbsRemoteDebuggerStackNavigator on: self ]

{ #category : 'private' }
GbsRemoteDebugger >> stackReportString [
	| rows |
	contextList ifNil: [ ^ '' ].
	rows := contextList collect: [ :ctx | ctx printString ].
	^ String crlf join: rows
]

{ #category : 'actions' }
GbsRemoteDebugger >> step [ ^ self executionController step ]

{ #category : 'actions' }
GbsRemoteDebugger >> stepInto [ ^ self executionController stepInto ]

{ #category : 'actions' }
GbsRemoteDebugger >> stepOver [ ^ self executionController stepOver ]

{ #category : 'actions' }
GbsRemoteDebugger >> stepReturn [ ^ self executionController stepReturn ]

{ #category : 'private' }
GbsRemoteDebugger >> syncBreakpointMarker [
	| summary |
	service ifNil: [ ^ self ].
	(service respondsTo: #breakpointSummaryString) ifFalse: [ ^ self ].
	summary := [ service breakpointSummaryString ] on: Error do: [ nil ].
	summary ifNil: [ ^ self ].
	self withWindowDo: [ :window |
		| base |
		base := 'GemStone Remote Debugger'.
		window title: base, ' - ', summary ].
]

{ #category : 'actions' }
GbsRemoteDebugger >> terminate [ ^ self executionController terminate ]

{ #category : 'actions' }
GbsRemoteDebugger >> closeRemoteDebuggerSession [ ^ self executionController closeRemoteDebuggerSession ]

{ #category : 'private' }
GbsRemoteDebugger >> remoteDebugProcessStillActive [ ^ self executionController remoteDebugProcessStillActive ]

{ #category : 'actions' }
GbsRemoteDebugger >> withRemoteDebuggerSessionDo: aBlock [ ^ self executionController withRemoteDebuggerSessionDo: aBlock ]

{ #category : 'actions' }
GbsRemoteDebugger >> toggleBreakPoint [
	service ifNil: [ ^ false ].
	^ self withBreakpointRefresh: [ service toggleBreakPointIn: sourceText ]
]

{ #category : 'private' }
GbsRemoteDebugger >> toggleFilterStack [
	self toggleGlueHiding.
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> toggleGlueHiding [
	self safeServiceCall: [ service toggleGlueHiding ] default: false.
	self fetchStackFrames.
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> withBreakpointRefresh: aBlock [
	| result |
	result := [ aBlock value ] on: Error do: [ false ].
	self syncBreakpointMarker.
	self refreshUiState.
	^ result
]
