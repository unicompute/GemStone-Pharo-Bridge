Extension { #name : 'GbsBrowser' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> browseNamedObjectCacheReport [
	self inform: session namedObjectCacheReportText.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> browsePromptedSessionStateKey [
	| rawKey key |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	rawKey := self uiRequest: 'Session state key:' initialAnswer: '19'.
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
GbsBrowser >> browsePromptedSessionStateKeysReport [
	| rawKeys keys |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	rawKeys := self uiRequest: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ false ].
	self inform: (session objectSpaceDiagnostics reportTextForKeys: keys).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> browseSessionStateAtKey: aKey [
	| sessionStateValue oop |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	sessionStateValue := [ session sessionStateAt: aKey ]
		on: Error
		do: [ :ex |
			self inform: 'Session state lookup failed: ', ex messageText.
			^ false ].
	sessionStateValue ifNil: [
		self inform: 'Session state key ', aKey printString, ' is not set.'.
		^ false ].
	oop := [ sessionStateValue oop ]
		on: Error
		do: [ nil ].
	oop ifNil: [
		((sessionStateValue isInteger) and: [ sessionStateValue > 20 ])
			ifTrue: [ oop := sessionStateValue ] ].
	oop ifNil: [
		self inform: 'Session state key ', aKey printString, ' does not currently have an inspectable remote oop.'.
		^ false ].
	^ self inspectOop: oop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> browseTypedWrapperAutoloadReport [
	self inform: (GbsSessionManager typedWrapperAutoloadReportTextForSession: session).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> browseTypedWrapperLifecycleReport [
	self inform: session typedWrapperLifecycleReportText.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> browseStaleTypedWrapperLifecycleReport [
	| report staleEntries |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	report := session typedWrapperLifecycleReport.
	staleEntries := report staleEntries.
	staleEntries isEmpty ifTrue: [
		self inform: 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.'.
		^ true ].
	self inform: (GbsTypedWrapperLifecycleReport entries: staleEntries) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> browseObjectsInMemoryReport [
	| start limit |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	start := self
		requestPositiveInteger: 'Object scan start index:'
		initialAnswer: '1'.
	start ifNil: [ ^ false ].
	limit := self
		requestPositiveInteger: 'Object scan limit:'
		initialAnswer: '25'.
	limit ifNil: [ ^ false ].
	self inform: (session objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> refreshAllTypedWrappers [
	| refreshed |
	refreshed := session refreshAllTypedWrapperClasses.
	self inform: 'Refreshed ', refreshed size printString, ' typed wrapper(s).'.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> refreshStaleTypedWrappers [
	| refreshed |
	refreshed := session refreshStaleTypedWrapperClasses.
	self inform: 'Refreshed ', refreshed size printString, ' stale typed wrapper(s).'.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> clearNamedObjectCache [
	session clearNamedObjectCache.
	self inform: 'Named object cache cleared.'.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> menuSession [
	| menu |
	menu := self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: self autoCommitMenuLabel; action: [ self deferAction: [ self toggleAutoCommit ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Commit Transaction'; action: [ self deferAction: [ self commitSession ] ] ].
			group addItem: [ :item | item name: 'Abort Transaction'; action: [ self deferAction: [ self abortSession ] ] ].
			group addItem: [ :item | item name: 'Begin Transaction'; action: [ self deferAction: [ self beginSessionTransaction ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Named Object Cache Report'; action: [ self deferAction: [ self browseNamedObjectCacheReport ] ] ].
			group addItem: [ :item | item name: 'Clear Named Object Cache'; action: [ self deferAction: [ self clearNamedObjectCache ] ] ].
			group addItem: [ :item | item name: 'Typed Wrapper Autoload Report'; action: [ self deferAction: [ self browseTypedWrapperAutoloadReport ] ] ].
			group addItem: [ :item | item name: 'Typed Wrapper Lifecycle Report'; action: [ self deferAction: [ self browseTypedWrapperLifecycleReport ] ] ].
			group addItem: [ :item | item name: 'Stale Typed Wrapper Report'; action: [ self deferAction: [ self browseStaleTypedWrapperLifecycleReport ] ] ].
			group addItem: [ :item | item name: 'Refresh Stale Typed Wrappers'; action: [ self deferAction: [ self refreshStaleTypedWrappers ] ] ].
			group addItem: [ :item | item name: 'Refresh All Typed Wrappers'; action: [ self deferAction: [ self refreshAllTypedWrappers ] ] ].
			group addItem: [ :item | item name: 'Inspect Session State Key...'; action: [ self deferAction: [ self browsePromptedSessionStateKey ] ] ].
			group addItem: [ :item | item name: 'Session State Keys Report...'; action: [ self deferAction: [ self browsePromptedSessionStateKeysReport ] ] ].
			group addItem: [ :item | item name: 'Objects In Memory Report...'; action: [ self deferAction: [ self browseObjectsInMemoryReport ] ] ].
			self addExtensionSessionMenuItemsTo: group ];
		yourself.
	^ menu
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> parseSessionStateKeysFrom: aStringOrNil [
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
GbsBrowser >> requestPositiveInteger: promptString initialAnswer: defaultString [
	| rawValue |
	rawValue := self uiRequest: promptString initialAnswer: defaultString.
	(rawValue isNil or: [ rawValue trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ [ | value |
		value := rawValue trimBoth asInteger.
		value > 0 ifTrue: [ value ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> browseClassInfo [
	| mirror |
	mirror := self selectedClassMirror.
	mirror ifNil: [
		self inform: 'No class selected!'.
		^ false ].
	self inform: (self classInfoTextForMirror: mirror).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> browseMethodInfo [
	| methodObject |
	methodObject := self selectedUnboundMethodObject.
	methodObject ifNil: [
		self inform: 'No method selected!'.
		^ false ].
	self inform: (self methodInfoTextForMirror: methodObject).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> browseVersions [
	| methodObject versions idx |
	methodObject := self selectedUnboundMethodObject.
	methodObject ifNil: [ ^ false ].
	versions := methodObject versionEntries.
	versions ifNil: [ ^ false ].
	versions := versions reject: [ :each | each isNil ].
	versions isEmpty ifTrue: [ ^ false ].
	idx := self
		uiChooseFrom: (versions collect: [ :each | each first asString ])
		title: 'Method Versions'.
	idx = 0 ifTrue: [ ^ false ].
	sourceText text: (((versions at: idx) at: 2 ifAbsent: [ '' ]) ifNil: [ '' ] ifNotNil: [ :src | src asString ]).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> classSelected: className [
	| mirror entries categories |

	className ifNil: [
		protocolsList items: #().
		methodsList items: #().
		sourceText text: ''.
		^ self ].

	mirror := session classMirrorOfNamed: className.
	entries := self classSideSelected
		ifTrue: [ mirror classProtocols ]
		ifFalse: [ mirror instanceProtocols ].
	categories := entries collect: [ :each | (each at: 1) asString ].
	categories := {'-- all --'} asOrderedCollection addAll: categories; yourself.
	protocolsList items: categories.
	methodsList items: #().
	sourceText text: ''
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> classInfoTextForMirror: aMirror [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Class: ';
			nextPutAll: (self infoValueForDisplay: aMirror name);
			lf;
			nextPutAll: 'Browser side: ';
			nextPutAll: (self classSideSelected ifTrue: [ 'class' ] ifFalse: [ 'instance' ]);
			lf;
			nextPutAll: 'Superclass: ';
			nextPutAll: (self infoValueForDisplay: aMirror superclassName);
			lf;
			nextPutAll: 'Package: ';
			nextPutAll: (self infoValueForDisplay: aMirror packageName);
			lf;
			nextPutAll: 'Category: ';
			nextPutAll: (self infoValueForDisplay: aMirror categoryName);
			lf;
			nextPutAll: 'Version: ';
			nextPutAll: (self versionSummaryCurrent: aMirror version total: aMirror numberOfVersions);
			lf;
			nextPutAll: 'OOP: ';
			nextPutAll: (self infoValueForDisplay: aMirror oop) ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> gsInspectIt [
	| code oop |
	code := self selectedCodeOrAll.
	code isEmpty ifTrue: [ ^ false ].
	oop := session serverInterface apiGciExecuteStr: code context: 20 env: 0.
	^ (oop isNumber and: [ oop > 20 ])
		ifTrue: [ self inspectOop: oop ]
		ifFalse: [ false ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> inspectAllInstances [
	| className oop |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	oop := session repository allInstancesOopOfNamed: className.
	(oop isNumber and: [ oop > 20 ]) ifFalse: [ ^ false ].
	^ self inspectOop: oop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> inspectClass [
	| className object oop |
	className := self selectedClassName.
	className ifNil: [ ^ false ].
	object := session namedObjectAt: className ifAbsent: [ nil ].
	oop := (object isKindOf: GbsProxy)
		ifTrue: [ object oop ]
		ifFalse: [ nil ].
	(oop isNumber and: [ oop > 20 ]) ifFalse: [ ^ false ].
	^ self inspectOop: oop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> inspectDictionary [
	| name object oop |
	name := self selectedDictionaryName.
	name ifNil: [ ^ false ].
	object := session namedObjectAt: name ifAbsent: [ nil ].
	oop := (object isKindOf: GbsProxy)
		ifTrue: [ object oop ]
		ifFalse: [ nil ].
	(oop isNumber and: [ oop > 20 ]) ifFalse: [ ^ false ].
	^ self inspectOop: oop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> inspectMethod [
	| methodObject oop |
	methodObject := self selectedUnboundMethodObject.
	methodObject ifNil: [ ^ false ].
	oop := methodObject oop.
	(oop isNumber and: [ oop > 20 ]) ifFalse: [ ^ false ].
	^ self inspectOop: oop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> invokeSelectedMethod [
	| methodObject invocationArguments result |
	methodObject := self selectedMethodObject.
	methodObject ifNil: [
		self inform: 'No method selected!'.
		^ false ].
	methodObject classSide ifFalse: [
		self inform: 'Browser invocation only supports class-side methods. Use the debugger to bind an instance receiver.'.
		^ false ].
	invocationArguments := self invocationArgumentsForMethodObject: methodObject.
	invocationArguments ifNil: [ ^ false ].
	result := [ methodObject callWithArguments: invocationArguments ] on: Error do: [ :ex |
		self inform: 'GemStone invoke failed: ', ex messageText.
		^ false ].
	self inform: 'GemStone method result: ', result printString.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> invocationArgumentsForMethodObject: aMethodObject [
	| argumentCount input |
	aMethodObject ifNil: [ ^ nil ].
	argumentCount := aMethodObject selector numArgs.
	argumentCount = 0 ifTrue: [ ^ #() ].
	input := self
		uiRequest: (GbsRemoteMethodObject
			invocationPromptForSelector: aMethodObject selector
			argumentCount: argumentCount)
		initialAnswer: (GbsRemoteMethodObject defaultArgumentInputForCount: argumentCount).
	input ifNil: [ ^ nil ].
	^ GbsRemoteMethodObject
		argumentsFromInput: input
		expectedCount: argumentCount
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> loadDictionaries [
	| dicts |
	dicts := [ session fetchRemoteDictionaries ] on: Error do: [ #() ].
	dicts := (dicts ifNil: [ #() ] ifNotNil: [ dicts ])
		collect: [ :each | each asString trimBoth ]
		thenReject: #isEmpty.
	dictionariesList items: dicts.
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> menuClass [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'File Out As ...'; action: [ self deferAction: [ self fileOutClass ] ] ].
			group addItem: [ :item | item name: 'File Out Methods As ...'; action: [ self deferAction: [ self fileOutClassMethods ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Browse Class'; action: [ self deferAction: [ self browseClass ] ] ].
			group addItem: [ :item | item name: 'Browse Class Info'; action: [ self deferAction: [ self browseClassInfo ] ] ].
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

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> menuMethod [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'File Out As ...'; action: [ self deferAction: [ self fileOutMethod ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Browse'; action: [ self deferAction: [ self browseMethod ] ] ].
			group addItem: [ :item | item name: 'Browse Method Info'; action: [ self deferAction: [ self browseMethodInfo ] ] ].
			group addItem: [ :item | item name: 'Browse Hierarchy'; action: [ self deferAction: [ self browseHierarchy ] ] ].
			group addItem: [ :item | item name: 'Invoke in GemStone'; action: [ self deferAction: [ self invokeSelectedMethod ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Browse Senders'; action: [ self deferAction: [ self querySenders ] ] ].
			group addItem: [ :item | item name: 'Browse Implementors'; action: [ self deferAction: [ self queryImplementors ] ] ].
			group addItem: [ :item | item name: 'Browse Hierarchy Senders'; subMenu: self menuHierarchySenders ].
			group addItem: [ :item | item name: 'Browse Hierarchy Implementors'; subMenu: self menuHierarchyImplementors ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Move To ...'; action: [ self deferAction: [ self moveMethodToCategory ] ] ].
			group addItem: [ :item | item name: 'Remove...'; action: [ self deferAction: [ self removeMethod ] ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Compile Client Method'; action: [ self deferAction: [ self acceptText: sourceText text asString ] ] ].
			group addItem: [ :item | item name: 'Inspect'; action: [ self deferAction: [ self inspectMethod ] ] ] ];
		yourself
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> methodSelected: selectorName [
	| methodObject rawSource |

	selectorName ifNil: [ ^ sourceText text: '' ].
	methodObject := self selectedUnboundMethodObjectForSelector: selectorName asSymbol.
	methodObject ifNil: [ ^ self ].
	rawSource := methodObject sourceCode.
	sourceText text: (rawSource ifNil: [ '' ] ifNotNil: [ rawSource asString ]).
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> openMethodObject: aMethodObject [
	aMethodObject ifNil: [ ^ false ].
	^ self
		selectClassNamed: aMethodObject ownerName
		classSide: aMethodObject isClassSide
		method: aMethodObject selector asString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> protocolSelected: protocolName [
	| mirror protocolEntries selectors entry |

	protocolName ifNil: [ ^ methodsList items: #(); yourself. sourceText text: '' ].
	mirror := self selectedClassMirror.
	mirror ifNil: [ ^ self ].
	protocolEntries := self classSideSelected
		ifTrue: [ mirror classProtocols ]
		ifFalse: [ mirror instanceProtocols ].
	selectors := protocolName = '-- all --'
		ifTrue: [
			(self classSideSelected
				ifTrue: [ mirror classSelectors ]
				ifFalse: [ mirror instanceSelectors ]) ]
		ifFalse: [
			entry := protocolEntries
				detect: [ :each | (each at: 1 ifAbsent: [ '' ]) asString = protocolName asString ]
				ifNone: [ nil ].
			entry
				ifNil: [ #() ]
				ifNotNil: [ entry at: 2 ifAbsent: [ #() ] ] ].
	selectors := selectors collect: [ :each | each asString ].
	methodsList items: selectors.
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> classSideSelected [
	^ metaCheckbox notNil
		and: [ (metaCheckbox respondsTo: #state)
		and: [ metaCheckbox state == true ] ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> infoValueForDisplay: anObject [
	anObject ifNil: [ ^ '<none>' ].
	^ anObject asString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> inform: aString [
	UIManager default inform: aString.
	^ aString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> inspectOop: anOop [
	GbsInspector inspect: anOop session: session.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> methodInfoTextForMirror: aMirror [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Method: ';
			nextPutAll: (self infoValueForDisplay: aMirror ownerName);
			nextPutAll: '>>';
			nextPutAll: (self infoValueForDisplay: aMirror selector);
			lf;
			nextPutAll: 'Side: ';
			nextPutAll: (aMirror classSide ifTrue: [ 'class' ] ifFalse: [ 'instance' ]);
			lf;
			nextPutAll: 'Owner: ';
			nextPutAll: (self infoValueForDisplay: aMirror ownerName);
			lf;
			nextPutAll: 'Selector: ';
			nextPutAll: (self infoValueForDisplay: aMirror selector);
			lf;
			nextPutAll: 'Binding: ';
			nextPutAll: ((aMirror respondsTo: #isBound)
				ifTrue: [ aMirror isBound ifTrue: [ 'bound' ] ifFalse: [ 'unbound' ] ]
				ifFalse: [ 'n/a' ]);
			lf;
			nextPutAll: 'Arity: ';
			nextPutAll: (self infoValueForDisplay: ((aMirror respondsTo: #arity)
				ifTrue: [ aMirror arity ]
				ifFalse: [ nil ]));
			lf;
			nextPutAll: 'Protocol: ';
			nextPutAll: (self infoValueForDisplay: aMirror protocol);
			lf;
			nextPutAll: 'Package: ';
			nextPutAll: (self infoValueForDisplay: aMirror packageName);
			lf;
			nextPutAll: 'Source location: ';
			nextPutAll: (self infoValueForDisplay: aMirror sourceLocation);
			lf;
			nextPutAll: 'Version: ';
			nextPutAll: (self versionSummaryCurrent: aMirror version total: aMirror numberOfVersions);
			lf;
			nextPutAll: 'OOP: ';
			nextPutAll: (self infoValueForDisplay: aMirror oop) ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> selectedClassMirror [
	| className |
	className := self selectedClassName.
	className ifNil: [ ^ nil ].
	^ session classMirrorOfNamed: className
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> selectedMethodMirror [
	| selector |
	selector := self selectedMethodSelector.
	selector ifNil: [ ^ nil ].
	^ self selectedMethodMirrorForSelector: selector
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> selectedMethodMirrorForSelector: aSelector [
	| className |
	className := self selectedClassName.
	className ifNil: [ ^ nil ].
	^ self classSideSelected
		ifTrue: [ session classMethodMirrorForClassNamed: className selector: aSelector ]
		ifFalse: [ session methodMirrorForClassNamed: className selector: aSelector ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> selectedMethodObject [
	| selector |
	selector := self selectedMethodSelector.
	selector ifNil: [ ^ nil ].
	^ self selectedMethodObjectForSelector: selector
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> selectedMethodObjectForSelector: aSelector [
	| className |
	className := self selectedClassName.
	className ifNil: [ ^ nil ].
	^ self classSideSelected
		ifTrue: [ session classMethodObjectForClassNamed: className selector: aSelector ]
		ifFalse: [ session methodObjectForClassNamed: className selector: aSelector ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> selectedUnboundMethodObject [
	| selector |
	selector := self selectedMethodSelector.
	selector ifNil: [ ^ nil ].
	^ self selectedUnboundMethodObjectForSelector: selector
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> selectedUnboundMethodObjectForSelector: aSelector [
	| className |
	className := self selectedClassName.
	className ifNil: [ ^ nil ].
	^ self classSideSelected
		ifTrue: [ session classUnboundMethodObjectForClassNamed: className selector: aSelector ]
		ifFalse: [ session unboundMethodObjectForClassNamed: className selector: aSelector ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> versionSummaryCurrent: currentVersion total: totalVersions [
	(currentVersion isNil and: [ totalVersions isNil ]) ifTrue: [ ^ '<none>' ].
	currentVersion ifNil: [ ^ 'of ', (self infoValueForDisplay: totalVersions) ].
	totalVersions ifNil: [ ^ currentVersion asString ].
	^ currentVersion asString, ' of ', totalVersions asString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsBrowser >> queryServerMethodsForSelector: selectorName mode: modeString rootClassName: rootClassName hierarchyScope: scopeString [
	(#('hierarchyImplementors' 'hierarchySenders') includes: modeString) ifTrue: [
		^ [ modeString = 'hierarchySenders'
			ifTrue: [
				session
					hierarchySenderMethodReferenceStringsForSelector: selectorName asString trimBoth
					rootClassName: rootClassName
					scope: scopeString ]
			ifFalse: [
				session
					hierarchyImplementorMethodReferenceStringsForSelector: selectorName asString trimBoth
					rootClassName: rootClassName
					scope: scopeString ] ]
			on: Error
			do: [ :ex | self queryServerMethodsByScanningForSelector: selectorName mode: modeString rootClassName: rootClassName hierarchyScope: scopeString ] ].
	((#('implementors' 'senders' 'references') includes: modeString)
		and: [ Smalltalk includesKey: #GbsClassicLauncher ]) ifTrue: [
		^ [ GbsClassicLauncher
			queryOrganizerMethodsFor: selectorName asString trimBoth
			mode: modeString
			inSession: session ]
			on: Error
			do: [ :ex | self queryServerMethodsByScanningForSelector: selectorName mode: modeString rootClassName: rootClassName hierarchyScope: scopeString ] ].
	^ self queryServerMethodsByScanningForSelector: selectorName mode: modeString rootClassName: rootClassName hierarchyScope: scopeString
]
