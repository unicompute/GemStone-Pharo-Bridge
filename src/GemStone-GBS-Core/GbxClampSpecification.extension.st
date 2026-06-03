Extension { #name : 'GbxClampSpecification' }

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> addClassClamp: aClass scheme: aScheme [
	classClamps at: aClass put: aScheme.
	^ aScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> addSubleafHeaders [
	^ addSubleafHeaders
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> addSubleafHeaders: aBoolean [
	addSubleafHeaders := aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> addIdentityClamp: anObject scheme: aScheme [
	idClamps at: anObject put: aScheme.
	^ aScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> classClamps [
	^ classClamps
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> classClamps: aCollection [
	classClamps := aCollection
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> environmentId [
	^ environmentId ifNil: [ 0 ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> environmentId: anInteger [
	environmentId := anInteger
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> idClamps [
	^ idClamps
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> idClamps: aCollection [
	idClamps := aCollection
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> initialize [
	super initialize.
	idClamps := IdentityDictionary new.
	classClamps := IdentityDictionary new.
	valueClamps := Dictionary new.
	instVarLevels := Dictionary new.
	addSubleafHeaders := true.
	traversalCallBackSelector := #_gbsTraversalCallback.
	environmentId := 0
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> instVarLevels [
	^ instVarLevels
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> instVarLevels: anObject [
	instVarLevels := anObject
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> instVarLevelsForClass: aClass [
	^ instVarLevels at: aClass ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> instVarLevelsSelector [
	^ instVarLevelsSelector
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> instVarLevelsSelector: aSymbolOrNil [
	instVarLevelsSelector := aSymbolOrNil
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> removeInstVarLevelsForClass: aClass [
	instVarLevels removeKey: aClass ifAbsent: [ ].
	^ aClass
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> replaceInstVarLevelsForClass: aClass with: levelsArray [
	levelsArray
		ifNil: [ self removeInstVarLevelsForClass: aClass ]
		ifNotNil: [ instVarLevels at: aClass put: levelsArray ].
	^ levelsArray
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> replicationSchemeFor: anObject ifAbsent: aBlock [
	^ idClamps
		at: anObject
		ifAbsent: [
			classClamps
				at: anObject class
				ifAbsent: aBlock ]
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> traversalCallBackSelector [
	^ traversalCallBackSelector
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> traversalCallBackSelector: aSymbol [
	traversalCallBackSelector := aSymbol
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> valueClamps [
	^ valueClamps
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> valueClamps: anObject [
	valueClamps := anObject
]
