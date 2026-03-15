Class {
	#name : 'GbxIdentitySetReplicator',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxIdentitySetReplicator >> replicate [
	"Replicate an IdentitySet from GemStone"
	| script result set |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '[
		| is stream |
		is := Object _objectForOop: ', target oop asString, '.
		stream := WriteStream on: String new.
		is do: [ :elem |
			| oop |
			oop := Reflection oopOf: elem.
			stream
				nextPutAll: elem printString; nextPutAll: ''|'';
				nextPutAll: oop asString; lf.
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	
	set := IdentitySet new.
	result ifNotNil: [
		result splitOn: Character lf do: [ :line |
			line isNotEmpty ifTrue: [
				| parts elem |
				parts := line splitOn: $|.
				parts size >= 1 ifTrue: [
					elem := parts first.
					set add: elem.
				].
			].
		].
	].
	
	^ set.
]
