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
		'entryText',
		'entryValuesByKey',
		'currentPreview'
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
	presenter refreshUsers.
	^ presenter
]

{ #category : 'instance creation' }
GbsSymbolListBrowserPresenter class >> openOn: aSession userName: aUserName dictionaryName: aDictionaryName [
	| presenter |
	presenter := self openOn: aSession userName: aUserName.
	(aDictionaryName isString and: [ aDictionaryName isNotEmpty ]) ifTrue: [
		presenter
			refreshDictionariesFor: aUserName preservingSelection: aDictionaryName;
			refreshEntriesForDictionary: aDictionaryName preservingSelection: nil ].
	^ presenter
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> addDictionary [
	| userName dictName script |
	userName := self selectedUserName.
	userName ifNil: [ ^ self ].
	dictName := UIManager default request: 'New Dictionary name:' initialAnswer: 'DictionaryName'.
	(dictName isNil or: [ dictName trimBoth isEmpty ]) ifTrue: [ ^ self ].
	script := self addDictionaryScriptForUser: userName dictionary: dictName trimBoth.
	[
		session execute: script.
		self refreshDictionariesFor: userName preservingSelection: dictName trimBoth.
		self refreshEntriesForDictionary: dictName trimBoth preservingSelection: nil
	] on: Error do: [ :ex | UIManager default inform: 'Add dictionary failed: ', ex messageText ].
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> addDictionaryScriptForUser: userName dictionary: dictName [
	| u d |
	u := self literalString: userName.
	d := self literalString: dictName.
	^ '
	| users user sl exists newDict idx |
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ self error: ''AllUsers not found'' ].
	user := users detect: [ :x | x userId asString = ', u, ' ] ifNone: [ nil ].
	user ifNil: [ self error: ''User not found'' ].
	sl := user symbolList.
	exists := sl detect: [ :each |
		| nm |
		nm := (each respondsTo: #name) ifTrue: [ each name asString ] ifFalse: [ each printString ].
		nm = ', d, ' ] ifNone: [ nil ].
	exists ifNotNil: [ self error: ''Dictionary already exists'' ].
	newDict := SymbolDictionary new.
	newDict name: ', d, '.
	newDict at: ', d, ' asSymbol put: newDict.
	idx := (sl respondsTo: #size) ifTrue: [ sl size + 1 ] ifFalse: [ 1 ].
	(user respondsTo: #insertDictionary:at:)
		ifTrue: [ user insertDictionary: newDict at: idx ]
		ifFalse: [
			(sl respondsTo: #add:)
				ifTrue: [ sl add: newDict ]
				ifFalse: [ self error: ''Cannot add dictionary with available API'' ] ].
	true'
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> addEntry [
	| userName dictName keyName valueExpr script |
	userName := self selectedUserName.
	dictName := self selectedDictionaryName.
	(userName isNil or: [ dictName isNil ]) ifTrue: [ ^ self ].
	keyName := UIManager default request: 'New entry key:' initialAnswer: 'newKey'.
	(keyName isNil or: [ keyName trimBoth isEmpty ]) ifTrue: [ ^ self ].
	valueExpr := UIManager default request: 'Value expression (GemStone Smalltalk):' initialAnswer: 'nil'.
	valueExpr ifNil: [ ^ self ].
	script := self
		addEntryScriptForUser: userName
		dictionary: dictName
		keyName: keyName trimBoth
		valueExpression: valueExpr.
	[
		session execute: script.
		self refreshEntriesForDictionary: dictName preservingSelection: keyName trimBoth
	] on: Error do: [ :ex | UIManager default inform: 'Add entry failed: ', ex messageText ].
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> addEntryScriptForUser: userName dictionary: dictName keyName: keyName valueExpression: valueExpression [
	| u d k |
	u := self literalString: userName.
	d := self literalString: dictName.
	k := self literalString: keyName.
	^ '
	| users user sl dict value |
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ self error: ''AllUsers not found'' ].
	user := users detect: [ :x | x userId asString = ', u, ' ] ifNone: [ nil ].
	user ifNil: [ self error: ''User not found'' ].
	sl := user symbolList.
	dict := sl detect: [ :each |
		| nm |
		nm := (each respondsTo: #name) ifTrue: [ each name asString ] ifFalse: [ each printString ].
		nm = ', d, ' ] ifNone: [ nil ].
	dict ifNil: [ self error: ''Dictionary not found'' ].
	value := [ ', valueExpression, ' ] value.
	dict at: ', k, ' asSymbol put: value.
	true'
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

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> canOperateOnSelectedDictionary [
	| dictName |
	dictName := self selectedDictionaryName.
	^ self canOperateOnSelectedUser and: [ dictName isString and: [ dictName isNotEmpty ] ]
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> canOperateOnSelectedEntry [
	| entryName |
	entryName := self selectedEntryName.
	^ self canOperateOnSelectedDictionary and: [ entryName isString and: [ entryName isNotEmpty ] ]
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> canOperateOnSelectedPreviewRow [
	| row kind |
	row := self selectedPreviewRow.
	kind := currentPreview
		ifNil: [ nil ]
		ifNotNil: [ currentPreview at: #kind ifAbsent: [ nil ] ].
	^ row notNil
		and: [ (#('dictionary' 'collection') includes: kind)
		and: [ (row at: 1 ifAbsent: [ '' ]) asString ~= '__truncated__' ] ]
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> canOperateOnSelectedUser [
	| userName |
	userName := self selectedUserName.
	^ userName isString and: [ userName isNotEmpty ]
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
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
	(dictionariesList respondsTo: #contextMenu:) ifTrue: [
		dictionariesList contextMenu: [ self menuDictionaryPopup ] ].
	(entriesList respondsTo: #contextMenu:) ifTrue: [
		entriesList contextMenu: [ self menuEntryPopup ] ].
	(valueText respondsTo: #contextMenu:) ifTrue: [
		valueText contextMenu: [ self menuPreviewPopup ] ]
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
		add: (self newLabel label: 'Keys / Values') expand: false;
		add: valueText;
		add: (self newLabel label: 'PrintString') expand: false;
		add: entryText;
		spacing: 8;
		yourself
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
	valueText := self newTable.
	valueText
		addColumn: (SpStringTableColumn title: 'Key / Index' evaluated: [ :row | row at: 1 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :row | row at: 2 ifAbsent: [ '' ] ]);
		yourself.
	entryText := self newText.
	entryText beNotEditable.
	entryValuesByKey := Dictionary new
]

{ #category : 'initialization' }
GbsSymbolListBrowserPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'Symbol List Browser';
		initialExtent: 520 @ 620
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> inspectDictionary [
	| userName dictName raw |
	userName := self selectedUserName.
	dictName := self selectedDictionaryName.
	(userName isNil or: [ dictName isNil ]) ifTrue: [ ^ self ].
	raw := self withShallowMaterializationDo: [
		[ session evaluate: (self inspectDictionaryScriptForUser: userName dictionary: dictName) ]
			on: Error
			do: [ :ex | 'Inspect dictionary failed: ', ex messageText ] ].
	UIManager default inform: raw asString
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> inspectDictionaryScriptForUser: userName dictionary: dictName [
	| u d |
	u := self literalString: userName.
	d := self literalString: dictName.
	^ '
	| users user sl dict |
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ ^ ''AllUsers not found'' ].
	user := users detect: [ :x | x userId asString = ', u, ' ] ifNone: [ nil ].
	user ifNil: [ ^ ''User not found'' ].
	sl := user symbolList.
	dict := sl detect: [ :each |
		| name |
		name := (each respondsTo: #name) ifTrue: [ each name asString ] ifFalse: [ each printString ].
		name = ', d, ' ] ifNone: [ nil ].
	dict ifNil: [ ^ ''Dictionary not found'' ].
	dict printString'
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> inspectSelectedEntry [
	| key preview kind |
	key := self selectedEntryName.
	key ifNil: [ ^ self ].
	preview := self structuredPreviewForEntryKey: key.
	preview ifNil: [ ^ self ].
	kind := preview at: #kind ifAbsent: [ 'string' ].
	(#('dictionary' 'collection') includes: kind)
		ifTrue: [
			self
				openStructuredInspectorForPreview: preview
				title: key asString
				entryKey: key
				path: #()
				previewKind: kind.
			^ self ].
	UIManager default inform: (preview at: #value ifAbsent: [ '' ]) asString
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> browseReferencersForSelectedEntry [
	| key |
	key := self selectedEntryName.
	key ifNil: [ ^ false ].
	^ self browseReferencersForEntryKey: key path: #()
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> inspectSelectedPreviewValue [
	| entryKey preview kind row rowLabel path |
	entryKey := self selectedEntryName.
	entryKey ifNil: [ ^ self ].
	row := self selectedPreviewRow.
	row ifNil: [ ^ self ].
	rowLabel := (row at: 1 ifAbsent: [ '' ]) asString.
	rowLabel = '__truncated__' ifTrue: [ ^ self ].
	kind := currentPreview
		ifNil: [ nil ]
		ifNotNil: [ currentPreview at: #kind ifAbsent: [ nil ] ].
	kind ifNil: [ ^ self ].
	path := { { kind asString. rowLabel } }.
	preview := self structuredPreviewForEntryKey: entryKey path: path.
	preview ifNil: [ ^ self ].
	kind := preview at: #kind ifAbsent: [ 'string' ].
	(#('dictionary' 'collection') includes: kind)
		ifTrue: [
			self
				openStructuredInspectorForPreview: preview
				title: rowLabel
				entryKey: entryKey
				path: path
				previewKind: kind.
			^ self ].
	UIManager default inform: (preview at: #value ifAbsent: [ '' ]) asString
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> browseReferencersForSelectedPreviewValue [
	| entryKey row rowLabel kind path |
	entryKey := self selectedEntryName.
	entryKey ifNil: [ ^ false ].
	row := self selectedPreviewRow.
	row ifNil: [ ^ false ].
	rowLabel := (row at: 1 ifAbsent: [ '' ]) asString.
	rowLabel = '__truncated__' ifTrue: [ ^ false ].
	kind := currentPreview
		ifNil: [ nil ]
		ifNotNil: [ currentPreview at: #kind ifAbsent: [ nil ] ].
	kind ifNil: [ ^ false ].
	path := { { kind asString. rowLabel } }.
	^ self browseReferencersForEntryKey: entryKey path: path
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> literalString: aString [
	^ '''', (aString copyReplaceAll: '''' with: ''''''), ''''
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> inspectStructuredPreviewRow: row entryKey: entryKey path: path previewKind: previewKind [
	| rowLabel nextPath preview nextKind |
	rowLabel := (row at: 1 ifAbsent: [ '' ]) asString.
	rowLabel isEmpty ifTrue: [ ^ self ].
	rowLabel = '__truncated__' ifTrue: [ ^ self ].
	nextPath := path asArray copyWith: { previewKind asString. rowLabel }.
	preview := self structuredPreviewForEntryKey: entryKey path: nextPath.
	preview ifNil: [ ^ self ].
	nextKind := preview at: #kind ifAbsent: [ 'string' ].
	(#('dictionary' 'collection') includes: nextKind)
		ifTrue: [
			self
				openStructuredInspectorForPreview: preview
				title: rowLabel
				entryKey: entryKey
				path: nextPath
				previewKind: nextKind.
			^ self ].
	UIManager default inform: (preview at: #value ifAbsent: [ '' ]) asString
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> browseReferencersForStructuredPreviewRow: row entryKey: entryKey path: path previewKind: previewKind [
	| rowLabel nextPath |
	rowLabel := (row at: 1 ifAbsent: [ '' ]) asString.
	rowLabel isEmpty ifTrue: [ ^ false ].
	rowLabel = '__truncated__' ifTrue: [ ^ false ].
	nextPath := path asArray copyWith: { previewKind asString. rowLabel }.
	^ self browseReferencersForEntryKey: entryKey path: nextPath
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> browsePromptedSessionStateKey [
	| rawKey key |
	session ifNil: [ ^ false ].
	rawKey := self requestInput: 'Session state key:' initialAnswer: '19'.
	(rawKey isNil or: [ rawKey trimBoth isEmpty ]) ifTrue: [ ^ false ].
	key := [ rawKey trimBoth asInteger ]
		on: Error
		do: [ nil ].
	key ifNil: [
		self inform: 'Enter a numeric session state key.'.
		^ false ].
	^ self browseSessionStateAtKey: key
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> browsePromptedSessionStateKeysReport [
	| rawKeys keys |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	rawKeys := self requestInput: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [
		session objectSpaceDiagnostics reportTextForKeys: keys ]).
	^ true
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> browseSessionStateAtKey: aKey [
	| sessionStateValue targetOop |
	session ifNil: [ ^ false ].
	sessionStateValue := [ session sessionStateAt: aKey ]
		on: Error
		do: [ :ex |
			self inform: 'Session state lookup failed: ', ex messageText.
			^ false ].
	sessionStateValue ifNil: [
		self inform: 'Session state key ', aKey printString, ' is not set.'.
		^ false ].
	targetOop := self oopForInspectableObject: sessionStateValue.
	targetOop ifNil: [
		self inform: 'Session state key ', aKey printString, ' does not currently have an inspectable remote oop.'.
		^ false ].
	^ self openInspectorOnOop: targetOop
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> browseStaleTypedWrapperLifecycleReport [
	| report staleEntries |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	report := self withShallowMaterializationDo: [ session typedWrapperLifecycleReport ].
	staleEntries := report staleEntries.
	staleEntries isEmpty ifTrue: [
		self inform: 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.'.
		^ true ].
	self inform: (GbsTypedWrapperLifecycleReport entries: staleEntries) text.
	^ true
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> browseObjectsInMemoryReport [
	| start limit |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ false ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ false ].
	self inform: (self withShallowMaterializationDo: [
		(session objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text ]).
	^ true
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> browseReferencersForEntryKey: keyName path: pathCollection [
	| targetOop referencers inspectable selection |
	targetOop := self oopForEntryKey: keyName path: pathCollection.
	targetOop ifNil: [
		self inform: 'Could not determine a remote object for referencer lookup.'.
		^ false ].
	referencers := self referencersInMemoryForOop: targetOop.
	inspectable := referencers select: [ :each | (self oopForInspectableObject: each) notNil ].
	inspectable isEmpty ifTrue: [
		self inform: 'No in-memory referencers found.'.
		^ false ].
	inspectable size = 1 ifTrue: [
		^ self openInspectorOnOop: (self oopForInspectableObject: inspectable first) ].
	selection := self
		chooseReferencerFrom: inspectable
		title: 'In-memory referencers'.
	selection ifNil: [ ^ false ].
	^ self openInspectorOnOop: (self oopForInspectableObject: selection)
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> browseTypedWrapperLifecycleReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session typedWrapperLifecycleReportText ]).
	^ true
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuDictionary [
	^ self newMenu
		addItem: [ :item |
			item name: 'Refresh Dictionaries'; action: [ self refreshDictionariesFor: userDropList selectedItem ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedUser ] ];
		addItem: [ :item |
			item name: 'Add...'; action: [ self addDictionary ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedUser ] ];
		addItem: [ :item |
			item name: 'Rename As...'; action: [ self renameDictionary ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedDictionary ] ];
		addItem: [ :item |
			item name: 'Remove...'; action: [ self removeDictionary ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedDictionary ] ];
		addItem: [ :item |
			item name: 'Inspect'; action: [ self inspectDictionary ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedDictionary ] ];
		yourself
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuDictionaryPopup [
	^ self menuDictionary
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuEntry [
	| menu |
	menu := self newMenu
		addItem: [ :item |
			item name: 'Add...'; action: [ self addEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedDictionary ] ];
		addItem: [ :item |
			item name: 'Rename As...'; action: [ self renameEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Remove...'; action: [ self removeEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Inspect Entry'; action: [ self inspectSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Referencers'; action: [ self browseReferencersForSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Inspect Session State Key...'; action: [ self browsePromptedSessionStateKey ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Typed Wrapper Lifecycle Report'; action: [ self browseTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Stale Typed Wrapper Report'; action: [ self browseStaleTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Session State Keys Report...'; action: [ self browsePromptedSessionStateKeysReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Objects In Memory Report...'; action: [ self browseObjectsInMemoryReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		yourself.
	self addExtensionEntryMenuItemsTo: menu.
	^ menu
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuEntryPopup [
	^ self menuEntry
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuFile [
	^ self newMenu
		addItem: [ :item | item name: 'Update'; action: [ self refreshUsers ] ];
		addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ];
		yourself
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuHelp [
	^ self newMenu
		addItem: [ :item | item name: 'About Symbol List Browser'; action: [ UIManager default inform: 'GemStone Symbol List Browser' ] ];
		yourself
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuPreview [
	| menu |
	menu := self newMenu
		addItem: [ :item |
			item name: 'Inspect Entry'; action: [ self inspectSelectedPreviewValue ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPreviewRow ] ];
		addItem: [ :item |
			item name: 'Referencers'; action: [ self browseReferencersForSelectedPreviewValue ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPreviewRow ] ];
		addItem: [ :item |
			item name: 'Inspect Session State Key...'; action: [ self browsePromptedSessionStateKey ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Typed Wrapper Lifecycle Report'; action: [ self browseTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Stale Typed Wrapper Report'; action: [ self browseStaleTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Session State Keys Report...'; action: [ self browsePromptedSessionStateKeysReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Objects In Memory Report...'; action: [ self browseObjectsInMemoryReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		yourself.
	self addExtensionPreviewMenuItemsTo: menu.
	^ menu
]

{ #category : 'menus' }
GbsSymbolListBrowserPresenter >> menuPreviewPopup [
	^ self menuPreview
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> openStructuredInspectorForPreview: preview title: titleString entryKey: entryKey path: path previewKind: previewKind [
	| inspectorClass previewFetcherBlock presenter |
	inspectorClass := Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ].
	inspectorClass
		ifNil: [ self inform: 'Structured value inspector is not available.' ]
		ifNotNil: [
			"Create a block that fetches preview for a given row in the inspector"
			previewFetcherBlock := [ :row |
				| rowLabel nextPath |
				rowLabel := (row at: 1 ifAbsent: [ '' ]) asString.
				rowLabel = '__truncated__' ifTrue: [ nil ] ifFalse: [
					nextPath := path asArray copyWith: { previewKind asString. rowLabel }.
					self structuredPreviewForEntryKey: entryKey path: nextPath ] ].
			
			presenter := inspectorClass
				openRows: (preview at: #rows ifAbsent: [ #() ])
				kind: previewKind
				title: titleString
				inspectBlock: [ :row |
					self
						inspectStructuredPreviewRow: row
						entryKey: entryKey
						path: path
						previewKind: previewKind ]
				rawPrintString: (preview at: #rawPrintString ifAbsent: [ '' ])
				entryKey: entryKey
				path: path
				previewKind: previewKind
				previewFetcherBlock: previewFetcherBlock.
			presenter
				propertyAt: #referencersBlock
				put: [ :row |
					self
						browseReferencersForStructuredPreviewRow: row
						entryKey: entryKey
						path: path
						previewKind: previewKind ];
				propertyAt: #typedWrapperLifecycleReportBlock
				put: [ self withShallowMaterializationDo: [ session typedWrapperLifecycleReportText ] ];
				propertyAt: #staleTypedWrapperReportBlock
				put: [ self withShallowMaterializationDo: [
					| report staleEntries |
					report := session typedWrapperLifecycleReport.
					staleEntries := report staleEntries.
					staleEntries isEmpty
						ifTrue: [ 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.' ]
						ifFalse: [ (GbsTypedWrapperLifecycleReport entries: staleEntries) text ] ] ];
				propertyAt: #sessionStateKeysReportBlock
				put: [ :keys | self withShallowMaterializationDo: [
					session objectSpaceDiagnostics reportTextForKeys: keys ] ];
				propertyAt: #objectsInMemoryReportBlock
				put: [ :start :limit | self withShallowMaterializationDo: [
					(session objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text ] ];
				propertyAt: #sessionStateBlock
				put: [ :key | self browseSessionStateAtKey: key ].
			self configureExtensionStructuredInspector: presenter ]
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> refreshDictionariesFor: userName [
	| previousDict raw dicts |
	previousDict := self selectedDictionaryName.
	userName ifNil: [
		dictionariesList items: #().
		entriesList items: #().
		self showSelectedEntryPreview.
		^ self ].
	raw := self withShallowMaterializationDo: [
		[ session evaluate: (self dictionariesScriptForUser: userName asString) ]
			on: Error
			do: [ '' ] ].
	dicts := (raw isString and: [ raw isNotEmpty ])
		ifTrue: [ (raw splitOn: Character tab) reject: [ :each | each isEmpty ] ]
		ifFalse: [ #() ].
	dictionariesList items: dicts asArray.
	self selectDictionaryName: previousDict ifMissingSelectFirst: true.
	self refreshEntriesForSelectedDictionary
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> refreshDictionariesFor: userName preservingSelection: dictionaryName [
	self refreshDictionariesFor: userName.
	self selectDictionaryName: dictionaryName ifMissingSelectFirst: true
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> refreshEntriesForDictionary: dictName [
	| previousKey raw lines keys userName |
	previousKey := self selectedEntryName.
	dictName ifNil: [
		entriesList items: #().
		entryValuesByKey := Dictionary new.
		self showSelectedEntryPreview.
		^ self ].
	userName := self selectedUserName.
	userName ifNil: [
		entryValuesByKey := Dictionary new.
		self showSelectedEntryPreview.
		^ self ].
	raw := self withShallowMaterializationDo: [
		[ session evaluate: (self entriesScriptForUser: userName dictionary: dictName asString) ]
			on: Error
			do: [ '' ] ].
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
	self selectEntryName: previousKey ifMissingSelectFirst: true.
	self showSelectedEntryPreview
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> refreshEntriesForDictionary: dictName preservingSelection: entryName [
	self refreshEntriesForDictionary: dictName.
	self selectEntryName: entryName ifMissingSelectFirst: true.
	self showSelectedEntryPreview
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> refreshEntriesForSelectedDictionary [
	| dictName |
	dictName := self selectedDictionaryName.
	dictName
		ifNil: [
			entriesList items: #().
			entryValuesByKey := Dictionary new.
			self showSelectedEntryPreview ]
		ifNotNil: [ self refreshEntriesForDictionary: dictName ]
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> refreshUsers [
	| raw users defaultUser |
	raw := self withShallowMaterializationDo: [
		[ session evaluate: self usersScript ] on: Error do: [ '' ] ].
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
GbsSymbolListBrowserPresenter >> removeDictionary [
	| userName dictName script critical |
	userName := self selectedUserName.
	dictName := self selectedDictionaryName.
	(userName isNil or: [ dictName isNil ]) ifTrue: [ ^ self ].
	critical := #( 'Globals' 'Published' 'UserGlobals' ) includes: dictName asString.
	(critical and: [
		(UIManager default
			confirm: dictName asString, ' is a standard GemStone dictionary. Remove anyway?'
			label: 'Remove Critical Dictionary') not ])
		ifTrue: [ ^ self ].
	(UIManager default
		confirm: 'Remove dictionary "', dictName asString, '"?'
		label: 'Remove Dictionary') ifFalse: [ ^ self ].
	script := self removeDictionaryScriptForUser: userName dictionary: dictName.
	[
		session execute: script.
		self refreshDictionariesFor: userName
	] on: Error do: [ :ex | UIManager default inform: 'Remove dictionary failed: ', ex messageText ].
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> removeDictionaryScriptForUser: userName dictionary: dictName [
	| u d |
	u := self literalString: userName.
	d := self literalString: dictName.
	^ '
	| users user sl dict |
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ self error: ''AllUsers not found'' ].
	user := users detect: [ :x | x userId asString = ', u, ' ] ifNone: [ nil ].
	user ifNil: [ self error: ''User not found'' ].
	sl := user symbolList.
	dict := sl detect: [ :each |
		| nm |
		nm := (each respondsTo: #name) ifTrue: [ each name asString ] ifFalse: [ each printString ].
		nm = ', d, ' ] ifNone: [ nil ].
	dict ifNil: [ self error: ''Dictionary not found'' ].
	(sl respondsTo: #removeKey:ifAbsent:)
		ifTrue: [ sl removeKey: ', d, ' asSymbol ifAbsent: [ ] ].
	(sl respondsTo: #remove:ifAbsent:)
		ifTrue: [ sl remove: dict ifAbsent: [ ] ].
	true'
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> removeEntry [
	| userName dictName keyName script |
	userName := self selectedUserName.
	dictName := self selectedDictionaryName.
	keyName := self selectedEntryName.
	(userName isNil or: [ dictName isNil or: [ keyName isNil ] ]) ifTrue: [ ^ self ].
	(UIManager default
		confirm: 'Remove entry "', keyName, '" from "', dictName asString, '"?'
		label: 'Remove Entry') ifFalse: [ ^ self ].
	script := self
		removeEntryScriptForUser: userName
		dictionary: dictName
		keyName: keyName.
	[
		session execute: script.
		self refreshEntriesForDictionary: dictName
	] on: Error do: [ :ex | UIManager default inform: 'Remove entry failed: ', ex messageText ].
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> removeEntryScriptForUser: userName dictionary: dictName keyName: keyName [
	| u d k |
	u := self literalString: userName.
	d := self literalString: dictName.
	k := self literalString: keyName.
	^ '
	| users user sl dict |
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ self error: ''AllUsers not found'' ].
	user := users detect: [ :x | x userId asString = ', u, ' ] ifNone: [ nil ].
	user ifNil: [ self error: ''User not found'' ].
	sl := user symbolList.
	dict := sl detect: [ :each |
		| nm |
		nm := (each respondsTo: #name) ifTrue: [ each name asString ] ifFalse: [ each printString ].
		nm = ', d, ' ] ifNone: [ nil ].
	dict ifNil: [ self error: ''Dictionary not found'' ].
	dict removeKey: ', k, ' asSymbol ifAbsent: [ self error: ''Entry not found'' ].
	true'
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> renameDictionary [
	| userName oldName newName script |
	userName := self selectedUserName.
	oldName := self selectedDictionaryName.
	(userName isNil or: [ oldName isNil ]) ifTrue: [ ^ self ].
	newName := UIManager default request: 'Rename dictionary to:' initialAnswer: oldName.
	(newName isNil or: [ newName trimBoth isEmpty ]) ifTrue: [ ^ self ].
	script := self
		renameDictionaryScriptForUser: userName
		oldName: oldName
		newName: newName trimBoth.
	[
		session execute: script.
		self refreshDictionariesFor: userName preservingSelection: newName trimBoth.
		self refreshEntriesForDictionary: newName trimBoth preservingSelection: nil
	] on: Error do: [ :ex | UIManager default inform: 'Rename dictionary failed: ', ex messageText ].
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> renameDictionaryScriptForUser: userName oldName: oldName newName: newName [
	| u o n |
	u := self literalString: userName.
	o := self literalString: oldName.
	n := self literalString: newName.
	^ '
	| users user sl dict |
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ self error: ''AllUsers not found'' ].
	user := users detect: [ :x | x userId asString = ', u, ' ] ifNone: [ nil ].
	user ifNil: [ self error: ''User not found'' ].
	sl := user symbolList.
	dict := sl detect: [ :each |
		| nm |
		nm := (each respondsTo: #name) ifTrue: [ each name asString ] ifFalse: [ each printString ].
		nm = ', o, ' ] ifNone: [ nil ].
	dict ifNil: [ self error: ''Dictionary not found'' ].
	(sl respondsTo: #removeKey:ifAbsent:)
		ifTrue: [ sl removeKey: ', o, ' asSymbol ifAbsent: [ ] ].
	(sl respondsTo: #at:put:)
		ifTrue: [ sl at: ', n, ' asSymbol put: dict ].
	(dict respondsTo: #name:) ifTrue: [ dict name: ', n, ' ].
	true'
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> renameEntry [
	| userName dictName oldKey newKey script |
	userName := self selectedUserName.
	dictName := self selectedDictionaryName.
	oldKey := self selectedEntryName.
	(userName isNil or: [ dictName isNil or: [ oldKey isNil ] ]) ifTrue: [ ^ self ].
	newKey := UIManager default request: 'Rename entry to:' initialAnswer: oldKey.
	(newKey isNil or: [ newKey trimBoth isEmpty ]) ifTrue: [ ^ self ].
	script := self
		renameEntryScriptForUser: userName
		dictionary: dictName
		oldKeyName: oldKey
		newKeyName: newKey trimBoth.
	[
		session execute: script.
		self refreshEntriesForDictionary: dictName preservingSelection: newKey trimBoth
	] on: Error do: [ :ex | UIManager default inform: 'Rename entry failed: ', ex messageText ].
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> renameEntryScriptForUser: userName dictionary: dictName oldKeyName: oldKeyName newKeyName: newKeyName [
	| u d o n |
	u := self literalString: userName.
	d := self literalString: dictName.
	o := self literalString: oldKeyName.
	n := self literalString: newKeyName.
	^ '
	| users user sl dict value |
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ self error: ''AllUsers not found'' ].
	user := users detect: [ :x | x userId asString = ', u, ' ] ifNone: [ nil ].
	user ifNil: [ self error: ''User not found'' ].
	sl := user symbolList.
	dict := sl detect: [ :each |
		| nm |
		nm := (each respondsTo: #name) ifTrue: [ each name asString ] ifFalse: [ each printString ].
		nm = ', d, ' ] ifNone: [ nil ].
	dict ifNil: [ self error: ''Dictionary not found'' ].
	value := dict at: ', o, ' asSymbol ifAbsent: [ self error: ''Entry not found'' ].
	dict at: ', n, ' asSymbol put: value.
	dict removeKey: ', o, ' asSymbol ifAbsent: [ ].
	true'
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> selectDictionaryName: dictName ifMissingSelectFirst: selectFirstBoolean [
	| items candidate |
	items := dictionariesList items ifNil: [ #() ].
	items isEmpty ifTrue: [ ^ self ].
	candidate := (dictName isString and: [ dictName isNotEmpty ])
		ifTrue: [ items detect: [ :each | each asString = dictName ] ifNone: [ nil ] ]
		ifFalse: [ nil ].
	candidate ifNil: [
		selectFirstBoolean ifFalse: [ ^ self ].
		candidate := items first ].
	(dictionariesList respondsTo: #selectItem:)
		ifTrue: [ dictionariesList selectItem: candidate ]
		ifFalse: [
			(dictionariesList respondsTo: #selectedItem:)
				ifTrue: [ dictionariesList selectedItem: candidate ] ]
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> selectEntryName: entryName ifMissingSelectFirst: selectFirstBoolean [
	| items candidate |
	items := entriesList items ifNil: [ #() ].
	items isEmpty ifTrue: [ ^ self ].
	candidate := (entryName isString and: [ entryName isNotEmpty ])
		ifTrue: [ items detect: [ :each | each asString = entryName ] ifNone: [ nil ] ]
		ifFalse: [ nil ].
	candidate ifNil: [
		selectFirstBoolean ifFalse: [ ^ self ].
		candidate := items first ].
	(entriesList respondsTo: #selectItem:)
		ifTrue: [ entriesList selectItem: candidate ]
		ifFalse: [
			(entriesList respondsTo: #selectedItem:)
				ifTrue: [ entriesList selectedItem: candidate ] ]
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> selectedDictionaryName [
	| selected |
	(dictionariesList respondsTo: #selection)
		ifTrue: [
			selected := [ dictionariesList selection selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected asString ] ].
	(dictionariesList respondsTo: #selectedItem)
		ifTrue: [
			selected := [ dictionariesList selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected asString ] ].
	^ nil
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> selectedEntryName [
	| selected |
	(entriesList respondsTo: #selection)
		ifTrue: [
			selected := [ entriesList selection selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected asString ] ].
	(entriesList respondsTo: #selectedItem)
		ifTrue: [
			selected := [ entriesList selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected asString ] ].
	^ nil
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> selectedPreviewRow [
	| selected |
	(valueText respondsTo: #selection)
		ifTrue: [
			selected := [ valueText selection selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected ] ].
	(valueText respondsTo: #selectedItem)
		ifTrue: [
			selected := [ valueText selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected ] ].
	^ nil
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> selectedUserName [
	| selected |
	(userDropList respondsTo: #selectedItem)
		ifTrue: [
			selected := [ userDropList selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected asString ] ].
	(userDropList respondsTo: #selection)
		ifTrue: [
			selected := [ userDropList selection selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected asString ] ].
	^ nil
]

{ #category : 'accessing' }
GbsSymbolListBrowserPresenter >> session: aSession [
	session := aSession
]

{ #category : 'ui' }
GbsSymbolListBrowserPresenter >> chooseReferencerFrom: referencers title: aTitle [
	| labels index |
	labels := referencers collect: [ :each | self displayStringForReferencer: each ].
	index := UIManager default chooseFrom: labels title: aTitle.
	index = 0 ifTrue: [ ^ nil ].
	^ referencers at: index ifAbsent: [ nil ]
]

{ #category : 'ui' }
GbsSymbolListBrowserPresenter >> displayStringForReferencer: anObject [
	(anObject isKindOf: GbsProxy) ifTrue: [
		^ [ anObject asLocalString ]
			on: Error
			do: [ 'aGbsProxy(oop: ', anObject oop asString, ')' ] ].
	^ anObject printString
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> showEntryForKey: key [
	| preview |
	selectionField text: key asString.
	preview := self structuredPreviewForEntryKey: key.
	currentPreview := preview.
	(valueText respondsTo: #items:)
		ifTrue: [ valueText items: (preview ifNil: [ #() ] ifNotNil: [ preview at: #rows ifAbsent: [ #() ] ]) ].
	(entryText respondsTo: #text:)
		ifTrue: [ entryText text: (preview ifNil: [ '' ] ifNotNil: [ preview at: #rawPrintString ifAbsent: [ '' ] ]) ]
]

{ #category : 'actions' }
GbsSymbolListBrowserPresenter >> showSelectedEntryPreview [
	| key |
	key := self selectedEntryName.
	key ifNil: [
		currentPreview := nil.
		selectionField text: ''.
		(valueText respondsTo: #items:) ifTrue: [ valueText items: #() ].
		(entryText respondsTo: #text:) ifTrue: [ entryText text: '' ].
		^ self ].
	self showEntryForKey: key
]

{ #category : 'accessing' }
GbsSymbolListBrowserPresenter >> targetUserName: aString [
	targetUserName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> parsedStructuredPreviewFrom: rawString [
	| lines kind rows value rawPrintString rawParts structuredPart |
	(rawString isString and: [ rawString isNotEmpty ]) ifFalse: [
		^ Dictionary new
			at: #kind put: 'string';
			at: #rows put: { { 'Value'. '' } };
			at: #value put: '';
			at: #rawPrintString put: '';
			yourself ].
	
	"Split on raw printString delimiter first"
	rawParts := rawString splitOn: '===RAWPRINTSTRING==='.
	rawPrintString := rawParts size > 1
		ifTrue: [ rawParts last trimBoth ]
		ifFalse: [ '' ].
	
	"Parse structured data from first part only"
	structuredPart := rawParts first.
	lines := structuredPart lines.
	kind := lines
		ifEmpty: [ 'string' ]
		ifNotEmpty: [ lines first asString ].
	rows := OrderedCollection new.
	(kind = 'dictionary' or: [ kind = 'collection' ]) ifTrue: [
		(lines allButFirst) do: [ :line |
			| parts |
			parts := line splitOn: Character tab.
			rows add: {
				(parts at: 1 ifAbsent: [ '' ]).
				(parts at: 2 ifAbsent: [ '' ]) } ].
		^ Dictionary new
			at: #kind put: kind;
			at: #rows put: rows asArray;
			at: #value put: '';
			at: #rawPrintString put: rawPrintString;
			yourself ].
	value := lines size > 1
		ifTrue: [ lines second ]
		ifFalse: [ '' ].
	^ Dictionary new
		at: #kind put: 'string';
		at: #rows put: { { 'Value'. value asString } };
		at: #value put: value asString;
		at: #rawPrintString put: rawPrintString;
		yourself
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> pathLiteralStringFor: pathCollection [
	^ String streamContents: [ :stream |
		stream nextPutAll: '#('.
		pathCollection doWithIndex: [ :step :index |
			stream
				nextPutAll: '(';
				nextPutAll: (self literalString: (step at: 1 ifAbsent: [ '' ]) asString);
				space;
				nextPutAll: (self literalString: (step at: 2 ifAbsent: [ '' ]) asString);
				nextPutAll: ')'.
			index < pathCollection size ifTrue: [ stream space ] ].
		stream nextPutAll: ')' ]
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> structuredPreviewForEntryKey: keyName [
	^ self structuredPreviewForEntryKey: keyName path: #()
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> structuredPreviewForEntryKey: keyName path: pathCollection [
	| userName dictName raw |
	userName := self selectedUserName.
	dictName := self selectedDictionaryName.
	(userName isNil or: [ dictName isNil or: [ keyName isNil ] ]) ifTrue: [ ^ nil ].
	raw := self withShallowMaterializationDo: [
		[ session executeAndFetch: (self
			structuredPreviewScriptForUser: userName
			dictionary: dictName
			keyName: keyName
			path: pathCollection) ]
			on: Error
			do: [ :ex | 'string', String lf, 'Inspect entry failed: ', ex messageText ] ].
	^ self parsedStructuredPreviewFrom: raw
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> oopForEntryKey: keyName path: pathCollection [
	| userName dictName raw oopValue |
	userName := self selectedUserName.
	dictName := self selectedDictionaryName.
	(userName isNil or: [ dictName isNil or: [ keyName isNil ] ]) ifTrue: [ ^ nil ].
	raw := [ session executeAndFetch: (self
		oopScriptForUser: userName
		dictionary: dictName
		keyName: keyName
		path: pathCollection) ]
		on: Error
		do: [ nil ].
	raw ifNil: [ ^ nil ].
	oopValue := [ raw asString trimBoth asNumber ] on: Error do: [ nil ].
	^ oopValue
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> oopScriptForUser: userName dictionary: dictName keyName: keyName path: pathCollection [
	| u d k p |
	u := self literalString: userName.
	d := self literalString: dictName.
	k := self literalString: keyName.
	p := self pathLiteralStringFor: pathCollection.
	^ '
	| users user sl dict entryKey value path |
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
	entryKey := dict keys detect: [ :each | each asString = ', k, ' ] ifNone: [ nil ].
	entryKey ifNil: [ ^ '''' ].
	value := dict at: entryKey.
	path := ', p, '.
	path do: [ :step |
		| stepKind stepLabel assoc items index |
		stepKind := step first asString.
		stepLabel := step second asString.
		stepKind = ''dictionary'' ifTrue: [
			assoc := value associations
				detect: [ :each | each key printString asString = stepLabel or: [ each key asString = stepLabel ] ]
				ifNone: [ nil ].
			assoc ifNil: [ ^ '''' ].
			value := assoc value ].
		stepKind = ''collection'' ifTrue: [
			stepLabel = ''__truncated__'' ifTrue: [ ^ '''' ].
			items := value asArray.
			index := [ stepLabel asNumber ] on: Error do: [ nil ].
			(index isNil or: [ index < 1 or: [ index > items size ] ]) ifTrue: [ ^ '''' ].
			value := items at: index ] ].
	(Reflection oopOf: value) asString'
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> structuredPreviewForSelectedPreviewRowInEntryKey: keyName [
	| row kind rowLabel |
	row := self selectedPreviewRow.
	kind := currentPreview
		ifNil: [ nil ]
		ifNotNil: [ currentPreview at: #kind ifAbsent: [ nil ] ].
	rowLabel := row
		ifNil: [ nil ]
		ifNotNil: [ row at: 1 ifAbsent: [ nil ] ].
	(keyName isNil or: [ rowLabel isNil or: [ kind isNil ] ]) ifTrue: [ ^ nil ].
	^ self
		structuredPreviewForEntryKey: keyName
		path: { { kind asString. rowLabel asString } }
]

{ #category : 'ui' }
GbsSymbolListBrowserPresenter >> inform: aString [
	UIManager default inform: aString.
	^ aString
]

{ #category : 'ui' }
GbsSymbolListBrowserPresenter >> oopForInspectableObject: anObject [
	(anObject isKindOf: GbsProxy) ifTrue: [ ^ anObject oop ].
	(anObject isInteger and: [ anObject > 20 ]) ifTrue: [ ^ anObject ].
	^ nil
]

{ #category : 'ui' }
GbsSymbolListBrowserPresenter >> openInspectorOnOop: anOop [
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ false ].
	GbsInspector inspect: anOop session: session.
	^ true
]

{ #category : 'ui' }
GbsSymbolListBrowserPresenter >> requestInput: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> parseSessionStateKeysFrom: aStringOrNil [
	| trimmed tokens keys |
	(aStringOrNil isNil or: [ aStringOrNil trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	trimmed := aStringOrNil trimBoth.
	tokens := (trimmed findTokens: ',') collect: #trimBoth thenReject: #isEmpty.
	tokens isEmpty ifTrue: [ ^ nil ].
	keys := tokens collect: [ :each |
		[ each asInteger ] on: Error do: [ ^ nil ] ].
	^ keys asArray
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> requestPositiveInteger: promptString initialAnswer: defaultString [
	| rawValue |
	rawValue := self requestInput: promptString initialAnswer: defaultString.
	(rawValue isNil or: [ rawValue trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ [ | value |
		value := rawValue trimBoth asInteger.
		value > 0 ifTrue: [ value ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : 'querying' }
GbsSymbolListBrowserPresenter >> referencersInMemoryForOop: anOop [
	session ifNil: [ ^ #() ].
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ #() ].
	^ self withShallowMaterializationDo: [
		[ session referencesToOop: anOop ]
			on: Error
			do: [ #() ] ]
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> withShallowMaterializationDo: aBlock [
	session ifNil: [ ^ aBlock value ].
	^ session
		withMaterializationProfile: GbsShallowMaterializationProfile new
		do: aBlock
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> structuredPreviewScriptForUser: userName dictionary: dictName keyName: keyName [
	^ self structuredPreviewScriptForUser: userName dictionary: dictName keyName: keyName path: #()
]

{ #category : 'private' }
GbsSymbolListBrowserPresenter >> structuredPreviewScriptForUser: userName dictionary: dictName keyName: keyName path: pathCollection [
	| u d k p |
	u := self literalString: userName.
	d := self literalString: dictName.
	k := self literalString: keyName.
	p := self pathLiteralStringFor: pathCollection.
	^ '
	| users user sl dict entryKey value path sanitize stream limit index associations items rawString |
	sanitize := [ :obj |
		| string |
		string := obj printString asString.
		string := string copyReplaceAll: String cr with: '' ''.
		string := string copyReplaceAll: String lf with: '' ''.
		string := string copyReplaceAll: Character tab asString with: ''    ''.
		string ].
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ ^ ''string'', String cr, ''AllUsers not found'' ].
	user := users detect: [ :x | x userId asString = ', u, ' ] ifNone: [ nil ].
	user ifNil: [ ^ ''string'', String cr, ''User not found'' ].
	sl := user symbolList.
	dict := sl detect: [ :each |
		| name |
		name := (each respondsTo: #name) ifTrue: [ each name asString ] ifFalse: [ each printString ].
		name = ', d, ' ] ifNone: [ nil ].
	dict ifNil: [ ^ ''string'', String cr, ''Dictionary not found'' ].
	entryKey := dict keys detect: [ :each | each asString = ', k, ' ] ifNone: [ nil ].
	entryKey ifNil: [ ^ ''string'', String cr, ''Entry not found'' ].
	value := dict at: entryKey.
	path := ', p, '.
	path do: [ :step |
		| stepKind stepLabel assoc |
		stepKind := step first asString.
		stepLabel := step second asString.
		stepKind = ''dictionary'' ifTrue: [
			assoc := value associations
				detect: [ :each | (sanitize value: each key) = stepLabel ]
				ifNone: [ nil ].
			assoc ifNil: [ ^ ''string'', String cr, ''Entry not found'' ].
			value := assoc value ].
		stepKind = ''collection'' ifTrue: [
			stepLabel = ''__truncated__'' ifTrue: [ ^ ''string'', String cr, ''Entry not found'' ].
			items := value asArray.
			index := [ stepLabel asNumber ] on: Error do: [ nil ].
			(index isNil or: [ index < 1 or: [ index > items size ] ]) ifTrue: [ ^ ''string'', String cr, ''Entry not found'' ].
			value := items at: index ] ].
	stream := WriteStream on: String new.
	(value isKindOf: Dictionary) ifTrue: [
		stream nextPutAll: ''dictionary''; cr.
		associations := value associations asArray.
		limit := associations size min: 200.
		1 to: limit do: [ :idx |
			| assoc |
			assoc := associations at: idx.
			stream
				nextPutAll: (sanitize value: assoc key);
				tab;
				nextPutAll: (sanitize value: assoc value).
			idx < limit ifTrue: [ stream cr ] ].
		value size > limit ifTrue: [
			limit > 0 ifTrue: [ stream cr ].
			stream
				nextPutAll: ''__truncated__'';
				tab;
				nextPutAll: ''Only first '', limit asString, '' entries shown'' ].
		stream nextPutAll: String cr, ''===RAWPRINTSTRING==='' , String cr.
		stream nextPutAll: value printString.
		^ stream contents ].
	((value isCollection) and: [ (value isKindOf: String) not and: [ (value isKindOf: Symbol) not ] ]) ifTrue: [
		stream nextPutAll: ''collection''; cr.
		items := value asArray.
		limit := items size min: 200.
		1 to: limit do: [ :idx |
			stream
				nextPutAll: idx asString;
				tab;
				nextPutAll: (sanitize value: (items at: idx)).
			idx < limit ifTrue: [ stream cr ] ].
		value size > limit ifTrue: [
			limit > 0 ifTrue: [ stream cr ].
			stream
				nextPutAll: ''__truncated__'';
				tab;
				nextPutAll: ''Only first '', limit asString, '' items shown'' ].
		stream nextPutAll: String cr, ''===RAWPRINTSTRING==='' , String cr.
		stream nextPutAll: value printString.
		^ stream contents ].
	stream
		nextPutAll: ''string'';
		cr;
		nextPutAll: (sanitize value: value).
	stream nextPutAll: String cr, ''===RAWPRINTSTRING==='' , String cr.
	stream nextPutAll: value printString.
	stream contents'
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
