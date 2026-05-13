Class {
	#name : 'GbsRemoteDebuggerContextPresenter',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerContextPresenter class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'presenting' }
GbsRemoteDebuggerContextPresenter >> contextSelected: selectedItem [
	| context sourceCode variables associations |

	selectedItem ifNil: [ ^ self ].
	context := selectedItem.
	(context respondsTo: #sourceCode) ifFalse: [
		| index |
		index := (self stackList respondsTo: #selectedIndex)
			ifTrue: [ self stackList selectedIndex ifNil: [ 0 ] ]
			ifFalse: [ 0 ].
		(index > 0 and: [ self contextList notNil and: [ index <= self contextList size ] ])
			ifTrue: [ context := self contextList at: index ] ].
	(selectedItem respondsTo: #sourceCode) ifFalse: [
		(context respondsTo: #sourceCode) ifTrue: [ ^ self contextSelected: context ].
		debugger setSourceText: ''.
		debugger setVariableTableItems: #().
		debugger setReceiverInfoItems: #().
		debugger setFrameInfoItems: #().
		debugger setProcessInfoItems: #().
		^ self ].

	self service ifNotNil: [ self service selectContext: context ].
	context ifNil: [ ^ self ].

	sourceCode := nil.
	(context respondsTo: #sourceString) ifTrue: [
		sourceCode := context sourceString ].
	(sourceCode isNil or: [ sourceCode isEmpty ]) ifTrue: [
		sourceCode := context sourceCode ].
	(sourceCode isNil or: [ sourceCode isEmpty ]) ifTrue: [
		| fullSource |
		fullSource := debugger fetchFullSourceFor: context.
		fullSource ifNotEmpty: [
			sourceCode := fullSource.
			(context respondsTo: #sourceString:)
				ifTrue: [ context sourceString: fullSource ] ] ].
	(((context respondsTo: #methodClass) and: [ context methodClass = 'nil' ])
		and: [ (sourceCode includes: Character lf) not ])
		ifTrue: [
			| fullSource |
			fullSource := debugger fetchFullSourceFor: context.
			fullSource ifNotEmpty: [
				sourceCode := fullSource.
				(context respondsTo: #sourceString:)
					ifTrue: [ context sourceString: fullSource ] ] ].
	debugger setSourceText: (sourceCode ifNil: [
		context sourceString ifNil: [ '' ] ]).
	((context respondsTo: #isExecutedCodeFrame)
		and: [
			context isExecutedCodeFrame
				and: [ sourceCode isString and: [ sourceCode isEmpty not ] ] ]) ifTrue: [
		(self service notNil and: [ self service respondsTo: #restartSourceString: ])
			ifTrue: [ self service restartSourceString: sourceCode ] ].
	debugger applyBreakpointEmphasisFor: context.
	debugger applySourceMapHighlightFor: context.
	debugger syncBreakpointMarker.

	[
		variables := context tempNamesAndValues.
		associations := (variables respondsTo: #associations)
			ifTrue: [ variables associations ]
			ifFalse: [ #() ].
		debugger setVariableTableItems: (associations collect: [ :assoc |
			{ assoc key. assoc value asString } ])
	] on: Error do: [ :ex |
		debugger setVariableTableItems: #() ].

	debugger setReceiverInfoItems: {
		{ 'self'. ([ context receiverClassOrUnknown asString ] on: Error do: [ '<unknown>' ]) }.
		{ 'self oop'. ([ context selfOop asString ] on: Error do: [ 'nil' ]) }
	}.
	debugger setFrameInfoItems: {
		{ 'Class'. ([ context methodClassOrUnknown asString ] on: Error do: [ '<unknown>' ]) }.
		{ 'Selector'. ([ context selectorOrUnknown asString ] on: Error do: [ '<unknown>' ]) }.
		{ 'Level'. ([ context level asString ] on: Error do: [ '0' ]) }.
		{ 'Step'. ([ context quickStepPoint asString ] on: Error do: [ '0' ]) }
	}.
	debugger setProcessInfoItems: {
		{ 'Process OOP'. ([ context processOop asString ] on: Error do: [ '0' ]) }.
		{ 'Method'. ([ context methodId asString ] on: Error do: [ '<unknown>' ]) }
	}.
	debugger refreshUiState.
	debugger reinforceSourceCaretVisibility.
]

{ #category : 'accessing' }
GbsRemoteDebuggerContextPresenter >> contextList [
	^ debugger contextList
]

{ #category : 'accessing' }
GbsRemoteDebuggerContextPresenter >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerContextPresenter >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerContextPresenter >> service [
	^ debugger service
]

{ #category : 'private' }
GbsRemoteDebuggerContextPresenter >> selectedContextForInspector [
	| context index |
	context := (self service notNil and: [ self service respondsTo: #currentContext ])
		ifTrue: [ debugger safeServiceCall: [ self service currentContext ] default: nil ]
		ifFalse: [ nil ].
	context ifNotNil: [ ^ context ].
	index := (self stackList notNil and: [ self stackList respondsTo: #selectedIndex ])
		ifTrue: [ self stackList selectedIndex ifNil: [ 0 ] ]
		ifFalse: [ 0 ].
	(index > 0 and: [ self contextList notNil and: [ index <= self contextList size ] ])
		ifTrue: [ ^ self contextList at: index ].
	^ nil
]

{ #category : 'private' }
GbsRemoteDebuggerContextPresenter >> selectedVariableName [
	| variablesTable selectedItem |
	variablesTable := debugger instVarNamed: 'variablesTable'.
	variablesTable ifNil: [ ^ nil ].
	selectedItem := (variablesTable respondsTo: #selectedItem)
		ifTrue: [ variablesTable selectedItem ]
		ifFalse: [
			((variablesTable respondsTo: #selection) and: [ variablesTable selection notNil ])
				ifTrue: [
					(variablesTable selection respondsTo: #selectedItem)
						ifTrue: [ variablesTable selection selectedItem ]
						ifFalse: [ nil ] ]
				ifFalse: [ nil ] ].
	selectedItem ifNil: [ ^ nil ].
	(selectedItem isArray and: [ selectedItem size >= 1 ]) ifTrue: [ ^ selectedItem first asString ].
	(selectedItem respondsTo: #key) ifTrue: [ ^ selectedItem key asString ].
	^ nil
]

{ #category : 'accessing' }
GbsRemoteDebuggerContextPresenter >> stackList [
	^ debugger stackListPresenter
]
