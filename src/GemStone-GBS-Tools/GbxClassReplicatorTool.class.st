Class {
	#name : 'GbxClassReplicatorTool',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxClassReplicatorTool >> replicate [
	"Replicate a class from GemStone"
	| script className classHolder |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '(Object _objectForOop: ', target oop asString, ') name'.
	className := session executeAndFetch: script.
	
	classHolder := GbxClassHolder new
		name: className;
		proxy: target;
		session: session;
		yourself.
	
	^ classHolder.
]
