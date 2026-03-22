Extension { #name : 'ExternalAddress' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
ExternalAddress >> asAddress [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
ExternalAddress >> plusOffset: anInteger [
	^ self + anInteger
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
ExternalAddress >> gbxByteSizeForReplace [
	^ nil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
ExternalAddress >> gbxByteAtForReplace: index [
	^ self byteAt: index
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
ExternalAddress >> gbxByteAtForReplace: index put: value [
	^ self byteAt: index put: value
]
