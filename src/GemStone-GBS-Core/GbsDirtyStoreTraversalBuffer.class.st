Class {
	#name : 'GbsDirtyStoreTraversalBuffer',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'flags',
		'payload',
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsDirtyStoreTraversalBuffer class >> entries: dirtyEntries [
	^ self new
		initializeEntries: dirtyEntries;
		yourself
]

{ #category : 'instance creation' }
GbsDirtyStoreTraversalBuffer class >> entries: dirtyEntries session: aSession [
	^ self new
		session: aSession;
		initializeEntries: dirtyEntries;
		yourself
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> alignedByteCount: byteCount [
	^ ((byteCount + 7) // 8) * 8
]

{ #category : 'private - encoding' }
GbsDirtyStoreTraversalBuffer >> appendByte: anInteger to: bytes [
	bytes add: (anInteger bitAnd: 255)
]

{ #category : 'private - encoding' }
GbsDirtyStoreTraversalBuffer >> appendBytes: aByteArray to: bytes [
	aByteArray do: [ :each | bytes add: each ]
]

{ #category : 'private - encoding' }
GbsDirtyStoreTraversalBuffer >> appendInteger32: anInteger to: bytes [
	self appendByte: (anInteger bitShift: -24) to: bytes.
	self appendByte: (anInteger bitShift: -16) to: bytes.
	self appendByte: (anInteger bitShift: -8) to: bytes.
	self appendByte: anInteger to: bytes
]

{ #category : 'private - encoding' }
GbsDirtyStoreTraversalBuffer >> appendInteger64: anInteger to: bytes [
	self appendInteger32: (anInteger bitShift: -32) to: bytes.
	self appendInteger32: anInteger to: bytes
]

{ #category : 'private - encoding' }
GbsDirtyStoreTraversalBuffer >> appendString: aString to: bytes [
	| encoded |
	encoded := aString utf8Encoded.
	self appendInteger32: encoded size to: bytes.
	self appendBytes: encoded to: bytes
]

{ #category : 'private - encoding' }
GbsDirtyStoreTraversalBuffer >> buildPayload [
	| bytes |
	bytes := OrderedCollection new.
	self appendBytes: #[71 66 83 68 83 84 49 0] to: bytes.
	self appendInteger32: entries size to: bytes.
	entries do: [ :entry |
		self
			appendInteger64: entry first
			to: bytes.
		self appendString: (entry at: 3) asString to: bytes.
		self appendInteger32: (self elementCountForEntry: entry) to: bytes ].
	^ ByteArray withAll: bytes
]

{ #category : 'native encoding' }
GbsDirtyStoreTraversalBuffer >> canProduceNativeTraversalBuffer [
	session ifNil: [ ^ false ].
	entries do: [ :entry |
		(self canProduceNativeTraversalReportForEntry: entry) ifFalse: [ ^ false ] ].
	^ true
]

{ #category : 'native encoding' }
GbsDirtyStoreTraversalBuffer >> canProduceNativeTraversalReportForEntry: entry [
	(#(#array #association #orderedCollection) includes: (entry at: 3)) ifFalse: [ ^ false ].
	(self nativeValuesForEntry: entry) do: [ :each |
		(self oopForValue: each ifAbsent: [ nil ]) ifNil: [
			each ifNotNil: [ ^ false ] ] ].
	^ true
]

{ #category : 'private - encoding' }
GbsDirtyStoreTraversalBuffer >> elementCountForEntry: entry [
	| object kind |
	object := entry second.
	kind := entry at: 3.
	kind = #association ifTrue: [ ^ 2 ].
	kind = #dictionary ifTrue: [ ^ object size * 2 ].
	^ object size
]

{ #category : 'accessing' }
GbsDirtyStoreTraversalBuffer >> entries [
	^ entries
]

{ #category : 'accessing' }
GbsDirtyStoreTraversalBuffer >> flags [
	^ flags ifNil: [ 8 ]
]

{ #category : 'accessing' }
GbsDirtyStoreTraversalBuffer >> flags: anInteger [
	flags := anInteger
]

{ #category : 'initialization' }
GbsDirtyStoreTraversalBuffer >> initializeEntries: dirtyEntries [
	entries := dirtyEntries asArray.
	flags := 8.
	payload := self buildPayload
]

{ #category : 'testing' }
GbsDirtyStoreTraversalBuffer >> isNativeTraversalBuffer [
	^ self canProduceNativeTraversalBuffer
]

{ #category : 'accessing' }
GbsDirtyStoreTraversalBuffer >> nativeTraversalBuffer [
	^ nil
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeHeaderBytes [
	^ 8
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeLogicalByteCount [
	^ (self nativeUsedBytes max: 2040)
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeObjectReportHeaderBytes [
	^ 40
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeTraversalBufferBytes [
	^ self nativeHeaderBytes + self nativeLogicalByteCount
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeUsedBytes [
	| used |
	used := 0.
	entries do: [ :entry |
		used := used
			+ self nativeObjectReportHeaderBytes
			+ (self alignedByteCount: (self nativeValueByteCountForEntry: entry)) ].
	^ used
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeValueByteCountForEntry: entry [
	^ (self nativeValuesForEntry: entry) size * 8
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeValuesForEntry: entry [
	| object kind |
	object := entry second.
	kind := entry at: 3.
	kind = #array ifTrue: [ ^ object asArray ].
	kind = #association ifTrue: [ ^ { object key. object value } ].
	kind = #orderedCollection ifTrue: [ ^ object asArray ].
	self error: 'Native dirty store traversal currently supports Arrays, Associations, and OrderedCollections only.'
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> oopForValue: anObject ifAbsent: absentBlock [
	| oop |
	anObject ifNil: [ ^ 20 ].
	anObject == true ifTrue: [ ^ 268 ].
	anObject == false ifTrue: [ ^ 12 ].
	(anObject isInteger and: [ self valueFitsGemStoneSmallInteger: anObject ]) ifTrue: [
		^ self unsignedOopForSignedOop: ((anObject bitShift: 3) + 2) ].
	(anObject isCharacter) ifTrue: [
		^ self unsignedOopForSignedOop: ((anObject codePoint bitShift: 3) + 6) ].
	oop := [ GbsMaterializedObjectDirtyTracker oopForObject: anObject inSession: session ]
		on: Error
		do: [ nil ].
	oop ifNotNil: [ ^ oop ].
	((anObject respondsTo: #oop) and: [
		(anObject respondsTo: #session) not or: [ anObject session == session ] ]) ifTrue: [
		^ anObject oop ].
	^ absentBlock value
]

{ #category : 'accessing' }
GbsDirtyStoreTraversalBuffer >> payload [
	^ payload
]

{ #category : 'accessing' }
GbsDirtyStoreTraversalBuffer >> session [
	^ session
]

{ #category : 'accessing' }
GbsDirtyStoreTraversalBuffer >> session: aSession [
	session := aSession
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> unsignedOopForSignedOop: anInteger [
	anInteger >= 0 ifTrue: [ ^ anInteger ].
	^ (1 bitShift: 64) + anInteger
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> valueFitsGemStoneSmallInteger: anInteger [
	^ anInteger
		between: -1152921504606846976
		and: 1152921504606846975
]

{ #category : 'native encoding' }
GbsDirtyStoreTraversalBuffer >> withNativeTraversalBufferOn: serverInterface do: aBlock [
	| buffer |
	self canProduceNativeTraversalBuffer ifFalse: [
		self error: 'Native dirty store traversal can encode only mapped Arrays, Associations, and OrderedCollections with OOP-addressable values.' ].
	buffer := serverInterface apiGciAllocTravBuf: self nativeTraversalBufferBytes.
	((buffer isNil) or: [
		(buffer respondsTo: #isNull)
			ifTrue: [ buffer isNull ]
			ifFalse: [ buffer = 0 ] ]) ifTrue: [
		self error: 'Could not allocate native dirty store traversal buffer.' ].
	^ [
		self writeNativeTraversalBuffer: buffer serverInterface: serverInterface.
		aBlock value: buffer
	] ensure: [ serverInterface apiGciFree: buffer ]
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> writeNativeTraversalBuffer: traversalBuffer serverInterface: serverInterface [
	| offset usedBytes |
	traversalBuffer
		integerAt: 1 put: self nativeLogicalByteCount size: 4 signed: false;
		integerAt: 5 put: 0 size: 4 signed: false.
	offset := self nativeHeaderBytes + 1.
	entries do: [ :entry |
		offset := self
			writePointerReportForEntry: entry
			on: traversalBuffer
			offset: offset
			serverInterface: serverInterface ].
	usedBytes := offset - self nativeHeaderBytes - 1.
	traversalBuffer integerAt: 5 put: usedBytes size: 4 signed: false.
	^ traversalBuffer
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> writePointerReportForEntry: entry on: traversalBuffer offset: offset serverInterface: serverInterface [
	| object kind values namedSize indexedSize |
	object := entry second.
	kind := entry at: 3.
	values := self nativeValuesForEntry: entry.
	namedSize := kind = #association
		ifTrue: [ 2 ]
		ifFalse: [ 0 ].
	indexedSize := kind = #association
		ifTrue: [ 0 ]
		ifFalse: [ object size ].
	^ self
		writePointerReportForEntry: entry
		values: values
		namedSize: namedSize
		indexedSize: indexedSize
		on: traversalBuffer
		offset: offset
		serverInterface: serverInterface
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> writePointerReportForEntry: entry values: values namedSize: namedSize indexedSize: indexedSize on: traversalBuffer offset: offset serverInterface: serverInterface [
	| oop classOop valueOops valueSize alignedSize valueOffset idxSizeBits |
	oop := entry first.
	classOop := (serverInterface apiGciGetClass: oop) asInteger.
	valueOops := values collect: [ :each |
		self oopForValue: each ifAbsent: [
			self error: 'Native dirty store traversal cannot encode value: ', each printString ] ].
	valueSize := valueOops size * 8.
	alignedSize := self alignedByteCount: valueSize.
	idxSizeBits := (indexedSize bitShift: 24) + 16r20.
	traversalBuffer
		integerAt: offset put: valueSize size: 4 signed: true;
		integerAt: offset + 4 put: namedSize size: 2 signed: true;
		integerAt: offset + 6 put: 16rFFFF size: 2 signed: false;
		integerAt: offset + 8 put: oop size: 8 signed: false;
		integerAt: offset + 16 put: classOop size: 8 signed: false;
		integerAt: offset + 24 put: 1 size: 8 signed: true;
		integerAt: offset + 32 put: idxSizeBits size: 8 signed: false.
	valueOffset := offset + self nativeObjectReportHeaderBytes.
	valueOops doWithIndex: [ :valueOop :index |
		traversalBuffer
			integerAt: valueOffset + ((index - 1) * 8)
			put: valueOop
			size: 8
			signed: false ].
	valueSize + 1 to: alignedSize do: [ :index |
		traversalBuffer unsignedByteAt: valueOffset + index - 1 put: 0 ].
	^ offset + self nativeObjectReportHeaderBytes + alignedSize
]
