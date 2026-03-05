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
		self contextSelected: selection selectedItem
	].

	sourceText := self newText.
	sourceText beNotEditable.

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
		| parts |
		parts := frameStr splitOn: $|.
		parts size >= 3 ifTrue: [
			index := index + 1.
			GbxActivation new
				session: session;
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
		Transcript show: 'fetchContextsDirectly: processOop is nil'; cr.
		^ #( )
	].
	processOop = 0 ifTrue: [
		Transcript show: 'fetchContextsDirectly: processOop is 0'; cr.
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
		Transcript show: 'fetchContextsDirectly rawData: ', rawData; cr.
	] on: Error do: [ :ex |
		Transcript show: 'fetchContextsDirectly error: ', ex messageText; cr.
		^ #( )
	].

	rawData ifNil: [
		Transcript show: 'fetchContextsDirectly: rawData is nil'; cr.
		^ #( )
	].
	rawData isEmpty ifTrue: [
		Transcript show: 'fetchContextsDirectly: rawData is empty'; cr.
		^ #( )
	].

	contexts := (rawData splitOn: Character lf)
		collect: [ :line |
			| parts |
			line isEmpty ifTrue: [ nil ] ifFalse: [
				parts := line splitOn: Character tab.
				parts size >= 5 ifTrue: [
					[ GbxActivation new
						processOop: processOop;
						level: parts first asInteger;
						session: session;
						methodClass: (parts at: 2);
						selector: (parts at: 3) asSymbol;
						gsMethodId: (parts at: 4);
						sourceString: (((parts at: 5)
							copyReplaceAll: '<TAB>' with: Character tab asString)
							copyReplaceAll: '<CR>' with: String cr;
							copyReplaceAll: '<LF>' with: String lf);
						yourself
					] on: Error do: [ :ex |
						Transcript show: 'Error creating activation: ', ex messageText; cr.
						nil
					]
				]
			]
		] thenSelect: #isNotNil.

	^ contexts
]

{ #category : 'actions' }
GbsRemoteDebugger >> contextSelected: selectedItem [
	| context sourceCode variables associations |

	selectedItem ifNil: [ ^ self ].
	(selectedItem respondsTo: #sourceCode) ifFalse: [
		sourceText text: ''.
		variablesTable items: #().
		^ self
	].

	"Use the selected context"
	context := selectedItem.
	service ifNotNil: [ service selectContext: context ].
	context ifNil: [ ^ self ].

	"Display source code - use cached source if available"
	sourceCode := context sourceCode.
	sourceText text: (sourceCode ifNil: [ 
		"Try to get from cached sourceString"
		context sourceString ifNil: [ '' ]
	]).

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
