Class {
	#name : #'GbxClassReplicator',
	#superclass : #'GbxReplicator',
	#instVars : [ #'serverMetaclass' #'clientMetaclass' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'accessing' }
GbxClassReplicator >> clientClass

	^clientMetaclass

{ #category : #'accessing' }
GbxClassReplicator >> serverMetaclass

	^serverMetaclass

{ #category : #'per-object replication' }
GbxClassReplicator >> forReplication: replication replicateFromDeferredReport: report
	"The fact that I have been asked to replicate this report indicates that the class has already been mapped. So there's nothing left for me to do."

{ #category : #'per-object replication' }
GbxClassReplicator >> forReplication: replication replicateFromReport: report
	"The fact that I have been asked to replicate this report indicates that the class has already been mapped. So there's nothing left for me to do."
	"We should never get a non-deferred report for a class in single-trip, since an already-mapped class will be identity clamped.
	However, 32-bit servers want to send these reports when the result of execution, so it's a problem if we get here."

	[false] gbxAssert

{ #category : #'testing' }
GbxClassReplicator >> isSkew

	^false

{ #category : #'printing' }
GbxClassReplicator >> printOn: aStream

	| name |
	super printOn: aStream.
	name := [clientMetaclass name] on: Error do: [:ex | ex return: ex printString].
	aStream
		nextPutAll: ' for ';
		nextPutAll: name

{ #category : #'initialize-release' }
GbxClassReplicator >> initializeForClientClass: aClientClass serverClass: classDelegate manager: aManager

	clientMetaclass := aClientClass.
	serverMetaclass := classDelegate.
	manager := aManager.
	session := aManager session

{ #category : #'instance creation' }
GbxClassReplicator class >> forClientClass: clientClass serverClass: classDelegate manager: manager

	^self new
		initializeForClientClass: clientClass
		serverClass: classDelegate
		manager: manager

