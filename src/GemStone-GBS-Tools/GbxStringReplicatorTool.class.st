Class {
	#name : 'GbxStringReplicatorTool',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxStringReplicatorTool >> replicate [
	"Replicate a string from GemStone"
	| script |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '(Object _objectForOop: ', target oop asString, ') asString'.
	^ session executeAndFetch: script.
]
