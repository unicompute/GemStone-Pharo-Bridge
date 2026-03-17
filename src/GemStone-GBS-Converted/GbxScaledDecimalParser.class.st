Class {
	#name : #'GbxScaledDecimalParser',
	#superclass : #'Object',
	#instVars : [ #'string' #'position' #'sign' #'fractionalPart' #'defaultScale' #'explicitScale' #'integerPart' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'initialize-release' }
GbxScaledDecimalParser >> initialize

	defaultScale := 0.
	explicitScale := nil.
	sign := 1.
	integerPart := fractionalPart := 0.
	position := 1

{ #category : #'public' }
GbxScaledDecimalParser >> parse: aString
	"Parse the given string as a ScaledDecimal and answer that ScaledDecimal. 
	If the parse fails, signal an exception."

	aString isEmpty ifTrue: [^self failI: 'bad format'].
	string := aString.
	self
		skipBlanks;
		parseSign;
		parseIntegerAndFraction;
		parseScale;
		parseTrailingSpace.
	^self scaledDecimal

{ #category : #'private' }
GbxScaledDecimalParser >> skipBlanks

	[position <= string size and: [(string at: position) = $ ]] whileTrue: [position := position + 1]

{ #category : #'private' }
GbxScaledDecimalParser >> failOOR: aString

	OutOfRange raiseSignal: aString , ' at position ' , position printString

{ #category : #'private' }
GbxScaledDecimalParser >> skipPlus

	| foundPlus |
	foundPlus := 
	(position <= string size and: [(string at: position) = $+]).
	foundPlus ifTrue: [position := position + 1].
	^foundPlus

{ #category : #'private' }
GbxScaledDecimalParser >> integerFromDigits: digits

	| value |
	value := 0.
	digits do: [:digit | value := value * 10 + digit digitValue].
	^value

{ #category : #'private' }
GbxScaledDecimalParser >> parseDigits

	| digits digit |
	digits := WriteStream on: (String new: 10).
	[position <= string size and: [(digit := string at: position) isDigit]] whileTrue: 
			[digits nextPut: digit.
			position := position + 1].
	^digits contents

{ #category : #'private' }
GbxScaledDecimalParser >> parseFractionalPart
	"optional; decimal point followed by 0 or more digits."

	| digits |
	(position > string size or: [(string at: position) ~~ $.])
		ifTrue: [^self]
		ifFalse: 
			[position := position + 1.
			digits := self parseDigits.
			defaultScale := digits size.
			fractionalPart := self integerFromDigits: digits]

{ #category : #'private' }
GbxScaledDecimalParser >> parseIntegerAndFraction
	"optional; decimal point followed by 0 or more digits."

	position > string size ifTrue: [self failI: 'bad format'].
	(string at: position) == $.
		ifTrue: 
			["fraction only"
			self parseFractionalPart]
		ifFalse: 
			[self
				parseIntegerPart;
				parseFractionalPart]

{ #category : #'private' }
GbxScaledDecimalParser >> parseIntegerPart
	"Digit+"

	| digits |
	digits := self parseDigits.
	digits size < 1 ifTrue: [self failOOR: 'Digit expected'].
	integerPart := self integerFromDigits: digits.

{ #category : #'private' }
GbxScaledDecimalParser >> parseScale
	"optional; 's' followed by 0 or more digits."

	| digits haveSign |
	(position > string size or: [(string at: position) ~~ $s])
		ifTrue: [^self]
		ifFalse: 
			[position := position + 1.
			haveSign := self skipPlus.
			digits := self parseDigits.
			(haveSign and: [digits size = 0]) ifTrue: [self failOOR: 'digits required after scale sign'].
			digits size > 0 ifTrue: [explicitScale := self integerFromDigits: digits]]

{ #category : #'private' }
GbxScaledDecimalParser >> parseSign
	"optional + or -"

	position <= string size
		ifTrue: 
			[| char |
			char := string at: position.
			char == $+ ifTrue: [position := position + 1].
			char == $-
				ifTrue: 
					[sign := -1.
					position := position + 1]]

{ #category : #'private' }
GbxScaledDecimalParser >> parseTrailingSpace

	(position <= string size and: [(string at: position) ~~ $ ]) ifTrue: [self failOOR: 'illegal trailing digit']

{ #category : #'private' }
GbxScaledDecimalParser >> scaledDecimal
	"Compute the value of what we've parsed."

	| mantissa intFactor fracFactor |
	explicitScale == nil ifTrue: [explicitScale := defaultScale].
	defaultScale > explicitScale
		ifTrue: [^self failOOR: 'Specified scale must be >= number of fractional digits'].
	explicitScale > 30000 ifTrue: [^self failOOR: 'scale of a ScaledDecimal cannot exceed 30000'].
	intFactor := 10 raisedTo: explicitScale.
	fracFactor := 10 raisedTo: explicitScale - defaultScale.
	mantissa := sign * (integerPart * intFactor + (fractionalPart * fracFactor)).
	^ScaledDecimal _mantissa: mantissa scale: explicitScale

{ #category : #'private' }
GbxScaledDecimalParser >> failI: aString

	ImproperOperation raiseSignal: aString , ' at position ' , position printString

{ #category : #'instance creation' }
GbxScaledDecimalParser class >> parse: aString

	^self new initialize parse: aString

