Extension { #name : 'GbsMethodQueryResultsPresenter' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter class >> openOn: aSession query: aMethodQuery [
	| presenter |
	presenter := self new.
	presenter
		session: aSession;
		methodQuery: aMethodQuery;
		references: aMethodQuery references;
		windowTitle: aMethodQuery title;
		open.
	^ presenter
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> methodQuery [
	^ self propertyAt: #methodQuery ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> methodQuery: aMethodQuery [
	self propertyAt: #methodQuery put: aMethodQuery.
	^ aMethodQuery
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> referencesButton [
	^ self propertyAt: #referencesButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> referencesButton: aButton [
	self propertyAt: #referencesButton put: aButton.
	^ aButton
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> browseReferencesToSelectedClass [
	| className queryRefs title |
	className := self selectedReferenceClassName.
	className ifNil: [ ^ false ].
	queryRefs := [ session methodReferenceStringsToSymbol: className ]
		on: Error
		do: [ #() ].
	queryRefs isEmpty ifTrue: [
		UIManager default inform: 'No matches found.'.
		^ false ].
	title := self
		queryResultsTitleForSelector: className
		modePrefix: 'References to '
		count: queryRefs size.
	^ self class openOn: session references: queryRefs title: title
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> browseSelectedReference [
	| methodObject ref |
	methodObject := self selectedUnboundMethodObject.
	methodObject ifNotNil: [ ^ self browseMethodObject: methodObject ].
	ref := self selectedReference.
	ref ifNil: [ ^ self ].
	^ self browseMethodReference: ref asString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> browseSelectedMethodInfo [
	| methodObject |
	methodObject := self selectedUnboundMethodObject.
	methodObject ifNil: [
		self inform: 'Select a method first.'.
		^ false ].
	self inform: (self methodInfoTextFor: methodObject).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> buildActionBar [
	^ SpBoxLayout newLeftToRight
		spacing: 6;
		add: btnBrowse expand: false;
		add: btnHierarchySenders expand: false;
		add: btnHierarchyImplementors expand: false;
		add: btnSenders expand: false;
		add: btnImplementors expand: false;
		add: self referencesButton expand: false;
		add: btnFileOut expand: false;
		add: btnRefresh expand: false;
		yourself
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> inform: aString [
	UIManager default inform: aString.
	^ aString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> browseMethodObject: aMethodObject [
	| worker |
	aMethodObject ifNil: [ ^ false ].
	worker := GbsBrowser new.
	worker session: session.
	(worker respondsTo: #openMethodObject:)
		ifTrue: [ ^ worker openMethodObject: aMethodObject ].
	^ self browseMethodReference: aMethodObject name
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> browseMethodReference: referenceString [
	| worker |
	referenceString ifNil: [ ^ false ].
	worker := GbsBrowser new.
	worker session: session.
	(worker openMethodReference: referenceString asString)
		ifFalse: [ self inform: 'Could not browse selected method.' ].
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> inspectSelectedMethod [
	| methodObject oop |
	methodObject := self selectedUnboundMethodObject.
	methodObject ifNil: [
		self inform: 'Select a method first.'.
		^ false ].
	oop := methodObject oop.
	(oop isInteger and: [ oop > 20 ]) ifFalse: [ ^ false ].
	^ self openInspectorOnOop: oop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> invokeSelectedMethod [
	| methodObject invocationArguments result |
	methodObject := self selectedMethodObject.
	methodObject ifNil: [
		self inform: 'Select a method first.'.
		^ false ].
	methodObject classSide ifFalse: [
		self inform: 'Query results invocation only supports class-side methods. Use the debugger to bind an instance receiver.'.
		^ false ].
	invocationArguments := self invocationArgumentsForMethodObject: methodObject.
	invocationArguments ifNil: [ ^ false ].
	result := [ methodObject callWithArguments: invocationArguments ]
		on: Error
		do: [ :ex |
			self inform: 'GemStone invoke failed: ', ex messageText.
			^ false ].
	self inform: 'GemStone method result: ', result printString.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> iconForReferencesAction [
	^ self iconNamed: #smallFind
]

{ #category : '*GemStone-GBS-Core-Tools' }
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
	self referencesButton: (self newButton
		label: 'References';
		icon: (self iconForReferencesAction);
		action: [ self browseReferencesToSelectedClass ];
		yourself).
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
	selectionStatus := self newLabel label: ''
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> menuMethod [
	^ self newMenu
		addGroup: [ :group |
			group addItem: [ :item |
				item
					name: 'Browse';
					icon: self iconForBrowseAction;
					action: [ self browseSelectedReference ] ].
			group addItem: [ :item |
				item
					name: 'Browse Hierarchy';
					icon: self iconForHierarchyImplementorsAction;
					action: [ self browseHierarchyImplementorsOfSelected ] ].
			group addItem: [ :item |
				item
					name: 'Browse Method Info';
					action: [ self browseSelectedMethodInfo ] ].
			group addItem: [ :item |
				item
					name: 'Inspect';
					action: [ self inspectSelectedMethod ] ] ];
		addGroup: [ :group |
			group addItem: [ :item |
				item
					name: 'Senders';
					icon: self iconForSendersAction;
					action: [ self browseSendersOfSelected ] ].
			group addItem: [ :item |
				item
					name: 'Implementors';
					icon: self iconForImplementorsAction;
					action: [ self browseImplementorsOfSelected ] ].
			group addItem: [ :item |
				item
					name: 'References';
					icon: self iconForReferencesAction;
					action: [ self browseReferencesToSelectedClass ] ].
			group addItem: [ :item |
				item
					name: 'Invoke in GemStone';
					action: [ self invokeSelectedMethod ] ].
			group addItem: [ :item | item name: 'Hierarchy Senders'; subMenu: self menuHierarchySenders ].
			group addItem: [ :item | item name: 'Hierarchy Implementors'; subMenu: self menuHierarchyImplementors ] ];
		addGroup: [ :group |
			group addItem: [ :item |
				item
					name: 'File Out As...';
					icon: self iconForFileOutAction;
					action: [ self fileOutSelectedReferenceAs ] ] ];
		yourself
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> methodMirrorForReference: referenceString [
	| methodObject |
	methodObject := self unboundMethodObjectForReference: referenceString.
	^ methodObject ifNil: [ nil ] ifNotNil: [ methodObject mirror ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> methodInfoTextFor: aMethodObject [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Class: ';
			nextPutAll: aMethodObject ownerName;
			lf;
			nextPutAll: 'Selector: #';
			nextPutAll: aMethodObject selector asString;
			lf;
			nextPutAll: 'Binding: ';
			nextPutAll: (aMethodObject isBound ifTrue: [ 'bound' ] ifFalse: [ 'unbound' ]);
			lf;
			nextPutAll: 'Arity: ';
			nextPutAll: aMethodObject arity asString;
			lf;
			nextPutAll: 'Protocol: ';
			nextPutAll: aMethodObject protocol asString;
			lf;
			nextPutAll: 'Package: ';
			nextPutAll: aMethodObject packageName asString;
			lf;
			nextPutAll: 'Version: ';
			nextPutAll: aMethodObject version asString;
			nextPutAll: ' of ';
			nextPutAll: aMethodObject numberOfVersions asString;
			lf;
			nextPutAll: 'Source: ';
			nextPutAll: aMethodObject sourceLocation asString ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> methodObjectForReference: referenceString [
	| parsed className selector |
	self methodQuery ifNotNil: [
		^ [ self methodQuery methodObjectForReference: referenceString ]
			on: Error
			do: [ :ex | nil ] ].
	referenceString ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	parsed := self parseReference: referenceString asString.
	parsed ifNil: [ ^ nil ].
	className := parsed first.
	selector := parsed second asSymbol.
	^ parsed third
		ifTrue: [ session classMethodObjectForClassNamed: className selector: selector ]
		ifFalse: [ session methodObjectForClassNamed: className selector: selector ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> browseNamedObjectCacheReport [
	self inform: session namedObjectCacheReportText.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> browseTypedWrapperLifecycleReport [
	self inform: session typedWrapperLifecycleReportText.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> browseStaleTypedWrapperLifecycleReport [
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
GbsMethodQueryResultsPresenter >> browsePromptedSessionStateKey [
	| rawKey key |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	rawKey := self requestInput: 'Session state key:' initialAnswer: '19'.
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
GbsMethodQueryResultsPresenter >> browsePromptedSessionStateKeysReport [
	| rawKeys keys |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	rawKeys := self requestInput: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ false ].
	self inform: (session objectSpaceDiagnostics reportTextForKeys: keys).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> browseObjectsInMemoryReport [
	| start limit |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ false ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ false ].
	self inform: (session objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> browseSessionStateAtKey: aKey [
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
	^ self openInspectorOnOop: oop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> browseTypedWrapperAutoloadReport [
	self inform: (GbsSessionManager typedWrapperAutoloadReportTextForSession: session).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> clearNamedObjectCache [
	session clearNamedObjectCache.
	self inform: 'Named object cache cleared.'.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> menuSession [
	| menu |
	menu := self newMenu
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Commit Transaction'; action: [ self commitSession ] ].
			group addItem: [ :item | item name: 'Abort Transaction'; action: [ self abortSession ] ].
			group addItem: [ :item | item name: 'Begin Transaction'; action: [ self beginSessionTransaction ] ] ];
		addGroup: [ :group |
			group addItem: [ :item | item name: 'Named Object Cache Report'; action: [ self browseNamedObjectCacheReport ] ].
			group addItem: [ :item | item name: 'Clear Named Object Cache'; action: [ self clearNamedObjectCache ] ].
			group addItem: [ :item | item name: 'Typed Wrapper Autoload Report'; action: [ self browseTypedWrapperAutoloadReport ] ].
			group addItem: [ :item | item name: 'Typed Wrapper Lifecycle Report'; action: [ self browseTypedWrapperLifecycleReport ] ].
			group addItem: [ :item | item name: 'Stale Typed Wrapper Report'; action: [ self browseStaleTypedWrapperLifecycleReport ] ].
			group addItem: [ :item | item name: 'Session State Keys Report...'; action: [ self browsePromptedSessionStateKeysReport ] ].
			group addItem: [ :item | item name: 'Objects In Memory Report...'; action: [ self browseObjectsInMemoryReport ] ].
			group addItem: [ :item | item name: 'Inspect Session State Key...'; action: [ self browsePromptedSessionStateKey ] ].
			self addExtensionSessionMenuItemsTo: group ];
		yourself.
	^ menu
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> parseSessionStateKeysFrom: aStringOrNil [
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
GbsMethodQueryResultsPresenter >> requestExportPath: defaultPath [
	| answer |
	answer := self requestInput: 'Export file path:' initialAnswer: defaultPath.
	(answer isNil or: [ answer isEmpty ]) ifTrue: [ ^ nil ].
	^ answer
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> requestInput: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> requestPositiveInteger: promptString initialAnswer: defaultString [
	| rawValue |
	rawValue := self requestInput: promptString initialAnswer: defaultString.
	(rawValue isNil or: [ rawValue trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ [ | value |
		value := rawValue trimBoth asInteger.
		value > 0 ifTrue: [ value ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> uiChooseFrom: choices title: titleString [
	^ UIManager default chooseFrom: choices title: titleString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> invocationArgumentsForMethodObject: aMethodObject [
	| argumentCount input |
	aMethodObject ifNil: [ ^ nil ].
	argumentCount := aMethodObject selector numArgs.
	argumentCount = 0 ifTrue: [ ^ #() ].
	input := self
		requestInput: (GbsRemoteMethodObject
			invocationPromptForSelector: aMethodObject selector
			argumentCount: argumentCount)
		initialAnswer: (GbsRemoteMethodObject defaultArgumentInputForCount: argumentCount).
	input ifNil: [ ^ nil ].
	^ GbsRemoteMethodObject
		argumentsFromInput: input
		expectedCount: argumentCount
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> selectedReferenceClassName [
	| methodObject ref parsed |
	methodObject := self selectedMethodObject.
	methodObject ifNotNil: [ ^ methodObject ownerName ].
	ref := self selectedReference.
	ref ifNil: [ ^ nil ].
	parsed := self parseReference: ref asString.
	parsed ifNil: [ ^ nil ].
	^ parsed first
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> selectedMethodObject [
	^ self methodObjectForReference: self selectedReference
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> selectedUnboundMethodObject [
	^ self unboundMethodObjectForReference: self selectedReference
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> showSourceForReference: referenceString [
	| parsed methodObject source |
	referenceString ifNil: [
		sourceText text: ''.
		self updateStatusForReference: nil.
		^ self ].
	parsed := self parseReference: referenceString asString.
	parsed ifNil: [
		sourceText text: ''.
		self updateStatusForReference: referenceString.
		^ self ].
	methodObject := [ self unboundMethodObjectForReference: referenceString ] on: Error do: [ nil ].
	source := methodObject
		ifNil: [ '' ]
		ifNotNil: [ [ methodObject sourceCode ] on: Error do: [ '' ] ].
	sourceText text: (source ifNil: [ '' ] ifNotNil: [ source asString ]).
	self updateStatusForReference: referenceString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> unboundMethodObjectForReference: referenceString [
	| parsed className selector |
	self methodQuery ifNotNil: [
		^ [ (self methodQuery methodObjectForReference: referenceString) unbind ]
			on: Error
			do: [ :ex | nil ] ].
	referenceString ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	parsed := self parseReference: referenceString asString.
	parsed ifNil: [ ^ nil ].
	className := parsed first.
	selector := parsed second asSymbol.
	^ parsed third
		ifTrue: [ session classUnboundMethodObjectForClassNamed: className selector: selector ]
		ifFalse: [ session unboundMethodObjectForClassNamed: className selector: selector ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsMethodQueryResultsPresenter >> openInspectorOnOop: anOop [
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ false ].
	GbsInspector inspect: anOop session: session.
	^ true
]
