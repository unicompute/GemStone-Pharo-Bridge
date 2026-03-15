Class {
	#name : 'GbxDictionaryReplicator',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxDictionaryReplicator >> replicate [
	"Replicate a Dictionary from GemStone"
	| script result dict |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	script := '[
		| dict stream |
		dict := Object _objectForOop: ', target oop asString, '.
		stream := WriteStream on: String new.
		dict keysAndValuesDo: [ :k :v |
			stream
				nextPutAll: k printString; nextPutAll: ''|'';
				nextPutAll: v printString; lf.
		].
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	
	dict := Dictionary new.
	result ifNotNil: [
		result splitOn: Character lf do: [ :line |
			line isNotEmpty ifTrue: [
				| parts key value |
				parts := line splitOn: $|.
				parts size >= 2 ifTrue: [
					key := parts first.
					value := parts second.
					dict at: key put: value.
				].
			].
		].
	].
	
	^ dict.
]
