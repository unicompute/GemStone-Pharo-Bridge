Class {
	#name : 'GbxLargeIntegerDigitL32Replicator',
	#superclass : 'GbxLargeIntegerDigit32Replicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private store replication' }
GbxLargeIntegerDigitL32Replicator >> computeServerBytesFor: int
	"Answer a new byte array comprising the bytes to be put in one or more (if split) object reports for 
		the server large integer corresponding to the given client large integer. "

	^self computeUnswizzledServerBytesFor: int

{ #category : 'per-object private' }
GbxLargeIntegerDigitL32Replicator >> signedByteIndex

	^1

{ #category : 'per-object private' }
GbxLargeIntegerDigitL32Replicator >> createEmptyReplicateForReport
	"The current report is the first report for the integer in question. 
	If this report is also the last report for the integer (it will be in most cases) 
	we can compute the actual size needed, without any padding bytes.
	Create an object of sufficient size and answer it."

	| signedClass |
	signedClass := self clientClassForReportValues.
	^currentReport containsAllValues
		ifTrue: [signedClass basicNew: self neededSizeFromReportValues]
		ifFalse: 
			[needPostFaultReplacement := true.
			signedClass basicNew: currentReport idxSize - 4]

{ #category : 'per-object private' }
GbxLargeIntegerDigitL32Replicator >> copyBytesFromReportToClientObject

	self copyRawBytesFromReportToClientObject.
	(needPostFaultReplacement and: [currentReport isLastReportForObject])
		ifTrue: [self trimLeadingZeroes]

{ #category : 'per-object private' }
GbxLargeIntegerDigitL32Replicator >> neededSizeFromReportValues
	"Answer the number of bytes needed to represent the server object whose entire state is in currentReport.
	It is not valid to send this message if currentReport only contains part of the state of the object (which will be the 
	case if the object is split across multiple traversal buffers).
	The first four bytes in the report indicate the sign (we don't need those), 
	and there may also be up to three trailing high-order zero bytes that we don't need. 
	The needed size is all the bytes in between."

	| maxIndex |
	maxIndex := currentReport valueBuffSize.
	maxIndex to: maxIndex - 3
		by: -1
		do: [:i | (currentReport valueByteAt: i) == 0 ifFalse: [^i - 4]].
	^maxIndex - 8

