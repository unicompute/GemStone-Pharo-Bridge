"
An editor for the per-instance-variable clamp levels of a replication scheme. Surfaces the
GbxReplicationScheme / GbxClampSpecification instVarLevels model (previously only reachable through
serverClampInstVarLevelEntries) as an editable instVar-name -> level table.

A clamp level controls how deeply a named instance variable's slot is traversed during clamped
replication. Rows are built from the scheme's stored levels for the edited class, aligned to that class's
named instance variables; editing a row and applying writes the levels back through
replaceInstVarLevelsForClass:with: so the next clamped traversal uses them.

The logic methods (clampLevelRows, applyEditedRows:, levelsArrayFromRows:) are headless-testable; the
Spec2 table is the interactive shell.
"
Class {
	#name : 'GbsClampLevelEditorPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'scheme',
		'theClass',
		'table',
		'applyButton',
		'rows'
	],
	#category : 'GemStone-GBS-Core-Tools',
	#package : 'GemStone-GBS-Core-Tools'
}

{ #category : 'instance creation' }
GbsClampLevelEditorPresenter class >> onScheme: aScheme class: aClass [
	^ self new
		scheme: aScheme;
		theClass: aClass;
		refreshRows;
		yourself
]

{ #category : 'instance creation' }
GbsClampLevelEditorPresenter class >> openOnScheme: aScheme class: aClass [
	| presenter |
	presenter := self onScheme: aScheme class: aClass.
	presenter refreshRows.
	^ presenter openWithSpec
]

{ #category : 'instance creation' }
GbsClampLevelEditorPresenter class >> openForSession: aSession clientClass: aClassOrName [
	"Open the editor on the session's current replication scheme for the given client class (a class or a
	class name). Answers nil and informs the user when the scheme or class cannot be resolved."
	| scheme resolvedClass |
	scheme := self currentReplicationSchemeForSession: aSession.
	scheme ifNil: [
		[ UIManager default inform: 'No current replication scheme for this session.' ] on: Error do: [ ].
		^ nil ].
	resolvedClass := self resolveClass: aClassOrName.
	resolvedClass ifNil: [
		[ UIManager default inform: 'Could not resolve client class ', aClassOrName printString, '.' ] on: Error do: [ ].
		^ nil ].
	^ self openOnScheme: scheme class: resolvedClass
]

{ #category : 'private' }
GbsClampLevelEditorPresenter class >> currentReplicationSchemeForSession: aSession [
	| manager |
	aSession ifNil: [ ^ nil ].
	(aSession respondsTo: #replicatorManager) ifFalse: [ ^ nil ].
	manager := [ aSession replicatorManager ] on: Error do: [ ^ nil ].
	(manager notNil and: [ manager respondsTo: #currentReplicationScheme ]) ifFalse: [ ^ nil ].
	^ [ manager currentReplicationScheme ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbsClampLevelEditorPresenter class >> resolveClass: aClassOrName [
	aClassOrName ifNil: [ ^ nil ].
	((aClassOrName isKindOf: Behavior)
		or: [ (aClassOrName respondsTo: #isBehavior) and: [ aClassOrName isBehavior ] ]) ifTrue: [
			^ aClassOrName ].
	((aClassOrName isString) or: [ aClassOrName isSymbol ]) ifTrue: [
		^ Smalltalk classNamed: aClassOrName asString ].
	^ nil
]

{ #category : 'accessing' }
GbsClampLevelEditorPresenter >> scheme [
	^ scheme
]

{ #category : 'accessing' }
GbsClampLevelEditorPresenter >> scheme: aScheme [
	scheme := aScheme
]

{ #category : 'accessing' }
GbsClampLevelEditorPresenter >> theClass [
	^ theClass
]

{ #category : 'accessing' }
GbsClampLevelEditorPresenter >> theClass: aClass [
	theClass := aClass
]

{ #category : 'accessing' }
GbsClampLevelEditorPresenter >> rows [
	^ rows ifNil: [ rows := self clampLevelRows ]
]

{ #category : 'model' }
GbsClampLevelEditorPresenter >> instVarNames [
	"The named instance variables of the edited class, as strings, in slot order."
	theClass ifNil: [ ^ #() ].
	(theClass respondsTo: #allInstVarNames) ifFalse: [ ^ #() ].
	^ [ theClass allInstVarNames collect: [ :each | each asString ] ]
		on: Error
		do: [ #() ]
]

{ #category : 'model' }
GbsClampLevelEditorPresenter >> storedLevels [
	"The scheme's stored per-instVar levels array for the edited class, or an empty array when none."
	(scheme isNil or: [ theClass isNil ]) ifTrue: [ ^ #() ].
	(scheme respondsTo: #instVarLevelsForClass:) ifFalse: [ ^ #() ].
	^ ([ scheme instVarLevelsForClass: theClass ] on: Error do: [ nil ]) ifNil: [ #() ]
]

{ #category : 'model' }
GbsClampLevelEditorPresenter >> clampLevelRows [
	"Build one row per named instance variable: a GbsClampLevelRow with the instVar name, its slot index,
	and the currently stored level (nil when the slot has no clamp level set)."
	| names levels |
	names := self instVarNames.
	levels := self storedLevels.
	^ (1 to: names size) collect: [ :index |
		GbsClampLevelRow
			name: (names at: index)
			index: index
			level: (levels at: index ifAbsent: [ nil ]) ]
]

{ #category : 'model' }
GbsClampLevelEditorPresenter >> levelsArrayFromRows: aCollectionOfRows [
	"Build the levels array to store back into the clamp spec from the edited rows. Answers nil when every
	level is unset (so the class's clamp levels are removed). Otherwise the array is sized to the highest
	slot index that has a level set (trailing unset slots are trimmed, since a nil level means no clamp);
	intermediate unset slots are left as nil to preserve slot alignment."
	| maxSetIndex array |
	maxSetIndex := aCollectionOfRows inject: 0 into: [ :max :row |
		row level isNil ifTrue: [ max ] ifFalse: [ max max: row index ] ].
	maxSetIndex = 0 ifTrue: [ ^ nil ].
	array := Array new: maxSetIndex.
	aCollectionOfRows do: [ :row |
		row index <= maxSetIndex ifTrue: [ array at: row index put: row level ] ].
	^ array
]

{ #category : 'model' }
GbsClampLevelEditorPresenter >> applyEditedRows: aCollectionOfRows [
	"Write the edited per-instVar levels back into the scheme's clamp spec for the edited class. Answers the
	stored levels array (or nil when the class's clamp levels were cleared)."
	| levelsArray |
	(scheme isNil or: [ theClass isNil ]) ifTrue: [ ^ nil ].
	(scheme respondsTo: #replaceInstVarLevelsForClass:with:) ifFalse: [
		self error: 'Scheme does not support per-instVar clamp level editing.' ].
	levelsArray := self levelsArrayFromRows: aCollectionOfRows.
	scheme replaceInstVarLevelsForClass: theClass with: levelsArray.
	^ levelsArray
]

{ #category : 'actions' }
GbsClampLevelEditorPresenter >> refreshRows [
	rows := self clampLevelRows.
	table ifNotNil: [ table items: rows ].
	^ rows
]

{ #category : 'actions' }
GbsClampLevelEditorPresenter >> applyRows [
	| stored |
	stored := self applyEditedRows: self rows.
	[ UIManager default inform: 'Clamp levels saved.' ] on: Error do: [ ].
	^ stored
]

{ #category : 'initialization' }
GbsClampLevelEditorPresenter >> initializePresenters [
	table := self newTable.
	table
		addColumn: ((SpStringTableColumn title: 'Instance Variable' evaluated: [ :row | row name ]) width: 220);
		addColumn: (SpStringTableColumn title: 'Level' evaluated: [ :row | row levelDisplayString ]).
	table items: self rows.
	applyButton := self newButton
		label: 'Apply';
		action: [ self applyRows ];
		yourself
]

{ #category : 'layout' }
GbsClampLevelEditorPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: table;
		add: (SpBoxLayout newLeftToRight
			add: (self newLabel label: '');
			add: applyButton expand: false;
			yourself) expand: false;
		spacing: 6;
		yourself
]

{ #category : 'initialization' }
GbsClampLevelEditorPresenter >> initializeWindow: aWindow [
	aWindow
		title: 'Clamp Levels', (theClass ifNil: [ '' ] ifNotNil: [ ' - ', theClass name asString ]);
		initialExtent: 360 @ 420
]
