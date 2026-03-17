Class {
	#name : 'GbxSpecialConverter',
	#superclass : 'Object',
	#instVars : [
		'notCachedToken',
		'oopNil',
		'oopTrue',
		'oopFalse',
		'oopIllegal'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbxSpecialConverter >> isSpecialOop: anOop 
	"Answer true if delegate represents a server special object
	(SmallInteger, SmallDouble, nil, true, false, Character, JISCharacter)"

	^self subclassResponsibility

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> isSpecialScaledDecimal: aScaledDecimal
	"Answer whether aScaledDecimal is in the range for server SmallScaledDecimals."

	"GS64 is the only server version with SmallScaledDecimal, so just answer false here."

	^false

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> delegateForSpecialInteger: anInteger forSession: aSession 
	"anInteger is assumed to be in the range for server SmallIntegers."

	self subclassResponsibility

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> delegateForSpecialScaledDecimal: aScaledDecimal forSession: aSession 
	"Answer nil if aScaledDecimal is not in the range for server SmallScaledDecimals. 
	Otherwise, answer an existing or new delegate representing the server SmallScaledDecimal."

	"GS64 is the only server version with SmallScaledDecimal, so just answer nil here."

	^nil

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> isSpecialTime: aTime
	"Answer whether the server supports SmallTime."

	"GS64 is the only server version with SmallScaledDecimal, so just answer false here."

	^false

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> oopArrayClass
	^self subclassResponsibility

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> delegateForSpecialTime: aTime forSession: aSession
	"If the server does not support SmallTime, will answer nil.
	Otherwise, will answer a delegate for a SmallTime immediate oop,
	and set aTime to be immutable on the client."

	^nil

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> oopFalseForSession: aSession 
	oopFalse == nil 
		ifTrue: 
			[oopFalse := (GbxDelegate forSession: aSession) oopValue: self oopForFalse].
	^oopFalse

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> oopForOopNumber: oopNumber 
	"oopNumber is a POM oop number. Convert it to an object id for the current server."

	^self subclassResponsibility

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> dictionaryDepth
	"The depth of ObjIdDictionary to create for this kind of server."

	^2

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> hashForDelegate: aDelegate
	"Sender must hold sessionProtect."

	^((self isSpecialOop: aDelegate)
		ifTrue: [self localSpecialFromOop: aDelegate]
		ifFalse: [self oopNumberForOop: aDelegate oopValue]) hash

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> oopIllegalForSession: aSession 
	oopIllegal == nil 
		ifTrue: [oopIllegal := (GbxDelegate forSession: aSession) oopValue: 1].
	^oopIllegal

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> bufferOopClass
	"Overridden for 8-byte oops"

	^self subclassResponsibility

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> isSpecialCharacter: aCharacter
	"Answer whether aCharacter can be represented on the server."

	^self subclassResponsibility

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> isSpecialDate: aDate
	"Answer whether the server supports SmallDate.
	 Only 3.6 and newer do, so answer false."

	^false

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> oopNilForSession: aSession 
	oopNil == nil 
		ifTrue: 
			[oopNil := (GbxDelegate forSession: aSession) oopValue: self oopForNil].
	^oopNil

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> delegateClass
	"Overridden for 8-byte oops"

	^self subclassResponsibility

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> delegateForCharacter: aCharacter forSession: aSession 
	"aCharacter is assumed to fit in two bytes, since 
	that's all the server supports."

	self subclassResponsibility

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> oopNumberForOop: oop 
	^self subclassResponsibility

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> isSpecialDouble: aDouble session: aSession
	"Answer whether aDouble is in the range for server SmallDoubles."
	"GS64 is the only server version with SmallDoubles, so just answer false here."

	^false

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> oopTrueForSession: aSession 
	oopTrue == nil 
		ifTrue: 
			[oopTrue := (GbxDelegate forSession: aSession) oopValue: self oopForTrue].
	^oopTrue

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> delegateForSpecialDate: aDate forSession: aSession
	"If aDate is not in the range representable on the server,
	will error. If the server does not support SmallDate, will answer nil.
	Otherwise, will answer a delegate for a SmallDate immediate oop."

	self normalizeDate: aDate.
	^nil

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> isSpecialFraction: aFraction
	"Answer whether aFraction is in the range for server SmallFractions."

	"GS64 is the only server version with SmallFraction, so just answer false here."

	^false

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> isSpecialInteger: anInteger
	"Answer whether anInteger is in the range for server SmallIntegers.
	 VW and GS match, as long as their bitness matches."

	^anInteger isMemberOf: SmallInteger

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> traversalBufferClass

	self subclassResponsibility

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> delegateForSpecialDouble: aDouble forSession: aSession 
	"Answer nil if aDouble is not in the range for server SmallDoubles. 
	Otherwise, answer an existing or new delegate representing the server SmallDouble."

	"GS64 is the only server version with SmallDoubles, so 
	just answer nil."

	^nil

{ #category : 'GBS private - session interface' }
GbxSpecialConverter >> delegateForSpecialFraction: aFraction forSession: aSession 
	"Answer nil if aFraction is not in the range for server SmallFractions. 
	Otherwise, answer an existing or new delegate representing the server SmallFraction."

	"GS64 is the only server version with SmallFraction, so just answer nil here."

	^nil

{ #category : 'private - converting' }
GbxSpecialConverter >> localFromSmallIntegerOop: delegate
	"Delegate is assumed to represent a server SmallInteger. 
	Answer the local SmallInteger."

	self subclassResponsibility

{ #category : 'private - converting' }
GbxSpecialConverter >> localFromSmallDoubleOop: delegate
	"Delegate is assumed to represent a server SmallDouble. 
	Answer the local Double."

	self subclassResponsibility

{ #category : 'private' }
GbxSpecialConverter >> oopForTrue
	self subclassResponsibility

{ #category : 'private' }
GbxSpecialConverter >> oopForNil
	self subclassResponsibility

{ #category : 'private' }
GbxSpecialConverter >> normalizeDate: aDate
	"In case aDate has a day that is greater than the number of days in a year, 
	create and answer a new Date, which will normalize it and set the day and year correctly.
	Enforce the server limitation that the year must fit in 32 bits."

	| normalizedDate |
	normalizedDate := Date newDay: aDate day year: aDate year.
	"32-bit signed year is the server limit"
	(normalizedDate year between: -2147483648 and: 2147483647)
		ifFalse: 
			[OutOfRange
				raiseSignal: 'Date not within the range representable on the GemStone server'].
	^normalizedDate

{ #category : 'private' }
GbxSpecialConverter >> oopForFalse
	self subclassResponsibility

{ #category : 'initialize-release' }
GbxSpecialConverter >> initialize
	notCachedToken := NotCachedToken	"It seems deeply wrong to cache the NotCachedToken... but we do it for performance."

{ #category : 'converting' }
GbxSpecialConverter >> localSpecialFromOop: anOop 
	"If gsOop represents a GemStone special object (based on oop encoding), 
	return the local equivalent special object.  Otherwise, return NotCachedToken.
	The implementation is overly ornate, but that seems to get the best performance.
	Be sure to test performance before simplifying -- this is executed very frequently."

	^self subclassResponsibility

{ #category : 'initialize-release' }
GbxSpecialConverter class >> new
	^super new initialize

