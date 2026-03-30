Class {
	#name : 'GbxOverrideToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'private' }
GbxOverrideToolsTest >> clearTestOverrideMetadata [
	#(
		'GemStone-Pharo-Tests'
		'GbxOverrideDiscoveryPackage'
		'GbxOverrideReleasePackage'
	) do: [ :each |
		GbxOverrideUtility clearInstalledOverrideMetadataForPackageName: each ]
]

{ #category : 'private' }
GbxOverrideToolsTest >> ensureProductionOverrideState [
	((GbxOverrideUtility allOverridesInPackage: GbxRuntimeOverrideSpec overridesPackageName) isEmpty
		or: [ (GbxOverrideUtility allOverridesInPackage: GbxToolsOverrideSpec overridesPackageName) isEmpty ])
		ifTrue: [ BaselineOfGemStonePharo new postload: nil package: nil ]
]

{ #category : 'running' }
GbxOverrideToolsTest >> setUp [
	super setUp.
	self ensureProductionOverrideState.
	self clearTestOverrideMetadata.
	GbxOverrideFixture restoreDefaultDefinition.
	GbxOverrideReleaseSpecFixture restoreDefaultSpecMethod
]

{ #category : 'running' }
GbxOverrideToolsTest >> tearDown [
	GbxOverrideFixture restoreDefaultDefinition.
	GbxOverrideReleaseSpecFixture restoreDefaultSpecMethod.
	self clearTestOverrideMetadata.
	self ensureProductionOverrideState.
	super tearDown
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testAbstractOverrideSpecChoosesNewestDeclaredVersion [
	self assert: GbxOverrideSpecFixture specMethodSelector equals: #spec200.
	self assert: GbxOverrideSpecFixture specMethodVersion equals: '2.0'.
	self assert: GbxOverrideSpecFixture spec packageName equals: 'NewestPackage'
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testBaselineHooksRoundTripRuntimeOverrides [
	| baseline originalSource overriddenSource |
	baseline := BaselineOfGemStonePharo new.

	baseline preload: nil package: nil.
	originalSource := (Bag >> #add:withOccurrences:) sourceCode asString.

	self assert: (GbxOverrideUtility allOverridesInPackage: GbxRuntimeOverrideSpec overridesPackageName) isEmpty.

	baseline postload: nil package: nil.
	overriddenSource := (Bag >> #add:withOccurrences:) sourceCode asString.

	self assert: (GbxOverrideUtility allOverridesInPackage: GbxRuntimeOverrideSpec overridesPackageName) size equals: 4.
	self assert: (overriddenSource includesSubstring: 'gbxConsiderModified').
	self deny: overriddenSource equals: originalSource.

	baseline preload: nil package: nil.

	self assert: (GbxOverrideUtility allOverridesInPackage: GbxRuntimeOverrideSpec overridesPackageName) isEmpty.
	self assert: (Bag >> #add:withOccurrences:) sourceCode asString equals: originalSource
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testBaselineHooksRoundTripToolsOverrides [
	| baseline originalClassSource originalInstanceSource overriddenClassSource overriddenInstanceSource |
	baseline := BaselineOfGemStonePharo new.
	overriddenInstanceSource := (StPlaygroundPagePresenter >> #menuActionsFor:) sourceCode asString.
	overriddenClassSource := (StPlaygroundPagePresenter class >> #extendedMenuCommands) sourceCode asString.

	self assert: (GbxOverrideUtility allOverridesInPackage: GbxToolsOverrideSpec overridesPackageName) size equals: 2.
	self assert: (overriddenInstanceSource includesSubstring: 'GemStone').
	self assert: (overriddenClassSource includesSubstring: 'beginsWith: ''GbsPlayground''').

	baseline preload: nil package: nil.
	originalInstanceSource := (StPlaygroundPagePresenter >> #menuActionsFor:) sourceCode asString.
	originalClassSource := (StPlaygroundPagePresenter class >> #extendedMenuCommands) sourceCode asString.

	self assert: (GbxOverrideUtility allOverridesInPackage: GbxToolsOverrideSpec overridesPackageName) isEmpty.
	self deny: (originalInstanceSource includesSubstring: 'GemStone').
	self deny: (originalClassSource includesSubstring: 'beginsWith: ''GbsPlayground''').

	baseline postload: nil package: nil.

	self assert: (GbxOverrideUtility allOverridesInPackage: GbxToolsOverrideSpec overridesPackageName) size equals: 2.
	self assert: (StPlaygroundPagePresenter >> #menuActionsFor:) sourceCode asString equals: overriddenInstanceSource.
	self assert: (StPlaygroundPagePresenter class >> #extendedMenuCommands) sourceCode asString equals: overriddenClassSource
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testConcreteRuntimeOverrideSpecProvidesExpectedRuntimeOverrides [
	| spec selectors |
	spec := GbxRuntimeOverrideSpec spec.
	selectors := spec methodOverrides collect: [ :each | each selector ].

	self assert: GbxRuntimeOverrideSpec specMethodSelector equals: #spec93.
	self assert: GbxRuntimeOverrideSpec overridesPackageName equals: 'GbsRuntimeOverrides'.
	self assert: spec packageName equals: 'GbsRuntimeOverrides'.
	self assert: spec classOverrides isEmpty.
	self assert: spec variableOverrides isEmpty.
	self assert: spec methodOverrides size equals: 4.
	self assert: (selectors includes: #add:withOccurrences:).
	self assert: (selectors includes: #remove:ifAbsent:).
	self assert: (selectors includes: #removeKey:ifAbsent:).
	self assert: (selectors includes: #at:put:)
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testClassOverrideApplyRedefinesInstanceVariables [
	| original replacement override |
	original := 'oldVar'.
	replacement := 'oldVar extraVar'.
	override := GbxClassOverride
		behavior: GbxOverrideFixture
		from: original
		to: replacement.
	override parent: (GbxOverrideSet
		destinationPackageName: 'GemStone-Pharo-Tests'
		classOverrides: { override }
		variableOverrides: #()
		methodOverrides: #()).

	override apply.

	self assert: GbxOverrideFixture instVarNames asArray equals: #('oldVar' 'extraVar')
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testDiscoveryFindsInstalledClassAndMethodOverridesByPackageName [
	| classOverride methodOverride overrideSet discovered |
	classOverride := GbxClassOverride
		behavior: GbxOverrideFixture
		from: 'oldVar'
		to: 'oldVar extraVar'.
	methodOverride := GbxMethodOverride
		behavior: GbxOverrideFixture
		selector: #value
		from: (GbxOverrideFixture >> #value) sourceCode asString
		to: 'value
	^ 2'.
	overrideSet := GbxOverrideSet
		destinationPackageName: 'GbxOverrideDiscoveryPackage'
		classOverrides: { classOverride }
		variableOverrides: #()
		methodOverrides: { methodOverride }.

	overrideSet apply.
	discovered := GbxOverrideUtility allOverridesInPackage: 'GbxOverrideDiscoveryPackage'.

	self assert: discovered size equals: 2.
	self assert: ((discovered select: [ :each | each isKindOf: GbxClassOverride ]) size) equals: 1.
	self assert: ((discovered select: [ :each | each isKindOf: GbxMethodOverride ]) size) equals: 1.
	self assert: GbxOverrideFixture new value equals: 2.
	self assert: GbxOverrideFixture instVarNames asArray equals: #('oldVar' 'extraVar')
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testMethodOverrideApplyRecompilesMethodSource [
	| original replacement override |
	original := (GbxOverrideFixture >> #value) sourceCode asString.
	replacement := 'value
	^ 2'.
	override := GbxMethodOverride
		behavior: GbxOverrideFixture
		selector: #value
		from: original
		to: replacement.

	override apply.

	self assert: GbxOverrideFixture new value equals: 2
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testOverrideEditSequenceTransformsSource [
	| override |
	override := GbxMethodOverride
		behavior: GbxOverrideFixture
		selector: #value
		crc: 1
		edits: {
			(GbxOverrideEditCopy count: 3).
			(GbxOverrideEditDelete count: 1).
			(GbxOverrideEditInsert string: 'p').
			(GbxOverrideEditCopy count: 2) }.

	self
		assert: (override editedSourceFrom: 'kitten')
		equals: 'kitpen'
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testOverrideSetDifferencesClassifiesEditOnlyConflicts [
	| left right leftSet rightSet differences |
	left := GbxMethodOverride
		behavior: GbxOverrideFixture
		selector: #value
		crc: 123
		edits: { (GbxOverrideEditInsert string: '1') }.
	right := GbxMethodOverride
		behavior: GbxOverrideFixture
		selector: #value
		crc: 123
		edits: { (GbxOverrideEditInsert string: '2') }.
	leftSet := GbxOverrideSet
		destinationPackageName: 'Pkg'
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: { left }.
	rightSet := GbxOverrideSet
		destinationPackageName: 'Pkg'
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: { right }.

	differences := leftSet differencesFrom: rightSet.

	self assert: (differences at: #status) equals: 'Differences found'.
	self assert: ((differences at: #methodOverrides) includesKey: #editsOnlyConflicts)
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testSpecFormatterIncludesExecutableLookingSpec [
	| override overrideSet formatted |
	override := GbxMethodOverride
		behavior: GbxOverrideFixture
		selector: #value
		crc: 123
		edits: { (GbxOverrideEditInsert string: 'value
	^ 9') }.
	overrideSet := GbxOverrideSet
		destinationPackageName: 'Pkg'
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: { override }.

	formatted := GbxSpecFormatter format: overrideSet version: '2.0'.

	self assert: (formatted includesSubstring: 'destinationPackageName: ''Pkg''').
	self assert: (formatted includesSubstring: 'selector: #value').
	self assert: (formatted includesSubstring: '"version: 2.0"')
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testPrepareOverridesForReleaseRegeneratesSpecAndRestoresOriginalDefinition [
	| methodOverride overrideSet specSource |
	methodOverride := GbxMethodOverride
		behavior: GbxOverrideFixture
		selector: #value
		from: (GbxOverrideFixture >> #value) sourceCode asString
		to: 'value
	^ 9'.
	overrideSet := GbxOverrideSet
		destinationPackageName: GbxOverrideReleaseSpecFixture overridesPackageName
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: { methodOverride }.

	overrideSet apply.
	self assert: GbxOverrideFixture new value equals: 9.

	self assert: GbxOverrideUtility prepareOverridesForRelease.

	specSource := GbxOverrideReleaseSpecFixture specMethodSource.
	self assert: GbxOverrideFixture new value equals: 1.
	self assert: (GbxOverrideUtility allOverridesInPackage: GbxOverrideReleaseSpecFixture overridesPackageName) isEmpty.
	self assert: (specSource includesSubstring: 'destinationPackageName: ''GbxOverrideReleasePackage''').
	self assert: (specSource includesSubstring: 'selector: #value')
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testToolsOverrideSpecProvidesExpectedPlaygroundOverrides [
	| spec overrides |
	spec := GbxToolsOverrideSpec spec.
	overrides := spec methodOverrides.

	self assert: GbxToolsOverrideSpec specMethodSelector equals: #spec93.
	self assert: GbxToolsOverrideSpec overridesPackageName equals: 'GbsToolsOverrides'.
	self assert: spec packageName equals: 'GbsToolsOverrides'.
	self assert: spec classOverrides isEmpty.
	self assert: spec variableOverrides isEmpty.
	self assert: overrides size equals: 2.
	self deny: spec hasNoEffect.
	self assert: (overrides anySatisfy: [ :each |
		each behavior = StPlaygroundPagePresenter
			and: [ each selector = #menuActionsFor: ] ]).
	self assert: (overrides anySatisfy: [ :each |
		each behavior = StPlaygroundPagePresenter class
			and: [ each selector = #extendedMenuCommands ] ])
]
