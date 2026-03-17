Class {
	#name : 'GbxMultiTripServerTraversal',
	#superclass : 'GbxMultiTripServerInteraction',
	#instVars : [
		'rootDelegate'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'validation' }
GbxMultiTripServerTraversal >> verify
	"Raise an error if someone gave me bogus things to execute.
	If everything looks hunky-dory, answer true."

	^GbsError verify: rootDelegate is: GbxDelegate

{ #category : 'accessing' }
GbxMultiTripServerTraversal >> defaultResult
	"A multi-trip traversal won't do a storeTravDo call unless it needs to flush dirty objects to the server,
	but it needs to return a value. This is the value that would have been returned had it gone to the server."
	
	^rootDelegate

{ #category : 'accessing' }
GbxMultiTripServerTraversal >> rootDelegate
	^rootDelegate

{ #category : 'accessing' }
GbxMultiTripServerTraversal >> rootDelegate: anObject
	rootDelegate := anObject

{ #category : 'printing' }
GbxMultiTripServerTraversal >> printOn: aStream

	super printOn: aStream.
	aStream nextPutAll: ', traversal root: '.
	rootDelegate printOn: aStream

{ #category : 'dispatching' }
GbxMultiTripServerTraversal >> storeTravDoArgs
	"Answer an arguments struct appropriate for myself.
	Since I don't know anything about such structs, ask the server interface for it, since it knows
	about such things.
	
	Answer nil if no storeTravDo is required, which can only be the case with multi-trip traversals,
	in which the only function uf the storeTravDo is to flush objects to the server."
	
	^storeTraversal buffer isEmpty
		ifTrue: [nil]
		ifFalse: [serverInterface storeTravDoArgsForTraversal: self]

