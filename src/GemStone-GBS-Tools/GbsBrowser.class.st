Class {
	#name : 'GbsBrowser',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
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
	| browser |
	aSession ifNil: [ ^ self inform: 'You must log into GemStone first!' ].
	
	browser := self new.
	browser session: aSession.
	browser loadDictionaries.
	browser open.
	^ browser
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
	metaString := metaCheckbox state ifTrue: [' class'] ifFalse: [''].
	
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
	
	metaString := metaCheckbox state ifTrue: [' class'] ifFalse: [''].
	
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
			self inform: 'Compiled successfully!'.
			"Refresh the method list so the new method appears!"
			self protocolSelected: protocolsList selection selectedItem.
		].
]

{ #category : 'layout' }
GbsBrowser >> defaultLayout [
	^ SpBoxLayout newVertical
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
	metaString := metaCheckbox state ifTrue: [' class'] ifFalse: [''].
	
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
	metaString := metaCheckbox state ifTrue: [' class'] ifFalse: [''].
	
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
