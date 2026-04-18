Class {
	#name : 'TestableGbsPlaygroundActions',
	#superclass : 'GbsPlaygroundActions',
	#classVars : [
		'LastInspectedOop',
		'LastInspectedSession',
		'LastInfoMessage',
		'RequestAnswers'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'testing' }
TestableGbsPlaygroundActions class >> inspectOop: anOop session: aSession [
	LastInspectedOop := anOop.
	LastInspectedSession := aSession.
	^ anOop
]

{ #category : 'accessing' }
TestableGbsPlaygroundActions class >> lastInspectedOop [
	^ LastInspectedOop
]

{ #category : 'accessing' }
TestableGbsPlaygroundActions class >> lastInspectedSession [
	^ LastInspectedSession
]

{ #category : 'accessing' }
TestableGbsPlaygroundActions class >> lastInfoMessage [
	^ LastInfoMessage
]

{ #category : 'testing' }
TestableGbsPlaygroundActions class >> enqueueRequestAnswer: aStringOrNil [
	RequestAnswers ifNil: [ RequestAnswers := OrderedCollection new ].
	RequestAnswers add: aStringOrNil
]

{ #category : 'helpers' }
TestableGbsPlaygroundActions class >> inform: aString [
	LastInfoMessage := aString asString.
	^ LastInfoMessage
]

{ #category : 'helpers' }
TestableGbsPlaygroundActions class >> requestInput: prompt initialAnswer: defaultString [
	RequestAnswers ifNil: [ RequestAnswers := OrderedCollection new ].
	^ RequestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ RequestAnswers removeFirst ]
]

{ #category : 'testing' }
TestableGbsPlaygroundActions class >> resetHarness [
	LastInspectedOop := nil.
	LastInspectedSession := nil.
	LastInfoMessage := nil.
	RequestAnswers := OrderedCollection new
]
