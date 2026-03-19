Extension { #name : 'UndefinedObject' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
UndefinedObject >> gbxExistingOrSpecialDelegateInSession: aGbsSession [
	^ aGbsSession oopNil
]

{ #category : '*GemStone-GBS-Converted-debugging' }
UndefinedObject >> gbxIsGsTopGlue: aSelector [
	^ #(#onEventSignal:handle:raiseException: #processHandlers #initializeSystemExceptions)
		includes: aSelector
]
