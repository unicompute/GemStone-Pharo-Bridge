Class {
	#name : 'GbxDeferredElementsReplicator',
	#superclass : 'GbxPointerObjectReplicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'per-object private' }
GbxDeferredElementsReplicator >> assignIndexedInstvars
	"Because we're assigning into a hashed collection, we will usually send #hash to the elements.
	If any of the elements are stubs (or contain stubs and send #hash to them...) and the stubs are for
	the same class that I am for, the unstubbing will wipe out some of my instance variables. So I must
	save them and restore them."
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	| savedReplication savedReport savedOop savedScheme savedObject savedNamedBuffer savedIndexedBuffer namedSize |
	savedReplication := replication.
	savedReport := currentReport.
	savedOop := reportOop.
	savedScheme := replicationScheme.
	savedObject := clientObject.
	savedNamedBuffer := namedBuffer.
	savedIndexedBuffer := indexedBuffer.
	namedSize := savedReport namedSize.
	savedReport firstIndexableOffset to: savedReport lastIndexableOffset
		do: 
			[:serverOffset |
			| oop referent |
			oop := savedReport oopPtrAt: serverOffset.
			referent := self referentForOop: oop shouldBeForwarder: false.

			"Assign if now cached. If not cached, is an error, since all deferred assignments should have been done by now."
			referent == notCachedToken
				ifTrue: 
					[self gbsMessenger
						error: 'Referent not found during deferred elements assignment.']
				ifFalse: 
					[savedIndexedBuffer indexableValueAt: serverOffset - namedSize put: referent]].
	replication := savedReplication.
	currentReport := savedReport.
	reportOop := savedOop.
	replicationScheme := savedScheme.
	clientObject := savedObject.
	namedBuffer := savedNamedBuffer.
	indexedBuffer := savedIndexedBuffer

{ #category : 'per-object private' }
GbxDeferredElementsReplicator >> clientSizeIsCorrect
	"My client class is variable size, so the client object's size is always correct."

	^true

{ #category : 'per-object replication' }
GbxDeferredElementsReplicator >> forReplication: aReplication replicateFromDeferredReport: report
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	| interaction |
	report isFirstReportForObject ifTrue: [self initializeForNewObject].
	replication := aReplication.
	interaction := replication interaction.
	currentReport := report.
	reportOop := report objId.
	replicationScheme := interaction replicationScheme.
	self replicateFromDeferredReport.
	deferredAssignments == nil
		ifFalse: 
			[self gbsMessenger
				error: 'Deferred assignments remain following deferred elements assignment.'].
	report isLastReportForObject ifTrue: [self initializeForNewObject]

{ #category : 'private per-object replication' }
GbxDeferredElementsReplicator >> replicateFromReport
	"Hashed collections must wait until all of their contents are present to be filled in, 
	so defer that until after the deferred class mapping is done, and deferred assignments are done.
	Here, just create and map the client object, and defer the report."
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	clientObject := session clientAtOop: reportOop.
	reportCount := reportCount + 1.
	reportCount == 1
		ifTrue: 
			[self updateOrCreateClientObject.
			currentReport isHeaderOnly
				ifTrue: 
					[^self	"create or update all needed -- leave existing replicate alone (bug 41115)"]
				ifFalse: [self delegate nowExported].
			self gbxFixMe.	"assigns need to be unpreemptible"
			clientObject gbxIsProxy
				ifTrue: 
					[clientObject gbxTrapFutureChanges.
					^self].
			clientObject gbxIgnoreFutureChanges.
			clientObject preFaultWithReport: currentReport inSession: session].
	replication addDeferredElementsReport: currentReport copyWithPrivateBuffer

{ #category : 'private per-object replication' }
GbxDeferredElementsReplicator >> replicateFromDeferredReport
	"Fill in the object, which may have been previously created.
	We know we have a full report, since we don't defer header-only reports.
	"
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	clientObject := session clientAtOop: reportOop.
	reportCount := reportCount + 1.
	reportCount == 1
		ifTrue: 
			[self updateOrCreateClientObject
			"If this collection's class was not mapped, the client object might not yet exist or might be a stub."].
	namedBuffer := clientObject namedValuesBuffer.
	indexedBuffer := clientObject indexableValuesBuffer.
	clientObject gbxIgnoreFutureChanges.
	self assignInstvars.
	self clientObjectIsComplete
		ifTrue: 
			[clientObject namedValues: namedBuffer indexableValues: indexedBuffer.
			clientObject postFaultInSession: session].
	self gbxFixMe.	"assigns need to be unpreemptible"
	clientObject gbxTrapFutureChanges

