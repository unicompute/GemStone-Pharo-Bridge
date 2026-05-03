Extension { #name : 'GbsSymbolListBrowserPresenter' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> inspectDictionary [
	| userName dictName raw |
	userName := self selectedUserName.
	dictName := self selectedDictionaryName.
	(userName isNil or: [ dictName isNil ]) ifTrue: [ ^ self ].
	raw := self withShallowMaterializationDo: [
		[ session evaluate: (self inspectDictionaryScriptForUser: userName dictionary: dictName) ]
			on: Error
			do: [ :ex | 'Inspect dictionary failed: ', ex messageText ] ].
	UIManager default inform: raw asString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> browseReferencersForSelectedEntry [
	| key |
	key := self selectedEntryName.
	key ifNil: [ ^ false ].
	^ self browseReferencersForEntryKey: key path: #()
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> browseReferencersForSelectedPreviewValue [
	| entryKey row rowLabel kind path |
	entryKey := self selectedEntryName.
	entryKey ifNil: [ ^ false ].
	row := self selectedPreviewRow.
	row ifNil: [ ^ false ].
	rowLabel := (row at: 1 ifAbsent: [ '' ]) asString.
	rowLabel = '__truncated__' ifTrue: [ ^ false ].
	kind := currentPreview
		ifNil: [ nil ]
		ifNotNil: [ currentPreview at: #kind ifAbsent: [ nil ] ].
	kind ifNil: [ ^ false ].
	path := { { kind asString. rowLabel } }.
	^ self browseReferencersForEntryKey: entryKey path: path
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> browseReferencersForStructuredPreviewRow: row entryKey: entryKey path: path previewKind: previewKind [
	| rowLabel nextPath |
	rowLabel := (row at: 1 ifAbsent: [ '' ]) asString.
	rowLabel isEmpty ifTrue: [ ^ false ].
	rowLabel = '__truncated__' ifTrue: [ ^ false ].
	nextPath := path asArray copyWith: { previewKind asString. rowLabel }.
	^ self browseReferencersForEntryKey: entryKey path: nextPath
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> browsePromptedSessionStateKey [
	| rawKey key |
	session ifNil: [ ^ false ].
	rawKey := self requestInput: 'Session state key:' initialAnswer: '19'.
	(rawKey isNil or: [ rawKey trimBoth isEmpty ]) ifTrue: [ ^ false ].
	key := [ rawKey trimBoth asInteger ]
		on: Error
		do: [ nil ].
	key ifNil: [
		self inform: 'Enter a numeric session state key.'.
		^ false ].
	^ self browseSessionStateAtKey: key
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> browsePromptedSessionStateKeysReport [
	| rawKeys keys |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	rawKeys := self requestInput: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [
		session objectSpaceDiagnostics reportTextForKeys: keys ]).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> browseSessionStateAtKey: aKey [
	| sessionStateValue targetOop |
	session ifNil: [ ^ false ].
	sessionStateValue := [ session sessionStateAt: aKey ]
		on: Error
		do: [ :ex |
			self inform: 'Session state lookup failed: ', ex messageText.
			^ false ].
	sessionStateValue ifNil: [
		self inform: 'Session state key ', aKey printString, ' is not set.'.
		^ false ].
	targetOop := self oopForInspectableObject: sessionStateValue.
	targetOop ifNil: [
		self inform: 'Session state key ', aKey printString, ' does not currently have an inspectable remote oop.'.
		^ false ].
	^ self openInspectorOnOop: targetOop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> browseStaleTypedWrapperLifecycleReport [
	| report staleEntries |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	report := self withShallowMaterializationDo: [ session typedWrapperLifecycleReport ].
	staleEntries := report staleEntries.
	staleEntries isEmpty ifTrue: [
		self inform: 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.'.
		^ true ].
	self inform: (GbsTypedWrapperLifecycleReport entries: staleEntries) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> browseObjectsInMemoryReport [
	| start limit |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ false ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ false ].
	self inform: (self withShallowMaterializationDo: [
		(session objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text ]).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> browseReferencersForEntryKey: keyName path: pathCollection [
	| targetOop referencers inspectable selection |
	targetOop := self oopForEntryKey: keyName path: pathCollection.
	targetOop ifNil: [
		self inform: 'Could not determine a remote object for referencer lookup.'.
		^ false ].
	referencers := self referencersInMemoryForOop: targetOop.
	inspectable := referencers select: [ :each | (self oopForInspectableObject: each) notNil ].
	inspectable isEmpty ifTrue: [
		self inform: 'No in-memory referencers found.'.
		^ false ].
	inspectable size = 1 ifTrue: [
		^ self openInspectorOnOop: (self oopForInspectableObject: inspectable first) ].
	selection := self
		chooseReferencerFrom: inspectable
		title: 'In-memory referencers'.
	selection ifNil: [ ^ false ].
	^ self openInspectorOnOop: (self oopForInspectableObject: selection)
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> browseTypedWrapperLifecycleReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session typedWrapperLifecycleReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> menuEntry [
	| menu |
	menu := self newMenu
		addItem: [ :item |
			item name: 'Add...'; action: [ self addEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedDictionary ] ];
		addItem: [ :item |
			item name: 'Rename As...'; action: [ self renameEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Remove...'; action: [ self removeEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Inspect Entry'; action: [ self inspectSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Referencers'; action: [ self browseReferencersForSelectedEntry ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedEntry ] ];
		addItem: [ :item |
			item name: 'Inspect Session State Key...'; action: [ self browsePromptedSessionStateKey ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Typed Wrapper Lifecycle Report'; action: [ self browseTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Stale Typed Wrapper Report'; action: [ self browseStaleTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Session State Keys Report...'; action: [ self browsePromptedSessionStateKeysReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Objects In Memory Report...'; action: [ self browseObjectsInMemoryReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		yourself.
	self addExtensionEntryMenuItemsTo: menu.
	^ menu
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> menuPreview [
	| menu |
	menu := self newMenu
		addItem: [ :item |
			item name: 'Inspect Entry'; action: [ self inspectSelectedPreviewValue ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPreviewRow ] ];
		addItem: [ :item |
			item name: 'Referencers'; action: [ self browseReferencersForSelectedPreviewValue ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPreviewRow ] ];
		addItem: [ :item |
			item name: 'Inspect Session State Key...'; action: [ self browsePromptedSessionStateKey ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Typed Wrapper Lifecycle Report'; action: [ self browseTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Stale Typed Wrapper Report'; action: [ self browseStaleTypedWrapperLifecycleReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Session State Keys Report...'; action: [ self browsePromptedSessionStateKeysReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		addItem: [ :item |
			item name: 'Objects In Memory Report...'; action: [ self browseObjectsInMemoryReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: session notNil ] ];
		yourself.
	self addExtensionPreviewMenuItemsTo: menu.
	^ menu
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> openStructuredInspectorForPreview: preview title: titleString entryKey: entryKey path: path previewKind: previewKind [
	| inspectorClass previewFetcherBlock presenter |
	inspectorClass := Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ].
	inspectorClass
		ifNil: [ self inform: 'Structured value inspector is not available.' ]
		ifNotNil: [
			previewFetcherBlock := [ :row |
				| rowLabel nextPath |
				rowLabel := (row at: 1 ifAbsent: [ '' ]) asString.
				rowLabel = '__truncated__' ifTrue: [ nil ] ifFalse: [
					nextPath := path asArray copyWith: { previewKind asString. rowLabel }.
					self structuredPreviewForEntryKey: entryKey path: nextPath ] ].
			presenter := inspectorClass
				openRows: (preview at: #rows ifAbsent: [ #() ])
				kind: previewKind
				title: titleString
				inspectBlock: [ :row |
					self
						inspectStructuredPreviewRow: row
						entryKey: entryKey
						path: path
						previewKind: previewKind ]
				rawPrintString: (preview at: #rawPrintString ifAbsent: [ '' ])
				entryKey: entryKey
				path: path
				previewKind: previewKind
				previewFetcherBlock: previewFetcherBlock.
			presenter
				propertyAt: #referencersBlock
				put: [ :row |
					self
						browseReferencersForStructuredPreviewRow: row
						entryKey: entryKey
						path: path
						previewKind: previewKind ];
				propertyAt: #typedWrapperLifecycleReportBlock
				put: [ self withShallowMaterializationDo: [ session typedWrapperLifecycleReportText ] ];
				propertyAt: #staleTypedWrapperReportBlock
				put: [ self withShallowMaterializationDo: [
					| report staleEntries |
					report := session typedWrapperLifecycleReport.
					staleEntries := report staleEntries.
					staleEntries isEmpty
						ifTrue: [ 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.' ]
						ifFalse: [ (GbsTypedWrapperLifecycleReport entries: staleEntries) text ] ] ];
				propertyAt: #sessionStateKeysReportBlock
				put: [ :keys | self withShallowMaterializationDo: [
					session objectSpaceDiagnostics reportTextForKeys: keys ] ];
				propertyAt: #objectsInMemoryReportBlock
				put: [ :start :limit | self withShallowMaterializationDo: [
					(session objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text ] ];
				propertyAt: #sessionStateBlock
				put: [ :key | self browseSessionStateAtKey: key ].
			self configureExtensionStructuredInspector: presenter ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> refreshDictionariesFor: userName [
	| previousDict raw dicts |
	previousDict := self selectedDictionaryName.
	userName ifNil: [
		dictionariesList items: #().
		entriesList items: #().
		self showSelectedEntryPreview.
		^ self ].
	raw := self withShallowMaterializationDo: [
		[ session evaluate: (self dictionariesScriptForUser: userName asString) ]
			on: Error
			do: [ '' ] ].
	dicts := (raw isString and: [ raw isNotEmpty ])
		ifTrue: [ (raw splitOn: Character tab) reject: [ :each | each isEmpty ] ]
		ifFalse: [ #() ].
	dictionariesList items: dicts asArray.
	self selectDictionaryName: previousDict ifMissingSelectFirst: true.
	self refreshEntriesForSelectedDictionary
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> refreshEntriesForDictionary: dictName [
	| previousKey raw lines keys userName |
	previousKey := self selectedEntryName.
	dictName ifNil: [
		entriesList items: #().
		entryValuesByKey := Dictionary new.
		self showSelectedEntryPreview.
		^ self ].
	userName := self selectedUserName.
	userName ifNil: [
		entryValuesByKey := Dictionary new.
		self showSelectedEntryPreview.
		^ self ].
	raw := self withShallowMaterializationDo: [
		[ session evaluate: (self entriesScriptForUser: userName dictionary: dictName asString) ]
			on: Error
			do: [ '' ] ].
	lines := (raw isString and: [ raw isNotEmpty ])
		ifTrue: [ raw lines ]
		ifFalse: [ #() ].
	entryValuesByKey := Dictionary new.
	keys := OrderedCollection new.
	lines do: [ :line |
		| parts key value |
		parts := line splitOn: Character tab.
		key := parts at: 1 ifAbsent: [ '' ].
		value := parts at: 2 ifAbsent: [ '' ].
		(key isEmpty not) ifTrue: [
			keys add: key.
			entryValuesByKey at: key put: value ] ].
	entriesList items: keys asArray.
	self selectEntryName: previousKey ifMissingSelectFirst: true.
	self showSelectedEntryPreview
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> refreshUsers [
	| raw users defaultUser |
	raw := self withShallowMaterializationDo: [
		[ session evaluate: self usersScript ] on: Error do: [ '' ] ].
	users := (raw isString and: [ raw isNotEmpty ])
		ifTrue: [ (raw splitOn: Character tab) reject: [ :each | each isEmpty ] ]
		ifFalse: [ #() ].
	userDropList items: users asArray.
	defaultUser := ((targetUserName isString and: [ targetUserName isEmpty not ]) and: [ users includes: targetUserName ])
		ifTrue: [ targetUserName ]
		ifFalse: [ users ifEmpty: [ nil ] ifNotEmpty: [ users first ] ].
	defaultUser ifNotNil: [
		(userDropList respondsTo: #selectItem:)
			ifTrue: [ userDropList selectItem: defaultUser ]
			ifFalse: [ (userDropList respondsTo: #selectedItem:) ifTrue: [ userDropList selectedItem: defaultUser ] ].
		self refreshDictionariesFor: defaultUser ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> chooseReferencerFrom: referencers title: aTitle [
	| labels index |
	labels := referencers collect: [ :each | self displayStringForReferencer: each ].
	index := UIManager default chooseFrom: labels title: aTitle.
	index = 0 ifTrue: [ ^ nil ].
	^ referencers at: index ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> displayStringForReferencer: anObject [
	(anObject isKindOf: GbsProxy) ifTrue: [
		^ [ anObject asLocalString ]
			on: Error
			do: [ 'aGbsProxy(oop: ', anObject oop asString, ')' ] ].
	^ anObject printString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> structuredPreviewForEntryKey: keyName path: pathCollection [
	| userName dictName raw |
	userName := self selectedUserName.
	dictName := self selectedDictionaryName.
	(userName isNil or: [ dictName isNil or: [ keyName isNil ] ]) ifTrue: [ ^ nil ].
	raw := self withShallowMaterializationDo: [
		[ session executeAndFetch: (self
			structuredPreviewScriptForUser: userName
			dictionary: dictName
			keyName: keyName
			path: pathCollection) ]
			on: Error
			do: [ :ex | 'string', String lf, 'Inspect entry failed: ', ex messageText ] ].
	^ self parsedStructuredPreviewFrom: raw
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> oopForEntryKey: keyName path: pathCollection [
	| userName dictName raw oopValue |
	userName := self selectedUserName.
	dictName := self selectedDictionaryName.
	(userName isNil or: [ dictName isNil or: [ keyName isNil ] ]) ifTrue: [ ^ nil ].
	raw := [ session executeAndFetch: (self
		oopScriptForUser: userName
		dictionary: dictName
		keyName: keyName
		path: pathCollection) ]
		on: Error
		do: [ nil ].
	raw ifNil: [ ^ nil ].
	oopValue := [ raw asString trimBoth asNumber ] on: Error do: [ nil ].
	^ oopValue
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> oopScriptForUser: userName dictionary: dictName keyName: keyName path: pathCollection [
	| u d k p |
	u := self literalString: userName.
	d := self literalString: dictName.
	k := self literalString: keyName.
	p := self pathLiteralStringFor: pathCollection.
	^ '
	| users user sl dict entryKey value path |
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ ^ '''' ].
	user := users detect: [ :x | x userId asString = ', u, ' ] ifNone: [ nil ].
	user ifNil: [ ^ '''' ].
	sl := user symbolList.
	dict := sl detect: [ :each |
		| name |
		name := (each respondsTo: #name) ifTrue: [ each name asString ] ifFalse: [ each printString ].
		name = ', d, ' ] ifNone: [ nil ].
	dict ifNil: [ ^ '''' ].
	entryKey := dict keys detect: [ :each | each asString = ', k, ' ] ifNone: [ nil ].
	entryKey ifNil: [ ^ '''' ].
	value := dict at: entryKey.
	path := ', p, '.
	path do: [ :step |
		| stepKind stepLabel assoc items index |
		stepKind := step first asString.
		stepLabel := step second asString.
		stepKind = ''dictionary'' ifTrue: [
			assoc := value associations
				detect: [ :each | each key printString asString = stepLabel or: [ each key asString = stepLabel ] ]
				ifNone: [ nil ].
			assoc ifNil: [ ^ '''' ].
			value := assoc value ].
		stepKind = ''collection'' ifTrue: [
			stepLabel = ''__truncated__'' ifTrue: [ ^ '''' ].
			items := value asArray.
			index := [ stepLabel asNumber ] on: Error do: [ nil ].
			(index isNil or: [ index < 1 or: [ index > items size ] ]) ifTrue: [ ^ '''' ].
			value := items at: index ] ].
	(Reflection oopOf: value) asString'
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> inform: aString [
	UIManager default inform: aString.
	^ aString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> oopForInspectableObject: anObject [
	(anObject isKindOf: GbsProxy) ifTrue: [ ^ anObject oop ].
	(anObject isInteger and: [ anObject > 20 ]) ifTrue: [ ^ anObject ].
	^ nil
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> openInspectorOnOop: anOop [
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ false ].
	GbsInspector inspect: anOop session: session.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> requestInput: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> parseSessionStateKeysFrom: aStringOrNil [
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
GbsSymbolListBrowserPresenter >> requestPositiveInteger: promptString initialAnswer: defaultString [
	| rawValue |
	rawValue := self requestInput: promptString initialAnswer: defaultString.
	(rawValue isNil or: [ rawValue trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ [ | value |
		value := rawValue trimBoth asInteger.
		value > 0 ifTrue: [ value ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> referencersInMemoryForOop: anOop [
	session ifNil: [ ^ #() ].
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ #() ].
	^ self withShallowMaterializationDo: [
		[ session referencesToOop: anOop ]
			on: Error
			do: [ #() ] ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSymbolListBrowserPresenter >> withShallowMaterializationDo: aBlock [
	session ifNil: [ ^ aBlock value ].
	^ session
		withMaterializationProfile: GbsShallowMaterializationProfile new
		do: aBlock
]
