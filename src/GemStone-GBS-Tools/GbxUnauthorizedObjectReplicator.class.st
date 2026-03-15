Class {
	#name : 'GbxUnauthorizedObjectReplicator',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxUnauthorizedObjectReplicator >> replicate [
	"Replicate an unauthorized object (stub)"
	| stub |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	stub := GbxUnauthorizedObjectStub new.
	stub
		oop: target oop;
		session: session;
		yourself.
	
	^ stub.
]
