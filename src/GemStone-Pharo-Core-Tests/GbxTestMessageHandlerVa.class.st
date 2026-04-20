Class {
	#name : 'GbxTestMessageHandlerVa',
	#superclass : 'CstMessageHandlerVa',
	#instVars : [
		'chooseAnswers',
		'confirmAnswers',
		'requestAnswers',
		'openSelection',
		'existingPaths',
		'lastConfirmPrompt'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'initialization' }
GbxTestMessageHandlerVa >> initialize [
	super initialize.
	chooseAnswers := OrderedCollection new.
	confirmAnswers := OrderedCollection new.
	requestAnswers := OrderedCollection new.
	existingPaths := Set new.
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVa >> enqueueChooseAnswer: anInteger [
	chooseAnswers add: anInteger
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVa >> enqueueConfirmAnswer: aBoolean [
	confirmAnswers add: aBoolean
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVa >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVa >> openSelection: aStringOrNil [
	openSelection := aStringOrNil
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVa >> existingPaths: aCollection [
	existingPaths := aCollection asSet
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVa >> lastConfirmPrompt [
	^ lastConfirmPrompt
]

{ #category : 'private-ui' }
GbxTestMessageHandlerVa >> uiChooseFrom: labels title: aTitle [
	^ chooseAnswers
		ifEmpty: [ 0 ]
		ifNotEmpty: [ chooseAnswers removeFirst ]
]

{ #category : 'private-ui' }
GbxTestMessageHandlerVa >> uiConfirm: aString [
	lastConfirmPrompt := aString.
	^ confirmAnswers
		ifEmpty: [ false ]
		ifNotEmpty: [ confirmAnswers removeFirst ]
]

{ #category : 'private-ui' }
GbxTestMessageHandlerVa >> uiRequest: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ nil ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'private-ui' }
GbxTestMessageHandlerVa >> openFileSelectionForPrompt: prompt [
	^ openSelection
]

{ #category : 'private-ui' }
GbxTestMessageHandlerVa >> fileExistsAtPath: pathString [
	^ existingPaths includes: pathString
]
