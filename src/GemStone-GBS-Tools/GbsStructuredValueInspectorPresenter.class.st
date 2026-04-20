Class {
	#name : 'GbsStructuredValueInspectorPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'rows',
		'kind',
		'windowTitle',
		'table',
		'rawText',
		'entryKey',
		'path',
		'previewKind',
		'previewFetcherBlock'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsStructuredValueInspectorPresenter class >> openRows: aCollection kind: aKind title: aTitle [
	^ self openRows: aCollection kind: aKind title: aTitle inspectBlock: nil rawPrintString: '' entryKey: nil path: nil previewKind: aKind previewFetcherBlock: nil
]

{ #category : 'instance creation' }
GbsStructuredValueInspectorPresenter class >> openRows: aCollection kind: aKind title: aTitle inspectBlock: aBlock [
	^ self openRows: aCollection kind: aKind title: aTitle inspectBlock: aBlock rawPrintString: '' entryKey: nil path: nil previewKind: aKind previewFetcherBlock: nil
]

{ #category : 'instance creation' }
GbsStructuredValueInspectorPresenter class >> openRows: aCollection kind: aKind title: aTitle inspectBlock: aBlock rawPrintString: rawString [
	^ self openRows: aCollection kind: aKind title: aTitle inspectBlock: aBlock rawPrintString: rawString entryKey: nil path: nil previewKind: aKind previewFetcherBlock: nil
]

{ #category : 'instance creation' }
GbsStructuredValueInspectorPresenter class >> openRows: aCollection kind: aKind title: aTitle inspectBlock: aBlock rawPrintString: rawString entryKey: anEntryKey path: aPath previewKind: aPreviewKind previewFetcherBlock: aFetcherBlock [
	| presenter |
	presenter := self new.
	presenter
		rows: aCollection;
		kind: aKind;
		windowTitle: aTitle;
		rawPrintString: rawString;
		entryKey: anEntryKey;
		path: aPath;
		previewKind: aPreviewKind;
		previewFetcherBlock: aFetcherBlock.
	presenter propertyAt: #inspectBlock put: aBlock.
	presenter open.
	^ presenter
]

{ #category : 'private' }
GbsStructuredValueInspectorPresenter >> canInspectSelectedEntry [
	| row inspectBlock |
	row := self selectedRow.
	inspectBlock := self propertyAt: #inspectBlock ifAbsent: [ nil ].
	^ inspectBlock notNil
		and: [ row notNil
		and: [ (row at: 1 ifAbsent: [ '' ]) asString ~= '__truncated__' ] ]
]

{ #category : 'private' }
GbsStructuredValueInspectorPresenter >> canBrowseReferencersForSelectedEntry [
	| row referencersBlock |
	row := self selectedRow.
	referencersBlock := self propertyAt: #referencersBlock ifAbsent: [ nil ].
	^ referencersBlock notNil
		and: [ row notNil
		and: [ (row at: 1 ifAbsent: [ '' ]) asString ~= '__truncated__' ] ]
]

{ #category : 'private' }
GbsStructuredValueInspectorPresenter >> canBrowseSessionState [
	^ (self propertyAt: #sessionStateBlock ifAbsent: [ nil ]) notNil
]

{ #category : 'initialization' }
GbsStructuredValueInspectorPresenter >> connectPresenters [
	(table respondsTo: #contextMenu:) ifTrue: [
		table contextMenu: [ self menuEntryPopup ] ].
	(table respondsTo: #whenSelectionChangedDo:) ifTrue: [
		table whenSelectionChangedDo: [ :selection | self updateRawTextForSelectedRow ] ]
]

{ #category : 'layout' }
GbsStructuredValueInspectorPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: (self newLabel label: self firstColumnTitle, ' / Values') expand: false;
		add: table;
		add: (self newLabel label: 'PrintString') expand: false;
		add: rawText;
		spacing: 8;
		yourself
]

{ #category : 'initialization' }
GbsStructuredValueInspectorPresenter >> initializePresenters [
	table := self newTable.
	table
		addColumn: (SpStringTableColumn title: self firstColumnTitle evaluated: [ :row | row at: 1 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :row | row at: 2 ifAbsent: [ '' ] ]);
		yourself.
	table items: (rows ifNil: [ #() ]).
	rawText := self newText.
	rawText beNotEditable
]

{ #category : 'initialization' }
GbsStructuredValueInspectorPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: (windowTitle ifNil: [ 'Value Inspector' ]);
		initialExtent: 620 @ 520
]

{ #category : 'private' }
GbsStructuredValueInspectorPresenter >> firstColumnTitle [
	kind = 'collection' ifTrue: [ ^ 'Index' ].
	^ 'Key'
]

{ #category : 'actions' }
GbsStructuredValueInspectorPresenter >> inspectSelectedEntry [
	| row inspectBlock |
	self canInspectSelectedEntry ifFalse: [ ^ self ].
	row := self selectedRow.
	inspectBlock := self propertyAt: #inspectBlock ifAbsent: [ nil ].
	inspectBlock value: row
]

{ #category : 'actions' }
GbsStructuredValueInspectorPresenter >> browseReferencersForSelectedEntry [
	| row referencersBlock |
	self canBrowseReferencersForSelectedEntry ifFalse: [ ^ self ].
	row := self selectedRow.
	referencersBlock := self propertyAt: #referencersBlock ifAbsent: [ nil ].
	referencersBlock value: row
]

{ #category : 'actions' }
GbsStructuredValueInspectorPresenter >> browsePromptedSessionStateKey [
	| rawKey key |
	self canBrowseSessionState ifFalse: [ ^ self ].
	rawKey := self requestInput: 'Session state key:' initialAnswer: '19'.
	(rawKey isNil or: [ rawKey trimBoth isEmpty ]) ifTrue: [ ^ self ].
	key := [ rawKey trimBoth asInteger ]
		on: Error
		do: [ nil ].
	key ifNil: [
		self inform: 'Enter a numeric session state key.'.
		^ self ].
	self browseSessionStateAtKey: key
]

{ #category : 'actions' }
GbsStructuredValueInspectorPresenter >> browseSessionStateAtKey: aKey [
	| sessionStateBlock |
	self canBrowseSessionState ifFalse: [ ^ self ].
	sessionStateBlock := self propertyAt: #sessionStateBlock ifAbsent: [ nil ].
	sessionStateBlock value: aKey
]

{ #category : 'actions' }
GbsStructuredValueInspectorPresenter >> browseTypedWrapperLifecycleReport [
	| reportBlock |
	reportBlock := self propertyAt: #typedWrapperLifecycleReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	self inform: reportBlock value
]

{ #category : 'actions' }
GbsStructuredValueInspectorPresenter >> browseStaleTypedWrapperLifecycleReport [
	| reportBlock |
	reportBlock := self propertyAt: #staleTypedWrapperReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	self inform: reportBlock value
]

{ #category : 'actions' }
GbsStructuredValueInspectorPresenter >> browsePromptedSessionStateKeysReport [
	| reportBlock rawKeys keys |
	reportBlock := self propertyAt: #sessionStateKeysReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	rawKeys := self requestInput: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ self ].
	self inform: (reportBlock value: keys)
]

{ #category : 'actions' }
GbsStructuredValueInspectorPresenter >> browseObjectsInMemoryReport [
	| reportBlock start limit |
	reportBlock := self propertyAt: #objectsInMemoryReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ self ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ self ].
	self inform: (reportBlock value: start value: limit)
]

{ #category : 'menus' }
GbsStructuredValueInspectorPresenter >> menuEntry [
	| menu |
	menu := self newMenu
		addItem: [ :item |
			item name: 'Inspect Entry'; action: [ self inspectSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canInspectSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Referencers'; action: [ self browseReferencersForSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canBrowseReferencersForSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Inspect Session State Key...'; action: [ self browsePromptedSessionStateKey ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canBrowseSessionState ] ];
		addItem: [ :item |
			item name: 'Typed Wrapper Lifecycle Report'; action: [ self browseTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #typedWrapperLifecycleReportBlock ifAbsent: [ nil ]) notNil ] ];
		addItem: [ :item |
			item name: 'Stale Typed Wrapper Report'; action: [ self browseStaleTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #staleTypedWrapperReportBlock ifAbsent: [ nil ]) notNil ] ];
		addItem: [ :item |
			item name: 'Session State Keys Report...'; action: [ self browsePromptedSessionStateKeysReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #sessionStateKeysReportBlock ifAbsent: [ nil ]) notNil ] ];
		addItem: [ :item |
			item name: 'Objects In Memory Report...'; action: [ self browseObjectsInMemoryReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #objectsInMemoryReportBlock ifAbsent: [ nil ]) notNil ] ];
		yourself.
	self addExtensionEntryMenuItemsTo: menu.
	^ menu
]

{ #category : 'menus' }
GbsStructuredValueInspectorPresenter >> menuEntryPopup [
	^ self menuEntry
]

{ #category : 'ui' }
GbsStructuredValueInspectorPresenter >> inform: aString [
	| informBlock |
	informBlock := self propertyAt: #informBlock ifAbsent: [ nil ].
	informBlock ifNotNil: [ ^ informBlock value: aString ].
	UIManager default inform: aString.
	^ aString
]

{ #category : 'private' }
GbsStructuredValueInspectorPresenter >> parseSessionStateKeysFrom: aStringOrNil [
	| trimmed tokens keys |
	(aStringOrNil isNil or: [ aStringOrNil trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	trimmed := aStringOrNil trimBoth.
	tokens := (trimmed findTokens: ',') collect: #trimBoth thenReject: #isEmpty.
	tokens isEmpty ifTrue: [ ^ nil ].
	keys := tokens collect: [ :each |
		[ each asInteger ] on: Error do: [ ^ nil ] ].
	^ keys asArray
]

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> entryKey: aString [
	entryKey := aString
]

{ #category : 'private' }
GbsStructuredValueInspectorPresenter >> firstColumnTitle [
	kind = 'collection' ifTrue: [ ^ 'Index' ].
	^ 'Key'
]

{ #category : 'actions' }
GbsStructuredValueInspectorPresenter >> inspectSelectedEntry [
	| row inspectBlock |
	self canInspectSelectedEntry ifFalse: [ ^ self ].
	row := self selectedRow.
	inspectBlock := self propertyAt: #inspectBlock ifAbsent: [ nil ].
	inspectBlock value: row
]

{ #category : 'private' }
GbsStructuredValueInspectorPresenter >> canActivateSelectedEntry [
	| row activateBlock |
	row := self selectedRow.
	activateBlock := self propertyAt: #activateBlock ifAbsent: [ nil ].
	^ activateBlock notNil
		and: [ row notNil
		and: [ (row at: 1 ifAbsent: [ '' ]) asString ~= '__truncated__' ] ]
]

{ #category : 'actions' }
GbsStructuredValueInspectorPresenter >> activateSelectedEntry [
	| row activateBlock |
	self canActivateSelectedEntry ifFalse: [ ^ self ].
	row := self selectedRow.
	activateBlock := self propertyAt: #activateBlock ifAbsent: [ nil ].
	activateBlock value: row
]

{ #category : 'menus' }
GbsStructuredValueInspectorPresenter >> menuEntry [
	| menu |
	menu := self newMenu
		addItem: [ :item |
			item name: 'Inspect Entry'; action: [ self inspectSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canInspectSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Activate Entry'; action: [ self activateSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canActivateSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Referencers'; action: [ self browseReferencersForSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canBrowseReferencersForSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Inspect Session State Key...'; action: [ self browsePromptedSessionStateKey ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canBrowseSessionState ] ];
		addItem: [ :item |
			item name: 'Typed Wrapper Lifecycle Report'; action: [ self browseTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #typedWrapperLifecycleReportBlock ifAbsent: [ nil ]) notNil ] ];
		addItem: [ :item |
			item name: 'Stale Typed Wrapper Report'; action: [ self browseStaleTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #staleTypedWrapperReportBlock ifAbsent: [ nil ]) notNil ] ];
		addItem: [ :item |
			item name: 'Session State Keys Report...'; action: [ self browsePromptedSessionStateKeysReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #sessionStateKeysReportBlock ifAbsent: [ nil ]) notNil ] ];
		addItem: [ :item |
			item name: 'Objects In Memory Report...'; action: [ self browseObjectsInMemoryReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #objectsInMemoryReportBlock ifAbsent: [ nil ]) notNil ] ];
		yourself.
	self addExtensionEntryMenuItemsTo: menu.
	^ menu
]

{ #category : 'menus' }
GbsStructuredValueInspectorPresenter >> menuEntryPopup [
	^ self menuEntry
]

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> kind: aString [
	kind := aString ifNil: [ 'dictionary' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> path: aCollection [
	path := aCollection
]

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> previewFetcherBlock: aBlock [
	previewFetcherBlock := aBlock
]

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> previewKind: aString [
	previewKind := aString
]

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> rawPrintString: aString [
	rawText ifNotNil: [
		rawText text: (aString ifNil: [ '' ] ifNotNil: [ aString asString ]) ]
]

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> rows: aCollection [
	rows := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ].
	(table respondsTo: #items:)
		ifTrue: [ table items: rows ]
]

{ #category : 'ui' }
GbsStructuredValueInspectorPresenter >> requestInput: prompt initialAnswer: defaultString [
	| requestBlock |
	requestBlock := self propertyAt: #requestInputBlock ifAbsent: [ nil ].
	requestBlock ifNotNil: [ ^ requestBlock value: prompt value: defaultString ].
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : 'private' }
GbsStructuredValueInspectorPresenter >> requestPositiveInteger: promptString initialAnswer: defaultString [
	| rawValue |
	rawValue := self requestInput: promptString initialAnswer: defaultString.
	(rawValue isNil or: [ rawValue trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ [ | value |
		value := rawValue trimBoth asInteger.
		value > 0 ifTrue: [ value ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : 'private' }
GbsStructuredValueInspectorPresenter >> selectedRow [
	| selected |
	(table respondsTo: #selection)
		ifTrue: [
			selected := [ table selection selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected ] ].
	(table respondsTo: #selectedItem)
		ifTrue: [
			selected := [ table selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected ] ].
	^ nil
]

{ #category : 'actions' }
GbsStructuredValueInspectorPresenter >> updateRawTextForSelectedRow [
	| row preview |
	row := self selectedRow.
	row ifNil: [ ^ self ].
	(row at: 1 ifAbsent: [ '' ]) asString = '__truncated__' ifTrue: [ ^ self ].
	
	"Use previewFetcherBlock if available to fetch preview for this row"
	previewFetcherBlock ifNotNil: [
		preview := previewFetcherBlock value: row.
		preview ifNotNil: [
			self rawPrintString: (preview at: #rawPrintString ifAbsent: [ '' ]) ] ]
]

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> windowTitle: aString [
	windowTitle := aString ifNil: [ 'Value Inspector' ] ifNotNil: [ aString asString ]
]
