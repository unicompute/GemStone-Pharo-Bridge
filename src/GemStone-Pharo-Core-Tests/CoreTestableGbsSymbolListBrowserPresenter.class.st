Class {
	#name : 'CoreTestableGbsSymbolListBrowserPresenter',
	#superclass : 'GbsSymbolListBrowserPresenter',
	#instVars : [
		'lastOpenedOop',
		'lastInfoMessage',
		'chosenReferencer',
		'requestAnswers'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'initialization' }
CoreTestableGbsSymbolListBrowserPresenter >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new
]

{ #category : 'ui' }
CoreTestableGbsSymbolListBrowserPresenter >> chooseReferencerFrom: referencers title: aTitle [
	^ chosenReferencer
]

{ #category : 'ui' }
CoreTestableGbsSymbolListBrowserPresenter >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'testing' }
CoreTestableGbsSymbolListBrowserPresenter >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'accessing' }
CoreTestableGbsSymbolListBrowserPresenter >> chosenReferencer: anObject [
	chosenReferencer := anObject
]

{ #category : 'accessing' }
CoreTestableGbsSymbolListBrowserPresenter >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
CoreTestableGbsSymbolListBrowserPresenter >> lastOpenedOop [
	^ lastOpenedOop
]

{ #category : 'ui' }
CoreTestableGbsSymbolListBrowserPresenter >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'ui' }
CoreTestableGbsSymbolListBrowserPresenter >> openInspectorOnOop: anOop [
	lastOpenedOop := anOop.
	^ true
]
