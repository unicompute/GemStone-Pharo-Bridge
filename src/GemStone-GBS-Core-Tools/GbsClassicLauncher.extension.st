Extension { #name : 'GbsClassicLauncher' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher class >> inspectCurrentUserGlobalsOnCurrentSession [
	| session userGlobals oop |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	userGlobals := [ session namedObjectAt: #UserGlobals ifAbsent: [ nil ] ]
		on: Error
		do: [ nil ].
	oop := (userGlobals isKindOf: GbsProxy)
		ifTrue: [ userGlobals oop ]
		ifFalse: [ nil ].
	(oop isNumber and: [ oop > 20 ]) ifFalse: [
		UIManager default inform: 'Could not inspect current UserGlobals.'.
		^ self ].
	[
		GbsInspector inspect: oop session: session
	] on: Error do: [ :ex |
		UIManager default inform: 'Could not open UserGlobals inspector: ', ex messageText ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher class >> openNamespacesOnCurrentSession [
	| session presenterClass |
	session := self currentSessionOrInform.
	session ifNil: [ ^ self ].
	presenterClass := Smalltalk at: #GbsNamespacesPresenter ifAbsent: [ nil ].
	presenterClass ifNil: [
		UIManager default inform: 'Could not open namespaces tool: GbsNamespacesPresenter is not loaded.'.
		^ self ].
	[
		presenterClass openOn: session
	] on: Error do: [ :ex |
		UIManager default inform: 'Could not open namespaces tool: ', ex messageText
	].
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher class >> queryOrganizerMethodsFor: tokenString mode: modeString inSession: aSession [
	| raw normalized escapedToken escapedMode script |
	modeString = 'implementors' ifTrue: [
		(aSession respondsTo: #implementorMethodReferenceStringsForSelector:)
			ifTrue: [
				raw := aSession implementorMethodReferenceStringsForSelector: tokenString.
				normalized := GbsMethodQueryResultsPresenter new normalizeReferences: raw.
				normalized isEmpty ifFalse: [ ^ normalized ] ] ].
	modeString = 'senders' ifTrue: [
		(aSession respondsTo: #senderMethodReferenceStringsForSelector:)
			ifTrue: [
				raw := aSession senderMethodReferenceStringsForSelector: tokenString.
				normalized := GbsMethodQueryResultsPresenter new normalizeReferences: raw.
				normalized isEmpty ifFalse: [ ^ normalized ] ] ].
	modeString = 'references' ifTrue: [
		(aSession respondsTo: #methodReferenceStringsToSymbol:)
			ifTrue: [
				raw := aSession methodReferenceStringsToSymbol: tokenString.
				normalized := GbsMethodQueryResultsPresenter new normalizeReferences: raw.
				normalized isEmpty ifFalse: [ ^ normalized ] ] ].
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

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> browseNamedObjectCacheReport [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	self inform: session namedObjectCacheReportText.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> browseTypedWrapperAutoloadReport [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	self inform: (GbsSessionManager typedWrapperAutoloadReportTextForSession: session).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> browseTypedWrapperLifecycleReport [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	self inform: session typedWrapperLifecycleReportText.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> browseStaleTypedWrapperLifecycleReport [
	| session report staleEntries |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	report := session typedWrapperLifecycleReport.
	staleEntries := report staleEntries.
	staleEntries isEmpty ifTrue: [
		self inform: 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.'.
		^ true ].
	self inform: (GbsTypedWrapperLifecycleReport entries: staleEntries) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> browseSessionStateReport [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	self inform: (session objectSpaceDiagnostics reportTextForKeys: #(19)).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> browsePromptedSessionStateKeysReport [
	| session rawKeys keys |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	rawKeys := self class uiRequest: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	self inform: (session objectSpaceDiagnostics reportTextForKeys: keys).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> browseObjectsInMemoryReport [
	| session start limit |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ false ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ false ].
	GbsSessionParameters currentSession: session.
	self inform: (session objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> refreshAllTypedWrappers [
	| session refreshed |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	refreshed := session refreshAllTypedWrapperClasses.
	self inform: 'Refreshed ', refreshed size printString, ' typed wrapper(s).'.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> refreshStaleTypedWrappers [
	| session refreshed |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	refreshed := session refreshStaleTypedWrapperClasses.
	self inform: 'Refreshed ', refreshed size printString, ' stale typed wrapper(s).'.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> inspectPromptedSessionStateKey [
	| rawKey key |
	rawKey := self class uiRequest: 'Session state key:' initialAnswer: '19'.
	(rawKey isNil or: [ rawKey trimBoth isEmpty ]) ifTrue: [ ^ false ].
	key := [ rawKey trimBoth asInteger ]
		on: Error
		do: [ nil ].
	key ifNil: [
		self inform: 'Enter a numeric session state key.'.
		^ false ].
	^ self inspectSessionStateAtKey: key
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> inspectSessionStateAtKey: aKey [
	| session sessionStateValue oop |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	sessionStateValue := [ session sessionStateAt: aKey ]
		on: Error
		do: [ :ex |
			self inform: 'Session state lookup failed: ', ex messageText.
			^ false ].
	sessionStateValue ifNil: [
		self inform: 'Session state key ', aKey printString, ' is not set.'.
		^ false ].
	oop := self oopForInspectableObject: sessionStateValue.
	oop ifNil: [
		self inform: 'Session state key ', aKey printString, ' does not currently have an inspectable remote oop.'.
		^ false ].
	self inspectOop: oop session: session.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> clearNamedObjectCache [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	session clearNamedObjectCache.
	self inform: 'Named object cache cleared.'.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> menuSession [
	| menu |
	menu := self newMenu
		addItem: [ :item | item name: 'Login'; action: [ self inform: 'Use the main Launcher to create sessions' ] ];
		addItem: [ :item | item name: 'Logout'; action: [ self doLogout ] ];
		addItem: [ :item | item name: 'Commit'; action: [ self doCommit ] ];
		addItem: [ :item | item name: 'Abort'; action: [ self doAbort ] ];
		addItem: [ :item | item name: 'Named Object Cache Report'; action: [ self browseNamedObjectCacheReport ] ];
		addItem: [ :item | item name: 'Clear Named Object Cache'; action: [ self clearNamedObjectCache ] ];
		addItem: [ :item | item name: 'Typed Wrapper Autoload Report'; action: [ self browseTypedWrapperAutoloadReport ] ];
		addItem: [ :item | item name: 'Typed Wrapper Lifecycle Report'; action: [ self browseTypedWrapperLifecycleReport ] ];
		addItem: [ :item | item name: 'Stale Typed Wrapper Report'; action: [ self browseStaleTypedWrapperLifecycleReport ] ];
		addItem: [ :item | item name: 'Refresh Stale Typed Wrappers'; action: [ self refreshStaleTypedWrappers ] ];
		addItem: [ :item | item name: 'Refresh All Typed Wrappers'; action: [ self refreshAllTypedWrappers ] ];
		addItem: [ :item | item name: 'Session State Report'; action: [ self browseSessionStateReport ] ];
		addItem: [ :item | item name: 'Session State Keys Report...'; action: [ self browsePromptedSessionStateKeysReport ] ];
		addItem: [ :item | item name: 'Objects In Memory Report...'; action: [ self browseObjectsInMemoryReport ] ];
		addItem: [ :item | item name: 'Inspect Session State Key...'; action: [ self inspectPromptedSessionStateKey ] ];
		yourself.
	self addExtensionSessionMenuItemsTo: menu.
	^ menu
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> oopForInspectableObject: anObject [
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #oop) ifTrue: [ ^ anObject oop ].
	(anObject isInteger and: [ anObject > 20 ]) ifTrue: [ ^ anObject ].
	^ nil
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> parseSessionStateKeysFrom: aStringOrNil [
	| trimmed tokens keys |
	(aStringOrNil isNil or: [ aStringOrNil trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	trimmed := aStringOrNil trimBoth.
	tokens := (trimmed findTokens: ',') collect: #trimBoth thenReject: #isEmpty.
	tokens isEmpty ifTrue: [ ^ nil ].
	keys := tokens collect: [ :each |
		[ each asInteger ] on: Error do: [ ^ nil ] ].
	^ keys asArray
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> requestPositiveInteger: promptString initialAnswer: defaultString [
	| rawValue |
	rawValue := self class uiRequest: promptString initialAnswer: defaultString.
	(rawValue isNil or: [ rawValue trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ [ | value |
		value := rawValue trimBoth asInteger.
		value > 0 ifTrue: [ value ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> inspectCurrentUserGlobals [
	| session oop |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false
	].
	oop := self currentUserGlobalsOopIn: session.
	(oop isNumber and: [ oop > 20 ]) ifFalse: [
		self inform: 'Could not inspect current UserGlobals.'.
		^ false
	].
	GbsSessionParameters currentSession: session.
	[
		self inspectOop: oop session: session.
		^ true
	] on: Error do: [ :ex |
		self inform: 'Could not open UserGlobals inspector: ', ex messageText.
		^ false ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> currentUserGlobalsOopIn: aSession [
	| userGlobals |
	userGlobals := [ aSession namedObjectAt: #UserGlobals ifAbsent: [ nil ] ]
		on: Error
		do: [ nil ].
	^ (userGlobals isKindOf: GbsProxy)
		ifTrue: [ userGlobals oop ]
		ifFalse: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsClassicLauncher >> inspectOop: anOop session: aSession [
	GbsInspector inspect: anOop session: aSession
]
