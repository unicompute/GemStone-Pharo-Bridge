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

{ #category : 'private - instance creation' }
GbsSession class >> classWithStats [
	^ GbsSessionWithStats
]

{ #category : 'private - instance creation' }
GbsSession class >> new [
	^ GBSM mainStatsEnabled
		ifTrue: [ self classWithStats basicNew initialize ]
		ifFalse: [ self basicNew initialize ]
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
	| buffer errMsg contextOop exceptionOop debugOop gbsError |
	buffer := ExternalAddress allocate: 2168.
	[
		"Tell the C-library to give us the error and RESET its internal state"
		GbsServerInterface uniqueInstance apiGciErr: buffer.
		
		"Use the 64-bit offsets we verified from your gci_layout_mac.txt"
		contextOop := buffer unsignedLongLongAt: 9. "Offset 8"
		exceptionOop := buffer unsignedLongLongAt: 17. "Offset 16"
		debugOop := ((contextOop isNil or: [ contextOop = 0 or: [ contextOop = 20 ] ])
			ifTrue: [ exceptionOop ]
			ifFalse: [ contextOop ]).
		(debugOop isNil or: [ debugOop = 0 ]) ifTrue: [ debugOop := 20 ].
		errMsg := (buffer + 113) readString. "Offset 112"
		
		gbsError := GbsError new
			messageText: errMsg;
			tag: debugOop;
			serverProcessOop: contextOop;
			exceptionOop: exceptionOop;
			yourself.
		gbsError signal.
	] ensure: [ buffer free ].
]

{ #category : 'error handling' }
GbsSession >> checkForError [
	| buffer result errNum errMsg contextOop exceptionOop debugOop gbsError |

	buffer := ExternalAddress allocate: 2168.
	[
		result := GbsServerInterface uniqueInstance apiGciErr: buffer.

		(result = 1 or: [ result == true ]) ifTrue: [
			"CRITICAL: Exact GS64 64-bit Memory Offsets!"
			errNum := buffer signedLongAt: 105. "C-offset 104"
			contextOop := buffer unsignedLongLongAt: 9. "C-offset 8 - this is the suspended context"
			exceptionOop := buffer unsignedLongLongAt: 17. "C-offset 16 - exception object"
			errMsg := (buffer + 113) readString. "C-offset 113"
			debugOop := ((contextOop isNil or: [ contextOop = 0 or: [ contextOop = 20 ] ])
				ifTrue: [ exceptionOop ]
				ifFalse: [ contextOop ]).
			(debugOop isNil or: [ debugOop = 0 ]) ifTrue: [ debugOop := 20 ].

				"Create the error with BOTH the message and the context OOP"
				gbsError := GbsError new
				messageText: errMsg;
				tag: debugOop;
				serverProcessOop: contextOop;
				exceptionOop: exceptionOop;
				yourself.
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
    "Compatibility alias used by older GBS examples."
    ^ self commitTransaction
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
    | resultOop |
    self validateReadyForExecution: s.

    resultOop := self serverInterface
        apiGciExecuteStr: s
        context: 20
        env: 0.

    resultOop = 1 ifTrue: [ ^ self handleGciError ].

    "GemStone may return nil while still leaving a pending runtime error."
    self checkForError.

    ^ self fetchObject: resultOop asInteger
]

{ #category : 'execution' }
GbsSession >> executeScriptAndFetchObject: aString [
	| resultOop |
	self validateReadyForExecution: aString.

	resultOop := self serverInterface
		apiGciExecuteStr: aString
		context: 20
		env: 0.

	resultOop = 1 ifTrue: [ ^ self handleGciError ].
	self checkForError.

	^ self fetchObject: resultOop asInteger
]

{ #category : 'evaluating' }
GbsSession >> evaluateAndFetchString: aString [
    | resultOop |
    self validateReadyForExecution: aString.
    resultOop := GbsServerInterface uniqueInstance 
        apiGciExecuteStr: aString 
        context: sessionOop 
        env: 0.
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
	self validateReadyForExecution: script.

	resultOop := GbsServerInterface uniqueInstance
		apiGciExecuteStr: script context: 20 env: 0.

	"If result is 1, follow C++ logic: handle the error IMMEDIATELY"
	resultOop = 1 ifTrue: [ ^ self handleGciError ].

	"VW/GBS correspondence: execution may still leave a pending GCI error
	even when the returned oop is not OOP_ILLEGAL. Always drain/check GciErr."
	self checkForError.

	^ self resultFor: resultOop
]

{ #category : 'execution' }
GbsSession >> executeAndFetch: script [
	self validateReadyForExecution: script.
	^ self executeAndFetch: script context: 20
]

{ #category : 'execution' }
GbsSession >> executeAndFetch: script context: contextOop [
	"Executes code and fetches the resulting String safely."
	| interface stringOop |
	self validateReadyForExecution: script.

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

  ^ self serverInterface apiGciAbortCurrent
]

{ #category : 'as yet unclassified' }
GbsSession >> gciCommit [
  "GbsSession >> gciCommit"

  "Calls the C-library to commit the transaction. Returns 1 on success."

  ^ self serverInterface apiGciCommit
]

{ #category : 'ffi' }
GbsSession >> gciExecute: string context: ctx env: env [
    "String correctly maps to const char*, and we stay on the main thread"
    ^ self serverInterface apiGciExecuteStr: string context: ctx env: env
]

{ #category : 'as yet unclassified' }
GbsSession >> gciLogout [
	^ self serverInterface apiGciLogout
]

{ #category : 'as yet unclassified' }
GbsSession >> gciPollForSignal [
	^ self serverInterface apiGciPollForSignal
]

{ #category : 'error handling' }
GbsSession >> handleGciError [
	| buffer errMsg contextOop exceptionOop debugOop gbsError |

	"Allocate the 2168-byte struct from your gci_layout_mac.txt"
	buffer := ExternalAddress allocate: 2168.
	[
		"Linear Call: Fetch error and RESET the library state"
		GbsServerInterface uniqueInstance apiGciErr: buffer.

		"Extract 64-bit context from offset 8 (Pharo index 9)"
		contextOop := buffer unsignedLongLongAt: 9.
		exceptionOop := buffer unsignedLongLongAt: 17.
		debugOop := ((contextOop isNil or: [ contextOop = 0 or: [ contextOop = 20 ] ])
			ifTrue: [ exceptionOop ]
			ifFalse: [ contextOop ]).
		(debugOop isNil or: [ debugOop = 0 ]) ifTrue: [ debugOop := 20 ].
		"Extract message from offset 113"
		errMsg := (buffer + 113) readString.

		"Signal the error. tag carries the context for the debugger."
		gbsError := GbsError new
			messageText: errMsg;
			tag: debugOop;
			serverProcessOop: contextOop;
			exceptionOop: exceptionOop;
			yourself.
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
GbsSession >> mainStatsEnabled [
	^ false
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

{ #category : 'initialization' }
GbsSession >> isLoggedIn: aBoolean [
	isLoggedIn := aBoolean
]

{ #category : 'polling' }
GbsSession >> isPolling [

  ^ pollingProcess isNotNil and: [ pollingProcess isTerminated not ]
]

{ #category : 'initialization' }
GbsSession >> loginStone: stoneName user: username password: password [
  "Initializes GCI and attempts to log into the specified Stone"

  | initSuccess loginSuccess errorStruct interpretedError |
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
      ( self gciErr: errorStruct ) ifTrue: [ 
          "Log to Transcript for debugging"
          Transcript show: '[GemStone Login Error]'; cr.
          Transcript show: '  Stone: ', stoneName; cr.
          Transcript show: '  User: ', username; cr.
          Transcript show: '  Error Number: ', errorStruct number printString; cr.
          Transcript show: '  Error Message: ', errorStruct message; cr.
          
          "Interpret the error message for netldi issues"
          interpretedError := self interpretLoginError: errorStruct.
          
          Transcript show: '  Interpreted: ', interpretedError; cr; cr.
          
          self signalError: errorStruct.
          ^ GbsError signal: interpretedError ].

      ^ GbsError signal: 'Unknown login failure. Please check your GemStone connection parameters.'
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

{ #category : 'actions' }
GbsSession >> disconnect [
	^ self logout
]

{ #category : 'marshaling' }
GbsSession >> marshalArgumentToScript: anObject [
  "Converts local Pharo objects into strings that represent them in GemStone syntax"

  anObject isInteger ifTrue: [ ^ anObject asString ].
  anObject isSymbol ifTrue: [ ^ '#', anObject asString ].
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
  (anOop = 28 or: [ anOop = 268 ]) ifTrue: [ ^ true ].
  (anOop = 12 or: [ anOop = 140 ]) ifTrue: [ ^ false ].

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

{ #category : 'accessing' }
GbsSession >> symbolList [
	^ self executeScriptAndFetchObject: 'System myUserProfile symbolList'
]

{ #category : 'named-objects' }
GbsSession >> globals [
	"VisualWorks/VAST-style convenience accessor."
	^ self sessionForwarderFor: #Globals
]

{ #category : 'named-objects' }
GbsSession >> published [
	"VisualWorks/VAST-style convenience accessor."
	^ self sessionForwarderFor: #Published
]

{ #category : 'named-objects' }
GbsSession >> sessionForwarderFor: aSymbol [
	"Answer an explicit forwarder/proxy for the named GemStone object in the current session."
	^ self
		uncachedForwarderAt: aSymbol
		ifAbsent: [ self error: aSymbol printString , ' not defined' ]
]

{ #category : 'named-objects' }
GbsSession >> uncachedForwarderAt: aSymbol ifAbsent: aBlock [
	| result |
	result := self resolveSymbol: aSymbol ifAbsent: [ nil ].
	^ result ifNil: [ aBlock value ] ifNotNil: [ result ]
]

{ #category : 'named-objects' }
GbsSession >> resolveSymbol: aSymbol [
	^ self
		resolveSymbol: aSymbol
		ifAbsent: [ self error: 'No GemStone object named ', aSymbol asString ]
]

{ #category : 'named-objects' }
GbsSession >> resolveSymbol: aSymbol ifAbsent: aBlock [
	| script result |
	script := String streamContents: [ :stream |
		stream
			nextPutAll: '[:symbol | | association |
	association := GsSession currentSession resolveSymbol: symbol.
	association == nil ifTrue: [ nil ] ifFalse: [ association value ]] value: ';
			nextPutAll: (self marshalArgumentToScript: aSymbol) ].
	result := self executeScriptAndFetchObject: script.
	^ result ifNil: [ aBlock value ] ifNotNil: [ result ]
]

{ #category : 'named-objects' }
GbsSession >> userClasses [
	"VisualWorks/VAST-style convenience accessor."
	^ self sessionForwarderFor: #UserClasses
]

{ #category : 'named-objects' }
GbsSession >> userGlobals [
	"VisualWorks/VAST-style convenience accessor."
	^ self sessionForwarderFor: #UserGlobals
]

{ #category : 'error handling' }
GbsSession >> interpretLoginError: anErrorStruct [
    "Interpret login error and provide user-friendly messages for netldi issues"
    | errorMsg errNum |
    errorMsg := anErrorStruct message ifNil: [ '' ].
    errNum := anErrorStruct number ifNil: [ 0 ].
    
    ^ self interpretErrorMessage: errorMsg errorNumber: errNum
]

{ #category : 'error handling' }
GbsSession >> interpretErrorMessage: aString errorNumber: anErrorNumber [
    "Interpret error messages and provide user-friendly explanations for common issues"
    | errorMsgLower originalMsg |
    
    "Convert to string if needed"
    originalMsg := aString isString 
        ifTrue: [ aString ] 
        ifFalse: [ 
            "Handle ByteArray or other types"
            [ aString asString ] on: Error do: [ 'Unknown error' ] ].
    
    errorMsgLower := originalMsg asLowercase.
    
    "Check for netldi-specific errors"
    (errorMsgLower includesSubstring: 'connection refused') ifTrue: [
        ^ 'Cannot connect to GemStone netldi daemon.

The netldi is not running or not accessible.

To fix this, start netldi on the GemStone server:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
    
    (errorMsgLower includesSubstring: 'no such') ifTrue: [
        (errorMsgLower includesSubstring: 'stn' or: [ errorMsgLower includesSubstring: 'stone' ]) ifTrue: [
            ^ 'Cannot find the GemStone stone.

Please check that the stone exists and netldi is running.

To start the stone and netldi:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ] ].
    
    (errorMsgLower includesSubstring: 'netldi') ifTrue: [
        ^ 'GemStone netldi daemon is not running or not accessible.

To fix this, start netldi on the GemStone server:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
    
    (errorMsgLower includesSubstring: 'gemnetobject') ifTrue: [
        ^ 'Cannot connect to gemnetobject service.

Please ensure the GemStone service is running.

To start netldi:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
    
    (errorMsgLower includesSubstring: 'login') ifTrue: [
        (errorMsgLower includesSubstring: 'fail' or: [ errorMsgLower includesSubstring: 'denied' or: [ errorMsgLower includesSubstring: 'disabled' ] ]) ifTrue: [
            ^ 'GemStone login failed.

Please check your username and password, or verify that logins are enabled.

Original error: ', originalMsg ] ].
    
    (errorMsgLower includesSubstring: 'shutdown') ifTrue: [
        ^ 'GemStone is shutting down.

Please wait for it to fully stop and restart it.

To restart:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
    
    (errorMsgLower includesSubstring: 'timeout') ifTrue: [
        ^ 'Connection to GemStone timed out.

Please check network connectivity and that netldi is running.

To start netldi:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
    
    (anErrorNumber notNil and: [ anErrorNumber ~= 0 ]) ifTrue: [
        ^ 'GemStone error ', anErrorNumber asString, ': ', originalMsg ].
    
    "Fallback message"
    originalMsg isEmpty ifTrue: [ 
        ^ 'Login failed. Please check your GemStone connection parameters.

Common issues:
• netldi is not running - start with: startnetldi -a <stone_name> -g <username>
• Stone name is incorrect
• Network connectivity issues' ].
    
    ^ originalMsg
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

{ #category : 'execution' }
GbsSession >> validateReadyForExecution: script [
	(script isString and: [ script isEmpty not ]) ifFalse: [
		GbsError signal: 'Cannot execute empty script.' ].

	self isLoggedIn ifFalse: [
		GbsError signal: 'Not logged in to GemStone.' ].
]
