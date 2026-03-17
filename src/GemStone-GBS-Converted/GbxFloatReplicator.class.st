Class {
	#name : #'GbxFloatReplicator',
	#superclass : #'GbxByteObjectReplicator',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'private' }
GbxFloatReplicator >> setImmutabilityOf: aClientObject
	"Numbers are always immutable."

	self setMagnitudeImmutabilityOf: aClientObject

