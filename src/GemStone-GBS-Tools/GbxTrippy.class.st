Class {
	#name : 'GbxTrippy',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'currentOop',
		'navigationStack',
		'pathLabel',
		'objectTable',
		'infoPanel',
		'backButton',
		'forwardButton',
		'upButton',
		'refreshButton',
		'inspectButton',
		'doItButton',
		'cache',
		'traversal'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxTrippy class >> inspectOop: anOop session: aSession [
	| trippy |
	
	trippy := self on: aSession.
	trippy inspectOop: anOop.
	trippy open.
	^ trippy
]

{ #category : 'instance creation' }
GbxTrippy class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'display' }
GbxTrippy >> buildInfoStringForOop: anOop className: className size: size [
	"Build info string for an object"
	| stream |
	
	stream := WriteStream on: String new.
	stream
		nextPutAll: 'OOP: '; nextPutAll: anOop asString; cr;
		nextPutAll: 'Class: '; nextPutAll: className; cr;
		nextPutAll: 'Size: '; nextPutAll: size asString; cr;
		nextPutAll: 'Cache Hits: '; nextPutAll: cache hitCount asString; cr;
		nextPutAll: 'Cache Misses: '; nextPutAll: cache missCount asString; cr;
		nextPutAll: 'Hit Ratio: '; nextPutAll: (cache hitRatio * 100) printString; nextPutAll: '%'.
	
	^ stream contents.
]

{ #category : 'fetching' }
GbxTrippy >> buildItemsForOop: anOop className: className [
	"Build items list for an object"
	| items script result |
	
	items := OrderedCollection new.
	
	"Fetch instance variables or elements"
	script := '[
		| obj stream names |
		obj := Object _objectForOop: ', anOop asString, '.
		stream := WriteStream on: String new.
		
		(obj class isVariable) ifTrue: [
			"Array-like object"
			1 to: (obj size min: 100) do: [ :i |
				| elem oop |
				elem := obj at: i.
				oop := Reflection oopOf: elem.
				stream
					nextPutAll: ''['', i asString, '']''; tab;
					nextPutAll: elem class name; tab;
					nextPutAll: elem printString; tab;
					nextPutAll: oop asString; lf.
			]
		] ifFalse: [
			"Regular object with inst vars"
			names := obj class allInstVarNames.
			names do: [ :name |
				| val oop |
				val := obj instVarNamed: name.
				oop := Reflection oopOf: val.
				stream
					nextPutAll: name; tab;
					nextPutAll: val class name; tab;
					nextPutAll: val printString; tab;
					nextPutAll: oop asString; lf.
			]
		].
		
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	result ifNotNil: [
		result splitOn: Character lf do: [ :line |
			line isNotEmpty ifTrue: [
				| parts |
				parts := line splitOn: Character tab.
				parts size >= 4 ifTrue: [
					items add: { 
						parts first.   "Name"
						parts second.  "Type"
						((parts third copyFrom: 1 to: (parts third size min: 100))). "Value (truncated)"
						parts fourth asInteger. "OOP"
					}
				]
			]
		]
	].
	
	^ items asArray.
]

{ #category : 'building' }
GbxTrippy >> buildToolbar [
	^ SpBoxLayout newHorizontal
		spacing: 3;
		add: backButton width: 80;
		add: forwardButton width: 80;
		add: upButton width: 60;
		add: refreshButton width: 80;
		add: inspectButton width: 80;
		add: doItButton width: 80;
		yourself
]

{ #category : 'accessing' }
GbxTrippy >> cache [
	^ cache
]

{ #category : 'accessing' }
GbxTrippy >> currentOop [
	^ currentOop
]

{ #category : 'layout' }
GbxTrippy >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 3;
		add: (self buildToolbar) height: 35;
		add: pathLabel height: 25;
		add: objectTable;
		add: infoPanel height: 150;
		yourself
]

{ #category : 'actions' }
GbxTrippy >> doItSelected [
	"Execute Do it on selected item"
	| item oop script result |
	
	item := objectTable selectedItem.
	item ifNil: [ ^ self ].
	
	oop := item at: 4.
	oop ifNil: [ ^ self ].
	
	script := '(Object _objectForOop: ', oop asString, ') yourself'.
	result := session executeAndFetch: script.
	
	InformDialog inform: 'Do it completed. Result: ', result asString.
]

{ #category : 'fetching' }
GbxTrippy >> fetchClassNameForOop: anOop [
	"Fetch class name for an OOP"
	| script |
	
	script := '[
		| obj |
		obj := Object _objectForOop: ', anOop asString, '.
		obj class name
	] value'.
	
	^ session executeAndFetch: script.
]

{ #category : 'fetching' }
GbxTrippy >> fetchSizeForOop: anOop [
	"Fetch size for an OOP"
	| script |
	
	script := '[
		| obj |
		obj := Object _objectForOop: ', anOop asString, '.
		obj size
	] value'.
	
	^ session executeAndFetch: script.
]

{ #category : 'navigation' }
GbxTrippy >> goBack [
	"Go back in navigation history"
	
	navigationStack size <= 1 ifTrue: [ ^ self ].
	
	navigationStack removeLast.
	currentOop := navigationStack last.
	
	self updatePath.
	self loadObject: currentOop.
	self updateNavigationButtons.
]

{ #category : 'navigation' }
GbxTrippy >> goForward [
	"Go forward (not implemented in this simple version)"
	"Would need a forward stack"
]

{ #category : 'navigation' }
GbxTrippy >> goUp [
	"Go up to parent object"
	
	navigationStack size <= 1 ifTrue: [ ^ self ].
	
	"Remove current, go to previous"
	navigationStack removeLast.
	currentOop := navigationStack last.
	
	self updatePath.
	self loadObject: currentOop.
	self updateNavigationButtons.
]

{ #category : 'initialization' }
GbxTrippy >> initializePresenters [
	pathLabel := self newLabel.
	pathLabel label: 'Root'.

	objectTable := self newTable.
	objectTable
		addColumn: (SpStringTableColumn title: 'Name' evaluated: [ :item | item at: 1 ]);
		addColumn: (SpStringTableColumn title: 'Type' evaluated: [ :item | item at: 2 ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :item | item at: 3 ]);
		whenActivatedDo: [ :selection | self navigateTo: selection selectedItem ].

	infoPanel := self newText.
	infoPanel editable: false.
	
	backButton := self newButton
		label: '← Back';
		action: [ self goBack ];
		disable.
	
	forwardButton := self newButton
		label: 'Forward →';
		action: [ self goForward ];
		disable.
	
	upButton := self newButton
		label: '↑ Up';
		action: [ self goUp ];
		disable.
	
	refreshButton := self newButton
		label: '⟳ Refresh';
		action: [ self refresh ].
	
	inspectButton := self newButton
		label: '🔍 Inspect';
		action: [ self inspectSelected ].
	
	doItButton := self newButton
		label: '⚡ Do it';
		action: [ self doItSelected ].
	
	navigationStack := OrderedCollection new.
	cache := GbxBasicCache on: session.
	traversal := GbxFetchTraversalTool on: session cache: cache.
]

{ #category : 'initialization' }
GbxTrippy >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GbxTrippy - GemStone Object Browser';
		initialExtent: 900 @ 700.
]

{ #category : 'navigation' }
GbxTrippy >> inspectOop: anOop [
	"Start inspecting an OOP"
	
	currentOop := anOop.
	navigationStack := OrderedCollection new.
	navigationStack add: anOop.
	
	self updatePath.
	self loadObject: anOop.
	
	self updateNavigationButtons.
]

{ #category : 'actions' }
GbxTrippy >> inspectSelected [
	"Inspect selected item in new Trippy window"
	| item oop trippy |
	
	item := objectTable selectedItem.
	item ifNil: [ ^ self ].
	
	oop := item at: 4.
	oop ifNil: [ ^ self ].
	
	trippy := GbxTrippy inspectOop: oop session: session.
]

{ #category : 'loading' }
GbxTrippy >> loadObject: anOop [
	"Load and display an object"
	
	[
		| className size items |
		
		"Get class name"
		className := self fetchClassNameForOop: anOop.
		
		"Get size"
		size := self fetchSizeForOop: anOop.
		
		"Build items list"
		items := self buildItemsForOop: anOop className: className.
		
		"Update table"
		objectTable items: items.
		
		"Update info panel"
		infoPanel text: self buildInfoStringForOop: anOop className: className size: size.
		
	] on: Error do: [ :ex |
		infoPanel text: 'Error: ', ex messageText.
		objectTable items: #().
	].
]

{ #category : 'navigation' }
GbxTrippy >> navigateTo: item [
	"Navigate to a selected item"
	| oop |
	
	item ifNil: [ ^ self ].
	
	oop := item at: 4. "OOP is 4th element"
	oop ifNil: [ ^ self ].
	
	"Push current to stack"
	navigationStack add: currentOop.
	currentOop := oop.
	
	self updatePath.
	self loadObject: oop.
	self updateNavigationButtons.
]

{ #category : 'navigation' }
GbxTrippy >> refresh [
	"Refresh current object"
	
	currentOop ifNotNil: [
		self loadObject: currentOop.
	].
]

{ #category : 'accessing' }
GbxTrippy >> session [
	^ session
]

{ #category : 'accessing' }
GbxTrippy >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxTrippy >> traversal [
	^ traversal
]

{ #category : 'updating' }
GbxTrippy >> updateNavigationButtons [
	"Update navigation button states"
	
	backButton enable: navigationStack size > 1.
	upButton enable: navigationStack size > 1.
]

{ #category : 'updating' }
GbxTrippy >> updatePath [
	"Update the path label"
	| path |
	
	path := navigationStack inject: '' into: [ :sum :oop |
		sum isEmpty ifTrue: [ oop asString ] ifFalse: [ sum, ' → ', oop asString ]
	].
	
	pathLabel label: path.
]
