Class {
	#name : 'GbxTraversalBuffer',
	#superclass : 'Object',
	#instVars : [
		'data',
		'lock',
		'objectReport',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'store traversals' }
GbxTraversalBuffer >> setUsedBytes

	self usedBytes: objectReport offset - self headerSize - 1

{ #category : 'store traversals' }
GbxTraversalBuffer >> emptyBuffer
	"Set everything in the buffer to show that it's empty."

	self
		usedBytes: 0;
		resetObjectReport

{ #category : 'store traversals' }
GbxTraversalBuffer >> finishedReport
	"Header and valueBuffer all filled in -- advance the report to the next free space."

	| reportSize |
	reportSize := self sizeInBytesOfReport.
	objectReport setOffsetTo: objectReport offset + reportSize.
	self setUsedBytes

{ #category : 'accessing' }
GbxTraversalBuffer >> ensureSizeIsAtLeast: aSize
	"Return <self> making sure that the buffer is of at least size <aSize>.
	Re-allocate a bigger buffer if necessary.  If doing assertionChecks, check
	that the buffer is not currently locked (i.e. in use)."
	
	[self isLocked] gbxAssertEquals: false message:
			'Trying to access a locked buffer'.
	self bufferSize < aSize ifTrue: [self allocateDataSize: aSize].
	self emptyBuffer.
	^self

{ #category : 'accessing' }
GbxTraversalBuffer >> session: anObject

	session := anObject

{ #category : 'accessing' }
GbxTraversalBuffer >> sizeInBytesOfReport
	^self subclassResponsibility

{ #category : 'accessing' }
GbxTraversalBuffer >> remainingSpace
	"Return the amount of buffer space remaining, not counting any contents of the
	 current object report, which is assumed to point just past the used data."

	^data sizeInBytes - objectReport offset + 1

{ #category : 'accessing' }
GbxTraversalBuffer >> bufferSize
	"Return the size of the allocated buffer."

	^data sizeInBytes

{ #category : 'accessing' }
GbxTraversalBuffer >> objectReport

	^objectReport

{ #category : 'testing' }
GbxTraversalBuffer >> hasRoomForReport
	"Answer true only if I have room for an object header plus a few oops or bytes"

	^self remainingSpace >= self minimumReportSize

{ #category : 'testing' }
GbxTraversalBuffer >> isEmpty
	
	^self usedBytes == 0

{ #category : 'private' }
GbxTraversalBuffer >> usedBytes: anInteger
	
	self subclassResponsibility

{ #category : 'private' }
GbxTraversalBuffer >> allocatedBytes

	self subclassResponsibility

{ #category : 'private' }
GbxTraversalBuffer >> usedBytes
	
	self subclassResponsibility

{ #category : 'private' }
GbxTraversalBuffer >> objRepTypeClass
	
	^self subclassResponsibility

{ #category : 'private' }
GbxTraversalBuffer >> minimumReportSize

	^self class minimumReportSize

{ #category : 'private' }
GbxTraversalBuffer >> headerSize
	
	self subclassResponsibility

{ #category : 'private' }
GbxTraversalBuffer >> allocatedBytes: anInteger

	self subclassResponsibility

{ #category : 'support' }
GbxTraversalBuffer >> wordAlign: integerOffset
	
	self subclassResponsibility

{ #category : 'locking' }
GbxTraversalBuffer >> isLockedForFetchTraversal
	"For use by assertions only"

	^lock isKindOf: GbxFetchTraversal

{ #category : 'locking' }
GbxTraversalBuffer >> unlockFor: anOwner
	"Unlock the buffer so that it is available for use again."

	lock == anOwner ifTrue: [lock := nil].
	[lock == nil] gbxAssert

{ #category : 'locking' }
GbxTraversalBuffer >> isLocked
	"Return true if the buffer is locked (i.e. in use), false otherwise."
	
	^lock ~~ nil

{ #category : 'locking' }
GbxTraversalBuffer >> lockFor: newOwner
	"Set an owner. This prevents my use by another until I'm unlocked, and
	also identifies the owner for debugging."

	[lock == nil] gbxAssert.
	lock := newOwner

{ #category : 'initialize-release' }
GbxTraversalBuffer >> resetObjectReport
	"Point the object report at the beginning of the buffer."

	objectReport setOffsetTo: self headerSize + 1

{ #category : 'initialize-release' }
GbxTraversalBuffer >> allocateDataSize: logicalSize

	| physSize |
	physSize := logicalSize + self headerSize.
	data := UninterpretedBytes newInFixedSpace: physSize.
	lock := nil. "The unlocked state -- make it explicit."
	self
		allocatedBytes: logicalSize;
		initializeObjectReport

{ #category : 'initialize-release' }
GbxTraversalBuffer >> initializeObjectReport
	"Return a sliding object report that will be used to store objects into the traversal buffer."

	objectReport := self objRepTypeClass session: session.
	objectReport setBufferTo: data

{ #category : 'enumerating' }
GbxTraversalBuffer >> reportsAllButLastDo: reportBlock
	"Evaluate reportBlock with every report I contain, except the last. 
	This means that the block is not evaluated at all if I contain 0 or 1 reports.
	Answer the last report, or nil if I contain 0 reports."

	| buffSize position objReport |
	[self isLockedForFetchTraversal] gbxAssert.
	buffSize := self usedBytes + self headerSize.
	position := self headerSize + 1.
	^position >= buffSize
		ifTrue: 
			["empty buffer, no reports"
			nil]
		ifFalse: 
			[objReport := self objRepTypeClass session: session.
			objReport setBufferTo: data.
			
			[objReport setOffsetTo: position.
			position := (self wordAlign: position + objReport sizeWithValueBuff - 1)
						+ 1.
			position < buffSize]
					whileTrue: [reportBlock value: objReport].
			objReport]

{ #category : 'enumerating' }
GbxTraversalBuffer >> reportsDo: reportBlock

	| lastOne |
	lastOne := self reportsAllButLastDo: reportBlock.
	lastOne ~~ nil ifTrue: [reportBlock value: lastOne]

{ #category : 'printing' }
GbxTraversalBuffer >> printOwnerOn: aStream
	
	self isLocked
		ifTrue:
			[aStream nextPutAll: ' locked for: '.
			lock printOn: aStream.
			aStream nextPut: $ ]

{ #category : 'printing' }
GbxTraversalBuffer >> printOn: aStream
	
	| sz |
	aStream nextPutAll: self class name.
	self printOwnerOn: aStream.
	self printAllocatedBytesOn: aStream.
	sz := self usedBytes.
	aStream nextPutAll: ' used bytes: '.
	sz printOn: aStream.
	aStream nextPutAll: ' reports:('.
	self printReportsOn: aStream.
	aStream
		nextPutAll: ')';
		cr

{ #category : 'printing' }
GbxTraversalBuffer >> printReportsOn: stream
	"Print each of my reports on the stream."

	| lastOffset tOffset rep |
	lastOffset := self usedBytes + 1.
	lastOffset > 1
		ifFalse: 
			[stream nextPutAll: ' --empty traversal buffer'.
			^self].
	tOffset := 1.
	stream cr.
	rep := self objRepTypeClass session: session.
	rep setBufferTo: data.
	
	[rep setOffsetTo: self headerSize + tOffset.
	tOffset + rep sizeWithValueBuff > lastOffset
		ifTrue: 
			[stream nextPutAll: '<bogus report that claimed to go past end of buffer>'.
			false]
		ifFalse: 
			[rep printOn: stream.
			stream cr.
			tOffset := tOffset + rep sizeWithValueBuff.
			tOffset := (self wordAlign: tOffset - 1) + 1.
			tOffset < lastOffset]]
			whileTrue: []

{ #category : 'printing' }
GbxTraversalBuffer >> printAllocatedBytesOn: aStream 
	aStream nextPutAll: ' allocated bytes: '.
	self allocatedBytes printOn: aStream

{ #category : 'converting' }
GbxTraversalBuffer >> asAddress
	"Return the buffer, which is allocated in Fixed Space, and therefore suitable for passing to C"
	
	^data

{ #category : 'private' }
GbxTraversalBuffer class >> validateSize: aSize

	(aSize < 2048 or: [aSize \\ 8 ~= 0])
		ifTrue: 
			[self gbsMessenger
				error: 'Traversal buffer logical size must be a multiple of 8, and >= 2048']

{ #category : 'instance creation' }
GbxTraversalBuffer class >> size: aSize session: session
	"Return a new instance with a buffer of size <aSize>, for GbsSession session."

	self validateSize: aSize.
	^(self new)
		session: session;
		allocateDataSize: aSize;
		emptyBuffer;
		yourself

{ #category : 'constants' }
GbxTraversalBuffer class >> minimumReportSize
	"Answer the smallest number of bytes that are required for an object report.
	This varies by subclass, but is the size of a report header plus 8 bytes (the size of a 64-bit float, or equivalently one or two OOPs).
	This is a derived constant, cached since it is frequently accessed."

	minimumReportSize == nil
		ifTrue: 
			[| buff |
			buff := self new.
			minimumReportSize := buff objRepTypeClass fixedSize + 8].
	^minimumReportSize

