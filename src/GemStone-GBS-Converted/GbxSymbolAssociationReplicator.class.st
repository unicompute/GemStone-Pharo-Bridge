Class {
	#name : 'GbxSymbolAssociationReplicator',
	#superclass : 'GbxPointerObjectReplicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'per-object private' }
GbxSymbolAssociationReplicator >> clientClassIsCorrect
[
	"Answer true if the class of the server class of the existing mapped client object 
	is not sufficiently the same as the class of the server object being replicated.
	Since a GbxNameAssociation on the client is an SymbolAssociation on the server, 
	and we don't want to change the class of a client GbxNameAssociation,
	we consider that condition to be not a change."

	^currentReport isHeaderOnly or: 
			[clientObject gbxBasicClass == clientClass
				or: [clientObject gbxBasicClass == GbxNameAssociation]]
]

{ #category : 'per-object private' }
GbxSymbolAssociationReplicator >> clientSizeIsCorrect
[
	"We need to know whether the number of total pointers (named plus indexed) is correct.
	Especially in the unstubbing case, the number of named instvars may be different
	but the total size may still be correct."
	"Since the client class may be either of two classes, with different sizes, we use two tests.
	For GbxNameAssociations, which do not have indexed instvars, the size is always correct
	since server-side SymbolAssociations also do not have indexed instvars."

	| existingClass |
	existingClass := clientObject gbxBasicClass.
	^existingClass = GbxNameAssociation
		ifTrue: [true]
		ifFalse: [super clientSizeIsCorrect]
]

