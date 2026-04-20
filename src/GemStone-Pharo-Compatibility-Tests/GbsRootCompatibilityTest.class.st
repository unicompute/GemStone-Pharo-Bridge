Class {
	#name : 'GbsRootCompatibilityTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Compatibility-Tests',
	#package : 'GemStone-Pharo-Compatibility-Tests'
}

{ #category : 'private' }
GbsRootCompatibilityTest >> resumeDeprecationsDuring: aBlock [
	^ [ aBlock value ]
		on: Deprecation
		do: [ :ex | ex resume ]
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testMaglevPersistentRootAliasUsesBridgeRootFacade [
	| mockSession maglev |
	mockSession := MockGbsSession new.
	maglev := mockSession maglev.

	self assert: (self resumeDeprecationsDuring: [ maglev persistentRoot ]) class equals: GbsBridgeRootFacade.
	self assert: (self resumeDeprecationsDuring: [ maglev persistentRoot ]) rootKey equals: #GbsBridgeRoot
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testFacadeRootAliasesUseBridgeRootFacade [
	| mockSession smalltalk maglev |
	mockSession := MockGbsSession new.
	smalltalk := mockSession smalltalk.
	maglev := mockSession maglev.

	self assert: (self resumeDeprecationsDuring: [ smalltalk root ]) class equals: GbsBridgeRootFacade.
	self assert: (self resumeDeprecationsDuring: [ smalltalk root ]) rootKey equals: #GbsBridgeRoot.
	self assert: (self resumeDeprecationsDuring: [ maglev root ]) class equals: GbsBridgeRootFacade.
	self assert: (self resumeDeprecationsDuring: [ maglev root ]) rootKey equals: #GbsBridgeRoot
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testGBSMPersistentRootAliasUsesBridgeRootFacade [
	| mockSession previousSession |
	mockSession := MockGbsSession new.
	previousSession := GBSM currentSession.

	[
		GBSM currentSession: mockSession.
		self assert: (self resumeDeprecationsDuring: [ GBSM persistentRoot ]) class equals: GbsBridgeRootFacade.
		self assert: (self resumeDeprecationsDuring: [ GBSM persistentRoot ]) rootKey equals: #GbsBridgeRoot
	] ensure: [
		GBSM currentSession: previousSession ]
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testGBSMRootAliasesDelegateToRepositoryRoot [
	| mockSession previousSession |
	mockSession := MockGbsSession new.
	previousSession := GBSM currentSession.

	[
		GBSM currentSession: mockSession.
		self assert: (self resumeDeprecationsDuring: [ GBSM root ]) class equals: GbsRepositoryRootFacade.
		self assert: (self resumeDeprecationsDuring: [ GBSM root ]) rootKey equals: #GbsBridgeRoot
	] ensure: [
		GBSM currentSession: previousSession ]
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testGBSMRootAtAliasesDelegateToRepositoryRoot [
	| mockSession previousSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'container at: key put: value')
			ifTrue: [ 'vip' ]
			ifFalse: [
		(script includesSubstring: '#ticket')
			ifTrue: [ 'vip' ]
			ifFalse: [ nil ] ] ].
	previousSession := GBSM currentSession.

	[
		GBSM currentSession: mockSession.
		self assert: (self resumeDeprecationsDuring: [ GBSM rootAt: #ticket ]) equals: 'vip'.
		self assert: (self resumeDeprecationsDuring: [ GBSM rootAt: #missing ifAbsent: [ #fallback ] ]) equals: #fallback.
		self assert: (self resumeDeprecationsDuring: [ GBSM rootAt: #ticket put: 'vip' ]) equals: 'vip'
	] ensure: [
		GBSM currentSession: previousSession ]
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testBridgeRootScriptStillIncludesLegacyAliasKey [
	| mockSession scripts |
	mockSession := MockGbsSession new.
	scripts := OrderedCollection new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		scripts add: script.
		^ #() ].

	mockSession bridgeRoot associations.

	self assert: scripts size equals: 1.
	self assert: (scripts first includesSubstring: '#GbsBridgeRoot').
	self assert: (scripts first includesSubstring: '#GbsPersistentRoot')
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testPersistentRootCompatibilityFacadeKeepsLegacyKey [
	| mockSession |
	mockSession := MockGbsSession new.

	self assert: (GbsPersistentRootFacade on: mockSession) class equals: GbsPersistentRootFacade.
	self assert: (GbsPersistentRootFacade on: mockSession) rootKey equals: #GbsPersistentRoot
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testSessionCommitAliasDelegatesToCommitTransaction [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession instVarNamed: 'isLoggedIn' put: true.
	mockSession stubs at: #gciCommit put: 1.

	self assert: (self resumeDeprecationsDuring: [ mockSession commit ])
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testSessionAndSmalltalkPersistentRootAliasesUseBridgeRootFacade [
	| mockSession facade |
	mockSession := MockGbsSession new.
	facade := mockSession smalltalk.

	self assert: (self resumeDeprecationsDuring: [ mockSession persistentRoot ]) class equals: GbsBridgeRootFacade.
	self assert: (self resumeDeprecationsDuring: [ mockSession persistentRoot ]) rootKey equals: #GbsBridgeRoot.
	self assert: (self resumeDeprecationsDuring: [ facade persistentRoot ]) class equals: GbsBridgeRootFacade.
	self assert: (self resumeDeprecationsDuring: [ facade persistentRoot ]) rootKey equals: #GbsBridgeRoot
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testSessionRootAliasesDelegateToRepositoryRoot [
	| mockSession |
	mockSession := MockGbsSession new.

	self assert: (self resumeDeprecationsDuring: [ mockSession root ]) class equals: GbsRepositoryRootFacade.
	self assert: (self resumeDeprecationsDuring: [ mockSession root ]) rootKey equals: #GbsBridgeRoot
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testSessionRootAtAliasesDelegateToRepositoryRoot [
	| mockSession |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'container at: key put: value')
			ifTrue: [ 'vip' ]
			ifFalse: [
		(script includesSubstring: '#ticket')
			ifTrue: [ 'vip' ]
			ifFalse: [ nil ] ] ].

	self assert: (self resumeDeprecationsDuring: [ mockSession rootAt: #ticket ]) equals: 'vip'.
	self assert: (self resumeDeprecationsDuring: [ mockSession rootAt: #missing ifAbsent: [ #fallback ] ]) equals: #fallback.
	self assert: (self resumeDeprecationsDuring: [ mockSession rootAt: #ticket put: 'vip' ]) equals: 'vip'
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testLegacyRepositoryRootLockQueriesReturnDefaultsForMissingNamespace [
	| mockSession root |
	mockSession := MockGbsSession new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: '#GbsPersistentRoot').
		self assert: (script includesSubstring: '#GbsBridgeRoot').
		0 ].
	root := GbsRepositoryRootFacade
		on: mockSession
		rootKey: #GbsPersistentRoot
		path: #(#tickets).

	self assert: root lockKind equals: #none.
	self assert: root lockOwners equals: #().
	self assert: root removeLock == root
]

{ #category : 'tests' }
GbsRootCompatibilityTest >> testLegacyRepositoryRootWithWriteLockDoEnsuresNamespaceBeforeLocking [
	| mockSession root scripts result seenFacade seenProxy |
	mockSession := MockGbsSession new.
	scripts := OrderedCollection new.
	mockSession stubs at: #executeScriptAndReturnOop put: [ :script |
		self assert: (script includesSubstring: '#GbsPersistentRoot').
		self assert: (script includesSubstring: '#GbsBridgeRoot').
		self assert: (script includesSubstring: 'ifAbsentPut: [ Dictionary new ]').
		self assert: (script includesSubstring: '#tickets').
		5001 ].
	mockSession stubs at: #execute put: [ :script |
		scripts add: script.
		true ].
	root := GbsRepositoryRootFacade
		on: mockSession
		rootKey: #GbsPersistentRoot
		path: #(#tickets).

	result := root withWriteLockDo: [ :facade :proxy |
		seenFacade := facade.
		seenProxy := proxy.
		#done ].

	self assert: result equals: #done.
	self assert: seenFacade == root.
	self assert: seenProxy oop equals: 5001.
	self assert: scripts size equals: 2.
	self assert: (scripts first includesSubstring: 'System perform: #writeLock:').
	self assert: (scripts second includesSubstring: 'System perform: #removeLock:')
]
