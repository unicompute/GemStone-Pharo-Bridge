Class {
	#name : 'GemStonePharoLaneRunner',
	#superclass : 'Object',
	#instVars : [
		'environment',
		'baselineContract',
		'logBlock'
	],
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'instance creation' }
GemStonePharoLaneRunner class >> onEnvironment: anEnvironment log: aBlock [
	^ self new
		environment: anEnvironment;
		baselineContract: GemStonePharoContract new;
		logBlock: aBlock;
		yourself
]

{ #category : 'instance creation' }
GemStonePharoLaneRunner class >> baselineName [
	^ GemStonePharoReloadRunner baselineName
]

{ #category : 'instance creation' }
GemStonePharoLaneRunner class >> baselineRepositoryUrl [
	^ GemStonePharoReloadRunner baselineRepositoryUrl
]

{ #category : 'instance creation' }
GemStonePharoLaneRunner class >> loadBaselineOnEnvironment: anEnvironment log: aBlock [
	| loadGroup |
	loadGroup := self loadGroupNameFromEnvironment: anEnvironment.
	^ [ Metacello new
		baseline: self baselineName;
		repository: self baselineRepositoryUrl;
		load: { loadGroup }.
	true ]
		on: Error
		do: [ :ex |
			aBlock value: 'LOAD_ERROR: ', ex messageText.
			false ]
]

{ #category : 'instance creation' }
GemStonePharoLaneRunner class >> loadGroupNameFromEnvironment: anEnvironment [
	^ GemStonePharoReloadRunner loadGroupNameFromEnvironment: anEnvironment
]

{ #category : 'instance creation' }
GemStonePharoLaneRunner class >> runOnEnvironment: anEnvironment log: aBlock [
	^ (self onEnvironment: anEnvironment log: aBlock)
		runRegressionLaneEnsuringSessionRelease
]

{ #category : 'instance creation' }
GemStonePharoLaneRunner class >> runLoadingBaselineAndRegressionOnEnvironment: anEnvironment log: aBlock [
	| runner |
	runner := self onEnvironment: anEnvironment log: aBlock.
	runner hasRequiredPackagesLoaded
		ifFalse: [
			(self loadBaselineOnEnvironment: anEnvironment log: aBlock)
				ifFalse: [ ^ false ] ].
	^ runner runRegressionLaneEnsuringSessionRelease
]

{ #category : 'private' }
GemStonePharoLaneRunner >> candidateTestClasses [
	^ (Smalltalk allClasses
		select: [ :each |
			(each inheritsFrom: TestCase)
				and: [ | packageName filterTokens |
					packageName := each package name.
					filterTokens := self packageFilterTokens.
					filterTokens
						ifNil: [ packageName beginsWith: 'GemStone-Pharo-' ]
						ifNotNil: [ filterTokens includes: packageName ] ] ])
		asSortedCollection: [ :a :b | a name <= b name ]
]

{ #category : 'private' }
GemStonePharoLaneRunner >> baselineContract [
	^ baselineContract ifNil: [ GemStonePharoContract new ]
]

{ #category : 'private' }
GemStonePharoLaneRunner >> baselineContract: aContract [
	baselineContract := aContract
]

{ #category : 'private' }
GemStonePharoLaneRunner >> environment [
	^ environment ifNil: [ Smalltalk os environment ]
]

{ #category : 'private' }
GemStonePharoLaneRunner >> environment: anEnvironment [
	environment := anEnvironment
]

{ #category : 'private' }
GemStonePharoLaneRunner >> environmentAt: aString ifAbsent: aBlock [
	^ [ self environment at: aString ifAbsent: aBlock ]
		on: Error
		do: [ aBlock value ]
]

{ #category : 'private' }
GemStonePharoLaneRunner >> flattenTest: aCandidate into: aCollection [
	(aCandidate isKindOf: TestSuite)
		ifTrue: [ aCandidate tests do: [ :each | self flattenTest: each into: aCollection ] ]
		ifFalse: [ aCollection add: aCandidate ]
]

{ #category : 'private' }
GemStonePharoLaneRunner >> hasRequiredPackagesLoaded [
	| requiredPackages |
	requiredPackages := self requiredPackagesForLoadGroup.
	requiredPackages isEmpty ifTrue: [ ^ false ].
	^ requiredPackages allSatisfy: [ :packageName |
		self loadedPackageNames includes: packageName ]
]

{ #category : 'private' }
GemStonePharoLaneRunner >> hadFailureForResult: aResult skipped: skippedCount sessionReady: sessionReady [
	^ aResult failures notEmpty
		or: [ aResult errors notEmpty
		or: [ self isLiveLane and: [ sessionReady not ] ] ]
]

{ #category : 'private' }
GemStonePharoLaneRunner >> integrationProtocols [
	^ self baselineContract regressionIntegrationProtocols
]

{ #category : 'initialization' }
GemStonePharoLaneRunner >> initialize [
	super initialize.
	logBlock := [ :line | Transcript show: line; cr ]
]

{ #category : 'private' }
GemStonePharoLaneRunner >> isLiveLane [
	^ self laneSpec fourth
]

{ #category : 'private' }
GemStonePharoLaneRunner >> loadedPackageNames [
	| workingCopyClass |
	workingCopyClass := Smalltalk at: #MCWorkingCopy ifAbsent: [ nil ].
	workingCopyClass ifNil: [ ^ #() ].
	^ (workingCopyClass allWorkingCopies collect: [ :each | each packageName ]) asSet
]

{ #category : 'private' }
GemStonePharoLaneRunner >> laneName [
	^ self laneSpec first
]

{ #category : 'private' }
GemStonePharoLaneRunner >> laneSpec [
	^ self baselineContract
		regressionLaneSpecNamed: ((self environmentAt: 'GBS_TEST_LANE' ifAbsent: [ 'all' ]) asString) asLowercase
]

{ #category : 'private' }
GemStonePharoLaneRunner >> liveSessionSupportClass [
	^ Smalltalk
		at: #GbsLiveSessionTestSupport
		ifAbsent: [ Smalltalk at: #CoreGbsLiveSessionTestSupport ifAbsent: [ nil ] ]
]

{ #category : 'private' }
GemStonePharoLaneRunner >> log: aString [
	logBlock value: aString
]

{ #category : 'private' }
GemStonePharoLaneRunner >> logBlock: aBlock [
	logBlock := aBlock
]

{ #category : 'private' }
GemStonePharoLaneRunner >> packageFilterTokens [
	| packageFilter |
	packageFilter := ((self environmentAt: 'GBS_TEST_PACKAGES' ifAbsent: [ '' ]) asString) trimBoth.
	packageFilter isEmpty ifTrue: [ ^ nil ].
	^ (packageFilter findTokens: ',')
		collect: #trimBoth
		thenReject: #isEmpty
]

{ #category : 'private' }
GemStonePharoLaneRunner >> protocolForTest: aTestCase [
	^ [ (aTestCase class >> aTestCase selector) protocol name ]
		on: Error
		do: [ nil ]
]

{ #category : 'private' }
GemStonePharoLaneRunner >> requiredPackagesForLoadGroup [
	^ (self baselineContract groupMemberSpecs
		detect: [ :each | each first = (self class loadGroupNameFromEnvironment: self environment) ]
		ifNone: [ ^ #() ]) second
]

{ #category : 'private' }
GemStonePharoLaneRunner >> regressionLabel [
	^ self laneSpec second
]

{ #category : 'running' }
GemStonePharoLaneRunner >> runRegressionLane [
	| selectedTests result sessionReady failures errors skipped label hadFailure liveSessionSupportClass |
	sessionReady := true.
	self isLiveLane ifTrue: [
		liveSessionSupportClass := self liveSessionSupportClass.
		sessionReady := self sessionReadyForLiveSupportClass: liveSessionSupportClass ].
	selectedTests := self selectedTests.
	result := TestResult new.
	sessionReady ifTrue: [
		selectedTests do: [ :testCase |
			(self isLiveLane
				and: [ (self sessionReadyForLiveSupportClass: liveSessionSupportClass) not ]) ifTrue: [
				sessionReady := false ].
			sessionReady ifTrue: [ testCase run: result ] ] ].
	failures := result failures size.
	errors := result errors size.
	skipped := (result respondsTo: #skippedCount)
		ifTrue: [ result skippedCount ]
		ifFalse: [ 0 ].
	label := self regressionLabel.
	self
		log: label , ' CLASSES=' , ((selectedTests collect: [ :each | each class ]) asSet size asString),
			' RUN=' , result runCount asString,
			' FAIL=' , failures asString,
			' ERR=' , errors asString,
			' SKIP=' , skipped asString.
	failures > 0 ifTrue: [
		self log: 'FAILURES:'.
		result failures do: [ :each | self log: each printString ] ].
	errors > 0 ifTrue: [
		self log: 'ERRORS:'.
		result errors do: [ :each | self log: each printString ] ].
	hadFailure := self
		hadFailureForResult: result
		skipped: skipped
		sessionReady: sessionReady.
	self log: (hadFailure
		ifTrue: [ label , '_FAILED' ]
		ifFalse: [ label , '_OK' ]).
	^ hadFailure not
]

{ #category : 'running' }
GemStonePharoLaneRunner >> runRegressionLaneEnsuringSessionRelease [
	| liveSessionSupportClass |
	liveSessionSupportClass := self liveSessionSupportClass.
	^ [ self runRegressionLane ]
		ensure: [ liveSessionSupportClass ifNotNil: [ liveSessionSupportClass releaseOwnedSession ] ]
]

{ #category : 'private' }
GemStonePharoLaneRunner >> sessionReadyForLiveSupportClass: liveSessionSupportClass [
	| session |
	liveSessionSupportClass ifNil: [
		self log: 'LIVE_SESSION_ERROR: Live session support is not loaded.'.
		^ false ].
	session := liveSessionSupportClass ensureSharedSession.
	session ifNil: [
		self log: 'LIVE_SESSION_ERROR: ', liveSessionSupportClass unavailableReason.
		^ false ].
	(session respondsTo: #abortTransaction)
		ifTrue: [ [ session abortTransaction ] on: Error do: [ ] ].
	(self ensureTranscriptProxyInstalledOn: session)
		ifFalse: [
			self log: 'LIVE_SESSION_ERROR: transcript proxy installation failed.'.
			^ false ].
	^ true
]

{ #category : 'private' }
GemStonePharoLaneRunner >> ensureTranscriptProxyInstalledOn: aSession [
	^ (GemStonePharoVerificationRunner
		onEnvironment: self environment
		log: logBlock)
		ensureTranscriptProxyInstalledOn: aSession
]

{ #category : 'private' }
GemStonePharoLaneRunner >> selectedTests [
	^ self selectedTestsFromClasses: self candidateTestClasses
]

{ #category : 'private' }
GemStonePharoLaneRunner >> selectedTestsFromClasses: testClasses [
	| suite |
	suite := OrderedCollection new.
	testClasses do: [ :each |
		each suite tests do: [ :candidate |
			self flattenTest: candidate into: suite ] ].
	^ suite select: [ :testCase |
		| protocol isIntegration selectionMode |
		protocol := self protocolForTest: testCase.
		isIntegration := protocol notNil
			and: [ self integrationProtocols includes: protocol ].
		selectionMode := self laneSpec third.
		selectionMode = #excludeIntegration
			ifTrue: [ isIntegration not ]
			ifFalse: [
				selectionMode = #onlyIntegration
					ifTrue: [ isIntegration ]
					ifFalse: [ true ] ] ]
]
