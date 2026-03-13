Class {
	#name : 'GbsBrowser',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'mainMenu',
		'autoCommitEnabled',
		'dictionariesList',
		'classesList',
		'protocolsList',
		'methodsList',
		'sourceText',
		'metaCheckbox'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsBrowser class >> openOn: aSession [
	| browser loggedIn |
	aSession ifNil: [ ^ self inform: 'You must log into GemStone first!' ].
	loggedIn := true.
	(aSession respondsTo: #isLoggedIn) ifTrue: [
		loggedIn := [ aSession isLoggedIn == true ] on: Error do: [ false ]
	].
	loggedIn ifFalse: [ ^ self inform: 'You must log into GemStone first!' ].
	
	^ [
		browser := self new.
		browser session: aSession.
		browser loadDictionaries.
		browser open.
		browser
	] on: Error do: [ :ex |
		self inform: ('Could not open GemStone browser: {1} ({2}) in {3}
Top senders:
{4}' format: {
			ex messageText.
			ex class name.
			(ex signalerContext ifNil: [ '<none>' ] ifNotNil: [ :ctx | ctx printString ]).
			((self stackSummaryFrom: ex signalerContext maxFrames: 12) ifNil: [ '<none>' ])
		}).
		nil
	]
]

{ #category : 'private' }
GbsBrowser class >> stackSummaryFrom: aContext maxFrames: maxFrames [
	| stream ctx idx |
	aContext ifNil: [ ^ '<none>' ].
	stream := String new writeStream.
	ctx := aContext.
	idx := 0.
	[ (ctx notNil) and: [ idx < maxFrames ] ] whileTrue: [
		stream
			nextPutAll: idx asString;
			nextPutAll: ': ';
			nextPutAll: ctx printString;
			lf.
		ctx := ctx sender.
		idx := idx + 1
	].
	^ stream contents
]

{ #category : 'actions' }
GbsBrowser >> acceptText: newText [
	^ self compileMethod: newText
]

{ #category : 'actions' }
GbsBrowser >> classSelected: className [
	| script rawData categories metaString |
	
	className ifNil: [ 
		protocolsList items: #(). methodsList items: #(). sourceText text: ''. 
		^ self 
	].
	
	"The Metaclass switch!"
	metaString := (metaCheckbox state == true) ifTrue: [ ' class' ] ifFalse: [ '' ].
	
	script := '[
		| cls stream |
		cls := (System myUserProfile symbolList objectNamed: #', className, ')', metaString, '.
		stream := WriteStream on: String new.
		cls ifNotNil: [
			cls categoryNames asSortedCollection do: [ :cat | stream nextPutAll: cat asString; lf ].
		].
		stream contents
	] value'.
	
	rawData := session executeAndFetch: script.
	rawData := rawData
		ifNil: [ '' ]
		ifNotNil: [ rawData asString ].
	categories := (rawData splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty.
	categories := {'-- all --'} asOrderedCollection addAll: categories; yourself.
	protocolsList items: categories.
]

{ #category : 'actions' }
GbsBrowser >> compileMethod: newSource [
	| className protocol metaString cleanSource escapedSource script rawData |
	
	className := classesList selection selectedItem.
	className ifNil: [ ^ self inform: 'No class selected!' ].
	
	"If they have '-- all --' selected, default to a standard category"
	protocol := protocolsList selection selectedItem.
	(protocol isNil or: [ protocol = '-- all --' ]) ifTrue: [ protocol := 'as yet unclassified' ].
	
	metaString := (metaCheckbox state == true) ifTrue: [ ' class' ] ifFalse: [ '' ].
	
	"Sanitize line endings and escape single quotes for the script compiler"
	cleanSource := newSource copyReplaceAll: String cr with: String lf.
	escapedSource := cleanSource copyReplaceAll: '''' with: ''''''.
	
	script := '[
		| cls source result |
		cls := (System myUserProfile symbolList objectNamed: #', className, ')', metaString, '.
		source := ''', escapedSource, '''.
		
		"GemStone returns an Array of errors if it fails, or the GsMethod if it succeeds"
		result := cls compileMethod: source category: #''', protocol, '''.
		(result isKindOf: Array) 
			ifTrue: [ ''Error: Compilation failed. Check GemStone syntax.'' ] 
			ifFalse: [ ''Success'' ]
	] value'.
	
	rawData := session executeAndFetch: script.
	
	(rawData beginsWith: 'Error:') 
		ifTrue: [ self inform: rawData ]
		ifFalse: [ 
			self maybeAutoCommit.
			self inform: 'Compiled successfully!'.
			"Refresh the method list so the new method appears!"
			self protocolSelected: protocolsList selection selectedItem.
		].
]

{ #category : 'layout' }
GbsBrowser >> defaultLayout [
	^ SpBoxLayout newVertical
		add: mainMenu expand: false;
		add: (SpBoxLayout newHorizontal
			add: dictionariesList;
			add: (SpBoxLayout newVertical
				add: classesList;
				add: metaCheckbox expand: false; "Tucks it neatly under the classes"
				yourself);
			add: protocolsList;
			add: methodsList;
			yourself);
		add: sourceText;
		yourself
]

{ #category : 'actions' }
GbsBrowser >> dictionarySelected: dictName [
	"Fetches the classes for the selected dictionary"
	| script rawData classes |
	
	dictName ifNil: [ ^ classesList items: #() ].
	
	script := '[
		| dict classNames stream |
		dict := System myUserProfile symbolList objectNamed: #', dictName, '.
		classNames := dict keys select: [ :each | (dict at: each) isBehavior ].
		stream := WriteStream on: String new.
		classNames asSortedCollection do: [ :cls | stream nextPutAll: cls asString; lf ].
		stream contents
	] value'.
	
	rawData := session executeAndFetch: script.
	rawData := rawData
		ifNil: [ '' ]
		ifNotNil: [ rawData asString ].
	
	"Parse and trim the C-strings safely"
	classes := (rawData splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty.
	classesList items: classes.
]

{ #category : 'actions' }
GbsBrowser >> gsDoIt [
	| code |
	code := self selectedCodeOrAll.
	code isEmpty ifTrue: [ ^ false ].
	^ (session executeAndFetch: code context: 20) notNil
]

{ #category : 'actions' }
GbsBrowser >> gsInspectIt [
	| code oop |
	code := self selectedCodeOrAll.
	code isEmpty ifTrue: [ ^ false ].
	oop := session serverInterface apiGciExecuteStr: code context: 20 env: 0.
	^ (oop isNumber and: [ oop > 20 ])
		ifTrue: [ GbsInspector inspect: oop session: session. true ]
		ifFalse: [ false ]
]

{ #category : 'actions' }
GbsBrowser >> gsPrintIt [
	| code result currentText |
	code := self selectedCodeOrAll.
	code isEmpty ifTrue: [ ^ false ].
	result := session executeAndFetch: '[ ', code, ' ] value printString' context: 20.
	result ifNil: [ ^ false ].
	currentText := sourceText text asString.
	sourceText text: currentText, ' "', result asString, '"'.
	^ true
]

{ #category : 'initialization' }
GbsBrowser >> initializePresenters [
	autoCommitEnabled := false.
	mainMenu := [ self buildMenuBar ] on: Error do: [ self newMenuBar ].
	dictionariesList := self newList.
	classesList := self newList.
	protocolsList := self newList.
	methodsList := self newList.
	sourceText := self newText.
	
	metaCheckbox := self newCheckBox label: 'Class side'.
	
	dictionariesList whenSelectionChangedDo: [ :sel | self dictionarySelected: sel selectedItem ].
	classesList whenSelectionChangedDo: [ :sel | self classSelected: sel selectedItem ].
	protocolsList whenSelectionChangedDo: [ :sel | self protocolSelected: sel selectedItem ].
	methodsList whenSelectionChangedDo: [ :sel | self methodSelected: sel selectedItem ].
	metaCheckbox whenChangedDo: [ :state | self classSelected: classesList selection selectedItem ].
	
	"NEW: Listen for Cmd+S / Ctrl+S inside the code editor!"
	sourceText whenSubmitDo: [ :text | self compileMethod: text asString ].
	sourceText contextMenu: [ self textMenu ].
]

{ #category : 'initialization' }
GbsBrowser >> initializeWindow: aWindowPresenter [
	aWindowPresenter 
		title: 'GemStone Remote Browser';
		initialExtent: 800 @ 600.
]

{ #category : 'actions' }
GbsBrowser >> loadDictionaries [
	"Fetches the user's SymbolList (Dictionaries) from GemStone"
	| script rawData dicts |
	script := '[
		| stream |
		stream := WriteStream on: String new.
		System myUserProfile symbolList do: [ :dict | stream nextPutAll: dict name asString; lf ].
		stream contents
	] value'.
	
	rawData := session executeAndFetch: script.
	rawData := rawData
		ifNil: [ '' ]
		ifNotNil: [ rawData asString ].
	
	"Parse and trim the C-strings safely"
	dicts := (rawData splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty.
	dictionariesList items: dicts.
]

{ #category : 'actions' }
GbsBrowser >> methodSelected: selectorName [
	| script rawSource className metaString |
	
	selectorName ifNil: [ ^ sourceText text: '' ].
	className := classesList selection selectedItem.
	className ifNil: [ ^ self ].
	
	"The Metaclass switch!"
	metaString := (metaCheckbox state == true) ifTrue: [ ' class' ] ifFalse: [ '' ].
	
	script := '[
		| cls meth |
		cls := (System myUserProfile symbolList objectNamed: #', className, ')', metaString, '.
		cls ifNil: [ ^ '''' ].
		meth := cls compiledMethodAt: #''', selectorName, ''' ifAbsent: [ nil ].
		meth ifNil: [ '''' ] ifNotNil: [ meth sourceString ]
	] value'.
	
	rawSource := session executeAndFetch: script.
	(rawSource beginsWith: 'Error:') ifTrue: [ rawSource := 'Could not fetch source code.' ].
	sourceText text: rawSource.
]

{ #category : 'actions' }
GbsBrowser >> protocolSelected: protocolName [
	| script rawData selectors className metaString |
	
	protocolName ifNil: [ ^ methodsList items: #(); yourself. sourceText text: '' ].
	className := classesList selection selectedItem.
	className ifNil: [ ^ self ].
	
	"The Metaclass switch!"
	metaString := (metaCheckbox state == true) ifTrue: [ ' class' ] ifFalse: [ '' ].
	
	script := '[
		| cls stream sels |
		cls := (System myUserProfile symbolList objectNamed: #', className, ')', metaString, '.
		stream := WriteStream on: String new.
		cls ifNotNil: [
			sels := ''', protocolName, ''' = ''-- all --''
				ifTrue: [ cls selectors ]
				ifFalse: [ cls selectorsIn: #''', protocolName, ''' ].
			sels asSortedCollection do: [ :sel | stream nextPutAll: sel asString; lf ].
		].
		stream contents
	] value'.
	
	rawData := session executeAndFetch: script.
	rawData := rawData
		ifNil: [ '' ]
		ifNotNil: [ rawData asString ].
	selectors := (rawData splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty.
	methodsList items: selectors.
]

{ #category : 'actions' }
GbsBrowser >> selectDictionaryNamed: aDictionaryName [
	| dicts |
	(aDictionaryName isString and: [ aDictionaryName isEmpty not ]) ifFalse: [ ^ false ].
	dicts := (dictionariesList respondsTo: #items)
		ifTrue: [ dictionariesList items ]
		ifFalse: [ #( ) ].
	(dicts includes: aDictionaryName) ifTrue: [
		(dictionariesList respondsTo: #selectItem:) ifTrue: [ dictionariesList selectItem: aDictionaryName ].
		self dictionarySelected: aDictionaryName.
		^ true
	].
	^ false
]

{ #category : 'actions' }
GbsBrowser >> selectClassNamed: aClassName classSide: classSideBoolean method: aSelectorString [
	| clsItems chosenProtocol className dictName |
	(aClassName isString and: [ aClassName isEmpty not ]) ifFalse: [ ^ false ].
	className := aClassName trimBoth.
	(metaCheckbox respondsTo: #state:) ifTrue: [ metaCheckbox state: classSideBoolean ].
	clsItems := (classesList respondsTo: #items)
		ifTrue: [ classesList items ]
		ifFalse: [ #( ) ].
	(clsItems includes: className) ifFalse: [
		dictName := self dictionaryNameContainingClassNamed: className.
		(dictName isString and: [ dictName isEmpty not ])
			ifTrue: [ self selectDictionaryNamed: dictName ].
		clsItems := (classesList respondsTo: #items)
			ifTrue: [ classesList items ]
			ifFalse: [ #( ) ] ].
	(clsItems includes: className) ifFalse: [ ^ false ].
	(classesList respondsTo: #selectItem:scrollToSelection:)
		ifTrue: [ classesList selectItem: className scrollToSelection: true ]
		ifFalse: [
			(classesList respondsTo: #selectItem:)
				ifTrue: [ classesList selectItem: className ] ].
	self ensureClassVisibleNamed: className inItems: clsItems.
	self focusClasses.
	self classSelected: className.
	chosenProtocol := '-- all --'.
	(protocolsList respondsTo: #selectItem:) ifTrue: [ protocolsList selectItem: chosenProtocol ].
	self protocolSelected: chosenProtocol.
	(aSelectorString isString and: [ aSelectorString isEmpty not ]) ifTrue: [
		(methodsList respondsTo: #selectItem:) ifTrue: [ methodsList selectItem: aSelectorString ].
		self methodSelected: aSelectorString ].
	^ true
]

{ #category : 'private' }
GbsBrowser >> ensureClassVisibleNamed: className inItems: classItems [
	| index |
	index := classItems indexOf: className ifAbsent: [ 0 ].
	index > 0 ifTrue: [
		(classesList respondsTo: #scrollToIndex:)
			ifTrue: [ [ classesList scrollToIndex: index ] on: Error do: [ ] ].
		(classesList respondsTo: #selectIndex:)
			ifTrue: [ [ classesList selectIndex: index ] on: Error do: [ ] ] ].
	(classesList respondsTo: #withAdapterDo:)
		ifTrue: [
			[ classesList withAdapterDo: [ :adapter |
				| widget |
				widget := [ adapter widget ] on: Error do: [ nil ].
				widget ifNotNil: [
					(widget respondsTo: #scrollToIndex:)
						ifTrue: [ widget scrollToIndex: index ].
					(widget respondsTo: #scrollSelectionIntoView)
						ifTrue: [ widget scrollSelectionIntoView ] ] ] ]
				on: Error
				do: [ ] ].
]

{ #category : 'private' }
GbsBrowser >> selectedCodeOrAll [
	| code |
	code := (sourceText respondsTo: #selectedText)
		ifTrue: [ sourceText selectedText ]
		ifFalse: [ '' ].
	(code isString and: [ code isEmpty not ]) ifTrue: [ ^ code ].
	^ sourceText text asString
]

{ #category : 'accessing' }
GbsBrowser >> session: aSession [
	session := aSession.
]

{ #category : 'menus' }
GbsBrowser >> textMenu [
	| menu |
	menu := self newMenu.
	menu addGroup: [ :group |
		group addItem: [ :item | item name: 'Accept'; action: [ self acceptText: sourceText text asString ] ].
		group addItem: [ :item | item name: 'GS-Do it'; action: [ self gsDoIt ] ].
		group addItem: [ :item | item name: 'GS-Print it'; action: [ self gsPrintIt ] ].
		group addItem: [ :item | item name: 'GS-Inspect it'; action: [ self gsInspectIt ] ] ].
	^ menu
]

{ #category : 'menus' }
GbsBrowser >> buildMenuBar [
	| menu |
	menu := self newMenuBar.
	menu addGroup: [ :group |
		group addItem: [ :item | item name: 'Find'; subMenu: self menuFind ].
		group addItem: [ :item | item name: 'Dictionary'; subMenu: self menuDictionary ].
		group addItem: [ :item | item name: 'Class'; subMenu: self menuClass ].
		group addItem: [ :item | item name: 'Category'; subMenu: self menuCategory ].
		group addItem: [ :item | item name: 'Method'; subMenu: self menuMethod ].
		group addItem: [ :item | item name: 'Session'; subMenu: self menuSession ].
		group addItem: [ :item | item name: 'Window'; subMenu: self menuWindow ] ].
	^ menu
]

{ #category : 'menus' }
GbsBrowser >> menuFind [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Find Dictionary ...'; action: [ self deferAction: [ self findDictionary ] ] ].
			group addItem: [ :item | item name: 'Find Class ...'; action: [ self deferAction: [ self findClass ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Implementors Of ...'; action: [ self deferAction: [ self queryImplementors ] ] ].
			group addItem: [ :item | item name: 'Senders Of ...'; action: [ self deferAction: [ self querySenders ] ] ].
			group addItem: [ :item | item name: 'References to ...'; action: [ self deferAction: [ self queryReferences ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Methods With String Matching ...'; action: [ self deferAction: [ self queryMethodsWithString ] ] ] ];
		yourself
]

{ #category : 'menus' }
GbsBrowser >> menuDictionary [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'File Out As ...'; action: [ self deferAction: [ self fileOutDictionary ] ] ].
			group addItem: [ :item | item name: 'File Out Methods As ...'; action: [ self deferAction: [ self fileOutDictionaryMethods ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Browse'; action: [ self deferAction: [ self browseDictionary ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Add...'; action: [ self deferAction: [ self addDictionary ] ] ].
			group addItem: [ :item | item name: 'Rename As...'; action: [ self deferAction: [ self renameDictionary ] ] ].
			group addItem: [ :item | item name: 'Remove...'; action: [ self deferAction: [ self removeDictionary ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Inspect'; action: [ self deferAction: [ self inspectDictionary ] ] ] ];
		yourself
]

{ #category : 'menus' }
GbsBrowser >> menuClass [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'File Out As ...'; action: [ self deferAction: [ self fileOutClass ] ] ].
			group addItem: [ :item | item name: 'File Out Methods As ...'; action: [ self deferAction: [ self fileOutClassMethods ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Browse Class'; action: [ self deferAction: [ self browseClass ] ] ].
			group addItem: [ :item | item name: 'Browse Hierarchy'; action: [ self deferAction: [ self browseHierarchy ] ] ].
			group addItem: [ :item | item name: 'Browse Versions'; action: [ self deferAction: [ self browseVersions ] ] ].
			group addItem: [ :item | item name: 'Browse References'; action: [ self deferAction: [ self browseClassReferences ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Add'; subMenu: self menuClassAdd ].
			group addItem: [ :item | item name: 'Move To ...'; action: [ self deferAction: [ self moveClassToDictionary ] ] ].
			group addItem: [ :item | item name: 'Remove ...'; action: [ self deferAction: [ self removeClass ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Create Accessors ...'; action: [ self deferAction: [ self createAccessors ] ] ].
			group addItem: [ :item | item name: 'Create Client Class'; action: [ self deferAction: [ self createClientClass ] ] ].
			group addItem: [ :item | item name: 'Compile Client Class'; action: [ self deferAction: [ self compileClientClass ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Inspect All Instances'; action: [ self deferAction: [ self inspectAllInstances ] ] ].
			group addItem: [ :item | item name: 'Inspect Class'; action: [ self deferAction: [ self inspectClass ] ] ] ];
		yourself
]

{ #category : 'menus' }
GbsBrowser >> menuCategory [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Add...'; action: [ self deferAction: [ self addCategory ] ] ].
			group addItem: [ :item | item name: 'Rename As...'; action: [ self deferAction: [ self renameCategory ] ] ].
			group addItem: [ :item | item name: 'Remove...'; action: [ self deferAction: [ self removeCategory ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Browse'; action: [ self deferAction: [ self browseCategory ] ] ] ];
		yourself
]

{ #category : 'menus' }
GbsBrowser >> menuMethod [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'File Out As ...'; action: [ self deferAction: [ self fileOutMethod ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Browse'; action: [ self deferAction: [ self browseMethod ] ] ].
			group addItem: [ :item | item name: 'Browse Hierarchy'; action: [ self deferAction: [ self browseHierarchy ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Browse Senders'; subMenu: (self selectorSubMenuDo: [ :sel | self browseSendersOf: sel ]) ].
			group addItem: [ :item | item name: 'Browse Implementors'; subMenu: (self selectorSubMenuDo: [ :sel | self browseImplementorsOf: sel ]) ].
			group addItem: [ :item | item name: 'Browse Hierarchy Senders'; subMenu: (self selectorSubMenuDo: [ :sel | self browseHierarchySendersOf: sel ]) ].
			group addItem: [ :item | item name: 'Browse Hierarchy Implementors'; subMenu: (self selectorSubMenuDo: [ :sel | self browseHierarchyImplementorsOf: sel ]) ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Move To ...'; action: [ self deferAction: [ self moveMethodToCategory ] ] ].
			group addItem: [ :item | item name: 'Remove...'; action: [ self deferAction: [ self removeMethod ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Compile Client Method'; action: [ self deferAction: [ self acceptText: sourceText text asString ] ] ].
			group addItem: [ :item | item name: 'Inspect'; action: [ self deferAction: [ self inspectMethod ] ] ] ];
		yourself
]

{ #category : 'menus' }
GbsBrowser >> menuSession [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: self autoCommitMenuLabel; action: [ self deferAction: [ self toggleAutoCommit ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Commit Transaction'; action: [ self deferAction: [ self commitSession ] ] ].
			group addItem: [ :item | item name: 'Abort Transaction'; action: [ self deferAction: [ self abortSession ] ] ].
			group addItem: [ :item | item name: 'Begin Transaction'; action: [ self deferAction: [ self beginSessionTransaction ] ] ] ];
		yourself
]

{ #category : 'menus' }
GbsBrowser >> menuWindow [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Raise GemStone Windows'; action: [ self deferAction: [ self raiseGemStoneWindows ] ] ].
			group addItem: [ :item | item name: 'Collapse GemStone Windows'; action: [ self deferAction: [ self collapseGemStoneWindows ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Refresh from GS Server'; action: [ self deferAction: [ self refreshBrowserFromServer ] ] ].
			group addItem: [ :item | item name: 'Raise GemStone Launcher'; action: [ self deferAction: [ self raiseGemStoneLauncher ] ] ] ];
		yourself
]

{ #category : 'menus' }
GbsBrowser >> menuClassAdd [
	^ self newMenu
		addItem: [ :item | item name: 'New Class ...'; action: [ self deferAction: [ self addClass ] ] ];
		addItem: [ :item | item name: 'Instance Var ...'; action: [ self deferAction: [ self addInstanceVariable ] ] ];
		addItem: [ :item | item name: 'Class Var ...'; action: [ self deferAction: [ self addClassVariable ] ] ];
		addItem: [ :item | item name: 'Class Inst Var ...'; action: [ self deferAction: [ self addClassInstanceVariable ] ] ];
		yourself
]

{ #category : 'private' }
GbsBrowser >> deferAction: aBlock [
	UIManager default defer: aBlock
]

{ #category : 'private' }
GbsBrowser >> iconNamedSafe: aSymbol [
	^ [ self iconNamed: aSymbol ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbsBrowser >> informNotImplemented: aString [
	UIManager default inform: aString.
	^ false
]

{ #category : 'actions' }
GbsBrowser >> refreshBrowser [
	self loadDictionaries.
]

{ #category : 'private' }
GbsBrowser >> selectedDictionaryName [
	^ self selectedItemOf: dictionariesList
]

{ #category : 'private' }
GbsBrowser >> selectedClassName [
	^ self selectedItemOf: classesList
]

{ #category : 'private' }
GbsBrowser >> selectedMethodSelector [
	| methodName |
	methodName := self selectedItemOf: methodsList.
	methodName ifNil: [ ^ nil ].
	^ methodName asSymbol
]

{ #category : 'private' }
GbsBrowser >> selectedItemOf: aListPresenter [
	| selection |
	aListPresenter ifNil: [ ^ nil ].
	(aListPresenter respondsTo: #selection) ifFalse: [ ^ nil ].
	selection := aListPresenter selection.
	selection ifNil: [ ^ nil ].
	(selection respondsTo: #selectedItem) ifFalse: [ ^ nil ].
	^ selection selectedItem
]

{ #category : 'actions' }
GbsBrowser >> findDictionary [
	| name |
	name := UIManager default request: 'Dictionary name:' initialAnswer: ''.
	(name isNil or: [ name isEmpty ]) ifTrue: [ ^ false ].
	self selectDictionaryNamed: name trimBoth.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> findClass [
	| name |
	name := UIManager default request: 'Class name:' initialAnswer: ''.
	(name isNil or: [ name isEmpty ]) ifTrue: [ ^ false ].
	^ (self selectClassNamed: name trimBoth classSide: false method: nil)
		ifTrue: [
			self focusClasses.
			self browseClass ]
		ifFalse: [ false ]
]

{ #category : 'actions' }
GbsBrowser >> browseDictionary [
	^ self selectedDictionaryName notNil
]

{ #category : 'actions' }
GbsBrowser >> browseClass [
	| className requested metaString script source |
	className := self selectedClassName.
	className ifNil: [
		requested := UIManager default request: 'Class name:' initialAnswer: ''.
		(requested isNil or: [ requested trimBoth isEmpty ]) ifTrue: [ ^ false ].
		(self selectClassNamed: requested trimBoth classSide: (metaCheckbox state == true) method: nil)
			ifFalse: [ ^ false ].
		className := self selectedClassName ifNil: [ requested trimBoth ] ].

	metaString := (metaCheckbox state == true) ifTrue: [ ' class' ] ifFalse: [ '' ].
	script := '[
		| cls |
		cls := (System myUserProfile symbolList objectNamed: #', className, ')', metaString, '.
		cls ifNil: [ ^ '''' ].
		(cls respondsTo: #definition)
			ifTrue: [ cls definition asString ]
			ifFalse: [ cls printString ]
	] value'.
	source := session executeAndFetch: script.
	sourceText text: (source ifNil: [ '' ] ifNotNil: [ source asString ]).
	^ true
]

{ #category : 'actions' }
GbsBrowser >> browseHierarchy [
	| className script result |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	script := '[ | cls stream | stream := WriteStream on: String new. cls := System myUserProfile symbolList objectNamed: #', className, '. cls ifNotNil: [ cls withAllSuperclasses reverseDo: [ :c | stream nextPutAll: c name asString; lf ] ]. stream contents ] value'.
	result := session executeAndFetch: script.
	result ifNil: [ ^ false ].
	UIManager default inform: result asString.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> browseVersions [
	| className selector script raw versions idx |
	className := self selectedClassName.
	selector := self selectedMethodSelector.
	(className isNil or: [ selector isNil ]) ifTrue: [ ^ false ].
	script := '[
		| cls sel stream versions |
		cls := System myUserProfile symbolList objectNamed: #', className, '.
		sel := #', selector asString, '.
		stream := WriteStream on: String new.
		cls ifNil: [ ^ '''' ].
		versions := (cls respondsTo: #allVersionsOf:)
			ifTrue: [ [ cls allVersionsOf: sel ] on: Error do: [ #() ] ]
			ifFalse: [ #() ].
		versions isEmpty ifTrue: [
			| src |
			src := [ (cls compiledMethodAt: sel) sourceString ] on: Error do: [ '''' ].
			src isEmpty ifFalse: [
				stream nextPutAll: ''version 1''; tab; nextPutAll: src; lf
			]
		] ifFalse: [
			1 to: versions size do: [ :ix |
				| m src |
				m := versions at: ix.
				src := [ m sourceString ] on: Error do: [ '''' ].
				stream
					nextPutAll: ''version ''; nextPutAll: ix asString; tab;
					nextPutAll: src; lf
			]
		].
		stream contents
	] value'.
	raw := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	versions := (raw splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty.
	versions isEmpty ifTrue: [ ^ false ].
	idx := UIManager default chooseFrom: (versions collect: [ :ea | (ea splitOn: Character tab) first ]) title: 'Method Versions'.
	idx = 0 ifTrue: [ ^ false ].
	sourceText text: ((versions at: idx) allButFirst: (((versions at: idx) indexOf: Character tab ifAbsent: [ 0 ]))).
	^ true
]

{ #category : 'actions' }
GbsBrowser >> browseClassReferences [
	^ self queryReferences
]

{ #category : 'actions' }
GbsBrowser >> browseCategory [
	^ self protocolSelected: (protocolsList selection selectedItem)
]

{ #category : 'actions' }
GbsBrowser >> browseMethod [
	^ self methodSelected: (methodsList selection selectedItem)
]

{ #category : 'actions' }
GbsBrowser >> queryImplementors [
	^ self queryMethodsForSelectorPrompt: 'Implementors of selector:' mode: 'implementors'
]

{ #category : 'actions' }
GbsBrowser >> querySenders [
	^ self queryMethodsForSelectorPrompt: 'Senders of selector:' mode: 'senders'
]

{ #category : 'actions' }
GbsBrowser >> queryReferences [
	^ self queryMethodsForSelectorPrompt: 'References to class or variable name:' mode: 'references'
]

{ #category : 'private' }
GbsBrowser >> queryMethodsForSelectorPrompt: prompt mode: modeString [
	| selectorName references |
	selectorName := self uiRequest: prompt initialAnswer: ''.
	(selectorName isNil or: [ selectorName isEmpty ]) ifTrue: [ ^ false ].
	^ self queryMethodsForSelector: selectorName mode: modeString
]

{ #category : 'actions' }
GbsBrowser >> queryMethodsForSelector: selectorName mode: modeString [
	| normalized resolvedSelector references |
	normalized := self normalizeSelectorQuery: selectorName.
	normalized isEmpty ifTrue: [ ^ false ].
	resolvedSelector := self resolveSelectorForQueryInput: normalized.
	resolvedSelector isNil ifTrue: [ ^ false ].
	references := self queryServerMethodsForSelector: resolvedSelector trimBoth mode: modeString.
	references isEmpty ifTrue: [ ^ self informNotImplemented: 'No matches found.' ].
	^ self
		openQueryResults: references
		title: (self queryResultsTitleForSelector: resolvedSelector mode: modeString count: references size)
]

{ #category : 'private' }
GbsBrowser >> normalizeSelectorQuery: rawInput [
	| text idx |
	text := rawInput asString trimBoth.
	(text includesSubstring: '>>') ifTrue: [
		idx := text findString: '>>' startingAt: 1.
		text := (text copyFrom: idx + 2 to: text size) trimBoth ].
	(text beginsWith: '#') ifTrue: [ text := (text allButFirst) trimBoth ].
	((text beginsWith: '''') and: [ text endsWith: '''' ]) ifTrue: [
		text := (text copyFrom: 2 to: text size - 1) trimBoth ].
	^ text
]

{ #category : 'private' }
GbsBrowser >> resolveSelectorForQueryInput: rawInput [
	| matches exactMatch idx |
	matches := self queryMatchingSelectorsForPattern: rawInput.
	matches isEmpty ifTrue: [ ^ rawInput ].
	exactMatch := matches
		detect: [ :each | each asString = rawInput ]
		ifNone: [ nil ].
	exactMatch ifNotNil: [ ^ exactMatch asString ].
	matches size = 1 ifTrue: [ ^ matches first asString ].
	idx := self
		uiChooseFrom: (matches collect: [ :each | each asString ])
		title: 'Pick one matching selector'.
	idx = 0 ifTrue: [ ^ nil ].
	^ (matches at: idx) asString
]

{ #category : 'private' }
GbsBrowser >> queryMatchingSelectorsForPattern: rawPattern [
	| pattern escaped script raw |
	pattern := rawPattern asString trimBoth.
	pattern isEmpty ifTrue: [ ^ #() ].
	escaped := (pattern copyWithout: $*) copyReplaceAll: '''' with: ''''''.
	script := '[
		| token all stream |
		token := ''', escaped, '''.
		all := Set new.
		System myUserProfile symbolList do: [ :dict |
			dict keysAndValuesDo: [ :k :v |
				(v isBehavior) ifTrue: [
					[ v selectors do: [ :sel | all add: sel asString ] ] on: Error do: [ ] ] ] ].
		stream := WriteStream on: String new.
		(all asArray select: [ :sel |
			(sel = token) or: [ sel includesSubstring: token ] ]) asSortedCollection
			do: [ :sel | stream nextPutAll: sel; lf ].
		stream contents
	] value'.
	raw := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	raw isNil ifTrue: [ ^ #() ].
	^ ((raw asString splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty) asArray
]

{ #category : 'private' }
GbsBrowser >> dictionaryNameContainingClassNamed: className [
	| escapedName script raw |
	escapedName := className copyReplaceAll: '''' with: ''''''.
	script := '[
		| found |
		found := nil.
		System myUserProfile symbolList do: [ :dict |
			(found isNil and: [ dict includesKey: #', escapedName, ' ]) ifTrue: [
				| value |
				value := dict at: #', escapedName, '.
				(value isBehavior) ifTrue: [ found := dict name asString ] ] ].
		found ifNil: [ '''' ] ifNotNil: [ found ]
	] value'.
	raw := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	^ raw ifNil: [ '' ] ifNotNil: [ raw asString trimBoth ]
]

{ #category : 'private' }
GbsBrowser >> queryServerMethodsForSelector: selectorName mode: modeString [
	((#('implementors' 'senders' 'references') includes: modeString)
		and: [ Smalltalk includesKey: #GbsClassicLauncher ]) ifTrue: [
		^ [ GbsClassicLauncher
			queryOrganizerMethodsFor: selectorName asString trimBoth
			mode: modeString
			inSession: session ]
			on: Error
			do: [ :ex | self queryServerMethodsByScanningForSelector: selectorName mode: modeString ] ].
	^ self queryServerMethodsByScanningForSelector: selectorName mode: modeString
]

{ #category : 'private' }
GbsBrowser >> queryServerMethodsByScanningForSelector: selectorName mode: modeString [
	| escapedSelector selectedClassName escapedClass escapedToken script raw selectorExpr classFilterExpr |
	escapedSelector := selectorName copyReplaceAll: '''' with: ''''''.
	escapedToken := escapedSelector.
	selectedClassName := self selectedClassName ifNil: [ '' ].
	escapedClass := selectedClassName copyReplaceAll: '''' with: ''''''.
	selectorExpr := (modeString = 'implementors' or: [ modeString = 'hierarchyImplementors' ])
		ifTrue: [ 'sels := (cls includesSelector: sel) ifTrue: [ Array with: sel ] ifFalse: [ #() ]' ]
		ifFalse: [
			'sels := OrderedCollection new.
			[ cls selectors do: [ :candidate |
				| src |
				src := [ (cls compiledMethodAt: candidate) sourceString ] on: Error do: [ '''' ].
				(src notNil and: [ src asString includesSubstring: token ]) ifTrue: [ sels add: candidate ] ] ]
				on: Error
				do: [ ]' ].
	classFilterExpr := (modeString = 'hierarchySenders' or: [ modeString = 'hierarchyImplementors' ])
		ifTrue: [ '((rootClass notNil) and: [ ((cls withAllSuperclasses includes: rootClass) or: [ rootClass withAllSuperclasses includes: cls ]) not ]) ifTrue: [ sels := #() ]' ]
		ifFalse: [ '' ].
	script := '[
		| sel token classes stream rootClass |
		sel := #''', escapedSelector, '''.
		token := ''', escapedToken, '''.
		stream := WriteStream on: String new.
		classes := IdentitySet new.
		rootClass := ', (selectedClassName isEmpty
			ifTrue: [ 'nil' ]
			ifFalse: [ 'System myUserProfile symbolList objectNamed: #', escapedClass ]), '.
		System myUserProfile symbolList do: [ :dict |
			dict keysAndValuesDo: [ :k :v | (v isBehavior) ifTrue: [ classes add: v ] ] ].
		classes asArray do: [ :cls |
			| sels |
			', selectorExpr, '.
			', classFilterExpr, '.
			sels do: [ :s | stream nextPutAll: cls name asString; nextPutAll: ''>>''; nextPutAll: s asString; lf ].
		].
		stream contents
	] value'.
	raw := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	raw := raw ifNil: [ '' ] ifNotNil: [ raw asString ].
	^ ((raw splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty) asSortedCollection asArray
]

{ #category : 'private' }
GbsBrowser >> openMethodReference: referenceString [
	| split classPart selectorPart classSide className |
	(referenceString includesSubstring: '>>') ifFalse: [ ^ false ].
	split := referenceString findString: '>>' startingAt: 1.
	classPart := (referenceString copyFrom: 1 to: split - 1) trimBoth.
	selectorPart := (referenceString copyFrom: split + 2 to: referenceString size) trimBoth.
	classSide := classPart endsWith: ' class'.
	className := classSide
		ifTrue: [ classPart copyFrom: 1 to: classPart size - 6 ]
		ifFalse: [ classPart ].
	^ self selectClassNamed: className classSide: classSide method: selectorPart
]

{ #category : 'actions' }
GbsBrowser >> queryMethodsWithString [
	| pattern script raw matches selected |
	pattern := self uiRequest: 'Source substring:' initialAnswer: ''.
	(pattern isNil or: [ pattern isEmpty ]) ifTrue: [ ^ false ].
	script := '[
		| classes stream p |
		p := ''', (pattern copyReplaceAll: '''' with: ''''''), '''.
		stream := WriteStream on: String new.
		classes := IdentitySet new.
		System myUserProfile symbolList do: [ :dict |
			dict keysAndValuesDo: [ :k :v | (v isBehavior) ifTrue: [ classes add: v ] ] ].
		classes asArray do: [ :cls |
			cls selectors do: [ :sel |
				| src |
				src := [ (cls compiledMethodAt: sel) sourceString ] on: Error do: [ '''' ].
				(src includesSubstring: p) ifTrue: [
					stream nextPutAll: cls name asString; nextPutAll: ''>>''; nextPutAll: sel asString; lf
				]
			]
		].
		stream contents
	] value'.
	raw := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	raw := raw ifNil: [ '' ] ifNotNil: [ raw asString ].
	matches := (raw splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty.
	matches isEmpty ifTrue: [ ^ self informNotImplemented: 'No methods matched.' ].
	selected := matches asSortedCollection asArray.
	^ self openQueryResults: selected
]

{ #category : 'actions' }
GbsBrowser >> commitSession [
	(session respondsTo: #commitTransaction)
		ifTrue: [ ^ session commitTransaction ].
	^ false
]

{ #category : 'actions' }
GbsBrowser >> abortSession [
	(session respondsTo: #abort)
		ifTrue: [ session abort. ^ true ].
	^ false
]

{ #category : 'actions' }
GbsBrowser >> addDictionary [
	| name script |
	name := UIManager default request: 'New Dictionary name:' initialAnswer: ''.
	(name isNil or: [ name isEmpty ]) ifTrue: [ ^ false ].
	script := '[ | nm dict sym | nm := #', name trimBoth, '. dict := SymbolDictionary new. dict name: nm asString. sym := System myUserProfile symbolList. sym add: dict. true ] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	self loadDictionaries.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> renameDictionary [
	| oldName newName script |
	oldName := self selectedDictionaryName.
	oldName ifNil: [ ^ false ].
	newName := UIManager default request: 'Rename dictionary to:' initialAnswer: oldName.
	(newName isNil or: [ newName isEmpty or: [ newName = oldName ] ]) ifTrue: [ ^ false ].
	script := '[ | sym d old new | sym := System myUserProfile symbolList. old := #', oldName, '. new := #', newName trimBoth, '. d := sym objectNamed: old. d ifNil: [ ^ false ]. sym removeKey: old ifAbsent: [ ]. sym at: new put: d. d name: new asString. true ] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	self loadDictionaries.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> removeDictionary [
	| oldName script |
	oldName := self selectedDictionaryName.
	oldName ifNil: [ ^ false ].
	script := '[ | sym old | sym := System myUserProfile symbolList. old := #', oldName, '. sym removeKey: old ifAbsent: [ ]. true ] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	self loadDictionaries.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> inspectDictionary [
	| name oop |
	name := self selectedDictionaryName.
	name ifNil: [ ^ false ].
	oop := session serverInterface apiGciExecuteStr: '(System myUserProfile symbolList objectNamed: #', name, ')' context: 20 env: 0.
	(oop isNumber and: [ oop > 20 ]) ifFalse: [ ^ false ].
	GbsInspector inspect: oop session: session.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> addClass [
	| name superclass script dictionaryName |
	dictionaryName := self selectedDictionaryName ifNil: [ 'UserGlobals' ].
	superclass := self selectedClassName ifNil: [ 'Object' ].
	name := UIManager default request: 'New class name:' initialAnswer: 'NewClass'.
	(name isNil or: [ name isEmpty ]) ifTrue: [ ^ false ].
	script := '[ | super cls dict |
		dict := System myUserProfile symbolList objectNamed: #', dictionaryName, '.
		super := System myUserProfile symbolList objectNamed: #', superclass, '.
		super ifNil: [ ^ false ].
		cls := super
			subclass: #', name trimBoth, '
			instVarNames: #()
			classVars: #()
			classInstVars: #()
			poolDictionaries: #()
			inDictionary: dict
			options: #().
		cls notNil ] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	self dictionarySelected: dictionaryName.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> addInstanceVariable [
	| className varName script |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	varName := UIManager default request: 'Instance variable name:' initialAnswer: ''.
	(varName isNil or: [ varName isEmpty ]) ifTrue: [ ^ false ].
	script := '[ | cls | cls := System myUserProfile symbolList objectNamed: #', className, '. cls ifNil: [ ^ false ]. (cls respondsTo: #addInstVarName:) ifFalse: [ ^ false ]. cls addInstVarName: #''', varName trimBoth, '''. true ] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> addClassVariable [
	| className varName script |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	varName := UIManager default request: 'Class variable name:' initialAnswer: ''.
	(varName isNil or: [ varName isEmpty ]) ifTrue: [ ^ false ].
	script := '[ | cls | cls := System myUserProfile symbolList objectNamed: #', className, '. cls ifNil: [ ^ false ]. (cls respondsTo: #addClassVarName:) ifFalse: [ ^ false ]. cls addClassVarName: #''', varName trimBoth, '''. true ] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> addClassInstanceVariable [
	| className varName script |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	varName := UIManager default request: 'Class instance variable name:' initialAnswer: ''.
	(varName isNil or: [ varName isEmpty ]) ifTrue: [ ^ false ].
	script := '[ | cls | cls := System myUserProfile symbolList objectNamed: #', className, '. cls ifNil: [ ^ false ]. (cls class respondsTo: #addInstVarName:) ifFalse: [ ^ false ]. cls class addInstVarName: #''', varName trimBoth, '''. true ] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> removeClass [
	| className script |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	script := '[ | cls | cls := System myUserProfile symbolList objectNamed: #', className, '. cls ifNil: [ ^ false ]. cls removeFromSystem. true ] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	self dictionarySelected: self selectedDictionaryName.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> createAccessors [
	| className varName getter setter |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	varName := UIManager default request: 'Variable name for accessors:' initialAnswer: ''.
	(varName isNil or: [ varName isEmpty ]) ifTrue: [ ^ false ].
	getter := varName trimBoth, String lf, '^ ', varName trimBoth.
	setter := varName trimBoth, ': anObject', String lf, varName trimBoth, ' := anObject'.
	(self compileSource: getter inClass: className category: 'accessing') ifFalse: [ ^ false ].
	(self compileSource: setter inClass: className category: 'accessing') ifFalse: [ ^ false ].
	self maybeAutoCommit.
	self protocolSelected: protocolsList selection selectedItem.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> inspectAllInstances [
	| className oop |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	oop := session serverInterface apiGciExecuteStr: '((System myUserProfile symbolList objectNamed: #', className, ') allInstances)' context: 20 env: 0.
	(oop isNumber and: [ oop > 20 ]) ifFalse: [ ^ false ].
	GbsInspector inspect: oop session: session.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> inspectClass [
	| className oop |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	oop := session serverInterface apiGciExecuteStr: '(System myUserProfile symbolList objectNamed: #', className, ')' context: 20 env: 0.
	(oop isNumber and: [ oop > 20 ]) ifFalse: [ ^ false ].
	GbsInspector inspect: oop session: session.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> addCategory [
	| className category script |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	category := UIManager default request: 'Category name:' initialAnswer: 'new-category'.
	(category isNil or: [ category isEmpty ]) ifTrue: [ ^ false ].
	script := '[ | cls | cls := System myUserProfile symbolList objectNamed: #', className, '. cls ifNil: [ ^ false ]. cls addCategory: #''', category trimBoth, '''. true ] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	self classSelected: className.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> renameCategory [
	| className oldCategory newCategory script |
	className := self selectedClassName.
	oldCategory := protocolsList selection selectedItem.
	(className isNil or: [ oldCategory isNil or: [ oldCategory = '-- all --' ] ]) ifTrue: [ ^ false ].
	newCategory := UIManager default request: 'Rename category to:' initialAnswer: oldCategory.
	(newCategory isNil or: [ newCategory isEmpty or: [ newCategory = oldCategory ] ]) ifTrue: [ ^ false ].
	script := '[
		| cls sels |
		cls := System myUserProfile symbolList objectNamed: #', className, '.
		cls ifNil: [ ^ false ].
		sels := [ cls selectorsIn: #''', oldCategory, ''' ] on: Error do: [ #() ].
		sels do: [ :sel |
			| src |
			src := [ (cls compiledMethodAt: sel) sourceString ] on: Error do: [ '''' ].
			src isEmpty ifFalse: [ cls compileMethod: src category: #''', newCategory trimBoth, ''' ].
		].
		true
	] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	self classSelected: className.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> removeCategory [
	| className category script |
	className := self selectedClassName.
	category := protocolsList selection selectedItem.
	(className isNil or: [ category isNil or: [ category = '-- all --' ] ]) ifTrue: [ ^ false ].
	(UIManager default confirm: 'Remove category "', category, '" and move methods to "as yet unclassified"?')
		ifFalse: [ ^ false ].
	script := '[
		| cls sels |
		cls := System myUserProfile symbolList objectNamed: #', className, '.
		cls ifNil: [ ^ false ].
		sels := [ cls selectorsIn: #''', category, ''' ] on: Error do: [ #() ].
		sels do: [ :sel |
			| src |
			src := [ (cls compiledMethodAt: sel) sourceString ] on: Error do: [ '''' ].
			src isEmpty ifFalse: [ cls compileMethod: src category: #''as yet unclassified'' ].
		].
		true
	] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	self classSelected: className.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> removeMethod [
	| className selector script |
	className := self selectedClassName.
	selector := self selectedMethodSelector.
	(className isNil or: [ selector isNil ]) ifTrue: [ ^ false ].
	script := '[ | cls | cls := System myUserProfile symbolList objectNamed: #', className, '. cls ifNil: [ ^ false ]. cls removeSelector: #', selector asString, '. true ] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	self protocolSelected: protocolsList selection selectedItem.
	^ true
]

{ #category : 'private' }
GbsBrowser >> focusSource [
	(sourceText respondsTo: #takeKeyboardFocus)
		ifTrue: [ sourceText takeKeyboardFocus ].
]

{ #category : 'private' }
GbsBrowser >> focusClasses [
	(classesList respondsTo: #takeKeyboardFocus)
		ifTrue: [ [ classesList takeKeyboardFocus ] on: Error do: [ ] ].
]

{ #category : 'private' }
GbsBrowser >> compileSource: sourceString inClass: className category: categoryName [
	| escapedSource script result |
	escapedSource := sourceString copyReplaceAll: '''' with: ''''''.
	script := '[
		| cls result |
		cls := System myUserProfile symbolList objectNamed: #', className, '.
		cls ifNil: [ ^ false ].
		result := cls compileMethod: ''', escapedSource, ''' category: #''', categoryName, '''.
		(result isKindOf: Array) ifTrue: [ ^ false ].
		true
	] value'.
	result := [ session executeAndFetch: script context: 20 ] on: Error do: [ nil ].
	^ result notNil and: [ result asString asLowercase ~= 'false' ]
]

{ #category : 'actions' }
GbsBrowser >> moveClassToDictionary [
	| className fromDict toDict script initial |
	className := self selectedClassName.
	fromDict := self selectedDictionaryName.
	className ifNil: [ ^ false ].
	initial := fromDict ifNil: [ 'UserGlobals' ].
	toDict := UIManager default request: 'Move class to dictionary:' initialAnswer: initial.
	(toDict isNil or: [ toDict isEmpty or: [ toDict = fromDict ] ]) ifTrue: [ ^ false ].
	script := '[
		| cls oldDict newDict |
		cls := System myUserProfile symbolList objectNamed: #', className, '.
		oldDict := System myUserProfile symbolList objectNamed: #', (fromDict ifNil: [ 'UserGlobals' ]), '.
		newDict := System myUserProfile symbolList objectNamed: #', toDict trimBoth, '.
		(cls isNil or: [ newDict isNil ]) ifTrue: [ ^ false ].
		oldDict ifNotNil: [ oldDict removeKey: #', className, ' ifAbsent: [ ] ].
		newDict at: #', className, ' put: cls.
		true
	] value'.
	[ session executeAndFetch: script context: 20 ] on: Error do: [ ^ false ].
	self maybeAutoCommit.
	self loadDictionaries.
	self selectDictionaryNamed: toDict trimBoth.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> moveMethodToCategory [
	| className selector newCategory source category script |
	className := self selectedClassName.
	selector := self selectedMethodSelector.
	(className isNil or: [ selector isNil ]) ifTrue: [ ^ false ].
	newCategory := UIManager default request: 'Move method to category:' initialAnswer: 'as yet unclassified'.
	(newCategory isNil or: [ newCategory isEmpty ]) ifTrue: [ ^ false ].
	source := sourceText text asString.
	source isEmpty ifTrue: [
		script := '[ | cls | cls := System myUserProfile symbolList objectNamed: #', className, '. cls ifNil: [ ^ false ]. (cls compiledMethodAt: #', selector asString, ' ifAbsent: [ ^ false ]) sourceString ] value'.
		source := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	].
	category := newCategory trimBoth.
	(self compileSource: source inClass: className category: category) ifFalse: [ ^ false ].
	self maybeAutoCommit.
	self classSelected: className.
	self protocolSelected: category.
	(methodsList respondsTo: #selectItem:) ifTrue: [ methodsList selectItem: selector asString ].
	^ true
]

{ #category : 'actions' }
GbsBrowser >> createClientClass [
	| serverName clientName superclass |
	serverName := self selectedClassName.
	serverName ifNil: [ ^ false ].
	clientName := 'GsClient', serverName.
	superclass := Object.
	(Smalltalk includesKey: clientName asSymbol) ifFalse: [
		superclass
			subclass: clientName asSymbol
			instanceVariableNames: ''
			classVariableNames: ''
			package: 'GemStone-GBS-Tools'
	].
	UIManager default inform: 'Created client class ', clientName.
	^ true
]

{ #category : 'actions' }
GbsBrowser >> compileClientClass [
	| serverName clientName source |
	serverName := self selectedClassName.
	serverName ifNil: [ ^ false ].
	clientName := ('GsClient', serverName) asSymbol.
	(Smalltalk includesKey: clientName) ifFalse: [ self createClientClass ].
	source := sourceText text asString.
	source isEmpty ifTrue: [ ^ false ].
	[ (Smalltalk at: clientName) compile: source classified: 'gemstone-imported' ] on: Error do: [ :ex | ^ false ].
	^ true
]

{ #category : 'actions' }
GbsBrowser >> fileOutMethod [
	| className selector source defaultPath path |
	className := self selectedClassName ifNil: [ 'UnknownClass' ].
	selector := self selectedMethodSelector ifNil: [ #unknown ].
	source := sourceText text asString.
	source isEmpty ifTrue: [ ^ false ].
	defaultPath := self defaultExportPathFor: className, '-', selector asString, '.st'.
	path := self requestExportPath: defaultPath.
	path ifNil: [ ^ false ].
	^ self writeExport: source toPath: path
]

{ #category : 'actions' }
GbsBrowser >> fileOutClass [
	| className script source defaultPath path |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	script := '[
		| cls stream |
		cls := System myUserProfile symbolList objectNamed: #', className, '.
		cls ifNil: [ ^ '''' ].
		stream := WriteStream on: String new.
		stream nextPutAll: (cls definition); lf; lf.
		cls selectors asSortedCollection do: [ :sel |
			| src |
			src := [ (cls compiledMethodAt: sel) sourceString ] on: Error do: [ '''' ].
			src isEmpty ifFalse: [ stream nextPutAll: src; lf; lf ] ].
		stream contents
	] value'.
	source := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	source isEmpty ifTrue: [ ^ false ].
	defaultPath := self defaultExportPathFor: className, '.st'.
	path := self requestExportPath: defaultPath.
	path ifNil: [ ^ false ].
	^ self writeExport: source toPath: path
]

{ #category : 'actions' }
GbsBrowser >> fileOutClassMethods [
	| className script source defaultPath path |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	script := '[
		| cls stream |
		cls := System myUserProfile symbolList objectNamed: #', className, '.
		cls ifNil: [ ^ '''' ].
		stream := WriteStream on: String new.
		cls selectors asSortedCollection do: [ :sel |
			| src |
			src := [ (cls compiledMethodAt: sel) sourceString ] on: Error do: [ '''' ].
			src isEmpty ifFalse: [ stream nextPutAll: src; lf; lf ] ].
		stream contents
	] value'.
	source := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	source isEmpty ifTrue: [ ^ false ].
	defaultPath := self defaultExportPathFor: className, '-methods.st'.
	path := self requestExportPath: defaultPath.
	path ifNil: [ ^ false ].
	^ self writeExport: source toPath: path
]

{ #category : 'actions' }
GbsBrowser >> fileOutDictionary [
	| dictName script source defaultPath path |
	dictName := self selectedDictionaryName.
	dictName ifNil: [ ^ false ].
	script := '[
		| dict stream classes |
		dict := System myUserProfile symbolList objectNamed: #', dictName, '.
		dict ifNil: [ ^ '''' ].
		stream := WriteStream on: String new.
		classes := dict keys select: [ :k | (dict at: k) isBehavior ].
		classes asSortedCollection do: [ :nm |
			| cls |
			cls := dict at: nm.
			stream nextPutAll: cls definition; lf; lf.
			cls selectors asSortedCollection do: [ :sel |
				| src |
				src := [ (cls compiledMethodAt: sel) sourceString ] on: Error do: [ '''' ].
				src isEmpty ifFalse: [ stream nextPutAll: src; lf; lf ] ] ].
		stream contents
	] value'.
	source := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	source isEmpty ifTrue: [ ^ false ].
	defaultPath := self defaultExportPathFor: dictName, '.st'.
	path := self requestExportPath: defaultPath.
	path ifNil: [ ^ false ].
	^ self writeExport: source toPath: path
]

{ #category : 'actions' }
GbsBrowser >> fileOutDictionaryMethods [
	| dictName script source defaultPath path |
	dictName := self selectedDictionaryName.
	dictName ifNil: [ ^ false ].
	script := '[
		| dict stream classes |
		dict := System myUserProfile symbolList objectNamed: #', dictName, '.
		dict ifNil: [ ^ '''' ].
		stream := WriteStream on: String new.
		classes := dict keys select: [ :k | (dict at: k) isBehavior ].
		classes asSortedCollection do: [ :nm |
			| cls |
			cls := dict at: nm.
			cls selectors asSortedCollection do: [ :sel |
				| src |
				src := [ (cls compiledMethodAt: sel) sourceString ] on: Error do: [ '''' ].
				src isEmpty ifFalse: [ stream nextPutAll: src; lf; lf ] ] ].
		stream contents
	] value'.
	source := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	source isEmpty ifTrue: [ ^ false ].
	defaultPath := self defaultExportPathFor: dictName, '-methods.st'.
	path := self requestExportPath: defaultPath.
	path ifNil: [ ^ false ].
	^ self writeExport: source toPath: path
]

{ #category : 'private' }
GbsBrowser >> requestExportPath: defaultPath [
	| answer |
	answer := UIManager default request: 'Export file path:' initialAnswer: defaultPath.
	(answer isNil or: [ answer isEmpty ]) ifTrue: [ ^ nil ].
	^ answer
]

{ #category : 'private' }
GbsBrowser >> defaultExportPathFor: fileName [
	^ (FileSystem workingDirectory / fileName) fullName
]

{ #category : 'private' }
GbsBrowser >> writeExport: text toPath: pathString [
	| ref |
	ref := pathString asFileReference.
	[ ref ensureDelete. ref writeStreamDo: [ :str | str nextPutAll: text ] ] on: Error do: [ :ex | ^ false ].
	UIManager default inform: 'Wrote ', pathString.
	^ true
]

{ #category : 'private' }
GbsBrowser >> selectorSubMenuDo: oneArgBlock [
	| selectors submenu |
	submenu := self newMenu.
	selectors := self methodSelectorsForSubmenu.
	selectors isEmpty ifTrue: [
		submenu addItem: [ :item |
			item
				name: '...';
				action: [ self deferAction: [ self promptSelectorAndDo: oneArgBlock ] ] ].
		^ submenu ].
	selectors do: [ :sel |
		submenu addItem: [ :item |
			item
				name: sel asString;
				action: [ self deferAction: [ oneArgBlock value: sel ] ] ] ].
	^ submenu
]

{ #category : 'private' }
GbsBrowser >> promptSelectorAndDo: oneArgBlock [
	| raw selector |
	raw := UIManager default request: 'Selector:' initialAnswer: ''.
	(raw isNil or: [ raw trimBoth isEmpty ]) ifTrue: [ ^ self ].
	selector := raw trimBoth asSymbol.
	^ oneArgBlock value: selector
]

{ #category : 'private' }
GbsBrowser >> methodSelectorsForSubmenu [
	| selectors selected |
	selectors := OrderedCollection new.
	selected := self selectedMethodSelector.
	selected ifNotNil: [ selectors add: selected ].
	(methodsList respondsTo: #items) ifTrue: [
		methodsList items do: [ :each |
			| symbol |
			symbol := each asString asSymbol.
			(selectors includes: symbol) ifFalse: [ selectors add: symbol ].
		]
	].
	^ selectors asArray
]

{ #category : 'actions' }
GbsBrowser >> browseSendersOf: aSelector [
	| refs |
	refs := self queryServerMethodsForSelector: aSelector asString mode: 'senders'.
	^ self openQueryResults: refs title: (self queryResultsTitleForSelector: aSelector asString mode: 'senders' count: refs size)
]

{ #category : 'actions' }
GbsBrowser >> browseImplementorsOf: aSelector [
	| refs |
	refs := self queryServerMethodsForSelector: aSelector asString mode: 'implementors'.
	^ self openQueryResults: refs title: (self queryResultsTitleForSelector: aSelector asString mode: 'implementors' count: refs size)
]

{ #category : 'actions' }
GbsBrowser >> browseHierarchySendersOf: aSelector [
	| refs |
	refs := self queryServerMethodsForSelector: aSelector asString mode: 'hierarchySenders'.
	^ self openQueryResults: refs title: (self queryResultsTitleForSelector: aSelector asString mode: 'hierarchySenders' count: refs size)
]

{ #category : 'actions' }
GbsBrowser >> browseHierarchyImplementorsOf: aSelector [
	| refs |
	refs := self queryServerMethodsForSelector: aSelector asString mode: 'hierarchyImplementors'.
	^ self openQueryResults: refs title: (self queryResultsTitleForSelector: aSelector asString mode: 'hierarchyImplementors' count: refs size)
]

{ #category : 'private' }
GbsBrowser >> openQueryResults: references [
	^ self openQueryResults: references title: 'Method matches'
]

{ #category : 'private' }
GbsBrowser >> openQueryResults: references title: titleString [
	| presenterClass |
	references isEmpty ifTrue: [ ^ false ].
	presenterClass := Smalltalk
		at: #GbsMethodQueryResultsPresenter
		ifAbsent: [ self ensureMethodQueryResultsPresenterLoaded ].
	^ [ 
		presenterClass ifNotNil: [
			presenterClass openOn: session references: references title: titleString.
			^ true ].
		false ]
		on: Error
		do: [ :ex |
			"Fallback to the older selection behavior if presenter cannot be opened."
			| selected |
			references size = 1 ifTrue: [ ^ self openMethodReference: references first ].
			selected := self uiChooseFrom: references title: titleString.
			selected = 0 ifTrue: [ ^ false ].
			self openMethodReference: (references at: selected) ]
]

{ #category : 'private' }
GbsBrowser >> ensureMethodQueryResultsPresenterLoaded [
	| tonelClass readerClass file defs |
	tonelClass := Smalltalk at: #TonelReader ifAbsent: [ ^ nil ].
	readerClass := tonelClass.
	file := '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src/GemStone-GBS-Tools/GbsMethodQueryResultsPresenter.class.st' asFileReference.
	file exists ifFalse: [ ^ nil ].
	[
		defs := readerClass new parseTonelFile: file.
		defs do: [ :def | def load ].
	] on: Error do: [ :ex | ^ nil ].
	^ Smalltalk at: #GbsMethodQueryResultsPresenter ifAbsent: [ nil ]
]

{ #category : 'private' }
GbsBrowser >> queryResultsTitleForSelector: selectorString mode: modeString count: aCount [
	| sessionPart modePart |
	sessionPart := (session respondsTo: #sessionId)
		ifTrue: [ 'Session ', session sessionId asString, ' ' ]
		ifFalse: [ '' ].
	modePart := modeString = 'implementors'
		ifTrue: [ 'Implementors of ' ]
		ifFalse: [
			modeString = 'senders'
				ifTrue: [ 'Senders of ' ]
				ifFalse: [
					modeString = 'references'
						ifTrue: [ 'References to ' ]
						ifFalse: [ 'Matches for ' ] ] ].
	^ sessionPart, modePart, selectorString asString, ' (', aCount asString, ')'
]

{ #category : 'private' }
GbsBrowser >> uiRequest: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : 'private' }
GbsBrowser >> uiChooseFrom: choices title: titleString [
	^ UIManager default chooseFrom: choices title: titleString
]

{ #category : 'private' }
GbsBrowser >> autoCommitMenuLabel [
	^ (autoCommitEnabled == true)
		ifTrue: [ '✓ Auto-Commit' ]
		ifFalse: [ 'Auto-Commit' ]
]

{ #category : 'actions' }
GbsBrowser >> toggleAutoCommit [
	autoCommitEnabled := autoCommitEnabled not.
	^ autoCommitEnabled
]

{ #category : 'private' }
GbsBrowser >> maybeAutoCommit [
	autoCommitEnabled ifFalse: [ ^ self ].
	self commitSession.
]

{ #category : 'actions' }
GbsBrowser >> beginSessionTransaction [
	(session respondsTo: #beginTransaction)
		ifTrue: [ session beginTransaction. ^ true ].
	^ [ session executeAndFetch: 'System beginTransaction' context: 20. true ]
		on: Error
		do: [ false ]
]

{ #category : 'actions' }
GbsBrowser >> refreshBrowserFromServer [
	| dictName className protocolName methodName |
	dictName := self selectedDictionaryName.
	className := self selectedClassName.
	protocolName := protocolsList selection selectedItem.
	methodName := methodsList selection selectedItem.
	self loadDictionaries.
	dictName ifNotNil: [ self selectDictionaryNamed: dictName ].
	className ifNotNil: [ self classSelected: className ].
	protocolName ifNotNil: [ self protocolSelected: protocolName ].
	methodName ifNotNil: [ self methodSelected: methodName ].
	^ true
]

{ #category : 'actions' }
GbsBrowser >> raiseGemStoneWindows [
	| windows |
	windows := SystemWindow allInstances select: [ :w |
		| label |
		label := [ w label asString ] on: Error do: [ '' ].
		(label includesSubstring: 'GemStone')
			or: [ (label includesSubstring: 'GBS') ]
	].
	windows do: [ :w | [ w activate ] on: Error do: [ ] ].
	^ true
]

{ #category : 'actions' }
GbsBrowser >> collapseGemStoneWindows [
	| windows |
	windows := SystemWindow allInstances select: [ :w |
		| label |
		label := [ w label asString ] on: Error do: [ '' ].
		(label includesSubstring: 'GemStone')
			or: [ (label includesSubstring: 'GBS') ]
	].
	windows do: [ :w | [ w collapseBoxHit ] on: Error do: [ ] ].
	^ true
]

{ #category : 'actions' }
GbsBrowser >> raiseGemStoneLauncher [
	| didRaise |
	didRaise := false.
	GbsClassicLauncher allInstancesDo: [ :each |
		didRaise := true.
		each withWindowDo: [ :w | w window ifNotNil: [ :m | m activate ] ] ].
	GbsLauncher allInstancesDo: [ :each |
		didRaise := true.
		each withWindowDo: [ :w | w window ifNotNil: [ :m | m activate ] ] ].
	didRaise ifFalse: [ GbsClassicLauncher new open ].
	^ true
]

{ #category : 'actions' }
GbsBrowser >> inspectMethod [
	| className selector script oop |
	className := self selectedClassName.
	selector := self selectedMethodSelector.
	(className isNil or: [ selector isNil ]) ifTrue: [ ^ false ].
	script := '(System myUserProfile symbolList objectNamed: #', className, ') compiledMethodAt: #', selector asString.
	oop := session serverInterface apiGciExecuteStr: script context: 20 env: 0.
	(oop isNumber and: [ oop > 20 ]) ifFalse: [ ^ false ].
	GbsInspector inspect: oop session: session.
	^ true
]
