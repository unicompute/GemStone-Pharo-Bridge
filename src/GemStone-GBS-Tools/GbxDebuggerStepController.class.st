Class {
	#name : 'GbxDebuggerStepController',
	#superclass : 'Object',
	#instVars : [
		'service'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDebuggerStepController class >> on: aDebuggerService [
	^ self new
		service: aDebuggerService;
		yourself
]

{ #category : 'accessing' }
GbxDebuggerStepController >> service [
	^ service
]

{ #category : 'accessing' }
GbxDebuggerStepController >> service: aDebuggerService [
	service := aDebuggerService
]

{ #category : 'stepping' }
GbxDebuggerStepController >> step [
	| level before |
	before := service currentStepPoint.
	level := service effectiveServerStepLevel.
	level ifNil: [ level := 1 ].
	(service
		serverStepWithSelectorChain: #(step: stepIntoFromLevel: _stepIntoInFrame: gciStepIntoFromLevel:)
		level: level)
		ifTrue: [ ^ service normalizeExecutedCodeSingleStepFrom: before ].
	^ false
]

{ #category : 'stepping' }
GbxDebuggerStepController >> stepInto [
	| level before |
	before := service currentStepPoint.
	level := service effectiveServerStepLevel.
	level ifNil: [ level := 1 ].
	(service
		serverStepWithSelectorChain: #(stepIntoFromLevel: _stepIntoInFrame: gciStepIntoFromLevel: step:)
		level: level)
		ifTrue: [ ^ service normalizeExecutedCodeSingleStepFrom: before ].
	^ false
]

{ #category : 'stepping' }
GbxDebuggerStepController >> stepOver [
	| level before |
	before := service currentStepPoint.
	level := service effectiveServerStepLevel.
	level ifNil: [ level := 1 ].
	(service
		serverStepWithSelectorChain: #(stepOverFromLevel: _stepOverInFrame: gciStepOverFromLevel:)
		level: level)
		ifTrue: [ ^ service normalizeExecutedCodeSingleStepFrom: before ].
	^ false
]

{ #category : 'stepping' }
GbxDebuggerStepController >> stepReturn [
	(service runDebugProcessCommand: 'stepReturn' recompute: true)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'stepping' }
GbxDebuggerStepController >> stepUntilPC: stopPC [
	| steps |
	steps := 0.
	[ steps < 20 ] whileTrue: [
		| currentPC |
		currentPC := service currentStepPoint.
		(currentPC isNil or: [ currentPC >= stopPC ]) ifTrue: [ ^ true ].
		self stepOver ifFalse: [ ^ false ].
		steps := steps + 1 ].
	^ false
]
