Class {
	#name : 'GbxForwarderReplicator',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxForwarderReplicator >> replicate [
	"Replicate a forwarder (stub) from GemStone"
	| forwarder |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	forwarder := GbsForwarder new.
	forwarder
		oop: target oop;
		session: session;
		yourself.
	
	^ forwarder.
]
