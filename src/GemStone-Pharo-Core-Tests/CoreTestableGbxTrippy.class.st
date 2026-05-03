Class {
	#name : 'CoreTestableGbxTrippy',
	#superclass : 'GbxTrippy',
	#instVars : [
		'showCurrentObjectCalls',
		'lastOpenedOop',
		'lastInfoMessage',
		'chosenReferencer',
		'requestAnswers'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'ui' }
CoreTestableGbxTrippy >> chooseReferencerFrom: referencers title: aTitle [
	^ chosenReferencer
]

{ #category : 'accessing' }
CoreTestableGbxTrippy >> chosenReferencer: anObject [
	chosenReferencer := anObject
]

{ #category : 'ui' }
CoreTestableGbxTrippy >> enqueueRequestAnswer: aStringOrNil [
	self requestAnswers add: aStringOrNil
]

{ #category : 'ui' }
CoreTestableGbxTrippy >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'accessing' }
CoreTestableGbxTrippy >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
CoreTestableGbxTrippy >> lastOpenedOop [
	^ lastOpenedOop
]

{ #category : 'ui' }
CoreTestableGbxTrippy >> openTrippyOnOop: anOop [
	lastOpenedOop := anOop.
	^ true
]

{ #category : 'accessing' }
CoreTestableGbxTrippy >> requestAnswers [
	^ requestAnswers ifNil: [ requestAnswers := OrderedCollection new ]
]

{ #category : 'ui' }
CoreTestableGbxTrippy >> requestString: prompt initialAnswer: defaultString [
	^ self requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ self requestAnswers removeFirst ]
]

{ #category : 'navigation' }
CoreTestableGbxTrippy >> showCurrentObject [
	showCurrentObjectCalls := self showCurrentObjectCalls + 1
]

{ #category : 'accessing' }
CoreTestableGbxTrippy >> showCurrentObjectCalls [
	^ showCurrentObjectCalls ifNil: [ 0 ]
]
