Class {
	#name : 'GbsRemoteExecutionDispatcherTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbsRemoteExecutionDispatcherTest >> testFetchCommandBodyUsesTypedRemoteCommandBindings [
	| session literals oops capturedScript capturedContext result |
	session := MockGbsSession new.
	session stubs at: #executeAndFetchContext put: [ :script :contextOop |
		capturedScript := script.
		capturedContext := contextOop.
		#ok ].
	literals := Dictionary new.
	literals at: 'name' put: 'O''Reilly'.
	oops := Dictionary new.
	oops at: 'object' put: 9001.

	result := GbsRemoteExecutionDispatcher
		fetchCommandBody: 'object at: name'
		literalBindings: literals
		oopBindings: oops
		in: session
		context: 20.

	self assert: result equals: #ok.
	self assert: capturedContext equals: 20.
	self
		assert: capturedScript
		equals: '[ :object :name | object at: name ] value: (Object _objectForOop: 9001) value: ''O''''Reilly'''
]

{ #category : 'tests' }
GbsRemoteExecutionDispatcherTest >> testCompatibilityCommandScriptRejectsUnsafeNames [
	| literals |
	literals := Dictionary new.
	literals at: 'bad name' put: 1.

	self
		should: [
			GbsRemoteExecutionDispatcher
				compatibilityCommandScriptForBody: 'bad name'
				literalBindings: literals
				oopBindings: Dictionary new ]
		raise: Error
]
