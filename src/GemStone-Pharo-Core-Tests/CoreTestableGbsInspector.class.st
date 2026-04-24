Class {
	#name : 'CoreTestableGbsInspector',
	#superclass : 'GbsInspector',
	#instVars : [
		'lastOpenedOop',
		'lastInfoMessage',
		'chosenReferencer',
		'requestAnswers'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'ui' }
CoreTestableGbsInspector >> chooseReferencerFrom: referencers title: aTitle [
	^ chosenReferencer
]

{ #category : 'initialization' }
CoreTestableGbsInspector >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new
]

{ #category : 'ui' }
CoreTestableGbsInspector >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'testing' }
CoreTestableGbsInspector >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'ui' }
CoreTestableGbsInspector >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'accessing' }
CoreTestableGbsInspector >> chosenReferencer: anObject [
	chosenReferencer := anObject
]

{ #category : 'accessing' }
CoreTestableGbsInspector >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
CoreTestableGbsInspector >> lastOpenedOop [
	^ lastOpenedOop
]

{ #category : 'ui' }
CoreTestableGbsInspector >> openInspectorOnOop: anOop [
	lastOpenedOop := anOop.
	^ true
]
