Class {
	#name : 'GbxFakeTraversalServerInterface',
	#superclass : 'Object',
	#instVars : [
		'buffer',
		'session'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'instance creation' }
GbxFakeTraversalServerInterface class >> session: aSession buffer: aBuffer [
	^ self new
		session: aSession;
		buffer: aBuffer;
		yourself
]

{ #category : 'accessing' }
GbxFakeTraversalServerInterface >> allocateTraversalBufferFor: aTraversal [
	^ buffer
]

{ #category : 'accessing' }
GbxFakeTraversalServerInterface >> buffer: aBuffer [
	buffer := aBuffer
]

{ #category : 'accessing' }
GbxFakeTraversalServerInterface >> session [
	^ session
]

{ #category : 'accessing' }
GbxFakeTraversalServerInterface >> session: aSession [
	session := aSession
]
