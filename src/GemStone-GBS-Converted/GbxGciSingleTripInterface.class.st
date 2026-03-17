Class {
	#name : #'GbxGciSingleTripInterface',
	#superclass : #'GbxServerInterface',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'testing' }
GbxGciSingleTripInterface >> isSingleTrip
	"Answer false if using the legacy multi-trip interface; 
	true if using the single-trip (GciStoreTravDoTravRefs) interface introduced in GS64 2.2.5.x"
	
	^true

{ #category : #'ServerInteraction interface' }
GbxGciSingleTripInterface >> clampedTravArgsForServerInteraction: serverInteraction

	| ctArgs |
	ctArgs := super clampedTravArgsForServerInteraction: serverInteraction.
	ctArgs level: serverInteraction replicationLevel.
	^ctArgs

{ #category : #'ServerInteraction interface' }
GbxGciSingleTripInterface >> storeTravDoArgsForEvaluation: evaluation 
	"Answer an initialized struct.
	Allocates C memory for the selector; sender must free when done."

	| storeTravDoArgs args |
	storeTravDoArgs := super storeTravDoArgsForEvaluation: evaluation.
	args := evaluation argumentDelegates.
	storeTravDoArgs
		doPerform: (evaluation isBlock ifTrue: [2] ifFalse: [0]);
		execBlockArgs: (self oopArrayFromDelegates: args) asAddress;
		execBlockNumArgs: args size.
	^storeTravDoArgs

{ #category : #'ServerInteraction interface' }
GbxGciSingleTripInterface >> continueAfter: error forInteraction: serverInteraction 
	"Perform the specified server interaction. Answer a delegate representing the server object
	returned from the server, or a GbsError.

	Sender must hold my session's sessionProtect"

	| storeTravDoArgs clampedTravArgs |
	storeTravDoArgs := self 
				storeTravDoArgsForContinuationOf: serverInteraction
				afterError: error.
	clampedTravArgs := serverInteraction clampedTravArgs.
	^self 
		roundTripForInteraction: serverInteraction
		withStoreTravDoArgs: storeTravDoArgs
		clampedTravArgs: clampedTravArgs

{ #category : #'ServerInteraction interface' }
GbxGciSingleTripInterface >> storeTravDoArgsForContinuationOf: serverInteraction afterError: error
	"Allocates C memory for the selector; sender must free when done.
	error is a GbsError"

	| storeTravDoArgs |
	storeTravDoArgs := self storeTravDoArgsBuffer.
	"Already set:  StoreTravFlags, the unused buffers and sizes.."
	storeTravDoArgs
		storeTravBuff: serverInteraction storeTraversal buffer asAddress;
		doPerform: 4;
		doFlags: (self doFlagsForInteraction: serverInteraction);
		process: error serverProcess oopValue;
		storeTravFlags: (self storeTravFlagsForInteraction: serverInteraction);
		replaceTopOfStackWith: error gsReturnVal oopValue.
	^storeTravDoArgs

{ #category : #'ServerInteraction interface' }
GbxGciSingleTripInterface >> storeTravDoArgsForTraversal: serverTraversal

	| storeTravDoArgs |
	storeTravDoArgs := self storeTravDoArgsBuffer.
	storeTravDoArgs
		storeTravBuff: serverTraversal storeTraversal buffer asAddress;
		doPerform: 3;
		doFlags: 0;
		receiver: serverTraversal rootDelegate oopValue;
		selector: 0;
		args: 0;
		numArgs: 0;
		storeTravFlags: (self storeTravFlagsForInteraction: serverTraversal).
	^storeTravDoArgs

{ #category : #'retrievalFlags' }
GbxGciSingleTripInterface >> retrievalFlagsForServerInteraction: serverInteraction

	| retrievalFlags |
	retrievalFlags := super
				retrievalFlagsForServerInteraction: serverInteraction.
	serverInteraction shouldReplicateResult
		ifFalse: [retrievalFlags := retrievalFlags + self excludeResultObjFlag].
	"For 3.2.3 and later servers, we do not want to get the extra root report for a clean exported object.
	This flag is ignored in earlier server versions, so is safe to set unconditionally."
	retrievalFlags := retrievalFlags + 16r100.	"GCI_TRAV_REFS_EXCLUDE_EXPORTED_RESULT_OBJ"
	^retrievalFlags

{ #category : #'retrievalFlags' }
GbxGciSingleTripInterface >> excludeResultObjFlag
	"Used for #execute:, #remotePerform:, and any other place where we do not 
	want traversed results, even though we're in single-trip. The relevant flag is 
	GCI_TRAV_REFS_EXCLUDE_RESULT_OBJ = 0x80."

	^16r80

{ #category : #'private' }
GbxGciSingleTripInterface >> loginFlags
	"Refer to the superclass implementation for the complete list of flags."

	| loginFlags |
	loginFlags := 8.	"Single trip always uses the reference set"
	GbsConfiguration current fullCompression
		ifTrue: [loginFlags := loginFlags + 4].
	GbsConfiguration current verbose
		ifFalse: [loginFlags := loginFlags + 16].
	^loginFlags

{ #category : #'private' }
GbxGciSingleTripInterface >> x509ArgsForParameters: parameters

	| args |
	args := GbxX509LoginArg allocate.
	args
		argsArePemStrings: parameters argsArePemStrings;
		caCert: parameters caCert;
		cert: parameters cert;
		dirArg: parameters dirArg;
		extraGemArgs: parameters extraGemArgs;
		logArg: parameters logArg;
		netldiHostOrIp: parameters netldiHostOrIp;
		netldiNameOrPort: parameters netldiNameOrPort;
		privateKey: parameters privateKey;
		loginFlags: self loginFlags.
	^args

{ #category : #'private' }
GbxGciSingleTripInterface >> x509LoginFor: parameters
	"Private. Make the GciX509Login() call. 
	This must be done in the proper context.
	The sender must hold GciCallProtect"

	| args |
	args := self x509ArgsForParameters: parameters.
	^callSequencer performCheck: 
			[self gbsMessenger statusTag: #GciX509Login message: ''.
			callSequencer primInterface gciX509Login: args asAddress]

{ #category : #'GbsSessionManager interface' }
GbxGciSingleTripInterface >> gbsImageStartup
	"Discard defunct C pointers"

	super gbsImageStartup.
	gcedOopBuffer := nil.
	oopsNoLongerReplicatedBuffer := nil

{ #category : #'private - old single round trip' }
GbxGciSingleTripInterface >> execute: aStringOrSymbol class: aGSObject context: aGSObject2 symbolList: aGSObject3 numDirtyOops: anInteger2 numAlteredPairs: anInteger3 travBuffer: aGSTraversalBuffer withClamps: clampSpec toLevel: level retrieveFlags: retrieveFlags clampedTravBuffer: aClampedTravBuffer 
	^self gbsMessenger 
		error: 'Old style single round trip is not permitted with true single round trip'

{ #category : #'private - old single round trip' }
GbxGciSingleTripInterface >> receiver: aGSObject selector: aStringOrSymbol args: arrayOfGSObjects numDirtyOops: anInteger2 numAlteredPairs: anInteger3 travBuffer: aGSTraversalBuffer withClamps: clampSpec toLevel: level retrieveFlags: retrieveFlags clampedTravBuffer: aClampedTravBuffer 
	^self gbsMessenger 
		error: 'Old style single round trip is not permitted with true single round trip'

{ #category : #'GbsSession interface' }
GbxGciSingleTripInterface >> newMessageSend
	^GbxSingleTripServerMessageSend interface: thisSession serverInterface

{ #category : #'GbsSession interface' }
GbxGciSingleTripInterface >> executableBlockClassDelegate
	"Answer a delegate for the class used for executable blocks. This is ExecutableBlock in GS64 v2.x
	and ExecBlock GS64 3.0, so this special mechanism is required. At this point, only the prim interface is of a different
	class for 3.0, so we'll defer to it through the callSequencer as usual. "

	^callSequencer primInterface executableBlockClassOop asGSObjectInSession: thisSession

{ #category : #'GbsSession interface' }
GbxGciSingleTripInterface >> roundTripForInteraction: serverInteraction withStoreTravDoArgs: storeTravDoArgs clampedTravArgs: clampedTravArgs
	"Send the specified message to the server. Answer a delegate representing the server object
	returned from the server execution, or a GbsError.
	Sender must hold my sessionProtect."

	| callResult resultOop |
	self assertNotInTraversal.
	callResult := callSequencer gciCall: 
					[callSequencer
						gciStoreTravDoTravRefsnlr: self oopsNoLongerReplicatedBuffer asAddress
						nnr: self oopsNoLongerReplicatedBuffer numOops
						ogoc: self gcedOopBuffer asAddress
						ngc: self gcedOopBuffer numOops
						stdArgs: storeTravDoArgs asAddress
						ctArgs: clampedTravArgs asAddress]
				resultType: #intResult.
	callResult gbxIsGSError ifTrue: [^callResult].
	callResult ~~ 0 ifTrue: [self needMoreTraversal].
	serverInteraction fetchTraversal traversalCompleted: callResult == 0.
	resultOop := clampedTravArgs resultOop.
	^GbxDelegate oopValue: resultOop session: thisSession

{ #category : #'GbsSession interface' }
GbxGciSingleTripInterface >> saveFetchedOops: delegates
	"In single-trip, fetched oops are automatically in the referenced set, so no action needed here"

{ #category : #'GbsSession interface' }
GbxGciSingleTripInterface >> newServerTraversal
	^GbxSingleTripServerTraversal interface: thisSession serverInterface

{ #category : #'GbsSession interface' }
GbxGciSingleTripInterface >> addToNoLongerReplicated: aDelegate
	"This oop may be in the server's pure export set because the server sent a full report for it.
	If we do not replicate the object, or turn the replicate into a stub or forwarder, we must 
	let the server know. The noLongerReplicated list is where we keep the delegates whose 
	oops must be sent to the server at the next round trip."
	"Sender must hold my session's sessionProtect."

	[aDelegate isGSObject] gbxAssert.
	(aDelegate inExport
		and: [aDelegate isSpecial not and: [aDelegate ~= OIllegal]])
			ifTrue: [noLongerReplicatedOops add: aDelegate]

{ #category : #'GbsSession interface' }
GbxGciSingleTripInterface >> newServerEvaluation
	^GbxSingleTripServerEvaluation interface: thisSession serverInterface

