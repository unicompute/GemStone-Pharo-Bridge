Class {
	#name : 'GbxMetaclassReplicator',
	#superclass : 'GbxUnmappedClassReplicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private' }
GbxMetaclassReplicator >> replicateMetaclassAsForwarder
	"And answer the forwarder."
	"Sender must hold session's protect and cache semaphore."

	| forwarder |
	forwarder := GbsForwarder new.
	session unprotectedConnectNewClient: forwarder toServer: metaclassDelegate.
	^forwarder

{ #category : 'private' }
GbxMetaclassReplicator >> getClassAndMetaclassInformation

	self getClassAndMetaclassInformationForBehavior: report objId

{ #category : 'per-object replication' }
GbxMetaclassReplicator >> forReplication: replication replicateFromDeferredReport: aReport
	"This report is a full report for an as yet unmapped metaclass. We're now at a point where we can map it
	and the class that is its instance. This will have the side effect of identity clamping both the class
	and metaclass, so no future reports will be received for the class or metaclass."
	"Sender must hold session semaphore and cache semaphore."
	"A full report for a metaclass has only one oop in its value buffer, so the server
	will not split this into multiple reports. "
	"What must be done is:
	
	0) If we had a stub for this metaclass or class, unmap it / them.
	1) Find the same-named class on the client. If none, see if we can generate one. If not, error. 
	2) Is the same-named client class already mapped? If so, create a forwarder replicator for this 
		server metaclass and let it deal with it.
	3) If the existing or generated same-named class is not already mapped, map the class and metaclass.
	4) One-way-become any stubs we had, so references will now point to the new object.
	"

	[aReport objClass sameOopAs: serverClass] gbxAssert.
	report := aReport.
	self getClassAndMetaclassInformation.
	metaclassDelegate nowExported.	"Class delegate is not necessarily in the export set, but we just got a full report for the metaclass."
	self findExistingProxies.
	classProxy zzzisForwarder
		ifTrue: [self replicateMetaclassAsForwarder]
		ifFalse: 
			["Get a report for the class, and let the UnmappedClassReplicator handle mapping class and metaclass"
			| theClientClass |
			theClientClass := classDelegate performOnGsServer: #yourself.
			"In, for instance, a skew case, the mapping cannot be made to a client class, so we fall back to a forwarder."
			theClientClass zzzisForwarder ifTrue: [self replicateMetaclassAsForwarder]]

{ #category : 'instance creation' }
GbxMetaclassReplicator class >> forClientClass: clientBehavior serverClass: behaviorDelegate manager: manager

	clientBehavior == Metaclass
		ifFalse: 
			[self gbsMessenger
				error: 'Attempting to create a metaclass replicator for a class other than Metaclass.'].
	^self new initializeForSession: manager session
		serverBehavior: behaviorDelegate

