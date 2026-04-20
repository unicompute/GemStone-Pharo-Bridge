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
	'lastBrowsedMethodObject',
	'lastBrowsedReference',
	'requestAnswers',
	'chooseAnswers',
	'lastInspectedOop',
	'lastProvenanceGraph'
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
	requestAnswers := OrderedCollection new.
	chooseAnswers := OrderedCollection new
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

{ #category : 'private' }
TestableGbsMethodQueryResultsPresenter >> browseMethodObject: aMethodObject [
	lastBrowsedMethodObject := aMethodObject.
	^ true
]

{ #category : 'private' }
TestableGbsMethodQueryResultsPresenter >> browseMethodReference: referenceString [
	lastBrowsedReference := referenceString.
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

{ #category : 'testing' }
TestableGbsMethodQueryResultsPresenter >> enqueueChooseAnswer: anInteger [
	chooseAnswers add: anInteger
]

{ #category : 'private' }
TestableGbsMethodQueryResultsPresenter >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'private' }
TestableGbsMethodQueryResultsPresenter >> uiChooseFrom: choices title: titleString [
	^ chooseAnswers
		ifEmpty: [ 0 ]
		ifNotEmpty: [ chooseAnswers removeFirst ]
]

{ #category : 'private' }
TestableGbsMethodQueryResultsPresenter >> openInspectorOnOop: anOop [
	lastInspectedOop := anOop.
	^ true
]

{ #category : 'private' }
TestableGbsMethodQueryResultsPresenter >> openRubyRuntimeProvenanceBrowserFor: aGraph title: aTitle [
	lastProvenanceGraph := aGraph.
	lastInfoMessage := aTitle.
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

{ #category : 'accessing' }
TestableGbsMethodQueryResultsPresenter >> lastBrowsedMethodObject [
	^ lastBrowsedMethodObject
]

{ #category : 'accessing' }
TestableGbsMethodQueryResultsPresenter >> lastBrowsedReference [
	^ lastBrowsedReference
]

{ #category : 'accessing' }
TestableGbsMethodQueryResultsPresenter >> lastProvenanceGraph [
	^ lastProvenanceGraph
]
