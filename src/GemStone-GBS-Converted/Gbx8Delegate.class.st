Class {
	#name : 'Gbx8Delegate',
	#superclass : 'GbxDelegate',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
Gbx8Delegate >> isEightByte
[
	^true
]

{ #category : 'public - object management' }
Gbx8Delegate >> createObjectClass: oClass values: values clusterBucket: clusterBucket permanent: aBool
[
	"Creates a new object using a GemStone object identifier previously obtained from getFreeOop(s:).  See comment for GbsSession>>getFreeOops: for a further discussion of semantics of such identifiers.

	Arguments:
		oClass - a GbsObject representing the class of the new object
		values - a Smalltalk byte object or an array of GbsObjects
		clusterBucket - a SmallInteger representing the cluster bucket in which to place the object
		makePermanent - if true, allows bypassing of garbage collector

	If oClass is an indexable or Nsc class, then values may be as large or as small as desired.  If oClass is not indexable nor Nsc, then it is an error if values is larger than the number of named instance variables.  For certain classes of byte format, namely DateTime, Float, LargePositiveInteger, and LargeNegativeInteger, additional size restrictions apply.

	If oClass is a GemStone byte-type class, values must be a Smalltalk byte-type object.  Otherwise, values must be a Smalltalk array of GbsObjects.

	Values are stored into the object starting at the first named instance variable (if any) and continuing to the indexable (or Nsc) instance variables if oclass is indexable (or nsc).

	 For pointer type values, values may be forward references to objects whose identifier has been allocated with getFreeOops, but for which the object has not yet been created with createObject.

	If oClass defines indexable objects, the values array may be larger than the number of named instance variables.  If values is smaller than the number of named instance variables, then the objects size will be equal to the number of named instance variables, and any instance variables beyond the size of the values array will be initialized to NIL.

	If makePermanent is true, the object is created as a permanent object, thus providing a performance gain by bypassing the garbage collector.  Otherwise, the object is created in temporary object space, and the garbage collecter will make it permanent only if the object is or becomes referenced by another permanent object."
	
	self gbsMessenger error:
			'GbxDelegate>>#createObjectClass:values:clusterBucket:permanent: not supported for this type of server'
]

{ #category : 'public - object management' }
Gbx8Delegate >> createObjectClass: oClass values: values
[
	"Creates a new object using a GemStone object identifier previously obtained from getFreeOop(s:).  
	Uses the default clusterBucket, and creates the object in temporary space.  See comment in 
	createObjectClass:values:clusterBucket:permanent: for additional information."
	
	self gbsMessenger error:
			'GbxDelegate>>#createObjectClass:values: not supported for this type of server'
]

{ #category : 'GBS private - binary access' }
Gbx8Delegate >> oopSecondUnsignedLongPut: aSmallInteger
[
	"Used only in 64-bit VW. Replace bytes 9-12 of myself (which is the low-order half of the 
	oop in a B8Delegate, the high-order half of the oop in an L8Delegate) with the given SmallInteger.
	For this to work as expected, the receiver must be of the endianness of the machine."

	self primUnsignedLongAt: 9 put: aSmallInteger
]

{ #category : 'GBS private - binary access' }
Gbx8Delegate >> oopSecondUnsignedLong
[
	"Used only in 64-bit VW. Answer a SmallInteger representing bytes 9 - 12 of myself 
	(which is the low-order half of the oop in a B8Delegate, the high-order half of the 
	oop in an L8Delegate).
	For this to work as expected, the receiver must be of the endianness of the machine."

	^self primUnsignedLongAt: 9
]

{ #category : 'GBS private - binary access' }
Gbx8Delegate >> copyOopTo: delegate
[
	"Copy my oop bytes to the given delegate.  The number
	 of bytes in the oop of the receiver must match the number of bytes in delegate.
	 The endian-ness also must match.

	Note that this creates a non-canonical delegate -- it should be used only in special
	circumstances, like converting a SmallInteger or SmallDouble delegate (rare) to a client
	SmallInteger or SmallDouble.

	Note that this method relies on the internal structure of both itself and of the delegate.
	These low-level memory access routines are executed very frequently, so this tradeoff
	for speed over good separation of concerns is intentional."

	delegate gbxReplaceBytesFrom: 5 to: 12 with: self startingAt: 5
]

{ #category : 'GBS private - binary access' }
Gbx8Delegate >> oopFirstUnsignedLongPut: aSmallInteger
[
	"Used only in 64-bit VW. Replace bytes 5 - 8 of myself (which is the high-order half of the 
	oop in a B8Delegate, the low-order half of the oop in an L8Delegate) with the given SmallInteger.
	For this to work as expected, the receiver must be of the endianness of the machine."

	self primUnsignedLongAt: 5 put: aSmallInteger
]

{ #category : 'GBS private - binary access' }
Gbx8Delegate >> oopFirstUnsignedLong
[
	"Used only in 64-bit VW. Answer a SmallInteger representing bytes 5 - 8 of myself 
	(which is the high-order half of the oop in a B8Delegate, the low-order half of the 
	oop in an L8Delegate).
	For this to work as expected, the receiver must be of the endianness of the machine."

	^self primUnsignedLongAt: 5
]

{ #category : 'GBS private - binary access' }
Gbx8Delegate >> primUnsignedLongAt: index put: aSmallInteger
[
	<primitive: 545>

	^self primitiveFailed
]

{ #category : 'GBS private - binary access' }
Gbx8Delegate >> primUnsignedLongAt: index
[
	<primitive: 544>

	^self primitiveFailed
]

{ #category : 'private - testing' }
Gbx8Delegate >> serverCanAcceptClassChanges
[
	"The 64-bit 3.2 (and later) server can change the class of a server object through store traversal."
	"Eight-byte delegates are from a 64-bit server. GBS no longer supports any 64-bit server older than
	3.2, so we can just answer true here."

	^true
]

