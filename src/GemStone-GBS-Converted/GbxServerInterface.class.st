Class {
	#name : 'GbxServerInterface',
	#superclass : 'Object',
	#instVars : [
		'alteredOopBuffer',
		'byteFetchBuffer',
		'callSequencer',
		'clampedTravArgsBuffer',
		'dirtyOopBuffer',
		'eventDetector',
		'gcedOopBuffer',
		'longHolderBuffer',
		'longHolderBuffer2',
		'needMoreTraversal',
		'oopFetchBuffer',
		'oopsNoLongerReplicatedBuffer',
		'singleStepIsRequested',
		'storeTravDoArgsBuffer',
		'noLongerReplicatedOops',
		'thisSession',
		'traversalBufferManager'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'tracing and debugging' }
GbxServerInterface >> enableTracingToFileNamed: filename
[

	^callSequencer primInterface
		enableTracingToFileNamed: filename
		errorBuffer: callSequencer errorBuffer asAddress.
]

{ #category : 'tracing and debugging' }
GbxServerInterface >> printOnTraceFile: aMessage 
[
	"Print aMessage on the current GBC trace file, if tracing is enabled.  Include the given session number after the message."

	^callSequencer primInterface printOnTraceFile: aMessage
]

{ #category : 'tracing and debugging' }
GbxServerInterface >> disableTracingToFile
[

	callSequencer primInterface
		disableTracingToFileErrorBuffer: callSequencer errorBuffer asAddress.
]

{ #category : 'tracing and debugging' }
GbxServerInterface >> requestSingleStep
[
	"Next non-private execution is requested to break on entry"

	singleStepIsRequested := true
]

{ #category : 'Delegate interface' }
GbxServerInterface >> existsFor: target 
[
	^callSequencer setSessionPerformCheck: 
			[callSequencer primInterface gciObjExists: target oopValue]
]

{ #category : 'Delegate interface' }
GbxServerInterface >> remoteClassFor: target 
[
	"GciFetchClass"
	"Now used only for fetching the class of what might be ClientForwarders"
	self gbxFixMe. "Add a Smalltalk way to tell on the server whether an object is a clientForwarder or not"
	^self gciCallReturnDelegate: 
			[callSequencer primInterface gciFetchClass: target oopValue]
]

{ #category : 'Delegate interface' }
GbxServerInterface >> for: target storeOOPs: arrayOfGSObjects at: index
[
	
	^callSequencer
		setSessionPerformCheck:
			[self assertNotInTraversal.
			callSequencer primInterface
				gciStoreOops: target oopValue
				with: index
				with: (self oopArrayFromDelegates: arrayOfGSObjects) asAddress
				with: arrayOfGSObjects size]
]

{ #category : 'Delegate interface' }
GbxServerInterface >> for: target storeNamedOOPs: arrayOfGSObjects at: index
[
	
	^callSequencer
		setSessionPerformCheck:
			[self assertNotInTraversal.
			callSequencer primInterface
				gciStoreNamedOops: target oopValue
				with: index
				with: (self oopArrayFromDelegates: arrayOfGSObjects) asAddress
				with: arrayOfGSObjects size]
]

{ #category : 'Delegate interface' }
GbxServerInterface >> for: target storeIdxOOPs: arrayOfGSObjects at: index
[
	
	^callSequencer
		setSessionPerformCheck:
			[self assertNotInTraversal.
			callSequencer primInterface
				gciStoreIdxOops: target oopValue
				with: index
				with: (self oopArrayFromDelegates: arrayOfGSObjects) asAddress
				with: arrayOfGSObjects size]
]

{ #category : 'Delegate interface' }
GbxServerInterface >> for: target createObjectClass: oClass values: values clusterBucket: clusterBucket permanent: aBool
[
	
	^self
		gciCallReturnDelegate:
			[self assertNotInTraversal.
			values class isBits
				ifTrue:
					[| ans |
					ans := callSequencer primInterface
						gciCreateByteObj: oClass oopValue
						with: target oopValue
						with: values gbxAsCString
						with: values size
						with: clusterBucket
						with: aBool.
					ans]
				ifFalse:
					[callSequencer primInterface
						gciCreateOopObj: oClass oopValue
						with: target oopValue
						with: (self oopArrayFromDelegates: values) asAddress
						with: values size
						with: clusterBucket
						with: aBool]]
]

{ #category : 'events/nonblocking support' }
GbxServerInterface >> stopEventDetection
[
	"It's OK to send this even if event detection is already stopped."

	eventDetector isNil 
		ifFalse: 
			[eventDetector stop.
			eventDetector := nil]
]

{ #category : 'events/nonblocking support' }
GbxServerInterface >> startEventDetection
[
	"Private.  After this method is called, GemStone-generated events occurring in this session will be detected by the Smalltalk client (ex: changed object notification, gem-to-gem notifiers, signaled abort).  On unix platforms, an asynchronous implementation is used.  Otherwise, a polling implementation is used."

	eventDetector isNil ifFalse: [eventDetector stop].
	eventDetector := GbxEventDetector session: thisSession.
	eventDetector start
]

{ #category : 'buffers' }
GbxServerInterface >> oopsNoLongerReplicatedBuffer
[
	"Return a buffer that represents a C array of GemStone oops."

	oopsNoLongerReplicatedBuffer == nil 
		ifTrue: 
			[oopsNoLongerReplicatedBuffer := thisSession oopArrayClass 
						size: thisSession configuration gcedObjBufferSize].
	^oopsNoLongerReplicatedBuffer
]

{ #category : 'buffers' }
GbxServerInterface >> byteFetchBufferOfSize: aSize
[
	"Return a buffer that for use with fetch calls."
	
	^byteFetchBuffer isNil
		ifTrue: [byteFetchBuffer := GbxByteArray size: aSize]
		ifFalse: [byteFetchBuffer ensureSizeIsAtLeast: aSize]
]

{ #category : 'buffers' }
GbxServerInterface >> oopFetchBufferOfSize: aSize
[
	"Return a buffer that represents a C array of GemStone oops."
	
	^oopFetchBuffer isNil
		ifTrue: [oopFetchBuffer := thisSession oopArrayClass size: aSize]
		ifFalse: [oopFetchBuffer ensureSizeIsAtLeast: aSize]
]

{ #category : 'buffers' }
GbxServerInterface >> longHolderBuffer2
[
	"Return a buffer that represents a pointer to a long."

	longHolderBuffer2 isNil ifTrue: [
		longHolderBuffer2 := GbxLongHolderType allocate].
	^longHolderBuffer2
]

{ #category : 'buffers' }
GbxServerInterface >> longHolderBuffer
[
	"Return a buffer that represents a pointer to a long."

	longHolderBuffer isNil ifTrue: [
		longHolderBuffer := GbxLongHolderType allocate].
	^longHolderBuffer
]

{ #category : 'buffers' }
GbxServerInterface >> clampedTravArgsBuffer
[
	"Return a buffer that represents the GciClampedTravArgsSType structure."

	clampedTravArgsBuffer isNil ifTrue: [
		clampedTravArgsBuffer := GbxGciClampedTravArgsSType allocate].
	^clampedTravArgsBuffer
]

{ #category : 'buffers' }
GbxServerInterface >> storeTravDoArgsBuffer
[
	"Return a buffer that represents the GciStoreTravDoArgsSType structure.
	Perform basic initialization."

	storeTravDoArgsBuffer isNil
		ifTrue: 
			[storeTravDoArgsBuffer := callSequencer primInterface
						storeTravDoArgsSTypeClass allocate].
	storeTravDoArgsBuffer initialize.
	storeTravDoArgsBuffer storeTravFlags: (self storeTravFlags bitOr: 16r10).

	"In GemStone/64 3.2, GCI_STORE_TRAV_SWIZZLE_IN_PLACE was introduced. See gci.ht.
	GCI_STORE_TRAV_SWIZZLE_IN_PLACE = 0x10
	/* if swizzling by the client is being done for transmit to a server
     * with opposite byte order, this flag says it is ok to swizzle the
     * caller's buffer in place before transmitting.  Reduces client memory 
     * access footprint of a large store traversal */"
	^storeTravDoArgsBuffer
]

{ #category : 'GbsSessionManager interface' }
GbxServerInterface >> gbsImageStartup
[
	"Discard defunct C pointers"

	alteredOopBuffer := nil.
	byteFetchBuffer := nil.
	dirtyOopBuffer := nil.
	oopFetchBuffer := nil.
	clampedTravArgsBuffer := nil.
	longHolderBuffer := nil.
	longHolderBuffer2 := nil.
	storeTravDoArgsBuffer := nil.
	callSequencer == nil ifFalse: [callSequencer gbsImageStartup]
]

{ #category : 'GbsSessionManager interface' }
GbxServerInterface >> floatKind: aFloatOrDouble 
[
	self gbxFixMe.	"Compute this ourselves, rather than making a GCI call"
	^callSequencer floatKind: aFloatOrDouble
]

{ #category : 'GbsSessionManager interface' }
GbxServerInterface >> loadUserActionLibrary: libraryName
[
	"Private to GBS."

	^callSequencer gciCriticalPerformCheck: 
			[callSequencer primInterface
				gciLoadUserActionLibrary: libraryName gbxAsCString]
]

{ #category : 'ServerInteraction interface' }
GbxServerInterface >> storeTravDoArgsForStep: serverInteraction afterError: error selector: cSelector args: args
[
	"Allocates C memory for the selector; sender must free when done.
	error is a GbsError"

	| storeTravDoArgs |
	storeTravDoArgs := self storeTravDoArgsBuffer.
	storeTravDoArgs
		storeTravBuff: serverInteraction storeTraversal buffer asAddress;
		doPerform: 1;
		receiver: error serverProcess oopValue;
		selector: cSelector;
		args: (self oopArrayFromDelegates: args) asAddress;
		numArgs: args size;
		storeTravFlags: (self storeTravFlagsForInteraction: serverInteraction).
	storeTravDoArgs doFlags: 16r22.	"When stepping, don't stop for breakpoints, no async events, disable native code."
	^storeTravDoArgs
]

{ #category : 'ServerInteraction interface' }
GbxServerInterface >> storeTravDoArgsForMessageSend: messageSend
[
	"Allocates C memory for the selector; sender must free when done."

	| storeTravDoArgs args |
	storeTravDoArgs := self storeTravDoArgsBuffer.
	args := messageSend argumentDelegates.	"Already set: StoreTravFlags, the unused buffers and sizes."
	storeTravDoArgs
		storeTravBuff: messageSend storeTraversal buffer asAddress;
		doPerform: 1;
		doFlags: (self doFlagsForInteraction: messageSend);
		receiver: messageSend receiver oopValue;
		selector: messageSend cSelector;
		args: (self oopArrayFromDelegates: args) asAddress;
		numArgs: args size;
		storeTravFlags: (self storeTravFlagsForInteraction: messageSend).
	^storeTravDoArgs
]

{ #category : 'ServerInteraction interface' }
GbxServerInterface >> storeTravDoArgsForEvaluation: evaluation
[
	"Initialize the members of the args struct that are common between 
	single-trip and multi-trip, and answer the struct.
	Allocates C memory for the selector; sender must free when done."

	| storeTravDoArgs sourceClassDelegate sourceCode |
	sourceCode := evaluation sourceCode.
	sourceClassDelegate := sourceCode class gbxDelegate
				forSession: thisSession.
	sourceClassDelegate isNil
		ifTrue: 
			[^self gbsMessenger
				error: 'No match in server for evaluate string class %1'
				with: sourceCode class].
	storeTravDoArgs := self storeTravDoArgsBuffer.	"Already set: StoreTravFlags, the unused buffers and sizes."
	storeTravDoArgs
		storeTravBuff: evaluation storeTraversal buffer asAddress;
		doFlags: (self doFlagsForInteraction: evaluation);
		source: evaluation cSourceCode;
		sourceSize: sourceCode basicSize;
		sourceClass: sourceClassDelegate oopValue;
		contextObject: evaluation contextDelegate oopValue;
		symbolList: evaluation symbolListDelegate oopValue;
		storeTravFlags: (self storeTravFlagsForInteraction: evaluation).
	^storeTravDoArgs
]

{ #category : 'ServerInteraction interface' }
GbxServerInterface >> stepAfter: error forInteraction: serverInteraction
[
	"Perform a step on the server. Answer a delegate representing the server object
	returned from the server, or a GbsError.

	Sender must hold my session's sessionProtect"
	
	| storeTravDoArgs clampedTravArgs cSelector result args |
	result := error gsReturnVal.
	(result = thisSession oopIllegal or: [result = thisSession oopNil])
		ifTrue:
			[cSelector := #_stepOverInFrame: gbxAsCString.
			args := Array
				with:
					(error stepLevel
						asGSObjectInSession: serverInteraction serverInterface session)]
		ifFalse:
			[cSelector := #_stepOverInFrame:return: gbxAsCString.
			args := Array
				with:
					(error stepLevel
						asGSObjectInSession: serverInteraction serverInterface session)
				with: result].
	error stepLevel: nil.	"Must clear stepLevel before returning error"
	storeTravDoArgs := self storeTravDoArgsForStep: serverInteraction
		afterError: error selector: cSelector args: args.
	clampedTravArgs := serverInteraction clampedTravArgs.
	^self roundTripForInteraction: serverInteraction withStoreTravDoArgs:
			storeTravDoArgs clampedTravArgs: clampedTravArgs
]

{ #category : 'ServerInteraction interface' }
GbxServerInterface >> storeTravFlagsForInteraction: aServerInteraction
[

	^aServerInteraction shouldSynchronize
		ifTrue: [self storeTravFlags bitOr: 8	"GCI_STORE_TRAV_FINISH_UPDATES = 0x8"]
		ifFalse: [self storeTravFlags]
]

{ #category : 'ServerInteraction interface' }
GbxServerInterface >> performInteraction: serverInteraction
[
	"Perform the specified server interaction. Answer a delegate representing the server object
	returned from the server, or a GbsError.

	Sender must hold my session's sessionProtect"

	| storeTravDoArgs clampedTravArgs result |
	storeTravDoArgs := serverInteraction storeTravDoArgs.
	clampedTravArgs := serverInteraction clampedTravArgs.
	"If this thread is terminated while we're awaiting a non-blocking call to the server to return,
	the oop buffers may not get cleared, and the oops may get re-sent on the next round trip
	by another thread, causing a notInExportSet error.
	This #ensure: will clear the buffers before the session semaphore is released,
	eliminating this possibility."
	
	[result := self
				roundTripForInteraction: serverInteraction
				withStoreTravDoArgs: storeTravDoArgs
				clampedTravArgs: clampedTravArgs]
			ensure: 
				[self oopsNoLongerReplicatedBuffer clear.
				self gcedOopBuffer clear].
	^result
]

{ #category : 'ServerInteraction interface' }
GbxServerInterface >> storeTravDoArgsForTraversal: serverTraversal
[
	
	^self subclassResponsibility
]

{ #category : 'ServerInteraction interface' }
GbxServerInterface >> clampedTravArgsForServerInteraction: serverInteraction
[

	| ctArgs |
	ctArgs := self clampedTravArgsBuffer.
	ctArgs
		clampSpec: serverInteraction replicationClampDelegate oopValue;
		travBuff: serverInteraction fetchTraversal buffer asAddress;
		travBuffSize: serverInteraction fetchTraversal buffer bufferSize;
		retrievalFlags: (self retrievalFlagsForServerInteraction: serverInteraction).
	^ctArgs
]

{ #category : 'accessing' }
GbxServerInterface >> storeTravFlagsFor: config 
[
	"From GS64 2.2.2 gci.ht:
enum { GCI_STORE_TRAV_DEFAULT = 0,
    /* default behavior: 
     *   use 'add' sematics for varying instvars of Nsc's.
     *   if object to be stored into does not exist, give error
     */

  /* The following flags are orthogonal to each other; any combination of them
   * is allowed
   */
   GCI_STORE_TRAV_NSC_REP = 0x1,
   /*  use REPLACE semantics for varying instvars of Nsc's */

   GCI_STORE_TRAV_CREATE =  0x2,
   /*  If an object to be stored into does not exist, use GciCreate to
    *  semantics to create the object. such created objects are added to
    *  the PureExportSet .
    */

   GCI_STORE_TRAV_CREATE_PERMANENT = 0x4,
   /* This flag has no effect in this release */

   GCI_STORE_TRAV_FINISH_UPDATES = 0x8
  /* After processing the last object report in the traversal buffer,
   * automatically execute GciProcessDeferredUpdates
   */
  };"

	"If bulkLoad, we use createPermanent. This only has any effect with 32-bit servers."

	^config bulkLoad ifTrue: [7] ifFalse: [3]
]

{ #category : 'accessing' }
GbxServerInterface >> session
[
	"Answer the session I live to serve."

	^thisSession
]

{ #category : 'accessing' }
GbxServerInterface >> initializeTraversalBufferManager
[
	"If I'm GBSM's server interface, thisSession will be nil.
	Nobody should ask GBSM's interface to do any traversals, though."

	thisSession ~~ nil
		ifTrue: 
			[traversalBufferManager := GbxTraversalBufferManager
						forSession: thisSession]
]

{ #category : 'accessing' }
GbxServerInterface >> callSequencer
[
	^callSequencer
]

{ #category : 'accessing' }
GbxServerInterface >> session: aGSSession
[
	"Set the session with which this C interface object is associated."

	thisSession := aGSSession
]

{ #category : 'accessing' }
GbxServerInterface >> storeTravFlags
[
	^self storeTravFlagsFor: thisSession configuration
]

{ #category : 'accessing' }
GbxServerInterface >> bufferOopClass
[
	^thisSession bufferOopClass
]

{ #category : 'testing' }
GbxServerInterface >> isSingleTrip
[
	"Answer false if using the legacy multi-trip interface; 
	true if using the single-trip (GciStoreTravDoTravRefs) interface introduced in GS64 2.2.5.x"
	
	self subclassResponsibility
]

{ #category : 'testing' }
GbxServerInterface >> isBigEndian
[
	
	^UninterpretedBytes isBigEndian
]

{ #category : 'testing' }
GbxServerInterface >> isBlocking
[
	^callSequencer isBlocking
]

{ #category : 'private-primitive access' }
GbxServerInterface >> gciPerformNoDebugReceiver: target selector: aSelector args: argArray numArgs: gsObjects flags: flagInt 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^callSequencer 
		gciPerformNoDebugReceiver: target
		selector: aSelector
		args: argArray
		numArgs: gsObjects
		flags: flagInt
]

{ #category : 'private-primitive access' }
GbxServerInterface >> gciExecuteStrFromContextDbg: sourceString sourceSize: size sourceClass: class context: serverContext symbolList: aSymbolList flags: flagInt 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^callSequencer 
		gciExecuteStrFromContextDbg: sourceString
		sourceSize: size
		sourceClass: class
		context: serverContext
		symbolList: aSymbolList
		flags: flagInt
]

{ #category : 'private-primitive access' }
GbxServerInterface >> gciMoreTraversalBuffer: travBuff maxSize: travBuffSize 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result boolean or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^callSequencer gciMoreTraversalBuffer: travBuff maxSize: travBuffSize
]

{ #category : 'private-primitive access' }
GbxServerInterface >> gciStoreTravBuffer: travBuffer flags: flagsInt 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result boolean or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^callSequencer gciStoreTravBuffer: travBuffer flags: flagsInt
]

{ #category : 'support' }
GbxServerInterface >> gciCallReturnDelegate: callBlock 
[
	"Do the operation in <aBlock> (which must be a GCI call with a non-blocking variant)
	protected from other threads by <accessProtect> mutual exclusion semaphore.
	This particular method also sets the current session id, checks for GBC errors and returns 
	a delegate (or error)."

	| result |
	self gbxFixMe.	"Should look up oop in cache rather than create new delegate each time."
	result := callSequencer gciCall: callBlock resultType: #oopResult.
	^result gbxIsGSError 
		ifTrue: [result]
		ifFalse: [GbxDelegate oopValue: result session: thisSession]
]

{ #category : 'support' }
GbxServerInterface >> oopArrayFromDelegates: delegates
[
	"Delegates must be a sequenceable collection."

	^(self oopFetchBufferOfSize: delegates size)
		initializeFromDelegates: delegates
]

{ #category : 'support' }
GbxServerInterface >> gciGemTrace: anInteger
[

	callSequencer gciGemTrace: anInteger
]

{ #category : 'private' }
GbxServerInterface >> makeCacheStrongAndFinalizeIntoBuffers
[
	"Make my session's serverMap strong and scan it into my buffers."
	"Sender must hold my session's sessionProtect"

	self
		finishIGCMarking;
		finalizeIntoNoLongerReplicatedBuffer: self oopsNoLongerReplicatedBuffer
			gcedBuffer: self gcedOopBuffer
]

{ #category : 'private' }
GbxServerInterface >> needMoreTraversal
[
	"Assert that we need more traversal."

	needMoreTraversal := true
]

{ #category : 'private' }
GbxServerInterface >> roundTripForInteraction: serverInteraction withStoreTravDoArgs: storeTravDoArgs clampedTravArgs: clampedTravArgs
[
	
	self subclassResponsibility
]

{ #category : 'private' }
GbxServerInterface >> assertNotInTraversal
[
	"Error if we're in a state where we need to do a MoreTraversal."

	"Sender must hold my accessProtect."

	needMoreTraversal 
		ifTrue: 
			[self gbsMessenger 
				basicFailure: 'Operation out of order. Traversal in progress.'.
			needMoreTraversal := false	"Only error once; if the exception is proceeded"]
]

{ #category : 'private' }
GbxServerInterface >> setNetFor: session linked: linked hostPassword: password 
[
	"Private. Set session login network parameters.
	The sender must be holding GciCallProtect."

	| result parameters |
	parameters := session parameters.
	result := callSequencer performCheck: 
					[callSequencer primInterface 
						gciSetNetStoneName: parameters gemStoneName gbxAsCString
						hostUsername: parameters hostUsername gbxAsCString
						hostPassword: password gbxAsCString
						gemService: (linked 
								ifTrue: ['gcilnkobj' gbxAsCString]
								ifFalse: [parameters gemService gbxAsCString])].
	^result
]

{ #category : 'private' }
GbxServerInterface >> doFlagsForInteraction: aServerInteraction
[
	"Answer an integer value to be used as the doFlags member of a GciStoreTravDoArgsSType 
	struct. Which flags are used depend both on my own state (for single step in particular) 
	and on the specifics of aServerInteraction."
	"From GS64 3.0 gcicmn.ht:

	GCI_PERFORM_FLAG_ENABLE_DEBUG = 1,  
	/* make like GciPerform() with respect to debugging. default is debugger is
   	* disabled until GciPerformNoDebug returns */

	GCI_PERFORM_FLAG_DISABLE_ASYNC_EVENTS = 2  ,
	/* disable async events.  Used for GSI to be able to execute an exception
	* block or method to service RT_ERR_SIGNAL_ABORT, 
	*  RT_ERR_SIGNAL_GEMSTONE_SESSION, or ABORT_ERR_LOST_OT_ROOT */

	GCI_PERFORM_FLAG_SINGLE_STEP = 4, 
	/* place a single step break-point at the start of the method to be
	* performed, and then execute to hit that breakpoint.
	*/

 	GCI_PERFORM_MAP_SYMBOLS = 8, // obsolete, not used

  	GCI_PERFORM_RESULT_INTO_REFSET = 0x10,  /* for internal use only,
    	* add result oop to the ReferencedSet, not the PureExportSet  .
    	* Used in implementation of GciStoreTravDoTravRefs.
    	*/ (GBS does not need to set this, GciStoreTravDoTravRefs sets it internally.)

  	GCI_PERFORM_FLAG_INTERPRETED = 0x20 /* disable native code for the execution*"
	"stopForBreakpoints currently controls both enable_debug and disable_async_events.
	Also, we don't pay attention to single step requests when stopForBreakpoints is false, since
	that's probably an extra unsynchronized request such as a clamp creation."

	^aServerInteraction stopForBreakpoints
		ifTrue: 
			[singleStepIsRequested
				ifTrue: 
					[singleStepIsRequested := false.
					5]
				ifFalse: [1]]
		ifFalse: [2]
]

{ #category : 'private' }
GbxServerInterface >> doneWithTraversal
[
	"We're done with the current traversal."

	needMoreTraversal := false
]

{ #category : 'private' }
GbxServerInterface >> x509LoginFor: parameters
[

	self subclassResponsibility
]

{ #category : 'private' }
GbxServerInterface >> finalizeIntoNoLongerReplicatedBuffer: noLongerReplicatedBuffer gcedBuffer: gcedBuffer
[
	"Fill the given buffers with objIds of objects that I no longer have any reference to (gcedBuffer) 
	and objects that may have been replicated but now only have a reference to."
	"Sender must hold my session's sessionProtect"

	| cache |
	cache := thisSession serverMap.
	[cache isWeak] gbxAssert.
	cache
		beStrongAndFinalizeIntoNoLongerReplicatedBuffer: noLongerReplicatedBuffer
		gcedBuffer: gcedBuffer.	"If a replicate has been explicitly made into a proxy, its delegate will be in noLongerReplicatedOops. 
	That collection is strong, so we know that the delegate is still alive, so its oop has not been put in either the noLongerReplicatedBuffer
	or the gcedBuffer. So any delegates whose inExport flag is true need to be put in the noLongerReplicatedOops.
	There should be few objects explicitly made into proxies, so this cost isn't too bad.
	NoLongerReplicatedOops is also used when explicitly updating an object from the server which may have been
	dirtied on the client but we want to throw that version away, or on connector connect with updateSt post-connect action."
	noLongerReplicatedOops do: 
			[:del |
			del inExport
				ifTrue: 
					[noLongerReplicatedBuffer addFromDelegate: del.
					del noLongerExported]].
	noLongerReplicatedOops isEmpty
		ifFalse: [self initializeNoLongerReplicatedOops].
	self gbsMessenger
		statusTag: #finalizeIntoNoLongerReplicatedBuffer:gcedBuffer:
		message: '(s%1) noLongerReplicated: %2 gced: %3 '
		with: thisSession sessionId
		with: noLongerReplicatedBuffer
		with: gcedBuffer
]

{ #category : 'private' }
GbxServerInterface >> finishIGCMarking
[
	"If an incremental garbage collection is in the marking phase, finish the mark.
	We send this message before making the ServerMap weak.
	We do this because when in the marking phase, changing an object from weak to strong
	is much more expensive (it is scanned immediately if < 4096 slots)."

	ObjectMemory current incGCIsMarking
		ifTrue: [ObjectMemory finishIncrementalGC]
]

{ #category : 'private' }
GbxServerInterface >> gcedOopBuffer
[
	gcedOopBuffer == nil 
		ifTrue: 
			[gcedOopBuffer := thisSession oopArrayClass 
						size: thisSession configuration gcedObjBufferSize].
	^gcedOopBuffer
]

{ #category : 'private' }
GbxServerInterface >> loginFlags
[
	"Answer an integer with various bits set according to
	 what login variations are needed/wanted."

	"  GCI_LOGIN_PW_ENCRYPTED = 1, /* The gemstonePassword is encrypted. */
	   GCI_LOGIN_IS_SUBORDINATE = 2, /* Session created by this login
		 * is a child of the current session and will be terminated if the
		 * current session terminates. Intended for GciInterface .
		 * ignored in linked session login */
	   GCI_LOGIN_FULL_COMPRESSION_ENABLED = 4, /*support for full compression */
	   GCI_LOGIN_ERRS_USE_REF_SET = 8,/* oop fields of GciErrSType
								  * added to ReferencedSet instead of PureExportSet */
	   GCI_LOGIN_QUIET          = 0x10,
	   GCI_CLIENT_DOES_SESSION_INIT = 0x20,/* a GCI_LOGIN_ flag ,
		  Non-zero value ignored unless STN_ALLOW_NO_SESSION_INIT=TRUE in stone config.
		  Non-zero means GCI application
		  will do
			 GciPerform(OOP_CLASS_GSCURRENT_SESSION, 'initialize', NULL, 0);
		  after a successful GciLogin.  Zero means that the VM
		  is supposed to do that message send itself as part of GciLogin */

	   /* add next flag bit here and adjust GCI_LOGIN_ALL_FLAGS */
	   GCI_TS_CLIENT       =  0x40, /* a GCI_LOGIN_ flag,
		   *  bit is controlled by libgcirpc and libgcits
		   * and bit in flags arg passed to GciLoginEx and GciTsLogin is ignored */
	   GCI_PASSWORDLESS_LOGIN = 0x80, /* authenticate using Kerberos / GSSAPI ,
		   * ignored by GciX509Login  */

	   GCI_LOGIN_SOLO =      0x100,   /* also in image/gsparams.gs */

	   GCI_WINDOWS_CLIENT = 0x200, // controlled by libgci code
	   GCI_ONETIME_PASSWORD = 0x400, // password is a one-time security token"

	^self subclassResponsibility
]

{ #category : 'private' }
GbxServerInterface >> loginUser: username password: password flags: loginFlags 
[
	"Private. Make the GciLogin() call. 
	This must be done in the proper context.
	The sender must hold GciCallProtect"

	^callSequencer performCheck: 
			[self gbsMessenger statusTag: #GciLogin message: ''.
			callSequencer primInterface 
				gciLoginUsername: username gbxAsCString
				password: password gbxAsCString
				flags: loginFlags
				haltOnErr: -1]
]

{ #category : 'traversal buffers' }
GbxServerInterface >> allocateTraversalBufferFor: aServerInteraction 
[
	"Answer a locked traversal buffer.

	Sender must hold my session's sessionProtect."

	^traversalBufferManager allocateBufferFor: aServerInteraction
		size: thisSession configuration traversalBufferSize
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> sessionIsRemote
[
	"GciSessionIsRemote"
	"sender must hold session's sessionProtect, error processing can create a delegate"

	^callSequencer
		setSessionPerformCheck: [callSequencer primInterface gciSessionIsRemote]
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> softBreak
[
	"Note: do NOT acquire my accessProtect semaphore. 
	The thread we're trying to interrupt already has it."

	self doneWithTraversal.	"If we're in a traversal sequence, this will invalidate it."
	^callSequencer 
		setSessionPerformCheck: [callSequencer primInterface gciSoftBreak]
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> isRemote
[
	"GciIsRemote -- answers false if we've loaded the gcilnk library, true if it's the gcirpc library.
	Does not necessarily determine whether any given session is linked."
	"Sender must hold session's sessionProtect"

	^callSequencer isRemote
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> isLoggedIn
[
	"Answer true if my session is logged in or a GbsError if
      it is not.
	Should only be sent if the session thinks it is logged in
	(has a non-zero session ID)."

	"Implemented by calling GciSetSessionId, which will
       detect an error if the GCI doesn't think our session
       is still logged in."

	| maybeError |
	maybeError := callSequencer setSessionPerformCheck: [].
	^maybeError gbxIsGSError ifTrue: [maybeError] ifFalse: [true]
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> loginLinked: linked passwords: passwords errorHolder: errorHolder 
[
	"Log in and answer an integer representing the local (client) session id.  If the login
	 fails, answer 0.  If an error occurs, it will be placed in the first element of errorHolder, normally an Array."

	^callSequencer loginCall: 
			[| result |
			result := self 
						setNetFor: thisSession
						linked: linked
						hostPassword: (passwords at: 2).
			result gbxIsGSError 
				ifTrue: [errorHolder at: 1 put: result]
				ifFalse: 
					[result := self 
								loginUser: thisSession parameters username
								password: (passwords at: 1)
								flags: self loginFlags.
					result gbxIsGSError ifTrue: [errorHolder at: 1 put: result]]]
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> loginX509: parameters errorHolder: errorHolder
[
	"Log in and answer an integer representing the local (client) session id.  If the login
	 fails, answer 0.  If an error occurs, it will be placed in the first element of errorHolder, normally an Array."

	^callSequencer loginCall: 
			[| result |
			result := self x509LoginFor: parameters.
			result gbxIsGSError ifTrue: [errorHolder at: 1 put: result]]
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> logout
[
	"Changed in GBS 5.2 018 to go through the accessProtect semaphore too."

	^callSequencer setSessionPerformCheck: 
			[self gbsMessenger 
				statusTag: #GciLogout
				message: '(s%1)'
				with: self session sessionId.
			callSequencer primInterface gciLogout]
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> newMessageSend
[
	^self subclassResponsibility
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> newServerEvaluation
[
	^self subclassResponsibility
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> newServerTraversal
[
	^self subclassResponsibility
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> checkAuth: arrayOfGSObjects
[
	
	| result size buffer |
	result := callSequencer
		setSessionPerformCheck:
			[size := arrayOfGSObjects size.
			buffer := self byteFetchBufferOfSize: size.
			callSequencer primInterface
				gciCheckAuth: (self oopArrayFromDelegates: arrayOfGSObjects) asAddress
				with: size
				with: buffer asAddress].
	^result gbxIsGSError
		ifTrue: [result]
		ifFalse: [buffer asByteArrayOfSize: size]
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> pollForSignalFor: session deferFatalErrors: deferFatalErrors
[

	| resultOrError |
	resultOrError := callSequencer setSessionPerformCheck: 
					[| resultOrPrimFail |
					resultOrPrimFail := callSequencer primInterface gciPollForSignal.
					resultOrPrimFail gbxIsGSError ifFalse: [resultOrPrimFail := session].
					resultOrPrimFail].
	resultOrError gbxIsGSError
		ifTrue: 
			[(deferFatalErrors and: [session causeOfDeath == resultOrError])
				ifTrue: [resultOrError deferProcessing: true]
			"This error should be reraised in an application thread"].
	^resultOrError
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> saveFetchedOops: delegates
[

	self subclassResponsibility
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> dirtyObjectsInit
[
	"GciDirtyObjsInit"

	^callSequencer 
		setSessionPerformCheck: [callSequencer primInterface gciDirtyObjsInit]
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> getFreeOops: numberOfOops
[
	
	| result buffer |
	buffer := self oopFetchBufferOfSize: numberOfOops.
	result := callSequencer
		setSessionPerformCheck:
			[callSequencer primInterface
				gciGetFreeOops: numberOfOops
				with: buffer asAddress].
	result gbxIsGSError
		ifFalse:
			[result := buffer asDelegateArrayOfSize: numberOfOops forSession:
					thisSession].
	^result
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> saveObjects: delegates
[
	"Delegates must be a sequenceable collection."

	| oopArrayAddr size |
	oopArrayAddr := (self oopArrayFromDelegates: delegates) asAddress.
	size := delegates size.
	^callSequencer setSessionPerformCheck: 
			[callSequencer primInterface gciSaveObjs: oopArrayAddr with: size]
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> getSignalHandle
[
	^callSequencer getSignalHandle
]

{ #category : 'GbsSession interface' }
GbxServerInterface >> hardBreak
[
	"Note: do NOT acquire my accessProtect semaphore. 
	The thread we're trying to interrupt already has it."

	self doneWithTraversal.	"If we're in a traversal sequence, this will invalidate it."
	^callSequencer setSessionPerformCheck: [callSequencer primInterface gciHardBreak]
]

{ #category : 'retrievalFlags' }
GbxServerInterface >> exportFlag
[
	"We generally want to add any traversed objects to the pure export set. 
	The flag for this is GCI_RETRIEVE_EXPORT, whose value is 1."

	^1
]

{ #category : 'retrievalFlags' }
GbxServerInterface >> retrievalFlagsForServerInteraction: serverInteraction
[

	| retrievalFlags |
	retrievalFlags := 0.
	serverInteraction shouldExportResults
		ifTrue: [retrievalFlags := retrievalFlags + self exportFlag].
	^retrievalFlags
]

{ #category : 'initialize-release' }
GbxServerInterface >> initializeNoLongerReplicatedOops
[

	noLongerReplicatedOops := Set new
]

{ #category : 'initialize-release' }
GbxServerInterface >> initializeForSession: sess configuration: config
[
	"AccessProtect uses recursion in the moreTraversal case."
	"flags arg for GciPerformNoDebug (and other calls)"

	singleStepIsRequested := false.
	needMoreTraversal := false.
	thisSession := sess.
	callSequencer := GbxGciCallSequencer forSession: sess configuration: config.
	self initializeTraversalBufferManager.
	callSequencer primInterface.	"make sure it's initialized."
	self initializeNoLongerReplicatedOops
]

{ #category : 'initialize-release' }
GbxServerInterface >> shutdownSocket: aSocket withHandle: handle 
[
	^callSequencer shutdownSocket: aSocket withHandle: handle
]

{ #category : 'traversal interface' }
GbxServerInterface >> moreTraversalInTraversal: traversal
[
	"Fill traversal's buffer with more from the server. Answer true if done, false if there is more to be traversed than would fit in the buffer, an error if there is an error during the traversal, such as server VM out of memory."
	
	| traversalComplete |
	traversalComplete := callSequencer
		gciCall:
			[self
				gciMoreTraversalBuffer: traversal buffer asAddress
				maxSize: traversal bufferSize]
		resultType: #booleanResult.
	traversalComplete gbxIsGSError
		ifTrue: [self doneWithTraversal]
		ifFalse: [traversalComplete ifTrue: [self doneWithTraversal]].
	^traversalComplete
]

{ #category : 'traversal interface' }
GbxServerInterface >> storeTraversalBuffer: aBuffer flags: anInteger
[
	
	self assertNotInTraversal.
	^callSequencer
		gciCall:
			[self
				gciStoreTravBuffer: aBuffer asAddress
				flags: anInteger]
		resultType: #voidResult
]

{ #category : 'initialization' }
GbxServerInterface class >> postLoad: aParcel 
[
	"During parcel load, by default #initialize will be sent. We can't do that here,
	because some of the code needed to run #initialize is in other parcels. Wait until
	the post-load action for the parcel to initialize."

	"Do nothing."
]

{ #category : 'initialization' }
GbxServerInterface class >> initialize
[

	GbxGciCallSequencer initialize
]

{ #category : 'instance creation' }
GbxServerInterface class >> forSession: sess 
[
	"Return a new initialized instance for the given session"

	| config |
	config := sess
		ifNil: [ GbsConfiguration current copy ]
		ifNotNil: [ sess configuration ifNil: [ GbsConfiguration current copy ] ].
	^self forSession: sess configuration: config
]

{ #category : 'instance creation' }
GbxServerInterface class >> forSession: sess configuration: config 
[
	"Return a new initialized instance for the given GbsConfiguration"

	| inst |
	inst := self new.
	inst initializeForSession: sess configuration: config.
	^inst
]
