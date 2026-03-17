Class {
	#name : 'GbxReplicator',
	#superclass : 'Object',
	#instVars : [
		'manager',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private store replication' }
GbxReplicator >> store: anObject withDelegate: delegate inTraversal: storeTraversal
	"Recursively store object reports into the traversal buffer describing anObject
	and its referents. Only objects marked dirty are stored, and they will
	become 'not dirty'."
	"Sender must hold session's sessionProtect"

	delegate clearDirtyBit.	"Must clear now to prevent recursive references from going infinite."
	session startingToPack: anObject.
	self packDirtyReferentsOf: anObject inTraversal: storeTraversal.
	self pack: anObject withDelegate: delegate inTraversal: storeTraversal.
	self setImmutabilityOf: anObject.
	anObject gbxTrapFutureChanges

{ #category : 'private store replication' }
GbxReplicator >> pack: anObject withDelegate: delegate inTraversal: storeTraversal

	self error: 'Most subclasses will need to implement this. i.e. any replicator which actually stores the object to the server.'

{ #category : 'private store replication' }
GbxReplicator >> packDirtyReferentsOf: anObject inTraversal: storeTraversal

	self error: 'Most subclasses will need to implement this. i.e. any replicator which actually stores the object to the server.'

{ #category : 'accessing' }
GbxReplicator >> clientClass
	"Some replicators don't have the concept of a client class, so answer a sentinel non-class answer."

	^#NoClientClass

{ #category : 'testing' }
GbxReplicator >> isComplete
	"Replicators should answer false if they need to fetch information from the server to be 
	complete, such as server instvar names."

	^true

{ #category : 'testing' }
GbxReplicator >> shouldBeClassClamped
	"Replicator instances that are for classes that should be class clamped should answer true to this.
	This will be mostly the replicators for classes that answer true to #instancesAreForwarders.
	Replicators that answer true to this must also respond sensibly to #clientClass."

	^false

{ #category : 'private' }
GbxReplicator >> setImmutabilityOf: aClientObject
	"Some subclasses replicate immutable objects. In general, we leave replicates mutable."

{ #category : 'objectReplication interface' }
GbxReplicator >> indexedInstVarsShouldBeForwardersAccordingTo: specSet
	"Replicator classes that might actually have indexed instvars that are pointers will override this."

	^false

{ #category : 'clamping' }
GbxReplicator >> updateInstVarLevelsOfScheme: scheme
	"Any replicator that maps a client (non-meta) class to a server class should re-implement this method.
	 Replicators that map a metaclass or do not map both client and server classes should do nothing."

{ #category : 'private-initialization' }
GbxReplicator >> initializeServerOffsets
	"Only pointer object replicators need to do anything with this, since it deals with named instance variables."

{ #category : 'stubs' }
GbxReplicator >> nilMappedSlotsOf: anObject
	"AnObject is being made a stub, when it was a replicate of my class. Since it was a replicate, my offsets should be current.
	Nil out each of its named instance variables that are mapped, and all of its indexed instvars.
	We must make anObject mutable during this operation. To protect against another thread trying 
	to modify the object, all of the time that the object is mutable this thread must be unpreemptable."
	"No work to do except for pointer objects."

{ #category : 'stubs' }
GbxReplicator >> stubObject: dirtyObj forDelegate: delegate freeSlots: shouldFreeSlots

	self stubClass
		stubObject: dirtyObj
		forDelegate: delegate
		freeSlots: shouldFreeSlots

{ #category : 'stubs' }
GbxReplicator >> stubClass
	"The default stub class, which may be overridden in specific replicator classes."

	^GbxObjectStub

{ #category : 'store replication' }
GbxReplicator >> store: anObject inTraversal: storeTraversal
	"Recursively store object reports into the traversal buffer describing anObject
	and its referents. Only objects marked dirty are stored, and they will
	become 'not dirty'.
	This message may be overridden in subclasses for GBS Extensions."
	"Sender must hold session's sessionProtect"

	| aDelegate |
	aDelegate := anObject asGSObjectInSession: session.	"This maps the object, usually to a free oop, if not already mapped."
	aDelegate isIdentityClamped
		ifFalse: 
			[self store: anObject withDelegate: aDelegate inTraversal: storeTraversal]

