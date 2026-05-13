Class {
	#name : 'GbsMaglevSymbolDictionaryFacade',
	#superclass : 'Object',
	#instVars : [
		'session',
		'dictionaryName'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsMaglevSymbolDictionaryFacade class >> on: aSession name: aName [
	^ self new
		session: aSession;
		dictionaryName: aName;
		yourself
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> associations [
	| associations |
	associations := self fetchObjectCommandBody: '| items |
	items := OrderedCollection new.
	root ifNotNil: [
		root keysAndValuesDo: [ :key :value | items add: (key -> value) ] ].
	items asArray'
		literalBindings: Dictionary new.
	associations ifNil: [ ^ #() ].
	^ associations collect: [ :each |
		each key -> (self materializeValue: each value) ]
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> at: aKey [
	^ self
		at: aKey
		ifAbsent: [ self error: aKey printString , ' not found in ', self name ]
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> at: aKey ifAbsent: aBlock [
	| result |
	result := self fetchObjectCommandBody: 'root ifNil: [ nil ] ifNotNil: [
	(root respondsTo: #objectNamed:ifAbsent:)
		ifTrue: [ root objectNamed: key ifAbsent: [ nil ] ]
		ifFalse: [ root at: key ifAbsent: [ nil ] ] ]'
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			yourself).
	^ result
		ifNil: [ aBlock value ]
		ifNotNil: [ self materializeValue: result ]
]

{ #category : 'mutating' }
GbsMaglevSymbolDictionaryFacade >> at: aKey put: aValue [
	| result |
	result := self fetchObjectCommandBody: 'root ifNil: [ nil ] ifNotNil: [
	root at: key put: value.
	value ]'
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			at: 'value' put: aValue;
			yourself).
	^ self materializeValue: result
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> includesKey: aKey [
	^ self fetchObjectCommandBody: 'root ifNil: [ false ] ifNotNil: [
	(root respondsTo: #objectNamed:ifAbsent:)
		ifTrue: [ (root objectNamed: key ifAbsent: [ nil ]) notNil ]
		ifFalse: [ root includesKey: key ] ]'
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			yourself)
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> isEmpty [
	^ self size = 0
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> keys [
	^ self fetchObjectCommandBody: '| items |
	items := OrderedCollection new.
	root ifNotNil: [
		root keysAndValuesDo: [ :key :value | items add: key ] ].
	items asArray'
		literalBindings: Dictionary new
]

{ #category : 'private' }
GbsMaglevSymbolDictionaryFacade >> materializeValue: anObject [
	^ session materializeMaglevRuntimeValue: anObject
]

{ #category : 'accessing' }
GbsMaglevSymbolDictionaryFacade >> name [
	^ dictionaryName asString
]

{ #category : 'printing' }
GbsMaglevSymbolDictionaryFacade >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self name;
		nextPutAll: ')'
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> reportText [
	| associations |
	associations := self associations.
	associations isEmpty ifTrue: [
		^ self name , String cr , String cr , '(empty)' ].
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self name;
			cr; cr.
		associations do: [ :each |
			stream
				nextPutAll: each key asString;
				nextPutAll: ' -> ';
				nextPutAll: each value printString;
				cr ] ]
]

{ #category : 'mutating' }
GbsMaglevSymbolDictionaryFacade >> removeKey: aKey [
	^ self
		removeKey: aKey
		ifAbsent: [ self error: aKey printString , ' not found in ', self name ]
]

{ #category : 'mutating' }
GbsMaglevSymbolDictionaryFacade >> removeKey: aKey ifAbsent: aBlock [
	| marker result |
	marker := '__gbs_missing__'.
	result := self fetchObjectCommandBody: '| value |
	root ifNil: [ missingMarker ] ifNotNil: [
		value := (root respondsTo: #objectNamed:ifAbsent:)
			ifTrue: [ root objectNamed: key ifAbsent: [ missingMarker ] ]
			ifFalse: [ root at: key ifAbsent: [ missingMarker ] ].
		value = missingMarker ifTrue: [ value ] ifFalse: [
			root removeKey: key ifAbsent: [ ].
			value ] ]'
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			at: 'missingMarker' put: marker;
			yourself).
	result = marker ifTrue: [ ^ aBlock value ].
	^ self materializeValue: result
]

{ #category : 'accessing' }
GbsMaglevSymbolDictionaryFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsMaglevSymbolDictionaryFacade >> session: aSession [
	session := aSession
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> size [
	^ self fetchObjectCommandBody: 'root ifNil: [ 0 ] ifNotNil: [ root size ]'
		literalBindings: Dictionary new
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> values [
	^ self associations collect: [ :each | each value ]
]

{ #category : 'private' }
GbsMaglevSymbolDictionaryFacade >> fetchObjectCommandBody: bodyString literalBindings: literalDictionary [
	^ session fetchRemoteCommand: (GbsRemoteCommand
		forSymbolDictionaryNamed: dictionaryName
		body: bodyString
		literalBindings: literalDictionary)
]

{ #category : 'accessing' }
GbsMaglevSymbolDictionaryFacade >> dictionaryName: anObject [
	dictionaryName := anObject ifNil: [ #UserGlobals ] ifNotNil: [ anObject asSymbol ]
]
