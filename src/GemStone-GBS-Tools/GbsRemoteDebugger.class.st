"
A remote debugger for GemStone that runs in Pharo 13.
This debugger displays stack frames from GemStone server execution,
allows stepping through server code, and inspecting server objects.

Based on the VisualWorks GbxDebuggerService architecture.

Usage:
  GbsRemoteDebugger openOn: 'Error message' process: processOop session: aSession
"
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
GbsRemoteDebugger >> acceptSourceEdits [
	| code ok |
	service ifNil: [ ^ false ].
	code := (sourceText respondsTo: #text)
		ifTrue: [ sourceText text asString ]
		ifFalse: [ '' ].
	ok := [ service recompileCurrentMethodWithSource: code ] on: Error do: [ false ].
	ok ifTrue: [
		(contextList notNil and: [ contextList isEmpty not ]) ifTrue: [
			| idx |
			idx := (stackList respondsTo: #selectedIndex)
				ifTrue: [ stackList selectedIndex ifNil: [ 1 ] ]
				ifFalse: [ 1 ].
			(idx > 0 and: [ idx <= contextList size ]) ifTrue: [
				| ctx |
				ctx := contextList at: idx.
				(ctx respondsTo: #sourceString:) ifTrue: [ ctx sourceString: code ].
				(ctx respondsTo: #sourceCode:) ifTrue: [ ctx sourceCode: code ].
			].
		].
		self fetchStackFrames.
		self clearServiceCompileError.
		self syncBreakpointMarker.
		self refreshUiState.
	] ifFalse: [
		self showCompileErrorInSourcePane.
	].
	^ ok
]

{ #category : 'private' }
GbsRemoteDebugger >> applySourceMapHighlightFor: aContext [
	| map interval lineNumber stepPoint sourceOffsets stepEntry stepCandidates |
	sourceText ifNil: [ ^ self ].

	map := self sourceMapFor: aContext.
	(map isCollection and: [ map isEmpty not ]) ifTrue: [
		"Primary: anchor highlight to the selected frame's current step point."
		stepPoint := (aContext respondsTo: #stepPoint)
			ifTrue: [ [ aContext stepPoint ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		stepPoint ifNil: [
			stepPoint := (aContext respondsTo: #quickStepPoint)
				ifTrue: [ [ aContext quickStepPoint ] on: Error do: [ nil ] ]
				ifFalse: [ nil ]
		].
		stepPoint := [ stepPoint asInteger ] on: Error do: [ nil ].
		(stepPoint isNumber and: [ stepPoint > 0 ]) ifTrue: [
			stepEntry := map
				detect: [ :assoc |
					| key |
					(assoc respondsTo: #key) ifFalse: [ false ] ifTrue: [
						key := self integerFromSourceMapKey: assoc key.
						key = stepPoint
					] ]
				ifNone: [ nil ].
			stepEntry ifNil: [
				stepCandidates := map
					select: [ :assoc |
						| key |
						(assoc respondsTo: #key) ifFalse: [ false ] ifTrue: [
							key := self integerFromSourceMapKey: assoc key.
							key isNumber and: [ key <= stepPoint ]
						] ].
				stepCandidates ifNotEmpty: [
					stepEntry := stepCandidates first.
					stepCandidates allButFirstDo: [ :each |
						| eachKey currentKey |
						eachKey := self integerFromSourceMapKey: each key.
						currentKey := self integerFromSourceMapKey: stepEntry key.
						(eachKey isNumber and: [ currentKey isNumber and: [ eachKey > currentKey ] ])
							ifTrue: [ stepEntry := each ]
					]
				]
			].
			stepEntry ifNotNil: [ interval := stepEntry value ].
		].

		interval ifNil: [
			interval := (service notNil and: [ service respondsTo: #currentSourceSelectionInterval ])
				ifTrue: [ [ service currentSourceSelectionInterval ] on: Error do: [ nil ] ]
				ifFalse: [ nil ]
		].
		interval ifNil: [ interval := map first value ].
		(interval isNil or: [ (interval respondsTo: #first) not or: [ (interval respondsTo: #last) not ] ]) ifTrue: [
			^ self clearSourceHighlight
		].
		self selectAndRevealFrom: interval first to: interval last inTextPresenter: sourceText.
		self placeCaretAt: interval first inTextPresenter: sourceText.
		^ self.
	].

	lineNumber := (aContext respondsTo: #displayedLineNumber)
		ifTrue: [ [ aContext displayedLineNumber ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	(lineNumber isNumber and: [ lineNumber > 0 ])
		ifTrue: [ ^ self selectLineNumber: lineNumber inTextPresenter: sourceText ].

	"Final fallback for executed-code frames when map/line data is unavailable."
	(aContext respondsTo: #isExecutedCodeFrame) ifTrue: [
		aContext isExecutedCodeFrame ifTrue: [
			stepPoint := aContext quickStepPoint ifNil: [ 1 ].
			sourceOffsets := aContext sourceOffsets ifNil: [ #( 1 ) ].
			(sourceOffsets isCollection and: [ sourceOffsets isEmpty not and: [ stepPoint <= sourceOffsets size ] ]) ifTrue: [
				interval := sourceOffsets at: stepPoint ifAbsent: [ 1 ].
				interval ifNil: [ interval := 1 ].
				interval > 0 ifTrue: [
					self selectAndRevealFrom: interval to: interval inTextPresenter: sourceText.
					self placeCaretAt: interval inTextPresenter: sourceText.
					^ self
				]
			].
			^ self selectLineNumber: 1 inTextPresenter: sourceText
		]
	].

	self clearSourceHighlight.
]

{ #category : 'private' }
GbsRemoteDebugger >> integerFromSourceMapKey: rawKey [
	| value |
	rawKey ifNil: [ ^ nil ].
	value := rawKey.
	(value respondsTo: #asLocalString) ifTrue: [ value := value asLocalString ].
	^ [ value asString asInteger ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbsRemoteDebugger >> placeCaretAt: anIndex inTextPresenter: aTextPresenter [
	| caret |
	aTextPresenter ifNil: [ ^ self ].
	caret := anIndex ifNil: [ 1 ].
	[
		aTextPresenter withAdapterDo: [ :adapter |
			| widget textArea editor |
			widget := [ adapter widget ] on: Error do: [ nil ].
			widget ifNil: [ ^ self ].
			(widget respondsTo: #takeKeyboardFocus)
				ifTrue: [ [ widget takeKeyboardFocus ] on: Error do: [ ] ].
			textArea := (widget respondsTo: #textArea)
				ifTrue: [ [ widget textArea ] on: Error do: [ nil ] ]
				ifFalse: [ nil ].
			textArea ifNotNil: [
				(textArea respondsTo: #takeKeyboardFocus)
					ifTrue: [ [ textArea takeKeyboardFocus ] on: Error do: [ ] ].
				editor := (textArea respondsTo: #editor)
					ifTrue: [ [ textArea editor ] on: Error do: [ nil ] ]
					ifFalse: [ nil ].
				editor ifNotNil: [
					(editor respondsTo: #markIndex:) ifTrue: [ editor markIndex: caret ].
					(editor respondsTo: #pointIndex:) ifTrue: [ editor pointIndex: caret ].
					(editor respondsTo: #selectAt:) ifTrue: [ editor selectAt: caret ].
				].
				(textArea respondsTo: #scrollSelectionIntoView)
					ifTrue: [ [ textArea scrollSelectionIntoView ] on: Error do: [ ] ].
			].
		]
	] on: Error do: [ ].
]

{ #category : 'private' }
GbsRemoteDebugger >> canAcceptRecompile [
	^ self safeServiceCall: [ service currentContext notNil ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectFrame [
	^ self safeServiceCall: [ (service respondsTo: #canInspectCurrentFrame)
		ifTrue: [ service canInspectCurrentFrame ]
		ifFalse: [ true ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectProcess [
	^ self safeServiceCall: [ (service respondsTo: #canInspectCurrentProcess)
		ifTrue: [ service canInspectCurrentProcess ]
		ifFalse: [ true ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectReceiver [
	^ self safeServiceCall: [ (service respondsTo: #canInspectCurrentReceiver)
		ifTrue: [ service canInspectCurrentReceiver ]
		ifFalse: [ true ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectVariable [
	^ self selectedVariableName notNil
]

{ #category : 'private' }
GbsRemoteDebugger >> canRemoveAllBreakpoints [
	^ self safeServiceCall: [ service canRemoveAllBreakPoints ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canRemoveBreakpoint [
	^ self safeServiceCall: [ service canRemoveBreakPoint ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canSetBreakpoint [
	^ self safeServiceCall: [ service canSetBreakPoint ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canToggleBreakpoint [
	^ self safeServiceCall: [ service canToggleBreakPoint ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> clearServiceCompileError [
	service ifNil: [ ^ self ].
	(service respondsTo: #clearCompileError)
		ifTrue: [ [ service clearCompileError ] on: Error do: [ ] ].
]

{ #category : 'private' }
GbsRemoteDebugger >> clearSourceHighlight [
	| textSize |
	sourceText ifNil: [ ^ self ].
	[
		(sourceText respondsTo: #text)
			ifTrue: [ textSize := sourceText text asString size ]
			ifFalse: [ textSize := 0 ].
		self
			selectAndRevealFrom: textSize + 1
			to: textSize
			inTextPresenter: sourceText
	] on: Error do: [ ].
]

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
GbsRemoteDebugger >> contextSelected: selectedItem [
	| context sourceCode variables associations |

	selectedItem ifNil: [ ^ self ].
	context := selectedItem.
	(context respondsTo: #sourceCode) ifFalse: [
		| index |
		index := (stackList respondsTo: #selectedIndex)
			ifTrue: [ stackList selectedIndex ifNil: [ 0 ] ]
			ifFalse: [ 0 ].
		(index > 0 and: [ contextList notNil and: [ index <= contextList size ] ])
			ifTrue: [ context := contextList at: index ].
	].
	(selectedItem respondsTo: #sourceCode) ifFalse: [
		(context respondsTo: #sourceCode) ifTrue: [ ^ self contextSelected: context ].
		self setSourceText: ''.
		self setVariableTableItems: #().
		self setReceiverInfoItems: #().
		self setFrameInfoItems: #().
		self setProcessInfoItems: #().
		^ self
	].

	"Use the selected context"
	service ifNotNil: [ service selectContext: context ].
	context ifNil: [ ^ self ].

	"Display source code - use cached sourceString if available (from setInitialSourceCode)"
	sourceCode := nil.
	(context respondsTo: #sourceString) ifTrue: [
		sourceCode := context sourceString.
	].
	(sourceCode isNil or: [ sourceCode isEmpty ]) ifTrue: [
		sourceCode := context sourceCode.
	].
	(sourceCode isNil or: [ sourceCode isEmpty ]) ifTrue: [
		| fullSource |
		fullSource := self fetchFullSourceFor: context.
		fullSource ifNotEmpty: [
			sourceCode := fullSource.
			(context respondsTo: #sourceString:)
				ifTrue: [ context sourceString: fullSource ]
		]
	].
	(((context respondsTo: #methodClass) and: [ context methodClass = 'nil' ])
		and: [ (sourceCode includes: Character lf) not ])
		ifTrue: [
			| fullSource |
			fullSource := self fetchFullSourceFor: context.
			fullSource ifNotEmpty: [
				sourceCode := fullSource.
				(context respondsTo: #sourceString:)
					ifTrue: [ context sourceString: fullSource ].
			].
		].
	self setSourceText: (sourceCode ifNil: [ 
		"Try to get from cached sourceString"
		context sourceString ifNil: [ '' ]
	]).
	self applySourceMapHighlightFor: context.
	self syncBreakpointMarker.

	"Fetch and display variables"
	[
		variables := context tempNamesAndValues.
		associations := (variables respondsTo: #associations)
			ifTrue: [ variables associations ]
			ifFalse: [ #() ].
		self setVariableTableItems: (associations collect: [ :assoc |
			{ assoc key. assoc value asString }
		]).
	] on: Error do: [ :ex |
		self setVariableTableItems: #().
	].

	self setReceiverInfoItems: {
		{ 'self'. ([ context receiverClassOrUnknown asString ] on: Error do: [ '<unknown>' ]) }.
		{ 'self oop'. ([ context selfOop asString ] on: Error do: [ 'nil' ]) }
	}.
	self setFrameInfoItems: {
		{ 'Class'. ([ context methodClassOrUnknown asString ] on: Error do: [ '<unknown>' ]) }.
		{ 'Selector'. ([ context selectorOrUnknown asString ] on: Error do: [ '<unknown>' ]) }.
		{ 'Level'. ([ context level asString ] on: Error do: [ '0' ]) }.
		{ 'Step'. ([ context quickStepPoint asString ] on: Error do: [ '0' ]) }
	}.
	self setProcessInfoItems: {
		{ 'Process OOP'. ([ context processOop asString ] on: Error do: [ '0' ]) }.
		{ 'Method'. ([ context methodId asString ] on: Error do: [ '<unknown>' ]) }
	}.
	self refreshUiState.
]

{ #category : 'layout' }
GbsRemoteDebugger >> defaultLayout [
	| varsLeft varsRight varsAll sourceAndVars |
	varsLeft := SpPanedLayout newHorizontal
		add: variablesTable;
		add: receiverInfoTable;
		yourself.
	varsRight := SpPanedLayout newHorizontal
		add: frameInfoTable;
		add: processInfoTable;
		yourself.
	varsAll := SpPanedLayout newHorizontal
		add: varsLeft;
		add: varsRight;
		yourself.
	sourceAndVars := SpPanedLayout newVertical
		add: sourceText;
		add: varsAll;
		yourself.

	^ SpBoxLayout newVertical
		spacing: 5;
		add: mainMenu expand: false;
		add: errorMessageLabel expand: false;
		add: (SpBoxLayout newHorizontal
			spacing: 5;
			add: stepIntoButton; 
			add: stepButton;
			add: stepOverButton; 
			add: restartButton;
			add: resumeButton;
			add: runUntilReturnButton;
			add: runWithBreakAgainButton;
			add: runToCaretButton;
			add: jumpToCaretButton;
			add: returnButton;
			add: pauseButton;
			add: terminateButton;
			yourself) expand: false;
		add: (SpBoxLayout newHorizontal
			spacing: 5;
			add: inspectReceiverButton;
			add: inspectProcessButton;
			add: inspectFrameButton;
			add: inspectVariableButton;
			yourself) expand: false;
		add: (SpPanedLayout newVertical
			add: stackList;
			add: sourceAndVars;
			yourself);
		yourself
]

{ #category : 'actions' }
GbsRemoteDebugger >> fetchContextsDirectly [
	"Fetch contexts by walking the context sender chain"
	| script rawData contexts |

	processOop ifNil: [
		^ #( )
	].
	processOop = 0 ifTrue: [
		^ #( )
	].

	script := '[
		| obj ctx proc stream depth level stackReport fullEntry selectorName methodName className quickStep offsets offsetsText lineNumber sourceText offset |
		obj := Object _objectForOop: ', processOop asString, '.
		stream := WriteStream on: String new.
		obj ifNil: [ ^ '''' ].
		ctx := nil.
		proc := nil.
		(obj respondsTo: #sender) ifTrue: [ ctx := obj ].
		(ctx isNil and: [ obj respondsTo: #topContext ])
			ifTrue: [ ctx := [ obj topContext ] on: Error do: [ nil ] ].
		(ctx isNil and: [ obj respondsTo: #process ])
			ifTrue: [ proc := [ obj process ] on: Error do: [ nil ] ].
		(proc isNil and: [ obj respondsTo: #_gsiStackReportFromLevel:toLevel: ])
			ifTrue: [ proc := obj ].
		(ctx isNil and: [ proc notNil and: [ proc respondsTo: #topContext ] ])
			ifTrue: [ ctx := [ proc topContext ] on: Error do: [ nil ] ].

		"Preferred path: process stack report (works when topContext is unavailable)"
		(proc notNil and: [ proc respondsTo: #_gsiStackReportFromLevel:toLevel: ]) ifTrue: [
			level := 1.
			[ level <= 30 ] whileTrue: [
				stackReport := [ proc _gsiStackReportFromLevel: level toLevel: level ] on: Error do: [ nil ].
				(stackReport isNil or: [ stackReport size < 2 ])
					ifTrue: [ level := 31 ]
					ifFalse: [
						fullEntry := stackReport at: 2.
						className := [ fullEntry first inClass name ] on: Error do: [ ''<unknown>'' ].
						selectorName := [ (fullEntry at: 4) asString ] on: Error do: [ ''<unknown>'' ].
						methodName := [ (fullEntry first selector) asString ] on: Error do: [ ''<unknown>'' ].
						quickStep := [ (fullEntry at: 5) ] on: Error do: [ 0 ].
						quickStep ifNil: [ quickStep := 0 ].
						offsets := [ fullEntry at: 6 ] on: Error do: [ #() ].
						offsets ifNil: [ offsets := #() ].
						offsetsText := String streamContents: [ :offsetStream |
							1 to: offsets size do: [ :idx |
								| raw |
								raw := offsets at: idx.
								raw isNil
									ifTrue: [ offsetStream nextPutAll: ''nil'' ]
									ifFalse: [ offsetStream nextPutAll: raw asString ].
								idx < offsets size ifTrue: [ offsetStream nextPut: $, ]
							]
						].
						lineNumber := 0.
						sourceText := [ (fullEntry at: 9) asString ] on: Error do: [ '''' ].
						sourceText ifNil: [ sourceText := '''' ].
						(quickStep isNumber and: [ quickStep > 0 and: [ quickStep <= offsets size ] ]) ifTrue: [
							offset := [ (offsets at: quickStep) asInteger ] on: Error do: [ nil ].
							(offset isNumber and: [ offset > 0 ]) ifTrue: [
								lineNumber := 1.
								1 to: ((offset - 1) min: sourceText size) do: [ :i |
									| ch |
									ch := sourceText at: i.
									(ch = Character lf or: [ ch = Character cr ]) ifTrue: [ lineNumber := lineNumber + 1 ]
								]
							]
						].
						stream
							nextPutAll: level asString; tab;
							nextPutAll: className; tab;
							nextPutAll: selectorName; tab;
							nextPutAll: methodName; tab;
							nextPutAll: quickStep asString; tab;
							nextPutAll: offsetsText; tab;
							nextPutAll: lineNumber asString;
							lf.
						level := level + 1
					]
			].
			stream position > 0 ifTrue: [ ^ stream contents ].
		].

		ctx ifNil: [ ^ ''<ctx is nil>'' ].
		depth := 0.
		[ ctx notNil and: [ depth < 30 ] ] whileTrue: [
			className := [ ctx method inClass name ] on: Error do: [ ''<unknown>'' ].
			depth := depth + 1.
			stream
				nextPutAll: depth asString; tab;
				nextPutAll: className; tab;
				nextPutAll: (([ ctx selector asString ] on: Error do: [ ''<unknown>'' ])); tab;
				nextPutAll: (([ ctx method ifNil: [ ''<unknown>'' ] ifNotNil: [ :m | m selector asString ] ] on: Error do: [ ''<unknown>'' ]));
				lf.
			ctx := [ ctx sender ] on: Error do: [ nil ].
		].
		stream contents
	] value'.

	[
		rawData := session evaluate: script.
		(rawData respondsTo: #asLocalString) ifTrue: [ rawData := rawData asLocalString ].
		rawData ifNil: [ rawData := '' ].
	] on: Error do: [ :ex |
		^ #( )
	].

	rawData ifNil: [
		^ #( )
	].
	rawData = false ifTrue: [
		^ #( )
	].
	(rawData respondsTo: #isEmpty) ifFalse: [
		^ #( )
	].
	rawData isEmpty ifTrue: [
		^ #( )
	].

	contexts := (rawData splitOn: Character lf)
		collect: [ :line |
			| parts levelValue classValue selectorValue methodValue quickStepValue offsetsTokens offsetsValue lineNumberValue |
			line isEmpty ifTrue: [ nil ] ifFalse: [
				parts := line splitOn: Character tab.
				parts size >= 3 ifTrue: [
					levelValue := ([ parts first asInteger ] on: Error do: [ 1 ]).
					classValue := (parts size >= 2 ifTrue: [ parts at: 2 ] ifFalse: [ '<unknown>' ]).
					selectorValue := (parts size >= 3 ifTrue: [ parts at: 3 ] ifFalse: [ '<unknown>' ]).
					methodValue := (parts size >= 4 ifTrue: [ parts at: 4 ] ifFalse: [ selectorValue ]).
					quickStepValue := (parts size >= 5
						ifTrue: [ [ (parts at: 5) asInteger ] on: Error do: [ 0 ] ]
						ifFalse: [ 0 ]).
					offsetsTokens := (parts size >= 6
						ifTrue: [ (parts at: 6) splitOn: $, ]
						ifFalse: [ #() ]).
					lineNumberValue := (parts size >= 7
						ifTrue: [ [ (parts at: 7) asInteger ] on: Error do: [ 0 ] ]
						ifFalse: [ 0 ]).
					offsetsValue := offsetsTokens collect: [ :token |
						| cleaned |
						cleaned := token withBlanksTrimmed.
						cleaned isEmpty ifTrue: [ nil ] ifFalse: [
							cleaned = 'nil'
								ifTrue: [ nil ]
								ifFalse: [ [ cleaned asInteger ] on: Error do: [ nil ] ]
						]
					].
					[ | activation |
					activation := GbxActivation new.
					(activation respondsTo: #session:)
						ifTrue: [ activation session: session ]
						ifFalse: [ activation instVarNamed: 'session' put: session ].
					activation
						processOop: processOop;
						level: levelValue;
						methodClass: classValue;
						selector: ([ selectorValue asSymbol ] on: Error do: [ #unknown ]);
						gsMethodId: methodValue;
						quickStepPoint: quickStepValue;
						sourceOffsets: offsetsValue;
						sourceString: '';
						ipOffset: lineNumberValue;
						yourself
					] on: Error do: [ nil ]
				]
			]
		] thenSelect: #isNotNil.

	^ contexts
]

{ #category : 'private' }
GbsRemoteDebugger >> fetchFullSourceFor: aContext [
	| ctxProcessOop levelValue script raw |
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

	script := '[
		| obj stackReport fullEntry src ctx i |
		obj := Object _objectForOop: ', ctxProcessOop asString, '.
		obj ifNil: [ ^ '''' ].
		stackReport := [ obj _gsiStackReportFromLevel: ', levelValue asString, ' toLevel: ', levelValue asString, ' ] on: Error do: [ nil ].
		src := ''''.
		(stackReport notNil and: [ stackReport size >= 2 ]) ifTrue: [
			fullEntry := stackReport at: 2.
			(fullEntry notNil and: [ fullEntry size >= 9 ]) ifTrue: [
				src := [ fullEntry at: 9 ] on: Error do: [ '''' ].
				src ifNil: [ src := '''' ].
				src := src asString.
			]
		].

		"Fallback for do-it frames where stack report source can be truncated."
		((src includes: Character lf) not) ifTrue: [
			ctx := nil.
			(obj respondsTo: #topContext)
				ifTrue: [ ctx := [ obj topContext ] on: Error do: [ nil ] ].
			(ctx isNil and: [ obj respondsTo: #sender ])
				ifTrue: [ ctx := obj ].
			ctx ifNotNil: [
				i := 1.
				[ i < ', levelValue asString, ' and: [ ctx notNil ] ] whileTrue: [
					ctx := [ ctx sender ] on: Error do: [ nil ].
					i := i + 1
				].
				ctx ifNotNil: [
					src := [ ctx sourceCode ] on: Error do: [ src ].
					src ifNil: [ src := '''' ].
					src := src asString.
				]
			]
		].

		src isEmpty ifTrue: [ ^ '''' ].
		src := src
			copyReplaceAll: String cr with: ''<CR>'';
			copyReplaceAll: String lf with: ''<LF>'';
			copyReplaceAll: Character tab asString with: ''<TAB>''.
		src
	] value'.

	raw := [ session evaluate: script ] on: Error do: [ '' ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	raw ifNil: [ ^ '' ].
	^ ((raw copyReplaceAll: '<TAB>' with: Character tab asString)
		copyReplaceAll: '<CR>' with: String cr;
		copyReplaceAll: '<LF>' with: String lf)
]

{ #category : 'actions' }
GbsRemoteDebugger >> fetchStackFrames [
	| contexts |

	"Check if we have captured stack data"
	stackData ifNotNil: [
		^ self fetchStackFramesFromData
	].

	contexts := #( ).
	service ifNotNil: [
		[
			(service respondsTo: #recomputeContextList)
				ifTrue: [ service recomputeContextList ].
			contexts := service contextList
		] on: Error do: [ contexts := #( ) ]
	].

	contexts ifEmpty: [
		contexts := self fetchContextsDirectly
	].

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
		^ self
	].
	stackList items: (contextList collect: [ :ctx | ctx printString ]).

	contextList ifNotEmpty: [
		| preferredIndex |
		"We no longer unconditionally mark the first context here.
		Executed code frames are identified by their class/selector in printString.
		Special marking/resetting for Restart is handled in normalizeRestartSelectionAndPosition."
		preferredIndex := self preferredInitialContextIndex.
		stackList selectIndex: preferredIndex.
		self contextSelected: (contextList at: preferredIndex)
	].
	self refreshUiState.
]

{ #category : 'actions' }
GbsRemoteDebugger >> fetchStackFramesFromData [
	"Build context list from captured stack data"
	| contexts index |
	
	index := 0.
	contexts := stackData splitOn: $^ thenCollect: [ :frameStr |
		| parts activation |
		parts := frameStr splitOn: $|.
		parts size >= 3 ifTrue: [
			index := index + 1.
			activation := GbxActivation new.
			(activation respondsTo: #session:)
				ifTrue: [ activation session: session ]
				ifFalse: [ activation instVarNamed: 'session' put: session ].
			activation
				processOop: 0;
				level: index;
				selector: (parts at: 1) asSymbol;
				gsMethodId: (parts at: 2);
				sourceString: (parts at: 3);
				yourself
		]
	] thenSelect: #isNotNil.
	
	contextList := contexts.
	stackList items: (contexts collect: [ :ctx | ctx printString ]).

	contexts ifNotEmpty: [
		| preferredIndex firstContext |
		"Mark first frame as executed code frame so it shows 'GS: Executed code @...'"
		firstContext := contexts at: 1.
		(firstContext respondsTo: #markAsExecutedCodeFrame) ifTrue: [
			firstContext markAsExecutedCodeFrame.
		].
		preferredIndex := self preferredInitialContextIndex.
		stackList selectIndex: preferredIndex.
		self contextSelected: (contexts at: preferredIndex)
	].
]

{ #category : 'actions' }
GbsRemoteDebugger >> gsDoIt [
	| code |
	service ifNil: [ ^ false ].
	code := self selectedSourceOrAll.
	^ [ service gsDoIt: code ] on: Error do: [ false ]
]

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

{ #category : 'private' }
GbsRemoteDebugger >> highlightSourceLineFromCompileError: errorMessage [
	| lower lineToken idx start lineNumber |
	(errorMessage isString and: [ errorMessage isEmpty not ]) ifFalse: [ ^ self ].
	(sourceText respondsTo: #text) ifFalse: [ ^ self ].
	lower := errorMessage asLowercase.
	lineToken := 'line '.
	idx := lower findString: lineToken startingAt: 1.
	idx = 0 ifTrue: [ ^ self ].
	start := idx + lineToken size.
	lineNumber := [ (lower copyFrom: start to: lower size) asNumber ] on: Error do: [ nil ].
	lineNumber ifNil: [ ^ self ].
	self selectLineNumber: lineNumber inTextPresenter: sourceText.
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
		label: 'Inspect Frame';
		action: [ self inspectFrame ].
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
GbsRemoteDebugger >> inspectFrame [
	^ self safeServiceCall: [ service inspectCurrentFrame ] default: false
]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectProcess [
	^ self safeServiceCall: [ service inspectCurrentProcess ] default: false
]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectReceiver [
	^ self safeServiceCall: [ service inspectCurrentReceiver ] default: false
]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectVariable [
	| variableName |
	service ifNil: [ ^ false ].
	variableName := self selectedVariableName.
	variableName ifNil: [ ^ false ].
	(service respondsTo: #inspectVariableNamed:)
		ifTrue: [ ^ self safeServiceCall: [ service inspectVariableNamed: variableName ] default: false ].
	^ false
]

{ #category : 'private' }
GbsRemoteDebugger >> isLikelyUserFrame: aContext [
	| className selectorName source |
	aContext ifNil: [ ^ false ].

	className := [ aContext methodClassOrUnknown ] on: Error do: [ '<unknown>' ].
	selectorName := [ aContext selectorOrUnknown asString ] on: Error do: [ '<unknown>' ].
	source := [ aContext sourceString ifNil: [ '' ] ] on: Error do: [ '' ].

	(className beginsWith: 'AbstractException') ifTrue: [ ^ false ].
	(className beginsWith: 'GsNMethod') ifTrue: [ ^ false ].
	(selectorName beginsWith: '_') ifTrue: [ ^ false ].
	(#('signal' 'defaultAction' '_defaultAction' '_signal' '_signalToDebugger') includes: selectorName) ifTrue: [ ^ false ].
	source isEmpty ifTrue: [ ^ false ].

	^ true
]

{ #category : 'accessing' }
GbsRemoteDebugger >> label: aString [
	errorMessageLabel ifNotNil: [ errorMessageLabel label: aString ]
]

{ #category : 'accessing' }
GbsRemoteDebugger >> setInitialSourceCode: aString [
	"Set the source code for the first (top) context - the code that was being executed"
	| topContext |

	contextList ifEmpty: [ ^ self ].
	topContext := contextList at: 1.

	"Set source string directly on the context"
	topContext instVarNamed: #sourceString put: aString.

	"Select the top context to show the source"
	stackList selectIndex: 1.
	self contextSelected: topContext
]

{ #category : 'private' }
GbsRemoteDebugger >> preferredInitialContextIndex [
	| index |
	contextList ifNil: [ ^ 1 ].
	contextList isEmpty ifTrue: [ ^ 1 ].

	index := contextList
		findFirst: [ :ctx | self isLikelyUserFrame: ctx ].
	index = 0 ifTrue: [ ^ 1 ].
	^ index
]

{ #category : 'accessing' }
GbsRemoteDebugger >> processOop [
	^ processOop
]

{ #category : 'accessing' }
GbsRemoteDebugger >> processOop: anOop [
	processOop := anOop.
	stackList ifNotNil: [ self fetchStackFrames ].
]

{ #category : 'private' }
GbsRemoteDebugger >> refreshUiState [
	self updateButton: inspectReceiverButton enabled: self canInspectReceiver.
	self updateButton: inspectProcessButton enabled: self canInspectProcess.
	self updateButton: inspectFrameButton enabled: self canInspectFrame.
	self updateButton: inspectVariableButton enabled: self canInspectVariable.
]

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

{ #category : 'actions' }
GbsRemoteDebugger >> resume [
	self safeServiceCall: [ service resume ] default: false.
	self withWindowDo: [ :window | window close ]
]

{ #category : 'private' }
GbsRemoteDebugger >> safeServiceCall: aBlock default: defaultValue [
	service ifNil: [ ^ defaultValue ].
	^ [ aBlock value ] on: Error do: [ defaultValue ]
]

{ #category : 'private' }
GbsRemoteDebugger >> selectLineNumber: lineNumber inTextPresenter: aTextPresenter [
	| text pos currentLine lineStart lineEnd |
	(lineNumber isNumber and: [ lineNumber > 0 ]) ifFalse: [ ^ self ].
	text := aTextPresenter text asString.
	text isEmpty ifTrue: [ ^ self ].
	pos := 1.
	currentLine := 1.
	[ currentLine < lineNumber and: [ pos <= text size ] ] whileTrue: [
		(text at: pos) = Character lf ifTrue: [ currentLine := currentLine + 1 ].
		pos := pos + 1
	].
	currentLine = lineNumber ifFalse: [ ^ self ].
	lineStart := pos min: text size.
	lineEnd := lineStart.
	[ lineEnd <= text size and: [ (text at: lineEnd) ~= Character lf ] ] whileTrue: [
		lineEnd := lineEnd + 1
	].
	lineEnd := lineEnd - 1.
	lineEnd < lineStart ifTrue: [ lineEnd := lineStart ].
	self selectAndRevealFrom: lineStart to: lineEnd inTextPresenter: aTextPresenter.
]

{ #category : 'private' }
GbsRemoteDebugger >> selectAndRevealFrom: startIndex to: endIndex inTextPresenter: aTextPresenter [
	| start stop textSize |
	aTextPresenter ifNil: [ ^ self ].
	start := startIndex ifNil: [ 1 ].
	stop := endIndex ifNil: [ start ].
	stop < start ifTrue: [ stop := start ].
	textSize := [ aTextPresenter text asString size ] on: Error do: [ 0 ].
	textSize > 0 ifTrue: [
		start := (start max: 1) min: textSize.
		stop := (stop max: start) min: textSize
	].

	[
		"Standard Spec2 way"
		(aTextPresenter respondsTo: #selectionInterval:)
			ifTrue: [ aTextPresenter selectionInterval: (start to: stop) ]
			ifFalse: [
				(aTextPresenter respondsTo: #selectFrom:to:)
					ifTrue: [ aTextPresenter selectFrom: start to: stop ]
			].

		"Pharo 13/Spec2 visibility hacks"
		aTextPresenter withAdapterDo: [ :adapter |
			| widget |
			widget := [ adapter widget ] on: Error do: [ nil ].
			widget ifNotNil: [
				"Morph-level ensuring of selection"
				(widget respondsTo: #setSelection:) ifTrue: [ widget setSelection: (start to: stop) ].
				
				"Scroll into view"
				(widget respondsTo: #scrollSelectionIntoView) ifTrue: [ widget scrollSelectionIntoView ].
				
				"If it's a RubScrolledTextMorph (common in P13)"
				(widget respondsTo: #textArea) ifTrue: [
					| textArea editor |
					textArea := widget textArea.
					textArea ifNotNil: [
						(textArea respondsTo: #selectFrom:to:) ifTrue: [ textArea selectFrom: start to: stop ].
						editor := (textArea respondsTo: #editor)
							ifTrue: [ [ textArea editor ] on: Error do: [ nil ] ]
							ifFalse: [ nil ].
						editor ifNotNil: [
							(editor respondsTo: #markIndex:) ifTrue: [ editor markIndex: start ].
							(editor respondsTo: #pointIndex:) ifTrue: [ editor pointIndex: stop ].
							(editor respondsTo: #selectFrom:to:) ifTrue: [ editor selectFrom: start to: stop ].
							(editor respondsTo: #selectAt:) ifTrue: [ editor selectAt: stop ].
						].
						(textArea respondsTo: #scrollSelectionIntoView) ifTrue: [ textArea scrollSelectionIntoView ].
					]
				]
			]
		].
	] on: Error do: [ :ex | ].
]

{ #category : 'private' }
GbsRemoteDebugger >> selectedSourceOrAll [
	| selected text |
	sourceText ifNil: [ ^ '' ].
	selected := (sourceText respondsTo: #selectedText)
		ifTrue: [ sourceText selectedText ]
		ifFalse: [ nil ].
	(selected isString and: [ selected isEmpty not ]) ifTrue: [ ^ selected ].
	text := (sourceText respondsTo: #text)
		ifTrue: [ sourceText text ]
		ifFalse: [ '' ].
	^ text asString
]

{ #category : 'private' }
GbsRemoteDebugger >> selectedVariableName [
	| selectedItem |
	variablesTable ifNil: [ ^ nil ].
	selectedItem := (variablesTable respondsTo: #selectedItem)
		ifTrue: [ variablesTable selectedItem ]
		ifFalse: [
			((variablesTable respondsTo: #selection) and: [ variablesTable selection notNil ])
				ifTrue: [
					(variablesTable selection respondsTo: #selectedItem)
						ifTrue: [ variablesTable selection selectedItem ]
						ifFalse: [ nil ]
				]
				ifFalse: [ nil ]
		].
	selectedItem ifNil: [ ^ nil ].
	(selectedItem isArray and: [ selectedItem size >= 1 ]) ifTrue: [ ^ selectedItem first asString ].
	(selectedItem respondsTo: #key) ifTrue: [ ^ selectedItem key asString ].
	^ nil
]

{ #category : 'accessing' }
GbsRemoteDebugger >> service [
	^ service
]

{ #category : 'accessing' }
GbsRemoteDebugger >> service: aService [
	service := aService
]

{ #category : 'accessing' }
GbsRemoteDebugger >> session [
	^ session
]

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
GbsRemoteDebugger >> setSourceText: aString [
	sourceText ifNil: [ ^ self ].
	(sourceText respondsTo: #text:)
		ifTrue: [
			[ sourceText text: aString ] on: Error do: [ ]
		].
]

{ #category : 'private' }
GbsRemoteDebugger >> setVariableTableItems: aCollection [
	variablesTable ifNil: [ ^ self ].
	(variablesTable respondsTo: #items:)
		ifTrue: [
			[ variablesTable items: aCollection ] on: Error do: [ ]
		].
]

{ #category : 'private' }
GbsRemoteDebugger >> setReceiverInfoItems: aCollection [
	receiverInfoTable ifNil: [ ^ self ].
	(receiverInfoTable respondsTo: #items:)
		ifTrue: [ [ receiverInfoTable items: aCollection ] on: Error do: [ ] ].
]

{ #category : 'private' }
GbsRemoteDebugger >> setFrameInfoItems: aCollection [
	frameInfoTable ifNil: [ ^ self ].
	(frameInfoTable respondsTo: #items:)
		ifTrue: [ [ frameInfoTable items: aCollection ] on: Error do: [ ] ].
]

{ #category : 'private' }
GbsRemoteDebugger >> setProcessInfoItems: aCollection [
	processInfoTable ifNil: [ ^ self ].
	(processInfoTable respondsTo: #items:)
		ifTrue: [ [ processInfoTable items: aCollection ] on: Error do: [ ] ].
]

{ #category : 'private' }
GbsRemoteDebugger >> showCompileErrorInSourcePane [
	| message currentText |
	message := self safeServiceCall: [ service lastCompileError ] default: nil.
	message ifNil: [ message := 'Compile failed in GemStone.' ].
	currentText := (sourceText respondsTo: #text)
		ifTrue: [ sourceText text asString ]
		ifFalse: [ '' ].
	self setSourceText: currentText, String lf, String lf, '"Compile error: ', message asString, '"'.
	self highlightSourceLineFromCompileError: message.
]

{ #category : 'private' }
GbsRemoteDebugger >> sourceMapFor: aContext [
	| map |
	map := #( ).
	service ifNotNil: [
		map := [ service sourceMap ] on: Error do: [ #( ) ]
	].
	((map isCollection and: [ map isEmpty not ]) or: [ aContext isNil ]) ifTrue: [ ^ map ].
	^ [ aContext visibleSourceMap ] on: Error do: [ #( ) ]
]

{ #category : 'private' }
GbsRemoteDebugger >> sourceMenu [
	| menu |
	menu := self newMenu.
	menu addGroup: [ :group |
		self
			configureMenuItem: group
			named: 'GS-Do it'
			action: [ self gsDoIt ]
			enabled: true.
		self
			configureMenuItem: group
			named: 'GS-Print it'
			action: [ self gsPrintIt ]
			enabled: true.
		self
			configureMenuItem: group
			named: 'GS-Inspect it'
			action: [ self gsInspectIt ]
			enabled: true.
		self
			configureMenuItem: group
			named: 'Accept/Recompile'
			action: [ self acceptSourceEdits ]
			enabled: self canAcceptRecompile ].
	menu addGroup: [ :group |
		self
			configureMenuItem: group
			named: 'Toggle Breakpoint'
			action: [ self toggleBreakPoint ]
			enabled: (self canToggleBreakpoint).
		self
			configureMenuItem: group
			named: 'Set Breakpoint'
			action: [ self setBreakPoint ]
			enabled: (self canSetBreakpoint).
		self
			configureMenuItem: group
			named: 'Remove Breakpoint'
			action: [ self removeBreakPoint ]
			enabled: (self canRemoveBreakpoint).
		self
			configureMenuItem: group
			named: 'Remove All Breakpoints'
			action: [ self removeAllBreakPoints ]
			enabled: (self canRemoveAllBreakpoints) ].
	menu addGroup: [ :group |
		self
			configureMenuItem: group
			named: 'Inspect Receiver'
			action: [ self inspectReceiver ]
			enabled: (self canInspectReceiver).
		self
			configureMenuItem: group
			named: 'Inspect Process'
			action: [ self inspectProcess ]
			enabled: (self canInspectProcess).
		self
			configureMenuItem: group
			named: 'Inspect Frame'
			action: [ self inspectFrame ]
			enabled: (self canInspectFrame).
		self
			configureMenuItem: group
			named: 'Inspect Variable'
			action: [ self inspectVariable ]
			enabled: (self canInspectVariable) ].
	^ menu
]

{ #category : 'accessing' }
GbsRemoteDebugger >> stackData: anArray [
	stackData := anArray.
	stackList ifNotNil: [ self fetchStackFrames ].
]

{ #category : 'actions' }
GbsRemoteDebugger >> stepInto [
	| didStep |
	didStep := self safeServiceCall: [ service stepInto ] default: false.
	didStep ifFalse: [
		didStep := self
			directStepWithPrimarySelector: '_stepIntoInFrame:'
			fallbackSelector: '_stepOverInFrame:'
	].
	didStep ifTrue: [ self fetchStackFrames ].
	^ didStep
]

{ #category : 'actions' }
GbsRemoteDebugger >> step [
	^ self stepInto
]

{ #category : 'actions' }
GbsRemoteDebugger >> stepOver [
	| didStep |
	didStep := self safeServiceCall: [ service stepOver ] default: false.
	didStep ifFalse: [
		didStep := self
			directStepWithPrimarySelector: '_stepOverInFrame:'
			fallbackSelector: nil
	].
	didStep ifTrue: [ self fetchStackFrames ].
	^ didStep
]

{ #category : 'actions' }
GbsRemoteDebugger >> stepReturn [
	| didStep |
	didStep := self safeServiceCall: [ service stepReturn ] default: false.
	didStep ifTrue: [ self fetchStackFrames ].
	^ didStep
]

{ #category : 'private' }
GbsRemoteDebugger >> currentSelectedFrameLevel [
	| context index |
	service ifNotNil: [
		context := self safeServiceCall: [ service currentContext ] default: nil.
		(context notNil and: [ context respondsTo: #level ]) ifTrue: [ ^ context level ].
	].
	index := (stackList notNil and: [ stackList respondsTo: #selectedIndex ])
		ifTrue: [ stackList selectedIndex ifNil: [ 0 ] ]
		ifFalse: [ 0 ].
	(index > 0 and: [ contextList notNil and: [ index <= contextList size ] ]) ifTrue: [
		context := contextList at: index.
		(context respondsTo: #level) ifTrue: [ ^ context level ]
	].
	^ 1
]

{ #category : 'private' }
GbsRemoteDebugger >> directStepWithPrimarySelector: primarySelector fallbackSelector: fallbackSelector [
	| level script raw value |
	(session isNil or: [ processOop isNil ]) ifTrue: [ ^ false ].
	(processOop isNumber and: [ processOop > 20 ]) ifFalse: [ ^ false ].
	level := self currentSelectedFrameLevel.
	level ifNil: [ level := 1 ].

	script := '[
		| obj proc level selector ok |
		obj := Object _objectForOop: ', processOop asString, '.
		obj isNil ifTrue: [ ^ ''false'' ].
		proc := obj.
		((proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not) ifTrue: [
			(obj respondsTo: #serverProcess) ifTrue: [ proc := [ obj serverProcess ] on: Error do: [ nil ] ].
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #process ]) ifTrue: [
			proc := [ obj process ] on: Error do: [ nil ]
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #topContext ]) ifTrue: [
			| top |
			top := [ obj topContext ] on: Error do: [ nil ].
			(top notNil and: [ top respondsTo: #process ])
				ifTrue: [ proc := [ top process ] on: Error do: [ nil ] ]
		].
		(proc isNil or: [ (proc respondsTo: #perform:with:) not ]) ifTrue: [ ^ ''false'' ].
		level := ', level asString, '.
		selector := #', primarySelector, '.
		ok := [ proc perform: selector with: level ] on: Error do: [ nil ].
		(ok isNil and: [ ''', (fallbackSelector ifNil: '' ifNotNil: [ fallbackSelector ]), ''' notEmpty ]) ifTrue: [
			ok := [ proc perform: #', (fallbackSelector ifNil: '_doesNotExist:' ifNotNil: [ fallbackSelector ]), ' with: level ] on: Error do: [ nil ]
		].
		ok isNil ifTrue: [ ^ ''false'' ].
		''true''
	] value'.

	raw := [ session executeAndFetch: script context: 20 ] on: Error do: [ nil ].
	raw ifNil: [ ^ false ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	value := (raw respondsTo: #asString)
		ifTrue: [ raw asString asLowercase ]
		ifFalse: [ '' ].
	^ value = 'true' or: [ value = '1' or: [ value = 'ok' ] ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> runUntilReturn [
	^ self stepReturn
]

{ #category : 'actions' }
GbsRemoteDebugger >> runWithBreakAgain [
	self safeServiceCall: [ service resume ] default: false.
	self fetchStackFrames.
	^ true
]

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
GbsRemoteDebugger >> terminate [
	self safeServiceCall: [ service terminate ] default: false.
	self withWindowDo: [ :window | window close ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> toggleBreakPoint [
	service ifNil: [ ^ false ].
	^ self withBreakpointRefresh: [ service toggleBreakPointIn: sourceText ]
]

{ #category : 'private' }
GbsRemoteDebugger >> updateButton: aButton enabled: enabledBoolean [
	aButton ifNil: [ ^ self ].
	(aButton respondsTo: #enabled:)
		ifTrue: [ [ aButton enabled: enabledBoolean ] on: Error do: [ ] ].
]

{ #category : 'private' }
GbsRemoteDebugger >> withBreakpointRefresh: aBlock [
	| result |
	result := [ aBlock value ] on: Error do: [ false ].
	self syncBreakpointMarker.
	self refreshUiState.
	^ result
]

{ #category : 'menus' }
GbsRemoteDebugger >> buildMenuBar [
	^ self newMenuBar
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Stack'; subMenu: self stackMenu ].
			group addItem: [ :item | item name: 'Method'; subMenu: self methodMenu ].
			group addItem: [ :item | item name: 'Edit'; subMenu: self editMenu ].
			group addItem: [ :item | item name: 'Execute'; subMenu: self executeMenu ].
			group addItem: [ :item | item name: 'Correct'; subMenu: self correctMenu ] ];
		yourself
]

{ #category : 'menus' }
GbsRemoteDebugger >> correctMenu [
	^ self newMenu
		addItem: [ :item |
			item
				name: 'Define Method';
				action: [ self acceptSourceEdits ] ];
		addItem: [ :item |
			item
				name: 'Correct Selector';
				action: [ self correctSelector ] ];
		yourself
]

{ #category : 'menus' }
GbsRemoteDebugger >> editMenu [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Accepting'; action: [ self acceptSourceEdits ] ].
			group addItem: [ :item | item name: 'Format'; action: [ self formatSource ] ].
			group addItem: [ :item | item name: 'Insert Breakpoint'; action: [ self setBreakPoint ] ].
			group addItem: [ :item | item name: 'Remove This Probe'; action: [ self removeBreakPoint ] ].
			group addItem: [ :item | item name: 'GS-Insert Breakpoint'; action: [ self setBreakPoint ] ].
			group addItem: [ :item | item name: 'GS-Remove Breakpoint'; action: [ self removeBreakPoint ] ].
			group addItem: [ :item | item name: 'GS-Remove All Breakpoints'; action: [ self removeAllBreakPoints ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Do it'; action: [ self localDoIt ] ].
			group addItem: [ :item | item name: 'Print it'; action: [ self localPrintIt ] ].
			group addItem: [ :item | item name: 'Inspect it'; action: [ self localInspectIt ] ].
			group addItem: [ :item | item name: 'Debug it'; action: [ self localDebugIt ] ].
			group addItem: [ :item | item name: 'GS-Do it'; action: [ self gsDoIt ] ].
			group addItem: [ :item | item name: 'GS-Print it'; action: [ self gsPrintIt ] ].
			group addItem: [ :item | item name: 'GS-Inspect it'; action: [ self gsInspectIt ] ].
			group addItem: [ :item | item name: 'GS-Debug it'; action: [ self gsDebugIt ] ] ];
		yourself
]

{ #category : 'menus' }
GbsRemoteDebugger >> executeMenu [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Step Into'; action: [ self stepInto ] ].
			group addItem: [ :item | item name: 'Step'; action: [ self stepInto ] ].
			group addItem: [ :item | item name: 'Step Over'; action: [ self stepOver ] ].
			group addItem: [ :item | item name: 'Restart'; action: [ self restart ] ].
			group addItem: [ :item | item name: 'Run'; action: [ self resume ] ].
			group addItem: [ :item | item name: 'Run until Return'; action: [ self stepReturn ] ].
			group addItem: [ :item | item name: 'Run with Break Again'; action: [ self resume ] ].
			group addItem: [ :item | item name: 'Run to Caret'; action: [ self runToCaret ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Jump to Caret'; action: [ self jumpToCaret ] ].
			group addItem: [ :item | item name: 'Return...'; action: [ self returnFromFrame ] ].
			group addItem: [ :item | item name: 'Pause'; action: [ self pauseProcess ] ].
			group addItem: [ :item | item name: 'Terminate'; action: [ self terminate ] ] ];
		yourself
]

{ #category : 'menus' }
GbsRemoteDebugger >> methodMenu [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Browse'; action: [ self browseSelectedMethod ] ].
			group addItem: [ :item | item name: 'GS-Senders'; action: [ self gsBrowseAllReferences ] ].
			group addItem: [ :item | item name: 'GS-Implementors'; action: [ self gsBrowseAllImplementors ] ].
			group addItem: [ :item | item name: 'GS-Hierarchy Senders'; action: [ self gsBrowseAllHierarchyReferences ] ].
			group addItem: [ :item | item name: 'GS-Hierarchy Implementors'; action: [ self gsBrowseAllHierarchyImplementors ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Senders'; action: [ self browseLocalSenders ] ].
			group addItem: [ :item | item name: 'Implementors'; action: [ self browseLocalImplementors ] ].
			group addItem: [ :item | item name: 'Hierarchy Senders'; action: [ self browseLocalHierarchySenders ] ].
			group addItem: [ :item | item name: 'Hierarchy Implementors'; action: [ self browseLocalHierarchyImplementors ] ].
			group addItem: [ :item | item name: 'Show Containing Package...'; action: [ self showContainingPackage ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Recompile with Full Blocks'; action: [ self acceptSourceEdits ] ] ];
		yourself
]

{ #category : 'menus' }
GbsRemoteDebugger >> stackMenu [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Copy Stack Report'; action: [ self copyStackReport ] ].
			group addItem: [ :item | item name: 'Show More'; action: [ self showMoreContexts ] ].
			group addItem: [ :item | item name: 'Filter Stack'; action: [ self toggleFilterStack ] ].
			group addItem: [ :item | item name: 'Select Home Context'; action: [ self selectHomeContext ] ].
			group addItem: [ :item | item name: 'Inspect Context'; action: [ self inspectFrame ] ].
			group addItem: [ :item | item name: 'Bookmark Context'; action: [ self bookmarkContext ] ].
			group addItem: [ :item | item name: 'Clear Bookmark'; action: [ self clearBookmarkContext ] ].
			group addItem: [ :item | item name: 'Inspect Process'; action: [ self inspectProcess ] ].
			group addItem: [ :item | item name: 'Show Glue'; action: [ self toggleGlueHiding ] ] ];
		yourself
]

{ #category : 'private' }
GbsRemoteDebugger >> bookmarkContext [
	| index |
	stackList ifNil: [ ^ false ].
	index := (stackList respondsTo: #selectedIndex)
		ifTrue: [ stackList selectedIndex ]
		ifFalse: [ nil ].
	index ifNil: [ ^ false ].
	bookmarkContextIndex := index.
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> browseSelectedMethod [
	(service respondsTo: #browseMethod)
		ifTrue: [ ^ self safeServiceCall: [ service browseMethod ] default: false ].
	^ self openServerMethodReference: self selectedServerMethodReference
]

{ #category : 'private' }
GbsRemoteDebugger >> clearBookmarkContext [
	bookmarkContextIndex := nil.
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> copyStackReport [
	| report |
	report := self stackReportString.
	report isEmpty ifTrue: [ ^ false ].
	Clipboard clipboardText: report.
	^ true
]

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

{ #category : 'private' }
GbsRemoteDebugger >> firstUserContextIndex [
	^ self preferredInitialContextIndex
]

{ #category : 'private' }
GbsRemoteDebugger >> formatSource [
	| text |
	sourceText ifNil: [ ^ false ].
	(sourceText respondsTo: #text) ifFalse: [ ^ false ].
	text := sourceText text asString.
	(sourceText respondsTo: #text:)
		ifTrue: [ sourceText text: text withBlanksTrimmed ].
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> gsDebugIt [
	| code errorText processCandidate |
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
				self class
					openOn: errorText
					process: processCandidate
					session: session.
				true
			]
			ifFalse: [ UIManager default inform: errorText. false ]
	]
]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllHierarchyImplementors [
	^ self gsBrowseQueryFor: self selectedServerSelector hierarchyOnly: true senders: false
]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllHierarchyReferences [
	^ self gsBrowseQueryFor: self selectedServerSelector hierarchyOnly: true senders: true
]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllImplementors [
	^ self gsBrowseQueryFor: self selectedServerSelector hierarchyOnly: false senders: false
]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseAllReferences [
	^ self gsBrowseQueryFor: self selectedServerSelector hierarchyOnly: false senders: true
]

{ #category : 'private' }
GbsRemoteDebugger >> gsBrowseQueryFor: aSelector hierarchyOnly: hierarchyOnly senders: sendersOnly [
	| references selected |
	aSelector ifNil: [ ^ false ].
	references := self serverMethodReferencesFor: aSelector hierarchyOnly: hierarchyOnly senders: sendersOnly.
	references isEmpty ifTrue: [
		UIManager default inform: 'No matching GemStone methods found.'.
		^ false
	].
	selected := self chooseMethodReferenceFrom: references title: 'GemStone Methods'.
	selected ifNil: [ ^ false ].
	^ self openServerMethodReference: selected
]

{ #category : 'private' }
GbsRemoteDebugger >> selectedServerSelector [
	service ifNil: [ ^ nil ].
	^ self safeServiceCall: [ service selectedMethodSelector ] default: nil
]

{ #category : 'private' }
GbsRemoteDebugger >> selectedServerClassName [
	service ifNil: [ ^ nil ].
	^ self safeServiceCall: [ service selectedMethodClassName ] default: nil
]

{ #category : 'private' }
GbsRemoteDebugger >> selectedServerMethodReference [
	| className selector |
	className := self selectedServerClassName.
	selector := self selectedServerSelector.
	(className isNil or: [ selector isNil ]) ifTrue: [ ^ nil ].
	^ className asString , '>>' , selector asString
]

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
GbsRemoteDebugger >> serverMethodReferencesFor: aSelector hierarchyOnly: hierarchyOnly senders: sendersOnly [
	| className escapedSelector escapedClass script raw |
	session ifNil: [ ^ #( ) ].
	className := self selectedServerClassName.
	escapedSelector := aSelector asString copyReplaceAll: '''' with: ''''''.
	escapedClass := (className ifNil: [ '' ]) asString copyReplaceAll: '''' with: ''''''.
	script := '[
		| sel className classes target root stream |
		sel := #''', escapedSelector, '''.
		className := ''', escapedClass, '''.
		stream := WriteStream on: String new.
		classes := IdentitySet new.
		System myUserProfile symbolList do: [ :dict |
			dict keysAndValuesDo: [ :k :v |
				(v isBehavior) ifTrue: [ classes add: v ] ] ].
		root := nil.
		className isEmpty ifFalse: [
			(className endsWith: '' class'')
				ifTrue: [ | baseName |
					baseName := className copyFrom: 1 to: className size - 6.
					root := (System myUserProfile symbolList objectNamed: baseName asSymbol) class ]
				ifFalse: [ root := (System myUserProfile symbolList objectNamed: className asSymbol) ] ].
		', (hierarchyOnly
			ifTrue: [ 'root notNil ifTrue: [
				classes := (root withAllSuperclasses , root withAllSubclasses) asIdentitySet ]' ]
			ifFalse: [ '' ]), '.
		classes asArray do: [ :cls |
			| sels |
			', (sendersOnly
				ifTrue: [ 'sels := [ cls whichSelectorsReferTo: sel ] on: Error do: [ #() ]' ]
				ifFalse: [ 'sels := (cls includesSelector: sel) ifTrue: [ Array with: sel ] ifFalse: [ #() ]' ]), '.
			sels do: [ :s |
				stream nextPutAll: cls name asString; nextPutAll: ''>>''; nextPutAll: s asString; lf ].
			', (sendersOnly
				ifTrue: [ 'sels := [ cls class whichSelectorsReferTo: sel ] on: Error do: [ #() ]' ]
				ifFalse: [ 'sels := (cls class includesSelector: sel) ifTrue: [ Array with: sel ] ifFalse: [ #() ]' ]), '.
			sels do: [ :s |
				stream nextPutAll: cls name asString; nextPutAll: '' class>>''; nextPutAll: s asString; lf ] ].
		stream contents
	] value'.
	raw := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	^ (raw splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty
]

{ #category : 'private' }
GbsRemoteDebugger >> openServerMethodReference: aReferenceString [
	| split classPart selectorPart browser classSide className |
	(aReferenceString isString and: [ aReferenceString includesSubstring: '>>' ]) ifFalse: [ ^ false ].
	split := aReferenceString findString: '>>' startingAt: 1.
	classPart := (aReferenceString copyFrom: 1 to: split - 1) trimBoth.
	selectorPart := (aReferenceString copyFrom: split + 2 to: aReferenceString size) trimBoth.
	classSide := classPart endsWith: ' class'.
	className := classSide
		ifTrue: [ classPart copyFrom: 1 to: classPart size - 6 ]
		ifFalse: [ classPart ].
	browser := GbsBrowser openOn: session.
	(browser respondsTo: #selectClassNamed:classSide:method:)
		ifTrue: [ browser selectClassNamed: className classSide: classSide method: selectorPart ].
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> informUnsupported: aString [
	(UIManager default respondsTo: #inform:)
		ifTrue: [ UIManager default inform: aString ].
	^ false
]

{ #category : 'private' }
GbsRemoteDebugger >> jumpToCaret [
	| stepPoint didJump |
	stepPoint := self selectedStepPointFromCaret.
	stepPoint ifNil: [ ^ false ].
	didJump := self safeServiceCall: [ service jumpToStepPoint: stepPoint ] default: false.
	didJump ifTrue: [ self fetchStackFrames ].
	^ didJump
]

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
GbsRemoteDebugger >> browseLocalImplementors [
	| selector |
	selector := self selectedServerSelector.
	selector ifNil: [ ^ false ].
	(SystemNavigation default respondsTo: #browseAllImplementorsOf:)
		ifTrue: [ SystemNavigation default browseAllImplementorsOf: selector. ^ true ].
	^ false
]

{ #category : 'private' }
GbsRemoteDebugger >> browseLocalSenders [
	| selector |
	selector := self selectedServerSelector.
	selector ifNil: [ ^ false ].
	(SystemNavigation default respondsTo: #browseAllSendersOf:)
		ifTrue: [ SystemNavigation default browseAllSendersOf: selector. ^ true ].
	^ false
]

{ #category : 'private' }
GbsRemoteDebugger >> browseLocalHierarchyImplementors [
	| selector className behavior methods |
	selector := self selectedServerSelector.
	className := self selectedServerClassName.
	(selector isNil or: [ className isNil ]) ifTrue: [ ^ false ].
	behavior := self localBehaviorFromServerClassName: className.
	behavior ifNil: [ ^ false ].
	methods := (behavior withAllSuperclasses , behavior withAllSubclasses)
		collect: [ :cls | cls compiledMethodAt: selector ifAbsent: [ nil ] ]
		thenReject: #isNil.
	methods isEmpty ifTrue: [ ^ false ].
	methods size = 1
		ifTrue: [ methods first browse ]
		ifFalse: [ methods inspect ].
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> browseLocalHierarchySenders [
	| selector className behavior methods |
	selector := self selectedServerSelector.
	className := self selectedServerClassName.
	(selector isNil or: [ className isNil ]) ifTrue: [ ^ false ].
	behavior := self localBehaviorFromServerClassName: className.
	behavior ifNil: [ ^ false ].
	methods := OrderedCollection new.
	(behavior withAllSuperclasses , behavior withAllSubclasses) do: [ :cls |
		methods addAll: (cls whichSelectorsReferTo: selector) collect: [ :sel |
			cls compiledMethodAt: sel ifAbsent: [ nil ] ] ].
	methods := methods thenReject: #isNil.
	methods isEmpty ifTrue: [ ^ false ].
	methods size = 1
		ifTrue: [ methods first browse ]
		ifFalse: [ methods inspect ].
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> showContainingPackage [
	| className behavior package |
	className := self selectedServerClassName.
	className ifNil: [ ^ false ].
	behavior := self localBehaviorFromServerClassName: className.
	behavior ifNil: [ ^ false ].
	package := behavior package ifNil: [ ^ false ].
	(UIManager default respondsTo: #inform:)
		ifTrue: [ UIManager default inform: package name ].
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> localBehaviorFromServerClassName: classNameString [
	| baseName |
	classNameString ifNil: [ ^ nil ].
	baseName := classNameString asString.
	(baseName endsWith: ' class')
		ifTrue: [ baseName := baseName copyFrom: 1 to: baseName size - 6 ].
	^ Smalltalk at: baseName asSymbol ifAbsent: [ nil ]
]

{ #category : 'private' }
GbsRemoteDebugger >> localDoIt [
	| code |
	code := self selectedSourceOrAll.
	code isEmpty ifTrue: [ ^ false ].
	[ Smalltalk compiler evaluate: code ] on: Error do: [ :ex | ^ false ].
	^ true
]

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

{ #category : 'private' }
GbsRemoteDebugger >> pauseProcess [
	| didPause |
	didPause := self safeServiceCall: [ service pause ] default: false.
	didPause ifTrue: [ self fetchStackFrames ].
	^ didPause
]

{ #category : 'private' }
GbsRemoteDebugger >> restart [
	| didRestart serviceRestart |
	serviceRestart := self safeServiceCall: [ service restart ] default: false.
	didRestart := self restartUsingDirectTrimFromExecutedFrame.
	didRestart ifFalse: [ didRestart := serviceRestart ].
	didRestart ifTrue: [
		self fetchStackFrames.
		self normalizeRestartSelectionAndPosition.
		self moveSourceCursorToStart.
	].
	^ didRestart
]

{ #category : 'private' }
GbsRemoteDebugger >> restartUsingDirectTrimFromExecutedFrame [
	| script raw value |
	(session isNil or: [ processOop isNil ]) ifTrue: [ ^ false ].
	(processOop isNumber and: [ processOop > 20 ]) ifFalse: [ ^ false ].

	script := '[
		| obj proc maxDepth level stackReport fullEntry methodOrNil className selectorName restartLevel |
		obj := Object _objectForOop: ', processOop asString, '.
		obj isNil ifTrue: [ ^ ''false'' ].
		proc := obj.
		((proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not) ifTrue: [
			(obj respondsTo: #serverProcess) ifTrue: [ proc := [ obj serverProcess ] on: Error do: [ nil ] ].
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #process ]) ifTrue: [
			proc := [ obj process ] on: Error do: [ nil ]
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #topContext ]) ifTrue: [
			| top |
			top := [ obj topContext ] on: Error do: [ nil ].
			(top notNil and: [ top respondsTo: #process ])
				ifTrue: [ proc := [ top process ] on: Error do: [ nil ] ]
		].
		(proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) ifTrue: [ ^ ''false'' ].

		restartLevel := nil.
		maxDepth := 200.
		level := 1.
		[ level <= maxDepth and: [ restartLevel isNil ] ] whileTrue: [
			fullEntry := nil.
			stackReport := [ proc _gsiStackReportFromLevel: level toLevel: level ] on: Error do: [ nil ].
			(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ])
				ifTrue: [ fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ] ].
			fullEntry isNil
				ifTrue: [ level := maxDepth + 1 ]
				ifFalse: [
					methodOrNil := ((fullEntry respondsTo: #at:) and: [ fullEntry size >= 1 ])
						ifTrue: [ [ fullEntry at: 1 ] on: Error do: [ nil ] ]
						ifFalse: [ nil ].
					className := [ methodOrNil inClass name asString ] on: Error do: [ ''nil'' ].
					selectorName := [ (fullEntry at: 4) ifNil: [ ''nil'' ] ifNotNil: [ :s | s asString ] ]
						on: Error do: [ ''nil'' ].
					((className = ''nil'' or: [ className = ''<unknown>'' ])
						and: [ selectorName = ''nil'' or: [ selectorName = ''unboundMethod'' ] ])
						ifTrue: [ restartLevel := level ].
					level := level + 1
				]
		].
		restartLevel ifNil: [ ^ ''false'' ].
		[ proc _trimStackToLevel: restartLevel ] on: Error do: [ ^ ''false'' ].
		''true''
	] value'.

	raw := [ session executeAndFetch: script context: 20 ] on: Error do: [ nil ].
	raw ifNil: [ ^ false ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	value := (raw respondsTo: #asString)
		ifTrue: [ raw asString asLowercase ]
		ifFalse: [ '' ].
	^ value = 'true' or: [ value = '1' or: [ value = 'ok' ] ]
]

{ #category : 'private' }
GbsRemoteDebugger >> returnFromFrame [
	^ self stepReturn
]

{ #category : 'private' }
GbsRemoteDebugger >> runToCaret [
	| stepPoint didRun |
	stepPoint := self selectedStepPointFromCaret.
	stepPoint ifNil: [ ^ false ].
	didRun := self safeServiceCall: [ service runToStepPoint: stepPoint ] default: false.
	didRun ifTrue: [ self fetchStackFrames ].
	^ didRun
]

{ #category : 'private' }
GbsRemoteDebugger >> processOopFromGbsError: anError [
	| candidate |
	candidate := (anError respondsTo: #serverProcessOop)
		ifTrue: [ anError serverProcessOop ]
		ifFalse: [ nil ].
	((candidate isNumber and: [ candidate > 20 ]) not) ifTrue: [
		candidate := (anError respondsTo: #exceptionOop)
			ifTrue: [ anError exceptionOop ]
			ifFalse: [ nil ]
	].
	((candidate isNumber and: [ candidate > 20 ]) not) ifTrue: [
		candidate := (anError respondsTo: #tag)
			ifTrue: [ anError tag ]
			ifFalse: [ nil ]
	].
	^ candidate
]

{ #category : 'private' }
GbsRemoteDebugger >> selectedStepPointFromCaret [
	| caret map entries sorted match context |
	sourceText ifNil: [ ^ nil ].
	(sourceText respondsTo: #selectionInterval) ifFalse: [ ^ nil ].
	caret := sourceText selectionInterval first.
	context := (service notNil and: [ service respondsTo: #currentContext ])
		ifTrue: [ service currentContext ]
		ifFalse: [ nil ].
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

{ #category : 'private' }
GbsRemoteDebugger >> selectHomeContext [
	| index |
	(contextList isNil or: [ contextList isEmpty ]) ifTrue: [ ^ false ].
	index := self firstUserContextIndex.
	(index isNil or: [ index <= 0 or: [ index > contextList size ] ])
		ifTrue: [ index := 1 ].
	stackList selectIndex: index.
	self contextSelected: (contextList at: index).
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> showMoreContexts [
	self fetchStackFrames.
	^ true
]

{ #category : 'private' }
GbsRemoteDebugger >> moveSourceCursorToStart [
	| text |
	sourceText ifNil: [ ^ self ].
	text := [ (sourceText respondsTo: #text)
		ifTrue: [ sourceText text asString ]
		ifFalse: [ '' ] ] on: Error do: [ '' ].
	text isEmpty ifTrue: [ ^ self ].
	self selectAndRevealFrom: 1 to: 1 inTextPresenter: sourceText.
]

{ #category : 'private' }
GbsRemoteDebugger >> normalizeRestartSelectionAndPosition [
	| index context offsets copy reordered |
	(contextList isNil or: [ contextList isEmpty ]) ifTrue: [ ^ self ].

	"Find server-reported executed-code frame"
	index := contextList
		findFirst: [ :ctx |
			| className selectorName |
			className := [ ctx methodClassOrUnknown asString ] on: Error do: [ '' ].
			selectorName := [ ctx selectorOrUnknown asString ] on: Error do: [ '' ].
			(className = 'nil' or: [ className = '<unknown>' ])
				and: [ selectorName = 'nil' or: [ selectorName = 'unboundMethod' ] ] ].
	
	index = 0 ifTrue: [ index := 1 ].
	(index <= 0 or: [ index > contextList size ]) ifTrue: [ ^ self ].
	context := contextList at: index.

	(context respondsTo: #quickStepPoint:)
		ifTrue: [ context quickStepPoint: 1 ].
	(context respondsTo: #ipOffset:)
		ifTrue: [ context ipOffset: 1 ].
	(context respondsTo: #sourceOffsets) ifTrue: [
		offsets := [ context sourceOffsets ] on: Error do: [ #() ].
		(offsets isCollection and: [ offsets isEmpty not ]) ifTrue: [
			copy := offsets asArray copy.
			copy at: 1 put: 1.
			(context respondsTo: #sourceOffsets:)
				ifTrue: [ context sourceOffsets: copy ]
		]
	].

	index ~= 1 ifTrue: [
		reordered := OrderedCollection new: contextList size.
		reordered add: context.
		1 to: contextList size do: [ :i |
			i = index ifFalse: [ reordered add: (contextList at: i) ] ].
		contextList := reordered asArray.
		index := 1
	].

	service ifNotNil: [
		(service respondsTo: #currentContext:)
			ifTrue: [ service currentContext: context ].
		(service respondsTo: #updateSourceMapFromCurrentContext)
			ifTrue: [ service updateSourceMapFromCurrentContext ]
	].

	stackList ifNotNil: [
		(stackList respondsTo: #items:)
			ifTrue: [ stackList items: (contextList collect: [ :ctx | ctx printString ]) ]
	].

	(stackList respondsTo: #selectIndex:)
		ifTrue: [ stackList selectIndex: index ].
	
	self contextSelected: context.
	self moveSourceCursorToStart.
]

{ #category : 'private' }
GbsRemoteDebugger >> stackReportString [
	| rows |
	contextList ifNil: [ ^ '' ].
	rows := contextList collect: [ :ctx | ctx printString ].
	^ String crlf join: rows
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
