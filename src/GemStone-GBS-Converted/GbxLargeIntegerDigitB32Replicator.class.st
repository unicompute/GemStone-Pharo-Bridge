Class {
	#name : 'GbxLargeIntegerDigitB32Replicator',
	#superclass : 'GbxLargeIntegerDigit32Replicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'per-object private' }
GbxLargeIntegerDigitB32Replicator >> signedByteIndex
[

	^4
]

{ #category : 'per-object private' }
GbxLargeIntegerDigitB32Replicator >> createEmptyReplicateForReport
[
	"The current report is the first report for the integer in question. 
	On big-endian clients we must swizzle the digits, so there is no advantage to
	trying to figure out the exact needed size as we do in the little-endian case."

	^self clientClassForReportValues basicNew: currentReport idxSize - 4
]

{ #category : 'per-object private' }
GbxLargeIntegerDigitB32Replicator >> copyBytesFromReportToClientObject
[

	self copyRawBytesFromReportToClientObject.
	currentReport isLastReportForObject
		ifTrue: 
			[self
				swizzleDigitsOf: clientObject;
				trimLeadingZeroes]
]

{ #category : 'private store replication' }
GbxLargeIntegerDigitB32Replicator >> computeServerBytesFor: int
[
	"Answer a new byte array comprising the bytes to be put in one or more (if split) object reports for 
		the server large integer corresponding to the given client large integer. "

	| result |
	result := self computeUnswizzledServerBytesFor: int.
	self swizzleDigitsOf: result.
	^result
]

{ #category : 'private' }
GbxLargeIntegerDigitB32Replicator >> swizzleDigitsOf: bytes
[
	"Bytes is the body of a LargeInteger to be sent to the server, or received from the server. Each 32-bit digit is of the wrong endianness, since VW always uses little-endian, and the GCI expects platform-native endianness within each digit, but digits in little-endian order.
	Bytes must be of size 0 mod 4."

	1 to: bytes basicSize
		by: 4
		do: 
			[:byteIdx |
			| a b |
			a := bytes basicAt: byteIdx.
			b := bytes basicAt: byteIdx + 3.
			bytes basicAt: byteIdx put: b.
			bytes basicAt: byteIdx + 3 put: a.
			a := bytes basicAt: byteIdx + 1.
			b := bytes basicAt: byteIdx + 2.
			bytes basicAt: byteIdx + 1 put: b.
			bytes basicAt: byteIdx + 2 put: a]
]

