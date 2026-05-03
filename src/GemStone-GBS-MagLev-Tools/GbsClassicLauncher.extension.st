Extension { #name : 'GbsClassicLauncher' }

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsClassicLauncher >> addExtensionSessionMenuItemsTo: aMenu [
	aMenu
		addItem: [ :item | item name: '$LOAD_PATH Report'; action: [ self browseRubyLoadPathReport ] ];
		addItem: [ :item | item name: 'Loaded Features Report'; action: [ self browseRubyLoadedFeaturesReport ] ];
		addItem: [ :item | item name: 'Persistent Features Report'; action: [ self browseRubyPersistentLoadedFeaturesReport ] ];
		addItem: [ :item | item name: 'Top-Level Autoload Report'; action: [ self browseTopLevelAutoloadRegistrationsReport ] ];
		addItem: [ :item | item name: 'MagLev Finalizer Registry Report'; action: [ self browseMaglevFinalizerRegistryReport ] ];
		addItem: [ :item | item name: 'Inspect MagLev Finalizers'; action: [ self inspectMaglevFinalizerRegistry ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsClassicLauncher >> browseRubyLoadPathReport [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	self inform: session rubyRuntime loadPathReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsClassicLauncher >> browseRubyLoadedFeaturesReport [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	self inform: session rubyRuntime loadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsClassicLauncher >> browseRubyPersistentLoadedFeaturesReport [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	self inform: session rubyRuntime persistentLoadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsClassicLauncher >> browseTopLevelAutoloadRegistrationsReport [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	self inform: (session rubyRuntime
		autoloadRegistrationsReportTextForNamespace: session topLevelNamespaceMirror).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsClassicLauncher >> browseMaglevFinalizerRegistryReport [
	| session |
	session := self sessionForBrowsing.
	(self isSessionUsableForBrowsing: session) ifFalse: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	GbsSessionParameters currentSession: session.
	self inform: session objectSpaceDiagnostics finalizerRegistryReport text.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsClassicLauncher >> inspectMaglevFinalizerRegistry [
	^ self inspectSessionStateAtKey: 19
]
