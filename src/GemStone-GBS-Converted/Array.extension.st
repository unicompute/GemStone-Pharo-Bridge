Extension { #name : 'Array' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Array class >> gbsReplicatorClass [
	^ self == Array
		ifTrue: [ GbxArrayReplicator ]
		ifFalse: [ super gbsReplicatorClass ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Array >> gbxDebugPrintOn: aStream [
	| className size |
	className := self gbxBasicClass name.
	size := self gbxBasicSize.
	aStream
		nextPutAll: className;
		nextPutAll: ' of size '.
	size printOn: aStream.
	aStream nextPutAll: ' #('.
	self
		do: [ :element | GbxReflection debugPrint: element on: aStream ]
		separatedBy: [ aStream space ].
	aStream nextPut: $)
]
