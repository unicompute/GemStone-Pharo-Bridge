Class {
	#name : 'GbxOverrideToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbxOverrideToolsTest >> setUp [
	super setUp.
	GbxOverrideFixture restoreDefaultDefinition
]

{ #category : 'running' }
GbxOverrideToolsTest >> tearDown [
	GbxOverrideFixture restoreDefaultDefinition.
	super tearDown
]

{ #category : 'tests' }
GbxOverrideToolsTest >> testAbstractOverrideSpecChoosesNewestDeclaredVersion [
	self assert: GbxOverrideSpecFixture specMethodSelector equals: #spec200.
	self assert: GbxOverrideSpecFixture specMethodVersion equals: '2.0'.
	self assert: GbxOverrideSpecFixture spec packageName equals: 'NewestPackage'
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
