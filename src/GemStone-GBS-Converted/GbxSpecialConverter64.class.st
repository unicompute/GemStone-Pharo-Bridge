Class {
	#name : #'GbxSpecialConverter64',
	#superclass : #'GbxSpecialConverter',
	#instVars : [ #'supportsImmediateTimes' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'testing' }
GbxSpecialConverter64 >> isSpecialOop: anOop 
	"Answer true if delegate represents a server special object
	(SmallInteger, SmallDouble, nil, true, false, Character, JISCharacter, SmallFraction, more)"

	^((anOop oopByteAt: 8) bitAnd: 2r00000110) ~~ 0

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> isSpecialCharacter: aCharacter
	"Answer whether aCharacter fits in the Unicode range. (code points up to 16r10ffff)"

	^aCharacter asInteger <= 16r10FFFF.

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> isSpecialDate: aDate
	"Answer whether the server supports SmallDate.
	 If aDate is not in the range representable on the server, answer false.
	 Note: this duplicates logic in delegateForSpecialDate:forSession: since two return values is problematic."

	^supportsImmediateTimes and:
		[[self normalizeDate: aDate.
		true]
			on: GemStone.Gbs.Exceptions.OutOfRange
			do: [:ex | ex return: false]]

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> delegateClass
	^self isBigEndian ifTrue: [GbxB8Delegate] ifFalse: [GbxL8Delegate]

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> delegateForCharacter: aCharacter forSession: aSession
	"Characters can have a code point of up to 16r10ffff, so may take as many as three bytes."

	| del int |
	del := GbxDelegate forSession: aSession.
	int := aCharacter asInteger.
	"16r1c is the Character tag."
	^del
		oopByteAt: 8 put: 2r00011100;
		oopByteAt: 7 put: (int bitAnd: 16rFF);
		oopByteAt: 6 put: ((int bitShift: -8) bitAnd: 16rFF);
		oopByteAt: 5 put: (int bitShift: -16);
		yourself

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> oopNumberForOop: oop 
	^oop bitShift: -8

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> isSpecialDouble: aDouble session: aSession
	"Answer whether aDouble is in the range for server SmallDoubles.
	 For something that is rarely used, duplicating the complicated code
	 in the delegate creation method is undesirable. Answer whether
	 we can *create* a delegate for a special double.
	Sender must hold sessionProtect"

	^(self delegateForSpecialDouble: aDouble forSession: aSession) notNil.

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> delegateForSpecialDate: aDate forSession: aSession
	"If aDate is not in the range representable on the server,
	will error. If the server does not support SmallDate, will answer nil.
	Otherwise, will answer a delegate for a SmallDate immediate oop.
	Note: this duplicates logic in #isSpecialDate: because two return values is problematic."

	| normalizedDate year day delegate |
	normalizedDate := self normalizeDate: aDate.
	supportsImmediateTimes ifFalse: [^nil].

	"Note that delegates for server immediates are not cached, and therefore are not canonical."
	year := normalizedDate year.
	day := normalizedDate day.
	delegate := GbxDelegate forSession: aSession.
	delegate oopByteAt: 8 put: 2r01001100.
	delegate oopByteAt: 7 put: (day bitAnd: 16rFF).
	day := day bitShift: -8.
	year := year bitShift: 1.
	delegate oopByteAt: 6 put: (year bitAnd: 16rFE) + day.
	year := year bitShift: -8.
	delegate oopByteAt: 5 put: (year bitAnd: 16rFF).
	year := year bitShift: -8.
	delegate oopByteAt: 4 put: (year bitAnd: 16rFF).
	year := year bitShift: -8.
	delegate oopByteAt: 3 put: (year bitAnd: 16rFF).
	year := year bitShift: -8.
	delegate oopByteAt: 2 put: (year bitAnd: 16rFF).
	year := year bitShift: -8.
	delegate oopByteAt: 1 put: (year bitAnd: 16rFF).
	"This final bitAnd: is necessary for negative numbers, to eliminate the sign."
	aDate gbxIsImmutable: true.
	^delegate

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> isSpecialFractionNumerator: numerator denominator: denominator
	"Answer whether a Fraction's numerator and denominator are in the range for server SmallFractions.
	 Ordinarily, one would expect the denominator to be > 1, but it is possible
	 to legally construct them with a denominator of 1. Even with a 0 denominator,
	 if one hacks with private selectors."

	^(numerator between: -16r10000000 and: 16rFFFFFFF)
		and: [denominator between: 0 and: 16r7FFFFFF].

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> isSpecialFraction: aFraction
	"Answer whether aFraction is in the range for server SmallFractions."

	^self isSpecialFractionNumerator: aFraction numerator denominator: aFraction denominator

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> isSpecialScaledDecimalMantissa: mantissa scale: scale
	"Answer whether a ScaledDecimal's mantissa and scale are in the range for server SmallScaledDecimals."

	^supportsImmediateTimes
		and: [(mantissa between: -16r4000000000000 and: 16r3FFFFFFFFFFFF)
		and: [scale between: 0 and: 16r1F]].

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> traversalBufferClass
	"Overridden for 8-byte oops"

	^GbxTraversalBuffer6432

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> delegateForSpecialFraction: aFraction forSession: aSession 
	"Answer nil if aFraction is not in the range for server SmallFractions. 
	 Otherwise, answer an existing or new delegate representing the server SmallFraction.
	 (Refer to the comment in #localFromSmallFractionOop: for details.)"

	| numerator denominator delegate |
	(self isSpecialFractionNumerator: (numerator := aFraction numerator) denominator: (denominator := aFraction denominator))
		ifFalse: [^nil].

	"Note that delegates for server specials are not cached, and therefore are not canonical."
	delegate := GbxDelegate forSession: aSession.
	delegate
		oopByteAt: 8
		put: 2r00101100.
	delegate
		oopByteAt: 7
		put: (denominator bitAnd: 16rFF).
	denominator := denominator bitShift: -8.
	delegate
		oopByteAt: 6
		put: (denominator bitAnd: 16rFF).
	denominator := denominator bitShift: -8.
	delegate
		oopByteAt: 5
		put: (denominator bitAnd: 16rFF).
	denominator := denominator bitShift: -8.
	"The denominator must now be three bits or less."
	delegate
		oopByteAt: 4
		put: (numerator bitAnd: 16r1F) * 2r00001000 + denominator.
	numerator := numerator bitShift: -5.
	delegate
		oopByteAt: 3
		put: (numerator bitAnd: 16rFF).
	numerator := numerator bitShift: -8.
	delegate
		oopByteAt: 2
		put: (numerator bitAnd: 16rFF).
	numerator := numerator bitShift: -8.
	delegate
		oopByteAt: 1
		put: (numerator bitAnd: 16rFF).	"This final bitAnd: is necessary for negative numbers, to eliminate the sign."
	^delegate

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> isSpecialScaledDecimal: aScaledDecimal
	"Answer whether aScaledDecimal is in the range for server SmallScaledDecimals."

	^self isSpecialScaledDecimalMantissa: aScaledDecimal mantissa scale: aScaledDecimal scale.

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> delegateForSpecialInteger: anInteger forSession: aSession
	"Answer a delegate for a server SmallInteger equivalent to anInteger, or nil if anInteger is out of range.

	Note that delegates for server specials are not cached, and therefore are not canonical."

	| del int |
	^(self isSpecialInteger: anInteger)
		ifFalse: [nil]
		ifTrue: 
			[del := GbxDelegate forSession: aSession.
			int := anInteger.
			del oopByteAt: 8 put: (int bitAnd: 16r1F) * 8 + 2r010.
			int := int bitShift: -5.
			del oopByteAt: 7 put: (int bitAnd: 16rFF).
			int := int bitShift: -8.
			del oopByteAt: 6 put: (int bitAnd: 16rFF).
			int := int bitShift: -8.
			del oopByteAt: 5 put: (int bitAnd: 16rFF).
			int := int bitShift: -8.
			del oopByteAt: 4 put: (int bitAnd: 16rFF).
			int := int bitShift: -8.
			del oopByteAt: 3 put: (int bitAnd: 16rFF).
			int := int bitShift: -8.
			del oopByteAt: 2 put: (int bitAnd: 16rFF).
			int := int bitShift: -8.
			del oopByteAt: 1 put: (int bitAnd: 16rFF).
			del]	"Final bitAnd: is necessary for negative numbers."

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> delegateForSpecialScaledDecimal: aScaledDecimal forSession: aSession
	"Answer nil if aScaledDecimal is not in the range for server SmallScaledDecimals. 
	 Otherwise, answer an existing or new delegate representing the server SmallScaledDecimal.
	 (Refer to the comment in #localFromSmallScaledDecimalOop: for details.)"

	| mantissa scale delegate |
	(self isSpecialScaledDecimalMantissa: (mantissa := aScaledDecimal mantissa) scale: (scale := aScaledDecimal scale))
		ifFalse: [^nil].

	"Note that delegates for server immediates are not cached, and therefore are not canonical."
	delegate := GbxDelegate forSession: aSession.
	delegate oopByteAt: 8 put: 2r00110100.
	delegate oopByteAt: 7 put: ((mantissa bitAnd: 16r7) bitShift: 5) + scale.
	mantissa := mantissa bitShift: -3.
	delegate oopByteAt: 6 put: (mantissa bitAnd: 16rFF).
	mantissa := mantissa bitShift: -8.
	delegate oopByteAt: 5 put: (mantissa bitAnd: 16rFF).
	mantissa := mantissa bitShift: -8.
	delegate oopByteAt: 4 put: (mantissa bitAnd: 16rFF).
	mantissa := mantissa bitShift: -8.
	delegate oopByteAt: 3 put: (mantissa bitAnd: 16rFF).
	mantissa := mantissa bitShift: -8.
	delegate oopByteAt: 2 put: (mantissa bitAnd: 16rFF).
	mantissa := mantissa bitShift: -8.
	delegate oopByteAt: 1 put: (mantissa bitAnd: 16rFF).
	"This final bitAnd: is necessary for negative numbers, to eliminate the sign."
	^delegate

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> isSpecialTime: aTime
	"Answser whether the server supports SmallTime."

	^supportsImmediateTimes

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> oopArrayClass
	
	^self isBigEndian
		ifTrue: [GbxB8OopArray]
		ifFalse: [GbxL8OopArray]

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> delegateForSpecialTime: aTime forSession: aSession
	"If the server does not support SmallTime, will answer nil.
	Otherwise, will answer a delegate for a SmallTime immediate oop,
	and set aTime to be immutable on the client."

	| microseconds delegate |
	(self isSpecialTime: aTime) ifFalse: [^nil].
	microseconds := self normalizedMicrosecondsForTime: aTime.


	"Note that delegates for server immediates are not cached, and therefore are not canonical."
	delegate := GbxDelegate forSession: aSession.
	delegate oopByteAt: 8 put: 2r01000100.
	delegate oopByteAt: 7 put: (microseconds bitAnd: 16rFF).
	microseconds := microseconds bitShift: -8.
	delegate oopByteAt: 6 put: (microseconds bitAnd: 16rFF).
	microseconds := microseconds bitShift: -8.
	delegate oopByteAt: 5 put: (microseconds bitAnd: 16rFF).
	microseconds := microseconds bitShift: -8.
	delegate oopByteAt: 4 put: (microseconds bitAnd: 16rFF).
	microseconds := microseconds bitShift: -8.
	delegate oopByteAt: 3 put: microseconds.
	"2 and 1 are already zero"
	aTime gbxIsImmutable: true.
	^delegate

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> oopForOopNumber: oopNumber
	
	^oopNumber * 16r100 + 1

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> dictionaryDepth
	"The depth of ObjIdDictionary to create for this kind of server."

	^3

{ #category : #'GBS private - session interface' }
GbxSpecialConverter64 >> bufferOopClass
	"Overridden for 8-byte oops"
	
	^self isBigEndian
		ifTrue: [GbxB8BufferOop]
		ifFalse: [GbxL8BufferOop]

{ #category : #'private - converting' }
GbxSpecialConverter64 >> localFromSmallIntegerOop: delegate
	"Delegate is assumed to represent a server SmallInteger. 
	Answer the local SmallInteger or large integer"
	
	| highByte |
	highByte := delegate oopByteAt: 1.	"If the sign bit is negative, start it with a pre-shifted -1, otherwise with a pre-shifted 0, which is 0"
	^(((((((((highByte bitAnd: 16r80) ~~ 0
		ifTrue: [-16r100]
		ifFalse: [0]) + highByte) * 16r100 + (delegate oopByteAt: 2)) * 16r100
		+ (delegate oopByteAt: 3)) * 16r100 + (delegate oopByteAt: 4)) * 16r100
		+ (delegate oopByteAt: 5)) * 16r100 + (delegate oopByteAt: 6)) * 16r100
		+ (delegate oopByteAt: 7)) * 16r20
		+ ((delegate oopByteAt: 8) bitShift: -3)

{ #category : #'private - converting' }
GbxSpecialConverter64 >> localFromExtendedSpecialOop: delegate
	"Answer the UndefinedObject, Boolean, or Character represented by delegate.
	Delegate is assumed to represent one of these."

	| byte0 |
	byte0 := delegate oopByteAt: 8.
	byte0 == 2r00010100 ifTrue: [^nil].	"2. nil or remoteNil"
	byte0 == 2r00001100 ifTrue: [^(delegate oopByteAt: 7) ~~ 0].	"1. Boolean"
	byte0 == 2r00101100 ifTrue: [^self localFromSmallFractionOop: delegate].	"5. SmallFraction"
	byte0 == 2r00110100 ifTrue: [^self localFromSmallScaledDecimalOop: delegate].	"6. SmallScaledDecimal"
	byte0 == 2r01000100 ifTrue: [^self localFromSmallTimeOop: delegate].	"8. SmallTime"
	byte0 == 2r01001100 ifTrue: [^self localFromSmallDateOop: delegate].	"9. SmallDate"
	(byte0 == 2r00011100 or: [byte0 == 2r00100100]) ifTrue: [^self localFromCharacterOop: delegate].	"3 or 4. Character"
	byte0 == 2r00111100 ifTrue: [^notCachedToken]. "7. SmallDateAndTime, no equivalent client class."
	(byte0 >= 2r01010100 and: [byte0 <= 2r11001100]) ifTrue: [^notCachedToken	"10 -25. Special56bit* classes 0 -15"].
	"26 - 31. 2r11010100 through 2r11111100 reserved for future specials."
	self gbsMessenger error: 'Unrecognized object tag %1' with: byte0	"No idea what it is!"

{ #category : #'private - converting' }
GbxSpecialConverter64 >> localFromCharacterOop: delegate
	"Answer a Character, which can have a code point of up to 16r10ffff."
	
	^Character
		value: (delegate oopByteAt: 7)
				+ ((delegate oopByteAt: 6) * 16r100)
				+ ((delegate oopByteAt: 5) * 16r10000)

{ #category : #'private - converting' }
GbxSpecialConverter64 >> localFromSmallTimeOop: delegate
	"Delegate is assumed to represent a server SmallTime. 
	 Answer the corresponding local Time.

	The bit format of an instance is
	tttttttt|tttttttt|tttttttt|tttttttt|tttttttt |tttttttt|tttttttt| 01000100
	bits t  56 bits unsigned integer , local time since midnight  , units microseconds
	The maximum value of local time is  86399999999 .

	Thus, the upper two bytes will always be zero and can be ignored here."

	| microseconds result |
	microseconds := ((((delegate oopByteAt: 3) * 16r100
				+ (delegate oopByteAt: 4)) * 16r100
				+ (delegate oopByteAt: 5)) * 16r100
				+ (delegate oopByteAt: 6)) * 16r100
				+ (delegate oopByteAt: 7).
	result := Time fromMicroseconds: microseconds.
	result gbxIsImmutable: true.
	"Don't bother marking the delegate read-only.
	Delegates for immediates are not put in the mapping dictionaries,
	so no one can get a reference to this delegate."
	^result

{ #category : #'private - converting' }
GbxSpecialConverter64 >> localFromSmallScaledDecimalOop: delegate
	"Delegate is assumed to represent a server SmallScaledDecimal. 
	 Answer the corresponding local ScaledDecimal.

	SmallScaledDecimal is used to represent ScaledDecimals that have 
	scale <= 31 and mantissa in the range -1125899906842624..1125899906842623 .
 	The bit format of an instances is
   	mmmmmmmm|mmmmmmmm|mmmmmmmm|mmmmmmmm|mmmmmmmm|mmmmmmmm|mmmsssss|00110100
    	bits m 51 bit signed integer mantissa
	s 5 bit unsigned scale."

	| highByte lowByte mantissa |
	highByte := delegate oopByteAt: 1.	"If the sign bit is negative, start it with a pre-shifted -1, otherwise with a pre-shifted 0, which is 0"
	lowByte := delegate oopByteAt: 7.
	mantissa := ((((((((highByte bitAnd: 16r80) ~~ 0
				ifTrue: [-16r100]
				ifFalse: [0]) + highByte)
				* 16r100 + (delegate oopByteAt: 2))
				* 16r100 + (delegate oopByteAt: 3))
				* 16r100 + (delegate oopByteAt: 4))
				* 16r100 + (delegate oopByteAt: 5))
				* 16r100 + (delegate oopByteAt: 6))
				* 16r8 + (lowByte bitShift: -5).
	^ScaledDecimal _mantissa: mantissa scale: (lowByte bitAnd: 16r1F)

{ #category : #'private - converting' }
GbxSpecialConverter64 >> localFromSmallFractionOop: delegate
	"Delegate is assumed to represent a server SmallFraction. 
	 Answer the corresponding local Fraction.

	 SmallFractions are special objects that can represent Fractions
	 with -268435456 <= numerator <= 268435455
	 and 0 < denominator <= 134217727.

	 A SmallFraction contains the bits
		snnnnnnn|nnnnnnnn|nnnnnnnn|nnnnnddd|dddddddd|dddddddd|dddddddd|tttttttt
	 where bits are shown with least-significant on the right.
	 The bits sn...n are a 29 bit signed twos-complement numerator,
	 The bits d...d are a 27 bit unsigned denominator.
	 The 8 tag bits have the constant value 16r2C."

	| highByte midByte numerator denominator |
	highByte := delegate oopByteAt: 1.	"If the sign bit is negative, start it with a pre-shifted -1, otherwise with a pre-shifted 0, which is 0"
	midByte := delegate oopByteAt: 4.	"Contains 5 low-order bits of the numerator and 3 high-order bits of the denominator"
	numerator := (((((highByte bitAnd: 16r80) ~~ 0
				ifTrue: [-16r100]
				ifFalse: [0]) + highByte)
				* 16r100 + (delegate oopByteAt: 2))
				* 16r100 + (delegate oopByteAt: 3))
				* 2r00100000 + (midByte bitShift: -3).
	denominator := (((midByte bitAnd: 16r07) * 16r100
				+ (delegate oopByteAt: 5)) * 16r100
				+ (delegate oopByteAt: 6)) * 16r100
				+ (delegate oopByteAt: 7).
	^numerator / denominator

{ #category : #'private - converting' }
GbxSpecialConverter64 >> localFromSmallDateOop: delegate
	"Delegate is assumed to represent a server SmallDate. 
	 Answer the corresponding local Date.

	SmallDate represents instances of Date with year representable in 47 bits
	The bit format of an instance is
	yyyyyyyy|yyyyyyyy|yyyyyyyy|yyyyyyyy|yyyyyyyy|yyyyyyyd|dddddddd|01001100
	bits d 9 bits unsigned integer dayOfYear
	bits y 47 bits signed, holding a 31 bit signed integer year.

	This means that oop byte 1 can be ignored, since it just contains redundant sign bits."

	| highByte splitByte day year result |
	highByte := delegate oopByteAt: 2.	"If the sign bit is negative, start it with a pre-shifted -1, otherwise with a pre-shifted 0, which is 0"
	splitByte := delegate oopByteAt: 6.
	year := ((((highByte ~~ 0 ifTrue: [-16r1] ifFalse: [0]) * 16r100
				+ (delegate oopByteAt: 3)) * 16r100
				+ (delegate oopByteAt: 4)) * 16r100
				+ (delegate oopByteAt: 5)) * 16r80
				+ (splitByte bitShift: -1).
	day := (splitByte bitAnd: 16r1) * 16r100 + (delegate oopByteAt: 7).
	result := Date newDay: day year: year.
	result gbxIsImmutable: true.
	"Don't bother marking the delegate read-only.
	Delegates for immediates are not put in the mapping dictionaries,
	so no one can get a reference to this delegate."
	^result

{ #category : #'private' }
GbxSpecialConverter64 >> oopForFalse
	^2r1100

{ #category : #'private' }
GbxSpecialConverter64 >> oopForTrue
	^2r100001100

{ #category : #'private' }
GbxSpecialConverter64 >> oopForNil
	^2r10100

{ #category : #'private' }
GbxSpecialConverter64 >> normalizedMicrosecondsForTime: aTime
	"aTime is a VW Time, with a precision of nanoseconds, and is unbounded.
	It can be negative or positive beyond 24 hours.
	Server SmallTimes have a precision of microseconds, and are limited to 
	one day of 0 to 86399999999 microseconds (0:0:0 - 23:59:59.999999).
	Round the given Time to the nearest microsecond, rounding half to even, then
	normalize it to be within the server one-day interval."

	| nanoseconds microseconds nanosecondPart |
	nanoseconds := aTime asNanoseconds.
	microseconds := nanoseconds // 1000.
	"nanosecondPart needs to be nonnegative, even if nanoseconds is negative."
	nanosecondPart := nanoseconds \\ 1000.
	(nanosecondPart > 500 or: [nanosecondPart = 500 and: [microseconds odd]])
		ifTrue: [microseconds := microseconds + 1].
	^microseconds \\ 86400000000

{ #category : #'initializing - private' }
GbxSpecialConverter64 >> initialize

	super initialize.
	self initializeSupportedImmediates

{ #category : #'initializing - private' }
GbxSpecialConverter64 >> initializeSupportedImmediates

	supportsImmediateTimes := GbxServerVersion current supportsImmediateTimes

{ #category : #'converting' }
GbxSpecialConverter64 >> localSpecialFromOop: anOop
	"If gsOop represents a GemStone special object (based on oop encoding), 
	return the local equivalent special object.  Otherwise, return NotCachedToken.
	The implementation is overly ornate, but that seems to get the best performance.
	Be sure to test performance before simplifying -- this is executed very frequently.
	Sender must hold sessionProtect."

	| tag3Bits |
	tag3Bits := (anOop oopByteAt: 8) bitAnd: 2r00000111.
	tag3Bits == 2r100 ifTrue: [^self localFromExtendedSpecialOop: anOop].
	tag3Bits == 2r010 ifTrue: [^self localFromSmallIntegerOop: anOop].
	tag3Bits == 2r110 ifTrue: [^self localFromSmallDoubleOop: anOop].
	^notCachedToken	"Not really a special"

