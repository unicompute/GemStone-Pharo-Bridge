Class {
	#name : 'GbxLargeIntegerReplicatorTool',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxLargeIntegerReplicatorTool >> replicate [
	"Replicate a LargeInteger from GemStone"
	| script |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '(Object _objectForOop: ', target oop asString, ') asString'.
	^ session executeAndFetch: script.
]
