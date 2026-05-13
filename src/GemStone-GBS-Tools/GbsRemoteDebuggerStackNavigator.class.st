Class {
	#name : 'GbsRemoteDebuggerStackNavigator',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerStackNavigator class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'actions' }
GbsRemoteDebuggerStackNavigator >> bookmarkContext [
	| index stack |
	stack := self stackList.
	stack ifNil: [ ^ false ].
	index := (stack respondsTo: #selectedIndex)
		ifTrue: [ stack selectedIndex ]
		ifFalse: [ nil ].
	index ifNil: [ ^ false ].
	debugger bookmarkContextIndex: index.
	^ true
]

{ #category : 'actions' }
GbsRemoteDebuggerStackNavigator >> clearBookmarkContext [
	debugger bookmarkContextIndex: nil.
	^ true
]

{ #category : 'accessing' }
GbsRemoteDebuggerStackNavigator >> contextList [
	^ debugger contextList
]

{ #category : 'testing' }
GbsRemoteDebuggerStackNavigator >> currentSelectedContextIsExecutedCodeFrame [
	| context index |
	context := (self service notNil and: [ self service respondsTo: #currentContext ])
		ifTrue: [ debugger safeServiceCall: [ self service currentContext ] default: nil ]
		ifFalse: [ nil ].
	context ifNil: [
		index := (self stackList notNil and: [ self stackList respondsTo: #selectedIndex ])
			ifTrue: [ self stackList selectedIndex ifNil: [ 0 ] ]
			ifFalse: [ 0 ].
		(index > 0 and: [ self contextList notNil and: [ index <= self contextList size ] ])
			ifTrue: [ context := self contextList at: index ]
	].
	context ifNil: [ ^ false ].
	^ (context respondsTo: #isExecutedCodeFrame)
		and: [ context isExecutedCodeFrame ]
]

{ #category : 'accessing' }
GbsRemoteDebuggerStackNavigator >> currentSelectedFrameLevel [
	| context index |
	self service ifNotNil: [
		context := debugger safeServiceCall: [ self service currentContext ] default: nil.
		(context notNil and: [ context respondsTo: #level ]) ifTrue: [ ^ context level ].
	].
	index := (self stackList notNil and: [ self stackList respondsTo: #selectedIndex ])
		ifTrue: [ self stackList selectedIndex ifNil: [ 0 ] ]
		ifFalse: [ 0 ].
	(index > 0 and: [ self contextList notNil and: [ index <= self contextList size ] ]) ifTrue: [
		context := self contextList at: index.
		(context respondsTo: #level) ifTrue: [ ^ context level ]
	].
	^ 1
]

{ #category : 'accessing' }
GbsRemoteDebuggerStackNavigator >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerStackNavigator >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'testing' }
GbsRemoteDebuggerStackNavigator >> isExecutedCodeFrame: aContext [
	| className selectorName |
	aContext ifNil: [ ^ false ].
	className := [ aContext methodClassOrUnknown ] on: Error do: [ '<unknown>' ].
	selectorName := [ aContext selectorOrUnknown asString ] on: Error do: [ '<unknown>' ].
	^ (className = 'nil' or: [ className = '<unknown>' ])
		and: [ selectorName = 'nil' or: [ selectorName = 'unboundMethod' ] ]
]

{ #category : 'testing' }
GbsRemoteDebuggerStackNavigator >> isLikelyUserFrame: aContext [
	| className selectorName source |
	aContext ifNil: [ ^ false ].

	className := [ aContext methodClassOrUnknown ] on: Error do: [ '<unknown>' ].
	selectorName := [ aContext selectorOrUnknown asString ] on: Error do: [ '<unknown>' ].
	source := [ aContext sourceString ifNil: [ '' ] ] on: Error do: [ '' ].

	(className beginsWith: 'AbstractException') ifTrue: [ ^ false ].
	(className beginsWith: 'GsNMethod') ifTrue: [ ^ false ].
	(selectorName beginsWith: '_') ifTrue: [ ^ false ].
	(#('signal' 'defaultAction' '_defaultAction' '_signal' '_signalToDebugger') includes: selectorName) ifTrue: [ ^ false ].
	source isEmpty ifTrue: [ ^ false ].

	^ true
]

{ #category : 'normalizing' }
GbsRemoteDebuggerStackNavigator >> normalizePauseLandingSelection [
	"Pause should land on the current top server frame deterministically."
	(self contextList isCollection and: [ self contextList isEmpty not ]) ifFalse: [ ^ debugger ].
	self stackList ifNotNil: [
		(self stackList respondsTo: #selectIndex:)
			ifTrue: [ self stackList selectIndex: 1 ].
	].
	debugger contextSelected: self contextList first.
	^ debugger
]

{ #category : 'normalizing' }
GbsRemoteDebuggerStackNavigator >> normalizeRestartSelectionAndPosition [
	| index context |
	(self contextList isNil or: [ self contextList isEmpty ]) ifTrue: [ ^ debugger ].

	index := self contextList
		findFirst: [ :ctx |
			| className selectorName |
			className := [ ctx methodClassOrUnknown asString ] on: Error do: [ '' ].
			selectorName := [ ctx selectorOrUnknown asString ] on: Error do: [ '' ].
			(className = 'nil' or: [ className = '<unknown>' ])
				and: [ selectorName = 'nil' or: [ selectorName = 'unboundMethod' ] ] ].

	index = 0 ifTrue: [ index := 1 ].
	(index <= 0 or: [ index > self contextList size ]) ifTrue: [ ^ debugger ].
	context := self contextList at: index.

	self service ifNotNil: [
		(self service respondsTo: #currentContext:)
			ifTrue: [ self service currentContext: context ].
		(self service respondsTo: #updateSourceMapFromCurrentContext)
			ifTrue: [ self service updateSourceMapFromCurrentContext ]
	].

	(self stackList respondsTo: #selectIndex:)
		ifTrue: [ self stackList selectIndex: index ].

	debugger contextSelected: context.
	debugger moveSourceCursorToStart.
	debugger refreshUiState.
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerStackNavigator >> preferredInitialContextIndex [
	| index |
	self contextList ifNil: [ ^ 1 ].
	self contextList isEmpty ifTrue: [ ^ 1 ].

	(self contextList first respondsTo: #isExecutedCodeFrame) ifTrue: [
		(self contextList first isExecutedCodeFrame) ifTrue: [ ^ 1 ]
	].
	(self contextList first respondsTo: #isExecutedCodeAtStepOne) ifTrue: [
		(self contextList first isExecutedCodeAtStepOne) ifTrue: [ ^ 1 ]
	].

	index := self contextList
		findFirst: [ :ctx | self isLikelyUserFrame: ctx ].
	index = 0 ifTrue: [ ^ 1 ].
	^ index
]

{ #category : 'actions' }
GbsRemoteDebuggerStackNavigator >> selectHomeContext [
	| index |
	(self contextList isNil or: [ self contextList isEmpty ]) ifTrue: [ ^ false ].
	index := self preferredInitialContextIndex.
	(index isNil or: [ index <= 0 or: [ index > self contextList size ] ])
		ifTrue: [ index := 1 ].
	self stackList selectIndex: index.
	debugger contextSelected: (self contextList at: index).
	^ true
]

{ #category : 'accessing' }
GbsRemoteDebuggerStackNavigator >> service [
	^ debugger service
]

{ #category : 'accessing' }
GbsRemoteDebuggerStackNavigator >> stackList [
	^ debugger stackListPresenter
]
