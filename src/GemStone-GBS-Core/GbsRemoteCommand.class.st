Class {
	#name : 'GbsRemoteCommand',
	#superclass : 'Object',
	#instVars : [
		'script'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsRemoteCommand class >> blockBody: bodyString argumentScripts: argumentScripts [
	^ self
		blockBody: bodyString
		argumentNames: ((1 to: argumentScripts size) collect: [ :index | 'arg', index asString ])
		argumentScripts: argumentScripts
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> blockBody: bodyString argumentNames: argumentNames argumentScripts: argumentScripts [
	^ self
		script: (self
			blockScriptForBody: bodyString
			argumentNames: argumentNames
			argumentScripts: argumentScripts)
]

{ #category : 'private' }
GbsRemoteCommand class >> blockScriptForBody: bodyString argumentNames: argumentNames argumentScripts: argumentScripts [
	| args names |
	args := argumentScripts asArray.
	names := argumentNames asArray.
	args size = names size
		ifFalse: [ self error: 'Remote command argument names and scripts must have the same size' ].
	names do: [ :each | self validateArgumentName: each ].
	^ String streamContents: [ :stream |
		stream nextPutAll: '['.
		args
			ifEmpty: [ stream space ]
			ifNotEmpty: [
				args doWithIndex: [ :ignored :index |
					stream
						nextPutAll: ' :';
						nextPutAll: (names at: index) asString ].
				stream nextPutAll: ' | ' ].
		stream
			nextPutAll: bodyString;
			nextPutAll: ' ]'.
		args
			ifEmpty: [ stream nextPutAll: ' value' ]
			ifNotEmpty: [
				args doWithIndex: [ :argScript :index |
					index = 1
						ifTrue: [ stream nextPutAll: ' value: ' ]
						ifFalse: [ stream nextPutAll: ' value: ' ].
					stream nextPutAll: argScript asString ] ] ]
]

{ #category : 'private' }
GbsRemoteCommand class >> validateArgumentName: aString [
	| name |
	name := aString asString.
	(name isEmpty or: [ name first isDigit ]) ifTrue: [
		self error: 'Invalid remote command argument name: ', name printString ].
	(name allSatisfy: [ :ch | ch isAlphaNumeric or: [ ch = $_ ] ]) ifFalse: [
		self error: 'Invalid remote command argument name: ', name printString ].
	^ name
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> blockBody: bodyString literalArguments: argumentCollection [
	| builder |
	builder := GbsRemoteScriptBuilder new.
	^ self
		blockBody: bodyString
		argumentScripts: (argumentCollection collect: [ :each | builder literalFor: each ])
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> blockBody: bodyString literalBindings: aDictionary [
	| builder names |
	builder := GbsRemoteScriptBuilder new.
	names := aDictionary keys asArray sorted.
	^ self
		blockBody: bodyString
		argumentNames: names
		argumentScripts: (names collect: [ :each | builder literalFor: (aDictionary at: each) ])
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> blockBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary [
	| builder names scripts |
	builder := GbsRemoteScriptBuilder new.
	names := OrderedCollection new.
	scripts := OrderedCollection new.
	self
		keysAndValuesOf: oopDictionary
		do: [ :name :oop |
			names add: name.
			scripts add: (builder objectForOop: oop) ].
	self
		keysAndValuesOf: literalDictionary
		do: [ :name :value |
			names add: name.
			scripts add: (builder literalFor: value) ].
	^ self
		blockBody: bodyString
		argumentNames: names asArray
		argumentScripts: scripts asArray
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> blockBody: bodyString literalAssignments: literalDictionary oopAssignments: oopDictionary [
	| builder names scripts |
	builder := GbsRemoteScriptBuilder new.
	names := OrderedCollection new.
	scripts := OrderedCollection new.
	self
		keysAndValuesOf: oopDictionary
		do: [ :name :oop |
			self validateArgumentName: name.
			names add: name.
			scripts add: (builder objectForOop: oop) ].
	self
		keysAndValuesOf: literalDictionary
		do: [ :name :value |
			self validateArgumentName: name.
			names add: name.
			scripts add: (builder literalFor: value) ].
	^ self
		blockBody: (self
		body: bodyString
		withAssignmentsNamed: names asArray
		scripts: scripts asArray)
		argumentNames: #()
		argumentScripts: #()
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> blockBody: bodyString oopArguments: oopCollection [
	| builder |
	builder := GbsRemoteScriptBuilder new.
	^ self
		blockBody: bodyString
		argumentScripts: (oopCollection collect: [ :each | builder objectForOop: each ])
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> blockBody: bodyString oopBindings: aDictionary [
	| builder names |
	builder := GbsRemoteScriptBuilder new.
	names := aDictionary keys asArray sorted.
	^ self
		blockBody: bodyString
		argumentNames: names
		argumentScripts: (names collect: [ :each | builder objectForOop: (aDictionary at: each) ])
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> forObjectOop: anOop send: selectorSymbol [
	^ self
		forObjectOop: anOop
		send: selectorSymbol
		arguments: #()
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> forObjectOop: anOop send: selectorSymbol arguments: argumentCollection [
	^ self
		blockBody: 'object perform: selector withArguments: arguments'
		literalBindings: (Dictionary new
			at: 'arguments' put: argumentCollection asArray;
			at: 'selector' put: selectorSymbol asSymbol;
			yourself)
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> forRepositoryRoot: rootKey path: pathCollection aliasKeys: aliasKeys ensure: ensureBoolean body: bodyString literalBindings: literalDictionary [
	^ self
		forRepositoryRoot: rootKey
		path: pathCollection
		aliasKeys: aliasKeys
		ensure: ensureBoolean
		body: bodyString
		literalBindings: literalDictionary
		oopBindings: Dictionary new
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> forRepositoryRoot: rootKey path: pathCollection aliasKeys: aliasKeys ensure: ensureBoolean body: bodyString literalBindings: literalDictionary oopBindings: oopDictionary [
	| bindings preamble |
	bindings := Dictionary new.
	self
		keysAndValuesOf: literalDictionary
		do: [ :key :value | bindings at: key put: value ].
	bindings
		at: 'aliasKeys' put: aliasKeys asArray;
		at: 'path' put: pathCollection asArray;
		at: 'rootKey' put: rootKey asSymbol.
	preamble := ensureBoolean
		ifTrue: [ self repositoryRootEnsuringPreamble ]
		ifFalse: [ self repositoryRootReadingPreamble ].
	^ self
		blockBody: preamble, bodyString
		literalBindings: bindings
		oopBindings: oopDictionary
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> forSymbolDictionaryNamed: dictionaryName body: bodyString literalBindings: literalDictionary [
	| bindings |
	bindings := Dictionary new.
	self
		keysAndValuesOf: literalDictionary
		do: [ :key :value | bindings at: key put: value ].
	bindings at: 'dictionaryName' put: dictionaryName asSymbol.
	^ self
		blockBody: self symbolDictionaryPreamble, bodyString
		literalBindings: bindings
		oopBindings: Dictionary new
]

{ #category : 'private' }
GbsRemoteCommand class >> keysAndValuesOf: aDictionary do: aBlock [
	aDictionary ifNil: [ ^ self ].
	aDictionary keys asArray sorted do: [ :key |
		aBlock value: key value: (aDictionary at: key) ]
]

{ #category : 'private' }
GbsRemoteCommand class >> body: bodyString withAssignmentsNamed: names scripts: scripts [
	^ String streamContents: [ :stream |
		names isEmpty ifFalse: [
			stream nextPutAll: '| '.
			names do: [ :each |
				stream
					nextPutAll: each asString;
					space ].
			stream
				nextPutAll: '|';
				cr.
			names doWithIndex: [ :each :index |
				stream
					nextPutAll: each asString;
					nextPutAll: ' := ';
					nextPutAll: (scripts at: index) asString;
					nextPutAll: '.';
					cr ] ].
		stream nextPutAll: bodyString ]
]

{ #category : 'private' }
GbsRemoteCommand class >> repositoryRootEnsuringPreamble [
	^ '| root current next container |
	root := UserGlobals
		at: rootKey
		ifAbsent: [
			| existing |
			existing := nil.
			aliasKeys do: [ :each |
				existing ifNil: [
					existing := UserGlobals at: each ifAbsent: [ nil ] ] ].
			existing ifNil: [ Dictionary new ] ifNotNil: [ existing ] ].
	UserGlobals at: rootKey put: root.
	aliasKeys do: [ :each | UserGlobals at: each put: root ].
	current := root.
	path do: [ :each |
		next := current at: each ifAbsentPut: [ Dictionary new ].
		(next isKindOf: Dictionary)
			ifFalse: [ Error signal: ''Repository namespace path contains a non-dictionary value.'' ].
		current := next ].
	container := current.
	'
]

{ #category : 'private' }
GbsRemoteCommand class >> repositoryRootReadingPreamble [
	^ '| root current container |
	root := UserGlobals
		at: rootKey
		ifAbsent: [
			| existing |
			existing := nil.
			aliasKeys do: [ :each |
				existing ifNil: [
					existing := UserGlobals at: each ifAbsent: [ nil ] ] ].
			existing ifNil: [ Dictionary new ] ifNotNil: [ existing ] ].
	UserGlobals at: rootKey put: root.
	aliasKeys do: [ :each | UserGlobals at: each put: root ].
	current := root.
	path do: [ :each |
		current ifNotNil: [
			current := ((current isKindOf: Dictionary) and: [ current includesKey: each ])
				ifTrue: [ current at: each ]
				ifFalse: [ nil ] ] ].
	container := current.
	'
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> compatibilityScript: aString [
	"Free-form script constructor for documented compatibility paths.
	New Core and tool code should prefer blockBody:* with literal/oop bindings."
	^ self script: aString
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> staticExpression: aString [
	"Static no-argument remote expression. Use blockBody:* when binding Pharo values."
	^ self script: aString
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> script: aString [
	"Compatibility-level free-form script constructor. Prefer blockBody:* APIs."
	^ self new
		script: aString;
		yourself
]

{ #category : 'private' }
GbsRemoteCommand class >> symbolDictionaryPreamble [
	^ '| association root |
	association := GsSession currentSession resolveSymbol: dictionaryName.
	root := association ifNil: [ nil ] ifNotNil: [
		(association respondsTo: #value)
			ifTrue: [ association value ]
			ifFalse: [ association ] ].
	'
]

{ #category : 'executing' }
GbsRemoteCommand >> executeAndFetchIn: aSession context: anOop [
	^ aSession executeAndFetch: script context: anOop
]

{ #category : 'executing' }
GbsRemoteCommand >> executeAndFetchObjectIn: aSession [
	^ aSession executeScriptAndFetchObject: script
]

{ #category : 'executing' }
GbsRemoteCommand >> fetchUsingCompatibilitySession: aSession context: anOop [
	"Compatibility fallback for Original sessions that do not yet expose fetchRemoteCommand:context:."
	^ self executeAndFetchIn: aSession context: anOop
]

{ #category : 'executing' }
GbsRemoteCommand >> executeAndReturnOopIn: aSession [
	^ aSession executeScriptAndReturnOop: script
]

{ #category : 'printing' }
GbsRemoteCommand >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: script printString;
		nextPut: $)
]

{ #category : 'accessing' }
GbsRemoteCommand >> script [
	^ script
]

{ #category : 'accessing' }
GbsRemoteCommand >> script: aString [
	script := aString asString
]
