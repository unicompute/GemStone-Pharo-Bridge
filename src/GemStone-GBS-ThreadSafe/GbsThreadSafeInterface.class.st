"
Thread-safe GCI (GciTs*) interface for the GemStone-Pharo-Bridge.

Unlike the legacy GbsServerInterface, which relies on per-process global current-
session C state (GciSetSessionId_) and therefore needs the image-wide
GciAccessMutex to stop concurrent green processes clobbering each other, every
call here takes an explicit GciSession pointer. There is no global to clobber, so
the 'Could not activate GemStone GCI session N' race cannot occur and distinct
sessions can run concurrently.

This is a prototype of the hot path (login / executeAndFetchString / logout /
commit / abort) wired behind the existing bridge API. It does NOT yet replace the
full GbsServerInterface surface.

Instance Variables:
  session - ExternalAddress / ExternalData: the GciSession (void*) returned by
            GciTsLogin. nil until login succeeds.
"
Class {
	#name : 'GbsThreadSafeInterface',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#classVars : [
		'SessionRegistry'
	],
	#pools : [
		'GbsGciTypes'
	],
	#category : 'GemStone-GBS-ThreadSafe',
	#package : 'GemStone-GBS-ThreadSafe'
}

{ #category : 'session registry' }
GbsThreadSafeInterface class >> interfaceForSession: aSessionParameters [
	"Answer the thread-safe interface bound to aSessionParameters, or nil."
	^ self sessionRegistry at: aSessionParameters ifAbsent: [ nil ]
]

{ #category : 'session registry' }
GbsThreadSafeInterface class >> interfaceForSession: aSessionParameters put: anInterface [
	^ self sessionRegistry at: aSessionParameters put: anInterface
]

{ #category : 'session registry' }
GbsThreadSafeInterface class >> removeInterfaceForSession: aSessionParameters [
	^ self sessionRegistry removeKey: aSessionParameters ifAbsent: [ nil ]
]

{ #category : 'session registry' }
GbsThreadSafeInterface class >> sessionRegistry [
	"Transient map of GbsSessionParameters -> GbsThreadSafeInterface. Prototype
	scaffolding so the interface need not live on the converted session class."
	^ SessionRegistry ifNil: [ SessionRegistry := IdentityDictionary new ]
]

{ #category : 'constants' }
GbsThreadSafeInterface class >> gciPerformDetach [
	"GCI perform flag: fork the execution on the gem and detach the client, so the
	gem keeps running if the client logs out or the socket closes. Requires
	GemStone 3.7.1+."
	^ 16r40
]

{ #category : 'constants' }
GbsThreadSafeInterface class >> oopClassByteArray [
	^ 103425
]

{ #category : 'constants' }
GbsThreadSafeInterface class >> oopClassString [
	^ 74753
]

{ #category : 'constants' }
GbsThreadSafeInterface class >> oopClassSymbol [
	^ 110849
]

{ #category : 'constants' }
GbsThreadSafeInterface class >> oopFalse [
	^ 140
]

{ #category : 'constants' }
GbsThreadSafeInterface class >> oopIllegal [
	^ 1
]

{ #category : 'constants' }
GbsThreadSafeInterface class >> oopNil [
	^ 20
]

{ #category : 'constants' }
GbsThreadSafeInterface class >> oopNumTagBits [
	^ 3
]

{ #category : 'constants' }
GbsThreadSafeInterface class >> oopTagSmallInt [
	^ 2
]

{ #category : 'constants' }
GbsThreadSafeInterface class >> oopTagSpecialMask [
	^ 6
]

{ #category : 'constants' }
GbsThreadSafeInterface class >> oopTrue [
	^ 268
]

{ #category : 'converting' }
GbsThreadSafeInterface class >> asLocalObject: anOop [
	"Answer a local Boolean or SmallInteger for an immediate OOP, or Object when
	the value is not an easy immediate (caller must then fetch the bytes).
	Caller must check oopNil before calling."
	anOop == self oopTrue ifTrue: [ ^ true ].
	anOop == self oopFalse ifTrue: [ ^ false ].
	anOop == self oopNil ifTrue: [ ^ nil ].
	(self oopIsSmallInt: anOop) ifTrue: [ ^ self oopToSmallInt: anOop ].
	^ Object
]

{ #category : 'converting' }
GbsThreadSafeInterface class >> oopIsSmallInt: anOop [
	^ self oopTagSmallInt == (anOop bitAnd: self oopTagSpecialMask)
]

{ #category : 'converting' }
GbsThreadSafeInterface class >> oopToSmallInt: anOop [
	^ anOop bitShift: self oopNumTagBits negated
]

{ #category : 'accessing' }
GbsThreadSafeInterface >> gsLibraryPath [
	"The thread-safe GciTs* symbols live in libgcits, NOT in the legacy libgcirpc
	that GbsServerInterface loads. Reuse the bridge's resolved path (so we pick up
	the same GemStone install and version) but swap the rpc/lnk stem for the
	thread-safe one. This is the libgcits-/libgcirpc- distinction that
	PharoGemStoneFFI encodes in its fileNameStem."
	| legacyPath |
	legacyPath := GbsServerInterface uniqueInstance libraryPath.
	legacyPath ifNil: [ ^ nil ].
	^ (legacyPath
		copyReplaceAll: 'libgcirpc-' with: 'libgcits-')
		copyReplaceAll: 'libgcilnk-' with: 'libgcits-'
]

{ #category : 'testing' }
GbsThreadSafeInterface >> isLoggedIn [
	^ session notNil
]

{ #category : 'private' }
GbsThreadSafeInterface >> convertStringArg: aString tracker: tracker [
	"Convert a Pharo string to a tracked C string, or NULL for nil/empty."
	^ (aString notNil and: [ aString isEmpty not ])
		ifTrue: [ tracker add: (GbsExternalByteString newFromByteString: aString trimBoth) ]
		ifFalse: [ FFIExternalObject null ]
]

{ #category : 'ffi calls' }
GbsThreadSafeInterface >> ffiLibraryName [
	^ self gsLibraryPath
]

{ #category : 'ffi calls' }
GbsThreadSafeInterface >> gciTsLogin: stnNrs hostUserId: hostUid hostPassword: hostPw hostPwIsEncrypted: hostPwEnc gemNrs: gemNrs gsUserId: gsUid gsPassword: gsPw loginFlags: lFlags haltOnErrorNum: haltNum executedSessInit: aBoolPtr err: gsErr [
	^ self ffiCall: #( void* GciTsLogin(
			const char *stnNrs,
			const char *hostUid,
			const char *hostPw,
			int32 hostPwEnc,
			const char *gemNrs,
			const char *gsUid,
			const char *gsPw,
			uint32 lFlags,
			int32 haltNum,
			int32 *aBoolPtr,
			GbsGciErrSType *gsErr) )
		module: self gsLibraryPath
]

{ #category : 'ffi calls' }
GbsThreadSafeInterface >> gciTsLogout: sess gsError: gsError [
	^ self ffiCall: #( int32 GciTsLogout(void *sess, GbsGciErrSType *gsError) )
		module: self gsLibraryPath
]

{ #category : 'ffi calls' }
GbsThreadSafeInterface >> gciTsAbort: sess gsError: gsError [
	^ self ffiCall: #( int32 GciTsAbort(void *sess, GbsGciErrSType *gsError) )
		module: self gsLibraryPath
]

{ #category : 'ffi calls' }
GbsThreadSafeInterface >> gciTsCommit: sess gsError: gsError [
	^ self ffiCall: #( int32 GciTsCommit(void *sess, GbsGciErrSType *gsError) )
		module: self gsLibraryPath
]

{ #category : 'ffi calls' }
GbsThreadSafeInterface >> gciTsFetchObjInfo: sess object: objId addToExportSet: aBoolean resultInfo: objInfo resultBuffer: resultBuf resultBufferSize: resultBufSize gsError: gsError [
	"Fetch an object's class/size info plus its bytes in one call. Used to
	materialize a non-immediate Nb result (String / Symbol / ByteArray)."
	^ self ffiCall: #( int64 GciTsFetchObjInfo(
			void *sess,
			OopType objId,
			int32 aBoolean,
			GbsGciTsObjInfo *objInfo,
			char *resultBuf,
			size_t resultBufSize,
			GbsGciErrSType *gsError) )
		module: self gsLibraryPath
]

{ #category : 'ffi calls' }
GbsThreadSafeInterface >> gciTsNbExecute: sess sourceString: src sourceOop: srcOop contextObject: ctx symbolList: symList flags: flags envId: envId gsError: gsError [
	"Start a non-blocking execute against this session's explicit pointer. Returns
	immediately; the result is later collected with GciTsNbResult."
	^ self ffiCall: #( int32 GciTsNbExecute(
			void *sess,
			const char *src,
			OopType srcOop,
			OopType ctx,
			OopType symList,
			int flags,
			uint16 envId,
			GbsGciErrSType *gsError) )
		module: self gsLibraryPath
]

{ #category : 'ffi calls' }
GbsThreadSafeInterface >> gciTsNbPoll: sess timeoutMs: timeoutMs gsError: gsError [
	"Poll a pending non-blocking call. Returns 1 if complete, 0 if still running,
	-1 on error. Blocks up to timeoutMs (-1 = block forever)."
	^ self ffiCall: #( int GciTsNbPoll(void *sess, int timeoutMs, GbsGciErrSType *gsError) )
		module: self gsLibraryPath
]

{ #category : 'ffi calls' }
GbsThreadSafeInterface >> gciTsNbResult: sess gsError: gsError [
	"Collect the result OOP of a completed non-blocking call (oopIllegal on error)."
	^ self ffiCall: #( int64 GciTsNbResult(void *sess, GbsGciErrSType *gsError) )
		module: self gsLibraryPath
]

{ #category : 'ffi calls' }
GbsThreadSafeInterface >> gciTsExecute_: sess sourceString: src sourceStringSize: srcSize sourceOop: srcOop contextObject: ctx symbolList: symList flags: flags envId: envId gsError: gsError [
	"Execute a source string and return the result OOP (an OopType), without
	fetching its bytes. The thread-safe counterpart of the legacy GciExecuteStr_."
	^ self ffiCall: #( int64 GciTsExecute_(
			void *sess,
			const char *src,
			int64 srcSize,
			OopType srcOop,
			OopType ctx,
			OopType symList,
			int flags,
			ushort envId,
			GbsGciErrSType *gsError) )
		module: self gsLibraryPath
]

{ #category : 'ffi calls' }
GbsThreadSafeInterface >> gciTsExecuteFetchBytes: sess sourceString: src sourceStringSize: srcSize sourceOop: srcOop contextObject: ctx symbolList: symList resultBuffer: resultBuf resultBufferSize: resultBufSize gsError: gsError [
	^ self ffiCall: #( int64 GciTsExecuteFetchBytes(
			void *sess,
			const char *src,
			int64 srcSize,
			OopType srcOop,
			OopType ctx,
			OopType symList,
			char *resultBuf,
			int64 resultBufSize,
			GbsGciErrSType *gsError) )
		module: self gsLibraryPath
]

{ #category : 'login' }
GbsThreadSafeInterface >> loginStoneNrs: stoneNrs gemNrs: gemNrs gsUser: gsUser gsPassword: gsPassword hostUser: hostUser hostPassword: hostPassword [
	"Single-call login via GciTsLogin. Returns true on success or signals a
	GbsGciTsError. Stores the returned GciSession pointer in 'session'."
	| tracker exStone exGem exGsUser exGsPw exHostUser exHostPw exBoolPtr gsError result |
	self isLoggedIn ifTrue: [ ^ self error: 'session is already logged in' ].
	tracker := GbsMemoryTracker new.
	exStone := self convertStringArg: stoneNrs tracker: tracker.
	exGem := self convertStringArg: gemNrs tracker: tracker.
	exGsUser := self convertStringArg: gsUser tracker: tracker.
	exGsPw := self convertStringArg: gsPassword tracker: tracker.
	exHostUser := self convertStringArg: hostUser tracker: tracker.
	exHostPw := self convertStringArg: hostPassword tracker: tracker.
	exBoolPtr := tracker add: (FFIExternalArray externalNewType: 'int32' size: 1).
	gsError := tracker add: GbsGciErrSType externalNew.
	result := self
		gciTsLogin: exStone getHandle
		hostUserId: exHostUser getHandle
		hostPassword: exHostPw getHandle
		hostPwIsEncrypted: 0
		gemNrs: exGem getHandle
		gsUserId: exGsUser getHandle
		gsPassword: exGsPw getHandle
		loginFlags: 0
		haltOnErrorNum: 0
		executedSessInit: exBoolPtr getHandle
		err: gsError getHandle.
	result isNull ifTrue: [ ^ GbsGciTsError signalForError: gsError tracker: tracker ].
	session := result.
	tracker freeAll.
	^ true
]

{ #category : 'login' }
GbsThreadSafeInterface >> logout [
	"Logout this session. Signals on failure. Returns true."
	| tracker gsError result |
	self isLoggedIn ifFalse: [ ^ self error: 'session is not logged in' ].
	tracker := GbsMemoryTracker new.
	gsError := tracker add: GbsGciErrSType externalNew.
	result := self gciTsLogout: session gsError: gsError.
	session := nil.
	result == 1 ifTrue: [ tracker freeAll. ^ true ].
	^ GbsGciTsError signalForError: gsError tracker: tracker
]

{ #category : 'transaction' }
GbsThreadSafeInterface >> abort [
	| tracker gsError result |
	self assertLoggedIn.
	tracker := GbsMemoryTracker new.
	gsError := tracker add: GbsGciErrSType externalNew.
	result := self gciTsAbort: session gsError: gsError.
	result == 1 ifTrue: [ tracker freeAll. ^ true ].
	^ GbsGciTsError signalForError: gsError tracker: tracker
]

{ #category : 'transaction' }
GbsThreadSafeInterface >> commit [
	| tracker gsError result |
	self assertLoggedIn.
	tracker := GbsMemoryTracker new.
	gsError := tracker add: GbsGciErrSType externalNew.
	result := self gciTsCommit: session gsError: gsError.
	result == 1 ifTrue: [ tracker freeAll. ^ true ].
	^ GbsGciTsError signalForError: gsError tracker: tracker
]

{ #category : 'private' }
GbsThreadSafeInterface >> assertLoggedIn [
	self isLoggedIn ifFalse: [ ^ self error: 'session is not logged in' ]
]

{ #category : 'execution' }
GbsThreadSafeInterface >> executeAndFetchString: sourceString [
	"Execute sourceString and return its result as a ByteString in a single round
	trip via GciTsExecuteFetchBytes. Replaces the legacy three-trip dance
	(GciExecuteStr -> GciFetchSize_ -> GciFetchBytes_). Signals a GbsGciTsError on
	failure. Result is truncated to maxSize bytes (default 1024)."
	^ self executeAndFetchString: sourceString maxResultSize: 1024
]

{ #category : 'execution' }
GbsThreadSafeInterface >> executeScriptAndReturnOop: sourceString [
	"Execute sourceString and return the result object's OOP as a SmallInteger,
	without materializing it. Thread-safe counterpart of the legacy
	executeScriptAndReturnOop: -- uses GciTsExecute_ against this session's explicit
	pointer, so it never touches GCI's global current session. Signals a
	GbsGciTsError on failure."
	| tracker srcCstring gsError gciResult |
	self assertLoggedIn.
	tracker := GbsMemoryTracker new.
	srcCstring := self convertStringArg: sourceString tracker: tracker.
	gsError := tracker add: GbsGciErrSType externalNew.
	gciResult := self
		gciTsExecute_: session
		sourceString: srcCstring getHandle
		sourceStringSize: srcCstring sizeNoNull
		sourceOop: self class oopClassString
		contextObject: self class oopNil
		symbolList: self class oopNil
		flags: 0
		envId: 0
		gsError: gsError getHandle.
	gciResult == self class oopIllegal ifTrue: [
		^ GbsGciTsError signalForError: gsError tracker: tracker ].
	tracker freeAll.
	^ gciResult
]

{ #category : 'execution (nonblocking)' }
GbsThreadSafeInterface >> executeStringNb: sourceString [
	"Start non-blocking execution of sourceString. Returns true once started (the
	server runs it asynchronously); collect the result later with
	blockAndFetchNbResult / getNbCallStatusWithMaxDelay:. Signals on start failure."
	^ self executeStringNb: sourceString flags: 0
]

{ #category : 'execution (nonblocking)' }
GbsThreadSafeInterface >> executeStringAndDetachNb: sourceString [
	"Start non-blocking execution of sourceString and tell the gem to stop servicing
	this client and ignore disconnects -- i.e. fork the work on the server and let
	the client log out while it keeps running. Returns true once started. Requires
	GemStone 3.7.1+."
	^ self executeStringNb: sourceString flags: self class gciPerformDetach
]

{ #category : 'execution (nonblocking)' }
GbsThreadSafeInterface >> executeStringNb: sourceString flags: flags [
	| tracker srcCstring gsError result |
	self assertLoggedIn.
	tracker := GbsMemoryTracker new.
	srcCstring := self convertStringArg: sourceString tracker: tracker.
	gsError := tracker add: GbsGciErrSType externalNew.
	result := self
		gciTsNbExecute: session
		sourceString: srcCstring getHandle
		sourceOop: self class oopClassString
		contextObject: self class oopNil
		symbolList: self class oopNil
		flags: flags
		envId: 0
		gsError: gsError getHandle.
	result == 1 ifFalse: [ ^ GbsGciTsError signalForError: gsError tracker: tracker ].
	tracker freeAll.
	^ true
]

{ #category : 'execution (nonblocking)' }
GbsThreadSafeInterface >> getNbCallStatusWithMaxDelay: delayMs [
	"Poll a pending non-blocking call, blocking up to delayMs (-1 = forever).
	Answer true if it has completed, false if still running; signal if the session
	was terminated."
	| tracker gsError result |
	tracker := GbsMemoryTracker new.
	gsError := tracker add: GbsGciErrSType externalNew.
	result := self gciTsNbPoll: session timeoutMs: delayMs gsError: gsError getHandle.
	result == -1 ifTrue: [ ^ GbsGciTsError signalForError: gsError tracker: tracker ].
	tracker freeAll.
	result == 1 ifTrue: [ ^ true ].
	result == 0 ifTrue: [ ^ false ].
	^ self error: 'Unexpected GciTsNbPoll result: ', result printString
]

{ #category : 'execution (nonblocking)' }
GbsThreadSafeInterface >> blockAndFetchNbResult [
	"Block until a previously-started non-blocking execute completes, then return its
	result (Boolean / SmallInteger / nil for immediates, or a String / Symbol /
	ByteArray up to 1024 bytes). Signals on error or oversize result."
	^ self blockAndFetchNbResultWithMaxSize: 1024
]

{ #category : 'execution (nonblocking)' }
GbsThreadSafeInterface >> blockAndFetchNbResultWithMaxSize: maxSize [
	| tracker gsError resultOop local |
	self assertLoggedIn.
	tracker := GbsMemoryTracker new.
	gsError := tracker add: GbsGciErrSType externalNew.
	resultOop := self gciTsNbResult: session gsError: gsError getHandle.
	resultOop == self class oopIllegal ifTrue: [
		^ GbsGciTsError signalForError: gsError tracker: tracker ].
	resultOop == self class oopNil ifTrue: [ tracker freeAll. ^ nil ].
	local := self class asLocalObject: resultOop.
	local == Object ifTrue: [
		"Non-immediate result: materialize its bytes via GciTsFetchObjInfo."
		^ self doFetchResultByteObject: resultOop maxResultSize: maxSize tracker: tracker ].
	tracker freeAll.
	^ local
]

{ #category : 'execution' }
GbsThreadSafeInterface >> doFetchResultByteObject: oop maxResultSize: maxSize tracker: tracker [
	"Materialize a byte object (String / Symbol / ByteArray) result via
	GciTsFetchObjInfo. The tracker owns all C allocations and is freed on every exit."
	| resultBuf gsError objInfo gciResult classOop |
	resultBuf := tracker add: (GbsExternalByteString newWithNull: maxSize).
	gsError := tracker add: GbsGciErrSType externalNew.
	objInfo := tracker add: GbsGciTsObjInfo externalNew.
	gciResult := self
		gciTsFetchObjInfo: session
		object: oop
		addToExportSet: 0
		resultInfo: objInfo getHandle
		resultBuffer: resultBuf getHandle
		resultBufferSize: resultBuf size
		gsError: gsError getHandle.
	gciResult < 0 ifTrue: [ ^ GbsGciTsError signalForError: gsError tracker: tracker ].
	gciResult > maxSize ifTrue: [
		[ self error: ('Result buffer size (' , maxSize asString
			, ') is too small (Gci returned ' , gciResult asString , ' bytes)') ]
				ensure: [ tracker freeAll ] ].
	classOop := objInfo objClass.
	classOop == self class oopClassByteArray ifTrue: [
		^ [ resultBuf asByteArrayOfSize: gciResult ] ensure: [ tracker freeAll ] ].
	(classOop == self class oopClassString or: [ classOop == self class oopClassSymbol ])
		ifFalse: [
			[ self error: 'Unexpected result class OOP ', classOop printString ]
				ensure: [ tracker freeAll ] ].
	^ [
		| str |
		str := resultBuf asByteStringOfSize: gciResult.
		classOop == self class oopClassSymbol ifTrue: [ str := str asSymbol ].
		str ] ensure: [ tracker freeAll ]
]

{ #category : 'execution' }
GbsThreadSafeInterface >> executeAndFetchString: sourceString maxResultSize: maxSize [
	| tracker srcCstring resultBuf gsError gciResult |
	self assertLoggedIn.
	tracker := GbsMemoryTracker new.
	srcCstring := self convertStringArg: sourceString tracker: tracker.
	resultBuf := tracker add: (GbsExternalByteString newWithNull: maxSize).
	gsError := tracker add: GbsGciErrSType externalNew.
	gciResult := self
		gciTsExecuteFetchBytes: session
		sourceString: srcCstring getHandle
		sourceStringSize: srcCstring sizeNoNull
		sourceOop: self class oopClassString
		contextObject: self class oopNil
		symbolList: self class oopNil
		resultBuffer: resultBuf getHandle
		resultBufferSize: resultBuf size
		gsError: gsError getHandle.
	gciResult < 0 ifTrue: [ ^ GbsGciTsError signalForError: gsError tracker: tracker ].
	gciResult > maxSize ifTrue: [
		[ self error: ('Result buffer size (' , maxSize asString
			, ') is too small (Gci returned ' , gciResult asString , ' bytes)') ]
				ensure: [ tracker freeAll ] ].
	^ [ resultBuf asByteStringOfSize: gciResult ] ensure: [ tracker freeAll ]
]

{ #category : 'accessing' }
GbsThreadSafeInterface >> session [
	^ session
]
