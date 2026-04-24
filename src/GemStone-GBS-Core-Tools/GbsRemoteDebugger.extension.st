Extension { #name : 'GbsRemoteDebugger' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> browsePromptedSessionStateKey [
	| rawKey key |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	rawKey := self requestInput: 'Session state key:' initialAnswer: '19'.
	(rawKey isNil or: [ rawKey trimBoth isEmpty ]) ifTrue: [ ^ false ].
	key := [ rawKey trimBoth asInteger ]
		on: Error
		do: [ nil ].
	key ifNil: [
		self inform: 'Enter a numeric session state key.'.
		^ false ].
	^ self browseSessionStateAtKey: key
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> browseTypedWrapperLifecycleReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: session typedWrapperLifecycleReportText.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> browseStaleTypedWrapperLifecycleReport [
	| report staleEntries |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	report := session typedWrapperLifecycleReport.
	staleEntries := report staleEntries.
	staleEntries isEmpty ifTrue: [
		self inform: 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.'.
		^ true ].
	self inform: (GbsTypedWrapperLifecycleReport entries: staleEntries) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> browseSessionStateAtKey: aKey [
	| sessionStateValue oop |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	sessionStateValue := [ session sessionStateAt: aKey ]
		on: Error
		do: [ :ex |
			self inform: 'Session state lookup failed: ', ex messageText.
			^ false ].
	sessionStateValue ifNil: [
		self inform: 'Session state key ', aKey printString, ' is not set.'.
		^ false ].
	oop := [ sessionStateValue oop ]
		on: Error
		do: [ nil ].
	oop ifNil: [
		((sessionStateValue isInteger) and: [ sessionStateValue > 20 ])
			ifTrue: [ oop := sessionStateValue ] ].
	oop ifNil: [
		self inform: 'Session state key ', aKey printString, ' does not currently have an inspectable remote oop.'.
		^ false ].
	^ self inspectOop: oop session: session
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> browsePromptedSessionStateKeysReport [
	| rawKeys keys |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	rawKeys := self requestInput: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ false ].
	self inform: (session objectSpaceDiagnostics reportTextForKeys: keys).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> browseObjectsInMemoryReport [
	| start limit |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ false ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ false ].
	self inform: (session objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> buildMenuBar [
	^ self newMenuBar
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Stack'; subMenu: self stackMenu ].
			group addItem: [ :item | item name: 'Method'; subMenu: self methodMenu ].
			group addItem: [ :item | item name: 'Edit'; subMenu: self editMenu ].
			group addItem: [ :item | item name: 'Execute'; subMenu: self executeMenu ].
			group addItem: [ :item | item name: 'Correct'; subMenu: self correctMenu ].
			group addItem: [ :item | item name: 'Session'; subMenu: self sessionMenu ] ];
		yourself
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> gsBrowseReferencesToSelectedClass [
	| targetName references selected |
	targetName := self selectedServerReferenceTargetName.
	targetName ifNil: [ ^ false ].
	references := self serverClassReferenceStrings.
	references isEmpty ifTrue: [
		UIManager default inform: 'No matching GemStone methods found.'.
		^ false ].
	selected := self chooseMethodReferenceFrom: references title: 'References to ', targetName.
	selected ifNil: [ ^ false ].
	^ self openServerMethodReference: selected
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> methodMenu [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Browse'; action: [ self browseSelectedMethod ] ].
			self addExtensionMethodMenuItemsTo: group.
			group addItem: [ :item | item name: 'GS-Class References'; action: [ self gsBrowseReferencesToSelectedClass ] ].
			group addItem: [ :item | item name: 'GS-Senders'; subMenu: self gsSendersQuerySubMenu ].
			group addItem: [ :item | item name: 'GS-Implementors'; subMenu: self gsImplementorsQuerySubMenu ].
			group addItem: [ :item | item name: 'GS-Hierarchy Senders'; subMenu: self gsHierarchySendersQuerySubMenu ].
			group addItem: [ :item | item name: 'GS-Hierarchy Implementors'; subMenu: self gsHierarchyImplementorsQuerySubMenu ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Senders'; subMenu: self localSendersQuerySubMenu ].
			group addItem: [ :item | item name: 'Implementors'; subMenu: self localImplementorsQuerySubMenu ].
			group addItem: [ :item | item name: 'Hierarchy Senders'; subMenu: self localHierarchySendersQuerySubMenu ].
			group addItem: [ :item | item name: 'Hierarchy Implementors'; subMenu: self localHierarchyImplementorsQuerySubMenu ].
			group addItem: [ :item | item name: 'Show Containing Package...'; action: [ self showContainingPackage ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Recompile with Full Blocks'; action: [ self acceptSourceEdits ] ] ];
		yourself
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> selectedServerReferenceTargetName [
	| className |
	className := self selectedServerClassName.
	className ifNil: [ ^ nil ].
	className := className asString.
	^ (className endsWith: ' class')
		ifTrue: [ className copyFrom: 1 to: className size - 6 ]
		ifFalse: [ className ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> requestInput: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> uiChooseFrom: choices title: titleString [
	^ UIManager default chooseFrom: choices title: titleString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> parseSessionStateKeysFrom: aStringOrNil [
	| trimmed tokens keys |
	(aStringOrNil isNil or: [ aStringOrNil trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	trimmed := aStringOrNil trimBoth.
	tokens := (trimmed findTokens: ',') collect: #trimBoth thenReject: #isEmpty.
	tokens isEmpty ifTrue: [ ^ nil ].
	keys := tokens collect: [ :each |
		[ each asInteger ] on: Error do: [ ^ nil ] ].
	^ keys asArray
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> requestPositiveInteger: promptString initialAnswer: defaultString [
	| rawValue |
	rawValue := self requestInput: promptString initialAnswer: defaultString.
	(rawValue isNil or: [ rawValue trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ [ | value |
		value := rawValue trimBoth asInteger.
		value > 0 ifTrue: [ value ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> sessionMenu [
	| menu |
	menu := self newMenu
		addGroup: [ :group |
			group addItem: [ :item |
				item
					name: 'Typed Wrapper Lifecycle Report';
					action: [ self browseTypedWrapperLifecycleReport ] ].
			group addItem: [ :item |
				item
					name: 'Stale Typed Wrapper Report';
					action: [ self browseStaleTypedWrapperLifecycleReport ] ].
			group addItem: [ :item |
				item
					name: 'Session State Keys Report...';
					action: [ self browsePromptedSessionStateKeysReport ] ].
			group addItem: [ :item |
				item
					name: 'Objects In Memory Report...';
					action: [ self browseObjectsInMemoryReport ] ].
			group addItem: [ :item |
				item
					name: 'Inspect Session State Key...';
					action: [ self browsePromptedSessionStateKey ] ] ];
		yourself.
	self addExtensionSessionMenuItemsTo: menu.
	^ menu
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> serverClassReferenceStrings [
	| targetName |
	session ifNil: [ ^ #() ].
	targetName := self selectedServerReferenceTargetName.
	targetName ifNil: [ ^ #() ].
	^ [ session methodReferenceStringsToSymbol: targetName ]
		on: Error
		do: [ #() ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> serverMethodReferencesFor: aSelector hierarchyOnly: hierarchyOnly senders: sendersOnly [
	session ifNil: [ ^ #( ) ].
	hierarchyOnly ifFalse: [
		^ sendersOnly
			ifTrue: [ session senderMethodReferenceStringsForSelector: aSelector ]
			ifFalse: [ session implementorMethodReferenceStringsForSelector: aSelector ] ].
	^ sendersOnly
		ifTrue: [
			session
				hierarchySenderMethodReferenceStringsForSelector: aSelector
				rootClassName: self selectedServerClassName
				scope: 'full'
				includeClassSide: true ]
		ifFalse: [
			session
				hierarchyImplementorMethodReferenceStringsForSelector: aSelector
				rootClassName: self selectedServerClassName
				scope: 'full'
				includeClassSide: true ].
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> currentReceiverProxyForServerMethod [
	| receiverOop |
	session ifNil: [ ^ nil ].
	service ifNil: [ ^ nil ].
	receiverOop := self safeServiceCall: [ service currentReceiverOop ] default: nil.
	receiverOop ifNil: [ ^ nil ].
	(receiverOop isString and: [ receiverOop isEmpty not ]) ifTrue: [
		receiverOop := [ receiverOop asInteger ] on: Error do: [ nil ] ].
	(receiverOop isNumber and: [ receiverOop > 20 ]) ifFalse: [ ^ nil ].
	^ session objectForOop: receiverOop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> directStepOverExecutedFrame: stepIntoBoolean [
	| level effectiveLevel |
	(session isNil or: [ processOop isNil ]) ifTrue: [ ^ false ].
	(processOop isNumber and: [ processOop > 20 ]) ifFalse: [ ^ false ].

	level := self currentSelectedFrameLevel.
	(level isNumber and: [ level > 0 ]) ifFalse: [ level := 1 ].

	self forceServerJumpToStepPoint1.

	effectiveLevel := self resolveExecutedFrameLevelFromServer.
	(effectiveLevel isNumber and: [ effectiveLevel > 0 ]) ifTrue: [ level := effectiveLevel ].
	^ self remoteDebugProcess
		stepOverExecutedFrameLevel: level
		stepInto: stepIntoBoolean
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> directStepWithPrimarySelector: primarySelector fallbackSelector: fallbackSelector [
	| level |
	(session isNil or: [ processOop isNil ]) ifTrue: [ ^ false ].
	(processOop isNumber and: [ processOop > 20 ]) ifFalse: [ ^ false ].
	level := self currentSelectedFrameLevel.
	level ifNil: [ level := 1 ].
	^ self remoteDebugProcess
		performStepSelector: primarySelector
		fallbackSelector: fallbackSelector
		atLevel: level
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> fetchContextsDirectly [
	processOop ifNil: [ ^ #() ].
	processOop = 0 ifTrue: [ ^ #() ].
	^ self remoteDebugProcess contextActivations
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> applyFetchedContexts: contexts [
	contextList := contexts ifNil: [ #( ) ].
	contextList ifEmpty: [
		stackList items: #('No stack frames available - error occurred in GemStone').
		self setSourceText: ''.
		self clearSourceHighlight.
		self setVariableTableItems: #().
		self setReceiverInfoItems: #().
		self setFrameInfoItems: #().
		self setProcessInfoItems: #().
		self refreshUiState.
		^ self ].
	stackList items: (contextList collect: [ :ctx | ctx printString ]).

	contextList ifNotEmpty: [
		| preferredIndex |
		preferredIndex := self preferredInitialContextIndex.
		stackList selectIndex: preferredIndex.
		self contextSelected: (contextList at: preferredIndex) ].
	self refreshUiState
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> fetchFullSourceFor: aContext [
	| ctxProcessOop levelValue |
	aContext ifNil: [ ^ '' ].
	session ifNil: [ ^ '' ].
	levelValue := (aContext respondsTo: #level)
		ifTrue: [ aContext level ifNil: [ 0 ] ]
		ifFalse: [ 0 ].
	levelValue <= 0 ifTrue: [ ^ '' ].
	ctxProcessOop := (aContext respondsTo: #processOop)
		ifTrue: [ aContext processOop ]
		ifFalse: [ processOop ].
	(ctxProcessOop isNil or: [ ctxProcessOop = 0 ]) ifTrue: [ ^ '' ].
	^ (GbsRemoteDebugProcessFacade
		on: session
		processOop: ctxProcessOop)
			fullSourceAtLevel: levelValue
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> fetchStackFrames [
	| contexts |

	stackData ifNotNil: [ ^ self fetchStackFramesFromData ].

	contexts := #( ).
	service ifNotNil: [
		[
			(service respondsTo: #recomputeContextList)
				ifTrue: [ service recomputeContextList ].
			contexts := service contextList
		] on: Error do: [ contexts := #( ) ] ].

	contexts ifEmpty: [ contexts := self fetchContextsDirectly ].
	contexts ifEmpty: [
		| resolved |
		resolved := self resolveDebugProcessOopFromCurrentProcessOop.
		((resolved isNumber and: [ resolved > 20 ]) and: [ resolved ~= processOop ]) ifTrue: [
			processOop := resolved.
			(service notNil and: [ service respondsTo: #processOop: ])
				ifTrue: [ [ service processOop: resolved ] on: Error do: [ ] ].
			contexts := self fetchContextsDirectly ] ].
	self applyFetchedContexts: contexts
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> forceServerJumpToStepPoint1 [
	| level |
	(session isNil or: [ processOop isNil ]) ifTrue: [ ^ false ].
	(service notNil and: [ service respondsTo: #resetServerPCToStepOne ]) ifTrue: [
		^ self safeServiceCall: [ service resetServerPCToStepOne ] default: false
	].

	level := self resolveExecutedFrameLevelFromServer.
	level ifNil: [ level := 1 ].
	^ self remoteDebugProcess
		resetProgramCounterToStepOneAtLevel: level
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> invokeSelectedServerMethod [
	| result |
	result := [ self invokeSelectedServerMethodObject ] on: Error do: [ :ex |
		self inform: 'GemStone invoke failed: ', ex messageText.
		^ false ].
	result ifNil: [
		self inform: 'No GemStone method selected.'.
		^ false ].
	self inform: 'GemStone method result: ', result printString.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> inform: aString [
	(UIManager default respondsTo: #inform:)
		ifTrue: [ UIManager default inform: aString ].
	^ aString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> inspectOop: anOop session: aSession [
	GbsInspector inspect: anOop session: aSession
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> remoteDebugProcess [
	^ GbsRemoteDebugProcessFacade
		on: session
		processOop: processOop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> resolveDebugProcessOopFromCurrentProcessOop [
	(session isNil or: [ processOop isNil ]) ifTrue: [ ^ nil ].
	(processOop isNumber and: [ processOop > 20 ]) ifFalse: [ ^ nil ].
	^ self remoteDebugProcess resolvedProcessOop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> resolveExecutedFrameLevelFromServer [
	(session isNil or: [ processOop isNil ]) ifTrue: [ ^ nil ].
	(processOop isNumber and: [ processOop > 20 ]) ifFalse: [ ^ nil ].
	^ self remoteDebugProcess restartLevelFromServerStack
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> restartUsingDirectTrimFromExecutedFrame [
	| targetLevel |
	(session isNil or: [ processOop isNil ]) ifTrue: [ ^ false ].
	(processOop isNumber and: [ processOop > 20 ]) ifFalse: [ ^ false ].
	targetLevel := self currentSelectedFrameLevel.
	((targetLevel isNumber and: [ targetLevel > 0 ]) not) ifTrue: [ targetLevel := 1 ].
	^ self remoteDebugProcess
		restartUsingTrimAtExecutedFrameLevelOr: targetLevel
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> returnFromFrame [
	| contexts |
	(service notNil and: [ service respondsTo: #returnFromFrame ]) ifTrue: [
		| didReturn |
		didReturn := self safeServiceCall: [ service returnFromFrame ] default: false.
		didReturn ifTrue: [ self fetchStackFrames ].
		^ didReturn
	].
	contexts := self remoteDebugProcess returnFromFrameAndCollectContextActivations.
	contexts ifNil: [ ^ false ].
	self applyFetchedContexts: contexts.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> runToCaret [
	| stepPoint didRun contexts |
	stepPoint := self selectedStepPointFromCaret.
	stepPoint ifNil: [ ^ false ].
	didRun := self safeServiceCall: [ service runToStepPoint: stepPoint ] default: false.
	didRun ifFalse: [
		contexts := self remoteDebugProcess runToStepPointAndCollectContextActivations: stepPoint.
		contexts ifNil: [ ^ false ].
		self applyFetchedContexts: contexts.
		^ true ].
	self fetchStackFrames.
	^ didRun
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> selectedStepPointFromCaret [
	| caret map entries sorted match context |
	sourceText ifNil: [ ^ nil ].
	(sourceText respondsTo: #selectionInterval) ifFalse: [ ^ nil ].
	caret := sourceText selectionInterval first.
	context := (service notNil and: [ service respondsTo: #currentContext ])
		ifTrue: [ service currentContext ]
		ifFalse: [ self selectedContextForInspector ].
	context ifNil: [ context := self selectedContextForInspector ].
	map := self sourceMapFor: context.
	(map isCollection and: [ map isEmpty not ]) ifFalse: [ ^ nil ].
	entries := map collect: [ :assoc |
		| interval key |
		key := assoc key.
		interval := assoc value.
		(key isNumber and: [ interval respondsTo: #first ])
			ifTrue: [ assoc ]
			ifFalse: [ nil ] ] thenReject: #isNil.
	entries isEmpty ifTrue: [ ^ nil ].
	sorted := entries asSortedCollection: [ :a :b | a value first <= b value first ].
	match := sorted detect: [ :each |
		(each value first <= caret) and: [ (each value last ifNil: [ each value first ]) >= caret ] ]
		ifNone: [ sorted detect: [ :each | each value first >= caret ] ifNone: [ sorted last ] ].
	^ match key
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsRemoteDebugger >> stepReturn [
	| didStep contexts |
	didStep := self safeServiceCall: [ service stepReturn ] default: false.
	didStep ifFalse: [
		contexts := self remoteDebugProcess stepReturnAndCollectContextActivations.
		contexts ifNil: [ ^ false ].
		self applyFetchedContexts: contexts.
		^ true ].
	self fetchStackFrames.
	^ didStep
]
