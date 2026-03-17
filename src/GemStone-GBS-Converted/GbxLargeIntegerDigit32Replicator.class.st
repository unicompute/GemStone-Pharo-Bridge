Class {
	#name : 'GbxLargeIntegerDigit32Replicator',
	#superclass : 'GbxLargeIntegerReplicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'per-object private' }
GbxLargeIntegerDigit32Replicator >> copyRawBytesFromReportToClientObject
[
	"If this is the first report, the first four bytes are the sign, which has already been decided, so skip them."

	| numBytesToSkip bytesBuffer rawBuffer firstOffset targetStart targetEnd |
	firstOffset := currentReport firstOffset.
	numBytesToSkip := 5 - firstOffset max: 0.	"Skip any sign bytes in this report."
	targetStart := firstOffset - 4 + numBytesToSkip.
	targetEnd := firstOffset + currentReport valueBuffSize - 1
				- numBytesToSkip min: clientObject gbxBasicSize.
	bytesBuffer := currentReport bytesBuffer.
	rawBuffer := bytesBuffer buffer.
	targetEnd >= targetStart
		ifTrue: 
			[clientObject
				gbxReplaceBytesFrom: targetStart
				to: targetEnd
				with: rawBuffer
				startingAt: bytesBuffer offset + numBytesToSkip]
]

{ #category : 'per-object private' }
GbxLargeIntegerDigit32Replicator >> signedByteIndex
[
	"Answer the offset of the one byte within the four bytes allocated
	 for the sign that actually represents the sign."

	^self subclassResponsibility
]

{ #category : 'per-object private' }
GbxLargeIntegerDigit32Replicator >> clientClassForReportValues
[
	"Only send this message when the sender knows that the report contains the required bytes."

	^(currentReport valueByteAt: self signedByteIndex) == 0
		ifTrue: [LargePositiveInteger]
		ifFalse: [LargeNegativeInteger]
]

{ #category : 'private store replication' }
GbxLargeIntegerDigit32Replicator >> computeUnswizzledServerBytesFor: int
[
	"Answer a new byte array comprising the bytes to be put in one or more (if split) object reports for 
		the server large integer corresponding to the given client large integer. "

	| size result |
	size := int basicSize.
	result := ByteArray new: size + ((4 - (size \\ 4)) \\ 4 + 4).	"Allow space for the sign (first four bytes) and pad to 32-bit digit size"
	int negative ifTrue: [result at: 1 put: 1].
	"Non-copied bytes will be 0. This is the remaining bytes of the sign and any end padding bytes."
	result
		replaceBytesFrom: 5
		to: 4 + size
		with: int
		startingAt: 1.
	^result
]

