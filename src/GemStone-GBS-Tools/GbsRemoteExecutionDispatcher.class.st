"Dispatches debugger remote fetches through GbsRemoteCommand when Core is loaded.
The Original load group intentionally omits Core, so its executeAndFetch: fallback is kept here as the explicit compatibility boundary."
Class {
	#name : 'GbsRemoteExecutionDispatcher',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'execution' }
GbsRemoteExecutionDispatcher class >> fetchScript: scriptString in: aSession context: contextOop [
	| commandClass command |
	commandClass := Smalltalk at: #GbsRemoteCommand ifAbsent: [ nil ].
	(commandClass notNil and: [ aSession respondsTo: #fetchRemoteCommand:context: ])
		ifTrue: [
			command := commandClass script: scriptString.
			^ aSession fetchRemoteCommand: command context: contextOop ].
	^ self
		fetchScriptUsingOriginalCompatibility: scriptString
		in: aSession
		context: contextOop
]

{ #category : 'execution' }
GbsRemoteExecutionDispatcher class >> fetchCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary in: aSession context: contextOop [
	| commandClass command |
	commandClass := Smalltalk at: #GbsRemoteCommand ifAbsent: [ nil ].
	(commandClass notNil and: [ aSession respondsTo: #fetchRemoteCommand:context: ])
		ifTrue: [
			command := self
				remoteCommandClass: commandClass
				body: bodyString
				literalBindings: literalDictionary
				oopBindings: oopDictionary.
			^ aSession fetchRemoteCommand: command context: contextOop ].
	^ self
		fetchScriptUsingOriginalCompatibility:
			(self
				compatibilityCommandScriptForBody: bodyString
				literalBindings: literalDictionary
				oopBindings: oopDictionary)
		in: aSession
		context: contextOop
]

{ #category : 'private' }
GbsRemoteExecutionDispatcher class >> compatibilityCommandScriptForBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary [
	| names scripts |
	names := OrderedCollection new.
	scripts := OrderedCollection new.
	self
		keysAndValuesOf: oopDictionary
		do: [ :name :oop |
			names add: name.
			scripts add: (self objectScriptForOop: oop) ].
	self
		keysAndValuesOf: literalDictionary
		do: [ :name :value |
			names add: name.
			scripts add: (self literalScriptForCompatibility: value) ].
	^ self
		commandScriptForBody: bodyString
		argumentNames: names asArray
		argumentScripts: scripts asArray
]

{ #category : 'private' }
GbsRemoteExecutionDispatcher class >> commandScriptForBody: bodyString argumentNames: argumentNames argumentScripts: argumentScripts [
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
				names do: [ :name |
					stream
						nextPutAll: ' :';
						nextPutAll: name asString ].
				stream nextPutAll: ' | ' ].
		stream
			nextPutAll: bodyString;
			nextPutAll: ' ]'.
		args do: [ :argScript |
			stream
				nextPutAll: ' value: ';
				nextPutAll: argScript asString ] ]
]

{ #category : 'execution' }
GbsRemoteExecutionDispatcher class >> fetchScriptUsingOriginalCompatibility: scriptString in: aSession context: contextOop [
	"Original compatibility fallback. Core/MagLev loads should use GbsRemoteCommand through fetchScript:in:context:."
	^ aSession executeAndFetch: scriptString context: contextOop
]

{ #category : 'private' }
GbsRemoteExecutionDispatcher class >> keysAndValuesOf: aDictionary do: aBlock [
	aDictionary ifNil: [ ^ self ].
	aDictionary keys asArray sorted do: [ :key |
		aBlock value: key value: (aDictionary at: key) ]
]

{ #category : 'private' }
GbsRemoteExecutionDispatcher class >> literalScriptForCompatibility: anObject [
	anObject ifNil: [ ^ 'nil' ].
	anObject == true ifTrue: [ ^ 'true' ].
	anObject == false ifTrue: [ ^ 'false' ].
	anObject isSymbol ifTrue: [
		^ '(' , (self literalScriptForCompatibility: anObject asString) , ' asSymbol)' ].
	anObject isString ifTrue: [
		^ '''' , (anObject copyReplaceAll: '''' with: '''''') , '''' ].
	anObject isNumber ifTrue: [ ^ anObject printString ].
	self error: 'Unsupported Original compatibility literal: ', anObject class name
]

{ #category : 'private' }
GbsRemoteExecutionDispatcher class >> objectScriptForOop: anInteger [
	^ '(Object _objectForOop: ', anInteger asInteger printString, ')'
]

{ #category : 'private' }
GbsRemoteExecutionDispatcher class >> remoteCommandClass: commandClass body: bodyString literalBindings: literalDictionary oopBindings: oopDictionary [
	^ commandClass
		blockBody: bodyString
		literalBindings: literalDictionary
		oopBindings: oopDictionary
]

{ #category : 'private' }
GbsRemoteExecutionDispatcher class >> validateArgumentName: aString [
	| name |
	name := aString asString.
	(name isEmpty or: [ name first isDigit ]) ifTrue: [
		self error: 'Invalid remote command argument name: ', name printString ].
	(name allSatisfy: [ :ch | ch isAlphaNumeric or: [ ch = $_ ] ]) ifFalse: [
		self error: 'Invalid remote command argument name: ', name printString ].
	^ name
]
