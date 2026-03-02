Class {
	#name : 'GbsRemoteDebugger',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'exception',
		'listFrames',
		'textSource'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'initialization' }
GbsRemoteDebugger >> connectPresenters [

  listFrames whenSelectionChangedDo: [ :selection |
    selection selectedItem ifNotNil: [ :item | self fetchSourceForSelectedFrame ] ]
]

{ #category : 'layout' }
GbsRemoteDebugger >> defaultLayout [
	^ SpPanedLayout newVertical
		positionOfSlider: 0.3; "<-- Use a raw Float to bypass the broken math!"
		add: listFrames;
		add: textSource;
		yourself
]

{ #category : 'accessing' }
GbsRemoteDebugger >> exception: aGbsError [
	exception := aGbsError.
	"Only populate frames once we have the exception"
	self populateFrames
]

{ #category : 'actions' }
GbsRemoteDebugger >> fetchSourceForSelectedFrame [
	| contextOop script sourceText |
	
	(exception isNil or: [ exception tag isNil ]) ifTrue: [ ^ self ].
	(exception tag respondsTo: #context) ifFalse: [ ^ self ].
	
	contextOop := exception tag context.
	contextOop ifNil: [ ^ self ].
	
	script := '
	| ctx |
	ctx := Object _objectForOop: ', contextOop asString, '.
	(ctx class name == #GsProcess) 
		ifTrue: [ ctx _report ] 
		ifFalse: [ 
			(ctx respondsTo: #sourceString) 
				ifTrue: [ ctx sourceString ] 
				ifFalse: [ ctx asString ]
		]'.
		
	sourceText := session evaluate: script.
	textSource text: sourceText asString.
]

{ #category : 'initialization' }
GbsRemoteDebugger >> initializePresenters [
	listFrames := self newList.
	listFrames headerTitle: 'Remote Execution Stack'.
	
	textSource := self newCode.
	textSource text: '"Select a frame to see source code..."'.
	textSource beNotEditable.
]

{ #category : 'layout' }
GbsRemoteDebugger >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Remote Debugger';
		initialExtent: 700@500.
]

{ #category : 'initialization' }
GbsRemoteDebugger >> populateFrames [

  | errTag contextOop |
  errTag := exception tag.

  "1. Bulletproof check: If the tag is missing or is just a string"
  ( errTag isNil or: [ errTag isString ] ) ifTrue: [
      listFrames items: { ( 'Remote Error: ' , exception messageText ) }.
      ^ self
      ].

  "2. Safely check if the struct actually understands #context"
  ( errTag respondsTo: #context )
    ifTrue: [ contextOop := errTag context asString ]
    ifFalse: [ contextOop := 'Unavailable (Add #context to GciError struct)' ].

  "3. Display both the error message and the context OOP"
  listFrames items: {
      ( 'Exception: ' , exception messageText ).
      ( 'Remote Context OOP: ' , contextOop ) }
]

{ #category : 'accessing' }
GbsRemoteDebugger >> session: aSession [
	session := aSession
]

{ #category : 'as yet unclassified' }
GbsRemoteDebugger >> session: aSession exception: aGbsError [
	session := aSession.
	exception := aGbsError.
	self populateFrames.
]
