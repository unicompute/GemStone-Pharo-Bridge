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
		self error: 'GCI traversal-buffer transport is not available for this session.' ]
]

{ #category : 'constants' }
GbsMaterializationTraversalBufferReader >> defaultTraversalBufferBytes [
	^ 1048576
]

{ #category : 'testing' }
GbsMaterializationTraversalBufferReader >> isAvailable [
	| interface |
	interface := session serverInterface.
	^ (interface respondsTo: #apiGciAllocTravBuf:)
		and: [ (interface respondsTo: #apiGciFree:)
		and: [ (interface respondsTo: #apiGciTraverseOops:count:into:level:)
		and: [ interface respondsTo: #apiGciMoreTraversal: ] ] ]
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
		report := self reportAt: traversalBuffer offset: offset.
		reports at: report oop put: report.
		used := self objectReportUsedBytesAt: traversalBuffer offset: offset.
		used <= 0 ifTrue: [ self error: 'Invalid GCI traversal object report size.' ].
		offset := offset + used ].
	offset = limit ifFalse: [
		self error: 'GCI traversal buffer ended on a non-report boundary.' ].
	^ reports
]

{ #category : 'parsing' }
GbsMaterializationTraversalBufferReader >> reportAt: traversalBuffer offset: offset [
	| valueSize namedSize objId classOop firstOffset idxSizeBits objectFormat indexedSize valueOffset report |
	valueSize := traversalBuffer integerAt: offset size: 4 signed: true.
	namedSize := traversalBuffer integerAt: offset + 4 size: 2 signed: true.
	objId := (traversalBuffer integerAt: offset + 8 size: 8 signed: false) asInteger.
	classOop := (traversalBuffer integerAt: offset + 16 size: 8 signed: false) asInteger.
	firstOffset := (traversalBuffer integerAt: offset + 24 size: 8 signed: true) asInteger.
	idxSizeBits := (traversalBuffer integerAt: offset + 32 size: 8 signed: false) asInteger.
	objectFormat := idxSizeBits bitAnd: 3.
	indexedSize := idxSizeBits bitShift: -24.
	valueOffset := offset + self objectReportHeaderBytes.
	report := GbsMaterializationTraversalReport new.
	report
		oop: objId;
		classOop: classOop;
		objectFormat: objectFormat;
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
	| reports completed |
	oopCollection isEmpty ifTrue: [ ^ Dictionary new ].
	self checkAvailable.
	reports := Dictionary new.
	self
		withTraversalBufferDo: [ :traversalBuffer |
			self
				withOopBufferFor: oopCollection
				do: [ :oopBuffer |
					completed := session serverInterface
						apiGciTraverseOops: oopBuffer
						count: oopCollection size
						into: traversalBuffer
						level: traversalLevel.
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
			env := [ Smalltalk os environment ]
				on: Error
				do: [ Dictionary new ].
			env
				at: 'GBS_MATERIALIZATION_TRAVERSAL_BUFFER_BYTES'
				ifAbsent: [ self defaultTraversalBufferBytes ] ].
	value := [ raw asInteger ]
		on: Error
		do: [ self defaultTraversalBufferBytes ].
	value < 2048 ifTrue: [ value := 2048 ].
	^ self alignedByteCount: value
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
		self error: 'GCI traversal buffer allocation failed.' ].
	^ [ aBlock value: buffer ]
		ensure: [ session serverInterface apiGciFree: buffer ]
]
