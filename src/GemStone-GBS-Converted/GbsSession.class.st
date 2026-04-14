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

{ #category : 'event handling' }
GbsSession class >> clearNotificationActionFor: aSession [
	self notificationActions removeKey: aSession ifAbsent: [ ]
]

{ #category : 'event handling' }
GbsSession class >> clearSessionSignalActionFor: aSession [
	self sessionSignalActions removeKey: aSession ifAbsent: [ ]
]

{ #category : 'event handling' }
GbsSession class >> clearSignaledAbortActionFor: aSession [
	self signaledAbortActions removeKey: aSession ifAbsent: [ ]
]

{ #category : 'event handling' }
GbsSession class >> notificationActionFor: aSession [
	^ self notificationActions at: aSession ifAbsent: [ nil ]
]

{ #category : 'event handling' }
GbsSession class >> notificationActionFor: aSession put: aBlock [
	self notificationActions at: aSession put: aBlock
]

{ #category : 'event handling' }
GbsSession class >> notificationActions [
	^ self weakRegistryNamed: #GbsSessionNotificationActions
]

{ #category : 'event handling' }
GbsSession class >> sessionSignalActionFor: aSession [
	^ self sessionSignalActions at: aSession ifAbsent: [ nil ]
]

{ #category : 'event handling' }
GbsSession class >> sessionSignalActionFor: aSession put: aBlock [
	self sessionSignalActions at: aSession put: aBlock
]

{ #category : 'event handling' }
GbsSession class >> sessionSignalActions [
	^ self weakRegistryNamed: #GbsSessionSessionSignalActions
]

{ #category : 'event handling' }
GbsSession class >> signaledAbortActionFor: aSession [
	^ self signaledAbortActions at: aSession ifAbsent: [ nil ]
]

{ #category : 'event handling' }
GbsSession class >> signaledAbortActionFor: aSession put: aBlock [
	self signaledAbortActions at: aSession put: aBlock
]

{ #category : 'event handling' }
GbsSession class >> signaledAbortActions [
	^ self weakRegistryNamed: #GbsSessionSignaledAbortActions
]

{ #category : 'event handling' }
GbsSession class >> weakRegistryNamed: aSymbol [
	^ Smalltalk globals
		at: aSymbol
		ifAbsentPut: [ WeakKeyDictionary new ]
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
	| buffer errMsg errNum contextOop exceptionOop |
	buffer := ExternalAddress allocate: 2168.
	[
		self serverInterface apiGciErr: buffer.
		contextOop := buffer unsignedLongLongAt: 9.
		exceptionOop := buffer unsignedLongLongAt: 17.
		errNum := buffer signedLongAt: 105.
		errMsg := (buffer + 113) readString.
		^ self
			handleGemStoneErrorNumber: errNum
			messageText: errMsg
			contextOop: contextOop
			exceptionOop: exceptionOop
	] ensure: [ buffer free ].
]

{ #category : 'error handling' }
GbsSession >> checkForError [
	| buffer result errNum errMsg contextOop exceptionOop |
	buffer := ExternalAddress allocate: 2168.
	[
		result := self serverInterface apiGciErr: buffer.
		(result = 1 or: [ result == true ]) ifTrue: [
			errNum := buffer signedLongAt: 105.
			contextOop := buffer unsignedLongLongAt: 9.
			exceptionOop := buffer unsignedLongLongAt: 17.
			errMsg := (buffer + 113) readString.
			^ self
				handleGemStoneErrorNumber: errNum
				messageText: errMsg
				contextOop: contextOop
				exceptionOop: exceptionOop ].
	] ensure: [
		buffer free ].

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

{ #category : 'transactions' }
GbsSession >> beginTransaction [
	self executeSystemSelector: #beginTransaction withArguments: #().
	^ self
]

{ #category : 'transactions' }
GbsSession >> inTransaction [
	^ self evaluateSystemSelector: #inTransaction withArguments: #()
]

{ #category : 'transactions' }
GbsSession >> transactionMode [
	^ self evaluateSystemSelector: #transactionMode withArguments: #()
]

{ #category : 'transactions' }
GbsSession >> transactionMode: aSymbol [
	self executeSystemSelector: #transactionMode: withArguments: { aSymbol }.
	^ self
]

{ #category : 'private - remote execution' }
GbsSession >> evaluateSystemSelector: aSelector withArguments: arguments [
	^ self executeScriptAndFetchObject: (self systemCallScriptForSelector: aSelector arguments: arguments)
]

{ #category : 'private - remote execution' }
GbsSession >> executeSystemSelector: aSelector withArguments: arguments [
	^ self execute: (self systemCallScriptForSelector: aSelector arguments: arguments)
]

{ #category : 'private - remote execution' }
GbsSession >> systemCallScriptForSelector: aSelector arguments: arguments [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'System perform: #';
			nextPutAll: aSelector asString.
		arguments isEmpty ifFalse: [
			stream
				nextPutAll: ' withArguments: { ';
				nextPutAll: (' . ' join: (arguments collect: [ :each | self marshalArgumentToScript: each ]));
				nextPutAll: ' }' ] ]
]

{ #category : 'notification' }
GbsSession >> addToNotifySet: anObject [
	self executeSystemSelector: #addToNotifySet: withArguments: { anObject }.
	^ self
]

{ #category : 'notification' }
GbsSession >> addAllToNotifySet: aCollection [
	self executeSystemSelector: #addAllToNotifySet: withArguments: { aCollection }.
	^ self
]

{ #category : 'notification' }
GbsSession >> signaledObjects [
	^ self localSequenceableCollectionFrom:
		(self evaluateSystemSelector: #signaledObjects withArguments: #())
]

{ #category : 'lock status' }
GbsSession >> removeLock: anObject [
	self executeSystemSelector: #removeLock: withArguments: { anObject }.
	^ self
]

{ #category : 'lock status' }
GbsSession >> removeLockAll: aCollection [
	self executeSystemSelector: #removeLockAll: withArguments: { aCollection }.
	^ self
]

{ #category : 'lock status' }
GbsSession >> removeLocksForSession [
	self executeSystemSelector: #removeLocksForSession withArguments: #().
	^ self
]

{ #category : 'lock status' }
GbsSession >> sessionLocks [
	^ self materializeSessionLocks:
		(self evaluateSystemSelector: #sessionLocks withArguments: #())
]

{ #category : 'lock status' }
GbsSession >> systemLocks [
	| associations localLocks |
	associations := self localSequenceableCollectionFrom:
		(self executeScriptAndFetchObject: 'System systemLocks associations asArray').
	localLocks := Dictionary new: associations size.
	associations do: [ :association |
		localLocks
			at: association key
			put: (self materializeSessionLocks: association value) ].
	^ localLocks
]

{ #category : 'lock status' }
GbsSession >> lockOwners: anObject [
	^ self localSequenceableCollectionFrom:
		(self evaluateSystemSelector: #lockOwners: withArguments: { anObject })
]

{ #category : 'lock status' }
GbsSession >> lockKind: anObject [
	^ self evaluateSystemSelector: #lockKind: withArguments: { anObject }
]

{ #category : 'signalling' }
GbsSession >> sendSignal: aSignal to: sessionIdOrSerial withMessage: aString [
	^ self
		evaluateSystemSelector: #_sendSignal:toSess:withMessage:
		withArguments: { aSignal. sessionIdOrSerial. aString }
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
	| buffer errMsg errNum contextOop exceptionOop |
	buffer := ExternalAddress allocate: 2168.
	[
		self serverInterface apiGciErr: buffer.
		errNum := buffer signedLongAt: 105.
		contextOop := buffer unsignedLongLongAt: 9.
		exceptionOop := buffer unsignedLongLongAt: 17.
		errMsg := (buffer + 113) readString.
		^ self
			handleGemStoneErrorNumber: errNum
			messageText: errMsg
			contextOop: contextOop
			exceptionOop: exceptionOop
	] ensure: [ buffer free ].
	^ nil
]

{ #category : 'error handling' }
GbsSession >> handleGemStoneErrorNumber: anErrorNumber messageText: anErrorMessage contextOop: aContextOop exceptionOop: anExceptionOop [
	| debugOop gbsError |
	(#(6008 2748) includes: anErrorNumber) ifTrue: [
		^ self handleObjectsCommittedNotificationMessage: anErrorMessage ].
	(#(6009 2750) includes: anErrorNumber) ifTrue: [
		^ self handleSignaledAbortErrorMessage: anErrorMessage ].
	(#(6010 2711) includes: anErrorNumber) ifTrue: [
		^ self
			handleInterSessionSignalMessage: anErrorMessage
			exceptionOop: anExceptionOop ].

	debugOop := ((aContextOop isNil or: [ aContextOop = 0 or: [ aContextOop = 20 ] ])
		ifTrue: [ anExceptionOop ]
		ifFalse: [ aContextOop ]).
	(debugOop isNil or: [ debugOop = 0 ]) ifTrue: [ debugOop := 20 ].

	gbsError := GbsError new
		messageText: anErrorMessage;
		tag: debugOop;
		serverProcessOop: aContextOop;
		exceptionOop: anExceptionOop;
		yourself.
	gbsError gemStoneExceptionProxy: nil.
	gbsError signal
]

{ #category : 'error handling' }
GbsSession >> handleObjectsCommittedNotificationMessage: anErrorMessage [
	| action signaled |
	action := self notificationAction.
	action ifNil: [
		^ ObjectsCommittedNotification signal: anErrorMessage ].

	^ [
		signaled := self localIdentitySetFrom: self signaledObjects.
		signaled isEmpty ifFalse: [ action value: signaled ] ]
		ensure: [
			[ self enableSignaledObjectsError ]
				on: Error
				do: [ ] ]
]

{ #category : 'error handling' }
GbsSession >> handleSignaledAbortErrorMessage: anErrorMessage [
	| action |
	action := self signaledAbortAction.
	action ifNil: [
		^ (GbsRtErrSignalAbort new
			messageText: anErrorMessage;
			signal) ].

	^ [ action value ]
		ensure: [
			[ self enableSignaledAbortError ]
				on: Error
				do: [ ] ]
]

{ #category : 'error handling' }
GbsSession >> handleInterSessionSignalMessage: anErrorMessage exceptionOop: anExceptionOop [
	| action sessionSignal |
	action := self sessionSignalAction.
	action ifNil: [
		^ InterSessionSignal signal: anErrorMessage ].

	^ [
		sessionSignal := self legacyInterSessionSignalFromExceptionOop: anExceptionOop.
		sessionSignal ifNil: [
			sessionSignal := self legacyInterSessionSignalPoll ].
		[ sessionSignal isNil ] whileFalse: [
			action value: sessionSignal.
			sessionSignal := self legacyInterSessionSignalPoll ] ]
		ensure: [
			[ self enableSignaledGemStoneSessionError ]
				on: Error
				do: [ ] ]
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

{ #category : 'notification' }
GbsSession >> notificationAction [
	^ self class notificationActionFor: self
]

{ #category : 'notification' }
GbsSession >> notificationAction: aBlock [
	aBlock ifNil: [
		self class clearNotificationActionFor: self.
		[ self disableSignaledObjectsError ] on: Error do: [ ].
		^ nil ].

	self class notificationActionFor: self put: aBlock.
	self enableSignaledObjectsError.
	^ aBlock
]

{ #category : 'event handling' }
GbsSession >> sessionSignalAction [
	^ self class sessionSignalActionFor: self
]

{ #category : 'event handling' }
GbsSession >> sessionSignalAction: aBlock [
	aBlock ifNil: [
		self class clearSessionSignalActionFor: self.
		[ self disableSignaledGemStoneSessionError ] on: Error do: [ ].
		^ nil ].

	self class sessionSignalActionFor: self put: aBlock.
	self enableSignaledGemStoneSessionError.
	^ aBlock
]

{ #category : 'event handling' }
GbsSession >> signaledAbortAction [
	^ self class signaledAbortActionFor: self
]

{ #category : 'event handling' }
GbsSession >> signaledAbortAction: aBlock [
	aBlock ifNil: [
		self class clearSignaledAbortActionFor: self.
		[ self disableSignaledAbortError ] on: Error do: [ ].
		^ nil ].

	self class signaledAbortActionFor: self put: aBlock.
	self enableSignaledAbortError.
	^ aBlock
]

{ #category : 'notification' }
GbsSession >> disableSignaledObjectsError [
	self isLoggedIn ifFalse: [ ^ self ].
	^ [
		self evaluateSystemSelector: #disableSignaledObjectsError withArguments: #()
	] on: ObjectsCommittedNotification do: [ :ex | ex return: nil ]
]

{ #category : 'notification' }
GbsSession >> enableSignaledObjectsError [
	self isLoggedIn ifFalse: [ ^ self ].
	^ self evaluateSystemSelector: #enableSignaledObjectsError withArguments: #()
]

{ #category : 'event handling' }
GbsSession >> disableSignaledGemStoneSessionError [
	self isLoggedIn ifFalse: [ ^ self ].
	^ [
		self evaluateSystemSelector: #disableSignaledGemStoneSessionError withArguments: #()
	] on: InterSessionSignal do: [ :ex | ex return: nil ]
]

{ #category : 'event handling' }
GbsSession >> enableSignaledGemStoneSessionError [
	self isLoggedIn ifFalse: [ ^ self ].
	^ self evaluateSystemSelector: #enableSignaledGemStoneSessionError withArguments: #()
]

{ #category : 'event handling' }
GbsSession >> disableSignaledAbortError [
	self isLoggedIn ifFalse: [ ^ self ].
	^ [
		self evaluate: 'System disableSignaledAbortError'
	] on: GbsRtErrSignalAbort do: [ :ex | ex return: nil ]
]

{ #category : 'event handling' }
GbsSession >> enableSignaledAbortError [
	self isLoggedIn ifFalse: [ ^ self ].
	^ self evaluate: 'System enableSignaledAbortError'
]

{ #category : 'private - event handling' }
GbsSession >> legacyInterSessionSignalFromExceptionOop: anExceptionOop [
	(anExceptionOop isNil or: [ anExceptionOop = 0 or: [ anExceptionOop = 20 ] ]) ifTrue: [ ^ nil ].
	^ self executeScriptAndFetchObject: (self legacyInterSessionSignalScriptForExceptionOop: anExceptionOop)
]

{ #category : 'private - event handling' }
GbsSession >> legacyInterSessionSignalPoll [
	^ self executeScriptAndFetchObject: self legacyInterSessionSignalPollScript
]

{ #category : 'private - event handling' }
GbsSession >> legacyInterSessionSignalPollScript [
	^ 'GsCurrentSession currentSession signalFromSession'
]

{ #category : 'private - event handling' }
GbsSession >> legacyInterSessionSignalScriptForExceptionOop: anExceptionOop [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| modern legacy |';
			nextPutAll: ' modern := Object _objectForOop: ';
			nextPutAll: anExceptionOop printString;
			nextPutAll: '.';
			nextPutAll: ' modern == nil ifTrue: [ nil ] ifFalse: [';
			nextPutAll: ' legacy := GsInterSessionSignal signal: modern sentInt message: modern sentMessage.';
			nextPutAll: ' legacy session: (GsSession sessionWithSerialNumber: modern sendingSessionSerial).';
			nextPutAll: ' legacy ]' ]
]

{ #category : 'private - event handling' }
GbsSession >> localIdentitySetFrom: aCollectionOrProxy [
	| localSet |
	localSet := IdentitySet new.
	(self localSequenceableCollectionFrom: aCollectionOrProxy)
		do: [ :each | localSet add: each ].
	^ localSet
]

{ #category : 'private - event handling' }
GbsSession >> localSequenceableCollectionFrom: aCollectionOrProxy [
	| size localCollection |
	aCollectionOrProxy ifNil: [ ^ #() ].
	(aCollectionOrProxy isKindOf: GbsProxy) ifFalse: [ ^ aCollectionOrProxy asArray ].

	size := aCollectionOrProxy size.
	localCollection := Array new: size.
	1 to: size do: [ :index |
		localCollection at: index put: (aCollectionOrProxy at: index) ].
	^ localCollection
]

{ #category : 'private - event handling' }
GbsSession >> materializeSessionLocks: aLockCollection [
	| lockArrays |
	lockArrays := self localSequenceableCollectionFrom: aLockCollection.
	^ lockArrays collect: [ :each | self localSequenceableCollectionFrom: each ]
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
	[
		self isLoggedIn ifFalse: [ ^ self ].
		self gciLogout
	] on: Error do: [ :ex |
		GbsError signal: 'Failed to safely logout of GemStone: ', ex messageText ].
	self resetAfterLogout
]

{ #category : 'actions' }
GbsSession >> resetAfterLogout [
	self stopPolling.
	isLoggedIn := false.
	sessionOop := nil.
	sessionId := nil.
	parameters ifNotNil: [
		parameters sessionId: nil.
		parameters class currentSession == self ifTrue: [
			parameters class currentSession: nil ].
		parameters class unregisterSession: parameters ]
]

{ #category : 'actions' }
GbsSession >> disconnect [
	^ self logout
]

{ #category : 'marshaling' }
GbsSession >> marshalArgumentToScript: anObject [
	"Converts local Pharo objects into strings that represent them in GemStone syntax."

	^ self marshalArgumentToScript: anObject visited: IdentitySet new
]

{ #category : 'marshaling' }
GbsSession >> marshalArgumentToScript: anObject visited: visited [
	anObject isInteger ifTrue: [ ^ anObject asString ].
	anObject isFloat ifTrue: [ ^ anObject printString ].
	anObject class == Fraction ifTrue: [
		^ '(', anObject numerator printString, ' / ', anObject denominator printString, ')' ].
	anObject isSymbol ifTrue: [ ^ '#', anObject asString ].
	anObject == true ifTrue: [ ^ 'true' ].
	anObject == false ifTrue: [ ^ 'false' ].
	anObject ifNil: [ ^ 'nil' ].
	anObject isCharacter ifTrue: [
		^ '(Character value: ', anObject asInteger printString, ')' ].
	anObject isString ifTrue: [ ^ self marshalStringLiteralToScript: anObject ].

	"If the argument is another Proxy, look up its remote pointer!"
	(anObject isKindOf: GbsProxy) ifTrue: [
		^ '(Object _objectForOop: ', anObject oop asString, ')' ].

	^ self marshalComplexArgumentToScript: anObject visited: visited
]

{ #category : 'marshaling' }
GbsSession >> marshalArrayArgumentToScript: anArray visited: visited [
	| statements |
	statements := OrderedCollection new: anArray size.
	1 to: anArray size do: [ :index |
		statements add:
			'at: ', index printString, ' put: ',
				(self marshalArgumentToScript: (anArray at: index) visited: visited) ].
	^ self
		marshalConstructedObjectExpressionForReceiver: 'Array new: ', anArray size printString
		statements: statements
]

{ #category : 'marshaling' }
GbsSession >> marshalAssociationArgumentToScript: anAssociation visited: visited [
	^ '(Association key: ',
		(self marshalArgumentToScript: anAssociation key visited: visited),
		' value: ',
		(self marshalArgumentToScript: anAssociation value visited: visited),
		')'
]

{ #category : 'marshaling' }
GbsSession >> marshalBagArgumentToScript: aBag visited: visited [
	^ self
		marshalCollectionArgumentToScript: aBag
		receiver: 'Bag new'
		visited: visited
]

{ #category : 'marshaling' }
GbsSession >> marshalByteArrayArgumentToScript: aByteArray [
	| statements |
	statements := OrderedCollection new: aByteArray size.
	1 to: aByteArray size do: [ :index | | byte |
		byte := aByteArray at: index.
		((byte isInteger) and: [ byte >= 0 and: [ byte <= 255 ] ]) ifFalse: [
			self error: 'ByteArray arguments must contain integers between 0 and 255.' ].
		statements add: 'at: ', index printString, ' put: ', byte printString ].
	^ self
		marshalConstructedObjectExpressionForReceiver: 'ByteArray new: ', aByteArray size printString
		statements: statements
]

{ #category : 'marshaling' }
GbsSession >> marshalCollectionArgumentToScript: aCollection receiver: receiverString visited: visited [
	| statements |
	statements := OrderedCollection new: aCollection size.
	aCollection do: [ :each |
		statements add: 'add: ', (self marshalArgumentToScript: each visited: visited) ].
	^ self
		marshalConstructedObjectExpressionForReceiver: receiverString
		statements: statements
]

{ #category : 'marshaling' }
GbsSession >> marshalComplexArgumentToScript: anObject visited: visited [
	(visited includes: anObject) ifTrue: [
		self error: 'Cyclic local object graphs are not supported for remote message send.' ].

	visited add: anObject.
	^ [
		anObject class == Array ifTrue: [
			^ self marshalArrayArgumentToScript: anObject visited: visited ].
		anObject class == ByteArray ifTrue: [
			^ self marshalByteArrayArgumentToScript: anObject ].
		anObject class == OrderedCollection ifTrue: [
			^ self
				marshalCollectionArgumentToScript: anObject
				receiver: 'OrderedCollection new'
				visited: visited ].
		anObject class == Set ifTrue: [
			^ self
				marshalCollectionArgumentToScript: anObject
				receiver: 'Set new'
				visited: visited ].
		anObject class == IdentitySet ifTrue: [
			^ self
				marshalCollectionArgumentToScript: anObject
				receiver: 'IdentitySet new'
				visited: visited ].
		anObject class == Bag ifTrue: [
			^ self marshalBagArgumentToScript: anObject visited: visited ].
		anObject class == SortedCollection ifTrue: [
			^ self
				marshalCollectionArgumentToScript: anObject
				receiver: 'SortedCollection new'
				visited: visited ].
		anObject class == Dictionary ifTrue: [
			^ self
				marshalDictionaryArgumentToScript: anObject
				receiver: 'Dictionary new'
				visited: visited ].
		anObject class == IdentityDictionary ifTrue: [
			^ self
				marshalDictionaryArgumentToScript: anObject
				receiver: 'IdentityDictionary new'
				visited: visited ].
		anObject class == Association ifTrue: [
			^ self marshalAssociationArgumentToScript: anObject visited: visited ].
		anObject class == Date ifTrue: [
			^ '(Date year: ', anObject year printString,
				' month: ', anObject monthIndex printString,
				' day: ', anObject dayOfMonth printString,
				')' ].
		anObject class == Time ifTrue: [
			^ '(Time hour: ', anObject hour printString,
				' minute: ', anObject minute printString,
				' second: ', anObject second printString,
				')' ].
		anObject class == DateAndTime ifTrue: [
			^ '(DateTime fromString: ', (self marshalStringLiteralToScript: anObject printString), ')' ].
		self error:
			'Unsupported argument type for remote message send. Pass primitive types, common collections, dates/times, or GbsProxy objects.' ]
		ensure: [ visited remove: anObject ifAbsent: [ ] ]
]

{ #category : 'marshaling' }
GbsSession >> marshalConstructedObjectExpressionForReceiver: receiverString statements: statements [
	^ String streamContents: [ :stream |
		| first |
		stream
			nextPutAll: '((';
			nextPutAll: receiverString;
			nextPut: $).
		first := true.
		statements do: [ :each |
			first
				ifTrue: [
					stream nextPut: Character space.
					first := false ]
				ifFalse: [ stream nextPutAll: '; ' ].
			stream nextPutAll: each ].
		first ifTrue: [ stream nextPut: Character space ] ifFalse: [ stream nextPutAll: '; ' ].
		stream nextPutAll: 'yourself)' ]
]

{ #category : 'marshaling' }
GbsSession >> marshalDictionaryArgumentToScript: aDictionary receiver: receiverString visited: visited [
	| statements |
	statements := OrderedCollection new: aDictionary size.
	aDictionary keysAndValuesDo: [ :key :value |
		statements add:
			'at: ', (self marshalArgumentToScript: key visited: visited),
				' put: ',
				(self marshalArgumentToScript: value visited: visited) ].
	^ self
		marshalConstructedObjectExpressionForReceiver: receiverString
		statements: statements
]

{ #category : 'marshaling' }
GbsSession >> marshalStringLiteralToScript: aString [
	^ '''', (aString copyReplaceAll: '''' with: ''''''), ''''
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
