Extension { #name : 'GbsPlaygroundActions' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbsPlaygroundActions class >> gsInspectItIn: aPlaygroundPresenter [
	| code activeSession oop |
	code := self selectedCodeFrom: aPlaygroundPresenter.
	code ifEmpty: [ ^ self ].
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ self ].

	oop := activeSession executeScriptAndReturnOop: code.
	((oop isNumber) and: [ oop > 20 ])
		ifTrue: [ self inspectOop: oop session: activeSession ]
		ifFalse: [ UIManager default inform: 'Result is nil or execution failed.' ].
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsPlaygroundActions class >> gsBrowseTypedWrapperLifecycleReportIn: aPlaygroundPresenter [
	| activeSession |
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ false ].
	self inform: activeSession typedWrapperLifecycleReportText.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsPlaygroundActions class >> gsBrowseStaleTypedWrapperLifecycleReportIn: aPlaygroundPresenter [
	| activeSession report staleEntries |
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ false ].
	report := activeSession typedWrapperLifecycleReport.
	staleEntries := report staleEntries.
	staleEntries isEmpty ifTrue: [
		self inform: 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.'.
		^ true ].
	self inform: (GbsTypedWrapperLifecycleReport entries: staleEntries) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsPlaygroundActions class >> inspectOop: anOop session: aSession [
	GbsInspector inspect: anOop session: aSession
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsPlaygroundActions class >> inform: aString [
	^ UIManager default inform: aString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsPlaygroundActions class >> gsInspectSessionStateKeyIn: aPlaygroundPresenter [
	| activeSession rawKey key sessionStateValue oop |
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ self ].

	rawKey := self requestInput: 'Session state key:' initialAnswer: '19'.
	(rawKey isNil or: [ rawKey trimBoth isEmpty ]) ifTrue: [ ^ false ].
	key := [ rawKey trimBoth asInteger ]
		on: Error
		do: [ nil ].
	key ifNil: [
		self inform: 'Enter a numeric session state key.'.
		^ false ].

	sessionStateValue := [ activeSession sessionStateAt: key ]
		on: Error
		do: [ :ex |
			self inform: 'Session state lookup failed: ', ex messageText.
			^ false ].
	sessionStateValue ifNil: [
		self inform: 'Session state key ', key printString, ' is not set.'.
		^ false ].

	oop := [ sessionStateValue oop ]
		on: Error
		do: [ nil ].
	oop ifNil: [
		((sessionStateValue isInteger) and: [ sessionStateValue > 20 ])
			ifTrue: [ oop := sessionStateValue ] ].
	oop ifNil: [
		self inform: 'Session state key ', key printString, ' does not currently have an inspectable remote oop.'.
		^ false ].

	self inspectOop: oop session: activeSession.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsPlaygroundActions class >> gsBrowseSessionStateKeysReportIn: aPlaygroundPresenter [
	| activeSession rawKeys keys |
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ false ].
	rawKeys := self requestInput: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ false ].
	self inform: (activeSession objectSpaceDiagnostics reportTextForKeys: keys).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsPlaygroundActions class >> gsBrowseObjectsInMemoryReportIn: aPlaygroundPresenter [
	| activeSession start limit |
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ false ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ false ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ false ].
	self inform: (activeSession objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsPlaygroundActions class >> requestInput: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsPlaygroundActions class >> parseSessionStateKeysFrom: aStringOrNil [
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
GbsPlaygroundActions class >> requestPositiveInteger: promptString initialAnswer: defaultString [
	| rawValue |
	rawValue := self requestInput: promptString initialAnswer: defaultString.
	(rawValue isNil or: [ rawValue trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ [ | value |
		value := rawValue trimBoth asInteger.
		value > 0 ifTrue: [ value ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]
