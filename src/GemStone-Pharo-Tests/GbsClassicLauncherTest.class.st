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
GbsClassicLauncherTest >> testDoExportParametersWritesRedactedConfigurationFile [
	| previous params file exported |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	previous := GbsSessionParameters allParameters copy.
	file := FileLocator temp / ('gbs-session-parameters-export-', 1000000 atRandom asString, '.ston').
	[
		GbsSessionParameters allParameters removeAll.
		params := GbsSessionParameters new.
		params
			name: 'Production';
			username: 'DataCurator';
			password: 'secret'.
		GbsSessionParameters addParameter: params.
		GbsTestableClassicLauncher enqueueRequestAnswer: file fullName.

		self assert: launcher doExportParameters.

		exported := GbsSessionParameters parametersFromExportString: file contents.
		self assert: exported size equals: 1.
		self assert: exported first name equals: 'Production'.
		self assert: exported first password isNil.
		self assert: launcher infoMessages last equals: 'Exported 1 session parameter configuration(s).'
	] ensure: [
		file ensureDelete.
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testDoImportParametersAppendsConfigurationFromFile [
	| previous params file |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	previous := GbsSessionParameters allParameters copy.
	file := FileLocator temp / ('gbs-session-parameters-import-', 1000000 atRandom asString, '.ston').
	[
		GbsSessionParameters allParameters removeAll.
		params := GbsSessionParameters new.
		params
			name: 'Imported';
			username: 'GcUser'.
		file writeStreamDo: [ :stream | stream nextPutAll: params exportString ].
		GbsTestableClassicLauncher enqueueRequestAnswer: file fullName.

		self assert: launcher doImportParameters.

		self assert: GbsSessionParameters allParameters size equals: 1.
		self assert: GbsSessionParameters allParameters first name equals: 'Imported'.
		self assert: GbsSessionParameters allParameters first username equals: 'GcUser'.
		self assert: launcher infoMessages last equals: 'Imported 1 session parameter configuration(s).'
	] ensure: [
		file ensureDelete.
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]
