Class {
	#name : 'GbxFetchTraversal',
	#superclass : 'GbxTraversal',
	#instVars : [
		'traversalCompleted'
	],
	#classVars : [
		'FetchTraversalClass'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxFetchTraversal class >> fetchTraversalClass: aClass [


	FetchTraversalClass := aClass
]

{ #category : 'instance creation' }
GbxFetchTraversal class >> for: aServerInteraction [ 

	"Sender must hold my session's sessionProtect."

	^(FetchTraversalClass ifNil: [ self ]) new
		initializeForInteraction: aServerInteraction;
		yourself
]

{ #category : 'private - initializing' }
GbxFetchTraversal >> initializeForInteraction: anInteraction [

	"Sender must hold my session's sessionProtect."
	
	super initializeForInteraction: anInteraction.
	traversalCompleted := true
]

{ #category : 'enumerating' }
GbxFetchTraversal >> reportsAllButLastDo: reportsBlock [

	"Evaluate the block once per report, getting more buffers from the server as necessary.
	Do not evaluate the last report, just return it.
	If an error is returned from the server, return that error. Otherwise, answer the last report."
	"First, fully process all but the last buffer"

	[traversalCompleted] whileFalse: 
			[buffer reportsDo: reportsBlock.
			traversalCompleted := serverInterface moreTraversalInTraversal: self.
			traversalCompleted gbxIsGSError ifTrue: [^traversalCompleted]].
	"Now process the last (or only) buffer"
	^buffer reportsAllButLastDo: reportsBlock
]

{ #category : 'private - accessing' }
GbxFetchTraversal >> serverInterface [

	"The interface to the server for this session"

	^serverInterface
]

{ #category : 'private - accessing' }
GbxFetchTraversal >> traversalCompleted [


	"The receiver is presumably a traversal report obtained from GemStoneObject|traverse, GemStoneObject|moreTraversal, or  GemStoneObject|traverseToLevel:threshold:maxBytes:. This method returns a boolean stating whether the traversal of the object has been completed.  If false is returned, GemStoneObject|moreTraversal may be invoked to obtain another buffer full of the traversal"

	^traversalCompleted
]

{ #category : 'accessing' }
GbxFetchTraversal >> traversalCompleted: anObject [

	^traversalCompleted := anObject
]
