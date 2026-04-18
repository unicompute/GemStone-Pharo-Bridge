Class {
	#name : 'TestableGbsSymbolListBrowserPresenter',
	#superclass : 'GbsSymbolListBrowserPresenter',
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
TestableGbsSymbolListBrowserPresenter >> chooseReferencerFrom: referencers title: aTitle [
	^ chosenReferencer
]

{ #category : 'ui' }
TestableGbsSymbolListBrowserPresenter >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'testing' }
TestableGbsSymbolListBrowserPresenter >> enqueueRequestAnswer: aStringOrNil [
	self requestAnswers add: aStringOrNil
]

{ #category : 'accessing' }
TestableGbsSymbolListBrowserPresenter >> chosenReferencer: anObject [
	chosenReferencer := anObject
]

{ #category : 'accessing' }
TestableGbsSymbolListBrowserPresenter >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
TestableGbsSymbolListBrowserPresenter >> lastOpenedOop [
	^ lastOpenedOop
]

{ #category : 'ui' }
TestableGbsSymbolListBrowserPresenter >> requestAnswers [
	^ requestAnswers ifNil: [ requestAnswers := OrderedCollection new ]
]

{ #category : 'ui' }
TestableGbsSymbolListBrowserPresenter >> requestInput: prompt initialAnswer: defaultString [
	^ self requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ self requestAnswers removeFirst ]
]

{ #category : 'ui' }
TestableGbsSymbolListBrowserPresenter >> openInspectorOnOop: anOop [
	lastOpenedOop := anOop.
	^ true
]
