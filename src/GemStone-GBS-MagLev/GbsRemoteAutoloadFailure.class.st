Class {
	#name : 'GbsRemoteAutoloadFailure',
	#superclass : 'Object',
	#instVars : [
		'autoloadMirror',
		'exceptionObject',
		'retrySourceChoices'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRemoteAutoloadFailure class >> on: anAutoloadMirror [
	^ self new
		autoloadMirror: anAutoloadMirror;
		yourself
]

{ #category : 'accessing' }
GbsRemoteAutoloadFailure >> autoloadMirror [
	^ autoloadMirror
]

{ #category : 'accessing' }
GbsRemoteAutoloadFailure >> autoloadMirror: anAutoloadMirror [
	autoloadMirror := anAutoloadMirror
]

{ #category : 'printing' }
GbsRemoteAutoloadFailure >> displayString [
	^ String streamContents: [ :stream |
		stream nextPutAll: self stateLabel.
		self failureSourceLabel ifNotNil: [
			stream
				nextPutAll: ' from ';
				nextPutAll: self failureSourceLabel asString ].
		self lastAttemptedFile ifNotNil: [
			stream
				nextPutAll: ' @ ';
				nextPutAll: self lastAttemptedFile asString ] ]
]

{ #category : 'querying' }
GbsRemoteAutoloadFailure >> exceptionObject [
	exceptionObject ifNil: [
		exceptionObject := GbsRemoteAutoloadException
			session: autoloadMirror session
			oop: autoloadMirror failureExceptionOop
			messageText: self failureMessage
			backtraceText: self failureBacktraceText ].
	^ exceptionObject
]

{ #category : 'querying' }
GbsRemoteAutoloadFailure >> backtraceEntries [
	^ self exceptionObject backtraceEntries
]

{ #category : 'querying' }
GbsRemoteAutoloadFailure >> failureBacktraceText [
	^ autoloadMirror failureBacktraceText
]

{ #category : 'querying' }
GbsRemoteAutoloadFailure >> failureDetail [
	^ autoloadMirror failureDetail
]

{ #category : 'querying' }
GbsRemoteAutoloadFailure >> failureMessage [
	^ autoloadMirror failureMessage
]

{ #category : 'querying' }
GbsRemoteAutoloadFailure >> failureSourceLabel [
	^ autoloadMirror failureSourceLabel
]

{ #category : 'querying' }
GbsRemoteAutoloadFailure >> lastAttemptedFile [
	^ autoloadMirror lastAttemptedFile
]

{ #category : 'printing' }
GbsRemoteAutoloadFailure >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self displayString;
		nextPut: $)
]

{ #category : 'querying' }
GbsRemoteAutoloadFailure >> retrySourceChoices [
	retrySourceChoices ifNil: [
		retrySourceChoices := autoloadMirror retrySourceChoices ].
	^ retrySourceChoices
]

{ #category : 'querying' }
GbsRemoteAutoloadFailure >> retryActionChoices [
	^ self retrySourceChoices collect: [ :each |
		GbsRubyRuntimeProvenanceAction
			retryAction: #retryAutoload
			sourceEntry: autoloadMirror
			targetPath: autoloadMirror name
			sourceKind: each ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadFailure >> retrySourceChoices: aCollection [
	retrySourceChoices := aCollection
]

{ #category : 'querying' }
GbsRemoteAutoloadFailure >> retrySourceKind [
	^ autoloadMirror retrySourceKind
]

{ #category : 'querying' }
GbsRemoteAutoloadFailure >> stateLabel [
	^ autoloadMirror failureStateLabel
]

{ #category : 'printing' }
GbsRemoteAutoloadFailure >> text [
	^ String streamContents: [ :stream |
		stream nextPutAll: self displayString; cr.
		self failureDetail ifNotNil: [
			stream nextPutAll: self failureDetail asString; cr ].
		self failureMessage ifNotNil: [
			stream nextPutAll: self failureMessage asString; cr ].
		self retrySourceChoices ifNotEmpty: [
			stream
				nextPutAll: 'Retry Choices: ';
				nextPutAll: (self retrySourceChoices collect: #asString) printString;
				cr ].
		self exceptionObject text ifNotEmpty: [
			stream cr; nextPutAll: 'Exception'; cr.
			stream nextPutAll: self exceptionObject text ] ]
]
