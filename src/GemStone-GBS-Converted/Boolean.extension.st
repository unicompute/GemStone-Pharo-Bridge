Extension { #name : 'Boolean' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Boolean class >> gbsReplicatorClass [
	^ GbxNullReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Boolean >> asLocalBoolean [
	GbsConfiguration
		deprecated: 'Boolean>>asLocalBoolean deprecated March, 2006. Send #asLocalObject instead'.
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Boolean >> faultToLevel: level [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Boolean >> gbxCanBeArgForUnsynchronizedOperationInSession: session [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Boolean >> gbxCouldBeForwarder [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Boolean >> gbxDeepCopyCycles: cycles [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Boolean >> gbxDelegate [
	^ nil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Boolean >> gbxIsModifiable [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Boolean >> gbxIsServerSpecialInSession: aSession [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Boolean >> stubYourself [
]
