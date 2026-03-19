Extension { #name : #'WideString' }

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
WideString class >> gbsByteSwizzleStride [

	^1	"2-byte swizzling"
]

{ #category : '*GemStone-GBS-Converted-GBS-private' }
WideString class >> gbsReplicatorClass [

	^GbxMultiByteStringReplicator
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
WideString >> gbxCopyBytesFromReport: report [
	"Receiver must be a byte object. All bytes in report's valueBuffer are copied to myself, at the offset specified by the report."

	report shouldSwizzleByteOrder
		ifTrue: [self gbxCopyAndSwizzleBytesFromReport: report]
		ifFalse: [super gbxCopyBytesFromReport: report]
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
WideString >> gbxCopyAndSwizzleBytesFromReport: report [
	"Copy bytes from the report into myself, changing the endianness.
	The beginning and/or ending offset may be odd, so copy bytes individually
	to avoid interfering with other partial reports for myself."
	
	| selfIndex |
	selfIndex := report firstOffset.
	selfIndex := selfIndex odd
		ifTrue: [selfIndex + 1]
		ifFalse: [selfIndex - 1].
	1
		to: report valueBuffSize
		do:
			[:reportIndex | 
			self
				basicAt: selfIndex
				put: (report valueByteAt: reportIndex).
			selfIndex := selfIndex odd
				ifTrue: [selfIndex + 3]
				ifFalse: [selfIndex - 1]]
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
WideString >> gbxAsServerBytes [
	"Private.  GBS.  Preparation for copying to heap.  Might need to switch byte ordering -
	 GemStone DoubleByteStrings are always big endian in GemStone/S and
	GemStone64 servers prior to v3, but the byte ordering
	 of VisualWorks TwoByteStrings depends on the host platform."

	^self copy changeClassTo: ByteArray
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
WideString class >> gsObjImpl [
	"In 64-bit clients, WideString is already an 
	indexable bytes object.
	In 32-bit clients, it is a indexable pointers object
	and we convert to bytes.
	We always want to treat them as byte objects"
	
	^1	"Bytes"
]

{ #category : '*GemStone-GBS-Converted-gemstone-private' }
WideString >> gbxNeedsSTToGSMapping [
	
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
WideString class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
WideString class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
WideString class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
WideString >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
WideString >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
WideString >> isRunningUnderAssertingVM [
	^false
]

