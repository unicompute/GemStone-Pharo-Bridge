Class {
	#name : 'GbsSessionManagerMagLevTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousCurrentSession',
		'previousParameterCurrentSession'
	],
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'running' }
GbsSessionManagerMagLevTest >> setUp [
	super setUp.
	previousCurrentSession := GBSM currentSession.
	previousParameterCurrentSession := GbsSessionParameters currentSession.
	GBSM currentSession: nil.
	GbsSessionParameters currentSession: nil
]

{ #category : 'running' }
GbsSessionManagerMagLevTest >> tearDown [
	GBSM currentSession: previousCurrentSession.
	GbsSessionParameters currentSession: previousParameterCurrentSession.
	super tearDown
]

{ #category : 'tests' }
GbsSessionManagerMagLevTest >> testGBSMMaglevAndObjectLogDelegatesToCurrentSession [
	| mockSession |
	mockSession := CoreMockGbsSession new.
	GBSM currentSession: mockSession.

	self assert: GBSM smalltalk class equals: GbsSmalltalkFacade.
	self assert: GBSM smalltalk session == mockSession.
	self assert: GBSM maglev class equals: GbsMaglevFacade.
	self assert: GBSM maglev session == mockSession.
	self assert: GBSM objectLog class equals: GbsObjectLogFacade.
	self assert: GBSM objectLog session == mockSession
]

{ #category : 'tests' }
GbsSessionManagerMagLevTest >> testGBSMNamespaceAndRubyRuntimeDelegatesToCurrentSession [
	| mockSession namespaces topLevel exactNamespace namedNamespace loadPath loadedFeatures |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'System myUserProfile symbolList. entries := OrderedCollection new')
			ifTrue: [ ^ #(#(1 5001 'UserGlobals' nil 'SymbolDictionary' nil)) ].
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		(script includesSubstring: 'findTokens: ''::''')
			ifTrue: [ ^ #(8101 'Accounting::Invoice' 'Accounting::Invoice' 'RubyNameSpace' 'Class') ].
		(script includesSubstring: '[:value | value] value:')
			ifTrue: [ ^ #(8001 'Accounting' 'Accounting' 'RubyNameSpace' 'Module') ].
		(script includesSubstring: 'Object nameSpace: 1')
			ifTrue: [ ^ #(7001 nil nil 'RubyNameSpace' 'Object') ].
		self fail ].
	GBSM currentSession: mockSession.

	namespaces := GBSM namespaceMirrors.
	topLevel := GBSM topLevelNamespaceMirror.
	exactNamespace := GBSM namespaceMirrorForObject: (GbsProxy oop: 7101 session: mockSession).
	namedNamespace := GBSM namespaceMirrorForFullName: 'Accounting::Invoice'.
	loadPath := GBSM rubyLoadPath.
	loadedFeatures := GBSM rubyLoadedFeatures.

	self assert: namespaces size equals: 1.
	self assert: namespaces first displayName equals: 'UserGlobals'.
	self assert: topLevel moduleName equals: 'Object'.
	self assert: exactNamespace displayName equals: 'Accounting'.
	self assert: namedNamespace displayName equals: 'Accounting::Invoice'.
	self assert: loadPath equals: #('lib').
	self assert: loadedFeatures equals: #('foo.rb')
]

{ #category : 'tests' }
GbsSessionManagerMagLevTest >> testGBSMRuntimeAndObjectSpaceFacadeDelegatesToCurrentSession [
	| mockSession runtime diagnostics |
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('lib') ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #('foo.rb') ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #('persisted.rb') ].
		(script includesSubstring: 'System sessionStateAt: key')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		self fail ].
	GBSM currentSession: mockSession.

	runtime := GBSM rubyRuntime.
	diagnostics := GBSM objectSpaceDiagnostics.

	self assert: runtime loadPath equals: #('lib').
	self assert: runtime loadedFeatures equals: #('foo.rb').
	self assert: runtime persistentLoadedFeatures equals: #('persisted.rb').
	self assert: runtime reportSections size equals: 4.
	self assert: diagnostics report class equals: GbsObjectSpaceDiagnosticsReport.
	self assert: (diagnostics reportText includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1')
]

{ #category : 'tests' }
GbsSessionManagerMagLevTest >> testGBSMSessionMethodsDelegatesToCurrentSession [
	| mockSession result |
	mockSession := CoreMockGbsSession new.
	GBSM currentSession: mockSession.

	result := GBSM sessionMethods.

	self assert: result class equals: GbsSymbolDictionaryFacade.
	self assert: result name equals: 'SessionMethods'
]
