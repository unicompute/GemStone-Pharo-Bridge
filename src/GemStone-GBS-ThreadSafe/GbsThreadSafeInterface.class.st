"
Thread-safe GCI (GciTs*) interface for the GemStone-Pharo-Bridge.

Unlike the legacy GbsServerInterface, which relies on per-process global current-
session C state (GciSetSessionId_) and therefore needs the image-wide
GciAccessMutex to stop concurrent green processes clobbering each other, every
call here takes an explicit GciSession pointer. There is no global to clobber, so
the 'Could not activate GemStone GCI session N' race cannot occur and distinct
sessions cannot clobber each other's current-session state. Calls still pass
through the bridge's FFI library-binding mutex; this class promises session
correctness, not parallel execution inside one Pharo image.

This is a prototype of the hot path (login / executeAndFetchString / logout /
commit / abort) wired behind the existing bridge API. It does NOT yet replace the
full GbsServerInterface surface.

Instance Variables:
  session - ExternalAddress / ExternalData: the GciSession (void*) returned by
            GciTsLogin. nil until login succeeds.
  pendingReleaseOops - bounded batch of fetched result OOPs awaiting
            GciTsReleaseObjs; batching avoids a release round trip per read.
  releaseQueueMutex - per-interface reentrant lock protecting the release batch
            across FFI yield points.
"
Class {
	#name : 'GbsThreadSafeInterface',
	#superclass : 'Object',
	#instVars : [
		'session',
		'pendingReleaseOops',
		'releaseQueueMutex',
		'resolvedByteClassOops'
	],
	#classVars : [
		'SessionRegistry',
		'FfiMutex',
		'LastFfiLibraryPath',
		'LibraryPathOverride'
	],
	#pools : [
		'GbsGciTypes'
	],
	#category : 'GemStone-GBS-ThreadSafe',
	#package : 'GemStone-GBS-ThreadSafe'
}

