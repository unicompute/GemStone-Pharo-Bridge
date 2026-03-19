Extension { #name : 'SmallInteger' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
SmallInteger class >> gbsReplicatorClass [
	^ GbxNullReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
SmallInteger >> asGSObjectInSession: aGbsSession [
	^ aGbsSession delegateForSpecialInteger: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
SmallInteger >> gbxCouldBeForwarder [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
SmallInteger >> gbxDelegate [
	^ nil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
SmallInteger >> gbxExistingOrSpecialDelegateInSession: aGbsSession [
	^ aGbsSession delegateForSpecialInteger: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
SmallInteger >> gbxIdentityHash [
	^ self identityHash
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
SmallInteger >> gbxIsImmutable: bool [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
SmallInteger >> stubYourself [
]
