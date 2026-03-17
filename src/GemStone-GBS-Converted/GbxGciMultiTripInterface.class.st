Class {
	#name : #'GbxGciMultiTripInterface',
	#superclass : #'GbxServerInterface',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'buffers' }
GbxGciMultiTripInterface >> dirtyOopBuffer
	
	dirtyOopBuffer isNil
		ifTrue: [dirtyOopBuffer := thisSession oopArrayClass size: 2000].
	^dirtyOopBuffer

{ #category : #'buffers' }
GbxGciMultiTripInterface >> alteredOopBuffer
	
	alteredOopBuffer isNil
		ifTrue: [alteredOopBuffer := thisSession oopArrayClass size: 4000].
	^alteredOopBuffer

{ #category : #'testing' }
GbxGciMultiTripInterface >> isSingleTrip
	"Answer false if using the legacy multi-trip interface; 
	true if using the single-trip (GciStoreTravDoTravRefs) interface introduced in GS64 2.2.5.x"
	
	^false

{ #category : #'private' }
GbxGciMultiTripInterface >> loginFlags
	"Refer to the superclass implementation for the complete list of flags."

	^GbsConfiguration current fullCompression
		ifTrue: [4]
		ifFalse: [0]

{ #category : #'private' }
GbxGciMultiTripInterface >> releaseOops: oopArray
	"Sender must hold my session's sessionProtect"
	
	^callSequencer
		setSessionPerformCheck:
			[callSequencer primInterface
				gciReleaseOops: oopArray asAddress
				with: oopArray size]

{ #category : #'private' }
GbxGciMultiTripInterface >> roundTripForInteraction: serverInteraction withStoreTravDoArgs: storeTravDoArgs clampedTravArgs: clampedTravArgs
	"Send the specified message to the server. Answer a delegate representing the server object
	returned from the server execution, or a GbsError.
	In multi-trip, it's possible that a StoreTravDo will not be required (a traversal that has no dirty objects to flush).
	In this case, storeTravDoArgs will be nil.

	Sender must hold my session's sessionProtect."

	| callResult immediateOops |
	self assertNotInTraversal.
	self gcedOopBuffer isEmpty ifFalse: [self releaseOops: gcedOopBuffer].
	^storeTravDoArgs == nil
		ifFalse: 
			[callResult := self storeTravDoWithArgs: storeTravDoArgs.
			callResult isFatalError
				ifFalse: 
					[immediateOops := callResult processDirtyAndAltered.
					self
						traverseDelegates: immediateOops
						forInteraction: serverInteraction
						level: 1].
			callResult resultOrError]
		ifTrue: [serverInteraction defaultResult]

{ #category : #'private' }
GbxGciMultiTripInterface >> x509LoginFor: parameters

	self gbsMessenger
		error: 'x509 login is not supported with this GemStone server version.'

{ #category : #'private' }
GbxGciMultiTripInterface >> resultObjectFromPrimResult: callResult

	| result |
	result := GbxServerCallResult serverInterface: self.
	callResult isNil ifTrue: [^result].
	callResult gbxIsGSError
		ifTrue: [result gsError: callResult]
		ifFalse: 
			[result resultOop: (GbxDelegate oopValue: callResult session: thisSession)].
	^result

{ #category : #'ServerInteraction interface' }
GbxGciMultiTripInterface >> traverseDelegates: delegates forInteraction: serverInteraction level: anInteger
	
	| clampedTravArgs result completed |
	delegates isEmpty
		ifTrue:
			["no work needed."
			^self].
	clampedTravArgs := self clampedTravArgsForServerInteraction:
			serverInteraction.
	clampedTravArgs level: anInteger.
	result := callSequencer
		gciCall:
			[callSequencer
				gciClampedTravOops: (self oopArrayFromDelegates: delegates) asAddress
				numOops: delegates size
				travSpec: clampedTravArgs asAddress]
		resultType: #booleanResult.
	completed := GbsError
		primResultOrError: result
		verifyArgs:
			[(GbsError verify: delegates is: Array of: GbxDelegate)
				and: [serverInteraction verify]]
		session: thisSession.
	completed ifFalse: [self needMoreTraversal].
	serverInteraction fetchTraversal traversalCompleted: completed

{ #category : #'ServerInteraction interface' }
GbxGciMultiTripInterface >> storeTravDoArgsForEvaluation: evaluation
	"Answer an initialized struct."

	| storeTravDoArgs |
	storeTravDoArgs := super storeTravDoArgsForEvaluation: evaluation.
	storeTravDoArgs
		doPerform: 0;
		alteredTheOops: self dirtyOopBuffer asAddress;
		alteredNumOops: self dirtyOopBuffer "bufferSize" numOops;
		alteredSymbolBuf: self alteredOopBuffer asAddress;
		alteredNumPairs: self alteredOopBuffer "bufferSize" numOops // 2.
	^storeTravDoArgs

{ #category : #'ServerInteraction interface' }
GbxGciMultiTripInterface >> storeTravDoArgsForMessageSend: messageSend 
	"Allocates C memory for the selector; sender must free when done."

	| storeTravDoArgs |
	storeTravDoArgs := super storeTravDoArgsForMessageSend: messageSend.
	storeTravDoArgs
		alteredTheOops: self dirtyOopBuffer asAddress;
		alteredNumOops: self dirtyOopBuffer numOops;
		alteredSymbolBuf: self alteredOopBuffer asAddress;
		alteredNumPairs: self alteredOopBuffer numOops // 2.
	^storeTravDoArgs

{ #category : #'ServerInteraction interface' }
GbxGciMultiTripInterface >> continueAfter: error forInteraction: serverInteraction
	"Perform the specified server interaction. Answer a delegate representing the server object
	returned from the server, or a GbsError."
	"Sender must hold my session's accessProtect."

	| callResult result immediateOops |
	self assertNotInTraversal.
	self gcedOopBuffer isEmpty ifFalse: [self releaseOops: gcedOopBuffer].
	serverInteraction hasObjectsToStore
		ifTrue: 
			[| storeResult |
			storeResult := thisSession
						storeTraversalBuffer: serverInteraction storeTraversal buffer.
			storeResult gbxIsGSError ifTrue: [^storeResult]].
	callResult := callSequencer gciCall: 
					[callSequencer
						gciContinueProcess: error serverProcess oopValue
						returnValue: error gsReturnVal oopValue
						flags: (self doFlagsForInteraction: serverInteraction)
						error: 0]
				resultType: #oopResult.
	result := self resultObjectFromPrimResult: callResult.
	result
		alteredCompleted: false;
		dirtyOops: Array new;
		alteredPairs: Array new.
	result isFatalError
		ifFalse: 
			[immediateOops := result processDirtyAndAltered.
			self
				traverseDelegates: immediateOops
				forInteraction: serverInteraction
				level: 1].
	^result resultOrError

{ #category : #'ServerInteraction interface' }
GbxGciMultiTripInterface >> storeTravDoArgsForTraversal: serverTraversal
	"In multi-trip, a traversal does a StoreTravDo that just returns self,
	for the sole purpose of flushing objects to the server and fitting in with the other code."

	| storeTravDoArgs sourceCode sourceClassDelegate |
	storeTravDoArgs := self storeTravDoArgsBuffer.
	sourceCode := 'self'.
	sourceClassDelegate := sourceCode class gbxDelegate
				forSession: thisSession.
	storeTravDoArgs
		storeTravBuff: serverTraversal storeTraversal buffer asAddress;
		doPerform: 0;
		doFlags: 2;
		source: sourceCode gbxAsCString;
		sourceSize: 4;
		sourceClass: sourceClassDelegate oopValue;
		contextObject: serverTraversal rootDelegate oopValue;
		symbolList: thisSession oopNil oopValue;
		alteredTheOops: self dirtyOopBuffer asAddress;
		alteredNumOops: self dirtyOopBuffer numOops;
		alteredSymbolBuf: self alteredOopBuffer asAddress;
		alteredNumPairs: self alteredOopBuffer numOops // 2;
		storeTravFlags: (self storeTravFlagsForInteraction: serverTraversal).	"doFlags of 2: Disable async events, disable debug, no single step"
	^storeTravDoArgs

{ #category : #'support' }
GbxGciMultiTripInterface >> storeTravDoWithArgs: storeTravDoArgs
	"Execute a GciStoreTravDo, using the given 
	GbxGciStoreTravDoArgsSType as an argument.
	Sender must hold my <accessProtect>"
	
	| result callResult |
	callResult := callSequencer
		gciCall: [callSequencer gciStoreTravDo: storeTravDoArgs asAddress]
		resultType: #oopResult.
	result := self resultObjectFromPrimResult: callResult.
	result
		alteredCompleted: storeTravDoArgs alteredCompleted;
		dirtyOops:
				(dirtyOopBuffer
						asDelegateArrayOfSize: storeTravDoArgs alteredNumOops
						forSession: thisSession);
		alteredPairs:
				(alteredOopBuffer
						asDelegateArrayOfSize: storeTravDoArgs alteredNumPairs * 2
						forSession: thisSession).
	^result

{ #category : #'GbxStoreTravDoResult interface' }
GbxGciMultiTripInterface >> fetchAlteredObjectsInto: aResult

	| result numDirtyOopsPtr numAlteredPairsPtr |
	result := callSequencer setSessionPerformCheck: 
					[numDirtyOopsPtr := self longHolderBuffer.
					numDirtyOopsPtr content: 1000.
					numAlteredPairsPtr := self longHolderBuffer2.
					numAlteredPairsPtr content: 1000.
					callSequencer primInterface
						gciAlteredObjs: dirtyOopBuffer asAddress
						numDirty: numDirtyOopsPtr asAddress
						altered: alteredOopBuffer asAddress
						numAltered: numAlteredPairsPtr].
	result gbxIsGSError
		ifTrue: 
			["Got an error trying to fetch altered objects, 
			this is probably more serious than any original error, so write over the original."
			aResult
				dirtyOops: Array new;
				alteredPairs: Array new;
				alteredCompleted: true;
				gsError: result]
		ifFalse: 
			[aResult
				dirtyOops: (dirtyOopBuffer asDelegateArrayOfSize: numDirtyOopsPtr content
							forSession: thisSession);
				alteredPairs: (alteredOopBuffer
							asDelegateArrayOfSize: numAlteredPairsPtr content * 2
							forSession: thisSession);
				alteredCompleted: result]

{ #category : #'GbsSession interface' }
GbxGciMultiTripInterface >> newServerEvaluation
	^GbxMultiTripServerEvaluation interface: thisSession serverInterface

{ #category : #'GbsSession interface' }
GbxGciMultiTripInterface >> newServerTraversal
	^GbxMultiTripServerTraversal interface: thisSession serverInterface

{ #category : #'GbsSession interface' }
GbxGciMultiTripInterface >> newMessageSend
	^GbxMultiTripServerMessageSend interface: thisSession serverInterface

{ #category : #'GbsSession interface' }
GbxGciMultiTripInterface >> addToNoLongerReplicated: aDelegate
	"do nothing, only used in single trip"

{ #category : #'GbsSession interface' }
GbxGciMultiTripInterface >> saveFetchedOops: delegates
	"In multi-trip, objects are fetched with no subleaf headers, so they are not in the export set."
	"Need to send the session's version of this method so that we grab the sessionProtect first."

	thisSession saveObjects: delegates

