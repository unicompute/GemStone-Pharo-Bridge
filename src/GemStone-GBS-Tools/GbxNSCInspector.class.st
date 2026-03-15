Class {
	#name : 'GbxNSCInspector',
	#superclass : 'GbsInspector',
	#instVars : [
		'nscSize'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxNSCInspector class >> inspectNSC: nscOop session: aSession [
	"Inspect a GemStone Non-Sequenceable Collection (Set, Bag, Dictionary, etc)"
	| inspector |
	
	inspector := self new.
	inspector inspectNSCOop: nscOop session: aSession.
	inspector open.
	^ inspector
]

{ #category : 'accessing' }
GbxNSCInspector >> inspectNSCOop: nscOop session: aSession [
	| className sizeData elementsData items |
	
	oop := nscOop.
	session := aSession.
	evaluationContextOop := nil.

	"1. Get NSC class and size"
	className := session executeAndFetch: '(Object _objectForOop: ', nscOop asString, ') class name asString'.
	sizeData := session executeAndFetch: '(Object _objectForOop: ', nscOop asString, ') size asString'.
	
	classLabel label: className, ' (size: ', sizeData, ')'.
	nscSize := sizeData asInteger.

	"2. Fetch elements"
	elementsData := self fetchNSCElements.
	
	"3. Build items list"
	items := OrderedCollection new.
	elementsData doWithIndex: [ :elem :index |
		items add: { 
			'Element ', index asString.
			elem at: 1.  "printString"
			elem at: 2.  "OOP"
		}
	].

	stateTable items: items.

	"4. Double-click to inspect element"
	stateTable whenActivatedDo: [ :selection |
		| selectedItem childOop |
		selectedItem := selection selectedItem.
		childOop := selectedItem third.
		childOop ifNotNil: [
			childOop > 20 ifTrue: [
				GbsInspector inspect: childOop session: session
			]
		].
	].
]

{ #category : 'fetching' }
GbxNSCInspector >> fetchNSCElements [
	"Fetch NSC elements from server"
	| script result |
	
	script := '[
		| nsc stream |
		nsc := Object _objectForOop: ', oop asString, '.
		stream := WriteStream on: String new.
		nsc do: [ :elem |
			| elemOop |
			elemOop := Reflection oopOf: elem.
			stream
				nextPutAll: elem printString; nextPutAll: ''::::'';
				nextPutAll: elemOop asString; lf.
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	^ self parseNSCElements: result
]

{ #category : 'fetching' }
GbxNSCInspector >> parseNSCElements: aString [
	"Parse NSC elements string into array of { printString . OOP }"
	| items lines parts |
	
	items := OrderedCollection new.
	aString ifNil: [ ^ #() ].
	
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [
			parts := line splitOn: '::::'.
			parts size >= 2 ifTrue: [
				items add: { 
					parts first. 
					(parts second asInteger > 20) ifTrue: [ parts second asInteger ] ifFalse: [ nil ]
				}
			]
		]
	].
	^ items asArray
]

{ #category : 'initialization' }
GbxNSCInspector >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone NSC Inspector';
		initialExtent: 500 @ 600.
]
