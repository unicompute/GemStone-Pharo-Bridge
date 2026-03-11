Class {
	#name : 'GbsSymbolListBrowserPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'targetUserName',
		'mainMenu',
		'userDropList',
		'dictionariesList',
		'entriesList',
		'selectionField',
		'valueText',
		'entryValuesByKey'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsSymbolListBrowserPresenter class >> openOn: aSession userName: aUserName [
	| presenter |
	presenter := self new.
	presenter
		session: aSession;
		targetUserName: aUserName;
		open.
	^ presenter
]

{ #category : 'accessing' }
GbsSymbolListBrowserPresenter >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbsSymbolListBrowserPresenter >> targetUserName: aString [
	targetUserName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'initialization' }
GbsSymbolListBrowserPresenter >> initializePresenters [
	mainMenu := self buildMenuBar.
	userDropList := self newDropList.
	dictionariesList := self newList.
	dictionariesList display: [ :each | each asString ].
	entriesList := self newList.
	entriesList display: [ :each | each asString ].
	selectionField := self newTextInput.
	selectionField beNotEditable.
	valueText := self newText.
	(valueText respondsTo: #beNotEditable) ifTrue: [ valueText beNotEditable ].
	entryValuesByKey := Dictionary new
]

{ #category : 'initialization' }
GbsSymbolListBrowserPresenter >> connectPresenters [
	userDropList whenSelectedItemChangedDo: [ :userName |
		self refreshDictionariesFor: userName ].
	dictionariesList whenSelectionChangedDo: [ :selection |
		selection selectedItem ifNotNil: [ :dictName | self refreshEntriesForDictionary: dictName ] ].
	entriesList whenSelectionChangedDo: [ :selection |
		| key |
		key := selection selectedItem.
		key ifNotNil: [ self showEntryForKey: key ] ].
	self refreshUsers
]

{ #category : 'layout' }
GbsSymbolListBrowserPresenter >> defaultLayout [
	| userRow listsRow selectionRow |
	userRow := SpBoxLayout newLeftToRight
		add: (self newLabel label: 'Symbol List for') expand: false;
		add: userDropList;
		spacing: 8;
		yourself.
	listsRow := SpBoxLayout newLeftToRight
		add: dictionariesList;
		add: entriesList;
		spacing: 8;
		yourself.
	selectionRow := SpBoxLayout newLeftToRight
		add: (self newLabel label: 'Selection') expand: false;
		add: selectionField;
		spacing: 8;
		yourself.
	^ SpBoxLayout newTopToBottom
		add: mainMenu expand: false;
		add: userRow expand: false;
		add: (self newLabel label: 'Dictionaries') expand: false;
		add: listsRow;
		add: selectionRow expand: false;
		add: valueText;
		spacing: 8;
		yourself
]

{ #category : 'initialization' }
GbsSymbolListBrowserPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'Symbol List Browser';
		initialExtent: 520 @ 620
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> buildMenuBar [
	^ self newMenuBar
		addGroup: [ :group |
			group
				addItem: [ :item | item name: 'File'; subMenu: self menuFile ];
				addItem: [ :item | item name: 'Dictionary'; subMenu: self menuDictionary ];
				addItem: [ :item | item name: 'Entry'; subMenu: self menuEntry ];
				addItem: [ :item | item name: 'Help'; subMenu: self menuHelp ] ];
		yourself
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuFile [
	^ self newMenu
		addItem: [ :item | item name: 'Update'; action: [ self refreshUsers ] ];
		addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ];
		yourself
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuDictionary [
	^ self newMenu
		addItem: [ :item | item name: 'Refresh Dictionaries'; action: [ self refreshDictionariesFor: userDropList selectedItem ] ];
		yourself
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuEntry [
	^ self newMenu
		addItem: [ :item | item name: 'Inspect Entry'; action: [ self inspectSelectedEntry ] ];
		yourself
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuHelp [
	^ self newMenu
		addItem: [ :item | item name: 'About Symbol List Browser'; action: [ UIManager default inform: 'GemStone Symbol List Browser' ] ];
		yourself
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> inspectSelectedEntry [
	| key value |
	key := entriesList selection selectedItem.
	key ifNil: [ ^ self ].
	value := entryValuesByKey at: key ifAbsent: [ '' ].
	UIManager default inform: key asString, ' => ', value asString
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> refreshUsers [
	| raw users defaultUser |
	raw := [ session evaluate: self usersScript ] on: Error do: [ '' ].
	users := (raw isString and: [ raw isNotEmpty ])
		ifTrue: [ (raw splitOn: Character tab) reject: [ :each | each isEmpty ] ]
		ifFalse: [ #() ].
	userDropList items: users asArray.
	defaultUser := ((targetUserName isString and: [ targetUserName isEmpty not ]) and: [ users includes: targetUserName ])
		ifTrue: [ targetUserName ]
		ifFalse: [ users ifEmpty: [ nil ] ifNotEmpty: [ users first ] ].
	defaultUser ifNotNil: [
		(userDropList respondsTo: #selectItem:)
			ifTrue: [ userDropList selectItem: defaultUser ]
			ifFalse: [ (userDropList respondsTo: #selectedItem:) ifTrue: [ userDropList selectedItem: defaultUser ] ].
		self refreshDictionariesFor: defaultUser ]
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> refreshDictionariesFor: userName [
	| raw dicts |
	userName ifNil: [ dictionariesList items: #(). ^ self ].
	raw := [ session evaluate: (self dictionariesScriptForUser: userName asString) ] on: Error do: [ '' ].
	dicts := (raw isString and: [ raw isNotEmpty ])
		ifTrue: [ (raw splitOn: Character tab) reject: [ :each | each isEmpty ] ]
		ifFalse: [ #() ].
	dictionariesList items: dicts asArray.
	entriesList items: #().
	entryValuesByKey := Dictionary new.
	selectionField text: ''.
	(valueText respondsTo: #text:) ifTrue: [ valueText text: '' ]
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> refreshEntriesForDictionary: dictName [
	| raw lines keys |
	dictName ifNil: [ ^ self ].
	raw := [ session evaluate: (self entriesScriptForUser: (userDropList selectedItem asString) dictionary: dictName asString) ]
		on: Error do: [ '' ].
	lines := (raw isString and: [ raw isNotEmpty ])
		ifTrue: [ raw lines ]
		ifFalse: [ #() ].
	entryValuesByKey := Dictionary new.
	keys := OrderedCollection new.
	lines do: [ :line |
		| parts key value |
		parts := line splitOn: Character tab.
		key := parts at: 1 ifAbsent: [ '' ].
		value := parts at: 2 ifAbsent: [ '' ].
		(key isEmpty not) ifTrue: [
			keys add: key.
			entryValuesByKey at: key put: value ] ].
	entriesList items: keys asArray.
	selectionField text: ''.
	(valueText respondsTo: #text:) ifTrue: [ valueText text: '' ]
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> showEntryForKey: key [
	selectionField text: key asString.
	(valueText respondsTo: #text:)
		ifTrue: [ valueText text: (entryValuesByKey at: key ifAbsent: [ '' ]) asString ]
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> usersScript [
	^ '
	| users strm |
	strm := WriteStream on: String new.
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNotNil: [
		users do: [ :u | strm nextPutAll: u userId asString ] separatedBy: [ strm tab ] ].
	strm contents'
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> dictionariesScriptForUser: userName [
	| u |
	u := self literalString: userName.
	^ '
	| users user sl strm |
	strm := WriteStream on: String new.
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ ^ '''' ].
	user := users detect: [ :x | x userId asString = ', u, ' ] ifNone: [ nil ].
	user ifNil: [ ^ '''' ].
	sl := user symbolList.
	1 to: sl size do: [ :idx |
		| d name |
		d := sl at: idx.
		name := (d respondsTo: #name)
			ifTrue: [ d name asString ]
			ifFalse: [ d printString ].
		strm nextPutAll: name.
		idx < sl size ifTrue: [ strm tab ] ].
	strm contents'
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> entriesScriptForUser: userName dictionary: dictName [
	| u d |
	u := self literalString: userName.
	d := self literalString: dictName.
	^ '
	| users user sl dict strm |
	strm := WriteStream on: String new.
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ ^ '''' ].
	user := users detect: [ :x | x userId asString = ', u, ' ] ifNone: [ nil ].
	user ifNil: [ ^ '''' ].
	sl := user symbolList.
	dict := sl detect: [ :each |
		| name |
		name := (each respondsTo: #name) ifTrue: [ each name asString ] ifFalse: [ each printString ].
		name = ', d, ' ] ifNone: [ nil ].
	dict ifNil: [ ^ '''' ].
	dict keys asSortedCollection do: [ :k |
		| v |
		v := dict at: k.
		strm
			nextPutAll: k asString;
			tab;
			nextPutAll: v printString;
			cr ].
	strm contents'
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> literalString: aString [
	^ '''', (aString copyReplaceAll: '''' with: ''''''), ''''
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]
