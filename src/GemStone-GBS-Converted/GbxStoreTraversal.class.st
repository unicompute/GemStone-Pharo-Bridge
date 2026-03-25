Class {
	#name : 'GbxStoreTraversal',
	#superclass : 'GbxTraversal',
	#instVars : [
		'session',
		'packedNotYetAccepted'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxStoreTraversal class >> for: aServerInteraction [ 

	"Sender must hold my session's sessionProtect."

	^self new initializeForInteraction: aServerInteraction
]

{ #category : 'GBS private' }
GbxStoreTraversal >> emptyPackedNotYetAcceptedInto: aCollection [

	"Sender must hold my session's protect."

	aCollection addAll: packedNotYetAccepted.
	self initializePackedNotYetAccepted
]

{ #category : 'GBS private' }
GbxStoreTraversal >> exportPackedNotYetAccepted [


	packedNotYetAccepted
		do: [:each | (each gbxDelegate forSession: session) nowExported].
	"We must now discard our strong references to these objects.
	They are no longer dirty, so we no longer need to keep watch over them."
	self initializePackedNotYetAccepted
]

{ #category : 'packing' }
GbxStoreTraversal >> finishedReport [

	"Header and valueBuffer all filled in -- advance the report to the next free space."

	buffer finishedReport
]

{ #category : 'packing' }
GbxStoreTraversal >> flushBufferIfFull [

	"If there is not room for another report, send it."

	buffer hasRoomForReport ifFalse: [self flushBufferToServer]
]

{ #category : 'packing' }
GbxStoreTraversal >> flushBufferToServer [

	"The buffer is full while there is still more to pack, send the buffer's contents to the 
	gem and ready the now-empty buffer for more packing."

	session storeTraversalBuffer: buffer.

	"If we get here, the buffer has been accepted, so the objects are now all
	in the server's export set, so we must mark the delegates to match."
	self exportPackedNotYetAccepted.
	buffer emptyBuffer
]

{ #category : 'private - initializing' }
GbxStoreTraversal >> initializeForInteraction: anInteraction [

	"Sender must hold my session's sessionProtect."

	super initializeForInteraction: anInteraction.
	session := serverInterface session.
	self initializePackedNotYetAccepted.
	session addStoreTraversal: self
]

{ #category : 'private - initializing' }
GbxStoreTraversal >> initializePackedNotYetAccepted [


	packedNotYetAccepted := IdentitySet new
]

{ #category : 'object interface' }
GbxStoreTraversal >> objectReport [


	^buffer objectReport
]

{ #category : 'packing' }
GbxStoreTraversal >> pack: anObject [

	"Must hold all packed objects until done with the server interaction, so they don't get reported to the server
	as being GCed or no longer replicated until definitively after they've been flushed. 
	So the sender must make sure that the serverMap is strong at the time this object is packed. The server gets rightly confused
	if you tell it that an object is no longer replicated in the same round trip you create the object by putting it in a 
	traversal buffer, since it processes the noLongerReplicated/GCed objects before processing the store traversal."
	"Sender must hold session's sessionProtect"
	"If the object is alredy mapped, and is not dirty, it does not need to be packed. If it is not mapped, or if it is dirty, find a replicator to do the mapping (if necessary) and the storing in the traversal."

	| replicator delegate |
	delegate := anObject asGSObjectInSession: session.
	delegate isStDirty
		ifTrue: 
			[replicator := session replicatorForClientBehavior: anObject gbxBasicClass
						ifAbsent: 
							[session setAsideDirtyWhile: 
									[anObject gbxUnmappedClassReplicatorClass replicatorToFlush: anObject
										inSession: session]].
			replicator store: anObject inTraversal: self]
]

{ #category : 'packing' }
GbxStoreTraversal >> packed: anObject [


	packedNotYetAccepted add: anObject
]

{ #category : 'initialize-release' }
GbxStoreTraversal >> release [

	"Sender must hold my session's sessionProtect."

	super release.
	session removeStoreTraversal: self
]

{ #category : 'accessing' }
GbxStoreTraversal >> session [

	^session
]
