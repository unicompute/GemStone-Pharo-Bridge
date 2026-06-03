Class {
	#name : 'GemStonePharoContract',
	#superclass : 'Object',
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'contracts' }
GemStonePharoContract >> coreOnlyLoadedPackageNames [
	^ (self groupMemberSpecs
		detect: [ :each | each first = 'Core-Tests' ]
		ifNone: [ self error: 'Missing Core-Tests group specification' ]) second
]

{ #category : 'contracts' }
GemStonePharoContract >> coreOnlyClassChecks [
	^ self packageContract coreOnlyClassChecks
]

{ #category : 'contracts' }
GemStonePharoContract >> coreOnlyPackageChecks [
	^ self packageContract coreOnlyPackageChecks
]

{ #category : 'contracts' }
GemStonePharoContract >> coreOnlySelectorChecks [
	^ self packageContract coreOnlySelectorChecks
]

{ #category : 'contracts' }
GemStonePharoContract >> coreOnlyExplicitSelectorChecks [
	^ {
		{ #GbxDebuggerService. #instance. #browseMethod. true }.
		{ #GbxDebuggerService. #instance. #correctCurrentSelectorWithSource:. true }.
		{ #GbxDebuggerService. #instance. #gbxRecompileMethod:notifying:. true }.
		{ #GbxDebuggerService. #instance. #recompileCurrentMethodWithSource:. true }.
		{ #GbxDebuggerService. #instance. #selectedMethodClassName. true }.
		{ #GbxDebuggerService. #instance. #selectedMethodSelector. true }.
		{ #GbxDebuggerService. #instance. #sourceCode. true } }
]

{ #category : 'contracts' }
GemStonePharoContract >> coreOnlyDerivedSelectorChecks [
	^ self packageContract coreOnlyDerivedSelectorChecks
]

{ #category : 'contracts' }
GemStonePharoContract >> forbiddenPackageRequirementSpecs [
	^ self packageContract forbiddenPackageRequirementSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> docRenderer [
	^ GemStonePharoDocRenderer on: self
]

{ #category : 'contracts' }
GemStonePharoContract >> packageContract [
	^ GemStonePharoPackageContract on: self
]

{ #category : 'contracts' }
GemStonePharoContract >> verificationContract [
	^ GemStonePharoVerificationContract on: self
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedContractArtifactSpecs [
	^ self docRenderer generatedContractArtifactSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedDocumentationSectionSpecs [
	^ self docRenderer generatedDocumentationSectionSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedDocumentationSectionPaths [
	^ self docRenderer generatedDocumentationSectionPaths
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedPackageGraphDot [
	^ self docRenderer generatedPackageGraphDot
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedPackageGraphMarkdown [
	^ self docRenderer generatedPackageGraphMarkdown
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedLoadMatrixMarkdown [
	^ self docRenderer generatedLoadMatrixMarkdown
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedPackageGraphSvg [
	^ self docRenderer generatedPackageGraphSvg
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedOwnershipContractMarkdown [
	^ self docRenderer generatedOwnershipContractMarkdown
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedLivePreflightPolicyMarkdown [
	^ self docRenderer generatedLivePreflightPolicyMarkdown
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedMaglevBranchUsageMarkdown [
	^ self docRenderer generatedMaglevBranchUsageMarkdown
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedReloadPolicyMarkdown [
	^ self docRenderer generatedReloadPolicyMarkdown
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedUserManualReferenceHtml [
	^ self docRenderer generatedUserManualReferenceHtml
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedVerificationLanesMarkdown [
	^ self docRenderer generatedVerificationLanesMarkdown
]

{ #category : 'contracts' }
GemStonePharoContract >> groupMemberSpecs [
	^ self packageContract groupMemberSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilityClassNames [
	^ #(
		GbsPersistentRootFacade
		GbsRootCompatibilityTest)
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilityMethodPackageNames [
	^ #(
		'GemStone-GBS-Compatibility'
		'GemStone-Pharo-Compatibility-Tests')
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilityPackageNames [
	^ #(
		'GemStone-GBS-Compatibility'
		'GemStone-Pharo-Compatibility-Tests')
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySecondarySourceScanFiles [
	^ #(
		'.github/workflows/verify.yml'
		'README.md'
		'doc/ARCHITECTURE.md'
		'doc/GemStone-Pharo-Bridge-User-Manual.html'
		'doc/LIVE-PREFLIGHT-POLICY.md'
		'doc/LOAD-MATRIX.md'
		'doc/MAGLEV-BRANCH-USAGE.md'
		'doc/PACKAGE-GRAPH.dot'
		'doc/PACKAGE-GRAPH.md'
		'doc/PACKAGE-GRAPH.svg'
		'doc/RELOAD-POLICY.md'
		'doc/TESTING.md'
		'doc/USER-MANUAL-REFERENCE.html'
		'doc/VERIFICATION-LANES.md'
		'Makefile'
		'scripts/lane_common.sh'
		'scripts/check_bootstrap_smoke_group.st'
		'scripts/generate_contract_artifacts.st'
		'scripts/micro_bootstrap_reload.st'
		'scripts/probe_live_login.st'
		'scripts/run_all_package_regressions.st'
		'scripts/run_bootstrap_smoke.sh'
		'scripts/run_clean_reload_and_regressions.sh'
		'scripts/run_core_only_clean_reload.sh'
		'scripts/run_original_drift.sh'
		'scripts/run_original_clean_reload.sh'
		'scripts/run_generate_contract_artifacts.sh'
		'scripts/run_live_preflight.sh'
		'scripts/run_live_preflight_via_runner.st'
		'scripts/render_lane_json_summaries.sh'
		'scripts/test_render_lane_json_summaries.sh'
		'scripts/run_verify.sh'
		'scripts/run_verify_via_runner.st'
		'scripts/run_verify_contract_artifacts.sh')
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySecondarySourceScanSnippets [
	^ (self noCompatibilityPackageNames
		, (self noCompatibilityClassNames collect: #asString)
		, #('persistentRoot' 'rootAt:' 'GbsPersistentRootFacade')) asSet asSortedCollection asArray
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySourceScanRoots [
	^ #(
		'src/GemStone-GBS-Converted'
		'src/GemStone-GBS-Core'
		'src/GemStone-GBS-Core-Tools'
		'src/GemStone-GBS-Tools'
		'src/GemStone-GBS-MagLev'
		'src/GemStone-GBS-MagLev-Tools')
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySelectorChecks [
	^ {
		{ #GbsSession. #instance. #persistentRoot }.
		{ #GbsSession. #instance. #root }.
		{ #GbsSession. #instance. #rootAt: }.
		{ #GbsSession. #instance. #rootAt:ifAbsent: }.
		{ #GbsSession. #instance. #rootAt:put: }.
		{ #GbsSmalltalkFacade. #instance. #persistentRoot }.
		{ #GbsSmalltalkFacade. #instance. #root }.
		{ #GbsMaglevFacade. #instance. #persistentRoot }.
		{ #GbsMaglevFacade. #instance. #root }.
		{ #GBSM. #class. #persistentRoot }.
		{ #GBSM. #class. #root }.
		{ #GBSM. #class. #rootAt: }.
		{ #GBSM. #class. #rootAt:ifAbsent: }.
		{ #GBSM. #class. #rootAt:put: } }
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySourceScanSnippets [
	| selectorSnippets |
	selectorSnippets := self noCompatibilitySelectorChecks collect: [ :spec |
		self noCompatibilitySourceSnippetForBehavior: spec first side: spec second selector: spec third ].
	^ (self noCompatibilityPackageNames
		, (self noCompatibilityClassNames collect: #asString)
		, selectorSnippets) asSet asSortedCollection asArray
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySourceSnippetForBehavior: classSymbol side: side selector: selector [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: classSymbol asString;
			nextPutAll: (side = #class
				ifTrue: [ ' class >> ' ]
				ifFalse: [ ' >> ' ]);
			nextPutAll: selector asString;
			nextPutAll: ' [' ]
]

{ #category : 'contracts' }
GemStonePharoContract >> regressionIntegrationProtocols [
	^ #('integration tests')
]

{ #category : 'contracts' }
GemStonePharoContract >> regressionLaneSpecNamed: aString [
	^ self verificationContract regressionLaneSpecNamed: aString
]

{ #category : 'contracts' }
GemStonePharoContract >> regressionLaneSpecs [
	^ self verificationContract regressionLaneSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipAllowedPackagesByFamily [
	^ self packageContract packageOwnershipAllowedPackagesByFamily
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipBehaviorFamilySpecs [
	^ self packageContract packageOwnershipBehaviorFamilySpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipDerivedClassSideBehaviorFamilySpecs [
	^ self packageContract packageOwnershipDerivedClassSideBehaviorFamilySpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipExplicitBehaviorFamilySpecs [
	^ self packageContract packageOwnershipExplicitBehaviorFamilySpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipInstanceBehaviorFamilySpecs [
	^ self packageContract packageOwnershipInstanceBehaviorFamilySpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipBehaviorSpecs [
	^ self packageContract packageOwnershipBehaviorSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipClassSpecs [
	^ self packageContract packageOwnershipClassSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipDerivedClassSpecs [
	^ self packageContract packageOwnershipDerivedClassSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipExplicitClassSpecs [
	^ self packageContract packageOwnershipExplicitClassSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipExplicitClassFamilySpecs [
	^ self packageContract packageOwnershipExplicitClassFamilySpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipExplicitClassGroupSpecs [
	^ self packageContract packageOwnershipExplicitClassGroupSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipExplicitSelectorSpecs [
	^ self packageContract packageOwnershipExplicitSelectorSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipPrimaryClassPackagesByFamily [
	^ self packageContract packageOwnershipPrimaryClassPackagesByFamily
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipCorePackages [
	^ self packageContract packageOwnershipCorePackages
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipForbiddenCoreClassPatterns [
	^ self packageContract packageOwnershipForbiddenCoreClassPatterns
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipForbiddenCoreSelectorPatterns [
	^ self packageContract packageOwnershipForbiddenCoreSelectorPatterns
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipSelectorSpecs [
	^ self packageContract packageOwnershipSelectorSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipSelectorFamilySpecs [
	^ self packageContract packageOwnershipSelectorFamilySpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> livePreflightCodeSpecs [
	^ self verificationContract livePreflightCodeSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> livePreflightEnvironmentVariableSpecs [
	^ self verificationContract livePreflightEnvironmentVariableSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> reloadCheckModeSpecs [
	^ self verificationContract reloadCheckModeSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> reloadEnvironmentVariableSpecs [
	^ self verificationContract reloadEnvironmentVariableSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> livePreflightStepSpecs [
	^ self verificationContract livePreflightStepSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> livePreflightSummaryFields [
	^ #('result' 'code' 'stone' 'service' 'host' 'net' 'stone_status' 'netldi_status' 'topaz' 'gci' 'host_auth')
]

{ #category : 'contracts' }
GemStonePharoContract >> packageRequirementSpecs [
	^ self packageContract packageRequirementSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> verificationLaneSpecs [
	^ self verificationContract verificationLaneSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> originalLayerExpectedExceptionSpecs [
	^ self verificationContract originalLayerExpectedExceptionSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> activeRootApiSpecs [
	^ #('bridgeRoot' '#GbsBridgeRoot' 'GbsBridgeRootFacade')
]

{ #category : 'contracts' }
GemStonePharoContract >> boundaryGuardSpecs [
	^ self verificationContract boundaryGuardSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedArchitectureBodyMarkdown [
	^ self docRenderer generatedArchitectureBodyMarkdown
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedReadmeBodyMarkdown [
	^ self docRenderer generatedReadmeBodyMarkdown
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedTestingBodyMarkdown [
	^ self docRenderer generatedTestingBodyMarkdown
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedUserManualOverviewHtml [
	^ self docRenderer generatedUserManualOverviewHtml
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedUserManualTestingHtml [
	^ self docRenderer generatedUserManualTestingHtml
]

{ #category : 'contracts' }
GemStonePharoContract >> groupDescriptionSpecs [
	^ self packageContract groupDescriptionSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> loadMatrixGroupNames [
	^ #('Original' 'Original-Tests' 'Core' 'Core-Tools' 'Core-Tests' 'MagLev' 'MagLev-Tools' 'Full')
]

{ #category : 'contracts' }
GemStonePharoContract >> loadMatrixMarkerFor: aBoolean [
	^ self verificationContract loadMatrixMarkerFor: aBoolean
]

{ #category : 'contracts' }
GemStonePharoContract >> productionPackageSummarySpecs [
	^ self verificationContract productionPackageSummarySpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> testPackageSummarySpecs [
	^ self verificationContract testPackageSummarySpecs
]
