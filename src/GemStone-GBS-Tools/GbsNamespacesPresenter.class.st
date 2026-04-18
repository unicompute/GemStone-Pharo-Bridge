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
		'inspectSessionStateButton',
		'inspectFinalizerRegistryButton',
		'browseConstantButton',
		'referencesButton',
		'implementorsButton',
		'sendersButton',
		'refreshButton',
		'closeButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
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
	inspectSessionStateButton action: [ self inspectPromptedSessionStateKey ].
	inspectFinalizerRegistryButton action: [ self inspectMaglevFinalizerRegistry ].
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
		add: inspectSessionStateButton;
		add: inspectFinalizerRegistryButton;
		add: browseConstantButton;
		add: referencesButton;
		add: implementorsButton;
		add: sendersButton;
		spacing: 8;
		yourself.
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
	inspectSessionStateButton := self newButton
		label: 'Inspect State...';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
	inspectFinalizerRegistryButton := self newButton
		label: 'Inspect Finalizers';
		icon: (self iconNamed: #smallInspectIt);
		yourself.
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
	| namespace constant queryName references title |
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
	references := [ namespace methodReferenceStringsToSymbol: queryName ]
		on: Error
		do: [ :ex |
			self inform: 'Namespace references query failed: ', ex messageText.
			^ false ].
	references isEmpty ifTrue: [
		self inform: 'No namespace-scoped matches found.'.
		^ false ].
	title := 'Namespace References to ', queryName, ' (', (namespace displayName ifNil: [ 'namespace' ]), ')'.
	^ self openMethodQueryReferences: references title: title
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
	| namespace selectorString references titlePrefix |
	namespace := self selectedNamespaceForLookup.
	namespace ifNil: [
		self inform: 'Select a namespace, constant, or autoload first.'.
		^ false ].
	selectorString := self requestInput: promptString initialAnswer: ''.
	selectorString := self trimmedRequest: selectorString.
	selectorString ifNil: [ ^ false ].
	references := [
		aSymbol = #senders
			ifTrue: [ namespace senderMethodReferenceStringsForSelector: selectorString ]
			ifFalse: [ namespace implementorMethodReferenceStringsForSelector: selectorString ] ]
		on: Error
		do: [ :ex |
			self inform: 'Namespace selector query failed: ', ex messageText.
			^ false ].
	references isEmpty ifTrue: [
		self inform: 'No namespace-scoped matches found.'.
		^ false ].
	titlePrefix := aSymbol = #senders
		ifTrue: [ 'Namespace Senders of ' ]
		ifFalse: [ 'Namespace Implementors of ' ].
	^ self
		openMethodQueryReferences: references
		title: titlePrefix, selectorString, ' (', (namespace displayName ifNil: [ 'namespace' ]), ')'
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
GbsNamespacesPresenter >> inspectMaglevFinalizerRegistry [
	^ self inspectSessionStateAtKey: 19
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
GbsNamespacesPresenter >> removeSelectedAutoload [
	| namespace autoload result |
	namespace := self selectedNamespace.
	namespace ifNil: [
		self inform: 'Select a namespace first.'.
		^ false ].
	autoload := self selectedAutoload.
	autoload ifNil: [
		self inform: 'Select an autoload constant first.'.
		^ false ].
	result := [ namespace removeAutoload: autoload name ]
		on: Error
		do: [ :ex |
			self inform: 'Autoload removal failed: ', ex messageText.
			^ false ].
	self refreshSelectedNamespaceRuntimeSurface.
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
	| namespace lookupBase lookupBaseParentName selectedConstant selectedAutoload parentName |
	namespace := self selectedNamespace.
	lookupBase := self selectedNamespaceForLookup.
	selectedConstant := self selectedConstantTableItem
		ifNil: [ nil ]
		ifNotNil: [ self selectedConstant ].
	selectedAutoload := self selectedAutoloadTableItem
		ifNil: [ nil ]
		ifNotNil: [ self selectedAutoload ].
	parentName := namespace
		ifNil: [ nil ]
		ifNotNil: [
			namespace isSymbolListNamespace
				ifTrue: [ '(not applicable)' ]
				ifFalse: [ namespace parentFullName ifNil: [ '(top-level)' ] ] ].
	lookupBaseParentName := self namespaceParentDisplayNameFor: lookupBase.
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Ruby Runtime'; cr; cr.
		namespace ifNotNil: [
			stream
				nextPutAll: 'Selected Namespace: ';
				nextPutAll: (namespace displayName ifNil: [ namespace className ifNil: [ 'unnamed' ] ]) asString;
				cr;
				nextPutAll: 'Selected Namespace Source: ';
				nextPutAll: self selectedNamespaceSourceLabel;
				cr;
				nextPutAll: 'Namespace Path: ';
				nextPutAll: (namespace fullName ifNil: [ namespace displayName ifNil: [ 'unnamed' ] ]) asString;
				cr;
				nextPutAll: 'Parent Namespace: ';
				nextPutAll: parentName asString;
				cr;
				nextPutAll: 'Constants: ';
				nextPutAll: namespace constantMirrors size printString;
				cr;
				nextPutAll: 'Autoloads: ';
				nextPutAll: namespace autoloadMirrors size printString;
				cr;
				cr ].
		lookupBase ifNotNil: [
			stream
				nextPutAll: 'Lookup Base Source: ';
				nextPutAll: self selectedNamespaceLookupSourceLabel;
				cr;
				nextPutAll: 'Lookup Base Namespace: ';
				nextPutAll: (self namespaceDisplayNameFor: lookupBase);
				cr;
				nextPutAll: 'Lookup Base Parent: ';
				nextPutAll: lookupBaseParentName asString;
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
	^ aNamespaceMirror fullName
		ifNil: [ aNamespaceMirror displayName ifNil: [ 'unnamed' ] ]
]

{ #category : 'private' }
GbsNamespacesPresenter >> namespaceParentDisplayNameFor: aNamespaceMirror [
	aNamespaceMirror ifNil: [ ^ '(none)' ].
	aNamespaceMirror isSymbolListNamespace ifTrue: [ ^ '(not applicable)' ].
	^ aNamespaceMirror parentFullName ifNil: [ '(top-level)' ]
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
	| constant targetNamespace |
	constant := self selectedConstant.
	constant ifNotNil: [
		targetNamespace := [ constant targetNamespaceMirror ]
			on: Error
			do: [ :ex | nil ].
		((targetNamespace notNil) and: [ targetNamespace exists ])
			ifTrue: [ ^ targetNamespace ] ].
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
	| constant targetNamespace |
	constant := self selectedConstant.
	constant ifNotNil: [
		targetNamespace := [ constant targetNamespaceMirror ]
			on: Error
			do: [ :ex | nil ].
		((targetNamespace notNil) and: [ targetNamespace exists ])
			ifTrue: [
				self selectedAutoloadTableItem ifNotNil: [ ^ 'Selected Autoload Target' ].
				self selectedConstantTableItem ifNotNil: [ ^ 'Selected Constant Target' ].
				^ 'Selected Namespace Target' ] ].
	self selectedAutoloadTableItem ifNotNil: [ ^ 'Selected Autoload Owner' ].
	self selectedConstantTableItem ifNotNil: [ ^ 'Selected Constant Owner' ].
	^ 'Selected Namespace'
]

{ #category : 'private' }
GbsNamespacesPresenter >> selectedAutoload [
	| selected constant namespace |
	selected := self selectedAutoloadTableItem.
	selected ifNotNil: [
		(selected respondsTo: #stateLabel) ifTrue: [ ^ selected ].
		namespace := self selectedNamespace.
		namespace ifNil: [ ^ nil ].
		^ namespace autoloadMirrors
			detect: [ :each |
				each name = selected name
					and: [
						(selected respondsTo: #autoloadFile)
							ifTrue: [ each autoloadFile = selected autoloadFile ]
							ifFalse: [ true ] ] ]
			ifNone: [ nil ] ].
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
