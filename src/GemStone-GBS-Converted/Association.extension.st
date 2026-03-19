Extension { #name : 'Association' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Association class >> replicationSpec [
	^ super replicationSpec , #((key min 1))
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Association >> gbxDebugPrintOn: aStream [
	GbxReflection debugPrint: self key on: aStream.
	aStream nextPutAll: '->'.
	GbxReflection debugPrint: self value on: aStream
]
