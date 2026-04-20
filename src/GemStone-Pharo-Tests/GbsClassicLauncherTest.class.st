Class {
	#name : 'GbsClassicLauncherTest',
	#superclass : 'TestCase',
	#instVars : [
		'launcher',
		'previousCurrentSession'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsClassicLauncherTest >> setUp [
	super setUp.
	previousCurrentSession := GbsSessionParameters currentSession.
	GbsTestableClassicLauncher resetClassHarness.
	launcher := GbsTestableClassicLauncher new
]

{ #category : 'running' }
GbsClassicLauncherTest >> tearDown [
	GbsSessionParameters currentSession: previousCurrentSession.
	super tearDown
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testOpenSystemBrowserUsesSessionForBrowsing [
	| fakeSession |
	fakeSession := Object new.
	launcher forcedSession: fakeSession.

	self assert: launcher openSystemBrowser.
	self assert: launcher openBrowserCalls equals: 1.
	self assert: launcher lastOpenedSession == fakeSession.
	self assert: launcher lastOpenedDictionary isNil.
	self assert: GbsSessionParameters currentSession == fakeSession
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testOpenSystemBrowserWithoutSessionShowsMessage [
	launcher forcedSession: nil.

	self deny: launcher openSystemBrowser.
	self assert: launcher openBrowserCalls equals: 0.
	self assert: launcher infoMessages size equals: 1.
	self assert: launcher infoMessages first equals: 'Select or log into a GemStone session first.'
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testOpenSystemBrowserWithLoggedOutSessionShowsMessage [
	| fakeSession |
	fakeSession := MockGbsSession new.
	fakeSession isLoggedIn: false.
	launcher forcedSession: fakeSession.

	self deny: launcher openSystemBrowser.
	self assert: launcher openBrowserCalls equals: 0.
	self assert: launcher infoMessages size equals: 1.
	self assert: launcher infoMessages first equals: 'Select or log into a GemStone session first.'
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testBrowseHierarchySendersWithoutSessionShowsMessage [
	launcher forcedSession: nil.

	self deny: launcher browseHierarchySenders.
	self assert: launcher infoMessages size equals: 1.
	self assert: launcher infoMessages first equals: 'Select or log into a GemStone session first.'
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testBrowseHierarchyImplementorsWithoutSessionShowsMessage [
	launcher forcedSession: nil.

	self deny: launcher browseHierarchyImplementors.
	self assert: launcher infoMessages size equals: 1.
	self assert: launcher infoMessages first equals: 'Select or log into a GemStone session first.'
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testClassPerformBrowseHierarchyQueryPassesSuperScope [
	| session |
	session := MockGbsSession new.
	session isLoggedIn: true.
	session sessionId: 1.
	GbsSessionParameters currentSession: session.
	GbsTestableClassicLauncher enqueueRequestAnswer: 'Object'.
	GbsTestableClassicLauncher enqueueRequestAnswer: 'size'.
	"2 => superclasses"
	GbsTestableClassicLauncher enqueueChooseAnswer: 2.

	GbsTestableClassicLauncher
		performBrowseHierarchyQueryWithPrompt: 'Hierarchy senders of selector:'
		mode: 'hierarchySenders'
		titlePrefix: 'Hierarchy Senders of '.

	self assert: GbsTestableClassicLauncher lastHierarchyQuery equals: 'size'.
	self assert: GbsTestableClassicLauncher lastHierarchyMode equals: 'hierarchySenders'.
	self assert: GbsTestableClassicLauncher lastHierarchyRootClass equals: 'Object'.
	self assert: GbsTestableClassicLauncher lastHierarchyScope equals: 'super'.
	self assert: (GbsTestableClassicLauncher lastOpenedReferences includes: 'Object>>size')
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testClassPerformBrowseHierarchyQueryPassesSubScope [
	| session |
	session := MockGbsSession new.
	session isLoggedIn: true.
	session sessionId: 2.
	GbsSessionParameters currentSession: session.
	GbsTestableClassicLauncher enqueueRequestAnswer: 'Object'.
	GbsTestableClassicLauncher enqueueRequestAnswer: 'size'.
	"4 => subclasses"
	GbsTestableClassicLauncher enqueueChooseAnswer: 4.

	GbsTestableClassicLauncher
		performBrowseHierarchyQueryWithPrompt: 'Hierarchy implementors of selector:'
		mode: 'hierarchyImplementors'
		titlePrefix: 'Hierarchy Implementors of '.

	self assert: GbsTestableClassicLauncher lastHierarchyQuery equals: 'size'.
	self assert: GbsTestableClassicLauncher lastHierarchyMode equals: 'hierarchyImplementors'.
	self assert: GbsTestableClassicLauncher lastHierarchyRootClass equals: 'Object'.
	self assert: GbsTestableClassicLauncher lastHierarchyScope equals: 'sub'.
	self assert: (GbsTestableClassicLauncher lastOpenedReferences includes: 'Object>>size')
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testOpenSymbolDictionaryBrowserPassesDictionaryName [
	| fakeSession |
	fakeSession := Object new.
	launcher forcedSession: fakeSession.
	launcher requestedDictionaryName: 'UserGlobals'.

	self assert: launcher openSymbolDictionaryBrowser.
	self assert: launcher openBrowserCalls equals: 1.
	self assert: launcher lastOpenedSession == fakeSession.
	self assert: launcher lastOpenedDictionary equals: 'UserGlobals'
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testBrowsingSessionFromParametersUsesCurrentSession [
	| params liveSession |
	params := GbsSessionParameters new.
	liveSession := MockGbsSession new.
	liveSession isLoggedIn: true.
	GbsSessionParameters currentSession: liveSession.

	self assert: (launcher browsingSessionFrom: params) == liveSession
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testBrowseNamedObjectCacheReportUsesSelectedSessionCacheText [
	| session cache |
	session := MockGbsSession new.
	session isLoggedIn: true.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session instVarNamed: 'namedObjectCache' put: cache.
	launcher forcedSession: session.

	self assert: launcher browseNamedObjectCacheReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Named Object Cache').
	self assert: (launcher infoMessages first includesSubstring: 'UserGlobals -> oop 9001').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testBrowseTypedWrapperAutoloadReportUsesSelectedSessionRegistry [
	| session |
	session := MockGbsSession new.
	session isLoggedIn: true.
	launcher forcedSession: session.
	GbsSessionManager addConnectorClient: 'DemoClient' server: 'DemoServer' forSession: session.

	[
		self assert: launcher browseTypedWrapperAutoloadReport.
		self assert: launcher infoMessages size equals: 1.
		self assert: (launcher infoMessages first includesSubstring: 'Typed Wrapper Autoload').
		self assert: (launcher infoMessages first includesSubstring: 'DemoClient -> DemoServer').
		self assert: GbsSessionParameters currentSession == session
	] ensure: [
		GbsSessionManager removeConnectorClient: 'DemoClient' server: 'DemoServer' forSession: session ]
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testBrowseTypedWrapperLifecycleReportUsesSelectedSession [
	| session |
	session := MockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #typedWrapperLifecycleReportText put: [ 'Typed Wrapper Lifecycle', String cr, String cr, 'No typed wrappers generated.' ].
	launcher forcedSession: session.

	self assert: launcher browseTypedWrapperLifecycleReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Typed Wrapper Lifecycle').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testBrowseStaleTypedWrapperLifecycleReportUsesSelectedSession [
	| session stale current |
	session := MockGbsSession new.
	session isLoggedIn: true.
	stale := GbsTypedWrapperLifecycleEntry
		wrapperClass: GbsTypedProxy
		clientName: 'DemoClient'
		serverName: 'DemoServer'
		source: 'remote'
		localVersion: 1
		localNumberOfVersions: 1
		remoteVersion: 2
		remoteNumberOfVersions: 2
		status: #stale.
	current := GbsTypedWrapperLifecycleEntry
		wrapperClass: GbsTypedProxy
		clientName: 'FreshClient'
		serverName: 'FreshServer'
		source: 'remote'
		localVersion: 1
		localNumberOfVersions: 1
		remoteVersion: 1
		remoteNumberOfVersions: 1
		status: #current.
	session stubs at: #typedWrapperLifecycleReport put: [
		GbsTypedWrapperLifecycleReport entries: { stale. current } ].
	launcher forcedSession: session.

	self assert: launcher browseStaleTypedWrapperLifecycleReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'DemoClient').
	self deny: (launcher infoMessages first includesSubstring: 'FreshClient').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testBrowseSessionStateReportUsesSelectedSessionState [
	| session |
	session := MockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		self fail ].
	launcher forcedSession: session.

	self assert: launcher browseSessionStateReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Session State').
	self assert: (launcher infoMessages first includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testBrowsePromptedSessionStateKeysReportUsesSelectedSessionState [
	| session |
	session := MockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 19')
			ifTrue: [ ^ (IdentityDictionary new
				at: #lazyThing put: 'registered';
				yourself) ].
		(script includesSubstring: 'key := 21')
			ifTrue: [ ^ 'cache' ].
		self fail ].
	launcher forcedSession: session.
	GbsTestableClassicLauncher enqueueRequestAnswer: '19,21'.

	self assert: launcher browsePromptedSessionStateKeysReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1').
	self assert: (launcher infoMessages first includesSubstring: 'Key 21 (Session State): ByteString').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testBrowseRubyLoadPathReportUsesSelectedSession [
	| session |
	session := MockGbsSession new.
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
GbsClassicLauncherTest >> testBrowseRubyLoadedFeaturesReportUsesSelectedSession [
	| session |
	session := MockGbsSession new.
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
GbsClassicLauncherTest >> testBrowseRubyPersistentLoadedFeaturesReportUsesSelectedSession [
	| session |
	session := MockGbsSession new.
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
GbsClassicLauncherTest >> testBrowseTopLevelAutoloadRegistrationsReportUsesSelectedSession [
	| session |
	session := MockGbsSession new.
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
GbsClassicLauncherTest >> testBrowseObjectsInMemoryReportUsesSelectedSession [
	| session |
	session := MockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'startIndex := 3').
		self assert: (script includesSubstring: 'limitValue := 2').
		^ { GbsProxy oop: 9101 session: session. GbsProxy oop: 9102 session: session } ].
	launcher forcedSession: session.
	GbsTestableClassicLauncher enqueueRequestAnswer: '3'.
	GbsTestableClassicLauncher enqueueRequestAnswer: '2'.

	self assert: launcher browseObjectsInMemoryReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Objects In Memory').
	self assert: (launcher infoMessages first includesSubstring: 'oop=9101').
	self assert: (launcher infoMessages first includesSubstring: 'oop=9102').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testBrowseMaglevFinalizerRegistryReportUsesSelectedSessionState [
	| session |
	session := MockGbsSession new.
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
GbsClassicLauncherTest >> testInspectMaglevFinalizerRegistryUsesSelectedSession [
	| session registry |
	session := MockGbsSession new.
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

{ #category : 'tests' }
GbsClassicLauncherTest >> testInspectPromptedSessionStateKeyInformsWhenUnset [
	| session |
	session := MockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 21')
			ifTrue: [ ^ nil ].
		self fail ].
	launcher forcedSession: session.
	GbsTestableClassicLauncher enqueueRequestAnswer: '21'.

	self deny: launcher inspectPromptedSessionStateKey.
	self assert: launcher infoMessages last equals: 'Session state key 21 is not set.'.
	self assert: launcher lastInspectedOop isNil.
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testInspectPromptedSessionStateKeyRejectsNonNumericInput [
	| session |
	session := MockGbsSession new.
	session isLoggedIn: true.
	launcher forcedSession: session.
	GbsTestableClassicLauncher enqueueRequestAnswer: 'abc'.

	self deny: launcher inspectPromptedSessionStateKey.
	self assert: launcher infoMessages last equals: 'Enter a numeric session state key.'.
	self assert: launcher lastInspectedOop isNil
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testInspectPromptedSessionStateKeyUsesSelectedSession [
	| session registry |
	session := MockGbsSession new.
	session isLoggedIn: true.
	registry := GbsProxy oop: 8181 session: session.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 21')
			ifTrue: [ ^ registry ].
		self fail ].
	launcher forcedSession: session.
	GbsTestableClassicLauncher enqueueRequestAnswer: '21'.

	self assert: launcher inspectPromptedSessionStateKey.
	self assert: launcher lastInspectedOop equals: 8181.
	self assert: launcher lastInspectedSession == session.
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testClearNamedObjectCacheClearsSelectedSessionCache [
	| session cache |
	session := MockGbsSession new.
	session isLoggedIn: true.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session instVarNamed: 'namedObjectCache' put: cache.
	launcher forcedSession: session.

	self assert: launcher clearNamedObjectCache.
	self assert: launcher infoMessages size equals: 1.
	self assert: launcher infoMessages first equals: 'Named object cache cleared.'.
	self assert: session namedObjectCacheKeys equals: #().
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testInspectCurrentUserGlobalsUsesSelectedSessionNamedObjectProxy [
	| session cache |
	session := MockGbsSession new.
	session isLoggedIn: true.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session instVarNamed: 'namedObjectCache' put: cache.
	launcher forcedSession: session.

	self assert: launcher inspectCurrentUserGlobals.
	self assert: launcher lastInspectedOop equals: 9001.
	self assert: launcher lastInspectedSession == session.
	self assert: launcher infoMessages isEmpty.
	self assert: GbsSessionParameters currentSession == session
]
