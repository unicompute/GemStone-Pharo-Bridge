Class {
	#name : 'GbsSessionCompatibilityTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbsSessionCompatibilityTest >> testExecuteAndFetchDelegatesToUnsynchronizedEvaluate [
	| session |
	session := GbsExecuteAndFetchCompatSession basicNew.
	session nextValue: '42'.

	self assert: (session executeAndFetch: '1 + 1') equals: '42'.
	self assert: session lastSource equals: '1 + 1'.
	self assert: session lastContext isNil
]

{ #category : 'tests' }
GbsSessionCompatibilityTest >> testExecuteAndFetchWithContextDelegatesToUnsynchronizedEvaluate [
	| session |
	session := GbsExecuteAndFetchCompatSession basicNew.
	session nextValue: 'ok'.

	self assert: (session executeAndFetch: 'self printString' context: 20) equals: 'ok'.
	self assert: session lastSource equals: 'self printString'.
	self assert: session lastContext equals: 20
]
