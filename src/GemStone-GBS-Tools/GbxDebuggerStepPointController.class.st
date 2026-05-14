Class {
	#name : 'GbxDebuggerStepPointController',
	#superclass : 'Object',
	#instVars : [
		'service'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDebuggerStepPointController class >> on: aDebuggerService [
	^ self new
		service: aDebuggerService;
		yourself
]

{ #category : 'step points' }
GbxDebuggerStepPointController >> basicJumpToCaret [
	| targetStepPoint |
	targetStepPoint := self earliestSelectedStepPoint.
	targetStepPoint ifNil: [ ^ false ].
	^ service jumpToStepPoint: targetStepPoint
]

{ #category : 'step points' }
GbxDebuggerStepPointController >> basicSkipToCaret [
	| targetStepPoint |
	targetStepPoint := self earliestSelectedStepPoint.
	targetStepPoint ifNil: [ ^ false ].
	^ service runToStepPoint: targetStepPoint
]

{ #category : 'step points' }
GbxDebuggerStepPointController >> closestLeftStepPoint [
	| map currentStep candidates |
	map := service sourceMap.
	map ifEmpty: [ ^ nil ].
	currentStep := service currentStepPoint.
	currentStep ifNil: [ ^ nil ].
	candidates := map select: [ :assoc |
		(assoc respondsTo: #key) and: [
			assoc key isNumber and: [ assoc key < currentStep ] ] ].
	candidates ifEmpty: [ ^ nil ].
	^ (candidates collect: [ :assoc | assoc key ]) max
]

{ #category : 'step points' }
GbxDebuggerStepPointController >> closestRightStepPoint [
	| map currentStep candidates |
	map := service sourceMap.
	map ifEmpty: [ ^ nil ].
	currentStep := service currentStepPoint.
	currentStep ifNil: [ ^ nil ].
	candidates := map select: [ :assoc |
		(assoc respondsTo: #key) and: [
			assoc key isNumber and: [ assoc key > currentStep ] ] ].
	candidates ifEmpty: [ ^ nil ].
	^ (candidates collect: [ :assoc | assoc key ]) min
]

{ #category : 'step points' }
GbxDebuggerStepPointController >> currentSourceSelectionInterval [
	| map stepPoint entry |
	map := service sourceMap.
	(map isCollection and: [ map isEmpty not ]) ifFalse: [
		service selectionRange: nil.
		^ nil ].
	stepPoint := self currentStepPoint.
	stepPoint ifNotNil: [
		entry := map
			detect: [ :assoc | (assoc respondsTo: #key) and: [ assoc key = stepPoint ] ]
			ifNone: [ nil ].
		entry ifNil: [
			| candidates maxKey |
			candidates := map select: [ :assoc | (assoc respondsTo: #key) and: [ assoc key <= stepPoint ] ].
			maxKey := ((map collect: [ :assoc | assoc key ]) select: [ :k | k isNumber ])
				ifEmpty: [ nil ]
				ifNotEmpty: [ :keys | keys max ].
			(candidates isNotEmpty and: [ maxKey isNumber and: [ stepPoint <= maxKey ] ])
				ifTrue: [ entry := candidates last ] ].
		entry ifNotNil: [
			service selectionRange: entry value.
			^ service selectionRange ] ].
	service selectionRange: map first value.
	^ service selectionRange
]

{ #category : 'step points' }
GbxDebuggerStepPointController >> currentStepPoint [
	| raw context |
	context := service currentContext.
	context ifNil: [ ^ nil ].
	raw := (context respondsTo: #stepPoint)
		ifTrue: [ context stepPoint ]
		ifFalse: [
			(context respondsTo: #quickStepPoint)
				ifTrue: [ context quickStepPoint ]
				ifFalse: [ nil ] ].
	raw ifNil: [ ^ nil ].
	raw := [ raw asInteger ] on: Error do: [ nil ].
	(raw isNil or: [ raw <= 0 ]) ifTrue: [ ^ nil ].
	^ raw
]

{ #category : 'step points' }
GbxDebuggerStepPointController >> earliestOverlappingStepPoint [
	| map selection selectionStart selectionEnd |
	map := service sourceMap.
	map ifEmpty: [ ^ nil ].
	selection := service selectionRange.
	selection ifNil: [ ^ nil ].
	selectionStart := selection first.
	selectionEnd := selection last.
	map do: [ :assoc |
		(assoc respondsTo: #key) and: [
			(assoc respondsTo: #value) and: [
				assoc value isInterval and: [
					assoc value first <= selectionEnd and: [
						assoc value last >= selectionStart ] ] ] ]
			ifTrue: [ ^ assoc key ] ].
	^ nil
]

{ #category : 'step points' }
GbxDebuggerStepPointController >> earliestSelectedStepPoint [
	| stepPoint |
	stepPoint := self earliestOverlappingStepPoint.
	stepPoint ifNotNil: [ ^ stepPoint ].
	stepPoint := self closestRightStepPoint.
	stepPoint ifNil: [ stepPoint := self closestLeftStepPoint ].
	^ stepPoint
]

{ #category : 'step points' }
GbxDebuggerStepPointController >> effectiveServerStepLevel [
	| level resolved step |
	level := service currentContextLevel.
	(service isCurrentExecutedCodeFrame and: [ (step := service currentStepPoint) = 1 ]) ifTrue: [ ^ 1 ].
	(level isNumber and: [ level > 0 ]) ifTrue: [ ^ level ].
	service isCurrentExecutedCodeFrame ifFalse: [ ^ level ].
	resolved := service restartLevelFromServerStack.
	(resolved isNumber and: [ resolved > 0 ]) ifTrue: [ ^ resolved ].
	^ level
]

{ #category : 'accessing' }
GbxDebuggerStepPointController >> service [
	^ service
]

{ #category : 'accessing' }
GbxDebuggerStepPointController >> service: aDebuggerService [
	service := aDebuggerService
]
