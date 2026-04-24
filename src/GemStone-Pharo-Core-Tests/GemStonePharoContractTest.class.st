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
GemStonePharoContractTest >> testGroupMemberSpecsReflectCurrentLayeredGroupsAndExcludeRemovedLegacyGroups [
	| groupNames defaultGroup fullGroup originalGroup originalTestsGroup |
	groupNames := self contract groupMemberSpecs collect: [ :each | each first ].
	originalGroup := self contract groupMemberSpecs
		detect: [ :each | each first = 'Original' ].
	originalTestsGroup := self contract groupMemberSpecs
		detect: [ :each | each first = 'Original-Tests' ].
	defaultGroup := self contract groupMemberSpecs
		detect: [ :each | each first = 'default' ].
	fullGroup := self contract groupMemberSpecs
		detect: [ :each | each first = 'Full' ].

	self assert: (groupNames includes: 'Original').
	self assert: (groupNames includes: 'Original-Tests').
	self deny: (groupNames includes: 'Compatibility').
	self deny: (groupNames includes: 'Compatibility-Tests').
	self deny: (groupNames includes: 'Retirement-Preview').
	self assert: originalGroup second equals: #('GemStone-GBS-Converted' 'GemStone-GBS-Tools').
	self assert: originalTestsGroup second equals: #('GemStone-GBS-Converted' 'GemStone-GBS-Tools' 'GemStone-Pharo-Tests').
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
	self assert: sourceRoots asSet equals: #('src/GemStone-GBS-Converted' 'src/GemStone-GBS-Core' 'src/GemStone-GBS-Core-Tools' 'src/GemStone-GBS-Tools' 'src/GemStone-GBS-MagLev' 'src/GemStone-GBS-MagLev-Tools') asSet.
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

	self assert: (familySpecsByBehavior at: { #GbsRemoteNamespaceMirror. #instance }) equals: #coreWithMaglev.
	self assert: (familySpecsByBehavior at: { #GbsRemoteNamespaceMirror. #class }) equals: #coreWithMaglev.
	self assert: (familySpecsByBehavior at: { #GbsObjectSpaceDiagnosticsFacade. #instance }) equals: #coreWithMaglev.
	self assert: (familySpecsByBehavior at: { #GbsObjectSpaceDiagnosticsFacade. #class }) equals: #coreWithMaglev.
	self assert: (familySpecsByBehavior at: { #GbsObjectSpaceFacade. #instance }) equals: #coreWithMaglev.
	self assert: (familySpecsByBehavior at: { #GbsChunkedMigrationRunner. #instance }) equals: #coreOnly.
	self assert: (familySpecsByBehavior at: { #GbsMigrationPlan. #instance }) equals: #coreOnly.
	self assert: (familySpecsByBehavior at: { #GbsMigrationPlanEntry. #instance }) equals: #coreOnly.
	self assert: (familySpecsByBehavior at: { #GbsMaterializationProfile. #instance }) equals: #coreOnly.
	self assert: (familySpecsByBehavior at: { #GbsBrowser. #class }) equals: #toolsWithCoreToolsAndMaglevTools.
	self assert: (familySpecsByBehavior at: { #GbsInspector. #class }) equals: #toolsWithCoreToolsAndMaglevTools.
	self assert: (familySpecsByBehavior at: { #GbsNamespacesPresenter. #class }) equals: #toolsWithMaglevTools.
	self assert: (familySpecsByBehavior at: { #GbsStructuredValueInspectorPresenter. #class }) equals: #toolsWithCoreToolsAndMaglevTools.
	self assert: (familySpecsByBehavior at: { #GbsSymbolListBrowserPresenter. #class }) equals: #toolsWithCoreToolsAndMaglevTools.
	self assert: (familySpecsByBehavior at: { #GbsClassHistoryFacade. #instance }) equals: #coreOnly.
	self assert: (familySpecsByBehavior at: { #GBSM. #class }) equals: #convertedWithCoreAndMaglev.
	self assert: (familySpecsByBehavior at: { #GbxClassVersionBrowser. #instance }) equals: #convertedWithCore.
	self assert: (familySpecsByBehavior at: { #GbsPlaygroundGsInspectSessionStateCommand. #instance }) equals: #coreToolsOnly.
	self assert: (familySpecsByBehavior at: { #GbsPlaygroundCoreActionsTest. #instance }) equals: #coreTestsOnly.
	self assert: (familySpecsByBehavior at: { #GbsRepositoryFacade. #instance }) equals: #coreOnly.
	self assert: (familySpecsByBehavior at: { #GbsPlaygroundActions. #class }) equals: #toolsWithCoreToolsAndMaglevTools.
	self assert: (familySpecsByBehavior at: { #GbsWorkspace. #instance }) equals: #toolsWithCoreToolsAndMaglevTools.
	self assert: (familySpecsByBehavior at: { #GbsWorkspace. #class }) equals: #toolsWithCoreToolsAndMaglevTools.
	self assert: (familySpecsByBehavior at: { #GbxTrippy. #instance }) equals: #toolsWithCoreToolsAndMaglevTools.
	self assert: (familySpecsByBehavior at: { #GbsWorkspaceCoreActionsTest. #instance }) equals: #coreTestsOnly.
	self assert: (familySpecsByBehavior at: { #GbxTrippyCoreToolsTest. #instance }) equals: #coreTestsOnly.
	self assert: (familySpecsByBehavior at: { #CoreTestableGbxTrippy. #instance }) equals: #coreTestsOnly.
	self assert: (familySpecsByBehavior at: { #CoreTestableGbsWorkspace. #instance }) equals: #coreTestsOnly.
	self assert: (familySpecsByBehavior at: { #CoreTestableGbsWorkspaceActions. #instance }) equals: #coreTestsOnly
]

{ #category : 'tests' }
GemStonePharoContractTest >> testPackageOwnershipSelectorSpecsDeriveExpectedPackagesFromFamilies [
	| specs bySelector |
	specs := self contract packageOwnershipSelectorSpecs.
	bySelector := Dictionary new.
	specs do: [ :each | bySelector at: { each first. each second. each third } put: each fourth ].

	self
		assert: self contract packageOwnershipSelectorFamilySpecs size
		equals: specs size.
	self assert: self contract packageOwnershipExplicitSelectorSpecs isEmpty.
	self assert: (self contract packageOwnershipAllowedPackagesByFamily at: #coreOnly) equals: #('GemStone-GBS-Core').
	self assert: (self contract packageOwnershipAllowedPackagesByFamily at: #coreToolsOnly) equals: #('GemStone-GBS-Core-Tools').
	self assert: (self contract packageOwnershipAllowedPackagesByFamily at: #toolsOnly) equals: #('GemStone-GBS-Tools').
	self assert: (self contract packageOwnershipAllowedPackagesByFamily at: #maglevToolsOnly) equals: #('GemStone-GBS-MagLev-Tools').
	self assert: (bySelector at: { #GbsSession. #instance. #abortTransaction }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #bridgeRoot }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #chunkedMigrationRunnerFrom:to: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #classHistoryOf: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #commitTransaction }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #commitTransactionOrSignalConflict }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #commitTransactionWithRetryCount: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #invalidateRepositoryRoots }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #withCommitRetryCount:do: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #previewMigrationFrom:to: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #migrateInstancesWithSubclassesOf:allowAbort: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #namedObjectAt: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #namedObjectAt:ifAbsent: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #namedObjectCache }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #namedObjectAutoloadRegistry }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #repository }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #repositoryRootFacadeForKey:path: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #repositoryRootLifecycleVersion }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #resetAfterLogout }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #fetchByReference }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #fetchProfile }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #materializationProfile }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #proxyCache }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #objectSpace }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #objectSpaceDiagnosticsReport }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #objectSpaceRepository }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #defineFinalizerFor:do: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #eachObjectDo: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #instancesInMemoryOf: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #loadedClassesIncludingModules }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #sessionStateAt: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #referencesTo: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #objectsInMemory }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #undefineFinalizerFor: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GBSM. #class. #commitTransactionOrSignalConflict }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GBSM. #class. #chunkedMigrationRunnerFrom:to: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbxClassVersionBrowser. #instance. #previewMigrationTo:allowAbort: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbxClassVersionBrowser. #instance. #executePreviewPlan:allowAbort: }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsPlaygroundActions. #class. #gsInspectItIn: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsPlaygroundActions. #class. #gsBrowseSessionStateKeysReportIn: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsPlaygroundActions. #class. #gsBrowseObjectsInMemoryReportIn: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsWorkspace. #instance. #browsePromptedSessionStateKey }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsWorkspace. #instance. #browseTypedWrapperLifecycleReport }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsWorkspace. #instance. #browseObjectsInMemoryReport }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsWorkspace. #instance. #inspectIt }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsWorkspace. #instance. #workspaceMenu }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsClassicLauncher. #class. #inspectCurrentUserGlobalsOnCurrentSession }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsClassicLauncher. #class. #openNamespacesOnCurrentSession }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsClassicLauncher. #class. #queryOrganizerMethodsFor:mode:inSession: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsClassicLauncher. #instance. #browseNamedObjectCacheReport }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsClassicLauncher. #instance. #inspectPromptedSessionStateKey }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsClassicLauncher. #instance. #menuSession }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsMethodQueryResultsPresenter. #instance. #browseNamedObjectCacheReport }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsMethodQueryResultsPresenter. #instance. #browsePromptedSessionStateKey }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsMethodQueryResultsPresenter. #instance. #menuSession }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #browseNamedObjectCacheReport }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #browsePromptedSessionStateKey }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #browseClassInfo }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #browseMethodInfo }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #browseVersions }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #classSelected: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #gsInspectIt }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #inspectMethod }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #invokeSelectedMethod }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #loadDictionaries }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #menuClass }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #menuMethod }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #menuSession }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #methodSelected: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #protocolSelected: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #selectedMethodObject }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #selectedUnboundMethodObject }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsBrowser. #instance. #queryServerMethodsForSelector:mode:rootClassName:hierarchyScope: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsInspector. #instance. #browsePromptedSessionStateKey }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsInspector. #instance. #browsePromptedSessionStateKeysReport }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsInspector. #instance. #browseReportChooser }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsStructuredValueInspectorPresenter. #instance. #browsePromptedSessionStateKey }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsStructuredValueInspectorPresenter. #instance. #browsePromptedSessionStateKeysReport }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsStructuredValueInspectorPresenter. #instance. #menuEntry }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsSymbolListBrowserPresenter. #instance. #browsePromptedSessionStateKey }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsSymbolListBrowserPresenter. #instance. #browseReferencersForSelectedEntry }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsSymbolListBrowserPresenter. #instance. #menuEntry }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsSymbolListBrowserPresenter. #instance. #menuPreview }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsSymbolListBrowserPresenter. #instance. #openStructuredInspectorForPreview:title:entryKey:path:previewKind: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsSymbolListBrowserPresenter. #instance. #refreshUsers }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsSymbolListBrowserPresenter. #instance. #structuredPreviewForEntryKey:path: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #browsePromptedSessionStateKey }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #browsePromptedSessionStateKeysReport }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #buildMenuBar }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #fetchContextsDirectly }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #methodMenu }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #remoteDebugProcess }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #returnFromFrame }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #serverMethodReferencesFor:hierarchyOnly:senders: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #stepReturn }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxContextListPolicy. #instance. #buildContextListFromServerContexts: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxContextListPolicy. #instance. #updateContextListFromServerContexts: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxDebuggerService. #instance. #canExecuteOnDebugProcess }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxDebuggerService. #instance. #currentProcessOop }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxDebuggerService. #instance. #legacyCompileLookup }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxDebuggerService. #instance. #remoteDebugProcess }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxDebuggerService. #instance. #restartLevelFromServerStack }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxTrippy. #instance. #buildToolbar }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxTrippy. #instance. #browseReferencersInMemory }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxTrippy. #instance. #browseTypedWrapperLifecycleReport }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxTrippy. #instance. #browseReportChooser }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbxTrippy. #instance. #withShallowMaterializationDo: }) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (bySelector at: { #GbsRemoteMethodMirror. #instance. #asMethodObject }) equals: 'GemStone-GBS-Core'.
	self assert: (bySelector at: { #GbsSession. #instance. #materializeMaglevRuntimeValue: }) equals: 'GemStone-GBS-MagLev'.
	self assert: (bySelector at: { #GbsRemoteNamespaceMirror. #instance. #loadPath }) equals: 'GemStone-GBS-MagLev'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #addExtensionSessionMenuItemsTo: }) equals: 'GemStone-GBS-MagLev-Tools'.
	self assert: (bySelector at: { #GbsSession. #instance. #rubyRuntime }) equals: 'GemStone-GBS-MagLev'.
	self assert: (bySelector at: { #GbsPlaygroundActions. #class. #gsBrowseRubyLoadPathReportIn: }) equals: 'GemStone-GBS-MagLev-Tools'.
	self assert: (bySelector at: { #GbsWorkspace. #instance. #addExtensionWorkspaceMenuItemsTo: }) equals: 'GemStone-GBS-MagLev-Tools'.
	self assert: (bySelector at: { #GbsRemoteDebugger. #instance. #browseRubyLoadPathReport }) equals: 'GemStone-GBS-MagLev-Tools'
]

{ #category : 'tests' }
GemStonePharoContractTest >> testPackageOwnershipClassSpecsCombineDerivedAndExplicitSpecs [
	| byClass |
	byClass := Dictionary new.
	self contract packageOwnershipClassSpecs do: [ :each |
		byClass at: each first put: each second ].

	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsBridgeRootFacade. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsCacheSessionStateSlot. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsChunkedMigrationRunner. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsClassHistoryFacade. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsCompilerStateSessionStateSlot. 'GemStone-GBS-MagLev' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsDeepMaterializationProfile. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsLegacyMaterializationProfile. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsMaterializationProfile. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsMigrationPlan. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsMigrationPlanEntry. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsObjectFinalizer. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsObjectReferencerReport. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsObjectScanReport. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsObjectSpaceDiagnosticsFacade. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsObjectSpaceDiagnosticsReport. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsObjectSpaceFacade. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsObjectSpaceRepositoryFacade. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRemoteDebugProcessFacade. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsPlaygroundGsInspectSessionStateCommand. 'GemStone-GBS-Core-Tools' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsPlaygroundMenuObjectsInMemoryReportCommand. 'GemStone-GBS-Core-Tools' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsBrowserCoreToolsTest. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsClassicLauncherCoreToolsTest. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsInspectorCoreToolsTest. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsMethodQueryResultsPresenterCoreToolsTest. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsNamespaceScopedMethodQuery. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRemoteDebuggerCoreToolsTest. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRemoteClassMirror. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRemoteConstantMirror. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRemoteMethodMirror. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRemoteMethodObject. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRemoteNamespaceMirror. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRemoteUnboundMethodObject. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsStructuredValueInspectorPresenterCoreToolsTest. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsSymbolListBrowserPresenterCoreToolsTest. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbxTrippyCoreToolsTest. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsPlaygroundCoreActionsTest. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsWorkspaceCoreActionsTest. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsProxyOnlyMaterializationProfile. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsReportSection. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRepositoryFacade. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRepositoryRootFacade. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsSmalltalkFacade. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsStackSessionStateSlot. 'GemStone-GBS-MagLev' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsSymbolDictionaryFacade. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsSessionStateSlot. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsShallowMaterializationProfile. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsTypedProxy. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsTypedWrapperBuilder. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsTypedWrapperLifecycleEntry. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsTypedWrapperLifecycleReport. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsThreadStateSessionStateSlot. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRegistrySessionStateSlot. 'GemStone-GBS-Core' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsMaglevFacade. 'GemStone-GBS-MagLev' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsSession. 'GemStone-GBS-Converted' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbxClassVersionBrowser. 'GemStone-GBS-Converted' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbxContextListPolicy. 'GemStone-GBS-Tools' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbxTrippy. 'GemStone-GBS-Tools' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsBrowser. 'GemStone-GBS-Tools' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #CoreTestableGbsBrowser. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #CoreTestableGbsClassicLauncher. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #CoreTestableGbsInspector. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #CoreTestableGbsMethodQueryResultsPresenter. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #CoreTestableGbsRemoteDebugger. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #CoreGbxFakeServiceForRemoteDebugger. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #CoreGbxFakeContextForRemoteDebugger. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #CoreTestableGbxTrippy. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #CoreMockGbsPlaygroundPresenter. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #CoreTestableGbsWorkspace. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #CoreTestableGbsWorkspaceActions. 'GemStone-Pharo-Core-Tests' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsRubyRuntimeFacade. 'GemStone-GBS-MagLev' }).
	self assert: (self contract packageOwnershipDerivedClassSpecs includes: { #GbsNamespacesPresenter. 'GemStone-GBS-Tools' }).
	self assert: (byClass at: #GbsBridgeRootFacade) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsCacheSessionStateSlot) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsChunkedMigrationRunner) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsClassHistoryFacade) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsCommitConflictError) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsCompilerStateSessionStateSlot) equals: 'GemStone-GBS-MagLev'.
	self assert: (byClass at: #GbsDeepMaterializationProfile) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsLegacyMaterializationProfile) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsMaterializationProfile) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsMigrationPlan) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsMigrationPlanEntry) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsObjectFinalizer) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsObjectReferencerReport) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsObjectScanReport) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsObjectSpaceDiagnosticsFacade) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsObjectSpaceDiagnosticsReport) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsObjectSpaceFacade) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsObjectSpaceRepositoryFacade) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsPlaygroundGsInspectSessionStateCommand) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (byClass at: #GbsPlaygroundMenuSessionStateKeysReportCommand) equals: 'GemStone-GBS-Core-Tools'.
	self assert: (byClass at: #GbsBrowserCoreToolsTest) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbsClassicLauncherCoreToolsTest) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbsInspectorCoreToolsTest) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbsMethodQueryResultsPresenterCoreToolsTest) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbsRemoteDebuggerCoreToolsTest) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbsStructuredValueInspectorPresenterCoreToolsTest) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbxTrippyCoreToolsTest) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbsPlaygroundCoreActionsTest) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbsWorkspaceCoreActionsTest) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbsProxyOnlyMaterializationProfile) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsRepositoryFacade) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsRepositoryRootFacade) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsSessionStateSlot) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsShallowMaterializationProfile) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsSmalltalkFacade) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsStackSessionStateSlot) equals: 'GemStone-GBS-MagLev'.
	self assert: (byClass at: #GbsSymbolDictionaryFacade) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsThreadStateSessionStateSlot) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsRegistrySessionStateSlot) equals: 'GemStone-GBS-Core'.
	self assert: (byClass at: #GbsMaglevFacade) equals: 'GemStone-GBS-MagLev'.
	self assert: (byClass at: #GbsSession) equals: 'GemStone-GBS-Converted'.
	self assert: (byClass at: #GbxClassVersionBrowser) equals: 'GemStone-GBS-Converted'.
	self assert: (byClass at: #GbxContextListPolicy) equals: 'GemStone-GBS-Tools'.
	self assert: (byClass at: #GbxTrippy) equals: 'GemStone-GBS-Tools'.
	self assert: (byClass at: #CoreTestableGbsBrowser) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #CoreTestableGbsClassicLauncher) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #CoreTestableGbsInspector) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #CoreTestableGbsMethodQueryResultsPresenter) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #CoreTestableGbsRemoteDebugger) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #CoreGbxFakeServiceForRemoteDebugger) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #CoreGbxFakeContextForRemoteDebugger) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #CoreTestableGbxTrippy) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #CoreTestableGbsSymbolListBrowserPresenter) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #CoreMockGbsPlaygroundPresenter) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #CoreTestableGbsWorkspace) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #CoreTestableGbsWorkspaceActions) equals: 'GemStone-Pharo-Core-Tests'.
	self assert: (byClass at: #GbsRubyRuntimeFacade) equals: 'GemStone-GBS-MagLev'.
	self assert: (byClass at: #GbsNamespacesPresenter) equals: 'GemStone-GBS-Tools'.
	self assert: (byClass at: #GbsRemoteUnboundMethodObject) equals: 'GemStone-GBS-Core'
]

{ #category : 'tests' }
GemStonePharoContractTest >> testPackageOwnershipExplicitClassFamilySpecsDeriveNamesFromGroupedSuffixSpecs [
	| groupedSpecs familySpecs |
	groupedSpecs := self contract packageOwnershipExplicitClassGroupSpecs.
	familySpecs := self contract packageOwnershipExplicitClassFamilySpecs asSet.

	self assert: (groupedSpecs includes: { #GbxExecBlock. #('' '0' '1' '2' '3' '4' '5' 'N'). #convertedWithMaglev }).
	self assert: (groupedSpecs includes: { #GbsRc. #('Counter' 'Hash' 'Queue'). #maglevOnly }).
	self assert: (groupedSpecs includes: { #GbsGs. #('Object' 'Dictionary'). #maglevOnly }).
	self assert: (familySpecs includes: { #GbxExecBlockN. #convertedWithMaglev }).
	self assert: (familySpecs includes: { #GbsCommitConflictError. #coreOnly }).
	self assert: (familySpecs includes: { #GbsRcHash. #maglevOnly }).
	self assert: (familySpecs includes: { #GbsGsDictionary. #maglevOnly }).
	self deny: (familySpecs includes: { #GbsRemoteUnboundMethodObject. #convertedOnly })
]

{ #category : 'tests' }
GemStonePharoContractTest >> testPackageOwnershipPrimaryClassPackagesByFamilyCoverMixedOwnershipFamilies [
	| primaryPackages |
	primaryPackages := self contract packageOwnershipPrimaryClassPackagesByFamily.

	self assert: (primaryPackages at: #convertedWithCore) equals: 'GemStone-GBS-Converted'.
	self assert: (primaryPackages at: #convertedWithCoreAndMaglev) equals: 'GemStone-GBS-Converted'.
	self assert: (primaryPackages at: #convertedWithMaglev) equals: 'GemStone-GBS-Converted'.
	self assert: (primaryPackages at: #coreWithMaglev) equals: 'GemStone-GBS-Core'.
	self assert: (primaryPackages at: #toolsWithCoreToolsAndMaglevTools) equals: 'GemStone-GBS-Tools'.
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
		selectorChecksByKey at: { each first. each second. each third } put: each fourth.
		each second = #instance ifTrue: [
			selectorChecksByKey at: { each first. each third } put: each fourth ] ].

	self assert: self contract coreOnlyLoadedPackageNames equals: #('GemStone-GBS-Converted' 'GemStone-GBS-Core' 'GemStone-GBS-Tools' 'GemStone-GBS-Core-Tools' 'GemStone-Pharo-Core-Tests').
	self assert: (packageChecksByName at: 'GemStone-GBS-Converted') equals: true.
	self assert: (packageChecksByName at: 'GemStone-GBS-Core') equals: true.
	self assert: (packageChecksByName at: 'GemStone-GBS-Tools') equals: true.
	self assert: (packageChecksByName at: 'GemStone-GBS-Core-Tools') equals: true.
	self assert: (packageChecksByName at: 'GemStone-Pharo-Core-Tests') equals: true.
	self assert: (packageChecksByName at: 'GemStone-GBS-MagLev') equals: false.
	self assert: (packageChecksByName at: 'GemStone-Pharo-Tests') equals: false.
	self assert: (classChecksByName at: #GbsBridgeRootFacade) equals: true.
	self assert: (classChecksByName at: #GbsChunkedMigrationRunner) equals: true.
	self assert: (classChecksByName at: #GbsObjectSpaceFacade) equals: true.
	self assert: (classChecksByName at: #GbsObjectSpaceDiagnosticsFacade) equals: true.
	self assert: (classChecksByName at: #GbsObjectSpaceRepositoryFacade) equals: true.
	self assert: (classChecksByName at: #GbsMaterializationProfile) equals: true.
	self assert: (classChecksByName at: #GbsMigrationPlan) equals: true.
	self assert: (classChecksByName at: #GbsMigrationPlanEntry) equals: true.
	self assert: (classChecksByName at: #GbsCommitConflictError) equals: true.
	self assert: (classChecksByName at: #GbsPlaygroundGsInspectSessionStateCommand) equals: true.
	self assert: (classChecksByName at: #GbsPlaygroundCoreActionsTest) equals: true.
	self assert: (classChecksByName at: #GbsInspectorCoreToolsTest) equals: true.
	self assert: (classChecksByName at: #GbsStructuredValueInspectorPresenterCoreToolsTest) equals: true.
	self assert: (classChecksByName at: #GbsSymbolListBrowserPresenterCoreToolsTest) equals: true.
	self assert: (classChecksByName at: #GbsWorkspaceCoreActionsTest) equals: true.
	self assert: (classChecksByName at: #GbsSessionStateSlot) equals: true.
	self assert: (classChecksByName at: #GbsClassHistoryFacade) equals: true.
	self assert: (classChecksByName at: #GbsRepositoryFacade) equals: true.
	self assert: (classChecksByName at: #GbsRepositoryRootFacade) equals: true.
	self assert: (classChecksByName at: #CoreTestableGbsInspector) equals: true.
	self assert: (classChecksByName at: #CoreTestableGbsSymbolListBrowserPresenter) equals: true.
	self assert: (classChecksByName at: #CoreTestableGbxTrippy) equals: true.
	self assert: (classChecksByName at: #CoreTestableGbsWorkspace) equals: true.
	self assert: (classChecksByName at: #GbxTrippyCoreToolsTest) equals: true.
	self assert: (classChecksByName at: #CoreTestableGbsWorkspaceActions) equals: true.
	self assert: (classChecksByName at: #GbxClassVersionBrowser) equals: true.
	self assert: (classChecksByName at: #GbsRubyRuntimeFacade) equals: false.
	self assert: (selectorChecksByKey at: { #GbsSession. #abortTransaction }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #bridgeRoot }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #chunkedMigrationRunnerFrom:to: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #classHistoryOf: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #commitTransaction }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #commitTransactionOrSignalConflict }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #commitTransactionWithRetryCount: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #invalidateRepositoryRoots }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #withCommitRetryCount:do: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #previewMigrationFrom:to:allowAbort: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #namedObjectAt: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #namedObjectAt:ifAbsent: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #namedObjectCache }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #namedObjectAutoloadRegistry }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #repository }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #repositoryRootFacadeForKey:path: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #repositoryRootLifecycleVersion }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #resetAfterLogout }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #fetchByReference }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #materializationProfile }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #proxyCache }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #objectSpace }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #objectSpaceDiagnosticsReport }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #objectSpaceRepository }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #defineFinalizerFor:do: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #eachObjectDo: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #instancesInMemoryOf: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #loadedClassesIncludingModules }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #sessionStateAt: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #referencesTo: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #objectsInMemory }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #undefineFinalizerFor: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSymbolListBrowserPresenter. #browsePromptedSessionStateKey }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSymbolListBrowserPresenter. #browseReferencersForSelectedEntry }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSymbolListBrowserPresenter. #menuEntry }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSymbolListBrowserPresenter. #menuPreview }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSymbolListBrowserPresenter. #refreshUsers }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSymbolListBrowserPresenter. #withShallowMaterializationDo: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsPlaygroundActions. #class. #gsInspectItIn: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsPlaygroundActions. #class. #gsBrowseObjectsInMemoryReportIn: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsWorkspace. #browsePromptedSessionStateKey }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsWorkspace. #browseTypedWrapperLifecycleReport }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsWorkspace. #browseObjectsInMemoryReport }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsWorkspace. #inspectIt }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsWorkspace. #workspaceMenu }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsBrowser. #browseNamedObjectCacheReport }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsBrowser. #browsePromptedSessionStateKey }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsBrowser. #menuSession }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsInspector. #browsePromptedSessionStateKey }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsInspector. #browsePromptedSessionStateKeysReport }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsInspector. #browseReportChooser }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsStructuredValueInspectorPresenter. #browsePromptedSessionStateKey }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsStructuredValueInspectorPresenter. #browsePromptedSessionStateKeysReport }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsStructuredValueInspectorPresenter. #menuEntry }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsClassicLauncher. #class. #inspectCurrentUserGlobalsOnCurrentSession }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsClassicLauncher. #class. #openNamespacesOnCurrentSession }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsClassicLauncher. #class. #queryOrganizerMethodsFor:mode:inSession: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsClassicLauncher. #browseNamedObjectCacheReport }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsClassicLauncher. #inspectPromptedSessionStateKey }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsClassicLauncher. #menuSession }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsMethodQueryResultsPresenter. #browseNamedObjectCacheReport }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsMethodQueryResultsPresenter. #browsePromptedSessionStateKey }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsMethodQueryResultsPresenter. #menuSession }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsRemoteDebugger. #browsePromptedSessionStateKey }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsRemoteDebugger. #browsePromptedSessionStateKeysReport }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsRemoteDebugger. #fetchContextsDirectly }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsRemoteDebugger. #methodMenu }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsRemoteDebugger. #remoteDebugProcess }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsRemoteDebugger. #returnFromFrame }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsRemoteDebugger. #sessionMenu }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsRemoteDebugger. #stepReturn }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxContextListPolicy. #buildContextListFromServerContexts: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxContextListPolicy. #updateContextListFromServerContexts: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxTrippy. #buildToolbar }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxTrippy. #browseReferencersInMemory }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxTrippy. #withShallowMaterializationDo: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxDebuggerService. #browseMethod }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxDebuggerService. #canExecuteOnDebugProcess }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxDebuggerService. #currentProcessOop }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxDebuggerService. #legacyCompileLookup }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxDebuggerService. #remoteDebugProcess }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxDebuggerService. #restartLevelFromServerStack }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxDebuggerService. #selectedMethodClassName }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxDebuggerService. #sourceCode }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxDebuggerService. #selectedRemoteMethodObject }) equals: false.
	self assert: (selectorChecksByKey at: { #GBSM. #class. #commitTransactionOrSignalConflict }) equals: true.
	self assert: (selectorChecksByKey at: { #GbxClassVersionBrowser. #previewMigrationToLatestAllowAbort: }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsRemoteMethodMirror. #asMethodObject }) equals: true.
	self assert: (selectorChecksByKey at: { #GbsSession. #rubyRuntime }) equals: false.
	self assert: (selectorChecksByKey at: { #GbsRemoteNamespaceMirror. #loadPath }) equals: false.
	self assert: (selectorChecksByKey at: { #GbsRemoteDebugger. #addExtensionSessionMenuItemsTo: }) equals: false.
	self assert: (selectorChecksByKey at: { #GbsWorkspace. #addExtensionWorkspaceMenuItemsTo: }) equals: false.
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
	| laneNames bootstrapLane originalTestsLane fullLane verifyLane artifactLane |
	laneNames := self contract verificationLaneSpecs collect: [ :each | each first ].
	bootstrapLane := self contract verificationLaneSpecs
		detect: [ :each | each first = 'bootstrap-smoke' ].
	originalTestsLane := self contract verificationLaneSpecs
		detect: [ :each | each first = 'original-tests' ].
	fullLane := self contract verificationLaneSpecs
		detect: [ :each | each first = 'full' ].
	verifyLane := self contract verificationLaneSpecs
		detect: [ :each | each first = 'verify' ].
	artifactLane := self contract verificationLaneSpecs
		detect: [ :each | each first = 'artifact-freshness' ].

	self assert: laneNames asSet equals: #('core-only' 'bootstrap-smoke' 'original-tests' 'full' 'artifact-freshness' 'verify') asSet.
	self deny: (laneNames includes: 'compatibility-only').
	self deny: (laneNames includes: 'retirement-preview').
	self assert: ((self contract verificationLaneSpecs detect: [ :each | each first = 'core-only' ]) fifth includes: 'NO_COMPATIBILITY_PROOF_OK').
	self assert: bootstrapLane third equals: 'Core-Tests'.
	self assert: (bootstrapLane fifth includes: 'BOOTSTRAP_SMOKE_OK').
	self assert: (bootstrapLane fifth includes: 'BOOTSTRAP_SMOKE_DONE').
	self assert: originalTestsLane third equals: 'Original-Tests'.
	self assert: originalTestsLane fourth equals: #('GemStone-Pharo-Tests').
	self assert: (originalTestsLane fifth includes: 'ORIGINAL_TESTS_CHECK_OK').
	self assert: (fullLane fourth includes: 'GemStone-Pharo-Core-Tests').
	self assert: (fullLane fourth includes: 'GemStone-Pharo-Tests').
	self deny: (fullLane fourth includes: 'GemStone-Pharo-Compatibility-Tests').
	self assert: (fullLane fifth includes: 'NO_COMPAT_SOURCE_SCAN_OK').
	self assert: (fullLane fifth includes: 'NO_COMPATIBILITY_PROOF_OK').
	self assert: (artifactLane fourth includes: 'doc/LIVE-PREFLIGHT-POLICY.md').
	self assert: (artifactLane fourth includes: 'doc/RELOAD-POLICY.md').
	self assert: (artifactLane fourth includes: 'doc/USER-MANUAL-REFERENCE.html').
	self assert: (artifactLane fourth includes: 'doc/OWNERSHIP-CONTRACT.md').
	self assert: verifyLane fourth equals: #('core-only' 'bootstrap-smoke' 'original-tests' 'full' 'artifact-freshness' 'summary-renderer')
]
