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
		'sourceText'
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
	"Spec lifecycle can call this after connectPresenters; refresh list immediately if present."
	methodsList ifNotNil: [
		(methodsList respondsTo: #items:) ifTrue: [ methodsList items: references ].
		references ifNotEmpty: [
			(methodsList respondsTo: #selectIndex:)
				ifTrue: [ methodsList selectIndex: 1 ]
				ifFalse: [
					(methodsList respondsTo: #selectItem:)
						ifTrue: [ methodsList selectItem: references first ] ].
			self showSourceForReference: references first ] ]
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
	sourceText := self newText.
	(sourceText respondsTo: #beNotEditable) ifTrue: [ sourceText beNotEditable ].
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
	methodsList items: references.
	(references notNil and: [ references isEmpty not ]) ifTrue: [
		(methodsList respondsTo: #selectIndex:)
			ifTrue: [ methodsList selectIndex: 1 ]
			ifFalse: [
				(methodsList respondsTo: #selectItem:)
					ifTrue: [ methodsList selectItem: references first ] ].
		self showSourceForReference: references first ]
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
		yourself
]

{ #category : 'initialization' }
GbsMethodQueryResultsPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: (windowTitle ifNil: [ 'Method Query Results' ] ifNotNil: [ windowTitle ]);
		initialExtent: 980 @ 720
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> showSourceForReference: referenceString [
	| parsed className selector classLookup script source |
	referenceString ifNil: [
		sourceText text: ''.
		^ self ].
	parsed := self parseReference: referenceString asString.
	parsed ifNil: [
		sourceText text: ''.
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
	sourceText text: (source ifNil: [ '' ] ifNotNil: [ source asString ])
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
		addItem: [ :item | item name: 'Refresh'; action: [ self clearFilter ] ];
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
	methodsList items: references.
	references ifNotEmpty: [
		(methodsList respondsTo: #selectIndex:) ifTrue: [ methodsList selectIndex: 1 ].
		self showSourceForReference: references first ].
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> clearFilter [
	references := allReferences copy.
	methodsList items: references.
	references ifNotEmpty: [
		(methodsList respondsTo: #selectIndex:) ifTrue: [ methodsList selectIndex: 1 ].
		self showSourceForReference: references first ]
]

{ #category : 'actions' }
GbsMethodQueryResultsPresenter >> browseSelectedReference [
	| ref worker |
	ref := methodsList selection selectedItem.
	ref ifNil: [ ^ self ].
	worker := GbsBrowser new.
	worker session: session.
	(worker openMethodReference: ref asString)
		ifFalse: [ UIManager default inform: 'Could not browse selected method.' ]
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
