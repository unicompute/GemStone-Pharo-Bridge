Class {
	#name : 'GbxDictionaryInspector',
	#superclass : 'GbsInspector',
	#instVars : [
		'dictionarySize'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDictionaryInspector class >> inspectDictionary: dictOop session: aSession [
	"Inspect a GemStone dictionary"
	| inspector |
	
	inspector := self new.
	inspector inspectDictionaryOop: dictOop session: aSession.
	inspector open.
	^ inspector
]

{ #category : 'accessing' }
GbxDictionaryInspector >> inspectDictionaryOop: dictOop session: aSession [
	| className sizeData keysData items |
	
	oop := dictOop.
	session := aSession.
	evaluationContextOop := nil.

	"1. Get dictionary class and size"
	className := session executeAndFetch: '(Object _objectForOop: ', dictOop asString, ') class name asString'.
	sizeData := session executeAndFetch: '(Object _objectForOop: ', dictOop asString, ') size asString'.
	
	classLabel label: className, ' (size: ', sizeData, ')'.
	dictionarySize := sizeData asInteger.

	"2. Fetch keys and values"
	keysData := self fetchDictionaryEntries.
	
	"3. Build items list"
	items := OrderedCollection new.
	keysData do: [ :entry |
		items add: { 
			entry at: 1.  "key printString"
			entry at: 2.  "value printString"
			entry at: 3.  "value OOP"
		}
	].

	stateTable items: items.

	"4. Double-click to inspect value"
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
GbxDictionaryInspector >> fetchDictionaryEntries [
	"Fetch dictionary key-value pairs from server"
	| script result |
	
	script := '[
		| dict stream keys |
		dict := Object _objectForOop: ', oop asString, '.
		stream := WriteStream on: String new.
		keys := dict keys.
		keys do: [ :key |
			| val valOop |
			val := dict at: key.
			valOop := Reflection oopOf: val.
			stream
				nextPutAll: key printString; nextPutAll: ''::::'';
				nextPutAll: val printString; nextPutAll: ''::::'';
				nextPutAll: valOop asString; lf.
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	^ self parseDictionaryEntries: result
]

{ #category : 'fetching' }
GbxDictionaryInspector >> parseDictionaryEntries: aString [
	"Parse dictionary entries string into array of { key . value . valueOOP }"
	| items lines parts |
	
	items := OrderedCollection new.
	aString ifNil: [ ^ #() ].
	
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [
			parts := line splitOn: '::::'.
			parts size >= 3 ifTrue: [
				items add: { 
					parts first. 
					parts second. 
					(parts third asInteger > 20) ifTrue: [ parts third asInteger ] ifFalse: [ nil ]
				}
			]
		]
	].
	^ items asArray
]

{ #category : 'initialization' }
GbxDictionaryInspector >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Dictionary Inspector';
		initialExtent: 500 @ 600.
]
