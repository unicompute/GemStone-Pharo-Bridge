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
		'contextList',
		'selectedContextIndex',
		'stackList',
		'sourceText',
		'variablesTable',
		'stepOverButton',
		'stepIntoButton',
		'stepReturnButton',
		'resumeButton',
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

{ #category : 'accessing' }
GbsRemoteDebugger >> service: aService [
	service := aService
]

{ #category : 'accessing' }
GbsRemoteDebugger >> service [
	^ service
]

{ #category : 'initialization' }
GbsRemoteDebugger >> initializePresenters [
	errorMessageLabel := self newLabel.
	errorMessageLabel addStyle: 'danger'.

	stepOverButton := self newButton 
		label: 'Step Over'; 
		action: [ self stepOver ].
	stepIntoButton := self newButton 
		label: 'Step Into'; 
		action: [ self stepInto ].
	stepReturnButton := self newButton 
		label: 'Step Return'; 
		action: [ self stepReturn ].
	resumeButton := self newButton 
		label: 'Resume'; 
		action: [ self resume ].
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

	glueIsHidden := true.
	self refreshUiState.
]

{ #category : 'layout' }
GbsRemoteDebugger >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: errorMessageLabel expand: false;
		add: (SpBoxLayout newHorizontal
			spacing: 5;
			add: stepIntoButton; 
			add: stepOverButton; 
			add: stepReturnButton;
			add: resumeButton; 
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
			add: (SpPanedLayout newHorizontal
				add: sourceText;
				add: variablesTable;
				yourself);
			yourself);
		yourself
]

{ #category : 'accessing' }
GbsRemoteDebugger >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbsRemoteDebugger >> session [
	^ session
]

{ #category : 'accessing' }
GbsRemoteDebugger >> processOop: anOop [
	processOop := anOop.
	stackList ifNotNil: [ self fetchStackFrames ].
]

{ #category : 'accessing' }
GbsRemoteDebugger >> processOop [
	^ processOop
]

{ #category : 'accessing' }
GbsRemoteDebugger >> label: aString [
	errorMessageLabel ifNotNil: [ errorMessageLabel label: aString ]
]

{ #category : 'accessing' }
GbsRemoteDebugger >> stackData: anArray [
	stackData := anArray.
	stackList ifNotNil: [ self fetchStackFrames ].
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
			service recomputeContextList.
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
		self refreshUiState.
		^ self
	].
	stackList items: (contextList collect: [ :ctx | ctx printString ]).

	contextList ifNotEmpty: [
		| preferredIndex |
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
		| preferredIndex |
		preferredIndex := self preferredInitialContextIndex.
		stackList selectIndex: preferredIndex.
		self contextSelected: (contexts at: preferredIndex)
	].
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
		| obj ctx proc stream depth level stackReport fullEntry selectorName methodName className sourceText |
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
						sourceText := [ (fullEntry at: 9) asString ] on: Error do: [ '''' ].
						sourceText ifNil: [ sourceText := '''' ].
						sourceText := sourceText
							copyReplaceAll: (String with: Character cr) with: ''<CR>'';
							copyReplaceAll: (String with: Character lf) with: ''<LF>'';
							copyReplaceAll: String cr with: ''<CR>'';
							copyReplaceAll: String lf with: ''<LF>'';
							copyReplaceAll: Character tab asString with: ''<TAB>''.
						stream
							nextPutAll: level asString; tab;
							nextPutAll: className; tab;
							nextPutAll: selectorName; tab;
							nextPutAll: methodName; tab;
							nextPutAll: sourceText;
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
	rawData isEmpty ifTrue: [
		^ #( )
	].

	contexts := (rawData splitOn: Character lf)
		collect: [ :line |
			| parts levelValue classValue selectorValue methodValue sourceValue |
			line isEmpty ifTrue: [ nil ] ifFalse: [
				parts := line splitOn: Character tab.
				parts size >= 3 ifTrue: [
					levelValue := ([ parts first asInteger ] on: Error do: [ 1 ]).
					classValue := (parts size >= 2 ifTrue: [ parts at: 2 ] ifFalse: [ '<unknown>' ]).
					selectorValue := (parts size >= 3 ifTrue: [ parts at: 3 ] ifFalse: [ '<unknown>' ]).
					methodValue := (parts size >= 4 ifTrue: [ parts at: 4 ] ifFalse: [ selectorValue ]).
					sourceValue := (parts size >= 5
						ifTrue: [ parts at: 5 ]
						ifFalse: [ '' ]).
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
						sourceString: ((sourceValue
							copyReplaceAll: '<TAB>' with: Character tab asString)
							copyReplaceAll: '<CR>' with: String cr;
							copyReplaceAll: '<LF>' with: String lf);
						yourself
					] on: Error do: [ nil ]
				]
			]
		] thenSelect: #isNotNil.

	^ contexts
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
		^ self
	].

	"Use the selected context"
	service ifNotNil: [ service selectContext: context ].
	context ifNil: [ ^ self ].

	"Display source code - use cached source if available"
	sourceCode := context sourceCode.
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
	self refreshUiState.
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
GbsRemoteDebugger >> stepInto [
	self safeServiceCall: [ service stepInto ] default: false.
	self fetchStackFrames.
]

{ #category : 'actions' }
GbsRemoteDebugger >> stepOver [
	self safeServiceCall: [ service stepOver ] default: false.
	self fetchStackFrames.
]

{ #category : 'actions' }
GbsRemoteDebugger >> stepReturn [
	self safeServiceCall: [ service stepReturn ] default: false.
	self fetchStackFrames.
]

{ #category : 'actions' }
GbsRemoteDebugger >> resume [
	self safeServiceCall: [ service resume ] default: false.
	self withWindowDo: [ :window | window close ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> terminate [
	self safeServiceCall: [ service terminate ] default: false.
	self withWindowDo: [ :window | window close ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectReceiver [
	^ self safeServiceCall: [ service inspectCurrentReceiver ] default: false
]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectProcess [
	^ self safeServiceCall: [ service inspectCurrentProcess ] default: false
]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectFrame [
	^ self safeServiceCall: [ service inspectCurrentFrame ] default: false
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

{ #category : 'actions' }
GbsRemoteDebugger >> setBreakPoint [
	service ifNil: [ ^ false ].
	^ self withBreakpointRefresh: [ service setBreakPointIn: sourceText ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> toggleBreakPoint [
	service ifNil: [ ^ false ].
	^ self withBreakpointRefresh: [ service toggleBreakPointIn: sourceText ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> gsDoIt [
	| code |
	service ifNil: [ ^ false ].
	code := self selectedSourceOrAll.
	^ [ service gsDoIt: code ] on: Error do: [ false ]
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

{ #category : 'actions' }
GbsRemoteDebugger >> gsInspectIt [
	| code |
	service ifNil: [ ^ false ].
	code := self selectedSourceOrAll.
	^ [ service gsInspectIt: code ] on: Error do: [ false ]
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

{ #category : 'actions' }
GbsRemoteDebugger >> removeBreakPoint [
	service ifNil: [ ^ false ].
	^ self withBreakpointRefresh: [ service removeBreakIn: sourceText ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> removeAllBreakPoints [
	service ifNil: [ ^ 0 ].
	^ self withBreakpointRefresh: [ service removeAllBreakPoints ]
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

{ #category : 'private' }
GbsRemoteDebugger >> configureMenuItem: aMenuGroup named: labelText action: actionBlock enabled: enabledBoolean [
	aMenuGroup addItem: [ :item |
		item
			name: labelText;
			action: [ enabledBoolean ifTrue: [ actionBlock value ] ].
		(item respondsTo: #enabled:)
			ifTrue: [ item enabled: enabledBoolean ] ].
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
GbsRemoteDebugger >> safeServiceCall: aBlock default: defaultValue [
	service ifNil: [ ^ defaultValue ].
	^ [ aBlock value ] on: Error do: [ defaultValue ]
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
GbsRemoteDebugger >> withBreakpointRefresh: aBlock [
	| result |
	result := [ aBlock value ] on: Error do: [ false ].
	self syncBreakpointMarker.
	self refreshUiState.
	^ result
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

{ #category : 'private' }
GbsRemoteDebugger >> refreshUiState [
	self updateButton: inspectReceiverButton enabled: self canInspectReceiver.
	self updateButton: inspectProcessButton enabled: self canInspectProcess.
	self updateButton: inspectFrameButton enabled: self canInspectFrame.
	self updateButton: inspectVariableButton enabled: self canInspectVariable.
]

{ #category : 'private' }
GbsRemoteDebugger >> updateButton: aButton enabled: enabledBoolean [
	aButton ifNil: [ ^ self ].
	(aButton respondsTo: #enabled:)
		ifTrue: [ [ aButton enabled: enabledBoolean ] on: Error do: [ ] ].
]

{ #category : 'private' }
GbsRemoteDebugger >> canSetBreakpoint [
	^ self safeServiceCall: [ service canSetBreakPoint ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canRemoveBreakpoint [
	^ self safeServiceCall: [ service canRemoveBreakPoint ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canRemoveAllBreakpoints [
	^ self safeServiceCall: [ service canRemoveAllBreakPoints ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canToggleBreakpoint [
	^ self safeServiceCall: [ service canToggleBreakPoint ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canAcceptRecompile [
	^ self safeServiceCall: [ service currentContext notNil ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectReceiver [
	^ self safeServiceCall: [ (service respondsTo: #canInspectCurrentReceiver)
		ifTrue: [ service canInspectCurrentReceiver ]
		ifFalse: [ true ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectProcess [
	^ self safeServiceCall: [ (service respondsTo: #canInspectCurrentProcess)
		ifTrue: [ service canInspectCurrentProcess ]
		ifFalse: [ true ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectFrame [
	^ self safeServiceCall: [ (service respondsTo: #canInspectCurrentFrame)
		ifTrue: [ service canInspectCurrentFrame ]
		ifFalse: [ true ] ] default: false
]

{ #category : 'private' }
GbsRemoteDebugger >> canInspectVariable [
	^ self selectedVariableName notNil
]

{ #category : 'private' }
GbsRemoteDebugger >> clearServiceCompileError [
	service ifNil: [ ^ self ].
	(service respondsTo: #clearCompileError)
		ifTrue: [ [ service clearCompileError ] on: Error do: [ ] ].
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
	[
		(aTextPresenter respondsTo: #selectionInterval:)
			ifTrue: [ aTextPresenter selectionInterval: (lineStart to: lineEnd) ]
			ifFalse: [
				(aTextPresenter respondsTo: #selectFrom:to:)
					ifTrue: [ aTextPresenter selectFrom: lineStart to: lineEnd ]
			]
	] on: Error do: [ ].
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

{ #category : 'private' }
GbsRemoteDebugger >> applySourceMapHighlightFor: aContext [
	| map interval |
	sourceText ifNil: [ ^ self ].
	map := self sourceMapFor: aContext.
	(map isCollection and: [ map isEmpty not ]) ifFalse: [ ^ self clearSourceHighlight ].
	interval := (service notNil and: [ service respondsTo: #currentSourceSelectionInterval ])
		ifTrue: [ [ service currentSourceSelectionInterval ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	interval ifNil: [ interval := map first value ].
	(interval isNil or: [ (interval respondsTo: #first) not or: [ (interval respondsTo: #last) not ] ]) ifTrue: [
		^ self clearSourceHighlight
	].
	[
		(sourceText respondsTo: #selectionInterval:)
			ifTrue: [ sourceText selectionInterval: (interval first to: interval last) ]
			ifFalse: [
				(sourceText respondsTo: #selectFrom:to:)
					ifTrue: [ sourceText selectFrom: interval first to: interval last ]
			]
	] on: Error do: [ ].
]

{ #category : 'private' }
GbsRemoteDebugger >> clearSourceHighlight [
	| textSize |
	sourceText ifNil: [ ^ self ].
	[
		(sourceText respondsTo: #text)
			ifTrue: [ textSize := sourceText text asString size ]
			ifFalse: [ textSize := 0 ].
		(sourceText respondsTo: #selectionInterval:)
			ifTrue: [ sourceText selectionInterval: (textSize + 1 to: textSize) ]
	] on: Error do: [ ].
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
GbsRemoteDebugger >> preferredInitialContextIndex [
	| index |
	contextList ifNil: [ ^ 1 ].
	contextList isEmpty ifTrue: [ ^ 1 ].

	index := contextList
		findFirst: [ :ctx | self isLikelyUserFrame: ctx ].
	index = 0 ifTrue: [ ^ 1 ].
	^ index
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
