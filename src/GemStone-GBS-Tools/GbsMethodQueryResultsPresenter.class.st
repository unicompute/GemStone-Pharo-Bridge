Class {
	#name : 'GbsMethodQueryResultsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'references',
		'allReferences',
		'windowTitle',
		'mainMenu',
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
	methodsList := self newList.
	methodsList display: [ :each | each ifNil: [ '' ] ifNotNil: [ each asString ] ].
	sourceText := self newText.
	(sourceText respondsTo: #beNotEditable) ifTrue: [ sourceText beNotEditable ].
	countStatus := self newLabel label: ''.
	selectionStatus := self newLabel label: ''
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
	self reloadReferencesIntoList
]

{ #category : 'layout' }
GbsMethodQueryResultsPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: mainMenu expand: false;
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
	| split classPart selectorPart classSide className |
	(referenceString includesSubstring: '>>') ifFalse: [ ^ nil ].
	split := referenceString findString: '>>' startingAt: 1.
	classPart := (referenceString copyFrom: 1 to: split - 1) trimBoth.
	selectorPart := (referenceString copyFrom: split + 2 to: referenceString size) trimBoth.
	selectorPart isEmpty ifTrue: [ ^ nil ].
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
		addItem: [ :item | item name: 'Find Selector...'; action: [ self findSelector ] ];
		addItem: [ :item | item name: 'Filter Contains...'; action: [ self filterContains ] ];
		addItem: [ :item | item name: 'Clear Filter'; action: [ self clearFilter ] ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuMethod [
	^ self newMenu
		addItem: [ :item | item name: 'Browse'; action: [ self browseSelectedReference ] ];
		addItem: [ :item | item name: 'Senders'; action: [ self browseSendersOfSelected ] ];
		addItem: [ :item | item name: 'Implementors'; action: [ self browseImplementorsOfSelected ] ];
		addItem: [ :item | item name: 'Hierarchy Senders'; subMenu: self menuHierarchySenders ];
		addItem: [ :item | item name: 'Hierarchy Implementors'; subMenu: self menuHierarchyImplementors ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuHierarchySenders [
	^ self newMenu
		addItem: [ :item | item name: 'In Full Hierarchy'; action: [ self browseHierarchySendersOfSelected ] ];
		addItem: [ :item | item name: 'In Superclasses'; action: [ self browseHierarchySendersOfSelectedInScope: 'super' ] ];
		addItem: [ :item | item name: 'In This Class'; action: [ self browseHierarchySendersOfSelectedInScope: 'this' ] ];
		addItem: [ :item | item name: 'In Subclasses'; action: [ self browseHierarchySendersOfSelectedInScope: 'sub' ] ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuHierarchyImplementors [
	^ self newMenu
		addItem: [ :item | item name: 'In Full Hierarchy'; action: [ self browseHierarchyImplementorsOfSelected ] ];
		addItem: [ :item | item name: 'In Superclasses'; action: [ self browseHierarchyImplementorsOfSelectedInScope: 'super' ] ];
		addItem: [ :item | item name: 'In This Class'; action: [ self browseHierarchyImplementorsOfSelectedInScope: 'this' ] ];
		addItem: [ :item | item name: 'In Subclasses'; action: [ self browseHierarchyImplementorsOfSelectedInScope: 'sub' ] ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuSession [
	^ self newMenu
		addItem: [ :item | item name: 'Commit Transaction'; action: [ self commitSession ] ];
		addItem: [ :item | item name: 'Abort Transaction'; action: [ self abortSession ] ];
		addItem: [ :item | item name: 'Begin Transaction'; action: [ self beginSessionTransaction ] ];
		yourself
]

{ #category : 'menus' }
GbsMethodQueryResultsPresenter >> menuWindow [
	^ self newMenu
		addItem: [ :item | item name: 'Refresh'; action: [ self refreshSelectedSource ] ];
		addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ];
		yourself
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
		^ self ].
	parsed := self parseReference: referenceString asString.
	parsed ifNil: [
		selectionStatus label: 'Selection: ', referenceString asString.
		^ self ].
	className := parsed first.
	selector := parsed second.
	selectionStatus label: 'Method: #', selector, '    Class: ', className
]
