Class {
	#name : 'GbsRemoteDebuggerStackLoader',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerStackLoader class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'accessing' }
GbsRemoteDebuggerStackLoader >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerStackLoader >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'fetching' }
GbsRemoteDebuggerStackLoader >> fetchStackFrames [
	| contexts |
	debugger stackData ifNotNil: [ ^ self fetchStackFramesFromData ].
	contexts := self serviceContexts.
	contexts ifEmpty: [ contexts := debugger fetchContextsDirectly ].
	contexts ifEmpty: [ contexts := self retryWithResolvedProcessOop ].
	^ self installContexts: contexts
]

{ #category : 'fetching' }
GbsRemoteDebuggerStackLoader >> fetchStackFramesFromData [
	| contexts index |
	index := 0.
	contexts := debugger stackData splitOn: $^ thenCollect: [ :frameStr |
		| parts activation |
		parts := frameStr splitOn: $|.
		parts size >= 3 ifTrue: [
			index := index + 1.
			activation := GbxActivation new.
			(activation respondsTo: #session:)
				ifTrue: [ activation session: debugger session ]
				ifFalse: [ activation instVarNamed: 'session' put: debugger session ].
			activation
				processOop: 0;
				level: index;
				selector: (parts at: 1) asSymbol;
				gsMethodId: (parts at: 2);
				sourceString: (parts at: 3);
				yourself ] ] thenSelect: #isNotNil.
	debugger contextList: contexts.
	debugger stackListPresenter items: (contexts collect: [ :ctx | ctx printString ]).
	contexts ifNotEmpty: [ self selectInitialContextIn: contexts markFirstExecuted: true ].
]

{ #category : 'private' }
GbsRemoteDebuggerStackLoader >> installContexts: contexts [
	| installed |
	installed := contexts ifNil: [ #( ) ].
	debugger contextList: installed.
	installed ifEmpty: [ ^ self installNoStackFramesFallback ].
	debugger stackListPresenter items: (installed collect: [ :ctx | ctx printString ]).
	self selectInitialContextIn: installed markFirstExecuted: false.
	debugger refreshUiState
]

{ #category : 'private' }
GbsRemoteDebuggerStackLoader >> installNoStackFramesFallback [
	debugger stackListPresenter items: { self noStackFramesFallbackMessage }.
	debugger setSourceText: ''.
	debugger clearSourceHighlight.
	debugger setVariableTableItems: #().
	debugger setReceiverInfoItems: #().
	debugger setFrameInfoItems: #().
	debugger setProcessInfoItems: #().
	debugger refreshUiState.
	^ debugger
]

{ #category : 'private' }
GbsRemoteDebuggerStackLoader >> noStackFramesFallbackMessage [
	| oopText |
	oopText := (debugger processOop isNil or: [ debugger processOop = 0 ])
		ifTrue: [ 'unknown process' ]
		ifFalse: [ 'process oop ', debugger processOop asString ].
	^ 'No GemStone stack frames available for ', oopText, '. The server did not expose a context; abort the transaction before retrying if this debugger was opened from a failed remote evaluation.'
]

{ #category : 'private' }
GbsRemoteDebuggerStackLoader >> retryWithResolvedProcessOop [
	| resolved |
	resolved := debugger resolveDebugProcessOopFromCurrentProcessOop.
	((resolved isNumber and: [ resolved > 20 ]) and: [ resolved ~= debugger processOop ]) ifFalse: [ ^ #( ) ].
	debugger processOopSilently: resolved.
	(debugger service notNil and: [ debugger service respondsTo: #processOop: ])
		ifTrue: [ [ debugger service processOop: resolved ] on: Error do: [ ] ].
	^ debugger fetchContextsDirectly
]

{ #category : 'private' }
GbsRemoteDebuggerStackLoader >> selectInitialContextIn: contexts markFirstExecuted: shouldMark [
	| preferredIndex firstContext |
	shouldMark ifTrue: [
		firstContext := contexts at: 1.
		(firstContext respondsTo: #markAsExecutedCodeFrame)
			ifTrue: [ firstContext markAsExecutedCodeFrame ] ].
	preferredIndex := debugger preferredInitialContextIndex.
	debugger stackListPresenter selectIndex: preferredIndex.
	debugger contextSelected: (contexts at: preferredIndex)
]

{ #category : 'private' }
GbsRemoteDebuggerStackLoader >> serviceContexts [
	| contexts |
	contexts := #( ).
	debugger service ifNotNil: [
		[
			(debugger service respondsTo: #recomputeContextList)
				ifTrue: [ debugger service recomputeContextList ].
			contexts := debugger service contextList
		] on: Error do: [ contexts := #( ) ] ].
	^ contexts
]
