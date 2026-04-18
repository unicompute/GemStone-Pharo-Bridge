Class {
	#name : 'TestableGbsRemoteDebugger',
	#superclass : 'GbsRemoteDebugger',
	#instVars : [
		'requestAnswers',
		'lastInfoMessage',
		'lastInspectedOop',
		'lastInspectedSession'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
TestableGbsRemoteDebugger >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new
]

{ #category : 'testing' }
TestableGbsRemoteDebugger >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'private' }
TestableGbsRemoteDebugger >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'accessing' }
TestableGbsRemoteDebugger >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'private' }
TestableGbsRemoteDebugger >> inspectOop: anOop session: aSession [
	lastInspectedOop := anOop.
	lastInspectedSession := aSession.
	^ true
]

{ #category : 'accessing' }
TestableGbsRemoteDebugger >> lastInspectedOop [
	^ lastInspectedOop
]

{ #category : 'accessing' }
TestableGbsRemoteDebugger >> lastInspectedSession [
	^ lastInspectedSession
]

{ #category : 'private' }
TestableGbsRemoteDebugger >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]
