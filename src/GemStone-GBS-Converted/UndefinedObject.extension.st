Extension { #name : 'UndefinedObject' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject class >> gbsReplicatorClass [
	^ GbxNullReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> asGSObjectInSession: aGbsSession [
	^ aGbsSession oopNil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> faultToLevel: level [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> forAnySingleSession [
	^ nil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> forSession: aSession [
	^ nil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> gbxCanBeArgForUnsynchronizedOperationInSession: session [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> gbxCouldBeForwarder [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> gbxDeepCopyCycles: cycles [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> gbxDelegate [
	^ nil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> gbxExistingOrSpecialDelegateInSession: aGbsSession [
	^ aGbsSession oopNil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> gbxIsModifiable [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> gbxIsServerSpecialInSession: aSession [
	^ true
]

{ #category : '*GemStone-GBS-Converted-debugging' }
UndefinedObject >> gbxIsGsTopGlue: aSelector [
	^ #(#onEventSignal:handle:raiseException: #processHandlers #initializeSystemExceptions)
		includes: aSelector
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> notForSession: aGbsSession [
	^ nil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> stubYourself [
]
