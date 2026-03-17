Class {
	#name : 'GbxSingleTripServerMessageSend',
	#superclass : 'GbxSingleTripServerInteraction',
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
GbxSingleTripServerMessageSend >> verify
	"Raise an error if someone gave me bogus things to execute.
	If everything looks hunky-dory, answer true."

	^(GbsError verifyBytes: selector) & (GbsError 
				verify: argumentDelegates
				is: Array
				of: GbxDelegate)

{ #category : 'accessing' }
GbxSingleTripServerMessageSend >> selector: anObject
	
	selector := anObject.
	cSelector := anObject gbxAsCString

{ #category : 'accessing' }
GbxSingleTripServerMessageSend >> cSelector
	
	^cSelector

{ #category : 'accessing' }
GbxSingleTripServerMessageSend >> receiver: anObject
	receiver := anObject

{ #category : 'accessing' }
GbxSingleTripServerMessageSend >> selector
	^selector

{ #category : 'accessing' }
GbxSingleTripServerMessageSend >> receiver
	^receiver

{ #category : 'printing' }
GbxSingleTripServerMessageSend >> printOn: aStream

	super printOn: aStream.
	aStream nextPutAll: ', selector '.
	selector printOn: aStream.
	aStream nextPutAll: ', receiver '.
	receiver printOn: aStream

{ #category : 'dispatching' }
GbxSingleTripServerMessageSend >> storeTravDoArgs
	"Answer an arguments struct appropriate for myself.
	Since I don't know anything about such structs, ask the server interface for it, since it knows
	about such things."

	^serverInterface storeTravDoArgsForMessageSend: self

