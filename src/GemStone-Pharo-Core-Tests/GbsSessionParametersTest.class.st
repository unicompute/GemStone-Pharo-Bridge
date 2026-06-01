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
