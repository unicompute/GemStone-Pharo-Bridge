Class {
	#name : 'GbxUnmappedClassReplicator',
	#superclass : 'GbxClassReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxUnmappedClassReplicator >> replicate [
	"Replicate an unmapped class from GemStone"
	| script className classHolder |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '(Object _objectForOop: ', target oop asString, ') name'.
	className := session executeAndFetch: script.
	
	classHolder := GbxClassHolder new
		name: className, ' (unmapped)';
		proxy: target;
		session: session;
		yourself.
	
	^ classHolder.
]
