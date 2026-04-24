Class {
	#name : 'GemStonePharoReloadGuardsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'private' }
GemStonePharoReloadGuardsTest >> collectLogLinesDuring: aBlock [
	| lines |
	lines := OrderedCollection new.
	aBlock value: [ :line | lines add: line ].
	^ lines
]

{ #category : 'private' }
GemStonePharoReloadGuardsTest >> guards [
	^ GemStonePharoReloadGuards new
]

{ #category : 'private' }
GemStonePharoReloadGuardsTest >> helperSelectorForCoreOnlyCheck [
	^ 1
]

{ #category : 'private' }
GemStonePharoReloadGuardsTest >> helperSelectorForPackageOwnershipCheck [
	^ 2
]

{ #category : 'private' }
GemStonePharoReloadGuardsTest >> legacyRootAliasSymbol [
	^ ('persistent', 'Root') asSymbol
]

{ #category : 'private' }
GemStonePharoReloadGuardsTest >> newContract [
	^ GemStonePharoReloadGuardsTestContract new
]

{ #category : 'tests' }
GemStonePharoReloadGuardsTest >> testCheckArchitectureFailsWhenLoadGroupMissesExpectedPackage [
	| contract lines |
	contract := self newContract.
	contract
		packageRequirementSpecs: {
			{ 'PkgA'. #() }.
			{ 'PkgB'. #('PkgA') } };
		groupMemberSpecs: {
			{ 'default'. #('PkgB') } };
		forbiddenPackageRequirementSpecs: #().

	lines := self collectLogLinesDuring: [ :logBlock |
		self
			deny: (self guards
				checkArchitectureFor: contract
				loadGroup: 'default'
				loadedPackages: #('PkgA') asSet
				log: logBlock) ].

	self
		assert: (lines anySatisfy: [ :each |
			each includesSubstring: 'ARCHITECTURE_BOUNDARY_FAIL load group default missing #(''PkgB'')' ]).
	self assert: lines last equals: 'ARCHITECTURE_BOUNDARY_FAILED'
]

{ #category : 'tests' }
GemStonePharoReloadGuardsTest >> testCheckCoreOnlyPassesForExpectedPackageClassAndSelector [
	| contract lines className |
	contract := self newContract.
	className := self class name asString.
	contract
		coreOnlyPackageChecks: {
			{ 'PkgA'. true }.
			{ 'PkgB'. false } };
		coreOnlyClassChecks: {
			{ self class name asSymbol. true } };
		coreOnlySelectorChecks: {
			{ self class name asSymbol. #instance. #helperSelectorForCoreOnlyCheck. true }.
			{ self class name asSymbol. #instance. self legacyRootAliasSymbol. false } }.

	lines := self collectLogLinesDuring: [ :logBlock |
		self
			assert: (self guards
				checkCoreOnlyFor: contract
				workingCopyNamed: [ :packageName |
					packageName = 'PkgA'
						ifTrue: [ Object new ]
						ifFalse: [ nil ] ]
				log: logBlock) ].

	self assert: (lines includes: 'CORE_ONLY_CHECK_OK package PkgA').
	self assert: (lines includes: 'CORE_ONLY_CHECK_OK class ', className).
	self assert: lines last equals: 'CORE_ONLY_CLEAN_RELOAD_DONE'
]

{ #category : 'tests' }
GemStonePharoReloadGuardsTest >> testCheckNoCompatibilityFailsWhenDeletedPackageStillLoaded [
	| contract lines |
	contract := self newContract.
	contract
		noCompatibilityPackageNames: #('PkgCompat');
		noCompatibilityClassNames: #();
		noCompatibilitySelectorChecks: #();
		noCompatibilityMethodPackageNames: #().

	lines := self collectLogLinesDuring: [ :logBlock |
		self
			deny: (self guards
				checkNoCompatibilityFor: contract
				loadedPackages: #('PkgCompat') asSet
				log: logBlock) ].

	self assert: (lines includes: 'NO_COMPATIBILITY_PROOF_FAIL loaded package PkgCompat').
	self assert: lines last equals: 'NO_COMPATIBILITY_PROOF_FAILED'
]

{ #category : 'tests' }
GemStonePharoReloadGuardsTest >> testCheckNoCompatibilitySourceFailsWhenDeletedSnippetAppearsInProductionSourceTree [
	| contract lines repoRoot sourceFile |
	contract := self newContract.
	repoRoot := FileSystem memory root / 'repo'.
	sourceFile := repoRoot / 'src/GemStone-GBS-Converted/GbsSession.class.st'.
	sourceFile parent ensureCreateDirectory.
	sourceFile writeStreamDo: [ :stream |
		stream nextPutAll: 'GbsSession >> persistentRoot [' ].
	contract
		noCompatibilitySourceScanRoots: #('src/GemStone-GBS-Converted');
		noCompatibilitySourceScanSnippets: #('GbsSession >> persistentRoot [').

	lines := self collectLogLinesDuring: [ :logBlock |
		self
			deny: (self guards
				checkNoCompatibilitySourceFor: contract
				repoRoot: repoRoot
				log: logBlock) ].

	self assert: (lines anySatisfy: [ :each | each includesSubstring: 'NO_COMPAT_SOURCE_SCAN_FAIL' ]).
	self assert: lines last equals: 'NO_COMPAT_SOURCE_SCAN_FAILED'
]

{ #category : 'tests' }
GemStonePharoReloadGuardsTest >> testCheckNoCompatibilitySourceFailsWhenDeletedSnippetAppearsInSecondarySourceFile [
	| contract lines repoRoot sourceFile |
	contract := self newContract.
	repoRoot := FileSystem memory root / 'repo'.
	sourceFile := repoRoot / 'scripts/run_verify.sh'.
	sourceFile parent ensureCreateDirectory.
	sourceFile writeStreamDo: [ :stream |
		stream nextPutAll: 'echo persistentRoot' ].
	contract
		noCompatibilitySourceScanRoots: #();
		noCompatibilitySourceScanSnippets: #();
		noCompatibilitySecondarySourceScanFiles: #('scripts/run_verify.sh');
		noCompatibilitySecondarySourceScanSnippets: #('persistentRoot').

	lines := self collectLogLinesDuring: [ :logBlock |
		self
			deny: (self guards
				checkNoCompatibilitySourceFor: contract
				repoRoot: repoRoot
				log: logBlock) ].

	self assert: (lines anySatisfy: [ :each | each includesSubstring: 'NO_COMPAT_SOURCE_SCAN_FAIL' ]).
	self assert: lines last equals: 'NO_COMPAT_SOURCE_SCAN_FAILED'
]

{ #category : 'tests' }
GemStonePharoReloadGuardsTest >> testCheckNoCompatibilitySourcePassesWhenProductionSourceTreeIsClean [
	| contract lines repoRoot sourceFile |
	contract := self newContract.
	repoRoot := FileSystem memory root / 'repo'.
	sourceFile := repoRoot / 'src/GemStone-GBS-Converted/GbsSession.class.st'.
	sourceFile parent ensureCreateDirectory.
	sourceFile writeStreamDo: [ :stream |
		stream nextPutAll: 'GbsSession >> bridgeRoot [' ].
	contract
		noCompatibilitySourceScanRoots: #('src/GemStone-GBS-Converted');
		noCompatibilitySourceScanSnippets: #('GbsSession >> persistentRoot [').

	lines := self collectLogLinesDuring: [ :logBlock |
		self
			assert: (self guards
				checkNoCompatibilitySourceFor: contract
				repoRoot: repoRoot
				log: logBlock) ].

	self assert: (lines includes: 'NO_COMPAT_SOURCE_SCAN_OK root src/GemStone-GBS-Converted').
	self assert: lines last equals: 'NO_COMPAT_SOURCE_SCAN_OK'
]

{ #category : 'tests' }
GemStonePharoReloadGuardsTest >> testCheckNoCompatibilityPassesWhenSelectorsPackagesAndClassesAreAbsent [
	| contract lines |
	contract := self newContract.
	contract
		noCompatibilityPackageNames: #('PkgCompat');
		noCompatibilityClassNames: #(ImaginaryCompatibilityClass);
		noCompatibilitySelectorChecks: {
			{ self class name asSymbol. #instance. self legacyRootAliasSymbol } };
		noCompatibilityMethodPackageNames: #('PkgCompat').

	lines := self collectLogLinesDuring: [ :logBlock |
		self
			assert: (self guards
				checkNoCompatibilityFor: contract
				loadedPackages: #('GemStone-Pharo-Core-Tests') asSet
				log: logBlock) ].

	self assert: (lines includes: 'NO_COMPATIBILITY_PROOF_OK package PkgCompat absent').
	self assert: (lines includes: 'NO_COMPATIBILITY_PROOF_OK class ImaginaryCompatibilityClass absent').
	self assert: (lines anySatisfy: [ :each | each includesSubstring: 'NO_COMPATIBILITY_PROOF_OK selector ' ]).
	self assert: (lines includes: 'NO_COMPATIBILITY_PROOF_OK no methods in package PkgCompat').
	self assert: lines last equals: 'NO_COMPATIBILITY_PROOF_OK'
]

{ #category : 'tests' }
GemStonePharoReloadGuardsTest >> testCheckPackageOwnershipPassesForClassSelectorAndBehaviorFamily [
	| contract lines className |
	contract := self newContract.
	className := self class name asString.
	contract
		packageOwnershipClassSpecs: {
			{ self class name asSymbol. 'GemStone-Pharo-Core-Tests' } };
		packageOwnershipSelectorSpecs: {
			{ self class name asSymbol. #instance. #helperSelectorForPackageOwnershipCheck. 'GemStone-Pharo-Core-Tests' } };
		packageOwnershipBehaviorSpecs: {
			{ self class name asSymbol. #instance. #('GemStone-Pharo-Core-Tests') } };
		packageOwnershipCorePackages: #();
		packageOwnershipForbiddenCoreClassPatterns: #();
		packageOwnershipForbiddenCoreSelectorPatterns: #().

	lines := self collectLogLinesDuring: [ :logBlock |
		self
			assert: (self guards
				checkPackageOwnershipFor: contract
				loadedPackages: #('GemStone-Pharo-Core-Tests') asSet
				log: logBlock) ].

	self
		assert: (lines includes: 'PACKAGE_OWNERSHIP_DRIFT_OK class ', className, ' in GemStone-Pharo-Core-Tests').
	self
		assert: (lines includes: 'PACKAGE_OWNERSHIP_DRIFT_OK selector ', className,
			'>>#helperSelectorForPackageOwnershipCheck in GemStone-Pharo-Core-Tests').
	self assert: lines last equals: 'PACKAGE_OWNERSHIP_DRIFT_OK'
]

{ #category : 'tests' }
GemStonePharoReloadGuardsTest >> testGenerateContractArtifactsReplacesStaleContentsAndFreshnessPasses [
	| contract lines repoRoot staleFile markedFile |
	contract := self newContract.
	contract generatedContractArtifactSpecs: {
		{ 'doc/example.md'. 'fresh' } }.
	contract generatedDocumentationSectionSpecs: {
		{ 'README.md'. '<!-- BEGIN GENERATED:TEST -->'. '<!-- END GENERATED:TEST -->'. 'fresh doc section' } }.
	repoRoot := FileSystem memory root / 'contract-artifacts'.
	repoRoot ensureCreateDirectory.
	(repoRoot / 'doc') ensureCreateDirectory.
	staleFile := repoRoot / 'doc/example.md'.
	staleFile writeStreamDo: [ :stream |
		stream nextPutAll: 'fresh'; nextPutAll: ' stale tail' ].
	markedFile := repoRoot / 'README.md'.
	markedFile writeStreamDo: [ :stream |
		stream
			nextPutAll: 'prefix'; cr;
			nextPutAll: '<!-- BEGIN GENERATED:TEST -->'; cr;
			nextPutAll: 'stale'; cr;
			nextPutAll: '<!-- END GENERATED:TEST -->'; cr;
			nextPutAll: 'suffix' ].

	lines := self collectLogLinesDuring: [ :logBlock |
		self assert: (self guards generateContractArtifactsFor: contract repoRoot: repoRoot log: logBlock).
		self assert: (self guards verifyContractArtifactFreshnessFor: contract repoRoot: repoRoot log: logBlock) ].

	self assert: staleFile contents equals: 'fresh'.
	self assert: (markedFile contents includesSubstring: 'fresh doc section').
	self assert: (lines includes: 'GENERATED_CONTRACT_ARTIFACTS_OK').
	self assert: (lines includes: 'GENERATED_DOC_SECTION_OK README.md').
	self assert: (lines includes: 'CONTRACT_ARTIFACT_FRESH_OK doc/example.md').
	self assert: (lines anySatisfy: [ :each | each includesSubstring: 'CONTRACT_ARTIFACT_FRESH_OK README.md section <!-- BEGIN GENERATED:TEST -->' ]).
	self assert: lines last equals: 'CONTRACT_ARTIFACTS_FRESH_OK'
]
