Class {
	#name : 'GbxTraversalBufferManager',
	#superclass : 'Object',
	#instVars : [
		'traversalBuffers',
		'traversalBufferClass',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxTraversalBufferManager >> initialize

	traversalBuffers := OrderedCollection new.
	traversalBufferClass := session traversalBufferClass

{ #category : 'accessing' }
GbxTraversalBufferManager >> session: aGbsSession

	session := aGbsSession

{ #category : 'accessing' }
GbxTraversalBufferManager >> traversalBufferClass: anObject
	traversalBufferClass := anObject

{ #category : 'private' }
GbxTraversalBufferManager >> traversalBufferOfSize: aSize
	"Return an unlocked traversal buffer of at least size <aSize>.  If none are currently
	available, create a new one and add it to the list of available buffers.

	Sender must hold my session's sessionProtect."

	| aBuffer |
	traversalBuffers
		do: [:each | each isLocked ifFalse: [^each ensureSizeIsAtLeast: aSize]].
	aBuffer := traversalBufferClass size: aSize session: session.
	traversalBuffers add: aBuffer.
	"Assert a reasonable number of buffers. Since each concurrent serverInteraction gets its own pair of buffers,
	thread contention can lead to multiple buffers being allocated, but the number shouldn't go *too* high.
	Since interactions can now fully nest, the maximum number of buffers is not fixed, but allocating *too* many would
	run us out of fixed space quickly, so keep this assertion to catch infinite nesting of server interactions."

	"Example: The case for 6 buffers goes like this. 
	* Create a new client class and explicitly store him in the server via a remote #at:put: (2 buffers).
	* We don't have gsInstVars for the new class as we're trying to create
	 the replication clamp so update and get the gsInstVarNames (2 buffers). 
	* Because we use the new unsynchronizedEvaluateBlock:* call, we pass the client class as an
	argument, then make a further server trip to create the class on the server (2 buffers)"
	traversalBuffers size > 20
		ifTrue: 
			[self gbsMessenger
				failure: 'There are now %1 traversal buffers allocated in this session. This seems like too many.'
				with: traversalBuffers size].
	^aBuffer

{ #category : 'buffers' }
GbxTraversalBufferManager >> allocateBufferFor: anOwner size: size 
	"Return a locked traversal buffer that internally knows who is using it.

	Sender must hold my session's sessionProtect."

	| buffer |
	buffer := self traversalBufferOfSize: size.
	buffer lockFor: anOwner.
	^buffer

{ #category : 'instance creation' }
GbxTraversalBufferManager class >> forSession: session

	^(self new)
		session: session;
		initialize;
		yourself

