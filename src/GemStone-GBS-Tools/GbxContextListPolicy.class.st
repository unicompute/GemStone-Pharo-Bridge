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
	debugger logRestartText: 'computeContextList START'.
	serverContexts := self fetchServerContexts.
	debugger logRestartText: 'computeContextList fetchServerContexts returned ' , serverContexts size asString.
	allContexts := OrderedCollection new.
	allContexts addAll: serverContexts.

	topServerContext := serverContexts ifEmpty: [ nil ] ifNotEmpty: [ serverContexts first ].
	debugger logRestartText: 'computeContextList topServerContext=' , (topServerContext ifNil: [ 'nil' ] ifNotNil: [ topServerContext class name ]).
	topServerContext ifNotNil: [
		firstClientContext := self firstClientContextAbove: topServerContext.
		debugger logRestartText: 'computeContextList firstClientContext=' , (firstClientContext ifNil: [ 'nil' ] ifNotNil: [ firstClientContext class name ]).
		firstClientContext ifNotNil: [
			marker := self matchingServerCallMarkerForServerContext: topServerContext.
			debugger logRestartText: 'computeContextList marker=' , (marker ifNil: [ 'nil' ] ifNotNil: [ marker class name ]).
			allContexts addAll: (self
				clientContextsStartingAt: firstClientContext
				upToContextExclusive: marker)
		]
	].

	glueIsHidden
		ifTrue: [
			| filtered |
			filtered := self filterOutGlue: allContexts.
			debugger logRestartText: 'computeContextList filtered count=' , filtered size asString.
			contextList := filtered isEmpty
				ifTrue: [ allContexts asArray ]
				ifFalse: [ filtered ]
		]
		ifFalse: [ contextList := allContexts ].

	debugger logRestartText: 'computeContextList END contextList size=' , contextList size asString.
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
	"Fetch server activations by resolving the actual debug process oop and
	then letting GbxActivationTool>>reset populate each frame from
	_gsiDebuggerDetailedReportAt:. This stays closer to VW behavior and avoids
	depending on the exact _gsiStackReportFromLevel:toLevel: field layout."
	| processOop resolvedProcessOop depthScript rawDepth maxDepth contexts |
	debugger logRestartText: 'fetchServerContexts START'.

	processOop := debugger processOop.
	debugger logRestartText: 'fetchServerContexts processOop=' , (processOop ifNil: [ 'nil' ] ifNotNil: [ processOop asString ]).
	(processOop isNil or: [ processOop = 20 ]) ifTrue: [ 
		debugger logRestartText: 'fetchServerContexts processOop is nil or 20, returning empty'.
		^ #( ) 
	].

	resolvedProcessOop := (debugger respondsTo: #resolveDebugProcessOopFromCurrentProcessOop)
		ifTrue: [ [ debugger resolveDebugProcessOopFromCurrentProcessOop ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	((resolvedProcessOop isNumber and: [ resolvedProcessOop > 20 ]) not)
		ifTrue: [ resolvedProcessOop := processOop ].
	debugger logRestartText: 'fetchServerContexts resolvedProcessOop=' , resolvedProcessOop asString.

	depthScript := '[
		| obj depth frame |
		obj := Object _objectForOop: ', resolvedProcessOop asString, '.
		obj isNil ifTrue: [ ^ ''0'' ].
		depth := 0.
		[ depth < 200 ] whileTrue: [
			frame := [ obj _gsiDebuggerDetailedReportAt: depth + 1 ] on: Error do: [ nil ].
			frame isNil ifTrue: [ ^ depth asString ].
			depth := depth + 1
		].
		depth asString
	] value'.

	rawDepth := [
		debugger session evaluate: depthScript
	] on: Error do: [ :ex |
		debugger logRestartText: 'fetchServerContexts: ERROR depth probe: ' , ex messageText.
		nil
	].
	(rawDepth respondsTo: #asLocalString) ifTrue: [ rawDepth := rawDepth asLocalString ].
	maxDepth := [ rawDepth asString asInteger ] on: Error do: [ 0 ].

	"Diagnostic fallback if depth is 0"
	(maxDepth = 0 and: [ (resolvedProcessOop isNumber and: [ resolvedProcessOop > 20 ]) ]) ifTrue: [
		debugger logRestartText: 'fetchServerContexts: depth 0 detected, trying emergency probe'.
		maxDepth := [ (debugger session evaluate: '[ (Object _objectForOop: ', resolvedProcessOop asString, ') stackDepth ] value') asLocalString asInteger ] on: Error do: [ 0 ].
	].

	debugger logRestartText: 'fetchServerContexts maxDepth=' , maxDepth asString.

	contexts := OrderedCollection new.
	1 to: maxDepth do: [ :level |
		| activation |
		activation := GbxActivationTool processOop: resolvedProcessOop level: level session: debugger session.
		activation gsMethodId ifNil: [
			debugger logRestartText: 'fetchServerContexts stopping at invalid level=' , level asString.
			^ contexts asArray
		].
		contexts add: activation
	].

	contexts isEmpty ifTrue: [
		(debugger respondsTo: #fetchContextsDirectly) ifTrue: [
			debugger logRestartText: 'fetchServerContexts: falling back to debugger fetchContextsDirectly'.
			contexts := [ debugger fetchContextsDirectly ] on: Error do: [ #( ) ].
			contexts ifNil: [ contexts := #( ) ].
			debugger logRestartText: 'fetchServerContexts: direct fallback count=' , contexts size asString
		]
	].

	debugger logRestartText: 'fetchServerContexts END contexts count=' , contexts size asString.
	^ contexts asArray
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
	| identity |
	aContext ifNil: [ ^ nil ].
	(aContext respondsTo: #processOop)
		ifTrue: [
			identity := [ aContext processOop ] on: Error do: [ nil ].
			identity ifNotNil: [ ^ self normalizeProcessIdentity: identity ]
		].
	(aContext respondsTo: #process)
		ifTrue: [
			identity := [ aContext process ] on: Error do: [ nil ].
			identity ifNotNil: [ ^ self normalizeProcessIdentity: identity ]
		].
	^ self normalizeProcessIdentity: aContext
]

{ #category : 'private' }
GbxContextListPolicy >> processIdentityForErrorLike: anObject [
	| identity |
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #gbxIsGSError)
		ifTrue: [ anObject gbxIsGSError ifFalse: [ ^ nil ] ]
		ifFalse: [ ].
	(anObject respondsTo: #serverProcessOop)
		ifTrue: [
			identity := [ anObject serverProcessOop ] on: Error do: [ nil ].
			identity ifNotNil: [ ^ self normalizeProcessIdentity: identity ]
		].
	(anObject respondsTo: #serverProcess)
		ifTrue: [
			identity := [ anObject serverProcess ] on: Error do: [ nil ].
			identity ifNotNil: [ ^ self normalizeProcessIdentity: identity ]
		].
	(anObject respondsTo: #process)
		ifTrue: [
			identity := [ anObject process ] on: Error do: [ nil ].
			identity ifNotNil: [ ^ self normalizeProcessIdentity: identity ]
		].
	^ self normalizeProcessIdentity: anObject
]

{ #category : 'private' }
GbxContextListPolicy >> normalizeProcessIdentity: anObject [
	| oop |
	anObject ifNil: [ ^ nil ].
	anObject isNumber ifTrue: [ ^ anObject ].
	oop := [ anObject asOop ] on: Error do: [ nil ].
	oop ifNotNil: [ ^ oop ].
	oop := [ anObject oopValue ] on: Error do: [ nil ].
	oop ifNotNil: [ ^ oop ].
	^ anObject
]

{ #category : 'context list' }
GbxContextListPolicy >> topServerContext [
	"Return the topmost server context"
	| list |
	list := self contextList.
	^ list ifEmpty: [ nil ] ifNotEmpty: [ list first ]
]

{ #category : 'testing' }
GbxContextListPolicy >> isFullStack [
	"Check if displaying full stack (glue shown)"
	^ glueIsHidden not
]

{ #category : 'context list' }
GbxContextListPolicy >> updateContextList [
	"Update the context list and notify the debugger"
	self computeContextList.
	debugger updateStackList: self contextList
]
