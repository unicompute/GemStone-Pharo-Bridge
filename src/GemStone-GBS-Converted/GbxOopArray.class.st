Class {
	#name : 'GbxOopArray',
	#superclass : 'Object',
	#instVars : [
		'buffer',
		'offset',
		'bufferOop',
		'numOops'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'getting' }
GbxOopArray >> asDelegateArrayOfSize: size forSession: aSession
[
	"Return an array of Delegates from the oops in the receiver."
	
	| delegates slider |
	delegates := Array new: size.
	slider := self oopAt: 1.
	1
		to: size
		do:
			[:i | 
			delegates
				at: i
				put: (slider asGSObjectInSession: aSession).
			slider increment].
	^delegates
]

{ #category : 'accessing' }
GbxOopArray >> at: anIndex
[
	
	^self oopAt: anIndex
]

{ #category : 'accessing' }
GbxOopArray >> bufferOop
[
	
	bufferOop == nil
		ifTrue: [bufferOop := self bufferOopClass fromBuffer: buffer offset: offset].
	^bufferOop
]

{ #category : 'accessing' }
GbxOopArray >> buffer: anUninterpretedBytes offset: byteOffset
[
	
	buffer := anUninterpretedBytes.
	offset := byteOffset.
	numOops := 0
]

{ #category : 'accessing' }
GbxOopArray >> bufferSize
[
	
	^self subclassResponsibility
]

{ #category : 'accessing' }
GbxOopArray >> setOffsetTo: aByteOffset
[
	"aByteOffset is a nonnegative SmallInteger. Resets my heap oop to the beginning of the buffer."
	
	offset := aByteOffset.
	self bufferOop setOffsetTo: aByteOffset
]

{ #category : 'accessing' }
GbxOopArray >> setBufferTo: anUninterpretedBytes
[
	
	buffer := anUninterpretedBytes.
	self bufferOop setBufferTo: anUninterpretedBytes.
	self setOffsetTo: 1
]

{ #category : 'accessing' }
GbxOopArray >> size
[
	^numOops
]

{ #category : 'accessing' }
GbxOopArray >> oopAt: oopIndex
[
	"Answer a GbxBufferOop pointing at an oop in my buffer. oopIndex is in oops, not bytes, and is 1-based.
	Note that this is not a new oop, but is my captive oop, so it may be re-addressed later. Don't hang on to it
	for long."
	
	self bufferOop setOffsetTo: offset + ((oopIndex - 1) * self bytesPerOop).
	^bufferOop
]

{ #category : 'accessing' }
GbxOopArray >> numOops
[
	^numOops
]

{ #category : 'putting' }
GbxOopArray >> addOopFromDelegate: del
[
	"Add the given oop to my end.
	Del must be of my size and endianness."
	
	(self bufferOop)
		copyOopFrom: del;
		increment.
	numOops := numOops + 1
]

{ #category : 'putting' }
GbxOopArray >> setIndexTo: index
[
	"Further oops added with #addOopFromDelegate: will start at this 0-based oop index"
	
	self bufferOop setOffsetTo: offset + (index * self bytesPerOop)
]

{ #category : 'putting' }
GbxOopArray >> addUpper: upperBytes lower3: lower3
[
	
	^self subclassResponsibility
]

{ #category : 'putting' }
GbxOopArray >> initializeFromDelegates: delegates
[
	"Make sure the buffer has sufficient room for the number of delegates and then
	store their oop values in the buffer.
	Delegates must be a sequenceable collection"

	self ensureSizeIsAtLeast: delegates size * self bytesPerOop.
	self bufferOop setOffsetTo: 1.
	delegates do: [:each | self addOopFromDelegate: each]
]

{ #category : 'private' }
GbxOopArray >> isBigEndian
[
	
	^EndianDetector isBigEndian
]

{ #category : 'private' }
GbxOopArray >> grow
[
	self allocateDataSize: self bufferSize * 2
]

{ #category : 'private' }
GbxOopArray >> bufferOopClass
[
	
	self subclassResponsibility
]

{ #category : 'testing' }
GbxOopArray >> isEmpty
[
	
	^numOops == 0
]

{ #category : 'initialize-release' }
GbxOopArray >> allocateDataSize: newPhysicalSizeInOops
[
	"Allocate a buffer of the given size and set it as my buffer.
	If I already have a buffer, then this is a grow situation and I need to copy my 
	current contents to the new buffer first."
	
	| newBuffer |
	newPhysicalSizeInOops < numOops
		ifTrue:
			[self gbsMessenger error:
					'Not enough room in new size for current contents'].
	newBuffer := ByteArray new: newPhysicalSizeInOops * self bytesPerOop.
	buffer == nil
		ifFalse:
			[| byteSize |
			byteSize := numOops * self bytesPerOop.
			newBuffer replaceBytesFrom: 1 to: byteSize with: buffer startingAt: 1].
	buffer := newBuffer.
	offset := 1.
	bufferOop := nil
]

{ #category : 'initialize-release' }
GbxOopArray >> ensureSizeIsAtLeast: aSize
[
	"Guarantee the data buffer is at least <aSize> in size"
	"This assumes that the buffer is all mine, which means that I was created with size:"
	
	self bufferSize < aSize ifTrue: [self allocateDataSize: aSize]
]

{ #category : 'initialize-release' }
GbxOopArray >> clear
[
	"Sets logicalSize to zero, effectively discarding all oops previously contained."
	
	numOops := 0
]

{ #category : 'printing' }
GbxOopArray >> printOn: aStream numOops: howMany
[
	"Print self as an array of oop values on <aStream>."
	
	| printSize maxPrint |
	maxPrint := 5000.
	aStream nextPutAll: self class name.
	aStream nextPut: $(.
	howMany isNil
		ifTrue: [aStream nextPutAll: '<size unknown>']
		ifFalse:
			[printSize := maxPrint min: howMany.
			1
				to: printSize
				do: [:i | self printValueAt: i on: aStream].
			printSize = maxPrint ifTrue: [aStream nextPutAll: ' ... ']].
	aStream nextPut: $)
]

{ #category : 'printing' }
GbxOopArray >> printOn: aStream
[
	"Print self as an array of oop values on <aStream>."
	
	self
		printOn: aStream
		numOops: self numOops
]

{ #category : 'converting' }
GbxOopArray >> asAddress
[
	"Return the buffer, which is allocated in Fixed Space, and therefore suitable for passing to C"
	
	^buffer
]

{ #category : 'constants' }
GbxOopArray >> bytesPerOop
[
	
	^self subclassResponsibility
]

{ #category : 'instance creation' }
GbxOopArray class >> size: aSize
[
	"Return a new instance that points to a newly allocated buffer of size <aSize>. in oops"
	
	| inst buffer |
	inst := self new.
	buffer := ByteArray new: aSize * inst bytesPerOop.
	inst buffer: buffer offset: 1.
	^inst
]

{ #category : 'instance creation' }
GbxOopArray class >> buffer: anUninterpretedBytes offset: byteOffset
[
	
	| inst |
	inst := self new.
	inst buffer: anUninterpretedBytes offset: byteOffset.
	^inst
]
