Class {
	#name : 'GemStonePharoPackageContract',
	#superclass : 'Object',
	#instVars : [
		'contract'
	],
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'instance creation' }
GemStonePharoPackageContract class >> on: aContract [
	^ self new
		contract: aContract;
		yourself
]

{ #category : 'accessing' }
GemStonePharoPackageContract >> contract [
	^ contract
]

{ #category : 'accessing' }
GemStonePharoPackageContract >> contract: aContract [
	contract := aContract
]

{ #category : 'forwarding' }
GemStonePharoPackageContract >> coreOnlyExplicitSelectorChecks [
	^ contract coreOnlyExplicitSelectorChecks
]

{ #category : 'forwarding' }
GemStonePharoPackageContract >> coreOnlyLoadedPackageNames [
	^ contract coreOnlyLoadedPackageNames
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> coreOnlyClassChecks [
	| loadedPackages checks seen |
	loadedPackages := self coreOnlyLoadedPackageNames asSet.
	checks := OrderedCollection new.
	seen := Set new.
	self packageOwnershipClassSpecs do: [ :spec |
		(seen includes: spec first) ifFalse: [
			checks add: { spec first. (loadedPackages includes: spec second) }.
			seen add: spec first ] ].
	^ checks asArray
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> coreOnlyPackageChecks [
	| loadedPackages checks |
	loadedPackages := self coreOnlyLoadedPackageNames asSet.
	checks := OrderedCollection new.
	self packageRequirementSpecs do: [ :spec |
		checks add: { spec first. (loadedPackages includes: spec first) } ].
	^ checks asArray
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> coreOnlySelectorChecks [
	| byKey |
	byKey := Dictionary new.
	(self coreOnlyDerivedSelectorChecks , self coreOnlyExplicitSelectorChecks)
		do: [ :each | byKey at: { each first. each second. each third } put: each ].
	^ byKey values asArray
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> coreOnlyDerivedSelectorChecks [
	| loadedPackages checks seen classChecksByName |
	loadedPackages := self coreOnlyLoadedPackageNames asSet.
	checks := OrderedCollection new.
	seen := Set new.
	classChecksByName := Dictionary new.
	self coreOnlyClassChecks do: [ :each |
		classChecksByName at: each first put: each second ].
	self packageOwnershipSelectorSpecs do: [ :spec |
		| key shouldExist |
		key := { spec first. spec second. spec third }.
		shouldExist := loadedPackages includes: spec fourth.
		(seen includes: key) ifFalse: [
			((classChecksByName at: spec first ifAbsent: [ true ]) or: [ shouldExist ])
				ifTrue: [ checks add: { spec first. spec second. spec third. shouldExist } ].
			seen add: key ] ].
	^ checks asArray
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> forbiddenPackageRequirementSpecs [
	^ {
		{ 'GemStone-GBS-Tools'. #('GemStone-GBS-Core' 'GemStone-GBS-Core-Tools' 'GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'GemStone-Pharo-Core-Tests'. #('GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'GemStone-GBS-Converted'. #('GemStone-GBS-Core' 'GemStone-GBS-Core-Tools' 'GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools' 'GemStone-GBS-Tools') } }
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> groupMemberSpecs [
	^ {
		{ 'Original'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools') }.
		{ 'Original-Tests'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools' 'GemStone-Pharo-Tests') }.
		{ 'Core'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core') }.
		{ 'Core-Only'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core') }.
		{ 'Core-Tools'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core' 'GemStone-GBS-Tools' 'GemStone-GBS-Core-Tools') }.
		{ 'Core-Tests'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core' 'GemStone-GBS-Tools' 'GemStone-GBS-Core-Tools' 'GemStone-Pharo-Core-Tests') }.
		{ 'MagLev-Core'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core' 'GemStone-GBS-MagLev') }.
		{ 'MagLev-Tools'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core' 'GemStone-GBS-Tools' 'GemStone-GBS-Core-Tools' 'GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'MagLev'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core' 'GemStone-GBS-MagLev') }.
		{ 'Tools'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core' 'GemStone-GBS-Tools' 'GemStone-GBS-Core-Tools') }.
		{ 'All-Tests'. #('GemStone-Pharo-Tests' 'GemStone-Pharo-Core-Tests' 'GemStone-Pharo-MagLev-Tests') }.
		{ 'Tests'. #('GemStone-Pharo-Tests' 'GemStone-Pharo-Core-Tests' 'GemStone-Pharo-MagLev-Tests') }.
		{ 'Full'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core' 'GemStone-GBS-MagLev' 'GemStone-GBS-Tools' 'GemStone-GBS-Core-Tools' 'GemStone-GBS-MagLev-Tools' 'GemStone-Pharo-Tests' 'GemStone-Pharo-Core-Tests' 'GemStone-Pharo-MagLev-Tests') }.
		{ 'default'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core' 'GemStone-GBS-MagLev' 'GemStone-GBS-Tools' 'GemStone-GBS-Core-Tools' 'GemStone-GBS-MagLev-Tools' 'GemStone-Pharo-Tests' 'GemStone-Pharo-Core-Tests' 'GemStone-Pharo-MagLev-Tests') } }
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipAllowedPackagesByFamily [
	^ Dictionary newFromPairs: {
		#coreOnly. #('GemStone-GBS-Core').
		#coreToolsOnly. #('GemStone-GBS-Core-Tools').
		#coreWithMaglev. #('GemStone-GBS-Core' 'GemStone-GBS-MagLev').
		#coreTestsOnly. #('GemStone-Pharo-Core-Tests').
		#maglevTestsOnly. #('GemStone-Pharo-MagLev-Tests').
		#convertedWithCore. #('GemStone-GBS-Converted' 'GemStone-GBS-Core').
		#convertedOnly. #('GemStone-GBS-Converted').
		#convertedWithCoreAndMaglev. #('GemStone-GBS-Converted' 'GemStone-GBS-Core' 'GemStone-GBS-MagLev').
		#convertedWithMaglev. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev').
		#maglevOnly. #('GemStone-GBS-MagLev').
		#maglevToolsOnly. #('GemStone-GBS-MagLev-Tools').
		#toolsOnly. #('GemStone-GBS-Tools').
		#toolsWithCoreToolsAndMaglevTools. #('GemStone-GBS-Tools' 'GemStone-GBS-Core-Tools' 'GemStone-GBS-MagLev-Tools').
		#toolsWithMaglevTools. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipBehaviorFamilySpecs [
	^ self packageOwnershipInstanceBehaviorFamilySpecs
		, self packageOwnershipDerivedClassSideBehaviorFamilySpecs
		, self packageOwnershipExplicitBehaviorFamilySpecs
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipDerivedClassSideBehaviorFamilySpecs [
	^ self packageOwnershipInstanceBehaviorFamilySpecs collect: [ :spec |
		{ spec first. #class. spec third } ]
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipExplicitBehaviorFamilySpecs [
	^ {
		{ #GBSM. #class. #convertedWithCoreAndMaglev }.
		{ #GbsPlaygroundActions. #class. #toolsWithCoreToolsAndMaglevTools } }
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipInstanceBehaviorFamilySpecs [
	^ {
		{ #GbsBridgeRootFacade. #instance. #coreOnly }.
		{ #GbsBrowser. #instance. #toolsWithCoreToolsAndMaglevTools }.
		{ #GbsClassHistoryFacade. #instance. #coreOnly }.
		{ #GbsCacheSessionStateSlot. #instance. #coreOnly }.
		{ #GbsClassicLauncher. #instance. #toolsWithCoreToolsAndMaglevTools }.
		{ #GbsChunkedMigrationRunner. #instance. #coreOnly }.
		{ #GbsCompilerStateSessionStateSlot. #instance. #maglevOnly }.
		{ #GbsDeepMaterializationProfile. #instance. #coreOnly }.
		{ #GbsDirtyStoreTraversalBuffer. #instance. #coreOnly }.
		{ #GbsFinalizerRegistrySessionStateSlot. #instance. #maglevOnly }.
		{ #GbsInspector. #instance. #toolsWithCoreToolsAndMaglevTools }.
		{ #GbsLegacyMaterializationProfile. #instance. #coreOnly }.
		{ #GbsMaglevFacade. #instance. #maglevOnly }.
		{ #GbsMaglevRuntimeProxy. #instance. #maglevOnly }.
		{ #GbsMaterializationProfile. #instance. #coreOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #toolsWithCoreToolsAndMaglevTools }.
		{ #GbsMigrationPlan. #instance. #coreOnly }.
		{ #GbsMigrationPlanEntry. #instance. #coreOnly }.
		{ #GbsNamespaceScopedMethodQuery. #instance. #coreOnly }.
		{ #GbsNamespacesPresenter. #instance. #toolsWithMaglevTools }.
		{ #GbsObjectFinalizer. #instance. #coreOnly }.
		{ #GbsObjectReferencerReport. #instance. #coreOnly }.
		{ #GbsObjectScanReport. #instance. #coreOnly }.
		{ #GbsObjectSpaceDiagnosticsFacade. #instance. #coreWithMaglev }.
		{ #GbsObjectSpaceDiagnosticsReport. #instance. #coreOnly }.
		{ #GbsObjectSpaceFacade. #instance. #coreWithMaglev }.
		{ #GbsObjectSpaceRepositoryFacade. #instance. #coreOnly }.
		{ #GbsObjectLogEntry. #instance. #maglevOnly }.
		{ #GbsObjectLogFacade. #instance. #maglevOnly }.
		{ #GbsPlaygroundGsInspectSessionStateCommand. #instance. #coreToolsOnly }.
		{ #GbsPlaygroundGsObjectsInMemoryReportCommand. #instance. #coreToolsOnly }.
		{ #GbsPlaygroundGsSessionStateKeysReportCommand. #instance. #coreToolsOnly }.
		{ #GbsPlaygroundGsStaleTypedWrapperReportCommand. #instance. #coreToolsOnly }.
		{ #GbsPlaygroundGsTypedWrapperLifecycleReportCommand. #instance. #coreToolsOnly }.
		{ #GbsPlaygroundMenuInspectSessionStateCommand. #instance. #coreToolsOnly }.
		{ #GbsPlaygroundMenuObjectsInMemoryReportCommand. #instance. #coreToolsOnly }.
		{ #GbsPlaygroundMenuSessionStateKeysReportCommand. #instance. #coreToolsOnly }.
		{ #GbsPlaygroundMenuStaleTypedWrapperReportCommand. #instance. #coreToolsOnly }.
		{ #GbsPlaygroundMenuTypedWrapperLifecycleReportCommand. #instance. #coreToolsOnly }.
		{ #GbsProxyLifecycle. #instance. #coreOnly }.
		{ #GbsProxyOnlyMaterializationProfile. #instance. #coreOnly }.
		{ #GbsRemoteDebugProcessFacade. #instance. #coreOnly }.
		{ #GbsRemoteCommand. #instance. #coreOnly }.
		{ #GbsRemoteScriptBuilder. #instance. #coreOnly }.
		{ #GbsRemoteAutoloadMirror. #instance. #maglevOnly }.
		{ #GbsRemoteClassMirror. #instance. #coreOnly }.
		{ #GbsRemoteConstantMirror. #instance. #coreWithMaglev }.
		{ #GbsRemoteDebugger. #instance. #toolsWithCoreToolsAndMaglevTools }.
		{ #GbsRemoteDebuggerMenuBuilder. #instance. #toolsOnly }.
		{ #GbsRemoteDebuggerSourceResolver. #instance. #toolsOnly }.
		{ #GbsRemoteDebuggerStackFetcher. #instance. #toolsOnly }.
		{ #GbsRemoteMethodMirror. #instance. #coreOnly }.
		{ #GbsRemoteMethodObject. #instance. #coreWithMaglev }.
		{ #GbsRemoteNamespaceMirror. #instance. #coreWithMaglev }.
		{ #GbsReportSection. #instance. #coreOnly }.
		{ #GbsRepositoryFacade. #instance. #coreOnly }.
		{ #GbsRepositoryRootFacade. #instance. #coreOnly }.
		{ #GbsRemoteUnboundMethodObject. #instance. #coreOnly }.
		{ #GbsRubyRuntimeFacade. #instance. #maglevOnly }.
		{ #GbsSession. #instance. #convertedWithCoreAndMaglev }.
		{ #GbsSessionEventController. #instance. #coreOnly }.
		{ #GbsSessionLifecycleManager. #instance. #coreOnly }.
		{ #GbsSessionMaterializationRemoteReader. #instance. #coreOnly }.
		{ #GbsSessionStateSlot. #instance. #coreOnly }.
		{ #GbsShallowMaterializationProfile. #instance. #coreOnly }.
		{ #GbsSmalltalkFacade. #instance. #coreWithMaglev }.
		{ #GbsStackSessionStateSlot. #instance. #maglevOnly }.
		{ #GbsSymbolDictionaryFacade. #instance. #coreOnly }.
		{ #GbsTypedProxy. #instance. #coreOnly }.
		{ #GbsTypedWrapperBuilder. #instance. #coreOnly }.
		{ #GbsTypedWrapperLifecycleEntry. #instance. #coreOnly }.
		{ #GbsTypedWrapperLifecycleReport. #instance. #coreOnly }.
		{ #GbsThreadStateSessionStateSlot. #instance. #coreOnly }.
		{ #GbsRegistrySessionStateSlot. #instance. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #convertedWithCore }.
		{ #GbsBrowserCoreToolsTest. #instance. #coreTestsOnly }.
		{ #GbsPlaygroundCoreActionsTest. #instance. #coreTestsOnly }.
		{ #GbsClassicLauncherCoreToolsTest. #instance. #coreTestsOnly }.
		{ #GbsInspectorCoreToolsTest. #instance. #coreTestsOnly }.
		{ #GbsMethodQueryResultsPresenterCoreToolsTest. #instance. #coreTestsOnly }.
		{ #GbsRemoteDebuggerCoreToolsTest. #instance. #coreTestsOnly }.
		{ #GbsSessionCoreTest. #instance. #coreTestsOnly }.
		{ #GbsSessionManagerCoreTest. #instance. #coreTestsOnly }.
		{ #GbsStructuredValueInspectorPresenterCoreToolsTest. #instance. #coreTestsOnly }.
		{ #GbsSymbolListBrowserPresenterCoreToolsTest. #instance. #coreTestsOnly }.
		{ #GbxTrippyCoreToolsTest. #instance. #coreTestsOnly }.
		{ #GbsWorkspaceCoreActionsTest. #instance. #coreTestsOnly }.
		{ #CoreTestableGbsClassicLauncher. #instance. #coreTestsOnly }.
		{ #CoreTestableGbsMethodQueryResultsPresenter. #instance. #coreTestsOnly }.
		{ #CoreTestableGbsRemoteDebugger. #instance. #coreTestsOnly }.
		{ #CoreTestableGbsBrowser. #instance. #coreTestsOnly }.
		{ #CoreGbxFakeCheckBoxForBrowser. #instance. #coreTestsOnly }.
		{ #CoreGbxFakeServiceForRemoteDebugger. #instance. #coreTestsOnly }.
		{ #CoreGbxFakeContextForRemoteDebugger. #instance. #coreTestsOnly }.
		{ #CoreGbxFakeListPresenterForBrowser. #instance. #coreTestsOnly }.
		{ #CoreGbxFakeListPresenterForRemoteDebugger. #instance. #coreTestsOnly }.
		{ #CoreGbxFakeTablePresenterForRemoteDebugger. #instance. #coreTestsOnly }.
		{ #CoreGbxFakeTextPresenterForBrowser. #instance. #coreTestsOnly }.
		{ #CoreTestableGbsInspector. #instance. #coreTestsOnly }.
		{ #CoreTestableGbsSymbolListBrowserPresenter. #instance. #coreTestsOnly }.
		{ #CoreTestableGbxTrippy. #instance. #coreTestsOnly }.
		{ #CoreTestableGbsWorkspace. #instance. #coreTestsOnly }.
		{ #CoreMockGbsPlaygroundPresenter. #instance. #coreTestsOnly }.
		{ #CoreMockGbsSession. #instance. #coreTestsOnly }.
		{ #CoreGbsLiveSessionTestSupport. #instance. #coreTestsOnly }.
		{ #CoreTestableGbsWorkspaceActions. #instance. #coreTestsOnly }.
		{ #CoreGbsMigrationDomainOrder. #instance. #coreTestsOnly }.
		{ #CoreGbsMigrationDomainMappedOrder. #instance. #coreTestsOnly }.
		{ #GbsBrowserMagLevToolsTest. #instance. #maglevTestsOnly }.
		{ #GbsClassicLauncherMagLevToolsTest. #instance. #maglevTestsOnly }.
		{ #GbsInspectorMagLevToolsTest. #instance. #maglevTestsOnly }.
		{ #GbsMethodQueryResultsPresenterMagLevToolsTest. #instance. #maglevTestsOnly }.
		{ #GbsSessionMagLevTest. #instance. #maglevTestsOnly }.
		{ #GbsSessionManagerMagLevTest. #instance. #maglevTestsOnly }.
		{ #GbsWorkspaceMagLevToolsTest. #instance. #maglevTestsOnly }.
{ #GbxTrippyMagLevToolsTest. #instance. #maglevTestsOnly }.
{ #GbsNamespacesPresenterMagLevToolsTest. #instance. #maglevTestsOnly }.
{ #GbsStructuredValueInspectorPresenterMagLevToolsTest. #instance. #maglevTestsOnly }.
{ #GbsSymbolListBrowserPresenterMagLevToolsTest. #instance. #maglevTestsOnly }.
{ #TestableGbsNamespacesPresenter. #instance. #maglevTestsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #toolsWithCoreToolsAndMaglevTools }.
		{ #GbsSymbolListBrowserPresenter. #instance. #toolsWithCoreToolsAndMaglevTools }.
		{ #GbsWorkspace. #instance. #toolsWithCoreToolsAndMaglevTools }.
		{ #GbxContextListPolicy. #instance. #toolsWithCoreToolsAndMaglevTools }.
		{ #GbxDebuggerBreakpointController. #instance. #toolsOnly }.
		{ #GbxDebuggerCompileController. #instance. #toolsOnly }.
		{ #GbxDebuggerService. #instance. #toolsWithCoreToolsAndMaglevTools }.
		{ #GbxDebuggerProcessController. #instance. #toolsOnly }.
		{ #GbxTrippy. #instance. #toolsWithCoreToolsAndMaglevTools } }
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipBehaviorSpecs [
	| packagesByFamily |
	packagesByFamily := self packageOwnershipAllowedPackagesByFamily.
	^ self packageOwnershipBehaviorFamilySpecs collect: [ :spec |
		{ spec first. spec second. (packagesByFamily at: spec third) } ]
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipClassSpecs [
	^ self packageOwnershipDerivedClassSpecs , self packageOwnershipExplicitClassSpecs
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipDerivedClassSpecs [
	| packagesByFamily primaryClassPackagesByFamily |
	packagesByFamily := self packageOwnershipAllowedPackagesByFamily.
	primaryClassPackagesByFamily := self packageOwnershipPrimaryClassPackagesByFamily.
	^ (self packageOwnershipBehaviorFamilySpecs
		select: [ :spec | spec second = #instance ])
		collect: [ :spec |
			| allowedPackages expectedPackage |
			allowedPackages := packagesByFamily at: spec third.
			expectedPackage := allowedPackages size = 1
				ifTrue: [ allowedPackages first ]
				ifFalse: [ primaryClassPackagesByFamily at: spec third ifAbsent: [
					self error: 'Missing primary class package for ownership family: ', spec third asString ] ].
			{ spec first. expectedPackage } ]
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipExplicitClassSpecs [
	| packagesByFamily primaryClassPackagesByFamily |
	packagesByFamily := self packageOwnershipAllowedPackagesByFamily.
	primaryClassPackagesByFamily := self packageOwnershipPrimaryClassPackagesByFamily.
	^ self packageOwnershipExplicitClassFamilySpecs collect: [ :spec |
		| allowedPackages expectedPackage |
		allowedPackages := packagesByFamily at: spec second.
		expectedPackage := allowedPackages size = 1
			ifTrue: [ allowedPackages first ]
			ifFalse: [ primaryClassPackagesByFamily at: spec second ifAbsent: [
				self error: 'Missing primary class package for ownership family: ', spec second asString ] ].
		{ spec first. expectedPackage } ]
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipExplicitClassFamilySpecs [
	^ self packageOwnershipExplicitClassGroupSpecs flatCollect: [ :spec |
		spec second collect: [ :suffix |
			{ (spec first asString , suffix) asSymbol. spec third } ] ]
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipExplicitClassGroupSpecs [
	^ {
		{ #GbsCommitConflictError. #(''). #coreOnly }.
		{ #GbsMaterializationLimitError. #(''). #coreOnly }.
		{ #GbsRc. #('Counter' 'Hash' 'Queue'). #maglevOnly }.
		{ #GbsSharedCounter. #(''). #maglevOnly }.
		{ #GbsGs. #('Object' 'Dictionary'). #maglevOnly }.
		{ #GbxExecBlock. #('' '0' '1' '2' '3' '4' '5' 'N'). #convertedWithMaglev }.
		{ #GbsStDB. #('badAtRuby' 'noRuby'). #convertedWithMaglev }.
		{ #GbsErrRubySystemExitErr. #(''). #convertedWithMaglev } }
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipExplicitSelectorSpecs [
	^ #()
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipPrimaryClassPackagesByFamily [
	^ Dictionary newFromPairs: {
		#convertedWithCore. 'GemStone-GBS-Converted'.
		#convertedWithCoreAndMaglev. 'GemStone-GBS-Converted'.
		#convertedWithMaglev. 'GemStone-GBS-Converted'.
		#coreWithMaglev. 'GemStone-GBS-Core'.
		#toolsWithCoreToolsAndMaglevTools. 'GemStone-GBS-Tools'.
		#toolsWithMaglevTools. 'GemStone-GBS-Tools' }
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipCorePackages [
	^ #(
		'GemStone-GBS-Converted'
		'GemStone-GBS-Core'
		'GemStone-GBS-Core-Tools'
		'GemStone-GBS-Tools')
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipForbiddenCoreClassPatterns [
	^ #(
		'GbsMaglev'
		'GbsRuby'
		'GbsObjectLog'
		'GbsFinalizerRegistrySessionStateSlot'
		'GbsRcCounter'
		'GbsRcHash'
		'GbsRcQueue'
		'GbsSharedCounter'
		'GbsRemoteAutoload'
		'GbsRemoteProcObject'
		'GbsRemoteBindingObject'
		'GbsRemoteExecBlockObject')
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipForbiddenCoreSelectorPatterns [
	^ #(
		'addmaglev'
		'autoloadmirrors'
		'browseruby'
		'configuremaglev'
		'loadedfeatures'
		'loadpath'
		'maglevfinalizerregistry'
		'objectlog'
		'persistentloadedfeatures'
		'persistentroot'
		'registerautoload'
		'removeautoload'
		'requirefilenamed'
		'retryautoload'
		'rubyruntime'
		'sessionmethods'
		'supportsautoload')
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipSelectorSpecs [
	| packagesByFamily derived |
	packagesByFamily := self packageOwnershipAllowedPackagesByFamily.
	derived := self packageOwnershipSelectorFamilySpecs collect: [ :spec |
		| allowedPackages |
		allowedPackages := packagesByFamily at: spec fourth.
		allowedPackages size = 1 ifFalse: [
			self error: 'Selector ownership family must resolve to a single package: ', spec fourth asString ].
		{ spec first. spec second. spec third. allowedPackages first } ].
	^ derived , self packageOwnershipExplicitSelectorSpecs
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageOwnershipSelectorFamilySpecs [
	^ {
		{ #GbsSession. #instance. #abortTransaction. #coreOnly }.
		{ #GbsSession. #instance. #bridgeRoot. #coreOnly }.
		{ #GbsSession. #instance. #chunkedMigrationRunnerFrom:to:. #coreOnly }.
		{ #GbsSession. #instance. #classHistoryOf:. #coreOnly }.
		{ #GbsSession. #instance. #commitTransaction. #coreOnly }.
		{ #GbsSession. #instance. #commitTransactionOrSignalConflict. #coreOnly }.
		{ #GbsSession. #instance. #commitTransactionWithRetryCount:. #coreOnly }.
		{ #GbsSession. #instance. #invalidateRepositoryRoots. #coreOnly }.
		{ #GbsSession. #instance. #remoteScriptBuilder. #coreOnly }.
		{ #GbsSession. #instance. #withCommitRetryCount:do:. #coreOnly }.
		{ #GbsSession. #instance. #withGemStoneTransactionDo:. #coreOnly }.
		{ #GbsSession. #instance. #withGemStoneTransactionRetryCount:do:. #coreOnly }.
		{ #GbsSession. #instance. #previewMigrationFrom:to:. #coreOnly }.
		{ #GbsSession. #instance. #previewMigrationFrom:to:allowAbort:. #coreOnly }.
		{ #GbsSession. #instance. #previewMigrationWithSubclassesOf:. #coreOnly }.
		{ #GbsSession. #instance. #previewMigrationWithSubclassesOf:allowAbort:. #coreOnly }.
		{ #GbsSession. #instance. #migrateInstancesFrom:to:. #coreOnly }.
		{ #GbsSession. #instance. #migrateInstancesFrom:to:allowAbort:. #coreOnly }.
		{ #GbsSession. #instance. #migrateInstancesWithSubclassesOf:. #coreOnly }.
		{ #GbsSession. #instance. #migrateInstancesWithSubclassesOf:allowAbort:. #coreOnly }.
		{ #GbsSession. #instance. #namedObjectAt:. #coreOnly }.
		{ #GbsSession. #instance. #namedObjectAt:ifAbsent:. #coreOnly }.
		{ #GbsSession. #instance. #namedObjectCache. #coreOnly }.
		{ #GbsSession. #instance. #clearNamedObjectCache. #coreOnly }.
		{ #GbsSession. #instance. #namedObjectAutoloadRegistry. #coreOnly }.
		{ #GbsSession. #instance. #clearNamedObjectAutoloads. #coreOnly }.
		{ #GbsSession. #instance. #registerNamedObjectAutoload:. #coreOnly }.
		{ #GbsSession. #instance. #registerNamedObjectAutoload:remote:. #coreOnly }.
		{ #GbsSession. #instance. #unregisterNamedObjectAutoload:. #coreOnly }.
		{ #GbsSession. #instance. #hasNamedObjectAutoloadNamed:. #coreOnly }.
		{ #GbsSession. #instance. #namedObjectAutoloadTargetFor:. #coreOnly }.
		{ #GbsSession. #instance. #namedObjectAutoloadEntries. #coreOnly }.
		{ #GbsSession. #instance. #namedObjectAutoloadKeys. #coreOnly }.
		{ #GbsSession. #instance. #namedObjectAutoloadReportText. #coreOnly }.
		{ #GbsSession. #instance. #hasCachedNamedObjectNamed:. #coreOnly }.
		{ #GbsSession. #instance. #normalizedNamedObjectName:. #coreOnly }.
		{ #GbsSession. #instance. #namedObjectCacheEntries. #coreOnly }.
		{ #GbsSession. #instance. #namedObjectCacheKeys. #coreOnly }.
		{ #GbsSession. #instance. #namedObjectCacheReportText. #coreOnly }.
		{ #GbsSession. #instance. #executeScriptAndReturnOop:. #coreOnly }.
		{ #GbsSession. #instance. #fetchObject:withProfile:depth:seen:. #coreOnly }.
		{ #GbsSession. #instance. #fetchProfile. #coreOnly }.
		{ #GbsSession. #instance. #fetchProfile:. #coreOnly }.
		{ #GbsSession. #instance. #fetchByReference. #coreOnly }.
		{ #GbsSession. #instance. #fetchDeep. #coreOnly }.
		{ #GbsSession. #instance. #fetchLegacy. #coreOnly }.
		{ #GbsSession. #instance. #fetchShallow. #coreOnly }.
		{ #GbsSession. #instance. #isImmediateOop:. #coreOnly }.
		{ #GbsSession. #instance. #materializationProfile. #coreOnly }.
		{ #GbsSession. #instance. #materializationProfile:. #coreOnly }.
		{ #GbsSession. #instance. #materializeArrayOop:withProfile:depth:seen:. #coreOnly }.
		{ #GbsSession. #instance. #materializeAssociationOop:withProfile:depth:seen:. #coreOnly }.
		{ #GbsSession. #instance. #materializeByteArrayOop:withProfile:depth:seen:. #coreOnly }.
		{ #GbsSession. #instance. #materializeDictionaryOop:identityKeys:withProfile:depth:seen:. #coreOnly }.
		{ #GbsSession. #instance. #materializeSequenceableCollectionOop:using:withProfile:depth:seen:. #coreOnly }.
		{ #GbsSession. #instance. #withMaterializationProfile:do:. #coreOnly }.
		{ #GbsSession. #instance. #proxyForOop:. #coreOnly }.
		{ #GbsSession. #instance. #proxyForOop:serverClassName:. #coreOnly }.
		{ #GbsSession. #instance. #proxyForOop:usingClass:. #coreOnly }.
		{ #GbsSession. #instance. #cachedProxyForOop:. #coreOnly }.
		{ #GbsSession. #instance. #proxyCache. #coreOnly }.
		{ #GbsSession. #instance. #clearProxyCache. #coreOnly }.
		{ #GbsSession. #instance. #remoteArrayElementOopAt:ofOop:. #coreOnly }.
		{ #GbsSession. #instance. #remoteAssociationPairOopFor:. #coreOnly }.
		{ #GbsSession. #instance. #remoteClassNameForOop:. #coreOnly }.
		{ #GbsSession. #instance. #remoteCollectionAsArrayOop:. #coreOnly }.
		{ #GbsSession. #instance. #remoteDictionaryAssociationsAsArrayOop:. #coreOnly }.
		{ #GbsSession. #instance. #remoteSizeForOop:. #coreOnly }.
		{ #GbsSession. #instance. #remoteStringValueForOop:. #coreOnly }.
		{ #GbsSession. #instance. #objectForOop:. #coreOnly }.
		{ #GbsSession. #instance. #objectSpace. #coreOnly }.
		{ #GbsSession. #instance. #objectSpaceDiagnostics. #coreOnly }.
		{ #GbsSession. #instance. #objectSpaceDiagnosticsReport. #coreOnly }.
		{ #GbsSession. #instance. #objectSpaceRepository. #coreOnly }.
		{ #GbsSession. #instance. #defineFinalizerFor:do:. #coreOnly }.
		{ #GbsSession. #instance. #eachObjectDo:. #coreOnly }.
		{ #GbsSession. #instance. #eachObjectDo:batchSize:. #coreOnly }.
		{ #GbsSession. #instance. #eachObjectOf:do:. #coreOnly }.
		{ #GbsSession. #instance. #eachObjectOf:do:batchSize:. #coreOnly }.
		{ #GbsSession. #instance. #allSubclassesOf:. #coreOnly }.
		{ #GbsSession. #instance. #allSubclassesOfNamed:. #coreOnly }.
		{ #GbsSession. #instance. #instancesInMemoryOf:. #coreOnly }.
		{ #GbsSession. #instance. #instancesInMemoryOf:from:limit:. #coreOnly }.
		{ #GbsSession. #instance. #instancesInMemoryOfNamed:. #coreOnly }.
		{ #GbsSession. #instance. #hasFinalizerFor:. #coreOnly }.
		{ #GbsSession. #instance. #loadedClassesIncludingModules. #coreOnly }.
		{ #GbsSession. #instance. #loadedClassesIncludingModules:. #coreOnly }.
		{ #GbsSession. #instance. #sessionStateAt:. #coreOnly }.
		{ #GbsSession. #instance. #sessionStateAt:ifAbsent:. #coreOnly }.
		{ #GbsSession. #instance. #sessionStateAt:put:. #coreOnly }.
		{ #GbsSession. #instance. #referencesTo:. #coreOnly }.
		{ #GbsSession. #instance. #referencesToOop:. #coreOnly }.
		{ #GbsSession. #instance. #objectsInMemory. #coreOnly }.
		{ #GbsSession. #instance. #objectsInMemoryFrom:limit:. #coreOnly }.
		{ #GbsSession. #instance. #objectsInMemoryMatching:. #coreOnly }.
		{ #GbsSession. #instance. #objectsInMemoryMatching:limit:batchSize:. #coreOnly }.
		{ #GbsSession. #instance. #objectsInMemoryOf:from:limit:. #coreOnly }.
		{ #GbsSession. #instance. #objectsInMemoryOf:matching:. #coreOnly }.
		{ #GbsSession. #instance. #objectsInMemoryOf:matching:limit:batchSize:. #coreOnly }.
		{ #GbsSession. #instance. #undefineFinalizerFor:. #coreOnly }.
		{ #GbsSession. #instance. #repository. #coreOnly }.
		{ #GbsSession. #instance. #repositoryRootFacadeForKey:path:. #coreOnly }.
		{ #GbsSession. #instance. #repositoryRootLifecycleVersion. #coreOnly }.
		{ #GbsSession. #instance. #resetAfterLogout. #coreOnly }.
		{ #GbsSession. #instance. #smalltalk. #coreOnly }.
		{ #GbsSession. #instance. #symbolDictionaryNamed:. #coreOnly }.
		{ #GBSM. #class. #chunkedMigrationRunnerFrom:to:. #coreOnly }.
		{ #GBSM. #class. #commitTransactionOrSignalConflict. #coreOnly }.
		{ #GBSM. #class. #commitTransactionWithRetryCount:. #coreOnly }.
		{ #GBSM. #class. #withGemStoneTransactionDo:. #coreOnly }.
		{ #GBSM. #class. #withGemStoneTransactionRetryCount:do:. #coreOnly }.
		{ #GBSM. #class. #previewMigrationFrom:to:. #coreOnly }.
		{ #GBSM. #class. #previewMigrationFrom:to:allowAbort:. #coreOnly }.
		{ #GBSM. #class. #previewMigrationWithSubclassesOf:. #coreOnly }.
		{ #GBSM. #class. #previewMigrationWithSubclassesOf:allowAbort:. #coreOnly }.
		{ #GBSM. #class. #migrateInstancesFrom:to:. #coreOnly }.
		{ #GBSM. #class. #migrateInstancesFrom:to:allowAbort:. #coreOnly }.
		{ #GBSM. #class. #migrateInstancesWithSubclassesOf:. #coreOnly }.
		{ #GBSM. #class. #migrateInstancesWithSubclassesOf:allowAbort:. #coreOnly }.
		{ #GbsSmalltalkFacade. #instance. #bridgeRoot. #coreOnly }.
		{ #GbsSmalltalkFacade. #instance. #withGemStoneTransactionDo:. #coreOnly }.
		{ #GbsSmalltalkFacade. #instance. #withGemStoneTransactionRetryCount:do:. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #classHistory. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #classHistory:. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #canMigrateInstances. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #getClassList. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #impactSummaryForPlan:. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #latestHolder. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #makeCurrentIn:. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #oldVersionHolders. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #previewMigrationTo:allowAbort:. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #previewMigrationToLatestAllowAbort:. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #previewOldVersionsToLatestAllowAbort:. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #removeOldVersionBindingsFrom:. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #selectedHolder. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #migrateInstancesTo:allowAbort:. #coreOnly }.
		{ #GbxClassVersionBrowser. #instance. #executePreviewPlan:allowAbort:. #coreOnly }.
		{ #GbsPlaygroundActions. #class. #gsInspectItIn:. #coreToolsOnly }.
		{ #GbsPlaygroundActions. #class. #gsBrowseTypedWrapperLifecycleReportIn:. #coreToolsOnly }.
		{ #GbsPlaygroundActions. #class. #gsBrowseStaleTypedWrapperLifecycleReportIn:. #coreToolsOnly }.
		{ #GbsPlaygroundActions. #class. #inspectOop:session:. #coreToolsOnly }.
		{ #GbsPlaygroundActions. #class. #inform:. #coreToolsOnly }.
		{ #GbsPlaygroundActions. #class. #gsInspectSessionStateKeyIn:. #coreToolsOnly }.
		{ #GbsPlaygroundActions. #class. #gsBrowseSessionStateKeysReportIn:. #coreToolsOnly }.
		{ #GbsPlaygroundActions. #class. #gsBrowseObjectsInMemoryReportIn:. #coreToolsOnly }.
		{ #GbsPlaygroundActions. #class. #requestInput:initialAnswer:. #coreToolsOnly }.
		{ #GbsPlaygroundActions. #class. #parseSessionStateKeysFrom:. #coreToolsOnly }.
		{ #GbsPlaygroundActions. #class. #requestPositiveInteger:initialAnswer:. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #browseObjectsInMemoryReport. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #browsePromptedSessionStateKey. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #browsePromptedSessionStateKeysReport. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #browseSessionStateAtKey:session:. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #browseStaleTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #browseTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #inspectIt. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #inspectOop:session:. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #parseSessionStateKeysFrom:. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #requestInput:initialAnswer:. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #requestPositiveInteger:initialAnswer:. #coreToolsOnly }.
		{ #GbsWorkspace. #instance. #workspaceMenu. #coreToolsOnly }.
		{ #GbsClassicLauncher. #class. #inspectCurrentUserGlobalsOnCurrentSession. #coreToolsOnly }.
		{ #GbsClassicLauncher. #class. #openNamespacesOnCurrentSession. #coreToolsOnly }.
		{ #GbsClassicLauncher. #class. #queryOrganizerMethodsFor:mode:inSession:. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #browseNamedObjectCacheReport. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #browseTypedWrapperAutoloadReport. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #browseTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #browseStaleTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #browseSessionStateReport. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #browsePromptedSessionStateKeysReport. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #browseObjectsInMemoryReport. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #refreshAllTypedWrappers. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #refreshStaleTypedWrappers. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #inspectPromptedSessionStateKey. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #inspectSessionStateAtKey:. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #clearNamedObjectCache. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #menuSession. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #oopForInspectableObject:. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #parseSessionStateKeysFrom:. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #requestPositiveInteger:initialAnswer:. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #inspectCurrentUserGlobals. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #currentUserGlobalsOopIn:. #coreToolsOnly }.
		{ #GbsClassicLauncher. #instance. #inspectOop:session:. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #browseNamedObjectCacheReport. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #browseTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #browseStaleTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #browsePromptedSessionStateKey. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #browsePromptedSessionStateKeysReport. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #browseObjectsInMemoryReport. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #browseSessionStateAtKey:. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #browseTypedWrapperAutoloadReport. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #clearNamedObjectCache. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #menuSession. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #parseSessionStateKeysFrom:. #coreToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #requestPositiveInteger:initialAnswer:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #browsePromptedSessionStateKey. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #browseTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #browseStaleTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #browseSessionStateAtKey:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #browsePromptedSessionStateKeysReport. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #browseObjectsInMemoryReport. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #buildMenuBar. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #gsBrowseReferencesToSelectedClass. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #methodMenu. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #selectedServerReferenceTargetName. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #requestInput:initialAnswer:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #uiChooseFrom:title:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #parseSessionStateKeysFrom:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #requestPositiveInteger:initialAnswer:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #sessionMenu. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #serverClassReferenceStrings. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #serverMethodReferencesFor:hierarchyOnly:senders:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #currentReceiverProxyForServerMethod. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #directStepOverExecutedFrame:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #directStepWithPrimarySelector:fallbackSelector:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #fetchContextsDirectly. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #applyFetchedContexts:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #fetchFullSourceFor:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #fetchStackFrames. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #forceServerJumpToStepPoint1. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #inform:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #inspectOop:session:. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #invokeSelectedServerMethod. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #remoteDebugProcess. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #resolveDebugProcessOopFromCurrentProcessOop. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #resolveExecutedFrameLevelFromServer. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #restartUsingDirectTrimFromExecutedFrame. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #returnFromFrame. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #runToCaret. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #selectedStepPointFromCaret. #coreToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #stepReturn. #coreToolsOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #constantEntries. #coreOnly }.
		{ #GbsRemoteMethodMirror. #instance. #asMethodObject. #coreOnly }.
		{ #GbsRemoteMethodMirror. #instance. #asUnboundMethodObject. #coreOnly }.
		{ #GbsRemoteClassMirror. #instance. #methodObjectAt:. #coreOnly }.
		{ #GbsRemoteClassMirror. #instance. #classMethodObjectAt:. #coreOnly }.
		{ #GbsNamespaceScopedMethodQuery. #instance. #methodObjectForReference:. #coreOnly }.
		{ #GbsNamespaceScopedMethodQuery. #instance. #methodObjects. #coreOnly }.
		{ #GbsBrowser. #instance. #browseNamedObjectCacheReport. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #browsePromptedSessionStateKey. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #browsePromptedSessionStateKeysReport. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #browseSessionStateAtKey:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #browseTypedWrapperAutoloadReport. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #browseTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #browseStaleTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #browseObjectsInMemoryReport. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #browseClassInfo. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #browseMethodInfo. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #browseVersions. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #classSelected:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #classInfoTextForMirror:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #gsInspectIt. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #inspectAllInstances. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #inspectClass. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #inspectDictionary. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #inspectMethod. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #invokeSelectedMethod. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #loadDictionaries. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #menuClass. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #menuMethod. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #methodSelected:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #openMethodObject:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #protocolSelected:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #classSideSelected. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #infoValueForDisplay:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #inform:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #inspectOop:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #methodInfoTextForMirror:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #selectedClassMirror. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #selectedMethodMirror. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #selectedMethodMirrorForSelector:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #selectedMethodObject. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #selectedMethodObjectForSelector:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #selectedUnboundMethodObject. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #selectedUnboundMethodObjectForSelector:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #versionSummaryCurrent:total:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #queryServerMethodsForSelector:mode:rootClassName:hierarchyScope:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #refreshAllTypedWrappers. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #refreshStaleTypedWrappers. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #clearNamedObjectCache. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #menuSession. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #parseSessionStateKeysFrom:. #coreToolsOnly }.
		{ #GbsBrowser. #instance. #requestPositiveInteger:initialAnswer:. #coreToolsOnly }.
		{ #GbsInspector. #instance. #browsePromptedSessionStateKey. #coreToolsOnly }.
		{ #GbsInspector. #instance. #browsePromptedSessionStateKeysReport. #coreToolsOnly }.
		{ #GbsInspector. #instance. #browseSessionStateAtKey:. #coreToolsOnly }.
		{ #GbsInspector. #instance. #browseStaleTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsInspector. #instance. #browseObjectsInMemoryReport. #coreToolsOnly }.
		{ #GbsInspector. #instance. #browseTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsInspector. #instance. #browseReportChooser. #coreToolsOnly }.
		{ #GbsInspector. #instance. #parseSessionStateKeysFrom:. #coreToolsOnly }.
		{ #GbsInspector. #instance. #requestPositiveInteger:initialAnswer:. #coreToolsOnly }.
		{ #GbsInspector. #instance. #withShallowMaterializationDo:. #coreToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #browsePromptedSessionStateKey. #coreToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #browsePromptedSessionStateKeysReport. #coreToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #browseSessionStateAtKey:. #coreToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #browseStaleTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #browseObjectsInMemoryReport. #coreToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #browseTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #menuEntry. #coreToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #menuEntryPopup. #coreToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #parseSessionStateKeysFrom:. #coreToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #requestPositiveInteger:initialAnswer:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #inspectDictionary. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #browseReferencersForSelectedEntry. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #browseReferencersForSelectedPreviewValue. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #browseReferencersForStructuredPreviewRow:entryKey:path:previewKind:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #browsePromptedSessionStateKey. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #browsePromptedSessionStateKeysReport. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #browseSessionStateAtKey:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #browseStaleTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #browseObjectsInMemoryReport. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #browseReferencersForEntryKey:path:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #browseTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #menuEntry. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #menuPreview. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #openStructuredInspectorForPreview:title:entryKey:path:previewKind:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #refreshDictionariesFor:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #refreshEntriesForDictionary:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #refreshUsers. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #chooseReferencerFrom:title:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #displayStringForReferencer:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #structuredPreviewForEntryKey:path:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #oopForEntryKey:path:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #oopScriptForUser:dictionary:keyName:path:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #inform:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #oopForInspectableObject:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #openInspectorOnOop:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #requestInput:initialAnswer:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #parseSessionStateKeysFrom:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #requestPositiveInteger:initialAnswer:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #referencersInMemoryForOop:. #coreToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #withShallowMaterializationDo:. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #canExecuteOnDebugProcess. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #currentFrameOop. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #currentProcessOop. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #currentReceiverOop. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #cutbackGsTo:. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #isTerminated. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #oopForVariableNamed:. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #recomputeContextList. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #resetServerPCToStepOne. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #restartLevelFromServerStack. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #runDebugProcessCommand:recompute:. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #updateCurrentContextFromContexts:. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #updateContextListFromServerContexts:. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #runDebugProcessCommand:withInteger:recompute:. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #remoteDebugProcess. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #serverStepOverFrameLevel:. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #synchronizeServerProgramCounterAfterRestart. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #compatibilityCompileLookup. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #compatibilityCompileResponseForSource:correctingSelector:. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #compatibilityCorrectedCompileResponseForSource:. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #compatibilityRecompileResponseForSource:. #coreToolsOnly }.
		{ #GbxDebuggerService. #instance. #basicReenterServerContext. #toolsOnly }.
		{ #GbxContextListPolicy. #instance. #buildContextListFromServerContexts:. #coreToolsOnly }.
		{ #GbxContextListPolicy. #instance. #updateContextListFromServerContexts:. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #buildToolbar. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #browseObjectsInMemoryReport. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #browsePromptedSessionStateKey. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #browsePromptedSessionStateKeysReport. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #browseReferencersInMemory. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #browseReportChooser. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #browseSessionStateAtKey:. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #browseStaleTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #browseTypedWrapperLifecycleReport. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #chooseReferencerFrom:title:. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #displayStringForReferencer:. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #inform:. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #inspectSelected. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #oopForInspectableObject:. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #openTrippyOnOop:. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #parseSessionStateKeysFrom:. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #referencersInMemoryForOop:. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #requestPositiveInteger:initialAnswer:. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #requestString:initialAnswer:. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #selectedInspectableOop. #coreToolsOnly }.
		{ #GbxTrippy. #instance. #withShallowMaterializationDo:. #coreToolsOnly }.
		{ #GbsSession. #instance. #objectLog. #maglevOnly }.
		{ #GbsSession. #instance. #sessionMethods. #maglevOnly }.
		{ #GbsSession. #instance. #materializeMaglevRuntimeValue:. #maglevOnly }.
		{ #GbsSession. #instance. #gsDictionaryForOop:. #maglevOnly }.
		{ #GbsSession. #instance. #gsObjectForOop:. #maglevOnly }.
		{ #GbsSession. #instance. #rcCounterForOop:. #maglevOnly }.
		{ #GbsSession. #instance. #rcHashForOop:. #maglevOnly }.
		{ #GbsSession. #instance. #rcQueueForOop:. #maglevOnly }.
		{ #GbsSession. #instance. #rubyRuntime. #maglevOnly }.
		{ #GbsSmalltalkFacade. #instance. #objectLog. #maglevOnly }.
		{ #GbsObjectSpaceFacade. #instance. #maglevFinalizerRegistry. #maglevOnly }.
		{ #GbsObjectSpaceDiagnosticsFacade. #instance. #maglevFinalizerRegistry. #maglevOnly }.
		{ #GbsObjectSpaceDiagnosticsFacade. #instance. #finalizerRegistryReport. #maglevOnly }.
		{ #GbsObjectSpaceDiagnosticsFacade. #instance. #finalizerRegistrySlot. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #autoloadMirrors. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #autoloadEntries. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #autoloadFileFor:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #loadFileNamed:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #loadedFeatures. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #loadPath. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #persistentLoadedFeatures. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #registerAutoload:file:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #removeAutoload:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #requireFileNamed:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #retryAutoload:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #supportsAutoload. #maglevOnly }.
		{ #GbsRemoteConstantMirror. #instance. #autoloadFile. #maglevOnly }.
		{ #GbsRemoteConstantMirror. #instance. #isAutoload. #maglevOnly }.
		{ #GbsPlaygroundActions. #class. #gsBrowseRubyLoadPathReportIn:. #maglevToolsOnly }.
		{ #GbsPlaygroundActions. #class. #gsBrowseRubyLoadedFeaturesReportIn:. #maglevToolsOnly }.
		{ #GbsPlaygroundActions. #class. #gsBrowseRubyPersistentLoadedFeaturesReportIn:. #maglevToolsOnly }.
		{ #GbsPlaygroundActions. #class. #gsBrowseTopLevelAutoloadRegistrationsReportIn:. #maglevToolsOnly }.
		{ #GbsPlaygroundActions. #class. #gsBrowseMaglevFinalizerRegistryReportIn:. #maglevToolsOnly }.
		{ #GbsBrowser. #instance. #addExtensionSessionMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsBrowser. #instance. #browseRubyLoadPathReport. #maglevToolsOnly }.
		{ #GbsClassicLauncher. #instance. #addExtensionSessionMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsInspector. #instance. #addExtensionReportOptionsToLabels:actions:. #maglevToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #addExtensionSessionMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #addExtensionMethodMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #addExtensionSessionMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #browseRubyLoadPathReport. #maglevToolsOnly }.
		{ #GbsWorkspace. #instance. #addExtensionWorkspaceMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsWorkspace. #instance. #browseObjectLogReport. #maglevToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #addExtensionEntryMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #addExtensionEntryMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #addExtensionPreviewMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #configureExtensionStructuredInspector:. #maglevToolsOnly }.
		{ #GbxDebuggerService. #instance. #browseRemoteSelectedMethod. #maglevToolsOnly }.
		{ #GbxDebuggerService. #instance. #selectedMethodProtocol. #maglevToolsOnly }.
		{ #GbxDebuggerService. #instance. #selectedRemoteMethodLookup. #maglevToolsOnly }.
		{ #GbxDebuggerService. #instance. #selectedRemoteMethodMirror. #maglevToolsOnly }.
		{ #GbxDebuggerService. #instance. #selectedRemoteMethodObject. #maglevToolsOnly }.
		{ #GbxDebuggerService. #instance. #selectedRemoteUnboundMethodObject. #maglevToolsOnly }.
		{ #GbxTrippy. #instance. #addExtensionReportOptionsToLabels:actions:. #maglevToolsOnly } }
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> packageRequirementSpecs [
	^ {
		{ 'GemStone-GBS-Converted'. #() }.
		{ 'GemStone-GBS-Core'. #('GemStone-GBS-Converted') }.
		{ 'GemStone-GBS-Tools'. #('GemStone-GBS-Converted') }.
		{ 'GemStone-GBS-Core-Tools'. #('GemStone-GBS-Core' 'GemStone-GBS-Tools') }.
		{ 'GemStone-GBS-MagLev'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core') }.
		{ 'GemStone-GBS-MagLev-Tools'. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev') }.
		{ 'GemStone-Pharo-Core-Tests'. #('GemStone-GBS-Converted' 'GemStone-GBS-Core' 'GemStone-GBS-Tools' 'GemStone-GBS-Core-Tools') }.
		{ 'GemStone-Pharo-MagLev-Tests'. #('GemStone-Pharo-Tests' 'GemStone-Pharo-Core-Tests' 'GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'GemStone-Pharo-Tests'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools') } }
]

{ #category : 'contracts' }
GemStonePharoPackageContract >> groupDescriptionSpecs [
	^ Dictionary newFromPairs: {
		'Original'. 'original/base production packages only'.
		'Original-Tests'. 'original/base production packages plus the original/base test layer'.
		'Core-Only'. 'strict converted-core load for boundary checks'.
		'Core'. 'Smalltalk core bridge only'.
		'Core-Tools'. 'Smalltalk core plus the original Pharo tools and the generic core-tools overlay'.
		'Core-Tests'. 'Smalltalk core, generic tool overlays, and the core-only test suite'.
		'MagLev-Core'. 'optional MagLev runtime without MagLev-specific tools'.
		'MagLev-Tools'. 'optional MagLev runtime plus MagLev-specific tool integration'.
		'MagLev'. 'production MagLev runtime without debugger/tool UI packages'.
		'Tools'. 'convenience alias for the generic tools-capable load'.
		'All-Tests'. 'all active core and MagLev-aware test packages'.
		'Tests'. 'convenience alias for all active core and MagLev-aware test packages'.
		'Full'. 'full developer load'.
		'default'. 'alias for `Full`' }
]
