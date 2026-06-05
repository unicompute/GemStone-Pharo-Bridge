"
A single editable row in the GbsClampLevelEditorPresenter: a named instance variable, its slot index in
the class, and the clamp level for that slot (nil when no level is set).
"
Class {
	#name : 'GbsClampLevelRow',
	#superclass : 'Object',
	#instVars : [
		'name',
		'index',
		'level'
	],
	#category : 'GemStone-GBS-Core-Tools',
	#package : 'GemStone-GBS-Core-Tools'
}

{ #category : 'instance creation' }
GbsClampLevelRow class >> name: aName index: anIndex level: aLevelOrNil [
	^ self new
		name: aName;
		index: anIndex;
		level: aLevelOrNil;
		yourself
]

{ #category : 'accessing' }
GbsClampLevelRow >> index [
	^ index
]

{ #category : 'accessing' }
GbsClampLevelRow >> index: anInteger [
	index := anInteger
]

{ #category : 'accessing' }
GbsClampLevelRow >> level [
	^ level
]

{ #category : 'accessing' }
GbsClampLevelRow >> level: aLevelOrNil [
	"Accept an integer level, nil, or a string/empty value from an edited cell; blank or unparseable input
	clears the level."
	(aLevelOrNil isNil or: [ aLevelOrNil isInteger ]) ifTrue: [
		level := aLevelOrNil.
		^ level ].
	(aLevelOrNil isString) ifTrue: [
		| trimmed |
		trimmed := aLevelOrNil trimBoth.
		trimmed isEmpty ifTrue: [ level := nil. ^ level ].
		level := [ trimmed asInteger ] on: Error do: [ nil ].
		^ level ].
	level := nil.
	^ level
]

{ #category : 'accessing' }
GbsClampLevelRow >> levelDisplayString [
	^ level ifNil: [ '' ] ifNotNil: [ level asString ]
]

{ #category : 'accessing' }
GbsClampLevelRow >> name [
	^ name
]

{ #category : 'accessing' }
GbsClampLevelRow >> name: aString [
	name := aString
]
