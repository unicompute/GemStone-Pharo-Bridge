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
	(self nativeSupportedKinds includes: (entry at: 3)) ifFalse: [ ^ false ].
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
	kind = #dictionary ifTrue: [ ^ object size ].
	kind = #identityDictionary ifTrue: [ ^ object size * 2 ].
	kind = #namedObject ifTrue: [ ^ self nativeNamedSizeForObject: object ].
	^ object size
]

{ #category : 'accessing' }
GbsDirtyStoreTraversalBuffer >> entries [
	^ entries
]

{ #category : 'native encoding' }
GbsDirtyStoreTraversalBuffer >> createFlag [
	"GCI_STORE_TRAV_CREATE (0x2): when a store-traversal object report names an OOP that does not yet
	exist on the server, create the object with GciCreate semantics and add it to the PureExportSet.
	Required for new objects allocated from free OOPs (for example unmapped Set/Bag elements); without it
	GciStoreTrav fails with error 2101 'object does not exist'."
	^ 2
]

{ #category : 'native encoding' }
GbsDirtyStoreTraversalBuffer >> defaultFlags [
	"GCI_STORE_TRAV_FINISH_UPDATES (0x8) is always set so deferred updates run after the last report.
	GCI_STORE_TRAV_CREATE (0x2) is added when any entry creates a new object from a free OOP."
	| value |
	value := 8.
	(self entriesIncludeNewObject) ifTrue: [ value := value bitOr: self createFlag ].
	^ value
]

{ #category : 'testing' }
GbsDirtyStoreTraversalBuffer >> entriesIncludeNewObject [
	^ entries anySatisfy: [ :entry |
		entry size >= 6 and: [ (entry at: 6) == true ] ]
]

{ #category : 'accessing' }
GbsDirtyStoreTraversalBuffer >> flags [
	^ flags ifNil: [ self defaultFlags ]
]

{ #category : 'accessing' }
GbsDirtyStoreTraversalBuffer >> flags: anInteger [
	flags := anInteger
]

{ #category : 'initialization' }
GbsDirtyStoreTraversalBuffer >> initializeEntries: dirtyEntries [
	entries := dirtyEntries asArray.
	flags := self defaultFlags.
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

{ #category : 'native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeEncodingFailureDescriptions [
	| descriptions |
	descriptions := OrderedCollection new.
	entries do: [ :entry |
		(self canProduceNativeTraversalReportForEntry: entry) ifFalse: [
			descriptions add: (self nativeEncodingFailureDescriptionForEntry: entry) ] ].
	^ descriptions asArray
]

{ #category : 'native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeEncodingFailureDescriptionForEntry: entry [
	| values missing |
	values := [ self nativeValuesForEntry: entry ]
		on: Error
		do: [ :ex |
			^ 'oop=', entry first asString,
				' kind=', (entry at: 3) asString,
				' class=', entry second class name,
				' valuesError=', ex messageText ].
	missing := values select: [ :each |
		each notNil and: [
			(self oopForValue: each ifAbsent: [ nil ]) isNil ] ].
	missing isEmpty ifTrue: [
		^ 'oop=', entry first asString,
			' kind=', (entry at: 3) asString,
			' class=', entry second class name,
			' unsupported native entry shape' ].
	^ 'oop=', entry first asString,
		' kind=', (entry at: 3) asString,
		' class=', entry second class name,
		' missingValues=', (self nativeValueDescriptionListFor: missing)
]

{ #category : 'native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeEncodingFailureSummary [
	| descriptions |
	descriptions := self nativeEncodingFailureDescriptions.
	descriptions isEmpty ifTrue: [ ^ 'none' ].
	^ self nativeValueDescriptionListFor: descriptions
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
GbsDirtyStoreTraversalBuffer >> nativeIndexedSizeForEntry: entry [
	| kind object |
	kind := entry at: 3.
	kind = #association ifTrue: [ ^ 0 ].
	kind = #namedObject ifTrue: [
		^ self nativeIndexedSizeForNamedObject: entry second ].
	(#(#set #bag) includes: kind) ifTrue: [
		object := entry second.
		^ object size ].
	^ (self nativeValuesForEntry: entry) size
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeIndexedSizeForNamedObject: anObject [
	| replicator |
	replicator := self replicatorForNamedObject: anObject.
	(replicator notNil and: [ replicator respondsTo: #dirtyStoreIndexedSizeFor: ]) ifTrue: [
		^ replicator dirtyStoreIndexedSizeFor: anObject ].
	^ 0
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeIndexableValuesForNamedObject: anObject [
	| replicator |
	replicator := self replicatorForNamedObject: anObject.
	(replicator notNil and: [ replicator respondsTo: #dirtyStoreIndexableValuesFor: ]) ifTrue: [
		^ replicator dirtyStoreIndexableValuesFor: anObject ].
	^ #()
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeNamedInstVarValuesFor: anObject [
	| replicator |
	replicator := self replicatorForNamedObject: anObject.
	(replicator notNil and: [ replicator respondsTo: #dirtyStoreNamedValuesFor:unmappedValue: ]) ifTrue: [
		^ replicator
			dirtyStoreNamedValuesFor: anObject
			unmappedValue: self oopIllegalValueMarker ].
	(replicator notNil and: [
		(replicator respondsTo: #usesInstVarMap)
			and: [ replicator usesInstVarMap ] ]) ifTrue: [
			^ replicator
				namedInstVarValuesInServerOrderFor: anObject
				unmappedValue: self oopIllegalValueMarker ].
	^ ((1 to: (self nativeNamedSizeForObject: anObject)) collect: [ :index |
		anObject instVarAt: index ]) asArray
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeNamedSizeForEntry: entry [
	| kind |
	kind := entry at: 3.
	kind = #association ifTrue: [ ^ 2 ].
	kind = #namedObject ifTrue: [ ^ self nativeNamedSizeForObject: entry second ].
	kind = #set ifTrue: [ ^ 5 ].
	kind = #bag ifTrue: [ ^ 6 ].
	^ 0
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeNamedSizeForObject: anObject [
	| replicator serverNamedSize names |
	replicator := self replicatorForNamedObject: anObject.
	(replicator notNil and: [ replicator respondsTo: #dirtyStoreNamedSizeFor: ]) ifTrue: [
		serverNamedSize := replicator dirtyStoreNamedSizeFor: anObject.
		serverNamedSize > 0 ifTrue: [ ^ serverNamedSize ] ].
	(replicator notNil and: [
		(replicator respondsTo: #usesInstVarMap)
			and: [ replicator usesInstVarMap ] ]) ifTrue: [
		serverNamedSize := replicator serverNamedSize.
		serverNamedSize > 0 ifTrue: [ ^ serverNamedSize ] ].
	names := [ anObject class allInstVarNames ] on: Error do: [ #() ].
	^ names size
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeObjectFormatForEntry: entry [
	(#(#set #bag) includes: (entry at: 3)) ifTrue: [ ^ 2 ].
	^ 0
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeSupportedKinds [
	^ #(#array #association #orderedCollection #dictionary #identityDictionary #set #bag #namedObject)
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeValueByteCountForEntry: entry [
	^ (self nativeValuesForEntry: entry) size * 8
]

{ #category : 'native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeValueDescriptionFor: anObject [
	| text |
	text := [ anObject printString ] on: Error do: [ '<unprintable>' ].
	text size > 80 ifTrue: [ text := (text copyFrom: 1 to: 80), '...' ].
	^ anObject class name, '(', text, ')'
]

{ #category : 'native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeValueDescriptionListFor: aCollection [
	^ String streamContents: [ :stream |
		aCollection doWithIndex: [ :each :index |
			index > 1 ifTrue: [ stream nextPutAll: '; ' ].
			(each isString and: [ each includesSubstring: 'oop=' ])
				ifTrue: [ stream nextPutAll: each ]
				ifFalse: [ stream nextPutAll: (self nativeValueDescriptionFor: each) ] ] ]
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeValuesForIdentityDictionary: aDictionary [
	| values |
	values := OrderedCollection new: aDictionary size * 2.
	aDictionary keysAndValuesDo: [ :key :value |
		values
			add: key;
			add: value ].
	^ values asArray
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeValuesForEntry: entry [
	| object kind |
	object := entry second.
	kind := entry at: 3.
		kind = #array ifTrue: [ ^ object asArray ].
		kind = #association ifTrue: [ ^ { object key. object value } ].
		kind = #orderedCollection ifTrue: [ ^ object asArray ].
		kind = #dictionary ifTrue: [ ^ self nativeValuesForDictionaryEntry: entry ].
		kind = #identityDictionary ifTrue: [ ^ self nativeValuesForIdentityDictionary: object ].
		kind = #set ifTrue: [ ^ self nativeValuesForSetEntry: entry ].
		kind = #bag ifTrue: [ ^ self nativeValuesForBagEntry: entry ].
		kind = #namedObject ifTrue: [ ^ self nativeValuesForNamedObject: object ].
		self error: 'Native dirty store traversal does not support kind ', kind asString
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeValuesForNamedObject: anObject [
	^ (self nativeNamedInstVarValuesFor: anObject),
		(self nativeIndexableValuesForNamedObject: anObject)
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeValuesForSetEntry: entry [
	^ { nil. nil. nil. nil. nil }, entry second asArray
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeValuesForBagEntry: entry [
	| values |
	values := OrderedCollection new: entry second size + 6.
	6 timesRepeat: [ values add: nil ].
	entry second asSet do: [ :each |
		1 to: (entry second occurrencesOf: each) do: [ :ignored |
			values add: each ] ].
	^ values asArray
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> classOopForEntry: entry serverInterface: serverInterface [
	| explicitClassOop oop |
	explicitClassOop := entry size >= 5
		ifTrue: [ entry at: 5 ]
		ifFalse: [ nil ].
	explicitClassOop ifNotNil: [ ^ explicitClassOop asInteger ].
	oop := entry first.
	^ (serverInterface apiGciGetClass: oop) asInteger
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeValuesForDictionaryEntry: entry [
	| associations |
	associations := entry second associations asArray.
	(associations anySatisfy: [ :association |
		(self oopForValue: association ifAbsent: [ nil ]) isNil ]) ifTrue: [
			self registerRemoteAssociationsForDictionaryEntry: entry associations: associations ].
	^ associations
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> nativeScalarOopForValue: anObject ifAbsent: absentBlock [
	| serverInterface oop |
	session ifNil: [ ^ absentBlock value ].
	((session respondsTo: #serverInterface)
		and: [ session serverInterface notNil ]) ifFalse: [ ^ absentBlock value ].
	(self scalarValueCanUseNativeCString: anObject) ifFalse: [ ^ absentBlock value ].
	serverInterface := session serverInterface.
	((serverInterface respondsTo: #supportsNativeScalarOopResolution)
		and: [ serverInterface supportsNativeScalarOopResolution ]) ifFalse: [
			^ absentBlock value ].
	oop := [
		anObject isSymbol
			ifTrue: [ serverInterface apiGciNewSymbol: anObject asString ]
			ifFalse: [ serverInterface apiGciNewString: anObject asString ] ]
		on: Error
		do: [
			self incrementDirtyStoreReportAt: #nativeScalarOopResolutionFallbackCount by: 1.
			^ absentBlock value ].
	((oop isNil) or: [ oop asInteger = 1 ]) ifTrue: [
		self incrementDirtyStoreReportAt: #nativeScalarOopResolutionFallbackCount by: 1.
		^ absentBlock value ].
	self incrementDirtyStoreReportAt: #nativeScalarOopResolutionCount by: 1.
	^ self unsignedOopForSignedOop: oop asInteger
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> oopForValue: anObject ifAbsent: absentBlock [
	| oop |
	anObject == self oopIllegalValueMarker ifTrue: [ ^ 1 ].
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
	(self shouldResolveScalarOopFor: anObject) ifTrue: [
		^ self remoteScalarOopForValue: anObject ifAbsent: absentBlock ].
	^ absentBlock value
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> oopIllegalValueMarker [
	^ #GbsDirtyStoreTraversalOopIllegal
]

{ #category : 'private - reporting' }
GbsDirtyStoreTraversalBuffer >> incrementDirtyStoreReportAt: key by: amount [
	| report |
	session ifNil: [ ^ self ].
	report := [ GbsDirtyReplicateStoreTraversal dirtyStoreTraversalReportStorageForSession: session ]
		on: Error
		do: [ ^ self ].
	report
		at: key
		put: ((report at: key ifAbsent: [ 0 ]) + amount)
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> registerRemoteAssociationsForDictionaryEntry: entry associations: associations [
	| associationMaps associationOopByKeyOop associationOopByScalarKey |
	associationMaps := [ self remoteDictionaryAssociationOopMapsFor: entry first ]
		on: Error
		do: [ ^ self ].
	associationOopByKeyOop := associationMaps at: #byKeyOop ifAbsent: [ Dictionary new ].
	associationOopByScalarKey := associationMaps at: #byScalarKey ifAbsent: [ Dictionary new ].
	associations do: [ :association | | keyOop associationOop |
		keyOop := self oopForValue: association key ifAbsent: [ nil ].
		associationOop := keyOop
			ifNil: [ nil ]
			ifNotNil: [ associationOopByKeyOop at: keyOop ifAbsent: [ nil ] ].
		associationOop ifNil: [
			(self scalarDictionaryKeyLookupKeyFor: association key) ifNotNil: [ :scalarKey |
				associationOop := associationOopByScalarKey at: scalarKey ifAbsent: [ nil ] ] ].
		associationOop ifNotNil: [
			GbsMaterializedObjectDirtyTracker
				registerObject: association
				oop: associationOop
				session: session ] ]
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> remoteDictionaryAssociationOopMapsFor: dictionaryOop [
	| rootReports dictionaryReport associationOops associationReports keyOops keyReports byKeyOop byScalarKey |
	session ifNil: [ ^ Dictionary new ].
	((session respondsTo: #supportsMaterializationTraversalBufferTransport)
		and: [ session supportsMaterializationTraversalBufferTransport == false ]) ifTrue: [
			^ self remoteDictionaryAssociationOopMapsViaScriptFor: dictionaryOop ].
	(session respondsTo: #materializationTraversalReportsForOops:level:label:) ifFalse: [
		^ self remoteDictionaryAssociationOopMapsViaScriptFor: dictionaryOop ].
	rootReports := [ session
		materializationTraversalReportsForOops: { dictionaryOop }
		level: 1
		label: 'dirty-store dictionary association metadata' ]
		on: Error
		do: [ ^ self remoteDictionaryAssociationOopMapsViaScriptFor: dictionaryOop ].
	dictionaryReport := rootReports at: dictionaryOop ifAbsent: [
		^ self remoteDictionaryAssociationOopMapsViaScriptFor: dictionaryOop ].
	associationOops := dictionaryReport valueOops.
	associationOops isEmpty ifTrue: [
		self incrementDirtyStoreReportAt: #nativeDictionaryMetadataFetchCount by: 1.
		^ Dictionary new
			at: #byKeyOop put: Dictionary new;
			at: #byScalarKey put: Dictionary new;
			yourself ].
	associationReports := [ session
		materializationTraversalReportsForOops: associationOops
		level: 1
		label: 'dirty-store dictionary association metadata' ]
		on: Error
		do: [ ^ self remoteDictionaryAssociationOopMapsViaScriptFor: dictionaryOop ].
	keyOops := OrderedCollection new: associationOops size.
	associationOops do: [ :associationOop |
		(associationReports at: associationOop ifAbsent: [ nil ]) ifNotNil: [ :associationReport |
			associationReport valueOops isEmpty ifFalse: [
				keyOops add: associationReport valueOops first ] ] ].
	keyReports := keyOops isEmpty
		ifTrue: [ Dictionary new ]
		ifFalse: [
			[ session
				materializationTraversalReportsForOops: keyOops asArray
				level: 1
				label: 'dirty-store dictionary scalar-key metadata' ]
				on: Error
				do: [ Dictionary new ] ].
	byKeyOop := Dictionary new.
	byScalarKey := Dictionary new.
	associationOops do: [ :associationOop |
		(associationReports at: associationOop ifAbsent: [ nil ]) ifNotNil: [ :associationReport |
			associationReport valueOops isEmpty ifFalse: [ | keyOop |
				keyOop := associationReport valueOops first.
				byKeyOop at: keyOop put: associationOop.
				self
					registerScalarDictionaryKeyFromReport: (keyReports at: keyOop ifAbsent: [ nil ])
					associationOop: associationOop
					into: byScalarKey ] ] ].
	self incrementDirtyStoreReportAt: #nativeDictionaryMetadataFetchCount by: 1.
	^ Dictionary new
		at: #byKeyOop put: byKeyOop;
		at: #byScalarKey put: byScalarKey;
		yourself
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> remoteDictionaryAssociationOopMapsViaScriptFor: dictionaryOop [
	| text byKeyOop byScalarKey |
	self incrementDirtyStoreReportAt: #scriptDictionaryMetadataFallbackCount by: 1.
	text := session
		fetchRemoteCommandBody: '| stream |
	stream := WriteStream on: String new.
object associations do: [ :assoc |
	stream
		nextPutAll: assoc key asOop asString;
		nextPut: Character tab;
		nextPutAll: assoc asOop asString;
		nextPut: Character tab;
		nextPutAll: assoc key class name asString;
		nextPut: Character tab;
		nextPutAll: assoc key asString;
		nextPut: Character lf ].
stream contents'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: dictionaryOop;
			yourself)
		context: 20.
	byKeyOop := Dictionary new.
	byScalarKey := Dictionary new.
	text asString lines do: [ :line |
		line isEmpty ifFalse: [ | parts |
			parts := line asString splitOn: Character tab.
			parts size >= 2 ifTrue: [ | associationOop |
				associationOop := self unsignedOopForSignedOop: parts second asInteger.
				byKeyOop
					at: (self unsignedOopForSignedOop: parts first asInteger)
					put: associationOop.
				parts size >= 4 ifTrue: [
					(self
						scalarDictionaryKeyLookupKeyForClassName: parts third
						value: parts fourth) ifNotNil: [ :scalarKey |
							byScalarKey at: scalarKey put: associationOop ] ] ] ] ].
	^ Dictionary new
		at: #byKeyOop put: byKeyOop;
		at: #byScalarKey put: byScalarKey;
		yourself
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> replicatorForNamedObject: anObject [
	(session notNil and: [ session respondsTo: #replicatorForClient:ifAbsent: ]) ifFalse: [
		^ nil ].
	^ [ session
		replicatorForClient: anObject
		ifAbsent: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> scalarDictionaryKeyLookupKeyFor: anObject [
	anObject isSymbol ifTrue: [ ^ { 'Symbol'. anObject asString } ].
	anObject isString ifTrue: [ ^ { 'String'. anObject asString } ].
	^ nil
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> scalarDictionaryKeyLookupKeyForClassName: className value: valueString [
	((#('Symbol' 'DoubleByteSymbol') includes: className) and: [ valueString notNil ]) ifTrue: [
		^ { 'Symbol'. valueString asString } ].
	((#('String' 'DoubleByteString') includes: className) and: [ valueString notNil ]) ifTrue: [
		^ { 'String'. valueString asString } ].
	^ nil
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> scalarOopCache [
	session ifNil: [ ^ Dictionary new ].
	^ (session class weakRegistryNamed: #GbsSessionDirtyStoreScalarOopCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> remoteScalarOopForValue: anObject ifAbsent: absentBlock [
	| key |
	session ifNil: [ ^ absentBlock value ].
	key := self scalarDictionaryKeyLookupKeyFor: anObject.
	key ifNil: [ ^ absentBlock value ].
	^ self scalarOopCache
		at: key
		ifPresent: [ :oop |
			self incrementDirtyStoreReportAt: #scalarOopCacheHitCount by: 1.
			oop ]
		ifAbsent: [
			| oop |
			oop := self nativeScalarOopForValue: anObject ifAbsent: [ nil ].
			oop ifNotNil: [
				self scalarOopCache at: key put: oop.
				^ oop ].
			self incrementDirtyStoreReportAt: #scriptScalarOopFallbackCount by: 1.
			oop := [ session
				returnRemoteCommandBody: 'value'
				literalBindings: (Dictionary new
					at: 'value' put: anObject;
					yourself)
				oopBindings: Dictionary new ]
				on: Error
				do: [ ^ absentBlock value ].
			oop := self unsignedOopForSignedOop: oop asInteger.
			self scalarOopCache at: key put: oop.
			oop ]
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> registerScalarDictionaryKeyFromReport: keyReport associationOop: associationOop into: byScalarKey [
	keyReport ifNil: [ ^ self ].
	keyReport hasByteValue ifFalse: [ ^ self ].
	keyReport byteSwizzle = 0 ifFalse: [ ^ self ].
	(self
		scalarDictionaryKeyLookupKeyForClassName: (self scalarClassNameForClassOop: keyReport classOop)
		value: (self stringFromBytes: keyReport valueBytes)) ifNotNil: [ :scalarKey |
			byScalarKey at: scalarKey put: associationOop ]
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> scalarClassNameForClassOop: classOop [
	| oop name |
	session ifNil: [ ^ '' ].
	((session respondsTo: #serverInterface)
		and: [ session serverInterface respondsTo: #apiGciFetchNameOfClass: ]) ifFalse: [
			^ '' ].
	oop := [ session serverInterface apiGciFetchNameOfClass: classOop ]
		on: Error
		do: [ ^ '' ].
	name := [ (GbsSessionMaterializationRemoteReader on: session)
		rawStringForOop: oop
		label: 'dirty-store scalar-key class name' ]
		on: Error
		do: [ ^ '' ].
	^ name asString
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> stringFromBytes: byteArray [
	^ String streamContents: [ :stream |
		byteArray do: [ :byte |
			stream nextPut: (Character codePoint: byte) ] ]
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> shouldResolveScalarOopFor: anObject [
	anObject ifNil: [ ^ false ].
	anObject isSymbol ifTrue: [ ^ true ].
	anObject isString ifTrue: [ ^ true ].
	^ false
]

{ #category : 'private - native encoding' }
GbsDirtyStoreTraversalBuffer >> scalarValueCanUseNativeCString: anObject [
	| string |
	((anObject isString) or: [ anObject isSymbol ]) ifFalse: [ ^ false ].
	string := anObject asString.
	string do: [ :character |
		| codePoint |
		codePoint := character codePoint.
		(codePoint > 0 and: [ codePoint < 128 ]) ifFalse: [ ^ false ] ].
	^ true
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
		self error: 'Native dirty store traversal can encode only supported mapped objects whose stored values are nil, booleans, SmallIntegers, Characters, registered materialized objects, proxies, or scalar values resolvable to GemStone OOPs. Unencodable entries: ', self nativeEncodingFailureSummary ].
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
	| values namedSize indexedSize |
	values := self nativeValuesForEntry: entry.
	namedSize := self nativeNamedSizeForEntry: entry.
	indexedSize := self nativeIndexedSizeForEntry: entry.
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
	| oop classOop valueOops valueSize alignedSize valueOffset idxSizeBits objectFormat |
	oop := entry first.
	classOop := self classOopForEntry: entry serverInterface: serverInterface.
	valueOops := values collect: [ :each |
		self oopForValue: each ifAbsent: [
			self error: 'Native dirty store traversal cannot encode value: ', each printString ] ].
	valueSize := valueOops size * 8.
	alignedSize := self alignedByteCount: valueSize.
	objectFormat := self nativeObjectFormatForEntry: entry.
	idxSizeBits := (indexedSize bitShift: 24) + 16r20 + objectFormat.
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
