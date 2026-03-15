Class {
	#name : 'GbxSymbolReplicator',
	#superclass : 'GbxStringReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxSymbolReplicator >> replicate [
	"Replicate a symbol from GemStone"
	| script |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '(Object _objectForOop: ', target oop asString, ') asSymbol'.
	^ session executeAndFetch: script.
]
