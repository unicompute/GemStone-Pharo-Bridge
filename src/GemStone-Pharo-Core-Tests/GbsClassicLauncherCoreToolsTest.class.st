Class {
	#name : 'GbsClassicLauncherCoreToolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'launcher',
		'previousCurrentSession'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GbsClassicLauncherCoreToolsTest >> setUp [
	super setUp.
	previousCurrentSession := GbsSessionParameters currentSession.
	CoreTestableGbsClassicLauncher resetClassHarness.
	launcher := CoreTestableGbsClassicLauncher new
]

{ #category : 'running' }
GbsClassicLauncherCoreToolsTest >> tearDown [
	GbsSessionParameters currentSession: previousCurrentSession.
	super tearDown
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testBrowseNamedObjectCacheReportUsesSelectedSessionCacheText [
	| session cache |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session namedObjectCache addAll: cache.
	launcher forcedSession: session.

	self assert: launcher browseNamedObjectCacheReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Named Object Cache').
	self assert: (launcher infoMessages first includesSubstring: 'UserGlobals -> oop 9001').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testBrowseTypedWrapperAutoloadReportUsesSelectedSessionRegistry [
	| session |
	session := CoreMockGbsSession new.
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
GbsClassicLauncherCoreToolsTest >> testBrowseTypedWrapperLifecycleReportUsesSelectedSession [
	| session |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #typedWrapperLifecycleReportText put: [ 'Typed Wrapper Lifecycle', String cr, String cr, 'No typed wrappers generated.' ].
	launcher forcedSession: session.

	self assert: launcher browseTypedWrapperLifecycleReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Typed Wrapper Lifecycle').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testBrowseStaleTypedWrapperLifecycleReportUsesSelectedSession [
	| session stale current |
	session := CoreMockGbsSession new.
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
GbsClassicLauncherCoreToolsTest >> testBrowseSessionStateReportUsesSelectedSessionState [
	| session |
	session := CoreMockGbsSession new.
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
GbsClassicLauncherCoreToolsTest >> testBrowsePromptedSessionStateKeysReportUsesSelectedSessionState [
	| session |
	session := CoreMockGbsSession new.
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
	CoreTestableGbsClassicLauncher enqueueRequestAnswer: '19,21'.

	self assert: launcher browsePromptedSessionStateKeysReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Key 19 (MagLev Finalizer Registry): IdentityDictionary size=1').
	self assert: (launcher infoMessages first includesSubstring: 'Key 21 (Session State): ByteString').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testBrowseObjectsInMemoryReportUsesSelectedSession [
	| session |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		self assert: (script includesSubstring: 'startIndex := 3').
		self assert: (script includesSubstring: 'limitValue := 2').
		^ { GbsProxy oop: 9101 session: session. GbsProxy oop: 9102 session: session } ].
	launcher forcedSession: session.
	CoreTestableGbsClassicLauncher enqueueRequestAnswer: '3'.
	CoreTestableGbsClassicLauncher enqueueRequestAnswer: '2'.

	self assert: launcher browseObjectsInMemoryReport.
	self assert: launcher infoMessages size equals: 1.
	self assert: (launcher infoMessages first includesSubstring: 'Objects In Memory').
	self assert: (launcher infoMessages first includesSubstring: 'oop=9101').
	self assert: (launcher infoMessages first includesSubstring: 'oop=9102').
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testInspectPromptedSessionStateKeyInformsWhenUnset [
	| session |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 21')
			ifTrue: [ ^ nil ].
		self fail ].
	launcher forcedSession: session.
	CoreTestableGbsClassicLauncher enqueueRequestAnswer: '21'.

	self deny: launcher inspectPromptedSessionStateKey.
	self assert: launcher infoMessages last equals: 'Session state key 21 is not set.'.
	self assert: launcher lastInspectedOop isNil.
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testInspectPromptedSessionStateKeyRejectsNonNumericInput [
	| session |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	launcher forcedSession: session.
	CoreTestableGbsClassicLauncher enqueueRequestAnswer: 'abc'.

	self deny: launcher inspectPromptedSessionStateKey.
	self assert: launcher infoMessages last equals: 'Enter a numeric session state key.'.
	self assert: launcher lastInspectedOop isNil
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testInspectPromptedSessionStateKeyUsesSelectedSession [
	| session registry |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	registry := GbsProxy oop: 8181 session: session.
	session stubs at: #executeScriptAndFetchObject put: [ :script |
		(script includesSubstring: 'key := 21')
			ifTrue: [ ^ registry ].
		self fail ].
	launcher forcedSession: session.
	CoreTestableGbsClassicLauncher enqueueRequestAnswer: '21'.

	self assert: launcher inspectPromptedSessionStateKey.
	self assert: launcher lastInspectedOop equals: 8181.
	self assert: launcher lastInspectedSession == session.
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testClearNamedObjectCacheClearsSelectedSessionCache [
	| session cache |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session namedObjectCache addAll: cache.
	launcher forcedSession: session.

	self assert: launcher clearNamedObjectCache.
	self assert: launcher infoMessages size equals: 1.
	self assert: launcher infoMessages first equals: 'Named object cache cleared.'.
	self assert: session namedObjectCacheKeys equals: #().
	self assert: GbsSessionParameters currentSession == session
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testInspectCurrentUserGlobalsUsesSelectedSessionNamedObjectProxy [
	| session cache |
	session := CoreMockGbsSession new.
	session isLoggedIn: true.
	cache := Dictionary new.
	cache at: #UserGlobals put: (GbsProxy oop: 9001 session: session).
	session namedObjectCache addAll: cache.
	launcher forcedSession: session.

	self assert: launcher inspectCurrentUserGlobals.
	self assert: launcher lastInspectedOop equals: 9001.
	self assert: launcher lastInspectedSession == session.
	self assert: launcher infoMessages isEmpty.
	self assert: GbsSessionParameters currentSession == session
]
