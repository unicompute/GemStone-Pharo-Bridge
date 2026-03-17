Class {
	#name : 'GbxMultiByteStringReplicator',
	#superclass : 'GbxByteObjectReplicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'per-object private' }
GbxMultiByteStringReplicator >> copyBytesFromReportToClientObject

	clientObject gbxCopyBytesFromReport: currentReport

{ #category : 'private store replication' }
GbxMultiByteStringReplicator >> copyInto: report from: anObject numBytes: numBytes startingAt: firstOffset

	| bytesSource |
	bytesSource := report shouldSwizzleByteOrder
				ifTrue: [anObject copy reverseByteOrder]
				ifFalse: [anObject].
	report
		copyIntoBytesBufferFrom: bytesSource
		numBytes: numBytes
		startingAt: firstOffset

