Class {
	#name : #'GbxRemoteObject',
	#superclass : #'Object',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'private' }
GbxRemoteObject >> validateSessionForProxy: aProxy 
	"Private.  Raise an error if there are any obvious problems with
	 the proxy for the receiver delegate.
	Since a single proxy should not be associated with multiple sessions, 
	just invoking this method is an error."

	aProxy gbxProxyError: 'Defunct %1 - invalid self'
		with: aProxy gbxBasicClass.
	^nil

{ #category : #'private' }
GbxRemoteObject >> forAnySingleSession

	"Private.  The receiver satisfies this request.  Compare with GbxObjectList>>forAnyOrCurrentSessionForObject:."
	^self

{ #category : #'dirty management' }
GbxRemoteObject >> gbxDelegate
	"Private.  Answer nil or a client-object, found cached for any
	 session, representing a remote-object that is the logical
	 equivalent to the receiver. An instance of any subclass of
	 GbxRemoteObject is a valid response."
	"This message is rarely received by RemoteObjects, but 
	some debugging tools such as inspectors and stack dumpers
	send #gbxDelegate to anything. Since the receiver is never 
	a replicate, answer nil."

	^nil

