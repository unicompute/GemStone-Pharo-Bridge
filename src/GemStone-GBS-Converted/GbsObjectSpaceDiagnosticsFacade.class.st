Class {
	#name : 'GbsObjectSpaceDiagnosticsFacade',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsObjectSpaceDiagnosticsFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> maglevFinalizerRegistry [
	^ session maglevFinalizerRegistry
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> objectSpace [
	^ session objectSpace
]

{ #category : 'printing' }
GbsObjectSpaceDiagnosticsFacade >> reportText [
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Session State'; cr; cr.
		self sessionStateSummaryLines do: [ :each |
			stream nextPutAll: each; cr ] ]
]

{ #category : 'accessing' }
GbsObjectSpaceDiagnosticsFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsObjectSpaceDiagnosticsFacade >> session: aSession [
	session := aSession
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> sessionStateAt: aKey [
	^ session sessionStateAt: aKey
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> sessionStateSummaryLineForKey: aKey [
	^ self
		sessionStateSummaryLineForKey: aKey
		label: (self slotLabelForKey: aKey)
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> sessionStateSummaryLineForKey: aKey label: aLabel [
	| value |
	value := [ self sessionStateAt: aKey ]
		on: Error
		do: [ :ex | ex ].
	^ self
		summaryLineFor: value
		label: ('Key ', aKey printString, ' (', aLabel, ')')
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> sessionStateSummaryLines [
	^ self wellKnownSessionStateKeys collect: [ :each |
		self sessionStateSummaryLineForKey: each ]
]

{ #category : 'printing' }
GbsObjectSpaceDiagnosticsFacade >> slotLabelForKey: aKey [
	aKey = 19 ifTrue: [ ^ 'MagLev Finalizer Registry' ].
	^ 'Session State'
]

{ #category : 'printing' }
GbsObjectSpaceDiagnosticsFacade >> summaryLineFor: anObject label: aLabel [
	^ String streamContents: [ :stream |
		self writeSummaryFor: anObject label: aLabel on: stream ]
]

{ #category : 'printing' }
GbsObjectSpaceDiagnosticsFacade >> writeSummaryFor: anObject label: aLabel on: aStream [
	| sizeValue |
	(anObject isKindOf: Error) ifTrue: [
		aStream
			nextPutAll: aLabel;
			nextPutAll: ': ERROR - ';
			nextPutAll: anObject messageText.
		^ self ].
	anObject ifNil: [
		aStream
			nextPutAll: aLabel;
			nextPutAll: ': (absent)'.
		^ self ].
	aStream
		nextPutAll: aLabel;
		nextPutAll: ': ';
		nextPutAll: anObject class name asString.
	(anObject respondsTo: #oop) ifTrue: [
		aStream
			nextPutAll: ' oop=';
			nextPutAll: anObject oop printString ].
	sizeValue := [
		((anObject respondsTo: #size) and: [ anObject class ~~ GbsProxy ])
			ifTrue: [ anObject size ]
			ifFalse: [ nil ] ]
		on: Error
		do: [ nil ].
	(sizeValue isInteger) ifTrue: [
		aStream
			nextPutAll: ' size=';
			nextPutAll: sizeValue printString ]
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> wellKnownSessionStateKeys [
	^ #(19)
]
