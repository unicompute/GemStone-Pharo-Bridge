Class {
	#name : 'TestableGbsInspector',
	#superclass : 'GbsInspector',
	#instVars : [
		'lastOpenedOop',
		'lastInfoMessage',
		'chosenReferencer',
		'requestAnswers'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'ui' }
TestableGbsInspector >> chooseReferencerFrom: referencers title: aTitle [
	^ chosenReferencer
]

{ #category : 'initialization' }
TestableGbsInspector >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new
]

{ #category : 'ui' }
TestableGbsInspector >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'testing' }
TestableGbsInspector >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'ui' }
TestableGbsInspector >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'accessing' }
TestableGbsInspector >> chosenReferencer: anObject [
	chosenReferencer := anObject
]

{ #category : 'accessing' }
TestableGbsInspector >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
TestableGbsInspector >> lastOpenedOop [
	^ lastOpenedOop
]

{ #category : 'ui' }
TestableGbsInspector >> openInspectorOnOop: anOop [
	lastOpenedOop := anOop.
	^ true
]
