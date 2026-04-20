Class {
	#name : 'GbsSession',
	#superclass : 'Object',
	#instVars : [
		'isLoggedIn',
		'sessionOop',
		'parameters',
		'pollingProcess',
		'serverInterface',
		'sessionId',
		'materializationProfile',
		'proxyCache',
		'namedObjectCache',
		'namedObjectAutoloadRegistry',
		'repositoryRootCache',
		'repositoryRootLifecycleVersion'
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
  ((result = 1) or: [ result = true ]) ifFalse: [
    "Some local stones report a falsey GCI abort result even though the
    abort succeeds. Fall back to an explicit Smalltalk abortTransaction
    before treating the connection as broken."
    [ self evaluate: 'System abortTransaction. true' ]
      on: Error
      do: [ GbsError signal: 'Failed to abort transaction.' ] ].
  GbsSessionManager invalidateStaleTypedWrapperClassesForSession: self.
  self invalidateRepositoryRoots.
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

{ #category : 'deprecated' }
GbsSession >> commit [
	"Deprecated. Use #commitTransaction."
	self deprecated: 'Use #commitTransaction.'.
	^ self commitTransaction
]

{ #category : 'transactions' }
GbsSession >> commitTransaction [
	"Attempts to commit. Returns true if successful, false if there is a conflict.
	 You can extend this later to raise a GbsTransactionConflictError."
	| result |
	self isLoggedIn ifFalse: [ GbsError signal: 'Not logged in.' ].
	
	result := self gciCommit.
	result = 1 ifTrue: [
		GbsSessionManager invalidateStaleTypedWrapperClassesForSession: self.
		self invalidateRepositoryRoots ].
	^ result = 1
]

{ #category : 'transactions' }
GbsSession >> commitTransactionOrSignalConflict [
	(self commitTransaction)
		ifTrue: [ ^ true ].
	GbsCommitConflictError signal: 'GemStone commit conflict.'
]

{ #category : 'transactions' }
GbsSession >> commitTransactionWithRetryCount: aRetryCount [
	| retries attempts |
	retries := (aRetryCount ifNil: [ 0 ] ifNotNil: [ aRetryCount asInteger ]) max: 0.
	attempts := retries + 1.
	1 to: attempts do: [ :attempt |
		(self commitTransaction) ifTrue: [ ^ true ].
		attempt < attempts ifTrue: [ self abortTransaction ] ].
	GbsCommitConflictError signal: 'GemStone commit conflict after ', attempts printString, ' attempts.'
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
GbsSession >> needsCommit [
	^ self evaluateSystemSelector: #needsCommit withArguments: #()
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
GbsSession >> readLock: anObject [
	self executeSystemSelector: #readLock: withArguments: { anObject }.
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
GbsSession >> writeLock: anObject [
	self executeSystemSelector: #writeLock: withArguments: { anObject }.
	^ self
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

{ #category : 'execution' }
GbsSession >> executeScriptAndReturnOop: aString [
	| resultOop |
	self validateReadyForExecution: aString.

	resultOop := self serverInterface
		apiGciExecuteStr: aString
		context: 20
		env: 0.

	resultOop = 1 ifTrue: [ ^ self handleGciError ].
	self checkForError.

	^ resultOop asInteger
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
	^ self
		fetchObject: anOop
		withProfile: self materializationProfile
		depth: 0
		seen: IdentitySet new
]

{ #category : 'marshaling' }
GbsSession >> fetchObject: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	^ aProfile
		materializeOop: anOop
		inSession: self
		depth: anInteger
		seen: seenOops
]

{ #category : 'materialization' }
GbsSession >> fetchProfile [
	^ self materializationProfile
]

{ #category : 'materialization' }
GbsSession >> fetchProfile: aProfile [
	^ self materializationProfile: aProfile
]

{ #category : 'materialization' }
GbsSession >> fetchByReference [
	self materializationProfile: GbsProxyOnlyMaterializationProfile new.
	^ self
]

{ #category : 'materialization' }
GbsSession >> fetchDeep [
	self materializationProfile: GbsDeepMaterializationProfile new.
	^ self
]

{ #category : 'materialization' }
GbsSession >> fetchLegacy [
	self materializationProfile: GbsLegacyMaterializationProfile new.
	^ self
]

{ #category : 'materialization' }
GbsSession >> fetchShallow [
	self materializationProfile: GbsShallowMaterializationProfile new.
	^ self
]

{ #category : 'materialization' }
GbsSession >> materializationProfile [
	^ materializationProfile ifNil: [ materializationProfile := GbsLegacyMaterializationProfile new ]
]

{ #category : 'materialization' }
GbsSession >> materializationProfile: aProfile [
	materializationProfile := aProfile ifNil: [ GbsLegacyMaterializationProfile new ].
	^ materializationProfile
]

{ #category : 'materialization' }
GbsSession >> withMaterializationProfile: aProfile do: aBlock [
	| previousProfile result |
	previousProfile := self materializationProfile.
	self materializationProfile: aProfile.
	result := [ aBlock value ] ensure: [ self materializationProfile: previousProfile ].
	^ result
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

{ #category : 'materialization' }
GbsSession >> isImmediateOop: anOop [
	anOop = 20 ifTrue: [ ^ true ].
	(anOop = 28 or: [ anOop = 268 ]) ifTrue: [ ^ true ].
	(anOop = 12 or: [ anOop = 140 ]) ifTrue: [ ^ true ].
	((anOop bitAnd: 7) = 2 or: [ (anOop bitAnd: 7) = 6 ]) ifTrue: [ ^ true ].
	^ false
]

{ #category : 'materialization' }
GbsSession >> materializeArrayOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	| size localArray |
	size := self remoteSizeForOop: anOop.
	localArray := Array new: size.
	1 to: size do: [ :index |
		localArray
			at: index
			put: (self
				fetchObject: (self remoteArrayElementOopAt: index ofOop: anOop)
				withProfile: aProfile
				depth: anInteger + 1
				seen: seenOops) ].
	^ localArray
]

{ #category : 'materialization' }
GbsSession >> materializeAssociationOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	| pair |
	pair := self
		materializeArrayOop: (self remoteAssociationPairOopFor: anOop)
		withProfile: aProfile
		depth: anInteger
		seen: seenOops.
	^ Association
		key: (pair at: 1 ifAbsent: [ nil ])
		value: (pair at: 2 ifAbsent: [ nil ])
]

{ #category : 'materialization' }
GbsSession >> materializeByteArrayOop: anOop withProfile: aProfile depth: anInteger seen: seenOops [
	| bytes |
	bytes := self
		materializeArrayOop: (self remoteCollectionAsArrayOop: anOop)
		withProfile: aProfile
		depth: anInteger
		seen: seenOops.
	^ ByteArray withAll: bytes
]

{ #category : 'materialization' }
GbsSession >> materializeDictionaryOop: anOop identityKeys: useIdentity withProfile: aProfile depth: anInteger seen: seenOops [
	| associations dictionary |
	associations := self
		materializeArrayOop: (self remoteDictionaryAssociationsAsArrayOop: anOop)
		withProfile: aProfile
		depth: anInteger
		seen: seenOops.
	dictionary := useIdentity
		ifTrue: [ IdentityDictionary new ]
		ifFalse: [ Dictionary new ].
	associations do: [ :each |
		dictionary
			at: each key
			put: each value ].
	^ dictionary
]

{ #category : 'materialization' }
GbsSession >> materializeSequenceableCollectionOop: anOop using: aBlock withProfile: aProfile depth: anInteger seen: seenOops [
	| localArray |
	localArray := self
		materializeArrayOop: (self remoteCollectionAsArrayOop: anOop)
		withProfile: aProfile
		depth: anInteger
		seen: seenOops.
	^ aBlock value: localArray
]

{ #category : 'materialization' }
GbsSession >> proxyForOop: anOop [
	^ self proxyForOop: anOop usingClass: GbsProxy
]

{ #category : 'materialization' }
GbsSession >> proxyForOop: anOop serverClassName: aClassName [
	| cachedProxy wrapperClass |
	cachedProxy := self cachedProxyForOop: anOop.
	cachedProxy ifNotNil: [ ^ cachedProxy ].
	wrapperClass := GbsSessionManager typedWrapperClassForServerClassNamed: aClassName.
	wrapperClass ifNil: [ ^ self proxyForOop: anOop ].
	^ self proxyForOop: anOop usingClass: wrapperClass
]

{ #category : 'materialization' }
GbsSession >> proxyForOop: anOop usingClass: proxyClass [
	| cachedProxy proxy |
	cachedProxy := self cachedProxyForOop: anOop.
	cachedProxy ifNotNil: [ ^ cachedProxy ].
	proxy := proxyClass oop: anOop session: self.
	self proxyCache at: anOop put: { proxy }.
	^ proxy
]

{ #category : 'materialization' }
GbsSession >> cachedProxyForOop: anOop [
	| entry |
	entry := self proxyCache at: anOop ifAbsent: [ nil ].
	entry ifNil: [ ^ nil ].
	^ entry first
]

{ #category : 'materialization' }
GbsSession >> clearProxyCache [
	proxyCache := WeakValueDictionary new.
	^ proxyCache
]

{ #category : 'named-objects' }
GbsSession >> clearNamedObjectCache [
	namedObjectCache := Dictionary new.
	^ namedObjectCache
]

{ #category : 'materialization' }
GbsSession >> proxyCache [
	^ proxyCache ifNil: [ proxyCache := WeakValueDictionary new ]
]

{ #category : 'materialization' }
GbsSession >> remoteArrayElementOopAt: anInteger ofOop: anOop [
	^ self executeScriptAndReturnOop: (String streamContents: [ :stream |
		stream
			nextPutAll: '(Object _objectForOop: ';
			nextPutAll: anOop printString;
			nextPutAll: ') at: ';
			nextPutAll: anInteger printString ])
]

{ #category : 'materialization' }
GbsSession >> remoteAssociationPairOopFor: anOop [
	^ self executeScriptAndReturnOop: (String streamContents: [ :stream |
		stream
			nextPutAll: '| assoc | assoc := Object _objectForOop: ';
			nextPutAll: anOop printString;
			nextPutAll: '. Array with: assoc key with: assoc value' ])
]

{ #category : 'materialization' }
GbsSession >> remoteClassNameForOop: anOop [
	^ self executeAndFetch: (String streamContents: [ :stream |
		stream
			nextPutAll: '(Object _objectForOop: ';
			nextPutAll: anOop printString;
			nextPutAll: ') class name asString' ])
]

{ #category : 'materialization' }
GbsSession >> remoteCollectionAsArrayOop: anOop [
	^ self executeScriptAndReturnOop: (String streamContents: [ :stream |
		stream
			nextPutAll: '(Object _objectForOop: ';
			nextPutAll: anOop printString;
			nextPutAll: ') asArray' ])
]

{ #category : 'materialization' }
GbsSession >> remoteDictionaryAssociationsAsArrayOop: anOop [
	^ self executeScriptAndReturnOop: (String streamContents: [ :stream |
		stream
			nextPutAll: '(Object _objectForOop: ';
			nextPutAll: anOop printString;
			nextPutAll: ') associations asArray' ])
]

{ #category : 'materialization' }
GbsSession >> remoteSizeForOop: anOop [
	^ self executeScriptAndFetchObject: (String streamContents: [ :stream |
		stream
			nextPutAll: '(Object _objectForOop: ';
			nextPutAll: anOop printString;
			nextPutAll: ') size' ])
]

{ #category : 'materialization' }
GbsSession >> remoteStringValueForOop: anOop [
	^ self executeAndFetch: (String streamContents: [ :stream |
		stream
			nextPutAll: '(Object _objectForOop: ';
			nextPutAll: anOop printString;
			nextPutAll: ') asString' ])
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
	
	rawText := self executeAndFetch: '[
		| fetched log text |
		fetched := (Transcript respondsTo: #fetchAndClear)
			ifTrue: [ [ Transcript fetchAndClear ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		fetched ifNotNil: [ ^ fetched ifNil: [ '''' ] ].
		log := SessionTemps current at: #PharoTranscriptLog ifAbsent: [ OrderedCollection new ].
		text := String streamContents: [ :stream |
			log do: [ :each |
				stream nextPutAll: each asString.
				stream cr ] ].
		SessionTemps current at: #PharoTranscriptLog put: OrderedCollection new.
		text
	] value'.

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
	materializationProfile := GbsLegacyMaterializationProfile new.
	proxyCache := WeakValueDictionary new.
	namedObjectCache := Dictionary new.
	namedObjectAutoloadRegistry := Dictionary new.
	repositoryRootCache := Dictionary new.
	repositoryRootLifecycleVersion := 0
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
          Transcript
			show: '  Error Number: ';
			show: ([ errorStruct number printString ] on: Exception do: [ 'n/a' ]);
			cr.
          Transcript
			show: '  Error Message: ';
			show: ([ errorStruct message ] on: Exception do: [ 'Unknown login failure' ]);
			cr.
          
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
	self clearProxyCache.
	self clearNamedObjectCache.
	GbsSessionManager clearTypedWrapperAutoloadRegistrationsForSession: self.
	self invalidateRepositoryRoots.
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
	"If the argument is another proxy, preserve its remote identity before
	asking any generic type questions that could forward remotely."
	(anObject isKindOf: GbsProxy) ifTrue: [
		^ '(Object _objectForOop: ', anObject oop asString, ')' ].

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
  ^ self proxyForOop: anOop
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

{ #category : 'repository' }
GbsSession >> loadedClasses [
	^ self repository loadedClasses
]

{ #category : 'repository' }
GbsSession >> classHistoryOf: aClassOrName [
	^ self repository classHistoryOf: aClassOrName
]

{ #category : 'repository' }
GbsSession >> classMethodMirrorForClass: aClassOrName selector: aSelector [
	^ self
		repository
		classMethodMirrorForClass: aClassOrName
		selector: aSelector
]

{ #category : 'repository' }
GbsSession >> classMethodMirrorForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		classMethodMirrorForClassNamed: aClassName
		selector: aSelector
]

{ #category : 'repository' }
GbsSession >> classMethodObjectForClass: aClassOrName selector: aSelector [
	^ self
		repository
		classMethodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : 'repository' }
GbsSession >> classUnboundMethodObjectForClass: aClassOrName selector: aSelector [
	^ self
		repository
		classUnboundMethodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : 'repository' }
GbsSession >> classMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		classMethodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : 'repository' }
GbsSession >> classUnboundMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		classUnboundMethodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : 'repository' }
GbsSession >> classMirrorOf: aClassOrName [
	^ self repository classMirrorOf: aClassOrName
]

{ #category : 'repository' }
GbsSession >> classMirrorOfNamed: aClassName [
	^ self repository classMirrorOfNamed: aClassName
]

{ #category : 'repository' }
GbsSession >> namespaceMirrors [
	^ self repository namespaceMirrors
]

{ #category : 'repository' }
GbsSession >> namespaceMirrorAtSymbolListIndex: anInteger [
	^ self repository namespaceMirrorAtSymbolListIndex: anInteger
]

{ #category : 'repository' }
GbsSession >> topLevelNamespaceMirror [
	^ self repository topLevelNamespaceMirror
]

{ #category : 'repository' }
GbsSession >> namespaceMirrorForClass: aClassOrName [
	^ self repository namespaceMirrorForClass: aClassOrName
]

{ #category : 'repository' }
GbsSession >> namespaceMirrorForClassNamed: aClassName [
	^ self repository namespaceMirrorForClassNamed: aClassName
]

{ #category : 'repository' }
GbsSession >> namespaceMirrorForObject: anObjectOrProxy [
	^ self repository namespaceMirrorForObject: anObjectOrProxy
]

{ #category : 'repository' }
GbsSession >> namespaceMirrorForFullName: aString [
	^ self repository namespaceMirrorForFullName: aString
]

{ #category : 'repository' }
GbsSession >> implementorMethodReferenceStringsForSelector: aSelectorOrString [
	^ self repository implementorMethodReferenceStringsForSelector: aSelectorOrString
]

{ #category : 'repository' }
GbsSession >> hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString [
	^ self repository
		hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
]

{ #category : 'repository' }
GbsSession >> hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString includeClassSide: includeClassSideBoolean [
	^ self repository
		hierarchyImplementorMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
		includeClassSide: includeClassSideBoolean
]

{ #category : 'repository' }
GbsSession >> hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString [
	^ self repository
		hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
]

{ #category : 'repository' }
GbsSession >> hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString rootClassName: aRootClassName scope: aScopeString includeClassSide: includeClassSideBoolean [
	^ self repository
		hierarchySenderMethodReferenceStringsForSelector: aSelectorOrString
		rootClassName: aRootClassName
		scope: aScopeString
		includeClassSide: includeClassSideBoolean
]

{ #category : 'repository' }
GbsSession >> methodReferenceStringsToObject: anObject [
	^ self repository methodReferenceStringsToObject: anObject
]

{ #category : 'repository' }
GbsSession >> methodReferenceStringsToSymbol: aSymbolOrString [
	^ self repository methodReferenceStringsToSymbol: aSymbolOrString
]

{ #category : 'repository' }
GbsSession >> senderMethodReferenceStringsForSelector: aSelectorOrString [
	^ self repository senderMethodReferenceStringsForSelector: aSelectorOrString
]

{ #category : 'repository' }
GbsSession >> listInstancesOf: aClassOrName [
	^ self repository listInstancesOf: aClassOrName
]

{ #category : 'repository' }
GbsSession >> listInstancesOf: aClassOrName allowAbort: aBoolean [
	^ self repository listInstancesOf: aClassOrName allowAbort: aBoolean
]

{ #category : 'repository' }
GbsSession >> listInstancesOf: aClassOrName limit: aSmallInteger [
	^ self repository listInstancesOf: aClassOrName limit: aSmallInteger
]

{ #category : 'repository' }
GbsSession >> listInstancesOf: aClassOrName limit: aSmallInteger allowAbort: aBoolean [
	^ self
		repository
		listInstancesOf: aClassOrName
		limit: aSmallInteger
		allowAbort: aBoolean
]

{ #category : 'repository' }
GbsSession >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self
		repository
		migrateInstancesFrom: aSourceClassOrName
		to: aTargetClassOrName
]

{ #category : 'repository' }
GbsSession >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName [
	^ self
		repository
		previewMigrationFrom: aSourceClassOrName
		to: aTargetClassOrName
]

{ #category : 'repository' }
GbsSession >> previewMigrationFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	^ self
		repository
		previewMigrationFrom: aSourceClassOrName
		to: aTargetClassOrName
		allowAbort: aBoolean
]

{ #category : 'repository' }
GbsSession >> previewMigrationWithSubclassesOf: aTopClassOrName [
	^ self repository previewMigrationWithSubclassesOf: aTopClassOrName
]

{ #category : 'repository' }
GbsSession >> previewMigrationWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	^ self
		repository
		previewMigrationWithSubclassesOf: aTopClassOrName
		allowAbort: aBoolean
]

{ #category : 'repository' }
GbsSession >> migrateInstancesFrom: aSourceClassOrName to: aTargetClassOrName allowAbort: aBoolean [
	^ self
		repository
		migrateInstancesFrom: aSourceClassOrName
		to: aTargetClassOrName
		allowAbort: aBoolean
]

{ #category : 'repository' }
GbsSession >> migrateInstancesWithSubclassesOf: aTopClassOrName [
	^ self repository migrateInstancesWithSubclassesOf: aTopClassOrName
]

{ #category : 'repository' }
GbsSession >> migrateInstancesWithSubclassesOf: aTopClassOrName allowAbort: aBoolean [
	^ self
		repository
		migrateInstancesWithSubclassesOf: aTopClassOrName
		allowAbort: aBoolean
]

{ #category : 'repository' }
GbsSession >> chunkedMigrationRunnerFrom: aSourceClassOrName to: aTargetClassOrName [
	^ GbsChunkedMigrationRunner
		on: self
		source: aSourceClassOrName
		target: aTargetClassOrName
]

{ #category : 'repository' }
GbsSession >> methodMirrorForClass: aClassOrName selector: aSelector [
	^ self
		repository
		methodMirrorForClass: aClassOrName
		selector: aSelector
]

{ #category : 'repository' }
GbsSession >> methodMirrorForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		methodMirrorForClassNamed: aClassName
		selector: aSelector
]

{ #category : 'repository' }
GbsSession >> methodObjectForClass: aClassOrName selector: aSelector [
	^ self
		repository
		methodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : 'repository' }
GbsSession >> unboundMethodObjectForClass: aClassOrName selector: aSelector [
	^ self
		repository
		unboundMethodObjectForClass: aClassOrName
		selector: aSelector
]

{ #category : 'repository' }
GbsSession >> methodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		methodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : 'repository' }
GbsSession >> unboundMethodObjectForClassNamed: aClassName selector: aSelector [
	^ self
		repository
		unboundMethodObjectForClassNamed: aClassName
		selector: aSelector
]

{ #category : 'named-objects' }
GbsSession >> namedObjectAt: aName [
	^ self
		namedObjectAt: aName
		ifAbsent: [ self error: aName asString , ' not defined' ]
]

{ #category : 'named-objects' }
GbsSession >> namedObjectAt: aName ifAbsent: aBlock [
	| symbol targetSymbol cached |
	symbol := self normalizedNamedObjectName: aName.
	cached := self namedObjectCache at: symbol ifAbsent: [ nil ].
	cached ifNotNil: [ ^ cached ].
	targetSymbol := self namedObjectAutoloadTargetFor: symbol.
	cached := self namedObjectCache at: targetSymbol ifAbsent: [ nil ].
	cached ifNotNil: [
		symbol ~= targetSymbol ifTrue: [ self namedObjectCache at: symbol put: cached ].
		^ cached ].
	cached := self resolveSymbol: targetSymbol ifAbsent: [ ^ aBlock value ].
	self namedObjectCache at: targetSymbol put: cached.
	symbol ~= targetSymbol ifTrue: [ self namedObjectCache at: symbol put: cached ].
	^ cached
]

{ #category : 'named-objects' }
GbsSession >> namedObjectCache [
	^ namedObjectCache ifNil: [ namedObjectCache := Dictionary new ]
]

{ #category : 'named-objects' }
GbsSession >> clearNamedObjectCache [
	namedObjectCache := Dictionary new.
	^ self
]

{ #category : 'named-objects' }
GbsSession >> namedObjectAutoloadRegistry [
	^ namedObjectAutoloadRegistry ifNil: [ namedObjectAutoloadRegistry := Dictionary new ]
]

{ #category : 'named-objects' }
GbsSession >> clearNamedObjectAutoloads [
	namedObjectAutoloadRegistry := Dictionary new.
	^ self
]

{ #category : 'named-objects' }
GbsSession >> registerNamedObjectAutoload: aName [
	^ self registerNamedObjectAutoload: aName remote: aName
]

{ #category : 'named-objects' }
GbsSession >> registerNamedObjectAutoload: localName remote: remoteName [
	| localSymbol remoteSymbol |
	localSymbol := self normalizedNamedObjectName: localName.
	remoteSymbol := self normalizedNamedObjectName: remoteName.
	self namedObjectAutoloadRegistry at: localSymbol put: remoteSymbol.
	^ remoteSymbol
]

{ #category : 'named-objects' }
GbsSession >> unregisterNamedObjectAutoload: aName [
	self
		namedObjectAutoloadRegistry
		removeKey: (self normalizedNamedObjectName: aName)
		ifAbsent: [ ].
	^ self
]

{ #category : 'named-objects' }
GbsSession >> hasNamedObjectAutoloadNamed: aName [
	^ self
		namedObjectAutoloadRegistry
		includesKey: (self normalizedNamedObjectName: aName)
]

{ #category : 'named-objects' }
GbsSession >> namedObjectAutoloadTargetFor: aName [
	| symbol |
	symbol := self normalizedNamedObjectName: aName.
	^ self namedObjectAutoloadRegistry at: symbol ifAbsent: [ symbol ]
]

{ #category : 'named-objects' }
GbsSession >> namedObjectAutoloadEntries [
	^ self namedObjectAutoloadRegistry associations asArray sort: [ :a :b |
		a key asString <= b key asString ]
]

{ #category : 'named-objects' }
GbsSession >> namedObjectAutoloadKeys [
	^ (self namedObjectAutoloadEntries collect: [ :each | each key ]) asArray
]

{ #category : 'named-objects' }
GbsSession >> namedObjectAutoloadReportText [
	| entries |
	entries := self namedObjectAutoloadEntries.
	entries isEmpty ifTrue: [ ^ 'No named-object autoload registrations.' ].
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Named Object Autoload'; cr; cr.
		entries do: [ :association |
			stream
				nextPutAll: association key asString;
				nextPutAll: ' -> ';
					nextPutAll: association value asString;
					cr ] ]
]

{ #category : 'named-objects' }
GbsSession >> hasCachedNamedObjectNamed: aName [
	| symbol |
	symbol := self normalizedNamedObjectName: aName.
	^ self namedObjectCache includesKey: symbol
]

{ #category : 'named-objects' }
GbsSession >> normalizedNamedObjectName: aName [
	^ aName isSymbol
		ifTrue: [ aName ]
		ifFalse: [ aName asString asSymbol ]
]

{ #category : 'named-objects' }
GbsSession >> namedObjectCacheEntries [
	^ self namedObjectCache associations asArray sort: [ :a :b | a key asString <= b key asString ]
]

{ #category : 'named-objects' }
GbsSession >> namedObjectCacheKeys [
	^ (self namedObjectCacheEntries collect: [ :each | each key ]) asArray
]

{ #category : 'named-objects' }
GbsSession >> namedObjectCacheReportText [
	| entries |
	entries := self namedObjectCacheEntries.
	entries isEmpty ifTrue: [ ^ 'No named objects cached.' ].
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Named Object Cache'; cr; cr.
		entries do: [ :association |
			| value |
			value := association value.
			stream nextPutAll: association key asString.
			(value respondsTo: #oop)
				ifTrue: [
					stream
						nextPutAll: ' -> oop ';
						nextPutAll: value oop asString ]
				ifFalse: [
					stream
						nextPutAll: ' -> ';
						nextPutAll: value printString ].
			stream cr ] ]
]

{ #category : 'object space' }
GbsSession >> objectForOop: anOop [
	^ self resultFor: anOop
]

{ #category : 'object space' }
GbsSession >> objectSpace [
	^ GbsObjectSpaceFacade on: self
]

{ #category : 'object space' }
GbsSession >> objectSpaceDiagnostics [
	^ GbsObjectSpaceDiagnosticsFacade on: self
]

{ #category : 'object space' }
GbsSession >> objectSpaceDiagnosticsReport [
	^ self objectSpaceDiagnostics report
]

{ #category : 'typed wrappers' }
GbsSession >> typedWrapperLifecycleEntries [
	^ GbsSessionManager typedWrapperLifecycleEntriesForSession: self
]

{ #category : 'typed wrappers' }
GbsSession >> typedWrapperLifecycleObjects [
	^ GbsSessionManager typedWrapperLifecycleObjectsForSession: self
]

{ #category : 'typed wrappers' }
GbsSession >> typedWrapperLifecycleReport [
	^ GbsSessionManager typedWrapperLifecycleReportForSession: self
]

{ #category : 'typed wrappers' }
GbsSession >> typedWrapperLifecycleReportText [
	^ GbsSessionManager typedWrapperLifecycleReportTextForSession: self
]

{ #category : 'typed wrappers' }
GbsSession >> invalidateStaleTypedWrapperClasses [
	^ GbsSessionManager invalidateStaleTypedWrapperClassesForSession: self
]

{ #category : 'typed wrappers' }
GbsSession >> refreshStaleTypedWrapperClasses [
	^ GbsSessionManager refreshStaleTypedWrapperClassesForSession: self
]

{ #category : 'typed wrappers' }
GbsSession >> refreshAllTypedWrapperClasses [
	^ GbsSessionManager refreshAllTypedWrapperClassesForSession: self
]

{ #category : 'object space' }
GbsSession >> defineFinalizerFor: anObject do: aBlock [
	^ self objectSpace defineFinalizerFor: anObject do: aBlock
]

{ #category : 'object space' }
GbsSession >> eachObjectDo: aBlock [
	^ self objectSpace eachObjectDo: aBlock
]

{ #category : 'object space' }
GbsSession >> eachObjectDo: aBlock batchSize: aSmallInteger [
	^ self objectSpace eachObjectDo: aBlock batchSize: aSmallInteger
]

{ #category : 'object space' }
GbsSession >> eachObjectOf: aClassOrName do: aBlock [
	^ self objectSpace eachObjectOf: aClassOrName do: aBlock
]

{ #category : 'object space' }
GbsSession >> eachObjectOf: aClassOrName do: aBlock batchSize: aSmallInteger [
	^ self
		objectSpace
		eachObjectOf: aClassOrName
		do: aBlock
		batchSize: aSmallInteger
]

{ #category : 'object space' }
GbsSession >> allSubclassesOf: aClassOrName [
	^ self objectSpace allSubclassesOf: aClassOrName
]

{ #category : 'object space' }
GbsSession >> allSubclassesOfNamed: aClassName [
	^ self objectSpace allSubclassesOfNamed: aClassName
]

{ #category : 'object space' }
GbsSession >> instancesInMemoryOf: aClassOrName [
	^ self objectSpace instancesInMemoryOf: aClassOrName
]

{ #category : 'object space' }
GbsSession >> instancesInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	^ self
		objectSpace
		instancesInMemoryOf: aClassOrName
		from: aStartIndex
		limit: aLimit
]

{ #category : 'object space' }
GbsSession >> instancesInMemoryOfNamed: aClassName [
	^ self objectSpace instancesInMemoryOfNamed: aClassName
]

{ #category : 'object space' }
GbsSession >> hasFinalizerFor: anObject [
	^ self objectSpace hasFinalizerFor: anObject
]

{ #category : 'object space' }
GbsSession >> loadedClassesIncludingModules [
	^ self objectSpace loadedClassesIncludingModules
]

{ #category : 'object space' }
GbsSession >> loadedClassesIncludingModules: aBoolean [
	^ self objectSpace loadedClassesIncludingModules: aBoolean
]

{ #category : 'object space' }
GbsSession >> sessionStateAt: aKey [
	^ self objectSpace sessionStateAt: aKey
]

{ #category : 'object space' }
GbsSession >> sessionStateAt: aKey ifAbsent: aBlock [
	^ self objectSpace sessionStateAt: aKey ifAbsent: aBlock
]

{ #category : 'object space' }
GbsSession >> sessionStateAt: aKey put: anObject [
	^ self objectSpace sessionStateAt: aKey put: anObject
]

{ #category : 'object space' }
GbsSession >> referencesTo: anObject [
	^ self objectSpace referencesTo: anObject
]

{ #category : 'object space' }
GbsSession >> referencesToOop: anOop [
	^ self objectSpace referencesToOop: anOop
]

{ #category : 'object space' }
GbsSession >> objectsInMemory [
	^ self objectSpace objectsInMemory
]

{ #category : 'object space' }
GbsSession >> objectsInMemoryFrom: aStartIndex limit: aLimit [
	^ self objectSpace objectsInMemoryFrom: aStartIndex limit: aLimit
]

{ #category : 'object space' }
GbsSession >> objectsInMemoryMatching: aBlock [
	^ self objectSpace objectsInMemoryMatching: aBlock
]

{ #category : 'object space' }
GbsSession >> objectsInMemoryMatching: aBlock limit: aLimit batchSize: aBatchSize [
	^ self
		objectSpace
		objectsInMemoryMatching: aBlock
		limit: aLimit
		batchSize: aBatchSize
]

{ #category : 'object space' }
GbsSession >> objectsInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	^ self
		objectSpace
		objectsInMemoryOf: aClassOrName
		from: aStartIndex
		limit: aLimit
]

{ #category : 'object space' }
GbsSession >> objectsInMemoryOf: aClassOrName matching: aBlock [
	^ self
		objectSpace
		objectsInMemoryOf: aClassOrName
		matching: aBlock
]

{ #category : 'object space' }
GbsSession >> objectsInMemoryOf: aClassOrName matching: aBlock limit: aLimit batchSize: aBatchSize [
	^ self
		objectSpace
		objectsInMemoryOf: aClassOrName
		matching: aBlock
		limit: aLimit
		batchSize: aBatchSize
]

{ #category : 'object space' }
GbsSession >> undefineFinalizerFor: anObject [
	^ self objectSpace undefineFinalizerFor: anObject
]

{ #category : 'named-objects' }
GbsSession >> published [
	"VisualWorks/VAST-style convenience accessor."
	^ self sessionForwarderFor: #Published
]

{ #category : 'named-objects' }
GbsSession >> bridgeRoot [
	^ GbsBridgeRootFacade on: self
]

{ #category : 'deprecated' }
GbsSession >> persistentRoot [
	"Deprecated. Use #bridgeRoot."
	self deprecated: 'Use #bridgeRoot.'.
	^ self bridgeRoot
]

{ #category : 'repository' }
GbsSession >> repository [
	^ GbsRepositoryFacade on: self
]

{ #category : 'repository' }
GbsSession >> repositoryRootCache [
	^ repositoryRootCache ifNil: [ repositoryRootCache := Dictionary new ]
]

{ #category : 'repository' }
GbsSession >> repositoryRootLifecycleVersion [
	^ repositoryRootLifecycleVersion ifNil: [ repositoryRootLifecycleVersion := 0 ]
]

{ #category : 'repository' }
GbsSession >> invalidateRepositoryRoots [
	repositoryRootLifecycleVersion := self repositoryRootLifecycleVersion + 1.
	repositoryRootCache := Dictionary new.
	^ self
]

{ #category : 'repository' }
GbsSession >> repositoryRootFacadeForKey: aRootKey path: aCollection [
	| normalizedPath cacheKey facade |
	normalizedPath := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ].
	cacheKey := { aRootKey. normalizedPath }.
	facade := self repositoryRootCache at: cacheKey ifAbsent: [ nil ].
	facade ifNotNil: [ ^ facade ].
	facade := GbsRepositoryRootFacade
		on: self
		rootKey: aRootKey
		path: normalizedPath.
	self repositoryRootCache at: cacheKey put: facade.
	^ facade
]

{ #category : 'deprecated' }
GbsSession >> root [
	"Deprecated. Use #repository root."
	self deprecated: 'Use #repository root.'.
	^ self repository root
]

{ #category : 'deprecated' }
GbsSession >> rootAt: aKey [
	"Deprecated. Use #repository rootAt:."
	self deprecated: 'Use #repository rootAt:.'.
	^ self repository rootAt: aKey
]

{ #category : 'deprecated' }
GbsSession >> rootAt: aKey ifAbsent: aBlock [
	"Deprecated. Use #repository rootAt:ifAbsent:."
	self deprecated: 'Use #repository rootAt:ifAbsent:.'.
	^ self repository rootAt: aKey ifAbsent: aBlock
]

{ #category : 'deprecated' }
GbsSession >> rootAt: aKey put: aValue [
	"Deprecated. Use #repository rootAt:put:."
	self deprecated: 'Use #repository rootAt:put:.'.
	^ self repository rootAt: aKey put: aValue
]

{ #category : 'named-objects' }
GbsSession >> sessionForwarderFor: aSymbol [
	"Answer an explicit forwarder/proxy for the named GemStone object in the current session."
	^ self
		namedObjectAt: aSymbol
		ifAbsent: [ self error: aSymbol printString , ' not defined' ]
]

{ #category : 'materialization' }
GbsSession >> materializeRuntimeValue: anObject [
	anObject ifNil: [ ^ nil ].
	^ anObject
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

{ #category : 'named-objects' }
GbsSession >> smalltalk [
	^ GbsSmalltalkFacade on: self
]

{ #category : 'named-objects' }
GbsSession >> symbolDictionaryNamed: aName [
	^ GbsSymbolDictionaryFacade on: self name: aName
]

{ #category : 'object space' }
GbsSession >> objectSpaceRepository [
	^ GbsObjectSpaceRepositoryFacade on: self
]

{ #category : 'transactions' }
GbsSession >> withCommitRetryCount: aRetryCount do: aBlock [
	| retries attempts result |
	retries := (aRetryCount ifNil: [ 0 ] ifNotNil: [ aRetryCount asInteger ]) max: 0.
	attempts := retries + 1.
	1 to: attempts do: [ :attempt |
		result := aBlock value.
		(self commitTransaction) ifTrue: [ ^ result ].
		attempt < attempts ifTrue: [ self abortTransaction ] ].
	GbsCommitConflictError signal: 'GemStone commit conflict after ', attempts printString, ' attempts.'
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
		((errorMsgLower includesSubstring: 'stn')
			or: [ errorMsgLower includesSubstring: 'stone' ]) ifTrue: [
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
		((errorMsgLower includesSubstring: 'fail')
			or: [
				(errorMsgLower includesSubstring: 'denied')
					or: [ errorMsgLower includesSubstring: 'disabled' ] ]) ifTrue: [
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
