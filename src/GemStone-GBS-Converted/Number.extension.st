Extension { #name : 'Number' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Number >> faultPolicy [
	^ #immediate
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Number >> gbxCanBeArgForUnsynchronizedOperationInSession: session [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Number >> gbxDeepCopyCycles: dict [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Number >> gbxIsModifiable [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Number >> markDirty [
	^ self
]
