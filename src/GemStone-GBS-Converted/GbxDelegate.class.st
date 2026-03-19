Class {
	#name : 'GbxDelegate',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'public - implicit replication' }
GbxDelegate >> asLocalObjectToLevel: level replicationSpecSet: repSpecSet
[
	"This method returns a client object corresponding with the server object
	 represented by the receiver.  If we already have a replicate, answer that without 
	going to the server at all. If we do replicate from the server, the level argument 
	indicates how many levels of children of this object will be faulted in.  
	A level of 0 indicates no limit.  The repSpecSet argument is a symbol specifying 
	which replication spec set to use during replication.  
	The default, #replicationSpec, specifies to replicate objects
	 as specified by implementors of #replicationSpec."

	| sess |
	sess := self session.
	^self asLocalObjectToLevel: level
		replicationScheme: (sess
				sessionCritical: [sess replicationSchemeForSet: repSpecSet])
]

{ #category : 'public - implicit replication' }
GbxDelegate >> asGSObjectInSession: aGSSession 
[
	(self isForSession: aGSSession) ifTrue: [^self].
	self checkSession.
	aGSSession checkSession.
	self gbsMessenger error: 'Attempt to use a delegate from another session.'
]

{ #category : 'public - implicit replication' }
GbxDelegate >> asGSObject
[
	"I'm already a GSObject"

	^self
]

{ #category : 'public - implicit replication' }
GbxDelegate >> asLocalObjectToLevel: level
[
	"This method returns a Smalltalk object corresponding with the GemStone object
	 represented by the receiver.  The level argument indicates how many levels of
	 children of this object will be faulted in.  A level of 0 indicates no limit."

	^self asLocalObjectToLevel: level
		replicationScheme: self session currentReplicationScheme
]

{ #category : 'public - implicit replication' }
GbxDelegate >> asLocalObjectCopy
[
	"This method returns a Smalltalk object replicate of the GemStone object represented by the receiver.  The objects resulting from the replication are not resolved from or added to the transparency caches - they are a 'local deep copy'"
	
	GbsConfiguration deprecated:
			'Copy replication deprecated March, 2006. Send #asLocalObject instead'.
	^(self asLocalObjectToLevel: 0 replicationSpecSet: #transitiveClosureSpec)
		gbxDeepCopy
]

{ #category : 'public - implicit replication' }
GbxDelegate >> traverseToLevel: level replicationSpecSet: repSpecSet
[

	^self traverseToLevel: level
		replicationScheme: (self session replicationSchemeForSet: repSpecSet)
]

{ #category : 'public - implicit replication' }
GbxDelegate >> asGSObjectCopyInSession: aGSSession 
[
	GbsConfiguration 
		deprecated: 'Copy replication deprecated March, 2006. Use normal replication instead'.
	(self isForSession: aGSSession) ifTrue: [^self].
	self gbsMessenger error: 'Attempt to access a proxy from another session'
]

{ #category : 'public - implicit replication' }
GbxDelegate >> gbxCanBeStubbed
[
	"Private.  GBS.  Stubbing a delegate doesn't make much sense in any context. Raises an error."

	^false
]

{ #category : 'public - implicit replication' }
GbxDelegate >> asGSObjectCopy
[
	"I'm already a GSObject"

	self gbsMessenger 
		failure: 'Did you really intend to send #asGSObjectCopy to a delegate?'.
	^self
]

{ #category : 'public - implicit replication' }
GbxDelegate >> asLocalObjectUsingReplicationSpecSet: repSpecSet
[
	"This method returns a Smalltalk object corresponding with the GemStone object
	 represented by the receiver.  The repSpecSet argument is a symbol specifying
	 which replication spec set to use during replication.  The default, #replicationSpec,
	 specifies to replicate objects as specified by implementors of #replicationSpec."

	^self asLocalObjectToLevel: self session defaultGStoSTLevel
		replicationSpecSet: repSpecSet
]

{ #category : 'public - implicit replication' }
GbxDelegate >> asLocalObject
[
	"This method returns a Smalltalk object associated with the GemStone object represented by the receiver."

	self isSpecial ifTrue: [^self asLocalSpecial].
	"Fault to finite level, stubbing at leaf nodes, using caches"
	^self asLocalObjectToLevel: self session defaultGStoSTLevel
]

{ #category : 'GemStone extensions' }
GbxDelegate >> stubYourself
[
	"This is behavior intended for client objects only, so don't forward or
	 attempt to stub a stub; just answer the receiver."
]

{ #category : 'public - object management' }
GbxDelegate >> createObjectClass: oClass values: values
[
	
	^self subclassResponsibility
]

{ #category : 'public - object management' }
GbxDelegate >> releaseInGs
[
	"This method allows your application to inform GemStone the object
	 represented by the receiver can be released for garbage collection. This
	 method was named #release prior to 5.2 009 and was renamed to
	 avoid unintentional release in GS from VW windows."

	self gbsMessenger 
		error: 'GbxDelegate>>releaseInGs is not supported in this version of GBS.'
]

{ #category : 'public - object management' }
GbxDelegate >> createObjectClass: oClass values: values clusterBucket: clusterBucket permanent: aBool
[
	
	^self subclassResponsibility
]

{ #category : 'public - object management' }
GbxDelegate >> save
[
	"If you use a GemStone/S 64-bit server, you should not send #save. In the single-trip protocol used with 64-bit 
	servers, moving objects in and out of the export set is automatic, and should not be done manually."
	"For 32-bit servers: Marks the receiver to prevent it from being garabage collected (in a GemStone/S server).  This will prevent the Gem in-memory garbage collector from causing this object to disappear during a session because it is unreferenced.  Does NOT cause the object to be referenced from a permanent object, and thus there is no guarantee that it will be saved to disk at commit.

Note that results of new object creation methods, remotePerform, and remote execute calls are automatically saved.  Objects created using getFreeOops and create* calls are NOT automatically saved.  GbsSession>>releaseObjects: may be used to cancel the effect of this method, thus making objects eligible for garbage collection."

	self session saveObjects: (Array with: self)
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintClient: client in: aSession on: aStream 
[
	aStream
		cr;
		tab;
		tab.
	self 
		debugPrintBasicClient: client
		in: aSession
		on: aStream
]

{ #category : 'private - debug printing' }
GbxDelegate >> printDelegateOn: aStream 
[
	aStream cr.
	aStream
		nextPutAll: 'delegate = ';
		nextPut: ${;
		print: self identityHash;
		nextPut: $};
		space.
	[self printOn: aStream] on: Error
		do: 
			[:ex | 
			aStream
				nextPutAll: '<<';
				cr;
				nextPutAll: 'error occurred accessing object. ';
				cr;
				nextPutAll: ex description;
				cr;
				nextPutAll: 'originator: ';
				print: ex originator;
				nextPutAll: ' >>']
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintClientBlockedOn: aStream 
[
	aStream
		cr;
		tab;
		tab.
	self debugPrintBasicClientBlockedOn: aStream
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintDeadSessionOn: aStream 
[
	aStream nextPutAll: '#deadSessionFlag is '.
	self hasLiveSessionFlag not printOn: aStream
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugCurrentSessionPrintOn: aStream 
[
	| sess |
	sess := GBSM searchForCurrentSession.
	sess isNil 
		ifFalse: 
			[aStream
				cr;
				tab;
				nextPutAll: 'Session no longer logged in, using current session.'].
	^sess
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintFlagsOn: aStream
[

	aStream
		cr;
		tab;
		tab.
	self debugPrintIsStDirtyOn: aStream.
	aStream
		cr;
		tab;
		tab.
	self debugPrintDeadSessionOn: aStream.
	aStream
		cr;
		tab;
		tab.
	self debugPrintIsROMObjectOn: aStream.
	aStream
		cr;
		tab;
		tab.
	self debugPrintIsIdentityClampedOn: aStream.
	aStream
		cr;
		tab;
		tab.
	self debugPrintInExportOn: aStream
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintInExportOn: aStream 
[
	aStream nextPutAll: '#inExport is '.
	self inExport printOn: aStream
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintBasicClient: client in: aSession on: aStream
[

	client == nil
		ifTrue: [aStream nextPutAll: 'Not in session cache']
		ifFalse: 
			[client gbxBasicClass printOn: aStream.
			aStream nextPutAll: ' in session cache'.
			GbsConfiguration current autoMarkDirty
				ifTrue: 
					[aStream
						cr;
						tab;
						tab.
					"If not dirty and not detecting replicate changes then there is a problem."
					(self isStDirty not
						and: [client gbxIsProxy not & client gbxIsImmutable not])
							ifTrue: [aStream nextPut: $*].
					aStream nextPutAll: 'cached isImmutable is '.
					client gbxIsImmutable printOn: aStream]]
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintBasicClientBlockedOn: aStream 
[
	aStream nextPutAll: '*ServerToClient map access is blocked by another process'
]

{ #category : 'private - debug printing' }
GbxDelegate >> gbxDebugPrintOn: aStream
[
	"Symbols, specials, and metaclasses may not be in the GS export set."

	| loggedIn aSession client differs |
	self printOn: aStream.
	loggedIn := self debugPrintSessionInfoOn: aStream.
	self debugPrintFlagsOn: aStream.
	loggedIn ifTrue: [self debugPrintIsSpecialOn: aStream].
	loggedIn ifFalse: [^self].	"All further info requires a session."
	aSession := self noCheckSession.
	client := aSession sessionCritical: [aSession lookupOop: self]
				unlessBlocked: 
					[self debugPrintClientBlockedOn: aStream.
					nil].
	differs := self
				debugPrintCachedClientDiffers: client
				in: aSession
				on: aStream.
	differs ifTrue: [^self].
	self debugPrintClient: client in: aSession on: aStream
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintIsDefunctOn: aStream 
[
	aStream
		cr;
		tab;
		tab.
	self debugPrintBasicIsDefunctOn: aStream
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintBasicExportInfoClient: client loggedIn: loggedIn in: aSession on: aStream
[
	"Symbols, specials, and metaclasses may not be in the GS export set."

	(loggedIn and: [self isExported])
		ifTrue: [aStream nextPutAll: 'GS Exported']
		ifFalse: 
			[self isStDirty
				ifTrue: [aStream nextPutAll: 'Not GS exported (unflushed)']
				ifFalse: 
					[
					[self isSpecial
						ifTrue: [aStream nextPutAll: 'Not GS exported (special)']
						ifFalse: [aStream nextPutAll: 'Not GS exported']]
							on: Error
							do: [:ex | aStream nextPutAll: 'Unknown GS exported (' , ex description , ')']]].
	client ~~ nil ifTrue: [aStream nextPutAll: '; cached'] ifFalse: [aStream nextPutAll: '; uncached']
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintBasicIsDefunctOn: aStream
[
	"If the receiver is marked defunct but is has a logged-in session this method
	acquires the session's CInterface's accessProtect and GciCallProtect.
	If a debugging session is holding either of these for a long period, this
	method will block."

	| isDefunct |
	aStream nextPutAll: '#isGSDefunct is '.
	isDefunct := [self gbxIsGSDefunct printOn: aStream] on: Error
				do: 
					[:ex |
					aStream nextPutAll: 'unknown. Exception raised: ' , ex description.
					false].
	isDefunct
		ifTrue: 
			[self hasLiveSessionFlag
				ifFalse: [aStream nextPutAll: ' (invalid session id)']
				ifTrue: 
					[self sessionHasValidSessionId
						ifFalse: [aStream nextPutAll: ' (sessionQuickIsLoggedIn returned false)']
						ifTrue: [self exists ifFalse: [aStream nextPutAll: ' (doesn''t exist in gem)']]]]
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintIsIdentityClampedOn: aStream
[

	aStream nextPutAll: '#isIdentityClamped is '.
	self isIdentityClamped printOn: aStream
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintIsROMObjectOn: aStream 
[
	aStream nextPutAll: '#isROMObject is '.
	self isReadOnlyObject printOn: aStream
]

{ #category : 'private - debug printing' }
GbxDelegate >> gbxPrintClientOn: aStream
[

	| sess client |
	
	[(aStream canQueryServerSession: self noCheckSession)
		ifTrue: 
			[sess := self noCheckSession.
			client := sess sessionCritical: [sess serverMap clientAtOop: self]
						unlessBlocked: [nil].
			client isNil ifFalse: [GbsStackDumper printClient: client on: aStream]]
		ifFalse: 
			[aStream cr.
			aStream printUnknownClientHeader.
			aStream nextPutAll: '<<unavailable>>']]
			on: Error
			do: 
				[:ex |
				aStream cr.
				aStream printUnknownClientHeader.
				aStream
					nextPutAll: '<<error occurred accessing object>> ' , ex messageText]
]

{ #category : 'private - debug printing' }
GbxDelegate >> gbxPrintServerOn: aStream
[

	aStream cr.
	aStream nextPutAll: 'server = '.
	
	[(aStream canQueryServerSession: self noCheckSession)
		ifTrue: 
			[aStream
				nextPut: ${;
				print: (self unsynchronizedPerform: #identityHash) asLocalObject;
				nextPut: $};
				space;
				nextPutAll: (self unsynchronizedPerform: 'printString') asLocalObject]
		ifFalse: [aStream nextPutAll: '<<unavailable>>']]
			on: Error
			do: 
				[:ex |
				aStream nextPutAll: '<<error occurred accessing object>>' , ex messageText]
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintBasicIsSpecialOn: aStream
[

	| isSpecial |
	aStream nextPutAll: '#isSpecial is '.
	isSpecial := self isSpecial.
	isSpecial printOn: aStream.
	isSpecial
		ifTrue: 
			[| session |
			session := self session.
			aStream nextPutAll: ' -- '.
			session
				ifNil: [aStream nextPutAll: '<dead session>']
				ifNotNil: 
					[session critical: [self asLocalSpecial printOn: aStream]
						unlessBlocked: [aStream nextPutAll: '<blocked session>']]]
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintIsSpecialOn: aStream 
[
	aStream
		cr;
		tab;
		tab.
	self debugPrintBasicIsSpecialOn: aStream
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintIsStDirtyOn: aStream 
[
	aStream nextPutAll: '#isStDirty is '.
	self isStDirty printOn: aStream
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintBasicSessionInfoOn: aStream 
[
	"Print my session and whether or not it's logged in to aStream.
	Answer whether or not my session is logged in."

	| sess status |
	aStream nextPutAll: 'sessionId: '.
	self sessionId printOn: aStream.
	sess := self noCheckSession.
	status := sess isNil 
				ifTrue: ['(logged out)']
				ifFalse: 
					[sess hasValidSessionId 
						ifTrue: ['(believed logged in)']
						ifFalse: ['(logged out)']].
	aStream
		tab;
		nextPutAll: status.
	^status = '(believed logged in)'
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintCachedClientDiffers: client in: aSession on: aStream
[
	
	^client ~~ nil
		ifTrue:
			[| clientDelegate |
			aStream
				cr;
				tab;
				tab.
			clientDelegate := client gbxDelegate.
			(clientDelegate forSession: aSession) == self
				ifTrue:
					[aStream nextPutAll: 'Identical to StToGs cache value'.
					false]
				ifFalse:
					[client == NotCachedToken
						ifTrue: [aStream nextPutAll: 'Client is not in Client Map']
						ifFalse:
							[aStream nextPutAll: '*Differs from Client Map value: '.
							clientDelegate gbxDebugPrintOn: aStream].
					true]]
		ifFalse: [true]
]

{ #category : 'private - debug printing' }
GbxDelegate >> debugPrintSessionInfoOn: aStream 
[
	aStream
		cr;
		tab;
		tab.
	^self debugPrintBasicSessionInfoOn: aStream
]

{ #category : 'private - implicit replication' }
GbxDelegate >> asLocalObjectToLevel: level replicationScheme: scheme
[
	"This method returns a client object corresponding with the server object
	 represented by the receiver.  If we already have a replicate, answer that without 
	going to the server at all. If we do replicate from the server, the level argument 
	indicates how many levels of children of this object will be faulted in.  
	A level of 0 indicates no limit.  The replicationScheme argument specified
	which replication scheme to use during replication.  
	The default scheme has a selector of #replicationSpec and specifies to replicate objects
	 as specified by implementors of #replicationSpec."

	| sess mustTraverse localObj |
	sess := self session.
	localObj := sess
				sessionCritical: [sess clientObjForDelegate: self otherwise: NotCachedToken].
	mustTraverse := localObj == NotCachedToken or: [localObj zzzisStub].
	mustTraverse
		ifTrue: [localObj := self traverseToLevel: level replicationScheme: scheme].
	^localObj
]

{ #category : 'private - implicit replication' }
GbxDelegate >> traverseToLevel: level replicationScheme: scheme
[

	| serverTraversal |
	serverTraversal := self session newServerTraversal.
	serverTraversal
		rootDelegate: self;
		replicationLevel: level;
		replicationScheme: scheme.
	^serverTraversal execute
]

{ #category : 'private - class behavior' }
GbxDelegate >> compile: aString classified: aProtocol
[
	"Private.  Return nil if no compile error; otherwise a two element array containing the error text and
	the index into the source code at which the error occurred."

	| source errors error errorText errorIndex mySession |
	mySession := self session.
	source := aString isGSObject
				ifTrue: [aString asLocalObject]
				ifFalse: [aString asString gbxLfsOnly].
	source last = Character lf
		ifFalse: [source := source , (String with: Character lf)].
	errors := mySession
				evaluateBlock: '
					[:source :dicts :protocol | 
					[self compileMethod: source
						dictionaries: dicts
						category: protocol
						environmentId: 0.
					#success]
						on: CompileError
						do: [:ex | ex errorDetails]]'
				withArguments: (Array
						with: source
						with: mySession symbolListProxy
						with: aProtocol)
				context: self.
	errors == #success ifTrue: [^nil].
	error := errors at: 1.
	errorText := error at: 3.
	errorIndex := error at: 2.
	^Array with: errorText with: errorIndex
]

{ #category : 'private - class behavior' }
GbxDelegate >> versionDescription
[
	"Private.  Send this message when the receiver represents a GemStone class.  The
	 result is classname[vernum] (for example, X[2])"

	^self session 
		unsynchronizedEvaluate: 'self name, ''['', (self classHistory indexOf: self) printString, '']'''
		context: self
]

{ #category : 'private - class behavior' }
GbxDelegate >> compileInSmalltalkMethodAt: aSelector warn: warnBool fixErrors: fixBool
[
	"GBS Private.  Attempt to compile the GemStone source code for aSelector in the receiver in the corresponding Smalltalk class.
	 If fixBool is true, the user will be prompted with a window for fixing compiler errors.
	 If false, compilation errors will be logged to the transcript.
	 The receiver must represent a GemStone Behavior.
	 Answer a Boolean indicating whether the attempt was successful."

	| source category stClass |
	stClass := self asLocalObject.
	(warnBool and: 
			[(stClass includesSelector: aSelector) and: 
					[(self gbsMessenger
						confirm: 'Overwrite Smalltalk method %1>>%2?'
						with: stClass
						with: aSelector) not]])
		ifTrue: [^false].
	source := self performOnGsServer: #sourceCodeAt:
				withArguments: (Array with: aSelector).
	category := self performOnGsServer: #_categoryOfSelector:
				withArguments: (Array with: aSelector).
	stClass compile: source classified: category.
	^true
]

{ #category : 'private - class behavior' }
GbxDelegate >> remoteInheritsFrom: otherClassDelegate
[
	"Private.  Returns true if the receiver is a GemStone class that contains aGSClass in its superclass chain.
	Returns false for any other objects."

	^self session
		evaluateBlock: '[:myClass :otherClass | 
			myClass isBehavior
				and: [otherClass isBehavior and: [myClass inheritsFrom: otherClass]]]'
		with: self
		with: otherClassDelegate
		context: nil
]

{ #category : 'private - converting' }
GbxDelegate >> asKernelPomOop
[
	"GBS private"

	^GbxKernelPomOop oopNumber: (self session oopNumberForOop: self oopValue)
]

{ #category : 'public - forwarder access' }
GbxDelegate >> asForwarder
[
	"GBS. If there is a mapped client object for the server object 
	I represent, answer the result of sending #asForwarder to it.
	Otherwise, create a forwarder to the server object, map it, and answer it."

	| fwdr cached mySession |
	mySession := self session.
	mySession sessionCritical: 
			[cached := mySession clientObjForDelegate: self otherwise: NotCachedToken.
			cached == NotCachedToken
				ifTrue: 
					[fwdr := GbsForwarder new.
					mySession privateConnectNewClient: fwdr toServer: self]].
	^cached == NotCachedToken ifTrue: [fwdr] ifFalse: [cached asForwarder]
]

{ #category : 'public - forwarder access' }
GbxDelegate >> asUncachedForwarder
[

	GbsConfiguration
		deprecated: 'GbxDelegate>>asUncachedForwarder deprecated March, 2011. Use GbxDelegate>>gbsAsUncachedForwarder instead'.
	^self gbsAsUncachedForwarder
]

{ #category : 'public - forwarder access' }
GbxDelegate >> gbsAsUncachedForwarder
[
	"GBS. If there is a mapped client object for the server object 
	I represent, answer the result of sending #asUncachedForwarder to it.
	Otherwise, create a forwarder to the server object and answer it.
	The new forwarder is not mapped to me."

	| cached mySession |
	mySession := self session.
	^mySession sessionCritical: 
			[cached := mySession clientObjForDelegate: self otherwise: NotCachedToken.
			cached == NotCachedToken
				ifTrue: 
					[| fwdr |
					fwdr := GbsForwarder new.
					mySession cacheCritical: [GBSM atST: fwdr putGS: self].
					fwdr]
				ifFalse: [cached gbsAsUncachedForwarder]]
]

{ #category : 'private' }
GbxDelegate >> serverInterfaceDo: aBlock 
[
	^self session serverInterfaceDo: aBlock
]

{ #category : 'private' }
GbxDelegate >> validateSessionForProxy: aProxy 
[
	"Private.  Raise an error if there are any obvious problems with
	 the proxy for the receiver delegate."

	| error result |
	result := [self session] on: GbsError hostErrorSignal
				do: [:ex | error := ex].
	^error isNil 
		ifTrue: [result]
		ifFalse: 
			["Turn on stub or forwarder debugging and reraise the exception"

			aProxy gbxBasicClass debugWhile: [self session]]
]

{ #category : 'private' }
GbxDelegate >> fetch: max OOPsAtDebug: startIndex
[
	"Fetch the OOPs of one or more instance variables (named or unnamed) of an object"
	"Do NOT throw an error if the object is not pointers or NSC"

	^self session
		unsynchronizedEvaluateBlockReturnResultBodyAsDelegates: '
			[:max :startIndex |
			| endIndex result resultIndex |
			self class isBytesOrSpecial
				ifTrue: 
					[^self class printString].
			endIndex := startIndex + max - 1 min: self _primitiveSize.
			result := Array new: (endIndex - startIndex + 1 max: 0).
			resultIndex := 1.
			startIndex to: endIndex
				do: 
					[:sourceIndex |
					result at: resultIndex put: (self _primitiveAt: sourceIndex).
					resultIndex := resultIndex + 1].
			result]'
		with: max
		with: startIndex
		context: self
]

{ #category : 'private' }
GbxDelegate >> sessionIsLoggedIn
[
	"Private"

	| sess |
	sess := self noCheckSession.
	^sess notNil and: [sess isLoggedIn]
]

{ #category : 'private' }
GbxDelegate >> flags
[
	^self basicAt: 2
]

{ #category : 'private' }
GbxDelegate >> markStDirty: clientObject
[
	"Private.  
	clientObject must be my associated client object. Passing this object in is not a clean design,
	but saves a lookup in the clientMap.
	
	 Flag this Smalltalk/GemStone object relationship as being
	 dirty in the client (the Smalltalk state is more current than the
	 GemStone state).  
	If the server object is identity clamped, the client object is either a forwarder or the server 
	object is a client forwarder.
	In the case of a forwarder we'll never get here, in the case of a client forwarder we do not
	want to flush the state to the server (there's no server state to update) so do not mark it dirty."

	((self isSpecial or: [self isIdentityClamped]) or: [self isStDirty])
		ifTrue: 
			["Ignore"
			^nil].
	"sessionCritical to prevent concurrent modification of the dirty pool."
	^self session sessionCritical: 
			[self isStDirty ifTrue: [^nil].	"Another thread might have marked it dirty while we were waiting for the semaphore."
			self setDirtyBit.
			self session addToDirtyPool: clientObject forDelegate: self]
]

{ #category : 'private' }
GbxDelegate >> gbxStoreInTraversal: storeTraversal 
[
	"Private.  Generate an error if this is not a delegate for storeTraversal's session."

	(self isForSession: storeTraversal session) 
		ifFalse: 
			[self checkSession.
			self gbsMessenger 
				error: 'Attempt to store a reference to a delegate into another session.']
]

{ #category : 'private' }
GbxDelegate >> asLocalSpecial
[
	"Private.  If the receiver represents a GemStone special object (based on oop encoding),
	 return the local equivalent special object.  Otherwise, return NotCachedToken"

	| sess |
	sess := self session.
	^sess sessionCritical: [sess localSpecialFromOop: self]
]

{ #category : 'private' }
GbxDelegate >> remoteInstance
[
	"Private to GBS. Must be sent to a delegate for a server metaclass.
	Answer a delegate for the class that is the sole instance of that metaclass."
	"Do this carefully, since it is used during class connection.
	So, use unsynched execution, and answer the class as an integer oop to avoid trying to map the class."

	| sess classOop |
	sess := self session.
	classOop := sess unsynchronizedEvaluate: 'self thisClass asOop'
				context: self.
	^GbxDelegate oopValue: classOop session: sess
]

{ #category : 'private' }
GbxDelegate >> isSpecial
[
	"Examples of special objects are nil, true, false, char, etc.;
	 they don't need to be in the GS export set."

	^self session isSpecialOop: self
]

{ #category : 'private' }
GbxDelegate >> at: anything 
[
	self shouldNotImplement
]

{ #category : 'private' }
GbxDelegate >> at: anything put: something 
[
	self shouldNotImplement
]

{ #category : 'private' }
GbxDelegate >> fetch: count OOPsAt: sourceOffset into: target startingAt: targetOffset 
[
	"Using a limited buffer, fetch count oops from the receiver and place them in the targetOffset of target.  This is method is private, as it doesn't perform any error checking.  The sender must know what it is doing."

	| remaining thisSourceOffset thisTargetOffset thisPassSize thisPass |
	remaining := count.
	thisSourceOffset := sourceOffset.
	thisTargetOffset := targetOffset.
	self gbxFixMe.	"Get rid of the 4"
	
	[thisPassSize := remaining 
				min: GbsConfiguration current traversalBufferSize // 4.
	thisPass := self fetch: thisPassSize OOPsAt: thisSourceOffset.
	target 
		replaceFrom: thisTargetOffset
		to: thisTargetOffset + thisPassSize - 1
		with: thisPass.
	remaining := remaining - thisPassSize.
	thisSourceOffset := thisSourceOffset + thisPassSize.
	thisTargetOffset := thisTargetOffset + thisPassSize.
	remaining > 0] 
			whileTrue: [].
	^target
]

{ #category : 'private' }
GbxDelegate >> sessionId: anInteger 
[
	"if an error occurs at login, the error will come back with delegates of sessionId  0. 
	We need to go in and massage the delegates of the GbsError in this case"

	self basicAt: 1 put: anInteger.
	^self
]

{ #category : 'private' }
GbxDelegate >> forSession: aSession
[

	"Private.  Return self if I am a remote object for aSession.  Otherwise, return nil"

	(self isForSession: aSession)
		ifTrue: [ ^self ]
		ifFalse: [ ^nil ]
]

{ #category : 'private' }
GbxDelegate >> fetchImplementation
[
	"Private.  This returns the implementation of the receiver (0 = pointer, 1 = byte, 2 = NSC, 3 = special)"
	"Use the methods isPointer, isByte, isNSC, and isSpecial"

	^(self session unsynchronizedEvaluate: 'self class implementationFormat' context: self) \\ 4
]

{ #category : 'private' }
GbxDelegate >> gbxDelegate
[
	"Private.  Answer nil or a client-object, found cached for any
	 session, representing a remote-object that is the logical
	 equivalent to the receiver. Since a delegate is never a replicate,
	answer nil."

	self gbxFixMe.	"Remove this method once it's no longer raising regular errors."
	self error: 'Should not send gbxDelegate to Delegates'.
	^nil
]

{ #category : 'private' }
GbxDelegate >> notForSession: aSession
[

	"Private.  Return nil if I am a proxy for aSession, or for an invalid session.
	 Otherwise, return self"

	^(self isForSession: aSession)
		ifTrue: [ nil ]
		ifFalse: [
			self hasLiveSessionFlag
				ifTrue: [ self ]
				ifFalse: [ nil ]]
]

{ #category : 'private' }
GbxDelegate >> session: aGbsSession 
[
	self basicAt: 1 put: aGbsSession sessionId.
	^self
]

{ #category : 'private' }
GbxDelegate >> connectingDelegate: otherDelegate withClient: clientObj
[
	"Private. I'm already connected to clientObj. Now we're connecting clientObj to otherDelegate, which is not me.
	Answer the appropriate delegate or list to replace me in the cache."
	"Sender must hold both otherDelegate's session's accessProtect and the clientMap's writeProtect."
	"If #createClientObject has mapped a class/metaclass pair, we can get here 
	to 'replace' ourself"

	| mySession |
	self == otherDelegate ifTrue: [^self].
	self hasLiveSessionFlag ifFalse: [^otherDelegate].
	mySession := self session.
	
	[otherDelegate session hasCriticalAccess
		and: [GbsSessionManager current hasCacheWriteCriticalAccess]]
			gbxAssertEquals: true
			message: 'Must hold both sessionProtect and stObjectCache accessProtect at this point.'.
	otherDelegate isReadOnlyObject: self isReadOnlyObject.
	^(otherDelegate isForSession: mySession)
		ifFalse: 
			["connecting to delegates from different sessions"
			clientObj gbxConnectingToMultipleSessions.
			GbxObjectList with: self with: otherDelegate]
		ifTrue: 
			["otherDelegate is attempting to supersede me -- there are no longer legitimate cases for this"
			self gbsMessenger
				error: 'GBS internal error: Delegate being superseded.
Existing delegate: %1
Client object: %2
Superseding delegate: %3'
				with: self gbxDebugPrintString
				with: clientObj gbxDebugPrintString
				with: otherDelegate gbxDebugPrintString]
]

{ #category : 'private' }
GbxDelegate >> sessionHasValidSessionId
[
	"Private. The danger of using this method is it trusts
	 the Smalltalk state of the sessionId.  If our actual
	 connection to the repository has been lost, the sessionId
	 instance variable might be a lie.  For a more reliable
	 answer, send #sessionIsLoggedIn."

	| sess |
	sess := self noCheckSession.
	^sess notNil and: [ sess hasValidSessionId ]
]

{ #category : 'private' }
GbxDelegate >> fetch: count bytesAt: sourceOffset into: target startingAt: targetOffset 
[
	"Using a limited buffer, fetch count bytes from the receiver and place them in the targetOffset of target.  This is method is private, as it doesn't perform any error checking.  The sender must know what it is doing."

	| remaining thisSourceOffset thisTargetOffset thisPassSize thisPass |
	remaining := count.
	thisSourceOffset := sourceOffset.
	thisTargetOffset := targetOffset.
	
	[thisPassSize := remaining min: SmallTraversalBufferSize.
	thisPass := self fetch: thisPassSize bytesAt: thisSourceOffset.
	target 
		replaceFrom: thisTargetOffset
		to: thisTargetOffset + thisPassSize - 1
		with: thisPass.
	remaining := remaining - thisPassSize.
	thisSourceOffset := thisSourceOffset + thisPassSize.
	thisTargetOffset := thisTargetOffset + thisPassSize.
	remaining > 0] 
			whileTrue: [].
	^target
]

{ #category : 'private' }
GbxDelegate >> stubbing
[
	"Sender must hold my session's sessionProtect."

	self session addToNoLongerReplicated: self
]

{ #category : 'private' }
GbxDelegate >> forAnySingleSession
[

	"Private.  The receiver satisfies this request.  Compare with GbxObjectList>>forAnyOrCurrentSessionForObject:."
	^self
]

{ #category : 'private' }
GbxDelegate >> markDirty
[
	"GbsObject's ought not to be marked dirty"

	^self gbsMessenger error: 'Delegates should not be marked dirty'
]

{ #category : 'private' }
GbxDelegate >> noCheckSession
[
	"Returns either this Delegate's session (if it is alive), or nil "

	^self hasLiveSessionFlag 
		ifTrue: [GBSM sessionWithId: self sessionId]
		ifFalse: [nil]
]

{ #category : 'private' }
GbxDelegate >> doesNotUnderstand: aMessage 
[
	"This overrides Object's behavior by checking for selectors that begin with 'gs'.
	If this is the case, the 'gs' part is stripped from the selector and it is sent to
	the GemStone for remote execution"

	| sel newSel |
	sel := aMessage selector.
	(sel size > 2 and: [$g == (sel at: 1) and: [$s == (sel at: 2)]]) 
		ifTrue: 
			[GbsConfiguration 
				deprecated: 'gs prefixing deprecated August, 2005. Use forwarders instead'.
			newSel := sel asString copyFrom: 3 to: sel size.
			^self remotePerform: newSel withArgs: aMessage arguments]
		ifFalse: 
			[(sel size > 4 and: 
					[$p == (sel at: 1) 
						and: [$r == (sel at: 2) and: [$i == (sel at: 3) and: [$v == (sel at: 4)]]]]) 
				ifTrue: 
					[GbsConfiguration 
						deprecated: 'priv prefixing deprecated August, 2005. Use _ prefixed methods instead'.
					newSel := '_' , (sel asString copyFrom: 5 to: sel size).
					^self remotePerform: newSel withArgs: aMessage arguments].
			^super doesNotUnderstand: aMessage]
]

{ #category : 'private' }
GbxDelegate >> checkSession
[
	"If the session from which this GbsObject was derived is no longer
	 logged in, raise an error which attributes a cause of death, if available."

	self hasLiveSessionFlag 
		ifFalse: 
			[GbsError 
				raiseBadSessionIdFor: (GBSM disconnectedSessionWithId: self sessionId)]
]

{ #category : 'public - remote execution' }
GbxDelegate >> performOnGsServer: selector withArguments: args
[
	"Perform the given selector on the server, and replicate the result."

	| session messageSend |
	session := self session.
	messageSend := session newMessageSend.
	^messageSend
		selector: selector;
		arguments: args;
		receiver: self;
		shouldReplicateResult: true;
		execute
]

{ #category : 'public - remote execution' }
GbxDelegate >> remotePerform: selector withArgs: args
[
	"Send aSelector with arguments to the GemStone object the receiver represents and return the resulting delegate.  Convert arguments to delegates if necessary."

	| session messageSend |
	self gbsMessenger
		statusTag: #remotePerform
		message: '(s%1) %2 remotePerform: %3 withArgs: %4'
		with: self sessionId
		with: self
		with: selector
		with: args.
	session := self session.
	messageSend := session newMessageSend.
	^messageSend
		selector: selector;
		arguments: args;
		receiver: self;
		shouldReplicateResult: false;
		execute
]

{ #category : 'public - remote execution' }
GbxDelegate >> remotePerform: aSelector with: anArg with: argTwo with: argThree 
[
	"Send aSelector with arguments to the GemStone object the receiver represents and return the resulting GemStoneObject."

	^self remotePerform: aSelector
		withArgs: (Array 
				with: anArg
				with: argTwo
				with: argThree)
]

{ #category : 'public - remote execution' }
GbxDelegate >> remotePerform: aSelector with: anArg with: argTwo 
[
	"Send aSelector with arguments to the GemStone object the receiver represents and return the resulting GemStoneObject."

	^self remotePerform: aSelector withArgs: (Array with: anArg with: argTwo)
]

{ #category : 'public - remote execution' }
GbxDelegate >> remotePerform: aSelector with: anArg 
[
	"Send aSelector with anArg to the GemStone object the receiver represents and return the resulting GemStoneObject."

	^self remotePerform: aSelector withArgs: (Array with: anArg)
]

{ #category : 'public - remote execution' }
GbxDelegate >> remotePerform: aSelector 
[
	"Send aSelector to the GemStone object the receiver represents and return the resulting GemStoneObject."

	^self remotePerform: aSelector withArgs: #()
]

{ #category : 'public - nsc access' }
GbxDelegate >> addOOPs: gemStoneObjects 
[
	"This adds the given collection of OOPs to the NSC I represent.  Returns self."

	self gbsMessenger 
		error: 'GbxDelegate>>#addOOPs: is not supported in this version of GBS.'
]

{ #category : 'public - nsc access' }
GbxDelegate >> removeOOP: aGSObject 
[
	"This removes the given GemStone Object from the NSC that I represent. Returns false if aGSObject was not present in the receiver, true otherwise."

	self gbsMessenger 
		error: 'GbxDelegate>>#removeOOP: not supported in this version of GBS'
]

{ #category : 'public - nsc access' }
GbxDelegate >> addOOP: aDelegate 
[
	"This adds the given GemStone Object to the NSC that I represent.  Returns self."

	self gbsMessenger 
		error: 'GbxDelegate>>#addOOP: is not supported in this version of GBS.'
]

{ #category : 'public - nsc access' }
GbxDelegate >> removeOOPs: gsObjects 
[
	"This removes the collection of GbsObjects from the NSC that I represent. True is returned if all were present, false if any one element of gsObjects was not present in the receiver (note that elements which were present are removed)."

	self gbsMessenger 
		error: 'GbxDelegate>>#removeOOPs: not supported in this version of GBS'.
]

{ #category : 'testing' }
GbxDelegate >> gbxCanBeArgForUnsynchronizedOperationInSession: session
[
	" Note that we do allow dirty delegates, while we do not allow dirty client objects.
	The rationale is that if the programmer passes in a delegate to an unsynchronized operation,
	we assume their intent is to get the server's state of the object. If they pass in a client object,
	we assume that their intent is to get that client object's state, which they will not get if it's dirty."

	^self isForSession: session
]

{ #category : 'public - comparing' }
GbxDelegate >> hash
[
	"We could compute a reasonable hash more quickly, 
	but we don't store Delegates in hashed collections very often."

	"This hash function must be compatible with GbxKernelOop>>hash"

	^self noCheckSession hashForDelegate: self
]

{ #category : 'public - comparing' }
GbxDelegate >> = anObject 
[
	"If two Delegates represent the same GemStone object, they are equal"

	self == anObject ifTrue: [^true].
	anObject isGSObject ifFalse: [^false].
	^anObject equalsDelegate: self
]

{ #category : 'private - testing' }
GbxDelegate >> isEightByte
[
	^false
]

{ #category : 'private - testing' }
GbxDelegate >> serverCanAcceptClassChanges
[
	"The 64-bit 3.2 server (and later) can change the class of a server object through store traversal."

	self subclassResponsibility
]

{ #category : 'private - testing' }
GbxDelegate >> gbxIsDelegate
[
	"private"

	^true
]

{ #category : 'private - testing' }
GbxDelegate >> isGcProtected
[
	"Private. Answer true if the server object is in the session's export set or referenced set
	so it cannot be garbage collected. Answer false if it's not or we can't tell."

	| sess |
	self isExported ifTrue: [^true].
	sess := self session.
	sess isSingleTrip ifFalse: [^false].
	self isSpecial ifTrue: [^false].
	self exists ifFalse: [^false].
	^sess
		critical: 
			[sess unsynchronizedEvaluate: 'System _testIf: self isIn: 24' context: self]
		unlessBlocked: [false]
		onError: [:ex | false]
]

{ #category : 'public - object protocol' }
GbxDelegate >> printOn: aStream 
[
	aStream
		nextPutAll: 'a ';
		nextPutAll: self class name.
	aStream nextPutAll: ' sess: '.
	(self basicAt: 1) printOn: aStream.
	aStream nextPutAll: ' flags: '.
	(self basicAt: 2) printOn: aStream.
	aStream nextPutAll: ' {16r'.
	self oopValue printOn: aStream base: 16.
	aStream nextPut: $}
]

{ #category : 'public - fetching' }
GbxDelegate >> fetchVaryingOOPAt: index 
[
	"Return the GbsObject representing the object at index in the varying portion of the receiver.  Operates on both NSCs and indexable objects.  For NSCs, the result for a given index may change after modification of the receiver."

	^(self fetch: 1 varyingOOPsAt: index) at: 1
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: num namedOOPsAt: index onto: aStream 
[
	"Appends num or less GemStoneObjects fetched from the receiver starting at the specified index using structural access.  The index of the first element is 1."

	aStream nextPutAll: (self fetch: num namedOOPsAt: index).
	^index + num
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: max varyingOOPsAt: startIndex
[
	"Fetches up to 'max' varying instance variables starting at varying offset 'index'.  Operates on both Nscs and indexable objects.   For Nscs, the result for a given value of 'index' may change after a modification of the receiver."

	^self session
		unsynchronizedEvaluateBlockReturnResultBodyAsDelegates: '
					[:max :givenIndex | 
					| namedSize startIndex endIndex result resultIndex |
					namedSize := self class instSize.
					startIndex := givenIndex + namedSize.
					endIndex := startIndex + max - 1 min: self _primitiveSize.
					result := Array new: (endIndex - startIndex + 1 max: 0).
					resultIndex := 1.
					startIndex to: endIndex
						do: 
							[:sourceIndex | 
							result at: resultIndex put: (self _primitiveAt: sourceIndex).
							resultIndex := resultIndex + 1].
					result]'
		with: max
		with: startIndex
		context: self
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: max OOPsAt: startIndex
[
	"Fetch the OOPs of one or more instance variables (named or unnamed) of an object"
	"Throw an error if the object is not pointers or NSC"

	^self session
		unsynchronizedEvaluateBlockReturnResultBodyAsDelegates: '
			[:max :startIndex |
			| endIndex result resultIndex |
			self class isBytesOrSpecial
				ifTrue: 
					[^System
						signal: (ErrorSymbols at: #objErrNotOopOrNsc)
						args: (Array with: self)
						signalDictionary: GemStoneError].
			endIndex := startIndex + max - 1 min: self _primitiveSize.
			result := Array new: (endIndex - startIndex + 1 max: 0).
			resultIndex := 1.
			startIndex to: endIndex
				do: 
					[:sourceIndex |
					result at: resultIndex put: (self _primitiveAt: sourceIndex).
					resultIndex := resultIndex + 1].
			result]'
		with: max
		with: startIndex
		context: self
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: max varyingOOPsAt: index onto: aStream 
[
	aStream nextPutAll: (self fetch: max varyingOOPsAt: index).
	^index + max
]

{ #category : 'public - fetching' }
GbxDelegate >> fetchByteAt: index 
[
	"Returns the byte at index in the receiver as a SmallInteger"

	^(self fetch: 1 bytesAt: index) at: 1
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: max OOPsAt: index onto: aStream 
[
	aStream nextPutAll: (self fetch: max OOPsAt: index).
	^index + max
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: max bytesAt: startIndex
[
	"Fetch up to max bytes of the receiver from GemStone starting at index, returning a ByteArray."

	^self session
		unsynchronizedEvaluateBlock: '
			[:max :startIndex | 
			| endIndex result resultIndex |
			endIndex := startIndex + max - 1 min: self _primitiveSize.
			result := ByteArray new: (endIndex - startIndex + 1 max: 0).
			resultIndex := 1.
			startIndex to: endIndex
				do: 
					[:sourceIndex | 
					result at: resultIndex put: (self _primitiveAt: sourceIndex).
					resultIndex := resultIndex + 1].
			result]'
		with: max
		with: startIndex
		context: self
]

{ #category : 'public - fetching' }
GbxDelegate >> fetchCharAt: index 
[
	"This pulls one character of the receiver up from the GemStone"

	self gbxFixMe.	"There is no test coverage for this message.."
	^(self fetch: 1 charsAt: index) at: 1
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: max bytesAt: index onto: aStream 
[
	"Fetch up to max bytes of the receiver from GemStone starting at index, appending to aStream."

	aStream nextPutAll: (self fetch: max bytesAt: index).
	^index + max
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: max charsAt: index 
[
	"Fetch up to max bytes of the receiver from GemStone starting at index, returning a ByteString."

	^(self fetch: max bytesAt: index) gbxChangeClassTo: '' class
]

{ #category : 'public - fetching' }
GbxDelegate >> fetchIdxOOPAt: index 
[
	"Pre-3.2 functionality now provided by more general fetchVaryingOOPAt:"

	^self fetchVaryingOOPAt: index
]

{ #category : 'public - fetching' }
GbxDelegate >> fetchNamedOOPAt: index 
[
	"Returns the GemStoneObject fetched from the named instance variable portion of the receiver at the specified index using structural access.  The index of the first instance variable is 1."

	self gbsMessenger 
		error: '#fetch:namedOOPAt: is not supported in this version of GBS.'
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: max charsAt: index onto: aStream 
[
	"Fetch up to max bytes of the receiver from GemStone starting at index, appending to aStream."

	aStream nextPutAll: (self fetch: max charsAt: index).
	^index + max
]

{ #category : 'public - fetching' }
GbxDelegate >> fetchOOPAt: index 
[
	"Returns the single element fetched from the receiver (a GemStoneObject representing a GemStone pointer object or NSC) at the specified index using structural access.  The index of the first element is 1."

	| resultArray |
	resultArray := self fetch: 1 OOPsAt: index.
	resultArray isEmpty 
		ifTrue: 
			["this error simulates the server error raised by the primitive call used in prior versions of GBS"

			^GbsObjErrBadOffset 
				raiseErrorString: 'An object was indexed using structural access with the index ' 
						, index printString , ' that was out of range. '].
	^resultArray at: 1
]

{ #category : 'public - fetching' }
GbxDelegate >> fetchObjInfoStartingAt: firstOffset maxBytes: maxBytes 
[
	^self gbsMessenger 
		error: 'GbxDelegate>>#fetchObjInfoStartingAt:maxBytes: is not supported in this version of GBS'
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: max idxOOPsAt: index 
[
	"As of 3.2, this functionality is defined in terms of the more general fetch:varyingOOPsAt:"

	^self fetch: max varyingOOPsAt: index
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: max idxOOPsAt: index onto: aStream 
[
	aStream nextPutAll: (self fetch: max varyingOOPsAt: index).
	^index + max
]

{ #category : 'public - fetching' }
GbxDelegate >> fetchObjectInfo
[
	^self gbsMessenger 
		error: 'GbxDelegate>>#fetchObjectInfo is not supported in this version of GBS'
]

{ #category : 'public - fetching' }
GbxDelegate >> fetch: num namedOOPsAt: index 
[
	"Returns an array of num or less GemStoneObjects fetched from the receiver starting at the specified index using structural access.  The index of the first element is 1."

	self gbsMessenger 
		error: '#fetch:namedOOPsAt: is not supported in this version of GBS.'
]

{ #category : 'private - oop access' }
GbxDelegate >> oopByteAt: byteOffset put: byteValue 
[
	self subclassResponsibility
]

{ #category : 'private - oop access' }
GbxDelegate >> oopByteAt: byteOffset 
[
	self subclassResponsibility
]

{ #category : 'private - oop access' }
GbxDelegate >> oopNumberLower3
[
	"Returns the SmallInteger representation of the 3 least significant bytes
	 of the oop number.  For 4 byte oops this is bytes 2-4 (all but the most 
	 significant byte).  For 8 byte oops, it's bytes 5-7 (byte 8 doesn't count
	 because it only contains flags).  This value is used as the key in the
	 hash dictionary that is the bottom tier of the gs-to-st cache."

	^self subclassResponsibility
]

{ #category : 'private - oop access' }
GbxDelegate >> oopValue: anInteger 
[
	"this assumes a new delegate is all 0's"

	| temp index |
	self gbxFixMe.	"Make the following line be an optional assertion check."
	self oopValue == 0 ifFalse: [self error: 'resetting a Delegate''s value'].
	temp := anInteger.
	index := self basicSize - 4.
	[temp ~~ 0] whileTrue: 
			[self oopByteAt: index put: (temp bitAnd: 16rFF).
			temp := temp bitShift: -8.
			index := index - 1].
	^self
]

{ #category : 'private - oop access' }
GbxDelegate >> oopNumberHighBytes
[
	"Returns the SmallInteger representation of the 1 or 2 most significant bytes
	 of the oop number (all but the lower three).  For 4 byte oops this is byte 1 (the most 
	 significant byte).  For 8 byte oops, it's bytes 3-4.  This value is used as an index in the
	top level of the serverMap."

	^self subclassResponsibility
]

{ #category : 'private - oop access' }
GbxDelegate >> oopShortAt: shortOffset
[
	"Return the unsigned 16-bit chunk of the oop at the given shortOffset, starting from the 
	 high order end.  For example, (aDelegate oopShortAt: 1) returns the most 
	 significant 16 bits of the receiver's oop."
	
	| byteOffset |
	byteOffset := shortOffset * 2 - 1.
	^((self oopByteAt: byteOffset) bitShift: 8)
		bitOr: (self oopByteAt: byteOffset + 1)
]

{ #category : 'private - oop access' }
GbxDelegate >> oopNumberAt: byteOffset 
[
	self subclassResponsibility
]

{ #category : 'private - oop access' }
GbxDelegate >> bytesPerOop
[
	^self class bytesPerOop
]

{ #category : 'private - execution' }
GbxDelegate >> unsynchronizedPerform: selector withArgs: args
[
	"Private to GBS.  Bypass the normal <remotePerform:> methods so as to avoid store traversals, etc.
	Does NOT maintain normal GBS state synchronization between client and server.
	Arguments can be client objects or delegates.
	Should not be used except to implement debugging tools and GBS internal operations that must
	avoid changing the environment.
	Limitations for proper operation: 
	* 	Any arguments will be copied using #copy before being replicated to the server. The sender must
		ensure that #copy is sufficient to avoid arguments referencing any existing replicates or 
		compiled literals. Delegate arguments are not copied.
	*	Any arguments must be of special classes or classes that are mapped initially on login by fast
		connectors, since instvar mapping is not done on unsynchronized* messages.
	*	Execution must not change the state of any server objects that might be replicated to the client,
		with the exception of explicitly-desired changes (such as accept in an inspector on a server 
		object).
	*	If the result object were replicated, the replication should never include any objects that are
		currently replicated."

	| session messageSend |
	self gbsMessenger
		statusTag: #unsynchronizedPerform
		message: '(s%1) %2 unsynchronizedPerform: %3 withArgs: %4'
		with: self sessionId
		with: self
		with: selector
		with: args.
	session := self session.
	messageSend := session newMessageSend.
	^messageSend
		selector: selector;
		arguments: args;
		receiver: self;
		shouldSynchronize: false;
		shouldReplicateResult: false;
		replicationScheme: GbxNullReplicationScheme new;
		stopForBreakpoints: false;
		execute
]

{ #category : 'private - execution' }
GbxDelegate >> unsynchronizedPerform: aSymbol with: arg1 
[
	"Private.  Bypass the normal <remotePerform:> methods so as to avoid store traversals, etc."

	^self unsynchronizedPerform: aSymbol withArgs: (Array with: arg1)
]

{ #category : 'private - execution' }
GbxDelegate >> unsynchronizedPerform: aSymbol
[
	"Private.  Bypass the normal <remotePerform:> methods so as to avoid store traversals, etc."

	^self unsynchronizedPerform: aSymbol withArgs: #()
]

{ #category : 'private - execution' }
GbxDelegate >> unsynchronizedPerform: aSymbol with: arg1 with: arg2 
[
	"Private.  Bypass the normal <remotePerform:> methods so as to avoid store traversals, etc."

	^self unsynchronizedPerform: aSymbol withArgs: (Array with: arg1 with: arg2)
]

{ #category : 'public - storing' }
GbxDelegate >> storeBytes: array at: index
[
	"Store the given array of bytes into this object."

	| sourceArray |
	sourceArray := array copy gbxChangeClassTo: ByteArray.
	self session
		unsynchronizedEvaluateBlock: '
			[:bytes :startIndex | 
			| endIndex sourceIndex |
			endIndex := startIndex + bytes size - 1.
			sourceIndex := 1.
			startIndex to: endIndex
				do: 
					[:destIndex | 
					self _primitiveAt: destIndex put: (bytes _primitiveAt: sourceIndex).
					sourceIndex := sourceIndex + 1].
			nil]'
		with: sourceArray
		with: index
		context: self
]

{ #category : 'public - storing' }
GbxDelegate >> storeBytes: arrayOrString at: index instanceOf: remoteClass 
[
	"Store the given arrayOrString of bytes into this object.  The remoteClass argument should be a proxy for the GemStone class of the receiver, or Onil.  This information is used to determine whether byte swapping is required for objects such as floats."

	^self gbsMessenger 
		error: 'GbxDelegate>>#storeBytes:at:instanceOf: is not supported in this version of GBS'
]

{ #category : 'public - storing' }
GbxDelegate >> storeChar: aChar at: index 
[
	"This method stores aChar into the GemStone object represented by the receiver.  This method may be used for either byte or character stores."

	self gbxFixMe.	"There is no test coverage for this message.."
	^self storeByte: aChar at: index
]

{ #category : 'public - storing' }
GbxDelegate >> storeChars: string at: index 
[
	"Store the given string into this object."

	^self storeBytes: string at: index
]

{ #category : 'public - storing' }
GbxDelegate >> storeIdxOOP: aGSObject at: index 
[
	"Store aGSObject at index in the indexable portion of the GemStone object represented by the receiver"

	^self gbsMessenger 
		error: 'GbxDelegate>>#storeIdxOOP:at: is not supported in this version of GBS'
]

{ #category : 'public - storing' }
GbxDelegate >> storeIdxOOPs: arrayOfGSObjects at: index 
[
	"Store arrayOfGSObjects starting at index into the GemStone object represented by the receiver"

	^self gbsMessenger 
		error: 'GbxDelegate>>#storeIdxOOPs:at: is not supported in this version of GBS'
]

{ #category : 'public - storing' }
GbxDelegate >> storeNamedOOP: aGSObject at: index 
[
	"Store aGSObject at index in the named instance variable portion of the receiver"

	^self gbsMessenger 
		error: 'GbxDelegate>>#storeNamedOOP:at: is not supported in this version of GBS'
]

{ #category : 'public - storing' }
GbxDelegate >> storeNamedOOPs: arrayOfGSObjects at: index 
[
	"Store arrayOfGSObjects starting at index into the named instance variable portion of the receiver"

	^self gbsMessenger 
		error: 'GbxDelegate>>#storeNamedOOPs:at: is not supported in this version of GBS'
]

{ #category : 'public - storing' }
GbxDelegate >> replaceOOPs: gsObjects 
[
	"Replace the contents of the GemStone object represented by the receiver with gsObjects, an Array of GbxDelegates.  Applies to named as well as varying instance variables (indexable or NSC).  Values supplied for private instance variables will be silently ignored and passed over."

	self gbsMessenger 
		error: '#replaceOOPs: is not supported in this version of GBS.'
]

{ #category : 'public - storing' }
GbxDelegate >> storeOOP: aGSObject at: index 
[
	"Store aGSObject at index in the GemStone object represented by the receiver"

	self session 
		unsynchronizedEvaluateBlock: '
			[:obj :index | 
			self _primitiveAt: index put: obj.
			nil]'
		withArguments: (Array with: aGSObject with: index)
		context: self
]

{ #category : 'public - storing' }
GbxDelegate >> replaceVaryingOOPs: gsObjects 
[
	"Replace the varying portion (indexable or NSC) of the GemStone object represented by the receiver with gsObjects, an Array of GbsObjects.  This does not affect any named instance variables."

	self gbsMessenger 
		error: '#replaceVaryingOOPs: is not supported in this version of GBS.'
]

{ #category : 'public - storing' }
GbxDelegate >> storeByte: aByte at: index 
[
	"This method stores aByte into the GemStone object represented by the receiver.  This method may be used for either byte or character stores."

	self storeBytes: (ByteArray with: aByte asInteger) at: index
]

{ #category : 'public - storing' }
GbxDelegate >> storeOOPs: arrayOfGSObjects at: index 
[
	"Store arrayOfGSObjects starting at index in the GemStone object represented by the receiver"

	^self gbsMessenger 
		error: 'GbxDelegate>>#storeBytes:at:instanceOf: is not supported in this version of GBS'
]

{ #category : 'private - flag masks' }
GbxDelegate >> dirtyMask
[
	^1
]

{ #category : 'private - flag masks' }
GbxDelegate >> deadSessionMask
[
	^4
]

{ #category : 'private - flag masks' }
GbxDelegate >> readOnlyMask
[
	^8
]

{ #category : 'private - flag masks' }
GbxDelegate >> bit2reservedForCustomerUse
[
	"Formerly, the skewMask. No longer used by the GBS product."
	^2
]

{ #category : 'private - flag masks' }
GbxDelegate >> inExportMask
[
	^32
]

{ #category : 'private - flag masks' }
GbxDelegate >> identityClampedMask
[
	^16
]

{ #category : 'private - remote execution' }
GbxDelegate >> unsynchronizedPerformOnGsServer: selector withArgs: args
[
	"Private to GBS. Very dangerous, must follow the rules:
	* No modifying server objects that might be replicated
	* Only replicate simple objects, either direction, whose classes are known to be mapped, like Strings and Arrays.
	Perform the given selector on the server, and replicate the result."

	| session messageSend |
	self gbsMessenger
		statusTag: #unsynchronizedPerformOnGsServer
		message: '(s%1) %2 unsynchronizedPerformOnGsServer: %3 withArgs: %4'
		with: self sessionId
		with: self
		with: selector
		with: args.
	session := self session.
	messageSend := session newMessageSend.
	^messageSend
		selector: selector;
		arguments: args;
		receiver: self;
		shouldReplicateResult: true;
		replicationLevel: 0;
		shouldSynchronize: false;
		replicationScheme: GbxNullReplicationScheme new;
		stopForBreakpoints: false;
		execute
]

{ #category : 'private - remote execution' }
GbxDelegate >> unsynchronizedPerformOnGsServer: selector 
[
	"Private to GBS. Very dangerous, must follow the rules:
	* No modifying server objects that might be replicated
	* Only replicate simple objects, either direction, whose classes are known to be mapped, like Strings and Arrays.
	Perform the given selector on the server, and replicate the result."

	^self unsynchronizedPerformOnGsServer: selector withArgs: #()
]

{ #category : 'private - remote execution' }
GbxDelegate >> unsynchronizedRemoteClass
[
	"Answer a delegate for the class of the server object that I represent."
	"Do this carefully, since one place it is used is during replication clamp construction.
	So, use unsynched execution, and answer the class as an integer oop to avoid trying to map the class."

	| sess classOop |
	sess := self session.
	classOop := sess unsynchronizedEvaluate: 'self class asOop' context: self.
	^GbxDelegate oopValue: classOop session: sess
]

{ #category : 'public - testing' }
GbxDelegate >> isExported
[
	"Return true if the receiver is in the session's export set.
	Answer false if we can't tell."
	"Skip specials like (Otrue, Ofalse, and characters) because #'_testIf:isIn:'
	 has trouble testing for them. Specials shouldn't be in the export set anyway."

	self isSpecial ifTrue: [^false].
	self exists ifFalse: [^false].
	^self session
		critical: 
			[self session unsynchronizedEvaluate: 'System _testIf: self isIn: 39'
				context: self]
		unlessBlocked: [false]
		onError: [:ex | false]
]

{ #category : 'public - testing' }
GbxDelegate >> isGSObject
[
	^true
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalBoolean
[
	"Convert to a local boolean value if possible"

	GbsConfiguration 
		deprecated: 'Delegate>>asLocalBoolean deprecated March, 2006. Send #asLocalObject instead'.
	^self asLocalObject
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalSymbol
[
	"Creates and returns a Smalltalk symbol from the receiver."

	GbsConfiguration 
		deprecated: 'Delegate>>asLocalSymbol deprecated March, 2006. Send #asLocalObject  or #asLocalObjectCopy instead'.
	^self asLocalObject
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalUndefined
[
	GbsConfiguration 
		deprecated: 'Delegate>>asLocalUndefined deprecated March, 2006. Use ''nil'' instead'.
	^nil
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalCharacter
[
	"Return myself as a Smalltalk Character if possible"

	GbsConfiguration 
		deprecated: 'Delegate>>asLocalCharacter deprecated March, 2006. Send #asLocalObject instead'.
	^self asLocalObject
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalDouble
[
	"Returns a Double"

	GbsConfiguration 
		deprecated: 'Delegate>>asLocalDouble deprecated March, 2006. Send #asLocalObject instead'.
	^self asLocalObject
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalFloat
[
	GbsConfiguration 
		deprecated: 'Delegate>>asLocalFloat deprecated March, 2006. Send #asLocalObject instead'.
	^self asLocalDouble asFloat
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalFraction
[
	GbsConfiguration 
		deprecated: 'Delegate>>asLocalFraction deprecated March, 2006. Send #asLocalObject instead'.
	^self asLocalObject
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalInteger
[
	GbsConfiguration 
		deprecated: 'Delegate>>asLocalInteger deprecated March, 2006. Send #asLocalObject'.
	^self asLocalObject
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalLargeNegativeInteger
[
	"Assuming the receiver is a GemStone LargeNegativeInteger, replicate in Smalltalk"

	GbsConfiguration 
		deprecated: 'Delegate>>asLocalLargeNegativeInteger deprecated March, 2006. Send #asLocalObject instead'.
	^self asLocalObject
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalLargePositiveInteger
[
	"Assuming the receiver is a GemStone LargePositiveInteger, replicate in Smalltalk"

	GbsConfiguration 
		deprecated: 'Delegate>>asLocalLargePositiveInteger deprecated March, 2006. Send #asLocalObject instead'.
	^self asLocalObject
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalNumber
[
	GbsConfiguration 
		deprecated: 'Delegate>>asLocalLargeNumber deprecated March, 2006. Send #asLocalObject instead'.
	^self asLocalObject
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalSmallInteger
[
	"Returns a client Small Integer.  Note that no checking is done to verify that the oopValue of the receiver is a valid GemStone SmallInteger; if it's not, 0 will be returned."

	GbsConfiguration 
		deprecated: 'Delegate>>asLocalSmallInteger deprecated March, 2006. Send #asLocalObject  or #asLocalObjectCopy instead'.
	^self asLocalObject
]

{ #category : 'public - explicit replication' }
GbxDelegate >> asLocalString
[
	"This pulls the bytes of the receiver up from the GemStone and puts them into a local String object"

	GbsConfiguration 
		deprecated: 'Delegate>>asLocalString deprecated March, 2006. Send #asLocalObject instead'.
	^self asLocalObject
]

{ #category : 'private - temporary' }
GbxDelegate >> remoteClassIsClientForwarder
[
	"Answer true if the server I represent is of class ClientForwarder"

	self gbxFixMe.	"This method should be removed once we have server Smalltalk code for determining whether
					an object is a client forwarder."
	^(GbsError 
		primResultOrError: (self serverInterfaceDo: [:if | if remoteClassFor: self])
		verifyArgs: [true]
		session: self session) = OClientForwarder
]

{ #category : 'TEMPORARY' }
GbxDelegate >> fetchObjectValues
[
	"Return an array of delegates representing the instance variables of <self>."

	"I hope no one is using this for objects with more than a million instvars"

	self gbxFixMe.	"This message should be deprecated."
	^self fetch: 1000000 OOPsAt: 1
]

{ #category : 'TEMPORARY' }
GbxDelegate >> fetchObjectValuesDebug
[
	"Return an array of delegates representing the instance variables of <self>."

	"I hope no one is using this for objects with more than a million instvars"

	self gbxFixMe.	"This message should be deprecated."
	^self fetch: 1000000 OOPsAtDebug: 1
]

{ #category : 'private - inst var accessing' }
GbxDelegate >> instVarAt: anIndex 
[
	^self unsynchronizedPerform: #instVarAt: with: anIndex
]

{ #category : 'private - inst var accessing' }
GbxDelegate >> instVarNames
[
	^(self remoteClass unsynchronizedPerform: #allInstVarNames) asLocalObject
]

{ #category : 'public - general access' }
GbxDelegate >> checkAuth
[
	"Check authorization of this object for the current user.  The result is represented as #none, #read, or #write, and is the result of a complete authorization check, including owner, group, and world authorization(s).  Special objects such as SmallIntegers will always be reported as #read authorization.  Reports an error if the object doesn't exist."

	^(self session checkAuth: (Array with: self)) at: 1
]

{ #category : 'public - general access' }
GbxDelegate >> remoteVaryingSize
[
	"Return the number of varying elements (indexable or NSC) in the receiver"

	^self session evaluate: 'self _basicSize' context: self
]

{ #category : 'public - general access' }
GbxDelegate >> isBytes
[
	^self fetchImplementation == 1
]

{ #category : 'public - general access' }
GbxDelegate >> gbxIsGSDefunct
[
	"Private. Answer true if the proxy is defunct."

	self hasLiveSessionFlag ifFalse: [^true].
	self sessionHasValidSessionId ifFalse: [^true].
	^self exists not
]

{ #category : 'public - general access' }
GbxDelegate >> session
[
	| id ses |
	self checkSession.
	id := self sessionId.
	(ses := GBSM sessionWithId: id) notNil 
		ifTrue: [^ses]
		ifFalse: 
			["Session must be dying but my flag isn't yet set -- set it myself
			then throw exception."

			self setDeadSession.
			self checkSession].
	^nil
]

{ #category : 'public - general access' }
GbxDelegate >> sessionId
[
	^self basicAt: 1
]

{ #category : 'public - general access' }
GbxDelegate >> isForSession: aSession 
[
	"Returns true if receiver's session is aSession"

	^self sessionId == aSession sessionId
]

{ #category : 'public - general access' }
GbxDelegate >> isNSC
[
	^self fetchImplementation == 2
]

{ #category : 'public - general access' }
GbxDelegate >> isStringObject
[
	^(self remotePerform: #isKindOf: with: OCharacterCollection) = Otrue
]

{ #category : 'public - general access' }
GbxDelegate >> oopValue
[
	"Constructs an integer representation of the object ID (oop) of the server object I represent. 
	Not recommended for wide use -- in general it's better to leave oops in their byte representation."
	
	| temp |
	temp := 0.
	(1 to: self basicSize - 4)
		do: [:index | temp := temp * 16r100 + (self oopByteAt: index)].
	^temp
]

{ #category : 'public - general access' }
GbxDelegate >> exists
[
	"Return false if the GemStone object I represent does not exist"

	^GbsError 
		primResultOrError: (self serverInterfaceDo: [:if | if existsFor: self])
		verifyArgs: [true]
		session: self session
]

{ #category : 'public - general access' }
GbxDelegate >> remoteClass
[
	"Answer a delegate for the class of the server object that I represent."
	"Do this carefully, since one place it is used is during replication clamp construction.
	So, use unsynched execution, and answer the class as an integer oop to avoid trying to map the class."

	| sess classOop |
	sess := self session.
	classOop := sess evaluate: 'self class asOop' context: self.
	^GbxDelegate oopValue: classOop session: sess
]

{ #category : 'public - general access' }
GbxDelegate >> remoteClassName
[
	"This returns a Smalltalk string that is the name of the class of the
	GemStone object represented by the receiver."

	^self session evaluate: 'self class name asString' context: self
]

{ #category : 'public - general access' }
GbxDelegate >> remoteDescription
[
	"Return a Smalltalk string describing the GemStone object"
	
	^[self session evaluate: 'self printString' context: self]
		on: Error
		do:
			[:ex | 
			| stream |
			stream := String new writeStream.
			self printOn: stream.
			stream nextPutAll: ' encountered an error during a remote printString: '.
			stream nextPutAll: ex messageText.
			stream contents]
]

{ #category : 'public - general access' }
GbxDelegate >> remoteIdxSize
[
	"As of release 3.2, a more general version of this method exists - remoteVaryingSize"

	self gbxFixMe.	"There is no test coverage for this message.."
	^self remoteVaryingSize
]

{ #category : 'public - general access' }
GbxDelegate >> isPointers
[
	^self fetchImplementation == 0
]

{ #category : 'public - general access' }
GbxDelegate >> remoteNamedSize
[
	self gbxFixMe.	"There is no test coverage for this message.."
	^self session evaluate: 'self class instSize' context: self
]

{ #category : 'public - general access' }
GbxDelegate >> remoteSize
[
	"This returns the size of the GemStone object that I represent, including all named and indexed instvars "

	^self session evaluate: 'self _primitiveSize' context: self
]

{ #category : 'private - flag access' }
GbxDelegate >> isIdentityClamped
[
	"Private.  Return true if the receiver is known to be identity clamped.  
	Since GBS controls adds and removals from the identity clamp set, this
	should always be correct."

	^(self flags bitAnd: self identityClampedMask) ~~ 0
]

{ #category : 'private - flag access' }
GbxDelegate >> flags: anInteger
[
	self basicAt: 2 put: anInteger
]

{ #category : 'private - flag access' }
GbxDelegate >> isReadOnlyObject
[
	"Private"

	^(self flags bitAnd: self readOnlyMask) ~~ 0
]

{ #category : 'private - flag access' }
GbxDelegate >> isReadOnlyObject: aBoolean 
[
	"Private"

	aBoolean 
		ifTrue: [self flags: (self flags bitOr: self readOnlyMask)]
		ifFalse: [self flags: (self flags bitAnd: 16rFF - self readOnlyMask)]
]

{ #category : 'private - flag access' }
GbxDelegate >> isStDirty
[
	"Private.  Return true if the Smalltalk/GemStone object relationship is Smalltalk dirty (the Smalltalk state is more current than the GemStone state)"

	^(self flags bitAnd: self dirtyMask) ~~ 0
]

{ #category : 'private - flag access' }
GbxDelegate >> markStNotDirty: anObj
[
	"Private.  Flag this Smalltalk/GemStone object relationship as not being Smalltalk dirty."

	self isStDirty
		ifTrue: 
			[self session sessionCritical: 
					["Another thread might have marked not dirty while we waited for the semaphore."
					self isStDirty ifFalse: [^self].
					self clearDirtyBit]]
]

{ #category : 'private - flag access' }
GbxDelegate >> noLongerExported
[
	"I am no longer in the the server's pure export set, clear the flag."

	self flags: (self flags bitAnd: 16rFF - self inExportMask)
]

{ #category : 'private - flag access' }
GbxDelegate >> nowExported
[
	"signal that this object is in the server's export set. Either we just found out the object is 
	in the export set because we got a full report for it, or we are about to put it in the export 
	set by putting it in a store traversal."

	self flags: (self flags bitOr: self inExportMask)
]

{ #category : 'private - flag access' }
GbxDelegate >> setDeadSession
[
	"Private.  If the receiver isn't for all sessions, set the DeadSessionFlag"

	self flags: (self flags bitOr: self deadSessionMask)
]

{ #category : 'private - flag access' }
GbxDelegate >> clearDirtyBit
[
	"Private"

	self flags: (self flags bitAnd: 16rFF - self dirtyMask)
]

{ #category : 'private - flag access' }
GbxDelegate >> clearIdentityClampedBit
[
	"Private"

	self flags: (self flags bitAnd: 16rFF - self identityClampedMask)
]

{ #category : 'private - flag access' }
GbxDelegate >> setDirtyBit
[
	"Private"

	self flags: (self flags bitOr: self dirtyMask)
]

{ #category : 'private - flag access' }
GbxDelegate >> hasLiveSessionFlag
[
	"Indicates session has logged out or instance wasn't created
	 properly."

	^(self flags bitAnd: self deadSessionMask) == 0
]

{ #category : 'private - flag access' }
GbxDelegate >> setIdentityClampedBit
[
	"Private"

	self flags: (self flags bitOr: self identityClampedMask)
]

{ #category : 'private - flag access' }
GbxDelegate >> inExport
[
	"Answer true if I believe my oop to be in the server's pure export set."

	^(self flags bitAnd: self inExportMask) ~~ 0
]

{ #category : 'private - comparing' }
GbxDelegate >> equalsDelegate: aDelegate 
[
	^(self sameOopAs: aDelegate) and: 
			[aDelegate sessionId = self sessionId 
				and: [aDelegate hasLiveSessionFlag and: [self hasLiveSessionFlag]]]
]

{ #category : 'private - comparing' }
GbxDelegate >> sameOopAs: aBufferOopOrDelegate
[
	
	self bytesPerOop == aBufferOopOrDelegate bytesPerOop ifFalse: [^false].
	self bytesPerOop
		to: 1
		by: -1
		do:
			[:i | 
			(self oopByteAt: i) == (aBufferOopOrDelegate oopByteAt: i)
				ifFalse: [^false]].
	^true
]

{ #category : 'gemstone private' }
GbxDelegate >> gbxCouldBeForwarder
[

	^self isReadOnlyObject not
]

{ #category : 'gemstone private' }
GbxDelegate >> gbxExistingOrSpecialDelegateInSession: aGSSession
[

	(self isForSession: aGSSession) ifTrue: [^self].
	self checkSession.
	aGSSession checkSession.
	self gbsMessenger error: 'Attempt to use a delegate from another session.'
]

{ #category : 'private - instance creation' }
GbxDelegate class >> new
[
	^self basicNew: self bytesPerOop + 4
]

{ #category : 'private - instance creation' }
GbxDelegate class >> oopValue: anOop session: session
[
	"anOop is an integer in this case. Use this message only when absolutely necessary. There should usually be a better way."
	"Create a temporary delegate, but return the canonical one unless it's a special.
	Delegates for server specials are not canonicalized. OopIllegal must be handled specially, since
	it cannot live in the server map."

	| newDel |
	anOop == 1 ifTrue: [^session oopIllegal].
	newDel := (session delegateClass new)
				oopValue: anOop;
				session: session.
	^(session isSpecialOop: newDel)
		ifTrue: [newDel]
		ifFalse: 
			[session sessionCriticalNoSessionCheck: [session delegateForOop: newDel]]
]

{ #category : 'GBS private' }
GbxDelegate class >> gbsReplicatorClass
[

	^GbxNullReplicator
]

{ #category : 'instance creation' }
GbxDelegate class >> forSession: aSession 
[
	"WARNING: Delegates are canonical, except for delegates that represent server specials.
	This method is only to be used for creating server special delegates."

	^aSession delegateClass new session: aSession
]

{ #category : 'constants' }
GbxDelegate class >> bytesPerOop
[
	"Either 4 or 8"
	^self subclassResponsibility
]
