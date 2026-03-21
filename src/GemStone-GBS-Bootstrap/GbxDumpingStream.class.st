Class {
	#name : 'GbxDumpingStream',
	#superclass : 'Stream',
	#instVars : [
		'stream'
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'instance creation' }
GbxDumpingStream class >> on: aStream
[
	^ (self basicNew on: aStream) initialize
]

{ #category : 'accessing' }
GbxDumpingStream >> contents
[
	^ stream contents
]

{ #category : 'accessing' }
GbxDumpingStream >> cr
[
	self nextPut: Character cr.
	^ self
]

{ #category : 'accessing' }
GbxDumpingStream >> flush
[
	^ (stream respondsTo: #flush)
		ifTrue: [ stream flush ]
		ifFalse: [ self ]
]

{ #category : 'accessing' }
GbxDumpingStream >> next
[
	self shouldNotImplement
]

{ #category : 'accessing' }
GbxDumpingStream >> nextPutAll: aCollection
[
	aCollection do: [ :each | self nextPut: each ].
	^ aCollection
]

{ #category : 'accessing' }
GbxDumpingStream >> print: anObject
[
	anObject printOn: self.
	^ anObject
]

{ #category : 'accessing' }
GbxDumpingStream >> policy
[
	^ (stream respondsTo: #policy)
		ifTrue: [ stream policy ]
		ifFalse: [ nil ]
]

{ #category : 'accessing' }
GbxDumpingStream >> stream
[
	^ stream
]

{ #category : 'accessing' }
GbxDumpingStream >> space
[
	self nextPut: Character space.
	^ self
]

{ #category : 'testing' }
GbxDumpingStream >> isReadable
[
	^ false
]

{ #category : 'testing' }
GbxDumpingStream >> isWritable
[
	^ true
]

{ #category : 'accessing' }
GbxDumpingStream >> tab
[
	self nextPut: Character tab.
	^ self
]

{ #category : 'initialize-release' }
GbxDumpingStream >> on: aStream
[
	stream := aStream.
	^ self
]
