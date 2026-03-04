Class {
	#name : 'GbsWorkspace',
	#superclass : 'SpPresenter',
	#instVars : [
		'textEditor',
		'btnExecute',
		'btnCommit',
		'btnAbort'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'layout' }
GbsWorkspace >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: (SpBoxLayout newHorizontal
			spacing: 5;
			add: btnExecute;
			add: btnCommit;
			add: btnAbort;
			yourself) height: 30;
		add: textEditor;
		yourself
]

{ #category : 'actions' }
GbsWorkspace >> doAbort [
	GbsSessionParameters currentSession ifNotNil: [ :session |
		session abort.
		self inform: 'GemStone: Aborted and Synced to latest state.'
	].
]

{ #category : 'actions' }
GbsWorkspace >> doCommit [
	GbsSessionParameters currentSession ifNotNil: [ :session |
		session commitTransaction
			ifTrue: [ self inform: 'GemStone: Commit Successful!' ]
			ifFalse: [ self inform: 'GemStone: Commit Failed (Conflict)!' ]
	]
]

{ #category : 'actions' }
GbsWorkspace >> doIt [
	| code activeSession result processOop |

	code := self selectedCodeOrAll copyReplaceAll: String cr with: String lf.
	code ifEmpty: [ ^ self ].

	activeSession := GbsSessionParameters currentSession.
	activeSession ifNil: [ ^ self inform: 'No Session' ].

	"Execute and catch ALL errors - open debugger on any error"
	[
		result := activeSession execute: code.
		GbsRemoteTranscript allInstances do: [ :win | win fetchNewEntries ].
	] on: GbsError do: [ :ex |
		processOop := (ex respondsTo: #tag)
			ifTrue: [ ex tag ]
			ifFalse: [ 20 ].
		processOop ifNil: [ processOop := 20 ].
		Transcript
			show: 'GbsError: ';
			show: ex messageText;
			show: ' processOop=';
			show: processOop asString;
			cr.
		self
			openRemoteDebuggerOn: ex messageText
			processOop: processOop
			session: activeSession
	].
]

{ #category : 'actions' }
GbsWorkspace >> executeInGemStone [
	"Safely catch any old Cmd+G shortcuts and route them to the correct, main-thread method"
	^ self doIt
]

{ #category : 'actions' }
GbsWorkspace >> gemStoneDebugIt [
	"Use the same path as DoIt so GbsError carries a real process OOP for remote debugging."
	^ self doIt
]

{ #category : 'actions' }
GbsWorkspace >> gemStonePrintIt [
	| code activeSession printScript resultString currentText |
	
	"1. Format the script inside a BLOCK so periods and multiple statements compile perfectly"
	code := self textEditor text asString copyReplaceAll: String cr with: String lf.
	printScript := '[ ', code, ' ] value printString'.
	
	"2. Get the active session"
	activeSession := GbsSessionParameters currentSession.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	
	"3. Delegate execution entirely to GbsSession"
	resultString := activeSession executeAndFetch: printScript.
	
	"4. Append directly to UI textEditor"
	currentText := textEditor text ifNil: [ '' ].
	textEditor text: currentText asString, ' " ', resultString, ' "'.
	
	GbsRemoteTranscript allInstances do: [ :win | win fetchNewEntries ].
]

{ #category : 'initialization' }
GbsWorkspace >> initialize [

  super initialize.
  "In Pharo 13, we ensure the code presenter is ready for interaction"
  textEditor
    syntaxHighlight: true;
    beForObject: self.

  textEditor bindKeyCombination: $g command toAction: [ self executeInGemStone ].
  textEditor bindKeyCombination: $g control toAction: [ self executeInGemStone ]
]

{ #category : 'initialization' }
GbsWorkspace >> initializePresenters [
	textEditor := self newCode.
	
	"CRITICAL FIX: Removed syntaxHighlight and beForObject so pasting doesn't trigger FFI lookups!"
	
	textEditor contextMenu: [ self workspaceMenu ].
	
	textEditor bindKeyCombination: $d command toAction: [ self doIt ].
	textEditor bindKeyCombination: $p command toAction: [ self gemStonePrintIt ].
	
	btnExecute := self newButton
		label: 'Execute in GemStone (Cmd+G)';
		icon: ( self iconNamed: #glamorousPlay );
		action: [ self doIt ].
		
	btnCommit := self newButton label: 'Commit'; icon: (self iconNamed: #smallSave); action: [ self doCommit ].
	btnAbort := self newButton label: 'Abort (Sync)'; icon: (self iconNamed: #smallCancel); action: [ self doAbort ].
]

{ #category : 'initialization' }
GbsWorkspace >> initializeShortcutKeys [
    textEditor bindKeyCombination: $g command toAction: [ self executeInGemStone ].
    textEditor bindKeyCombination: $g control toAction: [ self executeInGemStone ]
]

{ #category : 'initialization' }
GbsWorkspace >> initializeWindow: aWindowPresenter [

  aWindowPresenter
    title: 'GemStone Workspace';
    initialExtent: 600 @ 400
]

{ #category : 'private' }
GbsWorkspace >> insertResult: aString [

  | text selectionEnd newText |
  text := textEditor text asString.
  selectionEnd := textEditor selectionInterval last.

  newText := ( text copyFrom: 1 to: selectionEnd ) , ' ' , aString
             , ( text copyFrom: selectionEnd + 1 to: text size ).

  textEditor text: newText
]

{ #category : 'actions' }
GbsWorkspace >> inspectIt [
	| code activeSession script rawOop |
	
	code := self textEditor text asString copyReplaceAll: String cr with: String lf.
	script := '[ ', code, ' ] value'.
	
	activeSession := GbsSessionParameters currentSession.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	
	"Use the low-level API to get the RAW OOP, bypassing the GbsProxy conversion"
	rawOop := GbsServerInterface uniqueInstance apiGciExecuteStr: script context: 20 env: 0.
	
	(rawOop = 1 or: [ rawOop = 20 ]) 
		ifTrue: [ self inform: 'Result is nil or execution failed.' ]
		ifFalse: [ GbsInspector inspect: rawOop session: activeSession ].
]

{ #category : 'local actions' }
GbsWorkspace >> localDebugIt [

  | code method context process |
  code := self selectedCodeOrAll.
  code ifEmpty: [ ^ self ].

  [ "1. Tell the compiler this is a headless DoIt (isScripting: true)"
    method := Smalltalk compiler
                source: code;
                isScripting: true;
                compile.

    "2. Create a runtime context for the method"
    context := Context
                 sender: nil
                 receiver: nil
                 method: method
                 arguments: #(  ).

    "3. Create a suspended process for this context"
    process := Process forContext: context priority: Processor userSchedulingPriority.

    "4. Tell the process to open the debugger on itself"
    process debug
    ]
    on: Error
    do: [ :ex | self inform: 'Pharo Local Error: ' , ex messageText ]
]

{ #category : 'local actions' }
GbsWorkspace >> localDoIt [
    | code |
    code := self selectedCodeOrAll.
    code ifEmpty: [ ^ self ].

    [ 
        "Execute locally using standard Pharo Compiler"
        Smalltalk compiler evaluate: code.
        self inform: 'Local DoIt: Executed'
    ] on: Error do: [ :ex | 
        self inform: 'Local Error: ', ex messageText 
    ]
]

{ #category : 'actions' }
GbsWorkspace >> localInspectIt [
    | code result |
    code := self selectedCodeOrAll.
    code ifEmpty: [ ^ self ].

    [ 
        result := Smalltalk compiler evaluate: code.
        result inspect
    ] on: Error do: [ :ex | 
        self inform: 'Local Error: ', ex messageText 
    ]
]

{ #category : 'actions' }
GbsWorkspace >> localPrintIt [

  | code result |
  code := self selectedCodeOrAll.
  code ifEmpty: [ ^ self ].

  [
    result := Smalltalk compiler evaluate: code.
    "Use our manual insertion helper"
    self insertResult: result printString
    ]
    on: Error
    do: [ :ex | self inform: 'Local Error: ' , ex messageText ]
]

{ #category : 'actions' }
GbsWorkspace >> openRemoteDebuggerOn: errorString processOop: processOop session: aSession [
	"Open the GbsRemoteDebugger on a GemStone error"
	| errorText safeProcessOop |

	"Ensure errorString is actually a string"
	errorText := errorString ifNil: [ 'Unknown Error' ] ifNotNil: [ :es | es asString ].
	safeProcessOop := processOop ifNil: [ 20 ].

	"Open the debugger using the class-side method"
	[
		GbsRemoteDebugger 
			openOn: errorText 
			process: safeProcessOop 
			session: aSession
	] on: Error do: [ :ex |
		Transcript
			show: 'Failed to open debugger: ';
			show: ex messageText;
			cr.
		self inform: 'Error opening debugger: ', ex messageText
	].
]

{ #category : 'actions' }
GbsWorkspace >> openRemoteDebuggerWithStack: stackData session: aSession [
	"Open debugger with pre-captured stack data"
	| debugger |
	
	debugger := GbsRemoteDebugger new.
	debugger session: aSession.
	debugger open.
	debugger label: 'GemStone Error'.
	debugger processOop: 0.
	debugger stackData: stackData.
	debugger withWindowDo: [ :win | win title: 'GemStone Remote Debugger' ].
]

{ #category : 'private' }
GbsWorkspace >> replaceSelectionWith: aString [

  | text selectionInterval newText |
  text := textEditor text asString.
  selectionInterval := textEditor selectionInterval.

  newText := ( text copyFrom: 1 to: selectionInterval first - 1 ) , aString
             , ( text copyFrom: selectionInterval last + 1 to: text size ).

  textEditor text: newText.
  "Move cursor to end of inserted text"
  textEditor selectionInterval:
    ( selectionInterval first + aString size to: selectionInterval first + aString size - 1 )
]

{ #category : 'private' }
GbsWorkspace >> selectedCodeOrAll [

  | code |
  code := textEditor selectedText.
  code ifEmpty: [ code := textEditor text ].
  ^ code
]

{ #category : 'private' }
GbsWorkspace >> selectedText [

  ^ textEditor selectedText
]

{ #category : 'layout' }
GbsWorkspace >> staticLayout [

  ^ SpBoxLayout newVertical
      add: textEditor;
      yourself
]

{ #category : 'accessing' }
GbsWorkspace >> textEditor [
    ^ textEditor
]

{ #category : 'menus' }
GbsWorkspace >> workspaceMenu [
	| menu |
	menu := self newMenu.
	
	"--- GEMSTONE ACTIONS ---"
	menu addGroup: [ :group | 
		group addItem: [ :item |
			item name: 'GemStone Do it'; shortcut: $d command; icon: (self iconNamed: #smallDoIt);
			"CRITICAL FIX: Defer the action so the menu closes first!"
			action: [ UIManager default defer: [ self doIt ] ] ].
			
		group addItem: [ :item |
			item name: 'GemStone Inspect it'; shortcut: $i command; icon: (self iconNamed: #smallInspectIt);
			action: [ UIManager default defer: [ self inspectIt ] ] ].
			
		group addItem: [ :item |
			item name: 'GemStone Print it'; shortcut: $p command; icon: (self iconNamed: #smallPrintIt);
			"CRITICAL FIX: Defer the action so the menu closes first!"
			action: [ UIManager default defer: [ self gemStonePrintIt ] ] ].
			
		group addItem: [ :item |
			item name: 'GemStone Debug it'; icon: (self iconNamed: #smallDebug);
			action: [ UIManager default defer: [ self gemStoneDebugIt ] ] ].
	].

	"--- LOCAL ACTIONS (These don't use FFI, so they don't need defer) ---"
	menu addGroup: [ :group | 
		group addItem: [ :item | item name: 'Local Do it'; icon: (self iconNamed: #smallDoIt); action: [ self localDoIt ] ].
		group addItem: [ :item | item name: 'Local Inspect it'; icon: (self iconNamed: #smallInspectIt); action: [ self localInspectIt ] ].
		group addItem: [ :item | item name: 'Local Print it'; icon: (self iconNamed: #smallPrintIt); action: [ self localPrintIt ] ].
	].
	
	^ menu
]
