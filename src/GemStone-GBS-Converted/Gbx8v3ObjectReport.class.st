Class {
	#name : 'Gbx8v3ObjectReport',
	#superclass : 'Gbx8ObjectReport',
	#instVars : [
		'swizzleStride'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing header' }
Gbx8v3ObjectReport >> idxSize
[

	indexedSize == nil
		ifTrue: [indexedSize := (data longLongAt: offset + 32) bitShift: -24].
	^indexedSize
]

{ #category : 'accessing header' }
Gbx8v3ObjectReport >> swizzleStride: strideCode
[
	"strideCode must be between 0 and 3, inclusive"

	swizzleStride := strideCode.
	bits := bits bitOr: (strideCode bitShift: 8)
]

{ #category : 'accessing header' }
Gbx8v3ObjectReport >> storeIndexedSizeBits
[

	| indexedSizeBits |
	indexedSizeBits := indexedSize * 16r1000000 + bits.
	data longLongAt: offset + 32 put: indexedSizeBits
]

{ #category : 'accessing header' }
Gbx8v3ObjectReport >> swizzleStride
[

	^swizzleStride
]

{ #category : 'accessing' }
Gbx8v3ObjectReport >> setOffsetTo: aByteOffset
[

	super setOffsetTo: aByteOffset.
	swizzleStride := nil
]

{ #category : 'testing' }
Gbx8v3ObjectReport >> shouldSwizzleByteOrder
[
	^false
]
