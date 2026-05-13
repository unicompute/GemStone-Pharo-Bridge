Class {
	#name : 'GbsRemoteDebuggerInspectorActions',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerInspectorActions class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'testing' }
GbsRemoteDebuggerInspectorActions >> canInspectFrame [
	^ debugger safeServiceCall: [
		(self service respondsTo: #canInspectCurrentFrame)
			ifTrue: [ self service canInspectCurrentFrame ]
			ifFalse: [ true ] ] default: false
]

{ #category : 'testing' }
GbsRemoteDebuggerInspectorActions >> canInspectProcess [
	^ debugger safeServiceCall: [
		(self service respondsTo: #canInspectCurrentProcess)
			ifTrue: [ self service canInspectCurrentProcess ]
			ifFalse: [ true ] ] default: false
]

{ #category : 'testing' }
GbsRemoteDebuggerInspectorActions >> canInspectReceiver [
	^ debugger safeServiceCall: [
		(self service respondsTo: #canInspectCurrentReceiver)
			ifTrue: [ self service canInspectCurrentReceiver ]
			ifFalse: [ true ] ] default: false
]

{ #category : 'testing' }
GbsRemoteDebuggerInspectorActions >> canInspectStack [
	^ self canInspectFrame
]

{ #category : 'testing' }
GbsRemoteDebuggerInspectorActions >> canInspectVariable [
	^ debugger selectedVariableName notNil
]

{ #category : 'accessing' }
GbsRemoteDebuggerInspectorActions >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerInspectorActions >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'actions' }
GbsRemoteDebuggerInspectorActions >> inspectFrame [
	(self openInspectorClassNamed: #GbxContextInspector) ifTrue: [ ^ true ].
	^ debugger safeServiceCall: [ self service inspectCurrentFrame ] default: false
]

{ #category : 'actions' }
GbsRemoteDebuggerInspectorActions >> inspectProcess [
	^ debugger safeServiceCall: [ self service inspectCurrentProcess ] default: false
]

{ #category : 'actions' }
GbsRemoteDebuggerInspectorActions >> inspectReceiver [
	(self openInspectorClassNamed: #GbxReceiverInspector) ifTrue: [ ^ true ].
	^ debugger safeServiceCall: [ self service inspectCurrentReceiver ] default: false
]

{ #category : 'actions' }
GbsRemoteDebuggerInspectorActions >> inspectStack [
	(self openInspectorClassNamed: #GbxStackInspector) ifTrue: [ ^ true ].
	^ self inspectFrame
]

{ #category : 'actions' }
GbsRemoteDebuggerInspectorActions >> inspectVariable [
	| variableName |
	self service ifNil: [ ^ false ].
	variableName := debugger selectedVariableName.
	variableName ifNil: [ ^ false ].
	(self service respondsTo: #inspectVariableNamed:)
		ifTrue: [
			^ debugger
				safeServiceCall: [ self service inspectVariableNamed: variableName ]
				default: false ].
	^ false
]

{ #category : 'private' }
GbsRemoteDebuggerInspectorActions >> openInspectorClassNamed: classSymbol [
	| inspectorClass context |
	inspectorClass := Smalltalk at: classSymbol ifAbsent: [ nil ].
	inspectorClass ifNil: [ ^ false ].
	(inspectorClass respondsTo: #openOn:service:) ifFalse: [ ^ false ].
	context := debugger selectedContextForInspector.
	context ifNil: [ ^ false ].
	^ [ inspectorClass openOn: context service: self service. true ]
		on: Error
		do: [ false ]
]

{ #category : 'accessing' }
GbsRemoteDebuggerInspectorActions >> service [
	^ debugger service
]
