"
Headless tests for the per-instVar clamp level editor logic (GbsClampLevelEditorPresenter and
GbsClampLevelRow). Exercise row building, level-array round-tripping, and write-back without rendering.
"
Class {
	#name : 'GbsClampLevelEditorPresenterCoreToolsTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'private' }
GbsClampLevelEditorPresenterCoreToolsTest >> editorWithLevels: levelsArrayOrNil [
	| scheme |
	scheme := CoreGbsFakeClampScheme new.
	levelsArrayOrNil ifNotNil: [
		scheme replaceInstVarLevelsForClass: CoreGbsClampLevelFixture with: levelsArrayOrNil ].
	^ GbsClampLevelEditorPresenter onScheme: scheme class: CoreGbsClampLevelFixture
]

{ #category : 'tests' }
GbsClampLevelEditorPresenterCoreToolsTest >> testRowsCoverAllInstanceVariables [
	| editor rows |
	editor := self editorWithLevels: nil.
	rows := editor clampLevelRows.
	self assert: (rows collect: [ :each | each name ]) asArray equals: #('customer' 'lineItems' 'status').
	self assert: (rows collect: [ :each | each index ]) asArray equals: #(1 2 3).
	self assert: (rows allSatisfy: [ :each | each level isNil ])
]

{ #category : 'tests' }
GbsClampLevelEditorPresenterCoreToolsTest >> testRowsReflectStoredLevels [
	| editor rows |
	editor := self editorWithLevels: { 2. nil. 5 }.
	rows := editor clampLevelRows.
	self assert: (rows first level) equals: 2.
	self assert: (rows second level) isNil.
	self assert: (rows third level) equals: 5.
	self assert: (rows third levelDisplayString) equals: '5'.
	self assert: (rows second levelDisplayString) equals: ''
]

{ #category : 'tests' }
GbsClampLevelEditorPresenterCoreToolsTest >> testLevelsArrayFromRowsRoundTrips [
	| editor rows array |
	editor := self editorWithLevels: nil.
	rows := editor clampLevelRows.
	rows first level: 3.
	rows third level: 7.
	array := editor levelsArrayFromRows: rows.
	self assert: array equals: { 3. nil. 7 }
]

{ #category : 'tests' }
GbsClampLevelEditorPresenterCoreToolsTest >> testLevelsArrayIsNilWhenAllUnset [
	| editor rows |
	editor := self editorWithLevels: nil.
	rows := editor clampLevelRows.
	self assert: (editor levelsArrayFromRows: rows) isNil
]

{ #category : 'tests' }
GbsClampLevelEditorPresenterCoreToolsTest >> testApplyEditedRowsWritesBackToScheme [
	| editor rows |
	editor := self editorWithLevels: nil.
	rows := editor clampLevelRows.
	rows second level: 4.
	editor applyEditedRows: rows.
	self assert: (editor scheme instVarLevelsForClass: CoreGbsClampLevelFixture) equals: { nil. 4 }
]

{ #category : 'tests' }
GbsClampLevelEditorPresenterCoreToolsTest >> testApplyEditedRowsClearsLevelsWhenAllUnset [
	| editor rows |
	editor := self editorWithLevels: { 2. 3. 4 }.
	rows := editor clampLevelRows.
	rows do: [ :each | each level: nil ].
	editor applyEditedRows: rows.
	self assert: (editor scheme instVarLevelsForClass: CoreGbsClampLevelFixture) isNil
]

{ #category : 'tests' }
GbsClampLevelEditorPresenterCoreToolsTest >> testRowLevelParsesStringInput [
	| row |
	row := GbsClampLevelRow name: 'x' index: 1 level: nil.
	row level: '6'.
	self assert: row level equals: 6.
	row level: '   '.
	self assert: row level isNil.
	row level: 'not-a-number'.
	self assert: row level isNil
]
