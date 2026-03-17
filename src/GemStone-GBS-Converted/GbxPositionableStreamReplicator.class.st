Class {
	#name : 'GbxPositionableStreamReplicator',
	#superclass : 'GbxPointerObjectReplicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private store replication' }
GbxPositionableStreamReplicator >> namedInstvarsOf: anObject inServerOrderDo: aBlock
[
	"anObject is a client object, an instance of the class that I replicate.
	For each instvar (named or indexed) that is mapped to the server,
	evaluate the unary aBlock with that instvar's value as the argument.
	The order of evaluation is the order in which oops would appear in
	the value buffer of a server object report. At the evaluation for server
	named instvars that are not mapped to the client, evaluate the block with 
	a delegate for OOP_ILLEGAL."

	aBlock value: anObject collection.
	aBlock value: anObject position + 1.
	self
		namedInstvarsOf: anObject
		inServerOrderFrom: 3
		to: serverToClientOffsets size
		do: aBlock
]

