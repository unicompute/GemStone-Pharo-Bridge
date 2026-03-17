Class {
	#name : 'GbxTimestampReplicator',
	#superclass : 'GbxPointerObjectReplicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private support' }
GbxTimestampReplicator >> clientTimeZone
[

	| timeZone |
	timeZone := session clientTimeZone == nil
				ifTrue: [GbsTimeZone current]
				ifFalse: [session clientTimeZone].
	^timeZone
]

{ #category : 'private store replication' }
GbxTimestampReplicator >> namedInstvarsOf: anObject inServerOrderDo: aBlock
[
	"anObject is a client object, an instance of the class that I replicate.
	For each instvar (named or indexed) that is mapped to the server,
	evaluate the unary aBlock with that instvar's value as the argument.
	The order of evaluation is the order in which oops would appear in
	the value buffer of a server object report. At the evaluation for server
	named instvars that are not mapped to the client, evaluate the block with 
	a delegate for OOP_ILLEGAL."

	| timeZone gmt dayOfYear millisecondPastMidnight |
	timeZone := self clientTimeZone.
	gmt := timeZone localToUniversal: anObject.
	dayOfYear := gmt asDate day.	"Timestamp day is day of month."
	millisecondPastMidnight := gmt asTime asSeconds * 1000 + gmt millisecond.	"Timestamp millisecond is 0-999"
	aBlock
		value: gmt year;
		value: dayOfYear;
		value: millisecondPastMidnight;
		value: session gemTimeZone.
	self
		namedInstvarsOf: anObject
		inServerOrderFrom: 5
		to: serverToClientOffsets size
		do: aBlock
]

