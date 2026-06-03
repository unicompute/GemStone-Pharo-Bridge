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
GbsServerInterface >> apiGciReleaseOops: oopBuffer count: oopCount [
	^ self
		ffiCall: #(void GciReleaseOops(void* oopBuffer, int oopCount))
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
GbsServerInterface >> supportsDirtyStoreTraversalBufferTransport [
	^ true
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsClampedTraversalTransport [
	^ (self respondsTo: #apiGciClampedTravOops:count:spec:)
		and: [ (self respondsTo: #apiGciAllocTravBuf:)
		and: [ (self respondsTo: #apiGciMoreTraversal:)
		and: [ self respondsTo: #apiGciFree: ] ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsNoLongerReplicatedStoreTraversalTransport [
	^ (self respondsTo: #apiGciStoreTravDoTravRefsNlr:nnr:ogoc:ngc:stdArgs:ctArgs:)
		and: [ self respondsTo: #apiGciAllocTravBuf: ]
]

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> supportsReleaseOopsTransport [
	^ true
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
