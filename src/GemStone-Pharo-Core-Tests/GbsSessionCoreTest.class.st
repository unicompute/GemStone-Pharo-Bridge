Class {
	#name : 'GbsSessionCoreTest',
	#superclass : 'TestCase',
	#instVars : [
		'session',
		'previousObjectSpaceFinalizationRegistry'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GbsSessionCoreTest >> materializationMockSession [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script | | result |
		result := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'text := object asString' ]) ifTrue: [
			result := String streamContents: [ :stream |
				#(
					(9040 'vip')
					(9056 'gold')
					(9064 'paid')) do: [ :entry |
					(script includesSubstring: entry first asString) ifTrue: [
						stream
							nextPutAll: (self encodedStringBatchLineForOop: entry first value: entry second) ] ] ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			result := String streamContents: [ :stream |
				(script includesSubstring: '9016') ifTrue: [
					stream
						nextPutAll: '9016';
						nextPut: Character tab;
						nextPutAll: 'Array';
						nextPut: Character lf ].
				#(9040 9056 9064) do: [ :oop |
					(script includesSubstring: oop asString) ifTrue: [
						stream
							nextPutAll: oop asString;
							nextPut: Character tab;
							nextPutAll: 'String';
							nextPut: Character lf ] ] ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object size asString' ]) ifTrue: [
			result := String streamContents: [ :stream |
				(script includesSubstring: '9016') ifTrue: [
					stream
						nextPutAll: '9016';
						nextPut: Character tab;
						nextPutAll: '2';
						nextPut: Character tab;
						nextPutAll: '9056';
						nextPut: Character tab;
						nextPutAll: '9064';
						nextPut: Character lf ] ] ].
		result ifNil: [
		(script includesSubstring: 'class name asString') ifTrue: [
			(script includesSubstring: '9000') ifTrue: [ result := 'Array' ].
			(script includesSubstring: '9016') ifTrue: [ result := 'Array' ].
			(script includesSubstring: '9040') ifTrue: [ result := 'String' ].
			(script includesSubstring: '9056') ifTrue: [ result := 'String' ].
			(script includesSubstring: '9064') ifTrue: [ result := 'String' ] ] ].
		result ifNil: [
		((script includesSubstring: ') asString') or: [ script includesSubstring: 'object asString' ]) ifTrue: [
			(script includesSubstring: '9040') ifTrue: [ result := 'vip' ].
			(script includesSubstring: '9056') ifTrue: [ result := 'gold' ].
			(script includesSubstring: '9064') ifTrue: [ result := 'paid' ] ] ].
		result ifNil: [ self fail ].
		result ].
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script | | result |
		result := nil.
		(script includesSubstring: 'history :=') ifTrue: [
			^ {
				5001.
				((script includesSubstring: '''String''') ifTrue: [ 'String' ] ifFalse: [ 'Array' ]).
				'Object'.
				nil.
				nil.
				1.
				1 } ].
		(script includesSubstring: 'methodDict keys') ifTrue: [ ^ #() ].
		(script includesSubstring: '9000') ifTrue: [ result := 2 ].
		(script includesSubstring: '9016') ifTrue: [ result := 2 ].
		result ifNil: [ self fail ].
		result ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		(oop = 9000 or: [ oop = 9016 ])
			ifTrue: [ 2 ]
			ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: start equals: 1.
		self assert: count equals: 2.
		oop = 9000 ifTrue: [ #(9040 9016) ] ifFalse: [
			oop = 9016 ifTrue: [ #(9056 9064) ] ifFalse: [ self fail ] ] ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script | | result |
		result := nil.
		(script includesSubstring: '9000') ifTrue: [
			((script includesSubstring: 'at: 1') or: [ script includesSubstring: 'value: 1' ]) ifTrue: [ result := 9040 ].
			((script includesSubstring: 'at: 2') or: [ script includesSubstring: 'value: 2' ]) ifTrue: [ result := 9016 ] ].
		(script includesSubstring: '9016') ifTrue: [
			((script includesSubstring: 'at: 1') or: [ script includesSubstring: 'value: 1' ]) ifTrue: [ result := 9056 ].
			((script includesSubstring: 'at: 2') or: [ script includesSubstring: 'value: 2' ]) ifTrue: [ result := 9064 ] ].
		result ifNil: [ self fail ].
		result ].
	^ mockSession
]

{ #category : 'running' }
GbsSessionCoreTest >> encodedStringBatchLineForOop: anOop value: aString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: anOop asString;
			nextPut: Character tab;
			nextPutAll: aString size asString.
		aString do: [ :character |
			stream
				nextPut: Character tab;
				nextPutAll: character codePoint asString ].
		stream nextPut: Character lf ]
]

