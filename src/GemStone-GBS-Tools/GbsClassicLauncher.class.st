Class {
	#name : 'GbsClassicLauncher',
	#superclass : 'SpPresenter',
	#instVars : [
		'sessionList',
		'parametersList',
		'mainMenu',
		'btnCommit',
		'btnLogout',
		'btnAbort',
		'btnCurrent',
		'btnBegin',
		'btnBreak',
		'btnLoginLink',
		'btnLoginRpc',
		'btnAdd',
		'btnCopy',
		'btnEdit',
		'btnDelete',
		'pollingProcess'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'menus' }
GbsClassicLauncher class >> aboutGemBuilder [
	UIManager default inform: 'GemBuilder for Pharo (GemStone-Pharo-Bridge)'.
]

{ #category : 'menus' }
GbsClassicLauncher class >> browseAllClassesOnCurrentSession [
	^ self openBrowserOnCurrentSession
]

{ #category : 'menus' }
GbsClassicLauncher class >> browseClassOnCurrentSession [
	self openBrowserOnCurrentSessionDo: [ :browser |
		(browser respondsTo: #findClass) ifTrue: [ browser findClass ] ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> browseHierarchyImplementorsOnCurrentSession [
	self
		performBrowseHierarchyQueryWithPrompt: 'Hierarchy implementors of selector:'
		mode: 'hierarchyImplementors'
		titlePrefix: 'Hierarchy Implementors of '
]

{ #category : 'menus' }
GbsClassicLauncher class >> browseHierarchySendersOnCurrentSession [
	self
		performBrowseHierarchyQueryWithPrompt: 'Hierarchy senders of selector:'
		mode: 'hierarchySenders'
		titlePrefix: 'Hierarchy Senders of '
]

{ #category : 'menus' }
GbsClassicLauncher class >> browseImplementorsOnCurrentSession [
	self
		performBrowseQueryWithPrompt: 'Implementors of selector:'
		mode: 'implementors'
		titlePrefix: 'Implementors of '
]

{ #category : 'menus' }
GbsClassicLauncher class >> browseMethodsWithSubstringOnCurrentSession [
	| session pattern worker references presenterClass sessionPart title script raw |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	pattern := UIManager default request: 'Methods with source substring:' initialAnswer: ''.
	(pattern isNil or: [ pattern trimBoth isEmpty ]) ifTrue: [ ^ self ].
	worker := GbsBrowser new.
	worker session: session.
	script := '[
		| classes stream p |
		p := ''', (pattern trimBoth copyReplaceAll: '''' with: ''''''), '''.
		stream := WriteStream on: String new.
		classes := IdentitySet new.
		System myUserProfile symbolList do: [ :dict |
			dict keysAndValuesDo: [ :k :v | (v isBehavior) ifTrue: [ classes add: v ] ] ].
		classes asArray do: [ :cls |
			cls selectors do: [ :sel |
				| src |
				src := [ (cls compiledMethodAt: sel) sourceString ] on: Error do: [ '''' ].
				(src includesSubstring: p) ifTrue: [
					stream nextPutAll: cls name asString; nextPutAll: ''>>''; nextPutAll: sel asString; lf
				]
			]
		].
		stream contents
	] value'.
	raw := [ session executeAndFetch: script context: 20 ] on: Error do: [ :ex |
		UIManager default inform: 'Browse methods-with-substring failed: ', ex messageText.
		'' ].
	references := ((raw asString splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty) asSortedCollection asArray.
	references isEmpty ifTrue: [ UIManager default inform: 'No matches found.'. ^ self ].
	presenterClass := Smalltalk at: #GbsMethodQueryResultsPresenter ifAbsent: [ nil ].
	presenterClass ifNil: [
		UIManager default inform: 'Could not open query results window: GbsMethodQueryResultsPresenter is not loaded.'.
		^ self ].
	sessionPart := (session respondsTo: #sessionId)
		ifTrue: [ 'Session ', session sessionId asString, ' ' ]
		ifFalse: [ '' ].
	title := sessionPart, 'Methods with substring ', pattern trimBoth, ' (', references size asString, ')'.
	[ presenterClass openOn: session references: references title: title ]
		on: Error
		do: [ :ex | UIManager default inform: 'Could not open query results window: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> browseNamespaceOnCurrentSession [
	self openBrowserOnCurrentSessionDo: [ :browser |
		(browser respondsTo: #findDictionary) ifTrue: [ browser findDictionary ] ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> browseReferencesOnCurrentSession [
	self
		performBrowseQueryWithPrompt: 'References to class or variable name:'
		mode: 'references'
		titlePrefix: 'References to '
]

{ #category : 'menus' }
GbsClassicLauncher class >> browseSendersOnCurrentSession [
	self
		performBrowseQueryWithPrompt: 'Senders of selector:'
		mode: 'senders'
		titlePrefix: 'Senders of '
]

{ #category : 'menus' }
GbsClassicLauncher class >> clearAllConnectorClassMappingsOnCurrentSession [
	| session mgr |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	mgr := Smalltalk at: #GbsSessionManager ifAbsent: [ nil ].
	(mgr isNil or: [ mgr respondsTo: #clearAllConnectorClassMappings not ]) ifTrue: [
		^ UIManager default inform: 'Connector manager unavailable.' ].
	(UIManager default
		confirm: 'Clear all connector class overrides and revert to default class resolution?'
		label: 'Clear Connector Class Overrides') ifFalse: [ ^ self ].
	[
		mgr clearAllConnectorClassMappings.
		UIManager default inform: 'Cleared all connector class overrides.'
	] on: Error do: [ :ex |
		UIManager default inform: 'Failed to clear connector class overrides: ', ex messageText ]
]

{ #category : 'menus' }
GbsClassicLauncher class >> currentSessionOrInform [
	| session |
	session := GbsSessionParameters currentSession.
	(session isNil or: [ (session respondsTo: #isLoggedIn) and: [ session isLoggedIn ~= true ] ]) ifTrue: [
		UIManager default inform: 'No connected GemStone session. Please login first.'.
		^ nil
	].
	^ session
]

{ #category : 'menus' }
GbsClassicLauncher class >> editConnectorClassMappingOnCurrentSession [
	| session mgr pairs pairLabels pairIndex pair clientName serverName choices labels classIndex selectedClass |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	mgr := Smalltalk at: #GbsSessionManager ifAbsent: [ nil ].
	(mgr isNil or: [ mgr respondsTo: #connectorPairs not ]) ifTrue: [
		^ UIManager default inform: 'Connector manager unavailable.' ].
	pairs := [ mgr connectorPairs ] on: Error do: [ #() ].
	pairs isEmpty ifTrue: [ ^ UIManager default inform: 'No connectors available.' ].
	pairLabels := pairs collect: [ :each |
		| c s |
		c := each at: 1 ifAbsent: [ '' ].
		s := each at: 2 ifAbsent: [ '' ].
		c asString, ' -> ', s asString ].
	pairIndex := UIManager default chooseFrom: pairLabels title: 'Select Connector Pair'.
	pairIndex = 0 ifTrue: [ ^ self ].
	pair := pairs at: pairIndex ifAbsent: [ ^ self ].
	clientName := pair at: 1 ifAbsent: [ ^ self ].
	serverName := pair at: 2 ifAbsent: [ ^ self ].
	choices := (mgr respondsTo: #connectorClassChoices)
		ifTrue: [ mgr connectorClassChoices ]
		ifFalse: [ { GbsFastConnector. GbsNameConnector. GbsClassConnector. GbsClassVarConnector. GbsClassInstVarConnector } ].
	labels := choices collect: [ :each | each name asString ].
	classIndex := UIManager default chooseFrom: labels title: 'Connector Class for ', clientName asString, ' -> ', serverName asString.
	classIndex = 0 ifTrue: [ ^ self ].
	selectedClass := choices at: classIndex ifAbsent: [ ^ self ].
	[
		mgr
			setConnectorClass: selectedClass
			forClient: clientName
			server: serverName.
		UIManager default inform: 'Connector class mapping saved.'.
	] on: Error do: [ :ex |
		UIManager default inform: 'Failed to save connector class mapping: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> generateClassConnectors [
	| mgr |
	mgr := Smalltalk at: #GbsSessionManager ifAbsent: [ nil ].
	(mgr isNil or: [ mgr respondsTo: #generateClassConnectors not ]) ifTrue: [
		^ UIManager default inform: 'Connector manager unavailable.' ].
	[
		mgr generateClassConnectors.
		UIManager default inform: 'Generated class connectors.'
	] on: Error do: [ :ex |
		UIManager default inform: 'Generate connectors failed: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> gsFileInOnCurrentSession [
	| session ref source |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	ref := self selectFileInReference.
	ref ifNil: [ ^ self ].
	[
		source := ref contents.
		session execute: source.
		UIManager default inform: 'GS File in completed.'
	] on: Error do: [ :ex |
		UIManager default inform: 'GS File in failed: ', ex messageText
	].
]

{ #category : 'menus' }
GbsClassicLauncher class >> hierarchyQueryReferencesFor: tokenString mode: modeString inSession: aSession rootClassName: rootClassName scope: scopeString [
	| worker |
	worker := GbsBrowser new.
	worker session: aSession.
	^ worker
		queryServerMethodsForSelector: tokenString
		mode: modeString
		rootClassName: rootClassName
		hierarchyScope: scopeString
]

{ #category : 'menus' }
GbsClassicLauncher class >> initializeFastConnectors [
	| mgr |
	mgr := Smalltalk at: #GbsSessionManager ifAbsent: [ nil ].
	(mgr isNil or: [ mgr respondsTo: #initializeFastConnectors not ]) ifTrue: [
		^ UIManager default inform: 'Connector manager unavailable.' ].
	[
		mgr initializeFastConnectors.
		UIManager default inform: 'Fast connectors initialized.'
	] on: Error do: [ :ex |
		UIManager default inform: 'Initialize connectors failed: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> logoutCurrentSession [
	| session params sessionId loggedOut |
	session := GbsSessionParameters currentSession.
	params := nil.
	sessionId := (session notNil and: [ session respondsTo: #sessionId ])
		ifTrue: [ [ session sessionId ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].

	params := GbsSessionParameters allSessions
		detect: [ :each |
			((each respondsTo: #isConnected) and: [ each isConnected = true ]) and: [
				sessionId isNil
					ifTrue: [ true ]
					ifFalse: [ (each respondsTo: #sessionId) and: [ each sessionId = sessionId ] ] ] ]
		ifNone: [ nil ].

	(session isNil and: [ params isNil ]) ifTrue: [
		^ UIManager default inform: 'No current GemStone session.' ].

	loggedOut := false.
	params ifNotNil: [
		[ params logout. loggedOut := true ] on: Error do: [ :ex | ] ].
	(loggedOut not and: [ session notNil and: [ session respondsTo: #logout ] ]) ifTrue: [
		[ session logout. loggedOut := true ] on: Error do: [ :ex | ] ].
	(loggedOut not) ifTrue: [
		[ GbsServerInterface uniqueInstance apiGciLogout. loggedOut := true ]
			on: Error
			do: [ :ex | ] ].

	params ifNotNil: [
		(params respondsTo: #sessionId:) ifTrue: [ params sessionId: nil ].
		GbsSessionParameters unregisterSession: params ].
	GbsSessionParameters currentSession: nil.

	UIManager default defer: [
		GbsSessionBrowserPresenter allInstancesDo: [ :presenter |
			(presenter respondsTo: #refreshAll) ifTrue: [ presenter refreshAll ] ].
		GbsLauncher allInstancesDo: [ :launcher | launcher updateUIState ].
		GbsClassicLauncher allInstancesDo: [ :launcher | launcher refreshAll ] ].

	UIManager default inform: (loggedOut
		ifTrue: [ 'Logged out current session.' ]
		ifFalse: [ 'Session state cleared.' ]).
]

{ #category : 'menus' }
GbsClassicLauncher class >> menuCommandGemStoneOn: aBuilder [
    <worldMenu>
    (aBuilder item: #GemStone)
        order: 79.9;
        label: 'GemStone';
        icon: (self iconNamed: #smallConfiguration);
        with: [
            (aBuilder item: #GbsSessions)
                label: 'Sessions';
                with: [
                    (aBuilder item: #SessionBrowser)
                        label: 'Session Browser';
                        action: [ GbsSessionBrowserPresenter new open ];
                        icon: (self iconNamed: #glamorousBrowse).
                    (aBuilder item: #SimpleLauncher)
                        label: 'Simple Launcher';
                        action: [ GbsLauncher new open ];
                        icon: (self iconNamed: #glamorousPlay).
                    (aBuilder item: #LogoutCurrentSession)
                        label: 'Logout Current Session';
                        action: [ self logoutCurrentSession ] ].

            (aBuilder item: #GbsConnectors)
                label: 'Connectors';
                with: [
                    (aBuilder item: #ConnectorBrowserGroup)
                        label: 'Browser';
                        with: [
                            (aBuilder item: #OpenConnectorBrowser)
                                label: 'Connector Browser';
                                action: [ self openConnectorBrowserOnCurrentSession ] ].
                    (aBuilder item: #ConnectorMaintenanceGroup)
                        label: 'Maintenance';
                        with: [
                            (aBuilder item: #InitializeFastConnectors)
                                label: 'Initialize Fast Connectors';
                                action: [ self initializeFastConnectors ].
                            (aBuilder item: #GenerateClassConnectors)
                                label: 'Generate Class Connectors';
                                action: [ self generateClassConnectors ].
                            (aBuilder item: #RemoveInvalidConnectors)
                                label: 'Remove Invalid Connectors';
                                action: [ self removeInvalidConnectors ].
                            (aBuilder item: #ConnectorClassMapping)
                                label: 'Connector Class Mapping...';
                                action: [ self editConnectorClassMappingOnCurrentSession ].
                            (aBuilder item: #ShowConnectorClassMappings)
                                label: 'Show Connector Class Mappings...';
                                action: [ self showConnectorClassMappingsOnCurrentSession ].
                            (aBuilder item: #ClearAllConnectorClassMappings)
                                label: 'Clear All Connector Class Overrides';
                                action: [ self clearAllConnectorClassMappingsOnCurrentSession ] ] ].

            (aBuilder item: #GbsBrowse)
                label: 'Browse';
                with: [
                    (aBuilder item: #BrowseAllClasses)
                        label: 'All Classes';
                        action: [ self browseAllClassesOnCurrentSession ].
                    (aBuilder item: #BrowseClass)
                        label: 'Class...';
                        action: [ self browseClassOnCurrentSession ].
                    (aBuilder item: #BrowseNamespace)
                        label: 'Namespace...';
                        action: [ self browseNamespaceOnCurrentSession ].
                    (aBuilder item: #BrowseSenders)
                        label: 'Senders of...';
                        action: [ self browseSendersOnCurrentSession ].
                    (aBuilder item: #BrowseImplementors)
                        label: 'Implementors of...';
                        action: [ self browseImplementorsOnCurrentSession ].
                    (aBuilder item: #BrowseHierarchySenders)
                        label: 'Hierarchy Senders of...';
                        action: [ self browseHierarchySendersOnCurrentSession ].
                    (aBuilder item: #BrowseHierarchyImplementors)
                        label: 'Hierarchy Implementors of...';
                        action: [ self browseHierarchyImplementorsOnCurrentSession ].
                    (aBuilder item: #BrowseReferences)
                        label: 'References to...';
                        action: [ self browseReferencesOnCurrentSession ].
                    (aBuilder item: #BrowseStringMatch)
                        label: 'Methods with substring...';
                        action: [ self browseMethodsWithSubstringOnCurrentSession ] ].

            (aBuilder item: #GbsAdmin)
                label: 'Admin';
                with: [
                    (aBuilder item: #AdminUsers)
                        label: 'Users';
                        action: [ self openUsersOnCurrentSession ].
                    (aBuilder item: #AdminNamespaces)
                        label: 'Namespaces';
                        action: [ self openNamespacesOnCurrentSession ].
                    (aBuilder item: #AdminSecurityPolicies)
                        label: 'Security Policies';
                        action: [ self openSecurityPoliciesOnCurrentSession ] ].

            (aBuilder item: #GbsTools)
                label: 'Tools';
                with: [
                    (aBuilder item: #NewGSWorkspace)
                        label: 'New GS Workspace';
                        action: [ GbsWorkspace new open ].
                    (aBuilder item: #OpenGSWorkspace)
                        label: 'Open GS Workspace...';
                        action: [ GbsWorkspace new open ].
                    (aBuilder item: #GSFileIn)
                        label: 'GS File in...';
                        action: [ self gsFileInOnCurrentSession ].
                    (aBuilder item: #GSSettings)
                        label: 'Settings';
                        action: [ self openSettings ].
                    (aBuilder item: #GSBreakpoints)
                        label: 'Breakpoints';
                        action: [ self openBreakpointsBrowser ].
                    (aBuilder item: #GSSystemWorkspace)
                        label: 'System Workspace';
                        action: [ GbsWorkspace new open ] ].

            (aBuilder item: #GbsUtilities)
                label: 'Utilities';
                with: [
                    (aBuilder item: #OpenGbxFileLogger)
                        label: 'File Logger';
                        action: [ self openGbxFileLogger ].
                    (aBuilder item: #OpenGbxMemoryLogger)
                        label: 'Memory Logger';
                        action: [ self openGbxMemoryLogger ].
                    (aBuilder item: #OpenGbxReplicatorManager)
                        label: 'Replication Manager';
                        action: [ self openGbxReplicatorManager ].
                    (aBuilder item: #OpenGbxServerMap)
                        label: 'Server Map';
                        action: [ self openGbxServerMap ].
                    (aBuilder item: #OpenGbxStatMonitor)
                        label: 'Stat Monitor';
                        action: [ self openGbxStatMonitor ].
                    (aBuilder item: #OpenGbxStoreTraversalTool)
                        label: 'Store Traversal Tool';
                        action: [ self openGbxStoreTraversalTool ].
                    (aBuilder item: #OpenGbxTrippy)
                        label: 'Trippy';
                        action: [ self openGbxTrippy ] ].

            (aBuilder item: #AboutGemBuilder)
                label: 'About GemBuilder...';
                action: [ self aboutGemBuilder ].
        ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openBreakpointsBrowser [
	| session |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	^ [ GbsBreakpointBrowserPresenter openOn: session ]
		on: Error
		do: [ :ex |
			UIManager default inform: 'Could not open breakpoints browser: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openBrowserOnCurrentSession [
	| session |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	[
		GbsBrowser openOn: session
	] on: Error do: [ :ex |
		UIManager default inform: 'Could not open GemStone browser: ', ex messageText
	].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openBrowserOnCurrentSessionDo: oneArgBlock [
	| session browser |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	[
		browser := GbsBrowser openOn: session.
		browser ifNotNil: [ oneArgBlock cull: browser ].
	] on: Error do: [ :ex |
		UIManager default inform: 'Could not open GemStone browser: ', ex messageText
	].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openConnectorBrowserOnCurrentSession [
	| session |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	^ [ GbsConnectorBrowserPresenter openOn: session ]
		on: Error
		do: [ :ex |
			UIManager default inform: 'Could not open connector browser: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openGbxFileLogger [
	| logger path contents |

	"Check if call tracing is already active"
	(GbsCallTracing isCallTracingActive and: [ GbsCallTracing logger isKindOf: GbxFileLogger ])
		ifTrue: [
			"Show existing file logger contents"
			logger := GbsCallTracing logger.
			contents := logger contents.
			contents ifEmpty: [ contents := '(Log file is empty)'. ].
			^ self showLogContent: contents title: 'File Logger - ' , logger filename
		].

	"Start new file logging"
	path := UIManager default
		request: 'Log file path:'
		initialAnswer: '/tmp/gbs-file-logger.log'.
	(path isNil or: [ path trimBoth isEmpty ]) ifTrue: [ ^ self ].

	[
		logger := GbsCallTracing startCallTracingToFileNamed: path trimBoth.
		logger logMessage: '--- Call tracing started ---'.
		contents := logger contents.
		contents ifEmpty: [ contents := '(Log file is empty)'. ].
		self showLogContent: contents title: 'File Logger - ' , logger filename
	] on: Error do: [ :ex |
		UIManager default inform: 'Failed to open File Logger: ', ex messageText ]
]

{ #category : 'utilities' }
GbsClassicLauncher class >> showLogContent: contents title: titleString [
	"Show log content in a proper multi-line text window"
	| textMorph window |
	
	textMorph := TextModelMorph textProvider: (TextModel new contents: contents).
	
	window := SystemWindow labelled: titleString.
	window addMorph: textMorph asMorph part: #center extent: 0@0.
	window setExtent: 800@600.
	window openInWorld
]

{ #category : 'menus' }
GbsClassicLauncher class >> openGbxMemoryLogger [
	| session logger |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	logger := session replicatorManager memoryLogger.
	logger ifNil: [
		^ UIManager default inform: 'Memory logger not available for this session.' ].
	^ [ logger inspect ]
		on: Error
		do: [ :ex |
			UIManager default inform: 'Could not open Memory Logger: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openGbxReplicatorManager [
	| session mgr |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	mgr := session replicatorManager.
	mgr ifNil: [
		^ UIManager default inform: 'Replication Manager not available for this session.' ].
	^ [ mgr inspect ]
		on: Error
		do: [ :ex |
			UIManager default inform: 'Could not open Replication Manager: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openGbxServerMap [
	| session serverMap |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	serverMap := session replicatorManager serverMap.
	serverMap ifNil: [
		^ UIManager default inform: 'Server Map not available for this session.' ].
	^ [ serverMap inspect ]
		on: Error
		do: [ :ex |
			UIManager default inform: 'Could not open Server Map: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openGbxStatMonitor [
	| monitor |
	monitor := Smalltalk at: #GbxStatMonitor ifAbsent: [ nil ].
	monitor ifNil: [
		^ UIManager default inform: 'Stat Monitor class not found.' ].
	^ [ monitor instance inspect ]
		on: Error
		do: [ :ex |
			UIManager default inform: 'Could not open Stat Monitor: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openGbxStoreTraversalTool [
	| session traversal |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	traversal := session currentTraversal.
	traversal ifNil: [
		^ UIManager default inform: 'No active store traversal for this session.' ].
	^ [ traversal inspect ]
		on: Error
		do: [ :ex |
			UIManager default inform: 'Could not open Store Traversal Tool: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openGbxTrippy [
	| session trippyDict |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	trippyDict := Dictionary new.
	trippyDict
		at: 'Session' put: session;
		at: 'ReplicatorManager' put: session replicatorManager;
		at: 'ServerMap' put: session replicatorManager serverMap;
		at: 'ClientMap' put: session replicatorManager clientMap.
	^ [ trippyDict inspect ]
		on: Error
		do: [ :ex |
			UIManager default inform: 'Could not open Trippy: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openNamespacesOnCurrentSession [
	| session |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	[
		GbsNamespacesPresenter openOn: session
	] on: Error do: [ :ex |
		UIManager default inform: 'Could not open namespaces tool: ', ex messageText
	].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openQueryResultsPresenterOn: session references: references title: titleString [
	| presenterClass |
	presenterClass := Smalltalk at: #GbsMethodQueryResultsPresenter ifAbsent: [ nil ].
	presenterClass ifNil: [
		UIManager default inform: 'Could not open query results window: GbsMethodQueryResultsPresenter is not loaded.'.
		^ self ].
	^ presenterClass openOn: session references: references title: titleString
]

{ #category : 'menus' }
GbsClassicLauncher class >> openSecurityPoliciesOnCurrentSession [
	| session |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	[
		GbsSecurityPoliciesPresenter openOn: session
	] on: Error do: [ :ex |
		UIManager default inform: 'Could not open security policies tool: ', ex messageText
	].
]

{ #category : 'menus' }
GbsClassicLauncher class >> openSettings [
	^ [ GbsSettingsPresenter open ]
		on: Error
		do: [ :ex | UIManager default inform: 'Could not open settings: ', ex messageText ]
]

{ #category : 'menus' }
GbsClassicLauncher class >> openUsersOnCurrentSession [
	| session |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	[
		GbsUserListPresenter openOn: session
	] on: Error do: [ :ex |
		UIManager default inform: 'Could not open users list: ', ex messageText
	].
]

{ #category : 'menus' }
GbsClassicLauncher class >> performBrowseHierarchyQueryWithPrompt: promptString mode: modeString titlePrefix: titlePrefixString [
	| session className query scope references sessionPart scopeLabel title |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	className := self uiRequest: 'Root class for hierarchy query:' initialAnswer: ''.
	(className isNil or: [ className trimBoth isEmpty ]) ifTrue: [ ^ self ].
	query := self uiRequest: promptString initialAnswer: ''.
	(query isNil or: [ query trimBoth isEmpty ]) ifTrue: [ ^ self ].
	scope := self selectHierarchyBrowseScope.
	scope ifNil: [ ^ self ].
	references := [
		self
			hierarchyQueryReferencesFor: query trimBoth
			mode: modeString
			inSession: session
			rootClassName: className trimBoth
			scope: scope ]
		on: Error
		do: [ :ex |
			UIManager default inform: 'Browse hierarchy query failed: ', ex messageText.
			#() ].
	references isEmpty ifTrue: [
		UIManager default inform: 'No matches found.'.
		^ self ].
	sessionPart := (session respondsTo: #sessionId)
		ifTrue: [ 'Session ', session sessionId asString, ' ' ]
		ifFalse: [ '' ].
	scopeLabel := scope = 'super'
		ifTrue: [ ' (superclasses)' ]
		ifFalse: [ scope = 'this'
			ifTrue: [ ' (this class)' ]
			ifFalse: [ scope = 'sub'
				ifTrue: [ ' (subclasses)' ]
				ifFalse: [ '' ] ] ].
	title := sessionPart, titlePrefixString, query trimBoth, scopeLabel, ' (', references size asString, ')'.
	[ self openQueryResultsPresenterOn: session references: references title: title ]
		on: Error
		do: [ :ex | UIManager default inform: 'Could not open query results window: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> performBrowseQueryWithPrompt: promptString mode: modeString titlePrefix: titlePrefixString [
	| session query references presenterClass sessionPart title |
	query := UIManager default request: promptString initialAnswer: ''.
	(query isNil or: [ query trimBoth isEmpty ]) ifTrue: [ ^ self ].
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	references := [ self queryOrganizerMethodsFor: query trimBoth mode: modeString inSession: session ]
		on: Error
		do: [ :ex |
			UIManager default inform: 'Browse query failed: ', ex messageText.
			#() ].
	references isEmpty ifTrue: [
		UIManager default inform: 'No matches found.'.
		^ self ].
	presenterClass := Smalltalk at: #GbsMethodQueryResultsPresenter ifAbsent: [ nil ].
	presenterClass ifNil: [
		UIManager default inform: 'Could not open query results window: GbsMethodQueryResultsPresenter is not loaded.'.
		^ self ].
	sessionPart := (session respondsTo: #sessionId)
		ifTrue: [ 'Session ', session sessionId asString, ' ' ]
		ifFalse: [ '' ].
	title := sessionPart, titlePrefixString, query trimBoth, ' (', references size asString, ')'.
	[ presenterClass openOn: session references: references title: title ]
		on: Error
		do: [ :ex | UIManager default inform: 'Could not open query results window: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> queryOrganizerMethodsFor: tokenString mode: modeString inSession: aSession [
	| escapedToken escapedMode script raw |
	escapedToken := tokenString copyReplaceAll: '''' with: ''''''.
	escapedMode := modeString copyReplaceAll: '''' with: ''''''.
	script := '[
		| token mode org methods searchResults stream |
		token := ''', escapedToken, '''.
		mode := ''', escapedMode, '''.
		org := ClassOrganizer new.
		methods := #().
		mode = ''implementors'' ifTrue: [
			methods := [ org implementorsOf: token asSymbol ] on: Error do: [ #() ] ].
		mode = ''senders'' ifTrue: [
			searchResults := [ org sendersOf: token asString ] on: Error do: [ #() ].
			methods := (searchResults isArray and: [ searchResults isEmpty not ])
				ifTrue: [ searchResults first ]
				ifFalse: [ searchResults ] ].
		mode = ''references'' ifTrue: [
			searchResults := [ org referencesTo: token asSymbol ] on: Error do: [ #() ].
			methods := (searchResults isArray and: [ searchResults isEmpty not ])
				ifTrue: [ searchResults first ]
				ifFalse: [ searchResults ] ].
		stream := WriteStream on: String new.
		(methods ifNil: [ #() ]) do: [ :m |
			| cls sel |
			cls := [ m inClass name asString ] on: Error do: [ '''' ].
			sel := [ m selector asString ] on: Error do: [ '''' ].
			(cls isEmpty or: [ sel isEmpty ]) ifFalse: [
				stream nextPutAll: cls; nextPutAll: ''>>''; nextPutAll: sel; lf ] ].
		stream contents
	] value'.
	raw := [ aSession executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	raw := raw ifNil: [ '' ] ifNotNil: [ raw asString ].
	^ ((raw splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty) asSet asArray asSortedCollection asArray
]

{ #category : 'menus' }
GbsClassicLauncher class >> removeInvalidConnectors [
	| mgr |
	mgr := Smalltalk at: #GbsSessionManager ifAbsent: [ nil ].
	(mgr isNil or: [ mgr respondsTo: #removeInvalidConnectors not ]) ifTrue: [
		^ UIManager default inform: 'Connector manager unavailable.' ].
	[
		mgr removeInvalidConnectors.
		UIManager default inform: 'Removed invalid connectors.'
	] on: Error do: [ :ex |
		UIManager default inform: 'Remove invalid connectors failed: ', ex messageText ].
]

{ #category : 'menus' }
GbsClassicLauncher class >> selectFileInReference [
	| presenter selected path |
	presenter := Smalltalk at: #StOpenFilePresenter ifAbsent: [ nil ].
	presenter ifNotNil: [
		selected := [
			| dlg result |
			dlg := presenter new.
			(dlg respondsTo: #title:) ifTrue: [ dlg title: 'Select GemStone file in script' ].
			(dlg respondsTo: #extensions:named:)
				ifTrue: [ dlg extensions: #( 'st' ) named: 'Smalltalk source (*.st)' ].
			result := dlg openModal.
			result
		] on: Error do: [ nil ].
		selected ifNotNil: [
			(selected isCollection and: [ selected isEmpty not ])
				ifTrue: [ ^ selected first asFileReference ].
			(selected respondsTo: #asFileReference)
				ifTrue: [ ^ selected asFileReference ] ] ].

	path := UIManager default
		request: 'Path to .st file to evaluate on GemStone:'
		initialAnswer: ''.
	(path isNil or: [ path isEmpty ]) ifTrue: [ ^ nil ].
	^ path asFileReference
]

{ #category : 'menus' }
GbsClassicLauncher class >> selectHierarchyBrowseScope [
	| labels idx |
	labels := #('Full Hierarchy' 'Superclasses' 'This Class' 'Subclasses').
	idx := self uiChooseFrom: labels title: 'Hierarchy Scope'.
	idx = 0 ifTrue: [ ^ nil ].
	idx = 2 ifTrue: [ ^ 'super' ].
	idx = 3 ifTrue: [ ^ 'this' ].
	idx = 4 ifTrue: [ ^ 'sub' ].
	^ 'full'
]

{ #category : 'menus' }
GbsClassicLauncher class >> showConnectorClassMappingsOnCurrentSession [
	| session mgr text |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	mgr := Smalltalk at: #GbsSessionManager ifAbsent: [ nil ].
	(mgr isNil or: [ mgr respondsTo: #connectorClassMappingReportText not ]) ifTrue: [
		^ UIManager default inform: 'Connector manager unavailable.' ].
	text := [
		mgr connectorClassMappingReportText ]
		on: Error
		do: [ :ex | 'Failed to build connector class mapping report: ', ex messageText ].
	UIManager default edit: text label: 'Connector Class Mappings'
]

{ #category : 'menus' }
GbsClassicLauncher class >> uiChooseFrom: labels title: titleString [
	^ UIManager default chooseFrom: labels title: titleString
]

{ #category : 'menus' }
GbsClassicLauncher class >> uiRequest: promptString initialAnswer: defaultString [
	^ UIManager default request: promptString initialAnswer: defaultString
]

{ #category : 'actions' }
GbsClassicLauncher >> browseHierarchyImplementors [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	^ [
		self class
			performBrowseHierarchyQueryWithPrompt: 'Hierarchy implementors of selector:'
			mode: 'hierarchyImplementors'
			titlePrefix: 'Hierarchy Implementors of '.
		true ]
		on: Error
		do: [ :ex | self inform: 'Browse hierarchy implementors failed: ', ex messageText. false ]
]

{ #category : 'actions' }
GbsClassicLauncher >> browseHierarchySenders [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	^ [
		self class
			performBrowseHierarchyQueryWithPrompt: 'Hierarchy senders of selector:'
			mode: 'hierarchySenders'
			titlePrefix: 'Hierarchy Senders of '.
		true ]
		on: Error
		do: [ :ex | self inform: 'Browse hierarchy senders failed: ', ex messageText. false ]
]

{ #category : 'actions' }
GbsClassicLauncher >> browseImplementors [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	^ [
		self class
			performBrowseQueryWithPrompt: 'Implementors of selector:'
			mode: 'implementors'
			titlePrefix: 'Implementors of '.
		true ]
		on: Error
		do: [ :ex | self inform: 'Browse implementors failed: ', ex messageText. false ]
]

{ #category : 'actions' }
GbsClassicLauncher >> browseMethodsWithSubstring [
	| browser |
	browser := self openBrowserForQuery.
	browser ifNil: [ ^ false ].
	^ [ browser queryMethodsWithString ]
		on: Error
		do: [ :ex |
			self inform: 'Browse methods-with-substring failed: ', ex messageText.
			false ]
]

{ #category : 'actions' }
GbsClassicLauncher >> browseReferences [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	^ [
		self class
			performBrowseQueryWithPrompt: 'References to class or variable name:'
			mode: 'references'
			titlePrefix: 'References to '.
		true ]
		on: Error
		do: [ :ex | self inform: 'Browse references failed: ', ex messageText. false ]
]

{ #category : 'actions' }
GbsClassicLauncher >> browseSenders [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	^ [
		self class
			performBrowseQueryWithPrompt: 'Senders of selector:'
			mode: 'senders'
			titlePrefix: 'Senders of '.
		true ]
		on: Error
		do: [ :ex | self inform: 'Browse senders failed: ', ex messageText. false ]
]

{ #category : 'private' }
GbsClassicLauncher >> browserClass [
	^ GbsBrowser
]

{ #category : 'private' }
GbsClassicLauncher >> browsingSessionFrom: selectedObject [
	"Classic launcher list can contain parameter records, but browsers need a live GbsSession."
	selectedObject ifNil: [ ^ nil ].
	(selectedObject respondsTo: #executeAndFetch:) ifTrue: [ ^ selectedObject ].
	(selectedObject class name = #GbsSessionParameters)
		ifTrue: [ ^ GbsSessionParameters currentSession ].
	^ GbsSessionParameters currentSession
]

{ #category : 'menus' }
GbsClassicLauncher >> buildMenuBar [
    ^ self newMenuBar
        addGroup: [ :group |
            group
                addItem: [ :item | item name: 'Browse'; subMenu: self menuBrowse ];
                addItem: [ :item | item name: 'Parameters'; subMenu: self menuParameters ];
                addItem: [ :item | item name: 'Session'; subMenu: self menuSession ];
                addItem: [ :item | item name: 'Tools'; subMenu: self menuTools ];
                addItem: [ :item | item name: 'Window'; subMenu: self menuWindow ];
                addItem: [ :item | item name: 'About'; action: [ self inform: 'GBS Classic Launcher for Pharo' ] ]
        ].
]

{ #category : 'initialization' }
GbsClassicLauncher >> connectPresenters [
	"Ensure your commit and abort buttons fire the new logic"
	btnCommit action: [ self doCommit ].
	btnAbort action: [ self doAbort ].
	
	"Also keep any other button wirings you already had here for btnLoginLink, btnAdd, etc..."

]

{ #category : 'layout' }
GbsClassicLauncher >> defaultLayout [
    | topButtons bottomButtons topHalf bottomHalf |
    
    "1. Group the upper buttons together"
    topButtons := SpBoxLayout newLeftToRight
        add: btnLoginLink;
        add: btnLoginRpc;
        add: btnAdd;
        add: btnCopy;
        add: btnEdit;
        add: btnDelete;
        spacing: 5;
        yourself.

    "2. Group the bottom buttons"
    bottomButtons := SpBoxLayout newLeftToRight
        add: btnCommit;
        add: btnLogout;
        add: btnAbort;
        add: btnCurrent;
        add: btnBegin;
        add: btnBreak;
        spacing: 5;
        yourself.

    "3. Group the Top Section (keeps label, list, and buttons tight together)"
    topHalf := SpBoxLayout newTopToBottom
        add: 'Session Parameters' expand: false;
        add: parametersList;
        add: topButtons expand: false;
        yourself.

    "4. Group the Bottom Section (keeps label, list, and buttons tight together)"
    bottomHalf := SpBoxLayout newTopToBottom
        add: 'Active Sessions' expand: false;
        add: sessionList;
        add: bottomButtons expand: false;
        yourself.

    "5. Main Layout: Adds a 10px gap ONLY between the main sections"
    ^ SpBoxLayout newTopToBottom
        spacing: 10;
        add: mainMenu expand: false;
        add: topHalf;       "Gap above 'Session Parameters'"
        add: bottomHalf;    "Gap above 'Active Sessions'"
        yourself
]

{ #category : 'actions' }
GbsClassicLauncher >> doAbort [
	self withSelectedSession: [ :session |
		session abort.
		self inform: 'GemStone: Transaction Aborted and Synced.'.
	].
]

{ #category : 'actions' }
GbsClassicLauncher >> doAddParameter [
	| newParam editor window |
	newParam := GbsSessionParameters new.
	editor := GbsSessionParametersEditor new.
	editor setModel: newParam.
	
	"Pass the save action to the editor"
	editor onAccept: [ 
		GbsSessionParameters addParameter: newParam.
		self refreshAll.
	].
	
	"Open as a standard window (No double buttons)"
	window := editor open.
	window centered.
]

{ #category : 'actions' }
GbsClassicLauncher >> doBegin [
    self withSelectedSession: [ :s | 
        s beginTransaction. 
        self inform: 'Manual Transaction Started'. 
    ].
]

{ #category : 'actions' }
GbsClassicLauncher >> doBreak [
    self withSelectedSession: [ :s | 
        s sendInterrupt. 
        self inform: 'Interrupt Signal Sent'. 
    ].
]

{ #category : 'actions' }
GbsClassicLauncher >> doCommit [
	self withSelectedSession: [ :session |
		session commitTransaction
			ifTrue: [ self inform: 'GemStone: Commit Successful!' ]
			ifFalse: [ self inform: 'GemStone: Commit Failed (Conflict)!' ]
	].
]

{ #category : 'actions' }
GbsClassicLauncher >> doCopyParameter [
    parametersList selection selectedItem ifNotNil: [ :param |
        | newParam |
        newParam := param copy.
        newParam name: param name, ' (copy)'.
        GbsSessionParameters addParameter: newParam.
        self refreshAll.
    ].
]

{ #category : 'actions' }
GbsClassicLauncher >> doDeleteParameter [
    parametersList selection selectedItem ifNotNil: [ :param |
        GbsSessionParameters removeParameter: param.
        self refreshAll.
    ].
]

{ #category : 'actions' }
GbsClassicLauncher >> doEditParameter [
	parametersList selection selectedItem ifNotNil: [ :param |
		| editor window |
		editor := GbsSessionParametersEditor new.
		editor setModel: param.
		
		editor onAccept: [ 
			self refreshAll. 
		].
		
		window := editor open.
		window centered.
	].
]

{ #category : 'actions' }
GbsClassicLauncher >> doLoginRpc [
	| session |
    parametersList selection selectedItem ifNotNil: [ :params |
        
        "Show progress"
        UIManager default showWaitCursorWhile: [ 
            [
                "Use the SELECTED object to login"
                session := params login.
                
                "Update the UI"
                self refreshAll.
                
                params isConnected 
                    ifTrue: [ 
                        GbsSessionParameters currentSession: session.
                        self inform: 'Login Successful: ', params name 
                    ].
                
            ] on: Error do: [ :ex | 
                self inform: 'Login Error: ', ex messageText.
                ex inspect. 
            ]
        ].
    ] ifNil: [ self inform: 'Please select a configuration first.' ].
]

{ #category : 'actions' }
GbsClassicLauncher >> doLogout [
	| session |
	session := self selectedSessionForLogout.
	session ifNil: [ ^ self inform: 'Please select a session from the list.' ].

	"Unselect first to prevent SubscriptOutOfBounds in Spec2"
	(sessionList respondsTo: #unselectAll) ifTrue: [ sessionList unselectAll ].

	[ session logout ] on: Error do: [ :ex |
		self inform: 'Error logging out: ', ex messageText.
		^ false
	].

	"Clear global current session if it matches, or if it is the simple-launcher session name."
	((GbsSessionParameters currentSession == session)
		or: [ (session respondsTo: #name) and: [ session name = 'Simple Launcher Session' ] ])
		ifTrue: [ GbsSessionParameters currentSession: nil ].

	"Sync all open launchers."
	UIManager default defer: [
		GbsLauncher allInstancesDo: [ :launcher | launcher updateUIState ].
		GbsClassicLauncher allInstancesDo: [ :launcher | launcher refreshAll ].
	].
	^ true
]

{ #category : 'initialization' }
GbsClassicLauncher >> initializePresenters [
    mainMenu := self buildMenuBar.
    
    "Lists"
    parametersList := self newTable.
    parametersList addColumn: (SpStringTableColumn title: 'Name' evaluated: #name).
    parametersList beSingleSelection.

    sessionList := self newTable.
    sessionList
        addColumn: (SpStringTableColumn title: 'Session ID' evaluated: [ :s | s sessionId asString ]);
        addColumn: (SpStringTableColumn title: 'Name' evaluated: [ :s | s name ]);
        addColumn: (SpStringTableColumn title: 'State' evaluated: [ :s | s isConnected ifTrue: ['Connected'] ifFalse: ['Disconnected'] ]).
    sessionList beSingleSelection.

    "Buttons"
    btnLoginLink := self newButton label: 'Login Link'; icon: (self iconNamed: #glamorousGo); action: [ self doLoginRpc ].
    btnLoginRpc  := self newButton label: 'Login RPC'; icon: (self iconNamed: #glamorousGo); action: [ self doLoginRpc ].
    btnAdd       := self newButton label: 'Add...'; icon: (self iconNamed: #add); action: [ self doAddParameter ].
    btnCopy      := self newButton label: 'Copy'; icon: (self iconNamed: #smallCopy); action: [ self doCopyParameter ].
    btnEdit      := self newButton label: 'Edit...'; icon: (self iconNamed: #edit); action: [ self doEditParameter ].
    btnDelete    := self newButton label: 'Delete'; icon: (self iconNamed: #delete); action: [ self doDeleteParameter ].

    btnCommit := self newButton label: 'Commit'; icon: (self iconNamed: #smallSave); action: [ self doCommit ].
    btnLogout := self newButton label: 'Logout'; icon: (self iconNamed: #smallCancel); action: [ self doLogout ].
    btnAbort  := self newButton label: 'Abort'; icon: (self iconNamed: #smallDelete); action: [ self doAbort ].
    btnCurrent:= self newButton label: 'Current'; icon: (self iconNamed: #smallForward); action: [ self makeCurrent ].
    btnBegin  := self newButton label: 'Begin'; icon: (self iconNamed: #smallUpdate); action: [ self doBegin ].
    btnBreak  := self newButton label: 'Break'; icon: (self iconNamed: #smallCancel); action: [ self doBreak ].

    "--> Wire up the click events to update button states <--"
    parametersList whenSelectionChangedDo: [ :selection | self updateButtonStates ].
    sessionList whenSelectionChangedDo: [ :selection | self updateButtonStates ].

    "--> DOUBLE CLICK ACTION <--"
    sessionList whenActivatedDo: [ :selection | self openWorkspaceFor: selection selectedItem ].

    self refreshAll.
]

{ #category : 'initialization' }
GbsClassicLauncher >> initializeWindow: aWindow [
	aWindow 
		title: 'GemStone Launcher';
		initialExtent: 500@400;
		whenClosedDo: [ self stopPolling ].
	self startPolling.

]

{ #category : 'private' }
GbsClassicLauncher >> isSessionUsableForBrowsing: aSession [
	aSession ifNil: [ ^ false ].
	(aSession respondsTo: #isLoggedIn)
		ifTrue: [ ^ [ aSession isLoggedIn == true ] on: Error do: [ false ] ].
	^ true
]

{ #category : 'actions' }
GbsClassicLauncher >> makeCurrent [
    self withSelectedSession: [ :s | 
        GbsSessionParameters currentSession: s.
        self inform: 'Session set as Current'.
        self refreshSessionList.
    ].
]

{ #category : 'menus' }
GbsClassicLauncher >> menuBrowse [
    ^ self newMenu
        addItem: [ :item | item name: 'All Classes'; action: [ UIManager default defer: [ self openSystemBrowser ] ] ];
        addItem: [ :item | item name: 'Class...'; action: [ UIManager default defer: [ self openClassBrowser ] ] ];
        addItem: [ :item | item name: 'Namespace...'; action: [ UIManager default defer: [ self openSymbolDictionaryBrowser ] ] ];
        addItem: [ :item | item name: 'Senders of...'; action: [ UIManager default defer: [ self browseSenders ] ] ];
        addItem: [ :item | item name: 'Implementors of...'; action: [ UIManager default defer: [ self browseImplementors ] ] ];
        addItem: [ :item | item name: 'Hierarchy Senders of...'; action: [ UIManager default defer: [ self browseHierarchySenders ] ] ];
        addItem: [ :item | item name: 'Hierarchy Implementors of...'; action: [ UIManager default defer: [ self browseHierarchyImplementors ] ] ];
        addItem: [ :item | item name: 'References to...'; action: [ UIManager default defer: [ self browseReferences ] ] ];
        addItem: [ :item | item name: 'Methods with substring...'; action: [ UIManager default defer: [ self browseMethodsWithSubstring ] ] ];
        yourself.
]

{ #category : 'menus' }
GbsClassicLauncher >> menuParameters [
    ^ self newMenu
        addItem: [ :item | item name: 'Add...'; action: [ self inform: 'Add Parameter' ] ];
        addItem: [ :item | item name: 'Edit'; action: [ self inform: 'Edit Parameter' ] ];
        addItem: [ :item | item name: 'Delete'; action: [ self inform: 'Delete Parameter' ] ];
        yourself.
]

{ #category : 'menus' }
GbsClassicLauncher >> menuSession [
    ^ self newMenu
        addItem: [ :item | item name: 'Login'; action: [ self inform: 'Use the main Launcher to create sessions' ] ];
        addItem: [ :item | item name: 'Logout'; action: [ self doLogout ] ];
        addItem: [ :item | item name: 'Commit'; action: [ self doCommit ] ];
        addItem: [ :item | item name: 'Abort'; action: [ self doAbort ] ];
        yourself.
]

{ #category : 'menus' }
GbsClassicLauncher >> menuTools [
    ^ self newMenu
        addItem: [ :item | 
            item name: 'Workspace'; 
            action: [ GbsWorkspace new open ] ];

        addItem: [ :item | 
            item name: 'Transcript'; 
            action: [ 
                | transcriptPresenter |
                transcriptPresenter := GbsRemoteTranscript new.
                transcriptPresenter open.
                transcriptPresenter startPolling.
            ] ];
        addItem: [ :item | item name: 'Toggle Polling'; action: [ GbsSessionParameters togglePolling. self refreshAll ] ];
        yourself.
]

{ #category : 'menus' }
GbsClassicLauncher >> menuWindow [
    ^ self newMenu
        addItem: [ :item | item name: 'Refresh'; action: [ self refreshSessionList ] ];
        addItem: [ :item | item name: 'Close'; action: [ self delete ] ];
        yourself.
]

{ #category : 'private' }
GbsClassicLauncher >> openBrowserForQuery [
	| session browser |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ nil
	].
	GbsSessionParameters currentSession: session.
	browser := [ self browserClass openOn: session ] on: Error do: [ :ex |
		self inform: 'Could not open browser: ', ex messageText.
		nil
	].
	^ browser
]

{ #category : 'private' }
GbsClassicLauncher >> openBrowserOn: aSession dictionary: aDictionaryName [
	| browser |
	(self isSessionUsableForBrowsing: aSession) ifFalse: [ ^ false ].
	((aSession respondsTo: #executeAndFetch:) not) ifTrue: [
		self inform: 'Selected item is not a live GemStone session.'.
		^ false
	].
	[
		browser := self browserClass openOn: aSession.
		(browser notNil
			and: [ aDictionaryName isString
			and: [ aDictionaryName isEmpty not
			and: [ browser respondsTo: #selectDictionaryNamed: ] ] ])
			ifTrue: [ browser selectDictionaryNamed: aDictionaryName ].
		^ browser notNil
	] on: Error do: [ :ex |
		self inform: 'Could not open browser: ', ex messageText.
		^ false
	]
]

{ #category : 'actions' }
GbsClassicLauncher >> openClassBrowser [
	| session className browser |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false
	].
	className := UIManager default request: 'Class name:' initialAnswer: ''.
	(className isNil or: [ className trimBoth isEmpty ]) ifTrue: [ ^ false ].
	GbsSessionParameters currentSession: session.
	browser := self openBrowserOn: session dictionary: nil.
	browser ifFalse: [ ^ false ].
	^ [ (browser
		selectClassNamed: className trimBoth
		classSide: false
		method: nil)
		ifTrue: [
			(browser respondsTo: #browseClass)
				ifTrue: [ browser browseClass ].
			(browser respondsTo: #focusClasses)
				ifTrue: [ UIManager default defer: [ browser focusClasses ] ].
			true ]
		ifFalse: [ false ] ] on: Error do: [ false ]
]

{ #category : 'actions' }
GbsClassicLauncher >> openSymbolDictionaryBrowser [
	| session dictName |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false
	].
	dictName := self requestSymbolDictionaryName.
	GbsSessionParameters currentSession: session.
	self openBrowserOn: session dictionary: dictName.
	^ true
]

{ #category : 'actions' }
GbsClassicLauncher >> openSystemBrowser [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false
	].
	GbsSessionParameters currentSession: session.
	self openBrowserOn: session dictionary: nil.
	^ true
]

{ #category : 'actions' }
GbsClassicLauncher >> openWorkspaceFor: aSession [
    aSession ifNil: [ ^ self ].
    
    "1. Ensure this session is the active one globally before opening tools"
    GbsSessionParameters currentSession: aSession.
    self refreshAll.
    
    "2. Open the Workspace"
    GbsWorkspace new open.
]

{ #category : 'actions' }
GbsClassicLauncher >> refreshAll [
    "Use asArray so Spec2 sees a NEW collection and forces a visual refresh"
    parametersList items: GbsSessionParameters allParameters asArray.
    sessionList items: GbsSessionParameters allSessions asArray.
    
    "Safely re-select the current session if it still exists"
    GbsSessionParameters currentSession ifNotNil: [ :current |
        (GbsSessionParameters allSessions includes: current) ifTrue: [ 
            sessionList selectItem: current 
        ]
    ].
    
    self updateButtonStates.
]

{ #category : 'actions' }
GbsClassicLauncher >> refreshSessionList [
    sessionList items: GbsSessionParameters allSessions.
    parametersList items: GbsSessionParameters allParameters. "Assuming this collection exists"
    GbsSessionParameters currentSession ifNotNil: [ :s | sessionList selectItem: s ].
]

{ #category : 'private' }
GbsClassicLauncher >> requestSymbolDictionaryName [
	^ UIManager default
		request: 'Symbol Dictionary name (optional):'
		initialAnswer: ''
]

{ #category : 'private' }
GbsClassicLauncher >> selectedSessionForLogout [
	| selected |
	selected := nil.
	(sessionList notNil and: [ sessionList respondsTo: #selection ]) ifTrue: [
		selected := [ sessionList selection selectedItem ] on: Error do: [ nil ]
	].
	^ selected ifNil: [ GbsSessionParameters currentSession ]
]

{ #category : 'private' }
GbsClassicLauncher >> sessionForBrowsing [
	| selected |
	selected := nil.
	(sessionList notNil and: [ sessionList respondsTo: #selection ]) ifTrue: [
		selected := [ sessionList selection selectedItem ] on: Error do: [ nil ]
	].
	selected := selected ifNil: [ GbsSessionParameters currentSession ].
	^ self browsingSessionFrom: selected
]

{ #category : 'polling' }
GbsClassicLauncher >> startPolling [ 
    pollingProcess ifNotNil: [ pollingProcess terminate ].
    pollingProcess := [ 
        [ self window isNotNil and: [ self window isOpen ] ] whileTrue: [ 
            GbsSessionParameters pollingEnabled ifTrue: [ UIManager default defer: [ self refreshAll ] ].
            (Delay forSeconds: 2) wait.
        ] 
    ] fork.


]

{ #category : 'polling' }
GbsClassicLauncher >> stopPolling [ 
    pollingProcess ifNotNil: [ pollingProcess terminate ].
    pollingProcess := nil.


]

{ #category : 'actions' }
GbsClassicLauncher >> updateButtonStates [
    | selectedParam selectedSession |
    
    selectedParam := parametersList selection selectedItem.
    selectedSession := sessionList selection selectedItem.

    "1. Login buttons: Enable only if a parameter is selected AND it is NOT connected"
    (selectedParam notNil and: [ selectedParam isConnected not ])
        ifTrue: [ 
            btnLoginRpc enable. 
            btnLoginLink enable. 
        ]
        ifFalse: [ 
            btnLoginRpc disable. 
            btnLoginLink disable. 
        ].

    "2. Session buttons (Logout, Commit, etc.): Enable only if an active session is selected"
    selectedSession notNil
        ifTrue: [ 
            btnLogout enable. btnCommit enable. btnAbort enable. 
            btnCurrent enable. btnBegin enable. btnBreak enable. 
        ]
        ifFalse: [ 
            btnLogout disable. btnCommit disable. btnAbort disable. 
            btnCurrent disable. btnBegin disable. btnBreak disable. 
        ].
]

{ #category : 'private' }
GbsClassicLauncher >> withSelectedSession: aBlock [
    sessionList selection selectedItem
        ifNotNil: [ :session | aBlock value: session ]
        ifNil: [ self inform: 'Please select a session from the list.' ].
]

{ #category : 'utilities' }
GbsClassicLauncher class >> openTextViewerOn: aString title: aTitle [
	"Open a text viewer/workspace with the given contents"
	| ws |
	ws := GbsWorkspace new.
	ws open.
	ws window title: aTitle.
	ws textEditor text: aString asString
]

{ #category : 'utilities' }
GbsClassicLauncher class >> openFileLoggerOn: aFileLogger title: aTitle [
	"Open a file logger viewer showing current log content"
	| contents |
	
	contents := aFileLogger contents.
	contents ifEmpty: [ contents := '(Log file is empty)' ].
	
	"Show in a multi-line text window"
	[
		UIManager default 
			request: aTitle
			initialAnswer: contents asString
	] on: Error do: [ :ex |
		UIManager default inform: 'Could not open log viewer: ', ex messageText
	]
]

{ #category : 'utilities' }
GbsClassicLauncher class >> clearLogFileWithLogger: aFileLogger [
	"Clear the log file contents"
	(aFileLogger respondsTo: #filename) ifTrue: [
		| fileRef |
		fileRef := aFileLogger filename asFileReference.
		fileRef exists ifTrue: [
			(UIManager default confirm: 'Clear all log entries?') ifTrue: [
				fileRef delete.
				fileRef ensureCreateDirectory.
			]
		]
	]
]

{ #category : 'utilities' }
GbsClassicLauncher class >> refreshLogFileOn: textMorph [
	"Manually refresh the log display"
	| newContents |
	newContents := (textMorph textProvider respondsTo: #contents) 
		ifTrue: [ textMorph textProvider contents ]
		ifFalse: [ '' ].
	textMorph text: newContents asText.
	textMorph textArea scrollToEnd.
]

{ #category : 'utilities' }
GbsClassicLauncher class >> closeFileLoggerWindow: window [
	"Close the file logger window"
	window delete
]
