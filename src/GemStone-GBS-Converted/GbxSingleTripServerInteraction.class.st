Class {
	#name : 'GbxSingleTripServerInteraction',
	#superclass : 'GbxServerInteraction',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private - executing' }
GbxSingleTripServerInteraction >> replicateAlteredObjectsAfterError
[
	"Used after an error interrupted execution. Note that an 'error' includes things like 
	client forwarder sends and breakpoints.

	Normally, answer resultDelegateOrError, which is known to be an error if this message is sent.
	However, if we run into an error replicating the altered objects,
	that error is probably worse than the original error, so answer the new error."

	| serverTraversal result |
	serverTraversal := serverInterface newServerTraversal.
	"stopForBreakpoints false to avoid asynch events at this point."
	"Only traversing the altered objects, no actual result, so rootDelegate nil."
	"Explicitly use my replication clamp. If the session's replication clamp has been flushed
	and we tried to recompute it at this point we'd get the altered objects with a nil
	replication clamp and choke on any objects that should have been traversed by callback."
	"Similarly, cannot cache GsInstVarNames at this point, so shouldSynchronize must be false."
	result := serverTraversal
				shouldReplicateResult: false;
				shouldSynchronize: false;
				replicationClampDelegate: replicationClampDelegate;
				stopForBreakpoints: false;
				rootDelegate: session oopNil;
				replicationScheme: replicationScheme;
				execute.
	"Shouldn't normally error here, but need to check in case of things like 
	session termination, or server out of memory."
	^result gbxIsGSError ifTrue: [result] ifFalse: [resultDelegateOrError]
]

{ #category : 'private - executing' }
GbxSingleTripServerInteraction >> replicateResult
[
	"In single-trip, the traversal contains all altered objects, and the traversal of the result if it was specified earlier.
	Answer the given delegate unless an error occurs during replication. In that case, answer
	the error."

	| error |
	error := replication replicateFromTraversal: fetchTraversal.
	^error == nil ifTrue: [resultDelegateOrError] ifFalse: [error]
]

{ #category : 'accessing' }
GbxSingleTripServerInteraction >> shouldExportResults
[
	"Only export the result if we're replicating the result. Otherwise, result oops end 
	up in the export set when they should be only in the referenced set to keep them alive."

	^shouldReplicateResult
]

