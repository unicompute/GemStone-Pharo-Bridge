Extension { #name : #'SyntaxError' }

{ #category : '*GemStone-GBS-Converted-instance-creation' }
SyntaxError class >> addButtonsTo: builder model: aSyntaxError [
	| acceptModel spec proceedModel |
	acceptModel := (PluggableAdaptor on: false) 
				getBlock: [:m | ]
				putBlock: 
					[:m :v | 
					| w oldValue |
					w := (builder componentAt: #editor) widget.
					oldValue := w model value.
					(aSyntaxError acceptText: w model value from: w controller) 
						ifTrue: 
							[aSyntaxError
								text: w model value;
								proceed]
						ifFalse: 
							[aSyntaxError text: oldValue.
							w flash]]
				updateBlock: [:m :a :p | true].
	spec := ActionButtonSpec 
				named: #compile
				model: acceptModel
				layout: ((LayoutFrame new)
						topFraction: 0.75 offset: 5;
						leftFraction: 0.25 offset: 5;
						rightFraction: 0.50 offset: -5;
						bottomFraction: 1 offset: -5).
	spec setLabel: 'Retry'.
	builder add: spec.
	proceedModel := (PluggableAdaptor on: false) 
				getBlock: [:m | ]
				putBlock: [:m :v | aSyntaxError proceed]
				updateBlock: [:m :a :p | true].
	spec := ActionButtonSpec 
				named: #proceed
				model: proceedModel
				layout: ((LayoutFrame new)
						topFraction: 0.75 offset: 5;
						leftFraction: 0.5 offset: 5;
						rightFraction: 0.75 offset: -5;
						bottomFraction: 1 offset: -5).
	spec setLabel: 'Skip'.
	builder add: spec
]

{ #category : '*GemStone-GBS-Converted-text' }
SyntaxError >> text: aString [
	badText := aString
]

{ #category : '*GemStone-GBS-Converted-instance-creation' }
SyntaxError class >> errorInClass: aClass withCode: aString errorString: errorString [
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

{ #category : '*GemStone-GBS-Converted-text' }
SyntaxError >> textMenu [
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

{ #category : '*GemStone-GBS-Converted-accessing' }
SyntaxError class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SyntaxError class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SyntaxError class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SyntaxError >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
SyntaxError >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
SyntaxError >> isRunningUnderAssertingVM [
	^false
]

