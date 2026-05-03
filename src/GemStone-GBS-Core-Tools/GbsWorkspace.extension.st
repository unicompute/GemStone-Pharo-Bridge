Extension { #name : 'GbsWorkspace' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbsWorkspace >> browseObjectsInMemoryReport [
	| activeSession start limit |
	activeSession := self activeSessionForRemoteExecution.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	start := self requestPositiveInteger: 'Object scan start index:' initialAnswer: '1'.
	start ifNil: [ ^ false ].
	limit := self requestPositiveInteger: 'Object scan limit:' initialAnswer: '25'.
	limit ifNil: [ ^ false ].
	self inform: (activeSession objectSpaceDiagnostics objectsInMemoryReportFrom: start limit: limit) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsWorkspace >> browsePromptedSessionStateKey [
	| activeSession rawKey key |
	activeSession := self activeSessionForRemoteExecution.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	rawKey := self requestInput: 'Session state key:' initialAnswer: '19'.
	(rawKey isNil or: [ rawKey trimBoth isEmpty ]) ifTrue: [ ^ false ].
	key := [ rawKey trimBoth asInteger ]
		on: Error
		do: [ nil ].
	key ifNil: [
		self inform: 'Enter a numeric session state key.'.
		^ false ].
	^ self browseSessionStateAtKey: key session: activeSession
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsWorkspace >> browsePromptedSessionStateKeysReport [
	| activeSession rawKeys keys |
	activeSession := self activeSessionForRemoteExecution.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	rawKeys := self requestInput: 'Session state keys (comma-separated):' initialAnswer: '19'.
	keys := self parseSessionStateKeysFrom: rawKeys.
	keys ifNil: [
		self inform: 'Enter one or more numeric session state keys.'.
		^ false ].
	self inform: (activeSession objectSpaceDiagnostics reportTextForKeys: keys).
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsWorkspace >> browseSessionStateAtKey: aKey session: aSession [
	| sessionStateValue oop |
	aSession ifNil: [ ^ self inform: 'No Session' ].
	sessionStateValue := [ aSession sessionStateAt: aKey ]
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
	self inspectOop: oop session: aSession.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsWorkspace >> browseStaleTypedWrapperLifecycleReport [
	| activeSession report staleEntries |
	activeSession := self activeSessionForRemoteExecution.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	report := activeSession typedWrapperLifecycleReport.
	staleEntries := report staleEntries.
	staleEntries isEmpty ifTrue: [
		self inform: 'Typed Wrapper Lifecycle', String cr, String cr, 'No stale typed wrappers.'.
		^ true ].
	self inform: (GbsTypedWrapperLifecycleReport entries: staleEntries) text.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsWorkspace >> browseTypedWrapperLifecycleReport [
	| activeSession |
	activeSession := self activeSessionForRemoteExecution.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	self inform: activeSession typedWrapperLifecycleReportText.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsWorkspace >> inspectIt [
	| code activeSession script rawOop |
	
	code := self textEditor text asString copyReplaceAll: String cr with: String lf.
	script := '[ ', code, ' ] value'.
	
	activeSession := GbsSessionParameters currentSession.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	
	rawOop := activeSession executeScriptAndReturnOop: script.
	
	(rawOop = 1 or: [ rawOop = 20 ]) 
		ifTrue: [ self inform: 'Result is nil or execution failed.' ]
		ifFalse: [ self inspectOop: rawOop session: activeSession ].
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsWorkspace >> inspectOop: anOop session: aSession [
	GbsInspector inspect: anOop session: aSession
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsWorkspace >> parseSessionStateKeysFrom: aStringOrNil [
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
GbsWorkspace >> requestInput: prompt initialAnswer: defaultString [
	^ UIManager default request: prompt initialAnswer: defaultString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsWorkspace >> requestPositiveInteger: promptString initialAnswer: defaultString [
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
GbsWorkspace >> workspaceMenu [
	| menu |
	menu := self newMenu.

	menu addGroup: [ :group | 
		group addItem: [ :item | item name: 'Local Do it'; icon: (self iconNamed: #smallDoIt); action: [ self localDoIt ] ].
		group addItem: [ :item | item name: 'Local Inspect it'; icon: (self iconNamed: #smallInspectIt); action: [ self localInspectIt ] ].
		group addItem: [ :item | item name: 'Local Print it'; icon: (self iconNamed: #smallPrintIt); action: [ self localPrintIt ] ].
	].

	menu addGroup: [ :group |
		group addItem: [ :item |
			item name: 'GS-Do it'; shortcut: $d command; icon: (self iconNamed: #smallDoIt);
			action: [ UIManager default defer: [ self doIt ] ] ].
		group addItem: [ :item |
			item name: 'GS-Print it'; shortcut: $p command; icon: (self iconNamed: #smallPrintIt);
			action: [ UIManager default defer: [ self gemStonePrintIt ] ] ].
		group addItem: [ :item |
			item name: 'GS-Inspect it'; shortcut: $i command; icon: (self iconNamed: #smallInspectIt);
			action: [ UIManager default defer: [ self inspectIt ] ] ].
		group addItem: [ :item |
			item name: 'GS-Debug it'; icon: (self iconNamed: #smallDebug);
			action: [ UIManager default defer: [ self gemStoneDebugIt ] ] ].
		group addItem: [ :item |
			item name: 'GS-Typed Wrapper Lifecycle Report'; icon: (self iconNamed: #smallInspectIt);
			action: [ UIManager default defer: [ self browseTypedWrapperLifecycleReport ] ] ].
		group addItem: [ :item |
			item name: 'GS-Stale Typed Wrapper Report'; icon: (self iconNamed: #smallInspectIt);
			action: [ UIManager default defer: [ self browseStaleTypedWrapperLifecycleReport ] ] ].
		group addItem: [ :item |
			item name: 'GS-Session State Keys Report...'; icon: (self iconNamed: #smallInspectIt);
			action: [ UIManager default defer: [ self browsePromptedSessionStateKeysReport ] ] ].
		group addItem: [ :item |
			item name: 'GS-Objects In Memory Report...'; icon: (self iconNamed: #smallInspectIt);
			action: [ UIManager default defer: [ self browseObjectsInMemoryReport ] ] ].
		self addExtensionWorkspaceMenuItemsTo: group.
		group addItem: [ :item |
			item name: 'GS-Inspect Session State Key...'; icon: (self iconNamed: #smallInspectIt);
			action: [ UIManager default defer: [ self browsePromptedSessionStateKey ] ] ].
		group addItem: [ :item |
			item name: 'GS-File it in'; icon: (self iconNamed: #smallSave);
			action: [ UIManager default defer: [ self gsFileItIn ] ] ].
	].
	
	^ menu
]
