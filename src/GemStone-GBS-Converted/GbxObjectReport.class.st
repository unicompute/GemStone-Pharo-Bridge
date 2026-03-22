Class {
	#name : 'GbxObjectReport',
	#superclass : 'Object',
	#instVars : [
		'bufferBytes',
		'bytesBuffer',
		'data',
		'firstOffset',
		'fixedSize',
		'indexedSize',
		'namedSize',
		'objClass',
		'objId',
		'objImpl',
		'offset',
		'oopsBuffer',
		'segment',
		'session',
		'valueBuffSize'
	],
	#classInstVars : [
		'fixedSize'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxObjectReport class >> computeFixedSize
[
	"Cache the size of the appropriate C structure for faster lookup later."

	fixedSize == nil
		ifTrue: 
			[| primInterface struct |
			primInterface := GbxGciCallSequencer primInterface.
			((primInterface notNil) and: [primInterface respondsTo: self structMessage])
				ifTrue: 
					[struct := primInterface perform: self structMessage.
					((struct notNil) and: [struct respondsTo: #sizeof])
						ifTrue: [fixedSize := struct sizeof]].
			fixedSize ifNil: [fixedSize := 40]].
	^fixedSize
]

{ #category : 'accessing' }
GbxObjectReport class >> sizeOfOopType
[

	| primInterface struct |
	primInterface := GbxGciCallSequencer primInterface.
	((primInterface notNil) and: [primInterface respondsTo: #OopType])
		ifTrue: 
			[struct := primInterface perform: #OopType.
			((struct notNil) and: [struct respondsTo: #sizeof])
				ifTrue: [^struct sizeof]].
	^8
]

{ #category : 'accessing' }
GbxObjectReport class >> fixedSize
[
	"Return the size in bytes of the structure."

	^self computeFixedSize
]

{ #category : 'accessing' }
GbxObjectReport class >> structMessage
[
	"Return the primitive-interface selector that describes the object-report header."

	^#GciObjRepHdrSType
]

{ #category : 'instance creation' }
GbxObjectReport class >> session: aGbsSession
[
	"Return a new instance that knows what session it accesses."

	| inst |
	inst := self basicNew.
	inst session: aGbsSession.
	inst offset: 1.
	^inst
]

{ #category : 'GemStone extensions' }
GbxObjectReport >> namedSize
[

	^self subclassResponsibility
]

{ #category : 'testing' }
GbxObjectReport >> containsAllValues
[
	"Answer true iff I contain all of the values for the object I describe."

	^self firstOffset = 1 and: [self containsHighestObjectIndex]
]

{ #category : 'testing' }
GbxObjectReport >> isHeaderOnly
[
	"Header-only reports have no value buffer and are clamped."

	^self valueBuffSize = 0 and: [self isClamped]
]

{ #category : 'testing' }
GbxObjectReport >> isFirstReportForObject
[

	^self isHeaderOnly or: [self firstOffset = 1]
]

{ #category : 'testing' }
GbxObjectReport >> isByteObjectReport
[

	^self objImpl = 1
]

{ #category : 'testing' }
GbxObjectReport >> containsHighestObjectIndex
[
	| unitsInBuffer |
	unitsInBuffer := self isByteObjectReport
		ifTrue: [self valueBuffSize]
		ifFalse: [self oopsInBuffer].
	^self firstOffset + unitsInBuffer - 1 = self objSize
]

{ #category : 'testing' }
GbxObjectReport >> shouldSwizzleByteOrder
[

	self subclassResponsibility
]

{ #category : 'testing' }
GbxObjectReport >> isLastReportForObject
[

	^self isHeaderOnly or: [self containsHighestObjectIndex]
]

{ #category : 'accessing value buffer' }
GbxObjectReport >> namedValueAt: index putDelegate: aDelegate
[
	"Store the oop from aDelegate in the value buffer."

	self oopsBuffer oopAt: index putDelegate: aDelegate
]

{ #category : 'accessing value buffer' }
GbxObjectReport >> namedValueAt: index put: aValue
[
	"Store the oop value in the value buffer."

	self oopsBuffer oopAt: index put: aValue
]

{ #category : 'accessing value buffer' }
GbxObjectReport >> copyBytes
[
	"Return the value portion of the buffer as a Smalltalk byte array."

	^self bytesBuffer asByteArrayOfSize: self valueBuffSize
]

{ #category : 'accessing value buffer' }
GbxObjectReport >> valueByteAt: anOffset
[
	"Answer the byte value at the given 1-based value-buffer offset."

	^self bytesBuffer byteAt: anOffset
]

{ #category : 'accessing value buffer' }
GbxObjectReport >> relativeOopAt: anOffset putDelegate: aDelegate
[
	"Store the oop from aDelegate into my buffer, adjusting for a partial report."

	^self oopsBuffer
		oopAt: anOffset - self firstOffset + 1
		putDelegate: aDelegate
]

{ #category : 'accessing value buffer' }
GbxObjectReport >> oopAt: anOffset putDelegate: aDelegate
[
	"Store the oop from aDelegate into my value buffer at the given 1-based oop offset."

	^self oopsBuffer oopAt: anOffset putDelegate: aDelegate
]

{ #category : 'private-addressing' }
GbxObjectReport >> setBufferTo: anUninterpretedBytes
[
	"Set the buffer and make the oop and byte accessors point into its value portion."

	data := anUninterpretedBytes.
	bufferBytes := (anUninterpretedBytes isKindOf: ByteArray)
		ifTrue: [anUninterpretedBytes size]
		ifFalse: [bufferBytes].
	self oopsBuffer setBufferTo: anUninterpretedBytes.
	self bytesBuffer setBufferTo: anUninterpretedBytes.
	self setOffsetTo: 1
]

{ #category : 'private-addressing' }
GbxObjectReport >> bufferBytes: anInteger
[
	bufferBytes := anInteger
]

{ #category : 'private-addressing' }
GbxObjectReport >> oopArrayClass
[

	self subclassResponsibility
]

{ #category : 'private-addressing' }
GbxObjectReport >> oopsBuffer
[
	"Return a pointer to the value portion of the buffer with a type appropriate for accessing oops."

	oopsBuffer == nil
		ifTrue: 
			[oopsBuffer := self oopArrayClass
				buffer: data
				offset: offset + fixedSize].
	^oopsBuffer
]

{ #category : 'private-addressing' }
GbxObjectReport >> oopPtrAt: serverOffset
[
	"Return a buffer oop pointed at the given server offset."

	| bufferOffset |
	bufferOffset := serverOffset - self firstOffset + 1.
	^self oopsBuffer oopAt: bufferOffset
]

{ #category : 'private-addressing' }
GbxObjectReport >> bytesBuffer
[
	"Return a pointer to the value portion of the buffer with a type appropriate for accessing bytes."

	bytesBuffer == nil
		ifTrue: 
			[bytesBuffer := GbxByteArray
				buffer: data
				offset: offset + fixedSize].
	^bytesBuffer
]

{ #category : 'private-addressing' }
GbxObjectReport >> fixedSize
[
	^fixedSize
]

{ #category : 'private-addressing' }
GbxObjectReport >> offset: anInteger
[

	offset := anInteger
]

{ #category : 'copying' }
GbxObjectReport >> copyIntoBytesBufferFrom: aByteObject numBytes: numBytes startingAt: offsetInSource
[
	"Copy a range of bytes from aByteObject into my bytes buffer."

	self bytesBuffer
		copyFrom: aByteObject
		size: numBytes
		startingAt: offsetInSource
]

{ #category : 'copying' }
GbxObjectReport >> copyWithPrivateBuffer
[
	"Return a copy of the receiver with its own copy of the data space."

	| selfAsByteArray newReport |
	selfAsByteArray := (GbxByteArray buffer: data offset: offset)
		asByteArrayOfSize: self sizeWithValueBuff.
	newReport := self class session: session.
	newReport setBufferTo: selfAsByteArray.
	^newReport
]

{ #category : 'copying' }
GbxObjectReport >> copyBytesBufferInto: aByteObject from: targetStart to: targetStop
[
	"Copy the value-buffer bytes into the given range of aByteObject."

	self bytesBuffer
		copyTo: aByteObject
		size: targetStop - targetStart + 1
		startingAt: targetStart
]

{ #category : 'accessing' }
GbxObjectReport >> sizeWithValueBuff
[

	^fixedSize + self valueBuffSize
]

{ #category : 'accessing' }
GbxObjectReport >> offset
[

	^offset
]

{ #category : 'accessing' }
GbxObjectReport >> maxValueBufferOops
[

	^self maxValueBufferBytes // self bytesPerOop
]

{ #category : 'accessing' }
GbxObjectReport >> maxValueBufferBytes
[

	^bufferBytes - (offset - 1) - fixedSize
]

{ #category : 'accessing' }
GbxObjectReport >> session: aGbsSession
[
	"Set the session this report accesses, which determines details like oop size."

	session := aGbsSession.
	fixedSize := self class fixedSize
]

{ #category : 'accessing' }
GbxObjectReport >> structMessage
[

	^self class structMessage
]

{ #category : 'accessing header' }
GbxObjectReport >> swizzleStride: strideCode
[
	"Ignore by default. Only used in 64-bit v3.0 and later."
]

{ #category : 'accessing header' }
GbxObjectReport >> objId
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> objImpl: impl
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> valueBuffSize
[

	valueBuffSize == nil
		ifTrue: [valueBuffSize := data unsignedLongAt: offset].
	^valueBuffSize
]

{ #category : 'accessing header' }
GbxObjectReport >> firstIndexableOffset
[
	| nmSz firstIdxInBuffer |
	nmSz := self namedSize.
	firstIdxInBuffer := self firstOffset.
	firstIdxInBuffer > nmSz
		ifTrue: [^firstIdxInBuffer]
		ifFalse: [^nmSz + 1]
]

{ #category : 'accessing header' }
GbxObjectReport >> isInvariant
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> firstOffset
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> objSize
[

	^self namedSize + self idxSize
]

{ #category : 'accessing header' }
GbxObjectReport >> valueBuffSize: aSize
[

	valueBuffSize := aSize.
	data unsignedLongAt: offset put: aSize
]

{ #category : 'accessing header' }
GbxObjectReport >> idxSize
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> isClamped
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> oopsInBuffer
[
	"Return the number of oops in this report's buffer. Return 0 for byte-object reports."

	self isByteObjectReport ifTrue: [^0].
	^self valueBuffSize // self bytesPerOop
]

{ #category : 'accessing header' }
GbxObjectReport >> segment
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> isIndexable
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> segment: segmentID
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> setObjClassFromDelegate: del
[

	^self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> isOverlayed
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> lastIndexableOffset
[
	| nmSz firstSlotInBuffer oopsInBuffer lastSlotInBuffer |
	nmSz := self namedSize.
	oopsInBuffer := self oopsInBuffer.
	firstSlotInBuffer := self firstOffset.
	lastSlotInBuffer := oopsInBuffer + firstSlotInBuffer - 1.
	^lastSlotInBuffer > nmSz
		ifTrue: [lastSlotInBuffer]
		ifFalse: [0]
]

{ #category : 'accessing header' }
GbxObjectReport >> objImpl
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> setObjIdFromDelegate: del
[

	^self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> lastNamedOffset
[
	| nmSz firstIdxInBuffer oopsInBuffer lastIdxInBuffer |
	nmSz := self namedSize.
	firstIdxInBuffer := self firstOffset.
	firstIdxInBuffer > nmSz ifTrue: [^0].
	oopsInBuffer := self oopsInBuffer.
	lastIdxInBuffer := firstIdxInBuffer + oopsInBuffer - 1.
	nmSz <= lastIdxInBuffer
		ifTrue: [^nmSz]
		ifFalse: [^lastIdxInBuffer]
]

{ #category : 'accessing header' }
GbxObjectReport >> namedSize: size
[

	self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> storeIndexedSizeBits
[

	^self subclassResponsibility
]

{ #category : 'accessing header' }
GbxObjectReport >> swizzleStride
[

	^0
]

{ #category : 'accessing header' }
GbxObjectReport >> objClass
[

	self subclassResponsibility
]

{ #category : 'printing' }
GbxObjectReport >> stringClasses
[
	"Printing helper. Skip dialect-specific string classes that are not present."

	^OrderedCollection new
]

{ #category : 'printing' }
GbxObjectReport >> printOn: aStream indent: indent
[
	self printHeaderOn: aStream indent: indent + 1.
	aStream crtab: indent.
	self isByteObjectReport
		ifFalse: 
			[aStream nextPutAll: 'oops = '.
			self oopsBuffer printOn: aStream numOops: self oopsInBuffer]
		ifTrue: 
			[aStream nextPutAll: 'bytes = '.
			aStream nextPutAll: self copyBytes printString]
]

{ #category : 'printing' }
GbxObjectReport >> printOn: aStream
[

	self printOn: aStream indent: 1
]

{ #category : 'printing' }
GbxObjectReport >> printHeaderOn: aStream indent: indent
[
	aStream tab: indent - 1.
	aStream nextPutAll: self class name , ' with:'.
	aStream crtab: indent.
	aStream nextPutAll: 'valueBuffSize = ' , self valueBuffSize printString.
	aStream crtab: indent.
	aStream nextPutAll: 'namedSize = ' , self namedSize printString.
	aStream crtab: indent.
	aStream nextPutAll: 'idxSize = ' , self idxSize printString.
	aStream crtab: indent.
	aStream nextPutAll: 'firstOffset = ' , self firstOffset printString.
	aStream crtab: indent.
	aStream nextPutAll: 'objId = ' , self objId printString.
	aStream crtab: indent.
	aStream nextPutAll: 'objClass = ' , self objClass printString.
	aStream crtab: indent.
	aStream nextPutAll: 'segment = ' , self segment printString.
	aStream crtab: indent.
	aStream nextPutAll: 'objSize = ' , self objSize printString.
	aStream crtab: indent.
	aStream nextPutAll: 'objImpl = ' , self objImpl printString.
	aStream crtab: indent.
	aStream nextPutAll: 'isIndexable = ' , self isIndexable printString.
	aStream crtab: indent.
	aStream nextPutAll: 'isInvariant = ' , self isInvariant printString.
	aStream crtab: indent.
	aStream nextPutAll: 'isOverlayed = ' , self isOverlayed printString
]

{ #category : 'constants' }
GbxObjectReport >> bytesPerOop
[

	self subclassResponsibility
]
