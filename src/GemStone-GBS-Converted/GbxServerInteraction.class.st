Class {
	#name : 'GbxServerInteraction',
	#superclass : 'Object',
	#instVars : [
		'argumentDelegates',
		'arguments',
		'fetchTraversal',
		'interactionState',
		'replicationClampDelegate',
		'replication',
		'replicationLevel',
		'replicationScheme',
		'resultDelegateOrError',
		'serverInterface',
		'session',
		'shouldReplicateResultBodyAsDelegates',
		'shouldReplicateResult',
		'shouldSynchronize',
		'statResource',
		'stopForBreakpoints',
		'storeTraversal'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxServerInteraction >> replicationScheme: aScheme
[

	replicationScheme := aScheme
]

{ #category : 'accessing' }
GbxServerInteraction >> shouldReplicateResultBodyAsDelegates
[

	^shouldReplicateResultBodyAsDelegates
]

{ #category : 'accessing' }
GbxServerInteraction >> shouldSynchronize
[

	^shouldSynchronize
]

{ #category : 'accessing' }
GbxServerInteraction >> replicationClampDelegate
[
	^replicationClampDelegate
]

{ #category : 'accessing' }
GbxServerInteraction >> arguments: args 
[
	arguments := args
]

{ #category : 'accessing' }
GbxServerInteraction >> replicationClampDelegate: anObject
[
	"This message should not be used to explicitly set the clamp for new interactions, since it bypasses clamp updating.
	It is for use by replicateAlteredObjectsAfterError:, when I'm a follow-up interaction to another interaction and 
	should use the same clamp."

	replicationClampDelegate := anObject
]

{ #category : 'accessing' }
GbxServerInteraction >> shouldSynchronize: aBoolean 
[
	shouldSynchronize := aBoolean
]

{ #category : 'accessing' }
GbxServerInteraction >> replicationLevel
[
	^replicationLevel
]

{ #category : 'accessing' }
GbxServerInteraction >> replicationLevel: level
[
	replicationLevel := level
]

{ #category : 'accessing' }
GbxServerInteraction >> statResource
[

	^statResource
]

{ #category : 'accessing' }
GbxServerInteraction >> stopForBreakpoints
[
	^stopForBreakpoints
]

{ #category : 'accessing' }
GbxServerInteraction >> session
[

	^session
]

{ #category : 'accessing' }
GbxServerInteraction >> replicationScheme
[

	^replicationScheme
		ifNil: [replicationScheme := session currentReplicationScheme]
]

{ #category : 'accessing' }
GbxServerInteraction >> stopForBreakpoints: anObject
[
	stopForBreakpoints := anObject
]

{ #category : 'accessing' }
GbxServerInteraction >> storeTraversal
[
	^storeTraversal
]

{ #category : 'accessing' }
GbxServerInteraction >> resultDelegateOrError
[

	^resultDelegateOrError
]

{ #category : 'accessing' }
GbxServerInteraction >> serverInterface
[
	^serverInterface
]

{ #category : 'accessing' }
GbxServerInteraction >> argumentDelegates
[
	^argumentDelegates
]

{ #category : 'accessing' }
GbxServerInteraction >> serverInterface: anObject
[
	serverInterface := anObject
]

{ #category : 'accessing' }
GbxServerInteraction >> session: anObject
[
	session := anObject
]

{ #category : 'accessing' }
GbxServerInteraction >> fetchTraversal
[
	^fetchTraversal
]

{ #category : 'accessing' }
GbxServerInteraction >> interactionState
[

	^interactionState
]

{ #category : 'accessing' }
GbxServerInteraction >> shouldReplicateResult
[
	^shouldReplicateResult
]

{ #category : 'accessing' }
GbxServerInteraction >> shouldReplicateResult: anObject
[
	shouldReplicateResult := anObject
]

{ #category : 'accessing' }
GbxServerInteraction >> interactionState: anInteractionState
[

	interactionState := anInteractionState
]

{ #category : 'testing' }
GbxServerInteraction >> hasObjectsToStore
[
	
	^storeTraversal buffer isEmpty not
]

{ #category : 'private-accessing' }
GbxServerInteraction >> shouldReplicateResultBodyAsDelegates: aBoolean
[

	shouldReplicateResultBodyAsDelegates := aBoolean
]

{ #category : 'private - executing' }
GbxServerInteraction >> replicateAlteredObjectsAfterError
[
	"Used after an error interrupted execution. Note that an 'error' includes things like 
	client forwarder sends and breakpoints.

	Normally, answer resultDelegateOrError, which is known to be an error if this message is sent.
	However, if we run into an error replicating the altered objects,
	that error is probably worse than the original error, so answer the new error."

	^self subclassResponsibility
]

{ #category : 'private - executing' }
GbxServerInteraction >> replicateResult
[
	"resultDelegateOrError is the server object answered by the message send.
	On entry, delegatesToTraverse is the immediate-faulting altered objects.

	Answer the given delegate unless an error occurs during replication. In that case, answer
	the error."

	self subclassResponsibility
]

{ #category : 'private - executing' }
GbxServerInteraction >> completeResult: delegateOrError
[
	"aDelegate is the server object answered by the message send. 
	Answer either aDelegate or, if result replication is specified, its client counterpart."

	| result |
	delegateOrError gbxIsGSError ifTrue: [^delegateOrError].
	"Done replicating, and out of sessionCritical:, so now's the time to perform class mapping
	and resolution of circular references."
	session sessionCritical: 
			[self gbsMessenger
				statusTag: #completeResult:
				message: '%1 Result: %2 replicating: %3'
				with: self
				with: delegateOrError
				with: shouldReplicateResult.
			replication resolve.
			"If single-trip, the result is already replicated, and is in the 
	cache, so asLocalObject will just look it up in the cache. In multi-trip, it will be replicated from the server.
	
	Expect to be able to look up the result 
	if its a delegate and replication is specified. If it's not in the cache, throw an error. "
			result := shouldReplicateResult
						ifTrue: 
							[delegateOrError gbxIsGSError
								ifTrue: [delegateOrError]
								ifFalse: [self getCachedResultFromDelegate: delegateOrError]]
						ifFalse: [delegateOrError]].
	^result
]

{ #category : 'private - executing' }
GbxServerInteraction >> continueAfter: error
[
	"We've resumed from an exception (could be a client forwarder send or a debugger step).
	Need to re-flush dirty, do a StoreTravDoTravRefs(4) to continue, replicate any altered objects 
	(and the result if not error), and return the result."

	self gbsMessenger
		statusTag: #continueAfter:
		message: '%1 continueAfter: %2'
		with: self
		with: error.
	^self
		doRoundTrip: [serverInterface continueAfter: error forInteraction: self]
]

{ #category : 'private - executing' }
GbxServerInteraction >> roundTripCurtailed
[
	"When the round trip is curtailed, report a (loss of) synchronization error,
	 unless there is reason not to:
		- unwinding from an async abort
		- unsynchronized interactions
		- processing a fatal error (causeOfDeath would be reported before the session knows it's logged out)"

	(session isUnwindingAsyncAbort not
		and: [shouldSynchronize
		and: [session causeOfDeath == nil]])
			ifTrue: [GbsSynchronizationError signalWith: session]
]

{ #category : 'private - executing' }
GbxServerInteraction >> doRoundTrip: aBlock
[

	| newResultOrError |
	session sessionCritical: 
			[| nestingLevelWas |
			self gbsMessenger statusTag: #doRoundTrip: message: '%1' with: self.
			nestingLevelWas := session nestingLevel.
			
			[session nestingLevel: nestingLevelWas + 1.
			self allocateTraversals.	"Inside critical section so other threads don't allocate buffers then wait"
			
			[self packForStore.
			
			[resultDelegateOrError := aBlock value.
			resultDelegateOrError gbxIsGSError
				ifTrue: 
					[resultDelegateOrError isAsyncAbortError
						ifTrue: [GbxAsyncAbortNotification raiseSignal]]]
					on: GbxAsyncAbortNotification
					do: 
						[:ex |
						nestingLevelWas > 0
							ifTrue: [ex pass]
							ifFalse: [session processAsyncAbort]].
			newResultOrError := self synchronizeForResultOrError]
					ifCurtailed: [self roundTripCurtailed]]
					ensure: 
						[session nestingLevel: nestingLevelWas.
						self releaseTraversals]].
	^newResultOrError
]

{ #category : 'private - executing' }
GbxServerInteraction >> fetchReplicationClamp
[
	"If the replication clamp has not been explicitly set, 
	find or create and answer the replication clamp delegate for this interaction. 
	If the replication clamp must be created, this will involve other server interactions.
	If the replication clamp must be created, creates another ServerInteraction and executes it
	to create the clamp. Therefore, the sender should *NOT* hold my sessionProtect. The session
	semaphore is not needed to create a class connector, so the replication clamp could be flushed 
	at any moment even if we did hold sessionProtect, so there would be no advantage.
	NOTE that the above sentence might be misleading or incorrect, since we don't flush replication clamps 
	any more, just update them."
	"Even if we're not replicating results, we need a clamp to handle traversal of altered immediate-faulting objects."
	"If I already have a clamp delegate, I'm a follow-on interaction to another interaction and do not need to 
	update clamps."

	replicationClampDelegate ~~ nil ifTrue: [^replicationClampDelegate].
	"Don't update clamps for a nil replication spec -- interactions with nil replications specs 
	can be executed in the updating the clamps."
	^self replicationScheme usesClamps
		ifTrue: [self replicationScheme clamp asGSObjectInSession: session]
		ifFalse: [session oopNil]
]

{ #category : 'private - executing' }
GbxServerInteraction >> stepAfter: error
[
	"We're stepping through a server execution."

	self doRoundTrip: [serverInterface stepAfter: error forInteraction: self].
	^resultDelegateOrError = error serverProcess
		ifTrue: [error]
		ifFalse: [resultDelegateOrError]
]

{ #category : 'private - executing' }
GbxServerInteraction >> stepOrContinueAfter: error
[
	"Either step or continue after the given GbsError. The error tells us which to do."

	self gbsMessenger
		statusTag: #stepOrContinueAfter
		message: 'GbsSession>>stepOrContinueAfter: stepLevel: %1'
		with: error stepLevel.
	error hasServerProcess
		ifFalse: 
			[self gbsMessenger error: 'Unproceedable state after error: %1 ' with: error.
			Processor activeProcess terminate].
	^error stepLevel isNil
		ifTrue: [self continueAfter: error]
		ifFalse: [self stepAfter: error]
]

{ #category : 'private - executing' }
GbxServerInteraction >> getCachedResultFromDelegate: delegateOrError
[
	"Look up the delegate. If its not cached, this is an error."
	"Sender must hold my session's sessionProtect."

	| result |
	result := session lookupOop: delegateOrError.
	result == NotCachedToken
		ifTrue: 
			[[false] gbxAssertEquals: true
				message: 'Did not have a cached result after a server interaction.'.
			result := GbxUnknownStub new.
			session privateConnectNewClient: result toServer: delegateOrError].
	^result
]

{ #category : 'private - executing' }
GbxServerInteraction >> synchronizeForResultOrError
[
	"resultDelegateOrError may be a result delegate, or may be a GbsError.
	Synchronize altered/swizzled objects if we have them. Fetch them if synchronizing and we don't have them.
	If not error, replicate result if specified. Don't finish resolving the replication.
	If it's a fatal error, we can't do anything, so just return.
	If we attempted to replicate, but got an error during replication, answer that error.
	Otherwise, answer the given resultOrError.

	Sender must hold my sessionProtect"

	| answer |
	replication := session replicationClass forInteraction: self.
	resultDelegateOrError gbxIsGSError
		ifTrue: 
			[answer := resultDelegateOrError isFatalError
						ifTrue: [resultDelegateOrError]
						ifFalse: 
							[storeTraversal exportPackedNotYetAccepted.
							self gbsMessenger
								statusTag: #replicateAlteredObjectsAfterError
								message: '%1 error: %2'
								with: self
								with: resultDelegateOrError.
							self replicateAlteredObjectsAfterError]
			"In an error condition, we may have a traversal of immediate-faulting 
			altered objects in multi-trip, but once we're done with that we can release the cache."
			"session endingReplication"]
		ifFalse: 
			[storeTraversal exportPackedNotYetAccepted.
			answer := self replicateResult].
	^answer
]

{ #category : 'private - executing' }
GbxServerInteraction >> unwindServerCall: aResult 
[
	"The client stack is being cut back past the point that a server 
	GsProcess was initiated -- need to terminate the GsProcess. 
	aResult is normally a GbsError, but it's possible under abnormal 
	circumstances (like process termination before it's assigned)
	for it to be something else, like nil, in which case 
	there isn't much we can do."

	aResult gbxIsGSError ifTrue: [aResult terminateGsProcess]
]

{ #category : 'private - executing' }
GbxServerInteraction >> makeArgumentDelegates
[
	argumentDelegates := arguments 
				collect: [:arg | arg asGSObjectInSession: session]
]

{ #category : 'private - executing' }
GbxServerInteraction >> makeInitialCall
[

	self gbsMessenger statusTag: #makeInitialCall: message: '%1' with: self.
	^self doRoundTrip: 
			[GBSM clientMap checkFinalizer.
			serverInterface performInteraction: self]
]

{ #category : 'private - executing' }
GbxServerInteraction >> packForStore
[
	"Sender must hold session's sessionProtect"

	storeTraversal emptyBuffer.	"In an error-continue scenario, we use this traversal more than once,
								so the buffer might not be empty."
	shouldSynchronize
		ifTrue: [self packAllDirtyForServer]
		ifFalse: [self packDirtyArgumentsForUnsynchronizedOperation]
]

{ #category : 'private - executing' }
GbxServerInteraction >> allocateTraversals
[
	"Sender must hold my session's sessionProtect."
	
	statResource == nil
		ifTrue:
			[storeTraversal := GbxStoreTraversal for: self.
			fetchTraversal := GbxFetchTraversal for: self]
		ifFalse:
			[storeTraversal := GbxStoreTraversalWithStats for: self statResource: statResource.
			fetchTraversal := GbxFetchTraversalWithStats for: self statResource: statResource]
]

{ #category : 'private - executing' }
GbxServerInteraction >> privateExecute
[
	"Actually perform the server interaction, and process the results.
	Answer either a delegate or a replicate, as specified by replicateResult."

	"The critical section must encompass the flush, server execution, synchronization
	afterwards, and traversal of the result. However, it should *NOT* include signaling 
	any server error, since the debugger needs to contact the server from a different thread.
	It's also best if it does not include second pass of replication, since that pass also may
	need to contact the server to fetch the names of unmapped classes."

	| resultOrError |
	
	["isInitialCall is used by the debugger, by digging its value out of the context."
	| isInitialCall |
	isInitialCall := true.
	resultOrError := self makeInitialCall.
	[resultOrError gbxIsGSError] whileTrue: 
			[resultOrError processVerifyArgs: [self verify].
			isInitialCall := false.
			resultOrError := self stepOrContinueAfter: resultOrError]]
			ifCurtailed: [self cleanupCurtailed: resultOrError].
	^resultOrError

	"GbxDebuggerService, stack dumping, and the like depend on various aspects of the exact 
	structure of this method. 
	If you change this method in any way, you'll likely break the debugger unless you correct 
	the dependencies. You should be able to find all the dependencies by browsing senders 
	of #dependsOnStructureOfServerCall. If you add a dependency, please add a send of 
	this message."
]

{ #category : 'private - executing' }
GbxServerInteraction >> releaseTraversals
[
	"In all normal cases, including all expected error cases, both traversals are allocated and assigned
	before this message is sent. However, since this message is sent by an ensure block, and both variables
	are nil when the block is entered, we'll guard it. One case where this is needed is if the Process is terminated.
	Note that it's possible for a traversal to be created but not yet assigned to my instvar at termination, in which
	case it will *NOT* be released. I'm not too concerned about this case, as there are no normal errors that 
	should interrupt execution during that narrow window."

	storeTraversal ~~ nil ifTrue: [storeTraversal release].
	fetchTraversal ~~ nil ifTrue: [fetchTraversal release]
]

{ #category : 'private - executing' }
GbxServerInteraction >> cleanupCurtailed: resultOrError
[

	self unwindServerCall: resultOrError
]

{ #category : 'validation' }
GbxServerInteraction >> verify
[
	"Raise an error if someone gave me bogus things to execute.
	If everything looks hunky-dory, answer true."

	^self subclassResponsibility
]

{ #category : 'initialize-release' }
GbxServerInteraction >> initialize
[
	"Initialize instance variables that have defaults. Others must be set explicitly."

	arguments := #().	"Not all interactions take arguments, but this is safe to iterate over even so."
	shouldSynchronize := shouldReplicateResult := stopForBreakpoints := true.
	shouldReplicateResultBodyAsDelegates := false.
	replicationLevel := session defaultGStoSTLevel
]

{ #category : 'private - flushing' }
GbxServerInteraction >> packAllDirtyForServer
[
	"Pack all dirty objects into a traversal buffer to be sent to the server. 
	If more dirty objects than will fit, send intermediate traversal buffers."
	"Sender must hold session's sessionProtect"

	self makeArgumentDelegates.	"This will dirty any arguments that are client objects."
	session flushDirtyPoolTo: storeTraversal
]

{ #category : 'private - flushing' }
GbxServerInteraction >> copyNotConnectedArguments
[
	"All arguments that are not delegates and do not have delegates are sent #copy, and these will be used as the actual arguments.
	Used by the #unsynchronized* methods to avoid replicating literal strings and the like to the server."

	arguments := arguments collect: 
					[:arg |
					(arg isGSObject
						ifTrue: [arg]
						ifFalse: [arg gbxDelegate forSession: session]) ifNil: [arg copy]]
]

{ #category : 'private - flushing' }
GbxServerInteraction >> packDirtyArgumentsForUnsynchronizedOperation
[
	"Pack only any of the arguments that are marked dirty into a traversal buffer to be sent to the server. 
	If more dirty objects than will fit, send intermediate traversal buffers. This *should* be 
	limited to those arguments that are client-only objects, and need to be replicated to the server."
	"This is designed to be used by the #unsynchronized* methods. We set aside the dirty list
	to avoid flushing those objects. The arguments are then copied,
	 delegates are made for the arguments, which dirties the argument copies, then all dirty objects
	are flushed to the server. This will flush the transitive closure of the arguments to the server,
	provided no argument's transitive closure contains an existing replicate, a case which fails
	by design."
	"Sender must hold session's sessionProtect"

	
	[| index result |
	result := true.
	index := 1.
	
	[index <= arguments size and: 
			[result := (arguments at: index)
						gbxCanBeArgForUnsynchronizedOperationInSession: session]]
			whileTrue: [index := index + 1].
	result]
			gbxAssert.
	self copyNotConnectedArguments.
	session setAsideDirtyWhile: [self packAllDirtyForServer]
]

{ #category : 'dispatching' }
GbxServerInteraction >> storeTravDoArgs
[
	"Answer an arguments struct appropriate for myself.
	Since I don't know anything about such structs, ask the server interface for it, since it knows
	about such things."

	^self subclassResponsibility
]

{ #category : 'dispatching' }
GbxServerInteraction >> clampedTravArgs
[
	"Answer an arguments struct appropriate for myself.
	Since I don't know anything about such structs, ask the server interface for it, since it knows
	about such things."

	^serverInterface clampedTravArgsForServerInteraction: self
]

{ #category : 'printing' }
GbxServerInteraction >> printOn: aStream
[

	super printOn: aStream.
	aStream nextPutAll: ' for session '.
	(session isNil ifTrue: [nil] ifFalse: [session sessionId])
		printOn: aStream.
	aStream
		cr;
		nextPutAll: 'replicationSpecSelector: ';
		print: (replicationScheme ifNil: [nil] ifNotNil: [:scheme | scheme selector]);
		cr
]

{ #category : 'executing' }
GbxServerInteraction >> execute
[
	"Actually perform the server interaction, and process the results.
	Answer either a delegate or a replicate, as specified by replicateResult."

	| resultOrError |
	replicationClampDelegate := self fetchReplicationClamp.
	"Fetch the clamp *before* starting the interaction so that the error if 
	the scheme is invalid will be processed before we make the serverMap
	strong and finalize from it."
	^
	[
	[| completeResult |
	
	[session startingInteraction: self.
	resultOrError := self privateExecute.
	completeResult := self completeResult: resultOrError]
			ensure: [session endingInteraction: self].
	completeResult]
			on: GbxReturnNotification
			do: 
				[:ex |
				session isUnwindingAsyncAbort: true.
				ex return]]
			ifCurtailed: [session isUnwindingAsyncAbort: false]
]

{ #category : 'instance creation' }
GbxServerInteraction class >> interface: aServerInterface
[

	| newInstance session |
	newInstance := self new.
	session := aServerInterface session.
	newInstance
		serverInterface: aServerInterface;
		session: session;
		interactionState: session newInteractionState;
		initialize.
	^newInstance
]

