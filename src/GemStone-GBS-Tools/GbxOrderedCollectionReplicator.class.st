Class {
	#name : 'GbxOrderedCollectionReplicator',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxOrderedCollectionReplicator >> replicate [
	"Replicate an OrderedCollection from GemStone"
	| script result collection |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '[
		| oc stream |
		oc := Object _objectForOop: ', target oop asString, '.
		stream := WriteStream on: String new.
		oc do: [ :elem |
			| oop |
			oop := Reflection oopOf: elem.
			stream
				nextPutAll: elem printString; nextPutAll: ''|'';
				nextPutAll: oop asString; lf.
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	
	collection := OrderedCollection new.
	result ifNotNil: [
		result splitOn: Character lf do: [ :line |
			line isNotEmpty ifTrue: [
				| parts elem |
				parts := line splitOn: $|.
				parts size >= 1 ifTrue: [
					elem := parts first.
					collection add: elem.
				].
			].
		].
	].
	
	^ collection.
]
