Class {
	#name : 'GemStonePharoContractTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'private' }
GemStonePharoContractTest >> contract [
	^ GemStonePharoContract new
]

{ #category : 'tests' }
GemStonePharoContractTest >> testGeneratedContractArtifactSpecsExcludeDeprecatedAliasesDocument [
	| paths |
	paths := self contract generatedContractArtifactSpecs collect: [ :each | each first ].

	self deny: (paths includes: 'doc/DEPRECATED-ALIASES.md').
	self assert: (paths includes: 'doc/PACKAGE-GRAPH.md').
	self assert: (paths includes: 'doc/PACKAGE-GRAPH.dot').
	self assert: (paths includes: 'doc/PACKAGE-GRAPH.svg').
	self assert: (paths includes: 'doc/LIVE-PREFLIGHT-POLICY.md').
	self assert: (paths includes: 'doc/RELOAD-POLICY.md').
	self assert: (paths includes: 'doc/USER-MANUAL-REFERENCE.html').
	self assert: (paths includes: 'doc/OWNERSHIP-CONTRACT.md').
	self assert: (paths includes: 'doc/VERIFICATION-LANES.md')
]

{ #category : 'tests' }
GemStonePharoContractTest >> testGeneratedDocumentationSectionSpecsCoverHumanFacingDocs [
	| specs paths |
	specs := self contract generatedDocumentationSectionSpecs.
	paths := specs collect: [ :each | each first ].

	self assert: (paths includes: 'README.md').
	self assert: (paths includes: 'doc/TESTING.md').
	self assert: (paths includes: 'doc/ARCHITECTURE.md').
	self assert: (paths includes: 'doc/GemStone-Pharo-Bridge-User-Manual.html').
	self assert: (specs anySatisfy: [ :each | each second = '<!-- BEGIN GENERATED:README-BODY -->' ]).
	self assert: (specs anySatisfy: [ :each | each second = '<!-- BEGIN GENERATED:USER-MANUAL-TESTING -->' ])
]

{ #category : 'tests' }
GemStonePharoContractTest >> testGeneratedPackageGraphMarkdownMentionsRenderedSvgAndExcludesCompatibilityPackages [
	| markdown |
	markdown := self contract generatedPackageGraphMarkdown.

	self assert: (markdown includesSubstring: 'PACKAGE-GRAPH.svg').
	self deny: (markdown includesSubstring: '`GemStone-GBS-Compatibility`').
	self deny: (markdown includesSubstring: '`GemStone-Pharo-Compatibility-Tests`').
	self assert: (markdown includesSubstring: '## Load Groups')
]

{ #category : 'tests' }
GemStonePharoContractTest >> testGeneratedOwnershipContractMarkdownDescribesLanePolicyAndOwnershipFamilies [
	| markdown |
	markdown := self contract generatedOwnershipContractMarkdown.

	self assert: (markdown includesSubstring: '# Ownership Contract').
	self assert: (markdown includesSubstring: '## Regression Lane Policy').
	self assert: (markdown includesSubstring: '`all`').
	self assert: (markdown includesSubstring: 'BRIDGE_UNIT_REGRESSION').
	self assert: (markdown includesSubstring: '## Ownership Families').
	self assert: (markdown includesSubstring: '`convertedWithMaglev`').
	self assert: (markdown includesSubstring: '## Split Behavior Ownership').
	self assert: (markdown includesSubstring: 'GbsSession').
	self assert: (markdown includesSubstring: '## No-compatibility Static Scan').
	self assert: (markdown includesSubstring: 'scripts/run_verify.sh')
]

{ #category : 'tests' }
GemStonePharoContractTest >> testGeneratedLivePreflightPolicyMarkdownDescribesEnvStepsAndCodes [
	| markdown |
	markdown := self contract generatedLivePreflightPolicyMarkdown.

	self assert: (markdown includesSubstring: '# Live Preflight Policy').
	self assert: (markdown includesSubstring: '## Required Environment').
	self assert: (markdown includesSubstring: 'GS_USER').
	self assert: (markdown includesSubstring: 'GS_NETLDI_NAME_OR_PORT').
	self assert: (markdown includesSubstring: '## Probe Steps').
	self assert: (markdown includesSubstring: 'GemStonePharoVerificationRunner').
	self assert: (markdown includesSubstring: 'topaz-login').
	self assert: (markdown includesSubstring: '## Summary Fields').
	self assert: (markdown includesSubstring: 'stone_status').
	self assert: (markdown includesSubstring: '## Result Codes').
	self assert: (markdown includesSubstring: 'LIVE_PREFLIGHT_GCI_ROUTE_FAILED')
]

{ #category : 'tests' }
GemStonePharoContractTest >> testGeneratedReloadPolicyMarkdownDescribesEnvModesAndLanes [
	| markdown |
	markdown := self contract generatedReloadPolicyMarkdown.

	self assert: (markdown includesSubstring: '# Reload Policy').
	self assert: (markdown includesSubstring: 'GemStonePharoVerificationRunner').
	self assert: (markdown includesSubstring: 'GemStonePharoVerifyRunner').
	self assert: (markdown includesSubstring: 'GBS_LOAD_GROUP').
	self assert: (markdown includesSubstring: 'GBS_RELOAD_CHECK_MODE').
	self assert: (markdown includesSubstring: 'GBS_VERIFY_LANE').
	self assert: (markdown includesSubstring: '## Reload Modes').
	self assert: (markdown includesSubstring: '`core-only`').
	self assert: (markdown includesSubstring: '## Verification Lanes').
	self assert: (markdown includesSubstring: '`full`')
]

{ #category : 'tests' }
GemStonePharoContractTest >> testGeneratedUserManualReferenceHtmlDescribesBridgeRootLanesAndLiveEnv [
	| html |
	html := self contract generatedUserManualReferenceHtml.

	self assert: (html includesSubstring: 'GemStone-Pharo-Bridge Operator Reference').
	self assert: (html includesSubstring: '<code>bridgeRoot</code>').
	self assert: (html includesSubstring: 'Active Load Groups').
	self assert: (html includesSubstring: '<code>Full</code>').
	self assert: (html includesSubstring: 'Verification Lanes').
	self assert: (html includesSubstring: '<code>full</code>').
	self assert: (html includesSubstring: '<code>make verify</code>').
	self assert: (html includesSubstring: 'GemStonePharoVerifyRunner').
	self assert: (html includesSubstring: 'GS_NETLDI_NAME_OR_PORT').
	self assert: (html includesSubstring: 'No-compatibility Proof').
	self deny: (html includesSubstring: 'persistentRoot').
	self deny: (html includesSubstring: 'GbsPersistentRootFacade')
]

{ #category : 'tests' }
GemStonePharoContractTest >> testGroupMemberSpecsExcludeRemovedLegacyGroups [
	| groupNames defaultGroup fullGroup |
	groupNames := self contract groupMemberSpecs collect: [ :each | each first ].
	defaultGroup := self contract groupMemberSpecs
		detect: [ :each | each first = 'default' ].
	fullGroup := self contract groupMemberSpecs
		detect: [ :each | each first = 'Full' ].

	self deny: (groupNames includes: 'Compatibility').
	self deny: (groupNames includes: 'Compatibility-Tests').
	self deny: (groupNames includes: 'Retirement-Preview').
	self deny: (defaultGroup second includes: 'GemStone-GBS-Compatibility').
	self deny: (defaultGroup second includes: 'GemStone-Pharo-Compatibility-Tests').
	self deny: (fullGroup second includes: 'GemStone-GBS-Compatibility').
	self deny: (fullGroup second includes: 'GemStone-Pharo-Compatibility-Tests')
]

{ #category : 'tests' }
GemStonePharoContractTest >> testGroupMemberSpecsOnlyReferenceKnownPackages [
	| packageNames |
	packageNames := (self contract packageRequirementSpecs collect: [ :each | each first ]) asSet.

	self contract groupMemberSpecs do: [ :spec |
		self deny: spec second isEmpty.
		self assert: ((spec second asSet difference: packageNames) isEmpty) ]
]

{ #category : 'tests' }
GemStonePharoContractTest >> testNoCompatibilitySpecsCoverDeletedPackagesClassesAndLegacySelectors [
	| selectorTriples sourceRoots sourceSnippets secondaryFiles secondarySnippets |
	selectorTriples := self contract noCompatibilitySelectorChecks.
	sourceRoots := self contract noCompatibilitySourceScanRoots.
	sourceSnippets := self contract noCompatibilitySourceScanSnippets.
	secondaryFiles := self contract noCompatibilitySecondarySourceScanFiles.
	secondarySnippets := self contract noCompatibilitySecondarySourceScanSnippets.

	self assert: self contract noCompatibilityPackageNames asSet equals: #('GemStone-GBS-Compatibility' 'GemStone-Pharo-Compatibility-Tests') asSet.
	self assert: (self contract noCompatibilityClassNames includes: #GbsPersistentRootFacade).
	self assert: (self contract noCompatibilityClassNames includes: #GbsRootCompatibilityTest).
	self assert: (selectorTriples includes: { #GbsSession. #instance. #persistentRoot }).
	self assert: (selectorTriples includes: { #GbsSession. #instance. #rootAt: }).
	self assert: (selectorTriples includes: { #GBSM. #class. #rootAt:put: }).
	self assert: self contract noCompatibilityMethodPackageNames asSet equals: self contract noCompatibilityPackageNames asSet.
	self assert: sourceRoots asSet equals: #('src/GemStone-GBS-Converted' 'src/GemStone-GBS-Tools' 'src/GemStone-GBS-MagLev' 'src/GemStone-GBS-MagLev-Tools') asSet.
	self assert: (sourceSnippets includes: 'GemStone-GBS-Compatibility').
	self assert: (sourceSnippets includes: 'GbsPersistentRootFacade').
	self assert: (sourceSnippets includes: 'GbsSession >> persistentRoot [').
	self assert: (sourceSnippets includes: 'GBSM class >> rootAt:put: [').
	self assert: (secondaryFiles includes: 'doc/LIVE-PREFLIGHT-POLICY.md').
	self assert: (secondaryFiles includes: 'doc/PACKAGE-GRAPH.dot').
	self assert: (secondaryFiles includes: 'doc/PACKAGE-GRAPH.md').
	self assert: (secondaryFiles includes: 'doc/PACKAGE-GRAPH.svg').
	self assert: (secondaryFiles includes: 'doc/RELOAD-POLICY.md').
	self assert: (secondaryFiles includes: 'README.md').
	self assert: (secondaryFiles includes: 'doc/ARCHITECTURE.md').
	self assert: (secondaryFiles includes: 'doc/GemStone-Pharo-Bridge-User-Manual.html').
	self assert: (secondaryFiles includes: 'doc/TESTING.md').
	self assert: (secondaryFiles includes: 'doc/USER-MANUAL-REFERENCE.html').
	self assert: (secondaryFiles includes: 'doc/VERIFICATION-LANES.md').
	self assert: (secondaryFiles includes: 'scripts/check_bootstrap_smoke_group.st').
	self assert: (secondaryFiles includes: 'scripts/generate_contract_artifacts.st').
	self assert: (secondaryFiles includes: 'scripts/micro_bootstrap_reload.st').
	self assert: (secondaryFiles includes: 'scripts/probe_live_login.st').
	self assert: (secondaryFiles includes: 'scripts/run_bootstrap_smoke.sh').
	self assert: (secondaryFiles includes: 'scripts/run_live_preflight_via_runner.st').
	self assert: (secondaryFiles includes: 'scripts/test_render_lane_json_summaries.sh').
	self assert: (secondaryFiles includes: 'scripts/render_lane_json_summaries.sh').
	self assert: (secondaryFiles includes: 'scripts/run_verify.sh').
	self assert: (secondaryFiles includes: 'scripts/run_verify_via_runner.st').
	self assert: (secondaryFiles includes: '.github/workflows/verify.yml').
	self assert: (secondarySnippets includes: 'GemStone-GBS-Compatibility').
	self assert: (secondarySnippets includes: 'persistentRoot')
]

{ #category : 'tests' }
GemStonePharoContractTest >> testPackageOwnershipBehaviorSpecsDeriveAllowedPackagesFromFamilies [
	| contract familyMap derivedByBehavior |
	contract := self contract.
	familyMap := contract packageOwnershipAllowedPackagesByFamily.
	derivedByBehavior := Dictionary new.
	contract packageOwnershipBehaviorSpecs do: [ :each |
		derivedByBehavior
			at: { each first. each second }
			put: each third asArray ].

	contract packageOwnershipBehaviorFamilySpecs do: [ :each |
		self
			assert: (derivedByBehavior at: { each first. each second })
			equals: (familyMap at: each third) ]
]

{ #category : 'tests' }
GemStonePharoContractTest >> testPackageOwnershipBehaviorFamilySpecsDeriveClassSideEntriesFromInstanceFamilies [
	| familySpecsByBehavior |
	familySpecsByBehavior := Dictionary new.
	self contract packageOwnershipBehaviorFamilySpecs do: [ :each |
		familySpecsByBehavior
			at: { each first. each second }
			put: each third ].

	self assert: (familySpecsByBehavior at: { #GbsRemoteNamespaceMirror. #instance }) equals: #convertedWithMaglev.
	self assert: (familySpecsByBehavior at: { #GbsRemoteNamespaceMirror. #class }) equals: #convertedWithMaglev.
	self assert: (familySpecsByBehavior at: { #GbsObjectSpaceDiagnosticsFacade. #class }) equals: #convertedWithMaglev.
	self assert: (familySpecsByBehavior at: { #GbsBrowser. #class }) equals: #toolsWithMaglevTools.
	self assert: (familySpecsByBehavior at: { #GBSM. #class }) equals: #convertedWithMaglev.
	self assert: (familySpecsByBehavior at: { #GbsPlaygroundActions. #class }) equals: #toolsWithMaglevTools
]

{ #category : 'tests' }
GemStonePharoContractTest >> testPackageOwnershipSelectorSpecsDeriveExpectedPackagesFromFamilies [
	| specs bySelector |
	specs := self contract packageOwnershipSelectorSpecs.
	bySelector := Dictionary new.
	specs do: [ :each | bySelector at: { each first. each second. each third } put: each fourth ].

	self assert: (self contract packageOwnershipSelectorFamilySpecs size) equals: specs size.
	self assert: self contract packageOwnershipExplicitSelectorSpecs isEmpty.
	self assert: (self contract packageOwnershipAllowedPackagesByFamily at: #toolsOnly) equals: #('GemStone-GBS-Tools').
	self assert: (self contract packageOwnershipAllowedPackagesByFamily at: #maglevToolsOnly) equals: #('GemStone-GBS-MagLev-Tools').
	self assert: (bySelector at: { #GbsBrowser. #instance. #browseNamedObjectCacheReport }) equals: 'GemStone-GBS-Tools'.
	self assert: (bySelector at: { #GbsRemoteMethodMirror. #instance. #asMethodObject }) equals: 'GemStone-GBS-Converted'.
	self assert: (bySelector at: { #GbsSession. #instance. #materializeMaglevRuntimeValue: }) equals: 'GemStone-GBS-MagLev'.
	self assert: (bySelector at: { #GbsRemoteNamespaceMirror. #instance. #loadPath }) equals: 'GemStone-GBS-MagLev'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #addExtensionSessionMenuItemsTo: }) equals: 'GemStone-GBS-MagLev-Tools'.
	self assert: (bySelector at: { #GbsSession. #instance. #rubyRuntime }) equals: 'GemStone-GBS-MagLev'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #browseRubyLoadPathReport }) equals: 'GemStone-GBS-MagLev-Tools'
]

{ #category : 'tests' }
GemStonePharoContractTest >> testPackageOwnershipClassSpecsCombineDerivedAndExplicitSpecs [
	| byClass |
	byClass := Dictionary new.
	self contract packageOwnershipClassSpecs do: [ :each |
		byClass at: each first put: each second ].

	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsBridgeRootFacade. 'GemStone-GBS-Converted' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsMaglevFacade. 'GemStone-GBS-MagLev' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsSession. 'GemStone-GBS-Converted' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsBrowser. 'GemStone-GBS-Tools' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GciErrorTest. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRubyRuntimeFacade. 'GemStone-GBS-MagLev' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsNamespacesPresenter. 'GemStone-GBS-MagLev-Tools' }).
	self assert: (byClass at: #GbsBridgeRootFacade) equals: 'GemStone-GBS-Converted'.
	self assert: (byClass at: #GbsMaglevFacade) equals: 'GemStone-GBS-MagLev'.
	self assert: (byClass at: #GbsSession) equals: 'GemStone-GBS-Converted'.
	self assert: (byClass at: #GciErrorTest) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbxActivationTest) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbsRubyRuntimeFacade) equals: 'GemStone-GBS-MagLev'.
	self assert: (byClass at: #GbsNamespacesPresenter) equals: 'GemStone-GBS-MagLev-Tools'.
	self assert: (byClass at: #GbsRemoteUnboundMethodObject) equals: 'GemStone-GBS-Converted'
]

{ #category : 'tests' }
GemStonePharoContractTest >> testPackageOwnershipExplicitClassFamilySpecsDeriveNamesFromGroupedSuffixSpecs [
	| groupedSpecs familySpecs |
	groupedSpecs := self contract packageOwnershipExplicitClassGroupSpecs.
	familySpecs := self contract packageOwnershipExplicitClassFamilySpecs asSet.

	self assert: (groupedSpecs includes: { #GbxExecBlock. #('' '0' '1' '2' '3' '4' '5' 'N'). #maglevOnly }).
	self assert: (groupedSpecs includes: { #GbsRc. #('Counter' 'Hash' 'Queue'). #maglevOnly }).
	self assert: (groupedSpecs includes: { #GbsGs. #('Object' 'Dictionary'). #maglevOnly }).
	self assert: (familySpecs includes: { #GbxExecBlockN. #maglevOnly }).
	self assert: (familySpecs includes: { #GbsRcHash. #maglevOnly }).
	self assert: (familySpecs includes: { #GbsGsDictionary. #maglevOnly }).
	self assert: (familySpecs includes: { #GbsRemoteUnboundMethodObject. #convertedOnly })
]

{ #category : 'tests' }
GemStonePharoContractTest >> testPackageOwnershipPrimaryClassPackagesByFamilyCoverMixedOwnershipFamilies [
	| primaryPackages |
	primaryPackages := self contract packageOwnershipPrimaryClassPackagesByFamily.

	self assert: (primaryPackages at: #convertedWithMaglev) equals: 'GemStone-GBS-Converted'.
	self assert: (primaryPackages at: #toolsWithMaglevTools) equals: 'GemStone-GBS-Tools'
]

{ #category : 'tests' }
GemStonePharoContractTest >> testCoreOnlyChecksDerivePresenceFromOwnershipAndNoCompatibilityContracts [
	| classChecksByName selectorChecksByKey packageChecksByName |
	packageChecksByName := Dictionary new.
	self contract coreOnlyPackageChecks do: [ :each |
		packageChecksByName at: each first put: each second ].
	classChecksByName := Dictionary new.
	self contract coreOnlyClassChecks do: [ :each |
		classChecksByName at: each first put: each second ].
	selectorChecksByKey := Dictionary new.
	self contract coreOnlySelectorChecks do: [ :each |
		selectorChecksByKey at: { each first. each second } put: each third ].

	self assert: self contract coreOnlyLoadedPackageNames equals: #('GemStone-GBS-Converted' 'GemStone-GBS-Tools' 'GemStone-Pharo-Core-Tests').
	self assert: (packageChecksByName at: 'GemStone-GBS-Converted') equals: true.
	self assert: (packageChecksByName at: 'GemStone-GBS-Tools') equals: true.
	self assert: (packageChecksByName at: 'GemStone-Pharo-Core-Tests') equals: true.
	self assert: (packageChecksByName at: 'GemStone-GBS-MagLev') equals: false.
	self assert: (packageChecksByName at: 'GemStone-Pharo-Tests') equals: false.
	self assert: (classChecksByName at: #GbsBridgeRootFacade) equals: true.
	self assert: (classChecksByName at: #GbsRubyRuntimeFacade) equals: false.
	self assert: (selectorChecksByKey at: { #GbsSession. #bridgeRoot }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsRemoteMethodMirror. #asMethodObject }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #rubyRuntime }) equals: false.
	self assert: (selectorChecksByKey at: { #GbsRemoteNamespaceMirror. #loadPath }) equals: false.
	self assert: (selectorChecksByKey at: { #GbsRemoteDebugger. #addExtensionSessionMenuItemsTo: }) equals: false.
	self deny: (packageChecksByName includesKey: 'GemStone-GBS-Compatibility').
	self deny: (classChecksByName includesKey: #GbsPersistentRootFacade).
	self deny: (selectorChecksByKey includesKey: { #GbsSession. #persistentRoot })
]

{ #category : 'tests' }
GemStonePharoContractTest >> testRegressionLaneSpecsDescribeSelectionAndLiveBehavior [
	| specs byName |
	specs := self contract regressionLaneSpecs.
	byName := Dictionary new.
	specs do: [ :each | byName at: each first put: each ].

	self assert: specs size equals: 3.
	self assert: (byName at: 'all') equals: #('all' 'BRIDGE_REGRESSION' #all false).
	self assert: (byName at: 'unit') equals: #('unit' 'BRIDGE_UNIT_REGRESSION' #excludeIntegration false).
	self assert: (byName at: 'live') equals: #('live' 'BRIDGE_LIVE_REGRESSION' #onlyIntegration true).
	self assert: (self contract regressionIntegrationProtocols) equals: #('integration tests')
]

{ #category : 'tests' }
GemStonePharoContractTest >> testPackageRequirementSpecsOnlyReferenceKnownPackages [
	| packageNames |
	packageNames := (self contract packageRequirementSpecs collect: [ :each | each first ]) asSet.

	self contract packageRequirementSpecs do: [ :spec |
		self assert: ((spec second asSet difference: packageNames) isEmpty) ]
]

{ #category : 'tests' }
GemStonePharoContractTest >> testVerificationLaneSpecsReflectSteadyStateLaneSet [
	| laneNames bootstrapLane fullLane verifyLane artifactLane |
	laneNames := self contract verificationLaneSpecs collect: [ :each | each first ].
	bootstrapLane := self contract verificationLaneSpecs
		detect: [ :each | each first = 'bootstrap-smoke' ].
	fullLane := self contract verificationLaneSpecs
		detect: [ :each | each first = 'full' ].
	verifyLane := self contract verificationLaneSpecs
		detect: [ :each | each first = 'verify' ].
	artifactLane := self contract verificationLaneSpecs
		detect: [ :each | each first = 'artifact-freshness' ].

	self assert: laneNames asSet equals: #('core-only' 'bootstrap-smoke' 'full' 'artifact-freshness' 'verify') asSet.
	self deny: (laneNames includes: 'compatibility-only').
	self deny: (laneNames includes: 'retirement-preview').
	self assert: ((self contract verificationLaneSpecs detect: [ :each | each first = 'core-only' ]) fifth includes: 'NO_COMPATIBILITY_PROOF_OK').
	self assert: bootstrapLane third equals: 'Core-Tests'.
	self assert: (bootstrapLane fifth includes: 'BOOTSTRAP_SMOKE_OK').
	self assert: (bootstrapLane fifth includes: 'BOOTSTRAP_SMOKE_DONE').
	self assert: (fullLane fourth includes: 'GemStone-Pharo-Core-Tests').
	self assert: (fullLane fourth includes: 'GemStone-Pharo-Tests').
	self deny: (fullLane fourth includes: 'GemStone-Pharo-Compatibility-Tests').
	self assert: (fullLane fifth includes: 'NO_COMPAT_SOURCE_SCAN_OK').
	self assert: (fullLane fifth includes: 'NO_COMPATIBILITY_PROOF_OK').
	self assert: (artifactLane fourth includes: 'doc/LIVE-PREFLIGHT-POLICY.md').
	self assert: (artifactLane fourth includes: 'doc/RELOAD-POLICY.md').
	self assert: (artifactLane fourth includes: 'doc/USER-MANUAL-REFERENCE.html').
	self assert: (artifactLane fourth includes: 'doc/OWNERSHIP-CONTRACT.md').
	self assert: verifyLane fourth equals: #('core-only' 'bootstrap-smoke' 'full' 'artifact-freshness' 'summary-renderer')
]
