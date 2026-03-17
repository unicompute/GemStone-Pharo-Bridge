Class {
	#name : 'GbxIdentityDictionaryReplicator',
	#superclass : 'GbxDeferredElementsReplicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private store replication' }
GbxIdentityDictionaryReplicator >> indexedInstvarsOf: anObject inServerOrderDo: aBlock
[
	"anObject is a client object, an instance of the class that I replicate.
	For each indexed instvar
	evaluate the unary aBlock with that instvar's value as the argument.
	The order of evaluation is the order in which oops would appear in
	the value buffer of a server object report.

	For an identity dictionary, keys and values alternate in the traversal buffer."

	anObject keysAndValuesDo: 
			[:key :value |
			aBlock value: key.
			aBlock value: value]
]

{ #category : 'private store replication' }
GbxIdentityDictionaryReplicator >> serverIndexedSizeOf: anObject
[
	"Answer the number of indexed instance variables in the server representation of anObject"

	^anObject size * 2	"Key and value for each entry"
]

{ #category : 'private store replication' }
GbxIdentityDictionaryReplicator >> instvarsOf: anObject inServerOrderDo: aBlock
[
	"anObject is a client object, an instance of the class that I replicate.
	For each instvar (named or indexed) that is mapped to the server,
	evaluate the unary aBlock with that instvar's value as the argument.
	The order of evaluation is the order in which oops would appear in
	the value buffer of a server object report. At the evaluation for server
	named instvars that are not mapped to the client, evaluate the block with 
	a delegate for OOP_ILLEGAL."

	"Do this on the actual object rather than the indexable buffer -- which would be doing the unrolling twice,
	and this should be faster."

	self
		namedInstvarsOf: anObject inServerOrderDo: aBlock;
		indexedInstvarsOf: anObject inServerOrderDo: aBlock
]

