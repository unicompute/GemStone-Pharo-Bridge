Class {
	#name : 'GbxMultiTripServerInteraction',
	#superclass : 'GbxServerInteraction',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxMultiTripServerInteraction >> defaultResult
[
	
	self gbsMessenger error: 'No default result for this type of interaction'
]

{ #category : 'accessing' }
GbxMultiTripServerInteraction >> shouldExportResults
[
	"In multi-trip, there is no referenced set, so we must always put results into the export set
	to prevent their garbage collection."

	^true
]

{ #category : 'private - executing' }
GbxMultiTripServerInteraction >> replicateAlteredObjectsAfterError
[
	"Used after an error interrupted execution. Note that an 'error' includes things like 
	client forwarder sends and breakpoints.

	Normally, answer resultDelegateOrError, which is known to be an error if this message is sent.
	However, if we run into an error replicating the altered objects,
	that error is probably worse than the original error, so answer the new error."
	"What's in the traversal at this point is the immediate-faulting dirty objects, just replicate those
	(and any moreTraversals required)."

	| result |
	result := replication replicateFromTraversal: fetchTraversal.


	"Shouldn't normally error here, but need to check in case of things like 
	session termination, or server out of memory."
	^result gbxIsGSError ifTrue: [result] ifFalse: [resultDelegateOrError]
]

{ #category : 'private - executing' }
GbxMultiTripServerInteraction >> replicateResult
[
	"aDelegate is the server object answered by the message send.
	First, replicate from the traversal of immediate faulters (which is already in the traversal). 
	Then, if specified, do another traversal (in the same GbxFetchTraversal) 
	for the result delegate and replicate from that."

	| error |
	error := replication replicateFromTraversal: fetchTraversal.	"This is the immediate oops only"
	error ~~ nil ifTrue: [^error].
	shouldReplicateResult
		ifTrue: 
			[(resultDelegateOrError isSpecial not
				and: [resultDelegateOrError isIdentityClamped not])
					ifTrue: 
						[serverInterface
							traverseDelegates: (Array with: resultDelegateOrError)
							forInteraction: self
							level: replicationLevel.
						error := replication replicateFromTraversal: fetchTraversal.
						error ~~ nil ifTrue: [^error]]].
	^resultDelegateOrError
]

