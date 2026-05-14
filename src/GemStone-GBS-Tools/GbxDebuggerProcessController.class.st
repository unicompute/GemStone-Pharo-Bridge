Class {
	#name : 'GbxDebuggerProcessController',
	#superclass : 'Object',
	#instVars : [
		'service'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDebuggerProcessController class >> on: aDebuggerService [
	^ self new
		service: aDebuggerService;
		yourself
]

{ #category : 'private' }
GbxDebuggerProcessController >> asBooleanResult: raw default: defaultBoolean [
	^ service asBooleanResult: raw default: defaultBoolean
]

{ #category : 'private' }
GbxDebuggerProcessController >> canExecuteOnDebugProcess [
	^ service canExecuteOnDebugProcess
]

{ #category : 'private' }
GbxDebuggerProcessController >> currentContext [
	^ service currentContext
]

{ #category : 'process control' }
GbxDebuggerProcessController >> isTerminated [
	| result |
	self canExecuteOnDebugProcess ifFalse: [ ^ true ].
	result := self fetchProcessCommandBody: 'proc isTerminated'.
	result ifNil: [ ^ true ].
	^ self asBooleanResult: result default: true
]

{ #category : 'private' }
GbxDebuggerProcessController >> fetchProcessCommandBody: bodyString [
	^ self
		fetchProcessCommandBody: bodyString
		literalAssignments: Dictionary new
]

{ #category : 'private' }
GbxDebuggerProcessController >> fetchProcessCommandBody: bodyString literalAssignments: literalDictionary [
	^ [ GbsRemoteExecutionDispatcher
		fetchCommandBody: (self processCommandBodyFor: bodyString)
		literalAssignments: literalDictionary
		oopAssignments: (Dictionary new
			at: 'obj' put: self processOop;
			yourself)
		in: service session
		context: 20 ]
		on: Error
		do: [ nil ]
]

{ #category : 'process control' }
GbxDebuggerProcessController >> pause [
	| session |
	service isSessionUsable ifFalse: [ ^ false ].
	session := service session.
	^ [
		(session respondsTo: #sendInterrupt)
			ifTrue: [ session sendInterrupt. true ]
			ifFalse: [
				(session respondsTo: #interrupt)
					ifTrue: [ session interrupt. true ]
					ifFalse: [
						(session respondsTo: #signalInterrupt)
							ifTrue: [ session signalInterrupt. true ]
							ifFalse: [ false ] ] ]
	] on: Error do: [ false ]
]

{ #category : 'accessing' }
GbxDebuggerProcessController >> processOop [
	^ service processOop
]

{ #category : 'process control' }
GbxDebuggerProcessController >> resetServerPCToStepOne [
	"Force the debugged server process to restart at method entry (step=1)."
	| result level |

	level := service resolvedRestartHomeLevel.

	result := self
		fetchProcessCommandBody: '[
		| tc stackReport fullEntry quick |
		(proc respondsTo: #_trimStackToLevel:) ifTrue: [
			[ proc _trimStackToLevel: restartLevel ] on: Error do: [ ]
		].

		(proc respondsTo: #_gsiStepAtLevel:step:) ifTrue: [
			[ proc _gsiStepAtLevel: restartLevel step: 1 ] on: Error do: [ ]
		].
		(proc respondsTo: #jumpToStepPoint:) ifTrue: [
			[ proc jumpToStepPoint: 1 ] on: Error do: [ ]
		].
		(proc respondsTo: #runToStepPoint:) ifTrue: [
			[ proc runToStepPoint: 1 ] on: Error do: [ ]
		].

		tc := [ proc topContext ] on: Error do: [ nil ].
		tc notNil ifTrue: [
			2 to: restartLevel do: [ :ignored |
				tc := [ tc sender ] on: Error do: [ nil ].
				tc ifNil: [ ignored := restartLevel ]
			].
			tc ifNotNil: [
				(tc respondsTo: #jumpToStepPoint:) ifTrue: [
					[ tc jumpToStepPoint: 1 ] on: Error do: [ ]
				].
				(tc respondsTo: #runToStepPoint:) ifTrue: [
					[ tc runToStepPoint: 1 ] on: Error do: [ ]
				]
			]
		].

		(proc respondsTo: #_trimStackToLevel:) ifTrue: [
			[ proc _trimStackToLevel: restartLevel ] on: Error do: [ ]
		].

		quick := 0.
		stackReport := [ proc _gsiStackReportFromLevel: restartLevel toLevel: restartLevel ] on: Error do: [ nil ].
		(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ]) ifTrue: [
			fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ].
			fullEntry ifNotNil: [
				quick := [ (fullEntry at: 5) asInteger ] on: Error do: [ 0 ]
			]
		].
		(quick <= 1) ifTrue: [ ''true'' ] ifFalse: [ ''false'' ]
	] value'
		literalAssignments: (Dictionary new
			at: 'restartLevel' put: level;
			yourself).

	service logRestartText: 'resetServerPCToStepOne level=', level asString, ' result=', result printString.
	^ self asBooleanResult: result default: false
]

{ #category : 'process control' }
GbxDebuggerProcessController >> restartLevelFromServerStack [
	| raw lines |
	self canExecuteOnDebugProcess ifFalse: [ ^ nil ].
	raw := self fetchProcessCommandBody: '[
		| stream maxDepth level stackReport fullEntry methodOrNil className selectorName |
		(proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ])
			ifTrue: [ ^ '''' ].
		stream := WriteStream on: String new.
		maxDepth := 200.
		level := 1.
		[ level <= maxDepth ] whileTrue: [
			fullEntry := nil.
			stackReport := [ proc _gsiStackReportFromLevel: level toLevel: level ] on: Error do: [ nil ].
			(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ])
				ifTrue: [ fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ] ].
			fullEntry isNil
				ifTrue: [ level := maxDepth + 1 ]
				ifFalse: [
					methodOrNil := ((fullEntry respondsTo: #at:) and: [ fullEntry size >= 1 ])
						ifTrue: [ [ fullEntry at: 1 ] on: Error do: [ nil ] ]
						ifFalse: [ nil ].
					className := [ methodOrNil inClass name asString ] on: Error do: [ ''nil'' ].
					selectorName := [ (fullEntry at: 4) ifNil: [ ''nil'' ] ifNotNil: [ :s | s asString ] ]
						on: Error do: [ ''nil'' ].
					stream
						nextPutAll: level asString; tab;
						nextPutAll: className; tab;
						nextPutAll: selectorName;
						lf.
					level := level + 1
				]
		].
		stream contents
	] value'.
	raw ifNil: [ ^ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	(raw respondsTo: #splitOn:) ifFalse: [ ^ nil ].
	lines := raw splitOn: Character lf.
	lines do: [ :line |
		| parts className selectorName |
		parts := line splitOn: Character tab.
		parts size >= 3 ifTrue: [
			className := [ (parts at: 2) asString ] on: Error do: [ '' ].
			selectorName := [ (parts at: 3) asString ] on: Error do: [ '' ].
			((className = 'nil' or: [ className = '<unknown>' ])
				and: [ selectorName = 'nil' or: [ selectorName = 'unboundMethod' ] ])
				ifTrue: [ ^ [ parts first asInteger ] on: Error do: [ nil ] ]
		]
	].
	^ nil
]

{ #category : 'process control' }
GbxDebuggerProcessController >> resume [
	(self runDebugProcessCommand: 'resume' recompute: false)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'process control' }
GbxDebuggerProcessController >> runDebugProcessCommand: commandName recompute: shouldRecompute [
	| result wasServerContext |
	self canExecuteOnDebugProcess ifFalse: [ ^ false ].
	wasServerContext := (self currentContext notNil
		and: [ (self currentContext respondsTo: #gbxIsServerContext)
		and: [ self currentContext gbxIsServerContext ] ]).
	result := self
		fetchProcessCommandBody: '[
		[ proc perform: commandSelector ] on: Error do: [ ^ ''false'' ].
		true
	] value'
		literalAssignments: (Dictionary new
			at: 'commandSelector' put: commandName asString asSymbol;
			yourself).
	(self asBooleanResult: result default: false) ifFalse: [ ^ false ].
	shouldRecompute ifTrue: [
		wasServerContext
			ifTrue: [ service selectTopServerContext ]
			ifFalse: [ service recomputeContextList ]
	].
	^ true
]

{ #category : 'process control' }
GbxDebuggerProcessController >> runDebugProcessCommand: commandName withInteger: anInteger recompute: shouldRecompute [
	| result wasServerContext |
	self canExecuteOnDebugProcess ifFalse: [ ^ false ].
	anInteger ifNil: [ ^ false ].
	wasServerContext := (self currentContext notNil
		and: [ (self currentContext respondsTo: #gbxIsServerContext)
		and: [ self currentContext gbxIsServerContext ] ]).
	result := self
		fetchProcessCommandBody: '[
		[ proc perform: commandSelector with: commandArgument ] on: Error do: [ ^ ''false'' ].
		true
	] value'
		literalAssignments: (Dictionary new
			at: 'commandArgument' put: anInteger;
			at: 'commandSelector' put: (commandName asString, ':') asSymbol;
			yourself).
	(self asBooleanResult: result default: false) ifFalse: [ ^ false ].
	shouldRecompute ifTrue: [
		wasServerContext
			ifTrue: [ service selectTopServerContext ]
			ifFalse: [ service recomputeContextList ]
	].
	^ true
]

{ #category : 'process control' }
GbxDebuggerProcessController >> runToStepPoint: aStepPoint [
	((aStepPoint isNumber and: [ aStepPoint > 0 ]) not) ifTrue: [ ^ false ].
	(self runDebugProcessCommand: 'runToStepPoint' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	(self runDebugProcessCommand: 'runTo' withInteger: aStepPoint recompute: true)
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'process control' }
GbxDebuggerProcessController >> runWithBreakAgain [
	service canRunWithBreakAgain ifFalse: [ ^ false ].
	service setBreakPointIn: nil.
	^ self resume
]

{ #category : 'process control' }
GbxDebuggerProcessController >> serverStepOverFrameLevel: levelValue [
	| result |
	self canExecuteOnDebugProcess ifFalse: [ ^ false ].
	levelValue ifNil: [ ^ false ].
	result := self
		fetchProcessCommandBody: '[
		| ok |
		(proc isNil or: [ (proc respondsTo: #perform:with:) not ]) ifTrue: [ ^ ''false'' ].
		ok := [ proc perform: #_stepOverInFrame: with: stepLevel ] on: Error do: [ nil ].
		ok isNil ifTrue: [ ^ ''false'' ].
		''true''
	] value'
		literalAssignments: (Dictionary new
			at: 'stepLevel' put: levelValue;
			yourself).
	(self asBooleanResult: result default: false) ifFalse: [ ^ false ].
	service selectTopServerContext.
	^ true
]

{ #category : 'process control' }
GbxDebuggerProcessController >> serverStepWithSelectorChain: selectorChain level: levelValue [
	| result |
	self canExecuteOnDebugProcess ifFalse: [ ^ false ].
	levelValue ifNil: [ ^ false ].
	selectorChain ifNil: [ ^ false ].
	selectorChain isEmpty ifTrue: [ ^ false ].
	result := self
		fetchProcessCommandBody: '[
		| ok selector |
		(proc isNil or: [ (proc respondsTo: #perform:with:) not ]) ifTrue: [ ^ ''false'' ].
		selectorChain do: [ :candidateSelector |
			(proc respondsTo: candidateSelector) ifTrue: [
				selector := candidateSelector.
				ok := [ proc perform: selector with: stepLevel ] on: Error do: [ nil ].
				ok isNil ifFalse: [ ^ ''true'' ] ] ].
		''false''
	] value'
		literalAssignments: (Dictionary new
			at: 'selectorChain' put: selectorChain asArray;
			at: 'stepLevel' put: levelValue;
			yourself).
	(self asBooleanResult: result default: false) ifFalse: [ ^ false ].
	service selectTopServerContext.
	^ true
]

{ #category : 'private' }
GbxDebuggerProcessController >> processCommandBodyFor: bodyString [
	^ '
		| proc |
		obj isNil ifTrue: [ ^ ''false'' ].
		proc := obj.
		((proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not) ifTrue: [
			(obj respondsTo: #serverProcess) ifTrue: [ proc := [ obj serverProcess ] on: Error do: [ nil ] ].
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #process ]) ifTrue: [
			proc := [ obj process ] on: Error do: [ nil ]
		].
		((proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) and: [ obj respondsTo: #topContext ]) ifTrue: [
			| top |
			top := [ obj topContext ] on: Error do: [ nil ].
			(top notNil and: [ top respondsTo: #process ])
				ifTrue: [ proc := [ top process ] on: Error do: [ nil ] ]
		].
		proc isNil ifTrue: [ ^ ''false'' ].
		', bodyString
]

{ #category : 'accessing' }
GbxDebuggerProcessController >> service [
	^ service
]

{ #category : 'accessing' }
GbxDebuggerProcessController >> service: aDebuggerService [
	service := aDebuggerService
]

{ #category : 'process control' }
GbxDebuggerProcessController >> terminate [
	(self runDebugProcessCommand: 'terminate' recompute: false)
		ifTrue: [ ^ true ].
	^ false
]
