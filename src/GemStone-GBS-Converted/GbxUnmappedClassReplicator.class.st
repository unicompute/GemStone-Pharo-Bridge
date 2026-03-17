Class {
	#name : #'GbxUnmappedClassReplicator',
	#superclass : #'GbxReplicator',
	#instVars : [ #'serverClass' #'classDelegate' #'classProxy' #'clientClass' #'metaclassDelegate' #'metaclassProxy' #'report' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'initialize-release' }
GbxUnmappedClassReplicator >> initializeForSession: aSession serverBehavior: aDelegate

	session := aSession.
	manager := session replicatorManager.
	serverClass := aDelegate

{ #category : #'per-object replication' }
GbxUnmappedClassReplicator >> forReplication: replication replicateFromDeferredReport: aReport
	"My server class is as yet unmapped. We're now at a point where we can map it, 
	replacing myself as the replicator for that server class, and ask the new replicator
	to handle the replication.
	The new replication will either be an ObjectReplicator, if normal class mapping was successful,
	or a skew replicator if a skew case is detected.
	The report could be for an instance of an unmapped class, in which case the report's class oop will be that of
	the unmapped class, or the report could be for the unmapped class itself, in which case the report's class oop
	will be that of the metaclass. In either case, we want to map both class and metaclass.
	The report will *not* be for the metaclass itself -- metaclasses are all instances of Metaclass(3), and that class
	is mapped at login and reports bearing that class oop are handle by GbxMetaclassReplicator."
	"Sender must hold session semaphore and cache semaphore."
	"We know that this report is the first report for this object -- if it were a subsequent report, I would
	no longer be the replicator for the server class."
	"What must be done is:
	1) Find the same-named class on the client. If none, see if we can generate one. If not, error.
	2) Is the same-named client class already mapped? If so, create skew replicator or forwarder 
	    replicator for this server class and let it deal with it.
	3) If not mapped and not skew, map the class and turn the class over to the new replicator."

	report := aReport.
	[report objClass sameOopAs: serverClass] gbxAssert.
	self getClassAndMetaclassInformation.
	self findExistingProxies.
	serverClass = metaclassDelegate
		ifTrue: 
			[classDelegate nowExported.	"We know it was a report for the class; if it had been a report 
									for the metaclass it would have gone to the MetaclassReplicator.
									We also know it was a full report, so is now in the gem's export set,
									since only full reports get deferred and processed here."
			self replicateClassItself]
		ifFalse: 
			[serverClass = classDelegate
				ifTrue: [self replicateClassInstanceForReplication: replication]
				ifFalse: 
					[self gbsMessenger
						error: 'Unmapped class replicator attempting to replicate unexpected class.']]

