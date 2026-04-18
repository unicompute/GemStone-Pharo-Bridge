Class {
	#name : 'GbxTestableTrippy',
	#superclass : 'GbxTrippy',
	#instVars : [
		'showCurrentObjectCalls',
		'lastOpenedOop',
		'lastInfoMessage',
		'chosenReferencer',
		'requestAnswers'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxTestableTrippy >> showCurrentObjectCalls [
	^ showCurrentObjectCalls ifNil: [ 0 ]
]

{ #category : 'navigation' }
GbxTestableTrippy >> showCurrentObject [
	showCurrentObjectCalls := self showCurrentObjectCalls + 1
]

{ #category : 'ui' }
GbxTestableTrippy >> openTrippyOnOop: anOop [
	lastOpenedOop := anOop.
	^ true
]

{ #category : 'ui' }
GbxTestableTrippy >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'ui' }
GbxTestableTrippy >> chooseReferencerFrom: referencers title: aTitle [
	^ chosenReferencer
]

{ #category : 'ui' }
GbxTestableTrippy >> enqueueRequestAnswer: aStringOrNil [
	self requestAnswers add: aStringOrNil
]

{ #category : 'accessing' }
GbxTestableTrippy >> lastOpenedOop [
	^ lastOpenedOop
]

{ #category : 'accessing' }
GbxTestableTrippy >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
GbxTestableTrippy >> chosenReferencer: anObject [
	chosenReferencer := anObject
]

{ #category : 'ui' }
GbxTestableTrippy >> requestAnswers [
	^ requestAnswers ifNil: [ requestAnswers := OrderedCollection new ]
]

{ #category : 'ui' }
GbxTestableTrippy >> requestString: prompt initialAnswer: defaultString [
	^ self requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ self requestAnswers removeFirst ]
]
