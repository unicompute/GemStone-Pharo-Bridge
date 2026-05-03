Extension { #name : 'GbsInspector' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: classLabel height: 30;
		add: stateTable;
		add: (SpBoxLayout newHorizontal
			add: doItButton;
			add: printItButton;
			add: inspectItButton;
			add: self invokeButton;
			add: self referencersButton;
			add: self sessionStateButton;
			add: self reportButton;
			yourself) height: 30;
		add: codeEditor;
		yourself
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> initializePresenters [
	classLabel := self newLabel.
	stateTable := self newTable.
	codeEditor := self newCode.
	doItButton := self newButton
		label: 'GS-Do it';
		action: [ self gsDoIt ].
	printItButton := self newButton
		label: 'GS-Print it';
		action: [ self gsPrintIt ].
	inspectItButton := self newButton
		label: 'GS-Inspect it';
		action: [ self gsInspectIt ].
	self invokeButton: (self newButton
		label: 'GS-Invoke';
		action: [ self invokeSelectedObjectMethod ];
		yourself).
	self referencersButton: (self newButton
		label: 'GS-Referencers';
		action: [ self browseReferencersInMemory ];
		yourself).
	self sessionStateButton: (self newButton
		label: 'GS-State';
		action: [ self browsePromptedSessionStateKey ];
		yourself).
	self reportButton: (self newButton
		label: 'GS-Reports';
		action: [ self browseReportChooser ];
		yourself).
	stateTable
		addColumn: (SpStringTableColumn title: 'Variable' evaluated: [ :item | item first ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :item | item second ]).
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> inspectOop: anOop session: aSession context: aContextOop [
	| className printString rawData parsedItems items |
	oop := anOop.
	session := aSession.
	evaluationContextOop := aContextOop.

	className := session executeAndFetch: '(Object _objectForOop: ', anOop asString, ') class name asString'.
	classLabel label: 'Remote Class: ', className.
	printString := session executeAndFetch: '(Object _objectForOop: ', anOop asString, ') printString'.

	items := OrderedCollection new.
	items add: { 'self' . printString . anOop }.

	rawData := self class fetchReflectionStringFor: anOop session: session.
	parsedItems := self class parseReflectionString: rawData.
	items addAll: parsedItems.

	stateTable items: items.
	stateTable whenActivatedDo: [ :selection |
		| selectedItem childOop |
		selectedItem := selection selectedItem.
		childOop := selectedItem third.
		childOop > 20 ifTrue: [ self openInspectorOnOop: childOop ] ].
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> browseReferencersInMemory [
	| targetOop referencers inspectable selection |
	targetOop := self selectedInspectableOop.
	targetOop ifNil: [ ^ false ].
	referencers := self referencersInMemoryForOop: targetOop.
	inspectable := referencers select: [ :each | (self oopForInspectableObject: each) notNil ].
	inspectable isEmpty ifTrue: [
		self inform: 'No in-memory referencers found.'.
		^ false ].
	inspectable size = 1 ifTrue: [
		^ self openInspectorOnOop: (self oopForInspectableObject: inspectable first) ].
	selection := self
		chooseReferencerFrom: inspectable
		title: 'In-memory referencers'.
	selection ifNil: [ ^ false ].
	^ self openInspectorOnOop: (self oopForInspectableObject: selection)
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> browsePromptedSessionStateKey [
	| rawKey key |
	session ifNil: [ ^ false ].
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
GbsInspector >> browsePromptedSessionStateKeysReport [
	| rawKeys keys |
	session ifNil: [ ^ false ].
	rawKeys := self requestInput: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [
		session objectSpaceDiagnostics reportTextForKeys: keys ]).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> browseSessionStateAtKey: aKey [
	| sessionStateValue oopToInspect |
	session ifNil: [ ^ false ].
	sessionStateValue := [ session sessionStateAt: aKey ]
		on: Error
		do: [ :ex |
			self inform: 'Session state lookup failed: ', ex messageText.
			^ false ].
	sessionStateValue ifNil: [
		self inform: 'Session state key ', aKey printString, ' is not set.'.
		^ false ].
	oopToInspect := self oopForInspectableObject: sessionStateValue.
	oopToInspect ifNil: [
		self inform: 'Session state key ', aKey printString, ' does not currently have an inspectable remote oop.'.
		^ false ].
	^ self openInspectorOnOop: oopToInspect
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> browseStaleTypedWrapperLifecycleReport [
	| report staleEntries |
	session ifNil: [ ^ false ].
	report := self withShallowMaterializationDo: [ session typedWrapperLifecycleReport ].
	staleEntries := report staleEntries.
	staleEntries isEmpty ifTrue: [
		self inform: 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.'.
		^ true ].
	self inform: (GbsTypedWrapperLifecycleReport entries: staleEntries) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> browseObjectsInMemoryReport [
	| start limit |
	session ifNil: [ ^ false ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ false ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ false ].
	self inform: (self withShallowMaterializationDo: [
		(session objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text ]).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> browseTypedWrapperLifecycleReport [
	session ifNil: [ ^ false ].
	self inform: (self withShallowMaterializationDo: [ session typedWrapperLifecycleReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> browseReportChooser [
	| labels actions index |
	labels := OrderedCollection withAll: #(
		'Typed Wrapper Lifecycle Report'
		'Stale Typed Wrapper Report'
		'Session State Keys Report...'
		'Objects In Memory Report...').
	actions := OrderedCollection withAll: {
		[ self browseTypedWrapperLifecycleReport ].
		[ self browseStaleTypedWrapperLifecycleReport ].
		[ self browsePromptedSessionStateKeysReport ].
		[ self browseObjectsInMemoryReport ] }.
	self addExtensionReportOptionsToLabels: labels actions: actions.
	index := UIManager default chooseFrom: labels title: 'GemStone Reports'.
	index = 0 ifTrue: [ ^ false ].
	^ (actions at: index) value
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> chooseReferencerFrom: referencers title: aTitle [
	| labels index |
	labels := referencers collect: [ :each | self displayStringForReferencer: each ].
	index := UIManager default chooseFrom: labels title: aTitle.
	index = 0 ifTrue: [ ^ nil ].
	^ referencers at: index ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> displayStringForReferencer: anObject [
	(anObject isKindOf: GbsProxy) ifTrue: [
		^ [ anObject asLocalString ]
			on: Error
			do: [ 'aGbsProxy(oop: ', anObject oop asString, ')' ] ].
	^ anObject printString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> inform: aString [
	UIManager default inform: aString.
	^ aString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> invokeButton [
	^ self propertyAt: #invokeButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> invokeButton: aButton [
	self propertyAt: #invokeButton put: aButton.
	^ aButton
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> referencersButton [
	^ self propertyAt: #referencersButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> referencersButton: aButton [
	self propertyAt: #referencersButton put: aButton.
	^ aButton
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> sessionStateButton [
	^ self propertyAt: #sessionStateButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> sessionStateButton: aButton [
	self propertyAt: #sessionStateButton put: aButton.
	^ aButton
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> reportButton [
	^ self propertyAt: #reportButton ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> reportButton: aButton [
	self propertyAt: #reportButton put: aButton.
	^ aButton
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> oopForInspectableObject: anObject [
	(anObject isKindOf: GbsProxy) ifTrue: [ ^ anObject oop ].
	(anObject isInteger and: [ anObject > 20 ]) ifTrue: [ ^ anObject ].
	^ nil
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> openInspectorOnOop: anOop [
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ false ].
	GbsInspector inspect: anOop session: session context: self evaluationContextOop.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> invokeSelectedObjectMethod [
	| targetOop className selectorInput selector methodObject invocationArguments result |
	session ifNil: [ ^ false ].
	targetOop := self selectedInspectableOop.
	targetOop ifNil: [ ^ false ].
	className := self remoteClassNameForOop: targetOop.
	className ifNil: [
		self inform: 'Could not determine remote class for invocation.'.
		^ false ].
	selectorInput := self requestInput: 'Selector to invoke in GemStone:' initialAnswer: ''.
	(selectorInput isNil or: [ selectorInput trimBoth isEmpty ]) ifTrue: [ ^ false ].
	selector := selectorInput trimBoth asSymbol.
	methodObject := self
		remoteMethodObjectForClassName: className
		selector: selector
		targetOop: targetOop.
	methodObject exists ifFalse: [
		self inform: 'Remote method ', selector asString, ' was not found on ', className, '.'.
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
GbsInspector >> parseSessionStateKeysFrom: aStringOrNil [
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
GbsInspector >> referencersInMemoryForOop: anOop [
	session ifNil: [ ^ #() ].
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ #() ].
	^ self withShallowMaterializationDo: [
		[ session referencesToOop: anOop ]
			on: Error
			do: [ #() ] ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> requestPositiveInteger: promptString initialAnswer: defaultString [
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
GbsInspector >> remoteClassNameForOop: anOop [
	session ifNil: [ ^ nil ].
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ nil ].
	^ [ session executeAndFetch: '(Object _objectForOop: ', anOop asString, ') class name asString' ]
		on: Error
		do: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> remoteMethodObjectForClassName: className selector: aSelector targetOop: targetOop [
	| trimmed baseName methodObject |
	trimmed := className asString trimBoth.
	(trimmed endsWith: ' class') ifTrue: [
		baseName := trimmed copyFrom: 1 to: trimmed size - 6.
		^ session classMethodObjectForClassNamed: baseName selector: aSelector ].
	methodObject := session methodObjectForClassNamed: trimmed selector: aSelector.
	^ methodObject bindTo: (session objectForOop: targetOop)
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> requestInput: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> selectedInspectableOop [
	| selected |
	stateTable ifNil: [ ^ oop ].
	selected := [ stateTable selection selectedItem ] on: Error do: [ nil ].
	selected ifNil: [
		selected := [ stateTable selectedItem ] on: Error do: [ nil ] ].
	(selected isCollection and: [ selected size >= 3 ]) ifTrue: [
		((selected third isInteger) and: [ selected third > 20 ]) ifTrue: [
			^ selected third ] ].
	^ oop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsInspector >> withShallowMaterializationDo: aBlock [
	session ifNil: [ ^ aBlock value ].
	^ session
		withMaterializationProfile: GbsShallowMaterializationProfile new
		do: aBlock
]
