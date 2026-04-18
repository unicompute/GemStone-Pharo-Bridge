Class {
	#name : 'TestableGbsMethodQueryResultsPresenter',
	#superclass : 'GbsMethodQueryResultsPresenter',
	#instVars : [
		'testSelectedReference',
		'lastMode',
		'lastPrefix',
		'lastScope',
		'lastInfoMessage',
		'lastReferenceClassName',
		'requestAnswers',
		'lastInspectedOop'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'testing' }
TestableGbsMethodQueryResultsPresenter >> selectedReference: aString [
	testSelectedReference := aString
]

{ #category : 'initialization' }
TestableGbsMethodQueryResultsPresenter >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new
]

{ #category : 'private' }
TestableGbsMethodQueryResultsPresenter >> selectedReference [
	^ testSelectedReference
]

{ #category : 'private' }
TestableGbsMethodQueryResultsPresenter >> openQueryForSelectedSelectorMode: modeString titlePrefix: prefixString hierarchyScope: scopeString [
	lastMode := modeString.
	lastPrefix := prefixString.
	lastScope := scopeString.
	^ true
]

{ #category : 'actions' }
TestableGbsMethodQueryResultsPresenter >> browseReferencesToSelectedClass [
	lastReferenceClassName := self selectedReferenceClassName.
	^ true
]

{ #category : 'private' }
TestableGbsMethodQueryResultsPresenter >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'testing' }
TestableGbsMethodQueryResultsPresenter >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'private' }
TestableGbsMethodQueryResultsPresenter >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'private' }
TestableGbsMethodQueryResultsPresenter >> openInspectorOnOop: anOop [
	lastInspectedOop := anOop.
	^ true
]

{ #category : 'accessing' }
TestableGbsMethodQueryResultsPresenter >> lastMode [
	^ lastMode
]

{ #category : 'accessing' }
TestableGbsMethodQueryResultsPresenter >> lastPrefix [
	^ lastPrefix
]

{ #category : 'accessing' }
TestableGbsMethodQueryResultsPresenter >> lastScope [
	^ lastScope
]

{ #category : 'accessing' }
TestableGbsMethodQueryResultsPresenter >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
TestableGbsMethodQueryResultsPresenter >> lastReferenceClassName [
	^ lastReferenceClassName
]

{ #category : 'accessing' }
TestableGbsMethodQueryResultsPresenter >> lastInspectedOop [
	^ lastInspectedOop
]
