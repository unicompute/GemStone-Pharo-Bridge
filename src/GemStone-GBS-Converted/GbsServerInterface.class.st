Class {
	#name : 'GbsServerInterface',
	#superclass : 'Object',
	#instVars : [
		'libraryPath',
		'dirtyObjectsInitialized'
	],
	#classInstVars : [
		'UniqueInstance',
		'GciAccessMutex'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'as yet unclassified' }
GbsServerInterface class >> initialize [ UniqueInstance := nil
]

{ #category : 'class initialization' }
GbsServerInterface class >> reset [
    "Resets the singleton instance to nil. The GCI access mutex is left in place:
     it is image-wide infrastructure, not per-connection state, and a session may
     be reconnecting on another process while reset runs."
    UniqueInstance := nil
]

{ #category : 'accessing' }
GbsServerInterface class >> uniqueInstance [ ^ UniqueInstance ifNil: [ UniqueInstance := self new ]
]

{ #category : 'gci serialization' }
GbsServerInterface class >> gciAccessMutex [
	"Image-wide lock serialising ALL GCI access. The current GemStone session is
	 per-process global C state in the non-reentrant libgcirpc, set by
	 GciSetSessionId_ and read by every subsequent GCI call. Because the bridge
	 uses optNonThreaded FFI and Pharo schedules concurrent work as green
	 processes, two callers could otherwise interleave their (set-session, execute)
	 pairs — one process's GciSetSessionId_ clobbers the global between another's
	 set and execute, so GciSetSessionId_ returns FALSE ('Could not activate
	 GemStone GCI session N') or a call runs against the wrong session. Holding this
	 mutex across each activate->execute makes every GCI interaction atomic.

	 Mutex (reentrant) is required: GCI blocks legitimately nest (e.g. error checks
	 inside an executing block), and a plain Semaphore would self-deadlock."
	^ GciAccessMutex ifNil: [ GciAccessMutex := Mutex new ]
]

{ #category : 'gci serialization' }
GbsServerInterface class >> gciCriticalDo: aBlock [
	^ self gciAccessMutex critical: aBlock
]

{ #category : 'api' }
GbsServerInterface >> apiGciAbort [ 
	^ self ffiCall: #(void GciAbort()) module: libraryPath
]

{ #category : 'api - session' }
GbsServerInterface >> apiGciAbort: aSessionId [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(void GciAbort(uint64 aSessionId))
        module: libraryPath
]

{ #category : 'api' }
GbsServerInterface >> apiGciAbortCurrent [
	^ self ffiCall: #(int GciAbort()) module: libraryPath options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciCommit [ ^ self ffiCall: #(int GciCommit()) module: libraryPath
]

{ #category : 'api - session' }
GbsServerInterface >> apiGciCommit: aSessionId [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(bool GciCommit(uint64 aSessionId))
        module: libraryPath
]

{ #category : 'as yet unclassified' }
GbsServerInterface >> apiGciEncrypt: pass buffer: buf size: size [
    <primitive: #primitiveNativeCall error: errorCode>
    "GCI 3.7.5: char* GciEncrypt(const char* password, char outBuff[], unsigned int outBuffSize).
    outBuffSize is a 32-bit unsigned int."
    ^ self ffiCall: #(char* GciEncrypt(char* pass, char* buf, uint size))
        module: libraryPath
        options: #(+ optNonThreaded)
]

{ #category : 'api - password' }
GbsServerInterface >> apiGciEncrypt: aString into: aBuffer [
    <primitive: #primitiveNativeCall error: errorCode>
    "GCI 3.7.5: char* GciEncrypt(const char* password, char outBuff[], unsigned int outBuffSize)."
    ^ self ffiCall: #(char* GciEncrypt(char* aString, void* aBuffer, uint 1024)) module: libraryPath
]

{ #category : 'api' }
GbsServerInterface >> apiGciEncrypt: s into: b size: z [
    "GCI 3.7.5: char* GciEncrypt(const char* password, char outBuff[], unsigned int outBuffSize). The size
    argument is a 32-bit unsigned int, not a pointer."
    ^ self ffiCall: #(char* GciEncrypt(String s, void* b, uint z)) module: libraryPath
]

{ #category : 'api' }
GbsServerInterface >> apiGciErr: aBuffer [
    ^ self 
        ffiCall: #(bool GciErr(void *aBuffer))
        module: libraryPath
        options: #( + optNonThreaded )
]

{ #category : 'ffi' }
GbsServerInterface >> apiGciErrAddress: anExternalAddress [
	"Strictly takes an ExternalAddress pointer allocated on the OS heap"
	^ self ffiCall: #(bool GciErr(void *anExternalAddress))
]

{ #category : 'api' }
GbsServerInterface >> apiGciErrBuffer: aByteArray [
	"Bypass all UFFI struct coercions by passing a raw byte buffer"
	^ self ffiCall: #(bool GciErr(void *aByteArray)) module: libraryPath
]

{ #category : 'ffi' }
GbsServerInterface >> apiGciErrRaw: aByteArray [
	"CRITICAL FIX: 'void *' tells Pharo to pass the safe byte payload, NOT the object header!"
	^ self ffiCall: #(bool GciErr(void * aByteArray))
]

{ #category : 'ffi' }
GbsServerInterface >> apiGciErrSafe: aVoidPointer [
	"Uses void* so UFFI passes the raw pointer, completely preventing C-stack buffer overflows"
	^ self apiGciErr: aVoidPointer
]

{ #category : 'api - execution' }
GbsServerInterface >> apiGciExecute: aString context: aContext [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self
        ffiCall: #(uint64 GciExecuteStr(String aString, uint64 aContext))
        module: libraryPath
        options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciExecuteStr: s context: c [
	"Canonical entrypoint delegates to 3-arg GciExecuteStr_ with env=0."
	^ self apiGciExecuteStr: s context: c env: 0
]

{ #category : 'api' }
GbsServerInterface >> apiGciExecuteStr: source context: contextOop env: env [
    "Exact C ABI: const char* + 64-bit context + 32-bit env."
    ^ self 
        ffiCall: #(uint64 GciExecuteStr_(String source, uint64 contextOop, ushort env))
        module: libraryPath
        options: #( + optNonThreaded )
]

{ #category : 'api - execution' }
GbsServerInterface >> apiGciExecuteStr: aString context: aContext environment: envId [
	"Compatibility selector; keep all ABI details in #apiGciExecuteStr:context:env:."
	^ self apiGciExecuteStr: aString context: aContext env: envId
]

{ #category : 'ffi' }
GbsServerInterface >> apiGciExecuteStrSafe: sourceString context: contextOop [
	| resultOop errorBuffer hasError |
	"Keep the safe path on top of the proven 3-arg execute call and convert
	pending runtime errors into OOP_ILLEGAL for callers that only need a safe probe."
	resultOop := self apiGciExecuteStr: sourceString context: contextOop env: 0.
	resultOop = 1 ifTrue: [ ^ 1 ].

	errorBuffer := ExternalAddress allocate: 2168.
	[
		hasError := self apiGciErr: errorBuffer.
		^ (hasError = 1 or: [ hasError == true ])
			ifTrue: [ 1 ]
			ifFalse: [ resultOop ]
	] ensure: [ errorBuffer free ]
]

{ #category : 'api - fetching' }
GbsServerInterface >> apiGciFetchBytes: anOop into: aBuffer size: bufferSize [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(int64 GciFetchBytes(int64 anOop, int64 1, void* aBuffer, int64 bufferSize)) module: libraryPath
]

{ #category : 'api - fetching' }
GbsServerInterface >> apiGciFetchBytes: anOop startingAt: startIndex into: aBuffer size: maxSize [
    ^ self ffiCall: #(int64 GciFetchBytes_(int64 anOop, int64 startIndex, void* aBuffer, int64 maxSize)) 
           options: #( + optNonThreaded )
]

{ #category : 'api - objects' }
GbsServerInterface >> apiGciFetchChars: anOop into: aBuffer [
    "Fetches characters from a GemStone object into a local buffer"
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(int64 GciFetchChars(uint64 anOop, int64 1, void* aBuffer, int64 1024))
        module: libraryPath
]

{ #category : 'api - fetching' }
GbsServerInterface >> apiGciFetchChars: anOop startingAt: startIndex into: aBuffer size: maxSize [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(int64 GciFetchChars_(int64 anOop, int64 startIndex, void* aBuffer, int64 maxSize)) 
           module: libraryPath 
           options: #( + optNonThreaded )
]

{ #category : 'api - fetching' }
GbsServerInterface >> apiGciFetchOops: anOop startingAt: startIndex into: aBuffer size: numOops [
    <primitive: #primitiveNativeCall error: errorCode>
    "GCI 3.7.5: int GciFetchOops(OopType, int64 startIndex, OopType[], int numOops). The return value and
    numOops are 32-bit int (not int64); OopType is uint64."
    ^ self ffiCall: #(int GciFetchOops(uint64 anOop, int64 startIndex, void* aBuffer, int numOops))
]

{ #category : 'api - fetching' }
GbsServerInterface >> apiGciFetchSize: anOop [
    ^ self ffiCall: #(int64 GciFetchSize_(int64 anOop)) 
           options: #( + optNonThreaded )
]

{ #category : 'ffi' }
GbsServerInterface >> apiGciGetClass: anOop [
    "GCI 3.7.5: OopType GciFetchClass(OopType theObject). There is no GciFetchClass_ symbol in the GCI
    library; a trailing underscore here resolves (via GCI_WEAK) to a NULL function pointer. Use the real
    GciFetchClass and keep optNonThreaded for the linked-session calling convention. The Core overlay binds
    the same correct selector; this converted definition keeps the Original load working too."
    ^ self
		ffiCall: #( uint64 GciFetchClass(uint64 anOop) )
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciInit [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(int GciInit()) module: libraryPath options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciIsKindOfClass: anObj isKindOf: aClass [
    "GCI 3.7.5: BoolType(=int) GciIsKindOfClass(OopType anObj, OopType aClass). OOPs are uint64, not
    pointers; binding them as void* is type-incorrect even though it happens to be 8 bytes on LP64."
    ^ self ffiCall: #(int GciIsKindOfClass(uint64 anObj, uint64 aClass))
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciLogin: gemService user: userId pass: password [
    <primitive: #primitiveNativeCall error: errorCode>
    "GCI 3.7.5: BoolType GciLogin(const char username[], const char password[]). GciLogin takes only the
    GemStone username and password -- network parameters come from a prior GciSetNet*. There is no
    gemService parameter; the first argument is the username. gemService is accepted for caller
    compatibility but not passed."
    self logGciCall: 'Login attempt for user: ', userId readString.
    ^ self ffiCall: #(int GciLogin(void* userId, void* password))
        module: libraryPath
        options: #(+ optNonThreaded)
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciLoginEx: user pass: password flags: flags context: context [
    <primitive: #primitiveNativeCall error: errorCode>
    "GCI 3.7.5: BoolType GciLoginEx(const char username[], const char password[], unsigned int loginFlags,
    int haltOnErrNum). The fourth argument is haltOnErrNum (a 32-bit int), not a context pointer/int64; the
    'context:' keyword is retained for caller compatibility but maps to haltOnErrNum."
    ^ self ffiCall: #(int GciLoginEx(String user, String password, uint flags, int context))
           module: libraryPath
           options: #( + optNonThreaded )
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciLoginEx_: user password: password flags: flags haltOn: haltOn executedSessionInit: executedSessionInit [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self
        ffiCall: #(int GciLoginEx_(String user, String password, uint flags, int haltOn, void* executedSessionInit))
        module: libraryPath
        options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciLoginEx: u password: p flags: f context: c [
    "GCI 3.7.5: BoolType GciLoginEx(const char username[], const char password[], unsigned int loginFlags,
    int haltOnErrNum). The fourth argument is a 32-bit int (haltOnErrNum), not a pointer; username/password
    are C strings, not opaque pointers."
    ^ self ffiCall: #(int GciLoginEx(void* u, void* p, uint f, int c))
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciLoginEx: gemService user: userId pass: password [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(uint64 GciLoginEx(
            void* gemService, 
            void* userId, 
            void* password,
            void* 0,        "hostUserId"
            void* 0,        "hostPassword"
            int 0,          "loginFlags"
            int 0           "haltOnConnect"))
        module: libraryPath
        options: #(+ optNonThreaded)
]

{ #category : 'api' }
GbsServerInterface >> apiGciLogout [ ^ self ffiCall: #(int GciLogout())
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciLogout: sessionId [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(bool GciLogout(int sessionId))
]

{ #category : 'api' }
GbsServerInterface >> apiGciPollForSignal [
	^ self ffiCall: #(int GciPollForSignal()) module: libraryPath options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciSetNet: aStone [
    "Mandatory GS64 step found in C++ test"
    ^ self 
        ffiCall: #(void GciSetNet(String aStone, void* nil1, void* nil2, void* nil3))
        module: libraryPath
        options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciSetNet: st host: h net: n service: s [
    "GCI 3.7.5: void GciSetNet(const char StoneName[], const char HostUserId[], const char HostPassword[],
    const char GemService[]). All four arguments are C strings. The keyword order here is
    stone/host(user)/net(=hostPassword)/service."
    ^ self ffiCall: #(void GciSetNet(String st, String h, String n, String s))
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciSetNetEx_: stone hostUser: hostUser hostPassword: hostPassword service: service encrypted: encrypted error: errString size: maxErrSize [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self
        ffiCall: #(int GciSetNetEx_(String stone, String hostUser, String hostPassword, String service, int encrypted, void* errString, uint64 maxErrSize))
        module: libraryPath
        options: #( + optNonThreaded )
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciSetNetEx__: stone hostUser: hostUser hostPassword: hostPassword service: service encrypted: encrypted error: errString size: maxErrSize netldi: netldiName [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self
        ffiCall: #(int GciSetNetEx__(String stone, String hostUser, String hostPassword, String service, int encrypted, void* errString, uint64 maxErrSize, String netldiName))
        module: libraryPath
        options: #( + optNonThreaded )
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciTsLoginStone: stoneNrs hostUser: hostUserId hostPassword: hostPassword hostPwEncrypted: hostPwEncrypted gemService: gemServiceNrs gsUser: gsUser gsPassword: gsPassword flags: loginFlags haltOn: haltOnErrNum executedSessionInit: executedSessionInit error: errBuf [
    <primitive: #primitiveNativeCall error: errorCode>
    "GCI 3.7.5 (gcits.hf): GciSession GciTsLogin(const char* StoneNameNrs, const char* HostUserId,
    const char* HostPassword, BoolType hostPwIsEncrypted, const char* GemServiceNrs,
    const char* gemstoneUsername, const char* gemstonePassword, unsigned int loginFlags, int haltOnErrNum,
    BoolType* executedSessionInit, GciErrSType* err). Eleven arguments; the prior binding had only nine and
    the wrong argument order. Returns a GciSession pointer (NULL on failure)."
    ^ self ffiCall: #(void* GciTsLogin(String stoneNrs, String hostUserId, String hostPassword, int hostPwEncrypted, String gemServiceNrs, String gsUser, String gsPassword, uint loginFlags, int haltOnErrNum, void* executedSessionInit, void* errBuf))
        module: libraryPath
]

{ #category : 'api - helpers' }
GbsServerInterface >> apiGciTsVersionInto: aBuffer size: bufSize [
    <primitive: #primitiveNativeCall error: errorCode>
    "GCI 3.7.5 (gcits.hf): uint GciTsVersion(char* buf, size_t bufSize). The prior no-argument binding did
    not match the C prototype."
    ^ self ffiCall: #(uint GciTsVersion(void* aBuffer, uint64 bufSize))
        module: libraryPath
]


{ #category : 'error handling' }
GbsServerInterface >> checkForError [
	| cBuffer hasError errorMsg contextOop |
	
	"1. Allocate a massive 2.5KB buffer. No structs, impossible to overflow!"
	cBuffer := ByteArray new: 2500.
	
	"2. Fetch the error directly into our raw bytes"
	hasError := GbsServerInterface uniqueInstance apiGciErrRaw: cBuffer.
	
	hasError ifTrue: [ 
		"3. Extract the context OOP (8 bytes) starting at index 9"
		contextOop := cBuffer integerAt: 9 size: 8 signed: false.
		
		"4. Extract the message string starting at index 114"
		errorMsg := (cBuffer copyFrom: 114 to: 1138) asString.
		errorMsg := errorMsg copyUpTo: Character null. "Trim the C null-terminators"
		
		"5. Signal the error to the UI!"
		(GbsError new messageText: errorMsg; tag: contextOop) signal.
		
	] ifFalse: [ 
		(GbsError new messageText: 'Unknown GemStone Error'; tag: 20) signal.
	].
	
	^ nil
]



{ #category : 'execution' }
GbsServerInterface >> execute: aString inSession: aSessionId [
    ^ self apiGciExecuteStr: aString context: aSessionId environment: 0.
]

{ #category : 'execution' }
GbsServerInterface >> executeAndFetchString: aString [
    | utf8Bytes cString resultOop size cBuffer fetched resultString |
    
    "1. Get raw bytes"
    utf8Bytes := aString utf8Encoded.
    
    "2. Allocate C-memory for the input string (like const char* printScript)"
    cString := ExternalAddress allocate: utf8Bytes size + 1.
    
    [
        "Write bytes directly into C-memory and null-terminate"
        1 to: utf8Bytes size do: [ :i | cString unsignedByteAt: i put: (utf8Bytes at: i) ].
        cString unsignedByteAt: utf8Bytes size + 1 put: 0.
        
        "3. Execute (like GciExecuteStr_(printScript, 20, 0))"
        resultOop := self apiGciExecuteStr: cString context: 20 environment: 0.
        
        "Catch exact C-code error states"
        resultOop = 1 ifTrue: [ ^ '<error: Compile Error>' ].
        resultOop = 20 ifTrue: [ ^ 'nil' ].
        
        "4. Fetch Size (like GciFetchSize_(stringOop))"
        size := self apiGciFetchSize: resultOop.
        (size isNil or: [ size <= 0 ]) ifTrue: [ ^ '' ].
        
        "5. Allocate C-buffer and Fetch Bytes (like malloc and GciFetchBytes_)"
        cBuffer := ExternalAddress allocate: size + 1.
        [
            fetched := self apiGciFetchBytes: resultOop startingAt: 1 into: cBuffer size: size.
            cBuffer unsignedByteAt: size + 1 put: 0. "Null terminate"
            
            resultString := cBuffer readString.
        ] ensure: [ cBuffer free ].
        
    ] ensure: [ cString free ].
    
    ^ resultString asString
]

{ #category : 'initialization' }
GbsServerInterface >> initialize [
	super initialize.
	libraryPath := self defaultLibraryPath.
	dirtyObjectsInitialized := false
]

{ #category : 'private' }
GbsServerInterface >> defaultLibraryPath [
	| os |
	os := OSPlatform current.
	os isMacOS ifTrue: [ ^ GbsLibrary macLibraryName ].
	os isUnix ifTrue: [ ^ GbsLibrary unixLibraryName ].
	os isWindows ifTrue: [ ^ GbsLibrary win32LibraryName ].
	^ nil
]

{ #category : 'execution' }
GbsServerInterface >> executeAndPrint: aString inSession: aSessionId [
    | stringOop |
    stringOop := self apiGciExecuteStr: aString context: aSessionId environment: 0.
    ^ self fetchString: stringOop.
]

{ #category : 'fetching' }
GbsServerInterface >> fetchString: stringOop [
    | size cBuffer fetched resultString |
    
    "Match Step 3: Fetch Size & Allocate C-buffer"
    size := self apiGciFetchSize: stringOop.
    (size isNil or: [ size <= 0 ]) ifTrue: [ ^ '' ].
    
    cBuffer := ExternalAddress allocate: size + 1.
    
    "Match Step 4: Fetch Bytes & Null Terminate"
    [
        fetched := self apiGciFetchBytes: stringOop startingAt: 1 into: cBuffer size: size.
        cBuffer unsignedByteAt: size + 1 put: 0.
        
        resultString := cBuffer readString.
    ] ensure: [ 
        cBuffer free. 
    ].
    
    ^ resultString asString.
]

{ #category : 'ffi-binding' }
GbsServerInterface >> ffiLibraryName [
  "UFFI calls this dynamically on the first FFI execution. 
     If it is nil, the compiler will crash."

  ^ libraryPath ifNil: [ libraryPath := self defaultLibraryPath ]
]

{ #category : 'GemStone-GBS-Converted' }
GbsServerInterface >> gciExecuteStr: aSource context: aContext [
    ^ self apiGciExecuteStr: aSource context: aContext environment: 0
]

{ #category : 'converting' }
GbsServerInterface >> gciLogin: aService user: aUser password: aPassword [ 
	"The converted code likely calls this. We handle the encryption automatically here."
	| encBuffer session |
	encBuffer := ExternalAddress allocate: 1024.
	[
		self resetDirtyObjectsInitialization.
		self apiGciInit. "Ensure library is initialized"
		self apiGciEncrypt: aPassword into: encBuffer.
		session := self apiGciLogin: aService user: aUser pass: encBuffer.
	] ensure: [ encBuffer free ].
	^ session

]

{ #category : 'accessing' }
GbsServerInterface >> libraryName [ 
    ^ libraryPath
]

{ #category : 'accessing' }
GbsServerInterface >> libraryName: aString [ 
    libraryPath := aString
]

{ #category : 'accessing' }
GbsServerInterface >> libraryPath [ ^ libraryPath
]

{ #category : 'accessing' }
GbsServerInterface >> libraryPath: aString [
    "Allow the Launcher UI to inject the physical file path"
    libraryPath := aString
]

{ #category : 'debugging' }
GbsServerInterface >> logGciCall: aString [ 
    Transcript show: '[GCI] ', aString; cr
]

{ #category : 'conversion' }
GbsServerInterface >> resultFor: anOop [
    | classOop |
    (anOop isNil or: [ anOop asInteger = 0 ]) ifTrue: [ ^ nil ].
    
    "Check for SmallInteger (bit 0 is 1)"
    (anOop asInteger bitAnd: 1) = 1 ifTrue: [ ^ anOop asInteger >> 1 ].
    
    "Check for common literals like nil, true, false (Special OOPs)"
    anOop asInteger = 20 ifTrue: [ ^ nil ].
    anOop asInteger = 268 ifTrue: [ ^ true ].
    anOop asInteger = 140 ifTrue: [ ^ false ].

    "Get the Class of the remote object"
    classOop := self apiGciGetClass: anOop.
    
    "GemStone String classes: String=74, Symbol=110, DoubleByteString=146"
    (#(74 110 146) includes: classOop asInteger) ifTrue: [ ^ self fetchString: anOop ].
    
    "Otherwise, return the Proxy"
    ^ GbsProxy for: anOop session: GbsSessionParameters currentSession.
]
