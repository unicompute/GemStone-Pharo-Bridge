Class {
	#name : #'GbxForwarderReplicator',
	#superclass : #'GbxReplicator',
	#instVars : [ #'serverClass' #'clientClass' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'initialize-release' }
GbxForwarderReplicator >> initializeForServerClass: serverClassDelegate manager: aManager

	serverClass := serverClassDelegate.
	manager := aManager.
	session := aManager session

{ #category : #'initialize-release' }
GbxForwarderReplicator >> initializeForClientClass: aClientClass serverClass: classDelegate manager: aManager

	clientClass := aClientClass.
	serverClass := classDelegate.
	manager := aManager.
	session := aManager session

{ #category : #'accessing' }
GbxForwarderReplicator >> clientClass

	^clientClass

{ #category : #'accessing' }
GbxForwarderReplicator >> serverClass

	^serverClass

{ #category : #'per-object replication' }
GbxForwarderReplicator >> forReplication: replication replicateFromDeferredReport: report
	"I always create and map a forwarder for any report, whether header-only or not."
	"Sender must hold session's semaphore, and clientMap semaphore."

	self forReplication: replication replicateFromReport: report

{ #category : #'per-object replication' }
GbxForwarderReplicator >> forReplication: replication replicateFromReport: report
	"I always create and map a forwarder for any report, whether header-only or not.
	If there's a previously-mapped stub, I must replace it with the new forwarder."
	"Sender must hold session's semaphore, and clientMap semaphore."

	| clientObject reportOop |
	reportOop := report objId.
	clientObject := session clientAtOop: reportOop.
	clientObject == NotCachedToken
		ifTrue: [clientObject := self createClientObjectForOop: reportOop]
		ifFalse: 
			[clientObject zzzisStub
				ifTrue: [clientObject gbxBecomeForwarder]
				ifFalse: [[clientObject zzzisForwarder] gbxAssert]].
	report isHeaderOnly
		ifFalse: 
			["We got a full report because the class is not yet clamped.
				Therefore the object is in the pure export set. We need to
				record this, then get it out of that set because we're making
				a forwarder."
			| delegate |
			delegate := clientObject gbxDelegate forSession: session.
			delegate nowExported.
			session addToNoLongerReplicated: delegate]

{ #category : #'testing' }
GbxForwarderReplicator >> shouldBeClassClamped
	"Replicator instances that are for classes that should be class clamped should answer true to this.
	This will be mostly the replicators for classes that answer true to #instancesAreForwarders."

	^true

{ #category : #'private' }
GbxForwarderReplicator >> createClientObjectForOop: reportOop
	"Create and map a forwarder."
	"Sender must hold aSession's sessionProtect and the clientMap semaphore."

	| clientObject |
	clientObject := GbsForwarder new.
	session unprotectedConnectNewClient: clientObject toServer: reportOop. "Which identity clamps the forwarder"
	^clientObject

{ #category : #'instance creation' }
GbxForwarderReplicator class >> forClientClass: clientClass serverClass: classDelegate manager: manager

	^self new
		initializeForClientClass: clientClass
		serverClass: classDelegate
		manager: manager

