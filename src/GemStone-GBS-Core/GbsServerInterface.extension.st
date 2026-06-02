Extension { #name : 'GbsServerInterface' }

{ #category : '*GemStone-GBS-Core' }
GbsServerInterface >> apiGciAllocTravBuf: byteCount [
	^ self
		ffiCall: #(void* GciAllocTravBuf(uint64 byteCount))
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
GbsServerInterface >> apiGciMoreTraversal: traversalBuffer [
	^ self
		ffiCall: #(int GciMoreTraversal(void* traversalBuffer))
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
