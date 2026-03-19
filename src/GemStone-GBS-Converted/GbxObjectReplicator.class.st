Class {
	#name : 'GbxObjectReplicator',
	#superclass : 'GbxReplicator',
	#instVars : [
		'serverClass',
		'currentReport',
		'reportOop',
		'clientObject',
		'notCachedToken',
		'reportCount',
		'delegate',
		'clientClass'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxObjectReplicator >> serverClass
[

	^serverClass
]

{ #category : 'accessing' }
GbxObjectReplicator >> clientClass
[

	^clientClass
]

{ #category : 'per-object initialization' }
GbxObjectReplicator >> initializeForNewObject
[

	clientObject := currentReport := delegate := reportOop := nil.
	reportCount := 0
]

{ #category : 'per-object private - testing' }
GbxObjectReplicator >> expectsAnotherReport
[
	"Answer true if there should be another report for this object at the start of the next buffer."

	^(clientObject gbxIsThisLastReport: currentReport) not
]

{ #category : 'per-object private' }
GbxObjectReplicator >> updateClientSize
[
	"ClientObject is of the correct class, but the size of clientObject needs to be changed 
	to match currentReport, which is known to be a full report.
	 For most replicators, we create an appropriate empty object for the currentReport and use
	two-way become to replace clientObject with the newly-created object."

	| oldClientObject |
	oldClientObject := clientObject.
	self createClientObject.
	oldClientObject gbxBecome: clientObject.
	clientObject := oldClientObject
]

{ #category : 'per-object private' }
GbxObjectReplicator >> updateOrCreateClientObject
[
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	clientObject == notCachedToken
		ifTrue: [self createAndMapClientObject]
		ifFalse: [self updateClientObjectForFault]
]

{ #category : 'per-object private' }
GbxObjectReplicator >> clientClassIsCorrect
[
	"Answer whether the class of clientObject is correct with respect to currentReport.
	If the report is header-only, then either clientObject is a stub and we leave it alone,
	or it's a replicate and we leave it alone. Otherwise, for most replicators the
	class must be an exact match."

	^currentReport isHeaderOnly
		or: [clientObject gbxBasicClass == clientClass]
]

{ #category : 'per-object private' }
GbxObjectReplicator >> clientSizeIsCorrect
[
	"Most client objects are fixed-size. Replicators for classes such as Set and OrderedCollection whose instances
	are variable-size should override this method to answer true."

	self subclassResponsibility
]

{ #category : 'per-object private' }
GbxObjectReplicator >> createAndMapClientObject
[
	"Create and map a stub, forwarder, or empty replicate as appropriate.
	In the case of header-only reports, clientClass may be the not cached token"
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	self createClientObject.
	"Whatever we created, map it."
	session unprotectedConnectNewClient: clientObject toServer: reportOop
]

{ #category : 'per-object private' }
GbxObjectReplicator >> createClientObject
[
	"Create but do not map a stub, forwarder, or empty replicate as appropriate.
	In the case of header-only reports, clientClass may be the not cached token"
	"Sender must hold aSession's sessionProtect"

	currentReport isHeaderOnly
		ifTrue: 
			["This report is a header-only report, so create a stub. We know the client class
				is a real class."
			clientObject := self stubClass newOfClass: clientClass
						fromReport: currentReport]
		ifFalse: 
			["We have values - if it's supposed to be a forwarder, we'll ignore those values. Otherwise, 
				instantiate a replicate. We must have a class that is not a forwarder at this point. 
				If the class was a stub this will unstub it."
			[clientClass instancesAreForwarders not] gbxAssert.
			clientObject := self createEmptyReplicateForReport]
]

{ #category : 'per-object private' }
GbxObjectReplicator >> createEmptyReplicateForReport
[

	^clientClass newFromGSObjectReport: currentReport inSession: session
]

{ #category : 'per-object private' }
GbxObjectReplicator >> reportTotalSize
[
	"Not how many bytes or slots are in the value buffer of this report, 
	but how many the report says are in the server object."

	^currentReport namedSize + currentReport idxSize
]

{ #category : 'per-object private' }
GbxObjectReplicator >> setImmutability
[
	"Some subclasses replicate immutable objects. In general, we leave replicates mutable."

	self setImmutabilityOf: clientObject
]

{ #category : 'per-object private' }
GbxObjectReplicator >> setMagnitudeImmutabilityOf: aClientObject
[
	"Magnitudes are always immutable."

	aClientObject gbxIsImmutable: true.
	aClientObject gbxDelegate
		ifNotNil: [:del | (del forSession: session) isReadOnlyObject: true]
]

{ #category : 'per-object private' }
GbxObjectReplicator >> updateClientClassAndSize
[
	"The class of clientObject needs to be changed to match currentReport, which is 
	known to be a full report.
	 In the case of a stub, we may be able to just change the class if the size matches. 
	Otherwise we create an appropriate empty object for the currentReport and use
	two-way become to replace clientObject with the newly-created object."
	"We're changing class, so if the old class was immutable (or a stub, and stubs are always immutable) 
	we need to make it mutable so we can update the object. If the new class is also immutable it'll 
	get fixed up after the state is replicated into the new instance."

	clientObject gbxIsImmutable: false.
	clientObject zzzisStub
		ifTrue: 
			[self canUnstubInPlace
				ifTrue: [clientObject gbxChangeClassTo: clientClass]
				ifFalse: [self updateClientSize]]
		ifFalse: [self updateClientSize]
]

{ #category : 'per-object private' }
GbxObjectReplicator >> updateClientObjectForFault
[
	"There is an existing client object, and we are about to update it from an object report. 
	The existing client object may or may not be compatible with the report.
	Reasons for incompatibility include:
		* The server object has changed its class, possibly through a #become: on the server,
			so the client object's class is no longer the mapped class of the server.
		* The server object has changed its size, and the client class is not one with a variable size.
		* The client object is a stub, and we have received a full report for it, and so should unstub.
	If it is not compatible, we change the client object so that it is compatible. Tools used to do this are:
		* #changeClassTo:
		* #become:

	Sender must hold sessionProtect"
	"If the client object is immutable, it is an error to try to change it."

	self clientClassIsCorrect
		ifFalse: 
			[self errorIfClientImmutable.
			self updateClientClassAndSize]
		ifTrue: 
			[self clientSizeIsCorrect
				ifFalse: 
					[self errorIfClientImmutable.
					self updateClientSize]]
]

{ #category : 'per-object private' }
GbxObjectReplicator >> canUnstubInPlace
[

	self subclassResponsibility
]

{ #category : 'immutability checking' }
GbxObjectReplicator >> signalNoModificationError
[

	(NoModificationError
		receiver: clientObject
		selector: #replicating
		index: nil
		value: nil) gbxReallyRaiseRequest
]

{ #category : 'immutability checking' }
GbxObjectReplicator >> clientObjectIsImmutable
[

	^self delegate isReadOnlyObject
]

{ #category : 'immutability checking' }
GbxObjectReplicator >> errorIfClientImmutable
[
	"If the client object is immutable, it is an error to try to change it.
	But we may get reports for objects that have not changed on the server.
	This happens frequently in multi-trip, and even in single-trip can happen
	if the server object is moved from one page to another by clustering."

	self clientObjectIsImmutable ifTrue: [self signalNoModificationError]
]

{ #category : 'initialize-release' }
GbxObjectReplicator >> initializeForClientClass: aClientClass serverClass: classDelegate manager: aManager
[

	clientClass := aClientClass.
	serverClass := classDelegate.
	manager := aManager.
	session := aManager session.
	notCachedToken := NotCachedToken.
	self initializeForNewObject.
	^self
]

{ #category : 'initialize-release' }
GbxObjectReplicator >> initializeForServerInstVarNames: names
[
	"Only pointer objects have named instvars, so ignore this message otherwise."
]

{ #category : 'printing' }
GbxObjectReplicator >> printOn: aStream
[

	| name |
	super printOn: aStream.
	name := [clientClass name] on: Error
				do: [:ex | ex return: '(' , ex printString , ')'].
	aStream
		nextPutAll: ' for ';
		nextPutAll: name
]

{ #category : 'per-object replication' }
GbxObjectReplicator >> forReplication: replicator replicateFromReport: report
[
	"Sender must hold session's semaphore, and clientMap semaphore."

	self subclassResponsibility
]

{ #category : 'per-object replication' }
GbxObjectReplicator >> forReplication: replication replicateFromDeferredReport: report
[
	"By the time an object replicator is asked to replicate from a deferred report, the condition that caused the deferral 
	has been dealt with, and normal replication can proceed."
	"Sender must hold session's semaphore, and clientMap semaphore."

	^self forReplication: replication replicateFromReport: report
]

{ #category : 'per-object accessing' }
GbxObjectReplicator >> delegate
[
	"Don't create delegate until needed, for instance no delegate for deferred reports."

	delegate == nil 
		ifTrue: [delegate := reportOop asGSObjectInSession: session].
	^delegate
]

{ #category : 'instance creation' }
GbxObjectReplicator class >> forClientClass: clientClass serverClass: classDelegate manager: manager
[

	^self new
		initializeForClientClass: clientClass
		serverClass: classDelegate
		manager: manager
]
