Class {
	#name : 'GemStonePharoVerificationContract',
	#superclass : 'Object',
	#instVars : [
		'contract'
	],
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'instance creation' }
GemStonePharoVerificationContract class >> on: aContract [
	^ self new
		contract: aContract;
		yourself
]

{ #category : 'accessing' }
GemStonePharoVerificationContract >> contract [
	^ contract
]

{ #category : 'accessing' }
GemStonePharoVerificationContract >> contract: aContract [
	contract := aContract
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> regressionLaneSpecNamed: aString [
	^ self regressionLaneSpecs
		detect: [ :each | each first = aString ]
		ifNone: [ self regressionLaneSpecs first ]
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> regressionLaneSpecs [
	^ {
		{ 'all'. 'BRIDGE_REGRESSION'. #all. false }.
		{ 'unit'. 'BRIDGE_UNIT_REGRESSION'. #excludeIntegration. false }.
		{ 'live'. 'BRIDGE_LIVE_REGRESSION'. #onlyIntegration. true } }
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> livePreflightCodeSpecs [
	^ {
		{ 'LIVE_PREFLIGHT_OK'. 'Both Topaz and GCI probes succeeded.' }.
		{ 'LIVE_PREFLIGHT_SKIPPED'. 'The live lane was skipped because login credentials were not supplied.' }.
		{ 'LIVE_PREFLIGHT_AUTH_FAILED'. 'Topaz login failed due to invalid credentials.' }.
		{ 'LIVE_PREFLIGHT_ROUTE_FAILED'. 'Topaz could not route through the configured host/netldi combination.' }.
		{ 'LIVE_PREFLIGHT_STONE_NOT_FOUND'. 'The target stone was not visible through the configured route.' }.
		{ 'LIVE_PREFLIGHT_TOPAZ_LOGIN_FAILED'. 'Topaz login failed for a non-routing, non-auth reason.' }.
		{ 'LIVE_PREFLIGHT_GCI_AUTH_FAILED'. 'The Pharo GCI login failed due to invalid credentials.' }.
		{ 'LIVE_PREFLIGHT_GCI_ROUTE_FAILED'. 'The Pharo GCI login could not route through the configured host/netldi combination.' }.
		{ 'LIVE_PREFLIGHT_GCI_STONE_NOT_FOUND'. 'The Pharo GCI login could not find the target stone.' }.
		{ 'LIVE_PREFLIGHT_GCI_LOGIN_FAILED'. 'The Pharo GCI login failed for a non-routing, non-auth reason.' } }
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> livePreflightEnvironmentVariableSpecs [
	^ {
		{ 'GS_USER'. 'GemStone login user used by both the Topaz and GCI probes.' }.
		{ 'GS_PASS'. 'GemStone login password used by both the Topaz and GCI probes.' }.
		{ 'GS_STONE'. 'Optional stone name override. Defaults to `gs64stone`.' }.
		{ 'GS_SERVICE'. 'Optional service name override. Defaults to `gemnetobject`.' }.
		{ 'GS_NETLDI_HOST'. 'Optional explicit host for netldi routing.' }.
		{ 'GS_NETLDI_NAME_OR_PORT'. 'Optional explicit netldi name or port, for example `gs64ldi` or `50377`.' }.
		{ 'GEMSTONE'. 'Optional explicit GemStone client home used by the GCI probe.' } }
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> reloadCheckModeSpecs [
	^ {
		{ 'default'. 'Run the steady-state reload proof, including no-compatibility checks after the requested load group is loaded.' }.
		{ 'core-only'. 'Run the core-only package/class/selector proof after loading `Core-Tests`, plus the no-compatibility image proof.' } }
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> reloadEnvironmentVariableSpecs [
	^ {
		{ 'GBS_LOAD_GROUP'. 'Metacello load group to reload before post-load checks run. Defaults to `default`.' }.
		{ 'GBS_RELOAD_CHECK_MODE'. 'Reload proof mode. Defaults to `default` and supports `core-only`.' }.
		{ 'GBS_VERIFY_LANE'. 'Optional verification lane to run in the same Smalltalk process after the reload proof. Supports `core-only`, `original`, `original-tests`, and `full`.' }.
		{ 'GBS_GENERATE_CONTRACT_ARTIFACTS'. 'When `1`, regenerate the contract-driven documentation after reload.' }.
		{ 'GBS_VERIFY_CONTRACT_ARTIFACTS'. 'When `1`, verify that the contract-driven documentation is already fresh.' } }
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> livePreflightStepSpecs [
	^ {
		{ 'stone-status'. 'Inspect the local stone and netldi state with `gslist -lcv` when available.' }.
		{ 'topaz-login'. 'Attempt a Topaz login using the configured stone, service, host, and netldi route.' }.
		{ 'gci-login'. 'Attempt a direct GCI login from Pharo using the same route and client library.' }.
		{ 'summary'. 'Emit `LIVE_PREFLIGHT_SUMMARY` and optional JSON with the final classification.' } }
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> verificationLaneSpecs [
	^ {
		{ 'core-only'. 'Verify the Smalltalk core without optional MagLev production packages and without deleted legacy surface.'. 'Core-Tests'. #('GemStone-Pharo-Core-Tests'). #('ARCHITECTURE_BOUNDARY_OK' 'PACKAGE_OWNERSHIP_DRIFT_OK' 'NO_COMPAT_SOURCE_SCAN_OK' 'NO_COMPATIBILITY_PROOF_OK' 'BRIDGE_UNIT_REGRESSION_OK' 'BRIDGE_CORE_ONLY_CHECK_OK') }.
		{ 'bootstrap-smoke'. 'Prove that a clean image can micro-bootstrap the helper package and load the requested group before post-load checks run.'. 'Core-Tests'. #('GemStonePharoReloadBootstrapper' 'GemStonePharoReloadRunner' 'GemStone-Pharo-Core-Tests'). #('CORE_ONLY_CLEAN_RELOAD_DONE' 'BOOTSTRAP_SMOKE_OK' 'BOOTSTRAP_SMOKE_DONE') }.
		{ 'original'. 'Verify that the original/base production layer reloads cleanly without the generic Core or optional MagLev overlays.'. 'Original'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools'). #('ARCHITECTURE_BOUNDARY_OK' 'PACKAGE_OWNERSHIP_DRIFT_SKIPPED' 'NO_COMPAT_SOURCE_SCAN_OK' 'NO_COMPATIBILITY_PROOF_OK' 'ORIGINAL_CHECK_OK') }.
		{ 'original-drift'. 'Verify that the original/base production layer stays clean relative to `56b6db3...`, allowing only the explicit accepted test-layer exceptions.'. 'Original-Tests'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools' 'GemStone-Pharo-Tests'). #('ORIGINAL_LAYER_DRIFT_EXPECTED_ONLY') }.
		{ 'original-tests'. 'Verify the original/base production and original/base test layer without the generic Core or optional MagLev overlays. This lane proves the base unit layer only.'. 'Original-Tests'. #('GemStone-Pharo-Tests'). #('ARCHITECTURE_BOUNDARY_OK' 'NO_COMPAT_SOURCE_SCAN_OK' 'NO_COMPATIBILITY_PROOF_OK' 'BRIDGE_UNIT_REGRESSION_OK' 'ORIGINAL_TESTS_CHECK_OK') }.
		{ 'full'. 'Verify the steady-state developer load plus the live GemStone lane.'. 'Full'. #('GemStone-Pharo-Core-Tests' 'GemStone-Pharo-MagLev-Tests' 'GemStone-Pharo-Tests'). #('ARCHITECTURE_BOUNDARY_OK' 'PACKAGE_OWNERSHIP_DRIFT_OK' 'NO_COMPAT_SOURCE_SCAN_OK' 'NO_COMPATIBILITY_PROOF_OK' 'BRIDGE_UNIT_REGRESSION_OK' 'BRIDGE_LIVE_REGRESSION_OK' 'CLEAN_RELOAD_AND_REGRESSION_RUN_DONE') }.
		{ 'artifact-freshness'. 'Verify that the generated contract artifacts and marker-managed doc sections are already up to date.'. 'default'. #('README.md' 'doc/ARCHITECTURE.md' 'doc/GemStone-Pharo-Bridge-User-Manual.html' 'doc/LOAD-MATRIX.md' 'doc/PACKAGE-GRAPH.md' 'doc/PACKAGE-GRAPH.dot' 'doc/PACKAGE-GRAPH.svg' 'doc/LIVE-PREFLIGHT-POLICY.md' 'doc/RELOAD-POLICY.md' 'doc/TESTING.md' 'doc/USER-MANUAL-REFERENCE.html' 'doc/OWNERSHIP-CONTRACT.md' 'doc/VERIFICATION-LANES.md'). #('NO_COMPAT_SOURCE_SCAN_OK' 'CONTRACT_ARTIFACTS_FRESH_OK') }.
		{ 'verify'. 'Run core-only, bootstrap-smoke, original, original-drift, original-tests, full, artifact-freshness, then the summary-renderer smoke check.'. 'composite'. #('core-only' 'bootstrap-smoke' 'original' 'original-drift' 'original-tests' 'full' 'artifact-freshness' 'summary-renderer'). #('All lane success markers above') } }
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> originalLayerExpectedExceptionSpecs [
	^ {
		{ 'src/GemStone-Pharo-Tests/GciError.extension.st'. 'Adds a tiny test-only GciError number accessor shim so the restored base login-error path can run without production drift.' }.
		{ 'src/GemStone-Pharo-Tests/MockGbsSession.class.st'. 'Keeps only a narrow interpretLoginError override so the restored base GbsSession production file stays clean.' } }
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> boundaryGuardSpecs [
	^ {
		{ 'ARCHITECTURE_BOUNDARY_OK'. 'Package graph, load-group membership, and forbidden reverse dependencies match the contract.' }.
		{ 'PACKAGE_OWNERSHIP_DRIFT_OK'. 'Representative class, selector, and split-behavior ownership stay in their allowed packages.' }.
		{ 'NO_COMPAT_SOURCE_SCAN_OK'. 'Deleted legacy surface is absent from the active source roots, scripts, and selected docs.' }.
		{ 'NO_COMPATIBILITY_PROOF_OK'. 'Deleted package, class, selector, and method-package ownership surface is absent from the loaded image.' } }
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> loadMatrixMarkerFor: aBoolean [
	^ aBoolean
		ifTrue: [ 'yes' ]
		ifFalse: [ 'no' ]
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> productionPackageSummarySpecs [
	^ {
		{ 'GemStone-GBS-Converted'. 'Legacy bridge/session base plus the remaining generic mirrors, repository access, and support code that still lives in the original package.' }.
		{ 'GemStone-GBS-Core'. 'Generic overlay package for Smalltalk-facing bridge facades and session/manager extensions that can load on top of the original Converted package.' }.
		{ 'GemStone-GBS-Tools'. 'The original generic Pharo developer tools and presenters package; do not include from runtime-only load groups unless tool UI is intentional.' }.
		{ 'GemStone-GBS-Core-Tools'. 'Generic developer tool/report overlay package that adds non-MagLev playground and presenter extensions without changing the original Tools package.' }.
		{ 'GemStone-GBS-MagLev'. 'Optional MagLev/Ruby runtime surface: runtime loading, autoload, proc/binding support, ObjectLog, RC wrappers, and MagLev facades.' }.
		{ 'GemStone-GBS-MagLev-Tools'. 'Optional MagLev/Ruby developer tool integration for browsers, workspaces, debuggers, ObjectLog access, and inspectors.' } }
]

{ #category : 'contracts' }
GemStonePharoVerificationContract >> testPackageSummarySpecs [
	^ {
		{ 'GemStone-Pharo-Core-Tests'. 'Smalltalk-core-only tests.' }.
		{ 'GemStone-Pharo-MagLev-Tests'. 'MagLev-only overlay tests that depend on the optional runtime and tool packages.' }.
		{ 'GemStone-Pharo-Tests'. 'Active full bridge tests, including MagLev-aware behavior.' } }
]
