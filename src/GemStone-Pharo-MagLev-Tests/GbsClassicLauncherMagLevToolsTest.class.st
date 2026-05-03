Class {
	#name : 'GbsClassicLauncherMagLevToolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'launcher',
		'previousCurrentSession'
	],
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'running' }
GbsClassicLauncherMagLevToolsTest >> setUp [
	super setUp.
	previousCurrentSession := GbsSessionParameters currentSession.
	CoreTestableGbsClassicLauncher resetClassHarness.
	launcher := CoreTestableGbsClassicLauncher new
]

{ #category : 'running' }
GbsClassicLauncherMagLevToolsTest >> tearDown [
	GbsSessionParameters currentSession: previousCurrentSession.
	super tearDown
]

{ #category : 'tests' }
GbsClassicLauncherMagLevToolsTest >> testBrowseRubyLoadPathReportUsesSelectedSession [
	| session |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #('/opt/demo/lib' '/opt/demo/app') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	launcher forcedSession: session.

	self assert: launcher browseRubyLoadPathReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: '$LOAD_PATH').
	self assert: (launcher infoMessages first includesSubstring: '/opt/demo/lib').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherMagLevToolsTest >> testBrowseRubyLoadedFeaturesReportUsesSelectedSession [
	| session |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default transientLoadedFeatures: 1'
			ifTrue: [ ^ #('json' 'set') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	launcher forcedSession: session.

	self assert: launcher browseRubyLoadedFeaturesReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Loaded Features').
	self assert: (launcher infoMessages first includesSubstring: 'json').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherMagLevToolsTest >> testBrowseRubyPersistentLoadedFeaturesReportUsesSelectedSession [
	| session |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyContext default persistentLoadedFeatures: 1'
			ifTrue: [ ^ #('bigdecimal') ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	launcher forcedSession: session.

	self assert: launcher browseRubyPersistentLoadedFeaturesReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Persistent Loaded Features').
	self assert: (launcher infoMessages first includesSubstring: 'bigdecimal').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherMagLevToolsTest >> testBrowseTopLevelAutoloadRegistrationsReportUsesSelectedSession [
	| session |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		script = 'RubyFile loadPath: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default transientLoadedFeatures: 1' ifTrue: [ ^ #() ].
		script = 'RubyContext default persistentLoadedFeatures: 1' ifTrue: [ ^ #() ].
		(script includesSubstring: 'rubyAutoloadAssociationAtOrNil:env:')
			ifTrue: [ ^ { #('DemoConst' 'demo/file' false nil) } ].
		(script includesSubstring: 'key := 19') ifTrue: [ ^ nil ].
		self fail ].
	launcher forcedSession: session.

	self assert: launcher browseTopLevelAutoloadRegistrationsReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Autoload Registrations').
	self assert: (launcher infoMessages first includesSubstring: 'DemoConst -> demo/file [Pending]').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherMagLevToolsTest >> testBrowseMaglevFinalizerRegistryReportUsesSelectedSessionState [
	| session |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ GbsProxy oop: 9191 session: session ].
		(script includesSubstring: 'findReferencesInMemory')
			ifTrue: [ ^ { GbsProxy oop: 9292 session: session } ].
		self fail ].
	launcher forcedSession: session.

	self assert: launcher browseMaglevFinalizerRegistryReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'MagLev Finalizer Registry oop=9191 Referencers').
	self assert: (launcher infoMessages first includesSubstring: 'oop=9292').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherMagLevToolsTest >> testInspectMaglevFinalizerRegistryUsesSelectedSession [
	| session registry |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	registry := GbsProxy oop: 9191 session: session.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ registry ].
		self fail ].
	launcher forcedSession: session.

	self assert: launcher inspectMaglevFinalizerRegistry.
	self assert: launcher lastInspectedOop equals: 9191.
	self assert: launcher lastInspectedSession == session.
	self assert: GbsSessionParameters currentSession == session
]
