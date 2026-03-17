Class {
	#name : 'GbxLargeIntegerReplicator',
	#superclass : 'GbxByteObjectReplicator',
	#instVars : [
		'integer',
		'needPostFaultReplacement',
		'serverBytes'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'per-object private' }
GbxLargeIntegerReplicator >> correctSizeOfClientObject
[
	"Answer how many bytes the client object should contain. This is the number of bytes 
	int currently contains, less any high-order bytes that are zero.
	Should only be sent after the high-order one bits are present, so
	it's an error for all bits to be zero."

	clientObject basicSize to: 1
		by: -1
		do: [:i | (clientObject basicAt: i) == 0 ifFalse: [^i]].
	self gbsMessenger error: 'Large Integer is zero'
]

{ #category : 'per-object private' }
GbxLargeIntegerReplicator >> createEmptyReplicateForReport
[

	self subclassResponsibility
]

{ #category : 'per-object private' }
GbxLargeIntegerReplicator >> trimLeadingZeroes
[

	| correctSize replacement |
	correctSize := self correctSizeOfClientObject.
	clientObject basicSize == correctSize
		ifFalse: 
			[replacement := clientObject gbxBasicClass basicNew: correctSize.
			replacement
				gbxReplaceBytesFrom: 1
				to: correctSize
				with: clientObject
				startingAt: 1.
			"clientObject is already mapped, so must use become: to replace it."
			clientObject gbxBecome: replacement]
]

{ #category : 'private store replication' }
GbxLargeIntegerReplicator >> byteSizeOf: anObject
[

	^(self serverBytesFor: anObject) size
]

{ #category : 'private store replication' }
GbxLargeIntegerReplicator >> copyInto: report from: anObject numBytes: numBytes startingAt: firstOffset
[

	report
		copyIntoBytesBufferFrom: (self serverBytesFor: anObject)
		numBytes: numBytes
		startingAt: firstOffset
]

{ #category : 'private store replication' }
GbxLargeIntegerReplicator >> serverBytesFor: int
[

	^int == integer
		ifTrue: [serverBytes]
		ifFalse: 
			[integer := int.
			serverBytes := self computeServerBytesFor: int]
]

{ #category : 'private store replication' }
GbxLargeIntegerReplicator >> computeServerBytesFor: int
[

	^self subclassResponsibility
]

{ #category : 'per-object initialization' }
GbxLargeIntegerReplicator >> initializeForNewObject
[

	super initializeForNewObject.
	integer := serverBytes := nil.
	needPostFaultReplacement := false
]

{ #category : 'per-object replication' }
GbxLargeIntegerReplicator >> replicateFromReport
[
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	super replicateFromReport.
	(currentReport isHeaderOnly not and: [self clientObjectIsComplete])
		ifTrue: 
			[clientObject gbxIsImmutable: true.
			self delegate isReadOnlyObject: true]
]

{ #category : 'instance creation' }
GbxLargeIntegerReplicator class >> forClientClass: clientClass serverClass: classDelegate manager: manager
[
	"Create an instance of the appropriate one of my concrete subclasses."

	| concreteClass |
	concreteClass := UninterpretedBytes isBigEndian
				ifTrue: [GbxLargeIntegerDigitB32Replicator]
				ifFalse: [GbxLargeIntegerDigitL32Replicator].
	^concreteClass new
		initializeForClientClass: clientClass
		serverClass: classDelegate
		manager: manager
]

