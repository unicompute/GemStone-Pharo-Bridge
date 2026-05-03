Class {
	#name : 'GbsRemoteAutoloadException',
	#superclass : 'Object',
	#instVars : [
		'session',
		'oop',
		'messageText',
		'backtraceText'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRemoteAutoloadException class >> session: aSession oop: anOop messageText: aString backtraceText: aBacktraceText [
	^ self new
		session: aSession;
		oop: anOop;
		messageText: aString;
		backtraceText: aBacktraceText;
		yourself
]

{ #category : 'querying' }
GbsRemoteAutoloadException >> backtraceLines [
	| text |
	text := self backtraceText.
	text ifNil: [ ^ #() ].
	(text respondsTo: #splitOn:) ifFalse: [ ^ { text asString } ].
	^ (text splitOn: Character lf) reject: #isEmpty
]

{ #category : 'querying' }
GbsRemoteAutoloadException >> backtraceEntries [
	| lines |
	lines := self backtraceLines.
	^ (1 to: lines size) collect: [ :index |
		GbsRemoteAutoloadBacktraceEntry
			line: (lines at: index)
			index: index ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadException >> backtraceText [
	^ backtraceText
]

{ #category : 'accessing' }
GbsRemoteAutoloadException >> backtraceText: aString [
	backtraceText := aString
]

{ #category : 'printing' }
GbsRemoteAutoloadException >> displayString [
	^ self messageText
		ifNil: [ 'Autoload exception unavailable' ]
		ifNotNil: [ self messageText asString ]
]

{ #category : 'testing' }
GbsRemoteAutoloadException >> hasBacktrace [
	^ self backtraceLines isEmpty not
]

{ #category : 'testing' }
GbsRemoteAutoloadException >> hasBacktraceLocations [
	^ self backtraceEntries anySatisfy: [ :each | each hasLocation ]
]

{ #category : 'testing' }
GbsRemoteAutoloadException >> hasRemoteObject [
	^ oop isInteger and: [ oop > 20 ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadException >> messageText [
	^ messageText
]

{ #category : 'accessing' }
GbsRemoteAutoloadException >> messageText: aString [
	messageText := aString
]

{ #category : 'accessing' }
GbsRemoteAutoloadException >> oop [
	^ oop
]

{ #category : 'accessing' }
GbsRemoteAutoloadException >> oop: anInteger [
	oop := anInteger
]

{ #category : 'printing' }
GbsRemoteAutoloadException >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self displayString;
		nextPut: $)
]

{ #category : 'querying' }
GbsRemoteAutoloadException >> proxy [
	self hasRemoteObject ifFalse: [ ^ nil ].
	^ session objectForOop: oop
]

{ #category : 'querying' }
GbsRemoteAutoloadException >> firstBacktraceEntry [
	^ self backtraceEntries
		ifEmpty: [ nil ]
		ifNotEmpty: [ :entries | entries first ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadException >> session [
	^ session
]

{ #category : 'accessing' }
GbsRemoteAutoloadException >> session: aSession [
	session := aSession
]

{ #category : 'printing' }
GbsRemoteAutoloadException >> text [
	^ String streamContents: [ :stream |
		stream nextPutAll: self displayString.
		self hasBacktrace ifTrue: [
			stream cr; nextPutAll: 'Backtrace'; cr.
			self backtraceEntries do: [ :each |
				stream nextPutAll: each displayString; cr ] ] ]
]
