Class {
	#name : 'GemStonePharoReloadRunnerTest',
	#superclass : 'TestCase',
	#instVars : [
		'runner',
		'logLines'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'private' }
GemStonePharoReloadRunnerTest >> newContract [
	^ GemStonePharoReloadGuardsTestContract new
]

{ #category : 'private' }
GemStonePharoReloadRunnerTest >> newGuards [
	^ GemStonePharoReloadRunnerTestGuards new
]

{ #category : 'running' }
GemStonePharoReloadRunnerTest >> setUp [
	super setUp.
	logLines := OrderedCollection new.
	runner := GemStonePharoReloadRunner
		onEnvironment: Dictionary new
		log: [ :line | logLines add: line ]
]

{ #category : 'tests' }
GemStonePharoReloadRunnerTest >> testArtifactFlagsReadEnvironment [
	runner := GemStonePharoReloadRunner
		onEnvironment: (Dictionary newFromPairs: {
			'GBS_GENERATE_CONTRACT_ARTIFACTS'. '1'.
			'GBS_VERIFY_CONTRACT_ARTIFACTS'. '1' })
		log: [ :line | logLines add: line ].

	self assert: runner shouldGenerateContractArtifacts.
	self assert: runner shouldVerifyContractArtifacts
]

{ #category : 'tests' }
GemStonePharoReloadRunnerTest >> testLoadGroupDefaultsToDefault [
	self assert: (GemStonePharoReloadRunner loadGroupNameFromEnvironment: Dictionary new) equals: 'default'
]

{ #category : 'tests' }
GemStonePharoReloadRunnerTest >> testReloadCheckModeDefaultsToDefaultAndLowercasesOverride [
	self assert: (GemStonePharoReloadRunner reloadCheckModeFromEnvironment: Dictionary new) equals: 'default'.
	self
		assert: (GemStonePharoReloadRunner
			reloadCheckModeFromEnvironment: (Dictionary newFromPairs: { 'GBS_RELOAD_CHECK_MODE'. 'Core-Only' }))
		equals: 'core-only'
]

{ #category : 'tests' }
GemStonePharoReloadRunnerTest >> testEmitMissingContractFailureLogsExpectedMarkers [
	self deny: runner emitMissingContractFailure.

	self assert: (logLines includes: 'ARCHITECTURE_BOUNDARY_FAILED').
	self assert: (logLines includes: 'PACKAGE_OWNERSHIP_DRIFT_FAILED').
	self assert: (logLines includes: 'NO_COMPAT_SOURCE_SCAN_FAILED').
	self assert: (logLines includes: 'NO_COMPATIBILITY_PROOF_FAILED').
	self assert: (logLines includes: 'CLEAN_RELOAD_DONE')
]

{ #category : 'tests' }
GemStonePharoReloadRunnerTest >> testRunLoadedImageRunsCoreOnlyChecksAndArtifactStepsThroughGuards [
	| guards contract repoRoot verificationCalled |
	guards := self newGuards.
	contract := self newContract.
	repoRoot := FileSystem memory root / 'reload-runner'.
	repoRoot ensureCreateDirectory.
	verificationCalled := false.
	runner := GemStonePharoReloadRunner
		onEnvironment: (Dictionary newFromPairs: {
			'GBS_LOAD_GROUP'. 'Core-Tests'.
			'GBS_RELOAD_CHECK_MODE'. 'core-only'.
			'GBS_VERIFY_LANE'. 'core-only'.
			'GBS_GENERATE_CONTRACT_ARTIFACTS'. '1'.
			'GBS_VERIFY_CONTRACT_ARTIFACTS'. '1' })
		log: [ :line | logLines add: line ].
	runner
		baselineContract: contract;
		reloadGuards: guards;
		loadedPackages: #('GemStone-Pharo-Core-Tests');
		repoRoot: repoRoot;
		verificationRunBlock: [ verificationCalled := true. true ];
		workingCopyNamedBlock: [ :packageName | nil ].

	self assert: runner runLoadedImage.
	self
		assert: guards calls asArray
		equals: #(architecture packageOwnership noCompatibilitySource noCompatibility coreOnly generateContractArtifacts verifyContractArtifacts).
	self assert: verificationCalled
]

{ #category : 'tests' }
GemStonePharoReloadRunnerTest >> testRunLoadedImageRunsDefaultNoCompatibilityPathAndLogsCleanReloadDone [
	| guards contract |
	guards := self newGuards.
	contract := self newContract.
	runner
		baselineContract: contract;
		reloadGuards: guards;
		loadedPackages: #('GemStone-GBS-Converted').

	self assert: runner runLoadedImage.
	self assert: (guards calls includes: #noCompatibility).
	self assert: (logLines includes: 'CLEAN_RELOAD_DONE')
]

{ #category : 'tests' }
GemStonePharoReloadRunnerTest >> testRunLoadedImageReturnsFalseWhenRequestedVerificationFails [
	| guards contract |
	guards := self newGuards.
	contract := self newContract.
	runner := GemStonePharoReloadRunner
		onEnvironment: (Dictionary newFromPairs: {
			'GBS_VERIFY_LANE'. 'full' })
		log: [ :line | logLines add: line ].
	runner
		baselineContract: contract;
		reloadGuards: guards;
		loadedPackages: #('GemStone-GBS-Converted');
		verificationRunBlock: [ false ].

	self deny: runner runLoadedImage
]
