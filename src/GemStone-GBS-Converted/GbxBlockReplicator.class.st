Class {
	#name : #'GbxBlockReplicator',
	#superclass : #'GbxPointerObjectReplicator',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'per-object private' }
GbxBlockReplicator >> canUnstubInPlace
	"Blocks aren't the size they appear to be from the report, so can never unstub in place."

	^false

{ #category : #'per-object private' }
GbxBlockReplicator >> assignInstvars
	"The normal assignment doesn't apply to blocks -- the method for the 
	block has already been compiled and set by the time this message is sent."

