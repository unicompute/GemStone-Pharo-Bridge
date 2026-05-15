Class {
	#name : 'GbsSessionCommandExecutor',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsSessionCommandExecutor class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'accessing' }
GbsSessionCommandExecutor >> session [
	^ session
]

{ #category : 'accessing' }
GbsSessionCommandExecutor >> session: aSession [
	session := aSession
]

{ #category : 'commands' }
GbsSessionCommandExecutor >> remoteScriptBuilder [
	^ GbsRemoteScriptBuilder new
]

{ #category : 'commands' }
GbsSessionCommandExecutor >> fetchRemoteCommand: aRemoteCommand [
	^ aRemoteCommand executeAndFetchObjectIn: session
]

{ #category : 'commands' }
GbsSessionCommandExecutor >> fetchRemoteCommand: aRemoteCommand context: anOop [
	^ aRemoteCommand executeAndFetchIn: session context: anOop
]

{ #category : 'commands' }
GbsSessionCommandExecutor >> fetchRemoteCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary context: anOop [
	^ self
		fetchRemoteCommand: (GbsRemoteCommand
			blockBody: bodyString
			literalBindings: literalDictionary
			oopBindings: oopDictionary)
		context: anOop
]

{ #category : 'commands' }
GbsSessionCommandExecutor >> fetchRemoteScript: scriptString context: anOop [
	"Compatibility helper for existing free-form scripts. New tool paths should prefer
	fetchRemoteCommandBody:literalBindings:oopBindings:context:."
	^ self
		fetchRemoteCommand: (GbsRemoteCommand compatibilityScript: scriptString)
		context: anOop
]

{ #category : 'commands' }
GbsSessionCommandExecutor >> returnRemoteCommandOop: aRemoteCommand [
	^ aRemoteCommand executeAndReturnOopIn: session
]

{ #category : 'commands' }
GbsSessionCommandExecutor >> returnRemoteCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary [
	^ self returnRemoteCommandOop: (GbsRemoteCommand
		blockBody: bodyString
		literalBindings: literalDictionary
		oopBindings: oopDictionary)
]

{ #category : 'workspace' }
GbsSessionCommandExecutor >> executeScriptAndReturnOop: aString [
	| resultOop |
	session validateReadyForExecution: aString.

	resultOop := session serverInterface
		apiGciExecuteStr: aString
		context: 20
		env: 0.

	resultOop = 1 ifTrue: [ ^ session handleGciError ].
	session checkForError.

	^ resultOop asInteger
]

{ #category : 'workspace' }
GbsSessionCommandExecutor >> executeWorkspaceScriptAndReturnOop: aString [
	"Explicit escape hatch for user-authored workspace/playground Inspect It code.
	Do not use this for bridge-generated scripts; use GbsRemoteCommand instead."
	^ self executeScriptAndReturnOop: aString
]

{ #category : 'transcript' }
GbsSessionCommandExecutor >> fetchTranscriptLogs [
	| rawText |
	rawText := self
		fetchRemoteCommandBody: '
		| fetched log text |
		fetched := (Transcript respondsTo: #fetchAndClear)
			ifTrue: [ [ Transcript fetchAndClear ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		fetched
			ifNil: [
				log := UserGlobals at: #PharoTranscriptLog ifAbsent: [ OrderedCollection new ].
				text := String streamContents: [ :stream |
					log do: [ :each |
						stream nextPutAll: each asString.
						stream cr ] ].
				UserGlobals at: #PharoTranscriptLog put: OrderedCollection new.
				text ]
			ifNotNil: [ fetched asString ]'
		literalBindings: Dictionary new
		oopBindings: Dictionary new
		context: 20.
	rawText ifNil: [ ^ '' ].
	rawText := rawText asString.
	(rawText beginsWith: 'Error:') ifTrue: [ ^ '' ].
	^ rawText
]
