Class {
	#name : 'GbxDictionaryHolder',
	#superclass : 'GbxDelegate',
	#instVars : [
		'name',
		'proxy',
		'session',
		'entries'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDictionaryHolder class >> name: aString proxy: aProxy [
	^ self new
		name: aString;
		proxy: aProxy;
		yourself
]

{ #category : 'instance creation' }
GbxDictionaryHolder class >> name: aString proxy: aProxy session: aSession [
	^ self new
		name: aString;
		proxy: aProxy;
		session: aSession;
		yourself
]

{ #category : 'instance creation' }
GbxDictionaryHolder class >> on: aDictionary [
	"Create a holder for a GemStone dictionary"
	^ self new
		proxy: aDictionary;
		yourself
]

{ #category : 'comparing' }
GbxDictionaryHolder >> = anObject [
	^ (anObject isKindOf: GbxDictionaryHolder)
		and: [ name = anObject name ]
]

{ #category : 'accessing' }
GbxDictionaryHolder >> asString [
	^ name ifNil: [ '<unknown dictionary>' ]
]

{ #category : 'accessing' }
GbxDictionaryHolder >> at: key [
	"Get value at key from remote dictionary"
	| script |
	
	session ifNil: [ ^ nil ].
	
	script := '[
		| dict |
		dict := Object _objectForOop: ', proxy oop asString, '.
		dict at: ', key asString, ' ifAbsent: [ nil ]
	] value'.
	
	^ session executeAndFetch: script
]

{ #category : 'accessing' }
GbxDictionaryHolder >> at: key put: value [
	"Put value at key in remote dictionary"
	| script |
	
	session ifNil: [ ^ nil ].
	
	script := '[
		| dict |
		dict := Object _objectForOop: ', proxy oop asString, '.
		dict at: ', key asString, ' put: ', value asString, '
	] value'.
	
	^ session executeAndFetch: script
]

{ #category : 'accessing' }
GbxDictionaryHolder >> entries [
	^ entries ifNil: [ 
		self fetchEntries.
		entries 
	]
]

{ #category : 'accessing' }
GbxDictionaryHolder >> fetchEntries [
	"Fetch dictionary entries from GemStone"
	| script result |
	
	(session isNil or: [ proxy isNil ]) ifTrue: [ ^ #() ].
	
	script := '[
		| dict stream |
		dict := Object _objectForOop: ', proxy oop asString, '.
		stream := WriteStream on: String new.
		dict keysAndValuesDo: [ :k :v |
			stream
				nextPutAll: k printString; nextPutAll: ''::::'';
				nextPutAll: v printString; lf.
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	entries := self parseEntries: result.
]

{ #category : 'accessing' }
GbxDictionaryHolder >> hash [
	^ name hash
]

{ #category : 'accessing' }
GbxDictionaryHolder >> keys [
	"Get all keys from remote dictionary"
	| script |
	
	session ifNil: [ ^ #() ].
	
	script := '[
		| dict |
		dict := Object _objectForOop: ', proxy oop asString, '.
		dict keys
	] value'.
	
	^ session executeAndFetch: script
]

{ #category : 'accessing' }
GbxDictionaryHolder >> name [
	^ name
]

{ #category : 'accessing' }
GbxDictionaryHolder >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GbxDictionaryHolder >> parseEntries: aString [
	"Parse entries string into array of associations"
	| items lines parts |
	
	items := OrderedCollection new.
	aString ifNil: [ ^ #() ].
	
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [
			parts := line splitOn: '::::'.
			parts size >= 2 ifTrue: [
				items add: (parts first -> parts second)
			]
		]
	].
	^ items asArray
]

{ #category : 'accessing' }
GbxDictionaryHolder >> printString [
	^ name ifNil: [ '<unknown dictionary>' ]
]

{ #category : 'accessing' }
GbxDictionaryHolder >> proxy [
	^ proxy
]

{ #category : 'accessing' }
GbxDictionaryHolder >> proxy: aProxy [
	proxy := aProxy
]

{ #category : 'accessing' }
GbxDictionaryHolder >> session [
	^ session
]

{ #category : 'accessing' }
GbxDictionaryHolder >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxDictionaryHolder >> size [
	"Get dictionary size from GemStone"
	| script |
	
	session ifNil: [ ^ 0 ].
	
	script := '[
		| dict |
		dict := Object _objectForOop: ', proxy oop asString, '.
		dict size
	] value'.
	
	^ session executeAndFetch: script
]
