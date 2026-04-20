Class {
	#name : 'GbsNamespacesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'namespacesTable',
		'constantsTable',
		'autoloadTable',
		'runtimeText',
		'requireButton',
		'requireAutoloadButton',
		'loadButton',
		'clearPersistentFeaturesButton',
		'autoloadButton',
		'removeAutoloadButton',
		'inspectAutoloadButton',
		'inspectConstantButton',
		'jumpNamespaceButton',
		'openNamespaceButton',
		'upNamespaceButton',
		'topNamespaceButton',
		'wrapperActionsButton',
		'runtimeReportsButton',
		'inspectSessionStateButton',
		'inspectFinalizerRegistryButton',
		'browseConstantButton',
		'referencesButton',
		'implementorsButton',
		'sendersButton',
		'refreshButton',
		'closeButton'
	],
	#category : 'GemStone-GBS-MagLev-Tools',
	#package : 'GemStone-GBS-MagLev-Tools'
}

{ #category : 'instance creation' }
GbsNamespacesPresenter class >> openOn: aSession [
	| presenter |
	aSession ifNil: [ ^ self inform: 'No connected GemStone session. Please login first.' ].
	presenter := self new.
	presenter
		session: aSession;
		open.
	^ presenter
]

{ #category : 'private' }
GbsNamespacesPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]

{ #category : 'initialization' }
GbsNamespacesPresenter >> connectPresenters [
	(namespacesTable respondsTo: #whenSelectionChangedDo:) ifTrue: [
		namespacesTable whenSelectionChangedDo: [ :selection |
			self
				refreshSelectedNamespaceDetails;
				refreshRuntimeInfo ] ].
	(constantsTable respondsTo: #whenSelectionChangedDo:) ifTrue: [
		constantsTable whenSelectionChangedDo: [ :selection |
			self handleConstantSelectionChanged ] ].
	(autoloadTable respondsTo: #whenSelectionChangedDo:) ifTrue: [
		autoloadTable whenSelectionChangedDo: [ :selection |
			self handleAutoloadSelectionChanged ] ].
	refreshButton action: [ self refreshAll ].
	requireButton action: [ self requireSelectedFile ].
	requireAutoloadButton action: [ self requireSelectedAutoload ].
	loadButton action: [ self loadSelectedFile ].
	clearPersistentFeaturesButton action: [ self clearPersistentLoadedFeatures ].
	autoloadButton action: [ self registerAutoloadForSelectedNamespace ].
	removeAutoloadButton action: [ self removeSelectedAutoload ].
	inspectAutoloadButton action: [ self inspectSelectedAutoload ].
	inspectConstantButton action: [ self inspectSelectedConstant ].
	jumpNamespaceButton action: [ self openPromptedNamespace ].
	openNamespaceButton action: [ self openSelectedConstantNamespace ].
	upNamespaceButton action: [ self openParentNamespace ].
	topNamespaceButton action: [ self openTopLevelNamespace ].
	wrapperActionsButton action: [ self browseWrapperActionChooser ].
	runtimeReportsButton action: [ self browseRuntimeReportChooser ].
	inspectSessionStateButton action: [ self inspectPromptedSessionStateKey ].
	self connectMaglevNamespaceActionButtons.
	browseConstantButton action: [ self browseSelectedConstantClass ].
	referencesButton action: [ self browseNamespaceReferencesToSelectedConstant ].
	implementorsButton action: [ self browseNamespaceImplementorsOfPromptedSelector ].
	sendersButton action: [ self browseNamespaceSendersOfPromptedSelector ].
	closeButton action: [ self closeWindow ].
	self refreshAll
]

{ #category : 'layout' }
GbsNamespacesPresenter >> defaultLayout [
	| detailsRow actionRow windowRow |
	detailsRow := SpBoxLayout newLeftToRight
		add: constantsTable;
		add: autoloadTable;
		spacing: 8;
		yourself.
	actionRow := SpBoxLayout newLeftToRight
		add: requireButton;
		add: requireAutoloadButton;
		add: loadButton;
		add: clearPersistentFeaturesButton;
		add: autoloadButton;
		add: removeAutoloadButton;
		add: inspectAutoloadButton;
		add: inspectConstantButton;
		add: jumpNamespaceButton;
		add: openNamespaceButton;
		add: upNamespaceButton;
		add: topNamespaceButton;
		add: wrapperActionsButton;
		add: runtimeReportsButton;
		add: inspectSessionStateButton;
		add: browseConstantButton;
		add: referencesButton;
		add: implementorsButton;
		add: sendersButton;
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
		add: runtimeText;
		add: actionRow expand: false;
		add: windowRow expand: false;
		yourself
]

{ #category : 'initialization' }
GbsNamespacesPresenter >> initializePresenters [
	namespacesTable := self newTable.
	namespacesTable
		addColumn: (SpStringTableColumn title: 'Index' evaluated: [ :row | row index ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Namespace' evaluated: [ :row | row displayName ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Class' evaluated: [ :row | row className ifNil: [ '' ] ]);
		yourself.
	constantsTable := self newTable.
	constantsTable
		addColumn: (SpStringTableColumn title: 'Constant' evaluated: [ :row | row name ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Target' evaluated: [ :row | row targetDisplayName ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Value Class' evaluated: [ :row | row valueClassName ifNil: [ '' ] ]);
		yourself.
	autoloadTable := self newTable.
	autoloadTable
		addColumn: (SpStringTableColumn title: 'Autoload Constant' evaluated: [ :row | row name ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'File' evaluated: [ :row | row autoloadFile ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Target' evaluated: [ :row | row targetDisplayName ifNil: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'State' evaluated: [ :row | row stateLabel ifNil: [ '' ] ]);
		yourself.
	runtimeText := self newText.
	requireButton := self newButton
		label: 'Require...';
		icon: (self iconNamed: #smallOpen);
		yourself.
	requireAutoloadButton := self newButton
		label: 'Require Autoload';
		icon: (self iconNamed: #smallOpen);
		yourself.
	loadButton := self newButton
		label: 'Load...';
		icon: (self iconNamed: #smallOpen);
		yourself.
	clearPersistentFeaturesButton := self newButton
		label: 'Clear Persistent Features';
		icon: (self iconNamed: #smallCancel);
		yourself.
	autoloadButton := self newButton
		label: 'Register Autoload...';
		icon: (self iconNamed: #add);
		yourself.
	removeAutoloadButton := self newButton
		label: 'Remove Autoload';
		icon: (self iconNamed: #smallDelete);
		yourself.
	inspectAutoloadButton := self newButton
		label: 'Inspect Autoload';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
	inspectConstantButton := self newButton
		label: 'Inspect Constant';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
	jumpNamespaceButton := self newButton
		label: 'Go To Namespace...';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	openNamespaceButton := self newButton
		label: 'Open Namespace';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	upNamespaceButton := self newButton
		label: 'Up Namespace';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	topNamespaceButton := self newButton
		label: 'Top Namespace';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	wrapperActionsButton := self newButton
		label: 'Wrapper Actions';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
	runtimeReportsButton := self newButton
		label: 'Session Tools';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
	inspectSessionStateButton := self newButton
		label: 'Inspect State...';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
	self initializeMaglevNamespaceActionButtons.
	browseConstantButton := self newButton
		label: 'Browse Constant';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	referencesButton := self newButton
		label: 'References';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	implementorsButton := self newButton
		label: 'Implementors...';
		icon: (self iconNamed: #glamorousBrowse);
		yourself.
	sendersButton := self newButton
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

{ #category : 'initialization' }
GbsNamespacesPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone Namespaces';
		initialExtent: 980 @ 620
]

{ #category : 'private' }
GbsNamespacesPresenter >> isSessionUsable [
	session ifNil: [ ^ false ].
	(session respondsTo: #isLoggedIn)
		ifTrue: [ ^ [ session isLoggedIn == true ] on: Error do: [ false ] ].
	^ true
]

{ #category : 'private' }
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

{ #category : 'private' }
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

{ #category : 'actions' }
GbsNamespacesPresenter >> refreshAll [
	self refreshNamespaces
]

{ #category : 'actions' }
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

{ #category : 'actions' }
GbsNamespacesPresenter >> refreshRuntimeInfo [
	| report |
	runtimeText ifNil: [ ^ self ].
	(self isSessionUsable not) ifTrue: [
		runtimeText text: ''.
		^ self ].
	report := [ self runtimeReportText ]
		on: Error
		do: [ :ex | 'Runtime info failed: ', ex messageText ].
	runtimeText text: report
]

{ #category : 'actions' }
GbsNamespacesPresenter >> refreshSelectedNamespaceDetails [
	| namespace constants autoloads previousConstantSelection previousAutoloadSelection |
	constantsTable ifNil: [ ^ self ].
	autoloadTable ifNil: [ ^ self ].
	previousConstantSelection := self selectedConstantTableItem.
	previousAutoloadSelection := self selectedAutoloadTableItem.
	namespace := self selectedNamespace.
	namespace ifNil: [
		constantsTable items: #().
		autoloadTable items: #().
		self clearTableSelection: constantsTable.
		self clearTableSelection: autoloadTable.
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
	constantsTable items: constants.
	autoloadTable items: autoloads.
	self restoreConstantSelectionFrom: previousConstantSelection.
	self restoreAutoloadSelectionFrom: previousAutoloadSelection
]

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
GbsNamespacesPresenter >> browseNamespaceImplementorsOfPromptedSelector [
	^ self
		browsePromptedNamespaceSelectorQuery:
			'Selector for namespace implementors:'
		mode: #implementors
]

{ #category : 'actions' }
GbsNamespacesPresenter >> browseNamespaceSendersOfPromptedSelector [
	^ self
		browsePromptedNamespaceSelectorQuery:
			'Selector for namespace senders:'
		mode: #senders
]

{ #category : 'actions' }
GbsNamespacesPresenter >> browseNamedObjectCacheReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session namedObjectCacheReportText.
	^ true
]

{ #category : 'actions' }
GbsNamespacesPresenter >> clearNamedObjectCache [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	session clearNamedObjectCache.
	self inform: 'Named object cache cleared.'.
	^ true
]

{ #category : 'actions' }
GbsNamespacesPresenter >> browseSessionStateReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: (session objectSpaceDiagnostics reportTextForKeys: #(19)).
	^ true
]

{ #category : 'actions' }
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

{ #category : 'layout' }
GbsNamespacesPresenter >> addNamespaceActionButtonsTo: actionRow [
	inspectFinalizerRegistryButton ifNotNil: [ actionRow add: inspectFinalizerRegistryButton ]
]

{ #category : 'actions' }
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

{ #category : 'actions' }
GbsNamespacesPresenter >> browseTypedWrapperAutoloadReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: (GbsSessionManager typedWrapperAutoloadReportTextForSession: session).
	^ true
]

{ #category : 'actions' }
GbsNamespacesPresenter >> browseRubyLoadPathReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session rubyRuntime loadPathReportText.
	^ true
]

{ #category : 'actions' }
GbsNamespacesPresenter >> browseRubyLoadedFeaturesReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session rubyRuntime loadedFeaturesReportText.
	^ true
]

{ #category : 'actions' }
GbsNamespacesPresenter >> browseRubyPersistentLoadedFeaturesReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session rubyRuntime persistentLoadedFeaturesReportText.
	^ true
]

{ #category : 'actions' }
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

{ #category : 'actions' }
GbsNamespacesPresenter >> browseMaglevFinalizerRegistryReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session objectSpaceDiagnostics finalizerRegistryReport text.
	^ true
]

{ #category : 'actions' }
GbsNamespacesPresenter >> browseTypedWrapperLifecycleReport [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	self inform: session typedWrapperLifecycleReportText.
	^ true
]

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'initialization' }
GbsNamespacesPresenter >> connectMaglevNamespaceActionButtons [
	inspectFinalizerRegistryButton action: [ self inspectMaglevFinalizerRegistry ]
]

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'private' }
GbsNamespacesPresenter >> defaultAutoloadFileForConstantName: aString [
	| trimmed |
	trimmed := aString ifNil: [ '' ] ifNotNil: [ aString asString trimBoth ].
	trimmed isEmpty ifTrue: [ ^ '' ].
	^ 'lib/', trimmed, '.rb'
]

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
GbsNamespacesPresenter >> handleAutoloadSelectionChanged [
	| autoload |
	autoload := self selectedAutoload.
	(autoload notNil and: [ autoload ~~ self selectedAutoloadTableItem ]) ifTrue: [
		(autoloadTable respondsTo: #selectItem:)
			ifTrue: [ autoloadTable selectItem: autoload ]
			ifFalse: [
				(autoloadTable respondsTo: #selectedItem:)
					ifTrue: [ autoloadTable selectedItem: autoload ] ] ].
	self selectedAutoloadTableItem ifNotNil: [
		self clearTableSelection: constantsTable ].
	self refreshRuntimeInfo
]

{ #category : 'actions' }
GbsNamespacesPresenter >> handleConstantSelectionChanged [
	| constant |
	constant := self selectedConstant.
	(constant notNil and: [ constant ~~ self selectedConstantTableItem ]) ifTrue: [
		(constantsTable respondsTo: #selectItem:)
			ifTrue: [ constantsTable selectItem: constant ]
			ifFalse: [
				(constantsTable respondsTo: #selectedItem:)
					ifTrue: [ constantsTable selectedItem: constant ] ] ].
	self selectedConstantTableItem ifNotNil: [
		self clearTableSelection: autoloadTable ].
	self refreshRuntimeInfo
]

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
GbsNamespacesPresenter >> inspectMaglevFinalizerRegistry [
	^ self inspectSessionStateAtKey: 19
]

{ #category : 'actions' }
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

{ #category : 'initialization' }
GbsNamespacesPresenter >> initializeMaglevNamespaceActionButtons [
	inspectFinalizerRegistryButton := self newButton
		label: 'Inspect Finalizers';
		icon: (self iconNamed: #smallInspectIt);
		yourself
]

{ #category : 'actions' }
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

{ #category : 'ui' }
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

{ #category : 'ui' }
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
		self clearTableSelection: constantsTable.
		self clearTableSelection: autoloadTable ].
	self
		refreshSelectedNamespaceDetails;
		refreshRuntimeInfo.
	^ true
]

{ #category : 'ui' }
GbsNamespacesPresenter >> openInspectorOnOop: anOop [
	GbsInspector inspect: anOop session: session.
	^ true
]

{ #category : 'ui' }
GbsNamespacesPresenter >> openMethodQueryReferences: aCollection title: aString [
	GbsMethodQueryResultsPresenter
		openOn: session
		references: aCollection
		title: aString.
	^ true
]

{ #category : 'ui' }
GbsNamespacesPresenter >> openMethodQuery: aMethodQuery [
	GbsMethodQueryResultsPresenter
		openOn: session
		query: aMethodQuery.
	^ true
]

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
GbsNamespacesPresenter >> openTopLevelNamespace [
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	^ self openNamespaceMirror: session topLevelNamespaceMirror
]

{ #category : 'private' }
GbsNamespacesPresenter >> oopForInspectableObject: anObject [
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #oop) ifTrue: [ ^ anObject oop ].
	(anObject isInteger and: [ anObject > 20 ]) ifTrue: [ ^ anObject ].
	^ nil
]

{ #category : 'private' }
GbsNamespacesPresenter >> namespaceMirrorForLookupName: aString [
	aString = 'Object'
		ifTrue: [ ^ session topLevelNamespaceMirror ].
	^ session namespaceMirrorForFullName: aString
]

{ #category : 'private' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
GbsNamespacesPresenter >> refreshAllTypedWrappers [
	| refreshed |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	refreshed := session refreshAllTypedWrapperClasses.
	self inform: 'Refreshed ', refreshed size printString, ' typed wrapper(s).'.
	^ true
]

{ #category : 'actions' }
GbsNamespacesPresenter >> refreshStaleTypedWrappers [
	| refreshed |
	(self isSessionUsable not) ifTrue: [
		self inform: 'Select or log into a GemStone session first.'.
		^ false ].
	refreshed := session refreshStaleTypedWrapperClasses.
	self inform: 'Refreshed ', refreshed size printString, ' stale typed wrapper(s).'.
	^ true
]

{ #category : 'actions' }
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

{ #category : 'private' }
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

{ #category : 'private' }
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

{ #category : 'private' }
GbsNamespacesPresenter >> sameNamespaceMirror: aNamespaceMirror as: anotherNamespaceMirror [
	aNamespaceMirror == anotherNamespaceMirror ifTrue: [ ^ true ].
	(aNamespaceMirror isNil or: [ anotherNamespaceMirror isNil ]) ifTrue: [ ^ false ].
	aNamespaceMirror namespaceExpression = anotherNamespaceMirror namespaceExpression ifTrue: [ ^ true ].
	(aNamespaceMirror oop notNil and: [ aNamespaceMirror oop = anotherNamespaceMirror oop ])
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'ui' }
GbsNamespacesPresenter >> requestInput: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : 'ui' }
GbsNamespacesPresenter >> uiChooseFrom: labels title: aTitle [
	^ UIManager default chooseFrom: labels title: aTitle
]

{ #category : 'private' }
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

{ #category : 'private' }
GbsNamespacesPresenter >> clearTableSelection: aTablePresenter [
	aTablePresenter ifNil: [ ^ self ].
	(aTablePresenter respondsTo: #selectItem:)
		ifTrue: [ aTablePresenter selectItem: nil ]
		ifFalse: [
			(aTablePresenter respondsTo: #selectedItem:)
				ifTrue: [ aTablePresenter selectedItem: nil ] ]
]

{ #category : 'private' }
GbsNamespacesPresenter >> restoreAutoloadSelectionFrom: anAutoloadMirror [
	| match |
	anAutoloadMirror ifNil: [
		self clearTableSelection: autoloadTable.
		^ self ].
	match := autoloadTable items
		detect: [ :each |
			(self sameNamespaceMirror: each namespaceMirror as: anAutoloadMirror namespaceMirror)
				and: [
					each name = anAutoloadMirror name
						and: [
							(each oop notNil and: [ anAutoloadMirror oop notNil and: [ each oop = anAutoloadMirror oop ] ])
								or: [ each autoloadFile = anAutoloadMirror autoloadFile ] ] ] ]
		ifNone: [
			autoloadTable items
				detect: [ :each |
					(self sameNamespaceMirror: each namespaceMirror as: anAutoloadMirror namespaceMirror)
						and: [ each name = anAutoloadMirror name ] ]
				ifNone: [ nil ] ].
	match
		ifNil: [ self clearTableSelection: autoloadTable ]
		ifNotNil: [
		(autoloadTable respondsTo: #selectItem:)
			ifTrue: [ autoloadTable selectItem: match ]
			ifFalse: [
				(autoloadTable respondsTo: #selectedItem:)
					ifTrue: [ autoloadTable selectedItem: match ] ] ]
]

{ #category : 'private' }
GbsNamespacesPresenter >> restoreConstantSelectionFrom: aConstantMirror [
	| match |
	aConstantMirror ifNil: [
		self clearTableSelection: constantsTable.
		^ self ].
	match := constantsTable items
		detect: [ :each |
			(self sameNamespaceMirror: each namespaceMirror as: aConstantMirror namespaceMirror)
				and: [
					each name = aConstantMirror name
						and: [ each oop = aConstantMirror oop ] ] ]
		ifNone: [
			constantsTable items
				detect: [ :each |
					(self sameNamespaceMirror: each namespaceMirror as: aConstantMirror namespaceMirror)
						and: [ each name = aConstantMirror name ] ]
				ifNone: [ nil ] ].
	match
		ifNil: [ self clearTableSelection: constantsTable ]
		ifNotNil: [
		(constantsTable respondsTo: #selectItem:)
			ifTrue: [ constantsTable selectItem: match ]
			ifFalse: [
				(constantsTable respondsTo: #selectedItem:)
					ifTrue: [ constantsTable selectedItem: match ] ] ]
]

{ #category : 'private' }
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

{ #category : 'private' }
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
	constantCount := constantsTable
		ifNil: [ 0 ]
		ifNotNil: [ (constantsTable items ifNil: [ #() ]) size ].
	autoloadCount := autoloadTable
		ifNil: [ 0 ]
		ifNotNil: [ (autoloadTable items ifNil: [ #() ]) size ].
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

{ #category : 'private' }
GbsNamespacesPresenter >> namespaceDisplayNameFor: aNamespaceMirror [
	aNamespaceMirror ifNil: [ ^ 'unnamed' ].
	^ [ aNamespaceMirror cachedDisplayName
		ifNil: [ self namespaceFallbackDisplayNameFor: aNamespaceMirror ] ]
		on: Exception
		do: [ :ex | self namespaceFallbackDisplayNameFor: aNamespaceMirror ]
]

{ #category : 'private' }
GbsNamespacesPresenter >> namespaceParentDisplayNameFor: aNamespaceMirror [
	^ self namespaceParentDisplayNameForFullName: (self namespacePathDisplayNameFor: aNamespaceMirror)
]

{ #category : 'private' }
GbsNamespacesPresenter >> namespacePathDisplayNameFor: aNamespaceMirror [
	aNamespaceMirror ifNil: [ ^ 'unnamed' ].
	^ [
		aNamespaceMirror cachedFullName
			ifNil: [ self namespaceDisplayNameFor: aNamespaceMirror ] ]
		on: Exception
		do: [ :ex | self namespaceFallbackDisplayNameFor: aNamespaceMirror ]
]

{ #category : 'private' }
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

{ #category : 'private' }
GbsNamespacesPresenter >> namespaceFallbackDisplayNameFor: aNamespaceMirror [
	| expression index |
	aNamespaceMirror ifNil: [ ^ 'unnamed' ].
	index := [ aNamespaceMirror index ] on: Error do: [ nil ].
	index ifNotNil: [ ^ 'Symbol List @', index printString ].
	expression := [ aNamespaceMirror namespaceExpression ] on: Error do: [ nil ].
	expression = 'Object nameSpace: 1' ifTrue: [ ^ 'Object' ].
	^ 'unnamed'
]

{ #category : 'private' }
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

{ #category : 'private' }
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

{ #category : 'private' }
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

{ #category : 'private' }
GbsNamespacesPresenter >> selectedNamespaceSourceLabel [
	self selectedNamespaceTableItem ifNotNil: [ ^ 'Selected Namespace Row' ].
	self selectedConstantTableItem ifNotNil: [ ^ 'Selected Constant Owner' ].
	self selectedAutoloadTableItem ifNotNil: [ ^ 'Selected Autoload Owner' ].
	^ 'None'
]

{ #category : 'private' }
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

{ #category : 'private' }
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

{ #category : 'private' }
GbsNamespacesPresenter >> runtimeLookupBaseTargetNameForAutoload: anAutoloadMirror [
	| constantMirror |
	anAutoloadMirror ifNil: [ ^ nil ].
	constantMirror := [ anAutoloadMirror cachedConstantMirror ]
		on: Exception
		do: [ :ex | nil ].
	constantMirror ifNil: [ ^ nil ].
	^ self runtimeLookupBaseTargetNameForConstant: constantMirror
]

{ #category : 'private' }
GbsNamespacesPresenter >> runtimeLookupBaseTargetNameForConstant: aConstantMirror [
	aConstantMirror ifNil: [ ^ nil ].
	^ aConstantMirror valueFullName
		ifNil: [ aConstantMirror targetDisplayName ]
]

{ #category : 'private' }
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

{ #category : 'private' }
GbsNamespacesPresenter >> selectedAutoloadTableItem [
	^ autoloadTable
		ifNil: [ nil ]
		ifNotNil: [ autoloadTable selectedItem ]
]

{ #category : 'private' }
GbsNamespacesPresenter >> selectedConstantTableItem [
	^ constantsTable
		ifNil: [ nil ]
		ifNotNil: [ constantsTable selectedItem ]
]

{ #category : 'private' }
GbsNamespacesPresenter >> selectedNamespaceTableItem [
	^ namespacesTable
		ifNil: [ nil ]
		ifNotNil: [ namespacesTable selectedItem ]
]

{ #category : 'private' }
GbsNamespacesPresenter >> session: aSession [
	session := aSession
]

{ #category : 'private' }
GbsNamespacesPresenter >> trimmedRequest: aStringOrNil [
	| trimmed |
	aStringOrNil ifNil: [ ^ nil ].
	trimmed := aStringOrNil asString trimBoth.
	trimmed isEmpty ifTrue: [ ^ nil ].
	^ trimmed
]

{ #category : 'private' }
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
