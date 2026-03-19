Extension { #name : 'Character' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character class >> gbsReplicatorClass [
	^ GbxNullReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character >> asGSObjectInSession: aSession [
	^ self gbxExistingOrSpecialDelegateInSession: aSession
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character >> gbxCanBeArgForUnsynchronizedOperationInSession: session [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character >> gbxCouldBeForwarder [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character >> gbxDeepCopyCycles: cycles [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character >> gbxDelegate [
	^ nil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character >> gbxExistingOrSpecialDelegateInSession: aSession [
	^ aSession delegateForCharacter: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character >> gbxIdentityHash [
	^ self identityHash
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character >> gbxIsImmutable: bool [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character >> gbxIsModifiable [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character >> gbxIsServerSpecialInSession: aSession [
	^ aSession isSpecialCharacter: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Character >> stubYourself [
]
