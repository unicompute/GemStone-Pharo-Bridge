Class {
	#name : 'GbxPointerMagnitudeReplicator',
	#superclass : 'GbxPointerObjectReplicator',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private' }
GbxPointerMagnitudeReplicator >> setImmutabilityOf: aClientObject
	"Magnitudes are always immutable."

	self setMagnitudeImmutabilityOf: aClientObject

