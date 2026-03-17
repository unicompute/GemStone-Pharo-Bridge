Class {
	#name : #'GbxServerInterfaceWithStats',
	#superclass : #'Object',
	#instVars : [ #'statResource' #'serverInterface' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'initialize-release' }
GbxServerInterfaceWithStats >> statResource: aStatResource 
	"If aStatResource is nil, return a non-wrapped GbxCInterface.  Otherwise, 
	 return the receiever, a GbxCInterfaceWithStats-wrapped cinterface."

	^aStatResource isNil 
		ifTrue: 
			[serverInterface statResource: aStatResource.
			serverInterface]
		ifFalse: [^self]

{ #category : #'initialize-release' }
GbxServerInterfaceWithStats >> serverInterface: interface statResource: resource

	serverInterface := interface.
	statResource := resource

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> remoteClassFor: remoteClassFor 
	| start result |
	start := self startCallToGem.
	result := serverInterface remoteClassFor: remoteClassFor.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for fetch: fetch OOPsAt: OOPsAt 
	| start result |
	start := self startCallToGem.
	result := serverInterface 
				for: for
				fetch: fetch
				OOPsAt: OOPsAt.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> saveObjects: delegates 
	| start result |
	start := self startCallToGem.
	result := serverInterface saveObjects: delegates.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> compileInstMethod: compileInstMethod forClass: forClass inMethodCategory: inMethodCategory symbolList: symbolList 
	| start result |
	self gbxFixMe.	"Remove this method."
	start := self startCallToGem.
	result := serverInterface 
				compileInstMethod: compileInstMethod
				forClass: forClass
				inMethodCategory: inMethodCategory
				symbolList: symbolList.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> remoteVaryingSizeFor: remoteVaryingSizeFor 
	| start result |
	start := self startCallToGem.
	result := serverInterface remoteVaryingSizeFor: remoteVaryingSizeFor.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for fetchByteAt: fetchByteAt 
	^self callToGem: [ serverInterface for: for fetchByteAt: fetchByteAt ]

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for createObjectClass: createObjectClass values: values clusterBucket: clusterBucket permanent: permanent 
	| start result |
	start := self startCallToGem.
	result := serverInterface for: for createObjectClass: createObjectClass values: values clusterBucket: clusterBucket permanent: permanent.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for fetchVaryingOOPAt: fetchVaryingOOPAt 
	^self callToGem: [ serverInterface for: for fetchVaryingOOPAt: fetchVaryingOOPAt ]

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> getFreeOops: getFreeOops 
	| start result |
	start := self startCallToGem.
	result := serverInterface getFreeOops: getFreeOops.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for storeOOPs: storeOOPs at: at 
	| start result |
	start := self startCallToGem.
	result := serverInterface 
				for: for
				storeOOPs: storeOOPs
				at: at.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> fetchImplementationFor: fetchImplementationFor 
	| start result |
	start := self startCallToGem.
	result := serverInterface fetchImplementationFor: fetchImplementationFor.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> remoteSizeFor: remoteSizeFor 
	| start result |
	start := self startCallToGem.
	result := serverInterface remoteSizeFor: remoteSizeFor.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> loginLinked: loginLinked passwords: passwords errorHolder: errorHolder 
	| start result |
	start := self startCallToGem.
	result := serverInterface loginLinked: loginLinked passwords: passwords errorHolder: errorHolder.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for fetch: fetch varyingOOPsAt: varyingOOPsAt 
	| start result |
	start := self startCallToGem.
	result := serverInterface for: for fetch: fetch varyingOOPsAt: varyingOOPsAt.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> softBreak
	^self callToGem: [ serverInterface softBreak ]

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> existsFor: existsFor 
	| start result |
	start := self startCallToGem.
	result := serverInterface existsFor: existsFor.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> storeTraversalBuffer: travBuffer flags: flags 
	| start result |
	self updateStatsForStoreTravBuffer: travBuffer.
	start := self startCallToGem.
	result := serverInterface storeTraversalBuffer: travBuffer flags: flags.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for fetchObjInfoStartingAt: fetchObjInfoStartingAt maxBytes: maxBytes convertSpecials: convertSpecials retrievalFlags: retrievalFlags 
	| start result |
	start := self startCallToGem.
	result := serverInterface for: for fetchObjInfoStartingAt: fetchObjInfoStartingAt maxBytes: maxBytes convertSpecials: convertSpecials retrievalFlags: retrievalFlags.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> dirtyObjectsInit
	| start result |
	start := self startCallToGem.
	result := serverInterface dirtyObjectsInit.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for storeNamedOOPs: storeNamedOOPs at: at 
	| start result |
	start := self startCallToGem.
	result := serverInterface 
				for: for
				storeNamedOOPs: storeNamedOOPs
				at: at.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> pollForSignalFor: pollForSignalFor deferFatalErrors: deferFatalErrors 
	| start result |
	start := self startCallToGem.
	result := serverInterface pollForSignalFor: pollForSignalFor deferFatalErrors: deferFatalErrors.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> compileClassMethod: compileClassMethod forClass: forClass inMethodCategory: inMethodCategory symbolList: symbolList 
	| start result |
	start := self startCallToGem.
	result := serverInterface 
				compileClassMethod: compileClassMethod
				forClass: forClass
				inMethodCategory: inMethodCategory
				symbolList: symbolList.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for unsynchronizedRemotePerform: privateRemotePerform withArgs: withArgs 
	| start result |
	start := self startCallToGem.
	result := serverInterface for: for unsynchronizedRemotePerform: privateRemotePerform withArgs: withArgs.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> traverseDelegates: delegates forInteraction: serverInteraction level: anInteger
	
	| result |
	result := serverInterface traverseDelegates: delegates forInteraction:
			serverInteraction level: anInteger.
	statResource incTraverseCalls.
	result gbxIsGSError
		ifFalse:
			[statResource
				incBytesTraversed: serverInteraction fetchTraversal buffer usedBytes].
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> moreTraversalInTraversal: traversal 
	| traversalComplete start |
	start := self startCallToGem.
	traversalComplete := serverInterface moreTraversalInTraversal: traversal.
	self endCallToGem: start.
	self 
		updateTravStatsStartMicroseconds: start
		travBuffer: traversal buffer
		wasError: traversalComplete gbxIsGSError.
	^traversalComplete

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for fetch: fetch bytesAt: bytesAt 
	| start result |
	start := self startCallToGem.
	result := serverInterface for: for fetch: fetch bytesAt: bytesAt.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> logout
	| start result |
	start := self startCallToGem.
	result := serverInterface logout.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for fetchOOPAt: fetchOOPAt 
	| start result |
	start := self startCallToGem.
	result := serverInterface for: for fetchOOPAt: fetchOOPAt.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> checkAuth: arrayOfGSObjects 
	^self callToGem: [serverInterface checkAuth: arrayOfGSObjects]

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for storeIdxOOPs: storeIdxOOPs at: at 
	^self callToGem: [ serverInterface for: for storeIdxOOPs: storeIdxOOPs at: at ]

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> performInteraction: serverInteraction
	"fetched bytes collected are only for single round trip because the fetchTraversal buffer hasn't
	yet been filled in multi-trip

	Sender must hold my sessionProtect."
	
	| result storedBytes start |
	storedBytes := serverInteraction storeTraversal buffer usedBytes.	"Only increment store traversals stats if there is something in the store traversal buffer"
	storedBytes > 0
		ifTrue:
			[statResource incStoreTraversals.
			statResource incBytesSentByStoreTraversal: storedBytes].
	start := self startCallToGem.
	result := serverInterface performInteraction: serverInteraction.
	self endCallToGem: start.
	result gbxIsGSError
		ifFalse:
			[serverInterface isSingleTrip
				ifTrue:
					[statResource
						incTraverseCalls;
						incBytesTraversed: serverInteraction fetchTraversal buffer usedBytes]].
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> for: for indexOfInstVarNamed: indexOfInstVarNamed 
	| start result |
	start := self startCallToGem.
	result := serverInterface for: for indexOfInstVarNamed: indexOfInstVarNamed.
	self endCallToGem: start.
	^result

{ #category : #'delegating and updating stats' }
GbxServerInterfaceWithStats >> hardBreak
	^self callToGem: [ serverInterface hardBreak ]

{ #category : #'accessing' }
GbxServerInterfaceWithStats >> statResource
	^statResource

{ #category : #'support' }
GbxServerInterfaceWithStats >> startCallToGem
	"Increment gciCallsToGem, and return the current  time to
	 be passed to the subsequent call to endCallToGem:."

	statResource incGciCallsToGem.
	^Time gbxClock

{ #category : #'support' }
GbxServerInterfaceWithStats >> callToGem: callBlock 
	| result start |
	start := self startCallToGem.
	result := callBlock value.
	self endCallToGem: start.
	^result

{ #category : #'support' }
GbxServerInterfaceWithStats >> updateStatsForStoreTravBuffer: aGbxTraversalBuffer 
	| bytesInBuffer |
	bytesInBuffer := aGbxTraversalBuffer usedBytes.
	"Only increment store traversals stats if there is something in the store traversal buffer"
	bytesInBuffer > 0 
		ifTrue: 
			[statResource incStoreTraversals.
			statResource incBytesSentByStoreTraversal: bytesInBuffer]

{ #category : #'support' }
GbxServerInterfaceWithStats >> updateTravStatsStartMicroseconds: start travBuffer: buffer wasError: wasError 
	statResource incTraverseCalls.
	statResource incTraverseCallTime: Time gbxClock - start.
	wasError ifFalse: [statResource incBytesTraversed: buffer usedBytes]

{ #category : #'support' }
GbxServerInterfaceWithStats >> endCallToGem: startTime 
	"Calculate the elapsed time given the startTime , and
	 increment the gciCallsToGemTime stat"

	statResource incGciCallsToGemTime: Time gbxClock - startTime

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> storeTravDoArgsForMessageSend: messageSend 
	^serverInterface storeTravDoArgsForMessageSend: messageSend

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> startEventDetection
	^serverInterface startEventDetection

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> continueAfter: error
	
	^serverInterface continueAfter: error

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> loginX509: parameters errorHolder: errorHolder

	^serverInterface loginX509: parameters errorHolder: errorHolder

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> allocateTraversalBufferFor: aServerInteraction
	
	^serverInterface allocateTraversalBufferFor: aServerInteraction

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> isBlocking
	^serverInterface isBlocking

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> gciGemTrace: anInt
	^serverInterface gciGemTrace: anInt

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> continueAfter: error forInteraction: serverInteraction
	"Sender must hold my session's accessProtect."

	^serverInterface continueAfter: error forInteraction: serverInteraction

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> newServerEvaluation
	^serverInterface newServerEvaluation

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> makeCacheStrongAndFinalizeIntoBuffers

	^serverInterface makeCacheStrongAndFinalizeIntoBuffers

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> shutdownSocket: aSocket withHandle: handle 
	^serverInterface shutdownSocket: aSocket withHandle: handle

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> clampedTravArgsForServerInteraction: serverInteraction
	
	^serverInterface clampedTravArgsForServerInteraction: serverInteraction

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> storeTravDoArgsBuffer
	^serverInterface storeTravDoArgsBuffer

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> storeTravDoArgsForEvaluation: anInteraction 
	^serverInterface storeTravDoArgsForEvaluation: anInteraction

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> saveFetchedOops: delegates

	^serverInterface saveFetchedOops: delegates

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> storeTravDoArgsForTraversal: serverTraversal
	
	^serverInterface storeTravDoArgsForTraversal: serverTraversal

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> session
	^serverInterface session

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> getSignalHandle
	^serverInterface getSignalHandle

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> asLocalSmallIntegerFor: asLocalSmallIntegerFor 
	^serverInterface asLocalSmallIntegerFor: asLocalSmallIntegerFor

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> newMessageSend
	^serverInterface newMessageSend

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> gbsImageStartup
	^serverInterface gbsImageStartup

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> stepAfter: error forInteraction: serverInteraction
	"Sender must hold my session's accessProtect."

	^serverInterface stepAfter: error forInteraction: serverInteraction

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> isLoggedIn
	^serverInterface isLoggedIn

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> sessionIsRemote
	"sender must hold session's sessionProtect"

	^serverInterface sessionIsRemote

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> gbxDebugPrintString
	^serverInterface gbxDebugPrintString

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> clampedTravArgsBuffer
	^serverInterface clampedTravArgsBuffer

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> loginFlags
	^serverInterface loginFlags

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> stopNbWaitSocket
	^serverInterface stopNbWaitSocket

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> requestSingleStep
	^serverInterface requestSingleStep

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> isSingleTrip
	"Answer false if using the legacy multi-trip interface; 
	true if using the single-trip (GciStoreTravDoTravRefs) interface introduced in GS64 2.2.5.x"
	
	^serverInterface isSingleTrip

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> stopEventDetection
	^serverInterface stopEventDetection

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> callSequencer
	^serverInterface callSequencer

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> executableBlockClassDelegate
	
	^serverInterface executableBlockClassDelegate

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> newServerTraversal
	^serverInterface newServerTraversal

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> addToNoLongerReplicated: aDelegate
	"Sender must hold my session's sessionProtect."

	^serverInterface addToNoLongerReplicated: aDelegate

{ #category : #'delegating' }
GbxServerInterfaceWithStats >> storeTravFlags
	^serverInterface storeTravFlags

{ #category : #'private' }
GbxServerInterfaceWithStats class >> gciCallProtect
	^GbxGciCallSequencer gciCallProtect

{ #category : #'instance creation' }
GbxServerInterfaceWithStats class >> serverInterface: interface statResource: resource

	^self new serverInterface: interface statResource: resource

