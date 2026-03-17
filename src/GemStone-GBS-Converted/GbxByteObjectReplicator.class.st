Class {
	#name : #'GbxByteObjectReplicator',
	#superclass : #'GbxObjectReplicator',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'clamping' }
GbxByteObjectReplicator >> updateInstVarLevelsOfScheme: scheme
	"Configure the scheme with default replication for the indexable part
	 (which is the whole of the client class?) and no forwarders for either
	 named nor indexed instance variables, since there are no named
	 variables and the indexed variables are bytes not pointers."

	scheme
		updateInstVarLevels: (Array with: nil)	"Cannot use a literal, as it cannot be shared across sessions."
		forwarderOffsets: #()
		forwardIndexedPart: false
		forClass: self clientClass

{ #category : #'per-object private' }
GbxByteObjectReplicator >> copyBytesFromClientObjectTo: aByteObject

	| firstOffset numberOfBytes |
	firstOffset := currentReport firstOffset.
	numberOfBytes := currentReport valueBuffSize.
	numberOfBytes > 0
		ifTrue: 
			[aByteObject
				gbxReplaceBytesFrom: 1
				to: numberOfBytes
				with: clientObject
				startingAt: firstOffset]

{ #category : #'per-object private' }
GbxByteObjectReplicator >> canUnstubInPlace
	"Byte objects always use zero-length stubs, so never unstub in place."

	^false

{ #category : #'per-object private' }
GbxByteObjectReplicator >> copyBytesFromReportToClientObject

	self copyBytesFromReportTo: clientObject

{ #category : #'per-object private' }
GbxByteObjectReplicator >> copyBytesFromReportTo: aByteObject

	| firstOffset lastOffset |
	firstOffset := currentReport firstOffset.
	lastOffset := firstOffset + currentReport valueBuffSize - 1.	"If there are 0 bytes to copy, lastOffset will be 1 less than firstOffset"
	lastOffset >= firstOffset
		ifTrue: 
			[currentReport
				copyBytesBufferInto: aByteObject
				from: firstOffset
				to: lastOffset]

{ #category : #'per-object private' }
GbxByteObjectReplicator >> clientSizeIsCorrect
	"For Byte objects, there are no named instvars, so it's just the number of bytes."

	^clientObject gbxBasicSize = currentReport idxSize

{ #category : #'private store replication' }
GbxByteObjectReplicator >> copyInto: report from: anObject numBytes: numBytes startingAt: firstOffset

	report
		copyIntoBytesBufferFrom: anObject
		numBytes: numBytes
		startingAt: firstOffset

{ #category : #'private store replication' }
GbxByteObjectReplicator >> packDirtyReferentsOf: anObject inTraversal: storeTraversal
	"Byte objects have no referents."

{ #category : #'private store replication' }
GbxByteObjectReplicator >> pack: anObject withDelegate: aDelegate inTraversal: storeTraversal
	"Store a report for anObject in the storeTraversal. If I won't fit, put the part of 
	anObject that will fit in, flush it to the server, and repeat until all of anObject has been stored."

	| indexWithinObject objectSize |
	objectSize := self byteSizeOf: anObject.
	"Always send at least one report, even for zero-size object."
	indexWithinObject := 1 + (self
						packOneReportFor: anObject
						withDelegate: aDelegate
						startingAt: 1
						inTraversal: storeTraversal).
	[indexWithinObject > objectSize] whileFalse: 
			[storeTraversal flushBufferToServer.
			indexWithinObject := indexWithinObject + (self
								packOneReportFor: anObject
								withDelegate: aDelegate
								startingAt: indexWithinObject
								inTraversal: storeTraversal)].
	storeTraversal packed: anObject.
	session packed: anObject

{ #category : #'private store replication' }
GbxByteObjectReplicator >> packOneReportFor: anObject withDelegate: aDelegate startingAt: firstOffset inTraversal: storeTraversal
	"Store a report for anObject in the storeTraversal, starting at 1-based offset firstOffset within anObject.
	If the rest of anObject won't fit, make a report for the part of anObject that will fit. 
	In either case, answer the number of value buffer bytes packed."

	| report valueBuffNumBytes objectSize |
	storeTraversal flushBufferIfFull.
	report := storeTraversal objectReport.
	objectSize := self byteSizeOf: anObject.
	"Figure out how many bytes we'll be storing in this report."
	valueBuffNumBytes := report maxValueBufferBytes
				min: objectSize - firstOffset + 1.

	"Write the value buffer"
	self
		copyInto: report
		from: anObject
		numBytes: valueBuffNumBytes
		startingAt: firstOffset.

	"Value buffer done, write Object Header"
	"objImpl of 1 means bytes. #objImpl: also sets isOverlayed"
	report
		valueBuffSize: valueBuffNumBytes;
		namedSize: 0;
		idxSize: objectSize;
		firstOffset: firstOffset;
		setObjIdFromDelegate: aDelegate;
		setObjClassFromDelegate: serverClass;
		segment: (report segmentValueForSession: session);
		objSize: objectSize;
		objImpl: 1;
		swizzleStride: clientClass gbsByteSwizzleStride;
		storeIndexedSizeBits.
	storeTraversal finishedReport.
	self gbsMessenger traceLog: 
			[:msgr |
			msgr
				statusTag: #storedObjectReport
				message: '(s%1)GbxByteObjectReplicator>>pack:... a %2 %3 firstOffset: %4'
				with: session sessionId
				with: anObject gbxBasicClass name
				with: aDelegate
				with: firstOffset].
	^valueBuffNumBytes

{ #category : #'private store replication' }
GbxByteObjectReplicator >> byteSizeOf: anObject

	^anObject gbxBasicSize

{ #category : #'per-object replication' }
GbxByteObjectReplicator >> verifyObjectBytes

	| numberOfBytes reportBytes clientBytes |
	numberOfBytes := currentReport valueBuffSize.
	reportBytes := ByteArray new: numberOfBytes.
	clientBytes := ByteArray new: numberOfBytes.
	self copyBytesFromReportTo: reportBytes.
	self copyBytesFromClientObjectTo: clientBytes.
	clientBytes = reportBytes ifFalse: [self signalNoModificationError]

{ #category : #'per-object replication' }
GbxByteObjectReplicator >> mutateObject

	clientObject gbxIgnoreFutureChanges.	"Fill in object body bytes."
	self copyBytesFromReportToClientObject.
	self clientObjectIsComplete
		ifTrue: 
			[self setImmutability.
			clientObject postFaultInSession: session].
	self gbxFixMe.	"assigns need to be unpreemptible"
	clientObject gbxTrapFutureChanges

{ #category : #'per-object replication' }
GbxByteObjectReplicator >> mutateOrVerifyObject
	"If the client object is mutable, update it with the bytes in the report.
	If immutable, verify that the bytes in the report match the bytes in the client object."

	self clientObjectIsImmutable
		ifTrue: [self verifyObjectBytes]
		ifFalse: 
			["Fill in object body bytes."
			"assigns need to be unpreemptible"
			self mutateObject]

{ #category : #'per-object replication' }
GbxByteObjectReplicator >> forReplication: replication replicateFromReport: report
	"Sender must hold session's semaphore, and clientMap semaphore."

	report isFirstReportForObject ifTrue: [self initializeForNewObject].
	currentReport := report.
	reportOop := report objId.
	self replicateFromReport.
	report isLastReportForObject ifTrue: [self initializeForNewObject]

{ #category : #'per-object replication' }
GbxByteObjectReplicator >> replicateFromReport
	"Private.  Given the description of a GemStone object from a traversal object header,
	 replicate the object as a client object.  If the object is already in the cache,
	 and it's not a stub, ignore it.. Self is returned."
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	reportCount := reportCount + 1.
	reportCount == 1
		ifTrue: 
			[clientObject := session clientAtOop: reportOop.
			self updateOrCreateClientObject.
			currentReport isHeaderOnly
				ifTrue: 
					[^self	"create or update all needed -- leave existing replicate alone (bug 41115)"]
				ifFalse: [self delegate nowExported].
			self gbxFixMe.	"assigns need to be unpreemptible"
			clientObject gbxIsProxy
				ifTrue: 
					[clientObject gbxTrapFutureChanges.
					^self].
			clientObject gbxIgnoreFutureChanges.
			clientObject preFaultWithReport: currentReport inSession: session]
		ifFalse: 
			["If we have a stub or forwarder at this point, we're done."
			clientObject gbxIsProxy ifTrue: [^self]].
	self mutateOrVerifyObject

{ #category : #'per-object testing' }
GbxByteObjectReplicator >> clientObjectIsComplete
	"Answer false if there is more work needed on this client object."

	^self expectsAnotherReport not

