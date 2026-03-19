Extension { #name : #'Fraction' }

{ #category : '*GemStone-GBS-Converted-GBS-private' }
Fraction class >> gbsReplicatorClass [

	^GbxPointerMagnitudeReplicator
]

{ #category : '*GemStone-GBS-Converted-GemStone-extensions' }
Fraction >> roundedHalfToEven [
	"Returns the integer nearest in value to the receiver. If the receiver is 
exactly halfway between two integers, return the even one."

	| remainder |
	remainder := numerator abs \\ denominator.
	^remainder * 2 = denominator
		ifFalse: [self rounded]
		ifTrue: 
			[| truncated |
			truncated := self truncated.
			truncated even ifTrue: [truncated] ifFalse: [truncated + self sign]]
]

{ #category : '*GemStone-GBS-Converted-converting' }
Fraction >> asScaledDecimal: scale [

	^ScaledDecimal numerator: numerator denominator: denominator scale: scale
]

{ #category : '*GemStone-GBS-Converted-converting' }
Fraction >> asFraction [

	^self
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
Fraction >> gbxIsServerSpecialInSession: aSession [

	^aSession isSpecialFraction: self.
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
Fraction >> gbxExistingOrSpecialDelegateInSession: aGbsSession [
	"Private.  GBS.  If I am within the range for an immediate fraction in this session, create and answer that delegate.
	Otherwise answer my mapped delegate, or nil if none."

	| delegate |
	delegate := aGbsSession delegateForSpecialFraction: self.
	^delegate isNil
		ifTrue: [super gbxExistingOrSpecialDelegateInSession: aGbsSession]
		ifFalse: [delegate]
]

{ #category : '*GemStone-GBS-Converted-GemStone-extensions' }
Fraction >> asGSObjectInSession: aGbsSession [
	"Private.  GBS.  Look up or create a delegate for me. If I'm in range to be an immediate fraction in this session,
	create a delegate for that. Otherwise, look up my POM oop mapping, or create a new mapping if I'm unmapped."

	| delegate |
	delegate := self gbxExistingOrSpecialDelegateInSession: aGbsSession.
	^delegate == nil
		ifTrue: [super asGSObjectInSession: aGbsSession]
		ifFalse: [delegate]
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Fraction class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Fraction class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Fraction class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Fraction >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Fraction >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Fraction >> isRunningUnderAssertingVM [
	^false
]

