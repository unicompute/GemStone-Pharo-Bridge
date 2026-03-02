Class {
	#name : 'GbsInspector',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'oop',
		'classLabel',
		'stateTable'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'reflection' }
GbsInspector class >> fetchReflectionStringFor: anOop session: aSession [
	"Sends the reflection script to GemStone and returns the raw formatted string"
	| script |
	script := '[
		| obj stream names childVal childOop |
		obj := Object _objectForOop: ', anOop asString, '.
		stream := WriteStream on: String new.
		names := obj class allInstVarNames.
		1 to: names size do: [ :i |
			childVal := obj instVarAt: i.
			childOop := Reflection oopOf: childVal.
			stream 
				nextPutAll: (names at: i) asString; nextPutAll: ''::::''; 
				nextPutAll: childVal printString; nextPutAll: ''::::'';
				nextPutAll: childOop asString; lf.
		].
		stream contents
	] value'.
	
	^ aSession executeAndFetch: script.
]

{ #category : 'instance creation' }
GbsInspector class >> inspect: anOop session: aSession [
	| inspector |
	inspector := self new.
	inspector inspectOop: anOop session: aSession.
	inspector open.
	^ inspector
]

{ #category : 'reflection' }
GbsInspector class >> parseReflectionString: aString [
	"Converts the GemStone string into an Array of { Name . Value . OOP }"
	| items lines parts |
	items := OrderedCollection new.
	
	(aString isNil or: [ aString beginsWith: 'Error:' ]) ifTrue: [ ^ items ].
	
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [ 
			parts := line splitOn: '::::'.
			parts size = 3 ifTrue: [ 
				items add: { parts first . parts second . parts third asInteger } 
			]
		]
	].
	^ items asArray
]

{ #category : 'layout' }
GbsInspector >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: classLabel height: 30;
		add: stateTable;
		yourself
]

{ #category : 'initialization' }
GbsInspector >> initializePresenters [
	classLabel := self newLabel.
	stateTable := self newTable.
	
	stateTable 
		addColumn: (SpStringTableColumn title: 'Variable' evaluated: [ :item | item first ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :item | item second ]).
]

{ #category : 'initialization' }
GbsInspector >> initializeWindow: aWindowPresenter [
	aWindowPresenter 
		title: 'GemStone Live Inspector';
		initialExtent: 450 @ 500.
]

{ #category : 'accessing' }
GbsInspector >> inspectOop: anOop session: aSession [
	| className printString rawData parsedItems items |
	oop := anOop.
	session := aSession.
	
	"1. Get Basic Info"
	className := session executeAndFetch: '(Object _objectForOop: ', anOop asString, ') class name asString'.
	classLabel label: 'Remote Class: ', className.
	printString := session executeAndFetch: '(Object _objectForOop: ', anOop asString, ') printString'.
	
	"2. Initialize table with 'self'"
	items := OrderedCollection new.
	items add: { 'self' . printString . anOop }.
	
	"3. Fetch and Parse using our GREEN TDD methods!"
	rawData := self class fetchReflectionStringFor: anOop session: session.
	parsedItems := self class parseReflectionString: rawData.
	items addAll: parsedItems.
	
	stateTable items: items.
	
	"4. DOUBLE-CLICK TO DIVE DEEPER!"
	stateTable whenActivatedDo: [ :selection |
		| selectedItem childOop |
		selectedItem := selection selectedItem.
		childOop := selectedItem third. 
		"Only inspect real objects, ignore nil (20)"
		childOop > 20 ifTrue: [ 
			GbsInspector inspect: childOop session: session 
		].
	].
]
