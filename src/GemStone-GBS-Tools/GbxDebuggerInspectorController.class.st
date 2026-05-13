Class {
	#name : 'GbxDebuggerInspectorController',
	#superclass : 'Object',
	#instVars : [
		'service'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDebuggerInspectorController class >> on: aService [
	^ self new
		service: aService;
		yourself
]

{ #category : 'testing' }
GbxDebuggerInspectorController >> canInspectCurrentFrame [
	^ self currentContext isNotNil
]

{ #category : 'testing' }
GbxDebuggerInspectorController >> canInspectCurrentProcess [
	^ self currentContext isNotNil
]

{ #category : 'testing' }
GbxDebuggerInspectorController >> canInspectCurrentReceiver [
	^ self currentContext isNotNil
]

{ #category : 'accessing' }
GbxDebuggerInspectorController >> currentContext [
	^ service currentContext
]

{ #category : 'accessing' }
GbxDebuggerInspectorController >> currentContextLevel [
	self currentContext ifNil: [ ^ nil ].
	(self currentContext respondsTo: #level) ifTrue: [ ^ self currentContext level ].
	^ nil
]

{ #category : 'accessing' }
GbxDebuggerInspectorController >> currentExecutionContextOop [
	| frameOop processOop |
	frameOop := self currentFrameOop.
	(frameOop isNumber and: [ frameOop > 20 ]) ifTrue: [ ^ frameOop ].
	processOop := self currentProcessOop.
	(processOop isNumber and: [ processOop > 20 ]) ifTrue: [ ^ processOop ].
	^ nil
]

{ #category : 'accessing' }
GbxDebuggerInspectorController >> currentFrameOop [
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

{ #category : 'accessing' }
GbxDebuggerInspectorController >> currentProcessOop [
	self currentContext ifNil: [ ^ nil ].
	(self currentContext respondsTo: #processOop) ifTrue: [ ^ self currentContext processOop ].
	(self currentContext respondsTo: #process) ifTrue: [ ^ self currentContext process ].
	^ nil
]

{ #category : 'accessing' }
GbxDebuggerInspectorController >> currentReceiverOop [
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

{ #category : 'evaluation' }
GbxDebuggerInspectorController >> evaluateCodeInCurrentFrame: codeString [
	| contextOop raw |
	(codeString isString and: [ codeString isEmpty not ]) ifFalse: [ ^ nil ].
	service isSessionUsable ifFalse: [ ^ nil ].
	contextOop := self currentExecutionContextOop.
	contextOop ifNil: [ ^ nil ].
	raw := [ service fetchRemoteScript: codeString context: contextOop ] on: Error do: [ nil ].
	raw ifNil: [ ^ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	^ raw
]

{ #category : 'evaluation' }
GbxDebuggerInspectorController >> evaluateOopFromScript: scriptString [
	| raw |
	service isSessionUsable ifFalse: [ ^ nil ].
	raw := [ service fetchRemoteScript: scriptString context: 20 ] on: Error do: [ nil ].
	raw ifNil: [ ^ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	(raw isString and: [ raw = 'nil' or: [ raw beginsWith: 'Error:' ] ]) ifTrue: [ ^ nil ].
	^ [ raw asInteger ] on: Error do: [ nil ]
]

{ #category : 'inspecting' }
GbxDebuggerInspectorController >> inspectCurrentFrame [
	| oop contextInspectorClass |
	oop := self currentFrameOop.
	(self openInspectorOnOop: oop) ifTrue: [ ^ true ].
	self currentContext ifNotNil: [
		contextInspectorClass := Smalltalk at: #GbxContextInspector ifAbsent: [ nil ].
		(contextInspectorClass notNil and: [ contextInspectorClass respondsTo: #openOn:service: ]) ifTrue: [
			[ contextInspectorClass openOn: self currentContext service: service. ^ true ]
				on: Error
				do: [ ].
		]
	].
	^ false
]

{ #category : 'inspecting' }
GbxDebuggerInspectorController >> inspectCurrentProcess [
	^ self openInspectorOnOop: self currentProcessOop
]

{ #category : 'inspecting' }
GbxDebuggerInspectorController >> inspectCurrentReceiver [
	^ self openInspectorOnOop: self currentReceiverOop
]

{ #category : 'inspecting' }
GbxDebuggerInspectorController >> inspectVariableNamed: aVariableName [
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

{ #category : 'inspecting' }
GbxDebuggerInspectorController >> inspectorClass [
	^ service inspectorClass
]

{ #category : 'inspecting' }
GbxDebuggerInspectorController >> oopForVariableNamed: aVariableName [
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

{ #category : 'inspecting' }
GbxDebuggerInspectorController >> openInspectorOnOop: anOop [
	| contextOop inspectorKlass |
	service isSessionUsable ifFalse: [ ^ false ].
	(anOop isNil or: [ anOop <= 20 ]) ifTrue: [ ^ false ].
	inspectorKlass := self inspectorClass.
	contextOop := self currentExecutionContextOop.
	[
		(inspectorKlass respondsTo: #inspect:session:context:)
			ifTrue: [ inspectorKlass inspect: anOop session: service session context: contextOop ]
			ifFalse: [ inspectorKlass inspect: anOop session: service session ].
		^ true
	] on: Error do: [ :ex |
		^ false
	]
]

{ #category : 'inspecting' }
GbxDebuggerInspectorController >> openInspectors [
	Smalltalk at: #GbxContextInspector ifAbsent: [ ^ self ].
	self canInspectCurrentReceiver ifTrue: [ self inspectCurrentReceiver ].
	self canInspectCurrentFrame ifTrue: [ self inspectCurrentFrame ].
	self canInspectCurrentProcess ifTrue: [ self inspectCurrentProcess ]
]

{ #category : 'accessing' }
GbxDebuggerInspectorController >> service [
	^ service
]

{ #category : 'accessing' }
GbxDebuggerInspectorController >> service: aService [
	service := aService
]
