Class {
	#name : 'GemStonePharoReloadRunnerTestGuards',
	#superclass : 'Object',
	#instVars : [
		'calls'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'checks' }
GemStonePharoReloadRunnerTestGuards >> calls [
	^ calls ifNil: [ calls := OrderedCollection new ]
]

{ #category : 'checks' }
GemStonePharoReloadRunnerTestGuards >> checkArchitectureFor: baselineContract loadGroup: loadGroup loadedPackages: loadedPackages log: logBlock [
	self calls add: #architecture.
	^ true
]

{ #category : 'checks' }
GemStonePharoReloadRunnerTestGuards >> checkCoreOnlyFor: baselineContract workingCopyNamed: workingCopyNamedBlock log: logBlock [
	self calls add: #coreOnly.
	^ true
]

{ #category : 'checks' }
GemStonePharoReloadRunnerTestGuards >> checkNoCompatibilityFor: baselineContract loadedPackages: loadedPackages log: logBlock [
	self calls add: #noCompatibility.
	^ true
]

{ #category : 'checks' }
GemStonePharoReloadRunnerTestGuards >> checkNoCompatibilitySourceFor: baselineContract repoRoot: repoRoot log: logBlock [
	self calls add: #noCompatibilitySource.
	^ true
]

{ #category : 'checks' }
GemStonePharoReloadRunnerTestGuards >> checkPackageOwnershipFor: baselineContract loadedPackages: loadedPackages log: logBlock [
	self calls add: #packageOwnership.
	^ true
]

{ #category : 'checks' }
GemStonePharoReloadRunnerTestGuards >> generateContractArtifactsFor: baselineContract repoRoot: repoRoot log: logBlock [
	self calls add: #generateContractArtifacts.
	^ true
]

{ #category : 'checks' }
GemStonePharoReloadRunnerTestGuards >> verifyContractArtifactFreshnessFor: baselineContract repoRoot: repoRoot log: logBlock [
	self calls add: #verifyContractArtifacts.
	^ true
]
