Class {
	#name : 'GbxObjectWithDeferredAssignments',
	#superclass : 'Object',
	#instVars : [
		'clientObject',
		'deferredAssignments',
		'indexedBuffer',
		'namedBuffer',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'deferring' }
GbxObjectWithDeferredAssignments >> add: aDeferredAssignment 
[
	deferredAssignments add: aDeferredAssignment
]

{ #category : 'deferring' }
GbxObjectWithDeferredAssignments >> deferIndexedOffset: clientOffset oop: oop
[
	"Oop points to traversal buffer memory, must copy into a delegate, even though this delegate
	will not be put into the cache in most cases."
	
	deferredAssignments
		add:
			(self deferredIndexedAssignmentClass
				offset: clientOffset
				delegate: (oop asGSObjectInSession: session)
				buffer: indexedBuffer).
]

{ #category : 'deferring' }
GbxObjectWithDeferredAssignments >> deferNamedOffset: clientOffset oop: oop
[
	"Oop points to traversal buffer memory, must copy into a delegate."

	deferredAssignments add: (self deferredNamedAssignmentClass
				offset: clientOffset
				delegate: (oop asGSObjectInSession: session)
				buffer: namedBuffer)
]

{ #category : 'accessing' }
GbxObjectWithDeferredAssignments >> indexedBuffer: anObject
[
	indexedBuffer := anObject
]

{ #category : 'accessing' }
GbxObjectWithDeferredAssignments >> namedBuffer: anObject
[
	namedBuffer := anObject
]

{ #category : 'accessing' }
GbxObjectWithDeferredAssignments >> session: anObject
[
	session := anObject
]

{ #category : 'accessing' }
GbxObjectWithDeferredAssignments >> clientObject: anObject
[
	clientObject := anObject
]

{ #category : 'accessing' }
GbxObjectWithDeferredAssignments >> clientObject
[
	^clientObject
]

{ #category : 'initialize-release' }
GbxObjectWithDeferredAssignments >> initialize
[
	deferredAssignments := OrderedCollection new
]

{ #category : 'resolving' }
GbxObjectWithDeferredAssignments >> resolve
[
	"Sender must hold the session's sessionProtect"

	
	[clientObject gbxIgnoreFutureChanges.
	deferredAssignments do: [:assignment | assignment resolveIn: session].
	clientObject namedValues: namedBuffer indexableValues: indexedBuffer.
	clientObject postFaultInSession: session.
	clientObject gbxTrapFutureChanges]
			valueUnpreemptively
]

{ #category : 'private' }
GbxObjectWithDeferredAssignments >> deferredIndexedAssignmentClass
[
	
	^GbxDeferredIndexedAssignment.
]

{ #category : 'private' }
GbxObjectWithDeferredAssignments >> deferredNamedAssignmentClass
[
	
	^GbxDeferredNamedAssignment.
]

{ #category : 'instance creation' }
GbxObjectWithDeferredAssignments class >> new
[
	^super new initialize
]

