"
GbxDebuggerService is the main debugger service for GemStone remote debugging in Pharo 13.
It manages the debugged process, context list, and provides all debugging operations.

Based on VisualWorks GbxDebuggerService class.
"
Class {
	#name : 'GbxDebuggerService',
	#superclass : 'Object',
	#instVars : [
		'session',
		'processOop',
		'label',
		'contextStackPolicy',
		'currentContext',
		'selectionRange',
		'sourceMap',
		'receiverInspector',
		'contextInspector',
		'stackInspector',
		'tags',
		'pendingEvents',
		'doStepIntoBlock',
		'dontUpdateInspectors',
		'lastCompileError',
		'restartHomeResetPasses'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDebuggerService class >> context: aContext label: aString [
	"Create a debugger service for a GemStone process context"
	^ self new
		context: aContext;
		label: aString;
		yourself
]

{ #category : 'instance creation' }
GbxDebuggerService class >> openOn: anErrorString process: processOop session: aSession [
	"Open a remote debugger on a GemStone process"
	| service |
	service := self new.
	service session: aSession.
	service processOop: processOop.
	service label: anErrorString.
	[
		service initializeForDebugging
	] on: Error do: [ :ex |
		Transcript
			show: 'GbxDebuggerService initializeForDebugging failed: ';
			show: ex messageText;
			cr
	].

	^ GbsRemoteDebugger
		openOn: anErrorString
		process: processOop
		session: aSession
		service: service
]

{ #category : 'private' }
GbxDebuggerService >> asBooleanResult: raw default: defaultBoolean [
	| value |
	value := raw.
	value ifNil: [ ^ defaultBoolean ].
	value = true ifTrue: [ ^ true ].
	value = false ifTrue: [ ^ false ].
	(value respondsTo: #asLocalString) ifTrue: [ value := value asLocalString ].
	(value respondsTo: #asString) ifFalse: [ ^ defaultBoolean ].
	value := value asString asLowercase.
	(#('true' '1' 'yes' 'ok') includes: value) ifTrue: [ ^ true ].
	(#('false' '0' 'no' 'nil' '') includes: value) ifTrue: [ ^ false ].
	^ defaultBoolean
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpoint: aBreakPoint matchesSelection: anInterval [
	| offset |
	offset := self sourceOffsetForBreakPoint: aBreakPoint.
	offset ifNil: [ ^ false ].
	^ anInterval first <= offset and: [ anInterval last >= offset ]
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointClass [
	^ Smalltalk at: #GbxBreakPoint ifAbsent: [ nil ]
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointIntervalsInCurrentMethod [
	| intervals |
	intervals := OrderedCollection new.
	self breakpointsInSelectedMethod do: [ :bp |
		| offset |
		offset := self sourceOffsetForBreakPoint: bp.
		offset ifNotNil: [ intervals add: (offset to: offset) ]
	].
	^ intervals asArray
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointSummaryString [
	| points stream |
	points := (self breakpointsInSelectedMethod
		collect: [ :bp | (bp respondsTo: #stepPoint) ifTrue: [ bp stepPoint ] ifFalse: [ nil ] ])
		select: #notNil.
	points isEmpty ifTrue: [ ^ 'No breakpoints in method' ].
	stream := WriteStream on: String new.
	points
		doWithIndex: [ :sp :idx |
			idx > 1 ifTrue: [ stream nextPutAll: ', ' ].
			stream nextPutAll: sp asString ].
	^ 'Breakpoints step points: ', stream contents
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> highlightBreakPointsIn: aText [
	"Highlight breakpoints in text widget with purple underline emphasis.
	Returns the text with emphasis added."
	| bps methodSelector |
	currentContext ifNil: [ ^ aText ].
	currentContext gbxIsServerContext ifFalse: [ ^ aText ].
	currentContext isValid ifFalse: [ ^ aText ].
	self isTerminated ifTrue: [ ^ aText ].
	
	methodSelector := self selectedMethodSelector.
	methodSelector ifNil: [ ^ aText ].
	
	bps := self currentBreakPointList select: [ :each |
		each selector = methodSelector and: [ each remoteClass = self selectedMethodClassName ]
	].
	
	bps do: [ :bp |
		| offset |
		offset := currentContext sourceOffsets at: bp stepPoint ifAbsent: [ nil ].
		offset ifNotNil: [
			(aText respondsTo: #emphasizeFrom:to:with:) ifTrue: [
				aText emphasizeFrom: offset to: offset with: #( #underline #color -> #purple )
			]
		]
	].
	^ aText
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointToRemoveIn: aTextWidget from: breakpoints [
	| selection stepPointMatch |
	selection := self selectionIntervalForTextWidget: aTextWidget.
	selection ifNil: [
		stepPointMatch := self currentStepPoint.
		stepPointMatch ifNotNil: [
			^ breakpoints
				detect: [ :bp | (bp respondsTo: #stepPoint) and: [ bp stepPoint = stepPointMatch ] ]
				ifNone: [ breakpoints first ]
		].
		^ breakpoints first
	].
	^ breakpoints
		detect: [ :bp | self breakpoint: bp matchesSelection: selection ]
		ifNone: [ nil ]
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointsInSelectedMethod [
	"Get breakpoints in the currently selected method"
	| selector className |
	(self canManageBreakPoints) ifFalse: [ ^ #( ) ].
	selector := self selectedMethodSelector.
	className := self selectedMethodClassName.
	(selector isNil or: [ className isNil ]) ifTrue: [ ^ #( ) ].
	
	^ self currentBreakPointList select: [ :bp |
		bp selector = selector and: [ bp remoteClass = className ]
	]
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> browserClass [
	^ Smalltalk at: #GbxBrowser ifAbsent: [ nil ]
]

{ #category : 'private' }
GbxDebuggerService >> canExecuteOnDebugProcess [
	(self isSessionUsable and: [ processOop isNumber ]) ifFalse: [ ^ false ].
	^ processOop > 20
]

{ #category : 'inspector' }
GbxDebuggerService >> canInspectCurrentFrame [
	^ self currentContext isNotNil
]

{ #category : 'inspector' }
GbxDebuggerService >> canInspectCurrentProcess [
	^ self currentContext isNotNil
]

{ #category : 'inspector' }
GbxDebuggerService >> canInspectCurrentReceiver [
	^ self currentContext isNotNil
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canManageBreakPoints [
	| selector |
	currentContext ifNil: [ ^ false ].
	(currentContext respondsTo: #gbxIsServerContext)
		ifTrue: [ currentContext gbxIsServerContext ifFalse: [ ^ false ] ].
	selector := self selectedMethodSelector.
	selector isNil ifTrue: [ ^ false ].
	(selector = #unboundMethod) ifTrue: [
		^ (currentContext respondsTo: #isExecutedCodeFrame)
			and: [ currentContext isExecutedCodeFrame ]
	].
	^ self selectedMethodClassName isNotNil
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canRemoveAllBreakPoints [
	^ self breakpointsInSelectedMethod isNotEmpty
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canRemoveBreakPoint [
	^ self hasBreakPointIn: nil
]

{ #category : 'testing' }
GbxDebuggerService >> canResume [
	^ self isTerminated not
]

{ #category : 'testing' }
GbxDebuggerService >> canRunWithBreakAgain [
	^ self canResume and: [ self canIssueContextCommand ]
]

{ #category : 'testing' }
GbxDebuggerService >> canPause [
	^ self canResume
]

{ #category : 'testing' }
GbxDebuggerService >> canRunToStepPoint [
	^ self canIssueContextCommand
]

{ #category : 'testing' }
GbxDebuggerService >> canJumpToStepPoint [
	^ self canIssueContextCommand
]

{ #category : 'testing' }
GbxDebuggerService >> canIssueContextCommand [
	^ currentContext isNotNil and: [ self isTerminated not ]
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canSetBreakPoint [
	^ self canManageBreakPoints and: [ (self hasBreakPointIn: nil) not ]
]

{ #category : 'testing' }
GbxDebuggerService >> canStepInto [
	^ self canIssueContextCommand
]

{ #category : 'testing' }
GbxDebuggerService >> canStepOver [
	^ self canIssueContextCommand
]

{ #category : 'testing' }
GbxDebuggerService >> canStepReturn [
	^ self canIssueContextCommand
]

{ #category : 'testing' }
GbxDebuggerService >> canReturnFromFrame [
	currentContext ifNil: [ ^ false ].
	(currentContext respondsTo: #gbxIsServerContext)
		ifTrue: [ currentContext gbxIsServerContext ifTrue: [ ^ false ] ].
	^ self canStepReturn
]

{ #category : 'testing' }
GbxDebuggerService >> canTerminate [
	^ self isTerminated not
]

{ #category : 'testing' }
GbxDebuggerService >> hasLoopControlContext [
	"VW compatibility hook for Next Loop enablement."
	^ false
]

{ #category : 'testing' }
GbxDebuggerService >> isMethodContextSelected [
	currentContext ifNil: [ ^ false ].
	(currentContext respondsTo: #isExecutedCodeFrame)
		ifTrue: [ ^ currentContext isExecutedCodeFrame not ].
	^ true
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canToggleBreakPoint [
	^ self canManageBreakPoints
]

{ #category : 'evaluation' }
GbxDebuggerService >> clearCompileError [
	lastCompileError := nil
]

{ #category : 'accessing' }
GbxDebuggerService >> contextList [
	contextStackPolicy ifNil: [ ^ #( ) ].
	^ contextStackPolicy contextList
]

{ #category : 'accessing' }
GbxDebuggerService >> contextStackPolicy [
	^ contextStackPolicy
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> currentBreakPointList [
	"Get breakpoints for current session"
	| klass |
	klass := self breakpointClass.
	klass ifNil: [ ^ #( ) ].
	^ klass breakPointListFor: session
]

{ #category : 'accessing' }
GbxDebuggerService >> currentContext [
	^ currentContext
]

{ #category : 'accessing' }
GbxDebuggerService >> currentContext: aContext [
	currentContext := aContext.
	self updateSourceMapFromCurrentContext
]

{ #category : 'inspector' }
GbxDebuggerService >> currentContextLevel [
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #level) ifTrue: [ ^ currentContext level ].
	^ nil
]

{ #category : 'evaluation' }
GbxDebuggerService >> currentExecutionContextOop [
	| frameOop |
	frameOop := self currentFrameOop.
	(frameOop isNumber and: [ frameOop > 20 ]) ifTrue: [ ^ frameOop ].
	((self currentProcessOop) isNumber and: [ self currentProcessOop > 20 ]) ifTrue: [ ^ self currentProcessOop ].
	^ nil
]

{ #category : 'inspector' }
GbxDebuggerService >> currentFrameOop [
	| procOop lvl script |
	procOop := self currentProcessOop.
	lvl := self currentContextLevel.
	(procOop isNil or: [ lvl isNil ]) ifTrue: [ ^ nil ].
	script := '[
		| proc frameObj |
		proc := Object _objectForOop: ', procOop asString, '.
		proc ifNil: [ ^ ''0'' ].
		frameObj := [ proc _frameContentsAt: ', lvl asString, ' ] on: Error do: [ nil ].
		frameObj ifNil: [ ^ ''0'' ].
		(Reflection oopOf: frameObj) asString
	] value'.
	^ self evaluateOopFromScript: script
]

{ #category : 'inspector' }
GbxDebuggerService >> currentProcessOop [
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #processOop) ifTrue: [ ^ currentContext processOop ].
	(currentContext respondsTo: #process) ifTrue: [ ^ currentContext process ].
	^ nil
]

{ #category : 'inspector' }
GbxDebuggerService >> currentReceiverOop [
	| procOop lvl script |
	procOop := self currentProcessOop.
	lvl := self currentContextLevel.
	(procOop isNil or: [ lvl isNil ]) ifTrue: [ ^ nil ].
	script := '[
		| proc frame fullEntry receiverObj |
		proc := Object _objectForOop: ', procOop asString, '.
		proc ifNil: [ ^ ''0'' ].
		frame := [ proc _gsiDebuggerDetailedReportAt: ', lvl asString, ' ] on: Error do: [ nil ].
		frame ifNil: [ ^ ''0'' ].
		fullEntry := [ frame first ] on: Error do: [ nil ].
		fullEntry ifNil: [ ^ ''0'' ].
		receiverObj := [ fullEntry at: 2 ] on: Error do: [ nil ].
		receiverObj ifNil: [ ^ ''0'' ].
		(Reflection oopOf: receiverObj) asString
	] value'.
	^ self evaluateOopFromScript: script
]

{ #category : 'source code' }
GbxDebuggerService >> currentSourceSelectionInterval [
	| map stepPoint entry |
	map := self sourceMap.
	(map isCollection and: [ map isEmpty not ]) ifFalse: [
		selectionRange := nil.
		^ nil
	].

	stepPoint := self currentStepPoint.
	stepPoint ifNotNil: [
		"Find exact match first"
		entry := map
			detect: [ :assoc | (assoc respondsTo: #key) and: [ assoc key = stepPoint ] ]
			ifNone: [ nil ].
			
		"Fallback: find the highest step point number <= current stepPoint"
		entry ifNil: [
			| candidates maxKey |
			candidates := map select: [ :assoc | (assoc respondsTo: #key) and: [ assoc key <= stepPoint ] ].
			maxKey := ((map collect: [ :assoc | assoc key ]) select: [ :k | k isNumber ])
				ifEmpty: [ nil ]
				ifNotEmpty: [ :keys | keys max ].
			(candidates isNotEmpty and: [ maxKey isNumber and: [ stepPoint <= maxKey ] ]) ifTrue: [
				entry := candidates last. "Assuming map is sorted by key"
			]
		].

		entry ifNotNil: [
			selectionRange := entry value.
			^ selectionRange
		]
	].

	selectionRange := map first value.
	^ selectionRange
]

{ #category : 'source code' }
GbxDebuggerService >> currentStepPoint [
	| raw |
	currentContext ifNil: [ ^ nil ].
	raw := (currentContext respondsTo: #stepPoint)
		ifTrue: [ currentContext stepPoint ]
		ifFalse: [
			(currentContext respondsTo: #quickStepPoint)
				ifTrue: [ currentContext quickStepPoint ]
				ifFalse: [ nil ]
		].
	raw ifNil: [ ^ nil ].
	raw := [ raw asInteger ] on: Error do: [ nil ].
	(raw isNil or: [ raw <= 0 ]) ifTrue: [ ^ nil ].
	^ raw
]

{ #category : 'private-step points' }
GbxDebuggerService >> closestRightStepPoint [
	"Find the closest step point strictly right of (after) the current selection.
	Returns the step point number or nil if none found."
	| map currentStep candidates |
	map := self sourceMap.
	map ifEmpty: [ ^ nil ].
	currentStep := self currentStepPoint.
	currentStep ifNil: [ ^ nil ].
	
	candidates := map select: [ :assoc |
		(assoc respondsTo: #key) and: [
			assoc key isNumber and: [ assoc key > currentStep ]
		]
	].
	candidates ifEmpty: [ ^ nil ].
	
	^ (candidates collect: [ :assoc | assoc key ]) min
]

{ #category : 'private-step points' }
GbxDebuggerService >> closestLeftStepPoint [
	"Find the closest step point strictly left of (before) the current selection.
	Returns the step point number or nil if none found."
	| map currentStep candidates |
	map := self sourceMap.
	map ifEmpty: [ ^ nil ].
	currentStep := self currentStepPoint.
	currentStep ifNil: [ ^ nil ].
	
	candidates := map select: [ :assoc |
		(assoc respondsTo: #key) and: [
			assoc key isNumber and: [ assoc key < currentStep ]
		]
	].
	candidates ifEmpty: [ ^ nil ].
	
	^ (candidates collect: [ :assoc | assoc key ]) max
]

{ #category : 'private-step points' }
GbxDebuggerService >> earliestOverlappingStepPoint [
	"Find the lowest step point whose range overlaps the current selection.
	Returns the step point number or nil if none found."
	| map selectionStart selectionEnd |
	map := self sourceMap.
	map ifEmpty: [ ^ nil ].
	selectionRange ifNil: [ ^ nil ].
	
	selectionStart := selectionRange first.
	selectionEnd := selectionRange last.
	
	map do: [ :assoc |
		(assoc respondsTo: #key) and: [
			(assoc respondsTo: #value) and: [
				assoc value isInterval and: [
					assoc value first <= selectionEnd and: [
						assoc value last >= selectionStart
					]
				]
			]
		] ifTrue: [ ^ assoc key ]
	].
	^ nil
]

{ #category : 'private-step points' }
GbxDebuggerService >> earliestSelectedStepPoint [
	"Get the earliest step point for the current selection.
	Tries overlap first, then neighbor step points."
	| stepPoint |
	stepPoint := self earliestOverlappingStepPoint.
	stepPoint ifNotNil: [ ^ stepPoint ].
	
	"No overlap - find closest neighbor"
	stepPoint := self closestRightStepPoint.
	stepPoint ifNil: [ stepPoint := self closestLeftStepPoint ].
	^ stepPoint
]

{ #category : 'private-step points' }
GbxDebuggerService >> basicSkipToCaret [
	"Run to caret position using step points.
	Steps until targetStepPoint is reached."
	| targetStepPoint |
	targetStepPoint := self earliestSelectedStepPoint.
	targetStepPoint ifNil: [ ^ false ].
	
	^ self runToStepPoint: targetStepPoint
]

{ #category : 'private-step points' }
GbxDebuggerService >> basicJumpToCaret [
	"Jump to caret position without executing code.
	Not supported for server frames - use runToStepPoint instead."
	| targetStepPoint |
	targetStepPoint := self earliestSelectedStepPoint.
	targetStepPoint ifNil: [ ^ false ].
	
	^ self jumpToStepPoint: targetStepPoint
]

{ #category : 'private' }
GbxDebuggerService >> escapeForScriptLiteral: aString [
	| s |
	s := aString ifNil: [ '' ] ifNotNil: [ :txt | txt asString ].
	s := s copyReplaceAll: String cr with: String lf.
	^ s copyReplaceAll: '''' with: ''''''
]

{ #category : 'evaluation' }
GbxDebuggerService >> evaluateCodeInCurrentFrame: codeString [
	| contextOop raw |
	(codeString isString and: [ codeString isEmpty not ]) ifFalse: [ ^ nil ].
	self isSessionUsable ifFalse: [ ^ nil ].
	contextOop := self currentExecutionContextOop.
	contextOop ifNil: [ ^ nil ].
	raw := [ session executeAndFetch: codeString context: contextOop ] on: Error do: [ nil ].
	raw ifNil: [ ^ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	^ raw
]

{ #category : 'inspector' }
GbxDebuggerService >> evaluateOopFromScript: scriptString [
	| raw |
	self isSessionUsable ifFalse: [ ^ nil ].
	raw := [ session executeAndFetch: scriptString context: 20 ] on: Error do: [ nil ].
	raw ifNil: [ ^ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	(raw isString and: [ raw = 'nil' or: [ raw beginsWith: 'Error:' ] ]) ifTrue: [ ^ nil ].
	^ [ raw asInteger ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbxDebuggerService >> executeDebugScript: scriptString [
	self isSessionUsable ifFalse: [ ^ nil ].
	^ [ session executeAndFetch: scriptString context: 20 ]
		on: Error
		do: [ nil ]
]

{ #category : 'accessing' }
GbxDebuggerService >> glueIsHidden [
	^ contextStackPolicy glueIsHidden
]

{ #category : 'accessing' }
GbxDebuggerService >> glueIsHidden: aBoolean [
	contextStackPolicy glueIsHidden: aBoolean
]

{ #category : 'evaluation' }
GbxDebuggerService >> gsDoIt: codeString [
	| raw |
	raw := self evaluateCodeInCurrentFrame: codeString.
	^ raw notNil and: [ (raw beginsWith: 'Error:') not ]
]

{ #category : 'evaluation' }
GbxDebuggerService >> gsInspectIt: codeString [
	| contextOop resultOop |
	codeString ifNil: [ ^ false ].
	self isSessionUsable ifFalse: [ ^ false ].
	contextOop := self currentExecutionContextOop.
	contextOop ifNil: [ ^ false ].
	resultOop := [
		session serverInterface
			apiGciExecuteStr: codeString
			context: contextOop
			env: 0
	] on: Error do: [ nil ].
	^ self openInspectorOnOop: resultOop
]

{ #category : 'evaluation' }
GbxDebuggerService >> gsPrintIt: codeString [
	| script |
	codeString ifNil: [ ^ nil ].
	script := '[ ', codeString, ' ] value printString'.
	^ self evaluateCodeInCurrentFrame: script
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> hasBreakPointIn: aTextWidget [
	| bps selection stepPoint |
	bps := self breakpointsInSelectedMethod.
	bps isEmpty ifTrue: [ ^ false ].
	selection := self selectionIntervalForTextWidget: aTextWidget.
	selection ifNotNil: [
		^ bps anySatisfy: [ :bp | self breakpoint: bp matchesSelection: selection ]
	].
	stepPoint := self currentStepPoint.
	stepPoint ifNil: [ ^ false ].
	^ bps anySatisfy: [ :bp | (bp respondsTo: #stepPoint) and: [ bp stepPoint = stepPoint ] ]
]

{ #category : 'initialization' }
GbxDebuggerService >> initialize [
	super initialize.
	tags := Set new.
	pendingEvents := OrderedCollection new.
	dontUpdateInspectors := false.
	lastCompileError := nil.
	restartHomeResetPasses := 0.
]

{ #category : 'initialization' }
GbxDebuggerService >> initializeForDebugging [
	"Initialize the debugger for a new debugging session"
	contextStackPolicy := GbxContextListPolicy debugger: self.
	contextStackPolicy computeContextList.
	
	contextStackPolicy contextList ifNotEmpty: [ :contexts |
		currentContext := contexts first.
	].
	self updateSourceMapFromCurrentContext.
]

{ #category : 'inspector' }
GbxDebuggerService >> inspectCurrentFrame [
	| oop contextInspectorClass |
	oop := self currentFrameOop.
	(self openInspectorOnOop: oop) ifTrue: [ ^ true ].
	currentContext ifNotNil: [
		contextInspectorClass := Smalltalk at: #GbxContextInspector ifAbsent: [ nil ].
		(contextInspectorClass notNil and: [ contextInspectorClass respondsTo: #openOn:service: ]) ifTrue: [
			[ contextInspectorClass openOn: currentContext service: self. ^ true ]
				on: Error
				do: [ ].
		]
	].
	^ false
]

{ #category : 'inspector' }
GbxDebuggerService >> inspectCurrentProcess [
	^ self openInspectorOnOop: self currentProcessOop
]

{ #category : 'inspector' }
GbxDebuggerService >> inspectCurrentReceiver [
	^ self openInspectorOnOop: self currentReceiverOop
]

{ #category : 'inspector' }
GbxDebuggerService >> inspectVariableNamed: aVariableName [
	| variableName start stop |
	(aVariableName isString and: [ aVariableName isEmpty not ]) ifFalse: [ ^ false ].
	variableName := aVariableName asString.
	start := 1.
	stop := variableName size.
	[ start <= stop and: [ (variableName at: start) isSeparator ] ] whileTrue: [ start := start + 1 ].
	[ stop >= start and: [ (variableName at: stop) isSeparator ] ] whileTrue: [ stop := stop - 1 ].
	variableName := start <= stop
		ifTrue: [ variableName copyFrom: start to: stop ]
		ifFalse: [ '' ].
	variableName isEmpty ifTrue: [ ^ false ].
	^ self openInspectorOnOop: (self oopForVariableNamed: variableName)
]

{ #category : 'inspector' }
GbxDebuggerService >> inspectorClass [
	^ GbsInspector
]

{ #category : 'private' }
GbxDebuggerService >> isSessionUsable [
	| loggedIn |
	session ifNil: [ ^ false ].
	(session respondsTo: #isLoggedIn) ifFalse: [ ^ true ].
	loggedIn := [ session isLoggedIn ] on: Error do: [ false ].
	^ loggedIn = true
]

{ #category : 'process control' }
GbxDebuggerService >> isTerminated [
	"Check if the debugged process is terminated"
	| result |
	(self canExecuteOnDebugProcess) ifFalse: [ ^ true ].
	result := self executeDebugScript: '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc ifNil: [ ^ ''true'' ].
		proc isTerminated
	] value'.
	result ifNil: [ ^ true ].
	^ self asBooleanResult: result default: true
]

{ #category : 'accessing' }
GbxDebuggerService >> label [
	^ label
]

{ #category : 'accessing' }
GbxDebuggerService >> label: aString [
	label := aString
]

{ #category : 'evaluation' }
GbxDebuggerService >> lastCompileError [
	^ lastCompileError
]

{ #category : 'evaluation' }
GbxDebuggerService >> normalizedCompileErrorFrom: rawResult [
	| text |
	text := rawResult asString.
	(text beginsWith: 'ERROR|')
		ifTrue: [ ^ (text copyFrom: 7 to: text size) ].
	^ text
]

{ #category : 'context list' }
GbxDebuggerService >> notifyContextChanged [
	"Notify that the context has changed"
	"UI update would happen here"
]

{ #category : 'inspector' }
GbxDebuggerService >> oopForVariableNamed: aVariableName [
	| procOop lvl escapedName script |
	procOop := self currentProcessOop.
	lvl := self currentContextLevel.
	(procOop isNil or: [ lvl isNil ]) ifTrue: [ ^ nil ].
	escapedName := aVariableName copyReplaceAll: '''' with: ''''''.
	script := '[
		| proc frame fullEntry receiverObj names vals idx value |
		proc := Object _objectForOop: ', procOop asString, '.
		proc ifNil: [ ^ ''0'' ].
		frame := [ proc _gsiDebuggerDetailedReportAt: ', lvl asString, ' ] on: Error do: [ nil ].
		frame ifNil: [ ^ ''0'' ].
		fullEntry := [ frame first ] on: Error do: [ nil ].
		fullEntry ifNil: [ ^ ''0'' ].
		(''', escapedName, ''' = ''self'') ifTrue: [
			receiverObj := [ fullEntry at: 2 ] on: Error do: [ nil ].
			receiverObj ifNil: [ ^ ''0'' ].
			^ (Reflection oopOf: receiverObj) asString
		].
		names := [ frame at: 7 ] on: Error do: [ #() ].
		vals := [ frame at: 8 ] on: Error do: [ #() ].
		idx := 0.
		1 to: (names size min: vals size) do: [ :i |
			(((names at: i) asString = ''', escapedName, ''') and: [ idx = 0 ])
				ifTrue: [ idx := i ]
		].
		idx = 0 ifTrue: [ ^ ''0'' ].
		value := [ vals at: idx ] on: Error do: [ nil ].
		value ifNil: [ ^ ''0'' ].
		(Reflection oopOf: value) asString
	] value'.
	^ self evaluateOopFromScript: script
]

{ #category : 'inspector' }
GbxDebuggerService >> openInspectorOnOop: anOop [
	| contextOop inspectorKlass |
	self isSessionUsable ifFalse: [ ^ false ].
	(anOop isNil or: [ anOop <= 20 ]) ifTrue: [ ^ false ].
	inspectorKlass := self inspectorClass.
	contextOop := self currentExecutionContextOop.
	[
		(inspectorKlass respondsTo: #inspect:session:context:)
			ifTrue: [ inspectorKlass inspect: anOop session: session context: contextOop ]
			ifFalse: [ inspectorKlass inspect: anOop session: session ].
		^ true
	] on: Error do: [ :ex |
		^ false
	]
]

{ #category : 'private' }
GbxDebuggerService >> prepareForDebugging [
	"Prepare the debugger for a new debugging session"
	self initializeForDebugging.
]

{ #category : 'private' }
GbxDebuggerService >> processEvents [
	"Process pending UI events"
	| events |
	events := pendingEvents asArray.
	pendingEvents removeAll.
	events do: [ :event | event value ].
]

{ #category : 'accessing' }
GbxDebuggerService >> processOop [
	^ processOop
]

{ #category : 'accessing' }
GbxDebuggerService >> processOop: anOop [
	processOop := anOop
]

{ #category : 'variables' }
GbxDebuggerService >> receiver [
	"Get the receiver of the current context"
	currentContext ifNil: [ ^ nil ].
	^ currentContext receiver
]

{ #category : 'variables' }
GbxDebuggerService >> receiverClass [
	"Get the class of the receiver"
	currentContext ifNil: [ ^ nil ].
	^ currentContext receiverClass
]

{ #category : 'evaluation' }
GbxDebuggerService >> recompileCurrentMethodWithSource: sourceText [
	| className selector isMeta classLookupName escapedSource script raw |
	currentContext ifNil: [ ^ false ].
	self isSessionUsable ifFalse: [ ^ false ].
	self clearCompileError.
	className := self selectedMethodClassName.
	selector := self selectedMethodSelector.
	(className isNil or: [ selector isNil or: [ selector = #unboundMethod ] ]) ifTrue: [ ^ false ].

	isMeta := className asString endsWith: ' class'.
	classLookupName := isMeta
		ifTrue: [ (className asString copyFrom: 1 to: className size - 6) ]
		ifFalse: [ className asString ].
	escapedSource := self escapeForScriptLiteral: sourceText.

	script := '[
		| cls sel protocol result source |
		cls := System myUserProfile symbolList objectNamed: #', classLookupName, '.
		cls ifNil: [ ^ ''ERROR|Class not found'' ].
		', (isMeta ifTrue: [ 'cls := cls class.' ] ifFalse: [ '' ]), '
		sel := #', selector asString, '.
		source := ''', escapedSource, '''.
		protocol := [ cls categoryOfSelector: sel ] on: Error do: [ ''as yet unclassified'' ].
		protocol ifNil: [ protocol := ''as yet unclassified'' ].
		result := [ cls compileMethod: source category: protocol ] on: Error do: [ :ex | ''ERROR|'', ex description ].
		(result isString and: [ result beginsWith: ''ERROR|'' ]) ifTrue: [ ^ result ].
		(result isKindOf: Array) ifTrue: [ ^ ''ERROR|Compilation failed'' ].
		''OK''
	] value'.

	raw := [ session executeAndFetch: script context: session sessionOop ] on: Error do: [ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	raw ifNil: [
		lastCompileError := 'Compile failed: no response from GemStone'.
		^ false
	].
	(raw = 'OK') ifTrue: [ ^ true ].
	lastCompileError := (self normalizedCompileErrorFrom: raw).
	^ false
]

{ #category : 'doIt/accept/explain' }
GbxDebuggerService >> gbxRecompileMethod: sourceText notifying: requestor [
	"Recompile the method in the receiver's current stack frame using sourceText.
	Answer true if compilation is successful, otherwise false.
	Displays compiler errors in the requestor (text editor)."
	| gbxMethod method sess result myErrorText error preErrorText postErrorText |
	gbxMethod := self selectedMethod.
	gbxMethod ifNil: [ ^ false ].
	method := gbxMethod methodDelegate.
	method ifNil: [ ^ false ].
	sess := method session.
	sess ifNil: [ ^ false ].
	
	"Check if method class is nil (unbound method)"
	(gbxMethod methodClass = sess oopNil) ifTrue: [
		^ false "Can't recompile unbound method"
	].

	"Save old method in case it needs to be restored"
	result := [
		sess unsynchronizedEvaluateBlock: '[:meth :source | meth _recompileWithSource: source]'
			with: method
			with: (sourceText gbxConvertToServerLineDelimiter ifNil: [ sourceText ])
	] on: Error do: [ :ex | ex messageText ].
	
	"Check for compilation failure"
	result ~~ true & (result ~~ false) ifTrue: [
		"Compilation failed in 32-bit server or error occurred"
		error := result isEmpty ifTrue: [ nil ] ifFalse: [ result at: 1 ].
		myErrorText := error size < 3 ifTrue: [ 'error' ] ifFalse: [ error at: 3 ].
		requestor ifNotNil: [
			(requestor respondsTo: #insertAndSelect:at:) ifTrue: [
				requestor insertAndSelect: myErrorText , '->' at: (error at: 2)
			]
		].
		^ false
	].
	
	result ifTrue: [
		"Success, same selector - notify method changed"
		self gbxMethodChanged: sourceText.
		^ true
	] ifFalse: [
		"Changed the method selector on recompilation"
		self scheduleTextUpdate.
		self processEvents.
		^ true
	]
]

{ #category : 'doIt/accept/explain' }
GbxDebuggerService >> gbxMethodChanged: newSource [
	"Handle method change - cutback to home context, update source, and refresh display"
	| newContext |
	newContext := self homeContextForCutback.
	newContext ifNil: [ ^ self ].
	
	self cutbackTo: newContext
		finishWith: [
			self performDebugOperation: [
				"Simulate a return value on top client glue context so we don't underflow the stack"
				self topContext ifNotNil: [ :top | top push: nil ].
				sourceMap := newContext visibleSourceMap.
				self selectTopServerContext.
				self scheduleContextListUpdate
			]
		].
	
	currentContext gbxIsServerContext ifTrue: [
		currentContext sourceString: newSource.
		newContext sourceString: newSource
	].
	
	self scheduleTextUpdate.
	self processEvents
]

{ #category : 'doIt/accept/explain' }
GbxDebuggerService >> homeContextForCutback [
	"Get the home context for cutback operations.
	This is typically the current context or its home for blocks."
	^ currentContext
]

{ #category : 'doIt/accept/explain' }
GbxDebuggerService >> acceptTextFrom: textController [
	"Accept/compile text from editor.
	Calls gbxRecompileMethod: for server contexts."
	currentContext gbxIsServerContext
		ifTrue: [ self gbxRecompileMethod: textController text notifying: textController ]
		ifFalse: [ 
			"For client contexts, use standard evaluation"
			self evaluateCodeInCurrentFrame: textController text
		]
]

{ #category : 'context list' }
GbxDebuggerService >> recomputeContextList [
	"Recompute the context list after a step operation.
	Always rebind currentContext to the freshly-computed list entry, even when
	an equal/stale context object is still considered present."
	| contexts refreshed |
	contextStackPolicy ifNil: [
		self updateSourceMapFromCurrentContext.
		self notifyContextChanged.
		^ self
	].
	contextStackPolicy computeContextList.
	contexts := contextStackPolicy contextList.
	
	currentContext isNil
		ifTrue: [
			contexts ifNotEmpty: [ :list | currentContext := list first ]
		]
		ifFalse: [
			refreshed := contexts
				detect: [ :each | (each == currentContext) or: [ each = currentContext ] ]
				ifNone: [ nil ].
			refreshed
				ifNil: [ contexts ifNotEmpty: [ :list | currentContext := list first ] ]
				ifNotNil: [ currentContext := refreshed ]
		].
	self updateSourceMapFromCurrentContext.
	self notifyContextChanged.
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> removeAllBreakPoints [
	"Remove all breakpoints in selected method"
	| bps |
	bps := self breakpointsInSelectedMethod.
	bps do: [ :bp | bp clear ].
	^ bps size
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> removeBreakIn: aTextWidget [
	| bps target |
	bps := self breakpointsInSelectedMethod.
	bps isEmpty ifTrue: [ ^ false ].
	target := self breakpointToRemoveIn: aTextWidget from: bps.
	target ifNil: [ ^ false ].
	target clear.
	^ true
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> removeBreakPoint [
	"Remove breakpoint at current location"
	^ self removeBreakIn: nil
]

{ #category : 'process control' }
GbxDebuggerService >> resume [
	"Resume execution of the debugged process"
	(self runDebugProcessCommand: 'resume' recompute: false)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'process control' }
GbxDebuggerService >> runWithBreakAgain [
	"VW-style behavior: ensure the current source step has a breakpoint, then resume."
	self canRunWithBreakAgain ifFalse: [ ^ false ].
	self setBreakPointIn: nil.
	^ self resume
]

{ #category : 'actions' }
GbxDebuggerService >> basicReenterServerContext [
	"Executed in a debugger service process.
	A server context is selected. Reset to the initial state of that context,
	as if it had just been entered. Discard any execution since the context
	was entered."
	| theContext |
	theContext := currentContext.
	theContext ifNil: [ ^ false ].
	self logRestartState: 'basicReenter/start' context: theContext.

	(self cutbackTo: theContext
		finishWith: [
			"First, reset the server-side PC to step 1 BEFORE fetching the context list.
			This ensures the server reports the correct step point."
			self resetServerPCToStepOne.

			"Level numbers may have changed; recompute and select server-truth context."
			self selectTopServerContext.
			self selectRestartTargetContext.

			"Force another refresh to ensure the display shows step=1"
			self notifyContextChanged
		]) ifFalse: [ ^ false ].
	self logRestartState: 'basicReenter/done' context: self currentContext.

	^ true
]

{ #category : 'private' }
GbxDebuggerService >> markCurrentContextAsRestarted [
	"Mark the current context as restarted (step=1, at method entry).
	This ensures the display shows 'GS: Executed code @1' and stepping starts correctly."
	| target |
	target := self currentContext.
	target ifNil: [ target := self restartTargetContext ].
	target ifNil: [ ^ self ].

	"Mark as executed code frame - this sets class/selector to unknown and step to 1"
	(target respondsTo: #markAsExecutedCodeFrame) ifTrue: [
		target markAsExecutedCodeFrame
	].

	"Update the source map to reflect the new step point"
	self updateSourceMapFromCurrentContext
]

{ #category : 'private' }
GbxDebuggerService >> ensureRestartAtStepOne [
	| step |
	(self isCurrentExecutedCodeFrame) ifFalse: [ ^ self ].
	step := self currentStepPoint ifNil: [ 1 ].
	self logRestartText: 'ensureRestartAtStepOne step=', step asString.
	step > 1 ifFalse: [ ^ self ].
	(self jumpToStepPoint: 1)
		ifFalse: [ self runToStepPoint: 1 ].
	self selectTopServerContext
]

{ #category : 'private' }
GbxDebuggerService >> resetServerPCToStepOne [
	"Force the debugged server process to restart at method entry (step=1).
	This is the deterministic restart anchor used by basicReenterServerContext,
	especially important for repeated Restart actions.
	
	Note: _trimStackToLevel: (called in cutbackGsTo:) already resets the stack
	to step=1. This method ensures the server PC is also reset by re-trimming
	at the executed code frame level."
	| didReset script result level |
	
	"Get the executed code frame level"
	level := self restartLevelFromServerStack.
	level ifNil: [ level := 1 ].
	
	"Try jumpToStepPoint: first (may work on some GemStone versions)"
	didReset := self runDebugProcessCommand: 'jumpToStepPoint' withInteger: 1 recompute: true.
	self logRestartText: 'resetServerPCToStepOne jumpToStepPoint:1 -> ', didReset asString.
	didReset ifTrue: [ ^ true ].
	
	"Try runToStepPoint: as fallback"
	didReset := self runDebugProcessCommand: 'runToStepPoint' withInteger: 1 recompute: true.
	self logRestartText: 'resetServerPCToStepOne runToStepPoint:1 -> ', didReset asString.
	didReset ifTrue: [ ^ true ].
	
	"_trimStackToLevel: already reset the stack, but re-trim to ensure PC is reset"
	script := '[
		| obj proc |
		obj := Object _objectForOop: ', processOop asString, '.
		obj isNil ifTrue: [ ^ ''false'' ].
		proc := obj.
		((proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not) ifTrue: [
			(obj respondsTo: #serverProcess) ifTrue: [ proc := [ obj serverProcess ] on: Error do: [ nil ] ].
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #process ]) ifTrue: [
			proc := [ obj process ] on: Error do: [ nil ]
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #topContext ]) ifTrue: [
			| top |
			top := [ obj topContext ] on: Error do: [ nil ].
			(top notNil and: [ top respondsTo: #process ])
				ifTrue: [ proc := [ top process ] on: Error do: [ nil ] ]
		].
		(proc respondsTo: #_trimStackToLevel:) ifFalse: [ ^ ''false'' ].
		[ proc _trimStackToLevel: ', level asString, ' ] on: Error do: [ nil ].
		''true''
	] value'.
	
	result := self executeDebugScript: script.
	didReset := self asBooleanResult: result default: false.
	self logRestartText: 'resetServerPCToStepOne _trimStackToLevel:', level asString, ' -> ', didReset asString.
	^ didReset
]

{ #category : 'actions' }
GbxDebuggerService >> cutbackTo: aContext finishWith: aBlock [
	"Discard any partially-completed execution above aContext on the logical
	stack, then evaluate aBlock.
	If aContext is a server context, also discard partially-completed execution
	within that server context."

	| isServer |
	aContext ifNil: [ ^ false ].
	isServer := (aContext respondsTo: #gbxIsServerContext)
		and: [ aContext gbxIsServerContext ].
	isServer
		ifTrue: [ ^ self cutbackToGsContext: aContext finishWith: aBlock ].

	self cutbackGsProcessesAbove: aContext.
	aBlock value.
	^ true
]

{ #category : 'actions' }
GbxDebuggerService >> cutbackToGsContext: gsContext finishWith: finishBlockArg [
	"gsContext must be a GemStone server context.
	Discard any partially-completed execution above and 
	within gsContext on my stack, then evaluate finishBlockArg.
	This operation is performed on the logical stack which 
	consists of both client and server contexts, so both client 
	and server contexts may be terminated."
	
	self cutbackClientContextsAbove: gsContext.
	(self cutbackGsTo: gsContext) ifFalse: [ ^ false ].
	finishBlockArg value.
	^ true
]

{ #category : 'actions' }
GbxDebuggerService >> cutbackGsTo: gsContext [
	"gsContext must be a GemStone server context.
	Discard any partially-completed server execution above 
	gsContext on the stack of its GSProcess. Also discards 
	any partial execution in gsContext, resetting it to the 
	beginning."
	| lvl resolvedHomeLevel script result |
	lvl := (gsContext respondsTo: #level) ifTrue: [ gsContext level ] ifFalse: [ 1 ].
	resolvedHomeLevel := self restartLevelFromServerStack.
	(resolvedHomeLevel isNumber and: [ resolvedHomeLevel > 0 ])
		ifTrue: [ lvl := resolvedHomeLevel ].
	
	script := '[
		| obj proc |
		obj := Object _objectForOop: ', processOop asString, '.
		obj isNil ifTrue: [ ^ ''false'' ].
		proc := obj.
		((proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not) ifTrue: [
			(obj respondsTo: #serverProcess) ifTrue: [ proc := [ obj serverProcess ] on: Error do: [ nil ] ].
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #process ]) ifTrue: [
			proc := [ obj process ] on: Error do: [ nil ]
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #topContext ]) ifTrue: [
			| top |
			top := [ obj topContext ] on: Error do: [ nil ].
			(top notNil and: [ top respondsTo: #process ])
				ifTrue: [ proc := [ top process ] on: Error do: [ nil ] ]
		].
		
		(proc respondsTo: #_trimStackToLevel:) ifFalse: [ ^ ''false'' ].
		[ proc _trimStackToLevel: ', lvl asString, ' ] on: Error do: [ ^ ''false'' ].
		''true''
	] value'.

	result := self executeDebugScript: script.
	self logRestartText: 'cutbackGsTo level=', lvl asString, ' result=', result printString.
	^ self asBooleanResult: result default: false
]

{ #category : 'actions' }
GbxDebuggerService >> cutbackClientContextsAbove: gsContext [
	"gsContext must be a GemStone server context.
	Discard any partially-completed client execution above gsContext."
	| ctx |
	contextStackPolicy ifNil: [ ^ self ].
	(contextStackPolicy respondsTo: #firstClientContextAbove:) ifFalse: [ ^ self ].
	ctx := contextStackPolicy firstClientContextAbove: gsContext.
	ctx ifNotNil: [ self cutbackTo: ctx finishWith: [ ] ]
]

{ #category : 'actions' }
GbxDebuggerService >> cutbackGsProcessesAbove: clientContext [
	"clientContext must be a client context.
	Discard any partially-completed server execution above clientContext."
	| ctx |
	ctx := self firstServerContextAbove: clientContext.
	ctx ifNotNil: [ self cutbackToGsProcessOf: ctx ]
]

{ #category : 'actions' }
GbxDebuggerService >> cutbackToGsProcessOf: gsContext [
	"gsContext must be a GemStone server context.
	Discard execution above the owning GS process and terminate that process."
	| gbsError |
	self cutbackClientContextsAbove: gsContext.
	(gsContext respondsTo: #terminateProcess) ifTrue: [
		[ gsContext terminateProcess ] on: Error do: [ ]
	].
	gbsError := (gsContext respondsTo: #gbsError)
		ifTrue: [ [ gsContext gbsError ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	(gbsError notNil and: [ gbsError respondsTo: #session: ]) ifTrue: [
		[ gbsError session: nil ] on: Error do: [ ]
	].
	^ true
]

{ #category : 'actions' }
GbxDebuggerService >> firstServerContextAbove: clientContext [
	"Return the first server context above clientContext in the logical stack."
	| ctxList gsContext i ctx numContexts |
	ctxList := self contextList.
	gsContext := nil.
	i := 1.
	ctx := nil.
	numContexts := ctxList size.
	[ i <= numContexts and: [ ctx ~~ clientContext ] ] whileTrue: [
		ctx := ctxList at: i.
		((ctx respondsTo: #gbxIsServerContext) and: [ ctx gbxIsServerContext ])
			ifTrue: [ gsContext := ctx ].
		i := i + 1
	].
	ctx == clientContext ifFalse: [ ^ nil ].
	^ gsContext
]

{ #category : 'process control' }
GbxDebuggerService >> restart [
	"Restart the current context using the coordinated reenter operation.
	Fixes bug where second restart does not reset Frame Step to 1."
	| didRestart target |
	self logRestartState: 'restart/start' context: self currentContext.
	target := self restartTargetContext.
	target ifNotNil: [ self selectContext: target ].
	didRestart := self basicReenterServerContext.
	didRestart ifTrue: [
		self selectRestartTargetContext.
		(self isExecutedCodeAtStepOne) ifFalse: [
			self logRestartText: 'restart auto-retry: first reenter did not reach step 1'.
			didRestart := self basicReenterServerContext.
			didRestart ifTrue: [ self selectRestartTargetContext ].
		].
		self ensureRestartAtStepOne.
		self selectRestartTargetContext.
		(self isExecutedCodeAtStepOne) ifFalse: [
			"Final deterministic guard: force server PC and UI context to method start."
			self resetServerPCToStepOne.
			self selectTopServerContext.
			self selectRestartTargetContext
		]
	].
	self logRestartText: 'restart/result=', didRestart asString.
	self logRestartState: 'restart/end' context: self currentContext.
	^ didRestart
]

{ #category : 'private' }
GbxDebuggerService >> isExecutedCodeAtStepOne [
	^ self isCurrentExecutedCodeFrame
		and: [ (self currentStepPoint ifNil: [ 0 ]) = 1 ]
]

{ #category : 'private' }
GbxDebuggerService >> logRestartState: labelString context: aContext [
	"Restart diagnostics hook. Keep as no-op by default."
	^ self
]

{ #category : 'private' }
GbxDebuggerService >> logRestartText: aString [
	"Restart diagnostics hook. Keep as no-op by default."
	^ self
]

{ #category : 'private' }
GbxDebuggerService >> restartLevelFromServerStack [
	| raw lines |
	(self canExecuteOnDebugProcess) ifFalse: [ ^ nil ].
	raw := self executeDebugScript: '[
		| obj proc stream maxDepth level stackReport fullEntry methodOrNil className selectorName source quick offsets line offset |
		obj := Object _objectForOop: ', processOop asString, '.
		obj isNil ifTrue: [ ^ '''' ].
		proc := obj.
		((proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not) ifTrue: [
			(obj respondsTo: #serverProcess) ifTrue: [
				proc := [ obj serverProcess ] on: Error do: [ nil ]
			]
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #process ]) ifTrue: [
			proc := [ obj process ] on: Error do: [ nil ]
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #topContext ]) ifTrue: [
			| top |
			top := [ obj topContext ] on: Error do: [ nil ].
			(top notNil and: [ top respondsTo: #process ])
				ifTrue: [ proc := [ top process ] on: Error do: [ nil ] ]
		].
		(proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ])
			ifTrue: [ ^ '''' ].
		stream := WriteStream on: String new.
		maxDepth := 200.
		level := 1.
		[ level <= maxDepth ] whileTrue: [
			fullEntry := nil.
			stackReport := [ proc _gsiStackReportFromLevel: level toLevel: level ] on: Error do: [ nil ].
			(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ])
				ifTrue: [ fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ] ].
			fullEntry isNil
				ifTrue: [ level := maxDepth + 1 ]
				ifFalse: [
					methodOrNil := ((fullEntry respondsTo: #at:) and: [ fullEntry size >= 1 ])
						ifTrue: [ [ fullEntry at: 1 ] on: Error do: [ nil ] ]
						ifFalse: [ nil ].
					className := [ methodOrNil inClass name asString ] on: Error do: [ ''nil'' ].
					selectorName := [ (fullEntry at: 4) ifNil: [ ''nil'' ] ifNotNil: [ :s | s asString ] ]
						on: Error do: [ ''nil'' ].
					stream
						nextPutAll: level asString; tab;
						nextPutAll: className; tab;
						nextPutAll: selectorName;
						lf.
					level := level + 1
				]
		].
		stream contents
	] value'.
	raw ifNil: [ ^ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	(raw respondsTo: #splitOn:) ifFalse: [ ^ nil ].
	lines := raw splitOn: Character lf.
	lines do: [ :line |
		| parts className selectorName |
		parts := line splitOn: Character tab.
		parts size >= 3 ifTrue: [
			className := [ (parts at: 2) asString ] on: Error do: [ '' ].
			selectorName := [ (parts at: 3) asString ] on: Error do: [ '' ].
			((className = 'nil' or: [ className = '<unknown>' ])
				and: [ selectorName = 'nil' or: [ selectorName = 'unboundMethod' ] ])
				ifTrue: [ ^ [ parts first asInteger ] on: Error do: [ nil ] ]
		]
	].
	^ nil
]

{ #category : 'private' }
GbxDebuggerService >> forceRestartPositionToMethodStart [
	"Force the restart target context to position at method start (step=1, line=1)"
	| target |
	target := self currentContext.
	target ifNil: [ target := self restartTargetContext ].
	target ifNil: [ ^ self ].

	"Reset step point to 1 - use instVar access to bypass any validation"
	target instVarNamed: #quickStepPoint put: 1.

	"Reset IP offset to 1"
	target instVarNamed: #ipOffset put: 1.

	"Clear source offsets - they will be recalculated when needed from the server"
	target instVarNamed: #sourceOffsets put: #( ).
	
	"Update the source map to reflect the new step point"
	self updateSourceMapFromCurrentContext
]

{ #category : 'private' }
GbxDebuggerService >> restartTargetContext [
	| contexts |
	contexts := self contextList.
	(contexts isCollection and: [ contexts respondsTo: #isEmpty ]) ifFalse: [ ^ nil ].
	contexts ifEmpty: [ ^ nil ].
	^ contexts
		detect: [ :ctx |
			| className selectorName |
			className := [ ctx methodClassOrUnknown asString ] on: Error do: [ '' ].
			selectorName := [ ctx selectorOrUnknown asString ] on: Error do: [ '' ].
			(className = 'nil' or: [ className = '<unknown>' ])
				and: [ selectorName = 'nil' or: [ selectorName = 'unboundMethod' ] ] ]
		ifNone: [ contexts first ]
]

{ #category : 'private' }
GbxDebuggerService >> selectRestartTargetContext [
	| target |
	target := self restartTargetContext.
	target ifNil: [ ^ self ].
	self selectContext: target
]

{ #category : 'context list' }
GbxDebuggerService >> selectTopServerContext [
	"The stack has changed. Recompute and select the top GemStone context.
	Then refresh the displayed list without a second recompute."
	| topServer |
	contextStackPolicy ifNil: [ ^ self ].
	contextStackPolicy computeContextList.
	topServer := self restartTargetContext.
	topServer ifNil: [
		topServer := (contextStackPolicy respondsTo: #topServerContext)
			ifTrue: [ contextStackPolicy topServerContext ]
			ifFalse: [ nil ]
	].
	topServer ifNil: [
		topServer := contextStackPolicy contextList
			ifEmpty: [ nil ]
			ifNotEmpty: [ :contexts | contexts first ]
	].
	topServer ifNotNil: [ self selectContext: topServer ].
	self schedulePrecomputedContextListUpdate
]

{ #category : 'private-event processing' }
GbxDebuggerService >> schedulePrecomputedContextListUpdate [
	self updatePrecomputedContextList
]

{ #category : 'private-event processing' }
GbxDebuggerService >> scheduleContextListUpdate [
	"Schedule a full context list recomputation and update"
	self recomputeContextList
]

{ #category : 'private-event processing' }
GbxDebuggerService >> scheduleTextUpdate [
	"Schedule source text display update"
	"UI would refresh the source code display"
	self notifyContextChanged
]

{ #category : 'private-event processing' }
GbxDebuggerService >> schedulePCUpdate [
	"Schedule program counter (source highlight) update"
	"UI would refresh the source code highlighting"
	self updateSourceMapFromCurrentContext
]

{ #category : 'private-event processing' }
GbxDebuggerService >> scheduleLabelUpdate [
	"Schedule debugger label update"
	"UI would refresh the debugger title/label"
]

{ #category : 'private-event processing' }
GbxDebuggerService >> eventOrder [
	"Define event processing order for debugger updates"
	^ #( #contextList #text #pc #label )
]

{ #category : 'context list' }
GbxDebuggerService >> correctSelectedContextIfGlue [
	"If the currently selected context should be hidden glue,
	change the selection to a top visible context.
	The hidden glue must be at the top of the stack, so the
	correct context to show is the top visible context."
	(contextStackPolicy isHiddenGlue: currentContext) ifTrue: [
		"It is glue - reselect top visible context"
		self recomputeContextList.
		"Top visible is likely server context, must recompute"
		self selectContextAt: 1
	]
]

{ #category : 'private-event processing' }
GbxDebuggerService >> updatePrecomputedContextList [
	self updateStackList: self contextList
]

{ #category : 'private' }
GbxDebuggerService >> runDebugProcessCommand: commandName recompute: shouldRecompute [
	| result script wasServerContext |
	(self canExecuteOnDebugProcess) ifFalse: [ ^ false ].
	wasServerContext := (currentContext notNil
		and: [ (currentContext respondsTo: #gbxIsServerContext)
		and: [ currentContext gbxIsServerContext ] ]).
	script := '[
		| obj proc |
		obj := Object _objectForOop: ', processOop asString, '.
		obj isNil ifTrue: [ ^ ''false'' ].
		proc := obj.
		((proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not) ifTrue: [
			(obj respondsTo: #serverProcess) ifTrue: [ proc := [ obj serverProcess ] on: Error do: [ nil ] ].
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #process ]) ifTrue: [
			proc := [ obj process ] on: Error do: [ nil ]
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #topContext ]) ifTrue: [
			| top |
			top := [ obj topContext ] on: Error do: [ nil ].
			(top notNil and: [ top respondsTo: #process ])
				ifTrue: [ proc := [ top process ] on: Error do: [ nil ] ]
		].
		proc isNil ifTrue: [ ^ ''false'' ].
		proc ', commandName, '.
		true
	] value'.
	result := self executeDebugScript: script.
	(self asBooleanResult: result default: false) ifFalse: [ ^ false ].
	shouldRecompute ifTrue: [
		wasServerContext
			ifTrue: [ self selectTopServerContext ]
			ifFalse: [ self recomputeContextList ]
	].
	^ true
]

{ #category : 'private' }
GbxDebuggerService >> runDebugProcessCommand: commandName withInteger: anInteger recompute: shouldRecompute [
	| result script wasServerContext |
	(self canExecuteOnDebugProcess) ifFalse: [ ^ false ].
	anInteger ifNil: [ ^ false ].
	wasServerContext := (currentContext notNil
		and: [ (currentContext respondsTo: #gbxIsServerContext)
		and: [ currentContext gbxIsServerContext ] ]).
	script := '[
		| obj proc |
		obj := Object _objectForOop: ', processOop asString, '.
		obj isNil ifTrue: [ ^ ''false'' ].
		proc := obj.
		((proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not) ifTrue: [
			(obj respondsTo: #serverProcess) ifTrue: [ proc := [ obj serverProcess ] on: Error do: [ nil ] ].
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #process ]) ifTrue: [
			proc := [ obj process ] on: Error do: [ nil ]
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #topContext ]) ifTrue: [
			| top |
			top := [ obj topContext ] on: Error do: [ nil ].
			(top notNil and: [ top respondsTo: #process ])
				ifTrue: [ proc := [ top process ] on: Error do: [ nil ] ]
		].
		proc isNil ifTrue: [ ^ ''false'' ].
		[ proc perform: #', commandName, ': with: ', anInteger asString, ' ] on: Error do: [ ^ ''false'' ].
		true
	] value'.
	result := self executeDebugScript: script.
	(self asBooleanResult: result default: false) ifFalse: [ ^ false ].
	shouldRecompute ifTrue: [
		wasServerContext
			ifTrue: [ self selectTopServerContext ]
			ifFalse: [ self recomputeContextList ]
	].
	^ true
]

{ #category : 'context list' }
GbxDebuggerService >> selectContext: aContext [
	"Select a specific context"
	currentContext == aContext ifTrue: [ ^ self ].
	currentContext := aContext.
	self updateSourceMapFromCurrentContext.
	self notifyContextChanged.
]

{ #category : 'context list' }
GbxDebuggerService >> selectContextAt: anIndex [
	"Select a context by index in the context list"
	| contexts |
	contexts := self contextList.
	anIndex <= contexts size ifTrue: [
		currentContext := contexts at: anIndex.
		self updateSourceMapFromCurrentContext.
		self notifyContextChanged.
	].
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> selectedMethodClassName [
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #methodClassOrUnknown) ifTrue: [ ^ currentContext methodClassOrUnknown ].
	(currentContext respondsTo: #methodClass) ifTrue: [ ^ currentContext methodClass ].
	^ nil
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> selectedMethodSelector [
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #selectorOrUnknown) ifTrue: [ ^ currentContext selectorOrUnknown ].
	(currentContext respondsTo: #selector) ifTrue: [ ^ currentContext selector ].
	^ nil
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> selectionIntervalForTextWidget: aTextWidget [
	| controller start stop |
	aTextWidget ifNil: [ ^ nil ].
	(aTextWidget respondsTo: #selectionInterval) ifTrue: [ ^ aTextWidget selectionInterval ].
	(aTextWidget respondsTo: #controller) ifFalse: [ ^ nil ].
	controller := aTextWidget controller.
	((controller respondsTo: #selectionStartIndex) and: [ controller respondsTo: #selectionStopIndex ])
		ifFalse: [ ^ nil ].
	start := controller selectionStartIndex.
	stop := controller selectionStopIndex.
	(start isNil or: [ stop isNil ]) ifTrue: [ ^ nil ].
	^ start to: stop
]

{ #category : 'accessing' }
GbxDebuggerService >> session [
	^ session
]

{ #category : 'accessing' }
GbxDebuggerService >> session: aSession [
	session := aSession
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> setBreakPoint [
	"Set a breakpoint at the current location"
	^ self setBreakPointIn: nil
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> setBreakPointIn: aTextWidget [
	| browserKlass |
	(self canManageBreakPoints) ifFalse: [ ^ false ].
	(self sourceMatchesCurrentMethodIn: aTextWidget) ifFalse: [ ^ false ].
	(self hasBreakPointIn: aTextWidget) ifTrue: [ ^ false ].
	browserKlass := self browserClass.
	browserKlass ifNil: [ ^ false ].

	browserKlass
		setBreakInView: aTextWidget
		model: currentContext
		method: self selectedMethodSelector
		class: self selectedMethodClassName.
	^ true
]

{ #category : 'source code' }
GbxDebuggerService >> sourceCode [
	"Get the source code for the current context"
	currentContext ifNil: [ ^ '' ].
	^ currentContext sourceCode
]

{ #category : 'source code' }
GbxDebuggerService >> sourceMap [
	"Get the source map for highlighting"
	currentContext ifNil: [ sourceMap := #( ). ^ sourceMap ].
	sourceMap ifNil: [ self updateSourceMapFromCurrentContext ].
	^ sourceMap
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> sourceMatchesCurrentMethodIn: aTextWidget [
	| widgetText sourceText |
	aTextWidget ifNil: [ ^ true ].
	(aTextWidget respondsTo: #text) ifFalse: [ ^ true ].
	currentContext ifNil: [ ^ true ].
	sourceText := (currentContext respondsTo: #sourceCode)
		ifTrue: [ currentContext sourceCode ]
		ifFalse: [ (currentContext respondsTo: #sourceString) ifTrue: [ currentContext sourceString ] ifFalse: [ nil ] ].
	sourceText ifNil: [ ^ true ].
	widgetText := [ aTextWidget text asString ] on: Error do: [ nil ].
	widgetText ifNil: [ ^ true ].
	^ widgetText = sourceText asString
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> sourceOffsetForBreakPoint: aBreakPoint [
	| stepPoint offsets rawOffset |
	currentContext ifNil: [ ^ nil ].
	(aBreakPoint respondsTo: #stepPoint) ifFalse: [ ^ nil ].
	stepPoint := aBreakPoint stepPoint.
	stepPoint ifNil: [ ^ nil ].
	(currentContext respondsTo: #sourceOffsets) ifFalse: [ ^ nil ].
	offsets := currentContext sourceOffsets.
	rawOffset := [ offsets at: stepPoint ] on: Error do: [ nil ].
	rawOffset ifNil: [ ^ nil ].
	^ [ rawOffset asInteger ] on: Error do: [ nil ]
]

{ #category : 'stepping' }
GbxDebuggerService >> stepInto [
	"VW parity: step-into on server contexts is implemented by _stepOverInFrame:
	with the step-through flag in the high bit of level."
	| level before |
	before := self currentStepPoint.
	level := self effectiveServerStepLevel.
	level ifNil: [ level := 1 ].
	(self serverStepOverFrameLevel: (level bitOr: 16r100000000))
		ifTrue: [ ^ self normalizeExecutedCodeSingleStepFrom: before ].
	^ false
]

{ #category : 'stepping' }
GbxDebuggerService >> stepOver [
	| level before |
	before := self currentStepPoint.
	level := self effectiveServerStepLevel.
	level ifNil: [ level := 1 ].
	(self serverStepOverFrameLevel: level)
		ifTrue: [ ^ self normalizeExecutedCodeSingleStepFrom: before ].
	^ false
]

{ #category : 'private' }
GbxDebuggerService >> normalizeExecutedCodeSingleStepFrom: previousStepPoint [
	| currentStep target |
	(previousStepPoint isNumber and: [ previousStepPoint > 0 ]) ifFalse: [ ^ true ].
	self isCurrentExecutedCodeFrame ifFalse: [ ^ true ].
	currentStep := self currentStepPoint.
	target := previousStepPoint + 1.
	currentStep = target ifTrue: [ ^ true ].
	self
		logRestartText:
			'normalize single-step previous=', previousStepPoint asString,
			' current=', (currentStep ifNil: [ 'nil' ] ifNotNil: [ currentStep asString ]),
			' target=', target asString.
	(self jumpToStepPoint: target) ifTrue: [ ^ true ].
	(self runToStepPoint: target) ifTrue: [ ^ true ].
	^ true
]

{ #category : 'private' }
GbxDebuggerService >> effectiveServerStepLevel [
	| level resolved |
	level := self currentContextLevel.
	(level isNumber and: [ level > 0 ]) ifTrue: [ ^ level ].
	(self isCurrentExecutedCodeFrame not) ifTrue: [ ^ level ].
	resolved := self restartLevelFromServerStack.
	(resolved isNumber and: [ resolved > 0 ]) ifTrue: [ ^ resolved ].
	^ level
]

{ #category : 'private' }
GbxDebuggerService >> isCurrentExecutedCodeFrame [
	| className selectorName |
	currentContext ifNil: [ ^ false ].
	((currentContext respondsTo: #isExecutedCodeFrame)
		and: [ currentContext isExecutedCodeFrame ]) ifTrue: [ ^ true ].
	className := [ currentContext methodClassOrUnknown asString ] on: Error do: [ '' ].
	selectorName := [ currentContext selectorOrUnknown asString ] on: Error do: [ '' ].
	^ (className = 'nil' or: [ className = '<unknown>' ])
		and: [ selectorName = 'nil' or: [ selectorName = 'unboundMethod' ] ]
]

{ #category : 'stepping' }
GbxDebuggerService >> stepReturn [
	"Step out of the current context (return to sender)"
	(self runDebugProcessCommand: 'stepReturn' recompute: true)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'stepping' }
GbxDebuggerService >> stepUntilPC: stopPC [
	"Step until PC reaches stopPC or context changes (max 20 steps).
	Used for precise server stepping control."
	| steps |
	steps := 0.
	[ steps < 20 ] whileTrue: [
		| currentPC |
		currentPC := self currentStepPoint.
		(currentPC isNil or: [ currentPC >= stopPC ]) ifTrue: [ ^ true ].
		(self stepOver) ifFalse: [ ^ false ].
		steps := steps + 1.
	].
	^ false
]

{ #category : 'private-GS execution' }
GbxDebuggerService >> requestServerSingleStep [
	"About to send from client to server. Set the single step flag for the session."
	| sess |
	(currentContext respondsTo: #gbxPeekForReceiver) ifFalse: [ ^ self ].
	sess := currentContext gbxPeekForReceiver gbxGsDebuggerSession.
	sess ifNil: [ ^ self ].
	sess serverInterface requestSingleStep
]

{ #category : 'private-GS execution' }
GbxDebuggerService >> basicSendIntoServer [
	"Send when the next send will take us from client to server.
	Requests single step and handles GbsError for rtErrStep."
	| gbsErr initial |
	self requestServerSingleStep.
	
	[ self privateStep ]
		on: Error "ContextEmergencyError in VW"
		do: [ :ex |
			gbsErr := ex parameter.
			(gbsErr isNil or: [ 
				(gbsErr respondsTo: #creator) ifFalse: [ true ]
				ifTrue: [ gbsErr creator ~~ (self gbsErrorClass signalFor: #rtErrStep) ]
			]) ifTrue: [
				ex pass "Pass non-rtErrStep errors up"
			]
		].
	
	gbsErr ifNotNil: [
		"Server method didn't stop for single step (simple method).
		Put new contexts on stack and update selection."
		initial := (gbsErr respondsTo: #initialContext)
			ifTrue: [ [ gbsErr initialContext ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		initial ifNotNil: [ currentContext := initial ].
		self selectTopServerContext
	]
]

{ #category : 'private-GS execution' }
GbxDebuggerService >> basicServerStepInLevel: level [
	"The selected context is a server context. Perform a step in the
	given level of that context's GsProcess.
	Level should be the level of the selected context, or if top context
	is selected and level is 0, do a send."
	| gbsError scContext |
	gbsError := currentContext gbsError.
	gbsError ifNil: [ ^ self ].
	
	gbsError stepLevel: level.
	
	"Internally select the serverCall context for the selected context"
	currentContext := scContext := currentContext serverCallContext.
	scContext ifNil: [ ^ self ].
	
	self resetPCSelection.
	
	"Step until right after the send of #stepOrContinueAfter (PC=31)"
	self stepUntilPC: 31.
	
	(currentContext == scContext) ifFalse: [
		"Entering client-side exception handler - stop now"
		^ self
	].
	
	"Step until assign result, back to loop head (PC=10)"
	self stepUntilPC: 10.
	
	(scContext respondsTo: #gbxResult) ifTrue: [
		(scContext gbxResult respondsTo: #gbxIsGSError) ifTrue: [
			scContext gbxResult gbxIsGSError
				ifTrue: [ self selectTopServerContext ]
				ifFalse: [ self stepOutOfServerIntoClient ]
		] ifFalse: [
			self stepOutOfServerIntoClient
		]
	] ifFalse: [
		self stepOutOfServerIntoClient
	]
]

{ #category : 'private-GS execution' }
GbxDebuggerService >> stepOutOfServerIntoClient [
	"A server step has terminated. Step to appropriate point in client below glue."
	| itsSender aContext |
	itsSender := currentContext.
	
	[ 
		aContext := itsSender.
		itsSender := itsSender sender.
		(aContext respondsTo: #gbxIsGsBottomGlue) 
			and: [ aContext gbxIsGsBottomGlue 
			and: [ itsSender notNil 
			and: [ (itsSender respondsTo: #gbxIsGsBottomGlue) 
				ifTrue: [ itsSender gbxIsGsBottomGlue not ]
				ifFalse: [ true ]
			]]]
	] whileTrue.
	
	itsSender ifNotNil: [
		currentContext := itsSender.
		sourceMap := currentContext visibleSourceMap.
		self stepOver.
		self selectContext: currentContext
	]
]

{ #category : 'private-GS execution' }
GbxDebuggerService >> gbsErrorClass [
	"Get the GbsError class for exception handling"
	^ Smalltalk at: #GbsError ifAbsent: [ Error ]
]

{ #category : 'private-GS execution' }
GbxDebuggerService >> privateStep [
	"Perform a private step operation.
	This is used internally for basicSendIntoServer."
	^ self stepInto
]

{ #category : 'private-GS execution' }
GbxDebuggerService >> resetPCSelection [
	"Reset PC selection - update source map before stepping"
	self updateSourceMapFromCurrentContext
]

{ #category : 'stack manipulation' }
GbxDebuggerService >> emergencyRestart: ex [
	"Handle ContextEmergencyError during simulation.
	Manages unwind, context restoration, and recovery."
	| originalContext |
	originalContext := currentContext.
	
	"Restore context to pre-error state"
	ex parameter ifNotNil: [ :param |
		(param respondsTo: #initialContext) ifTrue: [
			currentContext := param initialContext
		]
	].
	
	"Recompute context list and update display"
	self recomputeContextList.
	self scheduleTextUpdate.
	self processEvents
]

{ #category : 'private-inspectors' }
GbxDebuggerService >> openInspectors [
	"Open GbxReceiverInspector, GbxContextInspector, GbxStackInspector"
	| inspectorClass |
	inspectorClass := Smalltalk at: #GbxContextInspector ifAbsent: [ ^ self ].
	
	"Open receiver inspector"
	(self canInspectCurrentReceiver) ifTrue: [
		self inspectCurrentReceiver
	].
	
	"Open context inspector"
	(self canInspectCurrentFrame) ifTrue: [
		self inspectCurrentFrame
	].
	
	"Open process inspector"
	(self canInspectCurrentProcess) ifTrue: [
		self inspectCurrentProcess
	]
]

{ #category : 'stack accessing' }
GbxDebuggerService >> notifierStackStringOfSize: n [
	"Get string representation of top N contexts for display"
	| contexts stream |
	contexts := self contextList.
	contexts ifEmpty: [ ^ label ifNil: [ '' ] ].
	
	stream := WriteStream on: String new.
	stream nextPutAll: (label ifNil: [ 'Debugger' ]).
	stream cr.
	
	1 to: (n min: contexts size) do: [ :i |
		| ctx |
		ctx := contexts at: i.
		stream tab.
		stream nextPutAll: (ctx respondsTo: #printString)
			ifTrue: [ ctx printString ]
			ifFalse: [ ctx asString ].
		stream cr
	].
	
	^ stream contents
]

{ #category : 'actions' }
GbxDebuggerService >> stackForCopy [
	"Get stack string for copying using GbxContextDumpPolicy"
	| cp |
	cp := Smalltalk at: #GbxContextDumpPolicy ifAbsent: [ ^ self stackForCopySimple ].
	cp := cp new.
	cp stack: contextStackPolicy contextList.
	cp errorMessage: label.
	^ cp copyStackString
]

{ #category : 'actions' }
GbxDebuggerService >> stackForCopySimple [
	"Get simple stack string for copying"
	| contexts stream |
	contexts := self contextList.
	contexts ifEmpty: [ ^ label ifNil: [ '' ] ].
	
	stream := WriteStream on: String new.
	stream nextPutAll: (label ifNil: [ 'Debugger' ]).
	stream cr; cr.
	
	1 to: contexts size do: [ :i |
		| ctx |
		ctx := contexts at: i.
		stream nextPutAll: i asString.
		stream nextPutAll: '. '.
		stream nextPutAll: (ctx respondsTo: #printString)
			ifTrue: [ ctx printString ]
			ifFalse: [ ctx asString ].
		stream cr
	].
	
	^ stream contents
]

{ #category : 'process control' }
GbxDebuggerService >> returnFromFrame [
	self canReturnFromFrame ifFalse: [ ^ false ].
	^ self stepReturn
]

{ #category : 'process control' }
GbxDebuggerService >> pause [
	"Best effort: interrupt the active GemStone session."
	self isSessionUsable ifFalse: [ ^ false ].
	^ [ 
		(session respondsTo: #sendInterrupt)
			ifTrue: [ session sendInterrupt. true ]
			ifFalse: [
				(session respondsTo: #interrupt)
					ifTrue: [ session interrupt. true ]
					ifFalse: [
						(session respondsTo: #signalInterrupt)
							ifTrue: [ session signalInterrupt. true ]
							ifFalse: [ false ]
					]
			]
	] on: Error do: [ false ]
]

{ #category : 'process control' }
GbxDebuggerService >> runToStepPoint: aStepPoint [
	((aStepPoint isNumber and: [ aStepPoint > 0 ]) not) ifTrue: [ ^ false ].
	(self runDebugProcessCommand: 'runToStepPoint' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	(self runDebugProcessCommand: 'runTo' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'process control' }
GbxDebuggerService >> jumpToStepPoint: aStepPoint [
	((aStepPoint isNumber and: [ aStepPoint > 0 ]) not) ifTrue: [ ^ false ].
	(self runDebugProcessCommand: 'jumpToStepPoint' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	(self runDebugProcessCommand: 'jumpTo' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'private' }
GbxDebuggerService >> serverStepOverFrameLevel: levelValue [
	| result script |
	(self canExecuteOnDebugProcess) ifFalse: [ ^ false ].
	levelValue ifNil: [ ^ false ].
	script := '[
		| obj proc stepLevel ok |
		obj := Object _objectForOop: ', processOop asString, '.
		obj isNil ifTrue: [ ^ ''false'' ].
		proc := obj.
		((proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not) ifTrue: [
			(obj respondsTo: #serverProcess) ifTrue: [ proc := [ obj serverProcess ] on: Error do: [ nil ] ].
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #process ]) ifTrue: [
			proc := [ obj process ] on: Error do: [ nil ]
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #topContext ]) ifTrue: [
			| top |
			top := [ obj topContext ] on: Error do: [ nil ].
			(top notNil and: [ top respondsTo: #process ])
				ifTrue: [ proc := [ top process ] on: Error do: [ nil ] ]
		].
		(proc isNil or: [ (proc respondsTo: #perform:with:) not ]) ifTrue: [ ^ ''false'' ].
		stepLevel := ', levelValue asString, '.
		ok := [ proc perform: #_stepOverInFrame: with: stepLevel ] on: Error do: [ nil ].
		ok isNil ifTrue: [ ^ ''false'' ].
		''true''
	] value'.
	result := self executeDebugScript: script.
	(self asBooleanResult: result default: false) ifFalse: [ ^ false ].
	self selectTopServerContext.
	^ true
]

{ #category : 'variables' }
GbxDebuggerService >> tempNamesAndValues [
	"Get temp variable names and values for current context"
	currentContext ifNil: [ ^ #( ) ].
	^ currentContext tempNamesAndValues
]

{ #category : 'process control' }
GbxDebuggerService >> terminate [
	"Terminate the debugged process"
	(self runDebugProcessCommand: 'terminate' recompute: false)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'evaluation' }
GbxDebuggerService >> correctCurrentSelectorWithSource: sourceText [
	| className selector isMeta classLookupName escapedSource script raw |
	currentContext ifNil: [ ^ false ].
	self isSessionUsable ifFalse: [ ^ false ].
	self clearCompileError.
	className := self selectedMethodClassName.
	selector := self selectedMethodSelector.
	(className isNil or: [ selector isNil or: [ selector = #unboundMethod ] ]) ifTrue: [ ^ false ].

	isMeta := className asString endsWith: ' class'.
	classLookupName := isMeta
		ifTrue: [ (className asString copyFrom: 1 to: className size - 6) ]
		ifFalse: [ className asString ].
	escapedSource := self escapeForScriptLiteral: sourceText.

	script := '[
		| cls oldSel protocol result newSel source |
		cls := System myUserProfile symbolList objectNamed: #', classLookupName, '.
		cls ifNil: [ ^ ''ERROR|Class not found'' ].
		', (isMeta ifTrue: [ 'cls := cls class.' ] ifFalse: [ '' ]), '
		oldSel := #', selector asString, '.
		source := ''', escapedSource, '''.
		protocol := [ cls categoryOfSelector: oldSel ] on: Error do: [ ''as yet unclassified'' ].
		protocol ifNil: [ protocol := ''as yet unclassified'' ].
		result := [ cls compileMethod: source category: protocol ] on: Error do: [ :ex | ''ERROR|'', ex description ].
		(result isString and: [ result beginsWith: ''ERROR|'' ]) ifTrue: [ ^ result ].
		(result isKindOf: Array) ifTrue: [ ^ ''ERROR|Compilation failed'' ].
		newSel := [ result selector ] on: Error do: [ oldSel ].
		(newSel ~= oldSel and: [ cls includesSelector: oldSel ]) ifTrue: [
			[ cls removeSelector: oldSel ] on: Error do: [ :ex | ]
		].
		''OK''
	] value'.

	raw := [ session executeAndFetch: script context: session sessionOop ] on: Error do: [ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	raw ifNil: [
		lastCompileError := 'Correct selector failed: no response from GemStone'.
		^ false
	].
	(raw = 'OK') ifTrue: [ ^ true ].
	lastCompileError := (self normalizedCompileErrorFrom: raw).
	^ false
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> toggleBreakPoint [
	^ self toggleBreakPointIn: nil
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> toggleBreakPointIn: aTextWidget [
	(self hasBreakPointIn: aTextWidget)
		ifTrue: [ ^ self removeBreakIn: aTextWidget ]
		ifFalse: [ ^ self setBreakPointIn: aTextWidget ]
]

{ #category : 'private' }
GbxDebuggerService >> toggleGlueHiding [
	"Toggle visibility of GBS glue contexts"
	self glueIsHidden: self glueIsHidden not.
	self recomputeContextList.
]

{ #category : 'accessing' }
GbxDebuggerService >> topContext [
	"Best-effort client top context for mixed client/server stack logic."
	^ thisContext sender
]

{ #category : 'source code' }
GbxDebuggerService >> updateSourceMapFromCurrentContext [
	sourceMap := currentContext
		ifNil: [ #( ) ]
		ifNotNil: [
			[ currentContext visibleSourceMap ] on: Error do: [ #( ) ]
		].
	self currentSourceSelectionInterval.
]

{ #category : 'context list' }
GbxDebuggerService >> updateStackList: aList [
	"Update the stack list in the UI"
	"Called by context policy"
]

{ #category : 'actions-browsing' }
GbxDebuggerService >> browseMethod [
	"Browse current method - uses gbxBrowseMethod: for server contexts"
	currentContext gbxIsServerContext ifTrue: [
		^ self gbxBrowseMethod: self selectedMethod
	].
	"For client contexts, standard browsing would be used"
	^ nil
]

{ #category : 'actions-browsing' }
GbxDebuggerService >> browseClass [
	"Browse class - uses gbxBrowseClass: for server contexts"
	currentContext gbxIsServerContext ifTrue: [
		^ self gbxBrowseClass: currentContext homeReceiver
	].
	^ nil
]

{ #category : 'actions-browsing' }
GbxDebuggerService >> gbxBrowseMethod: delegate [
	"Browse server method with full info in single round trip.
	Opens GbxHierarchyBrowser on the method."
	| newBrowser result classHolder |
	delegate ifNil: [ ^ nil ].
	delegate session ifNil: [ ^ nil ].
	
	result := delegate session evaluate: '
		| method displayClass className sel protocol isMeta result |
		method := self selector isNil ifTrue:[self homeMethod] ifFalse:[self].
		displayClass := method inClass thisClass.
		className := displayClass name.
		sel := method selector.
		protocol := method inClass categoryOfSelector: sel.
		isMeta := method inClass isMeta.
		result := Array new.
		result add: displayClass asOop;
			add: className;
			add: sel;
			add: protocol;
			add: isMeta.
		result
	' context: delegate.
	
	result ifNil: [ ^ nil ].
	
	newBrowser := Smalltalk at: #GbxHierarchyBrowser ifAbsent: [ ^ nil ].
	newBrowser ifNil: [ ^ nil ].
	
	newBrowser := newBrowser new.
	newBrowser session: delegate session.
	
	classHolder := (Smalltalk at: #GbxClassHolder ifAbsent: [ ^ nil ])
		name: (result at: 2)
		proxy: (Smalltalk at: #GbxDelegate ifAbsent: [ ^ nil ])
			oopValue: (result at: 1)
			session: delegate session.
	
	newBrowser myClass: classHolder.
	newBrowser classList: nil
		class: classHolder
		protocolList: nil
		protocol: (result at: 4)
		methodList: nil
		selectedMethods: (Array with:
			(Smalltalk at: #GbxCompiledMethodHolder ifAbsent: [ ^ nil ])
				name: (result at: 3)).
	
	(result at: 5) ifTrue: [
		newBrowser initalizeMetaTabsToIndex: 2
	].
	
	^ newBrowser
]

{ #category : 'actions-browsing' }
GbxDebuggerService >> gbxBrowseClass: aDelegate [
	"Browse server class using GbxHierarchyBrowser"
	| newBrowser aClass remoteClass |
	aDelegate ifNil: [ ^ nil ].
	
	newBrowser := Smalltalk at: #GbxHierarchyBrowser ifAbsent: [ ^ nil ].
	newBrowser ifNil: [ ^ nil ].
	
	newBrowser := newBrowser new.
	newBrowser session: aDelegate session.
	
	remoteClass := aDelegate remoteClass.
	remoteClass ifNil: [ ^ nil ].
	
	(remoteClass unsynchronizedPerformOnGsServer: #isMeta) ifTrue: [
		remoteClass := aDelegate
	].
	
	aClass := (Smalltalk at: #GbxClassHolder ifAbsent: [ ^ nil ])
		name: (remoteClass unsynchronizedPerformOnGsServer: #name)
		proxy: remoteClass.
	
	newBrowser myClass: aClass.
	newBrowser classList: nil
		class: aClass
		protocolList: nil
		protocol: nil
		methodList: nil
		selectedMethods: nil.
	
	^ newBrowser
]

{ #category : 'private-support' }
GbxDebuggerService >> pendingMessage [
	"If the next step in the current context will not send a message, answer nil.
	If it will send a message, answer the MessageSend (receiver, selector, arguments)."
	| r s numArgs message messageClass |
	(currentContext respondsTo: #pdpWillSend) ifTrue: [
		currentContext pdpWillSend ifFalse: [ ^ nil ]
	].
	
	r := (currentContext respondsTo: #gbxPeekForReceiver)
		ifTrue: [ currentContext gbxPeekForReceiver ]
		ifFalse: [ currentContext receiver ].
	
	s := (currentContext respondsTo: #peekForSelector)
		ifTrue: [ currentContext peekForSelector ]
		ifFalse: [ nil ].
	
	s ifNil: [ ^ nil ].
	
	numArgs := s numArgs.
	messageClass := Smalltalk at: #MessageSend ifAbsent: [ ^ nil ].
	messageClass ifNil: [ ^ nil ].
	
	message := messageClass receiver: r selector: s arguments: (Array new: numArgs).
	1 to: numArgs do: [ :i |
		message argumentAt: i put: currentContext
	].
	
	^ message
]
