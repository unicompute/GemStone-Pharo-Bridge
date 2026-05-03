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
