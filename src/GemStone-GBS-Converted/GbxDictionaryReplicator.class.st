Class {
	#name : #'GbxDictionaryReplicator',
	#superclass : #'GbxDeferredElementsReplicator',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'private store replication' }
GbxDictionaryReplicator >> serverIndexedSizeOf: anObject
	"Answer the number of indexed instance variables in the server representation of anObject"

	^anObject size

{ #category : #'private store replication' }
GbxDictionaryReplicator >> indexedInstvarsOf: anObject inServerOrderDo: aBlock
	"anObject is a client object, an instance of the class that I replicate.
	For each indexed instvar
	evaluate the unary aBlock with that instvar's value as the argument.
	The order of evaluation is the order in which oops would appear in
	the value buffer of a server object report.

	This is the associations that are present, omitting the nil entries in the hash table."

	anObject associationsDo: aBlock

