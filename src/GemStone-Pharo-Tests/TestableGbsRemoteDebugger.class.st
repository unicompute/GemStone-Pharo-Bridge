Class {
	#name : 'TestableGbsRemoteDebugger',
	#superclass : 'GbsRemoteDebugger',
	#instVars : [
		'requestAnswers',
		'chooseAnswers',
		'lastInfoMessage',
		'lastInspectedOop',
		'lastInspectedSession',
		'lastProvenanceGraph'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
TestableGbsRemoteDebugger >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new.
	chooseAnswers := OrderedCollection new
]

{ #category : 'testing' }
TestableGbsRemoteDebugger >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'testing' }
TestableGbsRemoteDebugger >> enqueueChooseAnswer: anInteger [
	chooseAnswers add: anInteger
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

{ #category : 'private' }
TestableGbsRemoteDebugger >> openRubyRuntimeProvenanceBrowserFor: aGraph title: aTitle [
	lastProvenanceGraph := aGraph.
	lastInfoMessage := aTitle.
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

{ #category : 'accessing' }
TestableGbsRemoteDebugger >> lastProvenanceGraph [
	^ lastProvenanceGraph
]

{ #category : 'private' }
TestableGbsRemoteDebugger >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'private' }
TestableGbsRemoteDebugger >> uiChooseFrom: choices title: titleString [
	^ chooseAnswers
		ifEmpty: [ 0 ]
		ifNotEmpty: [ chooseAnswers removeFirst ]
]