{ #category : 'running' }
GbsSessionCoreTest >> encodedSmallIntegerOop: anInteger [
	^ (anInteger bitShift: 3) + 2
]

{ #category : 'running' }
GbsSessionCoreTest >> encodedStructuredStringSlotsFor: aString [
	| slots |
	slots := OrderedCollection with: (self encodedSmallIntegerOop: aString size).
	aString do: [ :character |
		slots add: (self encodedSmallIntegerOop: character codePoint) ].
	^ slots asArray
]

{ #category : 'running' }
GbsSessionCoreTest >> putUint32: anInteger into: byteArray at: offset [
	byteArray at: offset put: ((anInteger bitShift: -24) bitAnd: 255).
	byteArray at: offset + 1 put: ((anInteger bitShift: -16) bitAnd: 255).
	byteArray at: offset + 2 put: ((anInteger bitShift: -8) bitAnd: 255).
	byteArray at: offset + 3 put: (anInteger bitAnd: 255).
	^ offset + 4
]

{ #category : 'running' }
GbsSessionCoreTest >> encodedPackedStringPayloadFor: stringCollection [
	| total bytes offset |
	total := 0.
	stringCollection do: [ :each | total := total + 4 + (each size * 4) ].
	bytes := ByteArray new: total.
	offset := 1.
	stringCollection do: [ :each |
		offset := self putUint32: each size into: bytes at: offset.
		each do: [ :character |
			offset := self putUint32: character codePoint into: bytes at: offset ] ].
	^ bytes
]

{ #category : 'running' }
GbsSessionCoreTest >> encodedPackedByteArrayPayloadFor: byteArrayCollection [
	| total bytes offset |
	total := 0.
	byteArrayCollection do: [ :each | total := total + 4 + each size ].
	bytes := ByteArray new: total.
	offset := 1.
	byteArrayCollection do: [ :each |
		offset := self putUint32: each size into: bytes at: offset.
		each do: [ :byte |
			bytes at: offset put: byte.
			offset := offset + 1 ] ].
	^ bytes
]

{ #category : 'running' }
GbsSessionCoreTest >> traversalByteReportForOop: oop classOop: classOop bytes: byteArray [
	^ GbsMaterializationTraversalReport new
		oop: oop;
		classOop: classOop;
		objectFormat: 1;
		byteSwizzle: 0;
		indexedSize: byteArray size;
		namedSize: 0;
		firstOffset: 1;
		valueBytes: byteArray;
		yourself
]

{ #category : 'running' }
GbsSessionCoreTest >> traversalPointerReportForOop: oop classOop: classOop oops: oopArray [
	^ self
		traversalPointerReportForOop: oop
		classOop: classOop
		namedSize: 0
		indexedSize: oopArray size
		firstOffset: 1
		oops: oopArray
]

{ #category : 'running' }
GbsSessionCoreTest >> traversalPointerReportForOop: oop classOop: classOop namedSize: namedSize indexedSize: indexedSize firstOffset: firstOffset oops: oopArray [
	^ GbsMaterializationTraversalReport new
		oop: oop;
		classOop: classOop;
		objectFormat: 0;
		byteSwizzle: 0;
		indexedSize: indexedSize;
		namedSize: namedSize;
		firstOffset: firstOffset;
		valueOops: oopArray;
		yourself
]

{ #category : 'running' }
GbsSessionCoreTest >> alignedTraversalValueByteCount: byteCount [
	^ ((byteCount + 7) // 8) * 8
]

{ #category : 'running' }
GbsSessionCoreTest >> finishTraversalBuffer: traversalBuffer usedBytes: usedBytes [
	traversalBuffer
		integerAt: 5
		put: usedBytes
		size: 4
		signed: false
]

{ #category : 'running' }
GbsSessionCoreTest >> writeByteTraversalReportOn: traversalBuffer offset: offset oop: oop classOop: classOop bytes: byteArray byteSwizzle: byteSwizzle [
	| valueSize alignedSize idxSizeBits valueOffset |
	valueSize := byteArray size.
	alignedSize := self alignedTraversalValueByteCount: valueSize.
	idxSizeBits := (valueSize bitShift: 24) + (byteSwizzle bitShift: 8) + 1.
	traversalBuffer
		integerAt: offset put: valueSize size: 4 signed: true;
		integerAt: offset + 4 put: 0 size: 2 signed: true;
		integerAt: offset + 8 put: oop size: 8 signed: false;
		integerAt: offset + 16 put: classOop size: 8 signed: false;
		integerAt: offset + 24 put: 1 size: 8 signed: true;
		integerAt: offset + 32 put: idxSizeBits size: 8 signed: false.
	valueOffset := offset + 40.
	1 to: valueSize do: [ :index |
		traversalBuffer unsignedByteAt: valueOffset + index - 1 put: (byteArray at: index) ].
	^ offset + 40 + alignedSize
]

{ #category : 'running' }
GbsSessionCoreTest >> writePointerTraversalReportOn: traversalBuffer offset: offset oop: oop classOop: classOop namedSize: namedSize indexedSize: indexedSize firstOffset: firstOffset oops: oopArray [
	| valueSize alignedSize idxSizeBits valueOffset |
	valueSize := oopArray size * 8.
	alignedSize := self alignedTraversalValueByteCount: valueSize.
	idxSizeBits := indexedSize bitShift: 24.
	traversalBuffer
		integerAt: offset put: valueSize size: 4 signed: true;
		integerAt: offset + 4 put: namedSize size: 2 signed: true;
		integerAt: offset + 8 put: oop size: 8 signed: false;
		integerAt: offset + 16 put: classOop size: 8 signed: false;
		integerAt: offset + 24 put: firstOffset size: 8 signed: true;
		integerAt: offset + 32 put: idxSizeBits size: 8 signed: false.
	valueOffset := offset + 40.
	oopArray doWithIndex: [ :value :index |
		traversalBuffer
			integerAt: valueOffset + ((index - 1) * 8)
			put: value
			size: 8
			signed: false ].
	^ offset + 40 + alignedSize
]

{ #category : 'running' }
GbsSessionCoreTest >> setUp [
	super setUp.
	previousObjectSpaceFinalizationRegistry := Smalltalk globals
		at: #GbsObjectSpaceFinalizationRegistry
		ifAbsent: [ nil ].
	GbsObjectSpaceFacade resetFinalizationRegistry.
	session := GbsSession new
]

{ #category : 'running' }
GbsSessionCoreTest >> tearDown [
	GbsSession notificationActions removeAll.
	GbsSession sessionSignalActions removeAll.
	GbsSession signaledAbortActions removeAll.
	previousObjectSpaceFinalizationRegistry
		ifNil: [ Smalltalk globals removeKey: #GbsObjectSpaceFinalizationRegistry ifAbsent: [ ] ]
		ifNotNil: [ Smalltalk globals at: #GbsObjectSpaceFinalizationRegistry put: previousObjectSpaceFinalizationRegistry ].
	Smalltalk globals removeKey: #GbsMaterializedObjectSessionRegistry ifAbsent: [ ].
	Smalltalk globals removeKey: #GbsSessionReplicationPolicies ifAbsent: [ ].
	super tearDown
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationDoesNotMarkDuringMaterialization [
	| mockSession result nested dirtyOops |
	mockSession := self materializationMockSession.
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.
	nested := result second.

	self assert: mockSession dirtyMaterializedObjectOops isEmpty.
	result at: 1 put: 'changed'.
	nested at: 1 put: 'nested-changed'.
	dirtyOops := mockSession dirtyMaterializedObjectOops asSet.
	self assert: (dirtyOops includes: 9000).
	self assert: (dirtyOops includes: 9016)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationResetUnregistersMaterializedObject [
	| mockSession array |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.

	mockSession resetMaterializedObjectDirtyTracking.
	array at: 1 put: 'new'.

	self deny: (mockSession isMaterializedObjectDirty: array).
	self assert: mockSession dirtyMaterializedObjectOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationTracksCollectionMutators [
	| mockSession array dictionary ordered set bag association dirtyOops |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	dictionary := Dictionary new.
	ordered := OrderedCollection new.
	set := Set new.
	bag := Bag new.
	association := Association key: #key value: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	mockSession rememberMaterializedObject: dictionary forOop: 9100.
	mockSession rememberMaterializedObject: ordered forOop: 9200.
	mockSession rememberMaterializedObject: set forOop: 9300.
	mockSession rememberMaterializedObject: bag forOop: 9400.
	mockSession rememberMaterializedObject: association forOop: 9500.

	array at: 1 put: 'new'.
	dictionary at: #key put: 'value'.
	ordered add: 'item'.
	set add: 'item'.
	bag add: 'item' withOccurrences: 2.
	association value: 'new'.

	dirtyOops := mockSession dirtyMaterializedObjectOops asSet.
	#(9000 9100 9200 9300 9400 9500) do: [ :oop |
		self assert: (dirtyOops includes: oop) ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationTracksSuccessfulRemovalOnly [
	| mockSession ordered set bag dictionary |
	mockSession := CoreMockGbsSession new.
	ordered := OrderedCollection with: 'old'.
	set := Set with: 'old'.
	bag := Bag new add: 'old'; yourself.
	dictionary := Dictionary new at: #old put: 'value'; yourself.
	mockSession rememberMaterializedObject: ordered forOop: 9200.
	mockSession rememberMaterializedObject: set forOop: 9300.
	mockSession rememberMaterializedObject: bag forOop: 9400.
	mockSession rememberMaterializedObject: dictionary forOop: 9500.

	ordered remove: 'missing' ifAbsent: [ #missing ].
	set remove: 'missing' ifAbsent: [ #missing ].
	bag remove: 'missing' ifAbsent: [ #missing ].
	dictionary removeKey: #missing ifAbsent: [ #missing ].
	self assert: mockSession dirtyMaterializedObjectOops isEmpty.

	ordered remove: 'old' ifAbsent: [ self fail ].
	set remove: 'old' ifAbsent: [ self fail ].
	bag remove: 'old' ifAbsent: [ self fail ].
	dictionary removeKey: #old ifAbsent: [ self fail ].
	self assert: (mockSession dirtyMaterializedObjectOops asSet includesAll: #(9200 9300 9400 9500))
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationPolicyDefaultsMirrorCompatibilitySettings [
	| policy |
	policy := GbsReplicationPolicy default.

	self assert: policy autoMarkDirty.
	self assert: policy blockReplicationPolicy equals: 'replicate'.
	self assert: policy defaultFaultPolicy equals: 'lazy'.
	self deny: policy asyncSignalPollingEnabled.
	self assert: policy eventPollingFrequency equals: 300.
	self assert: policy eventPriority equals: 3.
	self assert: policy faultLevelRpc equals: 4.
	self assert: policy freeOopBatchSize equals: 256.
	self assert: policy freeSlotsOnStubbing.
	self assert: policy serverMapMode equals: 'weak'.
	self assert: policy storeTraversalTransport equals: 'script'.
	self assert: policy traversalBufferSize equals: 250000
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationPolicyCanCopyConvertedConfigurationValues [
	| configuration policy |
	configuration := GbsConfiguration new.
	configuration
		valueAt: #autoMarkDirty put: false;
		valueAt: #blockReplicationPolicy put: 'stub';
		valueAt: #defaultFaultPolicy put: 'eager';
		asyncSignalPollingEnabled: true;
		valueAt: #eventPollingFrequency put: 125;
		valueAt: #eventPriority put: 6;
		valueAt: #faultLevelRpc put: 2;
		freeOopBatchSize: 64;
		valueAt: #freeSlotsOnStubbing put: false;
		serverMapMode: 'strong';
		storeTraversalTransport: 'binaryRequired';
		valueAt: #traversalBufferSize put: 8192.

	policy := GbsReplicationPolicy fromConfiguration: configuration.

	self deny: policy autoMarkDirty.
	self assert: policy blockReplicationPolicy equals: 'stub'.
	self assert: policy defaultFaultPolicy equals: 'eager'.
	self assert: policy asyncSignalPollingEnabled.
	self assert: policy eventPollingFrequency equals: 125.
	self assert: policy eventPriority equals: 6.
	self assert: policy faultLevelRpc equals: 2.
	self assert: policy freeOopBatchSize equals: 64.
	self deny: policy freeSlotsOnStubbing.
	self assert: policy serverMapMode equals: 'strong'.
	self assert: policy storeTraversalTransport equals: 'binaryRequired'.
	self assert: policy traversalBufferSize equals: 8192
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClampManagerCanDisableAutoDirtyMarkingForClassAndOverrideByIdentity [
	| mockSession first second manager |
	mockSession := CoreMockGbsSession new.
	first := Array with: 'old'.
	second := Array with: 'old'.
	mockSession rememberMaterializedObject: first forOop: 9000.
	mockSession rememberMaterializedObject: second forOop: 9016.
	manager := GbxClampManager forSession: mockSession.
	manager clampClass: Array toScheme: GbxReplicationScheme none.
	manager clampObject: second toScheme: GbxReplicationScheme replicate.

	first at: 1 put: 'new'.
	second at: 1 put: 'new'.

	self deny: (mockSession isMaterializedObjectDirty: first).
	self assert: (mockSession isMaterializedObjectDirty: second)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClampManagerSupportsDefaultAndScopedReplicationSpecSets [
	| mockSession manager defaultScheme scopedResult |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager clampManager.

	self assert: manager defaultReplicationSpecSet equals: #replicate.
	defaultScheme := manager defaultReplicationSpecSet: #customerReplicationSpec.
	self assert: manager currentReplicationScheme equals: defaultScheme.
	self assert: manager defaultReplicationSpecSet equals: #customerReplicationSpec.

	scopedResult := manager
		usingReplicationSpecSet: #none
		do: [
			self assert: manager currentReplicationScheme selector equals: #none.
			#inside ].

	self assert: scopedResult equals: #inside.
	self assert: manager currentReplicationScheme equals: defaultScheme
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClampManagerInvalidatesNamedReplicationSchemeAndRestoresDefault [
	| mockSession manager scheme |
	mockSession := CoreMockGbsSession new.
	manager := mockSession replicatorManager clampManager.
	scheme := manager defaultReplicationSpecSet: #customerReplicationSpec.

	self assert: (manager invalidateSchemeWithSelector: #customerReplicationSpec).

	self deny: scheme isValid.
	self assert: manager defaultReplicationSpecSet equals: #replicate.
	self deny: (manager invalidateSchemeWithSelector: #customerReplicationSpec)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationSchemeTransitiveClosureSpecMatchesVisualWorksFiltering [
	| scheme spec closure |
	scheme := GbxReplicationScheme replicate.
	spec := #(
		#(#name #replicate)
		#(#address #min 1)
		#(#orders #max 2)
		#(#notes #stub)
		#(#handler #forwarder)
		#(#indexable_part #forwarder)).

	closure := scheme transitiveClosureSpecForReplicationSpec: spec.

	self assert: closure equals: #(
		#(#name #replicate)
		#(#handler #forwarder)
		#(#indexable_part #forwarder)).
	self assert: (scheme transitiveClosureSpecForReplicationSpec: #callback) isEmpty.
	self assert: (scheme transitiveClosureSpecForReplicationSpec: nil) isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClampSpecificationDefaultsMirrorServerClampMetadata [
	| clamp |
	clamp := GbxClampSpecification new.

	self assert: clamp addSubleafHeaders.
	self assert: clamp traversalCallBackSelector equals: #_gbsTraversalCallback.
	self assert: clamp environmentId equals: 0.
	self assert: clamp instVarLevels isEmpty.
	self assert: clamp instVarLevelsSelector isNil.
	self assert: clamp valueClamps isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClampedTraversalArgumentsWriteNativeBuffer [
	| traversalBuffer arguments |
	traversalBuffer := ExternalAddress allocate: 64.
	[
		arguments := GbsClampedTraversalArguments
			clampSpecOop: 777
			traversalBuffer: traversalBuffer
			level: 3
			retrievalFlags: 5.

		arguments withNativeBufferDo: [ :buffer |
			self assert: (buffer integerAt: 1 size: 8 signed: false) asInteger equals: 777.
			self assert: (buffer integerAt: 9 size: 8 signed: false) asInteger equals: 20.
			self
				assert: (buffer integerAt: 17 size: 8 signed: false) asInteger
				equals: traversalBuffer asInteger.
			self assert: (buffer integerAt: 25 size: 4 signed: true) equals: 3.
			self assert: (buffer integerAt: 29 size: 4 signed: true) equals: 5.
			self assert: (buffer integerAt: 33 size: 4 signed: true) equals: 1 ] ]
		ensure: [ traversalBuffer free ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testServerClampSpecificationSynchronizerInstallsAndCachesByFingerprint [
	| mockSession scheme bodies bindings first second third entries |
	mockSession := CoreMockGbsSession new.
	bodies := OrderedCollection new.
	bindings := OrderedCollection new.
	mockSession stubs
		at: #returnRemoteCommandBody
		put: [ :bodyString :literalBindings :oopBindings |
			bodies add: bodyString.
			bindings add: literalBindings.
			7000 + bodies size ].
	scheme := GbxReplicationScheme selector: #customerReplicationSpec.
	scheme
		updateInstVarLevelsForClass: Association
		serverInstVarNames: #('key' 'value')
		replicationSpec: #(
			#(#key #forwarder)
			#(#value #min 2)).

	first := GbsServerClampSpecificationSynchronizer
		clampSpecOopForScheme: scheme
		session: mockSession.
	second := GbsServerClampSpecificationSynchronizer
		clampSpecOopForScheme: scheme
		session: mockSession.

	self assert: first equals: 7001.
	self assert: second equals: first.
	self assert: bodies size equals: 1.
	self assert: (bodies first includesSubstring: 'ClampSpecification new').
	self assert: (bodies first includesSubstring: '#FastIdentityKeyValueDictionary').
	entries := bindings first at: 'classLevelEntries'.
	self assert: entries first first equals: 'Association'.
	self assert: entries first second equals: { false. -2. nil }.

	scheme
		updateInstVarLevelsForClass: Array
		serverInstVarNames: #()
		replicationSpec: #(#(#indexable_part #forwarder)).
	third := GbsServerClampSpecificationSynchronizer
		clampSpecOopForScheme: scheme
		session: mockSession.

	self assert: third equals: 7002.
	self assert: bodies size equals: 2
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalBufferReaderFallsBackToPlainTraversalWithoutClampMetadata [
	| mockSession clampedCalls plainCalls reports |
	mockSession := CoreMockGbsSession new.
	clampedCalls := 0.
	plainCalls := 0.
	mockSession stubs
		at: #supportsClampedTraversalTransport put: true;
		at: #apiGciClampedTravOops put: [ :oopBuffer :oopCount :clampedArgs |
			clampedCalls := clampedCalls + 1.
			1 ];
		at: #apiGciTraverseOops put: [ :oopBuffer :oopCount :traversalBuffer :level |
			plainCalls := plainCalls + 1.
			traversalBuffer integerAt: 5 put: 0 size: 4 signed: false.
			1 ].

	reports := (GbsMaterializationTraversalBufferReader on: mockSession)
		reportsForOops: #(9000)
		level: 1
		label: 'plain traversal fallback test'.

	self assert: reports isEmpty.
	self assert: plainCalls equals: 1.
	self assert: clampedCalls equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalBufferReaderUsesClampedTraversalForSchemeMetadata [
	| mockSession manager clampedCalls plainCalls capturedClamp capturedLevel reports |
	mockSession := CoreMockGbsSession new.
	clampedCalls := 0.
	plainCalls := 0.
	mockSession stubs
		at: #supportsClampedTraversalTransport put: true;
		at: #returnRemoteCommandBody put: [ :bodyString :literalBindings :oopBindings | 777 ];
		at: #apiGciTraverseOops put: [ :oopBuffer :oopCount :traversalBuffer :level |
			plainCalls := plainCalls + 1.
			traversalBuffer integerAt: 5 put: 0 size: 4 signed: false.
			1 ];
		at: #apiGciClampedTravOops put: [ :oopBuffer :oopCount :clampedArgs |
			| traversalBufferAddress traversalBuffer |
			clampedCalls := clampedCalls + 1.
			capturedClamp := (clampedArgs integerAt: 1 size: 8 signed: false) asInteger.
			capturedLevel := clampedArgs integerAt: 25 size: 4 signed: true.
			traversalBufferAddress := (clampedArgs integerAt: 17 size: 8 signed: false) asInteger.
			traversalBuffer := ExternalAddress fromAddress: traversalBufferAddress.
			traversalBuffer integerAt: 5 put: 0 size: 4 signed: false.
			1 ].
	manager := GbxClampManager forSession: mockSession.
	manager defaultReplicationScheme
		updateInstVarLevelsForClass: Array
		serverInstVarNames: #()
		replicationSpec: #(#(#indexable_part #forwarder)).

	reports := (GbsMaterializationTraversalBufferReader on: mockSession)
		reportsForOops: #(9000)
		level: 2
		label: 'clamped traversal test'.

	self assert: reports isEmpty.
	self assert: clampedCalls equals: 1.
	self assert: plainCalls equals: 0.
	self assert: capturedClamp equals: 777.
	self assert: capturedLevel equals: 2.
	self assert: (mockSession materializationMetrics at: #clampedTraversalBufferFetchCalls) equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalBufferReaderPlainReportsBypassClampedSchemeMetadata [
	| mockSession manager clampedCalls plainCalls reports |
	mockSession := CoreMockGbsSession new.
	clampedCalls := 0.
	plainCalls := 0.
	mockSession stubs
		at: #supportsClampedTraversalTransport put: true;
		at: #returnRemoteCommandBody put: [ :bodyString :literalBindings :oopBindings | 777 ];
		at: #apiGciTraverseOops put: [ :oopBuffer :oopCount :traversalBuffer :level |
			plainCalls := plainCalls + 1.
			traversalBuffer integerAt: 5 put: 0 size: 4 signed: false.
			1 ];
		at: #apiGciClampedTravOops put: [ :oopBuffer :oopCount :clampedArgs |
			clampedCalls := clampedCalls + 1.
			1 ].
	manager := GbxClampManager forSession: mockSession.
	manager defaultReplicationScheme
		updateInstVarLevelsForClass: Array
		serverInstVarNames: #()
		replicationSpec: #(#(#indexable_part #forwarder)).

	reports := (GbsMaterializationTraversalBufferReader on: mockSession)
		plainReportsForOops: #(9000)
		level: 1
		label: 'plain traversal under clamp scheme test'.

	self assert: reports isEmpty.
	self assert: plainCalls equals: 1.
	self assert: clampedCalls equals: 0.
	self assert: (mockSession materializationMetrics at: #clampedTraversalBufferFetchCalls ifAbsent: [ 0 ]) equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationSchemeClampByCallbackTogglesTraversalSelector [
	| mockSession scheme |
	mockSession := CoreMockGbsSession new.
	scheme := GbxReplicationScheme selector: #customerReplicationSpec.

	scheme updateForClampingByCallback: true inSession: mockSession.
	self assert: scheme clamp instVarLevelsSelector equals: #_gbsTraversalCallback.

	scheme updateForClampingByCallback: false inSession: mockSession.
	self assert: scheme clamp instVarLevelsSelector isNil
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationSchemeTranslatesVisualWorksPerInstvarSpecs [
	| scheme levels |
	scheme := GbxReplicationScheme selector: #customerReplicationSpec.

	scheme
		updateInstVarLevelsForClass: Association
		serverInstVarNames: #('key' 'value')
		replicationSpec: #(
			#(#key #forwarder)
			#(#value #min 3)
			#(#indexable_part #stub)).

	levels := scheme instVarLevelsForClass: Association.
	self assert: levels equals: { false. -3. 0 }.
	self assert: (scheme shouldProxyNamedSlot: 1 ofClass: Association).
	self deny: (scheme shouldProxyNamedSlot: 2 ofClass: Association).
	self deny: (scheme shouldProxyIndexedInstvarsOfClass: Association)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationSchemePreservesServerOrderNilMappingsAndForwarders [
	| scheme levels |
	scheme := GbxReplicationScheme selector: #customerReplicationSpec.

	scheme
		updateInstVarLevelsForClass: Association
		serverInstVarNames: #('missing' 'key' 'value')
		replicationSpec: #(
			#(#key #replicate)
			#(#value #forwarder)
			#(#indexable_part #stub)).

	levels := scheme instVarLevelsForClass: Association.
	self assert: levels equals: { nil. nil. false. 0 }.
	self deny: (scheme shouldProxyNamedSlot: 1 ofClass: Association).
	self deny: (scheme shouldProxyNamedSlot: 2 ofClass: Association).
	self assert: (scheme shouldProxyNamedSlot: 3 ofClass: Association).
	self deny: (scheme shouldProxyIndexedInstvarsOfClass: Association)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationSchemeTranslatesIndexableForwarderSpec [
	| scheme levels |
	scheme := GbxReplicationScheme selector: #customerReplicationSpec.

	scheme
		updateInstVarLevelsForClass: Array
		serverInstVarNames: #()
		replicationSpec: #(#(#indexable_part #forwarder)).

	levels := scheme instVarLevelsForClass: Array.
	self assert: levels equals: { false }.
	self assert: (scheme shouldProxyIndexedInstvarsOfClass: Array)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationSchemeIndexableForwarderSpecKeepsNestedArraysAsProxies [
	| mockSession result nested manager |
	mockSession := self materializationMockSession.
	manager := GbxClampManager forSession: mockSession.
	manager defaultReplicationScheme
		updateInstVarLevelsForClass: Array
		serverInstVarNames: #()
		replicationSpec: #(#(#indexable_part #forwarder)).
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.
	nested := result second.

	self assert: result first equals: 'vip'.
	self assert: (nested isKindOf: GbsProxy).
	self assert: nested oop equals: 9016
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationPolicyCanDisableAutoMarkDirtyForSession [
	| mockSession array policy |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	policy := GbsReplicationPolicy forSession: mockSession.
	policy autoMarkDirty: false.

	array at: 1 put: 'new'.

	self deny: (mockSession isMaterializedObjectDirty: array).
	self assert: mockSession dirtyMaterializedObjectOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationSchemeModesControlDirtyTracking [
	| mockSession replicateArray stubArray noneArray namedSpecArray manager |
	mockSession := CoreMockGbsSession new.
	replicateArray := Array with: 'old'.
	stubArray := Array with: 'old'.
	noneArray := Array with: 'old'.
	namedSpecArray := Array with: 'old'.
	mockSession rememberMaterializedObject: replicateArray forOop: 9000.
	mockSession rememberMaterializedObject: stubArray forOop: 9016.
	mockSession rememberMaterializedObject: noneArray forOop: 9032.
	mockSession rememberMaterializedObject: namedSpecArray forOop: 9048.
	manager := GbxClampManager forSession: mockSession.
	manager
		clampObject: replicateArray toScheme: GbxReplicationScheme replicate;
		clampObject: stubArray toScheme: GbxReplicationScheme stub;
		clampObject: noneArray toScheme: GbxReplicationScheme none;
		clampObject: namedSpecArray toScheme: (manager replicationSchemeForSet: #customerReplicationSpec).

	replicateArray at: 1 put: 'new'.
	stubArray at: 1 put: 'new'.
	noneArray at: 1 put: 'new'.
	namedSpecArray at: 1 put: 'new'.

	self assert: (mockSession isMaterializedObjectDirty: replicateArray).
	self deny: (mockSession isMaterializedObjectDirty: stubArray).
	self deny: (mockSession isMaterializedObjectDirty: noneArray).
	self assert: (mockSession isMaterializedObjectDirty: namedSpecArray)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationPolicyNormalizesSymbolsAndFaultPolicy [
	| mockSession array policy |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	policy := GbsReplicationPolicy forSession: mockSession.
	policy
		blockReplicationPolicy: #callback;
		defaultFaultPolicy: 'eager';
		serverMapMode: #strong;
		storeTraversalTransport: #binaryRequired.

	self assert: policy blockReplicationPolicySymbol equals: #callback.
	self assert: policy defaultFaultPolicySymbol equals: #immediate.
	self assert: policy serverMapModeSymbol equals: #strong.
	self assert: policy storeTraversalTransportSymbol equals: #binaryRequired.
	self assert: array faultPolicy equals: #immediate.
	self should: [ policy defaultFaultPolicy: #invalid ] raise: Error
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationPolicyAcceptsSettingsPresenterPolicyValues [
	| policy |
	policy := GbsReplicationPolicy default.

	policy
		blockReplicationPolicy: #stub;
		defaultFaultPolicy: #none;
		serverMapMode: #strong;
		storeTraversalTransport: #binary.

	self assert: policy blockReplicationPolicySymbol equals: #stub.
	self assert: policy defaultFaultPolicySymbol equals: #none.
	self assert: policy serverMapModeSymbol equals: #strong.
	self assert: policy storeTraversalTransportSymbol equals: #binary.

	policy blockReplicationPolicy: #none.
	self assert: policy blockReplicationPolicySymbol equals: #none
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationPolicyResetAfterLogout [
	| mockSession policy |
	mockSession := CoreMockGbsSession new.
	policy := GbsReplicationPolicy forSession: mockSession.
	policy autoMarkDirty: false.

	mockSession resetAfterLogout.

	self deny: (GbsReplicationPolicy forSession: mockSession) == policy.
	self assert: (GbsReplicationPolicy forSession: mockSession) autoMarkDirty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalBufferSizeCanComeFromReplicationPolicy [
	| mockSession reader policy |
	mockSession := CoreMockGbsSession new.
	reader := GbsMaterializationTraversalBufferReader on: mockSession.
	policy := GbsReplicationPolicy forSession: mockSession.
	policy traversalBufferSize: 4096.

	self assert: reader traversalBufferBytesFromReplicationPolicy equals: 4096
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReplicationPolicyIsSessionScoped [
	| disabledSession enabledSession disabledArray enabledArray |
	disabledSession := CoreMockGbsSession new.
	enabledSession := CoreMockGbsSession new.
	disabledArray := Array with: 'old'.
	enabledArray := Array with: 'old'.
	disabledSession rememberMaterializedObject: disabledArray forOop: 9000.
	enabledSession rememberMaterializedObject: enabledArray forOop: 9000.
	(GbsReplicationPolicy forSession: disabledSession) autoMarkDirty: false.

	disabledArray at: 1 put: 'disabled'.
	enabledArray at: 1 put: 'enabled'.

	self deny: (disabledSession isMaterializedObjectDirty: disabledArray).
	self assert: (enabledSession isMaterializedObjectDirty: enabledArray)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationFlushKeepsDirtyObjectsWhenRemoteStoreFails [
	| mockSession array |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	array at: 1 put: 'new'.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		Error signal: 'remote store failed' ].

	self
		should: [ mockSession flushDirtyMaterializedObjects ]
		raise: Error.
	self assert: (mockSession isMaterializedObjectDirty: array).
	self assert: (mockSession dirtyMaterializedObjectOops asSet includes: 9000)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationBinaryTransportFallsBackToScriptWhenUnavailable [
	| mockSession array capturedScript |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binary'.
	array at: 1 put: 'new'.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		capturedScript := script.
		268 ].

	mockSession flushDirtyMaterializedObjects.

	self assert: (capturedScript includesSubstring: 'object at: 1 put: value1_1')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationBinaryTransportRequiredKeepsDirtyObjectsWhenUnavailable [
	| mockSession array |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binaryRequired'.
	array at: 1 put: 'new'.

	self
		should: [ mockSession flushDirtyMaterializedObjects ]
		raise: Error.
	self assert: (mockSession isMaterializedObjectDirty: array)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationBinaryTransportFallsBackToScriptWhenBatchCannotEncodeNatively [
	| mockSession array capturedScript |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binary'.
	mockSession stubs at: #supportsDirtyStoreTraversalBufferTransport put: true.
	array at: 1 put: 'new'.
	mockSession stubs at: #storeTraversalBuffer put: [ :buffer | self fail ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		capturedScript := script.
		268 ].

	mockSession flushDirtyMaterializedObjects.

	self assert: (capturedScript includesSubstring: 'object at: 1 put: value1_1')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationBinaryTransportRequiredFailsWhenBatchCannotEncodeNatively [
	| mockSession array |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binaryRequired'.
	mockSession stubs at: #supportsDirtyStoreTraversalBufferTransport put: true.
	array at: 1 put: 'new'.

	self
		should: [ mockSession flushDirtyMaterializedObjects ]
		raise: Error
		withExceptionDo: [ :ex |
			self assert: (ex messageText includesSubstring: 'cannot be encoded natively') ].
	self assert: (mockSession isMaterializedObjectDirty: array)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationFlushUsesBinaryStoreTraversalBufferWhenAvailable [
	| mockSession array capturedBuffer flushed |
	mockSession := CoreMockGbsSession new.
	array := Array with: 1.
	mockSession rememberMaterializedObject: array forOop: 9000.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binary'.
	array at: 1 put: 2.
	mockSession stubs at: #supportsDirtyStoreTraversalBufferTransport put: true.
	mockSession stubs at: #storeTraversalBuffer put: [ :buffer |
		capturedBuffer := buffer.
		268 ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script | self fail ].

	flushed := mockSession flushDirtyMaterializedObjects.

	self assert: flushed equals: #(9000).
	self assert: capturedBuffer class equals: GbsDirtyStoreTraversalBuffer.
	self assert: capturedBuffer entries first first equals: 9000.
	self assert: (capturedBuffer payload copyFrom: 1 to: 7) equals: #[71 66 83 68 83 84 49].
	self assert: mockSession dirtyMaterializedObjectOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationFlushUsesBinaryStoreTraversalBufferForAssociationAndOrderedCollection [
	| mockSession association ordered capturedBuffer flushed |
	mockSession := CoreMockGbsSession new.
	association := Association key: 1 value: 2.
	ordered := OrderedCollection with: 3.
	mockSession rememberMaterializedObject: association forOop: 9100.
	mockSession rememberMaterializedObject: ordered forOop: 9200.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binaryRequired'.
	association value: true.
	ordered add: nil.
	mockSession stubs at: #supportsDirtyStoreTraversalBufferTransport put: true.
	mockSession stubs at: #storeTraversalBuffer put: [ :buffer |
		capturedBuffer := buffer.
		268 ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script | self fail ].

	flushed := mockSession flushDirtyMaterializedObjects.

	self assert: flushed asSet equals: #(9100 9200) asSet.
	self assert: capturedBuffer class equals: GbsDirtyStoreTraversalBuffer.
	self assert: capturedBuffer canProduceNativeTraversalBuffer.
	self assert: mockSession dirtyMaterializedObjectOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationFlushUsesBinaryStoreTraversalBufferForDictionarySetBagAndNamedObject [
	| mockSession dictionary dictionaryAssociation set bag point capturedBuffer flushed |
	mockSession := CoreMockGbsSession new.
	dictionary := Dictionary new.
	set := Set new.
	bag := Bag new.
	point := 3 @ 4.
	mockSession rememberMaterializedObject: dictionary forOop: 9300.
	mockSession rememberMaterializedObject: set forOop: 9400.
	mockSession rememberMaterializedObject: bag forOop: 9500.
	mockSession rememberMaterializedObject: point forOop: 9600.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binaryRequired'.
	dictionary at: 1 put: true.
	dictionaryAssociation := dictionary associations asArray first.
	mockSession rememberMaterializedObject: dictionaryAssociation forOop: 9308.
	set add: nil.
	bag add: 2 withOccurrences: 2.
	mockSession dirtyPool markDirty: point.
	mockSession stubs at: #supportsDirtyStoreTraversalBufferTransport put: true.
	mockSession stubs at: #storeTraversalBuffer put: [ :buffer |
		capturedBuffer := buffer.
		268 ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script | self fail ].

	flushed := mockSession flushDirtyMaterializedObjects.

	self assert: flushed asSet equals: #(9300 9400 9500 9600) asSet.
	self assert: capturedBuffer class equals: GbsDirtyStoreTraversalBuffer.
	self assert: capturedBuffer canProduceNativeTraversalBuffer.
	self assert: (capturedBuffer entries collect: [ :entry | entry at: 3 ]) asSet equals: #(#dictionary #set #bag #namedObject) asSet.
	self assert: mockSession dirtyMaterializedObjectOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationBinaryStoreTraversalCarriesNoLongerReplicatedOopsWhenSupported [
	| mockSession array capturedBuffer capturedNoLonger flushed |
	mockSession := CoreMockGbsSession new.
	array := Array with: 1.
	mockSession rememberMaterializedObject: array forOop: 9000.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binaryRequired'.
	array at: 1 put: 2.
	GbsSessionLifecycleManager noteNoLongerReplicatedOop: 9016 forSession: mockSession.
	GbsSessionLifecycleManager noteNoLongerReplicatedOop: 9032 forSession: mockSession.
	mockSession stubs at: #supportsDirtyStoreTraversalBufferTransport put: true.
	mockSession stubs at: #supportsNoLongerReplicatedStoreTraversalTransport put: true.
	mockSession stubs at: #storeTraversalBufferReleasingNoLongerReplicatedOops put: [ :buffer :oops |
		capturedBuffer := buffer.
		capturedNoLonger := oops asArray.
		268 ].

	flushed := mockSession flushDirtyMaterializedObjects.

	self assert: flushed equals: #(9000).
	self assert: capturedBuffer class equals: GbsDirtyStoreTraversalBuffer.
	self assert: capturedNoLonger equals: #(9016 9032).
	self assert: mockSession objectSpace pendingNoLongerReplicatedOops isEmpty.
	self assert: mockSession dirtyMaterializedObjectOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationBinaryStoreTraversalCarriesGcedAndNoLongerReplicatedOopsWhenSupported [
	| mockSession array capturedBuffer capturedNoLonger capturedGced flushed |
	mockSession := CoreMockGbsSession new.
	array := Array with: 1.
	mockSession rememberMaterializedObject: array forOop: 9000.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binaryRequired'.
	array at: 1 put: 2.
	GbsSessionLifecycleManager noteNoLongerReplicatedOop: 9016 forSession: mockSession.
	GbsSessionLifecycleManager noteGcedOop: 9032 forSession: mockSession.
	mockSession stubs at: #supportsDirtyStoreTraversalBufferTransport put: true.
	mockSession stubs at: #supportsNoLongerReplicatedStoreTraversalTransport put: true.
	mockSession stubs at: #storeTraversalBufferReleasingExportSetOops put: [ :buffer :noLongerOops :gcedOops |
		capturedBuffer := buffer.
		capturedNoLonger := noLongerOops asArray.
		capturedGced := gcedOops asArray.
		268 ].

	flushed := mockSession flushDirtyMaterializedObjects.

	self assert: flushed equals: #(9000).
	self assert: capturedBuffer class equals: GbsDirtyStoreTraversalBuffer.
	self assert: capturedNoLonger equals: #(9016).
	self assert: capturedGced equals: #(9032).
	self assert: mockSession objectSpace pendingNoLongerReplicatedOops isEmpty.
	self assert: mockSession objectSpace pendingGcedOops isEmpty.
	self assert: mockSession objectSpace pendingExportSetReleaseOopCount equals: 0.
	self assert: mockSession dirtyMaterializedObjectOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationBinaryStoreTraversalKeepsNoLongerReplicatedOopsWhenTransportFails [
	| mockSession array |
	mockSession := CoreMockGbsSession new.
	array := Array with: 1.
	mockSession rememberMaterializedObject: array forOop: 9000.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binaryRequired'.
	array at: 1 put: 2.
	GbsSessionLifecycleManager noteNoLongerReplicatedOop: 9016 forSession: mockSession.
	mockSession stubs at: #supportsDirtyStoreTraversalBufferTransport put: true.
	mockSession stubs at: #supportsNoLongerReplicatedStoreTraversalTransport put: true.
	mockSession stubs at: #storeTraversalBufferReleasingNoLongerReplicatedOops put: [ :buffer :oops |
		Error signal: 'store traversal refs failed' ].

	self
		should: [ mockSession flushDirtyMaterializedObjects ]
		raise: Error.
	self assert: (mockSession isMaterializedObjectDirty: array).
	self assert: mockSession objectSpace pendingNoLongerReplicatedOops equals: #(9016)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationBinaryStoreTraversalKeepsExportSetOopsWhenTransportFails [
	| mockSession array |
	mockSession := CoreMockGbsSession new.
	array := Array with: 1.
	mockSession rememberMaterializedObject: array forOop: 9000.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binaryRequired'.
	array at: 1 put: 2.
	GbsSessionLifecycleManager noteNoLongerReplicatedOop: 9016 forSession: mockSession.
	GbsSessionLifecycleManager noteGcedOop: 9032 forSession: mockSession.
	mockSession stubs at: #supportsDirtyStoreTraversalBufferTransport put: true.
	mockSession stubs at: #supportsNoLongerReplicatedStoreTraversalTransport put: true.
	mockSession stubs at: #storeTraversalBufferReleasingExportSetOops put: [ :buffer :noLongerOops :gcedOops |
		Error signal: 'store traversal refs failed' ].

	self
		should: [ mockSession flushDirtyMaterializedObjects ]
		raise: Error.
	self assert: (mockSession isMaterializedObjectDirty: array).
	self assert: mockSession objectSpace pendingNoLongerReplicatedOops equals: #(9016).
	self assert: mockSession objectSpace pendingGcedOops equals: #(9032)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationBinaryStoreTraversalLeavesNoLongerReplicatedOopsWhenUnsupported [
	| mockSession array capturedBuffer |
	mockSession := CoreMockGbsSession new.
	array := Array with: 1.
	mockSession rememberMaterializedObject: array forOop: 9000.
	(GbsReplicationPolicy forSession: mockSession) storeTraversalTransport: 'binaryRequired'.
	array at: 1 put: 2.
	GbsSessionLifecycleManager noteNoLongerReplicatedOop: 9016 forSession: mockSession.
	mockSession stubs at: #supportsDirtyStoreTraversalBufferTransport put: true.
	mockSession stubs at: #storeTraversalBuffer put: [ :buffer |
		capturedBuffer := buffer.
		268 ].

	mockSession flushDirtyMaterializedObjects.

	self assert: capturedBuffer class equals: GbsDirtyStoreTraversalBuffer.
	self assert: mockSession objectSpace pendingNoLongerReplicatedOops equals: #(9016).
	self assert: mockSession dirtyMaterializedObjectOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testStoreTravDoTravRefsArgumentsWriteNativeBuffers [
	| mockSession array dirtyBuffer arguments |
	mockSession := CoreMockGbsSession new.
	array := Array with: 1.
	mockSession rememberMaterializedObject: array forOop: 9000.
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9000. array. #array } }
		session: mockSession.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: oop equals: 9000.
		7000 ].
	arguments := GbsStoreTravDoTravRefsArguments
		storeTraversalBuffer: dirtyBuffer
		noLongerReplicatedOops: #(9016 9032)
		gcedOops: #(9040)
		flags: 8.

	arguments
		withNativeBuffersOn: mockSession
		do: [ :noLongerBuffer :noLongerCount :gcedBuffer :gcedCount :stdArgs :ctArgs |
			self assert: noLongerCount equals: 2.
			self assert: gcedCount equals: 1.
			self assert: (noLongerBuffer integerAt: 1 size: 8 signed: false) asInteger equals: 9016.
			self assert: (noLongerBuffer integerAt: 9 size: 8 signed: false) asInteger equals: 9032.
			self assert: (gcedBuffer integerAt: 1 size: 8 signed: false) asInteger equals: 9040.
			self assert: (stdArgs integerAt: 1 size: 4 signed: true) equals: 3.
			self assert: (stdArgs integerAt: 5 size: 4 signed: true) equals: 16.
			self assert: (stdArgs integerAt: 17 size: 8 signed: false) asInteger equals: 20.
			self deny: ((stdArgs integerAt: 81 size: 8 signed: false) asInteger = 0).
			self assert: (stdArgs integerAt: 97 size: 4 signed: true) equals: 8.
			self assert: (ctArgs integerAt: 1 size: 8 signed: false) asInteger equals: 20.
			self assert: (ctArgs integerAt: 9 size: 8 signed: false) asInteger equals: 20.
			self deny: ((ctArgs integerAt: 17 size: 8 signed: false) asInteger = 0).
			self assert: (ctArgs integerAt: 33 size: 4 signed: true) equals: 1 ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyStoreTraversalBufferProducesNativeArrayReport [
	| mockSession array dirtyBuffer reader |
	mockSession := CoreMockGbsSession new.
	array := Array with: 1 with: nil with: true.
	mockSession rememberMaterializedObject: array forOop: 9000.
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9000. array. #array } }
		session: mockSession.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: oop equals: 9000.
		7000 ].
	reader := GbsMaterializationTraversalBufferReader on: mockSession.

	dirtyBuffer
		withNativeTraversalBufferOn: mockSession
		do: [ :nativeBuffer | | usedBytes report |
			usedBytes := nativeBuffer integerAt: 5 size: 4 signed: false.
			self assert: usedBytes equals: 64.
			report := reader reportAt: nativeBuffer offset: 9.
			self assert: report oop equals: 9000.
			self assert: report classOop equals: 7000.
			self assert: report objectFormat equals: 0.
			self assert: report indexedSize equals: 3.
			self assert: report valueOops equals: #(10 20 268) ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyStoreTraversalBufferProducesNativeAssociationReport [
	| mockSession association dirtyBuffer reader |
	mockSession := CoreMockGbsSession new.
	association := Association key: 7 value: true.
	mockSession rememberMaterializedObject: association forOop: 9100.
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9100. association. #association } }
		session: mockSession.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: oop equals: 9100.
		7100 ].
	reader := GbsMaterializationTraversalBufferReader on: mockSession.

	dirtyBuffer
		withNativeTraversalBufferOn: mockSession
		do: [ :nativeBuffer | | usedBytes report |
			usedBytes := nativeBuffer integerAt: 5 size: 4 signed: false.
			self assert: usedBytes equals: 56.
			report := reader reportAt: nativeBuffer offset: 9.
			self assert: report oop equals: 9100.
			self assert: report classOop equals: 7100.
			self assert: report objectFormat equals: 0.
			self assert: report namedSize equals: 2.
			self assert: report indexedSize equals: 0.
			self assert: report valueOops equals: #(58 268) ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyStoreTraversalBufferProducesNativeOrderedCollectionReport [
	| mockSession ordered dirtyBuffer reader |
	mockSession := CoreMockGbsSession new.
	ordered := OrderedCollection with: 1 with: nil with: false.
	mockSession rememberMaterializedObject: ordered forOop: 9200.
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9200. ordered. #orderedCollection } }
		session: mockSession.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: oop equals: 9200.
		7200 ].
	reader := GbsMaterializationTraversalBufferReader on: mockSession.

	dirtyBuffer
		withNativeTraversalBufferOn: mockSession
		do: [ :nativeBuffer | | usedBytes report |
			usedBytes := nativeBuffer integerAt: 5 size: 4 signed: false.
			self assert: usedBytes equals: 64.
			report := reader reportAt: nativeBuffer offset: 9.
			self assert: report oop equals: 9200.
			self assert: report classOop equals: 7200.
			self assert: report objectFormat equals: 0.
			self assert: report namedSize equals: 0.
			self assert: report indexedSize equals: 3.
			self assert: report valueOops equals: #(10 20 12) ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyStoreTraversalBufferProducesNativeDictionaryReportWhenAssociationsAreMapped [
	| mockSession dictionary association dirtyBuffer reader |
	mockSession := CoreMockGbsSession new.
	dictionary := Dictionary new
		at: 1 put: true;
		yourself.
	association := dictionary associations asArray first.
	mockSession rememberMaterializedObject: dictionary forOop: 9300.
	mockSession rememberMaterializedObject: association forOop: 9308.
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9300. dictionary. #dictionary } }
		session: mockSession.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: oop equals: 9300.
		7300 ].
	reader := GbsMaterializationTraversalBufferReader on: mockSession.

	dirtyBuffer
		withNativeTraversalBufferOn: mockSession
		do: [ :nativeBuffer | | usedBytes report |
			usedBytes := nativeBuffer integerAt: 5 size: 4 signed: false.
			self assert: usedBytes equals: 48.
			report := reader reportAt: nativeBuffer offset: 9.
			self assert: report oop equals: 9300.
			self assert: report classOop equals: 7300.
			self assert: report objectFormat equals: 0.
			self assert: report namedSize equals: 0.
			self assert: report indexedSize equals: 1.
			self assert: report valueOops equals: #(9308) ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyStoreTraversalBufferRejectsDictionaryWithUnmappedAssociations [
	| mockSession dictionary dirtyBuffer |
	mockSession := CoreMockGbsSession new.
	dictionary := Dictionary new
		at: 1 put: true;
		yourself.
	mockSession rememberMaterializedObject: dictionary forOop: 9300.
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9300. dictionary. #dictionary } }
		session: mockSession.

	self deny: dirtyBuffer canProduceNativeTraversalBuffer
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyStoreTraversalBufferProducesNativeIdentityDictionaryReport [
	| mockSession dictionary dirtyBuffer reader |
	mockSession := CoreMockGbsSession new.
	dictionary := IdentityDictionary new
		at: 1 put: true;
		yourself.
	mockSession rememberMaterializedObject: dictionary forOop: 9320.
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9320. dictionary. #identityDictionary } }
		session: mockSession.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: oop equals: 9320.
		7320 ].
	reader := GbsMaterializationTraversalBufferReader on: mockSession.

	dirtyBuffer
		withNativeTraversalBufferOn: mockSession
		do: [ :nativeBuffer | | usedBytes report |
			usedBytes := nativeBuffer integerAt: 5 size: 4 signed: false.
			self assert: usedBytes equals: 56.
			report := reader reportAt: nativeBuffer offset: 9.
			self assert: report oop equals: 9320.
			self assert: report classOop equals: 7320.
			self assert: report objectFormat equals: 0.
			self assert: report namedSize equals: 0.
			self assert: report indexedSize equals: 2.
			self assert: report valueOops equals: #(10 268) ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyStoreTraversalBufferProducesNativeSetReport [
	| mockSession set dirtyBuffer reader |
	mockSession := CoreMockGbsSession new.
	set := Set with: 1 with: nil.
	mockSession rememberMaterializedObject: set forOop: 9400.
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9400. set. #set } }
		session: mockSession.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: oop equals: 9400.
		7400 ].
	reader := GbsMaterializationTraversalBufferReader on: mockSession.

	dirtyBuffer
		withNativeTraversalBufferOn: mockSession
		do: [ :nativeBuffer | | usedBytes report |
			usedBytes := nativeBuffer integerAt: 5 size: 4 signed: false.
			self assert: usedBytes equals: 56.
			report := reader reportAt: nativeBuffer offset: 9.
			self assert: report oop equals: 9400.
			self assert: report classOop equals: 7400.
			self assert: report objectFormat equals: 2.
			self assert: report namedSize equals: 0.
			self assert: report indexedSize equals: 2.
			self assert: report valueOops asSet equals: #(10 20) asSet ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyStoreTraversalBufferProducesNativeBagReport [
	| mockSession bag dirtyBuffer reader |
	mockSession := CoreMockGbsSession new.
	bag := Bag new
		add: 2 withOccurrences: 2;
		yourself.
	mockSession rememberMaterializedObject: bag forOop: 9500.
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9500. bag. #bag } }
		session: mockSession.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: oop equals: 9500.
		7500 ].
	reader := GbsMaterializationTraversalBufferReader on: mockSession.

	dirtyBuffer
		withNativeTraversalBufferOn: mockSession
		do: [ :nativeBuffer | | usedBytes report |
			usedBytes := nativeBuffer integerAt: 5 size: 4 signed: false.
			self assert: usedBytes equals: 56.
			report := reader reportAt: nativeBuffer offset: 9.
			self assert: report oop equals: 9500.
			self assert: report classOop equals: 7500.
			self assert: report objectFormat equals: 2.
			self assert: report namedSize equals: 0.
			self assert: report indexedSize equals: 2.
			self assert: report valueOops equals: #(18 18) ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyStoreTraversalBufferProducesNativeNamedObjectReport [
	| mockSession point dirtyBuffer reader |
	mockSession := CoreMockGbsSession new.
	point := 3 @ 4.
	mockSession rememberMaterializedObject: point forOop: 9600.
	dirtyBuffer := GbsDirtyStoreTraversalBuffer
		entries: { { 9600. point. #namedObject } }
		session: mockSession.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: oop equals: 9600.
		7600 ].
	reader := GbsMaterializationTraversalBufferReader on: mockSession.

	dirtyBuffer
		withNativeTraversalBufferOn: mockSession
		do: [ :nativeBuffer | | usedBytes report |
			usedBytes := nativeBuffer integerAt: 5 size: 4 signed: false.
			self assert: usedBytes equals: 56.
			report := reader reportAt: nativeBuffer offset: 9.
			self assert: report oop equals: 9600.
			self assert: report classOop equals: 7600.
			self assert: report objectFormat equals: 0.
			self assert: report namedSize equals: 2.
			self assert: report indexedSize equals: 0.
			self assert: report valueOops equals: #(26 34) ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationFlushStoresArrayAndClearsDirtyState [
	| mockSession array capturedScript flushed |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old' with: nil.
	mockSession rememberMaterializedObject: array forOop: 9000.
	array at: 1 put: 'new'.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		capturedScript := script.
		268 ].

	flushed := mockSession flushDirtyMaterializedObjects.

	self assert: flushed equals: #(9000).
	self deny: (mockSession isMaterializedObjectDirty: array).
	self assert: mockSession dirtyMaterializedObjectOops isEmpty.
	self assert: (capturedScript includesSubstring: 'object size = 2').
	self assert: (capturedScript includesSubstring: 'object at: 1 put: value1_1').
	self assert: (capturedScript includesSubstring: 'value: (Object _objectForOop: 9000)').
	self assert: (capturedScript includesSubstring: 'value: ''new''')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationFlushStoresMixedCollectionsInSingleCommand [
	| mockSession dictionary association ordered set bag capturedScript flushed |
	mockSession := CoreMockGbsSession new.
	dictionary := Dictionary new.
	association := Association key: #status value: 'old'.
	ordered := OrderedCollection new.
	set := Set new.
	bag := Bag new.
	mockSession rememberMaterializedObject: dictionary forOop: 9100.
	mockSession rememberMaterializedObject: association forOop: 9200.
	mockSession rememberMaterializedObject: ordered forOop: 9300.
	mockSession rememberMaterializedObject: set forOop: 9400.
	mockSession rememberMaterializedObject: bag forOop: 9500.
	dictionary at: #customer put: 'Dirk'.
	association value: 'changed'.
	ordered add: 'line'.
	set add: 'unique'.
	bag add: 'item' withOccurrences: 2.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		capturedScript := script.
		268 ].

	flushed := mockSession flushDirtyMaterializedObjects.

	self assert: flushed asSet equals: #(9100 9200 9300 9400 9500) asSet.
	self assert: mockSession dirtyMaterializedObjectOops isEmpty.
	#(9100 9200 9300 9400 9500) do: [ :oop |
		self assert: (capturedScript includesSubstring: 'Object _objectForOop: ', oop asString) ].
	self assert: (capturedScript includesSubstring: 'object at: key1_1 put: value1_1').
	self assert: (capturedScript includesSubstring: 'object key: key2 value: value2').
	self assert: (capturedScript includesSubstring: 'object add: value3_1').
	self assert: (capturedScript includesSubstring: 'object add: value4_1').
	self assert: (capturedScript includesSubstring: 'object add: value5_1').
	self assert: (capturedScript includesSubstring: 'object add: value5_2')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationFlushTracksActiveStoreTraversalDuringRemoteStore [
	| mockSession array activeDuringFlush |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	array at: 1 put: 'new'.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		activeDuringFlush := mockSession activeStoreTraversals size.
		268 ].

	mockSession flushDirtyMaterializedObjects.

	self assert: activeDuringFlush equals: 1.
	self assert: mockSession activeStoreTraversals isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDirtyReplicationFlushUsesRemoteIdentityForNestedMaterializedObjects [
	| mockSession root nested capturedScript |
	mockSession := CoreMockGbsSession new.
	root := Array with: nil.
	nested := Array with: 'child'.
	mockSession rememberMaterializedObject: root forOop: 9000.
	mockSession rememberMaterializedObject: nested forOop: 9016.
	root at: 1 put: nested.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		capturedScript := script.
		268 ].

	mockSession flushDirtyMaterializedObjects.

	self assert: (capturedScript includesSubstring: 'object at: 1 put: value1_1').
	self assert: (capturedScript includesSubstring: 'value: (Object _objectForOop: 9016)')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionEventControllerStartsFromPolicyAndStopsOnLifecycleReset [
	| mockSession controller policy |
	mockSession := CoreMockGbsSession new.
	policy := GbsReplicationPolicy forSession: mockSession.
	policy
		asyncSignalPollingEnabled: true;
		eventPollingFrequency: 75;
		eventPriority: 5.

	controller := GbsSessionEventController forSession: mockSession.
	controller startIfEnabledFromPolicy.

	self assert: controller isPollingActive.
	self assert: controller pollingFrequency equals: 75.
	self assert: controller eventPriority equals: 5.

	mockSession resetMaterializedObjectDirtyTracking.

	self deny: (GbsSessionEventController isPollingActiveForSession: mockSession)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionEventControllerPollOnceDelegatesPositiveSignalToErrorHandler [
	| mockSession controller pollCount errorChecks |
	mockSession := CoreMockGbsSession new.
	pollCount := 0.
	errorChecks := 0.
	mockSession stubs at: #gciPollForSignal put: [
		pollCount := pollCount + 1.
		2 ].
	mockSession stubs at: #checkForError put: [
		errorChecks := errorChecks + 1.
		#handledSignal ].
	controller := GbsSessionEventController forSession: mockSession.
	controller startPolling.

	self assert: controller pollOnce equals: #handledSignal.
	self assert: pollCount equals: 1.
	self assert: errorChecks equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionEventControllerPollOnceIgnoresInactiveController [
	| mockSession controller pollCount |
	mockSession := CoreMockGbsSession new.
	pollCount := 0.
	mockSession stubs at: #gciPollForSignal put: [
		pollCount := pollCount + 1.
		2 ].
	controller := GbsSessionEventController forSession: mockSession.

	self assert: controller pollOnce isNil.
	self assert: pollCount equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionEventControllerPollOnceSignalsAlmostOutOfMemoryWhenNoErrorDetails [
	| mockSession controller |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #gciPollForSignal put: 1.
	mockSession stubs at: #checkForError put: [ nil ].
	controller := GbsSessionEventController forSession: mockSession.
	controller startPolling.

	self should: [ controller pollOnce ] raise: AlmostOutOfMemory
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionEventControllerPollOnceSignalsTransactionBacklog [
	| mockSession controller |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #gciPollForSignal put: 4.
	controller := GbsSessionEventController forSession: mockSession.
	controller startPolling.

	self should: [ controller pollOnce ] raise: TransactionBacklog
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionLifecycleManagerTracksServerMapAndFreeOops [
	| mockSession array |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	GbsSessionLifecycleManager noteFreeOop: 123456 forSession: mockSession.
	GbsSessionLifecycleManager noteFreeOop: 123464 forSession: mockSession.

	self assert: (GbsSessionLifecycleManager objectForOop: 9000 inSession: mockSession) == array.
	self assert: (GbsSessionLifecycleManager serverMapSizeForSession: mockSession) equals: 1.
	self assert: (GbsSessionLifecycleManager drainFreeOopsForSession: mockSession limit: 1) equals: #(123456).

	mockSession resetMaterializedObjectDirtyTracking.

	self assert: (GbsSessionLifecycleManager objectForOop: 9000 inSession: mockSession) isNil.
	self assert: (GbsSessionLifecycleManager drainFreeOopsForSession: mockSession limit: 10) isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionLifecycleForgetObjectQueuesNoLongerReplicatedOop [
	| mockSession array forgotten |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	array at: 1 put: 'new'.
	self assert: (mockSession isMaterializedObjectDirty: array).

	forgotten := mockSession objectSpace forgetObjectForOop: 9000.

	self assert: forgotten == array.
	self assert: (GbsSessionLifecycleManager objectForOop: 9000 inSession: mockSession) isNil.
	self deny: (mockSession isMaterializedObjectDirty: array).
	self assert: mockSession objectSpace pendingNoLongerReplicatedOopCount equals: 1.
	self assert: mockSession objectSpace drainNoLongerReplicatedOops equals: #(9000).
	self assert: mockSession objectSpace drainNoLongerReplicatedOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionLifecycleFinalizerQueuesGcedOop [
	| mockSession array finalizer |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	finalizer := mockSession objectSpace finalizerFor: array.

	self assert: finalizer notNil.
	finalizer finalize.

	self assert: (GbsSessionLifecycleManager objectForOop: 9000 inSession: mockSession) isNil.
	self assert: mockSession objectSpace pendingGcedOopCount equals: 1.
	self assert: mockSession objectSpace drainGcedOops equals: #(9000).
	self assert: mockSession objectSpace drainGcedOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionLifecycleFinalizerAfterResetDoesNotRequeueOop [
	| mockSession array finalizer |
	mockSession := CoreMockGbsSession new.
	array := Array with: 'old'.
	mockSession rememberMaterializedObject: array forOop: 9000.
	finalizer := mockSession objectSpace finalizerFor: array.

	mockSession resetMaterializedObjectDirtyTracking.
	finalizer finalize.

	self assert: mockSession objectSpace pendingGcedOopCount equals: 0.
	self assert: mockSession objectSpace drainGcedOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionLifecycleStressAcrossTransactionsAndLogoutWithMappedReplicator [
	| mockSession manager replicator first second oldProxy newManager |
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciCommit put: 1.
	mockSession stubs at: #gciAbort put: 1.
	manager := mockSession replicatorManager.
	replicator := manager mapReplicatorForClientBehavior: Array serverBehavior: Array.
	manager currentReplicationScheme
		updateInstVarLevelsForClass: Array
		serverInstVarNames: #()
		replicationSpec: #(#(#indexable_part #replicate)).

	first := Array with: 'old'.
	mockSession rememberMaterializedObject: first forOop: 9000.
	first at: 1 put: 'changed'.
	GbsSessionLifecycleManager noteNoLongerReplicatedOop: 9016 forSession: mockSession.
	GbsSessionLifecycleManager noteGcedOop: 9032 forSession: mockSession.
	self assert: (mockSession isMaterializedObjectDirty: first).
	self assert: mockSession objectSpace pendingExportSetReleaseOopCount equals: 2.

	self assert: mockSession commitTransaction.
	self assert: mockSession replicatorManager == manager.
	self assert: (manager replicatorForClientBehavior: Array ifAbsent: [ nil ]) == replicator.
	self deny: (mockSession isMaterializedObjectDirty: first).
	self assert: (GbsSessionLifecycleManager objectForOop: 9000 inSession: mockSession) isNil.
	self assert: mockSession objectSpace pendingExportSetReleaseOopCount equals: 0.

	second := Array with: 'again'.
	mockSession rememberMaterializedObject: second forOop: 9048.
	second at: 1 put: 'aborted'.
	GbsSessionLifecycleManager noteGcedOop: 9064 forSession: mockSession.
	self assert: mockSession abortTransaction.
	self assert: mockSession replicatorManager == manager.
	self deny: (mockSession isMaterializedObjectDirty: second).
	self assert: (GbsSessionLifecycleManager objectForOop: 9048 inSession: mockSession) isNil.
	self assert: mockSession objectSpace pendingExportSetReleaseOopCount equals: 0.

	oldProxy := mockSession resultFor: 9080.
	mockSession resetAfterLogout.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	newManager := mockSession replicatorManager.

	self deny: newManager == manager.
	self assert: (newManager replicatorForClientBehavior: Array ifAbsent: [ nil ]) isNil.
	self
		should: [ oldProxy ensureSessionIsUsable ]
		raise: GbsError
		withExceptionDo: [ :ex |
			self assert: (ex messageText includesSubstring: 'previous session lifecycle') ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionLifecycleSplitsExportReleaseQueuesAndSkipsImmediateOops [
	| mockSession releaseBatch report |
	mockSession := CoreMockGbsSession new.
	GbsSessionLifecycleManager noteNoLongerReplicatedOop: 9000 forSession: mockSession.
	GbsSessionLifecycleManager noteNoLongerReplicatedOop: 9016 forSession: mockSession.
	GbsSessionLifecycleManager noteNoLongerReplicatedOop: 9000 forSession: mockSession.
	GbsSessionLifecycleManager noteGcedOop: 9024 forSession: mockSession.
	GbsSessionLifecycleManager noteGcedOop: 20 forSession: mockSession.

	report := mockSession objectSpace lifecycleReport.
	self assert: (report at: #noLongerReplicatedOopQueueSize) equals: 2.
	self assert: (report at: #gcedOopQueueSize) equals: 1.
	self assert: (report at: #exportSetReleaseOopQueueSize) equals: 3.

	releaseBatch := mockSession objectSpace drainExportSetReleaseOopsLimit: 1.
	self assert: (releaseBatch at: #noLongerReplicated) equals: #(9000).
	self assert: (releaseBatch at: #gced) equals: #(9024).
	self assert: mockSession objectSpace drainNoLongerReplicatedOops equals: #(9016).
	self assert: mockSession objectSpace drainGcedOops isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionLifecycleFlushExportSetReleaseOopsReleasesOnlyGcedOops [
	| mockSession releasedFromBuffer releaseSummary |
	mockSession := CoreMockGbsSession new.
	releasedFromBuffer := nil.
	mockSession stubs at: #supportsReleaseOopsTransport put: true.
	mockSession stubs at: #apiGciReleaseOops put: [ :oopBuffer :oopCount |
		releasedFromBuffer := Array new: oopCount.
		1 to: oopCount do: [ :index |
			releasedFromBuffer
				at: index
				put: ((oopBuffer
					integerAt: 1 + ((index - 1) * 8)
					size: 8
					signed: false) asInteger) ].
		true ].
	GbsSessionLifecycleManager noteGcedOop: 9000 forSession: mockSession.
	GbsSessionLifecycleManager noteGcedOop: 9016 forSession: mockSession.
	GbsSessionLifecycleManager noteGcedOop: 9032 forSession: mockSession.
	GbsSessionLifecycleManager noteNoLongerReplicatedOop: 9024 forSession: mockSession.

	releaseSummary := mockSession objectSpace flushExportSetReleaseOopsLimit: 2.

	self assert: releasedFromBuffer equals: #(9000 9016).
	self assert: (releaseSummary at: #gcedReleased) equals: #(9000 9016).
	self assert: (releaseSummary at: #noLongerReplicatedPending) equals: #(9024).
	self assert: mockSession objectSpace pendingGcedOops equals: #(9032).
	self assert: mockSession objectSpace pendingNoLongerReplicatedOops equals: #(9024)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionLifecycleFlushGcedOopsKeepsQueueOnTransportFailure [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #supportsReleaseOopsTransport put: true.
	mockSession stubs at: #apiGciReleaseOops put: [ :oopBuffer :oopCount |
		Error signal: 'release failed' ].
	GbsSessionLifecycleManager noteGcedOop: 9000 forSession: mockSession.

	self should: [ mockSession objectSpace flushGcedOops ] raise: Error.
	self assert: mockSession objectSpace pendingGcedOops equals: #(9000)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testDefaultFetchProfileIsLegacy [
	self assert: session fetchProfile class equals: GbsLegacyMaterializationProfile
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchByReferenceUsesTypedWrapperForKnownCollectionClass [
	| mockSession result |
	mockSession := self materializationMockSession.
	GbsSessionManager initializeFastConnectors.
	mockSession fetchByReference.

	result := mockSession fetchObject: 9000.

	self assert: (result isKindOf: GbsTypedProxy).
	self assert: result clientBehaviorName equals: 'Array'.
	self assert: result oop equals: 9000
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchByReferenceUsesTypedWrapperWithoutExplicitFastConnectorBootstrap [
	| mockSession result previousRegistry |
	previousRegistry := Smalltalk globals at: #GbsFastConnectorRegistry ifAbsent: [ nil ].
	[
		Smalltalk globals removeKey: #GbsFastConnectorRegistry ifAbsent: [ ].
		mockSession := self materializationMockSession.
		mockSession fetchByReference.

		result := mockSession fetchObject: 9000.

		self assert: (result isKindOf: GbsTypedProxy).
		self assert: result clientBehaviorName equals: 'Array'
	] ensure: [
		previousRegistry
			ifNil: [ Smalltalk globals removeKey: #GbsFastConnectorRegistry ifAbsent: [ ] ]
			ifNotNil: [ Smalltalk globals at: #GbsFastConnectorRegistry put: previousRegistry ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchByReferenceFallsBackToPlainProxyForUnknownClass [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		(script includesSubstring: 'class name asString')
			ifTrue: [ 'Invoice' ]
			ifFalse: [ self fail ] ].
	mockSession fetchByReference.

	result := mockSession fetchObject: 9500.

	self assert: result class equals: GbsProxy.
	self assert: result oop equals: 9500
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchByReferenceCachesRemoteClassNameForRepeatedOop [
	| mockSession classNameFetches first second |
	mockSession := CoreMockGbsSession new.
	classNameFetches := 0.
	mockSession stubs at: #executeAndFetch put: [ :script |
		self assert: (script includesSubstring: 'class name asString').
		classNameFetches := classNameFetches + 1.
		'Invoice' ].
	mockSession fetchByReference.

	first := mockSession fetchObject: 9500.
	second := mockSession fetchObject: 9500.

	self assert: first == second.
	self assert: classNameFetches equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchByReferenceCachesRemoteClassNameForSharedClassOop [
	| mockSession classOopFetches classNameFetches first second |
	mockSession := CoreMockGbsSession new.
	classOopFetches := 0.
	classNameFetches := 0.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		self assert: (#(9500 9501) includes: oop).
		classOopFetches := classOopFetches + 1.
		9900 ].
	mockSession stubs at: #executeAndFetch put: [ :script |
		self assert: (script includesSubstring: 'classObject name asString').
		classNameFetches := classNameFetches + 1.
		'Invoice' ].
	mockSession fetchByReference.

	first := mockSession fetchObject: 9500.
	second := mockSession fetchObject: 9501.

	self assert: first class equals: GbsProxy.
	self assert: first oop equals: 9500.
	self assert: second class equals: GbsProxy.
	self assert: second oop equals: 9501.
	self assert: classOopFetches equals: 2.
	self assert: classNameFetches equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepKeepsMaterializedIdentityAcrossRootFetches [
	| mockSession first second metrics |
	mockSession := self materializationMockSession.
	mockSession fetchDeep.

	first := mockSession fetchObject: 9000.
	second := mockSession fetchObject: 9000.

	self assert: first == second.
	self assert: first second == second second.
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #materializedObjectSessionCacheHits ifAbsent: [ 0 ]) equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepReregistersDirtyTrackingFromMaterializedIdentityCache [
	| mockSession first second |
	mockSession := self materializationMockSession.
	mockSession fetchDeep.
	first := mockSession fetchObject: 9000.
	mockSession resetMaterializedObjectDirtyTracking.

	second := mockSession fetchObject: 9000.
	second at: 1 put: 'changed'.

	self assert: first == second.
	self assert: (mockSession dirtyMaterializedObjectOops asSet includes: 9000)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testMaterializedIdentityCacheClearsOnExplicitReset [
	| mockSession first second |
	mockSession := self materializationMockSession.
	mockSession fetchDeep.
	first := mockSession fetchObject: 9000.

	mockSession resetMaterializedObjectCache.
	second := mockSession fetchObject: 9000.

	self deny: first == second
]

{ #category : 'tests' }
GbsSessionCoreTest >> testMaterializedIdentityCacheClearsWhenFetchProfileChanges [
	| mockSession shallowRoot deepRoot |
	mockSession := self materializationMockSession.

	mockSession fetchShallow.
	shallowRoot := mockSession fetchObject: 9000.
	mockSession fetchDeep.
	deepRoot := mockSession fetchObject: 9000.

	self deny: shallowRoot == deepRoot.
	self assert: deepRoot second equals: #('gold' 'paid')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepMaterializesNestedArraysRecursively [
	| mockSession result nested |
	mockSession := self materializationMockSession.
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.
	nested := result at: 2.

	self assert: result class equals: Array.
	self assert: (result at: 1) equals: 'vip'.
	self assert: nested class equals: Array.
	self assert: nested equals: #('gold' 'paid')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepUsesBulkArrayOopFetch [
	| mockSession result returnOopCommands |
	mockSession := self materializationMockSession.
	returnOopCommands := 0.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		returnOopCommands := returnOopCommands + 1.
		self fail ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.

	self assert: result equals: #('vip' #('gold' 'paid')).
	self assert: returnOopCommands equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepBatchesNestedArrayFrontierSlots [
	| mockSession result metrics |
	mockSession := self materializationMockSession.
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.

	self assert: result equals: #('vip' #('gold' 'paid')).
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #slotBatchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #frontierSlotBatchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #frontierSlotBatchObjectCount ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #frontierSlotBatchOopCount ifAbsent: [ 0 ]) equals: 2.
	self assert: (metrics at: #classNameBatchCalls ifAbsent: [ 0 ]) equals: 2.
	self assert: (metrics at: #classNameBatchOopCount ifAbsent: [ 0 ]) equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepBatchesScalarStringValues [
	| mockSession result metrics |
	mockSession := self materializationMockSession.
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.

	self assert: result equals: #('vip' #('gold' 'paid')).
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #scalarStringBatchCalls ifAbsent: [ 0 ]) equals: 2.
	self assert: (metrics at: #scalarStringBatchObjectCount ifAbsent: [ 0 ]) equals: 3.
	self assert: (metrics at: #scalarStringFallbackCalls ifAbsent: [ 0 ]) equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepPreservesRepeatedNestedArrayIdentity [
	| mockSession result metrics |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'text := object asString' ]) ifTrue: [
			response := self encodedStringBatchLineForOop: 9056 value: 'shared' ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			response := String streamContents: [ :stream |
				(script includesSubstring: '9016') ifTrue: [
					stream
						nextPutAll: '9016';
						nextPut: Character tab;
						nextPutAll: 'Array';
						nextPut: Character lf ].
				(script includesSubstring: '9056') ifTrue: [
					stream
						nextPutAll: '9056';
						nextPut: Character tab;
						nextPutAll: 'String';
						nextPut: Character lf ] ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object size asString' ]) ifTrue: [
			response := '9016', Character tab asString, '1', Character tab asString, '9056', Character lf asString ].
		response ifNil: [
			(script includesSubstring: 'class name asString') ifTrue: [
				(script includesSubstring: '9000') ifTrue: [ response := 'Array' ].
				(script includesSubstring: '9016') ifTrue: [ response := 'Array' ].
				(script includesSubstring: '9056') ifTrue: [ response := 'String' ] ] ].
		response ifNil: [ self fail ].
		response ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9000 ifTrue: [ 2 ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9000.
		self assert: start equals: 1.
		self assert: count equals: 2.
		#(9016 9016) ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.

	self assert: result size equals: 2.
	self assert: result first == result second.
	self assert: result first equals: #('shared').
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #frontierSlotBatchObjectCount ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #scalarStringBatchObjectCount ifAbsent: [ 0 ]) equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassNameBatchUsesStructuredBuffer [
	| mockSession slots classNames bufferCalls metrics |
	mockSession := CoreMockGbsSession new.
	slots := OrderedCollection new.
	slots addAll: (self encodedStructuredStringSlotsFor: 'Array').
	slots addAll: (self encodedStructuredStringSlotsFor: 'String').
	bufferCalls := 0.
	mockSession stubs at: #supportsStructuredMaterializationBatchBuffers put: true.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: 'buffer := Array new: total').
		bufferCalls := bufferCalls + 1.
		9900 ].
	mockSession stubs at: #executeAndFetch put: [ :script | self fail ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9900 ifTrue: [ slots size ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9900.
		self assert: start equals: 1.
		self assert: count equals: slots size.
		slots asArray ].

	classNames := mockSession materializer remoteReader
		remoteClassNamesForOops: #(9100 9040).

	self assert: (classNames at: 9100) equals: 'Array'.
	self assert: (classNames at: 9040) equals: 'String'.
	self assert: bufferCalls equals: 1.
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #structuredBatchBufferFetchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #structuredBatchFallbacks ifAbsent: [ 0 ]) equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassNameBatchUsesStructuredBytePayload [
	| mockSession bytes classNames byteCalls metrics |
	mockSession := CoreMockGbsSession new.
	bytes := self encodedPackedStringPayloadFor: #('Array' 'String').
	byteCalls := 0.
	mockSession stubs at: #supportsStructuredMaterializationBatchBytes put: true.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: 'buffer := ByteArray new: total').
		byteCalls := byteCalls + 1.
		9910 ].
	mockSession stubs at: #executeAndFetch put: [ :script | self fail ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9910 ifTrue: [ bytes size ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchBytes put: [ :oop :start :buffer :count |
		self assert: oop equals: 9910.
		self assert: start equals: 1.
		self assert: count equals: bytes size.
		bytes ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count | self fail ].

	classNames := mockSession materializer remoteReader
		remoteClassNamesForOops: #(9100 9040).

	self assert: (classNames at: 9100) equals: 'Array'.
	self assert: (classNames at: 9040) equals: 'String'.
	self assert: byteCalls equals: 1.
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #structuredBatchByteFetchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #structuredBatchBufferFetchCalls ifAbsent: [ 0 ]) equals: 0.
	self assert: (metrics at: #structuredBatchFallbacks ifAbsent: [ 0 ]) equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassNameBatchUsesGciTraversalBuffer [
	| mockSession classNames traversalCalls metrics previousTransport hadTransport |
	mockSession := CoreMockGbsSession new.
	traversalCalls := 0.
	hadTransport := Smalltalk globals includesKey: #GbsMaterializationByteTransport.
	previousTransport := Smalltalk globals at: #GbsMaterializationByteTransport ifAbsent: [ nil ].
	[
		Smalltalk globals at: #GbsMaterializationByteTransport put: 'traversal-buffer'.
		mockSession stubs at: #supportsMaterializationTraversalBufferTransport put: true.
		mockSession stubs at: #apiGciTraverseOops put: [ :oopBuffer :oopCount :traversalBuffer :level |
			| nextOffset |
			traversalCalls := traversalCalls + 1.
			self assert: oopCount equals: 2.
			self assert: level equals: 1.
			nextOffset := self
				writePointerTraversalReportOn: traversalBuffer
				offset: 9
				oop: 9100
				classOop: 7000
				namedSize: 0
				indexedSize: 0
				firstOffset: 1
				oops: #().
			nextOffset := self
				writeByteTraversalReportOn: traversalBuffer
				offset: nextOffset
				oop: 9040
				classOop: 7001
				bytes: (ByteArray withAll: #(118 105 112))
				byteSwizzle: 0.
			self finishTraversalBuffer: traversalBuffer usedBytes: nextOffset - 9.
			1 ].
		mockSession stubs at: #apiGciFetchNameOfClass put: [ :classOop |
			classOop = 7000 ifTrue: [ 8000 ] ifFalse: [
				classOop = 7001 ifTrue: [ 8001 ] ifFalse: [ self fail ] ] ].
		mockSession stubs at: #apiGciFetchSize put: [ :oop |
			oop = 8000 ifTrue: [ 5 ] ifFalse: [
				oop = 8001 ifTrue: [ 6 ] ifFalse: [ self fail ] ] ].
		mockSession stubs at: #apiGciFetchBytes put: [ :oop :start :buffer :count |
			self assert: start equals: 1.
			oop = 8000 ifTrue: [
				self assert: count equals: 5.
				ByteArray withAll: #(65 114 114 97 121) ] ifFalse: [
				oop = 8001 ifTrue: [
					self assert: count equals: 6.
					ByteArray withAll: #(83 116 114 105 110 103) ] ifFalse: [ self fail ] ] ].
		mockSession stubs at: #executeScriptAndReturnOop put: [ :script | self fail ].
		mockSession stubs at: #executeAndFetch put: [ :script | self fail ].

		classNames := mockSession materializer remoteReader
			remoteClassNamesForOops: #(9100 9040).

		self assert: (classNames at: 9100) equals: 'Array'.
		self assert: (classNames at: 9040) equals: 'String'.
		self assert: traversalCalls equals: 1.
		metrics := mockSession materializationMetrics.
		self assert: (metrics at: #structuredTraversalBufferFetchCalls ifAbsent: [ 0 ]) equals: 1.
		self assert: (metrics at: #structuredBatchByteFetchCalls ifAbsent: [ 0 ]) equals: 0.
		self assert: (metrics at: #structuredTraversalBufferFallbacks ifAbsent: [ 0 ]) equals: 0
	] ensure: [
		hadTransport
			ifTrue: [ Smalltalk globals at: #GbsMaterializationByteTransport put: previousTransport ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationByteTransport ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testScalarStringsUseGciTraversalBuffer [
	| mockSession values metrics previousTransport hadTransport |
	mockSession := CoreMockGbsSession new.
	hadTransport := Smalltalk globals includesKey: #GbsMaterializationByteTransport.
	previousTransport := Smalltalk globals at: #GbsMaterializationByteTransport ifAbsent: [ nil ].
	[
		Smalltalk globals at: #GbsMaterializationByteTransport put: 'traversal-buffer'.
		mockSession stubs at: #supportsMaterializationTraversalBufferTransport put: true.
		mockSession stubs at: #apiGciTraverseOops put: [ :oopBuffer :oopCount :traversalBuffer :level |
			| nextOffset |
			self assert: oopCount equals: 1.
			self assert: level equals: 1.
			nextOffset := self
				writeByteTraversalReportOn: traversalBuffer
				offset: 9
				oop: 9040
				classOop: 7001
				bytes: (ByteArray withAll: #(118 105 112))
				byteSwizzle: 0.
			self finishTraversalBuffer: traversalBuffer usedBytes: nextOffset - 9.
			1 ].
		mockSession stubs at: #executeScriptAndReturnOop put: [ :script | self fail ].
		mockSession stubs at: #executeAndFetch put: [ :script | self fail ].

		values := mockSession materializer remoteReader remoteStringValuesForOops: #(9040).

		self assert: (values at: 9040) equals: 'vip'.
		metrics := mockSession materializationMetrics.
		self assert: (metrics at: #structuredTraversalBufferFetchCalls ifAbsent: [ 0 ]) equals: 1.
		self assert: (metrics at: #structuredBatchByteFetchCalls ifAbsent: [ 0 ]) equals: 0.
		self assert: (metrics at: #structuredTraversalBufferFallbacks ifAbsent: [ 0 ]) equals: 0
	] ensure: [
		hadTransport
			ifTrue: [ Smalltalk globals at: #GbsMaterializationByteTransport put: previousTransport ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationByteTransport ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testScalarByteArraysUseGciTraversalBuffer [
	| mockSession values metrics previousTransport hadTransport |
	mockSession := CoreMockGbsSession new.
	hadTransport := Smalltalk globals includesKey: #GbsMaterializationByteTransport.
	previousTransport := Smalltalk globals at: #GbsMaterializationByteTransport ifAbsent: [ nil ].
	[
		Smalltalk globals at: #GbsMaterializationByteTransport put: 'traversal-buffer'.
		mockSession stubs at: #supportsMaterializationTraversalBufferTransport put: true.
		mockSession stubs at: #apiGciTraverseOops put: [ :oopBuffer :oopCount :traversalBuffer :level |
			| nextOffset |
			self assert: oopCount equals: 1.
			self assert: level equals: 1.
			nextOffset := self
				writeByteTraversalReportOn: traversalBuffer
				offset: 9
				oop: 9400
				classOop: 7002
				bytes: (ByteArray withAll: #(1 2 3))
				byteSwizzle: 0.
			self finishTraversalBuffer: traversalBuffer usedBytes: nextOffset - 9.
			1 ].
		mockSession stubs at: #executeScriptAndReturnOop put: [ :script | self fail ].
		mockSession stubs at: #executeAndFetch put: [ :script | self fail ].

		values := mockSession materializer remoteReader remoteByteArrayValuesForOops: #(9400).

		self assert: (values at: 9400) equals: (ByteArray withAll: #(1 2 3)).
		metrics := mockSession materializationMetrics.
		self assert: (metrics at: #structuredTraversalBufferFetchCalls ifAbsent: [ 0 ]) equals: 1.
		self assert: (metrics at: #structuredBatchByteFetchCalls ifAbsent: [ 0 ]) equals: 0.
		self assert: (metrics at: #structuredTraversalBufferFallbacks ifAbsent: [ 0 ]) equals: 0
	] ensure: [
		hadTransport
			ifTrue: [ Smalltalk globals at: #GbsMaterializationByteTransport put: previousTransport ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationByteTransport ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testArraySlotsUseGciTraversalBuffer [
	| mockSession reports values metrics previousTransport hadTransport |
	mockSession := CoreMockGbsSession new.
	reports := Dictionary new.
	reports at: 9100 put: (self traversalPointerReportForOop: 9100 classOop: 7000 oops: #(101 102 103)).
	hadTransport := Smalltalk globals includesKey: #GbsMaterializationByteTransport.
	previousTransport := Smalltalk globals at: #GbsMaterializationByteTransport ifAbsent: [ nil ].
	[
		Smalltalk globals at: #GbsMaterializationByteTransport put: 'traversal-buffer'.
		mockSession stubs at: #supportsMaterializationTraversalBufferTransport put: true.
		mockSession stubs at: #materializationTraversalReportsForOops put: [ :oops :level :label |
			self assert: oops equals: #(9100).
			self assert: level equals: 1.
			self assert: label equals: 'array-element traversal batch'.
			reports ].
		mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count | self fail ].
		mockSession stubs at: #returnRemoteCommandBody put: [ :body :literalBindings :oopBindings | self fail ].

		values := mockSession materializer remoteReader remoteArrayElementOopsForOops: #(9100).

		self assert: (values at: 9100) equals: #(101 102 103).
		metrics := mockSession materializationMetrics.
		self assert: (metrics at: #frontierSlotTraversalBatchCalls ifAbsent: [ 0 ]) equals: 1.
		self assert: (metrics at: #structuredTraversalBufferFetchCalls ifAbsent: [ 0 ]) equals: 1.
		self assert: (metrics at: #structuredBatchBufferFetchCalls ifAbsent: [ 0 ]) equals: 0.
		self assert: (metrics at: #structuredTraversalBufferFallbacks ifAbsent: [ 0 ]) equals: 0
	] ensure: [
		hadTransport
			ifTrue: [ Smalltalk globals at: #GbsMaterializationByteTransport put: previousTransport ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationByteTransport ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testAssociationPairsUseGciTraversalBuffer [
	| mockSession reports values metrics previousTransport hadTransport |
	mockSession := CoreMockGbsSession new.
	reports := Dictionary new.
	reports at: 9600 put: (self
		traversalPointerReportForOop: 9600
		classOop: 7010
		namedSize: 2
		indexedSize: 0
		firstOffset: 1
		oops: #(111 222)).
	hadTransport := Smalltalk globals includesKey: #GbsMaterializationByteTransport.
	previousTransport := Smalltalk globals at: #GbsMaterializationByteTransport ifAbsent: [ nil ].
	[
		Smalltalk globals at: #GbsMaterializationByteTransport put: 'traversal-buffer'.
		mockSession stubs at: #supportsMaterializationTraversalBufferTransport put: true.
		mockSession stubs at: #materializationTraversalReportsForOops put: [ :oops :level :label |
			self assert: oops equals: #(9600).
			self assert: level equals: 1.
			self assert: label equals: 'association-pair traversal batch'.
			reports ].
		mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count | self fail ].
		mockSession stubs at: #returnRemoteCommandBody put: [ :body :literalBindings :oopBindings | self fail ].

		values := mockSession materializer remoteReader remoteAssociationOopPairsForOops: #(9600).

		self assert: (values at: 9600) equals: #(111 222).
		metrics := mockSession materializationMetrics.
		self assert: (metrics at: #associationPairTraversalBatchCalls ifAbsent: [ 0 ]) equals: 1.
		self assert: (metrics at: #structuredTraversalBufferFetchCalls ifAbsent: [ 0 ]) equals: 1.
		self assert: (metrics at: #structuredBatchBufferFetchCalls ifAbsent: [ 0 ]) equals: 0.
		self assert: (metrics at: #structuredTraversalBufferFallbacks ifAbsent: [ 0 ]) equals: 0
	] ensure: [
		hadTransport
			ifTrue: [ Smalltalk globals at: #GbsMaterializationByteTransport put: previousTransport ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationByteTransport ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalBufferReaderContinuesWithMoreTraversal [
	| mockSession reader reports moreCalls |
	mockSession := CoreMockGbsSession new.
	moreCalls := 0.
	mockSession stubs at: #apiGciTraverseOops put: [ :oopBuffer :oopCount :traversalBuffer :level |
		| nextOffset |
		self assert: oopCount equals: 2.
		self assert: level equals: 1.
		nextOffset := self
			writePointerTraversalReportOn: traversalBuffer
			offset: 9
			oop: 9100
			classOop: 7000
			namedSize: 0
			indexedSize: 1
			firstOffset: 1
			oops: #(101).
		self finishTraversalBuffer: traversalBuffer usedBytes: nextOffset - 9.
		0 ].
	mockSession stubs at: #apiGciMoreTraversal put: [ :traversalBuffer |
		| nextOffset |
		moreCalls := moreCalls + 1.
		nextOffset := self
			writePointerTraversalReportOn: traversalBuffer
			offset: 9
			oop: 9200
			classOop: 7000
			namedSize: 0
			indexedSize: 2
			firstOffset: 1
			oops: #(201 202).
		self finishTraversalBuffer: traversalBuffer usedBytes: nextOffset - 9.
		1 ].
	reader := GbsMaterializationTraversalBufferReader on: mockSession.

	reports := reader reportsForOops: #(9100 9200) level: 1 label: 'test traversal'.

	self assert: moreCalls equals: 1.
	self assert: (reports at: 9100) valueOops equals: #(101).
	self assert: (reports at: 9200) valueOops equals: #(201 202)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalBufferReaderRejectsIncompleteReportBoundary [
	| mockSession reader buffer nextOffset |
	mockSession := CoreMockGbsSession new.
	reader := GbsMaterializationTraversalBufferReader on: mockSession.
	buffer := ExternalAddress allocate: 256.
	[
		nextOffset := self
			writePointerTraversalReportOn: buffer
			offset: 9
			oop: 9100
			classOop: 7000
			namedSize: 0
			indexedSize: 2
			firstOffset: 1
			oops: #(101 102).
		self finishTraversalBuffer: buffer usedBytes: (nextOffset - 9) - 1.
		self
			should: [ reader parseReportsFromBuffer: buffer into: Dictionary new label: 'malformed traversal' ]
			raise: GbsMaterializationTraversalError
	] ensure: [ buffer free ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalBufferReaderParsesMixedByteAndOopReports [
	| mockSession reader buffer nextOffset reports |
	mockSession := CoreMockGbsSession new.
	reader := GbsMaterializationTraversalBufferReader on: mockSession.
	buffer := ExternalAddress allocate: 512.
	[
		nextOffset := self
			writePointerTraversalReportOn: buffer
			offset: 9
			oop: 9100
			classOop: 7000
			namedSize: 0
			indexedSize: 2
			firstOffset: 1
			oops: #(101 102).
		nextOffset := self
			writeByteTraversalReportOn: buffer
			offset: nextOffset
			oop: 9040
			classOop: 7001
			bytes: (ByteArray withAll: #(118 105 112))
			byteSwizzle: 0.
		self finishTraversalBuffer: buffer usedBytes: nextOffset - 9.

		reports := reader parseReportsFromBuffer: buffer into: Dictionary new label: 'mixed traversal'.

		self assert: (reports at: 9100) valueOops equals: #(101 102).
		self assert: (reports at: 9040) valueBytes equals: (ByteArray withAll: #(118 105 112)).
		self assert: (reports at: 9040) byteSwizzle equals: 0
	] ensure: [ buffer free ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalBufferReaderAppliesBatchByteLimit [
	| mockSession reader buffer nextOffset previous hadPrevious raised |
	mockSession := CoreMockGbsSession new.
	reader := GbsMaterializationTraversalBufferReader on: mockSession.
	buffer := ExternalAddress allocate: 512.
	hadPrevious := Smalltalk globals includesKey: #GbsMaterializationMaxBatchBytes.
	previous := Smalltalk globals at: #GbsMaterializationMaxBatchBytes ifAbsent: [ nil ].
	raised := false.
	[
		Smalltalk globals at: #GbsMaterializationMaxBatchBytes put: 16.
		nextOffset := self
			writeByteTraversalReportOn: buffer
			offset: 9
			oop: 9040
			classOop: 7001
			bytes: (ByteArray new: 64 withAll: 65)
			byteSwizzle: 0.
		self finishTraversalBuffer: buffer usedBytes: nextOffset - 9.
		[ reader parseReportsFromBuffer: buffer into: Dictionary new label: 'large traversal' ]
			on: GbsMaterializationLimitError
			do: [ :ex |
				raised := true.
				self assert: ex limitKind equals: #batchBytes ].
		self assert: raised
	] ensure: [
		buffer free.
		hadPrevious
			ifTrue: [ Smalltalk globals at: #GbsMaterializationMaxBatchBytes put: previous ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationMaxBatchBytes ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRemoteCollectionAsArrayOopIsCached [
	| mockSession reader calls first second |
	mockSession := CoreMockGbsSession new.
	reader := mockSession materializer remoteReader.
	calls := 0.
	mockSession stubs at: #returnRemoteCommandBody put: [ :body :literalBindings :oopBindings |
		calls := calls + 1.
		self assert: (body includesSubstring: 'object asArray').
		self assert: (oopBindings at: 'object') equals: 9000.
		9100 ].

	first := reader remoteCollectionAsArrayOop: 9000.
	second := reader remoteCollectionAsArrayOop: 9000.

	self assert: first equals: 9100.
	self assert: second equals: 9100.
	self assert: calls equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRemoteCollectionElementOopsAvoidsAsArrayConversion [
	| mockSession reader fetched metrics |
	mockSession := CoreMockGbsSession new.
	reader := mockSession materializer remoteReader.
	mockSession stubs at: #returnRemoteCommandBody put: [ :body :literalBindings :oopBindings | self fail ].
	mockSession stubs at: #executeAndFetch put: [ :script |
		self deny: (script includesSubstring: 'object asArray').
		self assert: (script includesSubstring: 'object do: [ :each | count := count + 1 ]').
		'9100', Character tab asString, '2', Character tab asString,
			'9040', Character tab asString, '9056', Character lf asString ].

	fetched := reader remoteCollectionElementOopsForOops: #(9100).

	self assert: (fetched at: 9100) equals: #(9040 9056).
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #collectionElementBatchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #collectionArrayBatchCalls ifAbsent: [ 0 ]) equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalBufferSizeIsAlignedAndMinimumBounded [
	| mockSession reader previous hadPrevious |
	mockSession := CoreMockGbsSession new.
	reader := GbsMaterializationTraversalBufferReader on: mockSession.
	hadPrevious := Smalltalk globals includesKey: #GbsMaterializationTraversalBufferBytes.
	previous := Smalltalk globals at: #GbsMaterializationTraversalBufferBytes ifAbsent: [ nil ].
	[
		Smalltalk globals at: #GbsMaterializationTraversalBufferBytes put: 7.
		self assert: reader traversalBufferBytes equals: 2048.
		Smalltalk globals at: #GbsMaterializationTraversalBufferBytes put: 2050.
		self assert: reader traversalBufferBytes equals: 2056
	] ensure: [
		hadPrevious
			ifTrue: [ Smalltalk globals at: #GbsMaterializationTraversalBufferBytes put: previous ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationTraversalBufferBytes ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalStringReportDecodesFourByteSwizzle [
	| mockSession report result |
	mockSession := CoreMockGbsSession new.
	report := self
		traversalByteReportForOop: 9040
		classOop: 7001
		bytes: (ByteArray withAll: #(0 246 1 0)).
	report byteSwizzle: 2.

	result := mockSession materializer remoteReader stringFromTraversalReport: report.

	self assert: result size equals: 1.
	self assert: result first equals: (Character codePoint: 16r1F600)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalStringReportDecodesTwoByteSwizzle [
	| mockSession report result |
	mockSession := CoreMockGbsSession new.
	report := self
		traversalByteReportForOop: 9040
		classOop: 7001
		bytes: (ByteArray withAll: #(65 0 218 3)).
	report byteSwizzle: 1.

	result := mockSession materializer remoteReader stringFromTraversalReport: report.

	self assert: result size equals: 2.
	self assert: result first equals: $A.
	self assert: result second equals: (Character codePoint: 16r03DA)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testTraversalStringReportRejectsUnsupportedEightByteSwizzle [
	| mockSession report |
	mockSession := CoreMockGbsSession new.
	report := self traversalByteReportForOop: 9040 classOop: 7001 bytes: (ByteArray withAll: #(65 0 0 0 0 0 0 0)).
	report byteSwizzle: 3.

	self
		should: [ mockSession materializer remoteReader stringFromTraversalReport: report ]
		raise: GbsMaterializationTraversalError
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepPreservesCyclicArrayIdentity [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			(script includesSubstring: '9040') ifTrue: [
				response := '9040', Character tab asString, 'String', Character lf asString ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'text := object asString' ]) ifTrue: [
			response := self encodedStringBatchLineForOop: 9040 value: 'self' ].
		response ifNil: [
			(script includesSubstring: 'class name asString') ifTrue: [
				(script includesSubstring: '9000') ifTrue: [ response := 'Array' ].
				(script includesSubstring: '9040') ifTrue: [ response := 'String' ] ] ].
		response ifNil: [ self fail ].
		response ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9000 ifTrue: [ 2 ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9000.
		self assert: start equals: 1.
		self assert: count equals: 2.
		#(9000 9040) ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.

	self assert: result first == result.
	self assert: result second equals: 'self'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepPreservesCyclicDictionaryIdentity [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			(script includesSubstring: '9040') ifTrue: [
				response := '9040', Character tab asString, 'String', Character lf asString ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'text := object asString' ]) ifTrue: [
			response := self encodedStringBatchLineForOop: 9040 value: 'self' ].
		response ifNil: [
			(script includesSubstring: 'class name asString') ifTrue: [
				(script includesSubstring: '9100') ifTrue: [ response := 'Dictionary' ].
				(script includesSubstring: '9040') ifTrue: [ response := 'String' ] ] ].
		response ifNil: [ self fail ].
		response ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		(script includesSubstring: 'pairs := Array new: object size * 2')
			ifTrue: [ 9200 ]
			ifFalse: [ Error signal: 'No return-OOP stub for this script.' ] ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9200 ifTrue: [ 2 ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9200.
		self assert: start equals: 1.
		self assert: count equals: 2.
		#(9040 9100) ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9100.

	self assert: (result at: 'self') == result
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepPreservesCyclicSetIdentity [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			(script includesSubstring: '9040') ifTrue: [
				response := '9040', Character tab asString, 'String', Character lf asString ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'text := object asString' ]) ifTrue: [
			response := self encodedStringBatchLineForOop: 9040 value: 'marker' ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object do: [ :each | count := count + 1 ]' ]) ifTrue: [
			(script includesSubstring: '9300') ifTrue: [
				response := '9300', Character tab asString, '2', Character tab asString,
					'9300', Character tab asString, '9040', Character lf asString ] ].
		response ifNil: [
			(script includesSubstring: 'class name asString') ifTrue: [
				(script includesSubstring: '9300') ifTrue: [ response := 'Set' ].
				(script includesSubstring: '9040') ifTrue: [ response := 'String' ] ] ].
		response ifNil: [ self fail ].
		response ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9300.

	self assert: (result anySatisfy: [ :each | each == result ]).
	self assert: (result includes: 'marker')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepPreservesCyclicAssociationIdentity [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #supportsStructuredMaterializationBatchBuffers put: true.
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			(script includesSubstring: '9040') ifTrue: [
				response := '9040', Character tab asString, 'String', Character lf asString ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'text := object asString' ]) ifTrue: [
			response := self encodedStringBatchLineForOop: 9040 value: 'self' ].
		response ifNil: [
			(script includesSubstring: 'class name asString') ifTrue: [
				(script includesSubstring: '9500') ifTrue: [ response := 'Association' ].
				(script includesSubstring: '9040') ifTrue: [ response := 'String' ] ] ].
		response ifNil: [ self fail ].
		response ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		((script includesSubstring: 'buffer := Array new: oops size * 2')
			or: [ script includesSubstring: 'Array with: assoc key with: assoc value' ])
			ifTrue: [ 9510 ]
			ifFalse: [ Error signal: 'No return-OOP stub for this script.' ] ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9510 ifTrue: [ 2 ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9510.
		self assert: start equals: 1.
		self assert: count equals: 2.
		#(9040 9500) ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9500.

	self assert: result key equals: 'self'.
	self assert: result value == result
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepPreservesRepeatedAssociationIdentityInMixedGraph [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			response := String streamContents: [ :stream |
				#(
					(9500 'Association')
					(9040 'String')
					(9056 'String')) do: [ :entry |
					(script includesSubstring: entry first asString) ifTrue: [
						stream
							nextPutAll: entry first asString;
							nextPut: Character tab;
							nextPutAll: entry second;
							nextPut: Character lf ] ] ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'text := object asString' ]) ifTrue: [
			response := String streamContents: [ :stream |
				stream
					nextPutAll: (self encodedStringBatchLineForOop: 9040 value: 'key');
					nextPutAll: (self encodedStringBatchLineForOop: 9056 value: 'value') ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'assoc := Object _objectForOop' ]) ifTrue: [
			response := '9500', Character tab asString, '9040', Character tab asString, '9056', Character lf asString ].
		response ifNil: [
			(script includesSubstring: 'class name asString') ifTrue: [
				(script includesSubstring: '9000') ifTrue: [ response := 'Array' ].
				(script includesSubstring: '9500') ifTrue: [ response := 'Association' ].
				(script includesSubstring: '9040') ifTrue: [ response := 'String' ].
				(script includesSubstring: '9056') ifTrue: [ response := 'String' ] ] ].
		response ifNil: [ self fail ].
		response ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9000 ifTrue: [ 2 ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9000.
		self assert: start equals: 1.
		self assert: count equals: 2.
		#(9500 9500) ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.

	self assert: result first == result second.
	self assert: result first key equals: 'key'.
	self assert: result second value equals: 'value'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepPreservesMutualDictionaryAssociationCycle [
	| mockSession result association |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		Error signal: 'Force text fallback for dictionary pair extraction.' ].
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			response := String streamContents: [ :stream |
				#(
					(9500 'Association')
					(9040 'String')
					(9048 'String')) do: [ :entry |
					(script includesSubstring: entry first asString) ifTrue: [
						stream
							nextPutAll: entry first asString;
							nextPut: Character tab;
							nextPutAll: entry second;
							nextPut: Character lf ] ] ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'text := object asString' ]) ifTrue: [
			response := String streamContents: [ :stream |
				stream
					nextPutAll: (self encodedStringBatchLineForOop: 9040 value: 'assoc');
					nextPutAll: (self encodedStringBatchLineForOop: 9048 value: 'dict') ] ].
		((script includesSubstring: 'object associations do:')
			and: [ (script includesSubstring: 'oops do:') not ]) ifTrue: [
			response := '9040', Character tab asString, '9500', Character lf asString ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object associations do:' ]) ifTrue: [
			response := '9100', Character tab asString, '1', Character tab asString,
				'9040', Character tab asString, '9500', Character lf asString ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'assoc := Object _objectForOop' ]) ifTrue: [
			response := '9500', Character tab asString, '9048', Character tab asString, '9100', Character lf asString ].
		response ifNil: [
			(script includesSubstring: 'class name asString') ifTrue: [
				(script includesSubstring: '9100') ifTrue: [ response := 'Dictionary' ].
				(script includesSubstring: '9500') ifTrue: [ response := 'Association' ].
				(script includesSubstring: '9040') ifTrue: [ response := 'String' ].
				(script includesSubstring: '9048') ifTrue: [ response := 'String' ] ] ].
		response ifNil: [ self fail ].
		response ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9100.
	association := result at: 'assoc'.

	self assert: association key equals: 'dict'.
	self assert: association value == result
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepBatchesScalarByteArraysThroughBytePayload [
	| mockSession result bytes metrics |
	mockSession := CoreMockGbsSession new.
	bytes := self encodedPackedByteArrayPayloadFor: { ByteArray withAll: #(1 2 3) }.
	mockSession stubs at: #supportsStructuredMaterializationBatchBytes put: true.
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			response := '9400', Character tab asString, 'ByteArray', Character lf asString ].
		response ifNil: [
			(script includesSubstring: 'class name asString') ifTrue: [
				(script includesSubstring: '9000') ifTrue: [ response := 'Array' ].
				(script includesSubstring: '9400') ifTrue: [ response := 'ByteArray' ] ] ].
		response ifNil: [ self fail ].
		response ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		((script includesSubstring: 'buffer := ByteArray new: total')
			and: [ script includesSubstring: 'object size' ])
			ifTrue: [ 9410 ]
			ifFalse: [ Error signal: 'No return-OOP stub for this script.' ] ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9000 ifTrue: [ 1 ] ifFalse: [
			oop = 9410 ifTrue: [ bytes size ] ifFalse: [ self fail ] ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9000.
		self assert: start equals: 1.
		self assert: count equals: 1.
		#(9400) ].
	mockSession stubs at: #apiGciFetchBytes put: [ :oop :start :buffer :count |
		self assert: oop equals: 9410.
		self assert: start equals: 1.
		self assert: count equals: bytes size.
		bytes ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.

	self assert: result first equals: (ByteArray withAll: #(1 2 3)).
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #structuredBatchByteFetchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #scalarByteArrayBatchCalls ifAbsent: [ 0 ]) equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testStructuredBatchBytesCanUseTraversalTransportHook [
	| mockSession previousTransport hadTransport bytes result metrics bindings |
	mockSession := CoreMockGbsSession new.
	bytes := self encodedPackedStringPayloadFor: #('String').
	hadTransport := Smalltalk globals includesKey: #GbsMaterializationByteTransport.
	previousTransport := Smalltalk globals at: #GbsMaterializationByteTransport ifAbsent: [ nil ].
	[
		Smalltalk globals at: #GbsMaterializationByteTransport put: 'traversal'.
		mockSession stubs at: #supportsStructuredMaterializationBatchBytes put: true.
		mockSession stubs at: #supportsMaterializationTraversalByteTransport put: true.
		mockSession stubs at: #materializationTraversalBytesForBody put: [ :body :literalBindings :label |
			bindings := literalBindings.
			bytes ].

		result := mockSession materializer remoteReader
			structuredBatchBytesForBody: 'ByteArray new'
			oopCollection: #(9040)
			label: 'test traversal byte batch'.

		self assert: result equals: bytes.
		self assert: (bindings at: 'oops') equals: #(9040).
		metrics := mockSession materializationMetrics.
		self assert: (metrics at: #structuredTraversalByteFetchCalls ifAbsent: [ 0 ]) equals: 1.
		self assert: (metrics at: #structuredBatchByteFetchCalls ifAbsent: [ 0 ]) equals: 0
	] ensure: [
		hadTransport
			ifTrue: [ Smalltalk globals at: #GbsMaterializationByteTransport put: previousTransport ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationByteTransport ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testStructuredBatchBytesTracksTraversalTransportFallback [
	| mockSession previousTransport hadTransport bytes result metrics |
	mockSession := CoreMockGbsSession new.
	bytes := self encodedPackedStringPayloadFor: #('String').
	hadTransport := Smalltalk globals includesKey: #GbsMaterializationByteTransport.
	previousTransport := Smalltalk globals at: #GbsMaterializationByteTransport ifAbsent: [ nil ].
	[
		Smalltalk globals at: #GbsMaterializationByteTransport put: 'traversal'.
		mockSession stubs at: #supportsStructuredMaterializationBatchBytes put: true.
		mockSession stubs at: #supportsMaterializationTraversalByteTransport put: false.
		mockSession stubs at: #returnRemoteCommandBody put: [ :body :literalBindings :oopBindings | 9400 ].
		mockSession stubs at: #apiGciFetchSize put: [ :oop |
			oop = 9400 ifTrue: [ bytes size ] ifFalse: [ self fail ] ].
		mockSession stubs at: #apiGciFetchBytes put: [ :oop :start :buffer :count |
			self assert: oop equals: 9400.
			self assert: start equals: 1.
			self assert: count equals: bytes size.
			bytes ].

		result := mockSession materializer remoteReader
			structuredBatchBytesForBody: 'ByteArray new'
			oopCollection: #(9040)
			label: 'test traversal fallback byte batch'.

		self assert: result equals: bytes.
		metrics := mockSession materializationMetrics.
		self assert: (metrics at: #structuredTraversalByteFallbacks ifAbsent: [ 0 ]) equals: 1.
		self assert: (metrics at: #structuredBatchByteFetchCalls ifAbsent: [ 0 ]) equals: 1
	] ensure: [
		hadTransport
			ifTrue: [ Smalltalk globals at: #GbsMaterializationByteTransport put: previousTransport ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationByteTransport ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testMaterializationMaxObjectsRaisesClearError [
	| mockSession previous hadPrevious raised |
	mockSession := self materializationMockSession.
	hadPrevious := Smalltalk globals includesKey: #GbsMaterializationMaxObjects.
	previous := Smalltalk globals at: #GbsMaterializationMaxObjects ifAbsent: [ nil ].
	raised := false.
	[
		Smalltalk globals at: #GbsMaterializationMaxObjects put: 1.
		mockSession fetchDeep.
		[ mockSession fetchObject: 9000 ]
			on: GbsMaterializationLimitError
			do: [ :ex |
				raised := true.
				self assert: ex limitKind equals: #objects ].
		self assert: raised
	] ensure: [
		hadPrevious
			ifTrue: [ Smalltalk globals at: #GbsMaterializationMaxObjects put: previous ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationMaxObjects ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testMaterializationMaxDepthRaisesClearError [
	| mockSession previous hadPrevious raised |
	mockSession := self materializationMockSession.
	hadPrevious := Smalltalk globals includesKey: #GbsMaterializationMaxDepth.
	previous := Smalltalk globals at: #GbsMaterializationMaxDepth ifAbsent: [ nil ].
	raised := false.
	[
		Smalltalk globals at: #GbsMaterializationMaxDepth put: 1.
		mockSession fetchDeep.
		[ mockSession fetchObject: 9000 ]
			on: GbsMaterializationLimitError
			do: [ :ex |
				raised := true.
				self assert: ex limitKind equals: #depth ].
		self assert: raised
	] ensure: [
		hadPrevious
			ifTrue: [ Smalltalk globals at: #GbsMaterializationMaxDepth put: previous ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationMaxDepth ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testMaterializationMaxBatchBytesRaisesClearError [
	| mockSession previous hadPrevious raised |
	mockSession := CoreMockGbsSession new.
	hadPrevious := Smalltalk globals includesKey: #GbsMaterializationMaxBatchBytes.
	previous := Smalltalk globals at: #GbsMaterializationMaxBatchBytes ifAbsent: [ nil ].
	raised := false.
	[
		Smalltalk globals at: #GbsMaterializationMaxBatchBytes put: 1.
		[ mockSession materializer remoteReader
			parseClassNameLines: '9000', Character tab asString, 'Array', Character lf asString ]
			on: GbsMaterializationLimitError
			do: [ :ex |
				raised := true.
				self assert: ex limitKind equals: #batchBytes ].
		self assert: raised
	] ensure: [
		hadPrevious
			ifTrue: [ Smalltalk globals at: #GbsMaterializationMaxBatchBytes put: previous ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationMaxBatchBytes ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testMaterializationMaxFrontierOopsRaisesTypedError [
	| mockSession previous hadPrevious raised |
	mockSession := self materializationMockSession.
	hadPrevious := Smalltalk globals includesKey: #GbsMaterializationMaxFrontierOops.
	previous := Smalltalk globals at: #GbsMaterializationMaxFrontierOops ifAbsent: [ nil ].
	raised := false.
	[
		Smalltalk globals at: #GbsMaterializationMaxFrontierOops put: 1.
		mockSession fetchDeep.
		[ mockSession fetchObject: 9000 ]
			on: GbsMaterializationLimitError
			do: [ :ex |
				raised := true.
				self assert: ex limitKind equals: #frontierOops.
				self assert: ex observedValue equals: 2 ].
		self assert: raised
	] ensure: [
		hadPrevious
			ifTrue: [ Smalltalk globals at: #GbsMaterializationMaxFrontierOops put: previous ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationMaxFrontierOops ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepBatchesNestedNonArrayCollections [
	| mockSession result ordered dictionary association metrics |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'text := object asString' ]) ifTrue: [
			response := String streamContents: [ :stream |
				stream
					nextPutAll: (self encodedStringBatchLineForOop: 9040 value: 'vip');
					nextPutAll: (self encodedStringBatchLineForOop: 9056 value: 'gold') ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			response := String streamContents: [ :stream |
				#(
					(9100 'OrderedCollection')
					(9200 'Dictionary')
					(9300 'Association')
					(9040 'String')
					(9056 'String')) do: [ :entry |
					(script includesSubstring: entry first asString) ifTrue: [
						stream
							nextPutAll: entry first asString;
							nextPut: Character tab;
							nextPutAll: entry second;
							nextPut: Character lf ] ] ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object do: [ :each | count := count + 1 ]' ]) ifTrue: [
			response := '9100', Character tab asString, '2', Character tab asString, '9040', Character tab asString, '9056', Character lf asString ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object associations do:' ]) ifTrue: [
			response := '9200', Character tab asString, '1', Character tab asString, '9040', Character tab asString, '9056', Character lf asString ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'assoc := Object _objectForOop' ]) ifTrue: [
			response := '9300', Character tab asString, '9040', Character tab asString, '9056', Character lf asString ].
		response ifNil: [
			(script includesSubstring: 'class name asString') ifTrue: [
				(script includesSubstring: '9000') ifTrue: [ response := 'Array' ] ] ].
		response ifNil: [ self fail ].
		response ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9000 ifTrue: [ 3 ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9000.
		self assert: start equals: 1.
		self assert: count equals: 3.
		#(9100 9200 9300) ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.
	ordered := result first.
	dictionary := result second.
	association := result third.

	self assert: ordered asArray equals: #('vip' 'gold').
	self assert: (dictionary at: 'vip') equals: 'gold'.
	self assert: association key equals: 'vip'.
	self assert: association value equals: 'gold'.
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #collectionElementBatchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #collectionArrayBatchCalls ifAbsent: [ 0 ]) equals: 0.
	self assert: (metrics at: #dictionaryPairBatchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #associationPairBatchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #scalarStringBatchObjectCount ifAbsent: [ 0 ]) equals: 2
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepBatchesScalarByteArrays [
	| mockSession result metrics |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: '(object at: index) asInteger asString' ]) ifTrue: [
			response := '9400', Character tab asString, '3', Character tab asString, '1', Character tab asString, '2', Character tab asString, '3', Character lf asString ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			response := '9400', Character tab asString, 'ByteArray', Character lf asString ].
		response ifNil: [
			(script includesSubstring: 'class name asString') ifTrue: [
				(script includesSubstring: '9000') ifTrue: [ response := 'Array' ] ] ].
		response ifNil: [ self fail ].
		response ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9000 ifTrue: [ 1 ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9000.
		self assert: start equals: 1.
		self assert: count equals: 1.
		#(9400) ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9000.

	self assert: result first equals: (ByteArray withAll: #(1 2 3)).
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #scalarByteArrayBatchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #scalarByteArrayBatchObjectCount ifAbsent: [ 0 ]) equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRemoteArrayElementOopsAreCachedPerSession [
	| mockSession first second sizeFetches oopFetches |
	mockSession := CoreMockGbsSession new.
	sizeFetches := 0.
	oopFetches := 0.
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		self assert: oop equals: 9000.
		sizeFetches := sizeFetches + 1.
		2 ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9000.
		self assert: start equals: 1.
		self assert: count equals: 2.
		oopFetches := oopFetches + 1.
		#(9040 9016) ].

	first := mockSession materializer remoteReader remoteArrayElementOopsForOop: 9000.
	second := mockSession materializer remoteReader remoteArrayElementOopsForOop: 9000.

	self assert: first equals: #(9040 9016).
	self assert: second equals: first.
	self assert: sizeFetches equals: 1.
	self assert: oopFetches equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchDeepDictionaryUsesFlattenedOopPairFetch [
	| mockSession result pairArrayCommands pairStringScripts |
	mockSession := CoreMockGbsSession new.
	pairArrayCommands := 0.
	pairStringScripts := 0.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		oop = 9100 ifTrue: [ 9910 ] ifFalse: [
			(#(9040 9056 9064) includes: oop) ifTrue: [ 9901 ] ifFalse: [ self fail ] ] ].
	mockSession stubs at: #executeAndFetch put: [ :script | | result |
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'text := object asString' ]) ifTrue: [
			result := String streamContents: [ :stream |
				#(
					(9040 'vip')
					(9056 'gold')
					(9064 'paid')) do: [ :entry |
					(script includesSubstring: entry first asString) ifTrue: [
						stream
							nextPutAll: (self encodedStringBatchLineForOop: entry first value: entry second) ] ] ] ].
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			result := String streamContents: [ :stream |
				#(9040 9056 9064) do: [ :oop |
					(script includesSubstring: oop asString) ifTrue: [
						stream
							nextPutAll: oop asString;
							nextPut: Character tab;
							nextPutAll: 'String';
							nextPut: Character lf ] ] ] ].
		((script includesSubstring: 'Character tab')
			and: [ (script includesSubstring: 'object class name asString') not
			and: [ (script includesSubstring: 'text := object asString') not ] ]) ifTrue: [
			pairStringScripts := pairStringScripts + 1.
			self fail ].
		result ifNil: [
		(script includesSubstring: 'classObject name asString') ifTrue: [
			(script includesSubstring: '9910') ifTrue: [ result := 'Dictionary' ].
			(script includesSubstring: '9901') ifTrue: [ result := 'String' ] ] ].
		result ifNil: [
		((script includesSubstring: ') asString') or: [ script includesSubstring: 'object asString' ]) ifTrue: [
			(script includesSubstring: '9040') ifTrue: [ result := 'vip' ].
			(script includesSubstring: '9056') ifTrue: [ result := 'gold' ].
			(script includesSubstring: '9064') ifTrue: [ result := 'paid' ] ] ].
		result ifNil: [ self fail ].
		result ].
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: 'pairs := Array new: object size * 2').
		pairArrayCommands := pairArrayCommands + 1.
		9200 ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9200 ifTrue: [ 4 ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9200.
		self assert: start equals: 1.
		self assert: count equals: 4.
		#(9040 9056 9064 9040) ].
	mockSession fetchDeep.

	result := mockSession fetchObject: 9100.

	self assert: (result at: 'vip') equals: 'gold'.
	self assert: (result at: 'paid') equals: 'vip'.
	self assert: pairArrayCommands equals: 1.
	self assert: pairStringScripts equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRemoteDictionaryAssociationPairsAreCachedPerSession [
	| mockSession first second pairArrayCommands oopFetches |
	mockSession := CoreMockGbsSession new.
	pairArrayCommands := 0.
	oopFetches := 0.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: 'pairs := Array new: object size * 2').
		pairArrayCommands := pairArrayCommands + 1.
		9200 ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		self assert: oop equals: 9200.
		4 ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9200.
		self assert: start equals: 1.
		self assert: count equals: 4.
		oopFetches := oopFetches + 1.
		#(9040 9056 9064 9040) ].

	first := mockSession materializer remoteReader remoteDictionaryAssociationOopPairsForOop: 9100.
	second := mockSession materializer remoteReader remoteDictionaryAssociationOopPairsForOop: 9100.

	self assert: first equals: #((9040 9056) (9064 9040)).
	self assert: second equals: first.
	self assert: pairArrayCommands equals: 1.
	self assert: oopFetches equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchLegacyMaterializesArraysRecursively [
	| mockSession result |
	mockSession := self materializationMockSession.

	result := mockSession fetchObject: 9000.

	self assert: result equals: #('vip' #('gold' 'paid'))
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchShallowLeavesNestedArrayAsProxy [
	| mockSession result nested |
	mockSession := self materializationMockSession.
	GbsSessionManager initializeFastConnectors.
	mockSession fetchShallow.

	result := mockSession fetchObject: 9000.
	nested := result at: 2.

	self assert: result class equals: Array.
	self assert: (result at: 1) equals: 'vip'.
	self assert: (nested isKindOf: GbsTypedProxy).
	self assert: nested oop equals: 9016
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchShallowBatchesNestedProxyClassNames [
	| mockSession result classOopFetches bulkClassNameFetches metrics |
	mockSession := CoreMockGbsSession new.
	classOopFetches := OrderedCollection new.
	bulkClassNameFetches := 0.
	GbsSessionManager initializeFastConnectors.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		classOopFetches add: oop.
		oop = 9000
			ifTrue: [ 5000 ]
			ifFalse: [ self fail ] ].
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		(script includesSubstring: 'classObject name asString') ifTrue: [
			self assert: (script includesSubstring: '5000').
			response := 'Array' ].
		(script includesSubstring: 'objectNamed: clsName asSymbol') ifTrue: [
			response := { 5000. 'Array'. 'Object'. nil. nil. 1. 1 } ].
		(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
			response := #() ].
		(script includesSubstring: 'oops do:') ifTrue: [
			bulkClassNameFetches := bulkClassNameFetches + 1.
			self assert: (script includesSubstring: '9100').
			self assert: (script includesSubstring: '9112').
			self assert: (script includesSubstring: '9120').
			response := String streamContents: [ :stream |
				#(9100 9112 9120) do: [ :oop |
					stream
						nextPutAll: oop asString;
						nextPut: Character tab;
						nextPutAll: 'Array';
						nextPut: Character lf ] ] ].
		response ifNil: [ self fail ].
		response ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9000 ifTrue: [ 3 ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9000.
		self assert: start equals: 1.
		self assert: count equals: 3.
		#(9100 9112 9120) ].
	mockSession fetchShallow.

	result := mockSession fetchObject: 9000.

	self assert: result size equals: 3.
	self assert: (result allSatisfy: [ :each | each isKindOf: GbsTypedProxy ]).
	self assert: (result collect: [ :each | each oop ]) equals: #(9100 9112 9120).
	self assert: classOopFetches asArray equals: #(9000).
	self assert: bulkClassNameFetches equals: 1.
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #rootFetches ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #slotBatchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #classNameBatchCalls ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #wrapperLookupCalls ifAbsent: [ 0 ]) equals: 0.
	self assert: (metrics at: #wrapperLookupMisses ifAbsent: [ 0 ]) equals: 0.
	self assert: (metrics at: #wrapperFastConnectorHits ifAbsent: [ 0 ]) equals: 1.
	self assert: ((metrics at: #wrapperLookupTypedClassCounts) at: 'Array') equals: 1.
	self assert: (metrics at: #proxyCreations ifAbsent: [ 0 ]) equals: 3
]

{ #category : 'tests' }
GbsSessionCoreTest >> testMaterializationFastConnectorWrapperAvoidsRemoteMetadataLookup [
	| mockSession proxy metadataFetches metrics |
	GbsSessionManager clearAllTypedWrapperClasses.
	GbsSessionManager initializeFastConnectors.
	mockSession := CoreMockGbsSession new.
	metadataFetches := 0.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		metadataFetches := metadataFetches + 1.
		self fail ].

	proxy := mockSession proxyForOop: 9100 serverClassName: 'Array'.

	self assert: (proxy isKindOf: GbsTypedProxy).
	self assert: proxy clientBehaviorName equals: 'Array'.
	self assert: proxy serverBehaviorName equals: 'Array'.
	self assert: metadataFetches equals: 0.
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #wrapperFastConnectorHits ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #wrapperLookupCalls ifAbsent: [ 0 ]) equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchShallowClassNameBatchSizeIsConfigurable [
	| mockSession result bulkClassNameFetches previousBatchSize hadBatchSize metrics |
	mockSession := CoreMockGbsSession new.
	bulkClassNameFetches := 0.
	hadBatchSize := Smalltalk globals includesKey: #GbsMaterializationBatchSize.
	previousBatchSize := Smalltalk globals at: #GbsMaterializationBatchSize ifAbsent: [ nil ].
	[
		Smalltalk globals at: #GbsMaterializationBatchSize put: 2.
		GbsSessionManager initializeFastConnectors.
		mockSession stubs at: #apiGciGetClass put: [ :oop |
			oop = 9000
				ifTrue: [ 5000 ]
				ifFalse: [ self fail ] ].
		mockSession stubs at: #executeAndFetch put: [ :script | | response |
			(script includesSubstring: 'classObject name asString') ifTrue: [
				self assert: (script includesSubstring: '5000').
				response := 'Array' ].
			(script includesSubstring: 'objectNamed: clsName asSymbol') ifTrue: [
				response := { 5000. 'Array'. 'Object'. nil. nil. 1. 1 } ].
			(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
				response := #() ].
			(script includesSubstring: 'oops do:') ifTrue: [
				bulkClassNameFetches := bulkClassNameFetches + 1.
				response := String streamContents: [ :stream |
					#(9100 9112 9120 9128 9136) do: [ :oop |
						stream
							nextPutAll: oop asString;
							nextPut: Character tab;
							nextPutAll: 'Array';
							nextPut: Character lf ] ] ].
			response ifNil: [ self fail ].
			response ].
		mockSession stubs at: #apiGciFetchSize put: [ :oop |
			oop = 9000 ifTrue: [ 5 ] ifFalse: [ self fail ] ].
		mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
			self assert: oop equals: 9000.
			self assert: start equals: 1.
			self assert: count equals: 5.
			#(9100 9112 9120 9128 9136) ].
		mockSession fetchShallow.

		result := mockSession fetchObject: 9000.

		self assert: result size equals: 5.
		self assert: (result allSatisfy: [ :each | each isKindOf: GbsTypedProxy ]).
		self assert: bulkClassNameFetches equals: 3.
		metrics := mockSession materializationMetrics.
		self assert: (metrics at: #classNameBatchCalls ifAbsent: [ 0 ]) equals: 3.
		self assert: (metrics at: #classNameBatchOopCount ifAbsent: [ 0 ]) equals: 5.
		self assert: (metrics at: #classNameFallbackCalls ifAbsent: [ 0 ]) equals: 0
	] ensure: [
		hadBatchSize
			ifTrue: [ Smalltalk globals at: #GbsMaterializationBatchSize put: previousBatchSize ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationBatchSize ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testMaterializationBatchSizeZeroUsesDefault [
	| mockSession previousBatchSize hadBatchSize |
	mockSession := CoreMockGbsSession new.
	hadBatchSize := Smalltalk globals includesKey: #GbsMaterializationBatchSize.
	previousBatchSize := Smalltalk globals at: #GbsMaterializationBatchSize ifAbsent: [ nil ].
	[
		Smalltalk globals at: #GbsMaterializationBatchSize put: 0.

		self assert: mockSession materializationBatchSize equals: 1000
	] ensure: [
		hadBatchSize
			ifTrue: [ Smalltalk globals at: #GbsMaterializationBatchSize put: previousBatchSize ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationBatchSize ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testMaterializationLimitsPreferSessionParameters [
	| mockSession params previousSession previousBatchSize hadBatchSize |
	mockSession := CoreMockGbsSession new.
	params := GbsSessionParameters new.
	params
		materializationBatchSize: '25';
		materializationMaxObjects: '3';
		materializationMaxDepth: '4';
		materializationMaxBatchBytes: '512';
		materializationMaxFrontierOops: '9'.
	previousSession := GbsSessionParameters currentSession.
	hadBatchSize := Smalltalk globals includesKey: #GbsMaterializationBatchSize.
	previousBatchSize := Smalltalk globals at: #GbsMaterializationBatchSize ifAbsent: [ nil ].
	[
		Smalltalk globals at: #GbsMaterializationBatchSize put: 999.
		mockSession parameters: params.

		self assert: mockSession materializationBatchSize equals: 25.
		self assert: mockSession materializer materializationMaxObjects equals: 3.
		self assert: mockSession materializer materializationMaxDepth equals: 4.
		self assert: mockSession materializer materializationMaxBatchBytes equals: 512.
		self assert: mockSession materializer materializationMaxFrontierOops equals: 9
	] ensure: [
		GbsSessionParameters currentSession: previousSession.
		hadBatchSize
			ifTrue: [ Smalltalk globals at: #GbsMaterializationBatchSize put: previousBatchSize ]
			ifFalse: [ Smalltalk globals removeKey: #GbsMaterializationBatchSize ifAbsent: [ ] ] ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchShallowFallsBackWhenClassNameBatchFails [
	| mockSession result bulkClassNameFetches fallbackClassNameFetches metrics |
	mockSession := CoreMockGbsSession new.
	bulkClassNameFetches := 0.
	fallbackClassNameFetches := 0.
	GbsSessionManager initializeFastConnectors.
	mockSession stubs at: #apiGciGetClass put: [ :oop |
		oop = 9000
			ifTrue: [ 5000 ]
			ifFalse: [ Error signal: 'Simulated per-object class OOP failure.' ] ].
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		(script includesSubstring: 'classObject name asString') ifTrue: [
			self assert: (script includesSubstring: '5000').
			response := 'Array' ].
		(script includesSubstring: 'objectNamed: clsName asSymbol') ifTrue: [
			response := { 5000. 'Array'. 'Object'. nil. nil. 1. 1 } ].
		(script includesSubstring: 'methodDict keys asSortedCollection') ifTrue: [
			response := #() ].
		(script includesSubstring: 'oops do:') ifTrue: [
			bulkClassNameFetches := bulkClassNameFetches + 1.
			Error signal: 'Simulated oversized class-name batch.' ].
		(script includesSubstring: 'object class name asString') ifTrue: [
			fallbackClassNameFetches := fallbackClassNameFetches + 1.
			response := 'Array' ].
		response ifNil: [ self fail ].
		response ].
	mockSession stubs at: #apiGciFetchSize put: [ :oop |
		oop = 9000 ifTrue: [ 3 ] ifFalse: [ self fail ] ].
	mockSession stubs at: #apiGciFetchOops put: [ :oop :start :buffer :count |
		self assert: oop equals: 9000.
		self assert: start equals: 1.
		self assert: count equals: 3.
		#(9100 9112 9120) ].
	mockSession fetchShallow.

	result := mockSession fetchObject: 9000.

	self assert: result size equals: 3.
	self assert: (result allSatisfy: [ :each | each isKindOf: GbsTypedProxy ]).
	self assert: (result collect: [ :each | each oop ]) equals: #(9100 9112 9120).
	self assert: bulkClassNameFetches equals: 5.
	self assert: fallbackClassNameFetches equals: 3.
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #classNameBatchCalls ifAbsent: [ 0 ]) equals: 5.
	self assert: (metrics at: #classNameBatchFallbacks ifAbsent: [ 0 ]) equals: 5.
	self assert: (metrics at: #classNameBatchSplits ifAbsent: [ 0 ]) equals: 2.
	self assert: (metrics at: #classNameFallbackCalls ifAbsent: [ 0 ]) equals: 3.
	self assert: (metrics at: #classNameObjectCalls ifAbsent: [ 0 ]) equals: 3
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassNameBatchSplitsAdaptivelyBeforePerObjectFallback [
	| mockSession classNames batchCalls metrics |
	mockSession := CoreMockGbsSession new.
	batchCalls := 0.
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object class name asString' ]) ifTrue: [
			batchCalls := batchCalls + 1.
			((script includesSubstring: '9100')
				and: [ (script includesSubstring: '9112')
				and: [ (script includesSubstring: '9120')
				and: [ script includesSubstring: '9128' ] ] ]) ifTrue: [
				Error signal: 'Simulated oversized class-name batch.' ].
			response := String streamContents: [ :stream |
				#(9100 9112 9120 9128) do: [ :oop |
					(script includesSubstring: oop asString) ifTrue: [
						stream
							nextPutAll: oop asString;
							nextPut: Character tab;
							nextPutAll: 'Array';
							nextPut: Character lf ] ] ] ].
		response ifNil: [ self fail ].
		response ].

	classNames := mockSession materializer remoteReader
		remoteClassNamesForOops: #(9100 9112 9120 9128).

	self assert: (classNames at: 9100) equals: 'Array'.
	self assert: (classNames at: 9128) equals: 'Array'.
	self assert: batchCalls equals: 3.
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #classNameBatchCalls ifAbsent: [ 0 ]) equals: 3.
	self assert: (metrics at: #classNameBatchFallbacks ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #classNameBatchSplits ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #classNameFallbackCalls ifAbsent: [ 0 ]) equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFrontierSlotBatchSplitsAdaptivelyBeforeSingleArrayFallback [
	| mockSession elementOops batchCalls metrics |
	mockSession := CoreMockGbsSession new.
	batchCalls := 0.
	mockSession stubs at: #executeAndFetch put: [ :script | | response |
		response := nil.
		((script includesSubstring: 'oops do:')
			and: [ script includesSubstring: 'object size asString' ]) ifTrue: [
			batchCalls := batchCalls + 1.
			((script includesSubstring: '9100')
				and: [ (script includesSubstring: '9112')
				and: [ (script includesSubstring: '9120')
				and: [ script includesSubstring: '9128' ] ] ]) ifTrue: [
				Error signal: 'Simulated oversized slot batch.' ].
			response := String streamContents: [ :stream |
				#(9100 9112 9120 9128) doWithIndex: [ :oop :index |
					(script includesSubstring: oop asString) ifTrue: [
						stream
							nextPutAll: oop asString;
							nextPut: Character tab;
							nextPutAll: '1';
							nextPut: Character tab;
							nextPutAll: (9040 + index) asString;
							nextPut: Character lf ] ] ] ].
		response ifNil: [ self fail ].
		response ].

	elementOops := mockSession materializer remoteReader
		remoteArrayElementOopsForOops: #(9100 9112 9120 9128).

	self assert: (elementOops at: 9100) equals: #(9041).
	self assert: (elementOops at: 9128) equals: #(9044).
	self assert: batchCalls equals: 3.
	metrics := mockSession materializationMetrics.
	self assert: (metrics at: #frontierSlotBatchCalls ifAbsent: [ 0 ]) equals: 3.
	self assert: (metrics at: #frontierSlotBatchFallbacks ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #frontierSlotBatchSplits ifAbsent: [ 0 ]) equals: 1.
	self assert: (metrics at: #frontierSlotFallbackCalls ifAbsent: [ 0 ]) equals: 0.
	self assert: (metrics at: #frontierSlotBatchOopCount ifAbsent: [ 0 ]) equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectAtCachesResolvedNamedRoots [
	| mockSession first second calls |
	mockSession := CoreMockGbsSession new.
	calls := 0.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		calls := calls + 1.
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 4444 session: mockSession ].

	first := mockSession namedObjectAt: #UserGlobals.
	second := mockSession namedObjectAt: 'UserGlobals'.

	self assert: first == second.
	self assert: calls equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectAtIfAbsentEvaluatesFallback [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#MissingThing').
		nil ].

	result := mockSession namedObjectAt: #MissingThing ifAbsent: [ #fallback ].

	self assert: result equals: #fallback
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectAtNormalizesStringNames [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 4444 session: mockSession ].

	result := mockSession namedObjectAt: 'UserGlobals'.

	self assert: result oop equals: 4444
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectAutoloadAliasResolvesRemoteNameAndCachesAlias [
	| mockSession first second calls |
	mockSession := CoreMockGbsSession new.
	calls := 0.
	mockSession registerNamedObjectAutoload: #UG remote: #UserGlobals.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		calls := calls + 1.
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 5555 session: mockSession ].

	first := mockSession namedObjectAt: #UG.
	second := mockSession namedObjectAt: #UserGlobals.

	self assert: first == second.
	self assert: calls equals: 1.
	self assert: (mockSession hasCachedNamedObjectNamed: #UG).
	self assert: (mockSession hasCachedNamedObjectNamed: #UserGlobals)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectAutoloadInspectionAndClear [
	| mockSession report entries |
	mockSession := CoreMockGbsSession new.
	mockSession registerNamedObjectAutoload: #UG remote: #UserGlobals.
	mockSession registerNamedObjectAutoload: #ROOT remote: #Globals.

	entries := mockSession namedObjectAutoloadEntries.
	report := mockSession namedObjectAutoloadReportText.

	self assert: mockSession namedObjectAutoloadKeys equals: #(ROOT UG).
	self assert: entries size equals: 2.
	self assert: (mockSession hasNamedObjectAutoloadNamed: #UG).
	self assert: (mockSession namedObjectAutoloadTargetFor: #ROOT) equals: #Globals.
	self assert: (report includesSubstring: 'UG -> UserGlobals').
	self assert: (report includesSubstring: 'ROOT -> Globals').

	mockSession unregisterNamedObjectAutoload: #UG.
	self deny: (mockSession hasNamedObjectAutoloadNamed: #UG).

	mockSession clearNamedObjectAutoloads.
	self assert: mockSession namedObjectAutoloadKeys isEmpty.
	self assert: mockSession namedObjectAutoloadReportText equals: 'No named-object autoload registrations.'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testNamedObjectCacheInspectionAndClear [
	| mockSession report entries |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '#UserGlobals').
		GbsProxy oop: 4444 session: mockSession ].

	mockSession namedObjectAt: #UserGlobals.
	entries := mockSession namedObjectCacheEntries.
	report := mockSession namedObjectCacheReportText.

	self assert: mockSession namedObjectCacheKeys equals: #(UserGlobals).
	self assert: entries size equals: 1.
	self assert: entries first key equals: #UserGlobals.
	self assert: (mockSession hasCachedNamedObjectNamed: 'UserGlobals').
	self assert: (report includesSubstring: 'UserGlobals').
	self assert: (report includesSubstring: '4444').

	mockSession clearNamedObjectCache.

	self assert: mockSession namedObjectCacheKeys isEmpty.
	self deny: (mockSession hasCachedNamedObjectNamed: #UserGlobals).
	self assert: mockSession namedObjectCacheReportText equals: 'No named objects cached.'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectForOopUsesReferenceSemantics [
	| proxy |
	proxy := session objectForOop: 1001.

	self assert: proxy class equals: GbsProxy.
	self assert: proxy oop equals: 1001.
	self assert: proxy session == session
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyEqualityDoesNotForwardClassPredicate [
	| mockSession left same differentSession differentOop forwarded |
	mockSession := CoreMockGbsSession new.
	left := GbsProxy oop: 1001 session: mockSession.
	same := GbsProxy oop: 1001 session: mockSession.
	differentOop := GbsProxy oop: 1002 session: mockSession.
	differentSession := GbsProxy oop: 1001 session: CoreMockGbsSession new.
	forwarded := false.
	mockSession stubs at: #forwardRemoteMessage put: [ :message :oop |
		forwarded := true.
		self fail ].

	self assert: left == left.
	self deny: left == same.
	self deny: left == differentOop.
	self deny: left == differentSession.
	self deny: left == Object new.
	self deny: forwarded
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyLifecycleIgnoresPlainSessionStandIns [
	| proxy plainSession |
	plainSession := Object new.
	proxy := GbsProxy oop: 12345 session: plainSession.

	self assert: proxy oop equals: 12345.
	self assert: proxy session equals: plainSession.
	self assert: proxy isNotNil.
	self assert: (GbsProxyLifecycle currentGenerationForSession: plainSession) equals: 0.
	self assert: (GbsProxyLifecycle invalidateSession: plainSession) equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyForOopServerClassNameUsesTypedWrapperWhenConnectorExists [
	| proxy |
	GbsSessionManager initializeFastConnectors.
	proxy := session
		proxyForOop: 1001
		serverClassName: 'Dictionary'.

	self assert: (proxy isKindOf: GbsTypedProxy).
	self assert: proxy clientBehaviorName equals: 'Dictionary'.
	self assert: proxy oop equals: 1001.
	self assert: proxy session == session
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyIdentityMapKeepsFirstProxyWhenPlainLookupPrecedesTypedLookup [
	| plain typed |
	GbsSessionManager initializeFastConnectors.
	plain := session resultFor: 1001.
	typed := session proxyForOop: 1001 serverClassName: 'Dictionary'.

	self assert: plain == typed.
	self assert: typed class equals: GbsProxy
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyIdentityMapKeepsTypedWrapperWhenTypedLookupPrecedesPlainLookup [
	| typed plain |
	GbsSessionManager initializeFastConnectors.
	typed := session proxyForOop: 1001 serverClassName: 'Dictionary'.
	plain := session resultFor: 1001.

	self assert: typed == plain.
	self assert: (plain isKindOf: GbsTypedProxy)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyIdentityMapReturnsSameProxyForRepeatedResultFor [
	| first second |
	first := session resultFor: 1001.
	second := session resultFor: 1001.

	self assert: first == second
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyIdentityMapReusesTypedWrapperForRepeatedTypedLookup [
	| first second |
	GbsSessionManager initializeFastConnectors.
	first := session proxyForOop: 1001 serverClassName: 'Dictionary'.
	second := session proxyForOop: 1001 serverClassName: 'Dictionary'.

	self assert: first == second.
	self assert: (first isKindOf: GbsTypedProxy)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClearProxyCacheAllowsTypedWrapperRecreation [
	| first second |
	GbsSessionManager initializeFastConnectors.
	first := session proxyForOop: 1001 serverClassName: 'Dictionary'.

	session clearProxyCache.
	second := session proxyForOop: 1001 serverClassName: 'Dictionary'.

	self deny: first == second.
	self assert: (second isKindOf: GbsTypedProxy).
	self assert: second session == session
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSessionForwarderForUsesNamedObjectCache [
	| mockSession first second calls |
	mockSession := CoreMockGbsSession new.
	calls := 0.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		calls := calls + 1.
		self assert: (script includesSubstring: '#Globals').
		GbsProxy oop: 1001 session: mockSession ].

	first := mockSession sessionForwarderFor: #Globals.
	second := mockSession sessionForwarderFor: #Globals.

	self assert: first == second.
	self assert: calls equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testWithMaterializationProfileRestoresPreviousProfile [
	| insideProfile |
	session withMaterializationProfile: GbsProxyOnlyMaterializationProfile new do: [
		insideProfile := session fetchProfile class ].

	self assert: insideProfile equals: GbsProxyOnlyMaterializationProfile.
	self assert: session fetchProfile class equals: GbsLegacyMaterializationProfile
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectFinalizerExecutesAllActionsWithTarget [
	| target finalizer seen |
	target := Object new.
	seen := OrderedCollection new.
	finalizer := GbsObjectFinalizer on: target.
	finalizer
		addAction: [ :each | seen add: each ];
		addAction: [ :each | seen add: each class name ].

	finalizer finalize.

	self assert: seen first == target.
	self assert: seen second equals: 'Object'.
	self assert: finalizer size equals: 0
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceAllSubclassesOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'cls allSubclasses asArray').
		self assert: (script includesSubstring: '''Invoice''').
		#(SubclassOne SubclassTwo) ].

	result := mockSession objectSpace allSubclassesOfNamed: 'Invoice'.

	self assert: result equals: #(SubclassOne SubclassTwo)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDefineAndUndefineFinalizerUsesSharedRegistry [
	| target first second group |
	target := Object new.
	first := [ :each | each ].
	second := [ :each | each class ].

	group := session
		defineFinalizerFor: target
		do: first.
	self assert: (session hasFinalizerFor: target).
	self assert: group size equals: 1.

	group := session
		defineFinalizerFor: target
		do: second.
	self assert: group size equals: 2.
	self assert: (session objectSpace finalizerFor: target) == group.

	session undefineFinalizerFor: target.
	self deny: (session hasFinalizerFor: target)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeSupportsArbitraryKeysWithSlotObjects [
	| mockSession diagnostics slot report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].
	diagnostics := mockSession objectSpaceDiagnostics.

	slot := diagnostics slotAtKey: 21 label: 'Custom Slot'.
	report := diagnostics reportTextForKeys: #(21).

	self assert: slot key equals: 21.
	self assert: slot label equals: 'Custom Slot'.
	self assert: slot size equals: 3.
	self assert: (diagnostics reportSlotsForKeys: #(21)) size equals: 1.
	self assert: (report includesSubstring: 'Key 21 (Session State): Array size=3')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeExpandsAliasPrefixesAndAliasNames [
	| mockSession diagnostics slot |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [ ^ IdentityDictionary new ].
		self fail ].
	diagnostics := mockSession objectSpaceDiagnostics.
	slot := diagnostics slotNamed: 'slot 19'.

	self assert: (diagnostics slotKeyNamed: 'slot 19') equals: 19.
	self assert: (diagnostics slotKeyNamed: 'session.state.19') equals: 19.
	self assert: (diagnostics slotKeyNamed: 'ruby main thread finalizers') equals: 19.
	self assert: (diagnostics slotAliasNamesAtKey: 19) notEmpty.
	self assert: (slot hasAliasNamed: 'rubymainthreadfinalizers').
	self assert: (slot aliasNames includes: 'maglevfinalizerregistry')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeReportObjectSeparatesWellKnownAndCustomSlots [
	| mockSession report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [ ^ (IdentityDictionary new at: #lazy put: true; yourself) ].
		(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2 3) ].
		self fail ].

	report := mockSession objectSpaceDiagnostics reportForKeys: #(19 21).

	self assert: report slots size equals: 2.
	self assert: report wellKnownSlots size equals: 1.
	self assert: report customSlots size equals: 1.
	self assert: (report text includesSubstring: 'Well-Known Session State').
	self assert: (report text includesSubstring: 'Custom Session State')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsObjectsInMemoryReportUsesStructuredObjects [
	| mockSession report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository _listInstancesInMemory:')
			ifTrue: [ ^ { GbsProxy oop: 9201 session: mockSession. GbsProxy oop: 9202 session: mockSession } ].
		self fail ].

	report := mockSession objectSpaceDiagnostics objectsInMemoryReportFrom: 1 limit: 2.

	self assert: report objects size equals: 2.
	self assert: report objects first oop equals: 9201.
	self assert: (report text includesSubstring: 'Objects In Memory').
	self assert: (report text includesSubstring: 'oop=9201')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeDiscoversOccupiedSlotsAndParsesNamedAliases [
	| mockSession diagnostics discovered slot |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazy put: true;
				yourself) ].
		(script includesSubstring: 'key := 20')
			ifTrue: [ ^ nil ].
		(script includesSubstring: 'key := 21')
			ifTrue: [ ^ #(1 2 3) ].
		self fail ].
	diagnostics := mockSession objectSpaceDiagnostics.

	slot := diagnostics slotNamed: 'session.state.21'.
	discovered := diagnostics occupiedSlotsFrom: 19 to: 21.

	self assert: slot key equals: 21.
	self assert: slot exists.
	self assert: (diagnostics slotNamed: 'slot 19') key equals: 19.
	self assert: discovered size equals: 2.
	self assert: (discovered collect: [ :each | each key ]) equals: #(19 21).
	self assert: ((diagnostics occupiedSlotsReportTextFrom: 19 to: 21)
		includesSubstring: 'Key 21 (Session State): Array size=3')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeSupportsRegisteredWellKnownSlots [
	| mockSession diagnostics slot report |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		GbsObjectSpaceDiagnosticsFacade
			registerWellKnownSessionStateSlotKey: 21
			label: 'Ruby Thread Cache'
			aliases: #('rubythreadcache' 'threadcache').
		mockSession := CoreMockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2) ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.

		slot := diagnostics slotNamed: 'Ruby Thread Cache'.
		report := diagnostics reportTextForSlotNames: #('thread cache').

		self assert: (diagnostics slotKeyNamed: 'ruby_thread_cache') equals: 21.
		self assert: (diagnostics slotKeyNamed: 'Ruby Thread Cache') equals: 21.
		self assert: slot label equals: 'Ruby Thread Cache'.
		self assert: (report includesSubstring: 'Key 21 (Ruby Thread Cache): Array size=2')
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeBatchRegistersSlotsAndTracksDiscoverySource [
	| mockSession diagnostics registeredSlot discoveredSlot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		GbsObjectSpaceDiagnosticsFacade registerWellKnownSessionStateSlots: {
			{ 21. 'Ruby Thread Cache'. #('rubythreadcache' 'threadcache') }.
			{ 22. 'Ruby Fiber Registry'. #('rubyfiberregistry' 'fiberregistry') } }.
		mockSession := CoreMockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2) ].
			(script includesSubstring: 'key := 23') ifTrue: [ ^ 'dynamic-slot' ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.

		registeredSlot := diagnostics slotNamed: 'thread cache'.
		discoveredSlot := diagnostics slotAtKey: 23.

		self assert: (diagnostics slotKeyNamed: 'fiber registry') equals: 22.
		self assert: registeredSlot isWellKnown.
		self assert: registeredSlot discoverySource equals: #registered.
		self deny: discoveredSlot isWellKnown.
		self assert: discoveredSlot discoverySource equals: #discovered
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeBuildsTypedCacheAndRegistrySlots [
	| mockSession diagnostics cacheSlot registrySlot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		GbsObjectSpaceDiagnosticsFacade
			registerWellKnownCacheSessionStateSlotKey: 21
			label: 'Ruby Thread Cache'
			aliases: #('threadcache')
			tags: #(#ruby #cache).
		GbsObjectSpaceDiagnosticsFacade
			registerWellKnownRegistrySessionStateSlotKey: 22
			label: 'Ruby Fiber Registry'
			aliases: #('fiberregistry')
			tags: #(#ruby #registry).
		mockSession := CoreMockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 21') ifTrue: [ ^ #(1 2) ].
			(script includesSubstring: 'key := 22') ifTrue: [ ^ (IdentityDictionary new at: #fiber put: 1; yourself) ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.
		cacheSlot := diagnostics slotNamed: 'thread cache'.
		registrySlot := diagnostics slotNamed: 'fiber registry'.

		self assert: cacheSlot class equals: GbsCacheSessionStateSlot.
		self assert: cacheSlot isCacheSlot.
		self assert: cacheSlot slotKind equals: #cache.
		self assert: (cacheSlot hasTag: #cache).
		self assert: registrySlot class equals: GbsRegistrySessionStateSlot.
		self assert: registrySlot isRegistrySlot.
		self assert: registrySlot slotKind equals: #registry.
		self assert: (registrySlot hasTag: #registry)
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceDiagnosticsFacadeInfersTypedSlotsForDiscoveredValues [
	| mockSession diagnostics registrySlot cacheSlot threadSlot |
	[
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots.
		GbsObjectSpaceDiagnosticsFacade
			registerWellKnownThreadStateSessionStateSlotKey: 25
			label: 'Ruby Thread State'
			aliases: #('rubythreadstate' 'threadstate')
			tags: #(#ruby #thread).
		mockSession := CoreMockGbsSession new.
		mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
			(script includesSubstring: 'key := 23') ifTrue: [ ^ IdentityDictionary new ].
			(script includesSubstring: 'key := 24') ifTrue: [ ^ #(1 2 3) ].
			(script includesSubstring: 'key := 25') ifTrue: [ ^ 'thread-state' ].
			self fail ].
		diagnostics := mockSession objectSpaceDiagnostics.

		registrySlot := diagnostics slotAtKey: 23 label: 'Session Registry'.
		cacheSlot := diagnostics slotAtKey: 24 label: 'Session Cache'.
		threadSlot := diagnostics slotNamed: 'threadstate'.

		self assert: registrySlot class equals: GbsRegistrySessionStateSlot.
		self assert: cacheSlot class equals: GbsCacheSessionStateSlot.
		self assert: threadSlot class equals: GbsThreadStateSessionStateSlot.
		self assert: (threadSlot hasTag: #thread)
	] ensure: [
		GbsObjectSpaceDiagnosticsFacade resetRegisteredWellKnownSessionStateSlots ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceEachObjectDoBatchSizeUsesPagedFetches [
	| mockSession seen |
	mockSession := CoreMockGbsSession new.
	seen := OrderedCollection new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'startIndex := 1')
			ifTrue: [ ^ #(11 12) ].
		(script includesSubstring: 'startIndex := 3')
			ifTrue: [ ^ #(13) ].
		self fail ].

	mockSession eachObjectDo: [ :each |
		seen add: each ] batchSize: 2.

	self assert: seen asArray equals: #(11 12 13)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceEachObjectDoBuildsExpectedScript [
	| mockSession seen |
	mockSession := CoreMockGbsSession new.
	seen := OrderedCollection new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'SystemRepository _loadedClasses: false').
		self assert: (script includesSubstring: 'SystemRepository _listInstancesInMemory: classes').
		#(11 12 13) ].

	mockSession eachObjectDo: [ :each |
		seen add: each ].

	self assert: seen asArray equals: #(11 12 13)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceFacadeRetainsSession [
	| mockSession facade |
	mockSession := CoreMockGbsSession new.

	facade := mockSession objectSpace.

	self assert: facade class equals: GbsObjectSpaceFacade.
	self assert: facade session == mockSession
]

{ #category : 'tests' }
GbsSessionCoreTest >> testChunkedMigrationRunnerBuildsMaglevAlignedScripts [
	| mockSession runner prepareScript chunkScript |
	mockSession := CoreMockGbsSession new.
	runner := GbsChunkedMigrationRunner
		on: mockSession
		source: #LegacyPoint
		target: #Point.
	prepareScript := runner listInstanceOopsCommand script.
	chunkScript := (runner migrateChunkCommandForOops: #(101 102 103)) script.

	self assert: (prepareScript includesSubstring: 'SystemRepository listInstances').
	self assert: (prepareScript includesSubstring: 'LegacyPoint').
	self assert: (chunkScript includesSubstring: 'migrateInstances: instances asArray to: toClass').
	self assert: (chunkScript includesSubstring: 'oops do:').
	self assert: (chunkScript includesSubstring: '101').
	self assert: (chunkScript includesSubstring: 'Point').
	self deny: (chunkScript includesSubstring: '(Object _objectForOop: 101)')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testChunkedMigrationRunnerPrepareCheckpointReplaysAcrossCommitConflict [
	| mockSession runner result listCount checkpointWriteCount commits |
	mockSession := CoreMockGbsSession new.
	listCount := 0.
	checkpointWriteCount := 0.
	commits := #(0 1) readStream.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository listInstances') ifTrue: [
			listCount := listCount + 1.
			^ #(101 102) ].
		(script includesSubstring: 'gbsMigration:LegacyPoint->Point') ifTrue: [
			checkpointWriteCount := checkpointWriteCount + 1.
			^ #(101 102) ].
		self fail ].
	mockSession stubs at: #gciCommit put: [ commits next ].
	runner := GbsChunkedMigrationRunner
		on: mockSession
		source: #LegacyPoint
		target: #Point.

	result := runner prepareCheckpoint.

	self assert: (result at: #remaining) equals: 2.
	self assert: (result at: #committed) equals: true.
	self assert: listCount equals: 2.
	self assert: checkpointWriteCount equals: 2
]

{ #category : 'tests' }
GbsSessionCoreTest >> testCommitTransactionWithRetryCountSignalsConflictAfterExhaustion [
	| mockSession commitCount |
	mockSession := CoreMockGbsSession new.
	commitCount := 0.
	mockSession stubs at: #gciCommit put: [
		commitCount := commitCount + 1.
		0 ].

	self
		should: [ mockSession commitTransactionWithRetryCount: 1 ]
		raise: GbsCommitConflictError.
	self assert: commitCount equals: 2
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSmalltalkFacadeExposesBridgeRootAndSymbolDictionaries [
	| mockSession facade |
	mockSession := CoreMockGbsSession new.
	facade := mockSession smalltalk.

	self assert: facade class equals: GbsSmalltalkFacade.
	self assert: mockSession bridgeRoot class equals: GbsBridgeRootFacade.
	self assert: mockSession bridgeRoot rootKey equals: #GbsBridgeRoot.
	self assert: facade bridgeRoot class equals: GbsBridgeRootFacade.
	self assert: facade bridgeRoot rootKey equals: #GbsBridgeRoot.
	self assert: facade globals class equals: GbsSymbolDictionaryFacade.
	self assert: facade published class equals: GbsSymbolDictionaryFacade.
	self assert: facade userGlobals class equals: GbsSymbolDictionaryFacade.
	self deny: (facade respondsTo: #sessionMethods)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFetchTranscriptLogsUsesSessionTempsFallbackScript [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeAndFetch put: [ :script |
		self assert: (script includesSubstring: 'Transcript respondsTo: #fetchAndClear').
		self assert: (script includesSubstring: '#PharoTranscriptLog').
		self assert: (script includesSubstring: 'UserGlobals at: #PharoTranscriptLog put: OrderedCollection new').
		^ 'TDD Hello', String cr ].

	self assert: (mockSession fetchTranscriptLogs includesSubstring: 'TDD Hello')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceRepositoryFacadeCountsOopsAndBuildsReport [
	| mockSession repository report |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'SystemRepository listInstances') ifTrue: [
			(script includesSubstring: 'instances size') ifTrue: [ ^ 3 ].
			(script includesSubstring: 'collect: [ :each | each asOop ]') ifTrue: [ ^ #(101 102 103) ] ].
		self fail ].
	repository := mockSession objectSpaceRepository.
	report := repository reportTextFor: #LegacyPoint.

	self assert: (repository countInstancesOf: #LegacyPoint) equals: 3.
	self assert: (repository instanceOopsOf: #LegacyPoint) equals: #(101 102 103).
	self assert: (report includesSubstring: 'ObjectSpace::Repository').
	self assert: (report includesSubstring: 'LegacyPoint').
	self assert: (report includesSubstring: '#(101 102 103)')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceInstancesInMemoryOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'SystemRepository _listInstancesInMemory: { cls }').
		self assert: (script includesSubstring: '''Invoice''').
		#(11 12) ].

	result := mockSession objectSpace instancesInMemoryOfNamed: 'Invoice'.

	self assert: result equals: #(11 12)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceInstancesInMemoryOfNamedFromLimitBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'SystemRepository _listInstancesInMemory: { cls }').
		self assert: (script includesSubstring: '''Invoice''').
		self assert: (script includesSubstring: ':startIndex').
		self assert: (script includesSubstring: ':limitValue').
		self assert: (script includesSubstring: 'value: 1 value: 2').
		#(12) ].

	result := mockSession
		objectSpace
		instancesInMemoryOf: 'Invoice'
		from: 2
		limit: 1.

	self assert: result equals: #(12)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceLoadedClassesIncludingModulesBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'SystemRepository _loadedClasses: includeModules').
		self assert: (script includesSubstring: 'includeModules := true').
		#('Invoice' 'Payments') ].

	result := mockSession objectSpace loadedClassesIncludingModules.

	self assert: result equals: #('Invoice' 'Payments')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceLoadedClassesIncludingModulesFalseBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'SystemRepository _loadedClasses: includeModules').
		self assert: (script includesSubstring: 'includeModules := false').
		#('Invoice') ].

	result := mockSession objectSpace loadedClassesIncludingModules: false.

	self assert: result equals: #('Invoice')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceObjectsInMemoryFromLimitBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'startIndex := 3').
		self assert: (script includesSubstring: 'limitValue := 2').
		self assert: (script includesSubstring: 'skipCount := startIndex - 1').
		self assert: (script includesSubstring: 'takeCount := limitValue').
		#(21 22) ].

	result := mockSession objectSpace objectsInMemoryFrom: 3 limit: 2.

	self assert: result equals: #(21 22)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceObjectsInMemoryMatchingFiltersIncrementally [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'startIndex := 1')
			ifTrue: [ ^ #(11 12) ].
		(script includesSubstring: 'startIndex := 3')
			ifTrue: [ ^ #(13 14) ].
		self fail ].

	result := mockSession
		objectsInMemoryMatching: [ :each | each odd ]
		limit: 2
		batchSize: 2.

	self assert: result equals: #(11 13)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceReferencesToBuildsExpectedScript [
	| mockSession proxy result |
	mockSession := CoreMockGbsSession new.
	proxy := GbsProxy oop: 4242 session: mockSession.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'object := (Object _objectForOop: 4242)').
		self assert: (script includesSubstring: 'object findReferencesInMemory asArray').
		^ #(9001 9002) ].

	result := mockSession objectSpace referencesTo: proxy.

	self assert: result equals: #(9001 9002)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceReferencesToOopBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'object := (Object _objectForOop: 4242)').
		self assert: (script includesSubstring: 'object findReferencesInMemory asArray').
		^ #(9001) ].

	result := mockSession objectSpace referencesToOop: 4242.

	self assert: result equals: #(9001)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceSessionStateAtBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '(System respondsTo: #sessionStateAt:)').
		self assert: (script includesSubstring: 'System sessionStateAt: key').
		self assert: (script includesSubstring: 'key := 19').
		^ 'finalizer-registry' ].

	result := mockSession objectSpace sessionStateAt: 19.

	self assert: result equals: 'finalizer-registry'.
	self assert: mockSession maglevFinalizerRegistry equals: 'finalizer-registry'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testObjectSpaceSessionStateAtPutBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: '(System respondsTo: #sessionStateAt:put:)').
		self assert: (script includesSubstring: 'System sessionStateAt: key put: value').
		self assert: (script includesSubstring: 'key := 21').
		self assert: (script includesSubstring: 'value := ''cached-value''').
		^ 'cached-value' ].

	result := mockSession
		objectSpace
		sessionStateAt: 21
		put: 'cached-value'.

	self assert: result equals: 'cached-value'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testWithCommitRetryCountReplaysBlockAcrossCommitConflict [
	| mockSession attempts commits result |
	mockSession := CoreMockGbsSession new.
	attempts := 0.
	commits := #(0 1) readStream.
	mockSession stubs at: #gciCommit put: [ commits next ].

	result := mockSession withCommitRetryCount: 1 do: [
		attempts := attempts + 1.
		attempts ].

	self assert: result equals: 2.
	self assert: attempts equals: 2
]

{ #category : 'tests' }
GbsSessionCoreTest >> testWithGemStoneTransactionDoAbortsOnBlockError [
	| mockSession aborts |
	mockSession := CoreMockGbsSession new.
	aborts := 0.
	mockSession stubs at: #gciAbort put: [
		aborts := aborts + 1.
		1 ].

	self
		should: [
			mockSession withGemStoneTransactionDo: [
				Error signal: 'boom' ] ]
		raise: Error.

	self assert: aborts equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testWithGemStoneTransactionDoCommitsAndReturnsResult [
	| mockSession commits result |
	mockSession := CoreMockGbsSession new.
	commits := 0.
	mockSession stubs at: #gciCommit put: [
		commits := commits + 1.
		1 ].

	result := mockSession withGemStoneTransactionDo: [ #committed ].

	self assert: result equals: #committed.
	self assert: commits equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testWithGemStoneTransactionRetryCountReplaysBlockAcrossCommitConflict [
	| mockSession attempts commits aborts result |
	mockSession := CoreMockGbsSession new.
	attempts := 0.
	aborts := 0.
	commits := #(0 1) readStream.
	mockSession stubs at: #gciCommit put: [ commits next ].
	mockSession stubs at: #gciAbort put: [
		aborts := aborts + 1.
		1 ].

	result := mockSession withGemStoneTransactionRetryCount: 1 do: [
		attempts := attempts + 1.
		attempts ].

	self assert: result equals: 2.
	self assert: attempts equals: 2.
	self assert: aborts equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testWithGemStoneTransactionRetryCountSignalsConflictAfterRetries [
	| mockSession aborts |
	mockSession := CoreMockGbsSession new.
	aborts := 0.
	mockSession stubs at: #gciCommit put: [ 0 ].
	mockSession stubs at: #gciAbort put: [
		aborts := aborts + 1.
		1 ].

	self
		should: [
			mockSession withGemStoneTransactionRetryCount: 0 do: [ #dirty ] ]
		raise: GbsCommitConflictError.

	self assert: aborts equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryClassMirrorOfNamedBuildsExpectedScripts [
	| mockSession mirror |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(1001 'Invoice' 'Object' 'Billing-Core' 'Billing-Models' 2 3) ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'Invoice' 1 3)
				#(1001 'Invoice' 2 3)
				#(1002 'Invoice' 3 3)) ].
		(script includesSubstring: 'behavior := cls class') ifTrue: [
			^ #(#('initialization' #('new')) #('testing' #('canOpen'))) ].
		(script includesSubstring: 'behavior := cls.') ifTrue: [
			^ #(#('accessing' #('amount' 'currency')) #('testing' #('isPaid'))) ].
		self fail ].

	mirror := mockSession classMirrorOfNamed: 'Invoice'.

	self assert: mirror exists.
	self assert: mirror name equals: 'Invoice'.
	self assert: mirror superclassName equals: 'Object'.
	self assert: mirror oop equals: 1001.
	self assert: mirror proxy oop equals: 1001.
	self assert: mirror packageName equals: 'Billing-Core'.
	self assert: mirror categoryName equals: 'Billing-Models'.
	self assert: mirror version equals: 2.
	self assert: mirror numberOfVersions equals: 3.
	self assert: mirror instanceProtocols equals: #(#('accessing' #('amount' 'currency')) #('testing' #('isPaid'))).
	self assert: mirror classProtocols equals: #(#('initialization' #('new')) #('testing' #('canOpen'))).
	self assert: mirror instanceSelectors equals: #(amount currency isPaid).
	self assert: mirror classSelectors equals: #(new canOpen).
	self assert: (mirror protocolForSelector: #currency) equals: 'accessing'.
	self assert: (mirror classProtocolForSelector: #new) equals: 'initialization'.
	self assert: mirror classHistory size equals: 3.
	self assert: mirror classHistory selectedVersionName equals: 'Invoice'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodMirrorForClassNamedBuildsExpectedScript [
	| mockSession instanceMirror classMirror |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'value: (''totalPrice'' asSymbol)') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		(script includesSubstring: 'value: (''new'' asSymbol)') ifTrue: [
			^ #(2002 'Invoice class' 'new' 'instance creation' 'new ^ super new' 'Billing-Core' 'Invoice class>>new' 1 2) ].
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(1001 'Invoice' 'Object' 'Billing-Core' 'Billing-Models' 2 3) ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'Invoice' 1 3)
				#(1001 'Invoice' 2 3)
				#(1002 'Invoice' 3 3)) ].
		self fail ].

	instanceMirror := mockSession
		methodMirrorForClassNamed: 'Invoice'
		selector: #totalPrice.
	classMirror := (mockSession classMirrorOfNamed: 'Invoice')
		classMethodMirrorAt: #new.

	self assert: instanceMirror exists.
	self assert: instanceMirror selector equals: #totalPrice.
	self assert: instanceMirror ownerName equals: 'Invoice'.
	self assert: instanceMirror protocol equals: 'pricing'.
	self assert: instanceMirror sourceCode equals: 'totalPrice ^ amount'.
	self assert: instanceMirror packageName equals: 'Billing-Core'.
	self assert: instanceMirror sourceLocation equals: 'Invoice>>totalPrice'.
	self assert: instanceMirror version equals: 3.
	self assert: instanceMirror numberOfVersions equals: 4.
	self assert: instanceMirror classMirror packageName equals: 'Billing-Core'.
	self assert: instanceMirror classHistory size equals: 3.
	self assert: instanceMirror oop equals: 2001.
	self assert: instanceMirror proxy oop equals: 2001.
	self assert: classMirror exists.
	self assert: classMirror classSide.
	self assert: classMirror ownerName equals: 'Invoice class'.
	self assert: classMirror protocol equals: 'instance creation'.
	self assert: classMirror sourceCode equals: 'new ^ super new'.
	self assert: classMirror packageName equals: 'Billing-Core'.
	self assert: classMirror sourceLocation equals: 'Invoice class>>new'.
	self assert: classMirror version equals: 1.
	self assert: classMirror numberOfVersions equals: 2.
	self assert: classMirror oop equals: 2002
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodObjectBindsAndInvokesThroughSession [
	| mockSession methodObject bound receiver capturedSelector capturedArguments capturedOop result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'value: (''totalPrice'' asSymbol)') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].
	mockSession stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#forwarded ].
	methodObject := mockSession
		methodObjectForClassNamed: 'Invoice'
		selector: #totalPrice.
	receiver := GbsProxy oop: 9001 session: mockSession.

	self deny: methodObject isBound.
	bound := methodObject bindTo: receiver.
	result := bound callWithArguments: #(5 'GBP').

	self assert: result equals: #forwarded.
	self deny: methodObject isBound.
	self assert: bound isBound.
	self assert: bound selector equals: #totalPrice.
	self assert: bound protocol equals: 'pricing'.
	self assert: bound sourceCode equals: 'totalPrice ^ amount'.
	self assert: bound receiver oop equals: 9001.
	self assert: capturedSelector equals: #totalPrice.
	self assert: capturedArguments equals: #(5 'GBP').
	self assert: capturedOop equals: 9001.
	self deny: bound unbind isBound
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodObjectEqualityHashAndBindingIdentity [
	| mockSession sameMethod sameMethodAgain boundSameReceiver boundSameReceiverAgain boundOtherReceiver receiverOne receiverTwo |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'value: (''totalPrice'' asSymbol)') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].

	sameMethod := mockSession methodObjectForClassNamed: 'Invoice' selector: #totalPrice.
	sameMethodAgain := mockSession methodObjectForClassNamed: 'Invoice' selector: #totalPrice.
	receiverOne := GbsProxy oop: 9001 session: mockSession.
	receiverTwo := GbsProxy oop: 9002 session: mockSession.
	boundSameReceiver := sameMethod bindTo: receiverOne.
	boundSameReceiverAgain := sameMethodAgain bindTo: receiverOne.
	boundOtherReceiver := sameMethod bindTo: receiverTwo.

	self assert: sameMethod equals: sameMethodAgain.
	self assert: sameMethod hash equals: sameMethodAgain hash.
	self assert: boundSameReceiver equals: boundSameReceiverAgain.
	self assert: boundSameReceiver hash equals: boundSameReceiverAgain hash.
	self deny: sameMethod equals: boundSameReceiver.
	self deny: boundSameReceiver equals: boundOtherReceiver
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryClassMethodObjectUsesClassProxyWhenUnbound [
	| mockSession methodObject capturedSelector capturedArguments capturedOop result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'value: (''new'' asSymbol)') ifTrue: [
			^ #(2002 'Invoice class' 'new' 'instance creation' 'new ^ super new' 'Billing-Core' 'Invoice class>>new' 1 2) ].
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(1001 'Invoice' 'Object' 'Billing-Core' 'Billing-Models' 2 3) ].
		self fail ].
	mockSession stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#created ].
	methodObject := mockSession
		classMethodObjectForClassNamed: 'Invoice'
		selector: #new.

	result := methodObject call.

	self assert: result equals: #created.
	self deny: methodObject isBound.
	self assert: methodObject ownerName equals: 'Invoice class'.
	self assert: capturedSelector equals: #new.
	self assert: capturedArguments equals: #().
	self assert: capturedOop equals: 1001
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodObjectValueConvenienceAndPrintString [
	| mockSession methodObject bound receiver capturedSelector capturedArguments capturedOop result printed |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'value: (''applyDiscount:currency:'' asSymbol)') ifTrue: [
			^ #(2003 'Invoice' 'applyDiscount:currency:' 'pricing' 'applyDiscount: percent currency: code ^ total' 'Billing-Core' 'Invoice>>applyDiscount:currency:' 2 4) ].
		self fail ].
	mockSession stubs at: #forwardRemoteMessage put: [ :message :oop |
		capturedSelector := message selector.
		capturedArguments := message arguments.
		capturedOop := oop.
		#discounted ].
	methodObject := mockSession
		methodObjectForClassNamed: 'Invoice'
		selector: #applyDiscount:currency:.
	receiver := GbsProxy oop: 9001 session: mockSession.
	bound := methodObject bindTo: receiver.

	result := bound value: 5 value: 'GBP'.
	printed := bound printString.

	self assert: result equals: #discounted.
	self assert: bound argumentCount equals: 2.
	self assert: bound isInstanceSide.
	self deny: bound isClassSide.
	self assert: capturedSelector equals: #applyDiscount:currency:.
	self assert: capturedArguments equals: #(5 'GBP').
	self assert: capturedOop equals: 9001.
	self assert: (printed includesSubstring: 'Invoice>>applyDiscount:currency:').
	self assert: (printed includesSubstring: '@9001')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodObjectParityDelegatesMirrorMetadata [
	| mockSession methodObject |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'value: (''new'' asSymbol)') ifTrue: [
			^ #(2002 'Invoice class' 'new' 'instance creation' 'new ^ super new' 'Billing-Core' 'Invoice class>>new' 1 2) ].
		(script includesSubstring: 'cls superclass') ifTrue: [
			^ #(1001 'Invoice' 'Object' 'Billing-Core' 'Billing-Models' 2 3) ].
		self fail ].
	methodObject := mockSession
		classMethodObjectForClassNamed: 'Invoice'
		selector: #new.

	self assert: methodObject categoryName equals: 'instance creation'.
	self assert: methodObject packageName equals: 'Billing-Core'.
	self assert: methodObject version equals: 1.
	self assert: methodObject numberOfVersions equals: 2.
	self assert: methodObject ownerProxy oop equals: 1001.
	self assert: methodObject name equals: 'Invoice class>>new'.
	self assert: (methodObject displayString includesSubstring: 'Invoice class>>new')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryUnboundMethodObjectDelegatesMirrorMetadataAndCanBind [
	| mockSession methodObject bound receiver |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'value: (''totalPrice'' asSymbol)') ifTrue: [
			^ #(2001 'Invoice' 'totalPrice' 'pricing' 'totalPrice ^ amount' 'Billing-Core' 'Invoice>>totalPrice' 3 4) ].
		self fail ].

	methodObject := mockSession
		unboundMethodObjectForClassNamed: 'Invoice'
		selector: #totalPrice.
	receiver := GbsProxy oop: 9001 session: mockSession.
	bound := methodObject bindTo: receiver.

	self deny: methodObject isBound.
	self assert: methodObject ownerName equals: 'Invoice'.
	self assert: methodObject selector equals: #totalPrice.
	self assert: methodObject categoryName equals: 'pricing'.
	self assert: methodObject packageName equals: 'Billing-Core'.
	self assert: methodObject version equals: 3.
	self assert: methodObject numberOfVersions equals: 4.
	self assert: methodObject receiver isNil.
	self assert: (methodObject displayString includesSubstring: 'Invoice>>totalPrice').
	self assert: methodObject unbind == methodObject.
	self assert: bound isBound.
	self assert: bound receiver oop equals: 9001
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryUnboundInstanceMethodObjectSignalsError [
	| mockSession methodObject |
	mockSession := CoreMockGbsSession new.
	methodObject := mockSession
		methodObjectForClassNamed: 'Invoice'
		selector: #totalPrice.

	self
		should: [ methodObject call ]
		raise: Error
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodReferenceStringsQueriesBuildExpectedScripts [
	| mockSession symbolResult objectResult proxy |
	mockSession := CoreMockGbsSession new.
	proxy := GbsProxy oop: 9001 session: mockSession.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		((script includesSubstring: 'organizer referencesTo: symbolValue')
			and: [ script includesSubstring: 'value: (''Invoice'' asSymbol)' ]) ifTrue: [
			^ #('Invoice>>totalPrice' 'Invoice class>>new') ].
		((script includesSubstring: 'organizer referencesToObject: targetObject')
			and: [ script includesSubstring: 'value: (Object _objectForOop: 9001)' ]) ifTrue: [
			self assert: (script includesSubstring: 'theNonMetaClass').
			^ #('Order>>invoice') ].
		self fail ].

	symbolResult := mockSession methodReferenceStringsToSymbol: 'Invoice'.
	objectResult := mockSession methodReferenceStringsToObject: proxy.

	self assert: symbolResult equals: #('Invoice>>totalPrice' 'Invoice class>>new').
	self assert: objectResult equals: #('Order>>invoice')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMethodSelectorReferenceQueriesBuildExpectedScripts [
	| mockSession implementors senders |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		((script includesSubstring: 'organizer implementorsOf: selectorValue')
			and: [ script includesSubstring: 'value: (''size'' asSymbol)' ]) ifTrue: [
			^ #('Object>>size' 'Behavior>>size') ].
		((script includesSubstring: 'organizer sendersOf: selectorValue')
			and: [ script includesSubstring: 'value: ''size''' ]) ifTrue: [
			^ #('Collection>>includes:' 'Behavior>>new') ].
		self fail ].

	implementors := mockSession implementorMethodReferenceStringsForSelector: 'size'.
	senders := mockSession senderMethodReferenceStringsForSelector: 'size'.

	self assert: implementors equals: #('Object>>size' 'Behavior>>size').
	self assert: senders equals: #('Collection>>includes:' 'Behavior>>new')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryHierarchyMethodReferenceQueriesBuildExpectedScripts [
	| mockSession implementors senders |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'className := rootClassName') ifFalse: [ self fail ].
		(script includesSubstring: 'value: ''Object''') ifFalse: [ self fail ].
		(script includesSubstring: 'scope = ''super''') ifFalse: [ self fail ].
		(script includesSubstring: 'cls class includesSelector: sel') ifTrue: [
			self assert: (script includesSubstring: 'stream nextPutAll: cls name asString; nextPutAll: '' class>>''').
			^ #('Object>>size' 'Object class>>new') ].
		(script includesSubstring: 'cls whichSelectorsReferTo: sel') ifTrue: [
			self deny: (script includesSubstring: 'cls class whichSelectorsReferTo: sel').
			^ #('Collection>>includes:') ].
		self fail ].

	implementors := mockSession
		hierarchyImplementorMethodReferenceStringsForSelector: 'size'
		rootClassName: 'Object'
		scope: 'super'
		includeClassSide: true.
	senders := mockSession
		hierarchySenderMethodReferenceStringsForSelector: 'size'
		rootClassName: 'Object'
		scope: 'super'.

	self assert: implementors equals: #('Object>>size' 'Object class>>new').
	self assert: senders equals: #('Collection>>includes:')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadeBuildsExpectedVersionEntries [
	| mockSession holders |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'cls classHistory').
		self assert: (script includesSubstring: '''Invoice''').
		#(
			#(1000 'Invoice' 1 2)
			#(1008 'Invoice' 2 2)) ].

	holders := (mockSession classHistoryOf: 'Invoice') holders.

	self assert: holders size equals: 2.
	self assert: holders first name equals: 'Invoice'.
	self assert: holders first proxy oop equals: 1008.
	self assert: holders first version equals: 2.
	self assert: holders second proxy oop equals: 1000
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadeCanMigrateWhenMultipleVersionsExist [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'cls classHistory').
		#(
			#(1000 'Invoice' 1 2)
			#(1008 'Invoice' 2 2)) ].

	result := (mockSession classHistoryOf: 'Invoice') canMigrateInstances.

	self assert: result
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadePreviewMigrationToBuildsExpectedPlan [
	| mockSession plan entry |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'compiledMethodAt:') ifTrue: [ self fail ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: 'SystemRepository listInstances: { fromClass }') ifTrue: [
			self assert: (script includesSubstring: '''Invoice''').
			^ #(
				#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].
		self fail ].

	plan := (mockSession classHistoryOf: 'OldInvoice')
		previewMigrationTo: 'Invoice'.
	entry := plan entries first.

	self assert: plan class equals: GbsMigrationPlan.
	self deny: plan includesSubclasses.
	self assert: plan totalInstanceCount equals: 4.
	self assert: plan affectedClassCount equals: 1.
	self assert: entry sourceName equals: 'OldInvoice'.
	self assert: entry sourceVersion equals: 1.
	self assert: entry sourceNumberOfVersions equals: 2.
	self assert: entry targetName equals: 'Invoice'.
	self assert: entry targetProxy oop equals: 1008.
	self assert: entry instanceCount equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadePreviewOldVersionsToLatestBuildsExpectedPlan [
	| mockSession plan |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'Invoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: 'withAllSubclasses') ifTrue: [
			^ #(
				#(1000 'Invoice' 1 2 1008 'Invoice' 0)
				#(1010 'OldReceipt' 1 3 1018 'Receipt' 5)) ].
		self fail ].

	plan := (mockSession classHistoryOf: 'Invoice')
		previewOldVersionsToLatest.

	self assert: plan includesSubclasses.
	self assert: plan entries size equals: 2.
	self assert: plan totalInstanceCount equals: 5.
	self assert: plan affectedClassCount equals: 1.
	self assert: plan hasAffectedInstances.
	self assert: (plan sourceNames includes: 'Invoice').
	self assert: (plan sourceNames includes: 'OldReceipt').
	self assert: (plan targetNames includes: 'Receipt')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadeExecutePreviewPlanDelegatesToMigrationOperation [
	| mockSession plan result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: 'SystemRepository listInstances: { fromClass }') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].
		(script includesSubstring: 'fromClass migrateInstances: instances to: toClass') ifTrue: [
			^ 4 ].
		self fail ].

	plan := (mockSession classHistoryOf: 'OldInvoice')
		previewMigrationTo: 'Invoice'.
	result := (mockSession classHistoryOf: 'OldInvoice')
		executePreviewPlan: plan.

	self assert: result equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassHistoryFacadeRemoveOldVersionBindingsFromLocalDictionary [
	| mockSession history dictionary removed |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		self fail ].

	history := mockSession classHistoryOf: 'OldInvoice'.
	dictionary := Dictionary new
		at: 'OldInvoice' put: #old;
		at: 'Invoice' put: #current;
		yourself.
	removed := history removeOldVersionBindingsFrom: dictionary.

	self assert: removed equals: #('OldInvoice').
	self deny: (dictionary includesKey: 'OldInvoice').
	self assert: (dictionary at: 'Invoice') equals: #current
]

{ #category : 'tests' }
GbsSessionCoreTest >> testMigrationPlanImpactSummaryStringIncludesScopeAndEntries [
	| plan summary |
	plan := GbsMigrationPlan new
		entries: {
			(GbsMigrationPlanEntry
				sourceName: 'OldReceipt'
				proxy: nil
				version: 1
				numberOfVersions: 3
				targetName: 'Receipt'
				targetProxy: nil
				count: 5).
			(GbsMigrationPlanEntry
				sourceName: 'Invoice'
				proxy: nil
				version: 1
				numberOfVersions: 2
				targetName: 'Invoice'
				targetProxy: nil
				count: 0) };
		includesSubclasses: true;
		yourself.

	summary := plan impactSummaryString.

	self assert: (summary includesSubstring: '5 instances across 1 classes').
	self assert: (summary includesSubstring: 'including subclasses').
	self assert: (summary includesSubstring: 'OldReceipt -> Receipt (5 instances)')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassVersionBrowserPreviewMigrationToLatestBuildsExpectedPlan [
	| mockSession browser plan |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: 'SystemRepository listInstances: { fromClass }') ifTrue: [
			self assert: (script includesSubstring: '1008').
			^ #(
				#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].
		self fail ].

	browser := GbxClassVersionBrowser new
		classHistory: (mockSession classHistoryOf: 'OldInvoice');
		yourself.
	plan := browser previewMigrationToLatestAllowAbort: false.

	self assert: plan class equals: GbsMigrationPlan.
	self deny: plan includesSubclasses.
	self assert: plan totalInstanceCount equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testClassVersionBrowserExecutePreviewPlanAndRemoveOldBindings [
	| mockSession browser plan result dictionary removed |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		(script includesSubstring: 'cls classHistory') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2)
				#(1008 'Invoice' 2 2)) ].
		(script includesSubstring: 'SystemRepository listInstances: { fromClass }') ifTrue: [
			^ #(
				#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].
		(script includesSubstring: 'fromClass migrateInstances: instances to: toClass') ifTrue: [
			^ 4 ].
		self fail ].

	browser := GbxClassVersionBrowser new
		classHistory: (mockSession classHistoryOf: 'OldInvoice');
		yourself.
	plan := browser previewMigrationToLatestAllowAbort: false.
	result := browser executePreviewPlan: plan allowAbort: false.
	dictionary := Dictionary new
		at: 'OldInvoice' put: #old;
		at: 'Invoice' put: #current;
		yourself.
	removed := browser removeOldVersionBindingsFrom: dictionary.

	self assert: result equals: 4.
	self assert: removed equals: #('OldInvoice').
	self deny: (dictionary includesKey: 'OldInvoice')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryAllInstancesOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'cls allInstances').
		self assert: (script includesSubstring: 'objectNamed: clsName asSymbol').
		self assert: (script includesSubstring: '''Invoice''').
		#(1 2 3) ].

	result := mockSession repository allInstancesOfNamed: 'Invoice'.

	self assert: result equals: #(1 2 3)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryListInstancesOfNamedBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'SystemRepository listInstances: { cls }').
		self assert: (script includesSubstring: '''Invoice''').
		#(3 4 5) ].

	result := mockSession repository listInstancesOfNamed: 'Invoice'.

	self assert: result equals: #(3 4 5)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryListInstancesOfNamedWithLimitBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'limit: limitValue').
		self assert: (script includesSubstring: 'value: 25').
		#(7 8) ].

	result := mockSession repository listInstancesOfNamed: 'Invoice' limit: 25.

	self assert: result equals: #(7 8)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryListInstancesRefusesAbortWhenSessionIsDirty [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit')
			ifTrue: [ ^ true ].
		self fail ].

	self
		should: [ mockSession repository listInstancesOfNamed: 'Invoice' ]
		raise: GbsError
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryListInstancesAllowsAbortWhenSessionIsDirty [
	| mockSession aborted result |
	mockSession := CoreMockGbsSession new.
	aborted := false.
	mockSession stubs at: #gciAbort put: [ aborted := true. 1 ].
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit')
			ifTrue: [ ^ true ].
		self assert: aborted.
		self assert: (script includesSubstring: 'SystemRepository listInstances: { cls }').
		#(11 12) ].

	result := mockSession repository listInstancesOfNamed: 'Invoice' allowAbort: true.

	self assert: aborted.
	self assert: result equals: #(11 12)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMigrateInstancesFromToBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'SystemRepository listInstances: { fromClass }').
		self assert: (script includesSubstring: 'fromClass migrateInstances: instances to: toClass').
		self assert: (script includesSubstring: '''OldInvoice''').
		self assert: (script includesSubstring: '''Invoice''').
		4 ].

	result := mockSession migrateInstancesFrom: 'OldInvoice' to: 'Invoice'.

	self assert: result equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryPreviewMigrationFromToBuildsExpectedPlan [
	| mockSession plan entry |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'SystemRepository listInstances: { fromClass }').
		self assert: (script includesSubstring: '''OldInvoice''').
		self assert: (script includesSubstring: '''Invoice''').
		#(
			#(1000 'OldInvoice' 1 2 1008 'Invoice' 4)) ].

	plan := mockSession repository
		previewMigrationFrom: 'OldInvoice'
		to: 'Invoice'.
	entry := plan entries first.

	self assert: plan class equals: GbsMigrationPlan.
	self deny: plan includesSubclasses.
	self assert: plan totalInstanceCount equals: 4.
	self assert: entry sourceName equals: 'OldInvoice'.
	self assert: entry targetName equals: 'Invoice'.
	self assert: entry instanceCount equals: 4
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryPreviewMigrationWithSubclassesBuildsExpectedPlan [
	| mockSession plan |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'withAllSubclasses').
		self assert: (script includesSubstring: 'SystemRepository listInstances: oldClasses asArray').
		#(
			#(1000 'OldInvoice' 1 2 1008 'Invoice' 0)
			#(1010 'OldReceipt' 1 3 1018 'Receipt' 5)) ].

	plan := mockSession repository previewMigrationWithSubclassesOf: 'Invoice'.

	self assert: plan includesSubclasses.
	self assert: plan entries size equals: 2.
	self assert: plan totalInstanceCount equals: 5.
	self assert: plan affectedClassCount equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryMigrateInstancesWithSubclassesBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: '#needsCommit') ifTrue: [ ^ false ].
		self assert: (script includesSubstring: 'withAllSubclasses').
		self assert: (script includesSubstring: 'SystemRepository listInstances: oldClasses asArray').
		self assert: (script includesSubstring: '''Invoice''').
		6 ].

	result := mockSession migrateInstancesWithSubclassesOf: 'Invoice'.

	self assert: result equals: 6
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryAllInstancesOopOfNamedUsesRawServerOop [
	| mockSession oop |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #apiGciExecuteStrContextEnv put: [ :script :context :env |
		self assert: context equals: 20.
		self assert: env equals: 0.
		self assert: (script includesSubstring: 'cls allInstances').
		9876 ].

	oop := mockSession repository allInstancesOopOfNamed: 'Invoice'.

	self assert: oop equals: 9876
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryClassHistoryOfRetainsSessionAndReference [
	| mockSession history |
	mockSession := CoreMockGbsSession new.

	history := mockSession repository classHistoryOf: 'Invoice'.

	self assert: history class equals: GbsClassHistoryFacade.
	self assert: history session == mockSession.
	self assert: history classReference equals: 'Invoice'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryFacadeRetainsSession [
	| mockSession facade |
	mockSession := CoreMockGbsSession new.

	facade := mockSession repository.

	self assert: facade class equals: GbsRepositoryFacade.
	self assert: facade session == mockSession
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootReturnsRootFacade [
	| mockSession root |
	mockSession := CoreMockGbsSession new.

	root := mockSession repository root.

	self assert: root class equals: GbsRepositoryRootFacade.
	self assert: root session == mockSession.
	self assert: root rootKey equals: #GbsBridgeRoot.
	self assert: root path isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootFacadeIsMemoizedUntilInvalidation [
	| mockSession first second third |
	mockSession := CoreMockGbsSession new.

	first := mockSession repository root.
	second := mockSession repository root.
	mockSession invalidateRepositoryRoots.
	third := mockSession repository root.

	self assert: first == second.
	self deny: third == first
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryLoadedClassesUsesVisibleBehaviorScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'value isBehavior').
		#('Account' 'Invoice') ].

	result := mockSession repository loadedClasses.

	self assert: result equals: #('Account' 'Invoice')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootAtIfAbsentEvaluatesFallback [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: ((script includesSubstring: '#GbsBridgeRoot')
			or: [ script includesSubstring: '''GbsBridgeRoot'' asSymbol' ]).
		self assert: (script includesSubstring: 'at: key ifAbsent: [ nil ]').
		nil ].

	result := mockSession repository rootAt: #missing ifAbsent: [ #fallback ].

	self assert: result equals: #fallback
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootAtPutBuildsExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: ((script includesSubstring: '#GbsBridgeRoot')
			or: [ script includesSubstring: '''GbsBridgeRoot'' asSymbol' ]).
		self assert: (script includesSubstring: 'container at: key put: value').
		self assert: ((script includesSubstring: '#ticket')
			or: [ script includesSubstring: '''ticket'' asSymbol' ]).
		self assert: (script includesSubstring: '''vip''').
		'vip' ].

	result := mockSession repository rootAt: #ticket put: 'vip'.

	self assert: result equals: 'vip'
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootProxyUsesRootScriptAndReturnsProxy [
	| mockSession root result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: ((script includesSubstring: '#GbsBridgeRoot')
			or: [ script includesSubstring: '''GbsBridgeRoot'' asSymbol' ]).
		2001 ].
	root := mockSession repository root.

	result := root proxy.

	self assert: result oop equals: 2001.
	self assert: result session == mockSession
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootProxyRefreshesAfterInvalidation [
	| mockSession root first second oops |
	mockSession := CoreMockGbsSession new.
	oops := #(2001 2002) readStream.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: ((script includesSubstring: '#GbsBridgeRoot')
			or: [ script includesSubstring: '''GbsBridgeRoot'' asSymbol' ]).
		oops next ].
	root := mockSession repository root.

	first := root proxy.
	mockSession invalidateRepositoryRoots.
	second := root proxy.

	self assert: first oop equals: 2001.
	self assert: second oop equals: 2002.
	self deny: second == first
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootKeysBuildExpectedScript [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: ((script includesSubstring: '#GbsBridgeRoot')
			or: [ script includesSubstring: '''GbsBridgeRoot'' asSymbol' ]).
		self assert: (script includesSubstring: 'container keys asArray').
		#(#tickets #users) ].

	result := mockSession repository root keys.

	self assert: result equals: #(#tickets #users)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootEnsureNamespaceAtReturnsNestedFacade [
	| mockSession namespace |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'at: key ifAbsentPut: [ Dictionary new ]').
		self assert: ((script includesSubstring: '#tickets')
			or: [ script includesSubstring: '''tickets'' asSymbol' ]).
		true ].

	namespace := (mockSession repository root) ensureNamespaceAt: #tickets.

	self assert: namespace class equals: GbsRepositoryRootFacade.
	self assert: namespace rootKey equals: #GbsBridgeRoot.
	self assert: namespace path equals: #(#tickets)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootNamespaceFacadeUsesSessionCache [
	| mockSession first second |
	mockSession := CoreMockGbsSession new.

	first := (mockSession repository root) namespaceFacadeAt: #tickets.
	second := (mockSession repository root) namespaceFacadeAt: #tickets.

	self assert: first == second.
	self assert: first path equals: #(#tickets)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootNamespaceAtIfAbsentEvaluatesFallback [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'value isKindOf: Dictionary').
		self assert: ((script includesSubstring: '#tickets')
			or: [ script includesSubstring: '''tickets'' asSymbol' ]).
		false ].

	result := (mockSession repository root)
		namespaceAt: #tickets
		ifAbsent: [ #fallback ].

	self assert: result equals: #fallback
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepositoryRootWithReadLockDoLocksAndUnlocksContainer [
	| mockSession root scripts result seenFacade seenProxy |
	mockSession := CoreMockGbsSession new.
	scripts := OrderedCollection new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: ((script includesSubstring: '#GbsBridgeRoot')
			or: [ script includesSubstring: '''GbsBridgeRoot'' asSymbol' ]).
		4001 ].
	mockSession stubs at: #execute put: [ :script |
		scripts add: script.
		true ].
	root := mockSession repository root.

	result := root withReadLockDo: [ :facade :proxy |
		seenFacade := facade.
		seenProxy := proxy.
		#done ].

	self assert: result equals: #done.
	self assert: seenFacade == root.
	self assert: seenProxy oop equals: 4001.
	self assert: scripts size equals: 2.
	self assert: (scripts first includesSubstring: 'System perform: #readLock:').
	self assert: (scripts second includesSubstring: 'System perform: #removeLock:')
]

{ #category : 'tests' }
GbsSessionCoreTest >> testCommitTransactionInvalidatesRepositoryRoots [
	| mockSession first second |
	mockSession := CoreMockGbsSession new.
	first := mockSession repository root.

	self assert: mockSession commitTransaction.
	second := mockSession repository root.

	self deny: second == first.
	self assert: mockSession repositoryRootLifecycleVersion equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testAbortTransactionInvalidatesRepositoryRoots [
	| mockSession first second |
	mockSession := CoreMockGbsSession new.
	first := mockSession repository root.

	self assert: mockSession abortTransaction.
	second := mockSession repository root.

	self deny: second == first.
	self assert: mockSession repositoryRootLifecycleVersion equals: 1
]

{ #category : 'tests' }
GbsSessionCoreTest >> testAbortTransactionDrainsPendingGciError [
	| mockSession drained |
	mockSession := CoreMockGbsSession new.
	drained := false.
	mockSession stubs at: #checkForError put: [ drained := true ].

	self assert: mockSession abortTransaction.
	self assert: drained
]

{ #category : 'tests' }
GbsSessionCoreTest >> testCommitTransactionClearsDirtyReplicatesAndMaterializedIdentity [
	| mockSession first second |
	mockSession := self materializationMockSession.
	mockSession fetchDeep.
	first := mockSession fetchObject: 9000.
	first at: 1 put: 'changed'.
	self assert: (mockSession dirtyMaterializedObjectOops asSet includes: 9000).

	self assert: mockSession commitTransaction.
	second := mockSession fetchObject: 9000.

	self assert: mockSession dirtyMaterializedObjectOops isEmpty.
	self deny: second == first
]

{ #category : 'tests' }
GbsSessionCoreTest >> testAbortTransactionClearsDirtyReplicatesAndMaterializedIdentity [
	| mockSession first second |
	mockSession := self materializationMockSession.
	mockSession fetchDeep.
	first := mockSession fetchObject: 9000.
	first at: 1 put: 'changed'.
	self assert: (mockSession dirtyMaterializedObjectOops asSet includes: 9000).

	self assert: mockSession abortTransaction.
	second := mockSession fetchObject: 9000.

	self assert: mockSession dirtyMaterializedObjectOops isEmpty.
	self deny: second == first
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFailedCommitKeepsDirtyReplicatesAndMaterializedIdentity [
	| mockSession first second |
	mockSession := self materializationMockSession.
	mockSession stubs at: #gciCommit put: 0.
	mockSession fetchDeep.
	first := mockSession fetchObject: 9000.
	first at: 1 put: 'changed'.

	self deny: mockSession commitTransaction.
	second := mockSession fetchObject: 9000.

	self assert: (mockSession dirtyMaterializedObjectOops asSet includes: 9000).
	self assert: second == first
]

{ #category : 'tests' }
GbsSessionCoreTest >> testExecuteScriptAndReturnOopUsesServerInterface [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #apiGciExecuteStrContextEnv put: [ :script :context :env |
		self assert: script equals: '42'.
		self assert: context equals: 20.
		self assert: env equals: 0.
		123456 ].

	result := mockSession executeScriptAndReturnOop: '42'.

	self assert: result equals: 123456
]

{ #category : 'tests' }
GbsSessionCoreTest >> testLogoutClearsProxyIdentityMap [
	| mockSession proxy |
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciLogout put: nil.
	proxy := mockSession resultFor: 1001.

	self assert: (mockSession cachedProxyForOop: 1001) == proxy.

	mockSession logout.

	self assert: (mockSession cachedProxyForOop: 1001) isNil
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFailedLoginLeavesSessionLoggedOut [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #gciLogin put: false.

	self
		should: [ mockSession loginStone: 'gs64stone' user: 'DataCurator' password: 'bad' ]
		raise: GbsError.
	self deny: mockSession isLoggedIn
]

{ #category : 'tests' }
GbsSessionCoreTest >> testSuccessfulLoginStartsEventControllerWhenConfigured [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #gciInit put: true.
	mockSession stubs at: #gciLogin put: true.
	(GbsReplicationPolicy forSession: mockSession) asyncSignalPollingEnabled: true.

	self
		assert: (mockSession loginStone: 'gs64stone' user: 'DataCurator' password: 'secret')
		equals: true.
	self assert: mockSession isLoggedIn.
	self assert: (GbsSessionEventController isPollingActiveForSession: mockSession)
]

{ #category : 'tests' }
GbsSessionCoreTest >> testProxyForwardingAfterDisconnectSignalsClearError [
	| mockSession proxy |
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	proxy := GbsProxy oop: 1001 session: mockSession.

	mockSession resetAfterLogout.

	self
		should: [ proxy size ]
		raise: GbsError
		withExceptionDo: [ :ex |
			self assert: (ex messageText includesSubstring: 'disconnected') ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReconnectCreatesFreshProxyIdentityMap [
	| mockSession first second |
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	first := mockSession resultFor: 1001.

	mockSession resetAfterLogout.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	second := mockSession resultFor: 1001.

	self deny: second == first.
	self assert: second session == mockSession
]

{ #category : 'tests' }
GbsSessionCoreTest >> testOldProxyAfterReconnectSignalsStaleLifecycleError [
	| mockSession oldProxy |
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	oldProxy := mockSession resultFor: 1001.

	mockSession resetAfterLogout.
	mockSession instVarNamed: 'isLoggedIn' put: true.

	self
		should: [ oldProxy ensureSessionIsUsable ]
		raise: GbsError
		withExceptionDo: [ :ex |
			self assert: (ex messageText includesSubstring: 'previous session lifecycle') ]
]

{ #category : 'tests' }
GbsSessionCoreTest >> testFreshProxyAfterReconnectUsesCurrentLifecycle [
	| mockSession proxy |
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	proxy := mockSession resultFor: 1001.

	mockSession resetAfterLogout.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	proxy := mockSession resultFor: 1001.

	self assert: proxy ensureSessionIsUsable
]

{ #category : 'tests' }
GbsSessionCoreTest >> testResetAfterLogoutClearsProxyCacheAndMaterializationMetrics [
	| mockSession proxy |
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	proxy := mockSession resultFor: 1001.
	mockSession materializationMetrics at: #slotBatchCalls put: 3.

	self assert: (mockSession cachedProxyForOop: 1001) == proxy.
	self deny: mockSession materializationMetrics isEmpty.

	mockSession resetAfterLogout.

	self assert: (mockSession cachedProxyForOop: 1001) isNil.
	self assert: mockSession materializationMetrics isEmpty
]

{ #category : 'tests' }
GbsSessionCoreTest >> testRepeatedReconnectCyclesDoNotAccumulateProxyCacheEntries [
	| mockSession proxy oop |
	mockSession := CoreMockGbsSession new.
	1 to: 3 do: [ :index |
		mockSession instVarNamed: 'isLoggedIn' put: true.
		oop := 1001 + (index * 8).
		proxy := mockSession resultFor: oop.
		self assert: proxy session == mockSession.
		self assert: (mockSession cachedProxyForOop: oop) == proxy.
		mockSession resetAfterLogout.
		self assert: (mockSession cachedProxyForOop: oop) isNil ].
]

{ #category : 'tests' }
GbsSessionCoreTest >> testResetAfterLogoutClearsConvertedLifecycleRegistriesWhenCoreLoaded [
	| mockSession dirtyPool replicatorManager traversal |
	mockSession := CoreMockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	traversal := Object new.
	mockSession addStoreTraversal: traversal.
	dirtyPool := mockSession dirtyPool.
	replicatorManager := mockSession replicatorManager.
	mockSession class notificationActionFor: mockSession put: [ #notification ].
	mockSession class sessionSignalActionFor: mockSession put: [ #signal ].
	mockSession class signaledAbortActionFor: mockSession put: [ #abort ].

	mockSession resetAfterLogout.

	self deny: mockSession dirtyPool == dirtyPool.
	self deny: mockSession replicatorManager == replicatorManager.
	self deny: (mockSession activeStoreTraversals includes: traversal).
	self assert: (mockSession class notificationActionFor: mockSession) isNil.
	self assert: (mockSession class sessionSignalActionFor: mockSession) isNil.
	self assert: (mockSession class signaledAbortActionFor: mockSession) isNil
]

{ #category : 'tests' }
GbsSessionCoreTest >> testReadAndWriteLockUseCompatibilityScripts [
	| mockSession scripts |
	mockSession := CoreMockGbsSession new.
	scripts := OrderedCollection new.
	mockSession stubs at: #execute put: [ :script |
		scripts add: script.
		true ].

	self assert: (mockSession readLock: #seat42) == mockSession.
	self assert: (mockSession writeLock: #seat42) == mockSession.
	self
		assert: scripts asArray
		equals: {
			(mockSession systemCallScriptForSelector: #readLock: arguments: { #seat42 }).
			(mockSession systemCallScriptForSelector: #writeLock: arguments: { #seat42 }) }
]
