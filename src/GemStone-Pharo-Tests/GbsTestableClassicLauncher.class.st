Class {
	#name : 'GbsTestableClassicLauncher',
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
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'testing' }
GbsTestableClassicLauncher class >> resetClassHarness [
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
GbsTestableClassicLauncher class >> enqueueRequestAnswer: aStringOrNil [
	RequestAnswers ifNil: [ self resetClassHarness ].
	RequestAnswers add: aStringOrNil
]

{ #category : 'testing' }
GbsTestableClassicLauncher class >> enqueueChooseAnswer: anInteger [
	ChooseAnswers ifNil: [ self resetClassHarness ].
	ChooseAnswers add: anInteger
]

{ #category : 'menus' }
GbsTestableClassicLauncher class >> uiRequest: promptString initialAnswer: defaultString [
	RequestAnswers ifNil: [ self resetClassHarness ].
	^ RequestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ RequestAnswers removeFirst ]
]

{ #category : 'menus' }
GbsTestableClassicLauncher class >> uiChooseFrom: labels title: titleString [
	ChooseAnswers ifNil: [ self resetClassHarness ].
	^ ChooseAnswers
		ifEmpty: [ 0 ]
		ifNotEmpty: [ ChooseAnswers removeFirst ]
]

{ #category : 'menus' }
GbsTestableClassicLauncher class >> hierarchyQueryReferencesFor: tokenString mode: modeString inSession: aSession rootClassName: rootClassName scope: scopeString [
	LastHierarchyQuery := tokenString.
	LastHierarchyMode := modeString.
	LastHierarchyRootClass := rootClassName.
	LastHierarchyScope := scopeString.
	^ #('Object>>size')
]

{ #category : 'menus' }
GbsTestableClassicLauncher class >> openQueryResultsPresenterOn: session references: references title: titleString [
	LastOpenedReferences := references.
	LastOpenedTitle := titleString.
	^ true
]

{ #category : 'accessing' }
GbsTestableClassicLauncher class >> lastHierarchyQuery [
	^ LastHierarchyQuery
]

{ #category : 'accessing' }
GbsTestableClassicLauncher class >> lastHierarchyMode [
	^ LastHierarchyMode
]

{ #category : 'accessing' }
GbsTestableClassicLauncher class >> lastHierarchyRootClass [
	^ LastHierarchyRootClass
]

{ #category : 'accessing' }
GbsTestableClassicLauncher class >> lastHierarchyScope [
	^ LastHierarchyScope
]

{ #category : 'accessing' }
GbsTestableClassicLauncher class >> lastOpenedReferences [
	^ LastOpenedReferences
]

{ #category : 'accessing' }
GbsTestableClassicLauncher class >> lastOpenedTitle [
	^ LastOpenedTitle
]

{ #category : 'private' }
GbsTestableClassicLauncher >> sessionForBrowsing [
	^ forcedSession
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> forcedSession: anObject [
	forcedSession := anObject
]

{ #category : 'private' }
GbsTestableClassicLauncher >> requestSymbolDictionaryName [
	^ requestedDictionaryName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> requestedDictionaryName: aString [
	requestedDictionaryName := aString
]

{ #category : 'private' }
GbsTestableClassicLauncher >> openBrowserOn: aSession dictionary: aDictionaryName [
	openBrowserCalls := self openBrowserCalls + 1.
	lastOpenedSession := aSession.
	lastOpenedDictionary := aDictionaryName.
	^ self
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> openBrowserCalls [
	^ openBrowserCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> lastOpenedSession [
	^ lastOpenedSession
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> lastOpenedDictionary [
	^ lastOpenedDictionary
]

{ #category : 'ui' }
GbsTestableClassicLauncher >> inform: aString [
	self infoMessages add: aString.
	^ aString
]

{ #category : 'private' }
GbsTestableClassicLauncher >> inspectOop: anOop session: aSession [
	lastInspectedOop := anOop.
	lastInspectedSession := aSession.
	^ anOop
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> infoMessages [
	^ infoMessages ifNil: [ infoMessages := OrderedCollection new ]
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> lastInspectedOop [
	^ lastInspectedOop
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> lastInspectedSession [
	^ lastInspectedSession
]
