Class {
	#name : 'TestableGbsBrowser',
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
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
TestableGbsBrowser >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new.
	chooseAnswers := OrderedCollection new.
	queryResultsByMode := Dictionary new
]

{ #category : 'testing' }
TestableGbsBrowser >> enableCompileSpy [
	compileSpyEnabled := true
]

{ #category : 'actions' }
TestableGbsBrowser >> compileMethod: newSource [
	compileSpyEnabled ifTrue: [
		lastCompileSource := newSource.
		^ #compiled
	].
	^ super compileMethod: newSource
]

{ #category : 'testing' }
TestableGbsBrowser >> runSuperCompileMethod: newSource [
	^ super compileMethod: newSource
]

{ #category : 'ui' }
TestableGbsBrowser >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'actions' }
TestableGbsBrowser >> protocolSelected: protocolName [
	lastProtocolSelected := protocolName
]

{ #category : 'testing' }
TestableGbsBrowser >> runSuperProtocolSelected: protocolName [
	^ super protocolSelected: protocolName
]

{ #category : 'testing' }
TestableGbsBrowser >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'testing' }
TestableGbsBrowser >> enqueueChooseAnswer: anInteger [
	chooseAnswers add: anInteger
]

{ #category : 'testing' }
TestableGbsBrowser >> queryResults: aCollection forMode: modeString [
	queryResultsByMode at: modeString put: aCollection asArray
]

{ #category : 'private' }
TestableGbsBrowser >> uiRequest: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]

{ #category : 'private' }
TestableGbsBrowser >> uiChooseFrom: choices title: titleString [
	^ chooseAnswers
		ifEmpty: [ 0 ]
		ifNotEmpty: [ chooseAnswers removeFirst ]
]

{ #category : 'private' }
TestableGbsBrowser >> queryServerMethodsForSelector: selectorName mode: modeString [
	^ self queryServerMethodsForSelector: selectorName mode: modeString rootClassName: nil hierarchyScope: 'full'
]

{ #category : 'private' }
TestableGbsBrowser >> queryServerMethodsForSelector: selectorName mode: modeString rootClassName: rootClassName [
	^ self queryServerMethodsForSelector: selectorName mode: modeString rootClassName: rootClassName hierarchyScope: 'full'
]

{ #category : 'private' }
TestableGbsBrowser >> queryServerMethodsForSelector: selectorName mode: modeString rootClassName: rootClassName hierarchyScope: scopeString [
	lastQueriedSelector := selectorName.
	lastQueriedMode := modeString.
	lastQueriedRootClass := rootClassName.
	lastQueriedHierarchyScope := scopeString.
	^ queryResultsByMode at: modeString ifAbsent: [ #() ]
]

{ #category : 'private' }
TestableGbsBrowser >> queryMatchingSelectorsForPattern: patternString [
	^ { patternString }
]

{ #category : 'private' }
TestableGbsBrowser >> openMethodReference: referenceString [
	lastOpenedReference := referenceString.
	^ true
]

{ #category : 'private' }
TestableGbsBrowser >> inspectOop: anOop [
	lastInspectedOop := anOop.
	^ true
]

{ #category : 'private' }
TestableGbsBrowser >> openQueryResults: references title: titleString [
	| selected |
	references isEmpty ifTrue: [ ^ false ].
	references size = 1 ifTrue: [ ^ self openMethodReference: references first ].
	selected := self uiChooseFrom: references title: titleString.
	selected = 0 ifTrue: [ ^ false ].
	^ self openMethodReference: (references at: selected)
]

{ #category : 'private' }
TestableGbsBrowser >> openRubyRuntimeProvenanceBrowserFor: aGraph title: aTitle [
	lastProvenanceGraph := aGraph.
	lastInfoMessage := aTitle.
	^ true
]

{ #category : 'private' }
TestableGbsBrowser >> openObjectLogBrowserFor: anObjectLog title: aTitle [
	lastObjectLog := anObjectLog.
	lastInfoMessage := aTitle.
	^ true
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastProtocolSelected [
	^ lastProtocolSelected
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastCompileSource [
	^ lastCompileSource
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastOpenedReference [
	^ lastOpenedReference
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastQueriedSelector [
	^ lastQueriedSelector
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastQueriedMode [
	^ lastQueriedMode
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastQueriedRootClass [
	^ lastQueriedRootClass
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastQueriedHierarchyScope [
	^ lastQueriedHierarchyScope
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastInspectedOop [
	^ lastInspectedOop
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastProvenanceGraph [
	^ lastProvenanceGraph
]

{ #category : 'accessing' }
TestableGbsBrowser >> lastObjectLog [
	^ lastObjectLog
]
