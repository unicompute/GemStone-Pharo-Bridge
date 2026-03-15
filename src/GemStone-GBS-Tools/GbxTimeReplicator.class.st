Class {
	#name : 'GbxTimeReplicator',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxTimeReplicator >> replicate [
	"Replicate a Time from GemStone"
	| script |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '(Object _objectForOop: ', target oop asString, ') asString'.
	^ session executeAndFetch: script.
]
