Class {
	#name : 'GbxNonBlockingGciCallSequencer',
	#superclass : 'GbxGciCallSequencer',
	#instVars : [
		'inNonBlockingCall',
		'inInterruptableCall',
		'pointerPointer',
		'nbSocket'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbxNonBlockingGciCallSequencer >> isBlocking
[

	^false
]

{ #category : 'nonblocking support' }
GbxNonBlockingGciCallSequencer >> handleInterruptWhile: aBlock 
[
	"Evaluate aBlock while handling user interrupt.  If user interrupt
	 occurs, send gciSoftBreak.  If there has been no response after
	 three interrupts, gciHardBreak is sent.  Return the value of aBlock.
	Ignore the interrupt if we're not in an interruptable call."

	| breakCountHolder |
	self gbxFixMe.	"The change to this method needs to be propagated to VA-specific code."
	breakCountHolder := Array with: 0.
	^aBlock
		on: GbsError userBreakSignal
		do: 
			[:ex | 
			inInterruptableCall 
				ifTrue: 
					[self processUserBreakCountHolder: breakCountHolder.
					ex resume]
				ifFalse: [ex pass]]
]

{ #category : 'nonblocking support' }
GbxNonBlockingGciCallSequencer >> waitForResult: initialResult type: resultType
[
	"InitialResult must be the answer from the original GCI call. If we're in a 
	non-blocking operation, and the initialResult wasn't an error, block the active 
	Process (waiting for activity on the GCI in-band socket.) until the results are 
	ready. If the call wasn't non-blocking, initialResult is the final result. Answer 
	a GbsError, or if no error the result of the specified type. resultType
	must be a symbol, a selector in the 'results' protocol of GbxPointer.
	Sender must hold this session's accessProtect."

	| done statsEnabled |
	(inNonBlockingCall not or: [initialResult gbxIsGSError])
		ifTrue: [^initialResult].	"Okay, we're in a non-blocking call; wait for the result."
	statsEnabled := thisSession mainStatsEnabled.
	
	[done := self setSessionPerformCheck: 
					[self primInterface gciNbEndResultPtrPtr: self pointerPointer asAddress].
	statsEnabled ifTrue: [thisSession statResource gbxIncProgress: done].
	done == self class resultReady]
			whileFalse: 
				[done gbxIsGSError ifTrue: [^done].
				done == self class resultProgressed
					ifFalse: 
						[self nbSocket
							readWaitWithTimeoutMs: thisSession configuration socketWaitTimeout]].
	^self pointerPointer perform: resultType
]

{ #category : 'nonblocking support' }
GbxNonBlockingGciCallSequencer >> stopNbWaitSocket
[
	"Shutdown the socket accessor that is waiting for activity on the in-band GCI socket."

	nbSocket notNil 
		ifTrue: 
			[self shutdownSocket: nbSocket withHandle: self getNBNotifyHandle.
			nbSocket := nil]
]

{ #category : 'nonblocking support' }
GbxNonBlockingGciCallSequencer >> waitFor: mSec 
[
	(GbxDelay forMilliseconds: mSec) wait
]

{ #category : 'nonblocking support' }
GbxNonBlockingGciCallSequencer >> processUserBreakCountHolder: countHolder 
[
	"The first two user interrupts will send GemStone a soft break, which
	 should interrupt the GemStone interpreter.  The third will send hard
	 break, which should abort the transaction.  Subsequent user interrupts
	 are passed on to the Smalltalk user interrupt handler."

	| count |
	count := (countHolder at: 1) + 1.
	countHolder at: 1 put: count.
	count < 3 ifTrue: [^thisSession softBreak].
	count == 3 ifTrue: [^thisSession hardBreak].
	"If control is here, more than three user interrupts have been received
	 with no response."
	self gbsMessenger error: 'GemStone did not respond to soft or hard break'
]

{ #category : 'nonblocking support' }
GbxNonBlockingGciCallSequencer >> pollForResult: initialResult type: resultType
[
	"InitialResult must be the answer from the original GCI call. If we're in a 
	non-blocking operation, and the initialResult wasn't an error, block the active 
	Process (in a restless sleep) until the results are ready. If the call wasn't 
	non-blocking, initialResult is the final result.
	Answer a GbsError, or if no error the result of the specified type. resultType
	must be a symbol, a selector in the 'results' protocol of GbxPointer.
	Sender must hold this session's accessProtect."
	
	| delayDelta currentDelay done statsEnabled |
	(inNonBlockingCall not or: [initialResult gbxIsGSError])
		ifTrue: [^initialResult].	"Okay, we're in a non-blocking call; poll for the result."
	delayDelta := 1.
	currentDelay := 0.
	statsEnabled := thisSession mainStatsEnabled.
	[done := self
		setSessionPerformCheck:
			[self primInterface gciNbEndResultPtrPtr: self pointerPointer asAddress].
	statsEnabled ifTrue: [thisSession statResource gbxIncProgress: done].
	done == self class resultReady]
		whileFalse:
			[done gbxIsGSError ifTrue: [^done].
			done == self class resultProgressed
				ifTrue: [currentDelay := 0]
				ifFalse:
					[currentDelay := currentDelay + delayDelta min: 50.
					self waitFor: currentDelay]].
	^self pointerPointer perform: resultType
]

{ #category : 'call services' }
GbxNonBlockingGciCallSequencer >> gciCall: callBlock resultType: typeSymbol 
[
	"Acquire GciCallProtect, set the current session, execute the 'real work' GCI 
	call in <callBlock> (which must be a call with a non-blocking variant),
	and check for errors. Answer the specified type of result. 
	<typeSymbol> must be a selector in the 'results' protocol of GbxPointer.
	Sender must hold my <accessProtect> semaphore.

	 Protect with a global semaphore, rather than the session-based semaphore,
	 because preemption of one gcisetsession/gcisomecall sequence with another
	 will cause the gci call to be executed against the wrong session.  One way
	 to eliminate this need is to rewrite the GCI layer such that all calls take a 
	session id argument.

	For the non-blocking interface, resultType must be the correct type for the
	GCI call in callBlock. The active Process is blocked until the result from the 
	server is ready, but other Processes in the client VM can continue, and a
	UserInterrupt raised in the active process will interrupt the server execution."

	^self handleInterruptWhile: 
			[| initialResult result |
			
			[
			[initialResult := self setSessionPerformCheck: callBlock.
			result := self waitForResult: initialResult type: typeSymbol] 
					ifCurtailed: 
						["Soft-break and complete the non-blocking call sequence if curtailed - 
					otherwise, the sequence won't be completed, and other 
					threads will get #gciErrOpInProgress"

						inNonBlockingCall 
							ifTrue: 
								[thisSession softBreak.
								"Due to VW bug 35987, we cannot do a normal wait here on Windows, must poll"
								result := self pollForResult: initialResult type: typeSymbol]	"if we couldn't get the semaphore, we better not send a softBreak"]] 
					ensure: 
						[inNonBlockingCall := false.
						inInterruptableCall := false].
			result]
]

{ #category : 'buffers' }
GbxNonBlockingGciCallSequencer >> pointerPointer
[
	"Return a buffer that acts as a pointer to a pointer."

	pointerPointer isNil ifTrue: [
		pointerPointer := GbxPointer allocate].
	^pointerPointer
]

{ #category : 'socket interface' }
GbxNonBlockingGciCallSequencer >> getNBNotifyHandle
[
	"Sender must hold my accessProtect"

	^self setSessionPerformCheck: [self primInterface gciNBGetNotifyHandle]
]

{ #category : 'socket interface' }
GbxNonBlockingGciCallSequencer >> nbSocket
[
	"Create the socket accessor that will wait for activity on the in-band socket as
	an alternative to doing time-based delays.

	If we are using a 3.2 or later server, the concept of an in-band and out-of-band
	socket are no longer relevant. Instead we will get a socket accessor 
	that makes a thread-safe gci call to wait on the socket."

	| handle |
	nbSocket isNil
		ifTrue: 
			[handle := self getNBNotifyHandle.
			nbSocket := self socketAccessorOn: handle].
	^nbSocket
]

{ #category : 'initialize-release' }
GbxNonBlockingGciCallSequencer >> initialize
[
	inNonBlockingCall := false.
	inInterruptableCall := false.
	^self
]

{ #category : 'initialize-release' }
GbxNonBlockingGciCallSequencer >> gbsImageStartup
[
	"Discard defunct C pointers"

	super gbsImageStartup.
	pointerPointer := nil
]

{ #category : 'private-primitive access' }
GbxNonBlockingGciCallSequencer >> gciStoreTravDoTravRefsnlr: oopsNoLongerReplicated nnr: numNotReplicated ogoc: oopsGcedOnClient ngc: numGced stdArgs: stdArgs ctArgs: ctArgs 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	inNonBlockingCall := true.
	inInterruptableCall := true.
	^self primInterface 
		gciNbStoreTravDoTravRefsnlr: oopsNoLongerReplicated
		nnr: numNotReplicated
		ogoc: oopsGcedOnClient
		ngc: numGced
		stdArgs: stdArgs
		ctArgs: ctArgs
]

{ #category : 'private-primitive access' }
GbxNonBlockingGciCallSequencer >> gciPerformNoDebugReceiver: target selector: aSelector args: argArray numArgs: gsObjects flags: flagInt 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	inNonBlockingCall := true.
	inInterruptableCall := true.
	^self primInterface 
		gciNbPerformNoDebugReceiver: target
		selector: aSelector
		args: argArray
		numArgs: gsObjects
		flags: flagInt
]

{ #category : 'private-primitive access' }
GbxNonBlockingGciCallSequencer >> gciMoreTraversalBuffer: travBuff maxSize: travBuffSize 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result boolean or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	inNonBlockingCall := true.
	^self primInterface gciNbMoreTraversalBuffer: travBuff
		maxSize: travBuffSize
]

{ #category : 'private-primitive access' }
GbxNonBlockingGciCallSequencer >> gciExecute: executeString context: contextOop symbolList: symlistOop travSpec: travSpec 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result boolean or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	inNonBlockingCall := true.
	inInterruptableCall := true.
	^self primInterface 
		gciNbExecute: executeString
		context: contextOop
		symbolList: symlistOop
		travSpec: travSpec
]

{ #category : 'private-primitive access' }
GbxNonBlockingGciCallSequencer >> gciStoreTravDo: storeTravDoArgs 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	inNonBlockingCall := true.
	inInterruptableCall := true.
	^self primInterface gciNbStoreTravDo: storeTravDoArgs
]

{ #category : 'private-primitive access' }
GbxNonBlockingGciCallSequencer >> gciContinueProcess: errorContextOop returnValue: returnOop flags: flagInt error: errorInt 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	inNonBlockingCall := true.
	inInterruptableCall := true.
	^self primInterface 
		gciNbContinueProcess: errorContextOop
		returnValue: returnOop
		flags: flagInt
		error: errorInt
]

{ #category : 'private-primitive access' }
GbxNonBlockingGciCallSequencer >> gciExecuteStrFromContextDbg: sourceString sourceSize: size sourceClass: class context: serverContext symbolList: aSymbolList flags: flagInt 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	inNonBlockingCall := true.
	inInterruptableCall := true.
	^self primInterface 
		gciNbExecuteStrFromContextDbg: sourceString
		sourceSize: size
		sourceClass: class
		context: serverContext
		symbolList: aSymbolList
		flags: flagInt
]

{ #category : 'private-primitive access' }
GbxNonBlockingGciCallSequencer >> gciClampedTravOops: oopArray numOops: numOops travSpec: travSpec 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result boolean or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	inNonBlockingCall := true.
	^self primInterface 
		gciNbClampedTravOops: oopArray
		numOops: numOops
		travSpec: travSpec
]

{ #category : 'private-primitive access' }
GbxNonBlockingGciCallSequencer >> gciStoreTravBuffer: travBuffer flags: flagsInt 
[
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result boolean or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	inNonBlockingCall := true.
	^self primInterface gciNbStoreTravBuffer: travBuffer flags: flagsInt
]

{ #category : 'constants' }
GbxNonBlockingGciCallSequencer class >> resultReady
[
	^2
]

{ #category : 'constants' }
GbxNonBlockingGciCallSequencer class >> resultNotReady
[
	^0
]

{ #category : 'constants' }
GbxNonBlockingGciCallSequencer class >> resultProgressed
[
	^1
]
