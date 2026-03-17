Class {
	#name : #'GbxArrayReplicator',
	#superclass : #'GbxPointerObjectReplicator',
	#instVars : [ #'fillResultWithDelegates' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'initialize-release' }
GbxArrayReplicator >> initializeForClientClass: aClientClass serverClass: classDelegate manager: aManager

	super
		initializeForClientClass: aClientClass
		serverClass: classDelegate
		manager: aManager.
	serverToClientOffsets := #().
	serverInstVarNames := #().
	fillResultWithDelegates := false

{ #category : #'per-object replication' }
GbxArrayReplicator >> forReplication: aReplication replicateFromReport: report
	"Sender must hold session's semaphore, and clientMap semaphore."

	| interaction |
	replication := aReplication.
	interaction := replication interaction.
	currentReport := report.
	reportOop := report objId.
	fillResultWithDelegates := interaction
				shouldReplicateResultBodyAsDelegates
					and: [reportOop sameOopAs: interaction resultDelegateOrError].
	super forReplication: replication replicateFromReport: report

{ #category : #'private' }
GbxArrayReplicator >> referentForOop: oop shouldBeForwarder: shouldBeForwarder
	"In this special-pupose subclass, objects are filled with delegates instead of client objects."
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	^fillResultWithDelegates
		ifTrue: [oop asGSObjectInSession: session]
		ifFalse: [super referentForOop: oop shouldBeForwarder: shouldBeForwarder]

