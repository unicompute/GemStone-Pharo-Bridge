Extension { #name : 'GbsMethodQueryResultsPresenter' }

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsMethodQueryResultsPresenter >> addExtensionSessionMenuItemsTo: aMenuGroup [
	aMenuGroup addItem: [ :item |
		item
			name: '$LOAD_PATH Report';
			action: [ self browseRubyLoadPathReport ] ].
	aMenuGroup addItem: [ :item |
		item
			name: 'Loaded Features Report';
			action: [ self browseRubyLoadedFeaturesReport ] ].
	aMenuGroup addItem: [ :item |
		item
			name: 'Persistent Features Report';
			action: [ self browseRubyPersistentLoadedFeaturesReport ] ].
	aMenuGroup addItem: [ :item |
		item
			name: 'Top-Level Autoload Report';
			action: [ self browseTopLevelAutoloadRegistrationsReport ] ].
	aMenuGroup addItem: [ :item |
		item
			name: 'Runtime Provenance Graph';
			action: [ self browseRubyRuntimeProvenanceGraph ] ].
	aMenuGroup addItem: [ :item |
		item
			name: 'Runtime Provenance Browser';
			action: [ self browseRubyRuntimeProvenanceBrowser ] ].
	aMenuGroup addItem: [ :item |
		item
			name: 'Runtime Provenance Actions...';
			action: [ self browseRubyRuntimeProvenanceActionChooser ] ].
	aMenuGroup addItem: [ :item |
		item
			name: 'MagLev Finalizer Registry Report';
			action: [ self browseMaglevFinalizerRegistryReport ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsMethodQueryResultsPresenter >> browseRubyLoadPathReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: session rubyRuntime loadPathReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsMethodQueryResultsPresenter >> browseRubyLoadedFeaturesReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: session rubyRuntime loadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsMethodQueryResultsPresenter >> browseRubyPersistentLoadedFeaturesReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: session rubyRuntime persistentLoadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsMethodQueryResultsPresenter >> browseTopLevelAutoloadRegistrationsReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (session rubyRuntime
		autoloadRegistrationsReportTextForNamespace: session topLevelNamespaceMirror).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsMethodQueryResultsPresenter >> browseRubyRuntimeProvenanceGraph [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: session rubyRuntime provenanceGraphText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsMethodQueryResultsPresenter >> browseRubyRuntimeProvenanceBrowser [
	| graph |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	graph := session rubyRuntime provenanceGraph.
	graph isEmpty ifTrue: [
		self inform: graph text.
		^ true ].
	^ self
		openRubyRuntimeProvenanceBrowserFor: graph
		title: 'Ruby Runtime Provenance'
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsMethodQueryResultsPresenter >> browseRubyRuntimeProvenanceActionChooser [
	| graph actions index action result |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	graph := session rubyRuntime provenanceGraph.
	actions := graph actions.
	actions isEmpty ifTrue: [
		self inform: graph text.
		^ true ].
	index := self
		uiChooseFrom: (actions collect: [ :each | each displayString ])
		title: 'Ruby Runtime Provenance Actions'.
	index = 0 ifTrue: [ ^ false ].
	action := actions at: index.
	result := session rubyRuntime executeProvenanceAction: action.
	self inform: (String streamContents: [ :stream |
		stream nextPutAll: 'Executed '; nextPutAll: action displayString.
		result ifNotNil: [
			stream
				nextPutAll: ' => ';
				nextPutAll: result printString ].
		stream cr; cr; nextPutAll: session rubyRuntime provenanceGraphText ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsMethodQueryResultsPresenter >> openRubyRuntimeProvenanceBrowserFor: aGraph title: aTitle [
	| presenterClass |
	presenterClass := Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ].
	presenterClass ifNil: [
		self inform: aGraph text.
		^ true ].
	presenterClass
		openRows: aGraph browserRows
		kind: 'dictionary'
		title: aTitle
		inspectBlock: nil
		rawPrintString: aGraph text
		entryKey: nil
		path: nil
		previewKind: 'provenance'
		previewFetcherBlock: [ :row | aGraph previewForBrowserRow: row ].
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsMethodQueryResultsPresenter >> browseMaglevFinalizerRegistryReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: session objectSpaceDiagnostics finalizerRegistryReport text.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsMethodQueryResultsPresenter >> invocationArgumentsForMethodObject: aMethodObject [
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
