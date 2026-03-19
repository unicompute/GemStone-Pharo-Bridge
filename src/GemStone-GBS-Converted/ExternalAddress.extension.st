Extension { #name : 'ExternalAddress' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
ExternalAddress >> asAddress [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
ExternalAddress >> plusOffset: anInteger [
	^ self + anInteger
]
