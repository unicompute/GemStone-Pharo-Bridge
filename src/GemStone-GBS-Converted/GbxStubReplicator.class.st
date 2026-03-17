Class {
	#name : #'GbxStubReplicator',
	#superclass : #'GbxNoServerClassReplicator',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'store replication' }
GbxStubReplicator >> store: aStub inTraversal: storeTraversal
	"Normally, a stub is already mapped and we don't need to flush it.
	However, if the stub is for a different session, and it's a stub for an object which *can* be mapped to multiple sessions,
	we need to fault the stub and then try to flush that in our session."
	"Sender must hold session's sessionProtect"

	| delegate |
	delegate := aStub gbxExistingOrSpecialDelegateInSession: session.
	delegate == nil
		ifTrue: 
			[aStub fault.
			"aStub is no longer a stub."
			storeTraversal pack: aStub]

