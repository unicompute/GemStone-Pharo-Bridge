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
	associations := session executeScriptAndFetchObject: self associationsScript.
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
	result := session executeScriptAndFetchObject: (self atScriptFor: aKey).
	^ result
		ifNil: [ aBlock value ]
		ifNotNil: [ self materializeValue: result ]
]

{ #category : 'mutating' }
GbsMaglevSymbolDictionaryFacade >> at: aKey put: aValue [
	| result |
	result := session executeScriptAndFetchObject: (self atPutScriptFor: aKey value: aValue).
	^ self materializeValue: result
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> includesKey: aKey [
	^ session executeScriptAndFetchObject: (self includesKeyScriptFor: aKey)
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> isEmpty [
	^ self size = 0
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> keys [
	^ session executeScriptAndFetchObject: self keysScript
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
	result := session executeScriptAndFetchObject: (self removeKeyScriptFor: aKey missingMarker: marker).
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
	^ session executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream
			nextPutAll: '[:root | root ifNil: [ 0 ] ifNotNil: [ root size ] ] value: ';
			nextPutAll: self rootScript ])
]

{ #category : 'querying' }
GbsMaglevSymbolDictionaryFacade >> values [
	^ self associations collect: [ :each | each value ]
]

{ #category : 'private' }
GbsMaglevSymbolDictionaryFacade >> associationsScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:root | | items |
	items := OrderedCollection new.
	root ifNotNil: [
		root keysAndValuesDo: [ :key :value | items add: (key -> value) ] ].
	items asArray ] value: ';
			nextPutAll: self rootScript ]
]

{ #category : 'private' }
GbsMaglevSymbolDictionaryFacade >> atPutScriptFor: aKey value: aValue [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:root :key :value |
	root ifNil: [ nil ] ifNotNil: [ root at: key put: value. value ] ] value: ';
			nextPutAll: self rootScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aKey);
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aValue) ]
]

{ #category : 'private' }
GbsMaglevSymbolDictionaryFacade >> atScriptFor: aKey [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:root :key |
	root ifNil: [ nil ] ifNotNil: [
		(root respondsTo: #objectNamed:ifAbsent:)
			ifTrue: [ root objectNamed: key ifAbsent: [ nil ] ]
			ifFalse: [ root at: key ifAbsent: [ nil ] ] ] ] value: ';
			nextPutAll: self rootScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aKey) ]
]

{ #category : 'private' }
GbsMaglevSymbolDictionaryFacade >> includesKeyScriptFor: aKey [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:root :key |
	root ifNil: [ false ] ifNotNil: [
		(root respondsTo: #objectNamed:ifAbsent:)
			ifTrue: [ (root objectNamed: key ifAbsent: [ nil ]) notNil ]
			ifFalse: [ root includesKey: key ] ] ] value: ';
			nextPutAll: self rootScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aKey) ]
]

{ #category : 'private' }
GbsMaglevSymbolDictionaryFacade >> keysScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:root | | items |
	items := OrderedCollection new.
	root ifNotNil: [
		root keysAndValuesDo: [ :key :value | items add: key ] ].
	items asArray ] value: ';
			nextPutAll: self rootScript ]
]

{ #category : 'private' }
GbsMaglevSymbolDictionaryFacade >> removeKeyScriptFor: aKey missingMarker: aMarkerString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:root :key | | value |
	root ifNil: [ ';
			nextPutAll: aMarkerString storeString;
			nextPutAll: ' ] ifNotNil: [
		value := (root respondsTo: #objectNamed:ifAbsent:)
			ifTrue: [ root objectNamed: key ifAbsent: [ ';
			nextPutAll: aMarkerString storeString;
			nextPutAll: ' ] ]
			ifFalse: [ root at: key ifAbsent: [ ';
			nextPutAll: aMarkerString storeString;
			nextPutAll: ' ] ].
		value = ';
			nextPutAll: aMarkerString storeString;
			nextPutAll: ' ifTrue: [ value ] ifFalse: [
			root removeKey: key ifAbsent: [ ].
			value ] ] ] value: ';
			nextPutAll: self rootScript;
			nextPutAll: ' value: ';
			nextPutAll: (session marshalArgumentToScript: aKey) ]
]

{ #category : 'private' }
GbsMaglevSymbolDictionaryFacade >> rootScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:symbol | | association |
	association := GsSession currentSession resolveSymbol: symbol.
	association ifNil: [ nil ] ifNotNil: [ association value ] ] value: ';
			nextPutAll: (session marshalArgumentToScript: dictionaryName asSymbol) ]
]

{ #category : 'accessing' }
GbsMaglevSymbolDictionaryFacade >> dictionaryName: anObject [
	dictionaryName := anObject ifNil: [ #UserGlobals ] ifNotNil: [ anObject asSymbol ]
]
