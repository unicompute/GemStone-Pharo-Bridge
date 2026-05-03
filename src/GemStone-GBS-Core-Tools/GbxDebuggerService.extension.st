Extension { #name : 'GbxDebuggerService' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> actualServerQuickStepPointAtLevel: levelValue [
	^ self remoteDebugProcess quickStepPointAtLevel: levelValue
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> canExecuteOnDebugProcess [
	| activeProcessOop |
	activeProcessOop := self currentProcessOop.
	(self isSessionUsable and: [ activeProcessOop isNumber ]) ifFalse: [ ^ false ].
	^ activeProcessOop > 20
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> currentFrameOop [
	^ self remoteDebugProcess
		currentFrameOopAtLevel: self currentContextLevel
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> currentProcessOop [
	processOop ifNotNil: [ ^ processOop ].
	currentContext ifNil: [ ^ nil ].
	(currentContext respondsTo: #processOop) ifTrue: [ ^ currentContext processOop ].
	(currentContext respondsTo: #process) ifTrue: [ ^ currentContext process ].
	^ nil
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> currentReceiverOop [
	^ self remoteDebugProcess
		currentReceiverOopAtLevel: self currentContextLevel
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> cutbackGsTo: gsContext [
	"gsContext must be a GemStone server context.
	Discard any partially-completed server execution above 
	gsContext on the stack of its GSProcess. Also discards 
	any partial execution in gsContext, resetting it to the 
	beginning."
	| lvl resolvedHomeLevel result |
	lvl := (gsContext respondsTo: #level) ifTrue: [ gsContext level ] ifFalse: [ 1 ].
	resolvedHomeLevel := self resolvedRestartHomeLevel.
	(resolvedHomeLevel isNumber and: [ resolvedHomeLevel > 0 ])
		ifTrue: [ lvl := resolvedHomeLevel ].
	result := self remoteDebugProcess trimStackToLevel: lvl.
	self logRestartText: 'cutbackGsTo level=', lvl asString, ' result=', result printString.
	^ result
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> isTerminated [
	"Check if the debugged process is terminated"
	(self canExecuteOnDebugProcess) ifFalse: [ ^ true ].
	^ self remoteDebugProcess isTerminated
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> oopForVariableNamed: aVariableName [
	^ self remoteDebugProcess
		oopForVariableNamed: aVariableName
		atLevel: self currentContextLevel
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> recomputeContextList [
	"Recompute the context list after a step operation.
	Always rebind currentContext to the freshly-computed list entry, even when
	an equal/stale context object is still considered present."
	| contexts |
	contextStackPolicy ifNil: [
		self updateSourceMapFromCurrentContext.
		self notifyContextChanged.
		^ self
	].
	contextStackPolicy computeContextList.
	contexts := contextStackPolicy contextList.
	self updateCurrentContextFromContexts: contexts.
	self updateSourceMapFromCurrentContext.
	self notifyContextChanged.
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> resetServerPCToStepOne [
	"Force the debugged server process to restart at method entry (step=1).
	This is the deterministic restart anchor used by basicReenterServerContext,
	especially important for repeated Restart actions.
	Uses the actual executed-code frame level from the current server stack and
	then applies a stronger reset ladder than the plain process-level
	jumpToStepPoint:. This matches the working C++ GemStone FFI probes more
	closely, especially for repeated restart cycles."
	| result level |

	level := self resolvedRestartHomeLevel.

	result := self remoteDebugProcess resetProgramCounterToStepOneAtLevel: level.
	self logRestartText: 'resetServerPCToStepOne level=', level asString, ' result=', result printString.
	^ result
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> restartLevelFromServerStack [
	"Delegate to the remote debug facade, which preserves the older
	restart stack parsing guard based on respondsTo: #splitOn:."
	^ self remoteDebugProcess restartLevelFromServerStack
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> runDebugProcessCommand: commandName recompute: shouldRecompute [
	| contexts |
	(self canExecuteOnDebugProcess) ifFalse: [ ^ false ].
	shouldRecompute ifFalse: [
		^ self remoteDebugProcess runCommand: commandName ].
	contexts := self remoteDebugProcess
		runCommandCollectingContextActivations: commandName.
	contexts ifNil: [ ^ false ].
	self updateContextListFromServerContexts: contexts.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> updateCurrentContextFromContexts: contexts [
	| refreshed |
	currentContext isNil
		ifTrue: [
			contexts ifNotEmpty: [ :list | currentContext := list first ] ]
		ifFalse: [
			refreshed := contexts
				detect: [ :each | (each == currentContext) or: [ each = currentContext ] ]
				ifNone: [ nil ].
			refreshed
				ifNil: [ contexts ifNotEmpty: [ :list | currentContext := list first ] ]
				ifNotNil: [ currentContext := refreshed ] ].
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> updateContextListFromServerContexts: serverContexts [
	| contexts |
	contextStackPolicy ifNil: [
		self updateSourceMapFromCurrentContext.
		self notifyContextChanged.
		^ self ].
	contextStackPolicy updateContextListFromServerContexts: serverContexts.
	contexts := contextStackPolicy contextList.
	self updateCurrentContextFromContexts: contexts.
	self updateSourceMapFromCurrentContext.
	self notifyContextChanged
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> runDebugProcessCommand: commandName withInteger: anInteger recompute: shouldRecompute [
	| contexts |
	(self canExecuteOnDebugProcess) ifFalse: [ ^ false ].
	anInteger ifNil: [ ^ false ].
	shouldRecompute ifTrue: [
		contexts := self remoteDebugProcess
			runCommand: commandName
			withIntegerCollectingContextActivations: anInteger.
		contexts ifNil: [ ^ false ].
		self updateContextListFromServerContexts: contexts.
		^ true ].
	^ self remoteDebugProcess runCommand: commandName withInteger: anInteger
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> remoteDebugProcess [
	^ GbsRemoteDebugProcessFacade
		on: session
		processOop: self currentProcessOop
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> serverStepOverFrameLevel: levelValue [
	(self canExecuteOnDebugProcess) ifFalse: [ ^ false ].
	levelValue ifNil: [ ^ false ].
	(self remoteDebugProcess stepOverFrameLevel: levelValue) ifFalse: [ ^ false ].
	self selectTopServerContext.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> synchronizeServerProgramCounterAfterRestart [
	"After restart, force server-side process PC to align with displayed restart frame."
	| level result |
	(self isCurrentExecutedCodeFrame) ifFalse: [ ^ false ].
	level := self resolvedRestartHomeLevel.
	result := self remoteDebugProcess synchronizeProgramCounterAtLevel: level.
	result ifTrue: [
		self selectTopServerContext.
		^ true
	].
	^ false
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> legacyCompileLookup [
	| className selector isMeta |
	className := self selectedMethodClassName.
	selector := self selectedMethodSelector.
	(className isNil or: [ selector isNil or: [ selector = #unboundMethod ] ]) ifTrue: [ ^ nil ].
	isMeta := className asString endsWith: ' class'.
	^ {
		(isMeta
			ifTrue: [ className asString allButLast: 6 ]
			ifFalse: [ className asString ]).
		selector asSymbol.
		isMeta.
		(self selectedMethodProtocol ifNil: [ 'as yet unclassified' ]) }
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> legacyCompileResponseForSource: sourceText correctingSelector: allowSelectorCorrection [
	| lookup escapedSource raw |
	lookup := self legacyCompileLookup.
	lookup ifNil: [ ^ nil ].
	escapedSource := sourceText
		ifNil: [ '' ]
		ifNotNil: [ :each | (each asString copyReplaceAll: String cr with: String lf) copyReplaceAll: '''' with: '''''' ].
	raw := [ session
		executeAndFetch: (String streamContents: [ :stream |
			stream nextPutAll: '[
		| cls oldSel protocol result newSel source |
		cls := Smalltalk at: '.
			stream nextPutAll: lookup first storeString.
			stream nextPutAll: ' ifAbsent: [ nil ].
		cls ifNil: [ ^ ''ERROR|Class not found'' ].
		'.
			lookup third ifTrue: [ stream nextPutAll: 'cls := cls class.' ].
			stream nextPutAll: '
		oldSel := '.
			stream nextPutAll: lookup second storeString.
			stream nextPutAll: '.
		source := '''.
			stream nextPutAll: escapedSource.
			stream nextPutAll: '''.
		protocol := '.
			stream nextPutAll: lookup fourth storeString.
			stream nextPutAll: '.
		result := [ cls compileMethod: source category: protocol ] on: Error do: [ :ex | ''ERROR|'', ex description ].
		(result isString and: [ result beginsWith: ''ERROR|'' ]) ifTrue: [ ^ result ].
		'.
			allowSelectorCorrection ifTrue: [
				stream nextPutAll: '
		newSel := [ result selector ] on: Error do: [ oldSel ].
		(newSel ~= oldSel and: [ cls includesSelector: oldSel ]) ifTrue: [
			[ cls removeSelector: oldSel ] on: Error do: [ :ex | ]
		].' ].
			stream nextPutAll: '
		''OK''
	] value' ])
		context: session sessionOop ]
		on: Error
		do: [ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	^ raw
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> legacyCorrectedCompileResponseForSource: sourceText [
	^ self legacyCompileResponseForSource: sourceText correctingSelector: true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbxDebuggerService >> legacyRecompileResponseForSource: sourceText [
	^ self legacyCompileResponseForSource: sourceText correctingSelector: false
]
