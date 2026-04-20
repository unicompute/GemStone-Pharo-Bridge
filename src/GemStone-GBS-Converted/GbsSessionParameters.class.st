Class {
	#name : 'GbsSessionParameters',
	#superclass : 'Object',
	#instVars : [
		'name',
		'gemStoneName',
		'username',
		'password',
		'gsRemember',
		'hostUsername',
		'hostPassword',
		'gemService',
		'hostRemember',
		'netObject',
		'isX509',
		'displayUsername',
		'caCert',
		'cert',
		'privateKey',
		'netldiHostOrIp',
		'netldiNameOrPort',
		'dirArg',
		'extraGemArgs',
		'logArg',
		'sessionId'
	],
	#classVars : [
		'AllParameters',
		'CurrentSession',
		'PollingEnabled',
		'Sessions'
	],
	#classInstVars : [
		'allParameters',
		'sessions'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'registry' }
GbsSessionParameters class >> addParameter: aParam [
	self allParameters add: aParam
]

{ #category : 'accessing' }
GbsSessionParameters class >> allParameters [
	^ AllParameters ifNil: [ AllParameters := OrderedCollection new ]
]

{ #category : 'accessing' }
GbsSessionParameters class >> allSessions [
	^ Sessions ifNil: [ Sessions := OrderedCollection new ]
]

{ #category : 'accessing' }
GbsSessionParameters class >> currentSession [
	^ CurrentSession
]

{ #category : 'accessing' }
GbsSessionParameters class >> currentSession: aSession [
	CurrentSession := aSession
]

{ #category : 'polling' }
GbsSessionParameters class >> pollingEnabled [
    "Persisted in the image as a global. Defaults to true."
    ^ (Smalltalk globals at: #GbsPollingEnabled ifAbsent: [ true ])


]

{ #category : 'polling' }
GbsSessionParameters class >> pollingEnabled: aBoolean [ 
    Smalltalk globals at: #GbsPollingEnabled put: aBoolean.
    ^ aBoolean


]

{ #category : 'registry' }
GbsSessionParameters class >> registerSession: aSession [
	self allSessions add: aSession
]

{ #category : 'registry' }
GbsSessionParameters class >> removeParameter: aParam [
	self allParameters remove: aParam ifAbsent: [ ]
]

{ #category : 'polling' }
GbsSessionParameters class >> togglePolling [ 
    ^ self pollingEnabled: self pollingEnabled not



]

{ #category : 'registry' }
GbsSessionParameters class >> unregisterSession: aSession [
    self allSessions remove: aSession ifAbsent: [ ]
]

{ #category : 'transactions' }
GbsSessionParameters >> abortTransaction [
    self isConnected ifTrue: [ 
        GbsServerInterface uniqueInstance abort: sessionId 
    ].
]

{ #category : 'accessing' }
GbsSessionParameters >> caCert [ ^ caCert
]

{ #category : 'accessing' }
GbsSessionParameters >> caCert: aValue [ caCert := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> cert [ ^ cert
]

{ #category : 'accessing' }
GbsSessionParameters >> cert: aValue [ cert := aValue
]

{ #category : 'transactions' }
GbsSessionParameters >> commitTransaction [
    self isConnected ifTrue: [ 
        GbsServerInterface uniqueInstance commit: sessionId 
    ].
]

{ #category : 'accessing' }
GbsSessionParameters >> dirArg [ ^ dirArg
]

{ #category : 'accessing' }
GbsSessionParameters >> dirArg: aValue [ dirArg := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> displayUsername [ ^ displayUsername
]

{ #category : 'accessing' }
GbsSessionParameters >> displayUsername: aValue [ displayUsername := aValue
]

{ #category : 'execution' }
GbsSessionParameters >> evaluate: aString [
    self isConnected ifFalse: [ ^ self error: 'Not Connected' ].
    
    ^ GbsServerInterface uniqueInstance 
        execute: aString 
        inSession: sessionId.
]

{ #category : 'evaluating' }
GbsSessionParameters >> evaluateAndFetchString: aString [
    "Ask the server interface to execute the code and fetch the resulting string"
    ^ GbsServerInterface uniqueInstance 
        executeAndPrint: aString 
        inSession: self sessionId.
]

{ #category : 'accessing' }
GbsSessionParameters >> extraGemArgs [ ^ extraGemArgs
]

{ #category : 'accessing' }
GbsSessionParameters >> extraGemArgs: aValue [ extraGemArgs := aValue
]

{ #category : 'evaluating' }
GbsSessionParameters >> fetchTranscriptLogs [
    "Ask the server interface to fetch the active Transcript logs"
    ^ GbsServerInterface uniqueInstance 
        executeAndPrint: '[
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
	] value' 
        inSession: self sessionId.
]

{ #category : 'accessing' }
GbsSessionParameters >> gemService [ ^ gemService
]

{ #category : 'accessing' }
GbsSessionParameters >> gemService: aValue [ gemService := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> gemStoneName [ ^ gemStoneName
]

{ #category : 'accessing' }
GbsSessionParameters >> gemStoneName: aValue [ gemStoneName := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> gsRemember [ ^ gsRemember
]

{ #category : 'accessing' }
GbsSessionParameters >> gsRemember: aValue [ gsRemember := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> hostPassword [ ^ hostPassword
]

{ #category : 'accessing' }
GbsSessionParameters >> hostPassword: aValue [ hostPassword := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> hostRemember [ ^ hostRemember
]

{ #category : 'accessing' }
GbsSessionParameters >> hostRemember: aValue [ hostRemember := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> hostUsername [ ^ hostUsername
]

{ #category : 'accessing' }
GbsSessionParameters >> hostUsername: aValue [ hostUsername := aValue
]

{ #category : 'initialization' }
GbsSessionParameters >> initialize [
	super initialize.
	name := 'New Config'.
	gemStoneName := 'gs64stone'.
	gemService := 'gemnetobject'.
	gsRemember := false.
	hostRemember := false.
	isX509 := false.
]

{ #category : 'testing' }
GbsSessionParameters >> isConnected [
    "It is connected if we have a valid session ID number"
    ^ sessionId notNil and: [ sessionId > 0 ]
]

{ #category : 'accessing' }
GbsSessionParameters >> isX509 [ ^ isX509
]

{ #category : 'accessing' }
GbsSessionParameters >> isX509: aValue [ isX509 := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> logArg [ ^ logArg
]

{ #category : 'accessing' }
GbsSessionParameters >> logArg: aValue [ logArg := aValue
]

{ #category : 'connection' }
GbsSessionParameters >> login [
    | interface outBuf stonePtr userPtr servicePtr emptyPtr result serviceString hostPtr netPtr |

    "UI State Check"
    self isConnected ifTrue: [ ^ self inform: 'Already Connected' ].

    interface := GbsServerInterface uniqueInstance.
    interface apiGciInit.

    "1. DYNAMIC SERVICE: Use the value from the text field (default to gemnetobject)"
    serviceString := (self gemService isNil or: [ self gemService isEmpty ])
        ifTrue: [ 'gemnetobject' ]
        ifFalse: [ self gemService ].

    "2. ALLOCATE (Your Manual FFI Code)"
    outBuf := ExternalAddress allocate: 1024.
    stonePtr := ExternalAddress allocate: gemStoneName size + 1.
    userPtr := ExternalAddress allocate: username size + 1.
    servicePtr := ExternalAddress allocate: serviceString size + 1.
    emptyPtr := ExternalAddress allocate: 1.
    
    "Allocate host and net pointers for netldi configuration"
    hostPtr := ExternalAddress allocate: 256.
    netPtr := ExternalAddress allocate: 256.

    [
        "3. COPY STRINGS (Your Manual Loop Logic)"
        1 to: gemStoneName size do: [ :i | stonePtr byteAt: i put: ( gemStoneName at: i ) asInteger ].
        stonePtr byteAt: gemStoneName size + 1 put: 0.

        1 to: username size do: [ :i | userPtr byteAt: i put: ( username at: i ) asInteger ].
        userPtr byteAt: username size + 1 put: 0.

        "Use the serviceString instead of the hardcoded array"
        1 to: serviceString size do: [ :i | servicePtr byteAt: i put: ( serviceString at: i ) asInteger ].
        servicePtr byteAt: serviceString size + 1 put: 0.

        emptyPtr byteAt: 1 put: 0.
        
        "Copy netldi host and port if configured"
        self netldiHostOrIp ifNotNil: [ :host |
            1 to: host size do: [ :i | hostPtr byteAt: i put: ( host at: i ) asInteger ].
            hostPtr byteAt: host size + 1 put: 0 ].
        
        self netldiNameOrPort ifNotNil: [ :port |
            1 to: port size do: [ :i | netPtr byteAt: i put: ( port at: i ) asInteger ].
            netPtr byteAt: port size + 1 put: 0 ].

        "4. ENCRYPT & LOGIN (Your Logic)"
        interface apiGciEncrypt: password into: outBuf size: 1024.
        interface
            apiGciSetNet: stonePtr
            host: (self netldiHostOrIp ifNil: [ emptyPtr ] ifNotNil: [ hostPtr ])
            net: (self netldiNameOrPort ifNil: [ emptyPtr ] ifNotNil: [ netPtr ])
            service: servicePtr.

        result := interface
                    apiGciLoginEx: userPtr
                    password: outBuf
                    flags: 3
                    context: 0.

        result = 1 ifFalse: [
            self handleLoginError: interface ]
    ] ensure: [
        outBuf free.
        stonePtr free.
        userPtr free.
        servicePtr free.
        emptyPtr free.
        hostPtr free.
        netPtr free
    ].

	    "5. UI STATE UPDATES (Crucial for Launcher)"
	    sessionId := result.

	    "Create the active session wrapper and mark it logged in"
	    CurrentSession := GbsSession new
	                        sessionId: result;
	                        sessionOop: result;
	                        isLoggedIn: true;
	                        parameters: self;
	                        yourself.

    "Register so it appears in the bottom list"
    self class registerSession: self.
    self inform: 'Login Successful'.

    ^ CurrentSession
]

{ #category : 'connection' }
GbsSessionParameters >> handleLoginError: interface [
    "Handle login failure with specific error messages for netldi and connection issues"
    | errorMessage rawErrMsg errNum hasError buffer |
    
    "First, try to read the raw error message from GCI"
    buffer := ExternalAddress allocate: 2168.
    [
        hasError := interface apiGciErr: buffer.
        (hasError = 1 or: [ hasError == true ]) ifTrue: [
            errNum := buffer signedLongAt: 5.
            rawErrMsg := self ensureCleanString: (self readErrorMessageFrom: buffer) ]
    ] ensure: [ buffer free ].
    
    "Log to Transcript for debugging"
    Transcript show: '[GemStone Login Error]'; cr.
    Transcript show: '  Stone: ', self gemStoneName; cr.
    Transcript show: '  User: ', self username; cr.
    Transcript show: '  Error Number: ', (errNum ifNil: [ 'nil' ]) printString; cr.
    Transcript show: '  Raw Message: ', ((rawErrMsg isNil or: [ rawErrMsg isEmpty ]) ifTrue: [ '(empty)' ] ifFalse: [ rawErrMsg ]); cr.
    
    "Build the error message - use netldiErrorMessage if raw message is empty"
    errorMessage := self interpretErrorMessage: rawErrMsg errorNumber: errNum.
    
    "Log the interpreted error"
    Transcript show: '  Interpreted: '; show: (errorMessage copyReplaceAll: String cr with: ' | '); cr; cr.
    
    self error: errorMessage
]

{ #category : 'connection' }
GbsSessionParameters >> readErrorMessageFrom: aBuffer [
    "Try to read error message from buffer using multiple strategies"
    | msg cleaned |
    
    "Strategy 1: Read bytes directly from offset 112 (most reliable)"
    [ | bytes strEnd |
      bytes := ByteArray new: 1024.
      1 to: 1024 do: [ :i |
          bytes at: i put: (aBuffer + 112) byteAt: i - 1 ].
      strEnd := bytes indexOf: 0.
      strEnd > 1 ifTrue: [
          msg := self convertBytesToString: (bytes copyFrom: 1 to: strEnd - 1).
          msg trimBoth isEmpty ifFalse: [ ^ msg ] ] ]
        on: Error do: [ ].
    
    "Strategy 2: Try readString at offset 112"
    [ msg := (aBuffer + 112) readString.
      msg ifNotNil: [ :raw | 
          cleaned := self ensureCleanString: raw.
          cleaned trimBoth isEmpty ifFalse: [ ^ cleaned ] ] ] 
        on: Error do: [ ].
    
    "Strategy 3: Try readString at offset 113"
    [ msg := (aBuffer + 113) readString.
      msg ifNotNil: [ :raw | 
          cleaned := self ensureCleanString: raw.
          cleaned trimBoth isEmpty ifFalse: [ ^ cleaned ] ] ] 
        on: Error do: [ ].
    
    "Strategy 4: Try readString at offset 114"
    [ msg := (aBuffer + 114) readString.
      msg ifNotNil: [ :raw | 
          cleaned := self ensureCleanString: raw.
          cleaned trimBoth isEmpty ifFalse: [ ^ cleaned ] ] ] 
        on: Error do: [ ].
    
    ^ nil
]

{ #category : 'connection' }
GbsSessionParameters >> convertBytesToString: aByteArray [
    "Convert ByteArray to String properly"
    | stream |
    aByteArray ifNil: [ ^ '' ].
    aByteArray isEmpty ifTrue: [ ^ '' ].
    
    stream := WriteStream on: String new.
    aByteArray do: [ :byte |
        byte > 0 ifTrue: [
            "Convert byte to character"
            stream nextPut: (Character codePoint: byte) ] ].
    
    ^ stream contents
]

{ #category : 'connection' }
GbsSessionParameters >> ensureCleanString: aString [
	| source |
	aString ifNil: [ ^ '' ].
	source := aString asString.
	^ (String streamContents: [ :stream |
		source do: [ :each |
			each codePoint = 0 ifFalse: [ stream nextPut: each ] ] ])
		trimBoth
]

{ #category : 'connection' }
GbsSessionParameters >> invalidCredentialsErrorMessage: originalMsg [
	| message |
	message := self ensureCleanString: originalMsg.
	message isEmpty ifTrue: [
		message := 'Login failed: the userId/password combination is invalid or expired.' ].
	^ 'GemStone login failed.

Please check your username and password, or verify that logins are enabled.

Original error: ', message
]

{ #category : 'connection' }
GbsSessionParameters >> netldiErrorMessage [
    "Return a helpful message when netldi is likely not running"
    ^ 'GemStone netldi daemon is not running or not accessible.

To fix this, start netldi on the GemStone server:

  startnetldi -a ', self gemStoneName, ' -g username

If netldi is already running, check:
• Stone name is correct: ', self gemStoneName, '
• Network connectivity to the GemStone server
• Firewall settings are not blocking the connection'
]

{ #category : 'connection' }
GbsSessionParameters >> interpretErrorMessage: aString errorNumber: anErrorNumber [
    "Interpret error messages and provide user-friendly explanations for common issues"
    | errorMsgLower originalMsg |

    "Convert to string if needed"
    originalMsg := aString
        ifNil: [ '' ]
        ifNotNil: [
            [ 
                (aString isKindOf: ByteArray)
                    ifTrue: [ self convertBytesToString: aString ]
                    ifFalse: [ aString asString ]
            ] on: Error do: [ '' ] ].
    originalMsg := self ensureCleanString: originalMsg.

    "4051 is authentication failure even when the raw GCI buffer is empty or garbled."
    anErrorNumber = 4051 ifTrue: [
        ^ self invalidCredentialsErrorMessage: originalMsg ].

    "Handle nil or empty messages after auth-code handling."
    originalMsg isEmpty ifTrue: [
        ^ self netldiErrorMessage ].
    
    errorMsgLower := originalMsg asLowercase.
    
    "Check for netldi-specific errors"
    (errorMsgLower includesSubstring: 'connection refused') ifTrue: [
        ^ 'Cannot connect to GemStone netldi daemon.

The netldi is not running or not accessible.

To fix this, start netldi on the GemStone server:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ].
    
    (errorMsgLower includesSubstring: 'no such') ifTrue: [
        ((errorMsgLower includesSubstring: 'stn')
            or: [ errorMsgLower includesSubstring: 'stone' ]) ifTrue: [
            ^ 'Cannot find the GemStone stone "', self gemStoneName, '".

Please check that the stone exists and netldi is running.

To start the stone and netldi:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ] ].
    
    (errorMsgLower includesSubstring: 'netldi') ifTrue: [
        ^ 'GemStone netldi daemon is not running or not accessible.

To fix this, start netldi on the GemStone server:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ].
    
    (errorMsgLower includesSubstring: 'gemnetobject') ifTrue: [
        ^ 'Cannot connect to gemnetobject service.

Please ensure the GemStone service is running.

To start netldi:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ].
    
    (errorMsgLower includesSubstring: 'login') ifTrue: [
        ((errorMsgLower includesSubstring: 'fail')
            or: [ (errorMsgLower includesSubstring: 'denied')
            or: [ errorMsgLower includesSubstring: 'disabled' ] ]) ifTrue: [
            ^ self invalidCredentialsErrorMessage: originalMsg ] ].

    ((errorMsgLower includesSubstring: 'invalid password')
        or: [ (errorMsgLower includesSubstring: 'invalid or expired')
        or: [ errorMsgLower includesSubstring: 'userid/password combination' ] ]) ifTrue: [
        ^ self invalidCredentialsErrorMessage: originalMsg ].
    
    (errorMsgLower includesSubstring: 'shutdown') ifTrue: [
        ^ 'GemStone is shutting down.

Please wait for it to fully stop and restart it:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ].
    
    (errorMsgLower includesSubstring: 'timeout') ifTrue: [
        ^ 'Connection to GemStone timed out.

Please check network connectivity and that netldi is running.

To start netldi:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ].
    
    (anErrorNumber notNil and: [ anErrorNumber ~= 0 ]) ifTrue: [
        ^ 'GemStone error ', anErrorNumber asString, ': ', originalMsg ].
    
    "Fallback message"
    originalMsg isEmpty ifTrue: [
        ^ self netldiErrorMessage ].
    
    ^ originalMsg
]

{ #category : 'connection' }
GbsSessionParameters >> logout [
    self isConnected ifTrue: [
        
        "1. Call the FFI Logout (Try standard 0-arg first)"
        [
            GbsServerInterface uniqueInstance apiGciLogout.
        ] on: MessageNotUnderstood do: [
             "Fallback: If it expects a session ID (rare in this specific binding)"
             GbsServerInterface uniqueInstance perform: #apiGciLogout: with: sessionId.
        ].

        "2. Clear Local State"
        sessionId := nil.
        CurrentSession := nil.
        
        "3. Unregister from the Active List"
        self class unregisterSession: self.
        
        self inform: 'Logged Out'.
    ].
]

{ #category : 'accessing' }
GbsSessionParameters >> name [ ^ name
]

{ #category : 'accessing' }
GbsSessionParameters >> name: aValue [ name := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> netObject [ ^ netObject
]

{ #category : 'accessing' }
GbsSessionParameters >> netObject: aValue [ netObject := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> netldiHostOrIp [ ^ netldiHostOrIp
]

{ #category : 'accessing' }
GbsSessionParameters >> netldiHostOrIp: aValue [ netldiHostOrIp := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> netldiNameOrPort [ ^ netldiNameOrPort
]

{ #category : 'accessing' }
GbsSessionParameters >> netldiNameOrPort: aValue [ netldiNameOrPort := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> password [ ^ password
]

{ #category : 'accessing' }
GbsSessionParameters >> password: aValue [ password := aValue
]

{ #category : 'accessing' }
GbsSessionParameters >> privateKey [ ^ privateKey
]

{ #category : 'accessing' }
GbsSessionParameters >> privateKey: aValue [ privateKey := aValue
]

{ #category : 'transactions' }
GbsSessionParameters >> sendInterrupt [
    self isConnected ifTrue: [ 
        GbsServerInterface uniqueInstance break: sessionId 
    ].
]

{ #category : 'accessing' }
GbsSessionParameters >> sessionId [
    ^ sessionId
]

{ #category : 'accessing' }
GbsSessionParameters >> sessionId: anInteger [
	sessionId := anInteger
]

{ #category : 'accessing' }
GbsSessionParameters >> username [ ^ username
]

{ #category : 'accessing' }
GbsSessionParameters >> username: aValue [ username := aValue
]
