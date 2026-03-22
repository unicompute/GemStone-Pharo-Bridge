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
GbxContextCompatibilityTest >> blockMethodHomeMethod [
	| outerMethod |
	outerMethod := thisContext method.
	^ {
		[ thisContext method homeMethod ] value.
		outerMethod
	}
]

{ #category : 'helpers' }
GbxContextCompatibilityTest >> methodContextHomeReceiver [
	^ thisContext homeReceiver
]

{ #category : 'helpers' }
GbxContextCompatibilityTest >> methodContextMethodClass [
	^ thisContext mclass
]

{ #category : 'helpers' }
GbxContextCompatibilityTest >> methodHomeMethod [
	^ {
		thisContext method homeMethod.
		thisContext method
	}
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
GbxContextCompatibilityTest >> testHomeMethodAnswersOuterMethodForCompiledBlock [
	| pair |
	pair := self blockMethodHomeMethod.
	self assert: pair first == pair second
]

{ #category : 'tests' }
GbxContextCompatibilityTest >> testHomeMethodAnswersSelfForCompiledMethod [
	| pair |
	pair := self methodHomeMethod.
	self assert: pair first == pair second
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
	| blockPair methodPair originalCompiledBlockHomeMethodProtocol originalCompiledBlockHomeMethodSource originalCompiledCodeHomeMethodProtocol originalCompiledCodeHomeMethodSource originalMclassSource originalMclassProtocol originalHomeReceiverSource originalHomeReceiverProtocol |
	originalCompiledCodeHomeMethodSource := (CompiledCode >> #homeMethod) sourceCode.
	originalCompiledCodeHomeMethodProtocol := (CompiledCode >> #homeMethod) protocol.
	originalCompiledBlockHomeMethodSource := (CompiledBlock >> #homeMethod) sourceCode.
	originalCompiledBlockHomeMethodProtocol := (CompiledBlock >> #homeMethod) protocol.
	originalHomeReceiverSource := (Context >> #homeReceiver) sourceCode.
	originalHomeReceiverProtocol := (Context >> #homeReceiver) protocol.
	originalMclassSource := (Context >> #mclass) sourceCode.
	originalMclassProtocol := (Context >> #mclass) protocol.

	[
		CompiledBlock removeSelector: #homeMethod.
		CompiledCode removeSelector: #homeMethod.
		Context removeSelector: #homeReceiver.
		Context removeSelector: #mclass.
		self deny: (CompiledBlock includesSelector: #homeMethod).
		self deny: (CompiledCode includesSelector: #homeMethod).
		self deny: (Context includesSelector: #homeReceiver).
		self deny: (Context includesSelector: #mclass).

		GbsPharoBootstrap activateCompatibilityInCurrentImage.

		self assert: (CompiledBlock includesSelector: #homeMethod).
		self assert: (CompiledCode includesSelector: #homeMethod).
		self assert: (Context includesSelector: #homeReceiver).
		self assert: (Context includesSelector: #mclass).
		methodPair := self methodHomeMethod.
		blockPair := self blockMethodHomeMethod.
		self assert: methodPair first == methodPair second.
		self assert: blockPair first == blockPair second.
		self assert: self methodContextHomeReceiver == self.
		self assert: self methodContextMethodClass equals: self class
	] ensure: [
		(CompiledBlock includesSelector: #homeMethod)
			ifTrue: [ CompiledBlock removeSelector: #homeMethod ].
		(CompiledCode includesSelector: #homeMethod)
			ifTrue: [ CompiledCode removeSelector: #homeMethod ].
		(Context includesSelector: #homeReceiver)
			ifTrue: [ Context removeSelector: #homeReceiver ].
		(Context includesSelector: #mclass)
			ifTrue: [ Context removeSelector: #mclass ].
		CompiledCode compile: originalCompiledCodeHomeMethodSource classified: originalCompiledCodeHomeMethodProtocol.
		CompiledBlock compile: originalCompiledBlockHomeMethodSource classified: originalCompiledBlockHomeMethodProtocol.
		Context compile: originalHomeReceiverSource classified: originalHomeReceiverProtocol.
		Context compile: originalMclassSource classified: originalMclassProtocol
	]
]
