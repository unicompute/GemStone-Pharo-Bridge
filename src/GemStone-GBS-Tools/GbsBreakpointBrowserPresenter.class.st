Class {
	#name : 'GbsBreakpointBrowserPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'mainMenu',
		'breakTable',
		'methodText'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsBreakpointBrowserPresenter class >> openOn: aSession [
	| presenter |
	aSession ifNil: [ ^ self inform: 'No connected GemStone session. Please login first.' ].
	presenter := self new.
	presenter
		session: aSession;
		open.
	^ presenter
]

{ #category : 'initialization' }
GbsBreakpointBrowserPresenter >> initializePresenters [
	mainMenu := self buildMenuBar.

	breakTable := self newTable.
	breakTable
		addColumn: (SpStringTableColumn title: 'Class' evaluated: [ :bp | self remoteClassNameFor: bp ]);
		addColumn: (SpStringTableColumn title: 'Selector' evaluated: [ :bp | self selectorNameFor: bp ]);
		addColumn: (SpStringTableColumn title: 'Step' evaluated: [ :bp | self stepPointFor: bp ]);
		yourself.

	methodText := self newCode.
	methodText beNotEditable
]

{ #category : 'initialization' }
GbsBreakpointBrowserPresenter >> connectPresenters [
	breakTable whenSelectionChangedDo: [ :selection |
		self refreshMethodTextFor: selection selectedItem ].
	self refreshAll
]

{ #category : 'layout' }
GbsBreakpointBrowserPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: mainMenu expand: false;
		add: breakTable;
		add: methodText;
		spacing: 8;
		yourself
]

{ #category : 'initialization' }
GbsBreakpointBrowserPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Breakpoint Browser';
		initialExtent: 760 @ 520
]

{ #category : 'menus' }
GbsBreakpointBrowserPresenter >> buildMenuBar [
	^ self newMenuBar
		addGroup: [ :group |
			group
				addItem: [ :item | item name: 'File'; subMenu: self menuFile ];
				addItem: [ :item | item name: 'Edit'; subMenu: self menuEdit ];
				addItem: [ :item | item name: 'Breakpoints'; subMenu: self menuBreakpoints ] ]
]

{ #category : 'menus' }
GbsBreakpointBrowserPresenter >> menuFile [
	^ self newMenu
		addItem: [ :item | item name: 'Refresh'; action: [ self refreshAll ] ];
		addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ];
		yourself
]

{ #category : 'menus' }
GbsBreakpointBrowserPresenter >> menuEdit [
	^ self newMenu
		addItem: [ :item | item name: 'Copy Method Source'; action: [ self copyMethodSource ] ];
		yourself
]

{ #category : 'menus' }
GbsBreakpointBrowserPresenter >> menuBreakpoints [
	^ self newMenu
		addItem: [ :item | item name: 'Remove Selected'; action: [ self removeSelectedBreakpoint ] ];
		addItem: [ :item | item name: 'Remove All'; action: [ self removeAllBreakpoints ] ];
		addItem: [ :item | item name: 'Refresh'; action: [ self refreshAll ] ];
		yourself
]

{ #category : 'actions' }
GbsBreakpointBrowserPresenter >> refreshAll [
	| points |
	points := self breakpoints.
	breakTable items: points.
	points isEmpty
		ifTrue: [ methodText text: '' ]
		ifFalse: [
			(breakTable respondsTo: #selectIndex:)
				ifTrue: [ breakTable selectIndex: 1 ]
				ifFalse: [ (breakTable respondsTo: #selectItem:) ifTrue: [ breakTable selectItem: points first ] ].
			self refreshMethodTextFor: points first ]
]

{ #category : 'private' }
GbsBreakpointBrowserPresenter >> breakpoints [
	| klass |
	klass := Smalltalk at: #GbxBreakPoint ifAbsent: [ nil ].
	klass ifNil: [ ^ #() ].
	^ [ klass breakPointListFor: session ] on: Error do: [ #() ]
]

{ #category : 'actions' }
GbsBreakpointBrowserPresenter >> refreshMethodTextFor: aBreakpoint [
	| source |
	aBreakpoint ifNil: [ methodText text: ''. ^ self ].
	source := self sourceForBreakpoint: aBreakpoint.
	methodText text: source
]

{ #category : 'private' }
GbsBreakpointBrowserPresenter >> sourceForBreakpoint: aBreakpoint [
	| className selectorName script |
	session ifNil: [ ^ '' ].
	className := self remoteClassNameFor: aBreakpoint.
	selectorName := self selectorNameFor: aBreakpoint.
	(className isEmpty or: [ selectorName isEmpty ]) ifTrue: [ ^ '' ].
	script := self sourceScriptForClassName: className selector: selectorName.
	^ [ session evaluate: script ] on: Error do: [ :ex | 'Could not fetch source: ', ex messageText ]
]

{ #category : 'private' }
GbsBreakpointBrowserPresenter >> sourceScriptForClassName: className selector: selectorName [
	| classSymbol selectorSymbol |
	classSymbol := self literalSymbolName: className.
	selectorSymbol := self literalSymbolName: selectorName.
	^ '
	| cls cm |
	cls := System myUserProfile symbolList objectNamed: #', classSymbol, '.
	cls ifNil: [ ^ '''' ].
	cm := cls compiledMethodAt: #', selectorSymbol, ' ifAbsent: [ nil ].
	cm ifNil: [ ^ '''' ].
	(cm respondsTo: #sourceString)
		ifTrue: [ cm sourceString ]
		ifFalse: [
			(cm respondsTo: #sourceCode)
				ifTrue: [ cm sourceCode ]
				ifFalse: [ cm printString ] ]'
]

{ #category : 'private' }
GbsBreakpointBrowserPresenter >> literalSymbolName: aString [
	^ (aString copyReplaceAll: ':' with: ':')
]

{ #category : 'private' }
GbsBreakpointBrowserPresenter >> remoteClassNameFor: aBreakpoint [
	(aBreakpoint respondsTo: #remoteClass) ifFalse: [ ^ '' ].
	^ [ aBreakpoint remoteClass asString ] on: Error do: [ '' ]
]

{ #category : 'private' }
GbsBreakpointBrowserPresenter >> selectorNameFor: aBreakpoint [
	(aBreakpoint respondsTo: #selector) ifFalse: [ ^ '' ].
	^ [ aBreakpoint selector asString ] on: Error do: [ '' ]
]

{ #category : 'private' }
GbsBreakpointBrowserPresenter >> stepPointFor: aBreakpoint [
	(aBreakpoint respondsTo: #stepPoint) ifFalse: [ ^ '' ].
	^ [ aBreakpoint stepPoint asString ] on: Error do: [ '' ]
]

{ #category : 'actions' }
GbsBreakpointBrowserPresenter >> removeSelectedBreakpoint [
	| selected |
	selected := breakTable selection selectedItem.
	selected ifNil: [ ^ self ].
	(selected respondsTo: #clear) ifTrue: [ selected clear ].
	self refreshAll
]

{ #category : 'actions' }
GbsBreakpointBrowserPresenter >> removeAllBreakpoints [
	self breakpoints do: [ :bp | (bp respondsTo: #clear) ifTrue: [ bp clear ] ].
	self refreshAll
]

{ #category : 'actions' }
GbsBreakpointBrowserPresenter >> copyMethodSource [
	| text |
	text := [ methodText text ] on: Error do: [ '' ].
	Clipboard clipboardText: text
]

{ #category : 'accessing' }
GbsBreakpointBrowserPresenter >> session: aSession [
	session := aSession
]

{ #category : 'actions' }
GbsBreakpointBrowserPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]
