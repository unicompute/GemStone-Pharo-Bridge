Class {
	#name : 'GbsSmalltalkCoreFacadeTest',
	#superclass : 'TestCase',
	#instVars : [
		'mockSession'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GbsSmalltalkCoreFacadeTest >> setUp [
	super setUp.
	mockSession := MockGbsSession new
]

{ #category : 'tests' }
GbsSmalltalkCoreFacadeTest >> testBridgeRootAssociationsScriptUsesNeutralKey [
	| scripts |
	scripts := OrderedCollection new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		scripts add: script.
		^ #() ].

	mockSession bridgeRoot associations.

	self assert: scripts size equals: 1.
	self assert: (scripts first includesSubstring: '#GbsBridgeRoot')
]

{ #category : 'tests' }
GbsSmalltalkCoreFacadeTest >> testBridgeRootMutationScriptsUseNeutralKey [
	| scripts bridgeRoot |
	scripts := OrderedCollection new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		scripts add: script.
		(script includesSubstring: 'removeKey: key ifAbsent: [ ]')
			ifTrue: [ ^ 9 ].
		^ 9 ].
	bridgeRoot := mockSession bridgeRoot.

	self assert: (bridgeRoot at: #Alpha put: 9) equals: 9.
	self assert: (bridgeRoot removeKey: #Alpha ifAbsent: [ self fail ]) equals: 9.
	self assert: scripts size equals: 2.
	self assert: (scripts allSatisfy: [ :each | each includesSubstring: '#GbsBridgeRoot' ])
]

{ #category : 'tests' }
GbsSmalltalkCoreFacadeTest >> testRemoteNamespaceMirrorBuildsGenericConstantMirrors [
	| namespace alpha beta |
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'mockNamespace'
		symbolListIndex: nil
		metadata: nil.
	namespace
		instVarNamed: 'constantEntries'
		put: {
			{ 'Alpha'. 1001. 'Dictionary'. nil. 'Alpha'. 'Object::Alpha' }.
			{ 'Beta'. nil. nil. nil. nil. nil } }.
	alpha := namespace constantMirrorAt: 'Alpha'.
	beta := namespace constantMirrorAt: 'Beta'.

	self assert: namespace constantNames equals: #('Alpha' 'Beta').
	self assert: alpha hasValue.
	self assert: alpha targetDisplayName equals: 'Object::Alpha'.
	self deny: beta hasValue
]

{ #category : 'tests' }
GbsSmalltalkCoreFacadeTest >> testRemoteNamespaceMirrorCachesConstantEntriesAfterFirstFetch [
	| namespace fetchCount |
	fetchCount := 0.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		fetchCount := fetchCount + 1.
		self assert: (script includesSubstring: 'ns := mockNamespace').
		^ {
			{ 'Alpha'. 1001. 'Dictionary'. nil. 'Alpha'. 'Object::Alpha' }.
			{ 'Beta'. nil. nil. nil. nil. nil } } ].
	namespace := GbsRemoteNamespaceMirror
		on: mockSession
		expression: 'mockNamespace'
		symbolListIndex: nil
		metadata: nil.

	self assert: namespace constantNames equals: #('Alpha' 'Beta').
	self assert: (namespace constantMirrorAt: 'Alpha') targetDisplayName equals: 'Object::Alpha'.
	self assert: fetchCount equals: 1
]

{ #category : 'tests' }
GbsSmalltalkCoreFacadeTest >> testRepositoryRootFacadeUsesBridgeRootPrimaryKey [
	| root |
	root := mockSession repository root.

	self assert: root rootKey equals: #GbsBridgeRoot.
	self assert: root path equals: #()
]

{ #category : 'tests' }
GbsSmalltalkCoreFacadeTest >> testSmalltalkFacadeExposesBridgeRootAndStandardDictionaries [
	| facade |
	facade := mockSession smalltalk.

	self assert: facade class equals: GbsSmalltalkFacade.
	self assert: mockSession bridgeRoot class equals: GbsBridgeRootFacade.
	self assert: mockSession bridgeRoot rootKey equals: #GbsBridgeRoot.
	self assert: facade bridgeRoot class equals: GbsBridgeRootFacade.
	self assert: facade bridgeRoot rootKey equals: #GbsBridgeRoot.
	self assert: facade globals class equals: GbsSymbolDictionaryFacade.
	self assert: facade published class equals: GbsSymbolDictionaryFacade.
	self assert: facade userGlobals class equals: GbsSymbolDictionaryFacade.
	self deny: (facade respondsTo: #sessionMethods)
]

{ #category : 'tests' }
GbsSmalltalkCoreFacadeTest >> testSymbolDictionaryFacadeReadsAndMutatesValues [
	| facade |
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'items add: (key -> value)')
			ifTrue: [ ^ { #Alpha -> 1. #Beta -> 2 } ].
		(script includesSubstring: 'items add: key')
			ifTrue: [ ^ #(#Alpha #Beta) ].
		(script includesSubstring: 'root ifNil: [ false ] ifNotNil:')
			ifTrue: [ ^ true ].
		(script includesSubstring: 'root ifNil: [ 0 ] ifNotNil: [ root size ]')
			ifTrue: [ ^ 2 ].
		(script includesSubstring: 'objectNamed: key ifAbsent: [ nil ]')
			ifTrue: [ ^ 'value' ].
		(script includesSubstring: 'root at: key put: value. value')
			ifTrue: [ ^ 9 ].
		(script includesSubstring: 'root removeKey: key ifAbsent: [ ]')
			ifTrue: [ ^ 9 ].
		self fail ].

	facade := GbsSymbolDictionaryFacade on: mockSession name: #UserGlobals.

	self assert: facade name equals: 'UserGlobals'.
	self assert: facade size equals: 2.
	self assert: facade isEmpty not.
	self assert: facade keys equals: #(#Alpha #Beta).
	self assert: facade associations asArray equals: { #Alpha -> 1. #Beta -> 2 }.
	self assert: (facade at: #Alpha ifAbsent: [ self fail ]) equals: 'value'.
	self assert: (facade includesKey: #Alpha).
	self assert: (facade at: #Alpha put: 9) equals: 9.
	self assert: (facade removeKey: #Alpha ifAbsent: [ self fail ]) equals: 9
]
