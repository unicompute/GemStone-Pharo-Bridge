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
		self notifyContextChanged.
	].
]

{ #category : 'context list' }
GbxDebuggerService >> selectContext: aContext [
	"Select a specific context"
	currentContext == aContext ifTrue: [ ^ self ].
	currentContext := aContext.
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
	currentContext ifNil: [ ^ #( ) ].
	^ currentContext visibleSourceMap
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

{ #category : 'breakpoint support' }
GbxDebuggerService >> currentBreakPointList [
	"Get breakpoints for current session"
	^ GbxBreakPoint breakPointListFor: session
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> breakpointsInSelectedMethod [
	"Get breakpoints in the currently selected method"
	| selector className |
	currentContext ifNil: [ ^ #( ) ].
	selector := currentContext selector.
	className := currentContext methodClass.
	
	^ self currentBreakPointList select: [ :bp |
		bp selector = selector and: [ bp remoteClass = className ]
	]
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> setBreakPoint [
	"Set a breakpoint at the current location"
	currentContext ifNil: [ ^ self ].
	
	GbxBrowser
		setBreakInView: nil  "Would need text widget reference"
		model: currentContext
		method: currentContext selector
		class: currentContext methodClass.
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> removeBreakPoint [
	"Remove breakpoint at current location"
	self breakpointsInSelectedMethod do: [ :bp | bp clear ].
]

{ #category : 'breakpoint support' }
GbxDebuggerService >> removeAllBreakPoints [
	"Remove all breakpoints in selected method"
	self breakpointsInSelectedMethod do: [ :bp | bp clear ].
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
