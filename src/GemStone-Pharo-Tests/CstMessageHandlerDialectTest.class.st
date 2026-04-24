Class {
	#name : 'CstMessageHandlerDialectTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests-vw' }
CstMessageHandlerDialectTest >> testVwConfirmOrCancelMapping [
	| handler |
	handler := GbxTestMessageHandlerVw new.

	handler enqueueChooseAnswer: 1.
	self assert: (handler confirmOrCancel: 'question') equals: true.

	handler enqueueChooseAnswer: 2.
	self assert: (handler confirmOrCancel: 'question') equals: false.

	handler enqueueChooseAnswer: 0.
	self assert: (handler confirmOrCancel: 'question') isNil
]

{ #category : 'tests-vw' }
CstMessageHandlerDialectTest >> testVwRequestFileNameOldRetriesWhenMissing [
	| handler result |
	handler := GbxTestMessageHandlerVw new.
	handler existingPaths: #('/tmp/existing.txt').
	handler enqueueRequestAnswer: '/tmp/missing.txt'.
	handler enqueueRequestAnswer: '/tmp/existing.txt'.
	handler enqueueConfirmAnswer: true.

	result := handler
		requestFileName: 'Pick file'
		default: ''
		version: #old
		ifFail: [ #failed ].

	self assert: result equals: '/tmp/existing.txt'.
	self assert: (handler lastConfirmPrompt includesSubstring: '/tmp/missing.txt')
]

{ #category : 'tests-va' }
CstMessageHandlerDialectTest >> testVaConfirmOrCancelMapping [
	| handler |
	handler := GbxTestMessageHandlerVa new.

	handler enqueueChooseAnswer: 1.
	self assert: (handler confirmOrCancel: 'question') equals: true.

	handler enqueueChooseAnswer: 2.
	self assert: (handler confirmOrCancel: 'question') equals: false.

	handler enqueueChooseAnswer: 0.
	self assert: (handler confirmOrCancel: 'question') isNil
]

{ #category : 'tests-va' }
CstMessageHandlerDialectTest >> testVaRequestFileNameNewFailsWhenExistingAndNotConfirmed [
	| handler result |
	handler := GbxTestMessageHandlerVa new.
	handler existingPaths: #('/tmp/existing.txt').
	handler enqueueRequestAnswer: '/tmp/existing.txt'.
	handler enqueueConfirmAnswer: false.

	result := handler
		requestFileName: 'Pick file'
		default: ''
		version: #new
		ifFail: [ #failed ].

	self assert: result equals: #failed.
	self assert: (handler lastConfirmPrompt includesSubstring: 'exists - use anyway?')
]
