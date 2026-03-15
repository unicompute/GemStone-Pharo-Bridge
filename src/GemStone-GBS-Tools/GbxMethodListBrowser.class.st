Class {
	#name : 'GbxMethodListBrowser',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'methods',
		'methodList',
		'sourceText',
		'filterText',
		'doItButton',
		'printItButton',
		'inspectItButton',
		'fileOutButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxMethodListBrowser class >> openListBrowserOn: methodHolderCollection [
	"Open a method list browser on a collection of method holders"
	| browser |
	
	browser := self new.
	browser methods: methodHolderCollection.
	browser open.
	^ browser
]

{ #category : 'instance creation' }
GbxMethodListBrowser class >> openListBrowserOn: methodHolderCollection session: aSession [
	"Open a method list browser on a collection of method holders with session"
	| browser |
	
	browser := self new.
	browser methods: methodHolderCollection.
	browser session: aSession.
	browser open.
	^ browser
]

{ #category : 'layout' }
GbxMethodListBrowser >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: filterText height: 30;
		add: (SpBoxLayout newHorizontal
			add: doItButton width: 80;
			add: printItButton width: 80;
			add: inspectItButton width: 100;
			add: fileOutButton width: 80;
			yourself) height: 35;
		add: methodList;
		add: sourceText;
		yourself
]

{ #category : 'initialization' }
GbxMethodListBrowser >> initializePresenters [
	filterText := self newTextInput.
	filterText
		placeholder: 'Filter methods...';
		whenTextChangedDo: [ :text | self filterMethods ].
	
	doItButton := self newButton
		label: 'Do it';
		action: [ self doIt ].
	
	printItButton := self newButton
		label: 'Print it';
		action: [ self printIt ].
	
	inspectItButton := self newButton
		label: 'Inspect it';
		action: [ self inspectIt ].
	
	fileOutButton := self newButton
		label: 'File out';
		action: [ self fileOut ].
	
	methodList := self newList.
	methodList
		addColumn: (SpStringTableColumn title: 'Method' evaluated: [ :item | item asString ]);
		whenActivatedDo: [ :selection | self showMethod: selection selectedItem ].
	
	sourceText := self newText.
	sourceText beReadOnly.
]

{ #category : 'initialization' }
GbxMethodListBrowser >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'Method List Browser';
		initialExtent: 700 @ 600.
]

{ #category : 'actions' }
GbxMethodListBrowser >> doIt [
	"Execute selected method source"
	| method source |
	
	method := methodList selectedItem.
	method ifNil: [ ^ self ].
	
	source := method sourceCode.
	source ifNotNil: [
		session ifNotNil: [
			session execute: source.
			InformDialog inform: 'Do it completed'.
		].
	].
]

{ #category : 'actions' }
GbxMethodListBrowser >> fileOut [
	"File out selected method"
	| method source fileName |
	
	method := methodList selectedItem.
	method ifNil: [ ^ self ].
	
	source := method sourceCode.
	source ifNil: [ ^ self ].
	
	fileName := (FileDialog saveFileWithFilter: 'st' title: 'File out method') asString.
	fileName ifNotEmpty: [
		| fileStream |
		fileStream := fileName asFileReference writeStream.
		fileStream
			nextPutAll: source;
			close.
		InformDialog inform: 'Filed out to: ', fileName.
	].
]

{ #category : 'filtering' }
GbxMethodListBrowser >> filterMethods [
	"Filter methods based on filter text"
	| filterTextValue filtered |
	
	filterTextValue := filterText text asString.
	filterTextValue isEmpty ifTrue: [
		methodList items: methods.
		^ self
	].
	
	filtered := methods select: [ :m |
		| selector className |
		selector := m selector asString.
		className := m methodClass asString.
		(selector includesSubstring: filterTextValue) or:
		(className includesSubstring: filterTextValue)
	].
	
	methodList items: filtered.
]

{ #category : 'actions' }
GbxMethodListBrowser >> inspectIt [
	"Inspect result of selected method"
	| method source result |
	
	method := methodList selectedItem.
	method ifNil: [ ^ self ].
	
	source := method sourceCode.
	source ifNil: [ ^ self ].
	
	session ifNotNil: [
		result := session executeAndFetch: source.
		result ifNotNil: [
			GbsInspector inspect: result session: session.
		].
	].
]

{ #category : 'accessing' }
GbxMethodListBrowser >> methods [
	^ methods
]

{ #category : 'accessing' }
GbxMethodListBrowser >> methods: aCollection [
	methods := aCollection.
	methodList items: aCollection.
	methodList selectIndex: 1.
	methodList selectedItem ifNotNil: [ :item |
		self showMethod: item.
	].
]

{ #category : 'actions' }
GbxMethodListBrowser >> printIt [
	"Print result of selected method"
	| method source result |
	
	method := methodList selectedItem.
	method ifNil: [ ^ self ].
	
	source := method sourceCode.
	source ifNil: [ ^ self ].
	
	session ifNotNil: [
		result := session executeAndFetch: source.
		result ifNotNil: [
			InformDialog inform: 'Result: ', result asString.
		].
	].
]

{ #category : 'accessing' }
GbxMethodListBrowser >> session [
	^ session
]

{ #category : 'accessing' }
GbxMethodListBrowser >> session: aSession [
	session := aSession
]

{ #category : 'actions' }
GbxMethodListBrowser >> showMethod: methodHolder [
	"Show source code for selected method"
	
	methodHolder ifNil: [
		sourceText text: ''.
		^ self
	].
	
	sourceText text: methodHolder sourceCode.
	self window ifNotNil: [ :win |
		win title: 'Method List Browser - ', methodHolder printString.
	].
]
