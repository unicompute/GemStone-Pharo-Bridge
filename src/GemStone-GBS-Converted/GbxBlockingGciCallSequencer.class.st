Class {
	#name : 'GbxBlockingGciCallSequencer',
	#superclass : 'GbxGciCallSequencer',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private-primitive access' }
GbxBlockingGciCallSequencer >> gciMoreTraversalBuffer: travBuff maxSize: travBuffSize 
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result boolean or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^self primInterface gciMoreTraversalBuffer: travBuff maxSize: travBuffSize

{ #category : 'private-primitive access' }
GbxBlockingGciCallSequencer >> gciStoreTravDo: storeTravDoArgs 
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^self primInterface gciStoreTravDo: storeTravDoArgs

{ #category : 'private-primitive access' }
GbxBlockingGciCallSequencer >> gciContinueProcess: errorContextOop returnValue: returnOop flags: flagInt error: errorInt 
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^self primInterface 
		gciContinueProcess: errorContextOop
		returnValue: returnOop
		flags: flagInt
		error: errorInt

{ #category : 'private-primitive access' }
GbxBlockingGciCallSequencer >> gciExecuteStrFromContextDbg: sourceString sourceSize: size sourceClass: class context: serverContext symbolList: aSymbolList flags: flagInt 
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^self primInterface 
		gciExecuteStrFromContextDbg: sourceString
		sourceSize: size
		sourceClass: class
		context: serverContext
		symbolList: aSymbolList
		flags: flagInt

{ #category : 'private-primitive access' }
GbxBlockingGciCallSequencer >> gciClampedTravOops: oopArray numOops: numOops travSpec: travSpec 
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result boolean or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^self primInterface 
		gciClampedTravOops: oopArray
		numOops: numOops
		travSpec: travSpec

{ #category : 'private-primitive access' }
GbxBlockingGciCallSequencer >> gciStoreTravBuffer: travBuffer flags: flagsInt 
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result boolean or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^self primInterface gciStoreTravBuffer: travBuffer flags: flagsInt

{ #category : 'private-primitive access' }
GbxBlockingGciCallSequencer >> gciStoreTravDoTravRefsnlr: oopsNoLongerReplicated nnr: numNotReplicated ogoc: oopsGcedOnClient ngc: numGced stdArgs: stdArgs ctArgs: ctArgs 
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^self primInterface 
		gciStoreTravDoTravRefsnlr: oopsNoLongerReplicated
		nnr: numNotReplicated
		ogoc: oopsGcedOnClient
		ngc: numGced
		stdArgs: stdArgs
		ctArgs: ctArgs

{ #category : 'private-primitive access' }
GbxBlockingGciCallSequencer >> gciPerformNoDebugReceiver: target selector: aSelector args: argArray numArgs: gsObjects flags: flagInt 
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result oop or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^self primInterface 
		gciPerformNoDebugReceiver: target
		selector: aSelector
		args: argArray
		numArgs: gsObjects
		flags: flagInt

{ #category : 'private - single round trip' }
GbxBlockingGciCallSequencer >> gciStoreTravDoTrav: storeTravDoArgs travStruct: travSpec 
	"Make the C call, with a uniform interface 
	across blocking and non-blocking.
	Will answer result boolean or a GbsError.
	Sender must hold my accessProtect and GciCallProtect."

	^self primInterface gciStoreTravDoTrav: storeTravDoArgs
		travStruct: travSpec

{ #category : 'services' }
GbxBlockingGciCallSequencer >> gciCall: callBlock resultType: typeSymbol 
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

	Since this is the blocking interface, resultType is ignored; the original callBlock 
	answers the correct type. The entire client VM is blocked until the result from the
	server is ready."

	^self setSessionPerformCheck: callBlock

{ #category : 'testing' }
GbxBlockingGciCallSequencer >> isBlocking
	^true

