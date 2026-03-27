Extension { #name : 'ParagraphEditor' }

{ #category : '*GbsToolsOverrides-Extensions' }
ParagraphEditor >> initializeMenuForCode
[

	self
		menuHolder: (ValueHolder with: TextEditorController.CodeYellowButtonMenu).
	Menu gbxAdjustForGSItemsFor: self menuHolder value
]

{ #category : '*GbsToolsOverrides-Extensions' }
ParagraphEditor >> initializeMenuForCodeWithFileItIn
[

	self menuHolder: (ValueHolder
				with: TextEditorController.CodeYellowButtonMenuWithFileItIn).
	Menu gbxAdjustForGSItemsFor: self menuHolder value.
	Menu gbxAdjustForGSFileInFor: self menuHolder value.
]

{ #category : '*GbsToolsOverrides-Extensions' }
ParagraphEditor >> inspectIt
[
	"Evaluate the current text selection as an expression and open an inspector on the result."

	self maybeSelectCurrentLine.
	self hasRangeSelection
		ifTrue: 
			[
			[| result |
			result := self evaluateSelection.
			InputState default shiftDown
				ifTrue: [result gbxOldInspect]
				ifFalse: [result inspect]]
					on: self class compilationErrorSignal
					do: [:ex | ex return]]
]

{ #category : '*GbsToolsOverrides-Extensions' }
ParagraphEditor >> localMenuItem: selector
[
	"Answer whether selector is one of the operate button menu items 
	for the receiver."
	"GBS: overrides for its own local behavior"

	^(localMenuItems includes: selector)
		or: [#(#gbxGSDoIt #gbxGSPrintIt #gbxGSInspectIt #gbxGSDebugIt) includes: selector]
]

{ #category : '*GbsToolsOverrides-Extensions' }
ParagraphEditor >> compileSelection
[
	"Compile the current text selection as an expression and answer
	the resulting method. Signal CompilationError if compilation fails.
 
	Stubs and forwarders will possibly do undesirable things with
	the message #class, so we send gbxBasicClass instead. If 
	a 'normal' object gets sent #gbxBasicClass, it will just send #class"

	| compiler |
	compiler := self doItReceiver gbxBasicClass evaluatorClass new.
	^compiler
		compile: self selectionAsStream
		in: self doItContext
		allowReceiver: self doItReceiverAllowed
		class: self doItReceiver gbxBasicClass
		environment: self doItEnvironment
		noPattern: true
		notifying: self
		ifFail: [self class compilationErrorSignal raise]
		handler: (self doItHandlerFor: compiler)
]

