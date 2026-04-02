Class {
	#name : 'GbsStructuredValueInspectorPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'rows',
		'kind',
		'windowTitle',
		'table'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsStructuredValueInspectorPresenter class >> openRows: aCollection kind: aKind title: aTitle [
	^ self openRows: aCollection kind: aKind title: aTitle inspectBlock: nil
]

{ #category : 'instance creation' }
GbsStructuredValueInspectorPresenter class >> openRows: aCollection kind: aKind title: aTitle inspectBlock: aBlock [
	| presenter |
	presenter := self new.
	presenter
		rows: aCollection;
		kind: aKind;
		windowTitle: aTitle.
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
		table contextMenu: [ self menuEntryPopup ] ]
]

{ #category : 'layout' }
GbsStructuredValueInspectorPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: table;
		yourself
]

{ #category : 'initialization' }
GbsStructuredValueInspectorPresenter >> initializePresenters [
	table := self newTable.
	table
		addColumn: (SpStringTableColumn title: self firstColumnTitle evaluated: [ :row | row at: 1 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :row | row at: 2 ifAbsent: [ '' ] ]);
		yourself.
	table items: (rows ifNil: [ #() ])
]

{ #category : 'initialization' }
GbsStructuredValueInspectorPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: (windowTitle ifNil: [ 'Value Inspector' ]);
		initialExtent: 620 @ 420
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

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> windowTitle: aString [
	windowTitle := aString ifNil: [ 'Value Inspector' ] ifNotNil: [ aString asString ]
]
