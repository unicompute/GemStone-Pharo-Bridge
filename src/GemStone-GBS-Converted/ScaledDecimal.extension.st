Extension { #name : 'ScaledDecimal' }

{ #category : '*GemStone-GBS-Converted' }
ScaledDecimal >> asGSObjectInSession: aGbsSession [
	| delegate |
	delegate := self gbxExistingOrSpecialDelegateInSession: aGbsSession.
	^ delegate == nil
		ifTrue: [ super asGSObjectInSession: aGbsSession ]
		ifFalse: [ delegate ]
]

{ #category : '*GemStone-GBS-Converted' }
ScaledDecimal >> gbxExistingOrSpecialDelegateInSession: aGbsSession [
	| delegate |
	delegate := aGbsSession delegateForSpecialScaledDecimal: self.
	^ delegate isNil
		ifTrue: [ super gbxExistingOrSpecialDelegateInSession: aGbsSession ]
		ifFalse: [ delegate ]
]

{ #category : '*GemStone-GBS-Converted' }
ScaledDecimal >> gbxIsServerSpecialInSession: aSession [
	^ aSession specialConvert64 scaledDecimalInRange: self
]

{ #category : '*GemStone-GBS-Converted' }
ScaledDecimal class >> _mantissa: m scale: s [
	^ self
		newFromNumber: (Fraction numerator: m denominator: (10 raisedTo: s))
		scale: s
]

{ #category : '*GemStone-GBS-Converted' }
ScaledDecimal class >> gbsReplicatorClass [
	^ GbxPointerMagnitudeReplicator
]
