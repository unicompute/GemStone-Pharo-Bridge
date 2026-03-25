Class {
	#name : 'GbxTraversal',
	#superclass : 'Object',
	#instVars : [
		'buffer',
		'interaction',
		'serverInterface'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'private - accessing' }
GbxTraversal >> buffer [


	^buffer
]

{ #category : 'accessing' }
GbxTraversal >> bufferSize [

	^buffer bufferSize
]

{ #category : 'initialize-release' }
GbxTraversal >> emptyBuffer [

	buffer emptyBuffer
]

{ #category : 'private - initializing' }
GbxTraversal >> initializeForInteraction: anInteraction [ 

	"Sender must hold my session's sessionProtect."

	interaction := anInteraction.
	serverInterface := interaction serverInterface.
	buffer := serverInterface allocateTraversalBufferFor: self
]

{ #category : 'initialize-release' }
GbxTraversal >> release [

	buffer unlockFor: self
]
