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
