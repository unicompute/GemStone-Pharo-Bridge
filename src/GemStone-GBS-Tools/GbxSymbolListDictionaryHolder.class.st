Class {
	#name : 'GbxSymbolListDictionaryHolder',
	#superclass : 'GbxDictionaryHolder',
	#instVars : [
		'symbolListIndex'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxSymbolListDictionaryHolder class >> on: aSymbolListDictionary [
	"Create a holder for a GemStone symbol list dictionary"
	^ self new
		proxy: aSymbolListDictionary;
		yourself
]

{ #category : 'instance creation' }
GbxSymbolListDictionaryHolder class >> on: aSymbolListDictionaryForwarder [
	"Create a holder for a GemStone symbol list dictionary forwarder"
	^ self new
		proxy: aSymbolListDictionaryForwarder;
		yourself
]

{ #category : 'accessing' }
GbxSymbolListDictionaryHolder >> fetchEntries [
	"Fetch symbol list dictionary entries from GemStone"
	| script result |
	
	(session isNil or: [ proxy isNil ]) ifTrue: [ ^ #() ].
	
	script := '[
		| dict stream |
		dict := Object _objectForOop: ', proxy oop asString, '.
		stream := WriteStream on: String new.
		dict keysAndValuesDo: [ :k :v |
			stream
				nextPutAll: k asString; nextPutAll: ''::::'';
				nextPutAll: v class name; nextPutAll: ''::::'';
				nextPutAll: (Reflection oopOf: v) asString; lf.
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	entries := self parseEntries: result.
]

{ #category : 'accessing' }
GbxSymbolListDictionaryHolder >> parseEntries: aString [
	"Parse entries string into array of { key . className . OOP }"
	| items lines parts |
	
	items := OrderedCollection new.
	aString ifNil: [ ^ #() ].
	
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [
			parts := line splitOn: '::::'.
			parts size >= 3 ifTrue: [
				items add: { 
					parts first.  "symbol name"
					parts second. "class name"
					(parts third asInteger > 20) ifTrue: [ parts third asInteger ] ifFalse: [ nil ]
				}
			]
		]
	].
	^ items asArray
]

{ #category : 'accessing' }
GbxSymbolListDictionaryHolder >> printString [
	^ 'SymbolList Dictionary: ', (name ifNil: [ '<unknown>' ])
]

{ #category : 'accessing' }
GbxSymbolListDictionaryHolder >> symbolListIndex [
	^ symbolListIndex
]

{ #category : 'accessing' }
GbxSymbolListDictionaryHolder >> symbolListIndex: anInteger [
	symbolListIndex := anInteger
]
