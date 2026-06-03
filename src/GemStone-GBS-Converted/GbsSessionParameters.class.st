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
		'materializationBatchSize',
		'materializationMaxObjects',
		'materializationMaxDepth',
		'materializationMaxBatchBytes',
		'materializationMaxFrontierOops',
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
	| prepared |
	prepared := self prepareImportedParameters: { aParam } replacingExisting: false.
	self allParameters add: prepared first.
	^ prepared first
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
	^ self exportObjectStringFor: (self exportAllParametersObjectIncludingSecrets: includeSecrets)
]

{ #category : 'persistence' }
GbsSessionParameters class >> exportAllParametersIncludingSecrets: includeSecrets [
	^ self allParameters collect: [ :each |
		each exportDictionaryIncludingSecrets: includeSecrets ] as: Array
]

{ #category : 'persistence' }
GbsSessionParameters class >> exportAllParametersObjectIncludingSecrets: includeSecrets [
	^ Dictionary new
		at: 'format' put: self exportBundleFormatIdentifier;
		at: 'schemaVersion' put: 2;
		at: 'exportedAt' put: DateAndTime now asString;
		at: 'includesSecrets' put: includeSecrets;
		at: 'parameters' put: (self exportAllParametersIncludingSecrets: includeSecrets);
		yourself
]

{ #category : 'persistence' }
GbsSessionParameters class >> exportBundleFormatIdentifier [
	^ 'GemStone-Pharo-Bridge.sessionParameters.bundle'
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
	imported := self prepareImportedParameters: (self parametersFromExportString: aString) replacingExisting: false.
	self allParameters addAll: imported.
	^ imported
]

{ #category : 'persistence' }
GbsSessionParameters class >> importParameterFromExportDictionary: aDictionary [
	| parameter |
	parameter := self fromExportDictionary: aDictionary.
	^ self addParameter: parameter
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
	| nestedParameters |
	anObject isDictionary ifTrue: [
		nestedParameters := self
			valueFromDictionary: anObject
			atAny: #('parameters' 'sessionParameters')
			ifAbsent: [ nil ].
		nestedParameters ifNotNil: [
			^ self parametersFromExportObject: nestedParameters ] ].
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
	imported := self
		prepareImportedParameters: (dictionaries collect: [ :each | self fromExportDictionary: each ])
		replacingExisting: true.
	AllParameters := imported asOrderedCollection.
	^ AllParameters
]

{ #category : 'persistence' }
GbsSessionParameters class >> replaceAllParametersFromExportString: aString [
	AllParameters := (self
		prepareImportedParameters: (self parametersFromExportString: aString)
		replacingExisting: true) asOrderedCollection.
	^ AllParameters
]

{ #category : 'validation' }
GbsSessionParameters class >> normalizedParameterName: aString [
	| normalized |
	normalized := aString ifNil: [ '' ] ifNotNil: [ aString asString trimBoth ].
	^ normalized isEmpty ifTrue: [ 'New Config' ] ifFalse: [ normalized ]
]

{ #category : 'validation' }
GbsSessionParameters class >> parameterNameKeyFor: aString [
	^ (self normalizedParameterName: aString) asLowercase
]

{ #category : 'persistence' }
GbsSessionParameters class >> prepareImportedParameters: parameters replacingExisting: replaceExisting [
	| prepared usedNames |
	prepared := parameters asOrderedCollection.
	prepared do: [ :each | each validateForStorage ].
	usedNames := Dictionary new.
	replaceExisting ifFalse: [
		self allParameters do: [ :each |
			usedNames at: (self parameterNameKeyFor: each name) put: true ] ].
	prepared do: [ :each |
		| base candidate index |
		base := self normalizedParameterName: each name.
		candidate := base.
		index := 2.
		[ usedNames includesKey: (self parameterNameKeyFor: candidate) ] whileTrue: [
			candidate := base, ' (', index asString, ')'.
			index := index + 1 ].
		each name: candidate.
		usedNames at: (self parameterNameKeyFor: candidate) put: true ].
	^ prepared asArray
]

{ #category : 'validation' }
GbsSessionParameters class >> hasParameterNamed: aString excluding: excludedParameter [
	| key |
	key := self parameterNameKeyFor: aString.
	^ self allParameters anySatisfy: [ :each |
		each ~~ excludedParameter and: [
			(self parameterNameKeyFor: each name) = key ] ]
]

{ #category : 'validation' }
GbsSessionParameters class >> uniqueNameFor: aString excluding: excludedParameter [
	| base candidate index |
	base := self normalizedParameterName: aString.
	candidate := base.
	index := 2.
	[ self hasParameterNamed: candidate excluding: excludedParameter ] whileTrue: [
		candidate := base, ' (', index asString, ')'.
		index := index + 1 ].
	^ candidate
]

{ #category : 'persistence' }
GbsSessionParameters class >> valueFromDictionary: aDictionary atAny: keyCollection ifAbsent: absentBlock [
	keyCollection do: [ :key |
		(aDictionary includesKey: key) ifTrue: [ ^ aDictionary at: key ].
		(aDictionary includesKey: key asSymbol) ifTrue: [ ^ aDictionary at: key asSymbol ] ].
	^ absentBlock value
]

{ #category : 'security' }
GbsSessionParameters class >> keychainServiceName [
	^ 'GemStone-Pharo-Bridge.sessionParameters'
]

{ #category : 'security' }
GbsSessionParameters class >> keychainStore [
	^ Smalltalk globals
		at: #GbsSessionParametersKeychainStore
		ifAbsent: [ nil ]
]

{ #category : 'security' }
GbsSessionParameters class >> keychainBackend [
	^ Smalltalk globals
		at: #GbsSessionParametersKeychainBackend
		ifAbsent: [
			self keychainStore
				ifNotNil: [ :store | store ]
				ifNil: [ self nativeKeychainBackend ] ]
]

{ #category : 'security' }
GbsSessionParameters class >> nativeKeychainBackend [
	(Smalltalk globals
		at: #GbsSessionParametersPreferNativeKeychain
		ifAbsent: [ false ]) ifFalse: [ ^ nil ].
	^ Smalltalk globals
		at: #GbsNativeMacOSKeychainBackend
		ifAbsent: [
			Smalltalk
				at: #GbsNativeMacOSKeychainBackend
				ifAbsent: [ nil ] ]
]

{ #category : 'security' }
GbsSessionParameters class >> secretFromKeychainBackend: backend account: accountName [
	(backend respondsTo: #secretAt:service:) ifTrue: [
		^ backend secretAt: accountName service: self keychainServiceName ].
	(backend respondsTo: #keychainSecretAt:service:) ifTrue: [
		^ backend keychainSecretAt: accountName service: self keychainServiceName ].
	(backend respondsTo: #at:ifAbsent:) ifTrue: [
		^ backend at: accountName ifAbsent: [ nil ] ].
	self error: 'Unsupported GemStone session Keychain backend.'
]

{ #category : 'security' }
GbsSessionParameters class >> storeSecretInKeychainBackend: backend account: accountName value: secretString [
	(backend respondsTo: #secretAt:put:service:) ifTrue: [
		^ backend
			secretAt: accountName
			put: secretString
			service: self keychainServiceName ].
	(backend respondsTo: #keychainSecretAt:put:service:) ifTrue: [
		^ backend
			keychainSecretAt: accountName
			put: secretString
			service: self keychainServiceName ].
	(backend respondsTo: #at:put:) ifTrue: [
		backend at: accountName put: secretString.
		^ secretString ].
	self error: 'Unsupported GemStone session Keychain backend.'
]

{ #category : 'security' }
GbsSessionParameters class >> deleteSecretInKeychainBackend: backend account: accountName [
	(backend respondsTo: #deleteSecretAt:service:) ifTrue: [
		^ backend deleteSecretAt: accountName service: self keychainServiceName ].
	(backend respondsTo: #deleteKeychainSecretAt:service:) ifTrue: [
		^ backend deleteKeychainSecretAt: accountName service: self keychainServiceName ].
	(backend respondsTo: #removeKey:ifAbsent:) ifTrue: [
		backend removeKey: accountName ifAbsent: [ ].
		^ self ].
	self error: 'Unsupported GemStone session Keychain backend.'
]

{ #category : 'security' }
GbsSessionParameters class >> keychainShellQuote: aString [
	| value |
	value := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	^ String streamContents: [ :stream |
		stream nextPut: $'.
		value do: [ :character |
			character = $'
				ifTrue: [
					stream
						nextPut: $';
						nextPut: $\;
						nextPut: $';
						nextPut: $' ]
				ifFalse: [ stream nextPut: character ] ].
		stream nextPut: $' ]
]

{ #category : 'security' }
GbsSessionParameters class >> keychainCommandStatus: commandString [
	| libc |
	libc := Smalltalk at: #LibC ifAbsent: [ ^ -1 ].
	^ [ libc system: commandString ]
		on: Error
		do: [ -1 ]
]

{ #category : 'security' }
GbsSessionParameters class >> removeTrailingLineEndingsFrom: aString [
	| value |
	value := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	[ value notEmpty and: [ value last = Character lf or: [ value last = Character cr ] ] ]
		whileTrue: [ value := value allButLast ].
	^ value
]

{ #category : 'security' }
GbsSessionParameters class >> keychainSecretAt: accountName [
	| backend |
	backend := self keychainBackend.
	backend ifNotNil: [
		^ self secretFromKeychainBackend: backend account: accountName ].
	^ self shellKeychainSecretAt: accountName
]

{ #category : 'security' }
GbsSessionParameters class >> shellKeychainSecretAt: accountName [
	| file command status secret |
	file := FileLocator temp / ('gbs-keychain-', 1000000 atRandom asString, '.txt').
	command := '/usr/bin/security find-generic-password -w -s ',
		(self keychainShellQuote: self keychainServiceName),
		' -a ',
		(self keychainShellQuote: accountName),
		' > ',
		(self keychainShellQuote: file fullName),
		' 2>/dev/null'.
	[
		status := self keychainCommandStatus: command.
		status = 0 ifFalse: [ ^ nil ].
		secret := file exists
			ifTrue: [ self removeTrailingLineEndingsFrom: file contents ]
			ifFalse: [ nil ].
		^ secret
	] ensure: [ file deleteIfAbsent: [ ] ]
]

{ #category : 'security' }
GbsSessionParameters class >> keychainSecretAt: accountName put: secretString [
	| backend |
	backend := self keychainBackend.
	backend ifNotNil: [
		^ self
			storeSecretInKeychainBackend: backend
			account: accountName
			value: secretString ].
	^ self shellKeychainSecretAt: accountName put: secretString
]

{ #category : 'security' }
GbsSessionParameters class >> shellKeychainSecretAt: accountName put: secretString [
	| file command status |
	file := FileLocator temp / ('gbs-keychain-secret-', 1000000 atRandom asString, '.txt').
	[
		file writeStreamDo: [ :stream | stream nextPutAll: secretString asString ].
		self keychainCommandStatus: 'chmod 600 ', (self keychainShellQuote: file fullName).
		command := '/bin/sh -c ', (self keychainShellQuote: (
			'secret="$(cat ', (self keychainShellQuote: file fullName), ')"; ',
			'exec /usr/bin/security add-generic-password -U -s ',
			(self keychainShellQuote: self keychainServiceName),
			' -a ',
			(self keychainShellQuote: accountName),
			' -w "$secret" >/dev/null 2>&1')).
		status := self keychainCommandStatus: command.
		status = 0 ifFalse: [ self error: 'Could not store GemStone session secret in macOS Keychain.' ].
		^ secretString
	] ensure: [ file deleteIfAbsent: [ ] ]
]

{ #category : 'security' }
GbsSessionParameters class >> deleteKeychainSecretAt: accountName [
	| backend |
	backend := self keychainBackend.
	backend ifNotNil: [
		^ self deleteSecretInKeychainBackend: backend account: accountName ].
	^ self deleteShellKeychainSecretAt: accountName
]

{ #category : 'security' }
GbsSessionParameters class >> deleteShellKeychainSecretAt: accountName [
	| command |
	command := '/usr/bin/security delete-generic-password -s ',
		(self keychainShellQuote: self keychainServiceName),
		' -a ',
		(self keychainShellQuote: accountName),
		' >/dev/null 2>&1'.
	self keychainCommandStatus: command.
	^ self
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
	name := self exportValueFrom: aDictionary atAny: #('name' 'configurationName' 'label') ifAbsent: [ name ].
	gemStoneName := self exportValueFrom: aDictionary atAny: #('gemStoneName' 'stoneName' 'stone') ifAbsent: [ gemStoneName ].
	username := self exportValueFrom: aDictionary atAny: #('username' 'userId' 'user') ifAbsent: [ username ].
	password := self exportValueFrom: aDictionary atAny: #('password' 'gemStonePassword') ifAbsent: [ password ].
	gsRemember := self booleanExportValueFrom: aDictionary atAny: #('gsRemember' 'rememberPassword') default: gsRemember.
	hostUsername := self exportValueFrom: aDictionary atAny: #('hostUsername' 'hostUser') ifAbsent: [ hostUsername ].
	hostPassword := self exportValueFrom: aDictionary atAny: #('hostPassword' 'hostPass') ifAbsent: [ hostPassword ].
	gemService := self exportValueFrom: aDictionary atAny: #('gemService' 'service' 'gemnetobject') ifAbsent: [ gemService ].
	hostRemember := self booleanExportValueFrom: aDictionary atAny: #('hostRemember' 'rememberHostPassword') default: hostRemember.
	netObject := self exportValueFrom: aDictionary atAny: #('netObject' 'netObjectName') ifAbsent: [ netObject ].
	isX509 := self booleanExportValueFrom: aDictionary atAny: #('isX509' 'x509') default: isX509.
	displayUsername := self exportValueFrom: aDictionary atAny: #('displayUsername' 'displayUser') ifAbsent: [ displayUsername ].
	caCert := self exportValueFrom: aDictionary atAny: #('caCert' 'caCertificate') ifAbsent: [ caCert ].
	cert := self exportValueFrom: aDictionary atAny: #('cert' 'certificate') ifAbsent: [ cert ].
	privateKey := self exportValueFrom: aDictionary atAny: #('privateKey' 'key') ifAbsent: [ privateKey ].
	netldiHostOrIp := self exportValueFrom: aDictionary atAny: #('netldiHostOrIp' 'netldiHost' 'netldiHostIp') ifAbsent: [ netldiHostOrIp ].
	netldiNameOrPort := self exportValueFrom: aDictionary atAny: #('netldiNameOrPort' 'netldiName' 'netldiPort' 'netldi') ifAbsent: [ netldiNameOrPort ].
	dirArg := self exportValueFrom: aDictionary atAny: #('dirArg' 'directory') ifAbsent: [ dirArg ].
	extraGemArgs := self exportValueFrom: aDictionary atAny: #('extraGemArgs' 'extraArgs') ifAbsent: [ extraGemArgs ].
	logArg := self exportValueFrom: aDictionary atAny: #('logArg' 'logFile') ifAbsent: [ logArg ].
	materializationBatchSize := self exportValueFrom: aDictionary atAny: #('materializationBatchSize' 'materializationBatchLimit') ifAbsent: [ materializationBatchSize ].
	materializationMaxObjects := self exportValueFrom: aDictionary atAny: #('materializationMaxObjects' 'materializationObjectLimit') ifAbsent: [ materializationMaxObjects ].
	materializationMaxDepth := self exportValueFrom: aDictionary atAny: #('materializationMaxDepth' 'materializationDepthLimit') ifAbsent: [ materializationMaxDepth ].
	materializationMaxBatchBytes := self exportValueFrom: aDictionary atAny: #('materializationMaxBatchBytes' 'materializationBatchByteLimit') ifAbsent: [ materializationMaxBatchBytes ].
	materializationMaxFrontierOops := self exportValueFrom: aDictionary atAny: #('materializationMaxFrontierOops' 'materializationFrontierLimit') ifAbsent: [ materializationMaxFrontierOops ].
	self normalizeConnectionFields.
	^ self
]

{ #category : 'persistence' }
GbsSessionParameters >> booleanExportValueFrom: aDictionary at: aKey default: defaultBoolean [
	^ self booleanExportValueFrom: aDictionary atAny: { aKey } default: defaultBoolean
]

{ #category : 'persistence' }
GbsSessionParameters >> booleanExportValueFrom: aDictionary atAny: keyCollection default: defaultBoolean [
	| value normalized |
	value := self exportValueFrom: aDictionary atAny: keyCollection ifAbsent: [ defaultBoolean ].
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
	| hadPassword hadHostPassword exported |
	hadPassword := password notNil.
	hadHostPassword := hostPassword notNil.
	includeSecrets ifTrue: [ self restoreRememberedSecretsFromKeychain ].
	[
		self normalizeConnectionFields.
		exported := Dictionary new
			at: 'format' put: self class exportFormatIdentifier;
			at: 'schemaVersion' put: 1;
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
			at: 'materializationBatchSize' put: (self materializationExportValueFrom: materializationBatchSize);
			at: 'materializationMaxObjects' put: (self materializationExportValueFrom: materializationMaxObjects);
			at: 'materializationMaxDepth' put: (self materializationExportValueFrom: materializationMaxDepth);
			at: 'materializationMaxBatchBytes' put: (self materializationExportValueFrom: materializationMaxBatchBytes);
			at: 'materializationMaxFrontierOops' put: (self materializationExportValueFrom: materializationMaxFrontierOops);
			yourself.
		^ exported
	] ensure: [
		includeSecrets ifTrue: [
			hadPassword ifFalse: [ password := nil ].
			hadHostPassword ifFalse: [ hostPassword := nil ] ] ]
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
	^ self exportValueFrom: aDictionary atAny: { aKey } ifAbsent: absentBlock
]

{ #category : 'persistence' }
GbsSessionParameters >> exportValueFrom: aDictionary atAny: keyCollection ifAbsent: absentBlock [
	keyCollection do: [ :key |
		(aDictionary includesKey: key) ifTrue: [ ^ aDictionary at: key ].
		(aDictionary includesKey: key asSymbol) ifTrue: [ ^ aDictionary at: key asSymbol ] ].
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

{ #category : 'validation' }
GbsSessionParameters >> gciGemServiceString [
	| netldiHost netldiName |
	self normalizeConnectionFields.
	(self gemService beginsWith: '!') ifTrue: [ ^ self gemService ].
	netldiHost := self netldiHostForGciService.
	netldiName := self netldiNameForGciService.
	(netldiHost isNil or: [ netldiName isNil ]) ifTrue: [ ^ self gemService ].
	^ String streamContents: [ :stream |
		stream
			nextPut: $!;
			nextPut: $@;
			nextPutAll: (self nrsEscapedIdentifier: netldiHost);
			nextPutAll: '#netldi:';
			nextPutAll: (self nrsEscapedIdentifier: netldiName);
			nextPutAll: '#task!';
			nextPutAll: self gemService ]
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

{ #category : 'validation' }
GbsSessionParameters >> configurationValidationErrorMessage [
	^ self validationMessageFrom: self configurationValidationMessages
]

{ #category : 'validation' }
GbsSessionParameters >> configurationValidationMessages [
	| messages |
	self normalizeConnectionFields.
	messages := OrderedCollection new.
	self name isEmpty ifTrue: [
		messages add: 'Configuration name is required.' ].
	messages addAll: self loginValidationMessages.
	self
		validateMaterializationLimit: materializationBatchSize
		label: 'Materialization batch size'
		allowZero: false
		into: messages.
	self
		validateMaterializationLimit: materializationMaxObjects
		label: 'Materialization max objects'
		allowZero: true
		into: messages.
	self
		validateMaterializationLimit: materializationMaxDepth
		label: 'Materialization max depth'
		allowZero: true
		into: messages.
	self
		validateMaterializationLimit: materializationMaxBatchBytes
		label: 'Materialization max batch bytes'
		allowZero: true
		into: messages.
	self
		validateMaterializationLimit: materializationMaxFrontierOops
		label: 'Materialization max frontier OOPs'
		allowZero: true
		into: messages.
	^ messages asArray
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

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationIntegerFrom: aValue ifInvalid: invalidBlock [
	| text |
	aValue ifNil: [ ^ nil ].
	aValue isInteger ifTrue: [ ^ aValue ].
	text := aValue asString trimBoth.
	text isEmpty ifTrue: [ ^ nil ].
	(text allSatisfy: [ :character | character isDigit ]) ifFalse: [
		^ invalidBlock value ].
	^ text asInteger
]

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationExportValueFrom: aValue [
	^ self
		materializationIntegerFrom: aValue
		ifInvalid: [ aValue ]
]

{ #category : 'materialization settings' }
GbsSessionParameters >> validateMaterializationLimit: aValue label: label allowZero: allowZero into: messages [
	| value |
	value := self
		materializationIntegerFrom: aValue
		ifInvalid: [
			messages add: label, ' must be a non-negative integer.'.
			^ self ].
	value ifNil: [ ^ self ].
	(value < 0 or: [ allowZero not and: [ value = 0 ] ]) ifTrue: [
		messages add: label, (allowZero
			ifTrue: [ ' must be a non-negative integer.' ]
			ifFalse: [ ' must be a positive integer.' ]) ]
]

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationBatchSize [
	^ materializationBatchSize
]

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationBatchSize: aValue [
	materializationBatchSize := aValue
]

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationMaxObjects [
	^ materializationMaxObjects
]

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationMaxObjects: aValue [
	materializationMaxObjects := aValue
]

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationMaxDepth [
	^ materializationMaxDepth
]

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationMaxDepth: aValue [
	materializationMaxDepth := aValue
]

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationMaxBatchBytes [
	^ materializationMaxBatchBytes
]

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationMaxBatchBytes: aValue [
	materializationMaxBatchBytes := aValue
]

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationMaxFrontierOops [
	^ materializationMaxFrontierOops
]

{ #category : 'materialization settings' }
GbsSessionParameters >> materializationMaxFrontierOops: aValue [
	materializationMaxFrontierOops := aValue
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
    self restoreRememberedSecretsFromKeychain.
    self validateForLogin.

	interface := GbsServerInterface uniqueInstance.
	interface resetDirtyObjectsInitialization.
	interface apiGciInit.

    serviceString := self gciGemServiceString.
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
GbsSessionParameters >> netldiHostForGciService [
	self normalizeConnectionFields.
	self netldiHostOrIp ifNotNil: [ ^ self netldiHostOrIp ].
	(self netldiNameOrPort notNil and: [ self netldiNameOrPort includes: $# ]) ifTrue: [
		^ (self netldiNameOrPort copyUpTo: $#) ifEmpty: [ nil ] ].
	^ nil
]

{ #category : 'validation' }
GbsSessionParameters >> netldiNameForGciService [
	| hashIndex |
	self normalizeConnectionFields.
	self netldiNameOrPort ifNil: [ ^ nil ].
	hashIndex := self netldiNameOrPort indexOf: $#.
	hashIndex = 0 ifTrue: [ ^ self netldiNameOrPort ].
	^ (self netldiNameOrPort copyFrom: hashIndex + 1 to: self netldiNameOrPort size)
		ifEmpty: [ nil ]
]

{ #category : 'validation' }
GbsSessionParameters >> netldiRoutingString [
	self normalizeConnectionFields.
	self netldiNameOrPort ifNil: [ ^ '' ].
	self netldiHostForGciService ifNotNil: [ ^ '' ].
	self netldiHostOrIp ifNil: [ ^ self netldiNameOrPort ].
	(self netldiNameOrPort includes: $#) ifTrue: [ ^ self netldiNameOrPort ].
	^ self netldiHostOrIp, '#', self netldiNameOrPort
]

{ #category : 'validation' }
GbsSessionParameters >> nrsEscapedIdentifier: aString [
	| source |
	source := self normalizedConnectionString: aString.
	^ String streamContents: [ :stream |
		source do: [ :each |
			((each isSeparator) or: [ '!#$@^' includes: each ]) ifTrue: [
				stream nextPut: $^ ].
			stream nextPut: each ] ]
]

{ #category : 'accessing' }
GbsSessionParameters >> password [ ^ password
]

{ #category : 'accessing' }
GbsSessionParameters >> password: aValue [ password := aValue
]

{ #category : 'security' }
GbsSessionParameters >> keychainAccountForSecretNamed: secretName [
	self normalizeConnectionFields.
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self name;
			nextPut: $|;
			nextPutAll: self gemStoneName;
			nextPut: $|;
			nextPutAll: self username;
			nextPut: $|;
			nextPutAll: secretName asString ]
]

{ #category : 'security' }
GbsSessionParameters >> storeRememberedSecretsInKeychain [
	(gsRemember == true and: [ password notNil and: [ password isEmpty not ] ]) ifTrue: [
		self class
			keychainSecretAt: (self keychainAccountForSecretNamed: #gemStonePassword)
			put: password.
		password := nil ].
	(hostRemember == true and: [ hostPassword notNil and: [ hostPassword isEmpty not ] ]) ifTrue: [
		self class
			keychainSecretAt: (self keychainAccountForSecretNamed: #hostPassword)
			put: hostPassword.
		hostPassword := nil ].
	^ self
]

{ #category : 'security' }
GbsSessionParameters >> restoreRememberedSecretsFromKeychain [
	| restored |
	(gsRemember == true and: [ password isNil or: [ password isEmpty ] ]) ifTrue: [
		restored := self class keychainSecretAt: (self keychainAccountForSecretNamed: #gemStonePassword).
		restored ifNotNil: [ password := restored ] ].
	(hostRemember == true and: [ hostPassword isNil or: [ hostPassword isEmpty ] ]) ifTrue: [
		restored := self class keychainSecretAt: (self keychainAccountForSecretNamed: #hostPassword).
		restored ifNotNil: [ hostPassword := restored ] ].
	^ self
]

{ #category : 'security' }
GbsSessionParameters >> deleteRememberedSecretsFromKeychain [
	self class deleteKeychainSecretAt: (self keychainAccountForSecretNamed: #gemStonePassword).
	self class deleteKeychainSecretAt: (self keychainAccountForSecretNamed: #hostPassword).
	^ self
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
GbsSessionParameters >> validateForStorage [
	self configurationValidationErrorMessage ifNotNil: [ :message |
		self error: 'Invalid GemStone session configuration:', String cr, message ].
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
