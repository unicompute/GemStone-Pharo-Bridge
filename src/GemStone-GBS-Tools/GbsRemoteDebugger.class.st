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
		'glueIsHidden'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebugger class >> openOn: anErrorString process: processOop session: aSession [
	| debugger service |
	service := GbxDebuggerService new.
	service session: aSession.
	service processOop: processOop.
	service label: anErrorString.
	service initializeForDebugging.
	
	debugger := self new.
	debugger service: service.
	debugger session: aSession.
	debugger processOop: processOop.
	debugger label: anErrorString.
	debugger open.
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
	sourceText beReadOnly.

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
	self fetchStackFrames.
]

{ #category : 'accessing' }
GbsRemoteDebugger >> label: aString [
	errorMessageLabel label: aString
]

{ #category : 'actions' }
GbsRemoteDebugger >> fetchStackFrames [
	| contexts |

	(processOop isNil or: [ processOop = 20 ]) ifTrue: [
		stackList items: #('No stack frames available (Context is nil)').
		^ self
	].

	"Use the service's context policy to fetch contexts"
	contexts := service ifNotNil: [ 
		service contextStackPolicy computeContextList 
	] ifnil: [ 
		self fetchContextsDirectly 
	].

	contextList := contexts.
	stackList items: (contexts collect: [ :ctx | ctx printString ]).

	contexts ifNotEmpty: [ 
		stackList selectIndex: 1.
		self contextSelected: (contexts at: 1)
	].
]

{ #category : 'actions' }
GbsRemoteDebugger >> fetchContextsDirectly [
	"Direct context fetching fallback"
	| script rawData contexts |
	
	script := '[
		| proc stream |
		proc := Object _objectForOop: ', processOop asString, '.
		stream := WriteStream on: String new.
		proc ifNotNil: [
			1 to: (proc stackDepth min: 30) do: [ :level |
				| frameId fullEntry methodOrNil selector className |
				frameId := proc _gsiStackReportFromLevel: level toLevel: level.
				frameId ifNotNil: [
					fullEntry := frameId first.
					fullEntry ifNotNil: [
						methodOrNil := fullEntry first.
						selector := fullEntry size >= 4 ifTrue: [ fullEntry at: 4 ] ifFalse: [ nil ].
						className := methodOrNil ifNotNil: [ 
							methodOrNil inClass ifNotNil: [ methodOrNil inClass name ] 
						] ifNil: [ nil ].
						stream 
							nextPutAll: level asString; tab;
							nextPutAll: (className ifNil: ['<unknown>'] ifNotNil: [ className ]); tab;
							nextPutAll: (selector ifNil: ['<unknown>'] ifNotNil: [ selector asString ]);
							lf.
					].
				].
			]
		].
		stream contents
	] value'.
	
	rawData := session executeAndFetch: script context: session sessionOop.
	contexts := (rawData splitOn: Character lf) 
		collect: [ :line | 
			| parts |
			parts := line splitOn: Character tab.
			parts size >= 3 ifTrue: [
				GbxActivation new
					level: (parts first asInteger);
					session: session;
					processOop: processOop;
					gsMethodId: (parts at: 2);
					selector: (parts at: 3) asSymbol;
					yourself
			]
		] thenSelect: #isNotNil.
	
	^ contexts
]

{ #category : 'actions' }
GbsRemoteDebugger >> contextSelected: selectedItem [
	| level context sourceCode variables |
	
	selectedItem ifNil: [ ^ self ].
	
	"Get the context from the service"
	context := service ifNotNil: [ service currentContext ] ifnil: [ nil ].
	context ifNil: [ ^ self ].
	
	"Display source code"
	sourceCode := context sourceCode.
	sourceText text: (sourceCode ifNil: [ '' ]).
	
	"Fetch and display variables"
	variables := context tempNamesAndValues.
	variablesTable items: (variables associations collect: [ :assoc | 
		{ assoc key. assoc value asString }
	]).
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
	self parent ifNotNil: [ self parent delete ].
]

{ #category : 'actions' }
GbsRemoteDebugger >> terminate [
	service ifNotNil: [ service terminate ].
	self parent ifNotNil: [ self parent delete ].
]
