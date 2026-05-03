Extension { #name : 'GbsNamespacesPresenter' }

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> maglevExtraPresenterPropertyNames [
	^ #(
		constantsTable
		autoloadTable
		runtimeText
		requireButton
		requireAutoloadButton
		loadButton
		clearPersistentFeaturesButton
		autoloadButton
		removeAutoloadButton
		inspectAutoloadButton
		inspectConstantButton
		jumpNamespaceButton
		openNamespaceButton
		upNamespaceButton
		topNamespaceButton
		wrapperActionsButton
		runtimeReportsButton
		inspectSessionStateButton
		inspectFinalizerRegistryButton
		browseConstantButton
		referencesButton
		implementorsButton
		sendersButton )
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> instVarNamed: aString [
	| symbol |
	symbol := aString asSymbol.
	(self maglevExtraPresenterPropertyNames includes: symbol) ifTrue: [
		^ self propertyAt: symbol ifAbsent: [ nil ] ].
	^ super instVarNamed: aString
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> instVarNamed: aString put: anObject [
	| symbol |
	symbol := aString asSymbol.
	(self maglevExtraPresenterPropertyNames includes: symbol) ifTrue: [
		self propertyAt: symbol put: anObject.
		^ anObject ].
	^ super instVarNamed: aString put: anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> constantsTable [
	^ self propertyAt: #constantsTable ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> constantsTable: anObject [
	self propertyAt: #constantsTable put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> autoloadTable [
	^ self propertyAt: #autoloadTable ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> autoloadTable: anObject [
	self propertyAt: #autoloadTable put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> runtimeText [
	^ self propertyAt: #runtimeText ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> runtimeText: anObject [
	self propertyAt: #runtimeText put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> requireButton [
	^ self propertyAt: #requireButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> requireButton: anObject [
	self propertyAt: #requireButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> requireAutoloadButton [
	^ self propertyAt: #requireAutoloadButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> requireAutoloadButton: anObject [
	self propertyAt: #requireAutoloadButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> loadButton [
	^ self propertyAt: #loadButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> loadButton: anObject [
	self propertyAt: #loadButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> clearPersistentFeaturesButton [
	^ self propertyAt: #clearPersistentFeaturesButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> clearPersistentFeaturesButton: anObject [
	self propertyAt: #clearPersistentFeaturesButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> autoloadButton [
	^ self propertyAt: #autoloadButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> autoloadButton: anObject [
	self propertyAt: #autoloadButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> removeAutoloadButton [
	^ self propertyAt: #removeAutoloadButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> removeAutoloadButton: anObject [
	self propertyAt: #removeAutoloadButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectAutoloadButton [
	^ self propertyAt: #inspectAutoloadButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectAutoloadButton: anObject [
	self propertyAt: #inspectAutoloadButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectConstantButton [
	^ self propertyAt: #inspectConstantButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectConstantButton: anObject [
	self propertyAt: #inspectConstantButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> jumpNamespaceButton [
	^ self propertyAt: #jumpNamespaceButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> jumpNamespaceButton: anObject [
	self propertyAt: #jumpNamespaceButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> openNamespaceButton [
	^ self propertyAt: #openNamespaceButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> openNamespaceButton: anObject [
	self propertyAt: #openNamespaceButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> upNamespaceButton [
	^ self propertyAt: #upNamespaceButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> upNamespaceButton: anObject [
	self propertyAt: #upNamespaceButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> topNamespaceButton [
	^ self propertyAt: #topNamespaceButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> topNamespaceButton: anObject [
	self propertyAt: #topNamespaceButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> wrapperActionsButton [
	^ self propertyAt: #wrapperActionsButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> wrapperActionsButton: anObject [
	self propertyAt: #wrapperActionsButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> runtimeReportsButton [
	^ self propertyAt: #runtimeReportsButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> runtimeReportsButton: anObject [
	self propertyAt: #runtimeReportsButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectSessionStateButton [
	^ self propertyAt: #inspectSessionStateButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectSessionStateButton: anObject [
	self propertyAt: #inspectSessionStateButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectFinalizerRegistryButton [
	^ self propertyAt: #inspectFinalizerRegistryButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectFinalizerRegistryButton: anObject [
	self propertyAt: #inspectFinalizerRegistryButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseConstantButton [
	^ self propertyAt: #browseConstantButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseConstantButton: anObject [
	self propertyAt: #browseConstantButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> referencesButton [
	^ self propertyAt: #referencesButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> referencesButton: anObject [
	self propertyAt: #referencesButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> implementorsButton [
	^ self propertyAt: #implementorsButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> implementorsButton: anObject [
	self propertyAt: #implementorsButton put: anObject.
	^ anObject
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> sendersButton [
	^ self propertyAt: #sendersButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> sendersButton: anObject [
	self propertyAt: #sendersButton put: anObject.
	^ anObject
]


{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter class >> openOn: aSession [
	| presenter |
	aSession ifNil: [ ^ self inform: 'No connected GemStone session. Please login first.' ].
	presenter := self new.
	presenter
		session: aSession;
		open.
	^ presenter
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> connectPresenters [
	(namespacesTable respondsTo: #whenSelectionChangedDo:) ifTrue: [
		namespacesTable whenSelectionChangedDo: [ :selection |
			self
				refreshSelectedNamespaceDetails;
				refreshRuntimeInfo ] ].
	(self constantsTable respondsTo: #whenSelectionChangedDo:) ifTrue: [
		self constantsTable whenSelectionChangedDo: [ :selection |
			self handleConstantSelectionChanged ] ].
	(self autoloadTable respondsTo: #whenSelectionChangedDo:) ifTrue: [
		self autoloadTable whenSelectionChangedDo: [ :selection |
			self handleAutoloadSelectionChanged ] ].
	refreshButton action: [ self refreshAll ].
	self requireButton action: [ self requireSelectedFile ].
	self requireAutoloadButton action: [ self requireSelectedAutoload ].
	self loadButton action: [ self loadSelectedFile ].
	self clearPersistentFeaturesButton action: [ self clearPersistentLoadedFeatures ].
	self autoloadButton action: [ self registerAutoloadForSelectedNamespace ].
	self removeAutoloadButton action: [ self removeSelectedAutoload ].
	self inspectAutoloadButton action: [ self inspectSelectedAutoload ].
	self inspectConstantButton action: [ self inspectSelectedConstant ].
	self jumpNamespaceButton action: [ self openPromptedNamespace ].
	self openNamespaceButton action: [ self openSelectedConstantNamespace ].
	self upNamespaceButton action: [ self openParentNamespace ].
	self topNamespaceButton action: [ self openTopLevelNamespace ].
	self wrapperActionsButton action: [ self browseWrapperActionChooser ].
	self runtimeReportsButton action: [ self browseRuntimeReportChooser ].
	self inspectSessionStateButton action: [ self inspectPromptedSessionStateKey ].
	self connectMaglevNamespaceActionButtons.
	self browseConstantButton action: [ self browseSelectedConstantClass ].
	self referencesButton action: [ self browseNamespaceReferencesToSelectedConstant ].
	self implementorsButton action: [ self browseNamespaceImplementorsOfPromptedSelector ].
	self sendersButton action: [ self browseNamespaceSendersOfPromptedSelector ].
	closeButton action: [ self closeWindow ].
	self refreshAll
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> defaultLayout [
	| detailsRow actionRow windowRow |
	detailsRow := SpBoxLayout newLeftToRight
		add: self constantsTable;
		add: self autoloadTable;
		spacing: 8;
		yourself.
	actionRow := SpBoxLayout newLeftToRight
		add: self requireButton;
		add: self requireAutoloadButton;
		add: self loadButton;
		add: self clearPersistentFeaturesButton;
		add: self autoloadButton;
		add: self removeAutoloadButton;
		add: self inspectAutoloadButton;
		add: self inspectConstantButton;
		add: self jumpNamespaceButton;
		add: self openNamespaceButton;
		add: self upNamespaceButton;
		add: self topNamespaceButton;
		add: self wrapperActionsButton;
		add: self runtimeReportsButton;
		add: self inspectSessionStateButton;
		add: self browseConstantButton;
		add: self referencesButton;
		add: self implementorsButton;
		add: self sendersButton;
		spacing: 8;
		yourself.
	self addNamespaceActionButtonsTo: actionRow.
	windowRow := SpBoxLayout newLeftToRight
		add: refreshButton;
		add: closeButton;
		spacing: 8;
		yourself.
	^ SpBoxLayout newTopToBottom
		add: namespacesTable;
		add: detailsRow;
		add: self runtimeText;
		add: actionRow expand: false;
		add: windowRow expand: false;
		yourself
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> initializePresenters [
	namespacesTable := self newTable.
	namespacesTable
		addColumn: (SpStringTableColumn title: 'Index' evaluated: [ :row | row index ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Namespace' evaluated: [ :row | row displayName ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Class' evaluated: [ :row | row className ifNil: [ '' ] ]);
		yourself.
	self constantsTable: self newTable.
	self constantsTable
		addColumn: (SpStringTableColumn title: 'Constant' evaluated: [ :row | row name ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Target' evaluated: [ :row | row targetDisplayName ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Value Class' evaluated: [ :row | row valueClassName ifNil: [ '' ] ]);
		yourself.
	self autoloadTable: self newTable.
	self autoloadTable
		addColumn: (SpStringTableColumn title: 'Autoload Constant' evaluated: [ :row | row name ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'File' evaluated: [ :row | row autoloadFile ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Target' evaluated: [ :row | row targetDisplayName ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'State' evaluated: [ :row | row stateLabel ifNil: [ '' ] ]);
		yourself.
	self runtimeText: self newText.
	self requireButton: self newButton.
	self requireButton
		label: 'Require...';
		icon: (self iconNamed: #smallOpen);
		yourself.
	self requireAutoloadButton: self newButton.
	self requireAutoloadButton
		label: 'Require Autoload';
		icon: (self iconNamed: #smallOpen);
		yourself.
	self loadButton: self newButton.
	self loadButton
		label: 'Load...';
		icon: (self iconNamed: #smallOpen);
		yourself.
	self clearPersistentFeaturesButton: self newButton.
	self clearPersistentFeaturesButton
		label: 'Clear Persistent Features';
		icon: (self iconNamed: #smallCancel);
		yourself.
	self autoloadButton: self newButton.
	self autoloadButton
		label: 'Register Autoload...';
		icon: (self iconNamed: #add);
		yourself.
	self removeAutoloadButton: self newButton.
	self removeAutoloadButton
		label: 'Remove Autoload';
		icon: (self iconNamed: #smallDelete);
		yourself.
	self inspectAutoloadButton: self newButton.
	self inspectAutoloadButton
		label: 'Inspect Autoload';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
	self inspectConstantButton: self newButton.
	self inspectConstantButton
		label: 'Inspect Constant';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
	self jumpNamespaceButton: self newButton.
	self jumpNamespaceButton
		label: 'Go To Namespace...';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	self openNamespaceButton: self newButton.
	self openNamespaceButton
		label: 'Open Namespace';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	self upNamespaceButton: self newButton.
	self upNamespaceButton
		label: 'Up Namespace';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	self topNamespaceButton: self newButton.
	self topNamespaceButton
		label: 'Top Namespace';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	self wrapperActionsButton: self newButton.
	self wrapperActionsButton
		label: 'Wrapper Actions';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
	self runtimeReportsButton: self newButton.
	self runtimeReportsButton
		label: 'Session Tools';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
	self inspectSessionStateButton: self newButton.
	self inspectSessionStateButton
		label: 'Inspect State...';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
	self initializeMaglevNamespaceActionButtons.
	self browseConstantButton: self newButton.
	self browseConstantButton
		label: 'Browse Constant';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	self referencesButton: self newButton.
	self referencesButton
		label: 'References';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	self implementorsButton: self newButton.
	self implementorsButton
		label: 'Implementors...';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	self sendersButton: self newButton.
	self sendersButton
		label: 'Senders...';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	refreshButton := self newButton
		label: 'Refresh';
		icon: (self iconNamed: #smallUpdate);
		yourself.
	closeButton := self newButton
		label: 'Close';
		icon: (self iconNamed: #smallCancel);
		yourself
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Namespaces';
		initialExtent: 980 @ 620
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> isSessionUsable [
	session ifNil: [ ^ false ].
	(session respondsTo: #isLoggedIn)
		ifTrue: [ ^ [ session isLoggedIn == true ] on: Error do: [ false ] ].
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> namespacesScript [
	^ '
	| sl strm |
	strm := WriteStream on: String new.
	sl := System myUserProfile symbolList.
	1 to: sl size do: [ :index |
		| ns nsName nsClass |
		ns := sl at: index.
		nsName := (ns respondsTo: #name)
			ifTrue: [ ns name ]
			ifFalse: [ ns printString ].
		nsClass := ns class name asString.
		strm
			nextPutAll: index asString;
			tab;
			nextPutAll: nsName asString;
			tab;
			nextPutAll: nsClass;
			cr ].
	strm contents'
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> parseRows: rawString [
	| lines |
	(rawString isString and: [ rawString isNotEmpty ]) ifFalse: [ ^ #() ].
	lines := rawString lines.
	^ lines collect: [ :line |
		| columns |
		columns := line splitOn: Character tab.
		{ (columns at: 1 ifAbsent: [ '' ]).
		  (columns at: 2 ifAbsent: [ '' ]).
		  (columns at: 3 ifAbsent: [ '' ]) } ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> refreshAll [
	self refreshNamespaces
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> refreshNamespaces [
	| rows previousSelection |
	(self isSessionUsable not) ifTrue: [
		namespacesTable items: #().
		self clearTableSelection: namespacesTable.
		self
			refreshSelectedNamespaceDetails;
			refreshRuntimeInfo.
		^ self
	].
	previousSelection := self selectedNamespace.
	rows := [ session namespaceMirrors ] on: Error do: [ :ex | self inform: 'Fetch namespaces failed: ', ex messageText. #() ].
	namespacesTable items: rows.
	self restoreNamespaceSelectionFrom: previousSelection.
	self
		refreshSelectedNamespaceDetails;
		refreshRuntimeInfo
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> refreshRuntimeInfo [
	| report |
	self runtimeText ifNil: [ ^ self ].
	(self isSessionUsable not) ifTrue: [
		self runtimeText text: ''.
		^ self ].
	report := [ self runtimeReportText ]
		on: Error
		do: [ :ex | 'Runtime info failed: ', ex messageText ].
	self runtimeText text: report
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> refreshSelectedNamespaceDetails [
	| namespace constants autoloads previousConstantSelection previousAutoloadSelection |
	self constantsTable ifNil: [ ^ self ].
	self autoloadTable ifNil: [ ^ self ].
	previousConstantSelection := self selectedConstantTableItem.
	previousAutoloadSelection := self selectedAutoloadTableItem.
	namespace := self selectedNamespace.
	namespace ifNil: [
		self constantsTable items: #().
		self autoloadTable items: #().
		self clearTableSelection: self constantsTable.
		self clearTableSelection: self autoloadTable.
		^ self ].
	self restoreNamespaceSelectionFrom: namespace.
	constants := [ namespace constantMirrors ]
		on: Error
		do: [ :ex |
			self inform: 'Fetch constants failed: ', ex messageText.
			#() ].
	autoloads := [ namespace autoloadMirrors ]
		on: Error
		do: [ :ex |
			self inform: 'Fetch autoloads failed: ', ex messageText.
			#() ].
	self constantsTable items: constants.
	self autoloadTable items: autoloads.
	self restoreConstantSelectionFrom: previousConstantSelection.
	self restoreAutoloadSelectionFrom: previousAutoloadSelection
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseSelectedConstantClass [
	| constant className |
	constant := self selectedConstant.
	constant ifNil: [
		self inform: 'Select a constant first.'.
		^ false ].
	className := constant browsableName ifNil: [ '' ].
	className := className asString trimBoth.
	className isEmpty ifTrue: [
		self inform: 'The selected constant has no browsable class name.'.
		^ false ].
	^ self openBrowserOnClassNamed: className
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseNamespaceReferencesToSelectedConstant [
	| namespace constant queryName query |
	namespace := self selectedNamespaceForLookup.
	constant := self selectedConstant.
	(namespace isNil or: [ constant isNil ]) ifTrue: [
		self inform: 'Select a constant first.'.
		^ false ].
	queryName := constant browsableName ifNil: [ constant name ].
	queryName := queryName asString trimBoth.
	queryName isEmpty ifTrue: [
		self inform: 'The selected constant does not currently have a queryable name.'.
		^ false ].
	query := [ namespace referencesQueryToSymbol: queryName ]
		on: Error
		do: [ :ex |
			self inform: 'Namespace references query failed: ', ex messageText.
			^ false ].
	query isEmpty ifTrue: [
		self inform: 'No namespace-scoped matches found.'.
		^ false ].
	^ self openMethodQuery: query
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseNamespaceImplementorsOfPromptedSelector [
	^ self
		browsePromptedNamespaceSelectorQuery:
			'Selector for namespace implementors:'
		mode: #implementors
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseNamespaceSendersOfPromptedSelector [
	^ self
		browsePromptedNamespaceSelectorQuery:
			'Selector for namespace senders:'
		mode: #senders
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseNamedObjectCacheReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session namedObjectCacheReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> clearNamedObjectCache [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	session clearNamedObjectCache.
	self inform: 'Named object cache cleared.'.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseSessionStateReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: (session objectSpaceDiagnostics reportTextForKeys: #(19)).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseRuntimeReportChooser [
	| labels actions index |
	labels := OrderedCollection withAll: #(
		'Named Object Cache Report'
		'Clear Named Object Cache'
		'Session State Report'
		'Session State Keys Report...'
		'Objects In Memory Report...').
	actions := {
		[ self browseNamedObjectCacheReport ].
		[ self clearNamedObjectCache ].
		[ self browseSessionStateReport ].
		[ self browsePromptedSessionStateKeysReport ].
		[ self browseObjectsInMemoryReport ] } asOrderedCollection.
	self addRuntimeReportOptionsTo: labels actions: actions.
	index := self uiChooseFrom: labels title: 'GemStone Session Tools'.
	index = 0 ifTrue: [ ^ false ].
	^ (actions at: index) value
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> addNamespaceActionButtonsTo: actionRow [
	self inspectFinalizerRegistryButton ifNotNil: [ actionRow add: self inspectFinalizerRegistryButton ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> addRuntimeReportOptionsTo: labels actions: actions [
	labels
		add: '$LOAD_PATH Report';
		add: 'Loaded Features Report';
		add: 'Persistent Features Report';
		add: 'MagLev Finalizer Registry Report';
		add: 'Namespace Autoload Report'.
	actions
		add: [ self browseRubyLoadPathReport ];
		add: [ self browseRubyLoadedFeaturesReport ];
		add: [ self browseRubyPersistentLoadedFeaturesReport ];
		add: [ self browseMaglevFinalizerRegistryReport ];
		add: [ self browseNamespaceAutoloadRegistrationsReport ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseTypedWrapperAutoloadReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: (GbsSessionManager typedWrapperAutoloadReportTextForSession: session).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseRubyLoadPathReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session rubyRuntime loadPathReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseRubyLoadedFeaturesReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session rubyRuntime loadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseRubyPersistentLoadedFeaturesReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session rubyRuntime persistentLoadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseNamespaceAutoloadRegistrationsReport [
	| namespace |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	namespace := self selectedNamespace ifNil: [ session topLevelNamespaceMirror ].
	self inform: (session rubyRuntime
		autoloadRegistrationsReportTextForNamespace: namespace).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseMaglevFinalizerRegistryReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session objectSpaceDiagnostics finalizerRegistryReport text.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseTypedWrapperLifecycleReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session typedWrapperLifecycleReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseStaleTypedWrapperLifecycleReport [
	| report staleEntries |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	report := session typedWrapperLifecycleReport.
	staleEntries := report staleEntries.
	staleEntries isEmpty ifTrue: [
		self inform: 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.'.
		^ true ].
	self inform: (GbsTypedWrapperLifecycleReport entries: staleEntries) text.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseWrapperActionChooser [
	| labels actions index |
	labels := #(
		'Typed Wrapper Autoload Report'
		'Typed Wrapper Lifecycle Report'
		'Stale Typed Wrapper Report'
		'Refresh Stale Typed Wrappers'
		'Refresh All Typed Wrappers').
	actions := {
		[ self browseTypedWrapperAutoloadReport ].
		[ self browseTypedWrapperLifecycleReport ].
		[ self browseStaleTypedWrapperLifecycleReport ].
		[ self refreshStaleTypedWrappers ].
		[ self refreshAllTypedWrappers ] }.
	index := self uiChooseFrom: labels title: 'Typed Wrapper Actions'.
	index = 0 ifTrue: [ ^ false ].
	^ (actions at: index) value
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> connectMaglevNamespaceActionButtons [
	self inspectFinalizerRegistryButton action: [ self inspectMaglevFinalizerRegistry ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browsePromptedSessionStateKeysReport [
	| rawKeys keys |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	rawKeys := self requestInput: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ false ].
	self inform: (session objectSpaceDiagnostics reportTextForKeys: keys).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browseObjectsInMemoryReport [
	| start limit |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ false ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ false ].
	self inform: (session objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> defaultAutoloadFileForConstantName: aString [
	| trimmed |
	trimmed := aString ifNil: [ '' ] ifNotNil: [ aString asString trimBoth ].
	trimmed isEmpty ifTrue: [ ^ '' ].
	^ 'lib/', trimmed, '.rb'
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> clearPersistentLoadedFeatures [
	| namespace result |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	namespace := self selectedNamespace.
	result := [ namespace
		ifNil: [ session clearPersistentRubyLoadedFeatures ]
		ifNotNil: [ namespace clearPersistentLoadedFeatures ] ]
		on: Error
		do: [ :ex |
			self inform: 'Clearing persistent loaded features failed: ', ex messageText.
			^ false ].
	self refreshRuntimeInfo.
	^ result ~= false
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> browsePromptedNamespaceSelectorQuery: promptString mode: aSymbol [
	| namespace selectorString query |
	namespace := self selectedNamespaceForLookup.
	namespace ifNil: [
		self inform: 'Select a namespace, constant, or autoload first.'.
		^ false ].
	selectorString := self requestInput: promptString initialAnswer: ''.
	selectorString := self trimmedRequest: selectorString.
	selectorString ifNil: [ ^ false ].
	query := [
		aSymbol = #senders
			ifTrue: [ namespace sendersQueryForSelector: selectorString ]
			ifFalse: [ namespace implementorsQueryForSelector: selectorString ] ]
		on: Error
		do: [ :ex |
			self inform: 'Namespace selector query failed: ', ex messageText.
			^ false ].
	query isEmpty ifTrue: [
		self inform: 'No namespace-scoped matches found.'.
		^ false ].
	^ self openMethodQuery: query
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectSelectedConstant [
	| constant oopValue |
	constant := self selectedConstant.
	constant ifNil: [
		self inform: 'Select a constant first.'.
		^ false ].
	oopValue := constant oop.
	oopValue ifNil: [
		self inform: 'The selected constant does not currently have a loaded value to inspect.'.
		^ false ].
	^ self openInspectorOnOop: oopValue
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> handleAutoloadSelectionChanged [
	| autoload |
	autoload := self selectedAutoload.
	(autoload notNil and: [ autoload ~~ self selectedAutoloadTableItem ]) ifTrue: [
		(self autoloadTable respondsTo: #selectItem:)
			ifTrue: [ self autoloadTable selectItem: autoload ]
			ifFalse: [
				(self autoloadTable respondsTo: #selectedItem:)
					ifTrue: [ self autoloadTable selectedItem: autoload ] ] ].
	self selectedAutoloadTableItem ifNotNil: [
		self clearTableSelection: self constantsTable ].
	self refreshRuntimeInfo
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> handleConstantSelectionChanged [
	| constant |
	constant := self selectedConstant.
	(constant notNil and: [ constant ~~ self selectedConstantTableItem ]) ifTrue: [
		(self constantsTable respondsTo: #selectItem:)
			ifTrue: [ self constantsTable selectItem: constant ]
			ifFalse: [
				(self constantsTable respondsTo: #selectedItem:)
					ifTrue: [ self constantsTable selectedItem: constant ] ] ].
	self selectedConstantTableItem ifNotNil: [
		self clearTableSelection: self autoloadTable ].
	self refreshRuntimeInfo
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectSelectedAutoload [
	| autoload oopValue |
	autoload := self selectedAutoload.
	autoload ifNil: [
		self inform: 'Select an autoload constant first.'.
		^ false ].
	oopValue := autoload oop.
	oopValue ifNil: [
		self inform: 'The selected autoload does not currently have an inspectable association object.'.
		^ false ].
	^ self openInspectorOnOop: oopValue
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectPromptedSessionStateKey [
	| rawKey key |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	rawKey := self requestInput: 'Session state key:' initialAnswer: '19'.
	rawKey := self trimmedRequest: rawKey.
	rawKey ifNil: [ ^ false ].
	key := [ rawKey asInteger ]
		on: Error
		do: [ nil ].
	key ifNil: [
		self inform: 'Enter a numeric session state key.'.
		^ false ].
	^ self inspectSessionStateAtKey: key
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectMaglevFinalizerRegistry [
	^ self inspectSessionStateAtKey: 19
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> inspectSessionStateAtKey: aKey [
	| registry oopValue |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	registry := [ session sessionStateAt: aKey ]
		on: Error
		do: [ :ex |
			self inform: 'Session state lookup failed: ', ex messageText.
			^ false ].
	registry ifNil: [
		self inform: 'Session state key ', aKey printString, ' is not set.'.
		^ false ].
	oopValue := self oopForInspectableObject: registry.
	oopValue ifNil: [
		self inform: 'Session state key ', aKey printString, ' does not currently have an inspectable remote oop.'.
		^ false ].
	^ self openInspectorOnOop: oopValue
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> initializeMaglevNamespaceActionButtons [
	self inspectFinalizerRegistryButton: self newButton.
	self inspectFinalizerRegistryButton
		label: 'Inspect Finalizers';
		icon: (self iconNamed: #smallInspectIt);
		yourself
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> loadSelectedFile [
	| namespace defaultFile fileName result |
	namespace := self selectedNamespace.
	namespace ifNil: [
		self inform: 'Select a namespace first.'.
		^ false ].
	defaultFile := self
		selectedConstant
		ifNil: [ '' ]
		ifNotNil: [ :constant | constant autoloadFile ifNil: [ '' ] ].
	fileName := self
		requestInput: 'Ruby file to load:'
		initialAnswer: defaultFile.
	fileName := self trimmedRequest: fileName.
	fileName ifNil: [ ^ false ].
	result := [ namespace loadFileNamed: fileName ]
		on: Error
		do: [ :ex |
			self inform: 'Load failed: ', ex messageText.
			^ false ].
	self refreshSelectedNamespaceRuntimeSurface.
	^ result ~= false
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> openBrowserOnClassNamed: aClassName [
	| browser |
	(self isSessionUsable not) ifTrue: [ ^ false ].
	browser := [ GbsBrowser openOn: session ]
		on: Error
		do: [ :ex |
			self inform: 'Could not open browser: ', ex messageText.
			^ false ].
	^ [ browser selectClassNamed: aClassName classSide: false method: nil ]
		on: Error
		do: [ :ex |
			self inform: 'Could not browse class ', aClassName asString, ': ', ex messageText.
			false ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> openNamespaceMirror: aNamespaceMirror [
	| rows existingRow selectedRow previousNamespace changingNamespace |
	aNamespaceMirror ifNil: [ ^ false ].
	namespacesTable ifNil: [ ^ false ].
	previousNamespace := self selectedNamespace.
	rows := [ namespacesTable items ]
		on: Error
		do: [ :ex | #() ].
	rows ifNil: [ rows := #() ].
	existingRow := rows
		detect: [ :each | self sameNamespaceMirror: each as: aNamespaceMirror ]
		ifNone: [ nil ].
	existingRow
		ifNil: [
			rows := rows copyWith: aNamespaceMirror.
			selectedRow := aNamespaceMirror ]
		ifNotNil: [
			rows := rows collect: [ :each |
				(self sameNamespaceMirror: each as: aNamespaceMirror)
					ifTrue: [ aNamespaceMirror ]
					ifFalse: [ each ] ].
			selectedRow := aNamespaceMirror ].
	changingNamespace := previousNamespace isNil
	ifTrue: [ true ]
	ifFalse: [ (self sameNamespaceMirror: previousNamespace as: selectedRow) not ].
	namespacesTable items: rows.
	(namespacesTable respondsTo: #selectItem:)
		ifTrue: [ namespacesTable selectItem: selectedRow ]
		ifFalse: [
			(namespacesTable respondsTo: #selectedItem:)
				ifTrue: [ namespacesTable selectedItem: selectedRow ] ].
	changingNamespace ifTrue: [
		self clearTableSelection: self constantsTable.
		self clearTableSelection: self autoloadTable ].
	self
		refreshSelectedNamespaceDetails;
		refreshRuntimeInfo.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> openInspectorOnOop: anOop [
	GbsInspector inspect: anOop session: session.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> openMethodQueryReferences: aCollection title: aString [
	GbsMethodQueryResultsPresenter
		openOn: session
		references: aCollection
		title: aString.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> openMethodQuery: aMethodQuery [
	GbsMethodQueryResultsPresenter
		openOn: session
		query: aMethodQuery.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> openSelectedConstantNamespace [
	| namespace |
	namespace := self selectedNamespaceForLookup.
	namespace ifNil: [
		self inform: 'Select a namespace, constant, or autoload first.'.
		^ false ].
	(namespace exists not) ifTrue: [
		self inform: 'The selected namespace target did not resolve to a browseable namespace.'.
		^ false ].
	^ self openNamespaceMirror: namespace
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> openParentNamespace [
	| namespace parent |
	namespace := self selectedNamespaceForLookup.
	namespace ifNil: [
		self inform: 'Select a namespace, constant, or autoload first.'.
		^ false ].
	parent := namespace parentNamespaceMirror.
	parent ifNil: [
		self inform: 'The selected namespace does not currently have a parent namespace.'.
		^ false ].
	^ self openNamespaceMirror: parent
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> openPromptedNamespace [
	| defaultName requestedName namespace |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	defaultName := self selectedNamespaceForLookup
		ifNil: [ '' ]
		ifNotNil: [ :each | each fullName ifNil: [ each displayName ifNil: [ '' ] ] ].
	requestedName := self
		requestInput: 'Namespace full name:'
		initialAnswer: defaultName.
	requestedName := self resolvedNamespaceLookupName: requestedName.
	requestedName ifNil: [ ^ false ].
	namespace := [ self namespaceMirrorForLookupName: requestedName ]
		on: Error
		do: [ :ex |
			self inform: 'Namespace lookup failed: ', ex messageText.
			^ false ].
	(namespace isNil or: [ namespace exists not ]) ifTrue: [
		self inform: 'Namespace ', requestedName, ' was not found.'.
		^ false ].
	^ self openNamespaceMirror: namespace
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> openTopLevelNamespace [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	^ self openNamespaceMirror: session topLevelNamespaceMirror
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> oopForInspectableObject: anObject [
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #oop) ifTrue: [ ^ anObject oop ].
	(anObject isInteger and: [ anObject > 20 ]) ifTrue: [ ^ anObject ].
	^ nil
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> namespaceMirrorForLookupName: aString [
	aString = 'Object'
		ifTrue: [ ^ session topLevelNamespaceMirror ].
	^ session namespaceMirrorForFullName: aString
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> parseSessionStateKeysFrom: aStringOrNil [
	| trimmed tokens keys |
	(aStringOrNil isNil or: [ aStringOrNil trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	trimmed := aStringOrNil trimBoth.
	tokens := (trimmed findTokens: ',') collect: #trimBoth thenReject: #isEmpty.
	tokens isEmpty ifTrue: [ ^ nil ].
	keys := tokens collect: [ :each |
		[ each asInteger ] on: Error do: [ ^ nil ] ].
	^ keys asArray
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> registerAutoloadForSelectedNamespace [
	| namespace constantName selectedConstant defaultFile fileName result |
	namespace := self selectedNamespace.
	namespace ifNil: [
		self inform: 'Select a namespace first.'.
		^ false ].
	(namespace supportsAutoload == false) ifTrue: [
		self inform: 'The selected namespace does not support Ruby autoload registration.'.
		^ false ].
	selectedConstant := self selectedConstant.
	constantName := selectedConstant
		ifNil: [
			self requestInput: 'Constant name for autoload:' initialAnswer: '' ]
		ifNotNil: [ selectedConstant name ].
	constantName := self trimmedRequest: constantName.
	constantName ifNil: [ ^ false ].
	defaultFile := selectedConstant
		ifNil: [ self defaultAutoloadFileForConstantName: constantName ]
		ifNotNil: [ selectedConstant autoloadFile ifNil: [ self defaultAutoloadFileForConstantName: constantName ] ].
	fileName := self requestInput: 'Ruby file for autoload:' initialAnswer: defaultFile.
	fileName := self trimmedRequest: fileName.
	fileName ifNil: [ ^ false ].
	result := [ namespace registerAutoload: constantName file: fileName ]
		on: Error
		do: [ :ex |
			self inform: 'Autoload registration failed: ', ex messageText.
			^ false ].
	self refreshSelectedNamespaceRuntimeSurface.
	^ result notNil
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> requireSelectedFile [
	| namespace defaultFile fileName result |
	namespace := self selectedNamespace.
	namespace ifNil: [
		self inform: 'Select a namespace first.'.
		^ false ].
	defaultFile := self
		selectedConstant
		ifNil: [ '' ]
		ifNotNil: [ :constant | constant autoloadFile ifNil: [ '' ] ].
	fileName := self
		requestInput: 'Ruby file to require:'
		initialAnswer: defaultFile.
	fileName := self trimmedRequest: fileName.
	fileName ifNil: [ ^ false ].
	result := [ namespace requireFileNamed: fileName ]
		on: Error
		do: [ :ex |
			self inform: 'Require failed: ', ex messageText.
			^ false ].
	self refreshSelectedNamespaceRuntimeSurface.
	^ result ~= false
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> requireSelectedAutoload [
	| namespace autoload fileName result |
	namespace := self selectedNamespace.
	namespace ifNil: [
		self inform: 'Select a namespace first.'.
		^ false ].
	autoload := self selectedAutoload.
	autoload ifNil: [
		self inform: 'Select an autoload constant first.'.
		^ false ].
	fileName := autoload autoloadFile.
	fileName ifNil: [
		self inform: 'The selected autoload does not currently have a file to require.'.
		^ false ].
	result := [ namespace requireFileNamed: fileName ]
		on: Error
		do: [ :ex |
			self inform: 'Autoload require failed: ', ex messageText.
			^ false ].
	self refreshSelectedNamespaceRuntimeSurface.
	^ result ~= false
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> refreshSelectedNamespaceRuntimeSurface [
	| namespace |
	namespace := self selectedNamespace.
	namespace ifNotNil: [
		[ namespace invalidate ]
			on: Error
			do: [ :ex | ] ].
	self refreshSelectedNamespaceDetails.
	self refreshRuntimeInfo
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> refreshAllTypedWrappers [
	| refreshed |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	refreshed := session refreshAllTypedWrapperClasses.
	self inform: 'Refreshed ', refreshed size printString, ' typed wrapper(s).'.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> refreshStaleTypedWrappers [
	| refreshed |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	refreshed := session refreshStaleTypedWrapperClasses.
	self inform: 'Refreshed ', refreshed size printString, ' stale typed wrapper(s).'.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> removeSelectedAutoload [
	| namespace autoload result |
	namespace := self selectedNamespace.
	namespace ifNil: [
		self inform: 'Select a namespace first.'.
		^ false ].
	autoload := self selectedAutoloadTableItem.
	autoload ifNil: [
		autoload := [ self selectedAutoload ]
			on: Exception
			do: [ :ex | nil ] ].
	autoload ifNil: [
		self inform: 'Select an autoload constant first.'.
		^ false ].
	result := [ namespace removeAutoload: autoload name ]
		on: Error
		do: [ :ex |
			self inform: 'Autoload removal failed: ', ex messageText.
			^ false ].
	[ self refreshSelectedNamespaceRuntimeSurface ]
		on: Error
		do: [ :ex | ].
	^ result ~= false
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> resolvedNamespaceLookupName: aStringOrNil [
	| trimmed tokens baseSegments resolvedSegments usesRelativeTokens |
	trimmed := self trimmedRequest: aStringOrNil.
	trimmed ifNil: [ ^ nil ].
	(trimmed beginsWith: '::')
		ifTrue: [ ^ trimmed size > 2
			ifTrue: [ trimmed copyFrom: 3 to: trimmed size ]
			ifFalse: [ 'Object' ] ].
	tokens := trimmed findTokens: '::'.
	tokens isEmpty ifTrue: [ ^ nil ].
	baseSegments := self selectedNamespaceLookupSegments.
	resolvedSegments := baseSegments asOrderedCollection.
	usesRelativeTokens := false.
	tokens do: [ :each |
		each = '.'
			ifTrue: [ usesRelativeTokens := true ]
			ifFalse: [
				each = '..'
					ifTrue: [
						usesRelativeTokens := true.
						resolvedSegments isEmpty
							ifTrue: [ ^ nil ].
						resolvedSegments := resolvedSegments allButLast ]
					ifFalse: [ resolvedSegments add: each ] ] ].
	resolvedSegments isEmpty ifTrue: [
		^ usesRelativeTokens
			ifTrue: [ 'Object' ]
			ifFalse: [ nil ] ].
	^ String streamContents: [ :stream |
		resolvedSegments doWithIndex: [ :each :index |
			index > 1 ifTrue: [ stream nextPutAll: '::' ].
			stream nextPutAll: each asString ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> selectedNamespaceLookupSegments [
	| namespace fullName |
	namespace := self selectedNamespaceForLookup.
	namespace ifNil: [ ^ #() ].
	namespace isSymbolListNamespace ifTrue: [ ^ #() ].
	fullName := namespace fullName.
	(fullName isNil or: [ fullName = 'Object' ])
		ifTrue: [ ^ #() ].
	^ namespace pathSegments
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> sameNamespaceMirror: aNamespaceMirror as: anotherNamespaceMirror [
	aNamespaceMirror == anotherNamespaceMirror ifTrue: [ ^ true ].
	(aNamespaceMirror isNil or: [ anotherNamespaceMirror isNil ]) ifTrue: [ ^ false ].
	aNamespaceMirror namespaceExpression = anotherNamespaceMirror namespaceExpression ifTrue: [ ^ true ].
	(aNamespaceMirror oop notNil and: [ aNamespaceMirror oop = anotherNamespaceMirror oop ])
		ifTrue: [ ^ true ].
	^ false
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> requestInput: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> uiChooseFrom: labels title: aTitle [
	^ UIManager default chooseFrom: labels title: aTitle
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> requestPositiveInteger: promptString initialAnswer: defaultString [
	| rawValue |
	rawValue := self requestInput: promptString initialAnswer: defaultString.
	(rawValue isNil or: [ rawValue trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ [ | value |
		value := rawValue trimBoth asInteger.
		value > 0 ifTrue: [ value ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> clearTableSelection: aTablePresenter [
	aTablePresenter ifNil: [ ^ self ].
	(aTablePresenter respondsTo: #selectItem:)
		ifTrue: [ aTablePresenter selectItem: nil ]
		ifFalse: [
			(aTablePresenter respondsTo: #selectedItem:)
				ifTrue: [ aTablePresenter selectedItem: nil ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> restoreAutoloadSelectionFrom: anAutoloadMirror [
	| match |
	anAutoloadMirror ifNil: [
		self clearTableSelection: self autoloadTable.
		^ self ].
	match := self autoloadTable items
		detect: [ :each |
			(self sameNamespaceMirror: each namespaceMirror as: anAutoloadMirror namespaceMirror)
				and: [
					each name = anAutoloadMirror name
						and: [
							(each oop notNil and: [ anAutoloadMirror oop notNil and: [ each oop = anAutoloadMirror oop ] ])
								or: [ each autoloadFile = anAutoloadMirror autoloadFile ] ] ] ]
		ifNone: [
			self autoloadTable items
				detect: [ :each |
					(self sameNamespaceMirror: each namespaceMirror as: anAutoloadMirror namespaceMirror)
						and: [ each name = anAutoloadMirror name ] ]
				ifNone: [ nil ] ].
	match
		ifNil: [ self clearTableSelection: self autoloadTable ]
		ifNotNil: [
		(self autoloadTable respondsTo: #selectItem:)
			ifTrue: [ self autoloadTable selectItem: match ]
			ifFalse: [
				(self autoloadTable respondsTo: #selectedItem:)
					ifTrue: [ self autoloadTable selectedItem: match ] ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> restoreConstantSelectionFrom: aConstantMirror [
	| match |
	aConstantMirror ifNil: [
		self clearTableSelection: self constantsTable.
		^ self ].
	match := self constantsTable items
		detect: [ :each |
			(self sameNamespaceMirror: each namespaceMirror as: aConstantMirror namespaceMirror)
				and: [
					each name = aConstantMirror name
						and: [ each oop = aConstantMirror oop ] ] ]
		ifNone: [
			self constantsTable items
				detect: [ :each |
					(self sameNamespaceMirror: each namespaceMirror as: aConstantMirror namespaceMirror)
						and: [ each name = aConstantMirror name ] ]
				ifNone: [ nil ] ].
	match
		ifNil: [ self clearTableSelection: self constantsTable ]
		ifNotNil: [
		(self constantsTable respondsTo: #selectItem:)
			ifTrue: [ self constantsTable selectItem: match ]
			ifFalse: [
				(self constantsTable respondsTo: #selectedItem:)
					ifTrue: [ self constantsTable selectedItem: match ] ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> restoreNamespaceSelectionFrom: aNamespaceMirror [
	| match |
	aNamespaceMirror ifNil: [
		self clearTableSelection: namespacesTable.
		^ self ].
	match := namespacesTable items
		detect: [ :each | self sameNamespaceMirror: each as: aNamespaceMirror ]
		ifNone: [ nil ].
	match
		ifNil: [ self clearTableSelection: namespacesTable ]
		ifNotNil: [
		(namespacesTable respondsTo: #selectItem:)
			ifTrue: [ namespacesTable selectItem: match ]
			ifFalse: [
				(namespacesTable respondsTo: #selectedItem:)
					ifTrue: [ namespacesTable selectedItem: match ] ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> runtimeReportText [
	| namespace lookupBaseInfo selectedConstant selectedAutoload parentName constantCount autoloadCount namespaceName namespacePath |
	namespace := self selectedNamespace.
	lookupBaseInfo := self runtimeLookupBaseInfo.
	selectedConstant := self selectedConstantTableItem
		ifNil: [ nil ]
		ifNotNil: [ self selectedConstant ].
	selectedAutoload := self selectedAutoloadTableItem
		ifNil: [ nil ]
		ifNotNil: [ self selectedAutoload ].
	constantCount := self constantsTable
		ifNil: [ 0 ]
		ifNotNil: [ (self constantsTable items ifNil: [ #() ]) size ].
	autoloadCount := self autoloadTable
		ifNil: [ 0 ]
		ifNotNil: [ (self autoloadTable items ifNil: [ #() ]) size ].
	namespaceName := self namespaceDisplayNameFor: namespace.
	namespacePath := self namespacePathDisplayNameFor: namespace.
	parentName := self namespaceParentDisplayNameFor: namespace.
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Ruby Runtime'; cr; cr.
		namespace ifNotNil: [
			stream
				nextPutAll: 'Selected Namespace: ';
				nextPutAll: namespaceName asString;
				cr;
				nextPutAll: 'Selected Namespace Source: ';
				nextPutAll: self selectedNamespaceSourceLabel;
				cr;
				nextPutAll: 'Namespace Path: ';
				nextPutAll: namespacePath asString;
				cr;
				nextPutAll: 'Parent Namespace: ';
				nextPutAll: parentName asString;
				cr;
				nextPutAll: 'Constants: ';
				nextPutAll: constantCount printString;
				cr;
				nextPutAll: 'Autoloads: ';
				nextPutAll: autoloadCount printString;
				cr;
				cr ].
		lookupBaseInfo ifNotNil: [
			stream
				nextPutAll: 'Lookup Base Source: ';
				nextPutAll: (lookupBaseInfo at: 1);
				cr;
				nextPutAll: 'Lookup Base Namespace: ';
				nextPutAll: (lookupBaseInfo at: 2);
				cr;
				nextPutAll: 'Lookup Base Parent: ';
				nextPutAll: (lookupBaseInfo at: 3);
				cr;
				cr ].
		session rubyRuntime
			appendRuntimeReportOn: stream
			namespace: namespace
			selectedConstant: selectedConstant
			selectedAutoload: selectedAutoload ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> namespaceDisplayNameFor: aNamespaceMirror [
	aNamespaceMirror ifNil: [ ^ 'unnamed' ].
	^ [ aNamespaceMirror cachedDisplayName
		ifNil: [ self namespaceFallbackDisplayNameFor: aNamespaceMirror ] ]
		on: Exception
		do: [ :ex | self namespaceFallbackDisplayNameFor: aNamespaceMirror ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> namespaceParentDisplayNameFor: aNamespaceMirror [
	^ self namespaceParentDisplayNameForFullName: (self namespacePathDisplayNameFor: aNamespaceMirror)
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> namespacePathDisplayNameFor: aNamespaceMirror [
	aNamespaceMirror ifNil: [ ^ 'unnamed' ].
	^ [
		aNamespaceMirror cachedFullName
			ifNil: [ self namespaceDisplayNameFor: aNamespaceMirror ] ]
		on: Exception
		do: [ :ex | self namespaceFallbackDisplayNameFor: aNamespaceMirror ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> namespaceParentDisplayNameForFullName: aStringOrNil [
	| path segments |
	aStringOrNil ifNil: [ ^ '(none)' ].
	path := aStringOrNil asString.
	(path = 'unnamed' or: [ path = '(not applicable)' ]) ifTrue: [ ^ '(none)' ].
	path = 'Object' ifTrue: [ ^ '(top-level)' ].
	segments := path findTokens: '::'.
	segments size <= 1 ifTrue: [ ^ '(top-level)' ].
	^ String streamContents: [ :stream |
		segments
			allButLast
			doWithIndex: [ :each :index |
				index > 1 ifTrue: [ stream nextPutAll: '::' ].
				stream nextPutAll: each asString ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> namespaceFallbackDisplayNameFor: aNamespaceMirror [
	| expression index |
	aNamespaceMirror ifNil: [ ^ 'unnamed' ].
	index := [ aNamespaceMirror index ] on: Error do: [ nil ].
	index ifNotNil: [ ^ 'Symbol List @', index printString ].
	expression := [ aNamespaceMirror namespaceExpression ] on: Error do: [ nil ].
	expression = 'Object nameSpace: 1' ifTrue: [ ^ 'Object' ].
	^ 'unnamed'
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> selectedNamespace [
	| namespace constant autoload |
	namespace := self selectedNamespaceTableItem.
	namespace ifNotNil: [ ^ namespace ].
	constant := self selectedConstantTableItem.
	constant ifNotNil: [ ^ constant namespaceMirror ].
	autoload := self selectedAutoloadTableItem.
	autoload ifNotNil: [ ^ autoload namespaceMirror ].
	^ nil
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> selectedConstant [
	| selected namespace autoload |
	selected := self selectedConstantTableItem.
	selected ifNotNil: [
		(selected respondsTo: #browsableName) ifTrue: [ ^ selected ].
		namespace := self selectedNamespace.
		namespace ifNil: [ ^ nil ].
		^ namespace constantMirrorAt: selected name ifAbsent: [ nil ] ].
	namespace := self selectedNamespace.
	autoload := self selectedAutoload.
	(namespace isNil or: [ autoload isNil ]) ifTrue: [ ^ nil ].
	^ namespace constantMirrorAt: autoload name ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> selectedNamespaceForLookup [
	| constant autoload targetNamespace |
	self selectedConstantTableItem ifNotNil: [
		constant := self selectedConstant.
		constant ifNotNil: [
			targetNamespace := [ constant targetNamespaceMirror ]
				on: Exception
				do: [ :ex | nil ].
			targetNamespace ifNotNil: [ ^ targetNamespace ] ] ].
	self selectedAutoloadTableItem ifNotNil: [
		autoload := self selectedAutoload.
		targetNamespace := [
			autoload
				ifNil: [ nil ]
				ifNotNil: [ :each |
					each constantMirror
						ifNil: [ nil ]
						ifNotNil: [ :constantMirror | constantMirror targetNamespaceMirror ] ] ]
			on: Exception
			do: [ :ex | nil ].
		targetNamespace ifNotNil: [ ^ targetNamespace ] ].
	^ self selectedNamespace
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> selectedNamespaceSourceLabel [
	self selectedNamespaceTableItem ifNotNil: [ ^ 'Selected Namespace Row' ].
	self selectedConstantTableItem ifNotNil: [ ^ 'Selected Constant Owner' ].
	self selectedAutoloadTableItem ifNotNil: [ ^ 'Selected Autoload Owner' ].
	^ 'None'
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> selectedNamespaceLookupSourceLabel [
	| constant autoload targetNamespace |
	self selectedConstantTableItem ifNotNil: [
		constant := self selectedConstant.
		targetNamespace := [ constant ifNil: [ nil ] ifNotNil: [ constant targetNamespaceMirror ] ]
			on: Exception
			do: [ :ex | nil ].
		targetNamespace ifNotNil: [ ^ 'Selected Constant Target' ].
		^ 'Selected Constant Owner' ].
	self selectedAutoloadTableItem ifNotNil: [
		autoload := self selectedAutoload.
		targetNamespace := [
			autoload
				ifNil: [ nil ]
				ifNotNil: [ :each |
					each constantMirror
						ifNil: [ nil ]
						ifNotNil: [ :constantMirror | constantMirror targetNamespaceMirror ] ] ]
			on: Exception
			do: [ :ex | nil ].
		targetNamespace ifNotNil: [ ^ 'Selected Autoload Target' ].
		^ 'Selected Autoload Owner' ].
	self selectedAutoloadTableItem ifNotNil: [ ^ 'Selected Autoload Owner' ].
	self selectedConstantTableItem ifNotNil: [ ^ 'Selected Constant Owner' ].
	^ 'Selected Namespace'
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> runtimeLookupBaseInfo [
	| namespace selectedConstant selectedAutoload targetName |
	namespace := self selectedNamespace.
	self selectedConstantTableItem ifNotNil: [
		selectedConstant := self selectedConstant.
		targetName := self runtimeLookupBaseTargetNameForConstant: selectedConstant.
		targetName ifNotNil: [
			^ { 'Selected Constant Target'. targetName. (self namespaceParentDisplayNameForFullName: targetName) } ].
		namespace ifNotNil: [
			^ { 'Selected Constant Owner'. (self namespaceDisplayNameFor: namespace). (self namespaceParentDisplayNameFor: namespace) } ].
		^ { 'Selected Constant Owner'. 'unnamed'. '(none)' } ].
	self selectedAutoloadTableItem ifNotNil: [
		selectedAutoload := self selectedAutoload.
		targetName := self runtimeLookupBaseTargetNameForAutoload: selectedAutoload.
		targetName ifNotNil: [
			^ { 'Selected Autoload Target'. targetName. (self namespaceParentDisplayNameForFullName: targetName) } ].
		namespace ifNotNil: [
			^ { 'Selected Autoload Owner'. (self namespaceDisplayNameFor: namespace). (self namespaceParentDisplayNameFor: namespace) } ].
		^ { 'Selected Autoload Owner'. 'unnamed'. '(none)' } ].
	namespace ifNil: [ ^ nil ].
	^ { 'Selected Namespace'. (self namespaceDisplayNameFor: namespace). (self namespaceParentDisplayNameFor: namespace) }
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> runtimeLookupBaseTargetNameForAutoload: anAutoloadMirror [
	| constantMirror |
	anAutoloadMirror ifNil: [ ^ nil ].
	constantMirror := [ anAutoloadMirror cachedConstantMirror ]
		on: Exception
		do: [ :ex | nil ].
	constantMirror ifNil: [ ^ nil ].
	^ self runtimeLookupBaseTargetNameForConstant: constantMirror
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> runtimeLookupBaseTargetNameForConstant: aConstantMirror [
	aConstantMirror ifNil: [ ^ nil ].
	^ aConstantMirror valueFullName
		ifNil: [ aConstantMirror targetDisplayName ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> selectedAutoload [
	| selected constant namespace |
	selected := self selectedAutoloadTableItem.
	selected ifNotNil: [
		(selected respondsTo: #stateLabel) ifTrue: [ ^ selected ].
		namespace := self selectedNamespace.
		namespace ifNil: [ ^ nil ].
		^ [
			namespace autoloadMirrors
				detect: [ :each |
					each name = selected name
						and: [
							(selected respondsTo: #autoloadFile)
								ifTrue: [ each autoloadFile = selected autoloadFile ]
								ifFalse: [ true ] ] ]
				ifNone: [ nil ] ]
			on: Error
			do: [ :ex |
				((selected respondsTo: #isAutoload) and: [ selected isAutoload ])
					ifTrue: [ selected ]
					ifFalse: [ nil ] ] ].
	namespace := self selectedNamespace.
	constant := self selectedConstantTableItem.
	((namespace notNil) and: [ constant notNil and: [ constant isAutoload ] ])
		ifTrue: [
			^ namespace autoloadMirrors
				detect: [ :each | each name = constant name ]
				ifNone: [ nil ] ].
	^ nil
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> selectedAutoloadTableItem [
	^ self autoloadTable
		ifNil: [ nil ]
		ifNotNil: [ self autoloadTable selectedItem ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> selectedConstantTableItem [
	^ self constantsTable
		ifNil: [ nil ]
		ifNotNil: [ self constantsTable selectedItem ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> selectedNamespaceTableItem [
	^ namespacesTable
		ifNil: [ nil ]
		ifNotNil: [ namespacesTable selectedItem ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> session: aSession [
	session := aSession
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> trimmedRequest: aStringOrNil [
	| trimmed |
	aStringOrNil ifNil: [ ^ nil ].
	trimmed := aStringOrNil asString trimBoth.
	trimmed isEmpty ifTrue: [ ^ nil ].
	^ trimmed
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsNamespacesPresenter >> writeSessionStateSummaryFor: anObject label: aLabel on: aStream [
	| sizeValue |
	(anObject isKindOf: Error) ifTrue: [
		aStream
			nextPutAll: aLabel;
			nextPutAll: ': ERROR - ';
			nextPutAll: anObject messageText;
			cr.
		^ self ].
	anObject ifNil: [
		aStream
			nextPutAll: aLabel;
			nextPutAll: ': (absent)';
			cr.
		^ self ].
	aStream
		nextPutAll: aLabel;
		nextPutAll: ': ';
		nextPutAll: anObject class name asString.
	(anObject respondsTo: #oop) ifTrue: [
		aStream
			nextPutAll: ' oop=';
			nextPutAll: anObject oop printString ].
	sizeValue := [
		((anObject respondsTo: #size) and: [ anObject class ~~ GbsProxy ])
			ifTrue: [ anObject size ]
			ifFalse: [ nil ] ]
		on: Error
		do: [ nil ].
	(sizeValue isInteger) ifTrue: [
			aStream
				nextPutAll: ' size=';
				nextPutAll: sizeValue printString ].
	aStream cr
]
