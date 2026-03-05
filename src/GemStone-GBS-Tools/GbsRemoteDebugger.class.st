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
	sourceText beNotEditable.
	sourceText contextMenu: [ self sourceMenu ].

	variablesTable := self newTable.
	variablesTable
		addColumn: (SpStringTableColumn title: 'Name' evaluated: [ :item | item first ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :item | item second ]).

	glueIsHidden := true.
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
		sourceText text: ''.
		self clearSourceHighlight.
		variablesTable items: #().
		^ self
	].
	stackList items: (contextList collect: [ :ctx | ctx printString ]).

	contextList ifNotEmpty: [
		| preferredIndex |
		preferredIndex := self preferredInitialContextIndex.
		stackList selectIndex: preferredIndex.
		self contextSelected: (contextList at: preferredIndex)
	].
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
		sourceText text: ''.
		variablesTable items: #().
		^ self
	].

	"Use the selected context"
	service ifNotNil: [ service selectContext: context ].
	context ifNil: [ ^ self ].
	(context respondsTo: #reset) ifTrue: [
		[ context reset ] on: Error do: [ ].
	].

	"Display source code - use cached source if available"
	sourceCode := context sourceCode.
	sourceText text: (sourceCode ifNil: [ 
		"Try to get from cached sourceString"
		context sourceString ifNil: [ '' ]
	]).
	self applySourceMapHighlightFor: context.

	"Fetch and display variables"
	[
		variables := context tempNamesAndValues.
		associations := (variables respondsTo: #associations)
			ifTrue: [ variables associations ]
			ifFalse: [ #() ].
		variablesTable items: (associations collect: [ :assoc |
			{ assoc key. assoc value asString }
		]).
	] on: Error do: [ :ex |
		variablesTable items: #().
	].
]

{ #category : 'actions' }
GbsRemoteDebugger >> stepInto [
	service ifNotNil: [ service stepInto ].
	self fetchStackFrames.
]

{ #category : 'actions' }
GbsRemoteDebugger >> stepOver [
	service ifNotNil: [ service stepOver ].
	self fetchStackFrames.
]

{ #category : 'actions' }
GbsRemoteDebugger >> stepReturn [
	service ifNotNil: [ service stepReturn ].
	self fetchStackFrames.
]

{ #category : 'actions' }
GbsRemoteDebugger >> resume [
	service ifNotNil: [ service resume ].
	self withWindowDo: [ :window | window close ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> terminate [
	service ifNotNil: [ service terminate ].
	self withWindowDo: [ :window | window close ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectReceiver [
	service ifNotNil: [ ^ service inspectCurrentReceiver ].
	^ false
]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectProcess [
	service ifNotNil: [ ^ service inspectCurrentProcess ].
	^ false
]

{ #category : 'actions' }
GbsRemoteDebugger >> inspectFrame [
	service ifNotNil: [ ^ service inspectCurrentFrame ].
	^ false
]

{ #category : 'actions' }
GbsRemoteDebugger >> setBreakPoint [
	service ifNil: [ ^ false ].
	^ [ service setBreakPointIn: sourceText ] on: Error do: [ false ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> removeBreakPoint [
	service ifNil: [ ^ false ].
	^ [ service removeBreakIn: sourceText ] on: Error do: [ false ]
]

{ #category : 'actions' }
GbsRemoteDebugger >> removeAllBreakPoints [
	service ifNil: [ ^ 0 ].
	^ [ service removeAllBreakPoints ] on: Error do: [ 0 ]
]

{ #category : 'private' }
GbsRemoteDebugger >> sourceMenu [
	| menu |
	menu := self newMenu.
	menu addGroup: [ :group |
		group addItem: [ :item |
			item
				name: 'Set Breakpoint';
				action: [ self setBreakPoint ] ].
		group addItem: [ :item |
			item
				name: 'Remove Breakpoint';
				action: [ self removeBreakPoint ] ].
		group addItem: [ :item |
			item
				name: 'Remove All Breakpoints';
				action: [ self removeAllBreakPoints ] ] ].
	menu addGroup: [ :group |
		group addItem: [ :item | item name: 'Inspect Receiver'; action: [ self inspectReceiver ] ].
		group addItem: [ :item | item name: 'Inspect Process'; action: [ self inspectProcess ] ].
		group addItem: [ :item | item name: 'Inspect Frame'; action: [ self inspectFrame ] ] ].
	^ menu
]

{ #category : 'private' }
GbsRemoteDebugger >> applySourceMapHighlightFor: aContext [
	| map interval |
	sourceText ifNil: [ ^ self ].
	map := self sourceMapFor: aContext.
	(map isCollection and: [ map isEmpty not ]) ifFalse: [ ^ self clearSourceHighlight ].
	interval := map first value.
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
