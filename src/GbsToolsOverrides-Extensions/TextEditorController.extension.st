Extension { #name : 'TextEditorController' }

{ #category : '*GbsToolsOverrides-Extensions' }
TextEditorController >> initialize
[

	super initialize.
	self supportCodeEditingFeels: self class supportCodeEditing.
	charComposer := CharacterComposer new.
	textHasChanged := false.
	localMenuItems := #(#cut #paste #copySelection #formatSelection #find #replace #again #undo #redo #cancel #accept #alwaysAccept #hardcopy #toggleWordWrap #doIt #printIt #inspectIt #debugIt #explain #fileItIn #changeTextStyle #align #gbxGSDebugIt #gbxGSDoIt #gbxGSFileItIn #gbxGSInspectIt #gbxGSPrintIt).
	readOnly := false.
	accepted := true.
	autoAccept := false.
	selectable := false.
	continuousAccept := false.
	tabMeansNextField := false.
	tabRequiresControl := true.
	nextUndoBlock := [self startNextUndo]
]

{ #category : '*GbsToolsOverrides-Extensions' }
TextEditorController >> initializeMenuForCode
[

	self menuHolder: (ValueHolder with: CodeYellowButtonMenu copy) .
	Menu gbxAdjustForGSItemsFor: self menuHolder value.
]

{ #category : '*GbsToolsOverrides-Extensions' }
TextEditorController >> initializeMenuForCodeWithFileItIn
[

	self menuHolder: (ValueHolder with: CodeYellowButtonMenuWithFileItIn copy).
	Menu gbxAdjustForGSItemsFor: self menuHolder value.
	Menu gbxAdjustForGSFileInFor: self menuHolder value
]

{ #category : '*GbsToolsOverrides-Extensions' }
TextEditorController >> localMenuItem: selector
[
	"Answer whether selector is one of the operate button menu items 
	for the receiver."
	"GBS: overrides for its own local behavior"

	^(localMenuItems includes: selector)
		or: [#(#gbxGSDoIt #gbxGSPrintIt #gbxGSInspectIt #gbxGSDebugIt) includes: selector]
]

{ #category : '*GbsToolsOverrides-Extensions' }
TextEditorController >> formatAllUsing: aSelector
[
	| pn src parserClass |
	parserClass := self parserClass valueOrDo: [^self].
	pn := parserClass
				perform: aSelector
				with: self text
				with: 
					[:errStr :errPos |
					self insertAndSelect: errStr asString , '->' at: errPos.
					self view flash.
					^nil].
	src := pn formattedCode.
	self selectFrom: 1 to: self text size.
	self replaceSelectionWith: src asText.
	self deselect
]

{ #category : '*GbsToolsOverrides-Extensions' }
TextEditorController >> compileSelection
[
	"Compile the current text selection as an expression and answer
	the resulting method. Signal CompilationError if compilation fails."

	"Stubs and forwarders will possibly do undesirable things with
	the message #class, so we send gbxBasicClass instead. If 
	a 'normal' object gets sent #gbxBasicClass, it will just send #class"

	| class compiler |
	class := GemStone.Gbs.GbxReflection classOf: self doItReceiver.
	compiler := class evaluatorClass new.
	^compiler
		compile: self selectionAsStream
		in: self doItContext
		allowReceiver: self doItReceiverAllowed
		class: class
		environment: self doItEnvironment
		noPattern: true
		notifying: self
		ifFail: [self class compilationErrorSignal raise]
		handler: (self doItHandlerFor: compiler)
]

