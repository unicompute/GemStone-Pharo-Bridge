Class {
	#name : 'GemStonePharoLaneRunnerTest',
	#superclass : 'TestCase',
	#instVars : [
		'runner',
		'logLines'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GemStonePharoLaneRunnerTest >> setUp [
	super setUp.
	logLines := OrderedCollection new.
	runner := GemStonePharoLaneRunner
		onEnvironment: Dictionary new
		log: [ :line | logLines add: line ]
]

{ #category : 'tests' }
GemStonePharoLaneRunnerTest >> testLaneDefaultsToAll [
	self assert: runner laneName equals: 'all'.
	self deny: runner isLiveLane
]

{ #category : 'tests' }
GemStonePharoLaneRunnerTest >> testLoadGroupNameDefaultsToDefault [
	self
		assert: (GemStonePharoLaneRunner loadGroupNameFromEnvironment: Dictionary new)
		equals: 'default'
]

{ #category : 'tests' }
GemStonePharoLaneRunnerTest >> testLoadGroupNameReadsEnvironmentOverride [
	self
		assert: (GemStonePharoLaneRunner
			loadGroupNameFromEnvironment: (Dictionary newFromPairs: { 'GBS_LOAD_GROUP'. 'Core-Tests' }))
		equals: 'Core-Tests'
]

{ #category : 'tests' }
GemStonePharoLaneRunnerTest >> testUnknownLaneFallsBackToAllContractSpec [
	runner := GemStonePharoLaneRunner
		onEnvironment: (Dictionary newFromPairs: { 'GBS_TEST_LANE'. 'nonesuch' })
		log: [ :line | logLines add: line ].

	self assert: runner laneName equals: 'all'.
	self assert: runner regressionLabel equals: 'BRIDGE_REGRESSION'
]

{ #category : 'tests' }
GemStonePharoLaneRunnerTest >> testPackageFilterTokensParsesCommaSeparatedList [
	runner := GemStonePharoLaneRunner
		onEnvironment: (Dictionary newFromPairs: {
			'GBS_TEST_PACKAGES'. ' GemStone-Pharo-Core-Tests, GemStone-Pharo-Tests ' })
		log: [ :line | logLines add: line ].

	self
		assert: runner packageFilterTokens asArray
		equals: #('GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Tests')
]

{ #category : 'tests' }
GemStonePharoLaneRunnerTest >> testHasRequiredPackagesLoadedUsesLoadGroupMembership [
	runner := GemStonePharoLaneRunnerTestRunner
		onEnvironment: (Dictionary newFromPairs: { 'GBS_LOAD_GROUP'. 'Core-Tests' })
		log: [ :line | logLines add: line ].
	runner loadedPackageNames: #('GemStone-GBS-Converted' 'GemStone-GBS-Tools' 'GemStone-Pharo-Core-Tests').
	self assert: runner hasRequiredPackagesLoaded.
	runner loadedPackageNames: #('GemStone-GBS-Converted' 'GemStone-GBS-Tools').
	self deny: runner hasRequiredPackagesLoaded
]

{ #category : 'tests' }
GemStonePharoLaneRunnerTest >> testRegressionLabelReflectsLane [
	self assert: runner regressionLabel equals: 'BRIDGE_REGRESSION'.
	runner := GemStonePharoLaneRunner
		onEnvironment: (Dictionary newFromPairs: { 'GBS_TEST_LANE'. 'unit' })
		log: [ :line | logLines add: line ].
	self assert: runner regressionLabel equals: 'BRIDGE_UNIT_REGRESSION'.
	runner := GemStonePharoLaneRunner
		onEnvironment: (Dictionary newFromPairs: { 'GBS_TEST_LANE'. 'live' })
		log: [ :line | logLines add: line ].
	self assert: runner regressionLabel equals: 'BRIDGE_LIVE_REGRESSION'.
	self assert: runner isLiveLane
]

{ #category : 'tests' }
GemStonePharoLaneRunnerTest >> testSelectedTestsFromClassesForAllLaneKeepsBothUnitAndIntegration [
	| selected selectors |
	selected := runner selectedTestsFromClasses: { GemStonePharoLaneRunnerExampleTest }.
	selectors := (selected collect: #selector) asSet.

	self assert: selectors equals: #(testExampleIntegrationSelection testExampleUnitSelection) asSet
]

{ #category : 'tests' }
GemStonePharoLaneRunnerTest >> testSelectedTestsFromClassesForLiveLaneKeepsOnlyIntegration [
	| selected selectors |
	runner := GemStonePharoLaneRunner
		onEnvironment: (Dictionary newFromPairs: { 'GBS_TEST_LANE'. 'live' })
		log: [ :line | logLines add: line ].
	selected := runner selectedTestsFromClasses: { GemStonePharoLaneRunnerExampleTest }.
	selectors := (selected collect: #selector) asSet.

	self assert: selectors equals: #(testExampleIntegrationSelection) asSet
]

{ #category : 'tests' }
GemStonePharoLaneRunnerTest >> testSelectedTestsFromClassesForUnitLaneKeepsOnlyUnit [
	| selected selectors |
	runner := GemStonePharoLaneRunner
		onEnvironment: (Dictionary newFromPairs: { 'GBS_TEST_LANE'. 'unit' })
		log: [ :line | logLines add: line ].
	selected := runner selectedTestsFromClasses: { GemStonePharoLaneRunnerExampleTest }.
	selectors := (selected collect: #selector) asSet.

	self assert: selectors equals: #(testExampleUnitSelection) asSet
]
