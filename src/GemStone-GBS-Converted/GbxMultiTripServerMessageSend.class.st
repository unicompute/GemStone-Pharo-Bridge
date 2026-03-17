Class {
	#name : 'GbxMultiTripServerMessageSend',
	#superclass : 'GbxMultiTripServerInteraction',
	#instVars : [
		'receiver',
		'selector',
		'cSelector'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'validation' }
GbxMultiTripServerMessageSend >> verify
	"Raise an error if someone gave me bogus things to execute.
	If everything looks hunky-dory, answer true."

	^(GbsError verifyBytes: selector) & (GbsError 
				verify: argumentDelegates
				is: Array
				of: GbxDelegate)

{ #category : 'accessing' }
GbxMultiTripServerMessageSend >> selector: anObject
	
	selector := anObject.
	cSelector := anObject gbxAsCString

{ #category : 'accessing' }
GbxMultiTripServerMessageSend >> cSelector
	
	^cSelector

{ #category : 'accessing' }
GbxMultiTripServerMessageSend >> receiver: anObject
	receiver := anObject

{ #category : 'accessing' }
GbxMultiTripServerMessageSend >> selector
	^selector

{ #category : 'accessing' }
GbxMultiTripServerMessageSend >> receiver
	^receiver

{ #category : 'printing' }
GbxMultiTripServerMessageSend >> printOn: aStream

	super printOn: aStream.
	aStream nextPutAll: ', selector '.
	selector printOn: aStream.
	aStream nextPutAll: ', receiver '.
	receiver printOn: aStream

{ #category : 'dispatching' }
GbxMultiTripServerMessageSend >> storeTravDoArgs
	"Answer an arguments struct appropriate for myself.
	Since I don't know anything about such structs, ask the server interface for it, since it knows
	about such things."

	^serverInterface storeTravDoArgsForMessageSend: self

