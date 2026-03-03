Class {
	#name : 'GbsServerInterface',
	#superclass : 'Object',
	#instVars : [
		'libraryPath'
	],
	#classInstVars : [
		'UniqueInstance'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'as yet unclassified' }
GbsServerInterface class >> initialize [ UniqueInstance := nil
]

{ #category : 'class initialization' }
GbsServerInterface class >> reset [
    "Resets the singleton instance to nil"
    UniqueInstance := nil
]

{ #category : 'accessing' }
GbsServerInterface class >> uniqueInstance [ ^ UniqueInstance ifNil: [ UniqueInstance := self new ]
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
    ^ self ffiCall: #(char* GciEncrypt(char* pass, char* buf, uint64 size))
        module: libraryPath
        options: #(+ optNonThreaded)
]

{ #category : 'api - password' }
GbsServerInterface >> apiGciEncrypt: aString into: aBuffer [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(char* GciEncrypt(char* aString, void* aBuffer, int64 1024)) module: libraryPath
]

{ #category : 'api' }
GbsServerInterface >> apiGciEncrypt: s into: b size: z [ ^ self ffiCall: #(void* GciEncrypt(String s, void* b, void* z)) module: libraryPath
]

{ #category : 'api' }
GbsServerInterface >> apiGciErr: anErrorStruct [
	"Forcing optNonThreaded bypasses the worker-thread pinning crash!"
	^ self 
		ffiCall: #(bool GciErr(GciError *anErrorStruct)) 
		module: libraryPath 
		options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciErrBuffer: aByteArray [
	"Bypass all UFFI struct coercions by passing a raw byte buffer"
	^ self ffiCall: #(bool GciErr(void *aByteArray)) module: libraryPath
]

{ #category : 'ffi' }
GbsServerInterface >> apiGciErrRaw: aByteArray [
	"CRITICAL FIX: 'void *' tells Pharo to pass the safe byte payload, NOT the object header!"
	^ self ffiCall: #(bool GciErr_(void * aByteArray))
]

{ #category : 'ffi' }
GbsServerInterface >> apiGciErrSafe: aVoidPointer [
	"Uses void* so UFFI passes the raw pointer, completely preventing C-stack buffer overflows"
	^ self ffiCall: #(bool GciErr_(void *aVoidPointer))
]

{ #category : 'api - execution' }
GbsServerInterface >> apiGciExecute: aString context: aContext [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(int64 GciExecuteStr(char* aString, int64 aContext)) module: libraryPath
]

{ #category : 'api' }
GbsServerInterface >> apiGciExecuteStr: s context: c [ ^ self ffiCall: #(void* GciExecuteStr(String s, void* c)) module: libraryPath
]

{ #category : 'api' }
GbsServerInterface >> apiGciExecuteStr: string context: ctx env: env [
	"CRITICAL: optNonThreaded prevents the VM memory pinning crash!"
	^ self 
		ffiCall: #(int64 GciExecuteStr_(String string, int64 ctx, int env)) 
		module: libraryPath
		options: #( + optNonThreaded )
]

{ #category : 'api - execution' }
GbsServerInterface >> apiGciExecuteStr: aString context: aContext environment: envId [
    <primitive: #primitiveNativeCall error: errorCode>
    "Use String - matching your standalone test exactly"
    ^ self ffiCall: #(int64 GciExecuteStr_(String aString, int64 aContext, int envId)) 
           module: libraryPath 
           options: #( + optNonThreaded )
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
    ^ self ffiCall: #(int64 GciFetchOops(int64 anOop, int64 startIndex, void* aBuffer, int64 numOops))
]

{ #category : 'api - fetching' }
GbsServerInterface >> apiGciFetchSize: anOop [
    ^ self ffiCall: #(int64 GciFetchSize_(int64 anOop)) 
           options: #( + optNonThreaded )
]

{ #category : 'ffi' }
GbsServerInterface >> apiGciGetClass: anOop [
    "Fetch the Class OOP of a remote object"
    ^ self ffiCall: #( uint64 GciFetchClass ( uint64 anOop ) ) 
           module: libraryPath
]

{ #category : 'api' }
GbsServerInterface >> apiGciInit [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(int GciInit()) module: libraryPath options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciIsKindOfClass: o isKindOf: c [ ^ self ffiCall: #(int GciIsKindOfClass(void* o, void* c))
]

{ #category : 'ffi' }
GbsServerInterface >> apiGciIsString: anOop [
    ^ self ffiCall: #( bool GciIsString ( uint64 anOop ) ) 
           module: libraryPath
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciLogin: gemService user: userId pass: password [
    <primitive: #primitiveNativeCall error: errorCode>
    self logGciCall: 'Login attempt for user: ', userId readString.
    ^ self ffiCall: #(uint64 GciLogin(void* gemService, void* userId, void* password))
        module: libraryPath
        options: #(+ optNonThreaded)
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciLoginEx: user pass: password flags: flags context: context [
    <primitive: #primitiveNativeCall error: errorCode>
    "Use String so UFFI marshals it safely to C!"
    ^ self ffiCall: #(bool GciLoginEx(String user, String password, int flags, int64 context)) 
           module: libraryPath 
           options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciLoginEx: u password: p flags: f context: c [ ^ self ffiCall: #(int GciLoginEx(void* u, void* p, int f, void* c))
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
GbsServerInterface >> apiGciSetNet: st host: h net: n service: s [ ^ self ffiCall: #(void GciSetNet(void* st, void* h, void* n, void* s))
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciTsLogin: gemService user: userId pass: password encrypted: isEncrypted remote: isRemote [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(uint64 GciTsLogin(
            char* gemService, 
            char* userId, 
            char* password, 
            int isEncrypted, 
            int isRemote,
            int 0, void* 0, int 0, int 0))
        module: libraryPath
]

{ #category : 'api - helpers' }
GbsServerInterface >> apiGciTsVersion [
    <primitive: #primitiveNativeCall error: errorCode>
    ^ self ffiCall: #(char* GciTsVersion())
        module: libraryPath
]

{ #category : 'error handling' }
GbsServerInterface >> checkError [
    "FIXED: Allocate a safe 2168-byte buffer to prevent C-library memory overflows"
    | buffer result errNum errMsg |
    buffer := ExternalAddress allocate: 2168.
    [
        result := self apiGciErr: buffer.
        (result = 1 or: [ result == true ]) ifTrue: [
            errNum := buffer signedLongAt: 5.
            errMsg := (buffer + 112) readString.
            GbsError signal: 'GemStone Error ', errNum asString, ': ', errMsg.
        ].
    ] ensure: [ buffer free ].
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

{ #category : 'as yet unclassified' }
GbsServerInterface >> checkGciError [
    | buffer errNum |
    buffer := ExternalAddress allocate: 2168.
    [
        (self apiGciErr: buffer) ifTrue: [
            errNum := buffer signedLongAt: 5. 
            Transcript cr; show: '>>> GCI ERROR ', errNum printString, ': ', (buffer + 112) readString.
        ]
    ] ensure: [ buffer free ]
]

{ #category : 'api - errors' }
GbsServerInterface >> checkGciError: anInterface [

  | buffer errNum |
  buffer := ExternalAddress allocate: 2168.
  [
    ( anInterface apiGciErr: buffer ) ifTrue: [
        errNum := buffer signedLongAt: 5. "Pharo offset for 32-bit error number"
        Transcript
          show: '>>> ERROR ' , errNum printString , ': ';
          show: ( buffer + 112 ) readString
        ]
    ] ensure: [ buffer free ]
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

  libraryPath ifNil: [ self error: 'GbsServerInterface libraryPath was not set by the Launcher!' ].
  ^ libraryPath
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
