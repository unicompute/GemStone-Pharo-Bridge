Class {
	#name : 'GbsWorkspaceMagLevToolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousSession'
	],
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'running' }
GbsWorkspaceMagLevToolsTest >> setUp [
	super setUp.
	previousSession := GbsSessionParameters currentSession
]

{ #category : 'running' }
GbsWorkspaceMagLevToolsTest >> tearDown [
	GbsSessionParameters currentSession: previousSession.
	super tearDown
]

{ #category : 'tests' }
GbsWorkspaceMagLevToolsTest >> testBrowseRubyLoadPathReportUsesRuntimeReport [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseRubyLoadPathReport.
	self assert: (workspace lastInfoMessage includesSubstring: '$LOAD_PATH').
	self assert: (workspace lastInfoMessage includesSubstring: '/opt/demo/lib')
]

{ #category : 'tests' }
GbsWorkspaceMagLevToolsTest >> testBrowseRubyLoadedFeaturesReportUsesRuntimeReport [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default transientLoadedFeatures: 1'
			ifTrue: [ ^ #('json' 'set') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseRubyLoadedFeaturesReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'Loaded Features').
	self assert: (workspace lastInfoMessage includesSubstring: 'json')
]

{ #category : 'tests' }
GbsWorkspaceMagLevToolsTest >> testBrowseRubyPersistentLoadedFeaturesReportUsesRuntimeReport [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default persistentLoadedFeatures: 1'
			ifTrue: [ ^ #('bigdecimal') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseRubyPersistentLoadedFeaturesReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'Persistent Loaded Features').
	self assert: (workspace lastInfoMessage includesSubstring: 'bigdecimal')
]

{ #category : 'tests' }
GbsWorkspaceMagLevToolsTest >> testBrowseTopLevelAutoloadRegistrationsReportUsesRuntimeReport [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:')
			ifTrue: [ ^ { #('DemoConst' 'demo/file' false nil) } ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseTopLevelAutoloadRegistrationsReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'Autoload Registrations').
	self assert: (workspace lastInfoMessage includesSubstring: 'DemoConst -> demo/file [Pending]')
]

{ #category : 'tests' }
GbsWorkspaceMagLevToolsTest >> testBrowseMaglevFinalizerRegistryReportUsesDiagnosticsFacade [
	| workspace mockSession |
	workspace := CoreTestableGbsWorkspace new.
	mockSession := CoreMockGbsSession new.
	mockSession stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19') ifTrue: [
			^ GbsProxy oop: 9001 session: mockSession ].
		(script includesSubstring: 'findReferencesInMemory') ifTrue: [
			^ { GbsProxy oop: 9101 session: mockSession } ].
		self fail ].
	GbsSessionParameters currentSession: mockSession.

	self assert: workspace browseMaglevFinalizerRegistryReport.
	self assert: (workspace lastInfoMessage includesSubstring: 'MagLev Finalizer Registry oop=9001 Referencers').
	self assert: (workspace lastInfoMessage includesSubstring: 'oop=9101')
]
