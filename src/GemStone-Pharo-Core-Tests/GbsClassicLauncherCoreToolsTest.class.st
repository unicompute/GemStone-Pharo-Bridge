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
GbsClassicLauncherCoreToolsTest >> testClassicLauncherStaticUtilitiesUseBoundCommands [
	| session trippyOop userName |
	session := CoreMockGbsSession new.
	session stubs at: #executeAndFetchContext put: [ :script :ctx |
		self assert: ctx equals: 20.
		self assert: (script beginsWith: '[ ').
		(script includesSubstring: 'GsCurrentSession currentSession asOop asString') ifTrue: [
			^ '9001' ].
		(script includesSubstring: 'System myUserProfile userId asString') ifTrue: [
			^ 'DataCurator' ].
		self fail ].

	trippyOop := GbsClassicLauncher defaultTrippyOopForSession: session.
	userName := GbsClassicLauncher currentUserNameIn: session.

	self assert: trippyOop equals: '9001'.
	self assert: userName equals: 'DataCurator'
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testSessionParametersEditorRoundTripsNetldiFields [
	| params editor hostField portField |
	params := GbsSessionParameters new.
	params
		netldiHostOrIp: 'localhost';
		netldiNameOrPort: '50377'.
	editor := GbsSessionParametersEditor new.
	editor setModel: params.
	hostField := editor instVarNamed: 'netldiHostField'.
	portField := editor instVarNamed: 'netldiPortField'.

	self assert: hostField text equals: 'localhost'.
	self assert: portField text equals: '50377'.

	hostField text: ' gemstone.example.com '.
	portField text: ' gs64ldi '.
	editor updateModel.

	self assert: params netldiHostOrIp equals: 'gemstone.example.com'.
	self assert: params netldiNameOrPort equals: 'gs64ldi'
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testSessionParametersEditorValidationReportsMissingRequiredFields [
	| params editor message |
	params := GbsSessionParameters new.
	params
		name: ' ';
		gemStoneName: ' ';
		username: ' '.
	editor := GbsSessionParametersEditor new.
	editor setModel: params.
	editor updateModel.

	message := editor validationErrorMessage.

	self assert: (message includesSubstring: 'Configuration name is required.').
	self assert: (message includesSubstring: 'GemStone stone name is required.').
	self assert: (message includesSubstring: 'GemStone username is required.')
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testSessionParametersEditorDoesNotDisplayOrRetainPasswordsUnlessRemembered [
	| params editor passField hostPassField |
	params := GbsSessionParameters new.
	params
		username: 'DataCurator';
		password: 'secret';
		hostPassword: 'host-secret';
		gsRemember: false;
		hostRemember: false.
	editor := GbsSessionParametersEditor new.
	editor setModel: params.
	passField := editor instVarNamed: 'passField'.
	hostPassField := editor instVarNamed: 'hostPassField'.

	self assert: passField text equals: ''.
	self assert: hostPassField text equals: ''.

	editor updateModel.

	self assert: params password isNil.
	self assert: params hostPassword isNil
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testSessionParametersEditorDetectsUnsavedChanges [
	| params editor nameField |
	params := GbsSessionParameters new.
	params
		name: 'Production';
		username: 'DataCurator'.
	editor := GbsSessionParametersEditor new.
	editor setModel: params.

	self deny: editor hasUnsavedChanges.

	nameField := editor instVarNamed: 'nameField'.
	nameField text: 'Production Copy'.

	self assert: editor hasUnsavedChanges.
	editor updateModel.
	self deny: editor hasUnsavedChanges
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testSessionParametersEditorValidationReportsDuplicateConfigurationName [
	| previous existing params editor message |
	previous := GbsSessionParameters allParameters copy.
	[
		GbsSessionParameters allParameters removeAll.
		existing := GbsSessionParameters new.
		existing
			name: 'Production';
			username: 'DataCurator'.
		GbsSessionParameters addParameter: existing.
		params := GbsSessionParameters new.
		params
			name: 'Production';
			username: 'GcUser'.
		editor := GbsSessionParametersEditor new.
		editor setModel: params.
		editor updateModel.

		message := editor validationErrorMessage.

		self assert: (message includesSubstring: 'already exists')
	] ensure: [
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testDoAddParameterAcceptAddsRefreshesAndSelectsNewConfiguration [
	| previous added |
	previous := GbsSessionParameters allParameters copy.
	[
		GbsSessionParameters allParameters removeAll.

		launcher doAddParameter.
		added := launcher lastEditorModel.
		added username: 'DataCurator'.
		self assert: GbsSessionParameters allParameters isEmpty.

		launcher acceptLastParameterEditor.

		self assert: GbsSessionParameters allParameters size equals: 1.
		self assert: GbsSessionParameters allParameters first == added.
		self assert: launcher lastSelectedParameter == added
	] ensure: [
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testDoEditParameterAcceptRefreshesAndKeepsSelection [
	| previous params |
	previous := GbsSessionParameters allParameters copy.
	[
		GbsSessionParameters allParameters removeAll.
		params := GbsSessionParameters new.
		params
			name: 'Production';
			username: 'DataCurator'.
		GbsSessionParameters addParameter: params.
		launcher selectedParameter: params.

		self assert: launcher doEditParameter.
		self assert: launcher lastEditorModel == params.
		launcher acceptLastParameterEditor.

		self assert: launcher lastSelectedParameter == params.
		self assert: launcher refreshCount > 0
	] ensure: [
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testDoCopyParameterRenamesCopyClearsSessionAndSelectsIt [
	| previous params copy |
	previous := GbsSessionParameters allParameters copy.
	[
		GbsSessionParameters allParameters removeAll.
		params := GbsSessionParameters new.
		params
			name: 'Production';
			username: 'DataCurator';
			sessionId: 123.
		GbsSessionParameters addParameter: params.
		launcher selectedParameter: params.

		self assert: launcher doCopyParameter.

		self assert: GbsSessionParameters allParameters size equals: 2.
		copy := GbsSessionParameters allParameters second.
		self assert: copy name equals: 'Production (copy)'.
		self assert: copy sessionId isNil.
		self assert: launcher lastSelectedParameter == copy
	] ensure: [
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testDoDeleteParameterRefreshesAndSelectsReplacement [
	| previous first second |
	previous := GbsSessionParameters allParameters copy.
	[
		GbsSessionParameters allParameters removeAll.
		first := GbsSessionParameters new
			name: 'One';
			username: 'DataCurator';
			yourself.
		second := GbsSessionParameters new
			name: 'Two';
			username: 'GcUser';
			yourself.
		GbsSessionParameters addParameter: first.
		GbsSessionParameters addParameter: second.
		launcher selectedParameter: first.

		self assert: launcher doDeleteParameter.

		self assert: GbsSessionParameters allParameters size equals: 1.
		self assert: GbsSessionParameters allParameters first == second.
		self assert: launcher lastSelectedParameter == second
	] ensure: [
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testDoExportParametersWritesRedactedConfigurationFile [
	| previous params file exported |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	previous := GbsSessionParameters allParameters copy.
	file := FileLocator temp / ('gbs-session-parameters-export-core-', 1000000 atRandom asString, '.ston').
	[
		GbsSessionParameters allParameters removeAll.
		params := GbsSessionParameters new.
		params
			name: 'Production';
			username: 'DataCurator';
			password: 'secret'.
		GbsSessionParameters addParameter: params.
		CoreTestableGbsClassicLauncher enqueueRequestAnswer: file fullName.

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
GbsClassicLauncherCoreToolsTest >> testDoExportParametersIncludingSecretsRequiresConfirmation [
	| previous params file |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	previous := GbsSessionParameters allParameters copy.
	file := FileLocator temp / ('gbs-session-parameters-secret-export-core-', 1000000 atRandom asString, '.ston').
	[
		GbsSessionParameters allParameters removeAll.
		params := GbsSessionParameters new.
		params
			name: 'Production';
			username: 'DataCurator';
			password: 'secret';
			gsRemember: true.
		GbsSessionParameters addParameter: params.
		launcher secretExportConfirmation: false.
		CoreTestableGbsClassicLauncher enqueueRequestAnswer: file fullName.

		self deny: launcher doExportParametersIncludingSecrets.
		self deny: file exists.
		self assert: launcher infoMessages isEmpty
	] ensure: [
		file ensureDelete.
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testDoExportParametersIncludingSecretsWritesStoredSecrets [
	| previous params file exported |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	previous := GbsSessionParameters allParameters copy.
	file := FileLocator temp / ('gbs-session-parameters-secret-export-core-', 1000000 atRandom asString, '.ston').
	[
		GbsSessionParameters allParameters removeAll.
		params := GbsSessionParameters new.
		params
			name: 'Production';
			username: 'DataCurator';
			password: 'secret';
			gsRemember: true.
		GbsSessionParameters addParameter: params.
		launcher secretExportConfirmation: true.
		CoreTestableGbsClassicLauncher enqueueRequestAnswer: file fullName.

		self assert: launcher doExportParametersIncludingSecrets.

		exported := GbsSessionParameters parametersFromExportString: file contents.
		self assert: exported first password equals: 'secret'.
		self assert: launcher infoMessages last equals: 'Exported 1 session parameter configuration(s) including stored secrets.'
	] ensure: [
		file ensureDelete.
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testDoImportParametersAppendsRefreshesAndSelectsImportedConfiguration [
	| previous params file |
	(Smalltalk includesKey: #STON) ifFalse: [ self skip: 'STON is not available in this image.' ].
	previous := GbsSessionParameters allParameters copy.
	file := FileLocator temp / ('gbs-session-parameters-import-core-', 1000000 atRandom asString, '.ston').
	[
		GbsSessionParameters allParameters removeAll.
		params := GbsSessionParameters new.
		params
			name: 'Imported';
			username: 'GcUser'.
		file writeStreamDo: [ :stream | stream nextPutAll: params exportString ].
		CoreTestableGbsClassicLauncher enqueueRequestAnswer: file fullName.

		self assert: launcher doImportParameters.

		self assert: GbsSessionParameters allParameters size equals: 1.
		self assert: GbsSessionParameters allParameters first name equals: 'Imported'.
		self assert: GbsSessionParameters allParameters first username equals: 'GcUser'.
		self assert: launcher lastSelectedParameter == GbsSessionParameters allParameters first.
		self assert: launcher infoMessages last equals: 'Imported 1 session parameter configuration(s).'
	] ensure: [
		file ensureDelete.
		GbsSessionParameters allParameters
			removeAll;
			addAll: previous ]
]

{ #category : 'tests' }
GbsClassicLauncherCoreToolsTest >> testLoginErrorMessageIncludesConnectionSummary [
	| params message exception |
	params := GbsSessionParameters new.
	params
		username: ' DataCurator ';
		gemStoneName: ' gs64stone ';
		gemService: ' gemnetobject ';
		netldiHostOrIp: ' gemstone.example.com ';
		netldiNameOrPort: ' 50377 '.
	exception := Error new
		messageText: 'Connection refused';
		yourself.

	message := launcher loginErrorMessageFor: params exception: exception.

	self assert: (message includesSubstring: 'Login failed for DataCurator@gs64stone via gemnetobject').
	self assert: (message includesSubstring: 'netldiHost=gemstone.example.com').
	self assert: (message includesSubstring: 'netldi=50377').
	self assert: (message includesSubstring: 'Connection refused')
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
