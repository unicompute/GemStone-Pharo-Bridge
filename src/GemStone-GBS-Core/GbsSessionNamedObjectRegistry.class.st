Class {
	#name : 'GbsSessionNamedObjectRegistry',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsSessionNamedObjectRegistry class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'accessing' }
GbsSessionNamedObjectRegistry >> session [
	^ session
]

{ #category : 'accessing' }
GbsSessionNamedObjectRegistry >> session: aSession [
	session := aSession
]

{ #category : 'lookup' }
GbsSessionNamedObjectRegistry >> namedObjectAt: aName [
	^ self
		namedObjectAt: aName
		ifAbsent: [ self error: aName asString , ' not defined' ]
]

{ #category : 'lookup' }
GbsSessionNamedObjectRegistry >> namedObjectAt: aName ifAbsent: aBlock [
	| symbol targetSymbol cached |
	symbol := self normalizedNamedObjectName: aName.
	cached := self namedObjectCache at: symbol ifAbsent: [ nil ].
	cached ifNotNil: [ ^ cached ].
	targetSymbol := self namedObjectAutoloadTargetFor: symbol.
	cached := self namedObjectCache at: targetSymbol ifAbsent: [ nil ].
	cached ifNotNil: [
		symbol ~= targetSymbol ifTrue: [ self namedObjectCache at: symbol put: cached ].
		^ cached ].
	cached := session resolveSymbol: targetSymbol ifAbsent: [ ^ aBlock value ].
	self namedObjectCache at: targetSymbol put: cached.
	symbol ~= targetSymbol ifTrue: [ self namedObjectCache at: symbol put: cached ].
	^ cached
]

{ #category : 'cache' }
GbsSessionNamedObjectRegistry >> namedObjectCache [
	^ (session class weakRegistryNamed: #GbsSessionNamedObjectCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'cache' }
GbsSessionNamedObjectRegistry >> clearNamedObjectCache [
	(session class weakRegistryNamed: #GbsSessionNamedObjectCaches)
		at: session
		put: Dictionary new.
	^ session
]

{ #category : 'autoloads' }
GbsSessionNamedObjectRegistry >> namedObjectAutoloadRegistry [
	^ (session class weakRegistryNamed: #GbsSessionNamedObjectAutoloadRegistries)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'autoloads' }
GbsSessionNamedObjectRegistry >> clearNamedObjectAutoloads [
	(session class weakRegistryNamed: #GbsSessionNamedObjectAutoloadRegistries)
		at: session
		put: Dictionary new.
	^ session
]

{ #category : 'autoloads' }
GbsSessionNamedObjectRegistry >> registerNamedObjectAutoload: aName [
	^ self registerNamedObjectAutoload: aName remote: aName
]

{ #category : 'autoloads' }
GbsSessionNamedObjectRegistry >> registerNamedObjectAutoload: localName remote: remoteName [
	| localSymbol remoteSymbol |
	localSymbol := self normalizedNamedObjectName: localName.
	remoteSymbol := self normalizedNamedObjectName: remoteName.
	self namedObjectAutoloadRegistry at: localSymbol put: remoteSymbol.
	^ remoteSymbol
]

{ #category : 'autoloads' }
GbsSessionNamedObjectRegistry >> unregisterNamedObjectAutoload: aName [
	self
		namedObjectAutoloadRegistry
		removeKey: (self normalizedNamedObjectName: aName)
		ifAbsent: [ ].
	^ session
]

{ #category : 'autoloads' }
GbsSessionNamedObjectRegistry >> hasNamedObjectAutoloadNamed: aName [
	^ self
		namedObjectAutoloadRegistry
		includesKey: (self normalizedNamedObjectName: aName)
]

{ #category : 'autoloads' }
GbsSessionNamedObjectRegistry >> namedObjectAutoloadTargetFor: aName [
	| symbol |
	symbol := self normalizedNamedObjectName: aName.
	^ self namedObjectAutoloadRegistry at: symbol ifAbsent: [ symbol ]
]

{ #category : 'autoloads' }
GbsSessionNamedObjectRegistry >> namedObjectAutoloadEntries [
	^ self namedObjectAutoloadRegistry associations asArray sort: [ :a :b |
		a key asString <= b key asString ]
]

{ #category : 'autoloads' }
GbsSessionNamedObjectRegistry >> namedObjectAutoloadKeys [
	^ (self namedObjectAutoloadEntries collect: [ :each | each key ]) asArray
]

{ #category : 'autoloads' }
GbsSessionNamedObjectRegistry >> namedObjectAutoloadReportText [
	| entries |
	entries := self namedObjectAutoloadEntries.
	entries isEmpty ifTrue: [ ^ 'No named-object autoload registrations.' ].
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Named Object Autoload'; cr; cr.
		entries do: [ :association |
			stream
				nextPutAll: association key asString;
				nextPutAll: ' -> ';
				nextPutAll: association value asString;
				cr ] ]
]

{ #category : 'cache' }
GbsSessionNamedObjectRegistry >> hasCachedNamedObjectNamed: aName [
	| symbol |
	symbol := self normalizedNamedObjectName: aName.
	^ self namedObjectCache includesKey: symbol
]

{ #category : 'private' }
GbsSessionNamedObjectRegistry >> normalizedNamedObjectName: aName [
	^ aName isSymbol
		ifTrue: [ aName ]
		ifFalse: [ aName asString asSymbol ]
]

{ #category : 'cache' }
GbsSessionNamedObjectRegistry >> namedObjectCacheEntries [
	^ self namedObjectCache associations asArray sort: [ :a :b |
		a key asString <= b key asString ]
]

{ #category : 'cache' }
GbsSessionNamedObjectRegistry >> namedObjectCacheKeys [
	^ (self namedObjectCacheEntries collect: [ :each | each key ]) asArray
]

{ #category : 'cache' }
GbsSessionNamedObjectRegistry >> namedObjectCacheReportText [
	| entries |
	entries := self namedObjectCacheEntries.
	entries isEmpty ifTrue: [ ^ 'No named objects cached.' ].
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Named Object Cache'; cr; cr.
		entries do: [ :association |
			| value |
			value := association value.
			stream nextPutAll: association key asString.
			(value respondsTo: #oop)
				ifTrue: [
					stream
						nextPutAll: ' -> oop ';
						nextPutAll: value oop asString ]
				ifFalse: [
					stream
						nextPutAll: ' -> ';
						nextPutAll: value printString ].
			stream cr ] ]
]
