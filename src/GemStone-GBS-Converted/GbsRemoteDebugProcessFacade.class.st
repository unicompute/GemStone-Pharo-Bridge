Class {
	#name : 'GbsRemoteDebugProcessFacade',
	#superclass : 'Object',
	#instVars : [
		'session',
		'processOop'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsRemoteDebugProcessFacade class >> on: aSession processOop: anOop [
	^ self new
		session: aSession;
		processOop: anOop;
		yourself
]

{ #category : 'private' }
GbsRemoteDebugProcessFacade >> asBooleanResult: rawResult default: aBoolean [
	| text normalized |
	rawResult ifNil: [ ^ aBoolean ].
	((rawResult == true) or: [ rawResult == false ]) ifTrue: [ ^ rawResult ].
	normalized := [ rawResult asInteger ]
		on: Error
		do: [ nil ].
	normalized = 1 ifTrue: [ ^ true ].
	normalized = 0 ifTrue: [ ^ false ].
	normalized = 268 ifTrue: [ ^ true ].
	normalized = 12 ifTrue: [ ^ false ].
	text := rawResult asString asLowercase trimBoth.
	(#('true' 't' '1' 'ok') includes: text) ifTrue: [ ^ true ].
	(#('false' 'f' '0' 'nil') includes: text) ifTrue: [ ^ false ].
	^ aBoolean
]

{ #category : 'private' }
GbsRemoteDebugProcessFacade >> canExecute [
	^ session notNil
		and: [ processOop isNumber and: [ processOop > 20 ] ]
]

{ #category : 'private' }
GbsRemoteDebugProcessFacade >> executeBooleanBody: bodyString [
	^ self
		asBooleanResult: (self executeScriptBody: bodyString)
		default: false
]

{ #category : 'private' }
GbsRemoteDebugProcessFacade >> executeOopBody: bodyString [
	| raw |
	raw := self executeScriptBody: bodyString.
	raw ifNil: [ ^ nil ].
	^ [ raw asInteger ]
		on: Error
		do: [ nil ]
]

{ #category : 'private' }
GbsRemoteDebugProcessFacade >> executeScriptBody: bodyString [
	| raw contextOop |
	self canExecute ifFalse: [ ^ nil ].
	contextOop := (session respondsTo: #sessionOop)
		ifTrue: [ ([ session sessionOop ] on: Error do: [ 20 ]) ifNil: [ 20 ] ]
		ifFalse: [ 20 ].
	((contextOop isNumber and: [ contextOop > 20 ]) not) ifTrue: [ contextOop := 20 ].
	raw := [ session executeAndFetch: (self processScriptForBody: bodyString) context: contextOop ]
		on: Error
		do: [ nil ].
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	^ raw
]

{ #category : 'querying' }
GbsRemoteDebugProcessFacade >> currentFrameOopAtLevel: levelValue [
	levelValue ifNil: [ ^ nil ].
	^ self executeOopBody: '[
		| frameObj |
		frameObj := [ proc _frameContentsAt: ', levelValue asString, ' ] on: Error do: [ nil ].
		frameObj ifNil: [ ^ ''0'' ].
		(Reflection oopOf: frameObj) asString
	] value'
]

{ #category : 'querying' }
GbsRemoteDebugProcessFacade >> currentReceiverOopAtLevel: levelValue [
	levelValue ifNil: [ ^ nil ].
	^ self executeOopBody: '[
		| frame fullEntry receiverObj |
		frame := [ proc _gsiDebuggerDetailedReportAt: ', levelValue asString, ' ] on: Error do: [ nil ].
		frame ifNil: [ ^ ''0'' ].
		fullEntry := [ frame first ] on: Error do: [ nil ].
		fullEntry ifNil: [ ^ ''0'' ].
		receiverObj := [ fullEntry at: 2 ] on: Error do: [ nil ].
		receiverObj ifNil: [ ^ ''0'' ].
		(Reflection oopOf: receiverObj) asString
	] value'
]

{ #category : 'querying' }
GbsRemoteDebugProcessFacade >> fullSourceAtLevel: levelValue [
	| raw |
	levelValue ifNil: [ ^ '' ].
	raw := self executeScriptBody: '[
		| stackReport fullEntry src ctx i |
		stackReport := [ proc _gsiStackReportFromLevel: ', levelValue asString, ' toLevel: ', levelValue asString, ' ] on: Error do: [ nil ].
		src := ''''.
		(stackReport notNil and: [ stackReport size >= 2 ]) ifTrue: [
			fullEntry := stackReport at: 2.
			(fullEntry notNil and: [ fullEntry size >= 9 ]) ifTrue: [
				src := [ fullEntry at: 9 ] on: Error do: [ '''' ].
				src ifNil: [ src := '''' ].
				src := src asString ] ].
		((src includes: Character lf) not) ifTrue: [
			ctx := [ proc topContext ] on: Error do: [ nil ].
			ctx ifNil: [
				(proc respondsTo: #sender)
					ifTrue: [ ctx := proc ] ].
			ctx ifNotNil: [
				i := 1.
				[ i < ', levelValue asString, ' and: [ ctx notNil ] ] whileTrue: [
					ctx := [ ctx sender ] on: Error do: [ nil ].
					i := i + 1 ].
				ctx ifNotNil: [
					src := [ ctx sourceCode ] on: Error do: [ src ].
					src ifNil: [ src := '''' ].
					src := src asString ] ] ].
		src isEmpty ifTrue: [ ^ '''' ].
		src := src
			copyReplaceAll: String cr with: ''<CR>'';
			copyReplaceAll: String lf with: ''<LF>'';
			copyReplaceAll: Character tab asString with: ''<TAB>''.
		src
	] value'.
	(raw isNil or: [ raw isEmpty ]) ifTrue: [
		raw := [ session evaluate: (self fullSourceFallbackScriptAtLevel: levelValue) ]
			on: Error
			do: [ '' ].
		(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ] ].
	raw ifNil: [ ^ '' ].
	^ ((raw copyReplaceAll: '<TAB>' with: Character tab asString)
		copyReplaceAll: '<CR>' with: String cr;
		copyReplaceAll: '<LF>' with: String lf)
]

{ #category : 'private' }
GbsRemoteDebugProcessFacade >> fullSourceFallbackScriptAtLevel: levelValue [
	^ String streamContents: [ :stream |
		stream nextPutAll: '[
		| obj stackReport fullEntry src ctx i |
		obj := Object _objectForOop: '.
		stream nextPutAll: processOop asString.
		stream nextPutAll: '.
		obj ifNil: [ ^ '''' ].
		stackReport := [ obj _gsiStackReportFromLevel: '.
		stream nextPutAll: levelValue asString.
		stream nextPutAll: ' toLevel: '.
		stream nextPutAll: levelValue asString.
		stream nextPutAll: ' ] on: Error do: [ nil ].
		src := ''''.
		(stackReport notNil and: [ stackReport size >= 2 ]) ifTrue: [
			fullEntry := stackReport at: 2.
			(fullEntry notNil and: [ fullEntry size >= 9 ]) ifTrue: [
				src := [ fullEntry at: 9 ] on: Error do: [ '''' ].
				src ifNil: [ src := '''' ].
				src := src asString ] ].
		((src includes: Character lf) not) ifTrue: [
			ctx := nil.
			(obj respondsTo: #topContext)
				ifTrue: [ ctx := [ obj topContext ] on: Error do: [ nil ] ].
			(ctx isNil and: [ obj respondsTo: #sender ])
				ifTrue: [ ctx := obj ].
			ctx ifNotNil: [
				i := 1.
				[ i < '.
		stream nextPutAll: levelValue asString.
		stream nextPutAll: ' and: [ ctx notNil ] ] whileTrue: [
					ctx := [ ctx sender ] on: Error do: [ nil ].
					i := i + 1 ].
				ctx ifNotNil: [
					src := [ ctx sourceCode ] on: Error do: [ src ].
					src ifNil: [ src := '''' ].
					src := src asString ] ] ].
		src isEmpty ifTrue: [ ^ '''' ].
		src := src
			copyReplaceAll: String cr with: ''<CR>'';
			copyReplaceAll: String lf with: ''<LF>'';
			copyReplaceAll: Character tab asString with: ''<TAB>''.
		src
	] value' ]
]

{ #category : 'querying' }
GbsRemoteDebugProcessFacade >> contextActivations [
	| raw |
	self canExecute ifFalse: [ ^ #() ].
	raw := self executeScriptBody: self contextActivationsScript.
	(raw respondsTo: #asLocalString) ifTrue: [ raw := raw asLocalString ].
	(raw isNil or: [ raw == false ]) ifTrue: [ ^ #() ].
	(raw respondsTo: #isEmpty) ifFalse: [ ^ #() ].
	raw isEmpty ifTrue: [ ^ #() ].
	^ self parseContextActivationsFrom: raw
]

{ #category : 'private' }
GbsRemoteDebugProcessFacade >> contextActivationsScript [
	^ '[
		| ctx stream depth level stackReport fullEntry selectorName methodName className quickStep offsets offsetsText lineNumber sourceText offset |
		stream := WriteStream on: String new.
		ctx := nil.
		(obj respondsTo: #sender) ifTrue: [ ctx := obj ].
		(ctx isNil and: [ obj respondsTo: #topContext ])
			ifTrue: [ ctx := [ obj topContext ] on: Error do: [ nil ] ].
		(ctx isNil and: [ proc notNil and: [ proc respondsTo: #topContext ] ])
			ifTrue: [ ctx := [ proc topContext ] on: Error do: [ nil ] ].

		(proc notNil and: [ proc respondsTo: #_gsiStackReportFromLevel:toLevel: ]) ifTrue: [
			level := 1.
			[ level <= 30 ] whileTrue: [
				stackReport := [ proc _gsiStackReportFromLevel: level toLevel: level ] on: Error do: [ nil ].
				(stackReport isNil or: [ stackReport size < 2 ])
					ifTrue: [ level := 31 ]
					ifFalse: [
						fullEntry := stackReport at: 2.
						className := [ fullEntry first inClass name ] on: Error do: [ ''<unknown>'' ].
						selectorName := [ (fullEntry at: 4) asString ] on: Error do: [ ''<unknown>'' ].
						methodName := [ (fullEntry first selector) asString ] on: Error do: [ ''<unknown>'' ].
						quickStep := [ (fullEntry at: 5) ] on: Error do: [ 0 ].
						quickStep ifNil: [ quickStep := 0 ].
						offsets := [ fullEntry at: 6 ] on: Error do: [ #() ].
						offsets ifNil: [ offsets := #() ].
						offsetsText := String streamContents: [ :offsetStream |
							1 to: offsets size do: [ :idx |
								| rawOffset |
								rawOffset := offsets at: idx.
								rawOffset isNil
									ifTrue: [ offsetStream nextPutAll: ''nil'' ]
									ifFalse: [ offsetStream nextPutAll: rawOffset asString ].
								idx < offsets size ifTrue: [ offsetStream nextPut: $, ] ] ].
						lineNumber := 0.
						sourceText := [ (fullEntry at: 9) asString ] on: Error do: [ '''' ].
						sourceText ifNil: [ sourceText := '''' ].
						(quickStep isNumber and: [ quickStep > 0 and: [ quickStep <= offsets size ] ]) ifTrue: [
							offset := [ (offsets at: quickStep) asInteger ] on: Error do: [ nil ].
							(offset isNumber and: [ offset > 0 ]) ifTrue: [
								lineNumber := 1.
								1 to: ((offset - 1) min: sourceText size) do: [ :i |
									| ch |
									ch := sourceText at: i.
									(ch = Character lf or: [ ch = Character cr ]) ifTrue: [ lineNumber := lineNumber + 1 ] ] ] ].
						stream
							nextPutAll: level asString; tab;
							nextPutAll: className; tab;
							nextPutAll: selectorName; tab;
							nextPutAll: methodName; tab;
							nextPutAll: quickStep asString; tab;
							nextPutAll: offsetsText; tab;
							nextPutAll: lineNumber asString;
							lf.
						level := level + 1 ] ].
			stream position > 0 ifTrue: [ ^ stream contents ] ].

		ctx ifNil: [ ^ '''' ].
		depth := 0.
		[ ctx notNil and: [ depth < 30 ] ] whileTrue: [
			className := [ ctx method inClass name ] on: Error do: [ ''<unknown>'' ].
			depth := depth + 1.
			stream
				nextPutAll: depth asString; tab;
				nextPutAll: className; tab;
				nextPutAll: (([ ctx selector asString ] on: Error do: [ ''<unknown>'' ])); tab;
				nextPutAll: (([ ctx method ifNil: [ ''<unknown>'' ] ifNotNil: [ :m | m selector asString ] ] on: Error do: [ ''<unknown>'' ]));
				lf.
			ctx := [ ctx sender ] on: Error do: [ nil ] ].
		stream contents
	] value'
]

{ #category : 'private' }
GbsRemoteDebugProcessFacade >> parseContextActivationsFrom: rawData [
	^ (rawData splitOn: Character lf)
		collect: [ :line |
			| parts levelValue classValue selectorValue methodValue quickStepValue offsetsTokens offsetsValue lineNumberValue |
			line isEmpty ifTrue: [ nil ] ifFalse: [
				parts := line splitOn: Character tab.
				parts size >= 3 ifTrue: [
					levelValue := ([ parts first asInteger ] on: Error do: [ 1 ]).
					classValue := (parts size >= 2 ifTrue: [ parts at: 2 ] ifFalse: [ '<unknown>' ]).
					selectorValue := (parts size >= 3 ifTrue: [ parts at: 3 ] ifFalse: [ '<unknown>' ]).
					methodValue := (parts size >= 4 ifTrue: [ parts at: 4 ] ifFalse: [ selectorValue ]).
					quickStepValue := (parts size >= 5
						ifTrue: [ [ (parts at: 5) asInteger ] on: Error do: [ 0 ] ]
						ifFalse: [ 0 ]).
					offsetsTokens := (parts size >= 6
						ifTrue: [ (parts at: 6) splitOn: $, ]
						ifFalse: [ #() ]).
					lineNumberValue := (parts size >= 7
						ifTrue: [ [ (parts at: 7) asInteger ] on: Error do: [ 0 ] ]
						ifFalse: [ 0 ]).
					offsetsValue := offsetsTokens collect: [ :token |
						| cleaned |
						cleaned := token withBlanksTrimmed.
						cleaned isEmpty ifTrue: [ nil ] ifFalse: [
							cleaned = 'nil'
								ifTrue: [ nil ]
								ifFalse: [ [ cleaned asInteger ] on: Error do: [ nil ] ] ] ].
					[ | activation |
					activation := GbxActivation new.
					(activation respondsTo: #session:)
						ifTrue: [ activation session: session ]
						ifFalse: [ activation instVarNamed: 'session' put: session ].
					activation
						processOop: processOop;
						level: levelValue;
						methodClass: classValue;
						selector: ([ selectorValue asSymbol ] on: Error do: [ #unknown ]);
						gsMethodId: methodValue;
						quickStepPoint: quickStepValue;
						sourceOffsets: offsetsValue;
						sourceString: '';
						ipOffset: lineNumberValue;
						yourself ]
						on: Error
						do: [ nil ] ] ] ]
		thenSelect: #isNotNil
]

{ #category : 'querying' }
GbsRemoteDebugProcessFacade >> resolvedProcessOop [
	^ self executeOopBody: '(Reflection oopOf: proc) asString'
]

{ #category : 'querying' }
GbsRemoteDebugProcessFacade >> isTerminated [
	self canExecute ifFalse: [ ^ true ].
	^ self executeBooleanBody: 'proc isTerminated'
]

{ #category : 'querying' }
GbsRemoteDebugProcessFacade >> oopForVariableNamed: aVariableName atLevel: levelValue [
	| escapedName |
	levelValue ifNil: [ ^ nil ].
	escapedName := aVariableName ifNil: [ '' ] ifNotNil: [ aVariableName asString copyReplaceAll: '''' with: '''''' ].
	^ self executeOopBody: '[
		| frame fullEntry receiverObj names vals idx value |
		frame := [ proc _gsiDebuggerDetailedReportAt: ', levelValue asString, ' ] on: Error do: [ nil ].
		frame ifNil: [ ^ ''0'' ].
		fullEntry := [ frame first ] on: Error do: [ nil ].
		fullEntry ifNil: [ ^ ''0'' ].
		(''', escapedName, ''' = ''self'') ifTrue: [
			receiverObj := [ fullEntry at: 2 ] on: Error do: [ nil ].
			receiverObj ifNil: [ ^ ''0'' ].
			^ (Reflection oopOf: receiverObj) asString
		].
		names := [ frame at: 7 ] on: Error do: [ #() ].
		vals := [ frame at: 8 ] on: Error do: [ #() ].
		idx := 0.
		1 to: (names size min: vals size) do: [ :i |
			(((names at: i) asString = ''', escapedName, ''') and: [ idx = 0 ])
				ifTrue: [ idx := i ]
		].
		idx = 0 ifTrue: [ ^ ''0'' ].
		value := [ vals at: idx ] on: Error do: [ nil ].
		value ifNil: [ ^ ''0'' ].
		(Reflection oopOf: value) asString
	] value'
]

{ #category : 'accessing' }
GbsRemoteDebugProcessFacade >> processOop [
	^ processOop
]

{ #category : 'accessing' }
GbsRemoteDebugProcessFacade >> processOop: anOop [
	processOop := anOop
]

{ #category : 'private' }
GbsRemoteDebugProcessFacade >> processScriptForBody: bodyString [
	^ String streamContents: [ :stream |
		stream nextPutAll: '[
		| obj proc |
		obj := Object _objectForOop: '.
		stream nextPutAll: processOop asString.
		stream nextPutAll: '.
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
		'.
		stream nextPutAll: bodyString.
		stream nextPutAll: '
	] value' ]
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> runCommand: commandName [
	commandName ifNil: [ ^ false ].
	^ self executeBooleanBody: '[ proc perform: #', commandName asString, ' ] on: Error do: [ ^ ''false'' ]. true'
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> runCommand: commandName withInteger: anInteger [
	(commandName isNil or: [ anInteger isNil ]) ifTrue: [ ^ false ].
	^ self executeBooleanBody: '[ proc perform: #', commandName asString, ': with: ', anInteger asString, ' ] on: Error do: [ ^ ''false'' ]. true'
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> runCommandCollectingContextActivations: commandName [
	(self runCommand: commandName) ifFalse: [ ^ nil ].
	^ self contextActivations
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> runCommand: commandName withIntegerCollectingContextActivations: anInteger [
	(self runCommand: commandName withInteger: anInteger) ifFalse: [ ^ nil ].
	^ self contextActivations
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> runToStepPoint: anInteger [
	((anInteger isNumber and: [ anInteger > 0 ]) not) ifTrue: [ ^ false ].
	(self runCommand: 'runToStepPoint' withInteger: anInteger) ifTrue: [ ^ true ].
	^ self runCommand: 'runTo' withInteger: anInteger
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> runToStepPointAndCollectContextActivations: anInteger [
	((anInteger isNumber and: [ anInteger > 0 ]) not) ifTrue: [ ^ nil ].
	(self runCommand: 'runToStepPoint' withIntegerCollectingContextActivations: anInteger) ifNotNil: [ :contexts |
		^ contexts ].
	^ self runCommand: 'runTo' withIntegerCollectingContextActivations: anInteger
]

{ #category : 'querying' }
GbsRemoteDebugProcessFacade >> restartLevelFromServerStack [
	| raw lines |
	raw := self executeScriptBody: '[
		| stream maxDepth level stackReport fullEntry methodOrNil className selectorName |
		(proc respondsTo: #_gsiStackReportFromLevel:toLevel:) ifFalse: [ ^ '''' ].
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
					level := level + 1 ] ].
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
				ifTrue: [ ^ [ parts first asInteger ] on: Error do: [ nil ] ] ] ].
	^ nil
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> resetProgramCounterToStepOneAtLevel: levelValue [
	levelValue ifNil: [ ^ false ].
	^ self executeBooleanBody: '[
		| tc restartLevel stackReport fullEntry quick |
		restartLevel := ', levelValue asString, '.
		(proc respondsTo: #_trimStackToLevel:) ifTrue: [
			[ proc _trimStackToLevel: restartLevel ] on: Error do: [ ] ].
		(proc respondsTo: #_gsiStepAtLevel:step:) ifTrue: [
			[ proc _gsiStepAtLevel: restartLevel step: 1 ] on: Error do: [ ] ].
		(proc respondsTo: #jumpToStepPoint:) ifTrue: [
			[ proc jumpToStepPoint: 1 ] on: Error do: [ ] ].
		(proc respondsTo: #runToStepPoint:) ifTrue: [
			[ proc runToStepPoint: 1 ] on: Error do: [ ] ].
		tc := [ proc topContext ] on: Error do: [ nil ].
		tc notNil ifTrue: [
			2 to: restartLevel do: [ :ignored |
				tc := [ tc sender ] on: Error do: [ nil ].
				tc ifNil: [ ignored := restartLevel ] ].
			tc ifNotNil: [
				(tc respondsTo: #jumpToStepPoint:) ifTrue: [
					[ tc jumpToStepPoint: 1 ] on: Error do: [ ] ].
				(tc respondsTo: #runToStepPoint:) ifTrue: [
					[ tc runToStepPoint: 1 ] on: Error do: [ ] ] ] ].
		(proc respondsTo: #_trimStackToLevel:) ifTrue: [
			[ proc _trimStackToLevel: restartLevel ] on: Error do: [ ] ].
		quick := 0.
		stackReport := [ proc _gsiStackReportFromLevel: restartLevel toLevel: restartLevel ] on: Error do: [ nil ].
		(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ]) ifTrue: [
			fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ].
			fullEntry ifNotNil: [ quick := [ (fullEntry at: 5) asInteger ] on: Error do: [ 0 ] ] ].
		(quick <= 1) ifTrue: [ ''true'' ] ifFalse: [ ''false'' ]
	] value'
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> restartUsingTrimAtExecutedFrameLevelOr: levelValue [
	levelValue ifNil: [ ^ false ].
	^ self executeBooleanBody: '[
		| restartLevel stackReport fullEntry quick level maxDepth methodOrNil className selectorName |
		restartLevel := ', levelValue asString, '.
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
									level := maxDepth + 1 ]
								ifFalse: [ level := level + 1 ] ] ] ].
		(proc respondsTo: #_trimStackToLevel:) ifFalse: [ ^ ''false'' ].
		[ proc _trimStackToLevel: restartLevel ] on: Error do: [ ^ ''false'' ].
		quick := 0.
		stackReport := [ proc _gsiStackReportFromLevel: 1 toLevel: 1 ] on: Error do: [ nil ].
		(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ]) ifTrue: [
			fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ].
			fullEntry ifNotNil: [
				quick := [ (fullEntry at: 5) asInteger ] on: Error do: [ 0 ] ] ].
		quick > 1 ifTrue: [
			(proc respondsTo: #jumpToStepPoint:)
				ifTrue: [ [ proc jumpToStepPoint: 1 ] on: Error do: [ ] ]
				ifFalse: [
					(proc respondsTo: #jumpTo:)
						ifTrue: [ [ proc jumpTo: 1 ] on: Error do: [ ] ] ] ].
		''true''
	] value'
]

{ #category : 'accessing' }
GbsRemoteDebugProcessFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsRemoteDebugProcessFacade >> session: aSession [
	session := aSession
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> stepOverFrameLevel: levelValue [
	levelValue ifNil: [ ^ false ].
	^ self executeBooleanBody: '[
		| stepLevel ok |
		(proc respondsTo: #perform:with:) ifFalse: [ ^ ''false'' ].
		stepLevel := ', levelValue asString, '.
		ok := [ proc perform: #_stepOverInFrame: with: stepLevel ] on: Error do: [ nil ].
		ok isNil ifTrue: [ ^ ''false'' ].
		''true''
	] value'
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> stepReturn [
	^ self runCommand: 'stepReturn'
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> stepReturnAndCollectContextActivations [
	^ self runCommandCollectingContextActivations: 'stepReturn'
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> stepOverExecutedFrameLevel: levelValue stepInto: aBoolean [
	| effectiveLevel |
	levelValue ifNil: [ ^ false ].
	effectiveLevel := levelValue.
	aBoolean ifTrue: [
		effectiveLevel := effectiveLevel bitOr: 16r100000000 ].
	^ self
		performStepSelector: '_stepOverInFrame:'
		fallbackSelector: nil
		atLevel: effectiveLevel
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> performStepSelector: primarySelector fallbackSelector: fallbackSelector atLevel: levelValue [
	| fallbackText |
	(primarySelector isNil or: [ levelValue isNil ]) ifTrue: [ ^ false ].
	fallbackText := fallbackSelector
		ifNil: [ '' ]
		ifNotNil: [ fallbackSelector asString ].
	^ self executeBooleanBody: '[
		| level selector ok |
		(proc respondsTo: #perform:with:) ifFalse: [ ^ ''false'' ].
		level := ', levelValue asString, '.
		selector := #', primarySelector asString, '.
		ok := [ proc perform: selector with: level ] on: Error do: [ nil ].
		(ok isNil and: [ ''', fallbackText, ''' notEmpty ]) ifTrue: [
			ok := [ proc perform: #', (fallbackSelector ifNil: [ '_doesNotExist:' ] ifNotNil: [ fallbackSelector asString ]), ' with: level ] on: Error do: [ nil ]
		].
		ok isNil ifTrue: [ ^ ''false'' ].
		''true''
	] value'
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> synchronizeProgramCounterAtLevel: levelValue [
	levelValue ifNil: [ ^ false ].
	^ self executeBooleanBody: '[
		(proc respondsTo: #_trimStackToLevel:) ifFalse: [ ^ ''false'' ].
		[ proc _trimStackToLevel: ', levelValue asString, ' ] on: Error do: [ ^ ''false'' ].
		''true''
	] value'
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> trimStackToLevel: levelValue [
	levelValue ifNil: [ ^ false ].
	^ self executeBooleanBody: '[
		(proc respondsTo: #_trimStackToLevel:) ifFalse: [ ^ ''false'' ].
		[ proc _trimStackToLevel: ', levelValue asString, ' ] on: Error do: [ ^ ''false'' ].
		''true''
	] value'
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> returnFromFrame [
	^ self stepReturn
]

{ #category : 'actions' }
GbsRemoteDebugProcessFacade >> returnFromFrameAndCollectContextActivations [
	^ self stepReturnAndCollectContextActivations
]
