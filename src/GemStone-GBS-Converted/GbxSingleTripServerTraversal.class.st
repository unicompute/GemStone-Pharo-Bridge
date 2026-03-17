Class {
	#name : 'GbxSingleTripServerTraversal',
	#superclass : 'GbxSingleTripServerInteraction',
	#instVars : [
		'rootDelegate'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'validation' }
GbxSingleTripServerTraversal >> verify
	"Raise an error if someone gave me bogus things to execute.
	If everything looks hunky-dory, answer true."

	^GbsError verify: rootDelegate is: GbxDelegate

{ #category : 'accessing' }
GbxSingleTripServerTraversal >> rootDelegate
	^rootDelegate

{ #category : 'accessing' }
GbxSingleTripServerTraversal >> rootDelegate: anObject
	rootDelegate := anObject

{ #category : 'printing' }
GbxSingleTripServerTraversal >> printOn: aStream

	super printOn: aStream.
	aStream nextPutAll: ', traversal root: '.
	rootDelegate printOn: aStream

{ #category : 'dispatching' }
GbxSingleTripServerTraversal >> storeTravDoArgs
	"Answer an arguments struct appropriate for myself.
	Since I don't know anything about such structs, ask the server interface for it, since it knows
	about such things."

	^serverInterface storeTravDoArgsForTraversal: self

