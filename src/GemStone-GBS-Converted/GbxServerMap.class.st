Class {
	#name : 'GbxServerMap',
	#superclass : 'GbxOopKeyedDictionary',
	#instVars : [
		'isWeak'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'replication support' }
GbxServerMap >> beStrongAndFinalizeIntoNoLongerReplicatedBuffer: noLongerReplicatedBuffer gcedBuffer: gcedBuffer
[
	"1. Change all of my references to delegates and to client objects to strong references. 
	2. Scan all node table segments that need finalization, and add appropriate oops into the given buffers.
	Either or both of the delegate and the client object may have been collected. 
	For each element that has had either delegate or client object collected, first change the reference(s)
	from 0 to nil. Then apply the rules.
	The rules:
		* If both delegate and client object are now nil, add oop to gcedBuffer and reclaim the element
		* If clientObject is nil, but delegate is not, add oop to stubbedBuffer
		* If delegate is nil but client object is not, do nothing (possibly assert that this shouldn't happen,
			since the delegate should really not become unreferenced before its client object does)."
	"The sender must hold my session's sessionProtect"

	self check.
	isWeak := false.
	self nodesDo: 
			[:node |
			node
				beStrongAndFinalizeIntoNoLongerReplicatedBuffer: noLongerReplicatedBuffer
				gcedBuffer: gcedBuffer]
]

{ #category : 'replication support' }
GbxServerMap >> beWeak
[
	"Change all of my references to delegates and to client objects to weak references."
	"The sender must hold my session's sessionProtect"

	self gbsMessenger
		statusTag: #beWeak
		message: 'serverMap of session: %1 is now weak.'
		with: session.
	self check.
	self nodesDo: [:node | node beWeak].
	isWeak := true
]

{ #category : 'accessing' }
GbxServerMap >> isWeak: aBoolean
[
	"Used only when growing.
	Should not be used when the map can have any nodes, since it does not propagate the weakness to the nodes."

	
	[self
		nodesDo: [:node | self gbsMessenger error: 'Setting weakness of map which has nodes'].
	true]
			gbxAssert.
	isWeak := aBoolean
]

{ #category : 'accessing' }
GbxServerMap >> delegateForOop: oop
[
	" Answer the canonical delegate for he oop. If the given oop is a delegate, and there is no 
	canonical delegate for the oop, it becomes the canonical delegate for the oop."
	"Sender must hold my session's sessionProtect"

	| index node |
	self check.
	self gbsMessenger
		statusTag: #delegateForOop:
		message: '%1 delegateForOop: %2'
		with: self
		with: oop.
	index := oop oopNumberHighBytes + 1.
	index > numNodeSlots ifTrue: [self growToAtLeast: index].
	node := self basicAt: index.
	node == nil ifTrue: [node := self createNodeAt: index].
	^node delegateForOop: oop
]

{ #category : 'testing' }
GbxServerMap >> isWeak
[

	^isWeak
]

{ #category : 'enumeration' }
GbxServerMap >> delegatesAndClientObjsDo: aBlock
[
	"For each entry I hold, evaluate the given two-argument block with arguments of the delegate and the client object.
	The delegate will not be nil, but the client object may be nil."
	"Sender must hold my session's accessProtect."

	self check.
	self nodesDo: [:node | node delegatesAndClientObjsDo: aBlock]
]

{ #category : 'private' }
GbxServerMap >> nodeClass
[

	^GbxServerMapNode
]

{ #category : 'private' }
GbxServerMap >> copyEmptyWithCapacity: newSize
[
	"Used when growing"

	| newSelf |
	newSelf := super copyEmptyWithCapacity: newSize.
	newSelf isWeak: isWeak.
	^newSelf
]

{ #category : 'removing' }
GbxServerMap >> pretendClientIsCollected: aDelegate
[
	"Nil out the client slot corresponding to aDelegate, and add the object to the noLongerReplicated oops,
	which together simulate the client object being GCed."
	"Sender must hold my session's sessionProtect"

	| node |
	self check.
	node := self basicAt: aDelegate oopNumberHighBytes + 1.
	"Entry cannot legitimately be nil while the delegate is referenced from this context."
	node pretendClientIsCollected: aDelegate.
	session addToNoLongerReplicated: aDelegate
]

{ #category : 'initialize-release' }
GbxServerMap >> initialize
[

	super initialize.
	isWeak := true
]

