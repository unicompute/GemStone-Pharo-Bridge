Class {
	#name : 'GbsStackDumperTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbsStackDumperTest >> testClassOfUsesPortableLookup [
	self assert: (GbsStackDumper classOf: 1) equals: SmallInteger.
	self assert: (GbsStackDumper classOf: Object new) equals: Object
]

{ #category : 'tests' }
GbsStackDumperTest >> testIfUnderstoodSendEvaluatesFallbackForUnknownSelector [
	| fallbackUsed |
	fallbackUsed := false.

	self
		assert: (GbsStackDumper
			ifUnderstoodSend: #selectorThatDoesNotExist
			to: Object new
			arguments: #()
			else: [
				fallbackUsed := true.
				#fallback ]) equals: #fallback.
	self assert: fallbackUsed
]

{ #category : 'tests' }
GbsStackDumperTest >> testIfUnderstoodSendPerformsKnownSelector [
	self
		assert: (GbsStackDumper
			ifUnderstoodSend: #yourself
			to: 42
			arguments: #()
			else: [ self fail ]) equals: 42
]
