Class {
	#name : 'GbsSessionParametersTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbsSessionParametersTest >> testInterpretErrorMessageTreats4051AsInvalidCredentialsEvenWhenRawMessageIsEmpty [
	| params message |
	params := GbsSessionParameters new.
	params gemStoneName: 'gs64stone'.

	message := params interpretErrorMessage: '' errorNumber: 4051.

	self assert: (message includesSubstring: 'GemStone login failed').
	self assert: (message includesSubstring: 'invalid or expired')
]

{ #category : 'tests' }
GbsSessionParametersTest >> testInterpretErrorMessageTreatsInvalidPasswordTextAsCredentialsFailure [
	| params raw message |
	params := GbsSessionParameters new.
	raw := 'Login failed: Invalid password'.

	message := params interpretErrorMessage: raw errorNumber: 0.

	self assert: (message includesSubstring: 'GemStone login failed').
	self assert: (message includesSubstring: 'Invalid password')
]

{ #category : 'tests' }
GbsSessionParametersTest >> testConnectionSummaryIncludesNormalizedNetworkFields [
	| params summary |
	params := GbsSessionParameters new.
	params
		username: ' DataCurator ';
		gemStoneName: ' gs64stone ';
		gemService: ' gemnetobject ';
		netldiHostOrIp: ' gemstone.example.com ';
		netldiNameOrPort: ' 50377 '.

	summary := params connectionSummary.

	self assert: summary equals: 'DataCurator@gs64stone via gemnetobject netldiHost=gemstone.example.com netldi=50377'
]

{ #category : 'tests' }
GbsSessionParametersTest >> testApplyExportDictionaryAcceptsSymbolKeysAndIgnoresSessionId [
	| params exported |
	params := GbsSessionParameters new.
	params
		username: 'ExistingUser';
		password: 'existing-secret';
		sessionId: 12345.
	exported := Dictionary new
		at: #username put: ' ImportedUser ';
		at: #hostRemember put: 'true';
		at: #sessionId put: 67890;
		yourself.

	params applyExportDictionary: exported.

	self assert: params username equals: 'ImportedUser'.
	self assert: params password equals: 'existing-secret'.
	self assert: params hostRemember.
	self assert: params sessionId equals: 12345
]

{ #category : 'tests' }
GbsSessionParametersTest >> testExportAllParametersCanRoundTripWithoutRuntimeSessionIds [
	| previous p1 p2 exported imported |
	previous := GbsSessionParameters allParameters copy.
	[
		GbsSessionParameters allParameters removeAll.
		p1 := GbsSessionParameters new.
		p1
			name: 'A';
			username: 'DataCurator';
			password: 'secret-a';
			sessionId: 101.
		p2 := GbsSessionParameters new.
		p2
			name: 'B';
			username: 'GcUser';
			hostPassword: 'secret-b';
			sessionId: 102.
		GbsSessionParameters
			addParameter: p1;
			addParameter: p2.

		exported := GbsSessionParameters exportAllParameters.
		imported := GbsSessionParameters replaceAllParametersFromExportDictionaries: exported.

		self assert: imported size equals: 2.
		self assert: GbsSessionParameters allParameters size equals: 2.
		self assert: imported first name equals: 'A'.
		self assert: imported first password isNil.
		self assert: imported first sessionId isNil.
		self assert: imported second hostPassword isNil.
		self assert: imported second sessionId isNil
	] ensure: [
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsSessionParametersTest >> testExportAllParametersStringRoundTripsAndRedactsSecrets [
	| previous params exported imported exportObject |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	previous := GbsSessionParameters allParameters copy.
	[
		GbsSessionParameters allParameters removeAll.
		params := GbsSessionParameters new.
		params
			name: 'Exported';
			username: 'DataCurator';
			password: 'secret';
			hostPassword: 'host-secret';
			sessionId: 9001.
		GbsSessionParameters addParameter: params.

			exported := GbsSessionParameters exportAllParametersString.
			exportObject := STON fromString: exported.
			imported := GbsSessionParameters parametersFromExportString: exported.

			self assert: (exportObject at: 'format') equals: GbsSessionParameters exportBundleFormatIdentifier.
			self assert: (exportObject at: 'schemaVersion') equals: 2.
			self deny: (exportObject at: 'includesSecrets').
			self assert: imported size equals: 1.
			self assert: imported first name equals: 'Exported'.
		self assert: imported first username equals: 'DataCurator'.
		self assert: imported first password isNil.
		self assert: imported first hostPassword isNil.
		self assert: imported first sessionId isNil
	] ensure: [
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsSessionParametersTest >> testExportDictionaryIncludingSecretsIncludesPasswords [
	| params exported |
	params := GbsSessionParameters new.
	params
		password: 'gs-secret';
		hostPassword: 'host-secret'.

	exported := params exportDictionaryIncludingSecrets: true.

	self assert: (exported at: 'password') equals: 'gs-secret'.
	self assert: (exported at: 'hostPassword') equals: 'host-secret'
]

{ #category : 'tests' }
GbsSessionParametersTest >> testRememberedSecretsCanRoundTripThroughKeychainStore [
	| previousStore store params |
	previousStore := Smalltalk globals
		at: #GbsSessionParametersKeychainStore
		ifAbsent: [ nil ].
	store := Dictionary new.
	[
		Smalltalk globals at: #GbsSessionParametersKeychainStore put: store.
		params := GbsSessionParameters new.
		params
			name: 'Production';
			gemStoneName: 'gs64stone';
			username: 'DataCurator';
			gsRemember: true;
			password: 'gs-secret';
			hostUsername: 'host-user';
			hostRemember: true;
			hostPassword: 'host-secret'.

		params storeRememberedSecretsInKeychain.

		self assert: params password isNil.
		self assert: params hostPassword isNil.
		self assert: store size equals: 2.

		params restoreRememberedSecretsFromKeychain.

		self assert: params password equals: 'gs-secret'.
		self assert: params hostPassword equals: 'host-secret'
	] ensure: [
		previousStore
			ifNil: [ Smalltalk globals removeKey: #GbsSessionParametersKeychainStore ifAbsent: [ ] ]
			ifNotNil: [ Smalltalk globals at: #GbsSessionParametersKeychainStore put: previousStore ] ]
]

{ #category : 'tests' }
GbsSessionParametersTest >> testRememberedSecretsCanUseKeychainBackendProtocol [
	| previousBackend backend params account |
	previousBackend := Smalltalk globals
		at: #GbsSessionParametersKeychainBackend
		ifAbsent: [ nil ].
	backend := CoreFakeKeychainBackend new.
	[
		Smalltalk globals at: #GbsSessionParametersKeychainBackend put: backend.
		params := GbsSessionParameters new.
		params
			name: 'Production';
			gemStoneName: 'gs64stone';
			username: 'DataCurator';
			gsRemember: true;
			password: 'gs-secret'.
		account := params keychainAccountForSecretNamed: #gemStonePassword.

		params storeRememberedSecretsInKeychain.
		self assert: params password isNil.
		self assert: (backend secretAt: account service: GbsSessionParameters keychainServiceName) equals: 'gs-secret'.
		self assert: (backend services includes: GbsSessionParameters keychainServiceName).

		params restoreRememberedSecretsFromKeychain.
		self assert: params password equals: 'gs-secret'.

		params deleteRememberedSecretsFromKeychain.
		self assert: (backend secretAt: account service: GbsSessionParameters keychainServiceName) isNil
	] ensure: [
		previousBackend
			ifNil: [ Smalltalk globals removeKey: #GbsSessionParametersKeychainBackend ifAbsent: [ ] ]
			ifNotNil: [ Smalltalk globals at: #GbsSessionParametersKeychainBackend put: previousBackend ] ]
]

{ #category : 'tests' }
GbsSessionParametersTest >> testKeychainShellQuoteHandlesSingleQuotes [
	| expected |
	expected := String streamContents: [ :stream |
		stream
			nextPut: $';
			nextPut: $a;
			nextPut: $';
			nextPut: $\;
			nextPut: $';
			nextPut: $';
			nextPut: $b;
			nextPut: $' ].

	self
		assert: (GbsSessionParameters keychainShellQuote: 'a''b')
		equals: expected
]

{ #category : 'tests' }
GbsSessionParametersTest >> testSecretExportRestoresRememberedSecretsFromKeychainStore [
	| previousStore store params exported |
	previousStore := Smalltalk globals
		at: #GbsSessionParametersKeychainStore
		ifAbsent: [ nil ].
	store := Dictionary new.
	[
		Smalltalk globals at: #GbsSessionParametersKeychainStore put: store.
		params := GbsSessionParameters new.
		params
			name: 'Production';
			gemStoneName: 'gs64stone';
			username: 'DataCurator';
			gsRemember: true;
			password: 'gs-secret'.
		params storeRememberedSecretsInKeychain.

		exported := params exportDictionaryIncludingSecrets: true.

		self assert: (exported at: 'password') equals: 'gs-secret'.
		self assert: params password isNil
	] ensure: [
		previousStore
			ifNil: [ Smalltalk globals removeKey: #GbsSessionParametersKeychainStore ifAbsent: [ ] ]
			ifNotNil: [ Smalltalk globals at: #GbsSessionParametersKeychainStore put: previousStore ] ]
]

{ #category : 'tests' }
GbsSessionParametersTest >> testExportDictionaryNormalizesFieldsAndOmitsSessionId [
	| params exported |
	params := GbsSessionParameters new.
	params
		name: ' Production ';
		gemStoneName: ' gs64stone ';
		username: ' DataCurator ';
		gemService: ' ';
		netldiHostOrIp: ' gemstone.example.com ';
		netldiNameOrPort: ' 50377 ';
		sessionId: 9876.

	exported := params exportDictionary.

	self assert: (exported at: 'format') equals: GbsSessionParameters exportFormatIdentifier.
	self assert: (exported at: 'name') equals: 'Production'.
	self assert: (exported at: 'gemStoneName') equals: 'gs64stone'.
	self assert: (exported at: 'username') equals: 'DataCurator'.
	self assert: (exported at: 'gemService') equals: 'gemnetobject'.
	self assert: (exported at: 'netldiHostOrIp') equals: 'gemstone.example.com'.
	self assert: (exported at: 'netldiNameOrPort') equals: '50377'.
	self deny: (exported includesKey: 'sessionId')
]

{ #category : 'tests' }
GbsSessionParametersTest >> testExportDictionaryIncludesMaterializationSafetySettings [
	| params exported imported |
	params := GbsSessionParameters new.
	params
		name: 'Production';
		username: 'DataCurator';
		materializationBatchSize: '250';
		materializationMaxObjects: '1000';
		materializationMaxDepth: '12';
		materializationMaxBatchBytes: '4096';
		materializationMaxFrontierOops: '300'.

	exported := params exportDictionary.
	imported := GbsSessionParameters fromExportDictionary: exported.

	self assert: (exported at: 'materializationBatchSize') equals: 250.
	self assert: (exported at: 'materializationMaxObjects') equals: 1000.
	self assert: (exported at: 'materializationMaxDepth') equals: 12.
	self assert: (exported at: 'materializationMaxBatchBytes') equals: 4096.
	self assert: (exported at: 'materializationMaxFrontierOops') equals: 300.
	self assert: imported materializationBatchSize equals: 250.
	self assert: imported materializationMaxObjects equals: 1000.
	self assert: imported materializationMaxDepth equals: 12.
	self assert: imported materializationMaxBatchBytes equals: 4096.
	self assert: imported materializationMaxFrontierOops equals: 300
]

{ #category : 'tests' }
GbsSessionParametersTest >> testConfigurationValidationRejectsInvalidMaterializationSettings [
	| params message |
	params := GbsSessionParameters new.
	params
		username: 'DataCurator';
		materializationBatchSize: '0';
		materializationMaxObjects: 'abc'.

	message := params configurationValidationErrorMessage.

	self assert: (message includesSubstring: 'Materialization batch size must be a positive integer.').
	self assert: (message includesSubstring: 'Materialization max objects must be a non-negative integer.')
]

{ #category : 'tests' }
GbsSessionParametersTest >> testExportDictionaryRedactsSecretsByDefault [
	| params exported |
	params := GbsSessionParameters new.
	params
		password: 'gs-secret';
		hostPassword: 'host-secret'.

	exported := params exportDictionary.

	self assert: (exported at: 'password') isNil.
	self assert: (exported at: 'hostPassword') isNil
	]

{ #category : 'tests' }
GbsSessionParametersTest >> testImportLegacyDictionaryAliases [
	| legacy params |
	legacy := Dictionary new
		at: 'configurationName' put: ' Legacy ';
		at: 'stoneName' put: ' gs64stone ';
		at: 'userId' put: ' DataCurator ';
		at: 'rememberPassword' put: 'true';
		at: 'hostUser' put: ' host-user ';
		at: 'hostPass' put: 'host-secret';
		at: 'rememberHostPassword' put: 'yes';
		at: 'service' put: ' gemnetobject ';
		at: 'netldiHost' put: ' gemstone.example.com ';
		at: 'netldiPort' put: ' 50377 ';
		yourself.

	params := GbsSessionParameters fromExportDictionary: legacy.

	self assert: params name equals: 'Legacy'.
	self assert: params gemStoneName equals: 'gs64stone'.
	self assert: params username equals: 'DataCurator'.
	self assert: params gsRemember.
	self assert: params hostUsername equals: 'host-user'.
	self assert: params hostPassword equals: 'host-secret'.
	self assert: params hostRemember.
	self assert: params netldiRoutingString equals: 'gemstone.example.com#50377'
]

{ #category : 'tests' }
GbsSessionParametersTest >> testImportParametersFromBadStonRaisesError [
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].

	self
		should: [ GbsSessionParameters parametersFromExportString: '{ this is not valid STON' ]
		raise: Error
]

{ #category : 'tests' }
GbsSessionParametersTest >> testImportParametersFromLegacyBundleWithoutMetadata [
	| bundle exported imported |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	bundle := Dictionary new
		at: 'parameters' put: {
			Dictionary new
				at: 'configurationName' put: ' Legacy ';
				at: 'stoneName' put: ' gs64stone ';
				at: 'userId' put: ' DataCurator ';
				yourself };
		yourself.
	exported := STON toString: bundle.

	imported := GbsSessionParameters parametersFromExportString: exported.

	self assert: imported size equals: 1.
	self assert: imported first name equals: 'Legacy'.
	self assert: imported first gemStoneName equals: 'gs64stone'.
	self assert: imported first username equals: 'DataCurator'
]

{ #category : 'tests' }
GbsSessionParametersTest >> testImportParametersFromLegacyBundleRenamesDuplicateNames [
	| previous bundle exported imported |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	previous := GbsSessionParameters allParameters copy.
	[
		GbsSessionParameters allParameters removeAll.
		bundle := Dictionary new
			at: 'parameters' put: {
				Dictionary new
					at: 'configurationName' put: 'Legacy';
					at: 'stoneName' put: 'gs64stone';
					at: 'userId' put: 'DataCurator';
					yourself.
				Dictionary new
					at: 'configurationName' put: ' Legacy ';
					at: 'stoneName' put: 'gs64stone';
					at: 'userId' put: 'GcUser';
					yourself };
			yourself.
		exported := STON toString: bundle.

		imported := GbsSessionParameters importParametersFromExportString: exported.

		self assert: imported size equals: 2.
		self assert: imported first name equals: 'Legacy'.
		self assert: imported second name equals: 'Legacy (2)'.
		self assert: GbsSessionParameters allParameters second name equals: 'Legacy (2)'
	] ensure: [
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsSessionParametersTest >> testImportParametersFromBundleRejectsMissingRequiredFields [
	| bundle exported |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	bundle := Dictionary new
		at: 'parameters' put: {
			Dictionary new
				at: 'name' put: 'Incomplete';
				at: 'gemStoneName' put: '';
				at: 'username' put: '';
				yourself };
		yourself.
	exported := STON toString: bundle.

	self
		should: [ GbsSessionParameters importParametersFromExportString: exported ]
		raise: Error
		withExceptionDo: [ :ex |
			self assert: (ex messageText includesSubstring: 'GemStone stone name is required.').
			self assert: (ex messageText includesSubstring: 'GemStone username is required.') ]
]

{ #category : 'tests' }
GbsSessionParametersTest >> testImportParametersFromExportStringAppendsImportedConfigurations [
	| previous params exported imported |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	previous := GbsSessionParameters allParameters copy.
	[
		GbsSessionParameters allParameters removeAll.
		params := GbsSessionParameters new.
		params
			name: 'Imported';
			username: 'GcUser'.
		exported := params exportString.

		imported := GbsSessionParameters importParametersFromExportString: exported.

		self assert: imported size equals: 1.
		self assert: GbsSessionParameters allParameters size equals: 1.
		self assert: GbsSessionParameters allParameters first name equals: 'Imported'.
		self assert: GbsSessionParameters allParameters first username equals: 'GcUser'
	] ensure: [
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
	]

{ #category : 'tests' }
GbsSessionParametersTest >> testImportParametersFromExportStringRenamesDuplicates [
	| previous existing importedParam exported imported |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	previous := GbsSessionParameters allParameters copy.
	[
		GbsSessionParameters allParameters removeAll.
		existing := GbsSessionParameters new.
		existing
			name: 'Production';
			username: 'DataCurator'.
		GbsSessionParameters addParameter: existing.
		importedParam := GbsSessionParameters new.
		importedParam
			name: 'Production';
			username: 'GcUser'.
		exported := importedParam exportString.

		imported := GbsSessionParameters importParametersFromExportString: exported.

		self assert: imported size equals: 1.
		self assert: imported first name equals: 'Production (2)'.
		self assert: GbsSessionParameters allParameters second name equals: 'Production (2)'
	] ensure: [
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsSessionParametersTest >> testImportParametersFromExportStringRejectsInvalidConfiguration [
	| invalid exported |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	invalid := Dictionary new
		at: 'name' put: 'Missing User';
		at: 'gemStoneName' put: 'gs64stone';
		at: 'username' put: '';
		yourself.
	exported := STON toString: invalid.

	self
		should: [ GbsSessionParameters importParametersFromExportString: exported ]
		raise: Error
		withExceptionDo: [ :ex |
			self assert: (ex messageText includesSubstring: 'GemStone username is required.') ]
]

{ #category : 'tests' }
GbsSessionParametersTest >> testImportFromExportDictionaryRestoresConnectionFieldsAndNormalizes [
	| exported params |
	exported := Dictionary new
		at: 'name' put: ' Production ';
		at: 'gemStoneName' put: ' gs64stone ';
		at: 'username' put: ' DataCurator ';
		at: 'password' put: 'gs-secret';
		at: 'gsRemember' put: 'true';
		at: 'hostUsername' put: ' host-user ';
		at: 'hostPassword' put: 'host-secret';
		at: 'hostRemember' put: 1;
		at: 'gemService' put: ' ';
		at: 'netObject' put: ' ';
		at: 'isX509' put: 'yes';
		at: 'displayUsername' put: 'Display';
		at: 'caCert' put: '/certs/ca.pem';
		at: 'cert' put: '/certs/client.pem';
		at: 'privateKey' put: '/certs/client.key';
		at: 'netldiHostOrIp' put: ' gemstone.example.com ';
		at: 'netldiNameOrPort' put: ' 50377 ';
		at: 'dirArg' put: '/tmp/gem';
		at: 'extraGemArgs' put: '-T';
		at: 'logArg' put: '/tmp/gem.log';
		at: 'sessionId' put: 456;
		yourself.

	params := GbsSessionParameters fromExportDictionary: exported.

	self assert: params name equals: 'Production'.
	self assert: params gemStoneName equals: 'gs64stone'.
	self assert: params username equals: 'DataCurator'.
	self assert: params password equals: 'gs-secret'.
	self assert: params gsRemember.
	self assert: params hostUsername equals: 'host-user'.
	self assert: params hostPassword equals: 'host-secret'.
	self assert: params hostRemember.
	self assert: params gemService equals: 'gemnetobject'.
	self assert: params netObject isNil.
	self assert: params isX509.
	self assert: params displayUsername equals: 'Display'.
	self assert: params caCert equals: '/certs/ca.pem'.
	self assert: params cert equals: '/certs/client.pem'.
	self assert: params privateKey equals: '/certs/client.key'.
	self assert: params netldiRoutingString equals: 'gemstone.example.com#50377'.
	self assert: params dirArg equals: '/tmp/gem'.
	self assert: params extraGemArgs equals: '-T'.
	self assert: params logArg equals: '/tmp/gem.log'.
	self assert: params sessionId isNil
]

{ #category : 'tests' }
GbsSessionParametersTest >> testNormalizeConnectionFieldsDefaultsServiceAndClearsBlankOptionalFields [
	| params |
	params := GbsSessionParameters new.
	params
		name: ' Production ';
		gemStoneName: ' gs64stone ';
		username: ' DataCurator ';
		gemService: ' ';
		hostUsername: ' ';
		netObject: ' ';
		netldiHostOrIp: ' ';
		netldiNameOrPort: ' gs64ldi '.

	params normalizeConnectionFields.

	self assert: params name equals: 'Production'.
	self assert: params gemStoneName equals: 'gs64stone'.
	self assert: params username equals: 'DataCurator'.
	self assert: params gemService equals: 'gemnetobject'.
	self assert: params hostUsername isNil.
	self assert: params netObject isNil.
	self assert: params netldiHostOrIp isNil.
	self assert: params netldiNameOrPort equals: 'gs64ldi'
]

{ #category : 'tests' }
GbsSessionParametersTest >> testNetldiRoutingStringCombinesHostAndNameForGci [
	| params |
	params := GbsSessionParameters new.
	params
		netldiHostOrIp: ' gemstone.example.com ';
		netldiNameOrPort: ' 50377 '.

	self assert: params netldiRoutingString equals: 'gemstone.example.com#50377'
]

{ #category : 'tests' }
GbsSessionParametersTest >> testNetldiRoutingStringUsesNameWhenHostIsAbsent [
	| params |
	params := GbsSessionParameters new.
	params netldiNameOrPort: ' gs64ldi '.

	self assert: params netldiRoutingString equals: 'gs64ldi'
]

{ #category : 'tests' }
GbsSessionParametersTest >> testValidateForLoginRejectsMissingStoneAndUsername [
	| params message |
	params := GbsSessionParameters new.
	params
		gemStoneName: ' ';
		username: ' '.

	message := params loginValidationErrorMessage.

	self assert: (message includesSubstring: 'GemStone stone name is required.').
	self assert: (message includesSubstring: 'GemStone username is required.')
]

{ #category : 'tests' }
GbsSessionParametersTest >> testValidateForLoginRejectsNetldiHostWithoutName [
	| params message |
	params := GbsSessionParameters new.
	params
		username: 'DataCurator';
		netldiHostOrIp: 'gemstone.example.com';
		netldiNameOrPort: ' '.

	message := params loginValidationErrorMessage.

	self assert: (message includesSubstring: 'NetLDI host/IP requires a NetLDI name or port.')
]
