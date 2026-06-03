Class {
	#name : 'CoreMockGbsSession',
	#superclass : 'GbsSession',
	#instVars : [
		'stubs'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'initialization' }
CoreMockGbsSession >> initialize [
	super initialize.
	isLoggedIn := true
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciAllocTravBuf: byteCount [
	| block |
	block := self stubs at: #apiGciAllocTravBuf ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: byteCount ].
	^ ExternalAddress allocate: byteCount
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciClampedTravOops: oopBuffer count: oopCount spec: clampedTraversalArgs [
	| block |
	block := self stubs at: #apiGciClampedTravOops ifAbsent: [ nil ].
	block ifNotNil: [
		^ block cull: oopBuffer cull: oopCount cull: clampedTraversalArgs ].
	self error: 'No apiGciClampedTravOops stub configured.'
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciExecute: aString context: anInteger [
	"Intercept the actual FFI call used by execute:"
	| errBlock |
	errBlock := self stubs at: #executeError ifAbsent: [ nil ].
	errBlock ifNotNil: [ errBlock value ].
	^ self stubs at: #apiGciExecute ifAbsent: [ 268 ] "268 = true in GS64"
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciExecuteStr: scriptString context: contextOop env: envId [
	| block |
	block := self stubs at: #apiGciExecuteStrContextEnv ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: scriptString cull: contextOop cull: envId ].
	^ self stubs at: #apiGciExecuteStr ifAbsent: [ 20 ]
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciFetchOops: anOop startingAt: startIndex into: aBuffer size: numOops [
	| block |
	block := self stubs at: #apiGciFetchOops ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: anOop cull: startIndex cull: aBuffer cull: numOops ].
	self error: 'No apiGciFetchOops stub configured.'
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciFetchBytes: anOop startingAt: startIndex into: aBuffer size: numBytes [
	| block |
	block := self stubs at: #apiGciFetchBytes ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: anOop cull: startIndex cull: aBuffer cull: numBytes ].
	self error: 'No apiGciFetchBytes stub configured.'
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciFetchNameOfClass: classOop [
	| block |
	block := self stubs at: #apiGciFetchNameOfClass ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: classOop ].
	self error: 'No apiGciFetchNameOfClass stub configured.'
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciFetchSize: anOop [
	| block |
	block := self stubs at: #apiGciFetchSize ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: anOop ].
	self error: 'No apiGciFetchSize stub configured.'
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciFree: anExternalAddress [
	| block |
	block := self stubs at: #apiGciFree ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: anExternalAddress ].
	anExternalAddress free
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciGetClass: anOop [
	| block |
	block := self stubs at: #apiGciGetClass ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: anOop ].
	self error: 'No apiGciGetClass stub configured.'
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciMoreTraversal: traversalBuffer [
	| block |
	block := self stubs at: #apiGciMoreTraversal ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: traversalBuffer ].
	^ 1
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciReleaseOops: oopBuffer count: oopCount [
	| block |
	block := self stubs at: #apiGciReleaseOops ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: oopBuffer cull: oopCount ].
	^ true
]

{ #category : 'dirty store traversal' }
CoreMockGbsSession >> ensureDirtyObjectsInitialized [
	| block |
	block := self stubs at: #ensureDirtyObjectsInitialized ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ true
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciStoreTravDoTravRefsNlr: noLongerBuffer nnr: noLongerCount ogoc: gcedBuffer ngc: gcedCount stdArgs: stdArgs ctArgs: ctArgs [
	| block |
	block := self stubs at: #apiGciStoreTravDoTravRefs ifAbsent: [ nil ].
	block ifNotNil: [
		^ block valueWithArguments: {
			noLongerBuffer.
			noLongerCount.
			gcedBuffer.
			gcedCount.
			stdArgs.
			ctArgs } ].
	^ 1
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciTraverseOops: oopBuffer count: oopCount into: traversalBuffer level: traversalLevel [
	| block |
	block := self stubs at: #apiGciTraverseOops ifAbsent: [ nil ].
	block ifNotNil: [
		^ block
			cull: oopBuffer
			cull: oopCount
			cull: traversalBuffer
			cull: traversalLevel ].
	self error: 'No apiGciTraverseOops stub configured.'
]

{ #category : 'accessing' }
CoreMockGbsSession >> apiGciErr: errorStruct [
	^ self gciErr: errorStruct
]

{ #category : 'error handling' }
CoreMockGbsSession >> checkForError [
	| block |
	block := self stubs at: #checkForError ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ nil
]

{ #category : 'execution' }
CoreMockGbsSession >> evaluate: aString [
	| value |
	value := self stubs at: #evaluate ifAbsent: [ '' ].
	(value respondsTo: #cull:) ifTrue: [ ^ value cull: aString ].
	^ value
]

{ #category : 'execution' }
CoreMockGbsSession >> execute: script [
	| block |
	block := self stubs at: #execute ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value: script ].
	^ self stubs at: #executeResult ifAbsent: [ true ]
]

{ #category : 'execution' }
CoreMockGbsSession >> executeAndFetch: script [
	| block |
	block := self stubs at: #executeAndFetch ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script ].
	^ self stubs at: #executeAndFetchResult ifAbsent: [ '' ]
]

{ #category : 'execution' }
CoreMockGbsSession >> executeAndFetch: script context: contextOop [
	| block |
	block := self stubs at: #executeAndFetchContext ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script cull: contextOop ].
	^ self executeAndFetch: script
]

{ #category : 'execution' }
CoreMockGbsSession >> executeScriptAndFetchObject: script [
	| block |
	block := self stubs at: #executeScriptAndFetchObject ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script ].
	(self stubs includesKey: #executeScriptAndFetchObjectResult)
		ifTrue: [ ^ self stubs at: #executeScriptAndFetchObjectResult ].
	((self stubs includesKey: #executeAndFetch)
		or: [ self stubs includesKey: #executeAndFetchResult ])
		ifTrue: [ ^ self executeAndFetch: script ].
	^ nil
]

{ #category : 'execution' }
CoreMockGbsSession >> executeScriptAndReturnOop: script [
	| block |
	block := self stubs at: #executeScriptAndReturnOop ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script ].
	(self stubs includesKey: #executeScriptAndReturnOopResult)
		ifTrue: [ ^ self stubs at: #executeScriptAndReturnOopResult ].
	^ super executeScriptAndReturnOop: script
]

{ #category : 'execution' }
CoreMockGbsSession >> executeWorkspaceScriptAndReturnOop: script [
	| block |
	block := self stubs at: #executeWorkspaceScriptAndReturnOop ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: script ].
	^ super executeWorkspaceScriptAndReturnOop: script
]

{ #category : 'execution' }
CoreMockGbsSession >> forwardRemoteMessage: aMessage forOop: targetOop [
	| block |
	block := self stubs at: #forwardRemoteMessage ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: aMessage cull: targetOop ].
	^ super forwardRemoteMessage: aMessage forOop: targetOop
]

{ #category : 'execution' }
CoreMockGbsSession >> fetchRemoteCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary context: anOop [
	| block |
	block := self stubs at: #fetchRemoteCommandBody ifAbsent: [ nil ].
	block ifNotNil: [
		^ block cull: bodyString cull: literalDictionary cull: oopDictionary cull: anOop ].
	^ super
		fetchRemoteCommandBody: bodyString
		literalBindings: literalDictionary
		oopBindings: oopDictionary
		context: anOop
]

{ #category : 'execution' }
CoreMockGbsSession >> returnRemoteCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary [
	| block |
	block := self stubs at: #returnRemoteCommandBody ifAbsent: [ nil ].
	block ifNotNil: [
		^ block cull: bodyString cull: literalDictionary cull: oopDictionary ].
	^ super
		returnRemoteCommandBody: bodyString
		literalBindings: literalDictionary
		oopBindings: oopDictionary
]

{ #category : 'execution' }
CoreMockGbsSession >> serverObjectCanUnderstand: aSelector [
	| block |
	block := self stubs at: #serverObjectCanUnderstand ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: aSelector ].
	^ true
]

{ #category : 'lifecycle' }
CoreMockGbsSession >> releaseOops: oopCollection [
	| block |
	block := self stubs at: #releaseOops ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: oopCollection ].
	^ self
		withOopBufferFor: oopCollection
		do: [ :oopBuffer |
			self apiGciReleaseOops: oopBuffer count: oopCollection size ]
]

{ #category : 'typed wrappers' }
CoreMockGbsSession >> refreshAllTypedWrapperClasses [
	| block |
	block := self stubs at: #refreshAllTypedWrapperClasses ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ super refreshAllTypedWrapperClasses
]

{ #category : 'typed wrappers' }
CoreMockGbsSession >> refreshStaleTypedWrapperClasses [
	| block |
	block := self stubs at: #refreshStaleTypedWrapperClasses ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ super refreshStaleTypedWrapperClasses
]

{ #category : 'typed wrappers' }
CoreMockGbsSession >> typedWrapperLifecycleReportText [
	| block |
	block := self stubs at: #typedWrapperLifecycleReportText ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ super typedWrapperLifecycleReportText
]

{ #category : 'typed wrappers' }
CoreMockGbsSession >> typedWrapperLifecycleReport [
	| block |
	block := self stubs at: #typedWrapperLifecycleReport ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ super typedWrapperLifecycleReport
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciAbort [
	| value |
	value := self stubs at: #gciAbort ifAbsent: [ 1 ].
	(value respondsTo: #value) ifTrue: [ ^ value value ].
	^ value
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciCommit [
	| value |
	value := self stubs at: #gciCommit ifAbsent: [ 1 ].
	(value respondsTo: #value) ifTrue: [ ^ value value ].
	^ value
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciErr: errorStruct [
	| block |
	block := self stubs at: #gciErr ifAbsent: [ nil ].
	block ifNotNil: [ block value: errorStruct. ^ true ].
	^ false
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciInit [
	^ self stubs at: #gciInit ifAbsent: [ true ]
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciLoginStone: s hostUser: hu hostPass: hp gsUser: gu gsPass: gp [
	^ self stubs at: #gciLogin ifAbsent: [ true ]
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciLogout [
	^ self stubs at: #gciLogout ifAbsent: [ 1 ]
]

{ #category : 'accessing' }
CoreMockGbsSession >> gciPollForSignal [
	| value |
	value := self stubs at: #gciPollForSignal ifAbsent: [ 0 ].
	(value respondsTo: #value) ifTrue: [ ^ value value ].
	^ value
]

{ #category : 'accessing' }
CoreMockGbsSession >> sendInterrupt [
	| block |
	block := self stubs at: #sendInterrupt ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ true
]

{ #category : 'accessing' }
CoreMockGbsSession >> interrupt [
	| block |
	block := self stubs at: #interrupt ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ true
]

{ #category : 'accessing' }
CoreMockGbsSession >> signalInterrupt [
	| block |
	block := self stubs at: #signalInterrupt ifAbsent: [ nil ].
	block ifNotNil: [ ^ block value ].
	^ true
]

{ #category : 'execution' }
CoreMockGbsSession >> serverInterface [
	"Return self so this mock can also intercept serverInterface calls!"
	^ self
]

{ #category : 'materialization' }
CoreMockGbsSession >> supportsStructuredMaterializationBatchBuffers [
	^ self stubs at: #supportsStructuredMaterializationBatchBuffers ifAbsent: [ false ]
]

{ #category : 'materialization' }
CoreMockGbsSession >> supportsStructuredMaterializationBatchBytes [
	^ self stubs at: #supportsStructuredMaterializationBatchBytes ifAbsent: [ false ]
]

{ #category : 'materialization' }
CoreMockGbsSession >> supportsMaterializationTraversalByteTransport [
	^ self stubs at: #supportsMaterializationTraversalByteTransport ifAbsent: [ false ]
]

{ #category : 'materialization' }
CoreMockGbsSession >> materializationTraversalBytesForBody: bodyString literalBindings: literalDictionary label: aString [
	| block |
	block := self stubs at: #materializationTraversalBytesForBody ifAbsent: [ nil ].
	block ifNotNil: [
		^ block cull: bodyString cull: literalDictionary cull: aString ].
	self error: 'No materialization traversal byte transport stub configured.'
]

{ #category : 'materialization' }
CoreMockGbsSession >> materializationTraversalReportsForOops: oopCollection level: traversalLevel label: aString [
	| block |
	block := self stubs at: #materializationTraversalReportsForOops ifAbsent: [ nil ].
	block ifNotNil: [
		^ block cull: oopCollection cull: traversalLevel cull: aString ].
	self error: 'No materialization traversal-buffer transport stub configured.'
]

{ #category : 'materialization' }
CoreMockGbsSession >> supportsMaterializationTraversalBufferTransport [
	^ self stubs at: #supportsMaterializationTraversalBufferTransport ifAbsent: [ false ]
]

{ #category : 'dirty store traversal' }
CoreMockGbsSession >> storeTraversalBuffer: aBuffer [
	| block |
	block := self stubs at: #storeTraversalBuffer ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: aBuffer ].
	^ true
]

{ #category : 'dirty store traversal' }
CoreMockGbsSession >> storeTraversalBuffer: aBuffer releasingNoLongerReplicatedOops: oopCollection [
	| block |
	block := self stubs at: #storeTraversalBufferReleasingNoLongerReplicatedOops ifAbsent: [ nil ].
	block ifNotNil: [ ^ block cull: aBuffer cull: oopCollection ].
	self error: 'No no-longer-replicated store traversal transport stub configured.'
]

{ #category : 'dirty store traversal' }
CoreMockGbsSession >> storeTraversalBuffer: aBuffer releasingNoLongerReplicatedOops: noLongerOopCollection gcedOops: gcedOopCollection [
	| block |
	block := self stubs at: #storeTraversalBufferReleasingExportSetOops ifAbsent: [ nil ].
	block ifNotNil: [
		^ block cull: aBuffer cull: noLongerOopCollection cull: gcedOopCollection ].
	^ self
		storeTraversalBuffer: aBuffer
		releasingNoLongerReplicatedOops: noLongerOopCollection
]

{ #category : 'dirty store traversal' }
CoreMockGbsSession >> supportsDirtyStoreTraversalBufferTransport [
	^ self stubs at: #supportsDirtyStoreTraversalBufferTransport ifAbsent: [ false ]
]

{ #category : 'materialization' }
CoreMockGbsSession >> supportsClampedTraversalTransport [
	^ self stubs at: #supportsClampedTraversalTransport ifAbsent: [ false ]
]

{ #category : 'dirty store traversal' }
CoreMockGbsSession >> supportsNoLongerReplicatedStoreTraversalTransport [
	^ self stubs at: #supportsNoLongerReplicatedStoreTraversalTransport ifAbsent: [ false ]
]

{ #category : 'lifecycle' }
CoreMockGbsSession >> supportsReleaseOopsTransport [
	^ self stubs at: #supportsReleaseOopsTransport ifAbsent: [ false ]
]

{ #category : 'accessing' }
CoreMockGbsSession >> stubs [
	^ stubs ifNil: [ stubs := Dictionary new ]
]

{ #category : 'private' }
CoreMockGbsSession >> withOopBufferFor: oopCollection do: aBlock [
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
