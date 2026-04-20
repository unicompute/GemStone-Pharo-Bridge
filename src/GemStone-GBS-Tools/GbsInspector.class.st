Class {
	#name : 'GbsInspector',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'oop',
		'classLabel',
		'stateTable',
		'codeEditor',
		'doItButton',
		'printItButton',
		'inspectItButton',
		'invokeButton',
		'referencersButton',
		'sessionStateButton',
		'reportButton',
		'evaluationContextOop'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'reflection' }
GbsInspector class >> fetchReflectionStringFor: anOop session: aSession [
	"Sends the reflection script to GemStone and returns the raw formatted string"
	| script |
	script := '[
		| obj stream names childVal childOop |
		obj := Object _objectForOop: ', anOop asString, '.
		stream := WriteStream on: String new.
		names := obj class allInstVarNames.
		1 to: names size do: [ :i |
			childVal := obj instVarAt: i.
			childOop := Reflection oopOf: childVal.
			stream 
				nextPutAll: (names at: i) asString; nextPutAll: ''::::''; 
				nextPutAll: childVal printString; nextPutAll: ''::::'';
				nextPutAll: childOop asString; lf.
		].
		stream contents
	] value'.
	
	^ aSession executeAndFetch: script.
]

{ #category : 'instance creation' }
GbsInspector class >> inspect: anOop session: aSession [
	| inspector |
	inspector := self new.
	inspector inspectOop: anOop session: aSession.
	inspector open.
	^ inspector
]

{ #category : 'instance creation' }
GbsInspector class >> inspect: anOop session: aSession context: aContextOop [
	| inspector |
	inspector := self new.
	inspector inspectOop: anOop session: aSession context: aContextOop.
	inspector open.
	^ inspector
]

{ #category : 'reflection' }
GbsInspector class >> parseReflectionString: aString [
	"Converts the GemStone string into an Array of { Name . Value . OOP }"
	| items lines parts |
	items := OrderedCollection new.
	
	(aString isNil or: [ aString beginsWith: 'Error:' ]) ifTrue: [ ^ items ].
	
	lines := aString splitOn: Character lf.
	lines do: [ :line |
		line isNotEmpty ifTrue: [ 
			parts := line splitOn: '::::'.
			parts size = 3 ifTrue: [ 
				items add: { parts first . parts second . parts third asInteger } 
			]
		]
	].
	^ items asArray
]

{ #category : 'layout' }
GbsInspector >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: classLabel height: 30;
		add: stateTable;
		add: (SpBoxLayout newHorizontal
			add: doItButton;
			add: printItButton;
			add: inspectItButton;
			add: invokeButton;
			add: referencersButton;
			add: sessionStateButton;
			add: reportButton;
			yourself) height: 30;
		add: codeEditor;
		yourself
]

{ #category : 'evaluation' }
GbsInspector >> evaluateCodeInContext: codeString [
	| contextOop raw |
	(codeString isString and: [ codeString isEmpty not ]) ifFalse: [ ^ nil ].
	session ifNil: [ ^ nil ].
	contextOop := self evaluationContextOop.
	raw := [ session executeAndFetch: codeString context: contextOop ] on: Error do: [ nil ].
	raw ifNil: [ ^ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	^ raw
]

{ #category : 'evaluation' }
GbsInspector >> evaluationContextOop [
	((evaluationContextOop isNumber) and: [ evaluationContextOop > 20 ])
		ifTrue: [ ^ evaluationContextOop ].
	^ (session respondsTo: #sessionOop)
		ifTrue: [ session sessionOop ]
		ifFalse: [ 20 ]
]

{ #category : 'evaluation' }
GbsInspector >> gsDoIt [
	| code |
	code := self selectedCodeOrAll.
	code isEmpty ifTrue: [ ^ false ].
	^ self gsDoIt: code
]

{ #category : 'evaluation' }
GbsInspector >> gsDoIt: codeString [
	| raw |
	raw := self evaluateCodeInContext: codeString.
	^ raw notNil and: [ (raw asString beginsWith: 'Error:') not ]
]

{ #category : 'evaluation' }
GbsInspector >> gsInspectIt [
	| code |
	code := self selectedCodeOrAll.
	code isEmpty ifTrue: [ ^ false ].
	^ self gsInspectIt: code
]

{ #category : 'evaluation' }
GbsInspector >> gsInspectIt: codeString [
	| contextOop resultOop |
	session ifNil: [ ^ false ].
	contextOop := self evaluationContextOop.
	resultOop := [
		session serverInterface
			apiGciExecuteStr: codeString
			context: contextOop
			env: 0
	] on: Error do: [ nil ].
	((resultOop isNumber and: [ resultOop > 20 ]) not) ifTrue: [ ^ false ].
	GbsInspector inspect: resultOop session: session context: contextOop.
	^ true
]

{ #category : 'evaluation' }
GbsInspector >> gsPrintIt [
	| code value currentText |
	code := self selectedCodeOrAll.
	code isEmpty ifTrue: [ ^ false ].
	value := self gsPrintIt: code.
	value ifNil: [ ^ false ].
	currentText := (codeEditor respondsTo: #text)
		ifTrue: [ codeEditor text asString ]
		ifFalse: [ '' ].
	(codeEditor respondsTo: #text:)
		ifTrue: [ codeEditor text: currentText, ' "', value asString, '"' ].
	^ true
]

{ #category : 'evaluation' }
GbsInspector >> gsPrintIt: codeString [
	| script |
	codeString ifNil: [ ^ nil ].
	script := '[ ', codeString, ' ] value printString'.
	^ self evaluateCodeInContext: script
]

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
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

{ #category : 'actions' }
GbsInspector >> browseTypedWrapperLifecycleReport [
	session ifNil: [ ^ false ].
	self inform: (self withShallowMaterializationDo: [ session typedWrapperLifecycleReportText ]).
	^ true
]

{ #category : 'actions' }
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

{ #category : 'initialization' }
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
	invokeButton := self newButton
		label: 'GS-Invoke';
		action: [ self invokeSelectedObjectMethod ].
	referencersButton := self newButton
		label: 'GS-Referencers';
		action: [ self browseReferencersInMemory ].
	sessionStateButton := self newButton
		label: 'GS-State';
		action: [ self browsePromptedSessionStateKey ].
	reportButton := self newButton
		label: 'GS-Reports';
		action: [ self browseReportChooser ].
	
	stateTable 
		addColumn: (SpStringTableColumn title: 'Variable' evaluated: [ :item | item first ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :item | item second ]).
]

{ #category : 'initialization' }
GbsInspector >> initializeWindow: aWindowPresenter [
	aWindowPresenter 
		title: 'GemStone Live Inspector';
		initialExtent: 450 @ 500.
]

{ #category : 'accessing' }
GbsInspector >> inspectOop: anOop session: aSession [
	self inspectOop: anOop session: aSession context: nil
]

{ #category : 'accessing' }
GbsInspector >> inspectOop: anOop session: aSession context: aContextOop [
	| className printString rawData parsedItems items |
	oop := anOop.
	session := aSession.
	evaluationContextOop := aContextOop.
	
	"1. Get Basic Info"
	className := session executeAndFetch: '(Object _objectForOop: ', anOop asString, ') class name asString'.
	classLabel label: 'Remote Class: ', className.
	printString := session executeAndFetch: '(Object _objectForOop: ', anOop asString, ') printString'.
	
	"2. Initialize table with 'self'"
	items := OrderedCollection new.
	items add: { 'self' . printString . anOop }.
	
	"3. Fetch and Parse using our GREEN TDD methods!"
	rawData := self class fetchReflectionStringFor: anOop session: session.
	parsedItems := self class parseReflectionString: rawData.
	items addAll: parsedItems.
	
	stateTable items: items.
	
	"4. DOUBLE-CLICK TO DIVE DEEPER!"
	stateTable whenActivatedDo: [ :selection |
		| selectedItem childOop |
		selectedItem := selection selectedItem.
		childOop := selectedItem third. 
		"Only inspect real objects, ignore nil (20)"
		childOop > 20 ifTrue: [ 
			self openInspectorOnOop: childOop
		].
	].
]

{ #category : 'ui' }
GbsInspector >> chooseReferencerFrom: referencers title: aTitle [
	| labels index |
	labels := referencers collect: [ :each | self displayStringForReferencer: each ].
	index := UIManager default chooseFrom: labels title: aTitle.
	index = 0 ifTrue: [ ^ nil ].
	^ referencers at: index ifAbsent: [ nil ]
]

{ #category : 'ui' }
GbsInspector >> displayStringForReferencer: anObject [
	(anObject isKindOf: GbsProxy) ifTrue: [
		^ [ anObject asLocalString ]
			on: Error
			do: [ 'aGbsProxy(oop: ', anObject oop asString, ')' ] ].
	^ anObject printString
]

{ #category : 'ui' }
GbsInspector >> inform: aString [
	UIManager default inform: aString.
	^ aString
]

{ #category : 'private' }
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

{ #category : 'ui' }
GbsInspector >> oopForInspectableObject: anObject [
	(anObject isKindOf: GbsProxy) ifTrue: [ ^ anObject oop ].
	(anObject isInteger and: [ anObject > 20 ]) ifTrue: [ ^ anObject ].
	^ nil
]

{ #category : 'ui' }
GbsInspector >> openInspectorOnOop: anOop [
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ false ].
	GbsInspector inspect: anOop session: session context: self evaluationContextOop.
	^ true
]

{ #category : 'actions' }
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

{ #category : 'querying' }
GbsInspector >> referencersInMemoryForOop: anOop [
	session ifNil: [ ^ #() ].
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ #() ].
	^ self withShallowMaterializationDo: [
		[ session referencesToOop: anOop ]
			on: Error
			do: [ #() ] ]
]

{ #category : 'private' }
GbsInspector >> remoteClassNameForOop: anOop [
	session ifNil: [ ^ nil ].
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ nil ].
	^ [ session executeAndFetch: '(Object _objectForOop: ', anOop asString, ') class name asString' ]
		on: Error
		do: [ nil ]
]

{ #category : 'private' }
GbsInspector >> remoteMethodObjectForClassName: className selector: aSelector targetOop: targetOop [
	| trimmed baseName methodObject |
	trimmed := className asString trimBoth.
	(trimmed endsWith: ' class') ifTrue: [
		baseName := trimmed copyFrom: 1 to: trimmed size - 6.
		^ session classMethodObjectForClassNamed: baseName selector: aSelector ].
	methodObject := session methodObjectForClassNamed: trimmed selector: aSelector.
	^ methodObject bindTo: (session objectForOop: targetOop)
]

{ #category : 'private' }
GbsInspector >> requestInput: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : 'private' }
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

{ #category : 'private' }
GbsInspector >> withShallowMaterializationDo: aBlock [
	session ifNil: [ ^ aBlock value ].
	^ session
		withMaterializationProfile: GbsShallowMaterializationProfile new
		do: aBlock
]

{ #category : 'evaluation' }
GbsInspector >> selectedCodeOrAll [
	| fullText |
	codeEditor ifNil: [ ^ '' ].
	fullText := (codeEditor respondsTo: #text)
		ifTrue: [ codeEditor text asString ]
		ifFalse: [ '' ].
	^ fullText
]

{ #category : 'accessing' }
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
