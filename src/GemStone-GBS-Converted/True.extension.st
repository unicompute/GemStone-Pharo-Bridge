Extension { #name : 'True' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
True >> asGSObjectInSession: aGbsSession [
	^ aGbsSession oopTrue
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
True >> gbxExistingOrSpecialDelegateInSession: aGbsSession [
	^ aGbsSession oopTrue
]
