Extension { #name : #'PositionableStream' }

{ #category : '*GemStone-GBS-Converted-GBS-private' }
PositionableStream class >> gbsReplicatorClass [

	^GbxPositionableStreamReplicator
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
PositionableStream class >> instVarMap [
	"GBS. Presently only and explicitly supports legacy streams.
	 A future to do would be to support both legacy and portable streams.
	 That's probably going to be very tricky."

	^super instVarMap ,
		#(	(collection itsCollection)	)
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
PositionableStream >> postFault [
	"GBS.  The retrieved GemStone values are already in my slots.  Do the necessary stuff to convert the GemStone representation to mine."

	| arr pos |
	arr := collection.
	pos := position.
	self on: arr.
	"GemStone is ahead by 1 - decrement position)"
	position := pos - 1
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
PositionableStream >> namedValues [
	"GBS."
	"Server does not keep empty space in collection, so before flush trim empty space from our collection"

	collection gbxBecome: self contents.
	^self
]

{ #category : '*GemStone-GBS-Converted-GBS-extensions' }
PositionableStream >> gbxBytesCached [
	"Bytes consumed by a PositionableStream includes its internal collection."

	^super gbxBytesCached + collection gbxBytesCached
]

{ #category : '*GemStone-GBS-Converted-accessing' }
PositionableStream class >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
PositionableStream class >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
PositionableStream class >> isRunningUnderAssertingVM [
	^false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
PositionableStream >> stType [
	^#Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
PositionableStream >> osType [
	^Smalltalk os isWindows ifTrue: [ #win ] ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
PositionableStream >> isRunningUnderAssertingVM [
	^false
]

