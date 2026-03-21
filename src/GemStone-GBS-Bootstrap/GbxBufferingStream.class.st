Class {
	#name : 'GbxBufferingStream',
	#superclass : 'GbxDumpingStream',
	#instVars : [
		'intermediateStream'
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
GbxBufferingStream >> close
[
	self flush.
	^ (stream respondsTo: #close)
		ifTrue: [ stream close ]
		ifFalse: [ self ]
]

{ #category : 'accessing' }
GbxBufferingStream >> flush
[
	| buffered |
	buffered := intermediateStream contents.
	buffered isEmpty ifFalse: [
		[ stream nextPutAll: buffered ]
			on: Error
			do: [
				buffered do: [ :each |
					[ stream nextPut: each ]
						on: Error
						do: [ stream nextPutAll: '<<illegal character>>' ] ] ] ].
	self initializeIntermediateStream.
	^ (stream respondsTo: #flush)
		ifTrue: [ stream flush ]
		ifFalse: [ self ]
]

{ #category : 'accessing' }
GbxBufferingStream >> nextPut: aCharacter
[
	intermediateStream nextPut: aCharacter.
	intermediateStream position >= self maxIntermediateSize
		ifTrue: [ self flush ].
	^ aCharacter
]

{ #category : 'accessing' }
GbxBufferingStream >> size
[
	| streamSize |
	streamSize := (stream respondsTo: #size)
		ifTrue: [ stream size ]
		ifFalse: [ 0 ].
	^ streamSize + intermediateStream position
]

{ #category : 'initialize-release' }
GbxBufferingStream >> initializeIntermediateStream
[
	intermediateStream := (String new: self maxIntermediateSize) writeStream
]

{ #category : 'private' }
GbxBufferingStream >> maxIntermediateSize
[
	^ 2 raisedTo: 20
]

{ #category : 'private' }
GbxBufferingStream >> on: aStream
[
	super on: aStream.
	self initializeIntermediateStream.
	^ self
]
