Class {
	#name : 'GbxNoServerClassReplicator',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxNoServerClassReplicator >> replicate [
	"Replicate an object with no server class mapping"
	| script className |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '(Object _objectForOop: ', target oop asString, ') class name'.
	className := session executeAndFetch: script.
	
	^ 'NoServerClass(', className, ')' asSymbol.
]