{ #category : 'ffi version mutex' }
GbsThreadSafeInterface class >> ffiMutex [
	"Image-wide lock serialising thread-safe GCI calls against a library-version
	switch. The compiled FFI methods bind to whichever client library was resolved
	when they were first run; if the resolved path changes (a different GemStone
	client-lib version), they must be reset and recompiled. Holding this mutex across
	the version check + the call keeps that atomic. Ported from PharoGemStoneFFI
	(GciInterface FfiMutex). Reentrant (Mutex) so nested ffiDo: blocks are safe."
	^ FfiMutex ifNil: [ FfiMutex := Mutex new ]
]

{ #category : 'ffi version mutex' }
GbsThreadSafeInterface class >> resetFfiMethods [
	"Force the package's compiled FFI methods back to their non-compiled form so the
	next call rebinds against the currently-resolved client library. Pharo stores the
	original under the #ffiNonCompiledMethod property when it compiles an ffiCall:.
	Ported from PharoGemStoneFFI (GciInterface resetFfiMethods)."
	self package classes do: [ :cls |
		cls methods do: [ :cm |
			(cm hasProperty: #ffiNonCompiledMethod) ifTrue: [
				cm methodClass methodDict
					at: cm selector
					put: (cm propertyAt: #ffiNonCompiledMethod) ] ] ]
]

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

{ #category : 'library path' }
GbsThreadSafeInterface class >> libraryPathOverride [
	"An explicit absolute path to the thread-safe (libgcits) client library, or nil
	to use the default resolution. Takes precedence over the env var and the
	stem-swap default -- the escape hatch for multi-version / non-standard installs."
	^ LibraryPathOverride
]

{ #category : 'library path' }
GbsThreadSafeInterface class >> libraryPathOverride: aStringOrNil [
	LibraryPathOverride := aStringOrNil
]

{ #category : 'library path' }
GbsThreadSafeInterface class >> libraryPathFromEnvironment [
	"An explicit libgcits path from the environment, or nil. Lets a deployment point
	the thread-safe interface at a specific client library without code changes."
	| env value |
	env := [ OSEnvironment current ] on: Error do: [ :e | nil ].
	env ifNil: [ ^ nil ].
	#( 'GS_THREADSAFE_LIBRARY' 'GEMSTONE_THREADSAFE_LIB' ) do: [ :key |
		value := [ env at: key ifAbsent: [ nil ] ] on: Error do: [ :e | nil ].
		(value notNil and: [ value isEmpty not ]) ifTrue: [ ^ value ] ].
	^ nil
]

{ #category : 'library path' }
GbsThreadSafeInterface class >> isWindowsPlatform [
	^ [ OSPlatform current isWindows ] on: Error do: [ :e | false ]
]

{ #category : 'library path' }
GbsThreadSafeInterface class >> addLibraryDirectoryToWindowsPath: aLibraryPath [
	"On Windows the vc-runtime DLLs sit beside the GCI library, so the library's
	directory must be on PATH for them to load (GemStone bug 48680). No-op elsewhere
	or when the directory is already present."
	| dir env path |
	self isWindowsPlatform ifFalse: [ ^ self ].
	aLibraryPath ifNil: [ ^ self ].
	dir := aLibraryPath asFileReference parent pathString.
	env := [ OSEnvironment current ] on: Error do: [ :e | nil ].
	env ifNil: [ ^ self ].
	path := [ env at: 'PATH' ifAbsent: [ '' ] ] on: Error do: [ :e | '' ].
	(path includesSubstring: dir) ifTrue: [ ^ self ].
	[ env at: 'PATH' put: path , ';' , dir ] on: Error do: [ :e | nil ]
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

{ #category : 'constants' }
GbsThreadSafeInterface class >> resultOopReleaseBatchSize [
	"Match GemStone's own GsTsExternalSession batching policy closely enough to
	bound the PureExportSet without adding a release round trip to every read."
	^ 100
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
	"Resolve the path to the thread-safe (libgcits) client library, in precedence:
	   1. an explicit override set via libraryPathOverride:,
	   2. a GS_THREADSAFE_LIBRARY / GEMSTONE_THREADSAFE_LIB env var,
	   3. the default: reuse the bridge's resolved legacy path (same install/version)
	      and swap the rpc/lnk stem for the thread-safe libgcits- stem.
	The GciTs* symbols live in libgcits, never the legacy libgcirpc/libgcilnk. On
	Windows the library's directory is added to PATH so the vc-runtime DLLs load."
	| path |
	path := self resolveGsLibraryPath.
	self class addLibraryDirectoryToWindowsPath: path.
	^ path
]

{ #category : 'accessing' }
GbsThreadSafeInterface >> resolveGsLibraryPath [
	| override fromEnv legacyPath |
	override := self class libraryPathOverride.
	(override notNil and: [ override isEmpty not ]) ifTrue: [ ^ override ].
	fromEnv := self class libraryPathFromEnvironment.
	fromEnv ifNotNil: [ ^ fromEnv ].
	legacyPath := GbsServerInterface uniqueInstance libraryPath.
	legacyPath ifNil: [ ^ nil ].
	^ (legacyPath
		copyReplaceAll: 'libgcirpc-' with: 'libgcits-')
		copyReplaceAll: 'libgcilnk-' with: 'libgcits-'
]

{ #category : 'ffi version mutex' }
GbsThreadSafeInterface >> ffiDo: aBlock [
	"Run a thread-safe GCI operation under the image-wide FFI mutex, resetting the
	compiled FFI methods first if the resolved client-library path has changed since
	the last call. This makes the version check and the call atomic so concurrent
	callers cannot bind to different library versions. Ported from PharoGemStoneFFI
	(GciInterface ffiDo:)."
	^ self class ffiMutex critical: [
		self checkFfiLibraryVersion.
		aBlock value ]
]

{ #category : 'ffi version mutex' }
GbsThreadSafeInterface >> checkFfiLibraryVersion [
	"If the resolved client-library path differs from the one the compiled FFI
	methods were last bound to, reset them so the next call rebinds against the
	current library. The library path encodes the version (e.g.
	libgcits-3.7.5-64.dylib), so a path change is a version change."
	| current |
	current := self gsLibraryPath.
	current = LastFfiLibraryPath ifTrue: [ ^ self ].
	self class resetFfiMethods.
	LastFfiLibraryPath := current
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
GbsThreadSafeInterface >> gciTsReleaseObjs: sess objects: objects count: count gsError: gsError [
	^ self ffiCall: #( int32 GciTsReleaseObjs(
			void *sess,
			uint64 *objects,
			int32 count,
			GbsGciErrSType *gsError) )
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
	result := self ffiDo: [ self
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
		err: gsError getHandle ].
	result isNull ifTrue: [ ^ GbsGciTsError signalForError: gsError tracker: tracker ].
	session := result.
	pendingReleaseOops := OrderedCollection new.
	releaseQueueMutex := Mutex new.
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
	result := self ffiDo: [ self gciTsLogout: session gsError: gsError ].
	session := nil.
	result == 1 ifTrue: [
		pendingReleaseOops := nil.
		tracker freeAll.
		^ true ].
	^ GbsGciTsError signalForError: gsError tracker: tracker
]

{ #category : 'transaction' }
GbsThreadSafeInterface >> abort [
	| tracker gsError result |
	self assertLoggedIn.
	tracker := GbsMemoryTracker new.
	gsError := tracker add: GbsGciErrSType externalNew.
	result := self ffiDo: [ self gciTsAbort: session gsError: gsError ].
	result == 1 ifTrue: [ tracker freeAll. ^ true ].
	^ GbsGciTsError signalForError: gsError tracker: tracker
]

{ #category : 'transaction' }
GbsThreadSafeInterface >> commit [
	| tracker gsError result |
	self assertLoggedIn.
	tracker := GbsMemoryTracker new.
	gsError := tracker add: GbsGciErrSType externalNew.
	result := self ffiDo: [ self gciTsCommit: session gsError: gsError ].
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
	gciResult := self ffiDo: [ self
		gciTsExecute_: session
		sourceString: srcCstring getHandle
		sourceStringSize: srcCstring sizeNoNull
		sourceOop: self class oopClassString
		contextObject: self class oopNil
		symbolList: self class oopNil
		flags: 0
		envId: 0
		gsError: gsError getHandle ].
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
	result := self ffiDo: [ self
		gciTsNbExecute: session
		sourceString: srcCstring getHandle
		sourceOop: self class oopClassString
		contextObject: self class oopNil
		symbolList: self class oopNil
		flags: flags
		envId: 0
		gsError: gsError getHandle ].
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
	result := self ffiDo: [ self gciTsNbPoll: session timeoutMs: delayMs gsError: gsError getHandle ].
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
	resultOop := self ffiDo: [ self gciTsNbResult: session gsError: gsError getHandle ].
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
	gciResult := self ffiDo: [ self
		gciTsFetchObjInfo: session
		object: oop
		addToExportSet: 0
		resultInfo: objInfo getHandle
		resultBuffer: resultBuf getHandle
		resultBufferSize: resultBuf size
		gsError: gsError getHandle ].
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
	gciResult := self ffiDo: [ self
		gciTsExecuteFetchBytes: session
		sourceString: srcCstring getHandle
		sourceStringSize: srcCstring sizeNoNull
		sourceOop: self class oopClassString
		contextObject: self class oopNil
		symbolList: self class oopNil
		resultBuffer: resultBuf getHandle
		resultBufferSize: resultBuf size
		gsError: gsError getHandle ].
	gciResult < 0 ifTrue: [ ^ GbsGciTsError signalForError: gsError tracker: tracker ].
	gciResult > maxSize ifTrue: [
		[ self error: ('Result buffer size (' , maxSize asString
			, ') is too small (Gci returned ' , gciResult asString , ' bytes)') ]
				ensure: [ tracker freeAll ] ].
	^ [ resultBuf asByteStringOfSize: gciResult ] ensure: [ tracker freeAll ]
]

{ #category : 'execution' }
GbsThreadSafeInterface >> executeAndFetchStringDynamic: sourceString [
	"Execute sourceString and return the result with dynamic buffer sizing.
	For byte-object results (String/ByteArray/Symbol), fetches the bytes with
	a buffer that grows as needed. For immediate results
	(SmallInteger/Boolean/nil), returns the local value. For other objects
	(class objects, dictionaries, etc.), signals an explicit unsupported-result
	error so a transport limitation cannot be mistaken for a legitimate remote
	nil. Callers should use string scripts that return byte-object snapshots.

	This is the primary read primitive for GbsThreadSafeSession. Unlike
	#executeAndFetchString: (fixed 1024-byte buffer), it handles arbitrarily
	large snapshots up to the defensive 64 MiB limit by reading the object size
	from GciTsFetchObjInfo and reallocating the buffer when needed."

	| tracker |
	self assertLoggedIn.
	tracker := GbsMemoryTracker new.
	^ [
		self executeDynamic: sourceString tracker: tracker ]
		ensure: [ tracker freeAll ]
]

{ #category : 'private' }
GbsThreadSafeInterface >> executeDynamic: sourceString tracker: tracker [
	"Private — caller owns the tracker lifecycle (via ensure: freeAll)."

	| srcCstring gsError resultOop local |
	srcCstring := self convertStringArg: sourceString tracker: tracker.
	gsError := tracker add: GbsGciErrSType externalNew.
	resultOop := self ffiDo: [ self
		gciTsExecute_: session
		sourceString: srcCstring getHandle
		sourceStringSize: srcCstring sizeNoNull
		sourceOop: self class oopClassString
		contextObject: self class oopNil
		symbolList: self class oopNil
		flags: 0
		envId: 0
		gsError: gsError getHandle ].
	resultOop == self class oopIllegal ifTrue: [
		^ GbsGciTsError signalForError: gsError tracker: tracker ].
	resultOop == self class oopNil ifTrue: [ ^ nil ].
	local := self class asLocalObject: resultOop.
	local == Object ifFalse: [ ^ local ].
	[ local := self fetchBytesForOop: resultOop tracker: tracker gsError: gsError ]
		on: Error
		do: [ :error |
			"The execute already exported resultOop, even when local fetch/validation
			fails. Preserve the original fetch error if a threshold-triggered release
			also fails; flushPendingResultOops keeps the batch intact for retry."
			[ self queueResultOopForRelease: resultOop ] on: Error do: [ :ignored | ].
			error pass ].
	self queueResultOopForRelease: resultOop.
	^ local
]

{ #category : 'private' }
GbsThreadSafeInterface >> fetchBytesForOop: anOop tracker: tracker gsError: gsError [
	"Fetch a byte object (String/ByteArray/Symbol) by OOP with dynamic buffer
	sizing. GciTsFetchObjInfo's function result reports success/body slots, not
	the authoritative byte-object length; objInfo objSize is the total byte size.
	Use objSize to decide whether a second fetch is required and how many bytes
	to materialize, matching GemStone's GsTsExternalSession implementation.
	Signals for non-byte objects so they cannot be confused with remote nil."

	| objInfo resultBuf bufferCapacity requiredSize gciResult classOop |
	objInfo := tracker add: GbsGciTsObjInfo externalNew.
	bufferCapacity := 8192.
	resultBuf := tracker add: (GbsExternalByteString new: bufferCapacity).
	gciResult := self ffiDo: [ self
		gciTsFetchObjInfo: session
		object: anOop
		addToExportSet: 0
		resultInfo: objInfo getHandle
		resultBuffer: resultBuf getHandle
		resultBufferSize: bufferCapacity
		gsError: gsError getHandle ].
	gciResult < 0 ifTrue: [
		^ GbsGciTsError signalForError: gsError tracker: tracker ].
	objInfo objId = anOop ifFalse: [
		^ self error: 'GciTsFetchObjInfo returned inconsistent object identity.' ].
	classOop := objInfo objClass.
	classOop = 0 ifTrue: [
		^ GbsError signal: 'Thread-safe GCI read access denied for result object.' ].
	(self byteResultClassOops includes: classOop) ifFalse: [
		^ GbsUnsupportedThreadSafeResultError signal:
			'Thread-safe GCI evaluate returned unsupported non-byte object class OOP '
			, classOop asString
			, '; return a String, ByteArray, Symbol, or immediate value instead.' ].
	requiredSize := objInfo objSize.
	(requiredSize < 0 or: [ requiredSize > (64 * 1024 * 1024) ]) ifTrue: [
		^ self error: 'Result object size out of range (' , requiredSize asString , ' bytes)' ].
	requiredSize > bufferCapacity ifTrue: [
		resultBuf free.
		tracker remove: resultBuf ifAbsent: [ nil ].
		bufferCapacity := requiredSize.
		resultBuf := tracker add: (GbsExternalByteString new: bufferCapacity).
		gciResult := self ffiDo: [ self
			gciTsFetchObjInfo: session
			object: anOop
			addToExportSet: 0
			resultInfo: objInfo getHandle
			resultBuffer: resultBuf getHandle
			resultBufferSize: bufferCapacity
			gsError: gsError getHandle ].
		gciResult < 0 ifTrue: [
			^ GbsGciTsError signalForError: gsError tracker: tracker ].
		(objInfo objSize = requiredSize) ifFalse: [
			^ self error: 'Result object size changed between fetches' ] ].
	classOop == self class oopClassByteArray ifTrue: [
		^ resultBuf asByteArrayOfSize: requiredSize ].
	classOop == self class oopClassSymbol ifTrue: [
		^ (resultBuf asByteStringOfSize: requiredSize) asSymbol ].
	^ resultBuf asByteStringOfSize: requiredSize
]

{ #category : 'private' }
GbsThreadSafeInterface >> flushPendingResultOops [
	"Release one bounded batch of result OOPs. Keep the batch intact on failure
	so callers can retry or let logout dispose of the session export set."
	^ self resultOopReleaseMutex critical: [
		| releaseOops tracker oopBuffer gsError result |
		pendingReleaseOops ifNil: [ ^ true ].
		pendingReleaseOops isEmpty ifTrue: [ ^ true ].
		releaseOops := pendingReleaseOops asArray.
		tracker := GbsMemoryTracker new.
		[
			oopBuffer := tracker add: (FFIExternalArray
				externalNewType: 'uint64'
				size: releaseOops size).
			1 to: releaseOops size do: [ :index |
				oopBuffer at: index put: (releaseOops at: index) ].
			gsError := tracker add: GbsGciErrSType externalNew.
			result := self ffiDo: [ self
				gciTsReleaseObjs: session
				objects: oopBuffer getHandle
				count: releaseOops size
				gsError: gsError getHandle ].
			result == 1 ifFalse: [
				^ GbsGciTsError signalForError: gsError tracker: tracker ].
			pendingReleaseOops removeAll.
			true ] ensure: [ tracker freeAll ] ]
]

{ #category : 'private' }
GbsThreadSafeInterface >> queueResultOopForRelease: anOop [
	"GciTsExecute_ exports non-immediate result OOPs. Dynamic evaluation returns
	fully local bytes (or rejects the shape), so queue every result for bounded,
	batched release instead of leaking it or paying one extra trip per read."
	self resultOopReleaseMutex critical: [
		pendingReleaseOops ifNil: [ pendingReleaseOops := OrderedCollection new ].
		pendingReleaseOops add: anOop.
		pendingReleaseOops size >= self class resultOopReleaseBatchSize ifTrue: [
			self flushPendingResultOops ] ].
	^ anOop
]

{ #category : 'private' }
GbsThreadSafeInterface >> resultOopReleaseMutex [
	^ releaseQueueMutex ifNil: [ releaseQueueMutex := Mutex new ]
]

{ #category : 'accessing' }
GbsThreadSafeInterface >> session [
	^ session
]

{ #category : 'constants' }
GbsThreadSafeInterface >> byteResultClassOops [
	"Class OOPs accepted as byte-object results by the dynamic transport.
	 Resolved from the LIVE stone on first use: the hardcoded class-side
	 constants (String=74753 etc.) are build-specific, so on a stone whose
	 canonical OOPs differ every valid String result raised
	 GbsUnsupportedThreadSafeResultError (OkZulu bridge audit 2026-07-17).
	 The accepted set stays String/ByteArray/Symbol -- only the OOP values
	 are resolved; per-name resolution is guarded and falls back to the
	 constants so a resolution failure can never make things worse."
	^ resolvedByteClassOops ifNil: [
		| oops |
		oops := Set new.
		#('String' 'ByteArray' 'Symbol') do: [ :name |
			[ oops add: (self executeScriptAndReturnOop: name) ]
				on: Error
				do: [ :ignored | nil ] ].
		oops isEmpty ifTrue: [
			oops
				add: self class oopClassString;
				add: self class oopClassByteArray;
				add: self class oopClassSymbol ].
		resolvedByteClassOops := oops ]
]