{ #category : #'per-object replication' }
GbxUnmappedClassReplicator >> forReplication: replication replicateFromReport: aReport
	"We don't need a mapped class to create a stub. 
	If it's a full report we must defer, and map the class at resolve time."
	"Sender must hold session's semaphore, and clientMap semaphore."

	aReport isHeaderOnly
		ifTrue: [self forReplication: replication replicateStubFromReport: aReport]
		ifFalse: [replication addUnmappedClassReport: aReport copyWithPrivateBuffer]

{ #category : #'private' }
GbxUnmappedClassReplicator >> clientClassForServerClass
	"Customer overrides this in subclass."

	^self clientClassWithSameNameAsServerClass

{ #category : #'private' }
GbxUnmappedClassReplicator >> clientClassIsAlreadyMapped
	"Client metaclass is mapped iff the client class is mapped, so only need to test the class.
	Classes can be mapped in more than one session, we care only about whether it's mapped in our session."

	^(clientClass gbxDelegate forSession: session) ~~ nil

{ #category : #'private' }
GbxUnmappedClassReplicator >> mapInstanceForwarderReplicator
	"When connecting a class that answers true to #instancesAreForwarders"
	"Sender must hold my session's protect and the ClientMap's writeProtect semaphores."

	| replicator |
	replicator := session forwarderReplicatorClass
				forClientClass: clientClass
				serverClass: serverClass
				manager: manager.

	"I am currently the mapped replicator for serverClass. Undo this, and replace with the new replicator."
	session
		disconnectReplicatorForServerBehavior: serverClass;
		connectReplicator: replicator
			toClientBehavior: clientClass
			andServerBehavior: serverClass;
		updateClassClampForReplicator: replicator.

	"Replicator for class is now straight. Must now connect the class with basicConnect 
	rather than unprotectedConnect to avoid automatic replicator mapping."
	self unmapProxies.
	session
		basicConnectPossiblyExistingClient: clientClass toServer: classDelegate;
		addClampedObject: clientClass withDelegate: classDelegate.
	"The metaclass can be connected normally and get the normal class replicator."
	session unprotectedConnectPossiblyExistingClient: clientClass class
		toServer: metaclassDelegate.
	self replaceProxies

{ #category : #'private' }
GbxUnmappedClassReplicator >> mapMetaclassAndClass
	"Unmap any currently-mapped replicators for the class and metaclass. I will be one of those replicators, but it doesn't matter,
	we're about to create new, better replicators.
	Map the given client class and its metaclass to the given server class and metaclass. This will create and map an ObjectReplicator
	for the class, and another replicator for the metaclass. Answer the new replicator for the class. 
	

	This class and metaclass may already be mapped in one or more other sessions."
	"Sender must hold session semaphore and cache semaphore."

	| clientMetaclass |
	clientMetaclass := clientClass gbxBasicClass.
	session
		disconnectReplicatorForClientBehavior: clientClass
			andServerBehavior: classDelegate;
		disconnectReplicatorForClientBehavior: clientMetaclass
			andServerBehavior: metaclassDelegate;
		unprotectedConnectPossiblyExistingClient: clientClass
			toServer: classDelegate;
		unprotectedConnectPossiblyExistingClient: clientMetaclass
			toServer: metaclassDelegate.
	session
		mappedClientClass: clientClass toServer: classDelegate;
		updateInstVarNamesAndClamps

{ #category : #'private' }
GbxUnmappedClassReplicator >> unmapMetaclassProxy

	metaclassProxy ~~ NotCachedToken
		ifTrue: 
			[session disconnectClient: metaclassProxy fromServer: metaclassDelegate]

{ #category : #'private' }
GbxUnmappedClassReplicator >> unmapProxies

	self
		unmapClassProxy;
		unmapMetaclassProxy

{ #category : #'private' }
GbxUnmappedClassReplicator >> clientClassWithSameNameAsServerClass
	"Answer the class, or nil if there is no class bound to that name."

	| className possibleClass |
	className := classDelegate unsynchronizedPerformOnGsServer: #name.
	possibleClass := session gbxResolve: className.
	"Client object bound to that name could be something other than a class."
	^(possibleClass isBehavior not or: [possibleClass isMeta])
		ifTrue: [nil]
		ifFalse: [possibleClass]

{ #category : #'private' }
GbxUnmappedClassReplicator >> mapSkewedReplicator
	"Create the skew replicator or error if illegal, and map the replicator to the given class delegate.
	Since there is no associated client class, only the replicator for the class is mapped, the class itself is not mapped.
	Also, no mapping is made for the metaclass.
	Sender must hold sessionProtect."

	| replicator |
	replicator := clientClass gbsSkewedReplicatorClass
				forSession: session
				serverBehavior: classDelegate
				clientClass: clientClass.
	"If the classes do not have the right relationship (unmapped one is in same 
	classHistory and older), an error will have been signaled by the above."
	"I am currently the mapped replicator for classDelegate. Undo this, and replace with the new replicator."
	session
		disconnectReplicatorForServerBehavior: classDelegate;
		connectReplicator: replicator toServerBehavior: classDelegate

{ #category : #'private' }
GbxUnmappedClassReplicator >> replaceClassProxy

	classProxy ~~ NotCachedToken
		ifTrue: [classProxy oneWayBecome: clientClass]

{ #category : #'private' }
GbxUnmappedClassReplicator >> unstubAndMap
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	self
		unmapProxies;
		mapMetaclassAndClass;
		replaceProxies

{ #category : #'private' }
GbxUnmappedClassReplicator >> createClientClassClassified: categoryName
	"Just create and answer the class, no mapping at this point. We use synchronized execution in this method because
	it is not legal to do class mapping during unsynchronized execution, so we're synchronized anyway."
	"Sender must hold session's protect semaphore."

	| clientSuperclass serverClassInfo className instVarNames classVarNames classInstVarNames serverFormat aClientClass |
	clientSuperclass := classDelegate performOnGsServer: #superclass.	"This may recursively invoke this method."
	clientSuperclass gbxIsProxy
		ifTrue: 
			[^self gbsMessenger raise: GbsClassGenerationError
				message: 'Attempt to create a client class for a server class whose superclass is mapped as a stub or forwarder.'].
	serverClassInfo := self infoForServerClass.
	className := serverClassInfo at: 1.
	instVarNames := serverClassInfo at: 2.
	classVarNames := serverClassInfo at: 3.
	classInstVarNames := serverClassInfo at: 4.
	serverFormat := serverClassInfo at: 5.
	GbsConfiguration current verbose
		ifTrue: 
			[self gbsMessenger comment: 'Creating client class %1.' with: className].
	serverFormat \\ 4 = 3
		ifTrue: 
			[^self gbsMessenger raise: GbsClassGenerationError
				message: 'Attempt to create an immediate client class'].
	aClientClass := clientSuperclass
				gbxCreateSubclassNamed: className
				inApplication: nil
				typeName: (serverFormat \\ 4 = 1 ifTrue: ['bytes'] ifFalse: ['pointers'])
				isVariable: (serverFormat \\ 4 = 1
						or: [serverFormat \\ 4 = 0 & (serverFormat // 4 \\ 2 = 1)])
				instanceVariables: instVarNames
				classVariables: classVarNames
				classInstanceVariables: classInstVarNames
				poolNames: #()
				category: categoryName.
	(aClientClass isBehavior and: [aClientClass isMeta not])
		ifFalse: 
			[^self gbsMessenger raise: GbsClassGenerationError
				message: 'A non-class object was generated'].
	^aClientClass

{ #category : #'private' }
GbxUnmappedClassReplicator >> findExistingProxies
	"If there are any existing mappings for client class or metaclass,
	they should be to forwarders or stubs.
	A mapping to a client metaclass or to a forwarder should have 
	resulted in the metaclass being identity clamped."
	"Sender must hold my session's accessProtect."

	classProxy := session lookupOop: classDelegate.
	metaclassProxy := session lookupOop: metaclassDelegate.
	
	[metaclassProxy gbxIsProxy | (metaclassProxy == NotCachedToken)
		& (classProxy gbxIsProxy | (classProxy == NotCachedToken))]
			gbxAssert

{ #category : #'private' }
GbxUnmappedClassReplicator >> replaceMetaclassProxyWith: clientMetaclassOrForwarder

	metaclassProxy ~~ NotCachedToken
		ifTrue: [metaclassProxy oneWayBecome: clientMetaclassOrForwarder]

{ #category : #'private' }
GbxUnmappedClassReplicator >> findOrGenerateClientClass
	"If there is a same-named client class that is both unmapped and compatible, answer it.
	If there is not a same-named client class, create one (if configuration allows) and answer it.
	Otherwise, answer nil."

	clientClass := self clientClassForServerClass.
	clientClass == nil
		ifTrue: [clientClass := self generateClientClass]
		ifFalse: [self checkCompatibilityWithServerClassOfClientClass].
	^clientClass

{ #category : #'private' }
GbxUnmappedClassReplicator >> replaceProxies

	| clientMetaclass |
	clientMetaclass := clientClass class.
	self replaceMetaclassProxyWith: clientMetaclass.
	self replaceClassProxy

{ #category : #'private' }
GbxUnmappedClassReplicator >> replicateClassAsForwarder
	"And answer the forwarder."
	"Sender must hold session's protect and cache semaphore."

	| forwarder |
	forwarder := GbsForwarder new.
	session unprotectedConnectNewClient: forwarder toServer: classDelegate.
	^forwarder

{ #category : #'private' }
GbxUnmappedClassReplicator >> forReplication: replication replicateStubFromReport: aReport
	"If we already have an object for the report oop, no action.
	Otherwise, create a stub from the given report (usually header-only)"
	"Sender must hold both session and clientMap semaphores."

	| oop clientObject |
	oop := aReport objId.
	clientObject := session lookupOop: oop.
	clientObject == NotCachedToken
		ifTrue: 
			[| newStub |
			newStub := self stubClass newFromReport: aReport.
			session unprotectedConnectNewClient: newStub toServer: oop]

{ #category : #'private' }
GbxUnmappedClassReplicator >> generateClientClass
	"Create and answer a client-side class with the same name and instvars as the given server class.
	Signal an error if client class generation is disabled."

	| aClientClass |
	session configuration generateClientClasses
		ifTrue: 
			[aClientClass := self
						createClientClassClassified: session class defaultDictionaryName]
		ifFalse: 
			[| cname |
			cname := classDelegate unsynchronizedPerformOnGsServer: #printString.
			^self gbsMessenger
				raise: GbsClassGenerationError
				message: 'No client class %1, class generation is disabled.'
				with: cname].
	^aClientClass

{ #category : #'private' }
GbxUnmappedClassReplicator >> replicateClassInstanceForReplication: replication
	"The report is for an instance of an unmapped class, not for the class itself."
	"Sender must hold my session's sessionProtect and the ClientMap's writeProtect semaphores."

	clientClass := self findOrGenerateClientClass.
	"If clientClass is nil at this point, an error has already been signaled."
	clientClass == nil
		ifFalse: 
			[| newReplicator |
			self shouldMapAsSkew
				ifTrue: [self mapSkewedReplicator]
				ifFalse: 
					["We are going to map class and metaclass, either or both of which might be stubs."
					clientClass instancesAreForwarders
						ifTrue: [self mapInstanceForwarderReplicator]
						ifFalse: [self unstubAndMap]].
			newReplicator := session replicatorForServerBehavior: serverClass
						ifAbsent: [self gbsMessenger error: 'No replicator found after class mapping'].
			newReplicator forReplication: replication
				replicateFromDeferredReport: report]

{ #category : #'private' }
GbxUnmappedClassReplicator >> getClassAndMetaclassInformation

	self getClassAndMetaclassInformationForBehavior: report objClass

{ #category : #'private' }
GbxUnmappedClassReplicator >> getClassAndMetaclassInformationForBehavior: behaviorOop

	| classMetaclassPair |
	classMetaclassPair := self classMetaclassPairForBehavior: behaviorOop.
	classMetaclassPair == nil
		ifTrue: [self gbsMessenger error: 'Server object is not a behavior.'].
	classDelegate := classMetaclassPair at: 1.
	metaclassDelegate := classMetaclassPair at: 2

{ #category : #'private' }
GbxUnmappedClassReplicator >> replicateClassItself
	"Report is for the class."
	"Sender must hold session's protect and cache semaphore."

	metaclassProxy zzzisForwarder
		ifTrue: [self replicateClassAsForwarder]
		ifFalse: 
			[clientClass := self findOrGenerateClientClass.
			"If clientClass is nil at this point, an error has already been signaled."
			clientClass == nil
				ifFalse: 
					[self clientClassIsAlreadyMapped
						ifTrue: [self replicateClassAsForwarder]
						ifFalse: [self unstubAndMap]]]

{ #category : #'private' }
GbxUnmappedClassReplicator >> checkCompatibilityWithServerClassOfClientClass

	(session doesClientClass: clientClass matchServerClass: classDelegate)
		ifFalse: 
			[self gbsMessenger
				raise: GbsClassGenerationError
				message: '%1 is incompatible between GemStone and Smalltalk'
				with: clientClass name.
			clientClass := nil]

{ #category : #'private' }
GbxUnmappedClassReplicator >> classMetaclassPairForBehavior: behaviorOop

	^session
		unsynchronizedEvaluateReturnResultBodyAsDelegates: '
| pair |
self isBehavior ifFalse: [^nil].
pair := Array new: 2.
self isMeta
	ifTrue: 
		[pair
			at: 1 put: self thisClass;
			at: 2 put: self]
	ifFalse: 
		[pair
			at: 1 put: self;
			at: 2 put: self class].
pair'
		context: (behaviorOop asGSObjectInSession: session)

{ #category : #'private' }
GbxUnmappedClassReplicator >> shouldMapAsSkew
	"Customer overrides this in custom subclass."

	^self clientClassIsAlreadyMapped

{ #category : #'private' }
GbxUnmappedClassReplicator >> infoForServerClass
	"Fetch and answer enough info about the give class (which must be a class, and not a metaclass) to create a matching client class."

	^session
		evaluate: '
| rawClassVars classVarNames result |
rawClassVars := self _classVars.
classVarNames := rawClassVars == nil
			ifTrue: [Array new]
			ifFalse: [rawClassVars keys asArray].
result := Array new.
result
	add: self name;
	add: self instVarNames;
	add: classVarNames;
	add: self _classInstVars;
	add: self format.
result'
		toLevel: 0
		context: classDelegate

{ #category : #'private' }
GbxUnmappedClassReplicator >> unmapClassProxy

	classProxy ~~ NotCachedToken
		ifTrue: [session disconnectClient: classProxy fromServer: classDelegate]

{ #category : #'flushing' }
GbxUnmappedClassReplicator class >> replicatorToFlush: anObject inSession: session
	"This could be customized in other replicator classes in GBS extensions. 
	Default behavior here is to map anObject's class and answer the resulting mapped replicator."

	| newReplicator |
	session gemStoneClassFor: anObject gbxBasicClass.
	newReplicator := session
				replicatorForClientBehavior: anObject gbxBasicClass
				ifAbsent: [self gbsMessenger error: 'Could not map the class of the object'].
	newReplicator isComplete
		ifFalse: 
			[session
				updateServerInstVarNamesForReplicators: (Array with: newReplicator)].
	^newReplicator

{ #category : #'instance creation' }
GbxUnmappedClassReplicator class >> forSession: session serverBehavior: aDelegate
	^self new initializeForSession:	session serverBehavior: aDelegate

