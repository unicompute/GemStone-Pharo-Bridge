Class {
	#name : 'GbxDebuggerRestartController',
	#superclass : 'Object',
	#instVars : [
		'service'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxDebuggerRestartController class >> on: aDebuggerService [
	^ self new
		service: aDebuggerService;
		yourself
]

{ #category : 'server state' }
GbxDebuggerRestartController >> actualServerQuickStepPointAfterRestart [
	| step |
	step := self actualServerQuickStepPointAtLevel: 1.
	(step isNumber and: [ step > 0 ]) ifTrue: [ ^ step ].
	step := self actualServerQuickStepPointAtLevel: service resolvedRestartHomeLevel.
	(step isNumber and: [ step > 0 ]) ifTrue: [ ^ step ].
	step := service currentStepPoint.
	(step isNumber and: [ step > 0 ]) ifTrue: [ ^ step ].
	^ 0
]

{ #category : 'server state' }
GbxDebuggerRestartController >> actualServerQuickStepPointAtLevel: levelValue [
	| raw processOop |
	processOop := service processOop.
	(service session isNil or: [ processOop isNil ]) ifTrue: [ ^ 0 ].
	(processOop isNumber and: [ processOop > 20 ]) ifFalse: [ ^ 0 ].
	raw := [ self
		fetchProcessCommandBody: '
	| stackReport fullEntry quick |
	(proc respondsTo: #_gsiStackReportFromLevel:toLevel:)
		ifFalse: [ ''0'' ]
		ifTrue: [
			stackReport := [ proc _gsiStackReportFromLevel: levelValue toLevel: levelValue ] on: Error do: [ nil ].
			(stackReport isNil or: [ stackReport size < 2 ])
				ifTrue: [ ''0'' ]
				ifFalse: [
					fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ].
					fullEntry ifNil: [ ''0'' ] ifNotNil: [
						quick := [ (fullEntry at: 5) asInteger ] on: Error do: [ 0 ].
						quick asString ] ] ]'
		literalAssignments: (Dictionary new
			at: 'levelValue' put: levelValue;
			yourself) ]
		on: Error
		do: [ nil ].
	raw ifNil: [ ^ 0 ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	^ [ raw asString asInteger ] on: Error do: [ 0 ]
]

{ #category : 'restart' }
GbxDebuggerRestartController >> basicReenterServerContext [
	"Reset the selected server context as if it had just been entered."
	| theContext |
	theContext := self restartTargetContext.
	theContext ifNil: [ theContext := service currentContext ].
	theContext ifNil: [ ^ false ].
	service selectContext: theContext.
	service logRestartState: 'basicReenter/start' context: theContext.

	(self cutbackTo: theContext
		finishWith: [
			service resetServerPCToStepOne.
			service selectTopServerContext.
			service selectRestartTargetContext.
			service notifyContextChanged ])
		ifFalse: [ ^ false ].
	service logRestartState: 'basicReenter/done' context: service currentContext.
	^ true
]

{ #category : 'cutback' }
GbxDebuggerRestartController >> cutbackClientContextsAbove: gsContext [
	| ctx policy |
	policy := service contextStackPolicy.
	policy ifNil: [ ^ self ].
	(policy respondsTo: #firstClientContextAbove:) ifFalse: [ ^ self ].
	ctx := policy firstClientContextAbove: gsContext.
	ctx ifNotNil: [ self cutbackTo: ctx finishWith: [ ] ]
]

{ #category : 'cutback' }
GbxDebuggerRestartController >> cutbackGsProcessesAbove: clientContext [
	| ctx |
	ctx := service firstServerContextAbove: clientContext.
	ctx ifNotNil: [ self cutbackToGsProcessOf: ctx ]
]

{ #category : 'cutback' }
GbxDebuggerRestartController >> cutbackGsTo: gsContext [
	| lvl resolvedHomeLevel result processOop |
	processOop := service processOop.
	(processOop isNumber and: [ processOop > 20 ]) ifFalse: [ ^ false ].
	lvl := (gsContext respondsTo: #level) ifTrue: [ gsContext level ] ifFalse: [ 1 ].
	resolvedHomeLevel := service resolvedRestartHomeLevel.
	(resolvedHomeLevel isNumber and: [ resolvedHomeLevel > 0 ])
		ifTrue: [ lvl := resolvedHomeLevel ].
	result := self
		fetchProcessCommandBody: '
		(proc respondsTo: #_trimStackToLevel:)
			ifFalse: [ ''false'' ]
			ifTrue: [
				[ proc _trimStackToLevel: restartLevel. ''true'' ]
					on: Error
					do: [ ''false'' ] ]'
		literalAssignments: (Dictionary new
			at: 'restartLevel' put: lvl;
			yourself).
	service logRestartText: 'cutbackGsTo level=', lvl asString, ' result=', result printString.
	^ service asBooleanResult: result default: false
]

{ #category : 'private' }
GbxDebuggerRestartController >> fetchProcessCommandBody: bodyString literalAssignments: literalDictionary [
	^ [ GbsRemoteExecutionDispatcher
		fetchCommandBody: (self processCommandBodyFor: bodyString)
		literalAssignments: literalDictionary
		oopAssignments: (Dictionary new
			at: 'obj' put: service processOop;
			yourself)
		in: service session
		context: 20 ]
		on: Error
		do: [ :ex |
			Transcript
				show: 'GBS_REMOTE_PROCESS_COMMAND_ERROR ';
				show: (([ ex messageText ] on: Error do: [ ex printString ]) ifNil: [ ex printString ]) asString;
				cr.
			nil ]
]

{ #category : 'private' }
GbxDebuggerRestartController >> processCommandBodyFor: bodyString [
	^ '
		| proc |
		proc := nil.
		obj notNil ifTrue: [
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
			] ].
		proc isNil
			ifTrue: [ ''false'' ]
			ifFalse: [
		', bodyString, '
			]'
]

{ #category : 'cutback' }
GbxDebuggerRestartController >> cutbackTo: aContext finishWith: aBlock [
	| isServer |
	aContext ifNil: [ ^ false ].
	isServer := (aContext respondsTo: #gbxIsServerContext)
		and: [ aContext gbxIsServerContext ].
	isServer
		ifTrue: [ ^ self cutbackToGsContext: aContext finishWith: aBlock ].

	self cutbackGsProcessesAbove: aContext.
	aBlock value.
	^ true
]

{ #category : 'cutback' }
GbxDebuggerRestartController >> cutbackToGsContext: gsContext finishWith: finishBlockArg [
	self cutbackClientContextsAbove: gsContext.
	(self cutbackGsTo: gsContext) ifFalse: [ ^ false ].
	finishBlockArg value.
	^ true
]

{ #category : 'cutback' }
GbxDebuggerRestartController >> cutbackToGsProcessOf: gsContext [
	| gbsError |
	self cutbackClientContextsAbove: gsContext.
	(gsContext respondsTo: #terminateProcess) ifTrue: [
		[ gsContext terminateProcess ] on: Error do: [ ]
	].
	gbsError := (gsContext respondsTo: #gbsError)
		ifTrue: [ [ gsContext gbsError ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	(gbsError notNil and: [ gbsError respondsTo: #session: ]) ifTrue: [
		[ gbsError session: nil ] on: Error do: [ ]
	].
	^ true
]

{ #category : 'restart' }
GbxDebuggerRestartController >> emergencyRestart: ex [
	| originalContext |
	originalContext := service currentContext.
	ex parameter ifNotNil: [ :param |
		(param respondsTo: #initialContext) ifTrue: [
			service currentContext: param initialContext
		]
	].
	service recomputeContextList.
	service scheduleTextUpdate.
	service processEvents
]

{ #category : 'restart' }
GbxDebuggerRestartController >> ensureRestartAtStepOne [
	| step |
	service isCurrentExecutedCodeFrame ifFalse: [ ^ self ].
	step := service currentStepPoint ifNil: [ 1 ].
	service logRestartText: 'ensureRestartAtStepOne step=', step asString.
	step > 1 ifFalse: [ ^ self ].
	(service jumpToStepPoint: 1)
		ifFalse: [ service runToStepPoint: 1 ].
	service selectTopServerContext
]

{ #category : 'restart' }
GbxDebuggerRestartController >> forceRestartPositionToMethodStart [
	| target |
	target := service currentContext.
	target ifNil: [ target := self restartTargetContext ].
	target ifNil: [ ^ self ].
	target instVarNamed: #quickStepPoint put: 1.
	target instVarNamed: #ipOffset put: 1.
	target instVarNamed: #sourceOffsets put: #( ).
	service updateSourceMapFromCurrentContext
]

{ #category : 'restart' }
GbxDebuggerRestartController >> markCurrentContextAsRestarted [
	| target |
	target := service currentContext.
	target ifNil: [ target := self restartTargetContext ].
	target ifNil: [ ^ self ].
	(target respondsTo: #markAsExecutedCodeFrame) ifTrue: [
		target markAsExecutedCodeFrame
	].
	service updateSourceMapFromCurrentContext
]

{ #category : 'process control' }
GbxDebuggerRestartController >> restart [
	| didRestart target |
	service logRestartState: 'restart/start' context: service currentContext.
	target := self restartTargetContext.
	target ifNotNil: [ service selectContext: target ].
	didRestart := service basicReenterServerContext.
	didRestart ifTrue: [
		service selectRestartTargetContext.
		service isExecutedCodeAtStepOne ifFalse: [
			service logRestartText: 'restart auto-retry: first reenter did not reach step 1'.
			didRestart := service basicReenterServerContext.
			didRestart ifTrue: [ service selectRestartTargetContext ] ].
		service ensureRestartAtStepOne.
		service selectRestartTargetContext.
		self synchronizeServerProgramCounterAfterRestart.
		service selectRestartTargetContext.
		service isExecutedCodeAtStepOne ifFalse: [
			service resetServerPCToStepOne.
			service selectTopServerContext.
			service selectRestartTargetContext ] ].
	service logRestartText: 'restart/result=', didRestart asString.
	service logRestartState: 'restart/end' context: service currentContext.
	^ didRestart
]

{ #category : 'restart' }
GbxDebuggerRestartController >> restartNeedsFreshFaultReplay [
	| step |
	(service isCurrentExecutedCodeFrame or: [
		service contextList anySatisfy: [ :each |
			(each respondsTo: #isExecutedCodeFrame)
				and: [ each isExecutedCodeFrame ] ] ]) ifFalse: [ ^ false ].
	step := self actualServerQuickStepPointAfterRestart.
	service logRestartText: 'restartNeedsFreshFaultReplay actualStep=', step asString.
	^ step > 1
]

{ #category : 'private' }
GbxDebuggerRestartController >> restartTargetContext [
	| contexts |
	contexts := service contextList.
	(contexts isCollection and: [ contexts respondsTo: #isEmpty ]) ifFalse: [ ^ nil ].
	contexts ifEmpty: [ ^ nil ].
	^ contexts
		detect: [ :ctx |
			| className selectorName |
			className := [ ctx methodClassOrUnknown asString ] on: Error do: [ '' ].
			selectorName := [ ctx selectorOrUnknown asString ] on: Error do: [ '' ].
			(className = 'nil'
				or: [ className = '<unknown>'
				or: [ className isEmpty ] ])
				and: [
					selectorName = 'nil'
						or: [ selectorName = 'unboundMethod'
						or: [ selectorName = '<unknown>'
						or: [ selectorName isEmpty ] ] ] ] ]
		ifNone: [ contexts first ]
]

{ #category : 'accessing' }
GbxDebuggerRestartController >> service [
	^ service
]

{ #category : 'accessing' }
GbxDebuggerRestartController >> service: aDebuggerService [
	service := aDebuggerService
]

{ #category : 'private' }
GbxDebuggerRestartController >> sourceStringForRestartContext: aContext [
	| source |
	aContext ifNil: [ ^ '' ].
	source := (aContext respondsTo: #sourceString)
		ifTrue: [ [ aContext sourceString ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	(source isString and: [ source isEmpty not ]) ifTrue: [ ^ source ].
	source := (aContext respondsTo: #sourceCode)
		ifTrue: [ [ aContext sourceCode ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	^ source ifNil: [ '' ]
]

{ #category : 'private' }
GbxDebuggerRestartController >> synchronizeServerProgramCounterAfterRestart [
	| level result |
	service isCurrentExecutedCodeFrame ifFalse: [ ^ false ].
	level := service resolvedRestartHomeLevel.
	result := self
		fetchProcessCommandBody: '
		(proc respondsTo: #_trimStackToLevel:)
			ifFalse: [ ''false'' ]
			ifTrue: [
				[ proc _trimStackToLevel: restartLevel. ''true'' ]
					on: Error
					do: [ ''false'' ] ]'
		literalAssignments: (Dictionary new
			at: 'restartLevel' put: level;
			yourself).
	(service asBooleanResult: result default: false) ifTrue: [
		service selectTopServerContext.
		^ true ].
	^ false
]
