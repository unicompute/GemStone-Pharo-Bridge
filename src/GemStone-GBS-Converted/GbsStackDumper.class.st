Class {
	#name : 'GbsStackDumper',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private - cache dumping' }
GbsStackDumper class >> dumpServerMapBodyForSession: session on: dumpingStream
[

	^session serverMap delegatesAndClientObjsDo: 
			[:del :clientObj |
			dumpingStream
				cr;
				nextPutAll: 'Delegate: ';
				indentMore.
			[del printDelegateOn: dumpingStream] on: Error
				do: [:ex | dumpingStream nextPutAll: '<<error: key not available>>'].
			dumpingStream
				indentLess;
				cr;
				nextPutAll: 'Client: ';
				indentMore.
			[self printClient: clientObj on: dumpingStream] on: Error
				do: [:ex | dumpingStream nextPutAll: '<<error: value not available>>'].
			dumpingStream
				indentLess;
				cr;
				nextPutAll: '---']
]

{ #category : 'private - cache dumping' }
GbsStackDumper class >> dumpClientMapOn: stream 
[
	self dumpClientMapHeaderOn: stream.
	self dumpClientMapBodyOn: stream
]

{ #category : 'private - cache dumping' }
GbsStackDumper class >> dumpClientMapHeaderOn: stream 
[
	stream
		cr;
		cr;
		nextPutAll: '=================================';
		cr;
		cr;
		nextPutAll: 'Client Map ';
		nextPutAll: '(size ';
		nextPutAll: GBSM clientMap size printString;
		nextPutAll: ')';
		cr.
	GBSM sessions isEmpty 
		ifTrue: 
			[stream
				nextPutAll: '**** No sessions logged in. Only defunct proxies should remain in client map ****';
				cr]
]

{ #category : 'private - cache dumping' }
GbsStackDumper class >> dumpClientMapBodyOn: dumpingStream
[

	GBSM clientMap keysAndValuesDo: 
			[:key :value |
			dumpingStream
				cr;
				nextPutAll: 'Key: ';
				indentMore.
			[self printClient: key on: dumpingStream] on: Error
				do: [:ex | dumpingStream nextPutAll: '<<error: key not available>>'].
			dumpingStream
				indentLess;
				cr;
				nextPutAll: 'Value: ';
				indentMore.
			[self printDelegateOf: value on: dumpingStream] on: Error
				do: [:ex | dumpingStream nextPutAll: '<<error: value not available>>'].
			dumpingStream
				indentLess;
				cr;
				nextPutAll: '---']
]

{ #category : 'private - cache dumping' }
GbsStackDumper class >> dumpServerMapsOn: dumpingStream 
[
	GBSM sessions 
		do: [:sess | self dumpServerMapForSession: sess on: dumpingStream]
]

{ #category : 'private - cache dumping' }
GbsStackDumper class >> dumpServerMapForSession: session on: dumpingStream 
[
	| gotSemaphore |
	gotSemaphore := false.
	dumpingStream
		cr;
		cr;
		nextPutAll: '=================================';
		cr;
		cr;
		nextPutAll: 'Server Map for Session: ';
		print: session;
		nextPutAll: ' (size ';
		nextPutAll: session serverMap size printString;
		nextPutAll: ')';
		cr.
	(dumpingStream canQueryServerSession: session) 
		ifTrue: 
			[session sessionCriticalWithoutAssertionChecks: 
					[gotSemaphore := true.
					self dumpServerMapBodyForSession: session on: dumpingStream]
				unlessBlocked: [gotSemaphore := false	"Redundant, but clearer"]].
	gotSemaphore 
		ifFalse: 
			[dumpingStream 
				nextPutAll: '<<semaphore for session ' , session printString 
						, ' held. Server map not available>>']
]

{ #category : 'private - cache dumping' }
GbsStackDumper class >> dumpCachesOn: stream 
[
	| cachedStubDebugging cachedForwarderDebugging |
	cachedStubDebugging := GbsConfiguration current stubDebugging.
	cachedForwarderDebugging := GbsConfiguration current forwarderDebugging.
	
	[GbsConfiguration current forwarderDebugging: true.
	GbsConfiguration current stubDebugging: true.
	self dumpClientMapOn: stream.
	self dumpServerMapsOn: stream] 
			ensure: 
				[GbsConfiguration current stubDebugging: cachedStubDebugging.
				GbsConfiguration current forwarderDebugging: cachedForwarderDebugging]
]

{ #category : 'public - stack dumping' }
GbsStackDumper class >> dumpAllProcessStacks
[
	"Dump the stacks of all Processes running in the client Smalltalk to a file.
	Answer a string representing the name of the file dumped to.
	The file will be created in the current directory with a name that is based on the current date and time.
	Information about all client contexts will be written. For any Process that is calling the server, the server
	context information will also be included if possible. It may not always be possible to include this information, 
	depending on the state of communications with the server. If it is not possible to obtain server information, 
	the stack dump will put a message in the stack dump and continue within a few seconds."
	"	GemStone.Gbs.GbsStackDumper dumpAllProcessStacks. 	"

	^self dumpAllProcessStacksUsingFileNamePattern: 'StacksAt%1.txt'.
]

{ #category : 'public - stack dumping' }
GbsStackDumper class >> printAllProcessStacksOn: aStream
[
	"Dump the stacks of all Processes running in the client Smalltalk to the given Stream.
	Information about all client contexts will be written. For any Process that is calling the server, the server
	context information will also be included if possible. It may not always be possible to include this information, 
	depending on the state of communications with the server. If it is not possible to obtain server information, 
	the stack dump will put a message in the stack dump and continue within a few seconds."

	| semaphore requestingProcess outerDumpThread |
	semaphore := GbxSemaphore new.
	requestingProcess := Processor activeProcess.

	"OuterDumpThread must run at a priority above that of innerDumpThread, so that it reliably
	enters the delay wait before the innerDumpThread starts its work. #gbxDisregard only
	functions if the delay is in progress. Both threads run just below lowIOPriority. The desire is
	to have them run at a high priority, but we mustn't get in the way of finalization, which 
	runs at lowIOPriority."
	outerDumpThread := 
			[| delay innerDumpThread |
			delay := GbxDelay forSeconds: 120.
			innerDumpThread := 
					[| procs wasFwdDebug wasStubDebug |
					
					[procs := self processesToDumpStartingWith: requestingProcess.
					wasFwdDebug := GbsConfiguration current forwarderDebugging: true.
					wasStubDebug := GbsConfiguration current stubDebugging: true.
					procs do: [:proc | self printProcess: proc on: aStream]]
							ensure: 
								[GbsConfiguration current forwarderDebugging: wasFwdDebug.
								GbsConfiguration current stubDebugging: wasStubDebug.
								delay gbxDisregard]]
							forkAt: Processor lowIOPriority - 2.
			innerDumpThread yourself.	"Lint -- this 'unused' variable is for debugging."
			delay wait.
			semaphore signal]
					forkAt: Processor lowIOPriority - 1.
	outerDumpThread yourself.	"Lint -- this 'unused' variable is for debugging."
	semaphore wait. "Don't return until dumping threads are done."
	aStream flush
]

{ #category : 'public - stack dumping' }
GbsStackDumper class >> dumpAllProcessStacksUsingFileNamePattern: aString
[
	"Dump the stacks of all Processes running in the client Smalltalk to a file.
	Answer a string representing the name of the file dumped to.
	The file will be created in the current directory with a name that is based on the current date and time.
	Information about all client contexts will be written. For any Process that is calling the server, the server
	context information will also be included if possible. It may not always be possible to include this information, 
	depending on the state of communications with the server. If it is not possible to obtain server information, 
	the stack dump will put a message in the stack dump and continue within a few seconds."
	"	GemStone.Gbs.GbsStackDumper dumpAllProcessStacksUsingFileNamePattern: 'StacksAt%1.txt'. 	"

	| filename |
	filename := self gbsMessenger
				print: aString
				with: self timestampForFilename.
	filename := Filename defaultClass suggest: filename.
	self dumpAllProcessStacksToFileNamed: filename.
	^filename
]

{ #category : 'public - stack dumping' }
GbsStackDumper class >> dumpFullDiagnostic
[
	"calls dumpAllProcessStacks for now. Perhaps someday, it will include more detailed diagnostics"

	self dumpAllProcessStacks
]

{ #category : 'public - stack dumping' }
GbsStackDumper class >> dumpAllProcessStacksToFileNamed: nameString
[
	"Dump the stacks of all Processes running in the client Smalltalk to a file.
	The file will be created with the given name.
	Information about all client contexts will be written. For any Process that is calling the server, the server
	context information will also be included if possible. It may not always be possible to include this information, 
	depending on the state of communications with the server. If it is not possible to obtain server information, 
	the stack dump will put a message in the stack dump and continue within a few seconds."

	| aStream |
	"Ensure any call tracing gets written to file."
	GbsCallTracing writeToFile.
	aStream := self dumpStackHeaderToFileNamed: nameString.
	
	[
	[self printAllProcessStacksOn: aStream.
	self dumpCachesOn: aStream.
	aStream
		cr;
		cr;
		nextPutAll: '<<End of stack dump>>';
		cr]
			on: GbsMaxStreamSizeNotification
			do: 
				[:ex |
				aStream
					cr;
					cr;
					nextPutAll: '<<Maximum number of characters reached. Stack dump terminated.>>']]
			ensure: [aStream close]
]

{ #category : 'private - stack computation' }
GbsStackDumper class >> bottomGlueFrom: topGlueContext 
[
	"Given aCtx, the top context of a glue run, answer the bottom
	 context of that run."

	| ctx bottomGlue |
	ctx := topGlueContext.
	"First, run down to the context that marks the GemStone process"
	[ctx isNil or: [ctx gbxIsServerCallContext]] 
		whileFalse: [ctx := ctx sender].
	ctx isNil ifTrue: [ctx := topGlueContext].

	"Now look for the last bottom glue before finding either the next top
	 glue or the next serverCall or the end of the stack."
	bottomGlue := topGlueContext.
	
	[ctx := ctx sender.
	ctx isNil or: [ctx gbxIsServerCallContext or: [ctx gbxIsGsTopGlue]]] 
			whileFalse: [ctx gbxIsGsBottomGlue ifTrue: [bottomGlue := ctx]].
	^bottomGlue
]

{ #category : 'private - stack computation' }
GbsStackDumper class >> computeContextListSelectedContext: selectedContext topContext: topContext stackLimit: stackLimit glueIsHidden: glueIsHidden 
[
	"Returns an array of contexts"

	| stk ctx includesSelectedCtx inGlue nextVisibleContext |
	includesSelectedCtx := selectedContext isNil.
	stk := WriteStream on: (Array new: stackLimit).
	ctx := topContext.
	inGlue := false.	"Remains false if glue is shown"
	"if the process for a debugger terminates while 
	there is a pending event, our topContext could legitimately be nil"
	(ctx ~~ nil and: [glueIsHidden]) 
		ifTrue: 
			[inGlue := ctx gbxIsGsTopGlue 
						or: [ctx gbxIsGsBottomGlue or: [ctx gbxIsServerCallContext]].
			inGlue ifTrue: [nextVisibleContext := (self bottomGlueFrom: ctx) sender]].
	
	[ctx == nil or: 
			[(includesSelectedCtx or: [includesSelectedCtx := ctx == selectedContext]) 
				and: [stk size >= stackLimit]]] 
			whileFalse: 
				["If this is a send to GS, insert server contexts"

				ctx gbxIsServerCallContext 
					ifTrue: 
						[stk nextPutAll: (self contextListFromGsProcessOfServerCallContext: ctx
									glueIsHidden: glueIsHidden)].

				"Track 'whether we're in glue' contexts"
				inGlue 
					ifTrue: [ctx = nextVisibleContext ifTrue: [inGlue := false]]
					ifFalse: 
						[glueIsHidden 
							ifTrue: 
								[ctx gbxIsGsTopGlue 
									ifTrue: 
										[inGlue := true.
										nextVisibleContext := (self bottomGlueFrom: ctx) sender]]].

				"Add current client context if it's not hidden glue"
				inGlue ifFalse: [stk nextPut: ctx].
				ctx := ctx sender].
	^stk contents
]

{ #category : 'private - stack computation' }
GbsStackDumper class >> activationsFrom: gsProcess context: serverCallContext
[

	| sess |
	sess := gsProcess noCheckSession.	"Don't check session here, we may be dumping a stack from a fatal error."
	^sess == nil
		ifTrue: [#()]
		ifFalse: 
			[sess
				critical: 
					[GbxActivation
						activationsFromProcess: gsProcess
						max: SmallInteger maxVal
						serverCallContext: serverCallContext]
				unlessBlocked: 
					[Array with: ((GbxInvalidActivation new)
								forProcess: gsProcess;
								error: 'The session semaphore was blocked')]
				onError: 
					[:ex |
					Array with: ((GbxInvalidActivation new)
								forProcess: gsProcess;
								error: ex)]
				retryFor: 500]
]

{ #category : 'private - stack computation' }
GbsStackDumper class >> contextListFromGsProcessOfServerCallContext: serverCallContext glueIsHidden: glueIsHidden
[
	"Answer the list of GbxActivations on the stack of a GSProcess 
	for which <serverCallContext> is the client context that marks the send.
	Each send from the client to the server results in a new GSProcess, so 
	there may be more than one GSProcess represented in a single stack.
	In the case of, for instance, a server compile error, the GbsError does
	not have a gsProcess, so there are no server contexts to answer.
	We also, rather than hang the debugger / stack dumper, answer an empty
	list if some other process holds the session semaphore."

	| list gsProcess gbsError |
	gbsError := serverCallContext gbxResult.
	gbsError == nil ifTrue: [^#()].
	gsProcess := gbsError serverProcess.
	(gsProcess isNil or: [gsProcess = gbsError session oopNil]) ifTrue: [^#()].
	list := self activationsFrom: gsProcess context: serverCallContext.
	list isEmpty ifTrue: [^#()].
	glueIsHidden ifTrue: [list := list select: [:gsact | gsact isGsGlue not]].
	^list
]

{ #category : 'private - proxy handling' }
GbsStackDumper class >> defaultPrintClient: anObject on: aStream
[

	| limitedSizeStream identityHash gbxIdentityHash |
	limitedSizeStream := GemStone.Gbs.GbxLimitingStream on: aStream.
	limitedSizeStream cr.
	limitedSizeStream printClientHeaderFor: anObject.
	identityHash := self identityHashOf: anObject.
	limitedSizeStream
		nextPut: ${;
		print: identityHash;
		nextPut: $};
		space.
	gbxIdentityHash := self gbxIdentityHashOf: anObject.
	gbxIdentityHash == identityHash
		ifFalse: 
			[limitedSizeStream
				nextPutAll: '{gbxIdentityHash: ';
				print: gbxIdentityHash;
				nextPut: $};
				space].
	
	[[self debugPrint: anObject on: limitedSizeStream]
		on: GemStone.Gbs.GbsMaxStreamSizeNotification
		do: [:ex | limitedSizeStream nextPutAll: '<< etc. >>']]
			on: Error
			do: 
				[:ex |
				limitedSizeStream
					nextPutAll: '<<error printing client object (' , ex printString
							, ') no further information>>']
]

{ #category : 'private - proxy handling' }
GbsStackDumper class >> printClient: anObject on: aStream
[
	"Only GBS-specific objects understand #gbxPrintClientOn:"

	^GbxReflection
		send: #gbxPrintClientOn:
		to: anObject
		with: aStream
		ifNotUnderstood: [self defaultPrintClient: anObject on: aStream]
]

{ #category : 'private - proxy handling' }
GbsStackDumper class >> debugPrint: anObject on: aStream
[

	GbxReflection debugPrint: anObject on: aStream
]

{ #category : 'private - proxy handling' }
GbsStackDumper class >> ifUnderstoodSend: aUnarySelector to: anObject else: aBlock
[
	"anObject might be a proxy that does not understand this message -- if so
	answer the value of the block instead"

	^self
		ifUnderstoodSend: aUnarySelector
		to: anObject
		arguments: Array new
		else: aBlock
]

{ #category : 'private - proxy handling' }
GbsStackDumper class >> classOf: anObject
[
	"Answer the object which is the argument's class.."

	<primitive: 211>
	^self primitiveFailed
]

{ #category : 'private - proxy handling' }
GbsStackDumper class >> ifUnderstoodSend: selector to: anObject arguments: arguments else: aBlock
[
	"anObject might be a proxy that does not understand this message -- if so
	answer the value of the block instead"

	| objectClass |
	objectClass := self classOf: anObject.
	^(objectClass canUnderstand: selector)
		ifTrue: [anObject perform: selector withArguments: arguments]
		ifFalse: [aBlock value]
]

{ #category : 'private - proxy handling' }
GbsStackDumper class >> identityHashOf: anObject
[

	^GbxReflection identityHashOf: anObject
]

{ #category : 'private - proxy handling' }
GbsStackDumper class >> printServer: anObject on: aStream
[
	"Objects that don't understand #gbxPrintServerOn: (because they 
	don't inherit from Object) can't have a server representation."

	GbxReflection
		send: #gbxPrintServerOn:
		to: anObject
		with: aStream
		ifNotUnderstood: [nil]
]

{ #category : 'private - proxy handling' }
GbsStackDumper class >> gbxIdentityHashOf: anObject
[

	^GbxReflection gbxIdentityHashOf: anObject
]

{ #category : 'private - proxy handling' }
GbsStackDumper class >> printDelegateOf: anObject on: aStream
[
	"Objects that don't understand #gbxDelegate (because they 
	don't inherit from Object) can't have a delegate."

	| objectIsDelegate delegate |
	objectIsDelegate := GbxReflection
				send: #isGSObject
				to: anObject
				ifNotUnderstood: [false].
	delegate := objectIsDelegate
				ifTrue: [anObject]
				ifFalse: 
					[GbxReflection
						send: #gbxDelegate
						to: anObject
						ifNotUnderstood: [nil]].
	delegate isNil ifFalse: [delegate printDelegateOn: aStream]
]

{ #category : 'private - stack dumping' }
GbsStackDumper class >> printContext: cxt on: stream count: cxtCount
[

	| homeReceiver limitedStream |
	limitedStream := GbxLimitingStream on: stream.
	limitedStream maxSize: 500000.
	limitedStream
		cr;
		nextPutAll: '---------------------------------';
		cr;
		nextPut: $[;
		print: cxtCount;
		nextPutAll: '] '.
	limitedStream
		print: cxt;
		cr;
		nextPutAll: 'Context PC = ' , cxt pc printString;
		cr.
	limitedStream
		nextPutAll: 'Receiver: ';
		indentMore.
	
	[homeReceiver := cxt homeReceiver.
	self printClient: homeReceiver on: limitedStream.
	self printServer: homeReceiver on: limitedStream.
	self printDelegateOf: homeReceiver on: limitedStream]
			ensure: [limitedStream indentLess].
	self printTemporariesIn: cxt on: limitedStream.
	self printInstVarsIn: cxt on: limitedStream.
	"LimitedStream does not buffer, so no need to flush here."
	^cxtCount + 1
]

{ #category : 'private - stack dumping' }
GbsStackDumper class >> processesToDumpStartingWith: requestingProcess 
[
	"Answer an ordered collection of Processes
	 Omit the active Process, and put requestingProcess first."

	| procs |
	procs := (Process allInstances copyWithout: Processor activeProcess) 
				copyWithout: requestingProcess.
	procs := procs asSortedCollection: 
					[:a :b | 
					a priority > b priority 
						or: [a priority = b priority and: [a hash < b hash]]].
	^(procs asOrderedCollection)
		addFirst: requestingProcess;
		yourself
]

{ #category : 'private - stack dumping' }
GbsStackDumper class >> dumpStackHeaderToFileNamed: nameString
[

	| file aStream time date |
	date := Date today.
	time := Time now.
	file := GbxFilename named: nameString.
	aStream := GbxLimitingStream on: (GbxBufferingStream on: file writeStream).
	aStream maxSize: 50000000.
	#dumpAllProcessStacks printOn: aStream.
	aStream cr.
	date printOn: aStream.
	aStream space.
	time printOn: aStream.
	self gbsMessenger
		print: '\GemBuilder for Smalltalk %1 of %2.'
		on: aStream
		with: GbsConfiguration gbsBuildName
		with: GbsConfiguration gbsBuildTime first.
	self gbsMessenger
		print: '\Client Operating System: %1\%2\%3'
		on: aStream
		with: OSHandle currentPlatformID
		with: SystemUtils version
		with: ObjectMemory versionId printString.
	self gbsMessenger
		print: '\GCI %1'
		on: aStream
		with: GbxServerVersion debugCurrent printString.
	aStream
		cr;
		cr;
		nextPutAll: 'ObjectMemory current spaceSummaryOn:';
		cr.
	ObjectMemory current spaceSummaryOn: aStream.
	aStream
		cr;
		cr;
		nextPutAll: 'GBSM sessionSummaryOn:';
		cr.
	GBSM sessionSummaryOn: aStream.
	aStream cr.
	^aStream
]

{ #category : 'private - stack dumping' }
GbsStackDumper class >> printTemporariesIn: cxt on: stream
[

	| tempNames |
	stream
		cr;
		nextPutAll: 'Temporaries:';
		indentMore.
	(cxt gbxIsServerContext or: [cxt method isExternalMethod not])
		ifTrue: 
			[
			[tempNames := cxt localScope localTempNames reject: [:nm | nm first = $.].
			tempNames doWithIndex: 
					[:tempName :i |
					| tempValue |
					"Print it immediately, so we have more information in the event of an error."
					stream
						cr;
						nextPutAll: tempName.

					tempValue := (cxt isKindOf: GbxActivation)
								ifTrue: [cxt tempAt: i]
								ifFalse: [cxt getTempVar: (cxt localScope temps detect: [:ea | ea key = tempName]) value].
					
					[
					[stream indentMore.
					self printClient: tempValue on: stream.
					self printServer: tempValue on: stream.
					self printDelegateOf: tempValue on: stream]
							ensure: [stream indentLess]]
							on: Error
							do: 
								[:ex |
								stream
									nextPutAll: '{Couldn''t print an instance of ';
									print: tempValue gbxBasicClass;
									nextPutAll: ' due to ';
									nextPutAll: ex messageText;
									nextPutAll: '}']]]
					on: Error
					do: 
						[:ex |
						stream
							tab;
							nextPutAll: 'No further information; ';
							space;
							nextPutAll: ex messageText;
							cr]].
	stream indentLess
]

{ #category : 'private - stack dumping' }
GbsStackDumper class >> printShortContext: cxt on: stream count: cxtCount 
[
	stream
		cr;
		nextPut: $[;
		print: cxtCount;
		nextPutAll: ']'.
	cxtCount < 100 ifTrue: [stream space].
	cxtCount < 10 ifTrue: [stream space].
	stream print: cxt.
	^cxtCount + 1
]

{ #category : 'private - stack dumping' }
GbsStackDumper class >> dumpAllProcessStacksEvery: seconds while: aBlock 
[
	"This code will dump the full client-side stack (with details) of all
	 processes running in a VisualWorks image to a file."

	"	GbsStackDumper
			dumpAllProcessStacksEvery: 2
			while: [(Delay forSeconds: 10) wait].
	"

	| finished answer proc |
	finished := Association key: 'sure wish VA had a value model' value: false.
	proc := 
			[:finVh | 
			[finVh value] whileFalse: 
					[GbsStackDumper dumpAllProcessStacks.
					(Delay forSeconds: seconds) wait]] 
					newProcessWithArguments: (Array with: finished).
	proc resume.
	[answer := aBlock value] ensure: [finished value: true].
	^answer
]

{ #category : 'private - stack dumping' }
GbsStackDumper class >> printProcess: process on: stream
[
	"Write a description of the given Process on the given Stream.
	Include detailed stack information. If an error or hang happens during the
	printing, note this on the stream and go on.
	If the process' suspended context is nil, assume ithas terminated and
	print nothing"
	
	| topContext cxtCount contexts |
	topContext := process suspendedContext.
	cxtCount := 1.
	topContext isNil
		ifTrue: [^self]
		ifFalse:
			[stream
				cr;
				nextPutAll: '=================================';
				cr.
			stream
				nextPutAll: 'Process {';
				print: process identityHash;
				nextPutAll: '} priority: ';
				print: process priority;
				cr].
	contexts := GbsStackDumper computeContextListSelectedContext: topContext
		topContext: topContext stackLimit: 1000 glueIsHidden: false.
	contexts
		do:
			[:cxt | cxtCount := self printShortContext: cxt on: stream count: cxtCount].
	cxtCount := 1.
	contexts
		do:
			[:cxt | cxtCount := self printContext: cxt on: stream count: cxtCount]
]

{ #category : 'private - stack dumping' }
GbsStackDumper class >> printInstVarsIn: cxt on: stream
[

	| instVarNames |
	stream
		cr;
		nextPutAll: 'Instance Variables:';
		indentMore.
	
	[cxt gbxIsServerContext
		ifTrue: [instVarNames := cxt homeReceiver instVarNames]
		ifFalse: 
			[instVarNames := OrderedCollection new.
			cxt homeReceiver gbxBasicClass accumulateInstVarNames: instVarNames].
	1 to: instVarNames size
		do: 
			[:i |
			| instVarName instVarValue |
			instVarName := instVarNames at: i.
			instVarValue := cxt homeReceiver instVarAt: i.
			stream
				cr;
				nextPutAll: instVarName.
			
			[
			[stream indentMore.
			self printClient: instVarValue on: stream.
			self printServer: instVarValue on: stream.
			self printDelegateOf: instVarValue on: stream]
					ensure: [stream indentLess]]
					on: Error
					do: 
						[:ex |
						stream
							nextPutAll: '{Couldn''t print an instance of ';
							print: instVarValue gbxBasicClass;
							nextPutAll: ' due to ';
							nextPutAll: ex description;
							nextPutAll: '}']]]
			on: Error
			do: 
				[:ex |
				stream
					tab;
					nextPutAll: 'No further information; ';
					space;
					print: ex;
					cr].
	stream indentLess
]

{ #category : 'private - stack dumping' }
GbsStackDumper class >> timestampForFilename
[
	"Answer a representation of the local date and time suitable for use as part of a filename.
	Avoid use of $:, which cannot be used in Windows filenames."

	| timestamp |
	timestamp := (Locale current printAsTime: Timestamp now
				policyNamed: #iso8601Enhanced) asString.
	timestamp
		replaceAll: $T with: $-;
		replaceAll: $: with: $..
	^timestamp
]

