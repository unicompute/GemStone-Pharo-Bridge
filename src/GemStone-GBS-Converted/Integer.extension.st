Extension { #name : 'Integer' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Integer >> asGSObjectInSession: aGbsSession [
	| specialDelegate |
	specialDelegate := aGbsSession delegateForSpecialInteger: self.
	^ specialDelegate
		ifNil: [ super asGSObjectInSession: aGbsSession ]
		ifNotNil: [ specialDelegate ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Integer >> gbxExistingOrSpecialDelegateInSession: aGbsSession [
	| specialDelegate |
	specialDelegate := aGbsSession delegateForSpecialInteger: self.
	^ specialDelegate
		ifNil: [ aGbsSession cacheAtST: self ]
		ifNotNil: [ specialDelegate ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Integer >> gbxIsServerSpecialInSession: aSession [
	^ aSession isSpecialInteger: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Integer >> oopValue [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Integer >> roundedHalfToEven [
	^ self
]
