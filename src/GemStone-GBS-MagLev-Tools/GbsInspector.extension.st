Extension { #name : 'GbsInspector' }

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsInspector >> addExtensionReportOptionsToLabels: labels actions: actions [
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
GbsInspector >> browseRubyLoadPathReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session rubyRuntime loadPathReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsInspector >> browseRubyLoadedFeaturesReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session rubyRuntime loadedFeaturesReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsInspector >> browseRubyPersistentLoadedFeaturesReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session rubyRuntime persistentLoadedFeaturesReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsInspector >> browseTopLevelAutoloadRegistrationsReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [
		session rubyRuntime
			autoloadRegistrationsReportTextForNamespace: session topLevelNamespaceMirror ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsInspector >> browseMaglevFinalizerRegistryReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [
		session objectSpaceDiagnostics finalizerRegistryReport text ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsInspector >> invocationArgumentsForMethodObject: aMethodObject [
	| argumentCount input |
	aMethodObject ifNil: [ ^ nil ].
	argumentCount := aMethodObject selector numArgs.
	argumentCount = 0 ifTrue: [ ^ #() ].
	input := self
		requestInput: (GbsRemoteMethodObject
			invocationPromptForSelector: aMethodObject selector
			argumentCount: argumentCount)
		initialAnswer: (GbsRemoteMethodObject defaultArgumentInputForCount: argumentCount).
	input ifNil: [ ^ nil ].
	^ GbsRemoteMethodObject
		argumentsFromInput: input
		expectedCount: argumentCount
]
