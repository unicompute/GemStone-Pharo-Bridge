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
	| script |
	
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc step.
		true
	] value'.
	
	session executeAndFetch: script context: session sessionOop.
	self recomputeContextList.
]

{ #category : 'stepping' }
GbxDebuggerService >> stepOver [
	"Step over the next message send (step through without entering)"
	| script |
	
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc stepOver.
		true
	] value'.
	
	session executeAndFetch: script context: session sessionOop.
	self recomputeContextList.
]

{ #category : 'stepping' }
GbxDebuggerService >> stepReturn [
	"Step out of the current context (return to sender)"
	| script |
	
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc stepReturn.
		true
	] value'.
	
	session executeAndFetch: script context: session sessionOop.
	self recomputeContextList.
]

{ #category : 'process control' }
GbxDebuggerService >> resume [
	"Resume execution of the debugged process"
	| script |
	
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc resume.
		true
	] value'.
	
	[ session executeAndFetch: script context: session sessionOop ] 
		on: Error 
		do: [ :ex | ].
]

{ #category : 'process control' }
GbxDebuggerService >> terminate [
	"Terminate the debugged process"
	| script |
	
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc terminate.
		true
	] value'.
	
	[ session executeAndFetch: script context: session sessionOop ] 
		on: Error 
		do: [ :ex | ].
]

{ #category : 'process control' }
GbxDebuggerService >> isTerminated [
	"Check if the debugged process is terminated"
	| script result |
	
	script := '[
		| proc |
		proc := Object _objectForOop: ', processOop asString, '.
		proc isTerminated
	] value'.
	
	result := session executeAndFetch: script context: session sessionOop.
	^ result = 'true'
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

{ #category : 'source code' }
GbxDebuggerService >> updateSourceMapFromCurrentContext [
	sourceMap := currentContext
		ifNil: [ #( ) ]
		ifNotNil: [
			[ currentContext visibleSourceMap ] on: Error do: [ #( ) ]
		]
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
GbxDebuggerService >> openInspectorOnOop: anOop [
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
GbxDebuggerService >> evaluateOopFromScript: scriptString [
	| raw |
	raw := [ session executeAndFetch: scriptString context: session sessionOop ] on: Error do: [ nil ].
	raw ifNil: [ ^ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	(raw isString and: [ raw = 'nil' or: [ raw beginsWith: 'Error:' ] ]) ifTrue: [ ^ nil ].
	^ [ raw asInteger ] on: Error do: [ nil ]
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> currentBreakPointList [
	"Get breakpoints for current session"
	^ self breakpointClass breakPointListFor: session
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
	(self canManageBreakPoints) ifFalse: [ ^ false ].

	self browserClass
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
	^ GbxBreakPoint
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> browserClass [
	^ GbxBrowser
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
	^ self canManageBreakPoints
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canRemoveBreakPoint [
	^ self breakpointsInSelectedMethod isNotEmpty
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> canRemoveAllBreakPoints [
	^ self breakpointsInSelectedMethod isNotEmpty
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
	| selection |
	selection := self selectionIntervalForTextWidget: aTextWidget.
	selection ifNil: [ ^ breakpoints first ].
	^ breakpoints
		detect: [ :bp | self breakpoint: bp matchesSelection: selection ]
		ifNone: [ nil ]
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
