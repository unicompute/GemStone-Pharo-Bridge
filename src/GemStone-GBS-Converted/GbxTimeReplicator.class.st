Class {
	#name : 'GbxTimeReplicator',
	#superclass : 'GbxPointerMagnitudeReplicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private store replication' }
GbxTimeReplicator >> namedInstvarsOf: anObject inServerOrderDo: aBlock
	"anObject is a client object, an instance of the class that I replicate.
	For each instvar (named or indexed) that is mapped to the server,
	evaluate the unary aBlock with that instvar's value as the argument.
	The order of evaluation is the order in which oops would appear in
	the value buffer of a server object report. At the evaluation for server
	named instvars that are not mapped to the client, evaluate the block with 
	a delegate for OOP_ILLEGAL."
	"The server class Time has only one instvar, 'milliseconds', but any 
	subclasses might have more"

	| nanosecondsWithinDay nanosecondsWithinMillisecond truncatedMilliseconds roundedMilliseconds |
	nanosecondsWithinDay := anObject asNanoseconds.
	nanosecondsWithinMillisecond := nanosecondsWithinDay \\ 1000000.
	truncatedMilliseconds := nanosecondsWithinDay // 1000000.
	roundedMilliseconds := (nanosecondsWithinMillisecond > 500000
				or: [nanosecondsWithinMillisecond == 500000 and: [truncatedMilliseconds odd]])
					ifTrue: [truncatedMilliseconds + 1]
					ifFalse: [truncatedMilliseconds].
	"Server wants milliseconds within a day so take VW Time modulo one day"
	aBlock value: roundedMilliseconds \\ 86400000.
	self
		namedInstvarsOf: anObject
		inServerOrderFrom: 2
		to: serverToClientOffsets size
		do: aBlock

