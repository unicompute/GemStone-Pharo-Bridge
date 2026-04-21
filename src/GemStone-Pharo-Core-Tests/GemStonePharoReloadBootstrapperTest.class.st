Class {
	#name : 'GemStonePharoReloadBootstrapperTest',
	#superclass : 'TestCase',
	#instVars : [
		'bootstrapper'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GemStonePharoReloadBootstrapperTest >> setUp [
	super setUp.
	bootstrapper := GemStonePharoReloadBootstrapperTestBootstrapper
		onEnvironment: Dictionary new
		log: [ :line | ]
]

{ #category : 'tests' }
GemStonePharoReloadBootstrapperTest >> testPackageNamesToUnloadDeriveFromContractInReverseDependencyOrder [
	self
		assert: GemStonePharoReloadBootstrapper new packageNamesToUnload
		equals: #(
			'GemStone-Pharo-Tests'
			'GemStone-Pharo-Core-Tests'
			'GemStone-GBS-MagLev-Tools'
			'GemStone-GBS-Tools'
			'GemStone-GBS-MagLev'
			'GemStone-GBS-Converted')
]

{ #category : 'tests' }
GemStonePharoReloadBootstrapperTest >> testRunBootstrapReloadExecutesBootstrapStepsBeforeReloadChecks [
	| expectedPackages |
	bootstrapper := GemStonePharoReloadBootstrapperTestBootstrapper
		onEnvironment: (Dictionary newFromPairs: { 'GBS_LOAD_GROUP'. 'Full' })
		log: [ :line | ].
	expectedPackages := #(
		'GemStone-Pharo-Tests'
		'GemStone-Pharo-Core-Tests'
		'GemStone-GBS-MagLev-Tools'
		'GemStone-GBS-Tools'
		'GemStone-GBS-MagLev'
		'GemStone-GBS-Converted').

	self assert: bootstrapper runBootstrapReload.
	self
		assert: bootstrapper calls asArray
		equals: {
			#removeOverrides.
			{ #collectClassNames. expectedPackages }.
			{ #unloadPackages. expectedPackages }.
			{ #forceRemoveClasses. #('LegacyBridgeClass') }.
			{ #unregisterWorkingCopies. expectedPackages }.
			{ #warmTonelCache. expectedPackages }.
			{ #loadRequestedGroup. 'Full' }.
			#runLoadedImageChecks }
]
