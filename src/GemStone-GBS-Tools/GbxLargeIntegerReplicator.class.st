Class {
	#name : 'GbxLargeIntegerReplicator',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxLargeIntegerReplicator >> replicate [
	"Replicate a LargeInteger from GemStone"
	| script |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '(Object _objectForOop: ', target oop asString, ') asString'.
	^ session executeAndFetch: script.
]
