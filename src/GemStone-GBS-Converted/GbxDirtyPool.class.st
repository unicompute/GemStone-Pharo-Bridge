Class {
	#name : #'GbxDirtyPool',
	#superclass : #'Object',
	#instVars : [ #'session' #'dirtyStack' #'dirtyAwaitingPacking' #'activeStoreTraversals' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'public' }
GbxDirtyPool >> removeStoreTraversal: aStoreTraversal

	activeStoreTraversals remove: aStoreTraversal

{ #category : #'public' }
GbxDirtyPool >> packed: anObject
	"To be used once the *last* portion of the object has been placed in a traversal buffer.
	Part of the object being sent to the gem in a previous traversal buffer doesn't count."
	"Sender must hold my session's sessionProtect."

	dirtyAwaitingPacking remove: anObject

{ #category : #'public' }
GbxDirtyPool >> addObject: anObject

	dirtyStack addObject: anObject

{ #category : #'public' }
GbxDirtyPool >> packTopIn: aStoreTraversal
	"Sender must hold my session's sessionProtect."

	dirtyStack top destructiveDo: [:obj | aStoreTraversal pack: obj]

{ #category : #'public' }
GbxDirtyPool >> size

	^dirtyStack size

{ #category : #'public' }
GbxDirtyPool >> emptyInto: resultCollection
	"Take all of the dirty objects that I'm holding, in all their various forms, and add them to resultCollection.
	At the end of this process I should be completely empty.
	Note that objects are added regardless of whether their delegates' dirty flag is set (it often won't be) since
	the dirty flags are reset before the server accepts the traversal. Any dirty flags that are still set are reset
	during this enumeration, making all objects processed 'not dirty' in both delegate flag and presence in this
	dirty pool."

	dirtyStack emptyInto: resultCollection.
	self
		emptyDirtyAwaitingPackingInto: resultCollection;
		emptyActiveStoreTraversalsInto: resultCollection

{ #category : #'public' }
GbxDirtyPool >> startingToPack: anObject
	"AnObject has been identified as a dirty object to pack in a traversal buffer
	to be sent to the gem. Its dirty referents will be packed first, however."
	"Sender must hold my session's sessionProtect."

	dirtyAwaitingPacking add: anObject

{ #category : #'public' }
GbxDirtyPool >> addStoreTraversal: aStoreTraversal

	activeStoreTraversals add: aStoreTraversal

{ #category : #'public' }
GbxDirtyPool >> isEmpty

	^dirtyStack isEmpty

{ #category : #'public' }
GbxDirtyPool >> setAsideDirtyWhile: aBlock
	"Private to GBS.
	Execute aBlock with an empty top dirty pool, then restore the former top dirty pool."
	"Sender must hold my sessionProtect."

	| dirtySave |
	dirtySave := dirtyStack top.
	^
	[| result |
	dirtyStack push.
	result := aBlock value.
	dirtyStack top isEmpty ifFalse: [session flushDirtyToGS].
	result]
			ensure: [dirtyStack popTo: dirtySave]

{ #category : #'initialize-release' }
GbxDirtyPool >> initialize

	dirtyStack := GbxDirtySetStack newForSession: session.
	self initializeDirtyAwaitingPacking.
	activeStoreTraversals := IdentitySet new

{ #category : #'initialize-release' }
GbxDirtyPool >> session: aGbsSession

	session := aGbsSession

{ #category : #'initialize-release' }
GbxDirtyPool >> initializeDirtyAwaitingPacking

	dirtyAwaitingPacking := IdentitySet new

{ #category : #'private' }
GbxDirtyPool >> emptyActiveStoreTraversalsInto: resultCollection

	activeStoreTraversals
		do: [:traversal | traversal emptyPackedNotYetAcceptedInto: resultCollection]

{ #category : #'private' }
GbxDirtyPool >> emptyDirtyAwaitingPackingInto: resultCollection

	dirtyAwaitingPacking do: 
			[:each |
			resultCollection add: each.
			(each asGSObjectInSession: session) clearDirtyBit].
	self initializeDirtyAwaitingPacking

{ #category : #'instance creation' }
GbxDirtyPool class >> newForSession: aGbsSession

	^(self new)
		session: aGbsSession;
		initialize;
		yourself

