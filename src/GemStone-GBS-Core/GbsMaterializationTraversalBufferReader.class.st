Class {
	#name : 'GbsMaterializationTraversalBufferReader',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsMaterializationTraversalBufferReader class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'constants' }
GbsMaterializationTraversalBufferReader >> alignedByteCount: byteCount [
	^ ((byteCount + 7) // 8) * 8
]

{ #category : 'parsing' }
GbsMaterializationTraversalBufferReader >> byteArrayFromBuffer: traversalBuffer offset: valueOffset count: byteCount [
	| bytes |
	bytes := ByteArray new: byteCount.
	1 to: byteCount do: [ :index |
		bytes at: index put: (traversalBuffer unsignedByteAt: valueOffset + index - 1) ].
	^ bytes
]

{ #category : 'private' }
GbsMaterializationTraversalBufferReader >> checkAvailable [
	(self isAvailable) ifFalse: [
		GbsMaterializationTraversalError
			signalKind: #unavailable
			label: 'traversal-buffer transport'
			message: 'GCI traversal-buffer transport is not available for this session.' ]
]

{ #category : 'constants' }
GbsMaterializationTraversalBufferReader >> defaultTraversalBufferBytes [
	^ 1048576
]

{ #category : 'testing' }
GbsMaterializationTraversalBufferReader >> isAvailable [
	| interface |
	interface := session serverInterface.
	(interface respondsTo: #supportsMaterializationTraversalBufferTransport) ifTrue: [
		^ interface supportsMaterializationTraversalBufferTransport == true ].
	^ (interface respondsTo: #apiGciAllocTravBuf:)
		and: [ (interface respondsTo: #apiGciFree:)
		and: [ (interface respondsTo: #apiGciTraverseOops:count:into:level:)
		and: [ interface respondsTo: #apiGciMoreTraversal: ] ] ]
]

{ #category : 'traversal' }
GbsMaterializationTraversalBufferReader >> clampedTraversalSpecOop [
	| manager scheme |
	manager := [ GbxClampManager forSession: session ] on: Error do: [ ^ nil ].
	scheme := [ manager currentReplicationScheme ] on: Error do: [ ^ nil ].
	scheme ifNil: [ ^ nil ].
	^ GbsServerClampSpecificationSynchronizer
		clampSpecOopForScheme: scheme
		session: session
]

{ #category : 'constants' }
GbsMaterializationTraversalBufferReader >> objectReportHeaderBytes [
	^ 40
]

{ #category : 'parsing' }
GbsMaterializationTraversalBufferReader >> objectReportUsedBytesAt: traversalBuffer offset: offset [
	| valueSize |
	valueSize := traversalBuffer integerAt: offset size: 4 signed: true.
	^ self objectReportHeaderBytes + (self alignedByteCount: valueSize)
]

{ #category : 'parsing' }
GbsMaterializationTraversalBufferReader >> oopArrayFromBuffer: traversalBuffer offset: valueOffset count: oopCount [
	| oops |
	oops := Array new: oopCount.
	1 to: oopCount do: [ :index |
		oops
			at: index
			put: ((traversalBuffer
				integerAt: valueOffset + ((index - 1) * 8)
				size: 8
				signed: false) asInteger) ].
	^ oops
]

{ #category : 'parsing' }
GbsMaterializationTraversalBufferReader >> parseReportsFromBuffer: traversalBuffer into: reports label: labelString [
	| usedBytes offset limit |
	usedBytes := traversalBuffer integerAt: 5 size: 4 signed: false.
	usedBytes = 0 ifTrue: [ ^ reports ].
	session materializer
		checkMaterializationBatchBytes: usedBytes
		label: labelString.
	offset := 9.
	limit := offset + usedBytes.
	[ offset < limit ] whileTrue: [
		| report used |
		used := self
			validatedObjectReportUsedBytesAt: traversalBuffer
			offset: offset
			limit: limit
			label: labelString.
		report := self reportAt: traversalBuffer offset: offset.
		reports at: report oop put: report.
		offset := offset + used ].
	offset = limit ifFalse: [
		GbsMaterializationTraversalError
			signalKind: #reportBoundary
			label: labelString
			observed: offset - limit
			message: 'GCI traversal buffer ended on a non-report boundary.' ].
	^ reports
]

{ #category : 'parsing' }
GbsMaterializationTraversalBufferReader >> validatedObjectReportUsedBytesAt: traversalBuffer offset: offset limit: limit label: labelString [
	| remaining valueSize idxSizeBits objectFormat used |
	remaining := limit - offset.
	remaining < self objectReportHeaderBytes ifTrue: [
		GbsMaterializationTraversalError
			signalKind: #incompleteReportHeader
			label: labelString
			observed: remaining
			message: 'GCI traversal buffer ended before a complete object report header.' ].
	valueSize := traversalBuffer integerAt: offset size: 4 signed: true.
	valueSize < 0 ifTrue: [
		GbsMaterializationTraversalError
			signalKind: #negativeValueSize
			label: labelString
			observed: valueSize
			message: 'GCI traversal object report has a negative value size.' ].
	idxSizeBits := (traversalBuffer integerAt: offset + 32 size: 8 signed: false) asInteger.
	objectFormat := idxSizeBits bitAnd: 3.
	(objectFormat ~= 1 and: [ valueSize \\ 8 ~= 0 ]) ifTrue: [
		GbsMaterializationTraversalError
			signalKind: #oopPayloadAlignment
			label: labelString
			observed: valueSize
			message: 'GCI traversal OOP object report value size is not 8-byte aligned.' ].
	used := self objectReportHeaderBytes + (self alignedByteCount: valueSize).
	used <= 0 ifTrue: [
		GbsMaterializationTraversalError
			signalKind: #invalidReportSize
			label: labelString
			observed: used
			message: 'Invalid GCI traversal object report size.' ].
	(offset + used) > limit ifTrue: [
		GbsMaterializationTraversalError
			signalKind: #incompleteReportPayload
			label: labelString
			observed: limit - offset
			message: 'GCI traversal buffer ended before the complete object report payload.' ].
	^ used
]

{ #category : 'parsing' }
GbsMaterializationTraversalBufferReader >> reportAt: traversalBuffer offset: offset [
	| valueSize namedSize objId classOop firstOffset idxSizeBits objectFormat byteSwizzle indexedSize valueOffset report |
	valueSize := traversalBuffer integerAt: offset size: 4 signed: true.
	namedSize := traversalBuffer integerAt: offset + 4 size: 2 signed: true.
	objId := (traversalBuffer integerAt: offset + 8 size: 8 signed: false) asInteger.
	classOop := (traversalBuffer integerAt: offset + 16 size: 8 signed: false) asInteger.
	firstOffset := (traversalBuffer integerAt: offset + 24 size: 8 signed: true) asInteger.
	idxSizeBits := (traversalBuffer integerAt: offset + 32 size: 8 signed: false) asInteger.
	objectFormat := idxSizeBits bitAnd: 3.
	byteSwizzle := (idxSizeBits bitAnd: 16r300) bitShift: -8.
	indexedSize := idxSizeBits bitShift: -24.
	valueOffset := offset + self objectReportHeaderBytes.
	report := GbsMaterializationTraversalReport new.
	report
		oop: objId;
		classOop: classOop;
		objectFormat: objectFormat;
		byteSwizzle: byteSwizzle;
		indexedSize: indexedSize;
		namedSize: namedSize;
		firstOffset: firstOffset.
	objectFormat = 1
		ifTrue: [ report valueBytes: (self byteArrayFromBuffer: traversalBuffer offset: valueOffset count: valueSize) ]
		ifFalse: [ report valueOops: (self oopArrayFromBuffer: traversalBuffer offset: valueOffset count: valueSize // 8) ].
	^ report
]

{ #category : 'traversal' }
GbsMaterializationTraversalBufferReader >> reportsForOops: oopCollection level: traversalLevel label: labelString [
	^ self
		reportsForOops: oopCollection
		level: traversalLevel
		label: labelString
		useClampedTraversal: true
]

{ #category : 'traversal' }
GbsMaterializationTraversalBufferReader >> plainReportsForOops: oopCollection level: traversalLevel label: labelString [
	^ self
		reportsForOops: oopCollection
		level: traversalLevel
		label: labelString
		useClampedTraversal: false
]

{ #category : 'traversal' }
GbsMaterializationTraversalBufferReader >> reportsForOops: oopCollection level: traversalLevel label: labelString useClampedTraversal: useClampedTraversal [
	| reports completed |
	oopCollection isEmpty ifTrue: [ ^ Dictionary new ].
	self checkAvailable.
	reports := Dictionary new.
	self
		withTraversalBufferDo: [ :traversalBuffer |
			self
				withOopBufferFor: oopCollection
				do: [ :oopBuffer |
					completed := self
						traverseOops: oopBuffer
						count: oopCollection size
						into: traversalBuffer
						level: traversalLevel
						useClampedTraversal: useClampedTraversal.
					session checkForError.
					self parseReportsFromBuffer: traversalBuffer into: reports label: labelString.
					[ completed = 0 or: [ completed == false ] ] whileTrue: [
						completed := session serverInterface apiGciMoreTraversal: traversalBuffer.
						session checkForError.
						self parseReportsFromBuffer: traversalBuffer into: reports label: labelString ] ] ].
	^ reports
]

{ #category : 'accessing' }
GbsMaterializationTraversalBufferReader >> session [
	^ session
]

{ #category : 'accessing' }
GbsMaterializationTraversalBufferReader >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbsMaterializationTraversalBufferReader >> traversalBufferBytes [
	| raw value env |
	raw := Smalltalk globals
		at: #GbsMaterializationTraversalBufferBytes
		ifAbsent: [
			env := [ OSEnvironment current ]
				on: Error
				do: [ Dictionary new ].
			env
				at: 'GBS_MATERIALIZATION_TRAVERSAL_BUFFER_BYTES'
				ifAbsent: [ self traversalBufferBytesFromReplicationPolicy ] ].
	value := [ raw asInteger ]
		on: Error
		do: [ self defaultTraversalBufferBytes ].
	value < 2048 ifTrue: [ value := 2048 ].
	^ self alignedByteCount: value
]

{ #category : 'accessing' }
GbsMaterializationTraversalBufferReader >> traversalBufferBytesFromReplicationPolicy [
	| policy |
	policy := [ GbsReplicationPolicy forSession: session ]
		on: Error
		do: [ nil ].
	(policy notNil and: [ policy respondsTo: #traversalBufferSize ]) ifTrue: [
		^ policy traversalBufferSize ].
	^ self defaultTraversalBufferBytes
]

{ #category : 'traversal' }
GbsMaterializationTraversalBufferReader >> traverseOops: oopBuffer count: oopCount into: traversalBuffer level: traversalLevel [
	^ self
		traverseOops: oopBuffer
		count: oopCount
		into: traversalBuffer
		level: traversalLevel
		useClampedTraversal: true
]

{ #category : 'traversal' }
GbsMaterializationTraversalBufferReader >> traverseOops: oopBuffer count: oopCount into: traversalBuffer level: traversalLevel useClampedTraversal: useClampedTraversal [
	| clampSpecOop |
	clampSpecOop := useClampedTraversal
		ifTrue: [ self clampedTraversalSpecOop ]
		ifFalse: [ nil ].
	(useClampedTraversal and: [ self supportsClampedTraversal and: [ clampSpecOop notNil ] ]) ifTrue: [
		session materializer incrementMaterializationMetric: #clampedTraversalBufferFetchCalls.
		^ (GbsClampedTraversalArguments
			clampSpecOop: clampSpecOop
			traversalBuffer: traversalBuffer
			level: traversalLevel
			retrievalFlags: 0)
				withNativeBufferDo: [ :clampedArgs |
					session serverInterface
						apiGciClampedTravOops: oopBuffer
						count: oopCount
						spec: clampedArgs ] ].
	^ session serverInterface
		apiGciTraverseOops: oopBuffer
		count: oopCount
		into: traversalBuffer
		level: traversalLevel
]

{ #category : 'testing' }
GbsMaterializationTraversalBufferReader >> supportsClampedTraversal [
	| interface |
	interface := session serverInterface.
	(interface respondsTo: #supportsClampedTraversalTransport) ifTrue: [
		^ interface supportsClampedTraversalTransport == true ].
	^ interface respondsTo: #apiGciClampedTravOops:count:spec:
]

{ #category : 'private' }
GbsMaterializationTraversalBufferReader >> withOopBufferFor: oopCollection do: aBlock [
	| buffer |
	buffer := ExternalAddress allocate: oopCollection size * 8.
	^ [
		oopCollection doWithIndex: [ :oop :index |
			buffer
				integerAt: 1 + ((index - 1) * 8)
				put: oop
				size: 8
				signed: false ].
		aBlock value: buffer
	] ensure: [ buffer free ]
]

{ #category : 'private' }
GbsMaterializationTraversalBufferReader >> withTraversalBufferDo: aBlock [
	| buffer |
	buffer := session serverInterface apiGciAllocTravBuf: self traversalBufferBytes.
	((buffer isNil) or: [
		(buffer respondsTo: #isNull)
			ifTrue: [ buffer isNull ]
			ifFalse: [ buffer = 0 ] ]) ifTrue: [
		GbsMaterializationTraversalError
			signalKind: #allocationFailed
			label: 'traversal-buffer allocation'
			message: 'GCI traversal buffer allocation failed.' ].
	^ [ aBlock value: buffer ]
		ensure: [ session serverInterface apiGciFree: buffer ]
]
