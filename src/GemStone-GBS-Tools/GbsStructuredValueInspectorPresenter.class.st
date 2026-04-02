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
	| presenter |
	presenter := self new.
	presenter
		rows: aCollection;
		kind: aKind;
		windowTitle: aTitle;
		open.
	^ presenter
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

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> kind: aString [
	kind := aString ifNil: [ 'dictionary' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> rows: aCollection [
	rows := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
GbsStructuredValueInspectorPresenter >> windowTitle: aString [
	windowTitle := aString ifNil: [ 'Value Inspector' ] ifNotNil: [ aString asString ]
]
