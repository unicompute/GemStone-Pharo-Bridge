Extension { #name : 'GbsStructuredValueInspectorPresenter' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> canBrowseReferencersForSelectedEntry [
	| row referencersBlock |
	row := self selectedRow.
	referencersBlock := self propertyAt: #referencersBlock ifAbsent: [ nil ].
	^ referencersBlock notNil
		and: [ row notNil
		and: [ (row at: 1 ifAbsent: [ '' ]) asString ~= '__truncated__' ] ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> canBrowseSessionState [
	^ (self propertyAt: #sessionStateBlock ifAbsent: [ nil ]) notNil
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> canActivateSelectedEntry [
	| row activateBlock |
	row := self selectedRow.
	activateBlock := self propertyAt: #activateBlock ifAbsent: [ nil ].
	^ activateBlock notNil
		and: [ row notNil
		and: [ (row at: 1 ifAbsent: [ '' ]) asString ~= '__truncated__' ] ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> activateSelectedEntry [
	| row activateBlock |
	self canActivateSelectedEntry ifFalse: [ ^ self ].
	row := self selectedRow.
	activateBlock := self propertyAt: #activateBlock ifAbsent: [ nil ].
	activateBlock value: row
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> browseObjectsInMemoryReport [
	| reportBlock start limit |
	reportBlock := self propertyAt: #objectsInMemoryReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ self ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ self ].
	self inform: (reportBlock value: start value: limit)
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> browsePromptedSessionStateKey [
	| rawKey key |
	self canBrowseSessionState ifFalse: [ ^ self ].
	rawKey := self requestInput: 'Session state key:' initialAnswer: '19'.
	(rawKey isNil or: [ rawKey trimBoth isEmpty ]) ifTrue: [ ^ self ].
	key := [ rawKey trimBoth asInteger ]
		on: Error
		do: [ nil ].
	key ifNil: [
		self inform: 'Enter a numeric session state key.'.
		^ self ].
	self browseSessionStateAtKey: key
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> browsePromptedSessionStateKeysReport [
	| reportBlock rawKeys keys |
	reportBlock := self propertyAt: #sessionStateKeysReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	rawKeys := self requestInput: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ self ].
	self inform: (reportBlock value: keys)
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> browseReferencersForSelectedEntry [
	| row referencersBlock |
	self canBrowseReferencersForSelectedEntry ifFalse: [ ^ self ].
	row := self selectedRow.
	referencersBlock := self propertyAt: #referencersBlock ifAbsent: [ nil ].
	referencersBlock value: row
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> browseSessionStateAtKey: aKey [
	| sessionStateBlock |
	self canBrowseSessionState ifFalse: [ ^ self ].
	sessionStateBlock := self propertyAt: #sessionStateBlock ifAbsent: [ nil ].
	sessionStateBlock value: aKey
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> browseStaleTypedWrapperLifecycleReport [
	| reportBlock |
	reportBlock := self propertyAt: #staleTypedWrapperReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	self inform: reportBlock value
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> browseTypedWrapperLifecycleReport [
	| reportBlock |
	reportBlock := self propertyAt: #typedWrapperLifecycleReportBlock ifAbsent: [ nil ].
	reportBlock ifNil: [ ^ self ].
	self inform: reportBlock value
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> inform: aString [
	| informBlock |
	informBlock := self propertyAt: #informBlock ifAbsent: [ nil ].
	informBlock ifNotNil: [ ^ informBlock value: aString ].
	UIManager default inform: aString.
	^ aString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> menuEntry [
	| menu |
	menu := self newMenu
		addItem: [ :item |
			item name: 'Inspect Entry'; action: [ self inspectSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canInspectSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Activate Entry'; action: [ self activateSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canActivateSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Referencers'; action: [ self browseReferencersForSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canBrowseReferencersForSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Inspect Session State Key...'; action: [ self browsePromptedSessionStateKey ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canBrowseSessionState ] ];
		addItem: [ :item |
			item name: 'Typed Wrapper Lifecycle Report'; action: [ self browseTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #typedWrapperLifecycleReportBlock ifAbsent: [ nil ]) notNil ] ];
		addItem: [ :item |
			item name: 'Stale Typed Wrapper Report'; action: [ self browseStaleTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #staleTypedWrapperReportBlock ifAbsent: [ nil ]) notNil ] ];
		addItem: [ :item |
			item name: 'Session State Keys Report...'; action: [ self browsePromptedSessionStateKeysReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #sessionStateKeysReportBlock ifAbsent: [ nil ]) notNil ] ];
		addItem: [ :item |
			item name: 'Objects In Memory Report...'; action: [ self browseObjectsInMemoryReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: (self propertyAt: #objectsInMemoryReportBlock ifAbsent: [ nil ]) notNil ] ];
		yourself.
	self addExtensionEntryMenuItemsTo: menu.
	^ menu
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> menuEntryPopup [
	^ self menuEntry
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> parseSessionStateKeysFrom: aStringOrNil [
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
GbsStructuredValueInspectorPresenter >> requestInput: prompt initialAnswer: defaultString [
	| requestBlock |
	requestBlock := self propertyAt: #requestInputBlock ifAbsent: [ nil ].
	requestBlock ifNotNil: [ ^ requestBlock value: prompt value: defaultString ].
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsStructuredValueInspectorPresenter >> requestPositiveInteger: promptString initialAnswer: defaultString [
	| rawValue |
	rawValue := self requestInput: promptString initialAnswer: defaultString.
	(rawValue isNil or: [ rawValue trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ [ | value |
		value := rawValue trimBoth asInteger.
		value > 0 ifTrue: [ value ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]
