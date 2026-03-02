Class {
	#name : 'GbsRemoteDebugger',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'processOop',
		'stackList',
		'sourceText',
		'variablesTable',
		'stepOverButton',
		'stepIntoButton',
		'resumeButton',
		'terminateButton',
		'errorMessageLabel'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebugger class >> openOn: anErrorString process: processOop session: aSession [
	| debugger |
	debugger := self new.
	debugger debugError: anErrorString process: processOop session: aSession.
	debugger open.
	
	"Set the window title"
	debugger withWindowDo: [ :win | win title: 'GemStone Remote Debugger' ].
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebugger >> debugError: anErrorString process: anOop session: aSession [
	session := aSession.
	processOop := anOop.
	errorMessageLabel label: anErrorString.
	
	self fetchStackFrames.
]

{ #category : 'layout' }
GbsRemoteDebugger >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: errorMessageLabel expand: false;
		add: (SpBoxLayout newHorizontal
			spacing: 5;
			add: stepIntoButton; add: stepOverButton; add: resumeButton; add: terminateButton;
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

{ #category : 'actions' }
GbsRemoteDebugger >> fetchStackFrames [
	| script rawData frames |
	
	"Query the suspended GemStone process for its stack depth and frame details"
	script := '[
		| proc stream |
		proc := Object _objectForOop: ', processOop asString, '.
		stream := WriteStream on: String new.
		proc ifNotNil: [
			1 to: (proc stackDepth min: 30) do: [ :level |
				stream nextPutAll: (proc _frameReportAt: level); lf.
			]
		].
		stream contents
	] value'.
	
	rawData := session executeAndFetch: script.
	
	frames := (rawData splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty.
	stackList items: frames.
]

{ #category : 'initialization' }
GbsRemoteDebugger >> initializePresenters [
	errorMessageLabel := self newLabel.
	errorMessageLabel addStyle: 'danger'. "Makes the error text red in Pharo 13"

	stepOverButton := self newButton label: 'Step Over'; iconName: #glamorousStepOver.
	stepIntoButton := self newButton label: 'Step Into'; iconName: #glamorousStepInto.
	resumeButton := self newButton label: 'Resume'; iconName: #glamorousGo.
	terminateButton := self newButton label: 'Terminate'; iconName: #glamorousTrash.

	stackList := self newList.
	sourceText := self newText.
	variablesTable := self newTable.
	
	variablesTable 
		addColumn: (SpStringTableColumn title: 'Variable' evaluated: [ :item | item first ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :item | item second ]).

	"When you click a stack frame, fetch its source code and variables!"
	stackList whenSelectionChangedDo: [ :selection | 
		self stackFrameSelected: selection selectedItem 
	].
]

{ #category : 'layout' }
GbsRemoteDebugger >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Remote Debugger';
		initialExtent: 700@500.
]

{ #category : 'accessing' }
GbsRemoteDebugger >> session: aSession [
	session := aSession
]
