Class {
	#name : 'GbsSession',
	#superclass : 'Object',
	#instVars : [
		'isLoggedIn',
		'sessionOop',
		'parameters',
		'pollingProcess',
		'serverInterface',
		'sessionId'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'as yet unclassified' }
GbsSession class >> loginWithUser: aUser password: aPass stone: aStone [
    | interface sessionID servicePtr userPtr passPtr |
    interface := GbsServerInterface uniqueInstance.
    interface apiGciInit.
    
    servicePtr := ExternalAddress fromString: aStone.
    userPtr := ExternalAddress fromString: aUser.
    passPtr := ExternalAddress fromString: aPass.
    
    [
        sessionID := interface apiGciLogin: servicePtr user: userPtr pass: passPtr.
        sessionID = 0 ifTrue: [ ^ nil ].
        
        ^ self new 
            instVarNamed: 'sessionId' put: sessionID;
            instVarNamed: 'serverInterface' put: interface;
            yourself
    ] ensure: [ servicePtr free. userPtr free. passPtr free ]
]

{ #category : 'transactions' }
GbsSession >> abort [
    "Discards uncommitted changes and syncs with the latest GemStone state."
    GbsServerInterface uniqueInstance apiGciAbort: self sessionOop.
    ^ true.
]

{ #category : 'transactions' }
GbsSession >> abortTransaction [
  "Aborts the current transaction."

  | result |
  self isLoggedIn ifFalse: [ GbsError signal: 'Not logged in.' ].

  result := self gciAbort.
  result = 1 ifFalse: [ "Abort rarely fails unless the connection is dead, but we should catch it."
    GbsError signal: 'Failed to abort transaction.' ].
  ^ true
]

{ #category : 'evaluating' }
GbsSession >> basicEvaluate: aString [

  | resultOop |
  resultOop := GbsServerInterface uniqueInstance
                 apiGciExecuteStr: aString
                 context: sessionOop
                 environment: 0.
  ^ GbsServerInterface uniqueInstance resultFor: resultOop
]

{ #category : 'error handling' }
GbsSession >> checkAndClearError [
	| buffer errMsg contextOop |
	buffer := ExternalAddress allocate: 2168.
	[
		"Tell the C-library to give us the error and RESET its internal state"
		GbsServerInterface uniqueInstance apiGciErr: buffer.
		
		"Use the 64-bit offsets we verified from your gci_layout_mac.txt"
		contextOop := buffer unsignedLongLongAt: 9. "Offset 8"
		errMsg := (buffer + 113) readString. "Offset 112"
		
		(GbsError new messageText: errMsg; tag: contextOop) signal.
	] ensure: [ buffer free ].
]

{ #category : 'error handling' }
GbsSession >> checkForError [
	| buffer result errNum errMsg contextOop gbsError |

	buffer := ExternalAddress allocate: 2168.
	[
		result := GbsServerInterface uniqueInstance apiGciErr: buffer.

		(result = 1 or: [ result == true ]) ifTrue: [
			"CRITICAL: Exact GS64 64-bit Memory Offsets!"
			errNum := buffer signedLongAt: 105. "C-offset 104"
			contextOop := buffer unsignedLongLongAt: 9. "C-offset 8 - this is the suspended context"
			errMsg := (buffer + 113) readString. "C-offset 113"

			"Log for debugging"
			Transcript show: 'checkForError: result=', result asString, ' contextOop=', contextOop asString; cr.

			"Create the error with BOTH the message and the context OOP"
			gbsError := GbsError new messageText: errMsg; tag: contextOop.
			gbsError gemStoneExceptionProxy: nil.
			gbsError signal.
		].
		"Only signal if there's actually an error (result = 1 or true)"
	] ensure: [
		buffer free.
	].

	^ nil
]

{ #category : 'as yet unclassified' }
GbsSession >> checkSignals [
	| signalResult |
	signalResult := self gciPollForSignal.
	
	signalResult = 4 ifTrue: [ TransactionBacklog signal ].
	signalResult = 1 ifTrue: [ AlmostOutOfMemory signal ].
	
	signalResult > 0 ifTrue: [ 
		Transcript cr; show: 'GemStone Signal: ', signalResult asString 
	].
]

{ #category : 'transactions' }
GbsSession >> commit [
    "Flushes local object changes to the GemStone database."
    ^ GbsServerInterface uniqueInstance apiGciCommit: self sessionOop.
]

{ #category : 'transactions' }
GbsSession >> commitTransaction [
	"Attempts to commit. Returns true if successful, false if there is a conflict.
	 You can extend this later to raise a GbsTransactionConflictError."
	| result |
	self isLoggedIn ifFalse: [ GbsError signal: 'Not logged in.' ].
	
	result := self gciCommit.
	^ result = 1
]

{ #category : 'execution' }
GbsSession >> evaluate: s [ 
    | i r | 
    i := GbsServerInterface uniqueInstance.
    r := i apiGciExecuteStr: s context: 20 environment: 0. 
    
    "CRITICAL: Only check for errors if GemStone returned OOP_ILLEGAL (1)"
    r = 1 ifTrue: [ 
        i checkError. 
        ^ self error: 'GemStone Evaluation Failed' 
    ]. 
    
    ^ self fetchObject: r asInteger
]

{ #category : 'evaluating' }
GbsSession >> evaluateAndFetchString: aString [
    | resultOop |
    resultOop := GbsServerInterface uniqueInstance 
        apiGciExecuteStr: aString 
        context: sessionOop 
        environment: 0.
    ^ GbsServerInterface uniqueInstance fetchString: resultOop.
]

{ #category : 'execution' }
GbsSession >> evaluateBlock: aBlock [
    "Compiles the block source to a string and executes it on the server"
    ^ self evaluateString: aBlock sourceNode body sourceCode
]

{ #category : 'evaluating' }
GbsSession >> evaluateString: aString [
	| resultOop buffer size |
	"Use self serverInterface instead of the raw variable!"
	resultOop := self serverInterface apiGciExecute: aString context: 20.
	
	(resultOop bitAnd: 7) = 2 ifTrue: [ ^ resultOop bitShift: -3 ].
	resultOop = 20 ifTrue: [ ^ nil ].

	buffer := ExternalAddress allocate: 1024.
	[
		size := self serverInterface apiGciFetchChars: resultOop into: buffer.
		size > 0 ifTrue: [ ^ (buffer copyFrom: 1 to: size) asString ].
	] ensure: [ buffer free ].

	^ resultOop
]

{ #category : 'execution' }
GbsSession >> execute: script [
	| resultOop |

	resultOop := GbsServerInterface uniqueInstance
		apiGciExecuteStr: script context: 20 env: 0.

	"If result is 1, follow C++ logic: handle the error IMMEDIATELY"
	resultOop = 1 ifTrue: [ ^ self handleGciError ].

	^ self resultFor: resultOop
]

{ #category : 'execution' }
GbsSession >> executeAndFetch: script [
	^ self executeAndFetch: script context: 20
]

{ #category : 'execution' }
GbsSession >> executeAndFetch: script context: contextOop [
	"Executes code and fetches the resulting String safely."
	| interface stringOop |

	interface := GbsServerInterface uniqueInstance.
	stringOop := interface apiGciExecuteStr: script context: contextOop env: 0.

	"SAFE ERROR CHECKING - No C-Structs!"
	stringOop = 1 ifTrue: [ ^ 'Error: GemStone Compile Error' ].
	stringOop = 20 ifTrue: [ ^ 'nil' ].

	^ interface fetchString: stringOop.
]

{ #category : 'error handling' }
GbsSession >> fetchLastError [
	| errStruct success errorMessage |
	errStruct := GciErrSType externalNew.
	[
		success := GbsServerInterface uniqueInstance apiGciErr: errStruct.
		success ifFalse: [ ^ 'Unknown GemStone Error' ].
		
		"Extract the message using your existing struct definition"
		errorMessage := errStruct message asString. 
		^ errorMessage
	] ensure: [ 
		errStruct free 
	]
]

{ #category : 'marshaling' }
GbsSession >> fetchObject: anOop [
	| i szPtr sz buf str classOop |
	"1. Literal / Immediate Checks"
	anOop = 20 ifTrue: [ ^ nil ]. 
	anOop = 268 ifTrue: [ ^ true ]. 
	anOop = 12 ifTrue: [ ^ false ]. 
	(anOop bitAnd: 7) = 2 ifTrue: [ ^ (anOop bitShift: -3) ]. "SmallInteger"

	i := GbsServerInterface uniqueInstance.

	"2. String Check (Class 74753)"
	(i apiGciIsKindOfClass: anOop isKindOf: 74753) = 1 ifTrue: [
		szPtr := i apiGciFetchSize: anOop.
		sz := szPtr asInteger. (sz <= 0) ifTrue: [ ^ '' ].
		buf := ExternalAddress allocate: sz + 1.
		[ i apiGciFetchChars: anOop startingAt: 1 into: buf size: sz + 1. 
		  str := String new: sz. 
		  1 to: sz do: [ :x | str at: x put: (buf unsignedByteAt: x) asCharacter ]. 
		] ensure: [ buf free ].
		^ str 
	].

	"3. DateTime Marshaling"
	(i apiGciIsKindOfClass: anOop isKindOf: 74241) = 1 ifTrue: [
		str := self evaluate: '(Object _objectForOop: ', anOop printString, ') asString'.
		^ DateAndTime readFrom: str readStream.
	].

	"4. Array Marshaling (Recursive)"
	(i apiGciIsKindOfClass: anOop isKindOf: 66817) = 1 ifTrue: [
		szPtr := i apiGciFetchSize: anOop.
		sz := szPtr asInteger.
		(sz > 0 and: [ sz < 100 ]) ifTrue: [ | localArray |
			localArray := Array new: sz.
			1 to: sz do: [ :idx | | elementOop |
				elementOop := self evaluate: '(Object _objectForOop: ', anOop printString, ') at: ', idx printString.
				localArray at: idx put: elementOop.
			].
			^ localArray
		].
	].

	"Default: Return a Proxy (FIXED: Removed 'new')"
	^ GbsProxy oop: anOop session: self
]

{ #category : 'accessing' }
GbsSession >> fetchRemoteClassNamesIn: dictionaryName [

  | script rawString |
  script := '
        | dict stream |
        stream := WriteStream on: String new.
        dict := System myUserProfile symbolList objectNamed: #' , dictionaryName , '.
        dict ifNotNil: [
            dict keysAndValuesDo: [:key :value |
                value isBehavior ifTrue: [ 
                    stream nextPutAll: key asString; nextPut: $, 
                ]
            ]
        ].
        stream contents
    '.

  "1. Evaluates the script, returning a local String by value"
  rawString := self evaluate: script.

  "2. Splitting it on the client creates a local Array, which IS a Collection"
  ^ rawString splitOn: ','
]

{ #category : 'browser backend' }
GbsSession >> fetchRemoteDictionaries [
    "Queries GemStone for all dictionary names in the user's symbol list, returned as a fast comma-separated string."
    | script rawString |
    
    script := '| strm |
    strm := WriteStream on: String new.
    System myUserProfile symbolList 
        do: [:dict | strm nextPutAll: dict name asString] 
        separatedBy: [strm nextPutAll: '',''].
    strm contents'.
        
    rawString := self evaluate: script.
    
    "Unbox if it came back as a Proxy"
    (rawString class name = #GbsProxy) ifTrue: [ rawString := rawString asLocalString ].
    
    "Split the comma-separated string into a native Pharo Array"
    ^ rawString substrings: ','.
]

{ #category : 'as yet unclassified' }
GbsSession >> fetchRemoteGroups [
	| script rawString |
	"Groups are typically managed in AllUsers as well, filtered by privilege or type.
	 If your DB uses a specific Group structure, adjust the AllUsers reference here."
	script := '| strm |
	strm := WriteStream on: String new.
	SystemRepository listGroups do: [:g | strm nextPutAll: g name asString] separatedBy: [strm nextPutAll: '',''].
	strm contents'.
	
	rawString := self evaluate: script.
	(rawString class name = #GbsProxy) ifTrue: [ rawString := rawString asLocalString ].
	
	^ (rawString splitOn: ',') sorted.
]

{ #category : 'as yet unclassified' }
GbsSession >> fetchRemoteUsers [
	| script rawString |
	script := '| strm |
	strm := WriteStream on: String new.
	AllUsers do: [:user | strm nextPutAll: user userId asString] separatedBy: [strm nextPutAll: '',''].
	strm contents'.
	
	rawString := self evaluate: script.
	(rawString class name = #GbsProxy) ifTrue: [ rawString := rawString asLocalString ].
	
	^ (rawString splitOn: ',') sorted.
]

{ #category : 'evaluating' }
GbsSession >> fetchTranscriptLogs [
	| rawText |
	
	"1. Use our proven pipeline which correctly passes 20 (nil) as the context"
	rawText := self executeAndFetch: 'Transcript fetchAndClear'.
	
	"2. If GemStone returns nil (no new logs), executeAndFetch returns an Error string. 
	    We intercept that here and cleanly return an empty string to the UI."
	(rawText beginsWith: 'Error:') ifTrue: [ ^ '' ].
	
	^ rawText
]

{ #category : 'marshaling' }
GbsSession >> forwardRemoteMessage: aMessage forOop: targetOop [
	| script argStrings argsArrayString |
	
	"1. Handle messages with NO arguments (e.g., proxy size, proxy asString)"
	aMessage arguments isEmpty ifTrue: [
		script := '(Object _objectForOop: ', targetOop printString, ') perform: #', aMessage selector asString.
		^ self evaluate: script
	].
	
	"2. Handle messages WITH arguments"
	argStrings := aMessage arguments collect: [ :each | self marshalArgumentToScript: each ].
	
	"Create a GemStone dynamic array syntax: { arg1 . arg2 }"
	argsArrayString := '{ ', (' . ' join: argStrings), ' }'.
	
	"Execute the perform block remotely"
	script := '(Object _objectForOop: ', targetOop printString, ') perform: #', aMessage selector asString, ' withArguments: ', argsArrayString.
	
	^ self evaluate: script
]

{ #category : 'as yet unclassified' }
GbsSession >> gciAbort [
  "GbsSession >> gciAbort"

  "Calls the C-library to abort the transaction. Returns 1 on success."

  ^ self ffiCall: #( int32 GciAbort #(  ) ) module: GbsLibrary
]

{ #category : 'as yet unclassified' }
GbsSession >> gciCommit [
  "GbsSession >> gciCommit"

  "Calls the C-library to commit the transaction. Returns 1 on success."

  ^ self ffiCall: #( int32 GciCommit #(  ) ) module: GbsLibrary
]

{ #category : 'ffi' }
GbsSession >> gciExecute: string context: ctx env: env [
    "String correctly maps to const char*, and we stay on the main thread"
    ^ self ffiCall: #(int64 GciExecuteStr_(String string, int64 ctx, int env)) options: #( + optNonThreaded )
]

{ #category : 'as yet unclassified' }
GbsSession >> gciLogout [
	^ self ffiCall: #( int32 GciLogout () ) module: GbsLibrary
]

{ #category : 'as yet unclassified' }
GbsSession >> gciPollForSignal [
	^ self ffiCall: #( int32 GciPollForSignal () ) module: GbsLibrary
]

{ #category : 'error handling' }
GbsSession >> handleGciError [
	| buffer errMsg contextOop gbsError |

	"Allocate the 2168-byte struct from your gci_layout_mac.txt"
	buffer := ExternalAddress allocate: 2168.
	[
		"Linear Call: Fetch error and RESET the library state"
		GbsServerInterface uniqueInstance apiGciErr: buffer.

		"Extract 64-bit context from offset 8 (Pharo index 9)"
		contextOop := buffer unsignedLongLongAt: 9.
		"Extract message from offset 113"
		errMsg := (buffer + 113) readString.

		Transcript show: 'handleGciError: contextOop=', contextOop asString, ' msg=', errMsg; cr.

		"Signal the error. tag carries the context for the debugger."
		gbsError := GbsError new messageText: errMsg; tag: contextOop.
		gbsError signal.

	] ensure: [ buffer free ].
	^ nil
]

{ #category : 'initialization' }
GbsSession >> initialize [
	super initialize.
	isLoggedIn := false.
]

{ #category : 'testing' }
GbsSession >> isConnected [
    "In GBS, if we have a sessionOop, we are connected"
    ^ sessionOop isNotNil and: [ sessionOop asInteger ~= 0 ]
]

{ #category : 'initialization' }
GbsSession >> isLoggedIn [
	^ isLoggedIn
]

{ #category : 'polling' }
GbsSession >> isPolling [

  ^ pollingProcess isNotNil and: [ pollingProcess isTerminated not ]
]

{ #category : 'initialization' }
GbsSession >> loginStone: stoneName user: username password: password [
  "Initializes GCI and attempts to log into the specified Stone"

  | initSuccess loginSuccess errorStruct |
  initSuccess := self gciInit.
  initSuccess ifFalse: [ ^ GbsError signal: 'Failed to initialize GemStone GCI library.' ].

  "Pass empty strings for host user/pass as is standard for typical RPC setups"
  loginSuccess := self
                    gciLoginStone: stoneName
                    hostUser: ''
                    hostPass: ''
                    gsUser: username
                    gsPass: password.

  loginSuccess ifFalse: [ "Login failed. Fetch the error from the C thread and signal it."
      errorStruct := GciError new.
      ( self gciErr: errorStruct ) ifTrue: [ self signalError: errorStruct ].

      ^ GbsError signal: 'Unknown login failure.'
      ].

  "If we reach here, we are successfully connected!"
  isLoggedIn := true
]

{ #category : 'actions' }
GbsSession >> logout [

  self isLoggedIn ifFalse: [ ^ self ].
  self gciLogout = 1
    ifTrue: [ isLoggedIn := false ]
    ifFalse: [ GbsError signal: 'Failed to safely logout of GemStone.' ]
]

{ #category : 'marshaling' }
GbsSession >> marshalArgumentToScript: anObject [
  "Converts local Pharo objects into strings that represent them in GemStone syntax"

  anObject isInteger ifTrue: [ ^ anObject asString ].
  anObject == true ifTrue: [ ^ 'true' ].
  anObject == false ifTrue: [ ^ 'false' ].
  anObject ifNil: [ ^ 'nil' ].
  anObject isString ifTrue: [ ^ '''' , ( anObject copyReplaceAll: '''' with: '''''' ) , '''' ].

  "If the argument is another Proxy, look up its remote pointer!"
  ( anObject isKindOf: GbsProxy ) ifTrue: [
    ^ '(Object _objectForOop: ' , anObject oop asString , ')' ].

  self error:
    'Unsupported argument type for remote message send. Pass primitive types or GbsProxy objects.'
]

{ #category : 'accessing' }
GbsSession >> parameters: p [ parameters := p. GbsSessionParameters classPool at: #CurrentSession put: self
]

{ #category : 'evaluating' }
GbsSession >> resultFor: anOop [
  "Identify special GemStone OOP tags (GS64 3.7 Guide, Chapter 5)"

  anOop = 20 ifTrue: [ ^ nil ].
  anOop = 28 ifTrue: [ ^ true ].
  anOop = 12 ifTrue: [ ^ false ].

  "Check if it's a SmallInteger (Tag 2)"
  ( anOop bitAnd: 7 ) = 2 ifTrue: [ ^ anOop bitShift: -3 ].

  "Check if it's a Character (Tag 6)"
  "Check if it's a Character (Tag 6)"
  ( anOop bitAnd: 7 ) = 6 ifTrue: [ ^ Character codePoint: ( anOop bitShift: -3 ) ].

  "If it's not a primitive, it's a complex object. Return a Proxy."
  ^ GbsProxy oop: anOop session: self
]

{ #category : 'accessing' }
GbsSession >> serverInterface [
	"Lazy load the real interface, but allow tests to inject a mock"
	^ serverInterface ifNil: [ serverInterface := GbsServerInterface uniqueInstance ]
]

{ #category : 'accessing' }
GbsSession >> serverInterface: anObject [

  serverInterface := anObject
]

{ #category : 'accessing' }
GbsSession >> sessionId [ ^ sessionId
]

{ #category : 'accessing' }
GbsSession >> sessionId: anInteger [ sessionId := anInteger
]

{ #category : 'accessing' }
GbsSession >> sessionOop [
    ^ sessionOop
]

{ #category : 'accessing' }
GbsSession >> sessionOop: anInteger [
    sessionOop := anInteger
]

{ #category : 'signalling' }
GbsSession >> signalError: aGciError [
	"Translates a GemStone C-level error into a Pharo exception"
	| errorMessage |
	
	errorMessage := aGciError message. 
	
	^ GbsError signal: errorMessage
]

{ #category : 'polling' }
GbsSession >> startPolling [
    "DO NOTHING! 
     This permanently prevents the background thread from colliding 
     with the main FFI thread and corrupting the C-library state."
    ^ self
]

{ #category : 'polling' }
GbsSession >> stopPolling [
    pollingProcess ifNotNil: [ 
        pollingProcess terminate.
        pollingProcess := nil ].
]
