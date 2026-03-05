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
		'dontUpdateInspectors'
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

{ #category : 'initialization' }
GbxDebuggerService >> initialize [
	super initialize.
	tags := Set new.
	pendingEvents := OrderedCollection new.
	dontUpdateInspectors := false.
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

{ #category : 'accessing' }
GbxDebuggerService >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxDebuggerService >> processOop: anOop [
	processOop := anOop
]

{ #category : 'accessing' }
GbxDebuggerService >> processOop [
	^ processOop
]

{ #category : 'accessing' }
GbxDebuggerService >> session [
	^ session
]

{ #category : 'accessing' }
GbxDebuggerService >> label: aString [
	label := aString
]

{ #category : 'accessing' }
GbxDebuggerService >> label [
	^ label
]

{ #category : 'accessing' }
GbxDebuggerService >> contextStackPolicy [
	^ contextStackPolicy
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

{ #category : 'accessing' }
GbxDebuggerService >> topContext [
	"Best-effort client top context for mixed client/server stack logic."
	^ thisContext sender
]

{ #category : 'accessing' }
GbxDebuggerService >> contextList [
	^ contextStackPolicy contextList
]

{ #category : 'accessing' }
GbxDebuggerService >> glueIsHidden [
	^ contextStackPolicy glueIsHidden
]

{ #category : 'accessing' }
GbxDebuggerService >> glueIsHidden: aBoolean [
	contextStackPolicy glueIsHidden: aBoolean
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

{ #category : 'context list' }
GbxDebuggerService >> selectContext: aContext [
	"Select a specific context"
	currentContext == aContext ifTrue: [ ^ self ].
	currentContext := aContext.
	self updateSourceMapFromCurrentContext.
	self notifyContextChanged.
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
	self updateSourceMapFromCurrentContext.
	self notifyContextChanged.
]

{ #category : 'context list' }
GbxDebuggerService >> notifyContextChanged [
	"Notify that the context has changed"
	"UI update would happen here"
]

{ #category : 'context list' }
GbxDebuggerService >> updateStackList: aList [
	"Update the stack list in the UI"
	"Called by context policy"
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
GbxDebuggerService >> resume [
	"Resume execution of the debugged process"
	(self runDebugProcessCommand: 'resume' recompute: false)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'process control' }
GbxDebuggerService >> terminate [
	"Terminate the debugged process"
	(self runDebugProcessCommand: 'terminate' recompute: false)
		ifTrue: [ ^ true ].
	^ false
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

{ #category : 'source code' }
GbxDebuggerService >> sourceCode [
	"Get the source code for the current context"
	currentContext ifNil: [ ^ '' ].
	^ currentContext sourceCode
]

{ #category : 'evaluation' }
GbxDebuggerService >> gsDoIt: codeString [
	| raw |
	raw := self evaluateCodeInCurrentFrame: codeString.
	^ raw notNil and: [ (raw beginsWith: 'Error:') not ]
]

{ #category : 'evaluation' }
GbxDebuggerService >> gsPrintIt: codeString [
	| script |
	codeString ifNil: [ ^ nil ].
	script := '[ ', codeString, ' ] value printString'.
	^ self evaluateCodeInCurrentFrame: script
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

{ #category : 'evaluation' }
GbxDebuggerService >> currentExecutionContextOop [
	| frameOop |
	frameOop := self currentFrameOop.
	(frameOop isNumber and: [ frameOop > 20 ]) ifTrue: [ ^ frameOop ].
	((self currentProcessOop) isNumber and: [ self currentProcessOop > 20 ]) ifTrue: [ ^ self currentProcessOop ].
	^ nil
]

{ #category : 'evaluation' }
GbxDebuggerService >> recompileCurrentMethodWithSource: sourceText [
	| className selector isMeta classLookupName escapedSource script raw |
	currentContext ifNil: [ ^ false ].
	self isSessionUsable ifFalse: [ ^ false ].
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
	^ raw = 'OK'
]

{ #category : 'private' }
GbxDebuggerService >> escapeForScriptLiteral: aString [
	| s |
	s := aString ifNil: [ '' ] ifNotNil: [ :txt | txt asString ].
	s := s copyReplaceAll: String cr with: String lf.
	^ s copyReplaceAll: '''' with: ''''''
]

{ #category : 'source code' }
GbxDebuggerService >> sourceMap [
	"Get the source map for highlighting"
	currentContext ifNil: [ sourceMap := #( ). ^ sourceMap ].
	sourceMap ifNil: [ self updateSourceMapFromCurrentContext ].
	^ sourceMap
]

{ #category : 'source code' }
GbxDebuggerService >> updateSourceMapFromCurrentContext [
	sourceMap := currentContext
		ifNil: [ #( ) ]
		ifNotNil: [
			[ currentContext visibleSourceMap ] on: Error do: [ #( ) ]
		]
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

{ #category : 'variables' }
GbxDebuggerService >> tempNamesAndValues [
	"Get temp variable names and values for current context"
	currentContext ifNil: [ ^ #( ) ].
	^ currentContext tempNamesAndValues
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

{ #category : 'inspector' }
GbxDebuggerService >> inspectorClass [
	^ GbsInspector
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
GbxDebuggerService >> inspectCurrentFrame [
	^ self openInspectorOnOop: self currentFrameOop
]

{ #category : 'inspector' }
GbxDebuggerService >> inspectVariableNamed: aVariableName [
	| variableName |
	(aVariableName isString and: [ aVariableName isEmpty not ]) ifFalse: [ ^ false ].
	variableName := aVariableName withBlanksTrimmed.
	variableName isEmpty ifTrue: [ ^ false ].
	^ self openInspectorOnOop: (self oopForVariableNamed: variableName)
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
GbxDebuggerService >> currentContextLevel [
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #level) ifTrue: [ ^ currentContext level ].
	^ nil
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
GbxDebuggerService >> canExecuteOnDebugProcess [
	(self isSessionUsable and: [ processOop isNumber ]) ifFalse: [ ^ false ].
	^ processOop > 20
]

{ #category : 'private' }
GbxDebuggerService >> isSessionUsable [
	| loggedIn |
	session ifNil: [ ^ false ].
	(session respondsTo: #isLoggedIn) ifFalse: [ ^ true ].
	loggedIn := [ session isLoggedIn ] on: Error do: [ false ].
	^ loggedIn = true
]

{ #category : 'private' }
GbxDebuggerService >> executeDebugScript: scriptString [
	self isSessionUsable ifFalse: [ ^ nil ].
	^ [ session executeAndFetch: scriptString context: session sessionOop ]
		on: Error
		do: [ nil ]
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
GbxDebuggerService >> asBooleanResult: raw default: defaultBoolean [
	raw ifNil: [ ^ defaultBoolean ].
	raw = true ifTrue: [ ^ true ].
	raw = false ifTrue: [ ^ false ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	(raw respondsTo: #asString) ifFalse: [ ^ defaultBoolean ].
	raw := raw asString asLowercase.
	(#('true' '1' 'yes' 'ok') includes: raw) ifTrue: [ ^ true ].
	(#('false' '0' 'no' 'nil' '') includes: raw) ifTrue: [ ^ false ].
	^ defaultBoolean
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> currentBreakPointList [
	"Get breakpoints for current session"
	| klass |
	klass := self breakpointClass.
	klass ifNil: [ ^ #( ) ].
	^ klass breakPointListFor: session
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

{ #category : 'breakpoint support' }
GbxDebuggerService >> removeBreakPoint [
	"Remove breakpoint at current location"
	^ self removeBreakIn: nil
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
GbxDebuggerService >> removeAllBreakPoints [
	"Remove all breakpoints in selected method"
	| bps |
	bps := self breakpointsInSelectedMethod.
	bps do: [ :bp | bp clear ].
	^ bps size
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointClass [
	^ Smalltalk at: #GbxBreakPoint ifAbsent: [ nil ]
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> browserClass [
	^ Smalltalk at: #GbxBrowser ifAbsent: [ nil ]
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
GbxDebuggerService >> canSetBreakPoint [
	^ self canManageBreakPoints and: [ (self hasBreakPointIn: nil) not ]
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canRemoveBreakPoint [
	^ self hasBreakPointIn: nil
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canRemoveAllBreakPoints [
	^ self breakpointsInSelectedMethod isNotEmpty
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canToggleBreakPoint [
	^ self canManageBreakPoints
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> selectedMethodSelector [
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #selectorOrUnknown) ifTrue: [ ^ currentContext selectorOrUnknown ].
	(currentContext respondsTo: #selector) ifTrue: [ ^ currentContext selector ].
	^ nil
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> selectedMethodClassName [
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #methodClassOrUnknown) ifTrue: [ ^ currentContext methodClassOrUnknown ].
	(currentContext respondsTo: #methodClass) ifTrue: [ ^ currentContext methodClass ].
	^ nil
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

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpoint: aBreakPoint matchesSelection: anInterval [
	| offset |
	offset := self sourceOffsetForBreakPoint: aBreakPoint.
	offset ifNil: [ ^ false ].
	^ anInterval first <= offset and: [ anInterval last >= offset ]
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
GbxDebuggerService >> canResume [
	^ self isTerminated not
]

{ #category : 'testing' }
GbxDebuggerService >> canTerminate [
	^ self isTerminated not
]

{ #category : 'private' }
GbxDebuggerService >> toggleGlueHiding [
	"Toggle visibility of GBS glue contexts"
	self glueIsHidden: self glueIsHidden not.
	self recomputeContextList.
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
