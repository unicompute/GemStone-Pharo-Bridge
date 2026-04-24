Class {
	#name : 'CoreTestableGbsClassicLauncher',
	#superclass : 'GbsClassicLauncher',
	#instVars : [
		'forcedSession',
		'requestedDictionaryName',
		'infoMessages',
		'lastOpenedSession',
		'lastOpenedDictionary',
		'openBrowserCalls',
		'lastInspectedOop',
		'lastInspectedSession'
	],
	#classVars : [
		'ChooseAnswers',
		'LastHierarchyMode',
		'LastHierarchyQuery',
		'LastHierarchyRootClass',
		'LastHierarchyScope',
		'LastOpenedReferences',
		'LastOpenedTitle',
		'RequestAnswers'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'testing' }
CoreTestableGbsClassicLauncher class >> resetClassHarness [
	RequestAnswers := OrderedCollection new.
	ChooseAnswers := OrderedCollection new.
	LastHierarchyQuery := nil.
	LastHierarchyMode := nil.
	LastHierarchyRootClass := nil.
	LastHierarchyScope := nil.
	LastOpenedReferences := nil.
	LastOpenedTitle := nil
]

{ #category : 'testing' }
CoreTestableGbsClassicLauncher class >> enqueueRequestAnswer: aStringOrNil [
	RequestAnswers ifNil: [ self resetClassHarness ].
	RequestAnswers add: aStringOrNil
]

{ #category : 'testing' }
CoreTestableGbsClassicLauncher class >> enqueueChooseAnswer: anInteger [
	ChooseAnswers ifNil: [ self resetClassHarness ].
	ChooseAnswers add: anInteger
]

{ #category : 'menus' }
CoreTestableGbsClassicLauncher class >> uiRequest: promptString initialAnswer: defaultString [
	RequestAnswers ifNil: [ self resetClassHarness ].
	^ RequestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ RequestAnswers removeFirst ]
]

{ #category : 'menus' }
CoreTestableGbsClassicLauncher class >> uiChooseFrom: labels title: titleString [
	ChooseAnswers ifNil: [ self resetClassHarness ].
	^ ChooseAnswers
		ifEmpty: [ 0 ]
		ifNotEmpty: [ ChooseAnswers removeFirst ]
]

{ #category : 'menus' }
CoreTestableGbsClassicLauncher class >> hierarchyQueryReferencesFor: tokenString mode: modeString inSession: aSession rootClassName: rootClassName scope: scopeString [
	LastHierarchyQuery := tokenString.
	LastHierarchyMode := modeString.
	LastHierarchyRootClass := rootClassName.
	LastHierarchyScope := scopeString.
	^ #('Object>>size')
]

{ #category : 'menus' }
CoreTestableGbsClassicLauncher class >> openQueryResultsPresenterOn: session references: references title: titleString [
	LastOpenedReferences := references.
	LastOpenedTitle := titleString.
	^ true
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher class >> lastHierarchyQuery [
	^ LastHierarchyQuery
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher class >> lastHierarchyMode [
	^ LastHierarchyMode
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher class >> lastHierarchyRootClass [
	^ LastHierarchyRootClass
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher class >> lastHierarchyScope [
	^ LastHierarchyScope
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher class >> lastOpenedReferences [
	^ LastOpenedReferences
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher class >> lastOpenedTitle [
	^ LastOpenedTitle
]

{ #category : 'private' }
CoreTestableGbsClassicLauncher >> sessionForBrowsing [
	^ forcedSession
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher >> forcedSession: anObject [
	forcedSession := anObject
]

{ #category : 'private' }
CoreTestableGbsClassicLauncher >> requestSymbolDictionaryName [
	^ requestedDictionaryName ifNil: [ '' ]
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher >> requestedDictionaryName: aString [
	requestedDictionaryName := aString
]

{ #category : 'private' }
CoreTestableGbsClassicLauncher >> openBrowserOn: aSession dictionary: aDictionaryName [
	openBrowserCalls := self openBrowserCalls + 1.
	lastOpenedSession := aSession.
	lastOpenedDictionary := aDictionaryName.
	^ self
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher >> openBrowserCalls [
	^ openBrowserCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher >> lastOpenedSession [
	^ lastOpenedSession
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher >> lastOpenedDictionary [
	^ lastOpenedDictionary
]

{ #category : 'ui' }
CoreTestableGbsClassicLauncher >> inform: aString [
	self infoMessages add: aString.
	^ aString
]

{ #category : 'private' }
CoreTestableGbsClassicLauncher >> inspectOop: anOop session: aSession [
	lastInspectedOop := anOop.
	lastInspectedSession := aSession.
	^ anOop
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher >> infoMessages [
	^ infoMessages ifNil: [ infoMessages := OrderedCollection new ]
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher >> lastInspectedOop [
	^ lastInspectedOop
]

{ #category : 'accessing' }
CoreTestableGbsClassicLauncher >> lastInspectedSession [
	^ lastInspectedSession
]
