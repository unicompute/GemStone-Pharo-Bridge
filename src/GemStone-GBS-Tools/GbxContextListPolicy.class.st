"
GbxContextListPolicy handles context list management for the GemStone remote debugger.

Its main responsibility is assembling the logical stack visible in the debugger.
The logical stack contains contexts from GemStone server execution as well as 
client Smalltalk execution. It follows a logical thread of execution that may 
pass from the client to the server in an execute, remotePerform, or forwarder send, 
and may pass back to the client in a clientForwarder send, and so on back and forth.

Usually, the user of the debugger doesn't want to see the ""glue"" code used by 
GBS to implement sends between client and server, so GbxContextListPolicy omits 
these glue contexts from its logical stack. For tough debugging scenarios, however, 
the user can choose to show the glue and see the entire true stack.

Based on VisualWorks GbxContextListPolicy class.
"
Class {
	#name : 'GbxContextListPolicy',
	#superclass : 'Object',
	#instVars : [
		'glueIsHidden',
		'contextList',
		'serverCallContext',
		'debugger'
	],
	#classVars : [
		'GlueIsHiddenDefault'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxContextListPolicy class >> debugger: aDebugger [
	^ self new
		debugger: aDebugger;
		yourself
]

{ #category : 'class initialization' }
GbxContextListPolicy class >> initialize [
	GlueIsHiddenDefault := true
]

{ #category : 'private' }
GbxContextListPolicy >> bottomGlueFrom: topGlueContext [
	"VW parity: given the top context of a glue run, find the bottom glue context."
	| ctx bottomGlue |
	ctx := topGlueContext.
	[ ctx isNil or: [ self isServerCallContext: ctx ] ]
		whileFalse: [ ctx := [ ctx sender ] on: Error do: [ nil ] ].
	ctx isNil ifTrue: [ ctx := topGlueContext ].

	bottomGlue := topGlueContext.
	[
		ctx := [ ctx sender ] on: Error do: [ nil ].
		ctx isNil or: [ (self isServerCallContext: ctx) or: [ self isTopGlueContext: ctx ] ]
	] whileFalse: [
		(self isBottomGlueContext: ctx) ifTrue: [ bottomGlue := ctx ]
	].
	^ bottomGlue
]

{ #category : 'private' }
GbxContextListPolicy >> clientContextsStartingAt: aContext [
	| contexts ctx |
	contexts := OrderedCollection new.
	ctx := aContext.
	[ ctx notNil ] whileTrue: [
		contexts add: ctx.
		ctx := [ ctx sender ] on: Error do: [ nil ].
	].
	^ contexts
]

{ #category : 'private' }
GbxContextListPolicy >> clientContextsStartingAt: aContext upToContextExclusive: stopContext [
	| contexts ctx |
	contexts := OrderedCollection new.
	ctx := aContext.
	[ ctx notNil and: [ ctx ~~ stopContext ] ] whileTrue: [
		contexts add: ctx.
		ctx := [ ctx sender ] on: Error do: [ nil ].
	].
	^ contexts
]

{ #category : 'context list' }
GbxContextListPolicy >> computeContextList [
	"Compute the logical context list from GemStone plus any client contexts
	above the top server context (VW mixed-stack parity)."
	| allContexts serverContexts topServerContext firstClientContext marker |

	serverContexts := self fetchServerContexts.
	allContexts := OrderedCollection new.
	allContexts addAll: serverContexts.

	topServerContext := serverContexts ifEmpty: [ nil ] ifNotEmpty: [ serverContexts first ].
	topServerContext ifNotNil: [
		firstClientContext := self firstClientContextAbove: topServerContext.
		firstClientContext ifNotNil: [
			marker := self matchingServerCallMarkerForServerContext: topServerContext.
			allContexts addAll: (self
				clientContextsStartingAt: firstClientContext
				upToContextExclusive: marker)
		]
	].
	
	glueIsHidden 
		ifTrue: [ contextList := self filterOutGlue: allContexts ]
		ifFalse: [ contextList := allContexts ].
	
	^ contextList
]

{ #category : 'context list' }
GbxContextListPolicy >> contextList [
	^ contextList ifNil: [ #( ) ]
]

{ #category : 'initialization' }
GbxContextListPolicy >> debugger: aDebugger [
	debugger := aDebugger.
	glueIsHidden := GlueIsHiddenDefault
]

{ #category : 'context list' }
GbxContextListPolicy >> fetchServerContexts [
	"Fetch server activations using the VW flow:
	serverCall/error oop -> gbsError -> serverProcess -> stack report."
	| processOop script rawData contexts |
	
	processOop := debugger processOop.
	(processOop isNil or: [ processOop = 20 ]) ifTrue: [ ^ #( ) ].
	
	script := '[
		| obj gbsError gsProcess ctx stream maxDepth level frame stackReport fullEntry methodOrNil className selectorName source ctxOop quickStep offsets offsetsText lineNumber offset |
		obj := Object _objectForOop: ', processOop asString, '.
		obj isNil ifTrue: [ ^ '''' ].
		stream := WriteStream on: String new.
		gbsError := nil.
		gsProcess := nil.
		ctx := nil.

		(obj respondsTo: #serverProcess) ifTrue: [ gbsError := obj ].
		gbsError isNil ifTrue: [
			(obj respondsTo: #gbxResult)
				ifTrue: [ gbsError := [ obj gbxResult ] on: Error do: [ nil ] ]
		].
		gbsError notNil ifTrue: [
			gsProcess := [ gbsError serverProcess ] on: Error do: [ nil ]
		].
		gsProcess isNil ifTrue: [
			(obj respondsTo: #_gsiStackReportFromLevel:toLevel:)
				ifTrue: [ gsProcess := obj ]
		].
		gsProcess isNil ifTrue: [
			(obj respondsTo: #process)
				ifTrue: [ gsProcess := [ obj process ] on: Error do: [ nil ] ]
		].
		(gsProcess isNil and: [ obj respondsTo: #topContext ]) ifTrue: [
			ctx := [ obj topContext ] on: Error do: [ nil ].
			(ctx notNil and: [ ctx respondsTo: #process ])
				ifTrue: [ gsProcess := [ ctx process ] on: Error do: [ nil ] ]
		].

		((gsProcess notNil) and: [
			(gsProcess respondsTo: #_gsiStackReportFromLevel:toLevel:)
				or: [ gsProcess respondsTo: #_gsiDebuggerDetailedReportAt: ] ]) ifTrue: [
			maxDepth := 200.
			level := 1.
			[ level <= maxDepth ] whileTrue: [
				fullEntry := nil.
				(gsProcess respondsTo: #_gsiStackReportFromLevel:toLevel:)
					ifTrue: [
						stackReport := [ gsProcess _gsiStackReportFromLevel: level toLevel: level ] on: Error do: [ nil ].
						(stackReport notNil and: [ (stackReport respondsTo: #size) and: [ stackReport size >= 2 ] ])
							ifTrue: [ fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ] ]
					].
				fullEntry isNil ifTrue: [
					(gsProcess respondsTo: #_gsiDebuggerDetailedReportAt:) ifTrue: [
						frame := [ gsProcess _gsiDebuggerDetailedReportAt: level ] on: Error do: [ nil ].
						(frame notNil and: [ (frame respondsTo: #size) and: [ frame size >= 1 ] ])
							ifTrue: [ fullEntry := [ frame first ] on: Error do: [ nil ] ]
					]
				].
				fullEntry isNil
					ifTrue: [ level := maxDepth + 1 ]
					ifFalse: [
						methodOrNil := ((fullEntry respondsTo: #at:) and: [ fullEntry size >= 1 ])
							ifTrue: [ [ fullEntry at: 1 ] on: Error do: [ nil ] ]
							ifFalse: [ nil ].
						className := [
							methodOrNil ifNil: [ ''<unknown>'' ] ifNotNil: [
								methodOrNil inClass ifNil: [ ''<unknown>'' ] ifNotNil: [ methodOrNil inClass name ]
							]
						] on: Error do: [ ''<unknown>'' ].
						selectorName := [
							methodOrNil ifNil: [
								((fullEntry respondsTo: #size) and: [ fullEntry size >= 4 ])
									ifTrue: [
										(fullEntry at: 4)
											ifNil: [ ''<unknown>'' ]
											ifNotNil: [ :sel | sel asString ]
									]
									ifFalse: [ ''<unknown>'' ]
							] ifNotNil: [
								[ methodOrNil selector asString ] on: Error do: [ ''<unknown>'' ]
							]
						] on: Error do: [ ''<unknown>'' ].
						source := [
							((fullEntry respondsTo: #size) and: [ fullEntry size >= 9 ])
								ifTrue: [
									(fullEntry at: 9)
										ifNil: [ '''' ]
										ifNotNil: [ :src | src asString ]
								]
								ifFalse: [ '''' ]
						] on: Error do: [ '''' ].
						quickStep := [
							((fullEntry respondsTo: #size) and: [ fullEntry size >= 5 ])
								ifTrue: [ fullEntry at: 5 ]
								ifFalse: [ 0 ]
						] on: Error do: [ 0 ].
						quickStep ifNil: [ quickStep := 0 ].
						offsets := [
							((fullEntry respondsTo: #size) and: [ fullEntry size >= 6 ])
								ifTrue: [ fullEntry at: 6 ]
								ifFalse: [ #() ]
						] on: Error do: [ #() ].
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
						(quickStep isNumber and: [ quickStep > 0 and: [ quickStep <= offsets size ] ]) ifTrue: [
							offset := [ (offsets at: quickStep) asInteger ] on: Error do: [ nil ].
							(offset isNumber and: [ offset > 0 ]) ifTrue: [
								lineNumber := 1.
								1 to: ((offset - 1) min: source size) do: [ :i |
									| ch |
									ch := source at: i.
									(ch = Character lf or: [ ch = Character cr ]) ifTrue: [ lineNumber := lineNumber + 1 ]
								]
							]
						].
						source := source
							copyReplaceAll: String cr with: ''<CR>'';
							copyReplaceAll: String lf with: ''<LF>'';
							copyReplaceAll: Character tab asString with: ''<TAB>''.
						ctxOop := [ gsProcess asOop printString ] on: Error do: [ ''0'' ].
						stream
							nextPutAll: level asString; tab;
							nextPutAll: className; tab;
							nextPutAll: selectorName; tab;
							nextPutAll: source; tab;
							nextPutAll: ctxOop; tab;
							nextPutAll: quickStep asString; tab;
							nextPutAll: offsetsText; tab;
							nextPutAll: lineNumber asString;
							lf.
						level := level + 1
					]
			]
		].

		"Fallback: sender-chain walk when stack report is unavailable."
		stream position = 0 ifTrue: [
			ctx isNil ifTrue: [
				(obj respondsTo: #sender) ifTrue: [ ctx := obj ].
				(ctx isNil and: [ gsProcess notNil and: [ gsProcess respondsTo: #topContext ] ])
					ifTrue: [ ctx := [ gsProcess topContext ] on: Error do: [ nil ] ]
			].
			maxDepth := 200.
			level := 1.
			[ ctx notNil and: [ level <= maxDepth ] ] whileTrue: [
				className := [ ctx method inClass name ] on: Error do: [ ''<unknown>'' ].
				selectorName := [ ctx selector asString ] on: Error do: [ ''<unknown>'' ].
				source := [ ctx sourceCode ] on: Error do: [ '''' ].
				source := source ifNil: [ '''' ].
				source := source
					copyReplaceAll: String cr with: ''<CR>'';
					copyReplaceAll: String lf with: ''<LF>'';
					copyReplaceAll: Character tab asString with: ''<TAB>''.
				ctxOop := [ ctx asOop printString ] on: Error do: [ ''0'' ].
				stream
					nextPutAll: level asString; tab;
					nextPutAll: className; tab;
					nextPutAll: selectorName; tab;
					nextPutAll: source; tab;
					nextPutAll: ctxOop;
					lf.
				ctx := [ ctx sender ] on: Error do: [ nil ].
				level := level + 1
			]
		].
		stream contents
	] value'.
	
	rawData := [ debugger session evaluate: script ] on: Error do: [ nil ].
	(rawData respondsTo: #asLocalString) ifTrue: [ rawData := rawData asLocalString ].
	rawData ifNil: [ rawData := '' ].
	rawData = false ifTrue: [ rawData := '' ].
	rawData = 'nil' ifTrue: [ rawData := '' ].
	(rawData respondsTo: #splitOn) ifFalse: [ rawData := '' ].
	contexts := (rawData splitOn: Character lf) 
		collect: [ :line | 
			| parts |
			parts := line splitOn: Character tab.
			parts size >= 5 ifTrue: [
				| activation selectorSymbol ctxOop quickStepValue offsetsTokens offsetsValue lineNumberValue |
				selectorSymbol := [ (parts at: 3) asSymbol ] on: Error do: [ #unboundMethod ].
				ctxOop := [ (parts at: 5) asInteger ] on: Error do: [ processOop ].
				quickStepValue := (parts size >= 6
					ifTrue: [ [ (parts at: 6) asInteger ] on: Error do: [ 0 ] ]
					ifFalse: [ 0 ]).
				offsetsTokens := (parts size >= 7
					ifTrue: [ (parts at: 7) splitOn: $, ]
					ifFalse: [ #() ]).
				lineNumberValue := (parts size >= 8
					ifTrue: [ [ (parts at: 8) asInteger ] on: Error do: [ 0 ] ]
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
				activation := GbxActivation new.
				(activation respondsTo: #session:)
					ifTrue: [ activation session: debugger session ]
					ifFalse: [ activation instVarNamed: 'session' put: debugger session ].
				activation
					level: ([ parts first asInteger ] on: Error do: [ 1 ]);
					initializeFromClass: (parts at: 2)
						selector: selectorSymbol
						source: ((((parts at: 4)
							copyReplaceAll: '<TAB>' with: Character tab asString)
							copyReplaceAll: '<CR>' with: String cr)
							copyReplaceAll: '<LF>' with: String lf)
						contextOop: ctxOop;
					quickStepPoint: quickStepValue;
					sourceOffsets: offsetsValue;
					ipOffset: lineNumberValue;
					yourself
			]
		] thenSelect: #isNotNil.
	
	^ contexts
]

{ #category : 'context list' }
GbxContextListPolicy >> filterOutGlue: contexts [
	"Filter out GBS glue contexts from the context list"
	| filtered |
	filtered := contexts select: [ :ctx | 
		(self isGlue: ctx) not
	].
	^ filtered
]

{ #category : 'context list' }
GbxContextListPolicy >> firstClientContextAbove: gsContext [
	"Ported from VW: find nearest non-glue client context above gsContext,
	bounded by the matching server-call glue marker for that server process."
	| ctx bestSoFar targetGsProcess rcvr markerProcess |
	gsContext ifNil: [ ^ nil ].
	bestSoFar := nil.
	targetGsProcess := self processIdentityForContext: gsContext.
	ctx := (debugger respondsTo: #topContext)
		ifTrue: [ debugger topContext ]
		ifFalse: [ nil ].
	[ ctx notNil ] whileTrue: [
		(self isGlue: ctx)
			ifFalse: [ bestSoFar := ctx ]
			ifTrue: [
				rcvr := [ ctx receiver ] on: Error do: [ nil ].
				markerProcess := self processIdentityForErrorLike: rcvr.
				(markerProcess notNil and: [ markerProcess = targetGsProcess ])
					ifTrue: [ ^ bestSoFar ]
			].
		ctx := [ ctx sender ] on: Error do: [ nil ].
	].
	^ nil
]

{ #category : 'accessing' }
GbxContextListPolicy >> glueIsHidden [
	^ glueIsHidden
]

{ #category : 'accessing' }
GbxContextListPolicy >> glueIsHidden: aBoolean [
	glueIsHidden := aBoolean
]

{ #category : 'private' }
GbxContextListPolicy >> isBottomGlueContext: aContext [
	(aContext respondsTo: #gbxIsGsBottomGlue)
		ifTrue: [ ^ aContext gbxIsGsBottomGlue ].
	^ false
]

{ #category : 'private' }
GbxContextListPolicy >> isDirectGlueContext: aContext [
	| className |
	aContext ifNil: [ ^ false ].
	(aContext respondsTo: #isGlue) ifTrue: [ ^ aContext isGlue ].
	(self isServerCallContext: aContext) ifTrue: [ ^ true ].
	(self isTopGlueContext: aContext) ifTrue: [ ^ true ].
	(self isBottomGlueContext: aContext) ifTrue: [ ^ true ].
	(aContext respondsTo: #gbxIsGsGlue)
		ifTrue: [ aContext gbxIsGsGlue ifTrue: [ ^ true ] ].
	(aContext respondsTo: #gbxIsServerContext)
		ifTrue: [ aContext gbxIsServerContext ifTrue: [ ^ self isGlueContext: aContext ] ].
	className := aContext class name asString.
	((className beginsWith: 'Gbs') or: [ className beginsWith: 'Gbx' ])
		ifTrue: [ ^ true ].
	^ false
]

{ #category : 'testing' }
GbxContextListPolicy >> isFullStack [
	"Check if displaying full stack (glue shown)"
	^ glueIsHidden not
]

{ #category : 'testing' }
GbxContextListPolicy >> isGlue: aContext [
	| inGlue nextVisibleContext ctx |
	aContext ifNil: [ ^ false ].

	(self isDirectGlueContext: aContext) ifTrue: [ ^ true ].

	"VW parity: a context can be glue even when it is not itself marked as top/bottom
	if it lies inside a top-glue to bottom-glue run."
	inGlue := false.
	nextVisibleContext := nil.
	ctx := (debugger respondsTo: #topContext)
		ifTrue: [ debugger topContext ]
		ifFalse: [ nil ].
	[ ctx notNil ] whileTrue: [
		inGlue
			ifTrue: [ ctx == nextVisibleContext ifTrue: [ inGlue := false ] ]
			ifFalse: [
				(self isTopGlueContext: ctx) ifTrue: [
					inGlue := true.
					nextVisibleContext := (self bottomGlueFrom: ctx) sender
				]
			].
		ctx == aContext ifTrue: [ ^ inGlue ].
		ctx := [ ctx sender ] on: Error do: [ nil ].
	].
	^ false
]

{ #category : 'testing' }
GbxContextListPolicy >> isGlueContext: aContext [
	"Check if a context is GBS glue code or server-side exception plumbing that should be hidden."
	| className selector |
	className := aContext methodClass ifNil: [ ^ false ].
	selector := aContext selector ifNil: [ ^ false ].

	"Server-side exception plumbing and VM return frames should be hidden by default."
	(className = 'AbstractException') ifTrue: [ 
		^ #( #signal #_signal #defaultAction #_defaultAction #_signalToDebugger ) includes: selector
	].
	(className = 'GsNMethod class') ifTrue: [ 
		^ #( #_gsReturnToC ) includes: selector
	].
	((className = 'Number') and: [ selector = #_errorDivideByZero ]) ifTrue: [ ^ true ].
	((className = 'SmallInteger') and: [ selector = #/ ]) ifTrue: [ ^ true ].

	"GBS glue classes"
	(className beginsWith: 'Gbs') ifTrue: [ ^ true ].
	(className beginsWith: 'Gbx') ifTrue: [ 
		"Some Gbx classes are glue, some are not"
		(#( #apiGciExecuteStr:context:env: #gciExecute:context:env: #execute: #evaluate: )
			includes: selector)
			ifTrue: [ ^ true ]
	].
	
	^ false
]

{ #category : 'context list' }
GbxContextListPolicy >> isHiddenGlue: aContext [
	"Check if a context should be hidden as glue"
	^ glueIsHidden and: [ self isGlueContext: aContext ]
]

{ #category : 'private' }
GbxContextListPolicy >> isServerCallContext: aContext [
	(aContext respondsTo: #gbxIsServerCallContext)
		ifTrue: [ ^ aContext gbxIsServerCallContext ].
	^ false
]

{ #category : 'private' }
GbxContextListPolicy >> isTopGlueContext: aContext [
	(aContext respondsTo: #gbxIsGsTopGlue)
		ifTrue: [ ^ aContext gbxIsGsTopGlue ].
	^ false
]

{ #category : 'context list' }
GbxContextListPolicy >> matchingServerCallMarkerForServerContext: gsContext [
	| ctx targetGsProcess rcvr markerProcess |
	gsContext ifNil: [ ^ nil ].
	targetGsProcess := self processIdentityForContext: gsContext.
	ctx := (debugger respondsTo: #topContext)
		ifTrue: [ debugger topContext ]
		ifFalse: [ nil ].
	[ ctx notNil ] whileTrue: [
		rcvr := [ ctx receiver ] on: Error do: [ nil ].
		markerProcess := self processIdentityForErrorLike: rcvr.
		(markerProcess notNil and: [ markerProcess = targetGsProcess ])
			ifTrue: [ ^ ctx ].
		ctx := [ ctx sender ] on: Error do: [ nil ].
	].
	^ nil
]

{ #category : 'private' }
GbxContextListPolicy >> processIdentityForContext: aContext [
	aContext ifNil: [ ^ nil ].
	(aContext respondsTo: #processOop) ifTrue: [ ^ aContext processOop ].
	(aContext respondsTo: #process) ifTrue: [ ^ aContext process ].
	^ nil
]

{ #category : 'private' }
GbxContextListPolicy >> processIdentityForErrorLike: anObject [
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #gbxIsGSError)
		ifTrue: [ anObject gbxIsGSError ifFalse: [ ^ nil ] ]
		ifFalse: [ ^ nil ].
	(anObject respondsTo: #serverProcessOop) ifTrue: [ ^ anObject serverProcessOop ].
	(anObject respondsTo: #serverProcess) ifTrue: [ ^ anObject serverProcess ].
	^ nil
]

{ #category : 'context list' }
GbxContextListPolicy >> topServerContext [
	"Return the topmost server context"
	| list |
	list := self contextList.
	^ list ifEmpty: [ nil ] ifNotEmpty: [ list first ]
]

{ #category : 'context list' }
GbxContextListPolicy >> updateContextList [
	"Update the context list and notify the debugger"
	self computeContextList.
	debugger updateStackList: self contextList
]
