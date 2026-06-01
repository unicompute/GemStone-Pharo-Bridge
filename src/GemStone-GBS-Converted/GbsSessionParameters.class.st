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

{ #category : 'persistence' }
GbsSessionParameters class >> exportAllParameters [
	^ self exportAllParametersIncludingSecrets: false
]

{ #category : 'persistence' }
GbsSessionParameters class >> exportAllParametersString [
	^ self exportAllParametersStringIncludingSecrets: false
]

{ #category : 'persistence' }
GbsSessionParameters class >> exportAllParametersStringIncludingSecrets: includeSecrets [
	^ self exportObjectStringFor: (self exportAllParametersIncludingSecrets: includeSecrets)
]

{ #category : 'persistence' }
GbsSessionParameters class >> exportAllParametersIncludingSecrets: includeSecrets [
	^ self allParameters collect: [ :each |
		each exportDictionaryIncludingSecrets: includeSecrets ] as: Array
]

{ #category : 'persistence' }
GbsSessionParameters class >> exportFormatIdentifier [
	^ 'GemStone-Pharo-Bridge.sessionParameters.v1'
]

{ #category : 'persistence' }
GbsSessionParameters class >> exportObjectFromString: aString [
	| ston |
	ston := Smalltalk at: #STON ifAbsent: [
		self error: 'STON support is required to import GemStone session parameters.' ].
	^ ston fromString: aString
]

{ #category : 'persistence' }
GbsSessionParameters class >> exportObjectStringFor: anObject [
	| ston |
	ston := Smalltalk at: #STON ifAbsent: [
		self error: 'STON support is required to export GemStone session parameters.' ].
	^ ston toString: anObject
]

{ #category : 'persistence' }
GbsSessionParameters class >> fromExportDictionary: aDictionary [
	^ self new
		applyExportDictionary: aDictionary;
		yourself
]

{ #category : 'persistence' }
GbsSessionParameters class >> importParametersFromExportString: aString [
	| imported |
	imported := self parametersFromExportString: aString.
	imported do: [ :each | self addParameter: each ].
	^ imported
]

{ #category : 'persistence' }
GbsSessionParameters class >> importParameterFromExportDictionary: aDictionary [
	| parameter |
	parameter := self fromExportDictionary: aDictionary.
	self addParameter: parameter.
	^ parameter
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

{ #category : 'persistence' }
GbsSessionParameters class >> parametersFromExportObject: anObject [
	anObject isDictionary ifTrue: [ ^ { self fromExportDictionary: anObject } ].
	(anObject isCollection and: [ anObject isString not ]) ifTrue: [
		^ anObject collect: [ :each | self fromExportDictionary: each ] as: Array ].
	self error: 'Session parameter export must contain a dictionary or collection of dictionaries.'
]

{ #category : 'persistence' }
GbsSessionParameters class >> parametersFromExportString: aString [
	^ self parametersFromExportObject: (self exportObjectFromString: aString)
]

{ #category : 'registry' }
GbsSessionParameters class >> registerSession: aSession [
	self allSessions add: aSession
]

{ #category : 'registry' }
GbsSessionParameters class >> removeParameter: aParam [
	self allParameters remove: aParam ifAbsent: [ ]
]

{ #category : 'persistence' }
GbsSessionParameters class >> replaceAllParametersFromExportDictionaries: dictionaries [
	| imported |
	imported := dictionaries collect: [ :each | self fromExportDictionary: each ].
	AllParameters := imported asOrderedCollection.
	^ AllParameters
]

{ #category : 'persistence' }
GbsSessionParameters class >> replaceAllParametersFromExportString: aString [
	AllParameters := (self parametersFromExportString: aString) asOrderedCollection.
	^ AllParameters
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

{ #category : 'persistence' }
GbsSessionParameters >> applyExportDictionary: aDictionary [
	name := self exportValueFrom: aDictionary at: 'name' ifAbsent: [ name ].
	gemStoneName := self exportValueFrom: aDictionary at: 'gemStoneName' ifAbsent: [ gemStoneName ].
	username := self exportValueFrom: aDictionary at: 'username' ifAbsent: [ username ].
	password := self exportValueFrom: aDictionary at: 'password' ifAbsent: [ password ].
	gsRemember := self booleanExportValueFrom: aDictionary at: 'gsRemember' default: gsRemember.
	hostUsername := self exportValueFrom: aDictionary at: 'hostUsername' ifAbsent: [ hostUsername ].
	hostPassword := self exportValueFrom: aDictionary at: 'hostPassword' ifAbsent: [ hostPassword ].
	gemService := self exportValueFrom: aDictionary at: 'gemService' ifAbsent: [ gemService ].
	hostRemember := self booleanExportValueFrom: aDictionary at: 'hostRemember' default: hostRemember.
	netObject := self exportValueFrom: aDictionary at: 'netObject' ifAbsent: [ netObject ].
	isX509 := self booleanExportValueFrom: aDictionary at: 'isX509' default: isX509.
	displayUsername := self exportValueFrom: aDictionary at: 'displayUsername' ifAbsent: [ displayUsername ].
	caCert := self exportValueFrom: aDictionary at: 'caCert' ifAbsent: [ caCert ].
	cert := self exportValueFrom: aDictionary at: 'cert' ifAbsent: [ cert ].
	privateKey := self exportValueFrom: aDictionary at: 'privateKey' ifAbsent: [ privateKey ].
	netldiHostOrIp := self exportValueFrom: aDictionary at: 'netldiHostOrIp' ifAbsent: [ netldiHostOrIp ].
	netldiNameOrPort := self exportValueFrom: aDictionary at: 'netldiNameOrPort' ifAbsent: [ netldiNameOrPort ].
	dirArg := self exportValueFrom: aDictionary at: 'dirArg' ifAbsent: [ dirArg ].
	extraGemArgs := self exportValueFrom: aDictionary at: 'extraGemArgs' ifAbsent: [ extraGemArgs ].
	logArg := self exportValueFrom: aDictionary at: 'logArg' ifAbsent: [ logArg ].
	self normalizeConnectionFields.
	^ self
]

{ #category : 'persistence' }
GbsSessionParameters >> booleanExportValueFrom: aDictionary at: aKey default: defaultBoolean [
	| value normalized |
	value := self exportValueFrom: aDictionary at: aKey ifAbsent: [ defaultBoolean ].
	value ifNil: [ ^ defaultBoolean ].
	(value == true or: [ value == false ]) ifTrue: [ ^ value ].
	value = 1 ifTrue: [ ^ true ].
	value = 0 ifTrue: [ ^ false ].
	value isString ifTrue: [
		normalized := value trimBoth asLowercase.
		(#('true' 'yes' '1' 'on') includes: normalized) ifTrue: [ ^ true ].
		(#('false' 'no' '0' 'off') includes: normalized) ifTrue: [ ^ false ] ].
	^ defaultBoolean
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

{ #category : 'persistence' }
GbsSessionParameters >> exportDictionary [
	^ self exportDictionaryIncludingSecrets: false
]

{ #category : 'persistence' }
GbsSessionParameters >> exportDictionaryIncludingSecrets: includeSecrets [
	self normalizeConnectionFields.
	^ Dictionary new
		at: 'format' put: self class exportFormatIdentifier;
		at: 'name' put: self name;
		at: 'gemStoneName' put: self gemStoneName;
		at: 'username' put: self username;
		at: 'password' put: (includeSecrets ifTrue: [ self password ] ifFalse: [ nil ]);
		at: 'gsRemember' put: self gsRemember;
		at: 'hostUsername' put: self hostUsername;
		at: 'hostPassword' put: (includeSecrets ifTrue: [ self hostPassword ] ifFalse: [ nil ]);
		at: 'gemService' put: self gemService;
		at: 'hostRemember' put: self hostRemember;
		at: 'netObject' put: self netObject;
		at: 'isX509' put: self isX509;
		at: 'displayUsername' put: self displayUsername;
		at: 'caCert' put: self caCert;
		at: 'cert' put: self cert;
		at: 'privateKey' put: self privateKey;
		at: 'netldiHostOrIp' put: self netldiHostOrIp;
		at: 'netldiNameOrPort' put: self netldiNameOrPort;
		at: 'dirArg' put: self dirArg;
		at: 'extraGemArgs' put: self extraGemArgs;
		at: 'logArg' put: self logArg;
		yourself
]

{ #category : 'persistence' }
GbsSessionParameters >> exportString [
	^ self exportStringIncludingSecrets: false
]

{ #category : 'persistence' }
GbsSessionParameters >> exportStringIncludingSecrets: includeSecrets [
	^ self class exportObjectStringFor: (self exportDictionaryIncludingSecrets: includeSecrets)
]

{ #category : 'persistence' }
GbsSessionParameters >> exportValueFrom: aDictionary at: aKey ifAbsent: absentBlock [
	(aDictionary includesKey: aKey) ifTrue: [ ^ aDictionary at: aKey ].
	(aDictionary includesKey: aKey asSymbol) ifTrue: [ ^ aDictionary at: aKey asSymbol ].
	^ absentBlock value
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

{ #category : 'validation' }
GbsSessionParameters >> connectionSummary [
	self normalizeConnectionFields.
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self username;
			nextPutAll: '@';
			nextPutAll: self gemStoneName;
			nextPutAll: ' via ';
			nextPutAll: self gemService.
		self netldiHostOrIp ifNotNil: [ :host |
			stream
				nextPutAll: ' netldiHost=';
				nextPutAll: host ].
		self netldiNameOrPort ifNotNil: [ :netldi |
			stream
				nextPutAll: ' netldi=';
				nextPutAll: netldi ] ]
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
    | interface result serviceString hostUserString hostPasswordString netldiString setNetError setNetResult executedSessionInit |

    "UI State Check"
    self isConnected ifTrue: [ ^ self inform: 'Already Connected' ].
    self validateForLogin.

    interface := GbsServerInterface uniqueInstance.
    interface apiGciInit.

    serviceString := self gemService.
    hostUserString := self hostUsername ifNil: [ '' ].
    hostPasswordString := self hostPassword ifNil: [ '' ].
    netldiString := self netldiRoutingString.

    setNetError := ExternalAddress allocate: 4096.
    executedSessionInit := ExternalAddress allocate: 4.
    [
        1 to: 4096 do: [ :i | setNetError byteAt: i put: 0 ].
        1 to: 4 do: [ :i | executedSessionInit byteAt: i put: 0 ].

        setNetResult := netldiString isEmpty
            ifTrue: [
                interface
                    apiGciSetNetEx_: gemStoneName
                    hostUser: hostUserString
                    hostPassword: hostPasswordString
                    service: serviceString
                    encrypted: 0
                    error: setNetError
                    size: 4096 ]
            ifFalse: [
                interface
                    apiGciSetNetEx__: gemStoneName
                    hostUser: hostUserString
                    hostPassword: hostPasswordString
                    service: serviceString
                    encrypted: 0
                    error: setNetError
                    size: 4096
                    netldi: netldiString ].

        setNetResult = 1 ifFalse: [
            self error: (setNetError readString ifEmpty: [ 'Invalid GemStone network parameters' ]) ].

        result := interface
            apiGciLoginEx_: username
            password: password
            flags: 0
            haltOn: -1
            executedSessionInit: executedSessionInit.

        result = 1 ifFalse: [
            self handleLoginError: interface ]
    ] ensure: [
        setNetError free.
        executedSessionInit free
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
    buffer := ExternalAddress allocate: 4096.
    [
        hasError := interface apiGciErr: buffer.
        (hasError = 1 or: [ hasError == true ]) ifTrue: [
            errNum := buffer signedLongAt: 105.
            rawErrMsg := self readErrorMessageFrom: buffer ]
    ] ensure: [ buffer free ].
    
    "Log to Transcript for debugging"
    Transcript show: '[GemStone Login Error]'; cr.
    Transcript show: '  Stone: ', self gemStoneName; cr.
    Transcript show: '  User: ', self username; cr.
    Transcript show: '  Error Number: ', (errNum ifNil: [ 'nil' ]) printString; cr.
    Transcript show: '  Raw Message: ', (rawErrMsg ifNil: [ '(empty)' ]); cr.
    
    "Build the error message - use netldiErrorMessage if raw message is empty"
    errorMessage := self interpretErrorMessage: rawErrMsg errorNumber: errNum.
    
    "Log the interpreted error"
    Transcript show: '  Interpreted: '; show: (errorMessage copyReplaceAll: String cr with: ' | '); cr; cr.
    
    self error: errorMessage
]

{ #category : 'connection' }
GbsSessionParameters >> readErrorMessageFrom: aBuffer [
    "GciErrSType has had alignment-sensitive changes across GemStone builds.
    Scan for the first useful printable C string instead of relying on one
    offset."
    | best bestSize current currentSize byte |
    best := ''.
    bestSize := 0.
    current := WriteStream on: String new.
    currentSize := 0.

    1 to: 3000 do: [ :i |
        byte := [ aBuffer byteAt: i ] on: Error do: [ 0 ].
        ((byte between: 32 and: 126) or: [ byte = 10 or: [ byte = 13 or: [ byte = 9 ] ] ])
            ifTrue: [
                current nextPut: (Character codePoint: byte).
                currentSize := currentSize + 1 ]
            ifFalse: [
                currentSize > bestSize ifTrue: [
                    best := current contents.
                    bestSize := currentSize ].
                current := WriteStream on: String new.
                currentSize := 0 ] ].
    currentSize > bestSize ifTrue: [ best := current contents ].
    best := self ensureCleanString: best.
    ^ best isEmpty ifTrue: [ nil ] ifFalse: [ best ]
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
GbsSessionParameters >> netldiErrorMessage [
    "Return a helpful message when netldi is likely not running"
    ^ 'GemStone netldi daemon is not running or not accessible.

To fix this, start netldi on the GemStone server:

  startnetldi -a ', self gemStoneName, ' -g username

If netldi is already running, check:
* Stone name is correct: ', self gemStoneName, '
* Network connectivity to the GemStone server
* Firewall settings are not blocking the connection'
]

{ #category : 'connection' }
GbsSessionParameters >> interpretErrorMessage: aString errorNumber: anErrorNumber [
    "Interpret error messages and provide user-friendly explanations for common issues"
    | errorMsgLower originalMsg |

    anErrorNumber = 4051 ifTrue: [
        ^ 'GemStone login failed.

The username or password is invalid or expired.

Original error: ', ((aString isNil or: [ aString asString trimBoth isEmpty ])
            ifTrue: [ '(no message returned by GCI)' ]
            ifFalse: [ aString asString trimBoth ]) ].
    
    "Handle nil or empty messages - likely netldi not running"
    (aString isNil or: [ aString trimBoth isEmpty ]) ifTrue: [
        ^ self netldiErrorMessage ].
    
    "Convert to string if needed"
    originalMsg := aString isString 
        ifTrue: [ aString trimBoth ]
        ifFalse: [ 
            "Handle ByteArray or other types"
            [ 
                (aString isKindOf: ByteArray) ifTrue: [
                    self convertBytesToString: aString ]
                ifFalse: [ aString asString trimBoth ]
            ] on: Error do: [ 
                ^ self netldiErrorMessage ] ].
    
    "Double check if converted message is empty"
    originalMsg isEmpty ifTrue: [
        ^ self netldiErrorMessage ].
    
    errorMsgLower := originalMsg asLowercase.
    
    anErrorNumber = 4042 ifTrue: [
        ^ 'GemStone could not start a remote Gem through netldi.

Netldi is reachable, but it rejected or failed the gemnetobject request. On Linux this commonly means the GemStone host username/password were not supplied or are invalid.

Set hostUsername/hostPassword on GbsSessionParameters, or export OKZ_GEMSTONE_HOST_USERNAME and OKZ_GEMSTONE_HOST_PASSWORD before starting Pharo.

Original error: ', originalMsg ].
    
    "Check for netldi-specific errors"
    (errorMsgLower includesSubstring: 'connection refused') ifTrue: [
        ^ 'Cannot connect to GemStone netldi daemon.

The netldi is not running or not accessible.

To fix this, start netldi on the GemStone server:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ].
    
    (errorMsgLower includesSubstring: 'no such') ifTrue: [
        (errorMsgLower includesSubstring: 'stn' or: [ errorMsgLower includesSubstring: 'stone' ]) ifTrue: [
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
        (errorMsgLower includesSubstring: 'fail' or: [ errorMsgLower includesSubstring: 'denied' or: [ errorMsgLower includesSubstring: 'disabled' ] ]) ifTrue: [
            ^ 'GemStone login failed.

Please check your username and password, or verify that logins are enabled.

Original error: ', originalMsg ] ].
    
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

{ #category : 'validation' }
GbsSessionParameters >> loginValidationErrorMessage [
	^ self validationMessageFrom: self loginValidationMessages
]

{ #category : 'validation' }
GbsSessionParameters >> loginValidationMessages [
	| messages |
	self normalizeConnectionFields.
	messages := OrderedCollection new.
	self gemStoneName isEmpty ifTrue: [
		messages add: 'GemStone stone name is required.' ].
	self username isEmpty ifTrue: [
		messages add: 'GemStone username is required.' ].
	self gemService isEmpty ifTrue: [
		messages add: 'Gem service is required.' ].
	(self netldiHostOrIp notNil and: [ self netldiNameOrPort isNil ]) ifTrue: [
		messages add: 'NetLDI host/IP requires a NetLDI name or port.' ].
	^ messages asArray
]

{ #category : 'accessing' }
GbsSessionParameters >> name [ ^ name
]

{ #category : 'accessing' }
GbsSessionParameters >> name: aValue [ name := aValue
]

{ #category : 'validation' }
GbsSessionParameters >> normalizeConnectionFields [
	name := self normalizedConnectionString: name.
	gemStoneName := self normalizedConnectionString: gemStoneName.
	username := self normalizedConnectionString: username.
	gemService := self normalizedConnectionString: gemService.
	gemService isEmpty ifTrue: [ gemService := 'gemnetobject' ].
	hostUsername := self normalizedOptionalConnectionString: hostUsername.
	netObject := self normalizedOptionalConnectionString: netObject.
	netldiHostOrIp := self normalizedOptionalConnectionString: netldiHostOrIp.
	netldiNameOrPort := self normalizedOptionalConnectionString: netldiNameOrPort
]

{ #category : 'validation' }
GbsSessionParameters >> normalizedConnectionString: aValue [
	aValue ifNil: [ ^ '' ].
	^ aValue asString trimBoth
]

{ #category : 'validation' }
GbsSessionParameters >> normalizedOptionalConnectionString: aValue [
	| normalized |
	normalized := self normalizedConnectionString: aValue.
	^ normalized isEmpty ifTrue: [ nil ] ifFalse: [ normalized ]
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

{ #category : 'validation' }
GbsSessionParameters >> netldiRoutingString [
	self normalizeConnectionFields.
	self netldiNameOrPort ifNil: [ ^ '' ].
	self netldiHostOrIp ifNil: [ ^ self netldiNameOrPort ].
	(self netldiNameOrPort includes: $#) ifTrue: [ ^ self netldiNameOrPort ].
	^ self netldiHostOrIp, '#', self netldiNameOrPort
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

{ #category : 'validation' }
GbsSessionParameters >> validateForLogin [
	self loginValidationErrorMessage ifNotNil: [ :message | self error: message ].
	^ true
]

{ #category : 'validation' }
GbsSessionParameters >> validationMessageFrom: messages [
	| first |
	messages isEmpty ifTrue: [ ^ nil ].
	first := true.
	^ String streamContents: [ :stream |
		messages do: [ :each |
			first
				ifTrue: [ first := false ]
				ifFalse: [ stream cr ].
			stream nextPutAll: each ] ]
]
