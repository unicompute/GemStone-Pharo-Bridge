Class {
	#name : 'GbxStubReplicator',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxStubReplicator >> replicate [
	"Replicate a stub from GemStone"
	| stub |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	stub := GbxObjectStub new.
	stub
		oop: target oop;
		session: session;
		yourself.
	
	^ stub.
]
