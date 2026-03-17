Class {
	#name : 'ScaledDecimal',
	#superclass : 'Number',
	#instVars : [
		'mantissa',
		'scale'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'Converting' }
ScaledDecimal >> asDouble
[
	"Returns an instance of SmallDouble or Float that has the value of the receiver."

	^self asFraction asDouble
]

{ #category : 'Converting' }
ScaledDecimal >> asFloat
[

	^self asFraction asFloat
]

{ #category : 'Converting' }
ScaledDecimal >> coerce: aNumber
[

	^aNumber asScaledDecimal: scale
]

{ #category : 'Converting' }
ScaledDecimal >> asDecimalFloat
[

	^self gbsMessenger raise: ArithmeticError message: 'Cannot convert to DecimalFloats on client'
]

{ #category : 'Converting' }
ScaledDecimal >> asRational
[

	^self asFraction
]

{ #category : 'Converting' }
ScaledDecimal >> asFixedPoint: newScale
[

	^self asFraction asFixedPoint: newScale
]

{ #category : 'Converting' }
ScaledDecimal >> asFraction
[

	^(Fraction numerator: mantissa denominator: (10 raisedTo: scale)) reduced
]

{ #category : 'GBS private' }
ScaledDecimal >> gbxExistingOrSpecialDelegateInSession: aGbsSession
[
	"Private.  GBS.  If I am within the range to be an immediate in this session, 
	create and answer that delegate.
	Otherwise answer my mapped delegate, or nil if none."

	| delegate |
	delegate := aGbsSession delegateForSpecialScaledDecimal: self.
	^delegate isNil
		ifTrue: [super gbxExistingOrSpecialDelegateInSession: aGbsSession]
		ifFalse: [delegate]
]

{ #category : 'GBS private' }
ScaledDecimal >> asGSObjectInSession: aGbsSession
[
	"Private.  GBS.  Look up or create a delegate for me. If I'm in range to be an immediate 
	in this session, create a delegate for that. Otherwise, look up my POM oop mapping, 
	or create a new mapping if I'm unmapped."

	| delegate |
	delegate := self gbxExistingOrSpecialDelegateInSession: aGbsSession.
	^delegate == nil
		ifTrue: [super asGSObjectInSession: aGbsSession]
		ifFalse: [delegate]
]

{ #category : 'Comparing' }
ScaledDecimal >> > aNumber
[

	| osc om m |
	(m := mantissa) ifNil: [^false	"self is a NaN"].
	aNumber _isScaledDecimal
		ifTrue: 
			[osc := aNumber scale.
			om := aNumber mantissa.
			om ifNil: [^false]]
		ifFalse: 
			[aNumber isInteger
				ifTrue: 
					[osc := 0.
					om := aNumber]].
	om
		ifNotNil: 
			[| sc |
			sc := scale.
			sc == osc ifFalse: [sc > osc ifTrue: [om := om * (10 raisedTo: sc - osc)] ifFalse: [m := m * (10 raisedTo: osc - sc)]].
			^m > om].
	^self retry: #> coercing: aNumber
]

{ #category : 'Comparing' }
ScaledDecimal >> = aNumber
[

	| osc om m |
	(m := mantissa) ifNil: [^false	"self is a NaN"].
	self == aNumber ifTrue: [^true].
	aNumber _isScaledDecimal
		ifTrue: 
			[osc := aNumber scale.
			om := aNumber mantissa.
			om ifNil: [^false]]
		ifFalse: 
			[aNumber isInteger
				ifTrue: 
					[osc := 0.
					om := aNumber]].
	om
		ifNotNil: 
			[| sc |
			sc := scale.
			sc == osc ifFalse: [sc > osc ifTrue: [om := om * (10 raisedTo: sc - osc)] ifFalse: [m := m * (10 raisedTo: osc - sc)]].
			^m = om].
	^self retry: #= coercing: aNumber
]

{ #category : 'Comparing' }
ScaledDecimal >> < aNumber
[

	| osc om m |
	(m := mantissa) ifNil: [^false	"self is a NaN"].
	aNumber _isScaledDecimal
		ifTrue: 
			[osc := aNumber scale.
			om := aNumber mantissa.
			om ifNil: [^false]]
		ifFalse: 
			[aNumber isInteger
				ifTrue: 
					[osc := 0.
					om := aNumber]].
	om
		ifNotNil: 
			[| sc |
			sc := scale.
			sc == osc ifFalse: [sc > osc ifTrue: [om := om * (10 raisedTo: sc - osc)] ifFalse: [m := m * (10 raisedTo: osc - sc)]].
			^m < om].
	^self retry: #< coercing: aNumber
]

{ #category : 'Comparing' }
ScaledDecimal >> <= aNumber
[

	| osc om m |
	(m := mantissa) ifNil: [^false	"self is a NaN"].
	aNumber _isScaledDecimal
		ifTrue: 
			[osc := aNumber scale.
			om := aNumber mantissa.
			om ifNil: [^false]]
		ifFalse: 
			[aNumber isInteger
				ifTrue: 
					[osc := 0.
					om := aNumber]].
	om
		ifNotNil: 
			[| sc |
			sc := scale.
			sc == osc ifFalse: [sc > osc ifTrue: [om := om * (10 raisedTo: sc - osc)] ifFalse: [m := m * (10 raisedTo: osc - sc)]].
			^m <= om].
	^self retry: #<= coercing: aNumber
]

{ #category : 'Comparing' }
ScaledDecimal >> hash
[
 
^ self asFloat hash
]

{ #category : 'Comparing' }
ScaledDecimal >> >= aNumber
[

	| osc om m |
	(m := mantissa) ifNil: [^false	"self is a NaN"].
	aNumber _isScaledDecimal
		ifTrue: 
			[osc := aNumber scale.
			om := aNumber mantissa.
			om ifNil: [^false]]
		ifFalse: 
			[aNumber isInteger
				ifTrue: 
					[osc := 0.
					om := aNumber]].
	om
		ifNotNil: 
			[| sc |
			sc := scale.
			sc == osc ifFalse: [sc > osc ifTrue: [om := om * (10 raisedTo: sc - osc)] ifFalse: [m := m * (10 raisedTo: osc - sc)]].
			^m >= om].
	^self retry: #>= coercing: aNumber
]

{ #category : 'printing' }
ScaledDecimal >> printOn: aStream
[

	aStream nextPutAll: self asString
]

{ #category : 'Arithmetic' }
ScaledDecimal >> + aNumber
[
	"Answers the sum of the receiver and aNumber.  
   If aNumber is an Integer or a ScaledDecimal, the result will be 
   an instance of the receiver's class with a scale equal to 
   the greater of the receiver's scale and aNumber's scale.
   The scale of an Integer is considered to be zero."

	| m sc |
	aNumber _isScaledDecimal
		ifTrue: 
			[| osc pten |
			osc := aNumber scale.
			scale == osc
				ifTrue: 
					[sc := scale.
					m := mantissa + aNumber mantissa]
				ifFalse: 
					[sc := scale max: osc.
					sc > scale
						ifTrue: 
							[pten := 10 raisedToInteger: sc - scale.
							m := mantissa * pten + aNumber mantissa]
						ifFalse: 
							[pten := 10 raisedToInteger: sc - osc.
							m := mantissa + (pten * aNumber mantissa)]].
			^self class _mantissa: m scale: sc].
	aNumber isInteger
		ifTrue: 
			[m := mantissa + (aNumber * (10 raisedToInteger: scale)).
			^self class _mantissa: m scale: scale].
	^self retry: #+ coercing: aNumber
]

{ #category : 'Arithmetic' }
ScaledDecimal >> * aNumber
[
	"Returns the result of multiplying the receiver by aNumber.
   If aNumber is an Integer or a ScaledDecimal, the result will be 
   an instance of the receiver's class with a scale equal to 
   the greater of the receiver's scale and aNumber's scale.
   The scale of an Integer is considered to be zero."

	| osc om |
	aNumber _isScaledDecimal
		ifTrue: 
			[om := aNumber mantissa.
			osc := aNumber scale]
		ifFalse: 
			[aNumber isInteger
				ifTrue: 
					[om := aNumber.
					osc := 0]].
	om
		ifNotNil: 
			[| m pten resultScale excessScale |
			m := mantissa * om.
			resultScale := scale max: osc.
			excessScale := scale + osc - resultScale.
			excessScale > 0
				ifTrue: 
					["reduce mantissa to match result scale"
					pten := 10 raisedTo: excessScale.
					m := (m / pten) roundedHalfToEven].
			^self class _mantissa: m scale: resultScale].
	^self retry: #* coercing: aNumber
]

{ #category : 'Arithmetic' }
ScaledDecimal >> negated
[
  "Returns 0 minus self. Result has same scale as receiver. "
^ self class _mantissa: 0 - mantissa scale: scale
]

{ #category : 'Arithmetic' }
ScaledDecimal >> / aNumber
[
	"Returns the result of dividing the receiver by aNumber.
   If aNumber is an Integer or a ScaledDecimal, the result will be 
   an instance of the receiver's class with a scale equal to 
   receiver's scale."

	| numberScale numberMantissa |
	aNumber _isScaledDecimal
		ifTrue: 
			[numberMantissa := aNumber mantissa.
			numberScale := aNumber scale]
		ifFalse: 
			[aNumber isInteger
				ifTrue: 
					[numberMantissa := aNumber.
					numberScale := 0]].
	numberMantissa
		ifNotNil: 
			[| resultScale adjustFactor m |
			numberMantissa == 0 ifTrue: [^self gbsMessenger raise: ZeroDivide].
			resultScale := scale max: numberScale.
			adjustFactor := 10 raisedToInteger: numberScale - scale + resultScale.
			m := (mantissa / numberMantissa * adjustFactor) roundedHalfToEven.
			^self class _mantissa: m scale: resultScale].
	^self retry: #/ coercing: aNumber
]

{ #category : 'Arithmetic' }
ScaledDecimal >> - aNumber
[
  "Returns the difference between the receiver and aNumber.
   If aNumber is an Integer or a ScaledDecimal, the result will be 
   an instance of the receiver's class with a scale equal to 
   receiver's scale." 

aNumber _isScaledDecimal ifTrue:[ 
  ^ self + ( ScaledDecimal _mantissa: 0 - (aNumber mantissa) 
				scale: aNumber scale )
].
^ self + (0 - aNumber)
]

{ #category : 'Formatting' }
ScaledDecimal >> asString
[

	| string neg |
	string := mantissa abs printString asOrderedCollection.
	neg := self mantissa negative.
	scale > string size ifTrue: [scale - string size timesRepeat: [string add: $0 beforeIndex: 1]].
	string add: $. beforeIndex: string size - scale + 1.
	string first = $. ifTrue: [string add: $0 beforeIndex: 1].
	neg ifTrue: [string add: $- beforeIndex: 1].
	^String fromIntegerArray: (string asArray collect: [:ea | ea asInteger])
]

{ #category : 'coercing' }
ScaledDecimal >> generality
[
	"Returns an Integer representing the ordering of the receiver in
 the generality hierarchy. Per ANSI, ScaledDecimal is between Integers and Fractions in generality."

	^50
]

{ #category : 'Truncation and Rounding' }
ScaledDecimal >> fractionPart
[
	"Returns the fraction remaining after the receiver is truncated toward zero."

	^self - self truncated
]

{ #category : 'Truncation and Rounding' }
ScaledDecimal >> floor
[
	"Returns the integer that is closest to the receiver, on the same side
 of the receiver as negative infinity."

	^mantissa // (10 raisedTo: scale)
]

{ #category : 'Truncation and Rounding' }
ScaledDecimal >> truncated
[
	"Returns the integer that is closest to the receiver, on the same side
 of the receiver as zero is located."

	| f |
	f := self floor.
	(mantissa < 0 and: [f ~= self]) ifTrue: [f := f + 1].
	^f
]

{ #category : 'Truncation and Rounding' }
ScaledDecimal >> roundTo: aNumber
[
	"Returns the multiple of aNumber that is nearest in value to the receiver. If the receiver is equally near to two multiples of aNumber, answer the even multiple."

	| n r sg og |
	aNumber = 0 ifTrue: [^0].
	n := (self / aNumber) roundedHalfToEven * aNumber.
	sg := self generality.
	og := aNumber generality.
	og < sg
		ifTrue: [r := n asScaledDecimal: scale]
		ifFalse: 
			[og > sg
				ifTrue: [r := n]
				ifFalse: 
					["both scaled decimals"
					scale > aNumber scale ifTrue: [r := n asScaledDecimal: scale] ifFalse: [r := n]]].
	^r
]

{ #category : 'Truncation and Rounding' }
ScaledDecimal >> integerPart
[

	^self class for: self truncated scale: scale
]

{ #category : 'gemstone private' }
ScaledDecimal >> gbxIsServerSpecialInSession: aSession
[

	^aSession isSpecialScaledDecimal: self.
]

{ #category : 'Testing' }
ScaledDecimal >> isZero
[
	"Returns true if the receiver is zero."

	^mantissa == 0
]

{ #category : 'Testing' }
ScaledDecimal >> odd
[
	"(R) Returns true if the receiver is an odd integer, false otherwise."

	scale == 0 ifTrue: [^mantissa odd].
	^(mantissa // (10 raisedTo: scale)) odd
]

{ #category : 'Testing' }
ScaledDecimal >> even
[
	"(R) Returns true if the receiver is an even integer, false otherwise."

	scale == 0 ifTrue: [^mantissa even].
	^(mantissa // (10 raisedTo: scale)) even
]

{ #category : 'Testing' }
ScaledDecimal >> _isScaledDecimal
[

	^true
]

{ #category : 'Compatibility' }
ScaledDecimal >> withScale: newScale
[
	"Returns a new instance with the new scale, and a numeric value 
 as close to that of the receiver as possible."

	^self asScaledDecimal: newScale
]

{ #category : 'Compatibility' }
ScaledDecimal >> denominator
[
  ^ self asFraction denominator
]

{ #category : 'Compatibility' }
ScaledDecimal >> numerator
[
  ^ self asFraction numerator
]

{ #category : 'Private' }
ScaledDecimal >> _mantissa: m scale: s
[

	m isInteger
		ifFalse: [self gbsMessenger raise: ArgumentTypeError message: 'Integer mantissa required'].
	s isInteger
		ifFalse: [self gbsMessenger raise: ArgumentTypeError message: 'Integer scale required'].
	s > MaxScale
		ifTrue: 
			[self gbsMessenger raise: OutOfRange message: 'scale must be <= 30000'].
	s < 0
		ifTrue: [self gbsMessenger raise: OutOfRange message: ' scale must be >= 0'].
	mantissa := m.
	scale := s
]

{ #category : 'Accessing' }
ScaledDecimal >> mantissa
[

	^mantissa
]

{ #category : 'Accessing' }
ScaledDecimal >> scale
[

	^scale
]

{ #category : 'Instance Creation' }
ScaledDecimal class >> fromString: aString
[
	"Given aString, parses the string as a ScaledDecimal, if possible, and answers the resulting ScaledDecimal."

	^GbxScaledDecimalParser parse: aString
]

{ #category : 'Instance Creation' }
ScaledDecimal class >> for: aNumber scale: s
[
	"Returns an instance of the receiver , having value aNumber
 and specified scale."

	| m |
	s isInteger ifFalse: [self gbsMessenger raise: ArgumentTypeError].
	aNumber respondsToArithmetic
		ifFalse: [self gbsMessenger raise: ArgumentTypeError].
	s > MaxScale
		ifTrue: 
			[self gbsMessenger raise: OutOfRange message: 'scale must be <= 30000'].
	m := (aNumber * (10 raisedTo: s)) roundedHalfToEven.
	^self _mantissa: m scale: s
]

{ #category : 'Compatibility' }
ScaledDecimal class >> numerator: numer denominator: denom scale: scale
[
	"Returns an instance of GbxScaledDecimal.
 Generates a RangeError the argument scale > 30000.  "

	| n d m |
	denom = 0 ifTrue: [^ZeroDivide raise].
	scale isInteger ifFalse: [self gbsMessenger raise: ArgumentTypeError message: 'Integer scale required'].
	(numer respondsToArithmetic and: [denom respondsToArithmetic])
		ifFalse: [self gbsMessenger raise: ArgumentTypeError message: 'Numeric numerator and denominator required'].
	(scale < 0 or: [scale > MaxScale])
		ifTrue: [self gbsMessenger raise: OutOfRange message: 'scale must be <= 30000'].
	n := numer.
	d := denom.
	d < 0
		ifTrue: 
			[d := 0 - d.
			n := 0 - n].
	m := (n * (10 raisedToInteger: scale) / d) roundedHalfToEven.
	^self _mantissa: m scale: scale
]

{ #category : 'GBS private' }
ScaledDecimal class >> gbsReplicatorClass
[

	^GemStone.Gbs.GbxPointerMagnitudeReplicator
]

{ #category : 'private' }
ScaledDecimal class >> _mantissa: m scale: s
[

	| inst |
	inst := self basicNew _mantissa: m scale: s.
	inst isImmutable: true.
	^inst
]

{ #category : 'private' }
ScaledDecimal class >> new
[

	self shouldNotImplement.
	^nil
]

