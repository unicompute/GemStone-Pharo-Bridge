Class {
	#name : 'GbxContextCompatibilityTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'helpers' }
GbxContextCompatibilityTest >> blockContextMethodClass [
	^ [ thisContext mclass ] value
]

{ #category : 'helpers' }
GbxContextCompatibilityTest >> blockContextHomeReceiver [
	^ [ thisContext homeReceiver ] value
]

{ #category : 'helpers' }
GbxContextCompatibilityTest >> methodContextHomeReceiver [
	^ thisContext homeReceiver
]

{ #category : 'helpers' }
GbxContextCompatibilityTest >> methodContextMethodClass [
	^ thisContext mclass
]

{ #category : 'tests' }
GbxContextCompatibilityTest >> testHomeReceiverAnswersReceiverForBlockContext [
	self assert: self blockContextHomeReceiver == self
]

{ #category : 'tests' }
GbxContextCompatibilityTest >> testHomeReceiverAnswersReceiverForMethodContext [
	self assert: self methodContextHomeReceiver == self
]

{ #category : 'tests' }
GbxContextCompatibilityTest >> testMclassAnswersOwningClassForBlockContext [
	self assert: self blockContextMethodClass equals: self class
]

{ #category : 'tests' }
GbxContextCompatibilityTest >> testMclassAnswersOwningClassForMethodContext [
	self assert: self methodContextMethodClass equals: self class
]

{ #category : 'tests' }
GbxContextCompatibilityTest >> testActivateCompatibilityReinstallsContextCompatibilitySelectors [
	| originalMclassSource originalMclassProtocol originalHomeReceiverSource originalHomeReceiverProtocol |
	originalHomeReceiverSource := (Context >> #homeReceiver) sourceCode.
	originalHomeReceiverProtocol := (Context >> #homeReceiver) protocol.
	originalMclassSource := (Context >> #mclass) sourceCode.
	originalMclassProtocol := (Context >> #mclass) protocol.

	[
		Context removeSelector: #homeReceiver.
		Context removeSelector: #mclass.
		self deny: (Context includesSelector: #homeReceiver).
		self deny: (Context includesSelector: #mclass).

		GbsPharoBootstrap activateCompatibilityInCurrentImage.

		self assert: (Context includesSelector: #homeReceiver).
		self assert: (Context includesSelector: #mclass).
		self assert: self methodContextHomeReceiver == self.
		self assert: self methodContextMethodClass equals: self class
	] ensure: [
		(Context includesSelector: #homeReceiver)
			ifTrue: [ Context removeSelector: #homeReceiver ].
		(Context includesSelector: #mclass)
			ifTrue: [ Context removeSelector: #mclass ].
		Context compile: originalHomeReceiverSource classified: originalHomeReceiverProtocol.
		Context compile: originalMclassSource classified: originalMclassProtocol
	]
]
