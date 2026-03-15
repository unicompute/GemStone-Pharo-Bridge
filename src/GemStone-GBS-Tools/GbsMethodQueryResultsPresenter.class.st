Class {
	#name : 'GbsMethodQueryResultsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'references',
		'allReferences',
		'windowTitle',
		'mainMenu',
		'actionBar',
		'btnBrowse',
		'btnSenders',
		'btnImplementors',
		'btnHierarchySenders',
		'btnHierarchyImplementors',
		'btnFileOut',
		'btnRefresh',
		'methodsList',
		'sourceText',
		'countStatus',
		'selectionStatus'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsMethodQueryResultsPresenter class >> openOn: aSession references: aCollection title: aString [
	| presenter |
	presenter := self new.
	presenter
		session: aSession;
		references: aCollection;
		windowTitle: aString;
		open.
	^ presenter
]

{ #category : 'accessing' }
GbsMethodQueryResultsPresenter >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbsMethodQueryResultsPresenter >> references: aCollection [
	references := (self normalizeReferences: aCollection)
		collect: [ :each | each ifNil: [ '' ] ifNotNil: [ each asString ] ].
	allReferences := references copy.
	self reloadReferencesIntoList
]

{ #category : 'accessing' }
GbsMethodQueryResultsPresenter >> windowTitle: aString [
	windowTitle := (aString ifNil: [ '' ] ifNotNil: [ aString asString ])
]

{ #category : 'initialization' }
GbsMethodQueryResultsPresenter >> initializePresenters [
	references ifNil: [ references := #() ].
	allReferences ifNil: [ allReferences := references copy ].
	mainMenu := self buildMenuBar.
	btnBrowse := self newButton
		label: 'Browse';
		icon: (self iconForBrowseAction);
		action: [ self browseSelectedReference ];
		yourself.
	btnHierarchySenders := self newButton
		label: 'Hierarchy Senders';
		icon: (self iconForHierarchySendersAction);
		action: [ self browseHierarchySendersOfSelected ];
		yourself.
	btnHierarchyImplementors := self newButton
		label: 'Hierarchy Implementors';
		icon: (self iconForHierarchyImplementorsAction);
		action: [ self browseHierarchyImplementorsOfSelected ];
		yourself.
	btnSenders := self newButton
		label: 'Senders';
		icon: (self iconForSendersAction);
		action: [ self browseSendersOfSelected ];
		yourself.
	btnImplementors := self newButton
		label: 'Implementors';
		icon: (self iconForImplementorsAction);
		action: [ self browseImplementorsOfSelected ];
		yourself.
	btnFileOut := self newButton
		label: 'File Out As...';
		icon: (self iconForFileOutAction);
		action: [ self fileOutSelectedReferenceAs ];
		yourself.
	btnRefresh := self newButton
		label: 'Refresh';
		icon: (self iconForRefreshAction);
		action: [ self refreshSelectedSource ];
		yourself.
	actionBar := self buildActionBar.
	methodsList := self newList.
	methodsList display: [ :each | each ifNil: [ '' ] ifNotNil: [ each asString ] ].
	sourceText := self newText.
	(sourceText respondsTo: #beNotEditable) ifTrue: [ sourceText beNotEditable ].
	countStatus := self newLabel label: ''.
	selectionStatus := self newLabel label: ''.
	self updateActionEnablement
]

{ #category : 'initialization' }
GbsMethodQueryResultsPresenter >> connectPresenters [
	references ifNil: [ references := #() ].
	methodsList whenSelectionChangedDo: [ :selection |
		| selected listSelection |
		selected := (selection respondsTo: #selectedItem)
			ifTrue: [ selection selectedItem ]
			ifFalse: [
				listSelection := methodsList selection.
				(listSelection notNil and: [ listSelection respondsTo: #selectedItem ])
					ifTrue: [ listSelection selectedItem ]
					ifFalse: [ nil ] ].
		self showSourceForReference: selected ].
	(methodsList respondsTo: #whenActivatedDo:) ifTrue: [
		methodsList whenActivatedDo: [ :selection |
			(self selectedReferenceFromEvent: selection)
				ifNotNil: [ self browseSelectedReference ] ] ].
	(methodsList respondsTo: #whenSubmitDo:) ifTrue: [
		methodsList whenSubmitDo: [ :selection |
			(self selectedReferenceFromEvent: selection)
				ifNotNil: [ self browseSelectedReference ] ] ].
	(methodsList respondsTo: #contextMenu:) ifTrue: [
		methodsList contextMenu: [ self menuMethodPopup ] ].
	self reloadReferencesIntoList
]

{ #category : 'layout' }
GbsMethodQueryResultsPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: mainMenu expand: false;
		add: actionBar expand: false;
		add: ((SpPanedLayout newTopToBottom
			positionOfSlider: 45 percent;
			add: methodsList;
			add: sourceText;
			yourself));
		add: (SpBoxLayout newLeftToRight
			add: countStatus;
			add: selectionStatus;
			spacing: 16;
			yourself)
			expand: false;
		yourself
]

{ #category : 'layout' }
GbsMethodQueryResultsPresenter >> buildActionBar [
	^ SpBoxLayout newLeftToRight
		spacing: 6;
		add: btnBrowse expand: false;
		add: btnHierarchySenders expand: false;
		add: btnHierarchyImplementors expand: false;
		add: btnSenders expand: false;
		add: btnImplementors expand: false;
		add: btnFileOut expand: false;
		add: btnRefresh expand: false;
		yourself
]

{ #category : 'initialization' }
GbsMethodQueryResultsPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: (windowTitle ifNil: [ 'Method Query Results' ] ifNotNil: [ windowTitle ]);
		initialExtent: 980 @ 720.
	self reloadReferencesIntoList
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> showSourceForReference: referenceString [
	| parsed className selector classLookup script source |
	referenceString ifNil: [
		sourceText text: ''.
		self updateStatusForReference: nil.
		^ self ].
	parsed := self parseReference: referenceString asString.
	parsed ifNil: [
		sourceText text: ''.
		self updateStatusForReference: referenceString.
		^ self ].
	className := parsed first.
	selector := parsed second.
	classLookup := parsed third
		ifTrue: [ '(System myUserProfile symbolList objectNamed: #', className, ') class' ]
		ifFalse: [ 'System myUserProfile symbolList objectNamed: #', className ].
	script := '[
		| cls meth |
		cls := ', classLookup, '.
		cls ifNil: [ ^ '''' ].
		meth := cls compiledMethodAt: #''', (selector copyReplaceAll: '''' with: ''''''), ''' ifAbsent: [ nil ].
		meth ifNil: [ '''' ] ifNotNil: [ meth sourceString ]
	] value'.
	source := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	sourceText text: (source ifNil: [ '' ] ifNotNil: [ source asString ]).
	self updateStatusForReference: referenceString
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> parseReference: referenceString [
	| split classPart selectorPart classSide className selectorToken |
	(referenceString includesSubstring: '>>') ifFalse: [ ^ nil ].
	split := referenceString findString: '>>' startingAt: 1.
	classPart := (referenceString copyFrom: 1 to: split - 1) trimBoth.
	selectorPart := (referenceString copyFrom: split + 2 to: referenceString size) trimBoth.
	selectorPart isEmpty ifTrue: [ ^ nil ].
	(selectorPart beginsWith: '#') ifTrue: [ selectorPart := selectorPart allButFirst trimBoth ].
	(selectorPart includesSubstring: '{')
		ifTrue: [ selectorPart := (selectorPart copyUpTo: ${) trimBoth ].
	(selectorPart includesSubstring: ' ')
		ifTrue: [
			| parts |
			parts := selectorPart substrings.
			selectorToken := parts isEmpty ifTrue: [ '' ] ifFalse: [ parts first ].
			selectorPart := selectorToken ifNil: [ '' ] ifNotNil: [ selectorToken trimBoth ] ].
	classSide := classPart endsWith: ' class'.
	className := classSide
		ifTrue: [ classPart copyFrom: 1 to: classPart size - 6 ]
		ifFalse: [ classPart ].
	className isEmpty ifTrue: [ ^ nil ].
	^ { className. selectorPart. classSide }
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> buildMenuBar [
	^ self newMenuBar
		addGroup: [ :group |
			group
				addItem: [ :item | item name: 'Find'; subMenu: self menuFind ];
				addItem: [ :item | item name: 'Method'; subMenu: self menuMethod ];
				addItem: [ :item | item name: 'Session'; subMenu: self menuSession ];
				addItem: [ :item | item name: 'Window'; subMenu: self menuWindow ] ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuFind [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item |
				item
					name: 'Find Selector...';
					icon: self iconForFindAction;
					action: [ self findSelector ] ] ];
		addGroup: [ :group |
			group addItem: [ :item |
				item
					name: 'Filter Contains...';
					icon: self iconForFindAction;
					action: [ self filterContains ] ].
			group addItem: [ :item |
				item
					name: 'Clear Filter';
					action: [ self clearFilter ] ] ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuMethod [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item |
				item
					name: 'Browse';
					icon: self iconForBrowseAction;
					action: [ self browseSelectedReference ].
				(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ].
			group addItem: [ :item |
				item
					name: 'Browse Hierarchy';
					icon: self iconForHierarchyImplementorsAction;
					action: [ self browseHierarchyImplementorsOfSelected ].
				(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ] ];
		addGroup: [ :group |
			group addItem: [ :item |
				item
					name: 'Senders';
					icon: self iconForSendersAction;
					action: [ self browseSendersOfSelected ].
				(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ].
			group addItem: [ :item |
				item
					name: 'Implementors';
					icon: self iconForImplementorsAction;
					action: [ self browseImplementorsOfSelected ].
				(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ].
			group addItem: [ :item | item name: 'Hierarchy Senders'; subMenu: self menuHierarchySenders ].
			group addItem: [ :item | item name: 'Hierarchy Implementors'; subMenu: self menuHierarchyImplementors ] ];
		addGroup: [ :group |
			group addItem: [ :item |
				item
					name: 'File Out As...';
					icon: self iconForFileOutAction;
					action: [ self fileOutSelectedReferenceAs ].
				(item respondsTo: #enabled:) ifTrue: [ item enabled: self canFileOutSelectedReference ] ] ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuHierarchySenders [
	^ self newMenu
		addItem: [ :item |
			item name: 'In Full Hierarchy'; action: [ self browseHierarchySendersOfSelected ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ];
		addItem: [ :item |
			item name: 'In Superclasses'; action: [ self browseHierarchySendersOfSelectedInScope: 'super' ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ];
		addItem: [ :item |
			item name: 'In This Class'; action: [ self browseHierarchySendersOfSelectedInScope: 'this' ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ];
		addItem: [ :item |
			item name: 'In Subclasses'; action: [ self browseHierarchySendersOfSelectedInScope: 'sub' ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuHierarchyImplementors [
	^ self newMenu
		addItem: [ :item |
			item name: 'In Full Hierarchy'; action: [ self browseHierarchyImplementorsOfSelected ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ];
		addItem: [ :item |
			item name: 'In Superclasses'; action: [ self browseHierarchyImplementorsOfSelectedInScope: 'super' ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ];
		addItem: [ :item |
			item name: 'In This Class'; action: [ self browseHierarchyImplementorsOfSelectedInScope: 'this' ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ];
		addItem: [ :item |
			item name: 'In Subclasses'; action: [ self browseHierarchyImplementorsOfSelectedInScope: 'sub' ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuSession [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Commit Transaction'; action: [ self commitSession ] ].
			group addItem: [ :item | item name: 'Abort Transaction'; action: [ self abortSession ] ].
			group addItem: [ :item | item name: 'Begin Transaction'; action: [ self beginSessionTransaction ] ] ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuWindow [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item |
				item
					name: 'Refresh';
					icon: self iconForRefreshAction;
					action: [ self refreshSelectedSource ].
				(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ] ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuMethodPopup [
	^ self newMenu
		addItem: [ :item |
			item
				name: 'Browse';
				icon: self iconForBrowseAction;
				action: [ self browseSelectedReference ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ] ;
		addItem: [ :item |
			item
				name: 'Senders';
				icon: self iconForSendersAction;
				action: [ self browseSendersOfSelected ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ] ;
		addItem: [ :item |
			item
				name: 'Implementors';
				icon: self iconForImplementorsAction;
				action: [ self browseImplementorsOfSelected ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRunMethodScopedActions ] ] ;
		addItem: [ :item | item name: 'Hierarchy Senders'; subMenu: self menuHierarchySenders ] ;
		addItem: [ :item | item name: 'Hierarchy Implementors'; subMenu: self menuHierarchyImplementors ] ;
		addItem: [ :item |
			item
				name: 'File Out As...';
				icon: self iconForFileOutAction;
				action: [ self fileOutSelectedReferenceAs ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canFileOutSelectedReference ] ] ;
		yourself
]

{ #category : 'icons' }
GbsMethodQueryResultsPresenter >> iconForBrowseAction [
	^ self iconNamed: #smallSystemBrowser
]

{ #category : 'icons' }
GbsMethodQueryResultsPresenter >> iconForFindAction [
	^ self iconNamed: #smallFind
]

{ #category : 'icons' }
GbsMethodQueryResultsPresenter >> iconForSendersAction [
	^ self iconNamed: #smallForward
]

{ #category : 'icons' }
GbsMethodQueryResultsPresenter >> iconForImplementorsAction [
	^ self iconNamed: #smallInspectIt
]

{ #category : 'icons' }
GbsMethodQueryResultsPresenter >> iconForHierarchySendersAction [
	^ self iconNamed: #glamorousGoTop
]

{ #category : 'icons' }
GbsMethodQueryResultsPresenter >> iconForHierarchyImplementorsAction [
	^ self iconNamed: #glamorousUp
]

{ #category : 'icons' }
GbsMethodQueryResultsPresenter >> iconForFileOutAction [
	^ self iconNamed: #smallSave
]

{ #category : 'icons' }
GbsMethodQueryResultsPresenter >> iconForRefreshAction [
	^ self iconNamed: #smallUpdate
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> findSelector [
	| token idx items |
	token := UIManager default request: 'Find selector:' initialAnswer: ''.
	(token isNil or: [ token trimBoth isEmpty ]) ifTrue: [ ^ self ].
	items := references ifNil: [ #() ].
	idx := (1 to: items size)
		detect: [ :i | (items at: i) asString includesSubstring: token trimBoth ]
		ifNone: [ 0 ].
	idx = 0 ifTrue: [ ^ UIManager default inform: 'No match found.' ].
	(methodsList respondsTo: #selectIndex:) ifTrue: [ methodsList selectIndex: idx ].
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> filterContains [
	| token filtered |
	token := UIManager default request: 'Filter methods containing:' initialAnswer: ''.
	(token isNil or: [ token trimBoth isEmpty ]) ifTrue: [ ^ self ].
	filtered := allReferences select: [ :each | each asString includesSubstring: token trimBoth ].
	references := filtered asArray.
	self reloadReferencesIntoList
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> clearFilter [
	references := allReferences copy.
	self reloadReferencesIntoList
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> reloadReferencesIntoList [
	methodsList ifNil: [ ^ self ].
	(methodsList respondsTo: #items:)
		ifTrue: [ methodsList items: (references ifNil: [ #() ] ifNotNil: [ references asArray ]) ].
	(references notNil and: [ references isEmpty not ]) ifTrue: [
		(methodsList respondsTo: #selectIndex:)
			ifTrue: [ methodsList selectIndex: 1 ]
			ifFalse: [
				(methodsList respondsTo: #selectItem:)
					ifTrue: [ methodsList selectItem: references first ] ].
		self showSourceForReference: references first ]
	ifFalse: [
		sourceText ifNotNil: [ sourceText text: '' ].
		self updateStatusForReference: nil ].
	self updateCountStatus
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> canRunMethodScopedActions [
	| ref |
	ref := self selectedReference.
	^ ref notNil and: [ (ref asString trimBoth isEmpty) not ]
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> canFileOutSelectedReference [
	^ self canRunMethodScopedActions and: [ (self currentSourceText trimBoth isEmpty) not ]
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> currentSourceText [
	sourceText ifNil: [ ^ '' ].
	(sourceText respondsTo: #text)
		ifTrue: [ ^ sourceText text ifNil: [ '' ] ifNotNil: [ :t | t asString ] ].
	^ ''
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> updateActionEnablement [
	| canAct canFile |
	canAct := self canRunMethodScopedActions.
	canFile := self canFileOutSelectedReference.
	{
		btnBrowse.
		btnSenders.
		btnImplementors.
		btnHierarchySenders.
		btnHierarchyImplementors.
		btnRefresh.
	} do: [ :button |
		(button notNil and: [ button respondsTo: #enabled: ])
			ifTrue: [ button enabled: canAct ] ].
	(btnFileOut notNil and: [ btnFileOut respondsTo: #enabled: ])
		ifTrue: [ btnFileOut enabled: canFile ]
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> browseSelectedReference [
	| ref worker |
	ref := self selectedReference.
	ref ifNil: [ ^ self ].
	worker := GbsBrowser new.
	worker session: session.
	(worker openMethodReference: ref asString)
		ifFalse: [ UIManager default inform: 'Could not browse selected method.' ]
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> browseSendersOfSelected [
	^ self openQueryForSelectedSelectorMode: 'senders' titlePrefix: 'Senders of '
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> browseImplementorsOfSelected [
	^ self openQueryForSelectedSelectorMode: 'implementors' titlePrefix: 'Implementors of '
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> browseHierarchySendersOfSelected [
	^ self openQueryForSelectedSelectorMode: 'hierarchySenders' titlePrefix: 'Hierarchy Senders of ' hierarchyScope: 'full'
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> browseHierarchyImplementorsOfSelected [
	^ self openQueryForSelectedSelectorMode: 'hierarchyImplementors' titlePrefix: 'Hierarchy Implementors of ' hierarchyScope: 'full'
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> browseHierarchySendersOfSelectedInScope: scopeString [
	^ self openQueryForSelectedSelectorMode: 'hierarchySenders' titlePrefix: 'Hierarchy Senders of ' hierarchyScope: scopeString
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> browseHierarchyImplementorsOfSelectedInScope: scopeString [
	^ self openQueryForSelectedSelectorMode: 'hierarchyImplementors' titlePrefix: 'Hierarchy Implementors of ' hierarchyScope: scopeString
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> openQueryForSelectedSelectorMode: modeString titlePrefix: prefixString [
	^ self openQueryForSelectedSelectorMode: modeString titlePrefix: prefixString hierarchyScope: 'full'
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> openQueryForSelectedSelectorMode: modeString titlePrefix: prefixString hierarchyScope: scopeString [
	| ref parsed selector worker queryRefs title rootClassName |
	ref := self selectedReference.
	ref ifNil: [ ^ self ].
	parsed := self parseReference: ref asString.
	parsed ifNil: [ ^ self ].
	rootClassName := parsed first.
	selector := parsed second.
	worker := GbsBrowser new.
	worker session: session.
	queryRefs := [
		(modeString = 'hierarchySenders' or: [ modeString = 'hierarchyImplementors' ])
			ifTrue: [ worker queryServerMethodsForSelector: selector mode: modeString rootClassName: rootClassName hierarchyScope: scopeString ]
			ifFalse: [ worker queryServerMethodsForSelector: selector mode: modeString ] ]
		on: Error
		do: [ #() ].
	queryRefs isEmpty ifTrue: [ ^ UIManager default inform: 'No matches found.' ].
	title := self queryResultsTitleForSelector: selector modePrefix: prefixString count: queryRefs size.
	^ self class openOn: session references: queryRefs title: title
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> queryResultsTitleForSelector: selector modePrefix: prefixString count: aCount [
	| sessionPart |
	sessionPart := (session respondsTo: #sessionId)
		ifTrue: [ 'Session ', session sessionId asString, ' ' ]
		ifFalse: [ '' ].
	^ sessionPart, prefixString, selector asString, ' (', aCount asString, ')'
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> commitSession [
	(session respondsTo: #commitTransaction)
		ifTrue: [ ^ session commitTransaction ].
	^ false
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> abortSession [
	(session respondsTo: #abort)
		ifTrue: [ session abort. ^ true ].
	^ false
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> beginSessionTransaction [
	(session respondsTo: #beginTransaction)
		ifTrue: [ ^ session beginTransaction ].
	(session respondsTo: #begin)
		ifTrue: [ ^ session begin ].
	^ false
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> closeWindow [
	(self respondsTo: #window)
		ifTrue: [ self window ifNotNil: [ :w | w close ] ]
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> refreshSelectedSource [
	| ref |
	ref := self selectedReference.
	ref ifNil: [ ^ self ].
	self showSourceForReference: ref
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> fileOutSelectedReferenceAs [
	| ref parsed className selector source defaultPath path |
	ref := self selectedReference.
	ref ifNil: [ ^ UIManager default inform: 'Select a method first.' ].
	parsed := self parseReference: ref asString.
	parsed ifNil: [ ^ UIManager default inform: 'Could not parse selected method reference.' ].
	className := parsed first.
	selector := parsed second.
	source := sourceText ifNil: [ '' ] ifNotNil: [ sourceText text asString ].
	source isEmpty ifTrue: [ ^ UIManager default inform: 'No source to file out.' ].
	defaultPath := self defaultExportPathFor: className, '-', selector, '.st'.
	path := self requestExportPath: defaultPath.
	path ifNil: [ ^ self ].
	self writeExport: source toPath: path.
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> selectedReference [
	| selection |
	methodsList ifNil: [ ^ nil ].
	selection := methodsList selection.
	(selection notNil and: [ selection respondsTo: #selectedItem ])
		ifTrue: [ ^ selection selectedItem ].
	^ nil
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> selectedReferenceFromEvent: selectionEvent [
	selectionEvent ifNotNil: [
		(selectionEvent respondsTo: #selectedItem)
			ifTrue: [
				selectionEvent selectedItem ifNotNil: [ :selected | ^ selected ] ] ].
	^ self selectedReference
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> requestExportPath: defaultPath [
	| answer |
	answer := UIManager default request: 'Export file path:' initialAnswer: defaultPath.
	(answer isNil or: [ answer isEmpty ]) ifTrue: [ ^ nil ].
	^ answer
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> defaultExportPathFor: fileName [
	^ (FileSystem workingDirectory / fileName) fullName
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> writeExport: text toPath: pathString [
	| ref |
	ref := pathString asFileReference.
	[ ref ensureDelete. ref writeStreamDo: [ :str | str nextPutAll: text ] ]
		on: Error
		do: [ :ex | ^ UIManager default inform: 'File out failed: ', ex messageText ].
	UIManager default inform: 'Wrote ', pathString.
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> normalizeReferences: aCollection [
	| rawItems normalized |
	rawItems := aCollection ifNil: [ #() ] ifNotNil: [
		(aCollection isString or: [ aCollection isSymbol ])
			ifTrue: [ aCollection asString splitOn: Character lf ]
			ifFalse: [ aCollection asArray ] ].
	normalized := OrderedCollection new.
	rawItems do: [ :each |
		| s lines tabs className selectorName firstNumeric classIndex selectorIndex parsed |
		s := each ifNil: [ '' ] ifNotNil: [ each asString ].
		s := s copyReplaceAll: String crlf with: String lf.
		s := s copyReplaceAll: String cr with: String lf.
		lines := (s splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty.
		lines do: [ :line |
			(line includesSubstring: '>>')
				ifTrue: [
					parsed := self parseReference: line.
					parsed ifNotNil: [ normalized add: parsed first, '>>', parsed second ] ]
				ifFalse: [
					tabs := (line splitOn: Character tab) collect: #trimBoth thenReject: #isEmpty.
					(tabs size >= 2)
						ifTrue: [
							firstNumeric := tabs first notEmpty
								and: [ tabs first allSatisfy: [ :ch | ch isDigit ] ].
							classIndex := firstNumeric ifTrue: [ 2 ] ifFalse: [ 1 ].
							selectorIndex := classIndex + 1.
							className := tabs at: classIndex ifAbsent: [ '' ].
							selectorName := tabs at: selectorIndex ifAbsent: [ '' ].
							(className isEmpty or: [ selectorName isEmpty ])
								ifFalse: [
									parsed := self parseReference: className, '>>', selectorName.
									parsed ifNotNil: [ normalized add: parsed first, '>>', parsed second ] ] ] ] ] ].
	normalized isEmpty ifTrue: [
		"Fallback so pane is never blank when upstream sends unexpected rows."
		normalized := (rawItems
			collect: [ :ea | (ea ifNil: [ '' ] ifNotNil: [ ea asString ]) trimBoth ]
			thenReject: [ :line | line isEmpty ]) asArray.
		^ normalized ].
	normalized := normalized asSet asArray asSortedCollection asArray.
	^ normalized
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> updateCountStatus [
	countStatus ifNil: [ ^ self ].
	countStatus label: 'Methods: ', (references ifNil: [ 0 ] ifNotNil: [ references size ]) asString
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> updateStatusForReference: referenceString [
	| parsed className selector |
	selectionStatus ifNil: [ ^ self ].
	referenceString ifNil: [
		selectionStatus label: 'Selection: <none>'.
		self updateActionEnablement.
		^ self ].
	parsed := self parseReference: referenceString asString.
	parsed ifNil: [
		selectionStatus label: 'Selection: ', referenceString asString.
		self updateActionEnablement.
		^ self ].
	className := parsed first.
	selector := parsed second.
	selectionStatus label: 'Method: #', selector, '    Class: ', className.
	self updateActionEnablement
]
