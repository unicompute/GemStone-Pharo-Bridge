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

{ #category : 'menus' }
GbsStructuredValueInspectorPresenter >> menuEntry [
	^ self newMenu
		addItem: [ :item |
			item name: 'Inspect Entry'; action: [ self inspectSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canInspectSelectedEntry ] ];
		yourself
]

{ #category : 'menus' }
GbsStructuredValueInspectorPresenter >> menuEntryPopup [
	^ self menuEntry
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

{ #category : 'menus' }
GbsStructuredValueInspectorPresenter >> menuEntry [
	^ self newMenu
		addItem: [ :item |
			item name: 'Inspect Entry'; action: [ self inspectSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canInspectSelectedEntry ] ];
		yourself
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
