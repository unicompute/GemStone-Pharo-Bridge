Class {
	#name : 'GbsRemoteDebuggerTest',
	#superclass : 'TestCase',
	#instVars : [
		'session'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsRemoteDebuggerTest >> setUp [
	| runLive sessionCandidate |
	super setUp.
	runLive := Smalltalk globals
		at: #GbsRunLiveDebuggerTests
		ifAbsent: [ false ].
	runLive ifFalse: [
		session := nil.
		^ self
	].

	sessionCandidate := GbsSessionParameters currentSession.
	session := sessionCandidate.
	session ifNotNil: [
		((session respondsTo: #isLoggedIn) and: [ session isLoggedIn not ]) ifTrue: [
			session := nil
		].
		((session respondsTo: #sessionOop)
			and: [ session sessionOop isNil or: [ session sessionOop <= 1 ] ]) ifTrue: [
			session := nil
		]
	]
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextOopIsValid [
	"Validate the error-driven oop that the remote debugger actually uses."
	| raisedError processOop |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].
	self assert: processOop notNil.
	self deny: processOop equals: 0.
	self deny: processOop equals: 20.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testFetchContextsDirectlyParsesRowsWithOnlyThreeOrFourColumns [
	| debugger mockSession contexts |

	mockSession := MockGbsSession new.
	mockSession stubs
		at: #evaluate
		put: '1	AbstractException	_signalToDebugger',
			String lf,
			'2	SmallInteger	/	/'.

	debugger := GbsRemoteDebugger new.
	debugger session: mockSession.
	debugger processOop: 222.

	contexts := debugger fetchContextsDirectly.

	self assert: contexts size equals: 2.
	self assert: (contexts first respondsTo: #selectorOrUnknown).
	self assert: (contexts first selectorOrUnknown) equals: #_signalToDebugger.
	self assert: (contexts second selectorOrUnknown) equals: #/.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextHasSender [
	self skip: 'Live sender-chain FFI probe disabled (can crash current VM/image).'
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextSourceCode [
	| raisedError processOop service contexts topContext sourceCode |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.
	service initializeForDebugging.

	contexts := service contextList.
	self assert: contexts notEmpty.
	topContext := contexts first.
	sourceCode := topContext sourceCode.
	self assert: sourceCode notNil.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextMethod [
	| activeSession raisedError processOop service contexts topContext |

	(Smalltalk globals at: #GbsRunDangerousLiveDebuggerTests ifAbsent: [ false ]) ifFalse: [
		self skip: 'Dangerous live FFI test disabled'
	].

	activeSession := session ifNil: [ GbsSessionParameters currentSession ].
	activeSession ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		activeSession execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].

	service := GbxDebuggerService new.
	service
		session: activeSession;
		processOop: processOop.
	service initializeForDebugging.

	contexts := service contextList.
	self assert: contexts notEmpty.
	topContext := contexts first.
	self assert: topContext gsMethodIdOrUnknown ~= '<unknown>'.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testContextSelector [
	| raisedError processOop service contexts topContext |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.
	service initializeForDebugging.

	contexts := service contextList.
	self assert: contexts notEmpty.
	topContext := contexts first.
	self deny: topContext selectorOrUnknown equals: #unboundMethod.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testErrorContextFetch [
	"Test fetching context from an actual error"
	| contextOop script |
	
	session ifNil: [ self skip: 'No session' ].
	
	"Execute code that will error and capture the context"
	script := '[
		[ 1 / 0 ] on: Error do: [ :ex |
			| ctx |
			ctx := Processor activeProcess topContext.
			[ ctx notNil and: [ ctx selector == #divide: ] ] whileTrue: [
				ctx := ctx sender.
			].
			ctx asOop
		]
	] value'.
	
	contextOop := session evaluate: script.
	
	Transcript show: 'Error context OOP: ', contextOop asString; cr.
	
	contextOop ifNotNil: [
		"Try to get source code"
		| sourceCode |
		sourceCode := session evaluate: '[
			| ctx |
			ctx := Object _objectForOop: ', contextOop asString, '.
			ctx sourceCode
		] value'.
		
		Transcript show: 'Error context source: ', sourceCode; cr.
	].
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testSimpleStackWalk [
	| raisedError processOop service contexts summary |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.
	service initializeForDebugging.

	contexts := service contextList.
	self assert: contexts notEmpty.
	summary := contexts collect: [ :ctx | ctx printString ].
	self assert: summary notEmpty.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testZeroDivideErrorCarriesServerProcessOop [
	| raisedError |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	self assert: (raisedError respondsTo: #serverProcessOop).
	self assert: raisedError serverProcessOop isNotNil.
	self deny: raisedError serverProcessOop equals: 0.
	self deny: raisedError serverProcessOop equals: 20.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testZeroDivideBuildsNonEmptyContextListFromDebuggerService [
	| raisedError processOop service contexts |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].
	self assert: processOop notNil.
	self deny: processOop equals: 20.

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.
	service initializeForDebugging.

	contexts := service contextList.
	self assert: contexts notEmpty.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testZeroDivideScriptServerSideStackDumpHasFrames [
	| raisedError stackText |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	stackText := self frameProbeTextForOop: raisedError serverProcessOop.
	(stackText isNil or: [ stackText isEmpty ]) ifTrue: [
		stackText := self frameProbeTextForOop: raisedError exceptionOop
	].

	Transcript show: 'testZeroDivideScriptServerSideStackDumpHasFrames:'; cr.
	Transcript show: (stackText ifNil: [ '<nil>' ]); cr.

	self assert: stackText notNil.
	self deny: stackText isEmpty.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testZeroDivideErrorOopsFrameProbe [
	| raisedError contextFrames exceptionFrames |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.

	contextFrames := self frameProbeTextForOop: raisedError serverProcessOop.
	exceptionFrames := self frameProbeTextForOop: raisedError exceptionOop.

	Transcript show: 'contextOop probe:'; cr.
	Transcript show: contextFrames; cr.
	Transcript show: 'exceptionOop probe:'; cr.
	Transcript show: exceptionFrames; cr.

	"At least one should provide usable frame text."
	self assert: ((contextFrames isNil or: [ contextFrames isEmpty ]) not
		or: [ (exceptionFrames isNil or: [ exceptionFrames isEmpty ]) not ]).
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testZeroDivideContextListContainsUserSourceFrame [
	| raisedError processOop service contexts userFrame |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.
	service initializeForDebugging.

	contexts := service contextList.
	self assert: contexts notEmpty.

	userFrame := contexts
		detect: [ :ctx | (ctx sourceCode includesSubstring: 'a / b') ]
		ifNone: [ nil ].
	self assert: userFrame notNil.
]

{ #category : 'tests' }
GbsRemoteDebuggerTest >> testZeroDivideUserFrameTempVariablesIncludeAAndB [
	| raisedError processOop service contexts userFrame temps |

	session ifNil: [ self skip: 'No session' ].

	raisedError := nil.
	[
		session execute: '| a b | a := 10. b := 0. a / b'.
	] on: GbsError do: [ :ex | raisedError := ex ].

	self assert: raisedError notNil.
	processOop := raisedError serverProcessOop ifNil: [ raisedError tag ].

	service := GbxDebuggerService new.
	service
		session: session;
		processOop: processOop.
	service initializeForDebugging.
	contexts := service contextList.

	userFrame := contexts
		detect: [ :ctx | (ctx sourceCode includesSubstring: 'a / b') ]
		ifNone: [ nil ].
	self assert: userFrame notNil.

	temps := userFrame tempNamesAndValues.
	self assert: (temps respondsTo: #includesKey:).
	self assert: (temps includesKey: 'a').
	self assert: (temps includesKey: 'b').
]

{ #category : 'private' }
GbsRemoteDebuggerTest >> frameProbeTextForOop: anOop [
	| oopText |

	(anOop isNil or: [ anOop = 0 or: [ anOop = 20 ] ]) ifTrue: [ ^ '' ].
	oopText := anOop asString.

	^ session evaluate: '[
		| obj proc ctx stream level stackReport fullEntry |
		obj := Object _objectForOop: ', oopText, '.
		obj isNil ifTrue: [ ^ '''' ].
		stream := WriteStream on: String new.

		proc := nil.
		(obj respondsTo: #_gsiStackReportFromLevel:toLevel:) ifTrue: [ proc := obj ].
		proc isNil ifTrue: [
			(obj respondsTo: #serverProcess)
				ifTrue: [ proc := [ obj serverProcess ] on: Error do: [ nil ] ]
		].
		proc isNil ifTrue: [
			(obj respondsTo: #process)
				ifTrue: [ proc := [ obj process ] on: Error do: [ nil ] ]
		].
		proc isNil ifTrue: [
			(obj respondsTo: #topContext) ifTrue: [
				ctx := [ obj topContext ] on: Error do: [ nil ].
				(ctx notNil and: [ ctx respondsTo: #process ])
					ifTrue: [ proc := [ ctx process ] on: Error do: [ nil ] ]
			]
		].

		(proc notNil and: [ proc respondsTo: #_gsiStackReportFromLevel:toLevel: ]) ifTrue: [
			level := 1.
			[ level <= 30 ] whileTrue: [
				stackReport := [ proc _gsiStackReportFromLevel: level toLevel: level ] on: Error do: [ nil ].
				(stackReport isNil or: [ stackReport size < 2 ])
					ifTrue: [ level := 31 ]
					ifFalse: [
						fullEntry := stackReport at: 2.
						stream
							nextPutAll: level asString; tab;
							nextPutAll: ((fullEntry size >= 4 and: [ (fullEntry at: 4) notNil ])
								ifTrue: [ (fullEntry at: 4) asString ]
								ifFalse: [ ''<no selector>'' ]);
							lf.
						level := level + 1
					]
			]
		].

		stream position = 0 ifTrue: [
			ctx := nil.
			(obj respondsTo: #sender) ifTrue: [ ctx := obj ].
			(ctx isNil and: [ obj respondsTo: #topContext ])
				ifTrue: [ ctx := [ obj topContext ] on: Error do: [ nil ] ].
			level := 1.
			[ ctx notNil and: [ level <= 30 ] ] whileTrue: [
				stream
					nextPutAll: level asString; tab;
					nextPutAll: (([ ctx selector asString ] on: Error do: [ ''<no selector>'' ]));
					lf.
				ctx := [ ctx sender ] on: Error do: [ nil ].
				level := level + 1
			]
		].

		stream contents
	] value'
]
