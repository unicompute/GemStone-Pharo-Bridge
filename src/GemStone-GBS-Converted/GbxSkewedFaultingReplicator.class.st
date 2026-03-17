Class {
	#name : #'GbxSkewedFaultingReplicator',
	#superclass : #'GbxReplicator',
	#instVars : [ #'oldServerClass' #'newServerClass' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'per-object replication' }
GbxSkewedFaultingReplicator >> forReplication: replication replicateFromDeferredReport: report
	"Migrate to a copy of the instance on the server, and use the mapped class's replicator to replicate the 
	result. Then copy that result and map the copy to the original report oop."
	"Sender must hold session semaphore and cache semaphore."

	| delegate skewedClientObject clientObject |
	GbsConfiguration current verbose
		ifTrue: 
			[self gbsMessenger
				comment: 'GBSM is replicating an instance %1 of %2 but is connected to %3'
				with: (report objId asGSObjectInSession: session)
				with: oldServerClass versionDescription
				with: newServerClass versionDescription].
	delegate := report objId asGSObjectInSession: session.
	"The following execution uses the normal replicator for the mapped class."
	skewedClientObject := session
				evaluateBlock: '
							[:mappedClass :existingObj | 
							| newObj |
							newObj := mappedClass new.
							newObj migrateFrom: existingObj.
							newObj]'
				withArguments: (Array with: newServerClass with: delegate)
				context: session oopIllegal
				toLevel: 1.
	"We might be unstubbing an instance of an old class version."
	clientObject := session lookupOop: delegate.
	clientObject == NotCachedToken
		ifTrue: 
			["No client object yet."
			clientObject := skewedClientObject shallowCopy.	"don't send copy which sends a #postCopy"
			session unprotectedConnectNewClient: clientObject toServer: delegate]
		ifFalse: [clientObject gbxBecome: skewedClientObject].
	"When autoMarkDirty false, client obj should not be immutable."
	clientObject gbxIsImmutable: skewedClientObject gbxIsImmutable

{ #category : #'per-object replication' }
GbxSkewedFaultingReplicator >> forReplication: replication replicateFromReport: report
	"Since we must go to the server to migrate the instance, and can't do that in the middle of a traversal,
	we must defer the report."
	"Sender must hold session's semaphore, and clientMap semaphore."

	replication addUnmappedClassReport: report copyWithPrivateBuffer

{ #category : #'testing' }
GbxSkewedFaultingReplicator >> isSkew

	^true

{ #category : #'accessing' }
GbxSkewedFaultingReplicator >> newServerClass

	^newServerClass

{ #category : #'initialize-release' }
GbxSkewedFaultingReplicator >> verifyClassRelationship
	"The old class and the new class must be in the same class history, and new must be later in the class history than the old.
	Sender must hold sessionProtect."

	| skewMessage |
	skewMessage := session
				unsynchronizedEvaluateBlock: '
							[:mappedClass :instanceClass |
							(instanceClass isVersionOf: mappedClass)
								ifTrue: [(mappedClass classHistory indexOf: mappedClass)
										> (instanceClass classHistory indexOf: instanceClass)
											ifTrue: [''skew'']
											ifFalse: [''which is an earlier version of that class'']]
								ifFalse: [''which is in a different class history.'']]'
				with: newServerClass
				with: oldServerClass.
	skewMessage = 'skew'
		ifFalse: 
			[self gbsMessenger
				raise: GbsClassGenerationError
				message: 'Cannot map GemStone class %1.\Smalltalk class %2 is already mapped to %3, %4'
				with: oldServerClass
				with: (session lookupOop: newServerClass) name
				with: newServerClass
				with: skewMessage]

{ #category : #'initialize-release' }
GbxSkewedFaultingReplicator >> initializeForSession: aSession serverBehavior: classDelegate clientClass: clientClass
	"Sender must hold sessionProtect."

	session := aSession.
	oldServerClass := classDelegate.
	newServerClass := clientClass gbxDelegate forSession: session.
	self verifyReplicatorExistsForClientClass: clientClass.
	self verifyClassRelationship.
	^self

{ #category : #'initialize-release' }
GbxSkewedFaultingReplicator >> verifyReplicatorExistsForClientClass: clientClass

	session replicatorForClientBehavior: clientClass
		ifAbsent: 
			[self gbsMessenger
				error: 'No replicator for mapped class during skew replication.']

{ #category : #'instance creation' }
GbxSkewedFaultingReplicator class >> forSession: session serverBehavior: classDelegate clientClass: clientClass
	"Sender must hold sessionProtect."

	^self new
		initializeForSession: session
		serverBehavior: classDelegate
		clientClass: clientClass

