Extension { #name : 'GbsServerInterface' }

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciAllocTravBuf: byteCount [
	^ self
		ffiCall: #(void* GciAllocTravBuf(uint64 byteCount))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciDirtyObjsInit [
	^ self
		ffiCall: #(void GciDirtyObjsInit())
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciClampedTravOops: oopBuffer count: oopCount spec: clampedTraversalArgs [
	^ self
		ffiCall: #(int GciClampedTrav(void* oopBuffer, int oopCount, void* clampedTraversalArgs))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciFetchNameOfClass: classOop [
	^ self
		ffiCall: #(uint64 GciFetchNameOfClass(uint64 classOop))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciFree: anExternalAddress [
	^ self
		ffiCall: #(void GciFree(void* anExternalAddress))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciGetFreeOops: oopCount into: oopBuffer [
	^ self
		ffiCall: #(void GciGetFreeOops(int oopCount, void* oopBuffer))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciGetSessionId [
	^ self
		ffiCall: #(int GciGetSessionId())
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciGetClass: anOop [
	^ self
		ffiCall: #(uint64 GciFetchClass(uint64 anOop))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciMoreTraversal: traversalBuffer [
	^ self
		ffiCall: #(int GciMoreTraversal(void* traversalBuffer))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciNewString: aString [
	^ self
		ffiCall: #(uint64 GciNewString(String aString))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciNewSymbol: aString [
	^ self
		ffiCall: #(uint64 GciNewSymbol(String aString))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciReleaseOops: oopBuffer count: oopCount [
	^ self
		ffiCall: #(void GciReleaseOops(void* oopBuffer, int oopCount))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciSetSessionId: sessionId [
	^ self
		ffiCall: #(int GciSetSessionId_(int sessionId))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciStoreTrav: traversalBuffer flags: flags [
	^ self
		ffiCall: #(void GciStoreTrav(void *traversalBuffer, int flags))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciStoreTravDoTravRefsNlr: noLongerBuffer nnr: noLongerCount ogoc: gcedBuffer ngc: gcedCount stdArgs: stdArgs ctArgs: ctArgs [
	^ self
		ffiCall: #(int GciStoreTravDoTravRefs_(void* noLongerBuffer, int noLongerCount, void* gcedBuffer, int gcedCount, void* stdArgs, void* ctArgs))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciTraverseOops: oopBuffer count: oopCount into: traversalBuffer level: traversalLevel [
	^ self
		ffiCall: #(int GciTraverseObjs(void* oopBuffer, int oopCount, void* traversalBuffer, int traversalLevel))
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> ensureDirtyObjectsInitialized [
	dirtyObjectsInitialized == true ifTrue: [ ^ true ].
	self apiGciDirtyObjsInit.
	dirtyObjectsInitialized := true.
	^ true
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> resetDirtyObjectsInitialization [
	dirtyObjectsInitialized := false
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> getFreeOops: oopCount [
	| buffer oops |
	oopCount <= 0 ifTrue: [ ^ #() ].
	(self supportsFreeOopAllocationTransport) ifFalse: [
		GbsError signal: 'GCI free-OOP allocation transport is not available.' ].
	buffer := ExternalAddress allocate: oopCount * 8.
	^ [
		self apiGciGetFreeOops: oopCount into: buffer.
		oops := (1 to: oopCount) collect: [ :index |
			(buffer integerAt: 1 + ((index - 1) * 8) size: 8 signed: false) asInteger ].
		oops asArray
	] ensure: [ buffer free ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> storeTraversalBuffer: aBuffer [
	(aBuffer respondsTo: #withNativeTraversalBufferOn:do:) ifFalse: [
		GbsError signal: 'Dirty store traversal buffer is not backed by a native GCI traversal buffer.' ].
	self ensureDirtyObjectsInitialized.
	^ aBuffer
		withNativeTraversalBufferOn: self
		do: [ :nativeBuffer |
			self apiGciStoreTrav: nativeBuffer flags: aBuffer flags ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> storeTraversalBuffer: aBuffer releasingNoLongerReplicatedOops: oopCollection [
	^ self
		storeTraversalBuffer: aBuffer
		releasingNoLongerReplicatedOops: oopCollection
		gcedOops: #()
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> storeTraversalBuffer: aBuffer releasingNoLongerReplicatedOops: noLongerOopCollection gcedOops: gcedOopCollection [
	| arguments result |
	(aBuffer respondsTo: #withNativeTraversalBufferOn:do:) ifFalse: [
		GbsError signal: 'Dirty store traversal buffer is not backed by a native GCI traversal buffer.' ].
	self ensureDirtyObjectsInitialized.
	arguments := GbsStoreTravDoTravRefsArguments
		storeTraversalBuffer: aBuffer
		noLongerReplicatedOops: noLongerOopCollection
		gcedOops: gcedOopCollection
		flags: aBuffer flags.
	result := arguments
		withNativeBuffersOn: self
		do: [ :noLongerBuffer :noLongerCount :gcedBuffer :gcedCount :stdArgs :ctArgs |
			self
				apiGciStoreTravDoTravRefsNlr: noLongerBuffer
				nnr: noLongerCount
				ogoc: gcedBuffer
				ngc: gcedCount
				stdArgs: stdArgs
				ctArgs: ctArgs ].
	result = 1 ifFalse: [
		GbsError signal: 'GciStoreTravDoTravRefs_ failed.' ].
	^ result
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> releaseOops: oopCollection [
	oopCollection isEmpty ifTrue: [ ^ oopCollection asArray ].
	self
		withOopBufferFor: oopCollection
		do: [ :oopBuffer |
			self apiGciReleaseOops: oopBuffer count: oopCollection size ].
	^ oopCollection asArray
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> nativeGciTransportsEnabled [
	| environment disabled |
	environment := [ Smalltalk os environment ] on: Error do: [ nil ].
	environment ifNil: [ ^ true ].
	disabled := [ environment at: 'GBS_DISABLE_NATIVE_GCI_TRANSPORT' ifAbsent: [ '0' ] ]
		on: Error
		do: [ '0' ].
	^ disabled asString ~= '1'
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsNativeStoreTraversalStructLayout [
	| wordSize |
	wordSize := [ Smalltalk vm wordSize ] on: Error do: [ 8 ].
	^ wordSize = 8
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> nativeStoreTraversalStructLayoutDiagnostics [
	^ Dictionary new
		at: #wordSizeBytes put: ([ Smalltalk vm wordSize ] on: Error do: [ 8 ]);
		at: #oopWidth put: self nativeGciOopWidth;
		at: #expectedOopWidth put: 64;
		at: #bufferHeaderBytes put: 8;
		at: #objectReportHeaderBytes put: 40;
		at: #objectSecurityPolicyIdOffset put: 6;
		at: #storeTravDoTravRefsArgsBytes put: 104;
		at: #clampedTraversalArgsBytes put: 40;
		at: #structLayoutSupported put: self supportsNativeStoreTraversalStructLayout;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> nativeStoreTraversalReportShape [
	^ Dictionary new
		at: #bufferHeaderBytes put: 8;
		at: #objectReportHeaderBytes put: 40;
		at: #oopBytes put: 8;
		at: #pointerObjectFormat put: 0;
		at: #nonSequenceableCollectionObjectFormat put: 2;
		at: #setNamedSize put: 5;
		at: #bagNamedSize put: 6;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> materializationTraversalReportShape [
	^ Dictionary new
		at: #bufferHeaderBytes put: 8;
		at: #objectReportHeaderBytes put: 40;
		at: #oopBytes put: 8;
		at: #pointerObjectFormat put: 0;
		at: #byteObjectFormat put: 1;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsMaterializationTraversalReportShape [
	| shape |
	self supportsNativeStoreTraversalStructLayout ifFalse: [ ^ false ].
	self nativeGciOopWidth = 64 ifFalse: [ ^ false ].
	shape := self materializationTraversalReportShape.
	^ (shape at: #bufferHeaderBytes ifAbsent: [ 0 ]) = 8
		and: [ (shape at: #objectReportHeaderBytes ifAbsent: [ 0 ]) = 40
		and: [ (shape at: #oopBytes ifAbsent: [ 0 ]) = 8
		and: [ (shape at: #pointerObjectFormat ifAbsent: [ -1 ]) = 0
		and: [ (shape at: #byteObjectFormat ifAbsent: [ -1 ]) = 1 ] ] ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsNativeStoreTraversalReportShape [
	| shape |
	self supportsNativeStoreTraversalStructLayout ifFalse: [ ^ false ].
	self nativeGciOopWidth = 64 ifFalse: [ ^ false ].
	shape := self nativeStoreTraversalReportShape.
	^ (shape at: #bufferHeaderBytes ifAbsent: [ 0 ]) = 8
		and: [ (shape at: #objectReportHeaderBytes ifAbsent: [ 0 ]) = 40
		and: [ (shape at: #oopBytes ifAbsent: [ 0 ]) = 8
		and: [ (shape at: #setNamedSize ifAbsent: [ 0 ]) = 5
		and: [ (shape at: #bagNamedSize ifAbsent: [ 0 ]) = 6 ] ] ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> nativeGciOopWidth [
	^ ([ Smalltalk vm wordSize ] on: Error do: [ 8 ]) * 8
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> nativeStoreTraversalCapabilityReport [
		^ Dictionary new
			at: #nativeGciTransportsEnabled put: self nativeGciTransportsEnabled;
			at: #oopWidth put: self nativeGciOopWidth;
			at: #storeTraversalStructLayoutSupported put: self supportsNativeStoreTraversalStructLayout;
			at: #storeTraversalStructLayoutDiagnostics put: self nativeStoreTraversalStructLayoutDiagnostics;
			at: #storeTraversalReportShapeSupported put: self supportsNativeStoreTraversalReportShape;
			at: #storeTraversalReportShape put: self nativeStoreTraversalReportShape;
			at: #materializationTraversalReportShapeSupported put: self supportsMaterializationTraversalReportShape;
			at: #dictionaryAssociationMetadataTraversalSupported put: self supportsDictionaryAssociationMetadataTraversal;
			at: #scalarOopNativeResolutionSupported put: self supportsNativeScalarOopResolution;
			at: #scalarOopCommandFallbackRequired put: self supportsNativeScalarOopResolution not;
			at: #dirtyStoreTraversalFunctionsSupported put: self supportsNativeDirtyStoreTraversalFunctions;
			at: #freeOopAllocationSupported put: self supportsFreeOopAllocationTransport;
			at: #dirtyStoreTraversalBufferTransportSupported put: self supportsDirtyStoreTraversalBufferTransport;
			at: #noLongerReplicatedStoreTraversalTransportSupported put: self supportsNoLongerReplicatedStoreTraversalTransport;
			yourself
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> nativeMaterializationTraversalCapabilityReport [
	^ Dictionary new
		at: #nativeGciTransportsEnabled put: self nativeGciTransportsEnabled;
		at: #oopWidth put: self nativeGciOopWidth;
		at: #traversalStructLayoutSupported put: self supportsNativeStoreTraversalStructLayout;
		at: #materializationTraversalReportShapeSupported put: self supportsMaterializationTraversalReportShape;
		at: #materializationTraversalReportShape put: self materializationTraversalReportShape;
		at: #traversalBufferAllocationSupported put: ((self respondsTo: #apiGciAllocTravBuf:) and: [ self respondsTo: #apiGciFree: ]);
		at: #plainTraversalSupported put: (self respondsTo: #apiGciTraverseOops:count:into:level:);
		at: #moreTraversalSupported put: (self respondsTo: #apiGciMoreTraversal:);
		at: #clampedTraversalSupported put: self supportsClampedTraversalTransport;
		at: #materializationTraversalBufferTransportSupported put: self supportsMaterializationTraversalBufferTransport;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsNativeDirtyStoreTraversalFunctions [
	^ (self respondsTo: #apiGciStoreTrav:flags:)
		and: [ (self respondsTo: #apiGciDirtyObjsInit)
		and: [ (self respondsTo: #apiGciAllocTravBuf:)
		and: [ self respondsTo: #apiGciFree: ] ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsNativeScalarOopResolution [
	^ self nativeGciTransportsEnabled
		and: [ (self respondsTo: #apiGciNewString:)
		and: [ self respondsTo: #apiGciNewSymbol: ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsDirtyStoreTraversalBufferTransport [
	^ self nativeGciTransportsEnabled
		and: [ self supportsNativeStoreTraversalStructLayout
		and: [ self supportsNativeDirtyStoreTraversalFunctions ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsDictionaryAssociationMetadataTraversal [
	^ self supportsMaterializationTraversalBufferTransport
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsMaterializationTraversalBufferTransport [
	^ self nativeGciTransportsEnabled
		and: [ self supportsMaterializationTraversalReportShape
		and: [ (self respondsTo: #apiGciAllocTravBuf:)
		and: [ (self respondsTo: #apiGciTraverseOops:count:into:level:)
		and: [ (self respondsTo: #apiGciMoreTraversal:)
		and: [ self respondsTo: #apiGciFree: ] ] ] ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsFreeOopAllocationTransport [
	^ self nativeGciTransportsEnabled
		and: [ self nativeGciOopWidth = 64
		and: [ self respondsTo: #apiGciGetFreeOops:into: ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsClampedTraversalTransport [
	^ self nativeGciTransportsEnabled
		and: [ self supportsMaterializationTraversalReportShape
		and: [ (self respondsTo: #apiGciClampedTravOops:count:spec:)
		and: [ (self respondsTo: #apiGciAllocTravBuf:)
		and: [ (self respondsTo: #apiGciMoreTraversal:)
		and: [ self respondsTo: #apiGciFree: ] ] ] ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsNoLongerReplicatedStoreTraversalTransport [
	^ self nativeGciTransportsEnabled
		and: [ self supportsNativeStoreTraversalStructLayout
		and: [ (self respondsTo: #apiGciStoreTravDoTravRefsNlr:nnr:ogoc:ngc:stdArgs:ctArgs:)
		and: [ (self respondsTo: #apiGciAllocTravBuf:)
		and: [ self respondsTo: #apiGciFree: ] ] ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsReleaseOopsTransport [
	^ self nativeGciTransportsEnabled
		and: [ self respondsTo: #apiGciReleaseOops:count: ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> withOopBufferFor: oopCollection do: aBlock [
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
