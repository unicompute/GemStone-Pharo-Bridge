Extension { #name : 'GbsStructuredValueInspectorPresenter' }

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsStructuredValueInspectorPresenter >> addExtensionEntryMenuItemsTo: aMenu [
	aMenu addItem: [ :item |
		item name: '$LOAD_PATH Report'; action: [ self browseRubyLoadPathReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #loadPathReportBlock ifAbsent: [ nil ]) notNil ] ].
	aMenu addItem: [ :item |
		item name: 'Loaded Features Report'; action: [ self browseRubyLoadedFeaturesReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #loadedFeaturesReportBlock ifAbsent: [ nil ]) notNil ] ].
	aMenu addItem: [ :item |
		item name: 'Persistent Features Report'; action: [ self browseRubyPersistentLoadedFeaturesReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #persistentFeaturesReportBlock ifAbsent: [ nil ]) notNil ] ].
	aMenu addItem: [ :item |
		item name: 'Top-Level Autoload Report'; action: [ self browseTopLevelAutoloadRegistrationsReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #topLevelAutoloadReportBlock ifAbsent: [ nil ]) notNil ] ].
	aMenu addItem: [ :item |
		item name: 'MagLev Finalizer Registry Report'; action: [ self browseMaglevFinalizerRegistryReport ].
		(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #finalizerRegistryReportBlock ifAbsent: [ nil ]) notNil ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsStructuredValueInspectorPresenter >> browseRubyLoadPathReport [
	| reportBlock |
	reportBlock := self propertyAt: #loadPathReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	self inform: reportBlock value
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsStructuredValueInspectorPresenter >> browseRubyLoadedFeaturesReport [
	| reportBlock |
	reportBlock := self propertyAt: #loadedFeaturesReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	self inform: reportBlock value
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsStructuredValueInspectorPresenter >> browseRubyPersistentLoadedFeaturesReport [
	| reportBlock |
	reportBlock := self propertyAt: #persistentFeaturesReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	self inform: reportBlock value
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsStructuredValueInspectorPresenter >> browseTopLevelAutoloadRegistrationsReport [
	| reportBlock |
	reportBlock := self propertyAt: #topLevelAutoloadReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	self inform: reportBlock value
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsStructuredValueInspectorPresenter >> browseMaglevFinalizerRegistryReport [
	| reportBlock |
	reportBlock := self propertyAt: #finalizerRegistryReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	self inform: reportBlock value
]
