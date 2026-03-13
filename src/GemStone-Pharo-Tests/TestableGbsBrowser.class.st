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
		'lastQueriedMode'
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
	lastQueriedSelector := selectorName.
	lastQueriedMode := modeString.
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
TestableGbsBrowser >> openQueryResults: references title: titleString [
	| selected |
	references isEmpty ifTrue: [ ^ false ].
	references size = 1 ifTrue: [ ^ self openMethodReference: references first ].
	selected := self uiChooseFrom: references title: titleString.
	selected = 0 ifTrue: [ ^ false ].
	^ self openMethodReference: (references at: selected)
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
