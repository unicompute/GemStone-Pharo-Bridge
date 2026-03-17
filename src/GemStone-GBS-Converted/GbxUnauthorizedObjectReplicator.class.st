Class {
	#name : 'GbxUnauthorizedObjectReplicator',
	#superclass : 'GbxObjectReplicator',
	#instVars : [
		'reportHasNilClass'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private store replication' }
GbxUnauthorizedObjectReplicator >> pack: anObject withDelegate: aDelegate inTraversal: storeTraversal
[
	"Unauthorized object stubs should never be dirty, and so never packed.
	If asked, do nothing, but if assertions are on fail."

	[false] gbxAssertEquals: true
		message: 'Unauthorized object stubs should never be dirty, and thus never packed.'
]

{ #category : 'private store replication' }
GbxUnauthorizedObjectReplicator >> packDirtyReferentsOf: anObject inTraversal: storeTraversal
[
	"Unauthorized object stubs have no referents, so it's safe to do nothing here.
	However, we should actually never enter this method, so fail if assertions are on."

	[false] gbxAssertEquals: true
		message: 'Unauthorized object stubs should never be dirty, and thus never packed.'
]

{ #category : 'per-object initialization' }
GbxUnauthorizedObjectReplicator >> initializeForNewObject
[

	super initializeForNewObject.
	reportHasNilClass := false
]

{ #category : 'per-object private' }
GbxUnauthorizedObjectReplicator >> updateClientClassAndSize
[
	"The class of clientObject needs to be changed to match currentReport, which is 
	known to be a full or header-only report calling for an unauthorized object stub.
	The customizable unauthorized stub class may not have a zero size, and this shouldn't happen frequently,
	so always take the full #become: route.
	"

	self updateClientSize
]

{ #category : 'per-object private' }
GbxUnauthorizedObjectReplicator >> canUnstubInPlace
[
	"Can't unstub at all, actually..."

	^false
]

{ #category : 'per-object private' }
GbxUnauthorizedObjectReplicator >> createClientObject
[
	"Create but do not map an unauthorized object stub."
	"Sender must hold aSession's sessionProtect"

	clientObject := self unauthorizedObjectStubClass new
]

{ #category : 'per-object private' }
GbxUnauthorizedObjectReplicator >> clientClassIsCorrect
[
	"Answer whether the class of clientObject is correct with respect to currentReport.
	In this case, the only correct class is our unauthorized object stub class."

	^clientObject gbxBasicClass == self unauthorizedObjectStubClass
]

{ #category : 'per-object private' }
GbxUnauthorizedObjectReplicator >> clientSizeIsCorrect
[
	"This question is only asked if the client class is correct. 
	Since unauthorized object stubs only come in one size..."

	^true
]

{ #category : 'clamping' }
GbxUnauthorizedObjectReplicator >> updateInstVarLevelsOfScheme: scheme
[
	"Unauthorized object stubs do not inherit from Object on the server, and so do not understand
	clamp-by-callback messages. In order to prevent clamp-by-callback messages from being sent,
	put an entry for this class into the instVarLevels dictionary, which will prevent attempts to 
	traverse it by callback. It has no instance variables, and no indexed instance variables, but adding 
	a nil spec for indexed instance variables should do the trick."
	
	scheme
		updateInstVarLevels: (Array with: nil)	"Cannot use a literal, as it cannot be shared across sessions."
		forwarderOffsets: #()
		forwardIndexedPart: false
		forClass: self clientClass
]

{ #category : 'initialize-release' }
GbxUnauthorizedObjectReplicator >> initializeForManager: aManager
[

	| stubClass sess |
	stubClass := self unauthorizedObjectStubClass.
	sess := aManager session.
	self
		initializeForClientClass: stubClass
		serverClass: (sess cacheAtST: stubClass)
		manager: aManager
]

{ #category : 'per-object replication' }
GbxUnauthorizedObjectReplicator >> unauthorizedObjectStubClass
[

	^GbxUnauthorizedObjectStub
]

{ #category : 'per-object replication' }
GbxUnauthorizedObjectReplicator >> forReplication: replication replicateFromReport: report
[
	"Don't have read access to the server object, so map it to an unauthorized object stub. 
	An attempt to unstub this stub will signal an error."
	"Sender must hold session's semaphore, and clientMap semaphore."

	currentReport := report.
	reportOop := report objId.
	reportHasNilClass := report objClass sameOopAs: session oopNil.
	self
		replicateFromReport;
		initializeForNewObject
]

{ #category : 'per-object replication' }
GbxUnauthorizedObjectReplicator >> replicateFromReport
[
	"Private.  Given the description of a GemStone object from a traversal object header,
	 replicate the object as a client unauthorized object stub. Self is returned."
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	clientObject := session clientAtOop: reportOop.
	self updateOrCreateClientObject.
	(reportHasNilClass or: [currentReport isHeaderOnly])
		ifFalse: [self delegate nowExported].
	"Catch any assignments made to instvars of what is now an unauthorized object stub."
	clientObject gbxTrapFutureChanges
]

{ #category : 'instance creation' }
GbxUnauthorizedObjectReplicator class >> newForManager: aManager
[

	^self new initializeForManager: aManager
]

