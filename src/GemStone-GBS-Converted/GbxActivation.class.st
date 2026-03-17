Class {
	#name : 'GbxActivation',
	#superclass : 'Object',
	#instVars : [
		'session',
		'gsMethod',
		'gsMethodId',
		'receiver',
		'remoteSelf',
		'selector',
		'quickStepPoint',
		'sourceOffsets',
		'argAndTempNames',
		'sourceString',
		'ipOffset',
		'process',
		'level',
		'receiverClass',
		'mclass',
		'deferredInfo',
		'stackP',
		'numArgsAndTemps',
		'serverCallContext',
		'convertedTempNames'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'comparing' }
GbxActivation >> = otherActivation

	^otherActivation gbxIsServerContext
		and: [otherActivation gsMethodId = gsMethodId
		and: [otherActivation level = level]]

{ #category : 'comparing' }
GbxActivation >> hash

	^gsMethodId hash

{ #category : 'testing' }
GbxActivation >> gbxIsInStackOf: topContext 
	"Answer true if I am part of the combined stack identified by topContext."

	^topContext == serverCallContext or: [topContext hasSender: serverCallContext]

{ #category : 'testing' }
GbxActivation >> isDoit

	^self selector isNil

{ #category : 'testing' }
GbxActivation >> isValid
	"Return whether the receiver still represents a valid activation
	 in a valid GemStone process"
	"removed for performance optimization"
	"and: [ process remoteClass = OGsProcess
		and: [ (process privatePerform: #stackDepth) asLocalInteger >= 1 ]] "

	^process isGSObject
		and: [process sessionIsLoggedIn
		and: [process isSpecial not]]

{ #category : 'testing' }
GbxActivation >> gbxIsServerContext
	"Answer true if the receiver represents a GemStone server 
	execution context, false if it represents a client execution context."

	^true

{ #category : 'accessing temps' }
GbxActivation >> privateTempAt: index 
	"Private. Returns a delegate for the requested activation temp"

	self session isLoggedIn ifFalse: [^nil].
	^self session 
		unsynchronizedExecuteBlock: '
			[:level :index |
			| frame |
			frame := self _frameContentsAt: level.
			frame size >= (10 + index)
				ifFalse: [ nil ]
				ifTrue: [ frame at: 10 + index]]'
		with: self level
		with: index
		context: process

{ #category : 'accessing temps' }
GbxActivation >> put: obj intoTempVar: aVar 
	"aVar should be one of my variables. Set obj as its new value."

	aVar value: obj

{ #category : 'accessing temps' }
GbxActivation >> tempAt: index
	"Returns a delegate for the requested activation temp"
	
	^self privateTempAt: index

{ #category : 'accessing temps' }
GbxActivation >> tempAt: index put: aDelegate
	"Modifies the value of a temp"


	process
		remotePerform: #_frameAt:tempAt:put:
		with: self level
		with: index
		with: aDelegate.
	self reset

{ #category : 'accessing temps' }
GbxActivation >> stackP
	^stackP

{ #category : 'accessing temps' }
GbxActivation >> localAt: index put: anObject
	"Modifies the given temp on the server."

	^self tempAt: index put: anObject

{ #category : 'accessing temps' }
GbxActivation >> getTempVar: aVar 
	"Answer the argument or temporary value of the variable.
	"

	^aVar value

{ #category : 'accessing temps' }
GbxActivation >> oopOfTempAt: index 
	"Private. Returns the oop of the requested activation temp"

	| del |
	del := self privateTempAt: index.
	^del == nil ifTrue: [nil] ifFalse: [del oopValue]

{ #category : 'accessing temps' }
GbxActivation >> localAt: index 
	"Returns a forwarder for the requested activation temp"

	^self tempAt: index

{ #category : 'accessing method' }
GbxActivation >> sourceString

	^sourceString

{ #category : 'accessing method' }
GbxActivation >> method

	^gsMethod

{ #category : 'accessing method' }
GbxActivation >> sourceOffsets
	^sourceOffsets

{ #category : 'accessing method' }
GbxActivation >> methodId
	"Answer a string that describes gsMethod.
	 Note: gsMethodId should now always be a String rather than a Delegate,
	 so #asLocalObject should be unnecessary."

	self process isNil | self level isNil ifTrue: [^'Invalid activation'].
	self gsMethodId notNil ifTrue: [^self gsMethodId asLocalObject].
	self
		gsMethodId: (
			[| result |
			result := self session
						unsynchronizedEvaluateBlock: '[:level | (self _gsiStackReportFromLevel: level toLevel: level) first]'
						with: self level
						context: self process.
			result ifNil: ['nil']]
					on: GbsError errorSignal
					do: [:ex | ex return: '-corrupt activation- (', ex messageText, ')']).
	^self gsMethodId asLocalObject

{ #category : 'accessing method' }
GbxActivation >> gbxSelector
	^selector

{ #category : 'accessing method' }
GbxActivation >> selector
	"The debugger's method menu doesn't like it if you answer nil; bug 30734"

	^selector == nil ifTrue: [#unboundMethod] ifFalse: [selector]

{ #category : 'accessing method' }
GbxActivation >> mclass
	"Return a proxy for the class of the method"

	^mclass

{ #category : 'accessing method' }
GbxActivation >> sourceCode

	^self sourceString

{ #category : 'private' }
GbxActivation >> reset
	"Private - Answer the receiver, or nil if any problems are found.
	 I reset my state from the array returned from GemStone by GsProcess | _gsiDebuggerDetailedReportAt:."

	| sess aGSArray gsCode |
	sess := process session.	"Keep this code synced with the GS code in self class>>activationInfoFromProcess:max:"
	self gbsMessenger
		statusTag: #ActivationReset
		message: '(s%1) GbxActivation>>reset'
		with: sess sessionId.

	"		============  Start of GemStone Code  ============		"
	gsCode := '
		[:frameLevel |
		| frameId fullEntry methodOrNil shortEntry numArgsAndTemps thisReceiver thisSelf nonReplicableEntry methodClassOrNil |
		fullEntry := self _gsiDebuggerDetailedReportAt: frameLevel.
		fullEntry isNil ifTrue:  "will be nil if level out of range"
			[ ^ nil ].
		methodOrNil := fullEntry first.
		frameId :=
			''<GS: '' , methodOrNil inClass printString ,
			'' | '' , methodOrNil selector asString , ''>''.
		thisReceiver := fullEntry at: 2.
		thisSelf := fullEntry at: 3.
		numArgsAndTemps := 
			thisReceiver == thisSelf
				ifTrue: ["Method. Can be nil if the context is a User Action context which legitimately has no method"
					 methodOrNil == nil 
						ifTrue:[0]
						 ifFalse:[methodOrNil _numArgsTempsCblkargs]]
				ifFalse: [ "Block" methodOrNil _numArgsTempsCblkargs].
		methodClassOrNil := methodOrNil ifNotNil: [methodOrNil inClass].
		shortEntry := Array new
					add: frameId;				" gsMethodId "
					add: ((fullEntry at: 4) ifNil: [#''<anonymous>'']);		" selector "
					add: (fullEntry at: 5);		" quickStepPoint "
					add: (fullEntry at: 6);		" sourceOffsets "
					add: (fullEntry at: 7);		" argAndTempNames "
					add: (fullEntry at: 9);		" sourceString "
					add: (fullEntry at: 10);		" ipOffset "
					add: numArgsAndTemps;
					add: (fullEntry at: 8) size; 	"stackP"
					add: (methodClassOrNil ifNil: [#''<None>''] ifNotNil: [methodClassOrNil name]);
					yourself.
		nonReplicableEntry := Array new
					add: methodOrNil;
					add: methodClassOrNil;
					add: thisReceiver;
					add: thisReceiver class;
					add: thisSelf;
					yourself.
		^ Array
			with: fullEntry
			with: shortEntry
			with: nonReplicableEntry]'.
	"		============  End of GemStone Code  ============		"

	aGSArray := sess executeBlock: gsCode with: level context: process.
	"A nil back from GemStone means there's something wrong with the GsProcess or the level."
	aGSArray = sess oopNil ifTrue: [^level := nil].

	aGSArray := aGSArray fetchObjectValues.
	self
		resetFrom: aGSArray first
		extract: ((aGSArray at: 2) asLocalObjectToLevel: 0 replicationSpecSet: nil)	" gets all info in one round-trip "
		andDelegates: aGSArray last fetchObjectValues

{ #category : 'private' }
GbxActivation >> gbxGsDebuggerSession

	"GemStone private.  Return the GemStone session associated with
	 the receiver, or nil if none."

	^self session

{ #category : 'private' }
GbxActivation >> scopeSymbolList
	"Returns a GemStone SymbolList containing the current UserProfile's
	 symbol list with the receiver's arguments and temporaries prepended."

	^self session
		execute: '
			| symList tempDict names values |
			symList := SymbolList new.
			tempDict := SymbolDictionary new.
			names := '
				, (argAndTempNames collect: [:each | each asSymbol]) storeString
					, '.
			values := self _frameContentsAt: ' , self level printString
				, '.
			values size: names size + 10. "In case some of the variables are not reported"
			1 to: names size do: [ :i | tempDict at: (names at: i) put: (values at: 10 + i) ].
			symList add: tempDict.
			symList addAll: System myUserProfile symbolList.
			symList'
		context: self process

{ #category : 'private' }
GbxActivation >> forProcess:  aGsProcess
	process := aGsProcess.
	session := aGsProcess session

{ #category : 'private' }
GbxActivation >> resetFrom: aGSArray extract: anExtractArray andDelegates: aDelegatesArray
	" Private - I reset my state from aGSArray from GemStone, assuming my process is OK.
	  NOTE:  aGSArray is described in GS class GsProcess, method _gsiDebuggerDetailedReportAt:.
		We save information from this that may be needed later by inspectors, etc.
	  NOTE:  anExtractArray contains fields from aGSArray that we know will be needed immediately
		by the debugger.  They have already been converted to local objects. "
	"The argument aGSArray is a proxy for an array of non-simple
	 objects which can't easily be bulk fetched.  The argument aDelegatesArray
	 brings some of these down as delegates because they may be needed
	 before they can safely be fetched after the fact."

	deferredInfo := aGSArray.
	gsMethodId := anExtractArray at: 1.
	"============="
	selector := anExtractArray at: 2.	" may be nil "
	quickStepPoint := anExtractArray at: 3.
	sourceOffsets := anExtractArray at: 4.
	argAndTempNames := anExtractArray at: 5.
	sourceString := anExtractArray at: 6.
	ipOffset := anExtractArray at: 7.
	numArgsAndTemps := anExtractArray at: 8.
	stackP := anExtractArray at: 9.
	"============="
	mclass := aDelegatesArray at: 2.
	gsMethod := (GbxMethod oopValue: aDelegatesArray first oopValue session: self session)
				selector: selector;
				className: (anExtractArray at: 10);
				classDelegate: mclass;
				yourself.
	receiver := aDelegatesArray at: 3.
	receiverClass := aDelegatesArray at: 4.
	remoteSelf := aDelegatesArray at: 5.

{ #category : 'private' }
GbxActivation >> isGsGlue
	"Answer whether this context is considered to be glue code, which is normally
	 hidden by the GemStone debugger."
	"^self receiverClass = OClientForwarder"

	^('*ClientForwarder*' match: self methodId)
		or: ['*_gsReturnToC*' match: self methodId]

{ #category : 'private' }
GbxActivation >> atLevel: anInteger
	level := anInteger.

{ #category : 'private' }
GbxActivation >> selector:  aSymbol
	selector := aSymbol

{ #category : 'private' }
GbxActivation >> gsMethodId: aGsMethodIdString
	"Set the value of gsMethodId, a String that describes the frame."

	gsMethodId := aGsMethodIdString.

{ #category : 'private' }
GbxActivation >> gsMethodId
	"Answer the value of gsMethodId, a String that describes the frame."

	^ gsMethodId

{ #category : 'private' }
GbxActivation >> sourceString:  aString
	sourceString := aString

{ #category : 'debugger support' }
GbxActivation >> gbsError
	"Answer the gbsError that caused my GsProcess to suspend."

	^serverCallContext gbxResult

{ #category : 'accessing context' }
GbxActivation >> session
	^session

{ #category : 'accessing context' }
GbxActivation >> stepPoint
	"Answer the current step point."

	^quickStepPoint isNil 
		ifFalse: [quickStepPoint]
		ifTrue: 
			[(self method unsynchronizedPerform: #_stepPointForIp:level:quick:
				withArgs: (Array 
						with: ipOffset
						with: level
						with: false)) 
					asLocalObject]

{ #category : 'accessing context' }
GbxActivation >> receiver

	^receiver

{ #category : 'accessing context' }
GbxActivation >> supposedHome
	"Method activations are their own home. Block activations might need more code!!!"

	^self

{ #category : 'accessing context' }
GbxActivation >> remoteSelf

	^remoteSelf

{ #category : 'accessing context' }
GbxActivation >> pc
	"^ipOffset"

	"Client doesn't need to know our real pc.
	Use step point numbers, but PDP debugger 
	doesn't correctly handle source maps with consecutive
	pcs, so use odd numbers."

	^self stepPoint * 2 - 1

{ #category : 'accessing context' }
GbxActivation >> process
	^process

{ #category : 'accessing context' }
GbxActivation >> receiverClass
	"Return a GbsObject representing the class of the GemStone activation's receiver.
	 The low-level remoteClass is used so that ClientForwarders are reported as such."

	^receiverClass

{ #category : 'accessing context' }
GbxActivation >> home
	"Method activations are their own home. Block activations might need more code."

	^self

{ #category : 'accessing context' }
GbxActivation >> intendedReceiver
	^self remoteSelf

{ #category : 'accessing context' }
GbxActivation >> homeReceiver
	"Method activations are their own home. Block activations might need more code."

	^self receiver

{ #category : 'accessing context' }
GbxActivation >> level
	^level

{ #category : 'accessing' }
GbxActivation >> serverCallContext: anObject
	serverCallContext := anObject

{ #category : 'accessing' }
GbxActivation >> serverCallContext
	^serverCallContext

{ #category : 'process control' }
GbxActivation >> terminateProcess
	"terminate the GSProcess which I am part of, executing any 
	unwind blocks but discarding any other uncompleted execution.
	Since unwind blocks can affect replicated objects, this must be 
	done while synchronizing client and server state through normal
	GBS mechanisms. (i.e. can't use privatePerform here)"

	process remotePerform: #terminate

{ #category : 'printing' }
GbxActivation >> printOn: aStream 
	aStream
		nextPutAll: 'GS: ';
		nextPutAll: self methodId

{ #category : 'private' }
GbxActivation class >> basicFromProcess: aProcess
atLevel: aStackOffset
	" Private - Answer an instance of me on aProcess at stack frame aStackOffset. "

	| act |

	act := self new.
	act forProcess: aProcess ;
		atLevel: aStackOffset.
	^act

{ #category : 'private' }
GbxActivation class >> activationInfoFromProcess: aGsProcess max: aMaxStackLevel
	" Private - Answer an array of information about the GemStone execution state of
	  aGsProcess.  The first entry is another array (see GS class GsProcess, method
	  #_gsiStackReportFromLevel:toLevel:, for more details).  The second entry is an array
	  containing selected fields from the first entry that we know we will need as local
	  objects (this is a performance hack to reduce round-trips to GemStone). The third
	  entry is an array of server objects which we will need, but not as local objects."
	"Keep this code synced with the GS code in (instance side) #reset"

	| gsCode result |
	self gbsMessenger
		statusTag: #activationInfoFromProcess
		message: '(s%1) GbxActivation>>activationInforFromProcess:max:'
		with: aGsProcess sessionId.

	"		============  Start of GemStone Code  ============		"
	gsCode := '
		[:maxDepth |
		| frameId fullEntry shortEntry numArgsAndTemps stackReport stackReportExtract stackReportNonreplicable nonReplicableEntry methodClassOrNil |
		stackReport := self
			_gsiStackReportFromLevel: 1
			toLevel: maxDepth.
		stackReportExtract := Array new: stackReport size / 2.
		stackReportNonreplicable := Array new: stackReportExtract size.
		1 to: stackReportExtract size do:
			[:index | | thisReceiver thisSelf methodOrNil |
			frameId := stackReport at: index * 2 - 1.
			fullEntry := stackReport at: index * 2.
			methodOrNil := fullEntry first.
			thisReceiver := fullEntry at: 2.
			thisSelf := fullEntry at: 3.
			numArgsAndTemps := 
				thisReceiver == thisSelf
					ifTrue: 
						["Method. Can be nil if the context is a User Action context which legitimately has no method"
						methodOrNil == nil 
							ifTrue:[0]
							ifFalse:[methodOrNil _numArgsTempsCblkargs]]
					ifFalse: [ "Block" methodOrNil _numArgsTempsCblkargs].
			methodClassOrNil := methodOrNil ifNotNil: [methodOrNil inClass].
			shortEntry := Array new
						add: frameId;				" gsMethodId "
						add: ((fullEntry at: 4) ifNil: [#''<anonymous>'']);		" selector "
						add: (fullEntry at: 5);		" quickStepPoint "
						add: (fullEntry at: 6);		" sourceOffsets "
						add: (fullEntry at: 7);		" argAndTempNames "
						add: (fullEntry at: 9);		" sourceString "
						add: (fullEntry at: 10);		" ipOffset "
						add: numArgsAndTemps;
						add: (fullEntry at: 8) size; 	"stackP"
						add: (methodClassOrNil ifNil: [#''<None>''] ifNotNil: [methodClassOrNil name]);
						yourself.
			stackReportExtract at: index put: shortEntry.
			nonReplicableEntry := Array new
						add: methodOrNil;
						add: methodClassOrNil;
						add: thisReceiver;
						add: thisReceiver class;
						add: thisSelf;
						yourself.
			stackReportNonreplicable at: index put: nonReplicableEntry.].
		^ Array
			with: stackReport
			with: stackReportExtract
			with: stackReportNonreplicable]'.
	"		============  End of GemStone Code  ============		"

	"Must use continuable execution here in case the execution trips over a client forwarder"
	result := aGsProcess session
				unsynchronizedExecuteBlock: gsCode
				with: aMaxStackLevel
				context: aGsProcess.
	^result fetchObjectValuesDebug

{ #category : 'private' }
GbxActivation class >> activationsFrom: activationInfo in: aGsProcess serverCallContext: serverCallContext
	"Private - Answer a list of GbxActivations for the GemStone
	 execution state of the GsProcess.

	 NOTE: activationInfo is an Array with three entries.
	 1) an array of stack frame details (see GS class GsProcess>>#_gsiStackReportFromLevel:toLevel:, for more details).
	 2) an array containing selected fields from the first entry that we know we will need as local
		objects (this is a performance hack to reduce round-trips to GemStone)
	 3) an array of server objects that aren't to be replicated to the client (the method, method class, receiver, receiver class, and self for the frame)"

	| activationList newActivation stackReport stackReportExtract stackReportNonreplicable |
	stackReport := activationInfo first fetchObjectValues.
	stackReportExtract := (activationInfo at: 2) asLocalObjectToLevel: 0
				replicationSpecSet: nil.	" gets all info in one round-trip "
	stackReportNonreplicable := activationInfo last fetchObjectValues.
	activationList := Array new: stackReportExtract size.
	1 to: activationList size
		do: 
			[:ix |
			newActivation := self basicFromProcess: aGsProcess atLevel: ix.
			newActivation
				resetFrom: (stackReport at: ix * 2)
				extract: (stackReportExtract at: ix)
				andDelegates: (stackReportNonreplicable at: ix) fetchObjectValues.
			newActivation serverCallContext: serverCallContext.
			activationList at: ix put: newActivation].
	^activationList

{ #category : 'instance creation' }
GbxActivation class >> activationsFromProcess: aGsProcess max: aMaxStackLevel serverCallContext: serverCallContext 
	" Private - Answer a list of GsActivations for the GemStone
	  execution state of aGsProcess"

	| activationInfo activationList |
	GBSM showBusyWhile: 
			[activationInfo := self activationInfoFromProcess: aGsProcess
						max: aMaxStackLevel.
			activationList := self 
						activationsFrom: activationInfo
						in: aGsProcess
						serverCallContext: serverCallContext].
	^activationList

