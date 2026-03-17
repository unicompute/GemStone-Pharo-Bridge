Class {
	#name : #'GbsFastConnector',
	#superclass : #'GbsConnector',
	#instVars : [ #'clientObj' #'serverKernelOop' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'private' }
GbsFastConnector >> isKnownKernelOop
	"Private.  Return true if the connector is guaranteed to resolve to a GemStone kernel object.  This doesn't include Japanese character oops"

	^serverKernelOop oopNumber <= LastKernelOopNumber

{ #category : #'private' }
GbsFastConnector >> clientObjIsUnstubbedClass
	"Private.  For building replication clamps, we need to be sure that unstubbing will not happen or
	we end up in an infinite loop."

	^clientObj zzzisStub not and: [clientObj isBehavior]

{ #category : #'private connecting' }
GbsFastConnector >> postConnectClient: aClientObj server: delegate inSession: aGSSession 
	"Private to GBS.  Events to occur after connecting.
	Sender must hold session's sessionProtect"

	| pca |
	pca := self postConnectAction.
	pca == #updateGS ifTrue: [delegate markStDirty: aClientObj].

	"Update the Smalltalk object from the given GemStone object"
	(pca == #updateST or: [pca == #forwarder]) 
		ifTrue: 
			[clientObj gbxUpdateAsForwarder: self postConnectAction == #forwarder
				fromDelegate: delegate]

{ #category : #'private connecting' }
GbsFastConnector >> canForwardTo: clientObject inSession: aSession
	"Answer true iff the client object is something that a server ClientForwarder can be connected to."

	self gbsMessenger
		error: 'Fast connectors with a post-connect action of ClientForwarder are not supported.'

{ #category : #'private connecting' }
GbsFastConnector >> validPostConnectActions
	"Private"

	| valid |
	valid := self class validPostConnectActions asSet.
	valid remove: #clientForwarder.
	^valid asArray

{ #category : #'private connecting' }
GbsFastConnector >> simpleConnectInSession: sess
	"Private to GBS. Used at login time to bootstrap crucial kernel classes.
	The sender must hold the session's sessionProtect.
	I am a fast connector for a class. Connect me without connecting my metaclass.
	Metaclass connection will be done later in the login, it can't be done now because
	the metaclass oop cannot be determined until I am connected."

	sess connectClient: clientObj toServer: (self resolveGSObjInSession: sess)

{ #category : #'printing' }
GbsFastConnector >> printOn: aStream

	super printOn: aStream.
	aStream
		nextPutAll: ' for ';
		nextPutAll: self clientObjDescription

{ #category : #'private printing' }
GbsFastConnector >> gsDescription
	"Private - do not delete as it is sent by the gui code with a #perform:, 
	see the #windowSpec for GbsConnectorBrowser"

	^serverKernelOop printString

{ #category : #'private printing' }
GbsFastConnector >> clientObjDescription
	"Private"
	
	^clientObj gbxDebugPrintString

{ #category : #'private printing' }
GbsFastConnector >> stDescription
	"Private. Sent by aspect adaptor in connector browser"

	^clientObj gbxDebugPrintString

{ #category : #'gbs private testing' }
GbsFastConnector >> isFastConnectorTypeNone
	"Private to GBS"

	^self postConnectAction == #none

{ #category : #'private initialization' }
GbsFastConnector >> stObj: anObject gsObj: aGSObject postConnectAction: pca
	"Private"

	self stObj: anObject gsObj: aGSObject.
	postConnectAction := pca

{ #category : #'private initialization' }
GbsFastConnector >> stObj: anObject gsObj: aGSObject
	"Private"

	serverKernelOop := aGSObject.
	clientObj := anObject.
	connectionCondition := [true]	"most connectors just connect"

{ #category : #'private initialization' }
GbsFastConnector >> postConnectSaveGsObjectInSession: aSession
	"Private. Answer nil or an GbsObject or oop to be added to the
	 session export set to avoid GC."
	
	^connectionCondition value
		ifTrue: [serverKernelOop asGSObjectInSession: aSession]
		ifFalse: [nil]

{ #category : #'private resolving' }
GbsFastConnector >> resolveGSObjInSession: aGSSession ifFail: failBlock 
	"fast connectors just create a delegate from a kernel oop.
	They can't fail"

	^self resolveGSObjInSession: aGSSession

{ #category : #'private resolving' }
GbsFastConnector >> resolveClientObj
	"Private.  Resolve (trivial) and return Smalltalk object to be connected.
	 Do not trigger any defunct forwarder or defunct stub errors."

	clientObj gbxIsGSDefunct ifTrue: [
		self gbsMessenger
			raise: GbsConnectorError
			message: 'Defunct stub or forwarder'.
		^nil
	].
	^clientObj

{ #category : #'private resolving' }
GbsFastConnector >> resolveGSObjInSession: aGbsSession 
	"Private.  Resolve (trivial) and return GemStone object to be connected"

	"Always return a new proxy guaranteed to reflect the given session"

	^serverKernelOop asGSObjectInSession: aGbsSession

{ #category : #'private resolving' }
GbsFastConnector >> updateGSfromST: anSTObj session: aGSSession

	"Private.  The 'update' is a simple resolution - it will get updated in postConnectST:GS:session: through markDirty"
	^self resolveGSObjInSession: aGSSession

{ #category : #'private resolving' }
GbsFastConnector >> updateClientfromDelegate: delegate

	"Private.  The update must happen after the connection has been made, as we can't
	 create a stub that isn't in the cache"
	^clientObj

{ #category : #'testing' }
GbsFastConnector class >> supportsFromUser
	"GBS Private. Answer whether the user is allowed to create connectors of this type through the GUI."

	^false

{ #category : #'instance creation' }
GbsFastConnector class >> smalltalk: anObject gemstone: aGSObject 
	GbsConfiguration 
		deprecated: 'GbsFastConnector>>smalltalk:gemstone: deprecated March, 2006. Send #stObj:gsObj: instead'.
	^self stObj: anObject gsObj: aGSObject

{ #category : #'instance creation' }
GbsFastConnector class >> stObj: anObject gsObj: aGSObject 
	"any fast connector should be created with a GbxKernelPomOop"

	self gbxFixMe.	"The current thinking is that we don't want the user to create KernelOops, so we may want to add a way to create a FastConnector for sessions that are not logged in. Or we may choose to disallow creation of FastConnectors unless logged in. Right now, the stObj:gsObj: method sends asKernelPomOop to the gs object that is passed in. If the gs object a GbxDelegate, it relies on its session's special converter to get the oopNumber for the KernelOop. Since the GbxDelegate doesn't store its session, it would send up an error message when trying to create the kernel oop in this way. "
	^self basicNew 
		stObj: anObject
		gsObj: aGSObject asKernelPomOop
		postConnectAction: self defaultPostConnectAction	"Private"

{ #category : #'instance creation' }
GbsFastConnector class >> gemstone: aGSObject smalltalk: anObject 
	GbsConfiguration 
		deprecated: 'GbsFastConnector>>gemstone:smalltalk: deprecated March, 2006. Send #stObj:gsObj: instead'.
	^self stObj: anObject gsObj: aGSObject

