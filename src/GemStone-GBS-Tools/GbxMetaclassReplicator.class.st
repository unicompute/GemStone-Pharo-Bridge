Class {
	#name : 'GbxMetaclassReplicator',
	#superclass : 'GbxClassReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxMetaclassReplicator >> replicate [
	"Replicate a metaclass from GemStone"
	| script className classHolder |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '(Object _objectForOop: ', target oop asString, ') thisClass name'.
	className := session executeAndFetch: script.
	
	classHolder := GbxClassHolder new
		name: className, ' class';
		proxy: target;
		session: session;
		yourself.
	
	^ classHolder.
]
