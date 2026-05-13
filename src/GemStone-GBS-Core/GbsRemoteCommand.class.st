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

{ #category : 'private' }
GbsRemoteCommand class >> keysAndValuesOf: aDictionary do: aBlock [
	aDictionary ifNil: [ ^ self ].
	aDictionary keys asArray sorted do: [ :key |
		aBlock value: key value: (aDictionary at: key) ]
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> compatibilityScript: aString [
	"Free-form script constructor for documented compatibility paths.
	New Core and tool code should prefer blockBody:* with literal/oop bindings."
	^ self script: aString
]

{ #category : 'instance creation' }
GbsRemoteCommand class >> script: aString [
	"Compatibility-level free-form script constructor. Prefer blockBody:* APIs."
	^ self new
		script: aString;
		yourself
]

{ #category : 'executing' }
GbsRemoteCommand >> evaluateIn: aSession [
	^ aSession evaluate: script
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
