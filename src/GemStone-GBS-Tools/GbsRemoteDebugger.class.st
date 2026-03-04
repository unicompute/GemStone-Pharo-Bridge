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
GbsRemoteDebugger >> processOop: anOop [
	processOop := anOop.
	stackList ifNotNil: [ self fetchStackFrames ].
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

	"Always try to fetch contexts - even with processOop 20"
	contexts := self fetchContextsDirectly.

	contextList := contexts ifNil: [ #( ) ].
	contextList ifEmpty: [
		stackList items: #('No stack frames available - error occurred in GemStone').
		sourceText text: ''.
		variablesTable items: #().
		^ self
	].
	stackList items: (contextList collect: [ :ctx | ctx printString ]).

	contextList ifNotEmpty: [
		stackList selectIndex: 1.
		self contextSelected: (contextList at: 1)
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
		stackList selectIndex: 1.
		self contextSelected: (contexts at: 1)
	].
]

{ #category : 'actions' }
GbsRemoteDebugger >> fetchContextsDirectly [
	"Direct context fetching fallback.
	Supports either an error context oop or a process oop."
	| script rawData contexts |

	script := '[
		| obj ctx stream depth className selectorName source oopText |
		obj := Object _objectForOop: ', processOop asString, '.
		ctx := nil.
		(obj notNil and: [obj respondsTo: #sender]) ifTrue: [ ctx := obj ].
		(ctx isNil and: [obj notNil and: [obj respondsTo: #topContext]])
			ifTrue: [ ctx := obj topContext ].
		(ctx isNil and: [obj notNil and: [obj respondsTo: #process]])
			ifTrue: [ ctx := obj process ].
		(ctx notNil and: [ctx respondsTo: #topContext]) ifTrue: [ ctx := ctx topContext ].
		ctx ifNil: [ ^ ''<ctx is nil>'' ].
		stream := WriteStream on: String new.
		depth := 0.
		[ ctx notNil and: [ depth < 30 ] ] whileTrue: [
			depth := depth + 1.
			className := [ ctx method inClass name ] on: Error do: [ ''<unknown>'' ].
			selectorName := [ ctx selector asString ] on: Error do: [ ''<unknown>'' ].
			source := [ ctx sourceCode ] on: Error do: [ '''' ].
			source := source ifNil: [ '''' ].
			source := source
				copyReplaceAll: String cr with: '' '';
				copyReplaceAll: String lf with: '' '';
				copyReplaceAll: Character tab asString with: '' ''.
			oopText := [ ctx asOop printString ] on: Error do: [ ''0'' ].
			stream
				nextPutAll: depth asString; tab;
				nextPutAll: className; tab;
				nextPutAll: selectorName; tab;
				nextPutAll: source; tab;
				nextPutAll: oopText;
				lf.
			ctx := ctx sender.
		].
		stream contents
	] value'.

	rawData := [ session evaluate: script ] on: Error do: [ nil ].
	(rawData respondsTo: #asLocalString) ifTrue: [ rawData := rawData asLocalString ].
	rawData ifNil: [ rawData := '' ].
	rawData = 'nil' ifTrue: [ rawData := '' ].
	Transcript show: 'rawData: ', rawData; cr.
	
	contexts := (rawData splitOn: Character lf)
		collect: [ :line |
			| parts |
			parts := line splitOn: Character tab.
			parts size >= 5 ifTrue: [
				[ | activation selectorSymbol ctxOop |
				selectorSymbol := [ (parts at: 3) asSymbol ] on: Error do: [ #unboundMethod ].
				ctxOop := [ (parts at: 5) asInteger ] on: Error do: [ processOop ].
				activation := GbxActivation new.
				activation
					session: session;
					level: (parts first asInteger);
					initializeFromClass: (parts at: 2)
						selector: selectorSymbol
						source: (parts at: 4)
						contextOop: ctxOop;
					yourself.
				activation ] on: Error do: [ :ex | 
					Transcript show: 'Error creating activation: ', ex messageText; cr.
					nil 
				]
			]
		] thenSelect: #isNotNil.

	^ contexts
]

{ #category : 'actions' }
GbsRemoteDebugger >> contextSelected: selectedItem [
	| context sourceCode variables |

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
		variablesTable items: (variables associations collect: [ :assoc |
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
