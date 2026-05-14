Class {
	#name : 'GbsRemoteScriptBuilderCoreTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testCollectionLiteralBuildsDynamicArray [
	| script |
	script := GbsRemoteScriptBuilder literalFor: { 1. 'two'. #three }.

	self assert: script equals: '{ 1. ''two''. (''three'' asSymbol) }'
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testObjectForOopBuildsRemoteReference [
	self
		assert: (GbsRemoteScriptBuilder objectForOop: 9001)
		equals: '(Object _objectForOop: 9001)'
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandBindsLiteralArguments [
	| command |
	command := GbsRemoteCommand
		blockBody: 'arg1 at: arg2'
		literalArguments: { 'UserGlobals'. #foo }.

	self
		assert: command script
		equals: '[ :arg1 :arg2 | arg1 at: arg2 ] value: ''UserGlobals'' value: (''foo'' asSymbol)'
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandBindsNamedArguments [
	| command |
	command := GbsRemoteCommand
		blockBody: 'root ifNil: [ 0 ] ifNotNil: [ root size ]'
		argumentNames: #('root')
		argumentScripts: #('UserGlobals').

	self
		assert: command script
		equals: '[ :root | root ifNil: [ 0 ] ifNotNil: [ root size ] ] value: UserGlobals'
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandBindsNamedLiteralArguments [
	| command bindings |
	bindings := Dictionary new.
	bindings at: 'name' put: 'O''Reilly'.
	command := GbsRemoteCommand
		blockBody: 'name size'
		literalBindings: bindings.

	self
		assert: command script
		equals: '[ :name | name size ] value: ''O''''Reilly'''
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandBindsNamedLiteralAndOopArguments [
	| command literals oops |
	literals := Dictionary new.
	literals at: 'name' put: 'O''Reilly'.
	oops := Dictionary new.
	oops at: 'object' put: 9001.
	command := GbsRemoteCommand
		blockBody: 'object at: name'
		literalBindings: literals
		oopBindings: oops.

	self
		assert: command script
		equals: '[ :object :name | object at: name ] value: (Object _objectForOop: 9001) value: ''O''''Reilly'''
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandBuildsTypedAssignments [
	| command literals oops |
	literals := Dictionary new.
	literals at: 'name' put: 'O''Reilly'.
	oops := Dictionary new.
	oops at: 'object' put: 9001.
	command := GbsRemoteCommand
		blockBody: 'object at: name'
		literalAssignments: literals
		oopAssignments: oops.

	self assert: (command script includesSubstring: 'object := (Object _objectForOop: 9001)').
	self assert: (command script includesSubstring: 'name := ''O''''Reilly''').
	self assert: (command script includesSubstring: 'object at: name')
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandBindsOopArguments [
	| command |
	command := GbsRemoteCommand
		blockBody: 'arg1 size'
		oopArguments: { 9001 }.

	self
		assert: command script
		equals: '[ :arg1 | arg1 size ] value: (Object _objectForOop: 9001)'
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandBindsNamedOopArguments [
	| command bindings |
	bindings := Dictionary new.
	bindings at: 'object' put: 9001.
	command := GbsRemoteCommand
		blockBody: 'object class name'
		oopBindings: bindings.

	self
		assert: command script
		equals: '[ :object | object class name ] value: (Object _objectForOop: 9001)'
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandBuildsObjectSend [
	| command |
	command := GbsRemoteCommand
		forObjectOop: 9001
		send: #at:
		arguments: #(1).

	self assert: (command script includesSubstring: 'object perform: selector withArguments: arguments').
	self assert: (command script includesSubstring: 'value: (Object _objectForOop: 9001)').
	self assert: (command script includesSubstring: '''at:'' asSymbol').
	self assert: (command script includesSubstring: '{ 1 }')
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandBuildsRepositoryRootCommand [
	| command |
	command := GbsRemoteCommand
		forRepositoryRoot: #GbsBridgeRoot
		path: #(tickets active)
		aliasKeys: #(LegacyRoot)
		ensure: true
		body: 'container size'
		literalBindings: Dictionary new.

	self assert: (command script includesSubstring: 'UserGlobals at: rootKey put: root').
	self assert: (command script includesSubstring: 'ifAbsentPut: [ Dictionary new ]').
	self assert: (command script includesSubstring: 'container size').
	self assert: (command script includesSubstring: '''GbsBridgeRoot'' asSymbol').
	self assert: (command script includesSubstring: '''tickets'' asSymbol')
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandBuildsSymbolDictionaryCommand [
	| command |
	command := GbsRemoteCommand
		forSymbolDictionaryNamed: #UserGlobals
		body: 'root ifNil: [ #() ] ifNotNil: [ root keys asArray ]'
		literalBindings: Dictionary new.

	self assert: (command script includesSubstring: 'resolveSymbol: dictionaryName').
	self assert: (command script includesSubstring: 'root ifNil: [ #() ]').
	self assert: (command script includesSubstring: '''UserGlobals'' asSymbol')
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandExecutesNoArgumentBlock [
	| command |
	command := GbsRemoteCommand
		blockBody: '1 + 1'
		literalBindings: Dictionary new
		oopBindings: Dictionary new.

	self assert: command script equals: '[ 1 + 1 ] value'
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testRemoteCommandRejectsUnsafeArgumentNames [
	self
		should: [
			GbsRemoteCommand
				blockBody: 'arg1'
				argumentNames: #('arg1; ObjectMemory quit')
				argumentScripts: #('1') ]
		raise: Error
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testSessionRemoteCommandApisDelegateFetchExecution [
	| session |
	session := CoreMockGbsSession new.
	session stubs
		at: #evaluate put: [ self fail: 'Remote commands should not use raw evaluate:.' ];
		at: #executeScriptAndFetchObject put: [ :script |
			self assert: script equals: '2 + 2'.
			#fetched ];
		at: #executeAndFetchContext put: [ :script :contextOop |
			self assert: script equals: '3 + 3'.
			self assert: contextOop equals: 20.
			#contextFetched ].

	self
		assert: (session fetchRemoteCommand: (GbsRemoteCommand staticExpression: '2 + 2'))
		equals: #fetched.
	self
		assert: (session fetchRemoteCommand: (GbsRemoteCommand staticExpression: '3 + 3') context: 20)
		equals: #contextFetched
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testSendBuildsKeywordMessageWithQuotedArguments [
	| script |
	script := GbsRemoteScriptBuilder
		send: #at:put:
		to: 'UserGlobals'
		arguments: { #invoiceTotal. 'O''Reilly' }.

	self
		assert: script
		equals: 'UserGlobals at: (''invoiceTotal'' asSymbol) put: ''O''''Reilly'''
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testStringLiteralEscapesQuotes [
	self
		assert: (GbsRemoteScriptBuilder literalFor: 'O''Reilly')
		equals: '''O''''Reilly'''
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testSymbolLiteralAvoidsIdentifierAssumptions [
	self
		assert: (GbsRemoteScriptBuilder literalFor: #'not a valid identifier')
		equals: '(''not a valid identifier'' asSymbol)'
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testUnaryAndBinarySendBuilders [
	self
		assert: (GbsRemoteScriptBuilder send: #size to: 'UserGlobals' arguments: #())
		equals: 'UserGlobals size'.
	self
		assert: (GbsRemoteScriptBuilder send: #+ to: '1' arguments: #(2))
		equals: '1 + 2'
]

{ #category : 'tests' }
GbsRemoteScriptBuilderCoreTest >> testWrongArgumentCountFails [
	self
		should: [
			GbsRemoteScriptBuilder
				send: #at:put:
				to: 'UserGlobals'
				arguments: #(key) ]
		raise: Error
]
