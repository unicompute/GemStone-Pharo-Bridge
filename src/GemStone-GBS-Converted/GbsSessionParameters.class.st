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
        executeAndPrint: 'Transcript fetchAndClear' 
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
    | interface outBuf stonePtr userPtr servicePtr emptyPtr result serviceString |
    
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
    servicePtr := ExternalAddress allocate: serviceString size + 1. "Allocating based on variable"
    emptyPtr := ExternalAddress allocate: 1.

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

        "4. ENCRYPT & LOGIN (Your Logic)"
        interface apiGciEncrypt: password into: outBuf size: 1024.
        interface
            apiGciSetNet: stonePtr
            host: emptyPtr
            net: emptyPtr
            service: servicePtr.

        result := interface
                    apiGciLoginEx: userPtr
                    password: outBuf
                    flags: 3
                    context: 0.

        result = 1 ifFalse: [
            interface checkError.
            self error: 'Login Failed'
        ]
    ] ensure: [
        outBuf free.
        stonePtr free.
        userPtr free.
        servicePtr free.
        emptyPtr free
    ].

    "5. UI STATE UPDATES (Crucial for Launcher)"
    
    "Set the session ID on THIS object so the UI knows we are connected"
    sessionId := 1. 

    "Create the GbsSession wrapper (Your logic)"
    CurrentSession := GbsSession new
                        sessionOop: 1;
                        parameters: self;
                        yourself.
                        
    "Register so it appears in the bottom list"
    self class registerSession: self.
    self inform: 'Login Successful'.
    
    ^ CurrentSession
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
GbsSessionParameters >> username [ ^ username
]

{ #category : 'accessing' }
GbsSessionParameters >> username: aValue [ username := aValue
]
