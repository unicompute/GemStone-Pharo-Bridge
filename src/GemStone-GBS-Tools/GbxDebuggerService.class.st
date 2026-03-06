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

{ #category : 'breakpoint support' }
GbxDebuggerService >> canSetBreakPoint [
	^ self canManageBreakPoints and: [ (self hasBreakPointIn: nil) not ]
]

{ #category : 'testing' }
GbxDebuggerService >> canStepInto [
	^ currentContext isNotNil and: [ self isTerminated not ]
]

{ #category : 'testing' }
GbxDebuggerService >> canStepOver [
	^ currentContext isNotNil and: [ self isTerminated not ]
]

{ #category : 'testing' }
GbxDebuggerService >> canStepReturn [
	^ currentContext isNotNil and: [ self isTerminated not ]
]

{ #category : 'testing' }
GbxDebuggerService >> canTerminate [
	^ self isTerminated not
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
		entry := map
			detect: [ :assoc | (assoc respondsTo: #key) and: [ assoc key = stepPoint ] ]
			ifNone: [ nil ].
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
	raw := [ session executeAndFetch: scriptString context: session sessionOop ] on: Error do: [ nil ].
	raw ifNil: [ ^ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	(raw isString and: [ raw = 'nil' or: [ raw beginsWith: 'Error:' ] ]) ifTrue: [ ^ nil ].
	^ [ raw asInteger ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbxDebuggerService >> executeDebugScript: scriptString [
	self isSessionUsable ifFalse: [ ^ nil ].
	^ [ session executeAndFetch: scriptString context: session sessionOop ]
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
	self isSessionUsable ifFalse: [ ^ false ].
	(anOop isNil or: [ anOop <= 20 ]) ifTrue: [ ^ false ].
	[
		self inspectorClass inspect: anOop session: session.
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
	"Recompute the context list after a step operation"
	contextStackPolicy computeContextList.
	
	"If current context is no longer valid, select top"
	(currentContext isNil or: [ 
		(contextStackPolicy contextList includes: currentContext) not 
	]) ifTrue: [
		contextStackPolicy contextList ifNotEmpty: [ :contexts |
			currentContext := contexts first.
		].
	].
	(restartHomeResetPasses isNumber and: [ restartHomeResetPasses > 0 ]) ifTrue: [
		self selectRestartTargetContext.
		self forceRestartPositionToMethodStart.
		restartHomeResetPasses := restartHomeResetPasses - 1
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
GbxDebuggerService >> restart [
	"Restart/reenter execution at the selected frame.
	Prefer level-aware selectors (VW-like reenter semantics), then fall back."
	| lvl script result stepAfter didResetWithStepPoint |
	(self canExecuteOnDebugProcess) ifFalse: [ ^ false ].
	lvl := self currentContextLevel.
	lvl ifNil: [ lvl := 1 ].

	script := '[
		| proc frameObj frameOop level ok tryOn |
		proc := Object _objectForOop: ', processOop asString, '.
		proc ifNil: [ ^ ''false'' ].
		level := ', lvl asString, '.
		frameObj := [ proc _frameContentsAt: level ] on: Error do: [ nil ].
		frameOop := frameObj ifNil: [ nil ] ifNotNil: [ [ Reflection oopOf: frameObj ] on: Error do: [ nil ] ].
		ok := false.

		tryOn := [ :target :sel :args |
			| cm |
			(ok or: [ target isNil ]) ifTrue: [ ^ nil ].
			(target respondsTo: sel) ifFalse: [ ^ nil ].
			cm := [ target class compiledMethodAt: sel ] on: Error do: [ nil ].
			cm ifNil: [ ^ nil ].
			(cm numArgs = args size) ifFalse: [ ^ nil ].
			[ target perform: sel withArguments: args. ok := true ] on: Error do: [ ].
		].

		"Most specific first (VW reenter/cutback intent)."
		tryOn value: proc value: #reenterAtLevel: value: (Array with: level).
		tryOn value: proc value: #restartAtLevel: value: (Array with: level).
		tryOn value: proc value: #reenterFrame: value: (Array with: level).
		tryOn value: proc value: #restartFrame: value: (Array with: level).
		tryOn value: proc value: #reenter: value: (Array with: level).
		tryOn value: proc value: #restartAt: value: (Array with: level).
		tryOn value: proc value: #reenterAt: value: (Array with: level).
		tryOn value: proc value: #cutbackTo: value: (Array with: level).
		tryOn value: proc value: #cutBackTo: value: (Array with: level).
		tryOn value: proc value: #cutbackToFrame: value: (Array with: level).
		tryOn value: proc value: #cutBackToFrame: value: (Array with: level).
		tryOn value: proc value: #_cutbackToFrame: value: (Array with: level).
		tryOn value: proc value: #_cutBackToFrame: value: (Array with: level).

		frameOop ifNotNil: [
			tryOn value: proc value: #reenterFrame: value: (Array with: frameOop).
			tryOn value: proc value: #restartFrame: value: (Array with: frameOop).
			tryOn value: proc value: #reenterAt: value: (Array with: frameOop).
			tryOn value: proc value: #restartAt: value: (Array with: frameOop).
			tryOn value: proc value: #cutbackTo: value: (Array with: frameOop).
			tryOn value: proc value: #cutBackTo: value: (Array with: frameOop).
			tryOn value: proc value: #cutbackToFrame: value: (Array with: frameOop).
			tryOn value: proc value: #cutBackToFrame: value: (Array with: frameOop).
			tryOn value: proc value: #_cutbackToFrame: value: (Array with: frameOop).
			tryOn value: proc value: #_cutBackToFrame: value: (Array with: frameOop)
		].

		frameObj ifNotNil: [
			tryOn value: frameObj value: #reenter value: #().
			tryOn value: frameObj value: #restart value: #().
			tryOn value: frameObj value: #reenterAtLevel: value: (Array with: level).
			tryOn value: frameObj value: #restartAtLevel: value: (Array with: level)
		].

		ok ifFalse: [
			tryOn value: proc value: #reenter value: #().
			tryOn value: proc value: #restart value: #()
		].

		ok ifTrue: [ ''true'' ] ifFalse: [ ''false'' ]
	] value'.

	result := self executeDebugScript: script.
	(self asBooleanResult: result default: false) ifFalse: [ ^ false ].
	restartHomeResetPasses := 2.
	self recomputeContextList.
	stepAfter := self currentStepPoint.
	didResetWithStepPoint := false.
	(stepAfter isNil or: [ stepAfter > 1 ]) ifTrue: [
		didResetWithStepPoint := (self runDebugProcessCommand: 'jumpToStepPoint' withInteger: 1 recompute: true)
			or: [ self runDebugProcessCommand: 'runToStepPoint' withInteger: 1 recompute: true ]
	].
	(stepAfter isNil or: [ stepAfter > 1 ]) ifTrue: [
		didResetWithStepPoint
			ifFalse: [
				restartHomeResetPasses := restartHomeResetPasses max: 2.
				self recomputeContextList
			]
	].
	^ true
]

{ #category : 'private' }
GbxDebuggerService >> forceRestartPositionToMethodStart [
	| target |
	target := self restartTargetContext.
	target ifNil: [ ^ self ].
	(target respondsTo: #quickStepPoint:)
		ifTrue: [ target quickStepPoint: 1 ].
	(target respondsTo: #ipOffset:)
		ifTrue: [ target ipOffset: 1 ].
	(target respondsTo: #sourceOffsets) ifTrue: [
		| offsets |
		offsets := target sourceOffsets.
		(offsets isCollection and: [ offsets isEmpty not ]) ifTrue: [
			(target respondsTo: #sourceOffsets:)
				ifTrue: [
					| copy |
					copy := offsets asArray copy.
					copy at: 1 put: ((copy at: 1 ifAbsent: [ 1 ]) ifNil: [ 1 ]).
					target sourceOffsets: copy
				]
		]
	].
]

{ #category : 'private' }
GbxDebuggerService >> restartTargetContext [
	| contexts |
	contexts := self contextList.
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

{ #category : 'private' }
GbxDebuggerService >> runDebugProcessCommand: commandName recompute: shouldRecompute [
	| result script |
	(self canExecuteOnDebugProcess) ifFalse: [ ^ false ].
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc ifNil: [ ^ ''false'' ].
		proc ', commandName, '.
		true
	] value'.
	result := self executeDebugScript: script.
	(self asBooleanResult: result default: false) ifFalse: [ ^ false ].
	shouldRecompute ifTrue: [ self recomputeContextList ].
	^ true
]

{ #category : 'private' }
GbxDebuggerService >> runDebugProcessCommand: commandName withInteger: anInteger recompute: shouldRecompute [
	| result script |
	(self canExecuteOnDebugProcess) ifFalse: [ ^ false ].
	anInteger ifNil: [ ^ false ].
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc ifNil: [ ^ ''false'' ].
		[ proc perform: #', commandName, ': with: ', anInteger asString, ' ] on: Error do: [ ^ ''false'' ].
		true
	] value'.
	result := self executeDebugScript: script.
	(self asBooleanResult: result default: false) ifFalse: [ ^ false ].
	shouldRecompute ifTrue: [ self recomputeContextList ].
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
	"Step into the next message send"
	(self runDebugProcessCommand: 'step' recompute: true)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'stepping' }
GbxDebuggerService >> stepOver [
	"Step over the next message send (step through without entering)"
	(self runDebugProcessCommand: 'stepOver' recompute: true)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'stepping' }
GbxDebuggerService >> stepReturn [
	"Step out of the current context (return to sender)"
	(self runDebugProcessCommand: 'stepReturn' recompute: true)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'process control' }
GbxDebuggerService >> pause [
	"Best effort: interrupt the active GemStone session."
	self isSessionUsable ifFalse: [ ^ false ].
	^ [ 
		(session respondsTo: #sendInterrupt)
			ifTrue: [ session sendInterrupt. true ]
			ifFalse: [ false ]
	] on: Error do: [ false ]
]

{ #category : 'process control' }
GbxDebuggerService >> runToStepPoint: aStepPoint [
	(self runDebugProcessCommand: 'runToStepPoint' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	(self runDebugProcessCommand: 'runTo' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'process control' }
GbxDebuggerService >> jumpToStepPoint: aStepPoint [
	(self runDebugProcessCommand: 'jumpToStepPoint' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	(self runDebugProcessCommand: 'jumpTo' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	^ false
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
		]
]

{ #category : 'context list' }
GbxDebuggerService >> updateStackList: aList [
	"Update the stack list in the UI"
	"Called by context policy"
]
