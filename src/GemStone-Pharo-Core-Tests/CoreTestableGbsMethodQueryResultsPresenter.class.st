Class {
	#name : 'CoreTestableGbsMethodQueryResultsPresenter',
	#superclass : 'GbsMethodQueryResultsPresenter',
	#instVars : [
		'testSelectedReference',
		'lastMode',
		'lastPrefix',
		'lastScope',
		'lastInfoMessage',
		'lastReferenceClassName',
		'lastBrowsedMethodObject',
		'lastBrowsedReference',
		'requestAnswers',
		'chooseAnswers',
		'lastInspectedOop',
		'lastProvenanceGraph'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'testing' }
CoreTestableGbsMethodQueryResultsPresenter >> selectedReference: aString [
	testSelectedReference := aString
]

{ #category : 'initialization' }
CoreTestableGbsMethodQueryResultsPresenter >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new.
	chooseAnswers := OrderedCollection new
]

{ #category : 'private' }
CoreTestableGbsMethodQueryResultsPresenter >> selectedReference [
	^ testSelectedReference
]

{ #category : 'private' }
CoreTestableGbsMethodQueryResultsPresenter >> openQueryForSelectedSelectorMode: modeString titlePrefix: prefixString hierarchyScope: scopeString [
	lastMode := modeString.
	lastPrefix := prefixString.
	lastScope := scopeString.
	^ true
]

{ #category : 'private' }
CoreTestableGbsMethodQueryResultsPresenter >> browseMethodObject: aMethodObject [
	lastBrowsedMethodObject := aMethodObject.
	^ true
]

{ #category : 'private' }
CoreTestableGbsMethodQueryResultsPresenter >> browseMethodReference: referenceString [
	lastBrowsedReference := referenceString.
	^ true
]

{ #category : 'actions' }
CoreTestableGbsMethodQueryResultsPresenter >> browseReferencesToSelectedClass [
	lastReferenceClassName := self selectedReferenceClassName.
	^ true
]

{ #category : 'private' }
CoreTestableGbsMethodQueryResultsPresenter >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'testing' }
CoreTestableGbsMethodQueryResultsPresenter >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'testing' }
CoreTestableGbsMethodQueryResultsPresenter >> enqueueChooseAnswer: anInteger [
	chooseAnswers add: anInteger
]

{ #category : 'private' }
CoreTestableGbsMethodQueryResultsPresenter >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'private' }
CoreTestableGbsMethodQueryResultsPresenter >> uiChooseFrom: choices title: titleString [
	^ chooseAnswers
		ifEmpty: [ 0 ]
		ifNotEmpty: [ chooseAnswers removeFirst ]
]

{ #category : 'private' }
CoreTestableGbsMethodQueryResultsPresenter >> openInspectorOnOop: anOop [
	lastInspectedOop := anOop.
	^ true
]

{ #category : 'private' }
CoreTestableGbsMethodQueryResultsPresenter >> openRubyRuntimeProvenanceBrowserFor: aGraph title: aTitle [
	lastProvenanceGraph := aGraph.
	lastInfoMessage := aTitle.
	^ true
]

{ #category : 'accessing' }
CoreTestableGbsMethodQueryResultsPresenter >> lastMode [
	^ lastMode
]

{ #category : 'accessing' }
CoreTestableGbsMethodQueryResultsPresenter >> lastPrefix [
	^ lastPrefix
]

{ #category : 'accessing' }
CoreTestableGbsMethodQueryResultsPresenter >> lastScope [
	^ lastScope
]

{ #category : 'accessing' }
CoreTestableGbsMethodQueryResultsPresenter >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
CoreTestableGbsMethodQueryResultsPresenter >> lastReferenceClassName [
	^ lastReferenceClassName
]

{ #category : 'accessing' }
CoreTestableGbsMethodQueryResultsPresenter >> lastInspectedOop [
	^ lastInspectedOop
]

{ #category : 'accessing' }
CoreTestableGbsMethodQueryResultsPresenter >> lastBrowsedMethodObject [
	^ lastBrowsedMethodObject
]

{ #category : 'accessing' }
CoreTestableGbsMethodQueryResultsPresenter >> lastBrowsedReference [
	^ lastBrowsedReference
]

{ #category : 'accessing' }
CoreTestableGbsMethodQueryResultsPresenter >> lastProvenanceGraph [
	^ lastProvenanceGraph
]
