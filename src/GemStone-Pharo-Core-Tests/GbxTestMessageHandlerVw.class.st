Class {
	#name : 'GbxTestMessageHandlerVw',
	#superclass : 'CstMessageHandlerVw',
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
GbxTestMessageHandlerVw >> initialize [
	super initialize.
	chooseAnswers := OrderedCollection new.
	confirmAnswers := OrderedCollection new.
	requestAnswers := OrderedCollection new.
	existingPaths := Set new.
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVw >> enqueueChooseAnswer: anInteger [
	chooseAnswers add: anInteger
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVw >> enqueueConfirmAnswer: aBoolean [
	confirmAnswers add: aBoolean
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVw >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVw >> openSelection: aStringOrNil [
	openSelection := aStringOrNil
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVw >> existingPaths: aCollection [
	existingPaths := aCollection asSet
]

{ #category : 'testing-api' }
GbxTestMessageHandlerVw >> lastConfirmPrompt [
	^ lastConfirmPrompt
]

{ #category : 'private-ui' }
GbxTestMessageHandlerVw >> uiChooseFrom: labels title: aTitle [
	^ chooseAnswers
		ifEmpty: [ 0 ]
		ifNotEmpty: [ chooseAnswers removeFirst ]
]

{ #category : 'private-ui' }
GbxTestMessageHandlerVw >> uiConfirm: aString [
	lastConfirmPrompt := aString.
	^ confirmAnswers
		ifEmpty: [ false ]
		ifNotEmpty: [ confirmAnswers removeFirst ]
]

{ #category : 'private-ui' }
GbxTestMessageHandlerVw >> uiRequest: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ nil ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'private-ui' }
GbxTestMessageHandlerVw >> openFileSelectionForPrompt: prompt [
	^ openSelection
]

{ #category : 'private-ui' }
GbxTestMessageHandlerVw >> fileExistsAtPath: pathString [
	^ existingPaths includes: pathString
]
