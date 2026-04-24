Class {
	#name : 'CoreTestableGbsRemoteDebugger',
	#superclass : 'GbsRemoteDebugger',
	#instVars : [
		'requestAnswers',
		'chooseAnswers',
		'lastInfoMessage',
		'lastInspectedOop',
		'lastInspectedSession',
		'lastProvenanceGraph'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'initialization' }
CoreTestableGbsRemoteDebugger >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new.
	chooseAnswers := OrderedCollection new
]

{ #category : 'testing' }
CoreTestableGbsRemoteDebugger >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'testing' }
CoreTestableGbsRemoteDebugger >> enqueueChooseAnswer: anInteger [
	chooseAnswers add: anInteger
]

{ #category : 'private' }
CoreTestableGbsRemoteDebugger >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'private' }
CoreTestableGbsRemoteDebugger >> inspectOop: anOop session: aSession [
	lastInspectedOop := anOop.
	lastInspectedSession := aSession.
	^ true
]

{ #category : 'accessing' }
CoreTestableGbsRemoteDebugger >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
CoreTestableGbsRemoteDebugger >> lastInspectedOop [
	^ lastInspectedOop
]

{ #category : 'accessing' }
CoreTestableGbsRemoteDebugger >> lastInspectedSession [
	^ lastInspectedSession
]

{ #category : 'accessing' }
CoreTestableGbsRemoteDebugger >> lastProvenanceGraph [
	^ lastProvenanceGraph
]

{ #category : 'private' }
CoreTestableGbsRemoteDebugger >> openRubyRuntimeProvenanceBrowserFor: aGraph title: aTitle [
	lastProvenanceGraph := aGraph.
	lastInfoMessage := aTitle.
	^ true
]

{ #category : 'private' }
CoreTestableGbsRemoteDebugger >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'private' }
CoreTestableGbsRemoteDebugger >> uiChooseFrom: choices title: titleString [
	^ chooseAnswers
		ifEmpty: [ 0 ]
		ifNotEmpty: [ chooseAnswers removeFirst ]
]
