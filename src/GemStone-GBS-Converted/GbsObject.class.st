Class {
	#name : 'GbsObject',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'implicit replication' }
GbsObject class >> newFrom: localObject 
[
	"Return a cached delegate representing a server replicate for localObject.  If localObject already has a delegate, that delegate will be returned. If localObject does not have a delegate, one is created. In the latter case, the server replicate is not created immediately. It will be created at the next flush."

	GbsConfiguration 
		deprecated: 'GbsObject class>>newFrom: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	^localObject asGSObject
]

{ #category : 'explicit replication' }
GbsObject class >> fromCharacter: aCharacter 
[
	GbsConfiguration 
		deprecated: 'GbsObject class>>fromCharacter: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	(GbsError verify: aCharacter is: Character) 
		ifTrue: [^aCharacter asGSObject]
]

{ #category : 'explicit replication' }
GbsObject class >> fromFloat: aFloat 
[
	"Returns a delegate representing the GemStone replicate for aFloat in the current session.  For more explicit session control."

	GbsConfiguration 
		deprecated: 'GbsObject class>>fromFloat: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	(GbsError verify: aFloat is: LimitedPrecisionReal) 
		ifTrue: [^aFloat asGSObject]
]

{ #category : 'explicit replication' }
GbsObject class >> fromString: aString 
[
	GbsConfiguration 
		deprecated: 'GbsObject class>>fromString: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	(GbsError verify: aString is: String) ifTrue: [^aString asGSObject]
]

{ #category : 'explicit replication' }
GbsObject class >> fromFraction: aFraction 
[
	GbsConfiguration 
		deprecated: 'GbsObject class>>fromFraction: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	(GbsError verify: aFraction is: Fraction) ifTrue: [^aFraction asGSObject]
]

{ #category : 'explicit replication' }
GbsObject class >> fromInteger: anInt 
[
	GbsConfiguration 
		deprecated: 'GbsObject class>>fromInteger: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	(GbsError verify: anInt is: Integer) ifTrue: [^anInt asGSObject]
]

{ #category : 'explicit replication' }
GbsObject class >> fromLargeNegativeInteger: lni 
[
	GbsConfiguration 
		deprecated: 'GbsObject class>>fromLargeNegativeInteger: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	(GbsError verify: lni is: LargeNegativeInteger) ifTrue: [^lni asGSObject]
]

{ #category : 'explicit replication' }
GbsObject class >> fromNumber: aNumber 
[
	GbsConfiguration 
		deprecated: 'GbsObject class>>fromNumber: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	(GbsError verify: aNumber is: Number) ifTrue: [^aNumber asGSObject]
]

{ #category : 'explicit replication' }
GbsObject class >> fromLargePositiveInteger: lpi 
[
	GbsConfiguration 
		deprecated: 'GbsObject class>>fromLargePositiveInteger: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	(GbsError verify: lpi is: LargePositiveInteger) ifTrue: [^lpi asGSObject]
]

{ #category : 'explicit replication' }
GbsObject class >> fromSymbol: aSymbol 
[
	^self fromSymbol: aSymbol session: GBSM currentSession
]

{ #category : 'explicit replication' }
GbsObject class >> fromSymbol: aSymbol session: aGbsSession 
[
	GbsConfiguration 
		deprecated: 'GbsObject class>>fromSymbol:session: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	(GbsError verify: aSymbol is: Symbol) 
		ifTrue: [^aSymbol asGSObjectInSession: aGbsSession]
]

{ #category : 'explicit replication' }
GbsObject class >> fromUndefinedObject: anUndefinedObject 
[
	GbsConfiguration 
		deprecated: 'GbsObject class>>fromUndefinedObject: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	(GbsError verify: anUndefinedObject is: UndefinedObject) 
		ifTrue: [^anUndefinedObject asGSObject]
]

{ #category : 'explicit replication' }
GbsObject class >> newObjects: classArray withIdxSizes: sizeArray 
[
	"Returns an array of delegates for server Objects in the current session.  For more explicit session control, use GbsSession>>newObjects:withIdxSizes:.  The size of the resulting array is the same size as classArray and sizeArray.  The nth element of the result will be a GemStoneObject for a new instance of class classArray[n], with an indexable size of sizeArray[n]."

	GbsConfiguration 
		deprecated: 'GbsObject class>>newObjects:withIdxSizes: deprecated March, 2006. If you must use this message, send it to a GbsSession instead, but creation of objects using normal replication or server Smalltalk execution is preferred.'.
	^GBSM currentSession newObjects: classArray withIdxSizes: sizeArray
]

{ #category : 'explicit replication' }
GbsObject class >> fromBoolean: aBoolean 
[
	GbsConfiguration 
		deprecated: 'GbsObject class>>fromBoolean: deprecated March, 2006. Send #asGSObjectInSession: instead.'.
	(GbsError verify: aBoolean is: Boolean) ifTrue: [^aBoolean asGSObject]
]

{ #category : 'explicit replication' }
GbsObject class >> newOfClass: aGemStoneClass 
[
	"Returns a delegate for a new server object of the given class in the current session.  For more explicit session control, use GbsSession class>>newObjectOfClass:"

	GbsConfiguration 
		deprecated: 'GbsObject class>>newOfClass: deprecated March, 2006. If you must, send #newObjectOfClass: to a GbsSession instead, but creation of objects using normal replication or server Smalltalk execution is preferred.'.
	^GBSM currentSession newObjectOfClass: aGemStoneClass
]

{ #category : 'variable access' }
GbsObject class >> specialNamed: aSymbol 
[
	GbsConfiguration 
		deprecated: 'GbsObject class>>specialNamed: deprecated March, 2006. If you must access these variables, access them directly in your code.'.
	^SpecialGemStoneObjects at: aSymbol
]

{ #category : 'object management' }
GbsObject class >> getFreeOop
[
	"Allocates a GemStone object identifier without creating an object, and returns this as a delegate.  See the comment for GbsSession>>getFreeOops: for more information."

	GbsConfiguration 
		deprecated: 'Delegate class>>getFreeOop deprecated March, 2006. Instead, create server objects through replication or server Smalltalk execution.'.
	^GBSM currentSession getFreeOop
]

