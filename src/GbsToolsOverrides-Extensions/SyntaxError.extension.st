Extension { #name : 'SyntaxError' }

{ #category : '*GbsToolsOverrides-Extensions' }
SyntaxError >> textMenu
[
	"Answer a Menu of operations on the text that is to be 
	displayed when the operate menu button is pressed."
	"We are removing Accept, Cancel, Proceed, and Debug because they were
	confusing. In lieu of that we're adding in another method the buttons
	Skip & Retry, which are a little more clear"
	"SyntaxError flushMenus"

	TextMenu == nil
		ifTrue: 
			[TextMenu := Menu labelList: TextEditorController editGroupLabels
								, (Array with: (Array
												with: #DoIt << #pdp >> 'Do it'
												with: #PrintIt << #pdp >> 'Print it'
												with: #InspectIt << #pdp >> 'Inspect it')
										with: (Array with: #Hardcopy << #pdp >> 'Hardcopy'))
						values: TextEditorController editGroupSelectors
								, #(#doIt #printIt #inspectIt #hardcopy)].
	^TextMenu
]

{ #category : '*GbsToolsOverrides-Extensions' }
SyntaxError class >> errorInClass: aClass withCode: aString errorString: errorString
[
	"Create and scehduled a ScheduledWindow on the receiver. The syntax 
	error occurred in trying to add code, aString, to class, aClass."

	| aSyntaxError builder mod editor wid rect |
	aSyntaxError := self new
				setClass: aClass
				code: aString
				processHandle: (ProcessHandle
						on: Processor activeProcess
						at: thisContext
						interrupted: false).
	builder := UIBuilder new.
	builder add: ((WindowSpec label: (#SyntaxError << #dialogs >> 'Syntax Error')) min: 300 @ 180).
	mod := (PluggableAdaptor on: aSyntaxError)
				getBlock: 
					[:m | 
					| wrap |
					wrap := builder componentAt: #editor.
					(wrap isNil or: [wrap widget controller textHasChanged not])
						ifTrue: [m text]
						ifFalse: [wrap widget controller text]]
				putBlock: [:m :v | 
					| w |
					w := (builder componentAt: #editor) widget.
					(m acceptText: v from: w controller)
						ifFalse: [w flash]]
				updateBlock: [:m :a :p | true].
	editor := TextEditorSpec
				named: #editor
				model: mod
				layout: ((LayoutFrame new) topOffset: 1; leftOffset: 1; rightFraction: 1 offset: -1; bottomFraction: 1 offset: -1).
	editor menu: aSyntaxError textMenu.
	editor performer: aSyntaxError.
	editor tabable: true.
	wid := (builder add: editor) widget.
	self addButtonsTo: builder model: aSyntaxError.
	builder window label: aClass fullyQualifiedReference printString.
	rect := Rectangle origin: 0 @ 0 extent: 300 @ 180.
	rect := rect align: rect center with: Screen default bounds center.
	Processor activeProcess
		suspendResumable: true
		do: [:proc |
			builder openIn: rect.
			wid controller find: errorString.
			wid positionToSelection.
			wid displaySelection: true; select.
			wid hasFocus: true.
			InputState default forgetAllGrabs].
	builder window close.
]

