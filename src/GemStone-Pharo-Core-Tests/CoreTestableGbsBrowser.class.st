Class {
	#name : 'CoreTestableGbsBrowser',
	#superclass : 'GbsBrowser',
	#instVars : [
		'lastInfoMessage',
		'lastProtocolSelected',
		'lastCompileSource',
		'compileSpyEnabled',
		'requestAnswers',
		'chooseAnswers',
		'queryResultsByMode',
		'lastOpenedReference',
		'lastQueriedSelector',
		'lastQueriedMode',
		'lastQueriedRootClass',
		'lastQueriedHierarchyScope',
		'lastInspectedOop',
		'lastProvenanceGraph',
		'lastObjectLog'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'initialization' }
CoreTestableGbsBrowser >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new.
	chooseAnswers := OrderedCollection new.
	queryResultsByMode := Dictionary new
]

{ #category : 'testing' }
CoreTestableGbsBrowser >> enableCompileSpy [
	compileSpyEnabled := true
]

{ #category : 'actions' }
CoreTestableGbsBrowser >> compileMethod: newSource [
	compileSpyEnabled ifTrue: [
		lastCompileSource := newSource.
		^ #compiled
	].
	^ super compileMethod: newSource
]

{ #category : 'testing' }
CoreTestableGbsBrowser >> runSuperCompileMethod: newSource [
	^ super compileMethod: newSource
]

{ #category : 'ui' }
CoreTestableGbsBrowser >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'actions' }
CoreTestableGbsBrowser >> protocolSelected: protocolName [
	lastProtocolSelected := protocolName
]

{ #category : 'testing' }
CoreTestableGbsBrowser >> runSuperProtocolSelected: protocolName [
	^ super protocolSelected: protocolName
]

{ #category : 'testing' }
CoreTestableGbsBrowser >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'testing' }
CoreTestableGbsBrowser >> enqueueChooseAnswer: anInteger [
	chooseAnswers add: anInteger
]

{ #category : 'testing' }
CoreTestableGbsBrowser >> queryResults: aCollection forMode: modeString [
	queryResultsByMode at: modeString put: aCollection asArray
]

{ #category : 'private' }
CoreTestableGbsBrowser >> uiRequest: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'private' }
CoreTestableGbsBrowser >> uiChooseFrom: choices title: titleString [
	^ chooseAnswers
		ifEmpty: [ 0 ]
		ifNotEmpty: [ chooseAnswers removeFirst ]
]

{ #category : 'private' }
CoreTestableGbsBrowser >> queryServerMethodsForSelector: selectorName mode: modeString [
	^ self queryServerMethodsForSelector: selectorName mode: modeString rootClassName: nil hierarchyScope: 'full'
]

{ #category : 'private' }
CoreTestableGbsBrowser >> queryServerMethodsForSelector: selectorName mode: modeString rootClassName: rootClassName [
	^ self queryServerMethodsForSelector: selectorName mode: modeString rootClassName: rootClassName hierarchyScope: 'full'
]

{ #category : 'private' }
CoreTestableGbsBrowser >> queryServerMethodsForSelector: selectorName mode: modeString rootClassName: rootClassName hierarchyScope: scopeString [
	lastQueriedSelector := selectorName.
	lastQueriedMode := modeString.
	lastQueriedRootClass := rootClassName.
	lastQueriedHierarchyScope := scopeString.
	^ queryResultsByMode at: modeString ifAbsent: [ #() ]
]

{ #category : 'private' }
CoreTestableGbsBrowser >> queryMatchingSelectorsForPattern: patternString [
	^ { patternString }
]

{ #category : 'private' }
CoreTestableGbsBrowser >> openMethodReference: referenceString [
	lastOpenedReference := referenceString.
	^ true
]

{ #category : 'private' }
CoreTestableGbsBrowser >> inspectOop: anOop [
	lastInspectedOop := anOop.
	^ true
]

{ #category : 'private' }
CoreTestableGbsBrowser >> openQueryResults: references title: titleString [
	| selected |
	references isEmpty ifTrue: [ ^ false ].
	references size = 1 ifTrue: [ ^ self openMethodReference: references first ].
	selected := self uiChooseFrom: references title: titleString.
	selected = 0 ifTrue: [ ^ false ].
	^ self openMethodReference: (references at: selected)
]

{ #category : 'private' }
CoreTestableGbsBrowser >> openRubyRuntimeProvenanceBrowserFor: aGraph title: aTitle [
	lastProvenanceGraph := aGraph.
	lastInfoMessage := aTitle.
	^ true
]

{ #category : 'private' }
CoreTestableGbsBrowser >> openObjectLogBrowserFor: anObjectLog title: aTitle [
	lastObjectLog := anObjectLog.
	lastInfoMessage := aTitle.
	^ true
]

{ #category : 'accessing' }
CoreTestableGbsBrowser >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
CoreTestableGbsBrowser >> lastProtocolSelected [
	^ lastProtocolSelected
]

{ #category : 'accessing' }
CoreTestableGbsBrowser >> lastCompileSource [
	^ lastCompileSource
]

{ #category : 'accessing' }
CoreTestableGbsBrowser >> lastOpenedReference [
	^ lastOpenedReference
]

{ #category : 'accessing' }
CoreTestableGbsBrowser >> lastQueriedSelector [
	^ lastQueriedSelector
]

{ #category : 'accessing' }
CoreTestableGbsBrowser >> lastQueriedMode [
	^ lastQueriedMode
]

{ #category : 'accessing' }
CoreTestableGbsBrowser >> lastQueriedRootClass [
	^ lastQueriedRootClass
]

{ #category : 'accessing' }
CoreTestableGbsBrowser >> lastQueriedHierarchyScope [
	^ lastQueriedHierarchyScope
]

{ #category : 'accessing' }
CoreTestableGbsBrowser >> lastInspectedOop [
	^ lastInspectedOop
]

{ #category : 'accessing' }
CoreTestableGbsBrowser >> lastProvenanceGraph [
	^ lastProvenanceGraph
]

{ #category : 'accessing' }
CoreTestableGbsBrowser >> lastObjectLog [
	^ lastObjectLog
]
