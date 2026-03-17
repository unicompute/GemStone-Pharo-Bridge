Class {
	#name : 'GbxIdentitySetReplicator',
	#superclass : 'GbxUnorderedCollectionReplicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'per-object private' }
GbxIdentitySetReplicator >> clientClassIsCorrect
[
	"Answer true if the class of the server class of the existing mapped client object 
	is not sufficiently the same as the class of the server object being replicated.
	Since a GbxIdentityClampSet on the client is an IdentitySet on the server, 
	and we don't want to change the class of a client GbxIdentityClampSet,
	we consider that condition to be not a change.

	A GbxIdentityClampSet can't be stubbed, so we don't need to check for that here."

	^clientObject gbxBasicClass == clientClass or: 
			[clientClass == IdentitySet
				and: [clientObject gbxBasicClass == GbxIdentityClampSet]]
]

