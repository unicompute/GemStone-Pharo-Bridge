Extension { #name : 'GbsSymbolListBrowserPresenter' }

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsSymbolListBrowserPresenter >> addExtensionEntryMenuItemsTo: aMenu [
	aMenu addItem: [ :item |
		item name: '$LOAD_PATH Report'; action: [ self browseRubyLoadPathReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ].
	aMenu addItem: [ :item |
		item name: 'Loaded Features Report'; action: [ self browseRubyLoadedFeaturesReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ].
	aMenu addItem: [ :item |
		item name: 'Persistent Features Report'; action: [ self browseRubyPersistentLoadedFeaturesReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ].
	aMenu addItem: [ :item |
		item name: 'Top-Level Autoload Report'; action: [ self browseTopLevelAutoloadRegistrationsReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ].
	aMenu addItem: [ :item |
		item name: 'MagLev Finalizer Registry Report'; action: [ self browseMaglevFinalizerRegistryReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsSymbolListBrowserPresenter >> addExtensionPreviewMenuItemsTo: aMenu [
	aMenu addItem: [ :item |
		item name: '$LOAD_PATH Report'; action: [ self browseRubyLoadPathReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ].
	aMenu addItem: [ :item |
		item name: 'Loaded Features Report'; action: [ self browseRubyLoadedFeaturesReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ].
	aMenu addItem: [ :item |
		item name: 'Persistent Features Report'; action: [ self browseRubyPersistentLoadedFeaturesReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ].
	aMenu addItem: [ :item |
		item name: 'Top-Level Autoload Report'; action: [ self browseTopLevelAutoloadRegistrationsReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ].
	aMenu addItem: [ :item |
		item name: 'MagLev Finalizer Registry Report'; action: [ self browseMaglevFinalizerRegistryReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsSymbolListBrowserPresenter >> browseRubyLoadPathReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session rubyRuntime loadPathReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsSymbolListBrowserPresenter >> browseRubyLoadedFeaturesReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session rubyRuntime loadedFeaturesReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsSymbolListBrowserPresenter >> browseRubyPersistentLoadedFeaturesReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session rubyRuntime persistentLoadedFeaturesReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsSymbolListBrowserPresenter >> browseTopLevelAutoloadRegistrationsReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [
		session rubyRuntime
			autoloadRegistrationsReportTextForNamespace: session topLevelNamespaceMirror ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsSymbolListBrowserPresenter >> browseMaglevFinalizerRegistryReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [
		session objectSpaceDiagnostics finalizerRegistryReport text ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsSymbolListBrowserPresenter >> configureExtensionStructuredInspector: presenter [
	presenter
		propertyAt: #loadPathReportBlock
		put: [ self withShallowMaterializationDo: [ session rubyRuntime loadPathReportText ] ];
		propertyAt: #loadedFeaturesReportBlock
		put: [ self withShallowMaterializationDo: [ session rubyRuntime loadedFeaturesReportText ] ];
		propertyAt: #persistentFeaturesReportBlock
		put: [ self withShallowMaterializationDo: [ session rubyRuntime persistentLoadedFeaturesReportText ] ];
		propertyAt: #topLevelAutoloadReportBlock
		put: [ self withShallowMaterializationDo: [
			session rubyRuntime
				autoloadRegistrationsReportTextForNamespace: session topLevelNamespaceMirror ] ];
		propertyAt: #finalizerRegistryReportBlock
		put: [ self withShallowMaterializationDo: [
			session objectSpaceDiagnostics finalizerRegistryReport text ] ]
]
