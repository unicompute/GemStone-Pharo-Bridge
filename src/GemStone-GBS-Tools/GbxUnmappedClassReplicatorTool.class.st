Class {
	#name : 'GbxUnmappedClassReplicatorTool',
	#superclass : 'GbxClassReplicatorTool',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxUnmappedClassReplicatorTool >> replicate [
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
