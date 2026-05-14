Class {
	#name : 'GbsRemoteDebuggerStackFetcher',
	#superclass : 'Object',
	#instVars : [
		'debugger'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsRemoteDebuggerStackFetcher class >> on: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'accessing' }
GbsRemoteDebuggerStackFetcher >> debugger [
	^ debugger
]

{ #category : 'accessing' }
GbsRemoteDebuggerStackFetcher >> debugger: aDebugger [
	debugger := aDebugger
]

{ #category : 'private' }
GbsRemoteDebuggerStackFetcher >> contextsFromRawStackData: rawData session: session processOop: processOop [
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
								ifFalse: [ [ cleaned asInteger ] on: Error do: [ nil ] ]
						]
					].
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
						yourself
					] on: Error do: [ nil ]
				]
			]
		] thenSelect: #isNotNil
]

{ #category : 'fetching' }
GbsRemoteDebuggerStackFetcher >> fetchContextsDirectly [
	| session processOop rawData |
	session := debugger session.
	processOop := debugger processOop.
	processOop ifNil: [ ^ #( ) ].
	processOop = 0 ifTrue: [ ^ #( ) ].

	[
		rawData := self stackReportIn: session processOop: processOop.
		(rawData respondsTo: #asLocalString) ifTrue: [ rawData := rawData asLocalString ].
		rawData ifNil: [ rawData := '' ].
	] on: Error do: [ :ex |
		^ #( )
	].

	rawData ifNil: [ ^ #( ) ].
	rawData = false ifTrue: [ ^ #( ) ].
	(rawData respondsTo: #isEmpty) ifFalse: [ ^ #( ) ].
	rawData isEmpty ifTrue: [ ^ #( ) ].

	^ self
		contextsFromRawStackData: rawData
		session: session
		processOop: processOop
]

{ #category : 'private' }
GbsRemoteDebuggerStackFetcher >> stackReportCommandBody [
	^ '
		| ctx proc stream depth level stackReport fullEntry selectorName methodName className quickStep offsets offsetsText lineNumber sourceText offset |
		stream := WriteStream on: String new.
		obj ifNotNil: [
			ctx := nil.
			proc := nil.
			(obj respondsTo: #sender) ifTrue: [ ctx := obj ].
			(ctx isNil and: [ obj respondsTo: #topContext ])
				ifTrue: [ ctx := [ obj topContext ] on: Error do: [ nil ] ].
			(ctx isNil and: [ obj respondsTo: #process ])
				ifTrue: [ proc := [ obj process ] on: Error do: [ nil ] ].
			(proc isNil and: [ obj respondsTo: #_gsiStackReportFromLevel:toLevel: ])
				ifTrue: [ proc := obj ].
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
									| raw |
									raw := offsets at: idx.
									raw isNil
										ifTrue: [ offsetStream nextPutAll: ''nil'' ]
										ifFalse: [ offsetStream nextPutAll: raw asString ].
									idx < offsets size ifTrue: [ offsetStream nextPut: $, ]
								]
							].
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
										(ch = Character lf or: [ ch = Character cr ]) ifTrue: [ lineNumber := lineNumber + 1 ]
									]
								]
							].
							stream
								nextPutAll: level asString; tab;
								nextPutAll: className; tab;
								nextPutAll: selectorName; tab;
								nextPutAll: methodName; tab;
								nextPutAll: quickStep asString; tab;
								nextPutAll: offsetsText; tab;
								nextPutAll: lineNumber asString;
								lf.
							level := level + 1
						]
				].
			].

			stream position = 0 ifTrue: [
				ctx
					ifNil: [ stream nextPutAll: ''<ctx is nil>'' ]
					ifNotNil: [
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
							ctx := [ ctx sender ] on: Error do: [ nil ].
						]
					]
			].
		].
		stream contents
	'
]

{ #category : 'private' }
GbsRemoteDebuggerStackFetcher >> stackReportIn: aSession processOop: processOop [
	^ GbsRemoteExecutionDispatcher
		fetchCommandBody: self stackReportCommandBody
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'obj' put: processOop;
			yourself)
		in: aSession
		context: 20
]
