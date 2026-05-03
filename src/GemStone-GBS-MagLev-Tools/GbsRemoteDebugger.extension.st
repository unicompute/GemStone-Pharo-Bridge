Extension { #name : 'GbsRemoteDebugger' }

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> addExtensionMethodMenuItemsTo: aMenuGroup [
	aMenuGroup addItem: [ :item | item name: 'GS-Method Info'; action: [ self browseSelectedServerMethodInfo ] ].
	aMenuGroup addItem: [ :item | item name: 'GS-Inspect Unbound Method'; action: [ self inspectSelectedServerUnboundMethod ] ].
	aMenuGroup addItem: [ :item | item name: 'GS-Invoke'; action: [ self invokeSelectedServerMethod ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> addExtensionSessionMenuItemsTo: aMenu [
	aMenu addGroup: [ :group |
		group addItem: [ :item |
			item
				name: '$LOAD_PATH Report';
				action: [ self browseRubyLoadPathReport ] ].
		group addItem: [ :item |
			item
				name: 'Loaded Features Report';
				action: [ self browseRubyLoadedFeaturesReport ] ].
		group addItem: [ :item |
			item
				name: 'Persistent Features Report';
				action: [ self browseRubyPersistentLoadedFeaturesReport ] ].
		group addItem: [ :item |
			item
				name: 'Top-Level Autoload Report';
				action: [ self browseTopLevelAutoloadRegistrationsReport ] ].
		group addItem: [ :item |
			item
				name: 'Runtime Provenance Graph';
				action: [ self browseRubyRuntimeProvenanceGraph ] ].
		group addItem: [ :item |
			item
				name: 'Runtime Provenance Browser';
				action: [ self browseRubyRuntimeProvenanceBrowser ] ].
		group addItem: [ :item |
			item
				name: 'Runtime Provenance Actions...';
				action: [ self browseRubyRuntimeProvenanceActionChooser ] ].
		group addItem: [ :item |
			item
				name: 'MagLev Finalizer Registry Report';
				action: [ self browseMaglevFinalizerRegistryReport ] ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> browseRubyLoadPathReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: session rubyRuntime loadPathReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> browseRubyLoadedFeaturesReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: session rubyRuntime loadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> browseRubyPersistentLoadedFeaturesReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: session rubyRuntime persistentLoadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> browseTopLevelAutoloadRegistrationsReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: (session rubyRuntime
		autoloadRegistrationsReportTextForNamespace: session topLevelNamespaceMirror).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> browseRubyRuntimeProvenanceGraph [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: session rubyRuntime provenanceGraphText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> browseRubyRuntimeProvenanceBrowser [
	| graph |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	graph := session rubyRuntime provenanceGraph.
	graph isEmpty ifTrue: [
		self inform: graph text.
		^ true ].
	^ self
		openRubyRuntimeProvenanceBrowserFor: graph
		title: 'Ruby Runtime Provenance'
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> browseRubyRuntimeProvenanceActionChooser [
	| graph actions index action result |
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	graph := session rubyRuntime provenanceGraph.
	actions := graph actions.
	actions isEmpty ifTrue: [
		self inform: graph text.
		^ true ].
	index := self
		uiChooseFrom: (actions collect: [ :each | each displayString ])
		title: 'Ruby Runtime Provenance Actions'.
	index = 0 ifTrue: [ ^ false ].
	action := actions at: index.
	result := session rubyRuntime executeProvenanceAction: action.
	self inform: (String streamContents: [ :stream |
		stream nextPutAll: 'Executed '; nextPutAll: action displayString.
		result ifNotNil: [
			stream
				nextPutAll: ' => ';
				nextPutAll: result printString ].
		stream cr; cr; nextPutAll: session rubyRuntime provenanceGraphText ]).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> openRubyRuntimeProvenanceBrowserFor: aGraph title: aTitle [
	| presenterClass |
	presenterClass := Smalltalk at: #GbsStructuredValueInspectorPresenter ifAbsent: [ nil ].
	presenterClass ifNil: [
		self inform: aGraph text.
		^ true ].
	presenterClass
		openRows: aGraph browserRows
		kind: 'dictionary'
		title: aTitle
		inspectBlock: nil
		rawPrintString: aGraph text
		entryKey: nil
		path: nil
		previewKind: 'provenance'
		previewFetcherBlock: [ :row | aGraph previewForBrowserRow: row ].
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> browseMaglevFinalizerRegistryReport [
	session ifNil: [
		self inform: 'No GemStone session available.'.
		^ false ].
	self inform: session objectSpaceDiagnostics finalizerRegistryReport text.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> invokeSelectedServerMethodObject [
	| methodObject invocationArguments |
	methodObject := self selectedServerMethodObject.
	methodObject ifNil: [ ^ nil ].
	invocationArguments := self invocationArgumentsForMethodObject: methodObject.
	invocationArguments ifNil: [ ^ nil ].
	^ methodObject callWithArguments: invocationArguments
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> methodInfoTextFor: aMethodObject [
	aMethodObject ifNil: [ ^ 'No GemStone method selected.' ].
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Method: ';
			nextPutAll: aMethodObject displayString;
			cr;
			nextPutAll: 'Side: ';
			nextPutAll: (aMethodObject isClassSide ifTrue: [ 'class' ] ifFalse: [ 'instance' ]);
			cr;
			nextPutAll: 'Owner: ';
			nextPutAll: aMethodObject ownerName asString;
			cr;
			nextPutAll: 'Selector: ';
			nextPutAll: aMethodObject selector asString;
			cr;
			nextPutAll: 'Binding: ';
			nextPutAll: aMethodObject bindingDisplayString asString;
			cr;
			nextPutAll: 'Arity: ';
			nextPutAll: aMethodObject arity asString.
		aMethodObject protocol ifNotNil: [
			stream
				cr;
				nextPutAll: 'Protocol: ';
				nextPutAll: aMethodObject protocol asString ].
		aMethodObject packageName ifNotNil: [
			stream
				cr;
				nextPutAll: 'Package: ';
				nextPutAll: aMethodObject packageName asString ].
		aMethodObject sourceLocation ifNotNil: [
			stream
				cr;
				nextPutAll: 'Source location: ';
				nextPutAll: aMethodObject sourceLocation asString ].
		aMethodObject oop ifNotNil: [
			stream
				cr;
				nextPutAll: 'OOP: ';
				nextPutAll: aMethodObject oop printString ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> invocationArgumentsForMethodObject: aMethodObject [
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

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> selectedServerMethodObject [
	| methodObject className |
	methodObject := self selectedServerUnboundMethodObject.
	methodObject ifNil: [ ^ nil ].
	className := self selectedServerClassName ifNil: [ ^ methodObject ].
	className := className asString.
	(className endsWith: ' class') ifTrue: [ ^ methodObject bindTo: methodObject classMirror proxy ].
	^ (self currentReceiverProxyForServerMethod)
		ifNil: [ methodObject ]
		ifNotNil: [ :receiverProxy | methodObject bindTo: receiverProxy ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> selectedServerUnboundMethodObject [
	| className selector baseName |
	session ifNil: [ ^ nil ].
	className := self selectedServerClassName.
	selector := self selectedServerSelector.
	(className isNil or: [ selector isNil ]) ifTrue: [ ^ nil ].
	className := className asString.
	baseName := (className endsWith: ' class')
		ifTrue: [ className copyFrom: 1 to: className size - 6 ]
		ifFalse: [ className ].
	^ (className endsWith: ' class')
		ifTrue: [ session classUnboundMethodObjectForClassNamed: baseName selector: selector ]
		ifFalse: [ session unboundMethodObjectForClassNamed: baseName selector: selector ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> browseSelectedServerMethodInfo [
	| methodObject |
	methodObject := self selectedServerUnboundMethodObject.
	methodObject ifNil: [
		self inform: 'No GemStone method selected.'.
		^ false ].
	self inform: (self methodInfoTextFor: methodObject).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsRemoteDebugger >> inspectSelectedServerUnboundMethod [
	| methodObject |
	methodObject := self selectedServerUnboundMethodObject.
	methodObject ifNil: [
		self inform: 'No GemStone method selected.'.
		^ false ].
	methodObject inspect.
	^ true
]
