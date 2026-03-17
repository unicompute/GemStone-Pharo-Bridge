Class {
	#name : 'GbxTraversal',
	#superclass : 'Object',
	#instVars : [
		'buffer',
		'interaction',
		'serverInterface'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private - initializing' }
GbxTraversal >> initializeForInteraction: anInteraction 
	"Sender must hold my session's sessionProtect."

	interaction := anInteraction.
	serverInterface := interaction serverInterface.
	buffer := serverInterface allocateTraversalBufferFor: self

{ #category : 'accessing' }
GbxTraversal >> bufferSize
	^buffer bufferSize

{ #category : 'private - accessing' }
GbxTraversal >> buffer

	^buffer

{ #category : 'initialize-release' }
GbxTraversal >> release
	buffer unlockFor: self

{ #category : 'initialize-release' }
GbxTraversal >> emptyBuffer
	buffer emptyBuffer

