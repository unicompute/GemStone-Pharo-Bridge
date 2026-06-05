"
A minimal replication-scheme double for testing GbsClampLevelEditorPresenter. Stores per-class instVar
level arrays in a dictionary, mirroring GbxReplicationScheme>>instVarLevelsForClass: /
replaceInstVarLevelsForClass:with:.
"
Class {
	#name : 'CoreGbsFakeClampScheme',
	#superclass : 'Object',
	#instVars : [
		'levelsByClass'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreGbsFakeClampScheme >> instVarLevelsForClass: aClass [
	^ self levelsByClass at: aClass ifAbsent: [ nil ]
]

{ #category : 'accessing' }
CoreGbsFakeClampScheme >> levelsByClass [
	^ levelsByClass ifNil: [ levelsByClass := IdentityDictionary new ]
]

{ #category : 'accessing' }
CoreGbsFakeClampScheme >> replaceInstVarLevelsForClass: aClass with: levelsArray [
	levelsArray
		ifNil: [ self levelsByClass removeKey: aClass ifAbsent: [ ] ]
		ifNotNil: [ self levelsByClass at: aClass put: levelsArray ].
	^ levelsArray
]
