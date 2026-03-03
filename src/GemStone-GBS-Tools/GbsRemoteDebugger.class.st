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

	"SAFETY CHECK: Prevent infinite loop if context is nil"
	(processOop isNil or: [ processOop = 20 ]) ifTrue: [
		stackList items: #('No stack frames available (Context is nil)').
		^ self
	].

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

	"CRITICAL: Must execute in the context of the session, not nil (20)"
	rawData := session executeAndFetch: script context: session sessionOop.
	frames := (rawData splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty.
	stackList items: frames.
]

{ #category : 'initialization' }
GbsRemoteDebugger >> initializePresenters [
	errorMessageLabel := self newLabel.
	errorMessageLabel addStyle: 'danger'. "Makes the error text red in Pharo 13"

	stepOverButton := self newButton 
		label: 'Step Over'; 
		iconName: #glamorousStepOver;
		action: [ self stepOver ].
	stepIntoButton := self newButton 
		label: 'Step Into'; 
		iconName: #glamorousStepInto;
		action: [ self stepInto ].
	resumeButton := self newButton 
		label: 'Resume'; 
		iconName: #glamorousGo;
		action: [ self resume ].
	terminateButton := self newButton 
		label: 'Terminate'; 
		iconName: #glamorousTrash;
		action: [ self terminate ].

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

{ #category : 'actions' }
GbsRemoteDebugger >> stackFrameSelected: selectedItem [
	| level script sourceCode varsScript variables |
	
	selectedItem ifNil: [ ^ self ].
	
	"Extract level number from frame description (e.g., 'level 1: Method >> selector')"
	level := (selectedItem findTokens: ' ') detect: [ :token | token isAllDigits ] ifNone: [ 1 ].
	
	"Fetch source code for this frame"
	script := '[
		| proc frame |
		proc := Object _objectForOop: ', processOop asString, '.
		frame := proc _frameAt: ', level asString, '.
		frame ifNotNil: [ frame sourceCode ] ifnil: [ ''<no source available>'' ]
	] value'.
	
	sourceCode := session executeAndFetch: script context: session sessionOop.
	sourceText text: sourceCode.
	
	"Fetch variables for this frame"
	varsScript := '[
		| proc frame stream |
		proc := Object _objectForOop: ', processOop asString, '.
		frame := proc _frameAt: ', level asString, '.
		stream := WriteStream on: String new.
		frame ifNotNil: [
			frame tempNames do: [ :name |
				| val |
				val := frame tempNamed: name.
				stream nextPutAll: name; tab; print: val; lf.
			].
			frame instVarNames do: [ :name |
				| val |
				val := frame receiver instVarNamed: name.
				stream nextPutAll: name; tab; print: val; lf.
			].
		].
		stream contents
	] value'.
	
	variables := session executeAndFetch: varsScript context: session sessionOop.
	variablesTable items: (variables lines select: #isNotEmpty thenCollect: [ :line | line splitOn: Character tab ]).
]

{ #category : 'actions' }
GbsRemoteDebugger >> stepInto [
	| script |
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc step.
		''stepped''
	] value'.
	
	session executeAndFetch: script context: session sessionOop.
	self fetchStackFrames.
]

{ #category : 'actions' }
GbsRemoteDebugger >> stepOver [
	| script |
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc stepOver.
		''stepped''
	] value'.
	
	session executeAndFetch: script context: session sessionOop.
	self fetchStackFrames.
]

{ #category : 'actions' }
GbsRemoteDebugger >> resume [
	| script |
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc resume.
		''resumed''
	] value'.
	
	session executeAndFetch: script context: session sessionOop.
	self parent ifNotNil: [ self parent delete ].
]

{ #category : 'actions' }
GbsRemoteDebugger >> terminate [
	| script |
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc terminate.
		''terminated''
	] value'.
	
	session executeAndFetch: script context: session sessionOop.
	self parent ifNotNil: [ self parent delete ].
]
