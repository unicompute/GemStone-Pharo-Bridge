Extension { #name : 'False' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
False >> asGSObjectInSession: aGbsSession [
	^ aGbsSession oopFalse
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
False >> gbxExistingOrSpecialDelegateInSession: aGbsSession [
	^ aGbsSession oopFalse
]
