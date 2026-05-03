Extension { #name : 'GbxTrippy' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> buildToolbar [
	^ SpBoxLayout newHorizontal
		spacing: 3;
		add: backButton width: 80;
		add: forwardButton width: 80;
		add: upButton width: 60;
		add: refreshButton width: 80;
		add: inspectButton width: 80;
		add: (self newButton
			label: '↩ Referencers';
			action: [ self browseReferencersInMemory ];
			yourself)
			width: 110;
		add: (self newButton
			label: '🗃 State';
			action: [ self browsePromptedSessionStateKey ];
			yourself)
			width: 90;
		add: (self newButton
			label: '📊 Reports';
			action: [ self browseReportChooser ];
			yourself)
			width: 95;
		add: doItButton width: 80;
		yourself
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> browseObjectsInMemoryReport [
	| start limit |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ false ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ false ].
	self inform: (self withShallowMaterializationDo: [
		(session objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text ]).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> browsePromptedSessionStateKey [
	| rawKey key |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	rawKey := self requestString: 'Session state key:' initialAnswer: '19'.
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
GbxTrippy >> browsePromptedSessionStateKeysReport [
	| rawKeys keys |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	rawKeys := self requestString: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [
		session objectSpaceDiagnostics reportTextForKeys: keys ]).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> browseReferencersInMemory [
	| targetOop referencers inspectable selection |
	targetOop := self selectedInspectableOop.
	targetOop ifNil: [ ^ false ].
	referencers := self referencersInMemoryForOop: targetOop.
	inspectable := referencers select: [ :each | (self oopForInspectableObject: each) notNil ].
	inspectable isEmpty ifTrue: [
		self inform: 'No in-memory referencers found.'.
		^ false ].
	inspectable size = 1 ifTrue: [
		^ self openTrippyOnOop: (self oopForInspectableObject: inspectable first) ].
	selection := self
		chooseReferencerFrom: inspectable
		title: 'In-memory referencers'.
	selection ifNil: [ ^ false ].
	^ self openTrippyOnOop: (self oopForInspectableObject: selection)
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> browseReportChooser [
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
GbxTrippy >> browseSessionStateAtKey: aKey [
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
	oop := self oopForInspectableObject: sessionStateValue.
	oop ifNil: [
		self inform: 'Session state key ', aKey printString, ' does not currently have an inspectable remote oop.'.
		^ false ].
	^ self openTrippyOnOop: oop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> browseStaleTypedWrapperLifecycleReport [
	| report staleEntries |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	report := self withShallowMaterializationDo: [ session typedWrapperLifecycleReport ].
	staleEntries := report staleEntries.
	staleEntries isEmpty ifTrue: [
		self inform: 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.'.
		^ true ].
	self inform: (GbsTypedWrapperLifecycleReport entries: staleEntries) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> browseTypedWrapperLifecycleReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (self withShallowMaterializationDo: [ session typedWrapperLifecycleReportText ]).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> chooseReferencerFrom: referencers title: aTitle [
	| labels index |
	labels := referencers collect: [ :each | self displayStringForReferencer: each ].
	index := UIManager default chooseFrom: labels title: aTitle.
	index = 0 ifTrue: [ ^ nil ].
	^ referencers at: index ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> displayStringForReferencer: anObject [
	(anObject isKindOf: GbsProxy) ifTrue: [
		^ [ anObject asLocalString ]
			on: Error
			do: [ 'aGbsProxy(oop: ', anObject oop asString, ')' ] ].
	^ anObject printString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> inform: aString [
	InformDialog inform: aString.
	^ aString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> inspectSelected [
	| oop |
	oop := self selectedInspectableOop.
	oop ifNil: [ ^ false ].
	^ self openTrippyOnOop: oop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> oopForInspectableObject: anObject [
	(anObject isKindOf: GbsProxy) ifTrue: [ ^ anObject oop ].
	(anObject isInteger and: [ anObject > 20 ]) ifTrue: [ ^ anObject ].
	^ nil
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> openTrippyOnOop: anOop [
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ false ].
	self class inspectOop: anOop session: session.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> parseSessionStateKeysFrom: aStringOrNil [
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
GbxTrippy >> referencersInMemoryForOop: anOop [
	session ifNil: [ ^ #() ].
	(anOop isInteger and: [ anOop > 20 ]) ifFalse: [ ^ #() ].
	^ self withShallowMaterializationDo: [
		[ session referencesToOop: anOop ]
			on: Error
			do: [ #() ] ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> requestPositiveInteger: promptString initialAnswer: defaultString [
	| rawValue |
	rawValue := self requestString: promptString initialAnswer: defaultString.
	(rawValue isNil or: [ rawValue trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ [ | value |
		value := rawValue trimBoth asInteger.
		value > 0 ifTrue: [ value ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> requestString: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> selectedInspectableOop [
	| item oop |
	objectTable ifNotNil: [
		item := [ objectTable selectedItem ] on: Error do: [ nil ].
		item ifNotNil: [
			oop := item at: 4 ifAbsent: [ nil ].
			(oop isInteger and: [ oop > 20 ]) ifTrue: [ ^ oop ] ] ].
	^ (currentOop isInteger and: [ currentOop > 20 ])
		ifTrue: [ currentOop ]
		ifFalse: [ nil ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxTrippy >> withShallowMaterializationDo: aBlock [
	session ifNil: [ ^ aBlock value ].
	^ session
		withMaterializationProfile: GbsShallowMaterializationProfile new
		do: aBlock
]
