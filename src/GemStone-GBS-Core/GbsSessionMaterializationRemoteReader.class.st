Class {
	#name : 'GbsSessionMaterializationRemoteReader',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsSessionMaterializationRemoteReader class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> clearRemoteClassNameCache [
	(session class weakRegistryNamed: #GbsSessionRemoteClassNameCaches)
		at: session
		put: Dictionary new.
	(session class weakRegistryNamed: #GbsSessionRemoteClassNameByClassOopCaches)
		at: session
		put: Dictionary new.
	(session class weakRegistryNamed: #GbsSessionRemoteClassOopCaches)
		at: session
		put: Dictionary new.
	(session class weakRegistryNamed: #GbsSessionRemoteSizeCaches)
		at: session
		put: Dictionary new.
	(session class weakRegistryNamed: #GbsSessionRemoteArrayElementOopsCaches)
		at: session
		put: Dictionary new.
	(session class weakRegistryNamed: #GbsSessionRemoteDictionaryAssociationOopPairCaches)
		at: session
		put: Dictionary new.
	(session class weakRegistryNamed: #GbsSessionRemoteAssociationOopPairCaches)
		at: session
		put: Dictionary new.
	^ self remoteClassNameCache
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> batchesForOops: oopCollection [
	| batches batch batchSize |
	batchSize := self materializationBatchSize.
	batches := OrderedCollection new.
	batch := OrderedCollection new.
	oopCollection do: [ :oop |
		batch add: oop.
		batch size >= batchSize ifTrue: [
			batches add: batch asArray.
			batch := OrderedCollection new ] ].
	batch isEmpty ifFalse: [ batches add: batch asArray ].
	^ batches asArray
]

{ #category : 'metrics' }
GbsSessionMaterializationRemoteReader >> incrementMaterializationMetric: aSymbol [
	^ session materializer incrementMaterializationMetric: aSymbol
]

{ #category : 'metrics' }
GbsSessionMaterializationRemoteReader >> incrementMaterializationMetric: aSymbol by: anInteger [
	^ session materializer incrementMaterializationMetric: aSymbol by: anInteger
]

{ #category : 'metrics' }
GbsSessionMaterializationRemoteReader >> materializationBatchSize [
	^ [ session materializationBatchSize ]
		on: Error
		do: [ 1000 ]
]

{ #category : 'metrics' }
GbsSessionMaterializationRemoteReader >> recordMillisecondsForMetric: aSymbol during: aBlock [
	^ session materializer
		recordMillisecondsForMetric: aSymbol
		during: aBlock
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> parseOopPairLine: aString [
	| parts |
	parts := aString asString splitOn: Character tab.
	parts size < 2 ifTrue: [ self error: 'Expected two OOP values.' ].
	^ { parts first asInteger. parts second asInteger }
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> parseOopPairLines: aString [
	| pairs |
	pairs := OrderedCollection new.
	aString asString lines do: [ :line |
		line isEmpty ifFalse: [ pairs add: (self parseOopPairLine: line) ] ].
	^ pairs asArray
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> parseClassNameLines: aString [
	| classNames |
	self checkMaterializationBatchBytes: aString asString size label: 'class-name text batch'.
	classNames := Dictionary new.
	aString asString lines do: [ :line |
		line isEmpty ifFalse: [
			| parts |
			parts := line asString splitOn: Character tab.
			parts size < 2 ifTrue: [ self error: 'Expected an OOP and class name.' ].
			classNames at: parts first asInteger put: parts second asString ] ].
	^ classNames
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> parseArrayElementOopLines: aString [
	| elementOopsByOop |
	self checkMaterializationBatchBytes: aString asString size label: 'array-element text batch'.
	elementOopsByOop := Dictionary new.
	aString asString lines do: [ :line |
		line isEmpty ifFalse: [
			| parts oop size elementOops |
			parts := line asString splitOn: Character tab.
			parts size < 2 ifTrue: [ self error: 'Expected an OOP and element count.' ].
			oop := parts first asInteger.
			size := parts second asInteger.
			parts size < (size + 2) ifTrue: [ self error: 'Expected all element OOP values.' ].
			elementOops := Array new: size.
			1 to: size do: [ :index |
				elementOops
					at: index
					put: ((parts at: index + 2) asInteger) ].
			elementOopsByOop at: oop put: elementOops ] ].
	^ elementOopsByOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> parseOopValueLines: aString [
	| valuesByOop |
	self checkMaterializationBatchBytes: aString asString size label: 'OOP-value text batch'.
	valuesByOop := Dictionary new.
	aString asString lines do: [ :line |
		line isEmpty ifFalse: [
			| parts |
			parts := line asString splitOn: Character tab.
			parts size < 2 ifTrue: [ self error: 'Expected an OOP and value OOP.' ].
			valuesByOop
				at: parts first asInteger
				put: parts second asInteger ] ].
	^ valuesByOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> parseStringValueLines: aString [
	| valuesByOop |
	self checkMaterializationBatchBytes: aString asString size label: 'string-value text batch'.
	valuesByOop := Dictionary new.
	aString asString lines do: [ :line |
		line isEmpty ifFalse: [
			| parts oop size value |
			parts := line asString splitOn: Character tab.
			parts size < 2 ifTrue: [ self error: 'Expected an OOP and character count.' ].
			oop := parts first asInteger.
			size := parts second asInteger.
			parts size < (size + 2) ifTrue: [ self error: 'Expected all character code points.' ].
			value := String streamContents: [ :stream |
				1 to: size do: [ :index |
					stream nextPut: (Character codePoint: ((parts at: index + 2) asInteger)) ] ].
			valuesByOop at: oop put: value ] ].
	^ valuesByOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> parseByteArrayValueLines: aString [
	| valuesByOop |
	self checkMaterializationBatchBytes: aString asString size label: 'byte-array text batch'.
	valuesByOop := Dictionary new.
	aString asString lines do: [ :line |
		line isEmpty ifFalse: [
			| parts oop size value |
			parts := line asString splitOn: Character tab.
			parts size < 2 ifTrue: [ self error: 'Expected an OOP and byte count.' ].
			oop := parts first asInteger.
			size := parts second asInteger.
			parts size < (size + 2) ifTrue: [ self error: 'Expected all byte values.' ].
			value := ByteArray new: size.
			1 to: size do: [ :index |
				value at: index put: ((parts at: index + 2) asInteger) ].
			valuesByOop at: oop put: value ] ].
	^ valuesByOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> parseAssociationOopPairLines: aString [
	| pairsByOop |
	self checkMaterializationBatchBytes: aString asString size label: 'association-pair text batch'.
	pairsByOop := Dictionary new.
	aString asString lines do: [ :line |
		line isEmpty ifFalse: [
			| parts |
			parts := line asString splitOn: Character tab.
			parts size < 3 ifTrue: [ self error: 'Expected an association OOP, key OOP, and value OOP.' ].
			pairsByOop
				at: parts first asInteger
				put: { parts second asInteger. parts third asInteger } ] ].
	^ pairsByOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> parseDictionaryAssociationOopPairLines: aString [
	| pairsByOop |
	self checkMaterializationBatchBytes: aString asString size label: 'dictionary-pair text batch'.
	pairsByOop := Dictionary new.
	aString asString lines do: [ :line |
		line isEmpty ifFalse: [
			| parts oop size pairs |
			parts := line asString splitOn: Character tab.
			parts size < 2 ifTrue: [ self error: 'Expected a dictionary OOP and association count.' ].
			oop := parts first asInteger.
			size := parts second asInteger.
			parts size < ((size * 2) + 2) ifTrue: [ self error: 'Expected all dictionary association OOP pairs.' ].
			pairs := Array new: size.
			1 to: size do: [ :index |
				pairs
					at: index
					put: {
						(parts at: (index * 2) + 1) asInteger.
						(parts at: (index * 2) + 2) asInteger } ].
			pairsByOop at: oop put: pairs ] ].
	^ pairsByOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> oopPairsFromFlatOops: oopArray [
	| pairs |
	oopArray size even ifFalse: [ self error: 'Expected an even number of OOP values.' ].
	pairs := Array new: oopArray size // 2.
	1 to: pairs size do: [ :index |
		pairs
			at: index
			put: {
				oopArray at: (index * 2) - 1.
				oopArray at: index * 2 } ].
	^ pairs
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> checkMaterializationBatchBytes: byteCount label: aString [
	^ session materializer checkMaterializationBatchBytes: byteCount label: aString
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> integerFromStructuredBatchSlotOop: anOop [
	(session isImmediateOop: anOop) ifFalse: [
		self error: 'Expected an immediate integer in a structured materialization batch.' ].
	^ session resultFor: anOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> structuredBatchSlotsForBody: bodyString oopCollection: oopCollection [
	| bufferOop slots |
	self structuredBatchBuffersEnabled ifFalse: [
		self error: 'Structured materialization batch buffers are disabled for this session.' ].
	bufferOop := session
		returnRemoteCommandBody: bodyString
		literalBindings: (Dictionary new
			at: 'oops' put: oopCollection asArray;
			yourself)
		oopBindings: Dictionary new.
	slots := self rawArrayElementOopsForOop: bufferOop.
	self incrementMaterializationMetric: #structuredBatchBufferFetchCalls.
	self incrementMaterializationMetric: #structuredBatchBufferOopCount by: slots size.
	^ slots
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> structuredBatchBytesForBody: bodyString oopCollection: oopCollection label: aString [
	| bufferOop bytes |
	self structuredBatchBytesEnabled ifFalse: [
		self error: 'Structured materialization byte payloads are disabled for this session.' ].
	self prefersTraversalByteTransport ifTrue: [
		self traversalByteTransportAvailable
			ifTrue: [
				^ self
					traversalBatchBytesForBody: bodyString
					oopCollection: oopCollection
					label: aString ]
			ifFalse: [
				self incrementMaterializationMetric: #structuredTraversalByteFallbacks ] ].
	bufferOop := session
		returnRemoteCommandBody: bodyString
		literalBindings: (Dictionary new
			at: 'oops' put: oopCollection asArray;
			yourself)
		oopBindings: Dictionary new.
	bytes := self rawBytesForOop: bufferOop label: aString.
	self incrementMaterializationMetric: #structuredBatchByteFetchCalls.
	self incrementMaterializationMetric: #structuredBatchByteCount by: bytes size.
	^ bytes
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> traversalBufferReportsForOops: oopCollection level: traversalLevel label: aString [
	| reports |
	self traversalBufferTransportAvailable ifFalse: [
		self error: 'GCI traversal-buffer materialization transport is not available for this session.' ].
	reports := session
		materializationTraversalReportsForOops: oopCollection asArray
		level: traversalLevel
		label: aString.
	self incrementMaterializationMetric: #structuredTraversalBufferFetchCalls.
	self incrementMaterializationMetric: #structuredTraversalReportCount by: reports size.
	^ reports
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> traversalBufferTransportAvailable [
	(session respondsTo: #supportsMaterializationTraversalBufferTransport) ifTrue: [
		session supportsMaterializationTraversalBufferTransport ifFalse: [ ^ false ] ].
	^ session respondsTo: #materializationTraversalReportsForOops:level:label:
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> prefersTraversalByteTransport [
	^ self structuredBatchByteTransport = #traversalByte
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> prefersTraversalBufferTransport [
	^ self structuredBatchByteTransport = #traversalBuffer
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> structuredBatchByteTransport [
	| raw env normalized |
	raw := Smalltalk globals
		at: #GbsMaterializationByteTransport
		ifAbsent: [
			env := [ Smalltalk os environment ]
				on: Error
				do: [ Dictionary new ].
			env at: 'GBS_MATERIALIZATION_BYTE_TRANSPORT' ifAbsent: [ 'traversal-buffer' ] ].
	normalized := raw asString asLowercase copyReplaceAll: '_' with: '-'.
	normalized = 'traversal-buffer' ifTrue: [ ^ #traversalBuffer ].
	normalized = 'traversal' ifTrue: [ ^ #traversalByte ].
	^ #gciBytes
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> traversalByteTransportAvailable [
	(session respondsTo: #supportsMaterializationTraversalByteTransport) ifTrue: [
		session supportsMaterializationTraversalByteTransport ifFalse: [ ^ false ] ].
	^ session respondsTo: #materializationTraversalBytesForBody:literalBindings:label:
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> traversalBatchBytesForBody: bodyString oopCollection: oopCollection label: aString [
	| bytes |
	bytes := session
		materializationTraversalBytesForBody: bodyString
		literalBindings: (Dictionary new
			at: 'oops' put: oopCollection asArray;
			yourself)
		label: aString.
	bytes := ByteArray withAll: bytes.
	self checkMaterializationBatchBytes: bytes size label: aString.
	self incrementMaterializationMetric: #structuredTraversalByteFetchCalls.
	self incrementMaterializationMetric: #structuredTraversalByteCount by: bytes size.
	^ bytes
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> structuredBatchBytesEnabled [
	(session respondsTo: #supportsStructuredMaterializationBatchBytes)
		ifTrue: [ ^ session supportsStructuredMaterializationBatchBytes ].
	^ true
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> structuredBatchBuffersEnabled [
	(session respondsTo: #supportsStructuredMaterializationBatchBuffers)
		ifTrue: [ ^ session supportsStructuredMaterializationBatchBuffers ].
	^ true
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> rawArrayElementOopsForOop: anOop [
	| size buffer fetched oops |
	size := (session serverInterface apiGciFetchSize: anOop) asInteger.
	size = 0 ifTrue: [ ^ #() ].
	self
		checkMaterializationBatchBytes: size * 8
		label: 'structured batch OOP buffer'.
	buffer := ExternalAddress allocate: size * 8.
	^ [
		fetched := session serverInterface
			apiGciFetchOops: anOop
			startingAt: 1
			into: buffer
			size: size.
		(fetched isCollection and: [ fetched isString not ])
			ifTrue: [ fetched asArray ]
			ifFalse: [
				oops := Array new: size.
				1 to: size do: [ :index |
					oops
						at: index
						put: ((buffer
							integerAt: 1 + ((index - 1) * 8)
							size: 8
							signed: false) asInteger) ].
				oops ] ]
		ensure: [ buffer free ]
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> rawBytesForOop: anOop label: aString [
	| size buffer fetched bytes |
	size := (session serverInterface apiGciFetchSize: anOop) asInteger.
	size = 0 ifTrue: [ ^ ByteArray new ].
	self
		checkMaterializationBatchBytes: size
		label: aString.
	buffer := ExternalAddress allocate: size.
	^ [
		fetched := session serverInterface
			apiGciFetchBytes: anOop
			startingAt: 1
			into: buffer
			size: size.
		(fetched isCollection and: [ fetched isString not ])
			ifTrue: [ ByteArray withAll: fetched ]
			ifFalse: [
				bytes := ByteArray new: size.
				1 to: size do: [ :index |
					bytes at: index put: (buffer unsignedByteAt: index) ].
				bytes ] ]
		ensure: [ buffer free ]
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> rawStringForOop: anOop label: aString [
	^ self stringFromBytes: (self rawBytesForOop: anOop label: aString)
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> stringFromBytes: byteArray [
	^ String streamContents: [ :stream |
		byteArray do: [ :byte | stream nextPut: byte asCharacter ] ]
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> uint32FromBytes: byteArray at: offset [
	offset + 3 > byteArray size ifTrue: [
		self error: 'Structured byte payload ended early while reading an integer.' ].
	^ (((byteArray at: offset) bitShift: 24)
		+ ((byteArray at: offset + 1) bitShift: 16)
		+ ((byteArray at: offset + 2) bitShift: 8)
		+ (byteArray at: offset + 3)) asInteger
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> stringDictionaryFromPackedBytes: byteArray forOops: oopCollection [
	| values offset |
	values := Dictionary new.
	offset := 1.
	oopCollection do: [ :oop |
		| size value |
		size := self uint32FromBytes: byteArray at: offset.
		offset := offset + 4.
		offset + (size * 4) - 1 > byteArray size ifTrue: [
			self error: 'Structured string byte payload is missing character codes.' ].
		value := String streamContents: [ :stream |
			1 to: size do: [ :index |
				stream nextPut: (Character codePoint: (self uint32FromBytes: byteArray at: offset)).
				offset := offset + 4 ] ].
		values at: oop put: value ].
	offset = (byteArray size + 1) ifFalse: [
		self error: 'Structured string byte payload has trailing data.' ].
	^ values
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> byteArrayDictionaryFromPackedBytes: byteArray forOops: oopCollection [
	| values offset |
	values := Dictionary new.
	offset := 1.
	oopCollection do: [ :oop |
		| size value |
		size := self uint32FromBytes: byteArray at: offset.
		offset := offset + 4.
		offset + size - 1 > byteArray size ifTrue: [
			self error: 'Structured byte-array payload is missing bytes.' ].
		value := ByteArray new: size.
		1 to: size do: [ :index |
			value at: index put: (byteArray at: offset).
			offset := offset + 1 ].
		values at: oop put: value ].
	offset = (byteArray size + 1) ifFalse: [
		self error: 'Structured byte-array payload has trailing data.' ].
	^ values
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> classNameDictionaryFromStructuredSlots: slots forOops: oopCollection [
	| classNames offset |
	classNames := Dictionary new.
	offset := 1.
	oopCollection do: [ :oop |
		| size value |
		offset > slots size ifTrue: [ self error: 'Structured class-name batch ended early.' ].
		size := self integerFromStructuredBatchSlotOop: (slots at: offset).
		offset := offset + 1.
		offset + size - 1 > slots size ifTrue: [ self error: 'Structured class-name batch is missing character codes.' ].
		value := String streamContents: [ :stream |
			1 to: size do: [ :index |
				stream nextPut: (Character codePoint: (self integerFromStructuredBatchSlotOop: (slots at: offset))).
				offset := offset + 1 ] ].
		classNames at: oop put: value ].
	offset = (slots size + 1) ifFalse: [ self error: 'Structured class-name batch has trailing data.' ].
	^ classNames
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> arrayElementOopDictionaryFromStructuredSlots: slots forOops: oopCollection [
	| elementOopsByOop offset |
	elementOopsByOop := Dictionary new.
	offset := 1.
	oopCollection do: [ :oop |
		| size elementOops |
		offset > slots size ifTrue: [ self error: 'Structured array-element batch ended early.' ].
		size := self integerFromStructuredBatchSlotOop: (slots at: offset).
		offset := offset + 1.
		offset + size - 1 > slots size ifTrue: [ self error: 'Structured array-element batch is missing element OOPs.' ].
		elementOops := Array new: size.
		1 to: size do: [ :index |
			elementOops at: index put: (slots at: offset).
			offset := offset + 1 ].
		elementOopsByOop at: oop put: elementOops ].
	offset = (slots size + 1) ifFalse: [ self error: 'Structured array-element batch has trailing data.' ].
	^ elementOopsByOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> oopValueDictionaryFromStructuredSlots: slots forOops: oopCollection [
	| valuesByOop |
	slots size = oopCollection size ifFalse: [ self error: 'Structured OOP-value batch size mismatch.' ].
	valuesByOop := Dictionary new.
	oopCollection doWithIndex: [ :oop :index |
		valuesByOop at: oop put: (slots at: index) ].
	^ valuesByOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> associationOopPairDictionaryFromStructuredSlots: slots forOops: oopCollection [
	| pairsByOop offset |
	slots size = (oopCollection size * 2) ifFalse: [ self error: 'Structured association-pair batch size mismatch.' ].
	pairsByOop := Dictionary new.
	offset := 1.
	oopCollection do: [ :oop |
		pairsByOop
			at: oop
			put: {
				slots at: offset.
				slots at: offset + 1 }.
		offset := offset + 2 ].
	^ pairsByOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> dictionaryAssociationOopPairDictionaryFromStructuredSlots: slots forOops: oopCollection [
	| pairsByOop offset |
	pairsByOop := Dictionary new.
	offset := 1.
	oopCollection do: [ :oop |
		| size pairs |
		offset > slots size ifTrue: [ self error: 'Structured dictionary-pair batch ended early.' ].
		size := self integerFromStructuredBatchSlotOop: (slots at: offset).
		offset := offset + 1.
		offset + (size * 2) - 1 > slots size ifTrue: [ self error: 'Structured dictionary-pair batch is missing key/value OOPs.' ].
		pairs := Array new: size.
		1 to: size do: [ :index |
			pairs
				at: index
				put: {
					slots at: offset.
					slots at: offset + 1 }.
			offset := offset + 2 ].
		pairsByOop at: oop put: pairs ].
	offset = (slots size + 1) ifFalse: [ self error: 'Structured dictionary-pair batch has trailing data.' ].
	^ pairsByOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> stringValueDictionaryFromStructuredSlots: slots forOops: oopCollection [
	| valuesByOop offset |
	valuesByOop := Dictionary new.
	offset := 1.
	oopCollection do: [ :oop |
		| size value |
		offset > slots size ifTrue: [ self error: 'Structured string batch ended early.' ].
		size := self integerFromStructuredBatchSlotOop: (slots at: offset).
		offset := offset + 1.
		offset + size - 1 > slots size ifTrue: [ self error: 'Structured string batch is missing character codes.' ].
		value := String streamContents: [ :stream |
			1 to: size do: [ :index |
				stream nextPut: (Character codePoint: (self integerFromStructuredBatchSlotOop: (slots at: offset))).
				offset := offset + 1 ] ].
		valuesByOop at: oop put: value ].
	offset = (slots size + 1) ifFalse: [ self error: 'Structured string batch has trailing data.' ].
	^ valuesByOop
]

{ #category : 'private' }
GbsSessionMaterializationRemoteReader >> byteArrayValueDictionaryFromStructuredSlots: slots forOops: oopCollection [
	| valuesByOop offset |
	valuesByOop := Dictionary new.
	offset := 1.
	oopCollection do: [ :oop |
		| size value |
		offset > slots size ifTrue: [ self error: 'Structured byte-array batch ended early.' ].
		size := self integerFromStructuredBatchSlotOop: (slots at: offset).
		offset := offset + 1.
		offset + size - 1 > slots size ifTrue: [ self error: 'Structured byte-array batch is missing byte values.' ].
		value := ByteArray new: size.
		1 to: size do: [ :index |
			value at: index put: (self integerFromStructuredBatchSlotOop: (slots at: offset)).
			offset := offset + 1 ].
		valuesByOop at: oop put: value ].
	offset = (slots size + 1) ifFalse: [ self error: 'Structured byte-array batch has trailing data.' ].
	^ valuesByOop
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopAt: anInteger ofOop: anOop [
	self incrementMaterializationMetric: #slotCommandCalls.
	^ self
		recordMillisecondsForMetric: #slotFetchMs
		during: [
			session
				returnRemoteCommandBody: 'object at: index'
				literalBindings: (Dictionary new
					at: 'index' put: anInteger;
					yourself)
				oopBindings: (Dictionary new
					at: 'object' put: anOop;
					yourself) ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsForOop: anOop [
	^ self remoteArrayElementOopsCache
		at: anOop
		ifAbsentPut: [
			| size |
			size := self remoteSizeForOop: anOop.
			size <= 0
				ifTrue: [ #() ]
				ifFalse: [
					[ self remoteArrayElementOopsViaGciForOop: anOop size: size ]
						on: Error
						do: [ self remoteArrayElementOopsViaCommandsForOop: anOop size: size ] ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsForOops: oopCollection [
	| result cache missing batches |
	result := Dictionary new.
	cache := self remoteArrayElementOopsCache.
	missing := OrderedCollection new.
	oopCollection do: [ :oop |
		(cache includesKey: oop)
			ifTrue: [ result at: oop put: (cache at: oop) ]
			ifFalse: [
				(missing includes: oop) ifFalse: [ missing add: oop ] ] ].
	missing isEmpty ifTrue: [ ^ result ].
	batches := self batchesForOops: missing.
	batches do: [ :batch |
		| fetched |
		fetched := self remoteArrayElementOopsDictionaryForOopsAdaptive: batch.
		batch do: [ :oop |
			| elementOops |
			elementOops := fetched
				at: oop
				ifAbsent: [
					self incrementMaterializationMetric: #frontierSlotFallbackCalls.
					self remoteArrayElementOopsForOop: oop ].
			cache at: oop put: elementOops.
			result at: oop put: elementOops ] ].
	^ result
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteArrayElementOopsCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsViaCommandsForOop: anOop size: size [
	| oops |
	self incrementMaterializationMetric: #slotFallbackCalls.
	oops := Array new: size.
	1 to: size do: [ :index |
		oops at: index put: (self remoteArrayElementOopAt: index ofOop: anOop) ].
	^ oops
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsDictionaryForOops: oopCollection [
	| fetched total |
	self incrementMaterializationMetric: #frontierSlotBatchCalls.
	self incrementMaterializationMetric: #frontierSlotBatchObjectCount by: oopCollection size.
	fetched := self
		recordMillisecondsForMetric: #frontierSlotFetchMs
		during: [
			[
				self arrayElementOopDictionaryFromStructuredSlots: (self
					structuredBatchSlotsForBody: '| sizes total buffer offset object |
sizes := Array new: oops size.
total := 0.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	sizes at: oopIndex put: object size.
	total := total + object size + 1 ].
buffer := Array new: total.
offset := 1.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	buffer at: offset put: object size.
	offset := offset + 1.
	1 to: object size do: [ :index |
		buffer at: offset put: (object at: index).
		offset := offset + 1 ] ].
buffer'
					oopCollection: oopCollection)
					forOops: oopCollection ]
				on: Error
				do: [
					self incrementMaterializationMetric: #structuredBatchFallbacks.
					self parseArrayElementOopLines: (session
						fetchRemoteCommandBody: '| stream object |
stream := WriteStream on: String new.
oops do: [ :oop |
	object := Object _objectForOop: oop.
	stream
		nextPutAll: oop asString;
		nextPut: Character tab;
		nextPutAll: object size asString.
	1 to: object size do: [ :index |
		stream
			nextPut: Character tab;
			nextPutAll: (object at: index) asOop asString ].
	stream nextPut: Character lf ].
stream contents'
						literalBindings: (Dictionary new
							at: 'oops' put: oopCollection asArray;
							yourself)
						oopBindings: Dictionary new
						context: 20) ] ].
	total := 0.
	fetched valuesDo: [ :each | total := total + each size ].
	self incrementMaterializationMetric: #frontierSlotBatchOopCount by: total.
	^ fetched
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsDictionaryForOopsAdaptive: oopCollection [
	^ [ self remoteArrayElementOopsDictionaryForOops: oopCollection ]
		on: Error
		do: [ :ex |
			| left right merged splitIndex singleton |
			self incrementMaterializationMetric: #frontierSlotBatchFallbacks.
			oopCollection size <= 1 ifTrue: [
				self incrementMaterializationMetric: #frontierSlotFallbackCalls.
				singleton := Dictionary new.
				singleton
					at: oopCollection first
					put: (self remoteArrayElementOopsForOop: oopCollection first).
				singleton ] ifFalse: [
				self incrementMaterializationMetric: #frontierSlotBatchSplits.
				splitIndex := oopCollection size // 2.
				left := oopCollection copyFrom: 1 to: splitIndex.
				right := oopCollection copyFrom: splitIndex + 1 to: oopCollection size.
				merged := self remoteArrayElementOopsDictionaryForOopsAdaptive: left.
				(self remoteArrayElementOopsDictionaryForOopsAdaptive: right)
					associationsDo: [ :association |
						merged at: association key put: association value ].
				merged ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteArrayElementOopsViaGciForOop: anOop size: size [
	| buffer fetched oops |
	self incrementMaterializationMetric: #slotBatchCalls.
	self incrementMaterializationMetric: #slotBatchOopCount by: size.
	buffer := ExternalAddress allocate: size * 8.
	^ [
		self
			recordMillisecondsForMetric: #slotFetchMs
			during: [
				fetched := session serverInterface
					apiGciFetchOops: anOop
					startingAt: 1
					into: buffer
					size: size.
				(fetched isCollection and: [ fetched isString not ])
					ifTrue: [ fetched asArray ]
					ifFalse: [
						oops := Array new: size.
						1 to: size do: [ :index |
							oops
								at: index
								put: ((buffer
									integerAt: 1 + ((index - 1) * 8)
									size: 8
									signed: false) asInteger) ].
						oops ] ]
	] ensure: [ buffer free ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteAssociationOopPairCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteAssociationOopPairCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteAssociationOopPairForOop: anOop [
	^ self remoteAssociationOopPairCache
		at: anOop
		ifAbsentPut: [
			[ self remoteArrayElementOopsForOop: (self remoteAssociationPairOopFor: anOop) ]
				on: Error
				do: [ self parseOopPairLine: (session
			fetchRemoteCommandBody: '| stream |
stream := WriteStream on: String new.
stream
	nextPutAll: assoc key asOop asString;
	nextPut: Character tab;
	nextPutAll: assoc value asOop asString.
stream contents'
			literalBindings: Dictionary new
			oopBindings: (Dictionary new
				at: 'assoc' put: anOop;
				yourself)
			context: 20) ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteAssociationOopPairsForOops: oopCollection [
	| result cache missing batches |
	result := Dictionary new.
	cache := self remoteAssociationOopPairCache.
	missing := OrderedCollection new.
	oopCollection do: [ :oop |
		(cache includesKey: oop)
			ifTrue: [ result at: oop put: (cache at: oop) ]
			ifFalse: [
				(missing includes: oop) ifFalse: [ missing add: oop ] ] ].
	missing isEmpty ifTrue: [ ^ result ].
	batches := self batchesForOops: missing.
	batches do: [ :batch |
		| fetched |
		fetched := self remoteAssociationOopPairDictionaryForOopsAdaptive: batch.
		batch do: [ :oop |
			| pair |
			pair := fetched
				at: oop
				ifAbsent: [
					self incrementMaterializationMetric: #associationPairFallbackCalls.
					self remoteAssociationOopPairForOop: oop ].
			cache at: oop put: pair.
			result at: oop put: pair ] ].
	^ result
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteAssociationOopPairDictionaryForOops: oopCollection [
	self incrementMaterializationMetric: #associationPairBatchCalls.
	self incrementMaterializationMetric: #associationPairBatchObjectCount by: oopCollection size.
	^ self
		recordMillisecondsForMetric: #associationPairBatchMs
		during: [
			[
				self associationOopPairDictionaryFromStructuredSlots: (self
					structuredBatchSlotsForBody: '| buffer offset assoc |
buffer := Array new: oops size * 2.
offset := 1.
oops do: [ :oop |
	assoc := Object _objectForOop: oop.
	buffer at: offset put: assoc key.
	buffer at: offset + 1 put: assoc value.
	offset := offset + 2 ].
buffer'
					oopCollection: oopCollection)
					forOops: oopCollection ]
				on: Error
				do: [
					self incrementMaterializationMetric: #structuredBatchFallbacks.
					self parseAssociationOopPairLines: (session
						fetchRemoteCommandBody: '| stream assoc |
stream := WriteStream on: String new.
oops do: [ :oop |
	assoc := Object _objectForOop: oop.
	stream
		nextPutAll: oop asString;
		nextPut: Character tab;
		nextPutAll: assoc key asOop asString;
		nextPut: Character tab;
		nextPutAll: assoc value asOop asString;
		nextPut: Character lf ].
stream contents'
						literalBindings: (Dictionary new
							at: 'oops' put: oopCollection asArray;
							yourself)
						oopBindings: Dictionary new
						context: 20) ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteAssociationOopPairDictionaryForOopsAdaptive: oopCollection [
	^ [ self remoteAssociationOopPairDictionaryForOops: oopCollection ]
		on: Error
		do: [ :ex |
			| left right merged splitIndex singleton |
			self incrementMaterializationMetric: #associationPairBatchFallbacks.
			oopCollection size <= 1 ifTrue: [
				self incrementMaterializationMetric: #associationPairFallbackCalls.
				singleton := Dictionary new.
				singleton
					at: oopCollection first
					put: (self remoteAssociationOopPairForOop: oopCollection first).
				singleton ] ifFalse: [
				self incrementMaterializationMetric: #associationPairBatchSplits.
				splitIndex := oopCollection size // 2.
				left := oopCollection copyFrom: 1 to: splitIndex.
				right := oopCollection copyFrom: splitIndex + 1 to: oopCollection size.
				merged := self remoteAssociationOopPairDictionaryForOopsAdaptive: left.
				(self remoteAssociationOopPairDictionaryForOopsAdaptive: right)
					associationsDo: [ :association |
						merged at: association key put: association value ].
				merged ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteAssociationPairOopFor: anOop [
	^ session
		returnRemoteCommandBody: 'Array with: assoc key with: assoc value'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'assoc' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameForOop: anOop [
	^ [ self remoteClassNameForClassOop: (self remoteClassOopForOop: anOop) ]
		on: Error
		do: [ self remoteClassNameForObjectOop: anOop ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameForClassOop: classOop [
	^ self remoteClassNameByClassOopCache
		at: classOop
		ifAbsentPut: [
			self incrementMaterializationMetric: #classNameByClassOopCalls.
			self
				recordMillisecondsForMetric: #classNameByClassOopMs
				during: [
					[ self remoteClassNameForClassOopViaGci: classOop ]
						on: Error
						do: [ self remoteClassNameForClassOopViaCommand: classOop ] ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameForClassOopViaCommand: classOop [
	^ session
		fetchRemoteCommandBody: 'classObject name asString'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'classObject' put: classOop;
			yourself)
		context: 20
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameForClassOopViaGci: classOop [
	| nameOop |
	(session serverInterface respondsTo: #apiGciFetchNameOfClass:) ifFalse: [
		self error: 'GciFetchNameOfClass is not available.' ].
	nameOop := session serverInterface apiGciFetchNameOfClass: classOop.
	^ self rawStringForOop: nameOop label: 'class-name GCI fetch'
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteClassNameByClassOopCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteClassNameByClassOopCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameForObjectOop: anOop [
	^ self remoteClassNameCache
		at: anOop
		ifAbsentPut: [
			self incrementMaterializationMetric: #classNameObjectCalls.
			self
				recordMillisecondsForMetric: #classNameObjectMs
				during: [
					session
						fetchRemoteCommandBody: 'object class name asString'
						literalBindings: Dictionary new
						oopBindings: (Dictionary new
							at: 'object' put: anOop;
							yourself)
							context: 20 ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameDictionaryForOops: oopCollection [
	self incrementMaterializationMetric: #classNameBatchCalls.
	self incrementMaterializationMetric: #classNameBatchOopCount by: oopCollection size.
	self prefersTraversalBufferTransport ifTrue: [
		[
			^ self
				recordMillisecondsForMetric: #classNameBatchMs
				during: [ self remoteClassNameDictionaryFromTraversalForOops: oopCollection ] ]
			on: Error
			do: [ self incrementMaterializationMetric: #structuredTraversalBufferFallbacks ] ].
	^ self
		recordMillisecondsForMetric: #classNameBatchMs
		during: [
			[
				self stringDictionaryFromPackedBytes: (self
					structuredBatchBytesForBody: '| sizes total buffer offset object text char code writeInteger |
sizes := Array new: oops size.
total := 0.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	text := object class name asString.
	sizes at: oopIndex put: text size.
	total := total + 4 + (text size * 4) ].
buffer := ByteArray new: total.
offset := 1.
writeInteger := [ :value |
	buffer at: offset put: ((value bitShift: -24) bitAnd: 255).
	buffer at: offset + 1 put: ((value bitShift: -16) bitAnd: 255).
	buffer at: offset + 2 put: ((value bitShift: -8) bitAnd: 255).
	buffer at: offset + 3 put: (value bitAnd: 255).
	offset := offset + 4 ].
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	text := object class name asString.
	writeInteger value: text size.
	1 to: text size do: [ :index |
		char := text at: index.
		code := [ char asInteger ] on: Error do: [
			[ char codePoint ] on: Error do: [ char asciiValue ] ].
		writeInteger value: code ] ].
buffer'
					oopCollection: oopCollection
					label: 'class-name byte batch')
					forOops: oopCollection ]
				on: Error
				do: [
					self incrementMaterializationMetric: #structuredByteBatchFallbacks.
					[
						self classNameDictionaryFromStructuredSlots: (self
							structuredBatchSlotsForBody: '| sizes total buffer offset object text char code |
sizes := Array new: oops size.
total := 0.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	text := object class name asString.
	sizes at: oopIndex put: text size.
	total := total + text size + 1 ].
buffer := Array new: total.
offset := 1.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	text := object class name asString.
	buffer at: offset put: text size.
	offset := offset + 1.
	1 to: text size do: [ :index |
		char := text at: index.
		code := [ char asInteger ] on: Error do: [
			[ char codePoint ] on: Error do: [ char asciiValue ] ].
		buffer at: offset put: code.
		offset := offset + 1 ] ].
buffer'
							oopCollection: oopCollection)
							forOops: oopCollection ]
						on: Error
						do: [
							self incrementMaterializationMetric: #structuredBatchFallbacks.
							self parseClassNameLines: (session
								fetchRemoteCommandBody: '| stream object |
stream := WriteStream on: String new.
oops do: [ :oop |
	object := Object _objectForOop: oop.
	stream
		nextPutAll: oop asString;
		nextPut: Character tab;
		nextPutAll: object class name asString;
		nextPut: Character lf ].
stream contents'
				literalBindings: (Dictionary new
					at: 'oops' put: oopCollection asArray;
					yourself)
				oopBindings: Dictionary new
				context: 20) ] ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameDictionaryFromTraversalForOops: oopCollection [
	| reports classNames |
	reports := self
		traversalBufferReportsForOops: oopCollection
		level: 1
		label: 'class-name traversal batch'.
	classNames := Dictionary new.
	oopCollection do: [ :oop |
		| report |
		report := reports at: oop ifAbsent: [
			self error: 'GCI traversal class-name batch did not include requested OOP.' ].
		classNames
			at: oop
			put: (self remoteClassNameForClassOop: report classOop) ].
	^ classNames
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNamesForOops: oopCollection [
	| result cache missing batches |
	result := Dictionary new.
	cache := self remoteClassNameCache.
	missing := OrderedCollection new.
	oopCollection do: [ :oop |
		(cache includesKey: oop)
			ifTrue: [ result at: oop put: (cache at: oop) ]
			ifFalse: [
				(missing includes: oop) ifFalse: [
					missing add: oop ] ] ].
	missing isEmpty ifTrue: [ ^ result ].
	batches := self batchesForOops: missing.
	batches do: [ :batch |
		| fetched |
		fetched := self remoteClassNameDictionaryForOopsAdaptive: batch.
		batch do: [ :oop |
			| className |
			className := fetched
				at: oop
				ifAbsent: [
					self incrementMaterializationMetric: #classNameFallbackCalls.
					self remoteClassNameForOop: oop ].
			cache at: oop put: className.
			result at: oop put: className ] ].
	^ result
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassNameDictionaryForOopsAdaptive: oopCollection [
	^ [ self remoteClassNameDictionaryForOops: oopCollection ]
		on: Error
		do: [ :ex |
			| left right merged splitIndex singleton |
			self incrementMaterializationMetric: #classNameBatchFallbacks.
			oopCollection size <= 1 ifTrue: [
				self incrementMaterializationMetric: #classNameFallbackCalls.
				singleton := Dictionary new.
				singleton
					at: oopCollection first
					put: (self remoteClassNameForOop: oopCollection first).
				singleton ] ifFalse: [
				self incrementMaterializationMetric: #classNameBatchSplits.
				splitIndex := oopCollection size // 2.
				left := oopCollection copyFrom: 1 to: splitIndex.
				right := oopCollection copyFrom: splitIndex + 1 to: oopCollection size.
				merged := self remoteClassNameDictionaryForOopsAdaptive: left.
				(self remoteClassNameDictionaryForOopsAdaptive: right)
					associationsDo: [ :association |
						merged at: association key put: association value ].
				merged ] ]
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteClassNameCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteClassNameCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteCollectionAsArrayOop: anOop [
	^ session
		returnRemoteCommandBody: 'object asArray'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteCollectionAsArrayOopsForOops: oopCollection [
	| result batches |
	result := Dictionary new.
	batches := self batchesForOops: oopCollection.
	batches do: [ :batch |
		| fetched |
		fetched := self remoteCollectionAsArrayOopDictionaryForOopsAdaptive: batch.
		batch do: [ :oop |
			| arrayOop |
			arrayOop := fetched
				at: oop
				ifAbsent: [
					self incrementMaterializationMetric: #collectionArrayFallbackCalls.
					self remoteCollectionAsArrayOop: oop ].
			result at: oop put: arrayOop ] ].
	^ result
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteCollectionAsArrayOopDictionaryForOops: oopCollection [
	self incrementMaterializationMetric: #collectionArrayBatchCalls.
	self incrementMaterializationMetric: #collectionArrayBatchObjectCount by: oopCollection size.
	^ self
		recordMillisecondsForMetric: #collectionArrayBatchMs
		during: [
			[
				self oopValueDictionaryFromStructuredSlots: (self
					structuredBatchSlotsForBody: '| buffer object |
buffer := Array new: oops size.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	buffer at: oopIndex put: object asArray ].
buffer'
					oopCollection: oopCollection)
					forOops: oopCollection ]
				on: Error
				do: [
					self incrementMaterializationMetric: #structuredBatchFallbacks.
					self parseOopValueLines: (session
						fetchRemoteCommandBody: '| stream object array |
stream := WriteStream on: String new.
oops do: [ :oop |
	object := Object _objectForOop: oop.
	array := object asArray.
	stream
		nextPutAll: oop asString;
		nextPut: Character tab;
		nextPutAll: array asOop asString;
		nextPut: Character lf ].
stream contents'
				literalBindings: (Dictionary new
					at: 'oops' put: oopCollection asArray;
					yourself)
				oopBindings: Dictionary new
				context: 20) ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteCollectionAsArrayOopDictionaryForOopsAdaptive: oopCollection [
	^ [ self remoteCollectionAsArrayOopDictionaryForOops: oopCollection ]
		on: Error
		do: [ :ex |
			| left right merged splitIndex singleton |
			self incrementMaterializationMetric: #collectionArrayBatchFallbacks.
			oopCollection size <= 1 ifTrue: [
				self incrementMaterializationMetric: #collectionArrayFallbackCalls.
				singleton := Dictionary new.
				singleton
					at: oopCollection first
					put: (self remoteCollectionAsArrayOop: oopCollection first).
				singleton ] ifFalse: [
				self incrementMaterializationMetric: #collectionArrayBatchSplits.
				splitIndex := oopCollection size // 2.
				left := oopCollection copyFrom: 1 to: splitIndex.
				right := oopCollection copyFrom: splitIndex + 1 to: oopCollection size.
				merged := self remoteCollectionAsArrayOopDictionaryForOopsAdaptive: left.
				(self remoteCollectionAsArrayOopDictionaryForOopsAdaptive: right)
					associationsDo: [ :association |
						merged at: association key put: association value ].
				merged ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteClassOopForOop: anOop [
	^ self remoteClassOopCache
		at: anOop
		ifAbsentPut: [
			self incrementMaterializationMetric: #classOopCalls.
			self
				recordMillisecondsForMetric: #classOopMs
				during: [ (session serverInterface apiGciGetClass: anOop) asInteger ] ]
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteClassOopCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteClassOopCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationOopPairsForOop: anOop [
	^ self remoteDictionaryAssociationOopPairCache
		at: anOop
		ifAbsentPut: [
			[ self oopPairsFromFlatOops: (self
				remoteArrayElementOopsForOop: (self remoteDictionaryAssociationPairsArrayOopFor: anOop)) ]
				on: Error
				do: [
					[ self parseOopPairLines: (session
						fetchRemoteCommandBody: '| stream |
	stream := WriteStream on: String new.
	object associations do: [ :assoc |
		stream
		nextPutAll: assoc key asOop asString;
		nextPut: Character tab;
		nextPutAll: assoc value asOop asString;
		nextPut: Character lf ].
stream contents'
			literalBindings: Dictionary new
			oopBindings: (Dictionary new
				at: 'object' put: anOop;
				yourself)
						context: 20) ]
					on: Error
					do: [
						| associationOops |
						associationOops := self remoteArrayElementOopsForOop: (self remoteDictionaryAssociationsAsArrayOop: anOop).
						associationOops collect: [ :each | self remoteAssociationOopPairForOop: each ] ] ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationOopPairsForOops: oopCollection [
	| result cache missing batches |
	result := Dictionary new.
	cache := self remoteDictionaryAssociationOopPairCache.
	missing := OrderedCollection new.
	oopCollection do: [ :oop |
		(cache includesKey: oop)
			ifTrue: [ result at: oop put: (cache at: oop) ]
			ifFalse: [
				(missing includes: oop) ifFalse: [ missing add: oop ] ] ].
	missing isEmpty ifTrue: [ ^ result ].
	batches := self batchesForOops: missing.
	batches do: [ :batch |
		| fetched |
		fetched := self remoteDictionaryAssociationOopPairDictionaryForOopsAdaptive: batch.
		batch do: [ :oop |
			| pairs |
			pairs := fetched
				at: oop
				ifAbsent: [
					self incrementMaterializationMetric: #dictionaryPairFallbackCalls.
					self remoteDictionaryAssociationOopPairsForOop: oop ].
			cache at: oop put: pairs.
			result at: oop put: pairs ] ].
	^ result
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationOopPairDictionaryForOops: oopCollection [
	| fetched total |
	self incrementMaterializationMetric: #dictionaryPairBatchCalls.
	self incrementMaterializationMetric: #dictionaryPairBatchObjectCount by: oopCollection size.
	fetched := self
		recordMillisecondsForMetric: #dictionaryPairBatchMs
		during: [
			[
				self dictionaryAssociationOopPairDictionaryFromStructuredSlots: (self
					structuredBatchSlotsForBody: '| sizes total buffer offset object |
sizes := Array new: oops size.
total := 0.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	sizes at: oopIndex put: object size.
	total := total + (object size * 2) + 1 ].
buffer := Array new: total.
offset := 1.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	buffer at: offset put: object size.
	offset := offset + 1.
	object associations do: [ :assoc |
		buffer at: offset put: assoc key.
		buffer at: offset + 1 put: assoc value.
		offset := offset + 2 ] ].
buffer'
					oopCollection: oopCollection)
					forOops: oopCollection ]
				on: Error
				do: [
					self incrementMaterializationMetric: #structuredBatchFallbacks.
					self parseDictionaryAssociationOopPairLines: (session
						fetchRemoteCommandBody: '| stream object |
stream := WriteStream on: String new.
oops do: [ :oop |
	object := Object _objectForOop: oop.
	stream
		nextPutAll: oop asString;
		nextPut: Character tab;
		nextPutAll: object size asString.
	object associations do: [ :assoc |
		stream
			nextPut: Character tab;
			nextPutAll: assoc key asOop asString;
			nextPut: Character tab;
			nextPutAll: assoc value asOop asString ].
	stream nextPut: Character lf ].
stream contents'
						literalBindings: (Dictionary new
							at: 'oops' put: oopCollection asArray;
							yourself)
						oopBindings: Dictionary new
						context: 20) ] ].
	total := 0.
	fetched valuesDo: [ :each | total := total + each size ].
	self incrementMaterializationMetric: #dictionaryPairBatchPairCount by: total.
	^ fetched
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationOopPairDictionaryForOopsAdaptive: oopCollection [
	^ [ self remoteDictionaryAssociationOopPairDictionaryForOops: oopCollection ]
		on: Error
		do: [ :ex |
			| left right merged splitIndex singleton |
			self incrementMaterializationMetric: #dictionaryPairBatchFallbacks.
			oopCollection size <= 1 ifTrue: [
				self incrementMaterializationMetric: #dictionaryPairFallbackCalls.
				singleton := Dictionary new.
				singleton
					at: oopCollection first
					put: (self remoteDictionaryAssociationOopPairsForOop: oopCollection first).
				singleton ] ifFalse: [
				self incrementMaterializationMetric: #dictionaryPairBatchSplits.
				splitIndex := oopCollection size // 2.
				left := oopCollection copyFrom: 1 to: splitIndex.
				right := oopCollection copyFrom: splitIndex + 1 to: oopCollection size.
				merged := self remoteDictionaryAssociationOopPairDictionaryForOopsAdaptive: left.
				(self remoteDictionaryAssociationOopPairDictionaryForOopsAdaptive: right)
					associationsDo: [ :association |
						merged at: association key put: association value ].
				merged ] ]
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationOopPairCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteDictionaryAssociationOopPairCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationPairsArrayOopFor: anOop [
	^ session
		returnRemoteCommandBody: '| pairs index |
pairs := Array new: object size * 2.
index := 1.
object associations do: [ :assoc |
	pairs at: index put: assoc key.
	pairs at: index + 1 put: assoc value.
	index := index + 2 ].
pairs'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteDictionaryAssociationsAsArrayOop: anOop [
	^ session
		returnRemoteCommandBody: 'object associations asArray'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteSizeForOop: anOop [
	^ self remoteSizeCache
		at: anOop
		ifAbsentPut: [
			self incrementMaterializationMetric: #sizeFetchCalls.
			self
				recordMillisecondsForMetric: #sizeFetchMs
				during: [
					[ (session serverInterface apiGciFetchSize: anOop) asInteger ] on: Error do: [
						session fetchRemoteCommand: (GbsRemoteCommand
							blockBody: 'object size'
							oopBindings: (Dictionary new
								at: 'object' put: anOop;
								yourself)) ] ] ]
]

{ #category : 'cache' }
GbsSessionMaterializationRemoteReader >> remoteSizeCache [
	^ (session class weakRegistryNamed: #GbsSessionRemoteSizeCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteStringValueForOop: anOop [
	^ session
		fetchRemoteCommandBody: 'object asString'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
		context: 20
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteStringValuesForOops: oopCollection [
	| result batches |
	result := Dictionary new.
	batches := self batchesForOops: oopCollection.
	batches do: [ :batch |
		| fetched |
		fetched := self remoteStringValueDictionaryForOopsAdaptive: batch.
		batch do: [ :oop |
			result
				at: oop
				put: (fetched
					at: oop
					ifAbsent: [
						self incrementMaterializationMetric: #scalarStringFallbackCalls.
						self remoteStringValueForOop: oop ]) ] ].
	^ result
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteStringValueDictionaryForOops: oopCollection [
	self incrementMaterializationMetric: #scalarStringBatchCalls.
	self incrementMaterializationMetric: #scalarStringBatchObjectCount by: oopCollection size.
	self prefersTraversalBufferTransport ifTrue: [
		[
			^ self
				recordMillisecondsForMetric: #scalarStringBatchMs
				during: [ self remoteStringValueDictionaryFromTraversalForOops: oopCollection ] ]
			on: Error
			do: [ self incrementMaterializationMetric: #structuredTraversalBufferFallbacks ] ].
	^ self
		recordMillisecondsForMetric: #scalarStringBatchMs
		during: [
			[
				self stringDictionaryFromPackedBytes: (self
					structuredBatchBytesForBody: '| sizes total buffer offset object text char code writeInteger |
sizes := Array new: oops size.
total := 0.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	text := object asString.
	sizes at: oopIndex put: text size.
	total := total + 4 + (text size * 4) ].
buffer := ByteArray new: total.
offset := 1.
writeInteger := [ :value |
	buffer at: offset put: ((value bitShift: -24) bitAnd: 255).
	buffer at: offset + 1 put: ((value bitShift: -16) bitAnd: 255).
	buffer at: offset + 2 put: ((value bitShift: -8) bitAnd: 255).
	buffer at: offset + 3 put: (value bitAnd: 255).
	offset := offset + 4 ].
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	text := object asString.
	writeInteger value: text size.
	1 to: text size do: [ :index |
		char := text at: index.
		code := [ char asInteger ] on: Error do: [
			[ char codePoint ] on: Error do: [ char asciiValue ] ].
		writeInteger value: code ] ].
buffer'
					oopCollection: oopCollection
					label: 'string-value byte batch')
					forOops: oopCollection ]
				on: Error
				do: [
					self incrementMaterializationMetric: #structuredByteBatchFallbacks.
					[
						self stringValueDictionaryFromStructuredSlots: (self
							structuredBatchSlotsForBody: '| sizes total buffer offset object text char code |
sizes := Array new: oops size.
total := 0.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	text := object asString.
	sizes at: oopIndex put: text size.
	total := total + text size + 1 ].
buffer := Array new: total.
offset := 1.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	text := object asString.
	buffer at: offset put: text size.
	offset := offset + 1.
	1 to: text size do: [ :index |
		char := text at: index.
		code := [ char asInteger ] on: Error do: [
			[ char codePoint ] on: Error do: [ char asciiValue ] ].
		buffer at: offset put: code.
		offset := offset + 1 ] ].
buffer'
							oopCollection: oopCollection)
							forOops: oopCollection ]
						on: Error
						do: [
							self incrementMaterializationMetric: #structuredBatchFallbacks.
							self parseStringValueLines: (session
								fetchRemoteCommandBody: '| stream object text char code |
stream := WriteStream on: String new.
oops do: [ :oop |
	object := Object _objectForOop: oop.
	text := object asString.
	stream
		nextPutAll: oop asString;
		nextPut: Character tab;
		nextPutAll: text size asString.
	1 to: text size do: [ :index |
		char := text at: index.
		code := [ char asInteger ] on: Error do: [
			[ char codePoint ] on: Error do: [ char asciiValue ] ].
		stream
			nextPut: Character tab;
			nextPutAll: code asString ].
	stream nextPut: Character lf ].
stream contents'
						literalBindings: (Dictionary new
							at: 'oops' put: oopCollection asArray;
							yourself)
						oopBindings: Dictionary new
						context: 20) ] ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteStringValueDictionaryForOopsAdaptive: oopCollection [
	^ [ self remoteStringValueDictionaryForOops: oopCollection ]
		on: Error
		do: [ :ex |
			| left right merged splitIndex singleton |
			self incrementMaterializationMetric: #scalarStringBatchFallbacks.
			oopCollection size <= 1 ifTrue: [
				self incrementMaterializationMetric: #scalarStringFallbackCalls.
				singleton := Dictionary new.
				singleton
					at: oopCollection first
					put: (self remoteStringValueForOop: oopCollection first).
				singleton ] ifFalse: [
				self incrementMaterializationMetric: #scalarStringBatchSplits.
				splitIndex := oopCollection size // 2.
				left := oopCollection copyFrom: 1 to: splitIndex.
				right := oopCollection copyFrom: splitIndex + 1 to: oopCollection size.
				merged := self remoteStringValueDictionaryForOopsAdaptive: left.
				(self remoteStringValueDictionaryForOopsAdaptive: right)
					associationsDo: [ :association |
						merged at: association key put: association value ].
				merged ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteStringValueDictionaryFromTraversalForOops: oopCollection [
	| reports values |
	reports := self
		traversalBufferReportsForOops: oopCollection
		level: 1
		label: 'string-value traversal batch'.
	values := Dictionary new.
	oopCollection do: [ :oop |
		| report |
		report := reports at: oop ifAbsent: [
			self error: 'GCI traversal string batch did not include requested OOP.' ].
		report hasByteValue ifFalse: [
			self error: 'GCI traversal string batch returned a non-byte object report.' ].
		values at: oop put: (self stringFromBytes: report valueBytes) ].
	^ values
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteByteArrayValuesForOops: oopCollection [
	| result batches |
	result := Dictionary new.
	batches := self batchesForOops: oopCollection.
	batches do: [ :batch |
		| fetched |
		fetched := self remoteByteArrayValueDictionaryForOopsAdaptive: batch.
		batch do: [ :oop |
			result
				at: oop
				put: (fetched
					at: oop
					ifAbsent: [
						self incrementMaterializationMetric: #scalarByteArrayFallbackCalls.
						session materializer
							materializeByteArrayOop: oop
							withProfile: GbsProxyOnlyMaterializationProfile new
							depth: 0
							seen: IdentitySet new ]) ] ].
	^ result
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteByteArrayValueDictionaryForOops: oopCollection [
	self incrementMaterializationMetric: #scalarByteArrayBatchCalls.
	self incrementMaterializationMetric: #scalarByteArrayBatchObjectCount by: oopCollection size.
	self prefersTraversalBufferTransport ifTrue: [
		[
			^ self
				recordMillisecondsForMetric: #scalarByteArrayBatchMs
				during: [ self remoteByteArrayValueDictionaryFromTraversalForOops: oopCollection ] ]
			on: Error
			do: [ self incrementMaterializationMetric: #structuredTraversalBufferFallbacks ] ].
	^ self
		recordMillisecondsForMetric: #scalarByteArrayBatchMs
		during: [
			[
				self byteArrayDictionaryFromPackedBytes: (self
					structuredBatchBytesForBody: '| sizes total buffer offset object writeInteger |
sizes := Array new: oops size.
total := 0.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	sizes at: oopIndex put: object size.
	total := total + 4 + object size ].
buffer := ByteArray new: total.
offset := 1.
writeInteger := [ :value |
	buffer at: offset put: ((value bitShift: -24) bitAnd: 255).
	buffer at: offset + 1 put: ((value bitShift: -16) bitAnd: 255).
	buffer at: offset + 2 put: ((value bitShift: -8) bitAnd: 255).
	buffer at: offset + 3 put: (value bitAnd: 255).
	offset := offset + 4 ].
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	writeInteger value: object size.
	1 to: object size do: [ :index |
		buffer at: offset put: (object at: index) asInteger.
		offset := offset + 1 ] ].
buffer'
					oopCollection: oopCollection
					label: 'byte-array byte batch')
					forOops: oopCollection ]
				on: Error
				do: [
					self incrementMaterializationMetric: #structuredByteBatchFallbacks.
					[
						self byteArrayValueDictionaryFromStructuredSlots: (self
							structuredBatchSlotsForBody: '| sizes total buffer offset object |
sizes := Array new: oops size.
total := 0.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	sizes at: oopIndex put: object size.
	total := total + object size + 1 ].
buffer := Array new: total.
offset := 1.
1 to: oops size do: [ :oopIndex |
	object := Object _objectForOop: (oops at: oopIndex).
	buffer at: offset put: object size.
	offset := offset + 1.
	1 to: object size do: [ :index |
		buffer at: offset put: (object at: index) asInteger.
		offset := offset + 1 ] ].
buffer'
							oopCollection: oopCollection)
							forOops: oopCollection ]
						on: Error
						do: [
							self incrementMaterializationMetric: #structuredBatchFallbacks.
							self parseByteArrayValueLines: (session
								fetchRemoteCommandBody: '| stream object |
stream := WriteStream on: String new.
oops do: [ :oop |
	object := Object _objectForOop: oop.
	stream
		nextPutAll: oop asString;
		nextPut: Character tab;
		nextPutAll: object size asString.
	1 to: object size do: [ :index |
		stream
			nextPut: Character tab;
			nextPutAll: (object at: index) asInteger asString ].
	stream nextPut: Character lf ].
stream contents'
						literalBindings: (Dictionary new
							at: 'oops' put: oopCollection asArray;
							yourself)
						oopBindings: Dictionary new
						context: 20) ] ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteByteArrayValueDictionaryForOopsAdaptive: oopCollection [
	^ [ self remoteByteArrayValueDictionaryForOops: oopCollection ]
		on: Error
		do: [ :ex |
			| left right merged splitIndex singleton |
			self incrementMaterializationMetric: #scalarByteArrayBatchFallbacks.
			oopCollection size <= 1 ifTrue: [
				self incrementMaterializationMetric: #scalarByteArrayFallbackCalls.
				singleton := Dictionary new.
				singleton
					at: oopCollection first
					put: (session materializer
						materializeByteArrayOop: oopCollection first
						withProfile: GbsProxyOnlyMaterializationProfile new
						depth: 0
						seen: IdentitySet new).
				singleton ] ifFalse: [
				self incrementMaterializationMetric: #scalarByteArrayBatchSplits.
				splitIndex := oopCollection size // 2.
				left := oopCollection copyFrom: 1 to: splitIndex.
				right := oopCollection copyFrom: splitIndex + 1 to: oopCollection size.
				merged := self remoteByteArrayValueDictionaryForOopsAdaptive: left.
				(self remoteByteArrayValueDictionaryForOopsAdaptive: right)
					associationsDo: [ :association |
						merged at: association key put: association value ].
				merged ] ]
]

{ #category : 'remote access' }
GbsSessionMaterializationRemoteReader >> remoteByteArrayValueDictionaryFromTraversalForOops: oopCollection [
	| reports values |
	reports := self
		traversalBufferReportsForOops: oopCollection
		level: 1
		label: 'byte-array traversal batch'.
	values := Dictionary new.
	oopCollection do: [ :oop |
		| report |
		report := reports at: oop ifAbsent: [
			self error: 'GCI traversal byte-array batch did not include requested OOP.' ].
		report hasByteValue ifFalse: [
			self error: 'GCI traversal byte-array batch returned a non-byte object report.' ].
		values at: oop put: report valueBytes ].
	^ values
]

{ #category : 'accessing' }
GbsSessionMaterializationRemoteReader >> session [
	^ session
]

{ #category : 'accessing' }
GbsSessionMaterializationRemoteReader >> session: aSession [
	session := aSession
]
