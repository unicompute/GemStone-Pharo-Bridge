Class {
	#name : 'GbxArrayReplicator',
	#superclass : 'GbxReplicator',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'replication' }
GbxArrayReplicator >> replicate [
	"Replicate an array from GemStone"
	| arrayClass size elements |
	
	target ifNil: [ ^ nil ].
	session ifNil: [ ^ nil ].
	
	"Get array class and size"
	arrayClass := self fetchClass.
	size := self fetchSize.
	
	"Fetch elements"
	elements := self fetchElements: size.
	
	"Create local array"
	^ self createArrayWith: elements class: arrayClass.
]

{ #category : 'fetching' }
GbxArrayReplicator >> fetchClass [
	"Fetch array class from server"
	| script |
	
	script := '(Object _objectForOop: ', target oop asString, ') class name'.
	^ session executeAndFetch: script.
]

{ #category : 'fetching' }
GbxArrayReplicator >> fetchElements: size [
	"Fetch array elements from server"
	| script |
	
	script := '[
		| arr stream |
		arr := Object _objectForOop: ', target oop asString, '.
		stream := WriteStream on: String new.
		1 to: ', size asString, ' do: [ :i |
			| elem oop |
			elem := arr at: i.
			oop := Reflection oopOf: elem.
			stream
				nextPutAll: elem printString; nextPutAll: ''|'';
				nextPutAll: oop asString; lf.
		].
		stream contents
	] value'.
	
	^ session executeAndFetch: script.
]

{ #category : 'fetching' }
GbxArrayReplicator >> fetchSize [
	"Fetch array size from server"
	| script |
	
	script := '(Object _objectForOop: ', target oop asString, ') size'.
	^ session executeAndFetch: script.
]

{ #category : 'creation' }
GbxArrayReplicator >> createArrayWith: elements class: className [
	"Create local array from elements"
	| array |
	
	array := Array new: elements size.
	elements keysAndValuesDo: [ :i :elemData |
		| parts elem |
		parts := elemData splitOn: $|.
		elem := parts first.
		array at: i put: elem.
	].
	
	^ array.
]
