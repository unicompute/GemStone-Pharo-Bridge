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
	currentContext ifNil: [ ^ false ].
	(currentContext respondsTo: #gbxIsServerContext)
		ifTrue: [ currentContext gbxIsServerContext ifFalse: [ ^ false ] ].
	(self selectedMethodSelector isNil or: [ self selectedMethodSelector = #unboundMethod ])
		ifTrue: [ ^ false ].
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
	| contextInspectorClass |
	currentContext ifNotNil: [
		contextInspectorClass := Smalltalk at: #GbxContextInspector ifAbsent: [ nil ].
		(contextInspectorClass notNil and: [ contextInspectorClass respondsTo: #openOn:service: ]) ifTrue: [
			[ contextInspectorClass openOn: currentContext service: self. ^ true ]
				on: Error
				do: [ ].
		]
	].
	^ self openInspectorOnOop: self currentFrameOop
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

	(self cutbackTo: theContext
		finishWith: [
			"Level numbers may have changed; recompute and select top server context."
			self selectTopServerContext
		]) ifFalse: [ ^ false ].

	^ true
]

{ #category : 'private' }
GbxDebuggerService >> ensureRestartAtStepOne [
	| step |
	(self isCurrentExecutedCodeFrame) ifFalse: [ ^ self ].
	step := self currentStepPoint ifNil: [ 1 ].
	step > 1 ifFalse: [ ^ self ].
	(self jumpToStepPoint: 1)
		ifFalse: [ self runToStepPoint: 1 ].
	self selectTopServerContext
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
	| lvl computed script result |
	lvl := (gsContext respondsTo: #level) ifTrue: [ gsContext level ] ifFalse: [ 1 ].
	((gsContext respondsTo: #isExecutedCodeFrame) and: [ gsContext isExecutedCodeFrame ]) ifTrue: [
		computed := self restartLevelFromServerStack.
		(computed isNumber and: [ computed > 0 ]) ifTrue: [ lvl := computed ].
	].
	
	script := '[
		| obj proc |
		obj := Object _objectForOop: ', processOop asString, '.
		proc := nil.
		(obj isNil or: [ obj = 20 ]) ifTrue: [ proc := GciSession current process ].
		proc isNil ifTrue: [
			(obj respondsTo: #serverProcess) ifTrue: [ proc := obj serverProcess ].
		].
		proc isNil ifTrue: [
			(obj respondsTo: #gbxResult) ifTrue: [ 
				| res | res := [ obj gbxResult ] on: Error do: [ nil ].
				(res notNil and: [ res respondsTo: #serverProcess ]) ifTrue: [ proc := res serverProcess ]
			].
		].
		proc isNil ifTrue: [ proc := obj ].
		
		(proc respondsTo: #_trimStackToLevel:) ifFalse: [ ^ ''false'' ].
		[ proc _trimStackToLevel: ', lvl asString, ' ] on: Error do: [ ^ ''false'' ].
		''true''
	] value'.

	result := self executeDebugScript: script.
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
	"Restart deterministically on the executed-code target when available,
	then enforce step-point 1."
	| target didRestart homeLevel |
	homeLevel := self restartLevelFromServerStack.
	(homeLevel isNumber and: [ homeLevel > 0 ]) ifTrue: [
		didRestart := self
			runDebugProcessCommand: '_trimStackToLevel'
			withInteger: homeLevel
			recompute: true.
		didRestart ifTrue: [
			self selectRestartTargetContext.
			self ensureRestartAtStepOne.
			self selectRestartTargetContext.
			^ true
		]
	].
	target := self restartTargetContext.
	target ifNotNil: [ self selectContext: target ].
	didRestart := self basicReenterServerContext.
	didRestart ifTrue: [
		self selectRestartTargetContext.
		self ensureRestartAtStepOne.
		self selectRestartTargetContext
	].
	^ didRestart
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
	| level |
	level := self effectiveServerStepLevel.
	level ifNil: [ level := 1 ].
	(self serverStepOverFrameLevel: (level bitOr: 16r100000000))
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'stepping' }
GbxDebuggerService >> stepOver [
	| level |
	level := self effectiveServerStepLevel.
	level ifNil: [ level := 1 ].
	(self serverStepOverFrameLevel: level)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'private' }
GbxDebuggerService >> effectiveServerStepLevel [
	| level resolved |
	level := self currentContextLevel.
	(self isCurrentExecutedCodeFrame not) ifTrue: [ ^ level ].
	resolved := self restartLevelFromServerStack.
	(resolved isNumber and: [ resolved > 0 ]) ifTrue: [ ^ resolved ].
	^ level
]

{ #category : 'private' }
GbxDebuggerService >> isCurrentExecutedCodeFrame [
	currentContext ifNil: [ ^ false ].
	^ (currentContext respondsTo: #isExecutedCodeFrame)
		and: [ currentContext isExecutedCodeFrame ]
]

{ #category : 'stepping' }
GbxDebuggerService >> stepReturn [
	"Step out of the current context (return to sender)"
	(self runDebugProcessCommand: 'stepReturn' recompute: true)
		ifTrue: [ ^ true ].
	^ false
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
