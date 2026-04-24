Class {
	#name : 'GbsRemoteClassMirror',
	#superclass : 'Object',
	#instVars : [
		'session',
		'classReference',
		'classMetadata',
		'instanceProtocolEntries',
		'classProtocolEntries'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsRemoteClassMirror class >> on: aSession class: aClassOrName [
	^ self new
		session: aSession;
		classReference: aClassOrName;
		yourself
]

{ #category : 'accessing' }
GbsRemoteClassMirror >> classMetadata [
	^ classMetadata ifNil: [
		classMetadata := session executeScriptAndFetchObject: self classMetadataScript ]
]

{ #category : 'accessing' }
GbsRemoteClassMirror >> classReference [
	^ classReference
]

{ #category : 'accessing' }
GbsRemoteClassMirror >> classReference: aClassOrName [
	classReference := aClassOrName
]

{ #category : 'private' }
GbsRemoteClassMirror >> classExpression [
	^ session repository classExpressionFor: classReference
]

{ #category : 'private' }
GbsRemoteClassMirror >> classMetadataScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| cls superclassName packageName categoryName history total versionIndex | cls := ';
			nextPutAll: self classExpression;
			nextPutAll: '. cls ifNil: [ nil ] ifNotNil: ['.
		stream nextPutAll: ' superclassName := [ cls superclass ifNil: [ nil ] ifNotNil: [ cls superclass name asString ] ] on: Error do: [ nil ].'.
		stream nextPutAll: ' packageName := [ (cls respondsTo: #package) ifTrue: [ cls package ifNil: [ nil ] ifNotNil: [ cls package name asString ] ] ifFalse: [ nil ] ] on: Error do: [ nil ].'.
		stream nextPutAll: ' categoryName := [ (cls respondsTo: #category) ifTrue: [ cls category asString ] ifFalse: [ nil ] ] on: Error do: [ nil ].'.
		stream nextPutAll: ' history := [ cls classHistory ] on: Error do: [ #() ].'.
		stream nextPutAll: ' total := history ifNil: [ nil ] ifNotNil: [ history size ].'.
		stream nextPutAll: ' versionIndex := (history isNil or: [ history isEmpty ]) ifTrue: [ nil ] ifFalse: [ [ history indexOf: cls ] on: Error do: [ nil ] ].'.
		stream nextPutAll: ' Array with: cls asOop with: cls name asString with: superclassName with: packageName with: categoryName with: versionIndex with: total ]' ]
]

{ #category : 'querying' }
GbsRemoteClassMirror >> classMethodMirrorAt: aSelector [
	^ GbsRemoteMethodMirror
		on: session
		class: (self proxy ifNil: [ classReference ])
		selector: aSelector
		classSide: true
]

{ #category : 'querying' }
GbsRemoteClassMirror >> classMethodObjectAt: aSelector [
	^ (self classMethodMirrorAt: aSelector) asMethodObject
]

{ #category : 'querying' }
GbsRemoteClassMirror >> classMethodMirrors [
	^ self classSelectors collect: [ :each |
		self classMethodMirrorAt: each ]
]

{ #category : 'querying' }
GbsRemoteClassMirror >> classProtocolForSelector: aSelector [
	^ self
		protocolForSelector: aSelector
		inEntries: self classProtocols
]

{ #category : 'querying' }
GbsRemoteClassMirror >> classProtocols [
	^ classProtocolEntries ifNil: [
		classProtocolEntries := self protocolEntriesForClassSide: true ]
]

{ #category : 'querying' }
GbsRemoteClassMirror >> classSelectors [
	^ self selectorSymbolsFromProtocolEntries: self classProtocols
]

{ #category : 'querying' }
GbsRemoteClassMirror >> exists [
	^ self classMetadata notNil
]

{ #category : 'querying' }
GbsRemoteClassMirror >> categoryName [
	| metadata |
	metadata := self classMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 5 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteClassMirror >> classHistory [
	^ session classHistoryOf: (self proxy ifNil: [ classReference ])
]

{ #category : 'querying' }
GbsRemoteClassMirror >> instanceMethodMirrors [
	^ self instanceSelectors collect: [ :each |
		self methodMirrorAt: each ]
]

{ #category : 'querying' }
GbsRemoteClassMirror >> instanceProtocols [
	^ instanceProtocolEntries ifNil: [
		instanceProtocolEntries := self protocolEntriesForClassSide: false ]
]

{ #category : 'querying' }
GbsRemoteClassMirror >> instanceSelectors [
	^ self selectorSymbolsFromProtocolEntries: self instanceProtocols
]

{ #category : 'querying' }
GbsRemoteClassMirror >> methodMirrorAt: aSelector [
	^ GbsRemoteMethodMirror
		on: session
		class: (self proxy ifNil: [ classReference ])
		selector: aSelector
		classSide: false
]

{ #category : 'querying' }
GbsRemoteClassMirror >> methodObjectAt: aSelector [
	^ (self methodMirrorAt: aSelector) asMethodObject
]

{ #category : 'querying' }
GbsRemoteClassMirror >> name [
	| metadata |
	metadata := self classMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 2
]

{ #category : 'querying' }
GbsRemoteClassMirror >> oop [
	| metadata |
	metadata := self classMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 1
]

{ #category : 'querying' }
GbsRemoteClassMirror >> packageName [
	| metadata |
	metadata := self classMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 4 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteClassMirror >> protocolEntriesForClassSide: aBoolean [
	^ session
		executeScriptAndFetchObject: (self protocolEntriesScriptForClassSide: aBoolean)
]

{ #category : 'private' }
GbsRemoteClassMirror >> protocolEntriesScriptForClassSide: aBoolean [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| cls behavior byProtocol entries | cls := ';
			nextPutAll: self classExpression;
			nextPutAll: '. cls ifNil: [ #() ] ifNotNil: [ behavior := '.
		aBoolean
			ifTrue: [ stream nextPutAll: 'cls class' ]
			ifFalse: [ stream nextPutAll: 'cls' ].
		stream nextPutAll: '. byProtocol := Dictionary new. behavior methodDict keys asSortedCollection do: [ :eachSelector | | protocol selectors | protocol := [ behavior categoryOfSelector: eachSelector ] on: Error do: [ nil ]. protocol ifNil: [ protocol := ''as yet unclassified'' ]. selectors := byProtocol at: protocol asString ifAbsentPut: [ OrderedCollection new ]. selectors add: eachSelector asString ]. entries := OrderedCollection new. (byProtocol keys asSortedCollection) do: [ :protocol | entries add: (Array with: protocol with: ((byProtocol at: protocol) asSortedCollection asArray)) ]. entries asArray ]'
	]
]

{ #category : 'querying' }
GbsRemoteClassMirror >> protocolForSelector: aSelector [
	^ self
		protocolForSelector: aSelector
		inEntries: self instanceProtocols
]

{ #category : 'private' }
GbsRemoteClassMirror >> protocolForSelector: aSelector inEntries: protocolEntries [
	| selectorString |
	selectorString := aSelector asString.
	protocolEntries do: [ :entry |
		((entry at: 2 ifAbsent: [ #() ]) anySatisfy: [ :each |
			each asString = selectorString ]) ifTrue: [
			^ entry at: 1 ] ].
	^ nil
]

{ #category : 'querying' }
GbsRemoteClassMirror >> proxy [
	| oopValue |
	oopValue := self oop.
	oopValue ifNil: [ ^ nil ].
	^ session objectForOop: oopValue
]

{ #category : 'private' }
GbsRemoteClassMirror >> selectorSymbolsFromProtocolEntries: protocolEntries [
	| selectors |
	selectors := OrderedCollection new.
	protocolEntries do: [ :entry |
		(entry at: 2 ifAbsent: [ #() ]) do: [ :each |
			selectors add: each asString asSymbol ] ].
	^ selectors asArray
]

{ #category : 'accessing' }
GbsRemoteClassMirror >> session [
	^ session
]

{ #category : 'accessing' }
GbsRemoteClassMirror >> session: aSession [
	session := aSession
]

{ #category : 'querying' }
GbsRemoteClassMirror >> numberOfVersions [
	| metadata |
	metadata := self classMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 7 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteClassMirror >> superclassName [
	| metadata |
	metadata := self classMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 3 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteClassMirror >> version [
	| metadata |
	metadata := self classMetadata.
	metadata ifNil: [ ^ nil ].
	^ metadata at: 6 ifAbsent: [ nil ]
]
