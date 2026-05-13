Class {
	#name : 'GbsRemoteDebuggerProcessControl',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerProcessControl class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'private' }
GbsRemoteDebuggerProcessControl >> booleanFromRemoteValue: rawValue [
	| normalized value |
	rawValue ifNil: [ ^ false ].
	rawValue = true ifTrue: [ ^ true ].
	normalized := (rawValue respondsTo: #asLocalString)
		ifTrue: [ rawValue asLocalString ]
		ifFalse: [ rawValue ].
	value := (normalized respondsTo: #asString)
		ifTrue: [ normalized asString asLowercase ]
		ifFalse: [ '' ].
	^ value = 'true' or: [ value = '1' or: [ value = 'ok' ] ]
]

{ #category : 'accessing' }
GbsRemoteDebuggerProcessControl >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerProcessControl >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'stepping' }
GbsRemoteDebuggerProcessControl >> directStepOverExecutedFrame: stepIntoBoolean [
	| level effectiveLevel raw body |
	self hasValidRemoteProcess ifFalse: [ ^ false ].

	level := debugger currentSelectedFrameLevel.
	(level isNumber and: [ level > 0 ]) ifFalse: [ level := 1 ].
	
	"CRITICAL FIX: Force server PC to step 1 BEFORE stepping from executed code frame.
	The server may have old step point even after restart."
	self forceServerJumpToStepPoint1.
	
	effectiveLevel := self resolveExecutedFrameLevelFromServer.
	(effectiveLevel isNumber and: [ effectiveLevel > 0 ]) ifTrue: [ level := effectiveLevel ].
	stepIntoBoolean ifTrue: [ level := level bitOr: 16r100000000 ].

	body := '
		| proc ok |
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
		(proc isNil or: [ (proc respondsTo: #perform:with:) not ]) ifTrue: [ ^ ''false'' ].
		ok := [ proc perform: #_stepOverInFrame: with: stepLevel ] on: Error do: [ nil ].
		ok isNil ifTrue: [ ^ ''false'' ].
		''true''.
'.

	raw := [
		self
			fetchRemoteCommandBody: body
			literalBindings: (Dictionary new
				at: 'stepLevel' put: level;
				yourself)
			oopBindings: (Dictionary new
				at: 'obj' put: self processOop;
				yourself)
			context: 20 ] on: Error do: [ nil ].
	^ self booleanFromRemoteValue: raw
]

{ #category : 'stepping' }
GbsRemoteDebuggerProcessControl >> directStepWithPrimarySelector: primarySelector fallbackSelector: fallbackSelector [
	| level body raw |
	self hasValidRemoteProcess ifFalse: [ ^ false ].
	level := debugger currentSelectedFrameLevel.
	level ifNil: [ level := 1 ].

	body := '
		| proc selector fallbackSelector ok |
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
		(proc isNil or: [ (proc respondsTo: #perform:with:) not ]) ifTrue: [ ^ ''false'' ].
		selector := primarySelectorName asSymbol.
		fallbackSelector := fallbackSelectorName isEmpty
			ifTrue: [ nil ]
			ifFalse: [ fallbackSelectorName asSymbol ].
		ok := [ proc perform: selector with: level ] on: Error do: [ nil ].
		(ok isNil and: [ fallbackSelector notNil ]) ifTrue: [
			ok := [ proc perform: fallbackSelector with: level ] on: Error do: [ nil ]
		].
		ok isNil ifTrue: [ ^ ''false'' ].
		''true''.
'.

	raw := [
		self
			fetchRemoteCommandBody: body
			literalBindings: (Dictionary new
				at: 'fallbackSelectorName' put: (fallbackSelector ifNil: [ '' ] ifNotNil: [ fallbackSelector asString ]);
				at: 'level' put: level;
				at: 'primarySelectorName' put: primarySelector asString;
				yourself)
			oopBindings: (Dictionary new
				at: 'obj' put: self processOop;
				yourself)
			context: 20 ] on: Error do: [ nil ].
	^ self booleanFromRemoteValue: raw
]

{ #category : 'private' }
GbsRemoteDebuggerProcessControl >> fetchRemoteCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary context: contextOop [
	^ GbsRemoteExecutionDispatcher
		fetchCommandBody: bodyString
		literalBindings: literalDictionary
		oopBindings: oopDictionary
		in: self session
		context: contextOop
]

{ #category : 'stepping' }
GbsRemoteDebuggerProcessControl >> forceServerJumpToStepPoint1 [
	"Force the server process to jump to step point 1.
	This is critical for correct stepping after restart.
	
	The _trimStackToLevel: method resets the stack, but we also need to ensure
	the server's internal PC is reset. We do this by calling _trimStackToLevel: 
	again at the executed code frame level to force a PC reset."
	| body raw level |
	(self session isNil or: [ self processOop isNil ]) ifTrue: [ ^ false ].

	(self service notNil and: [ self service respondsTo: #resetServerPCToStepOne ]) ifTrue: [
		^ debugger safeServiceCall: [ self service resetServerPCToStepOne ] default: false
	].
	
	"Get the executed code frame level from server"
	level := self resolveExecutedFrameLevelFromServer.
	level ifNil: [ level := 1 ].

	body := '
		| proc tc stackReport fullEntry quick |
		obj isNil ifTrue: [ ^ false ].
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
		proc isNil ifTrue: [ ^ false ].

		(proc respondsTo: #_trimStackToLevel:) ifTrue: [
			[ proc _trimStackToLevel: restartLevel ] on: Error do: [ ]
		].

		"Check current step point at the executed code frame level"
		quick := 0.
		stackReport := [ proc _gsiStackReportFromLevel: restartLevel toLevel: restartLevel ] on: Error do: [ nil ].
		(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ]) ifTrue: [
			fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ].
			fullEntry ifNotNil: [
				quick := [ (fullEntry at: 5) asInteger ] on: Error do: [ 0 ]
			]
		].
		
		"If already at step 1, nothing to do"
		quick <= 1 ifTrue: [ ^ true ].
		
		(proc respondsTo: #_gsiStepAtLevel:step:) ifTrue: [
			[ proc _gsiStepAtLevel: restartLevel step: 1 ] on: Error do: [ ]
		].
		(proc respondsTo: #jumpToStepPoint:) ifTrue: [
			[ proc jumpToStepPoint: 1 ] on: Error do: [ ].
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
		
		[ proc _trimStackToLevel: restartLevel ] on: Error do: [ ].

		quick := 0.
		stackReport := [ proc _gsiStackReportFromLevel: restartLevel toLevel: restartLevel ] on: Error do: [ nil ].
		(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ]) ifTrue: [
			fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ].
			fullEntry ifNotNil: [
				quick := [ (fullEntry at: 5) asInteger ] on: Error do: [ 0 ]
			]
		].
		quick <= 1
	'.

	raw := [
		self
			fetchRemoteCommandBody: body
			literalBindings: (Dictionary new
				at: 'restartLevel' put: level;
				yourself)
			oopBindings: (Dictionary new
				at: 'obj' put: self processOop;
				yourself)
			context: 20 ] on: Error do: [ nil ].
	^ self booleanFromRemoteValue: raw
]

{ #category : 'private' }
GbsRemoteDebuggerProcessControl >> hasValidRemoteProcess [
	^ self session notNil
		and: [
			self processOop notNil
				and: [ self processOop isNumber and: [ self processOop > 20 ] ] ]
]

{ #category : 'accessing' }
GbsRemoteDebuggerProcessControl >> processOop [
	^ debugger processOop
]

{ #category : 'resolving' }
GbsRemoteDebuggerProcessControl >> resolveDebugProcessOopFromCurrentProcessOop [
	| body raw resolved |
	self hasValidRemoteProcess ifFalse: [ ^ nil ].

	body := '
		| candidate top hasStack |
		obj isNil ifTrue: [ ^ ''0'' ].

		hasStack := [ :proc |
			| report |
			(proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) ifTrue: [ false ] ifFalse: [
				report := [ proc _gsiStackReportFromLevel: 1 toLevel: 1 ] on: Error do: [ nil ].
				(report notNil and: [ (report respondsTo: #size) and: [ report size >= 2 ] ])
			]
		].

		(hasStack value: obj) ifTrue: [ ^ (Reflection oopOf: obj) asString ].

		candidate := (obj respondsTo: #serverProcess)
			ifTrue: [ [ obj serverProcess ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		(hasStack value: candidate) ifTrue: [ ^ (Reflection oopOf: candidate) asString ].

		candidate := (obj respondsTo: #process)
			ifTrue: [ [ obj process ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		(hasStack value: candidate) ifTrue: [ ^ (Reflection oopOf: candidate) asString ].

		top := (obj respondsTo: #topContext)
			ifTrue: [ [ obj topContext ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		top ifNotNil: [
			candidate := (top respondsTo: #process)
				ifTrue: [ [ top process ] on: Error do: [ nil ] ]
				ifFalse: [ nil ].
			(hasStack value: candidate) ifTrue: [ ^ (Reflection oopOf: candidate) asString ].
			(hasStack value: top) ifTrue: [ ^ (Reflection oopOf: top) asString ].
		].

		(obj respondsTo: #sender) ifTrue: [
			candidate := (obj respondsTo: #process)
				ifTrue: [ [ obj process ] on: Error do: [ nil ] ]
				ifFalse: [ nil ].
			(hasStack value: candidate) ifTrue: [ ^ (Reflection oopOf: candidate) asString ].
		].

		''0''
	'.

	raw := [
		self
			fetchRemoteCommandBody: body
			literalBindings: Dictionary new
			oopBindings: (Dictionary new
				at: 'obj' put: self processOop;
				yourself)
			context: 20 ] on: Error do: [ nil ].
	raw ifNil: [ ^ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	resolved := [ raw asString asInteger ] on: Error do: [ nil ].
	^ resolved
]

{ #category : 'resolving' }
GbsRemoteDebuggerProcessControl >> resolveExecutedFrameLevelFromServer [
	| body raw lines |
	self hasValidRemoteProcess ifFalse: [ ^ nil ].

	body := '
		| proc stream maxDepth level stackReport fullEntry methodOrNil className selectorName |
		obj isNil ifTrue: [ ^ '''' ].
		proc := obj.
		((proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not) ifTrue: [
			(obj respondsTo: #serverProcess) ifTrue: [ proc := [ obj serverProcess ] on: Error do: [ nil ] ]
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
		(proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) ifTrue: [ ^ '''' ].
		stream := WriteStream on: String new.
		maxDepth := 200.
		level := 1.
		[ level <= maxDepth ] whileTrue: [
			stackReport := [ proc _gsiStackReportFromLevel: level toLevel: level ] on: Error do: [ nil ].
			(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ])
				ifFalse: [ level := maxDepth + 1 ]
				ifTrue: [
					fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ].
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
				]
		].
		stream contents
	'.

	raw := [
		self
			fetchRemoteCommandBody: body
			literalBindings: Dictionary new
			oopBindings: (Dictionary new
				at: 'obj' put: self processOop;
				yourself)
			context: 20 ] on: Error do: [ nil ].
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

{ #category : 'restart' }
GbsRemoteDebuggerProcessControl >> restartUsingDirectTrimFromExecutedFrame [
	| body raw targetLevel |
	self hasValidRemoteProcess ifFalse: [ ^ false ].
	targetLevel := debugger currentSelectedFrameLevel.
	((targetLevel isNumber and: [ targetLevel > 0 ]) not) ifTrue: [ targetLevel := 1 ].

	body := '
		| proc restartLevel stackReport fullEntry quick level maxDepth methodOrNil className selectorName |
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
		(proc isNil or: [ (proc respondsTo: #_gsiStackReportFromLevel:toLevel:) not ]) ifTrue: [ ^ ''false'' ].

		"Prefer the executed-code frame level (nil class + nil selector) from server stack."
		restartLevel := targetLevel.
		level := 1.
		maxDepth := 200.
		[ level <= maxDepth ] whileTrue: [
			stackReport := [ proc _gsiStackReportFromLevel: level toLevel: level ] on: Error do: [ nil ].
			(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ])
				ifFalse: [ level := maxDepth + 1 ]
				ifTrue: [
					fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ].
					fullEntry isNil
						ifTrue: [ level := maxDepth + 1 ]
						ifFalse: [
							methodOrNil := ((fullEntry respondsTo: #at:) and: [ fullEntry size >= 1 ])
								ifTrue: [ [ fullEntry at: 1 ] on: Error do: [ nil ] ]
								ifFalse: [ nil ].
							className := [ methodOrNil inClass name asString ] on: Error do: [ ''nil'' ].
							selectorName := [ (fullEntry at: 4) ifNil: [ ''nil'' ] ifNotNil: [ :s | s asString ] ]
								on: Error do: [ ''nil'' ].
							((className = ''nil'' or: [ className = ''<unknown>'' ])
								and: [ selectorName = ''nil'' or: [ selectorName = ''unboundMethod'' ] ])
								ifTrue: [
									restartLevel := level.
									level := maxDepth + 1
								]
								ifFalse: [ level := level + 1 ]
						]
				]
		].

		[ proc _trimStackToLevel: restartLevel ] on: Error do: [ ^ ''false'' ].

	"The jumpToStepPoint: call below is kept for compatibility with GemStone versions
		that support it, but _trimStackToLevel: is the primary mechanism."
		quick := 0.
		stackReport := [ proc _gsiStackReportFromLevel: 1 toLevel: 1 ] on: Error do: [ nil ].
		(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ]) ifTrue: [
			fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ].
			fullEntry ifNotNil: [
				quick := [ (fullEntry at: 5) asInteger ] on: Error do: [ 0 ]
			]
		].
		"Try jumpToStepPoint: only if step > 1 (may not exist on all GemStone versions)"
		quick > 1 ifTrue: [
			(proc respondsTo: #jumpToStepPoint:)
				ifTrue: [ [ proc jumpToStepPoint: 1 ] on: Error do: [ ] ]
				ifFalse: [
					(proc respondsTo: #jumpTo:)
						ifTrue: [ [ proc jumpTo: 1 ] on: Error do: [ ] ]
				]
		].
		''true''
	'.

	raw := [
		self
			fetchRemoteCommandBody: body
			literalBindings: (Dictionary new
				at: 'targetLevel' put: targetLevel;
				yourself)
			oopBindings: (Dictionary new
				at: 'obj' put: self processOop;
				yourself)
			context: 20 ] on: Error do: [ nil ].
	^ self booleanFromRemoteValue: raw
]

{ #category : 'accessing' }
GbsRemoteDebuggerProcessControl >> service [
	^ debugger service
]

{ #category : 'accessing' }
GbsRemoteDebuggerProcessControl >> session [
	^ debugger session
]
