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
GbxContextCompatibilityTest >> methodContextMethodClass [
	^ thisContext mclass
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
GbxContextCompatibilityTest >> testActivateCompatibilityReinstallsContextMclass [
	| originalSource originalProtocol |
	originalSource := (Context >> #mclass) sourceCode.
	originalProtocol := (Context >> #mclass) protocol.

	[
		Context removeSelector: #mclass.
		self deny: (Context includesSelector: #mclass).

		GbsPharoBootstrap activateCompatibilityInCurrentImage.

		self assert: (Context includesSelector: #mclass).
		self assert: self methodContextMethodClass equals: self class
	] ensure: [
		(Context includesSelector: #mclass)
			ifTrue: [ Context removeSelector: #mclass ].
		Context compile: originalSource classified: originalProtocol
	]
]
