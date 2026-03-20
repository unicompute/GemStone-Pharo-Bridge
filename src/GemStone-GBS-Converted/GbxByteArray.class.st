Class {
	#name : 'GbxByteArray',
	#superclass : 'Object',
	#instVars : [
		'buffer',
		'offset'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxByteArray class >> size: aSize
[
	"Return a new instance that points to a newly allocated buffer of size aSize."

	^self buffer: (ByteArray new: aSize) offset: 1
]

{ #category : 'instance creation' }
GbxByteArray class >> buffer: anUninterpretedBytes offset: byteOffset
[

	| inst |
	inst := self new.
	inst buffer: anUninterpretedBytes offset: byteOffset.
	^inst
]

{ #category : 'accessing' }
GbxByteArray >> buffer
[

	^buffer
]

{ #category : 'accessing' }
GbxByteArray >> setOffsetTo: aByteOffset
[
	"aByteOffset is a nonnegative SmallInteger"

	offset := aByteOffset
]

{ #category : 'accessing' }
GbxByteArray >> byteAt: byteOffset
[
	"Answer the byte at the given 1-based offset"

	^buffer basicAt: offset + byteOffset - 1
]

{ #category : 'accessing' }
GbxByteArray >> setBufferTo: anUninterpretedBytes
[
	"Set our buffer pointer. Reset offset."

	buffer := anUninterpretedBytes.
	self setOffsetTo: 1
]

{ #category : 'accessing' }
GbxByteArray >> offset
[

	^offset
]

{ #category : 'accessing' }
GbxByteArray >> byteAt: byteOffset put: byteValue
[
	"Set the byte at the given 1-based offset"

	^buffer
		basicAt: offset + byteOffset - 1
		put: byteValue
]

{ #category : 'converting' }
GbxByteArray >> copyFrom: aByteObject size: numBytes startingAt: offsetInSource
[
	"Write numBytes bytes to my address from aByteObject starting at 1-based offsetInSource."

	buffer
		gbxReplaceBytesFrom: offset
		to: offset + numBytes - 1
		with: aByteObject
		startingAt: offsetInSource
]

{ #category : 'converting' }
GbxByteArray >> copyAt: anOffset from: byteData size: dataSize startingAt: startIndex
[
	"Write dataSize bytes to the receiver's address + anOffset from byteData starting at startIndex."

	| start |
	start := offset + anOffset - 1.
	buffer
		gbxReplaceBytesFrom: start
		to: start + dataSize - 1
		with: byteData
		startingAt: startIndex
]

{ #category : 'converting' }
GbxByteArray >> asByteArrayOfSize: aSize
[
	"Return the contents of my chunk of the buffer as a ByteArray of size aSize."

	| bytes |
	bytes := ByteArray new: aSize.
	aSize > 0
		ifTrue: 
			[bytes
				gbxReplaceBytesFrom: 1
				to: aSize
				with: buffer
				startingAt: offset].
	^bytes
]

{ #category : 'converting' }
GbxByteArray >> asAddress
[
	"Return the underlying buffer."

	^buffer
]

{ #category : 'converting' }
GbxByteArray >> copyTo: aByteObject size: numBytes startingAt: targetStart
[
	"Copy numBytes from myself (starting at my beginning) to aByteObject."

	aByteObject
		gbxReplaceBytesFrom: targetStart
		to: targetStart + numBytes - 1
		with: buffer
		startingAt: offset
]

{ #category : 'converting' }
GbxByteArray >> copyTo: aByteObject size: numBytes sourceStart: sourceStart targetStart: targetStart
[
	"Copy numBytes from myself starting at 1-based sourceStart to aByteObject."

	aByteObject
		gbxReplaceBytesFrom: targetStart
		to: targetStart + numBytes - 1
		with: buffer
		startingAt: offset + sourceStart - 1
]

{ #category : 'initialize-release' }
GbxByteArray >> allocateDataSize: size
[

	buffer := ByteArray new: size.
	offset := 1
]

{ #category : 'initialize-release' }
GbxByteArray >> ensureSizeIsAtLeast: aSize
[
	"Guarantee the data buffer is at least aSize in size."

	(buffer isNil or: [buffer size < aSize]) ifTrue: [self allocateDataSize: aSize]
]

{ #category : 'initialize-release' }
GbxByteArray >> buffer: anUninterpretedBytes offset: byteOffset
[

	buffer := anUninterpretedBytes.
	offset := byteOffset
]
