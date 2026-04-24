Class {
	#name : 'TestableGbsMethodQueryResultsPresenter',
	#superclass : 'GbsMethodQueryResultsPresenter',
	#instVars : [
		'testSelectedReference',
		'lastMode',
		'lastPrefix',
		'lastScope'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'testing' }
TestableGbsMethodQueryResultsPresenter >> selectedReference: aString [
	testSelectedReference := aString
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
