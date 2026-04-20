Extension { #name : 'GbxTrippy' }

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxTrippy >> addExtensionReportOptionsToLabels: labels actions: actions [
	labels
		add: '$LOAD_PATH Report';
		add: 'Loaded Features Report';
		add: 'Persistent Features Report';
		add: 'Top-Level Autoload Report';
		add: 'MagLev Finalizer Registry Report'.
	actions
		add: [ self browseRubyLoadPathReport ];
		add: [ self browseRubyLoadedFeaturesReport ];
		add: [ self browseRubyPersistentLoadedFeaturesReport ];
		add: [ self browseTopLevelAutoloadRegistrationsReport ];
		add: [ self browseMaglevFinalizerRegistryReport ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxTrippy >> browseRubyLoadPathReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session rubyRuntime loadPathReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxTrippy >> browseRubyLoadedFeaturesReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session rubyRuntime loadedFeaturesReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxTrippy >> browseRubyPersistentLoadedFeaturesReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session rubyRuntime persistentLoadedFeaturesReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxTrippy >> browseMaglevFinalizerRegistryReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [
		session objectSpaceDiagnostics finalizerRegistryReport text ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbxTrippy >> browseTopLevelAutoloadRegistrationsReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [
		session rubyRuntime
			autoloadRegistrationsReportTextForNamespace: session topLevelNamespaceMirror ]).
	^ true
]
