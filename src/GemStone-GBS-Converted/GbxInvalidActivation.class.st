Class {
	#name : #'GbxInvalidActivation',
	#superclass : #'GbxActivation',
	#instVars : [ #'error' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'testing' }
GbxInvalidActivation >> gbxIsInStackOf: topContext
	"Answer true if I am part of the combined stack identified by topContext."
	
	^true

{ #category : #'testing' }
GbxInvalidActivation >> isValid
	
	^false

{ #category : #'accessing temps' }
GbxInvalidActivation >> stackP
	^0

{ #category : #'error handling' }
GbxInvalidActivation >> error: anObject
	error := anObject

{ #category : #'error handling' }
GbxInvalidActivation >> error
	^error

{ #category : #'private' }
GbxInvalidActivation >> forProcess: aGsProcess
	
	process := aGsProcess.
	session := aGsProcess noCheckSession

{ #category : #'private' }
GbxInvalidActivation >> methodString
	
	^'serverContextsUnavailable
	"this text is displayed when a server context could not be retrieved.
	This can happen, for example, if an error was encountered during 
	a server call which was gathering server contexts.

	You may inspect the context for more information "' copy

{ #category : #'private' }
GbxInvalidActivation >> reset
	"do nothing"

{ #category : #'private' }
GbxInvalidActivation >> isGsGlue
	
	^false

{ #category : #'private' }
GbxInvalidActivation >> resetFrom: aGSArray extract: anExtractArray andDelegates: anObject

	deferredInfo := Array new: aGSArray size.
	numArgsAndTemps := 0.
	stackP := 0.
	gsMethod := self class methodDictionary at: #serverContextsUnavailable.
	gsMethodId := 'Invalid Server Context'.

{ #category : #'accessing method' }
GbxInvalidActivation >> mclass
	^Object

{ #category : #'accessing method' }
GbxInvalidActivation >> serverContextsUnavailable
	"this text is displayed when a server context could not be retrieved.
	This can happen, for example, if an error was encountered during 
	a server call which was gathering server contexts.

	You may inspect the context for more information "

{ #category : #'accessing method' }
GbxInvalidActivation >> sourceString
	
	| ws |
	ws := String new writeStream.
	ws nextPutAll: self methodString.
	(error class canUnderstand: #messageText)
		ifFalse: [ws nextPutAll: error printString]
		ifTrue:
			[ws
				cr;
				cr;
				tab;
				nextPutAll: 'Error received:'.
			ws
				cr;
				cr;
				tab.
			ws
				nextPutAll: error printString;
				cr;
				tab.
			ws nextPutAll: error messageText].
	^ws contents

{ #category : #'debugger support' }
GbxInvalidActivation >> gbsError
	"Answer the gbsError that caused my GsProcess to suspend."

	"The debugger can get upset if this message isn't understood"

	^nil

{ #category : #'accessing context' }
GbxInvalidActivation >> homeReceiver
	"in a stack dump, the user will at least see the reason for the invalid context"
	
	^error

{ #category : #'accessing context' }
GbxInvalidActivation >> level
	^1

{ #category : #'accessing context' }
GbxInvalidActivation >> stepPoint
	"don't care"
	
	^0

{ #category : #'initialize-release' }
GbxInvalidActivation >> initialize

	self
		resetFrom: (Array new: 12)
		extract: nil
		andDelegates: nil.

{ #category : #'printing' }
GbxInvalidActivation >> printOn: aStream

	aStream
		nextPutAll: 'GS: ';
		nextPutAll: self gsMethodId;
		nextPutAll: ' (';
		nextPutAll: error printString;
		nextPutAll: ' )'

{ #category : #'instance creation' }
GbxInvalidActivation class >> new
	^super new initialize

