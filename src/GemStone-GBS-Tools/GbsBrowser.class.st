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
	(aDictionaryName isString and: [ aDictionaryName isEmpty not ]) ifFalse: [ ^ self ].
	dicts := (dictionariesList respondsTo: #items)
		ifTrue: [ dictionariesList items ]
		ifFalse: [ #( ) ].
	(dicts includes: aDictionaryName) ifTrue: [
		(dictionariesList respondsTo: #selectItem:) ifTrue: [ dictionariesList selectItem: aDictionaryName ].
		self dictionarySelected: aDictionaryName
	]
]

{ #category : 'actions' }
GbsBrowser >> selectClassNamed: aClassName classSide: classSideBoolean method: aSelectorString [
	| clsItems chosenProtocol |
	(aClassName isString and: [ aClassName isEmpty not ]) ifFalse: [ ^ self ].
	(metaCheckbox respondsTo: #state:) ifTrue: [ metaCheckbox state: classSideBoolean ].
	clsItems := (classesList respondsTo: #items)
		ifTrue: [ classesList items ]
		ifFalse: [ #( ) ].
	(clsItems includes: aClassName) ifFalse: [ ^ self ].
	(classesList respondsTo: #selectItem:) ifTrue: [ classesList selectItem: aClassName ].
	self classSelected: aClassName.
	chosenProtocol := '-- all --'.
	(protocolsList respondsTo: #selectItem:) ifTrue: [ protocolsList selectItem: chosenProtocol ].
	self protocolSelected: chosenProtocol.
	(methodsList respondsTo: #selectItem:) ifTrue: [ methodsList selectItem: aSelectorString ].
	self methodSelected: aSelectorString
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
	^ self selectClassNamed: name trimBoth classSide: false method: nil
]

{ #category : 'actions' }
GbsBrowser >> browseDictionary [
	^ self selectedDictionaryName notNil
]

{ #category : 'actions' }
GbsBrowser >> browseClass [
	^ self selectedClassName notNil
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
	^ self queryMethodsForSelectorPrompt: 'References to selector:' mode: 'references'
]

{ #category : 'private' }
GbsBrowser >> queryMethodsForSelectorPrompt: prompt mode: modeString [
	| selectorName references selected |
	selectorName := UIManager default request: prompt initialAnswer: ''.
	(selectorName isNil or: [ selectorName isEmpty ]) ifTrue: [ ^ false ].
	references := self queryServerMethodsForSelector: selectorName trimBoth mode: modeString.
	references isEmpty ifTrue: [ ^ self informNotImplemented: 'No matches found.' ].
	selected := UIManager default chooseFrom: references title: 'Matches'.
	selected = 0 ifTrue: [ ^ false ].
	^ self openMethodReference: (references at: selected)
]

{ #category : 'private' }
GbsBrowser >> queryServerMethodsForSelector: selectorName mode: modeString [
	| escapedSelector selectedClassName escapedClass script raw selectorExpr classFilterExpr |
	escapedSelector := selectorName copyReplaceAll: '''' with: ''''''.
	selectedClassName := self selectedClassName ifNil: [ '' ].
	escapedClass := selectedClassName copyReplaceAll: '''' with: ''''''.
	selectorExpr := (modeString = 'implementors' or: [ modeString = 'hierarchyImplementors' ])
		ifTrue: [ 'sels := (cls includesSelector: sel) ifTrue: [ Array with: sel ] ifFalse: [ #() ]' ]
		ifFalse: [ 'sels := [ cls whichSelectorsReferTo: sel ] on: Error do: [ #() ]' ].
	classFilterExpr := (modeString = 'hierarchySenders' or: [ modeString = 'hierarchyImplementors' ])
		ifTrue: [ '((rootClass notNil) and: [ ((cls withAllSuperclasses includes: rootClass) or: [ rootClass withAllSuperclasses includes: cls ]) not ]) ifTrue: [ sels := #() ]' ]
		ifFalse: [ '' ].
	script := '[
		| sel classes stream rootClass |
		sel := #''', escapedSelector, '''.
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
	^ (raw splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty
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
	pattern := UIManager default request: 'Source substring:' initialAnswer: ''.
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
	matches := (raw splitOn: Character lf) collect: #trimBoth thenReject: #isEmpty.
	matches isEmpty ifTrue: [ ^ self informNotImplemented: 'No methods matched.' ].
	selected := UIManager default chooseFrom: matches title: 'Matching Methods'.
	selected = 0 ifTrue: [ ^ false ].
	^ self openMethodReference: (matches at: selected)
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
	selectors isEmpty ifTrue: [ ^ submenu ].
	selectors do: [ :sel |
		submenu addItem: [ :item |
			item
				name: sel asString;
				action: [ self deferAction: [ oneArgBlock value: sel ] ] ] ].
	^ submenu
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
	^ self openQueryResults: (self queryServerMethodsForSelector: aSelector asString mode: 'senders')
]

{ #category : 'actions' }
GbsBrowser >> browseImplementorsOf: aSelector [
	^ self openQueryResults: (self queryServerMethodsForSelector: aSelector asString mode: 'implementors')
]

{ #category : 'actions' }
GbsBrowser >> browseHierarchySendersOf: aSelector [
	^ self openQueryResults: (self queryServerMethodsForSelector: aSelector asString mode: 'hierarchySenders')
]

{ #category : 'actions' }
GbsBrowser >> browseHierarchyImplementorsOf: aSelector [
	^ self openQueryResults: (self queryServerMethodsForSelector: aSelector asString mode: 'hierarchyImplementors')
]

{ #category : 'private' }
GbsBrowser >> openQueryResults: references [
	| selected |
	references isEmpty ifTrue: [ ^ false ].
	selected := UIManager default chooseFrom: references title: 'Matches'.
	selected = 0 ifTrue: [ ^ false ].
	^ self openMethodReference: (references at: selected)
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
