Extension { #name : 'GbxClampSpecification' }

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> addClassClamp: aClass scheme: aScheme [
	classClamps at: aClass put: aScheme.
	^ aScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxClampSpecification >> addIdentityClamp: anObject scheme: aScheme [
	idClamps at: anObject put: aScheme.
	^ aScheme
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
GbxClampSpecification >> initialize [
	super initialize.
	idClamps := IdentityDictionary new.
	classClamps := IdentityDictionary new.
	valueClamps := Dictionary new.
	instVarLevels := Dictionary new.
	addSubleafHeaders := false.
	environmentId := 0
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
