Class {
	#name : 'GbsSession',
	#superclass : 'Object',
	#instVars : [
		'activeInteractions',
		'causeOfDeath',
		'clientTimeZone',
		'configuration',
		'dependents',
		'dirtyPool',
		'eventHandlers',
		'eventDetectorErrorHandler',
		'freeOops',
		'gbsm',
		'gemTimeZone',
		'gsClassOrganizer',
		'isRemote',
		'isUnwindingAsyncAbort',
		'nestingLevel',
		'notCachedToken',
		'parameters',
		'procBalancer',
		'replicatorManager',
		'serverInterface',
		'serverMap',
		'sessionDisplayString',
		'sessionId',
		'sessionProtect',
		'specialConverter',
		'stats',
		'asyncAbortStartAction',
		'asyncAbortFinishAction',
		'loginTimestamp',
		'logoutTimestamp',
		'gemProcessId',
		'gemSerialNumber',
		'gemSessionId'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private - st object management' }
GbsSession >> uncacheNonExistentGSObjects
[
	"Private.  Remove cache entries for which the GemStone oop no longer exists.  Such oops don't normally exist in the cache, because saveObjects is called for each of them before commits and aborts.  It's important to remove these entries because stubbing such an object would mortally wound the Smalltalk counterpart."
	"GBSM currentSession uncacheNonExistentGSObjects"
	"Sender must hold my sessionProtect and client map write lock."

	serverMap delegatesAndClientObjsDo: 
			[:del :clientObj |
			(del ~~ nil and: [del exists not])
				ifTrue: 
					["Remove from serverMap.. Yank the canonical delegate as well,
					we don't want to try to unexport this object when the delegate is GC'ed.
					This could result in a non-canonical delegate, but there wasn't much you 
					could do with a delegate for a nonexistent object anyway."
					serverMap removeOop: del.
					"If there was a client object associated with this delegate, remove it from clientMap."
					clientObj ~~ nil ifTrue: [gbsm removeAtST: clientObj forSession: self]]]
]

{ #category : 'private - st object management' }
GbsSession >> addToDirtyPool: anObject forDelegate: delegate
[
	"Private.  Add anObj to the dirtyPool. This aids in dirty object flushing, and
	supplies a strong reference to anObj preventing it from being
	garbage collected before it is flushed to GemStone."

	self sessionCritical: 
			[dirtyPool addObject: anObject.
			delegate isReadOnlyObject ifFalse: [anObject gbxIgnoreFutureChanges]]
]

{ #category : 'private - st object management' }
GbsSession >> setAsideDirtyWhile: aBlock
[
	"Private to GBS.
	Execute aBlock with an empty top dirty pool, then restore the former top dirty pool.
	aBlock's execution should leave its dirty pool empty."
	"Sender must hold my sessionProtect."

	^dirtyPool setAsideDirtyWhile: aBlock
]

{ #category : 'private - st object management' }
GbsSession >> stubDirtySTObjects
[
	"Private.  Roll back all dirty Smalltalk objects to the current repository state.  This occurs after an abnormal abort, causing Smalltalk objects which were dirty before the abort to revert to their pre aborted transaction state."

	self gbsMessenger
		statusTag: #stubDirtySTObjects
		message: '(s%1) GbsSession>>stubDirtySTObjects'
		with: self sessionId.
	self sessionCritical: 
			[dirtyPool isNil
				ifFalse: 
					[| allDirty |
					allDirty := IdentitySet new: configuration initialDirtyPoolSize.
					dirtyPool emptyInto: allDirty.
					allDirty do: 
							[:dirtyObj |
							| delegate |
							delegate := self cacheAtST: dirtyObj.
							(delegate notNil and: [delegate isStDirty])
								ifTrue: 
									["Stub it to revert back to pre aborted transaction state."
									(delegate isReadOnlyObject not and: [delegate exists])
										ifTrue: 
											[| replicator |
											delegate markStNotDirty: dirtyObj.
											replicator := self replicatorForClientBehavior: dirtyObj gbxBasicClass
														ifAbsent: [nil].
											"If stubbing is to succeed, there really should be a replicator, but default anyway."
											replicator isNil
												ifTrue: 
													[GbxObjectStub stubObject: dirtyObj forDelegate: delegate freeSlots: true]
												ifFalse: 
													[replicator stubObject: dirtyObj forDelegate: delegate freeSlots: true]]
										ifFalse: [self disconnectClient: dirtyObj fromServer: delegate]]]]].
	self gbsMessenger
		statusTag: nil
		message: '(s%1) completed GbsSession>>stubDirtySTObjects'
		with: self sessionId
]

{ #category : 'public-clamping' }
GbsSession >> replicationSpecSet: aSymbol
[
	"The value of replicationSpecSet is a symbol which is the name of the
	 replication spec set currently in effect.  This symbol corresponds to the
	 unary message selector which is sent to application classes to specify
	 how that class's instances should replicate - a replication specification.
	 A replication spec set, then, is a collection of replication specs which,
	 as a whole, describe how to replicate instances of all the application's
	 classes.  The default replication spec set is #replicationSpec.  To define
	 a new replication spec set, #myReplicationSpec, you must implement
	 Object class>>myReplicationSpec (^self replicationSpec is a good
	 default implementation).  You can then implement myReplicationSpec
	 as a class method for each class where myReplicationSpec differs
	 from the default replicationSpec."

	self
		sessionCritical: [replicatorManager defaultReplicationSpecSet: aSymbol]
]

{ #category : 'public-clamping' }
GbsSession >> usingReplicationSpecSet: setSymbol do: aBlock
[
	"Evaluate the given nilary block using the given replication spec set name. 
	This does not affect the session's default replication spec set. The given replication spec set is used only in this Smalltalk Process
	(green thread) and only for this session. If the block interacts with any other sessions, the replication spec set
	currently in effect for that session will be used for that interaction. 
	This message is the recommended way to use multiple replication spec sets in a multi-threaded application.
	Answers the result of evaluating aBlock."

	^replicatorManager ifNotNil: [replicatorManager usingReplicationSpecSet: setSymbol do: aBlock]
		ifNil: [self checkSession]
	"replicatorManager will be nil if I've been logged out."
]

{ #category : 'public-clamping' }
GbsSession >> replicationSpecSet
[
	"The value of replicationSpecSet is a symbol which is the name of the
	 replication spec set currently in effect.  This symbol corresponds to the
	 unary message selector which is sent to application classes to specify
	 how that class's instances should replicate - a replication specification.
	 A replication spec set, then, is a collection of replication specs which,
	 as a whole, describe how to replicate instances of all the application's
	 classes.  The default replication spec set is #replicationSpec.  To define
	 a new replication spec set, #myReplicationSpec, you must implement
	 Object class>>myReplicationSpec (^self replicationSpec is a good
	 default implementation).  You can then implement myReplicationSpec
	 as a class method for each class where myReplicationSpec differs
	 from the default replicationSpec.

	NOTE that this value can be overridden on a thread-specific basis
	by #usingReplicationSpecSet:do:"

	^self sessionCritical: [replicatorManager defaultReplicationSpecSet]
]

{ #category : 'remote execution' }
GbsSession >> fwevaluate: aString context: aContext symbolList: aSymbolList 
[
	"Execute aString, GemStone Smalltalk code, on the server. Use as the execution 
	context (providing binding for self, super, and instance variable names) 
	the server object associated with aContext.  Resolve shared variables using 
	the server object associated with aSymbolList. aContext and aSymbolList may 
	be replicates, stubs, or forwarders.  Answer the result as a forwarder."

	^(self 
		execute: aString
		context: (aContext asGSObjectInSession: self)
		symbolList: (aSymbolList asGSObjectInSession: self)) asForwarder
]

{ #category : 'remote execution' }
GbsSession >> evaluate: aString symbolList: aSymbolList 
[
	"Execute aString, GemStone Smalltalk code, on the server.  Resolve shared variables using 
	the server object associated with aSymbolList. aSymbolList may 
	be a replicate, stub, or forwarder.  Answer the result as a replicate."

	^self 
		evaluate: aString
		context: self oopIllegal
		symbolList: aSymbolList
]

{ #category : 'remote execution' }
GbsSession >> evaluate: aString toLevel: level 
[
	"Execute aString, GemStone Smalltalk code, on the server,
	 and answer the result as a replicate."

	^self 
		evaluate: aString
		toLevel: level
		context: self oopIllegal
]

{ #category : 'remote execution' }
GbsSession >> fwevaluate: aString symbolList: aSymbolList 
[
	"Execute aString, GemStone Smalltalk code, on the server.  Resolve shared variables using 
	the server object associated with aSymbolList. aSymbolList may 
	be a replicate, stub, or forwarder.  Answer the result as a forwarder."

	^self 
		fwevaluate: aString
		context: self oopIllegal
		symbolList: aSymbolList
]

{ #category : 'remote execution' }
GbsSession >> evaluate: aString toLevel: level context: aContext 
[
	"Execute aString, GemStone Smalltalk code, on the server. Use as the execution 
	context (providing binding for self, super, and instance variable names) 
	the server object associated with aContext.  aContext may be a replicate, stub, 
	or forwarder.  Answer the result as a replicate."

	^self 
		evaluate: aString
		toLevel: level
		context: aContext
		symbolList: self oopNil
]

{ #category : 'remote execution' }
GbsSession >> evaluate: sourceString toLevel: level context: gsContext symbolList: gsSymbolList
[
	"Execute aString, GemStone Smalltalk code, on the server. Use as the execution 
	context (providing binding for self, super, and instance variable names) 
	the server object associated with aContext.  Resolve shared variables using 
	the server object associated with aSymbolList. aContext and aSymbolList may 
	be replicates, stubs, or forwarders.  Answer the result as a replicate."

	| evaluation ctxDel symListDel |
	evaluation := self newServerEvaluation.
	ctxDel := gsContext asGSObjectInSession: self.
	symListDel := gsSymbolList asGSObjectInSession: self.
	^evaluation
		sourceCode: sourceString;
		replicationLevel: level;
		contextDelegate: ctxDel;
		symbolListDelegate: symListDel;
		execute
]

{ #category : 'remote execution' }
GbsSession >> execute: aString 
[
	"Execute Smalltalk string aString, containing GemStone Smalltalk code, in GemStone"

	^self execute: aString symbolList: self oopNil
]

{ #category : 'remote execution' }
GbsSession >> execute: aString context: aContext 
[
	"Execute aString, a GemStone Smalltalk string in GemStone context aContext"

	^self 
		execute: aString
		context: aContext
		symbolList: self oopNil
]

{ #category : 'remote execution' }
GbsSession >> hardBreak
[
	"Sending this message while a non-blocking GemStone call is in progress will
	 cause the GemStone execution engine to be interrupted.  The GemStone call
	 will raise the error rtErrHardBreak, which can be proceeded.  This call differs
	 from softBreak in that it is not possible to trap hardBreak with a GemStone
	 exception handler."

	GbsError 
		primResultOrError: self serverInterface hardBreak
		verifyArgs: [true]
		session: self
]

{ #category : 'remote execution' }
GbsSession >> execute: sourceString context: gsContext symbolList: gsSymbolList
[
	"Execute the GemStone Smalltalk string in GemStone context gsContext"

	| evaluation ctxDel symListDel |
	evaluation := self newServerEvaluation.
	ctxDel := gsContext asGSObjectInSession: self.
	symListDel := gsSymbolList asGSObjectInSession: self.
	^evaluation
		sourceCode: sourceString;
		contextDelegate: ctxDel;
		symbolListDelegate: symListDel;
		shouldReplicateResult: false;
		execute
]

{ #category : 'remote execution' }
GbsSession >> execute: aString symbolList: aGSObjectSymbolList 
[
	^self 
		execute: aString
		context: self oopIllegal
		symbolList: aGSObjectSymbolList
]

{ #category : 'remote execution' }
GbsSession >> softBreak
[
	"Sending this message while a non-blocking GemStone call is in progress will
	 cause the GemStone execution engine to be interrupted.  The GemStone call
	 will raise the error rtErrSoftBreak, which can be proceeded.  This call differs
	 from hardBreak in that it is possible to trap softBreak with a GemStone exception
	 handler."

	GbsError 
		primResultOrError: self serverInterface softBreak
		verifyArgs: [true]
		session: self
]

{ #category : 'remote execution' }
GbsSession >> fwevaluate: aString 
[
	"Execute aString, GemStone Smalltalk code, on the server,
	 and answer the result as a forwarder."

	^self fwevaluate: aString context: self oopIllegal
]

{ #category : 'remote execution' }
GbsSession >> fwevaluate: aString context: aContext 
[
	"Execute aString, GemStone Smalltalk code, on the server. Use as the execution 
	context (providing binding for self, super, and instance variable names) 
	the server object associated with aContext.  aContext may be a replicate, stub, 
	or forwarder.  Answer the result as a forwarder."

	^self 
		fwevaluate: aString
		context: aContext
		symbolList: self oopNil
]

{ #category : 'remote execution' }
GbsSession >> evaluate: aString context: aContext 
[
	"Execute aString, GemStone Smalltalk code, on the server. Use as the execution 
	context (providing binding for self, super, and instance variable names) 
	the server object associated with aContext.  aContext may be a replicate, stub, 
	or forwarder.  Answer the result as a replicate."

	^self 
		evaluate: aString
		context: aContext
		symbolList: self oopNil
]

{ #category : 'remote execution' }
GbsSession >> evaluate: sourceString context: gsContext symbolList: gsSymbolList
[
	"Execute aString, GemStone Smalltalk code, on the server. Use as the execution 
	context (providing binding for self, super, and instance variable names) 
	the server object associated with aContext.  Resolve shared variables using 
	the server object associated with aSymbolList. aContext and aSymbolList may 
	be replicates, stubs, or forwarders.  Answer the result as a replicate."

	| evaluation ctxDel symListDel |
	evaluation := self newServerEvaluation.
	ctxDel := gsContext asGSObjectInSession: self.
	symListDel := gsSymbolList asGSObjectInSession: self.
	^evaluation
		sourceCode: sourceString;
		contextDelegate: ctxDel;
		symbolListDelegate: symListDel;
		execute
]

{ #category : 'remote execution' }
GbsSession >> evaluate: aString 
[
	"Execute aString, GemStone Smalltalk code, on the server,
	 and answer the result as a replicate."

	^self evaluate: aString context: self oopIllegal
]

{ #category : 'class translation' }
GbsSession >> gemStoneClassFor: stClass ifNone: aBlock
[

	"Given Smalltalk class stClass, return a GemStone class appropriate for replicating instances of stClass in GemStone.
	 If there is no corresponding entry in the transparency cache, then look for a suitable class of the same name.  If none
	 exists, then try to create one (along with all necessary superclasses).  If this isn't possible, return aBlock value."

	^[ self gemStoneClassFor: stClass ]
		on: GbsClassGenerationError
		do: [ :ex | ex return: aBlock value ]
]

{ #category : 'class translation' }
GbsSession >> smalltalkClassFor: gsClass ifNone: aBlock
[

	"Given gsClass, return a Smalltalk class appropriate for replicating instances of gsClass in Smalltalk.
	If there is no corresponding entry in the transparency cache, then look for a class of the same name.
	If no translation can be found, return aBlock value."

	^[ self smalltalkClassFor: gsClass ]
		on: GbsClassGenerationError
		do: [ :ex | ex return: aBlock value ]
]

{ #category : 'class translation' }
GbsSession >> gemStoneClassFor: clientBehavior
[
	"Given the client class or metaclass clientBehavior, return a server behavior appropriate for replicating instances of clientBehavior.
	 If the given class or metaclass is not mapped, but the corresponding metaclass or class is, map based on that.
	 If neither class nor metaclass is already mapped, then look for a suitable class of the same name and map both class and metaclass.  
	 If no same-name class exists, then try to create one, along with all necessary superclasses, and map them.
	 The class lookup considers the entire symbol list.
	 If this isn't possible, GbsClassGenerationError will be raised."

	^self gemStoneClassFor: clientBehavior inDictionaryNamed: nil
]

{ #category : 'class translation' }
GbsSession >> gemStoneClassFor: clientBehavior inDictionaryNamed: dictionaryNameOrNil
[
	"Given the client class or metaclass clientBehavior, return a server behavior appropriate for replicating instances of clientBehavior.
	 If the given class or metaclass is not mapped, but the corresponding metaclass or class is, map based on that.
	 If neither class nor metaclass is already mapped, then look for a suitable class of the same name and map both class and metaclass.  
	 If no same-name class exists, then try to create one, along with all necessary superclasses, and map them.  
	 If a dictionary name is specified, the class search is restricted to that specific
	 symbol dictionary. (This can arise when creating or updating a class for a connector
	 with a symbol dictionary specified.) Otherwise, the class lookup considers the entire symbol list.
	 If this isn't possible, GbsClassGenerationError will be signaled."

	| behaviorDelegate clientClass |
	clientBehavior isNil ifTrue: [^self oopNil].	"Nil May be passed if mapping a class that does not inherit from Object"
	self sessionCritical: 
			[behaviorDelegate := self cacheAtST: clientBehavior.
			"If we don't have it already mapped, try mapping from meta for class or vice versa"
			behaviorDelegate isNil
				ifTrue: 
					[| isMeta clientMetaclass classDelegate metaclassDelegate targetDictionaryName |
					isMeta := clientBehavior isMeta.
					isMeta
						ifTrue: 
							[clientMetaclass := clientBehavior.
							clientClass := clientMetaclass soleInstance.
							classDelegate := self cacheAtST: clientClass.
							classDelegate ~~ nil
								ifTrue: 
									[metaclassDelegate := classDelegate unsynchronizedPerform: #class.
									self mapClientBehavior: clientMetaclass toServer: metaclassDelegate.
									behaviorDelegate := metaclassDelegate]]
						ifFalse: 
							[clientClass := clientBehavior.
							clientMetaclass := clientClass class.
							metaclassDelegate := self cacheAtST: clientMetaclass.
							metaclassDelegate ~~ nil
								ifTrue: 
									[classDelegate := metaclassDelegate unsynchronizedPerform: #thisClass.
									self mapClientBehavior: clientClass toServer: classDelegate.
									behaviorDelegate := classDelegate]].
					"If neither metaclass nor class were mapped, try mapping by name, creating if necessary and allowed."
					behaviorDelegate == nil
						ifTrue: 
							[classDelegate := self serverClassWithSameNameAs: clientClass
										inDictionaryNamed: dictionaryNameOrNil.
							classDelegate == nil
								ifTrue: 
									[configuration generateServerClasses
										ifTrue: 
											[targetDictionaryName := dictionaryNameOrNil
														ifNil: [self class defaultDictionaryName].
											"Ensure the target dictionary exists."
											self symbolDictionaryNamed: targetDictionaryName.
											"For historical reasons, createGemStoneClassFor does the mapping itself."
											classDelegate := self createServerClassFor: clientClass
														inDictionaryNamed: targetDictionaryName]]
								ifFalse: 
									[self mapClientBehavior: clientClass toServer: classDelegate.
									metaclassDelegate := classDelegate unsynchronizedPerform: #class.
									self mapClientBehavior: clientMetaclass toServer: metaclassDelegate].
							behaviorDelegate := isMeta
										ifTrue: [self cacheAtST: clientClass class]
										ifFalse: [classDelegate]]]].
	behaviorDelegate == nil
		ifTrue: 
			[self gbsMessenger
				raise: GbsClassGenerationError
				message: 'Failed to find or generate a server class for client class or metaclass %1'
				with: clientClass name].
	^behaviorDelegate
]

{ #category : 'class translation' }
GbsSession >> smalltalkClassFor: behaviorOop
[
	"Given the server class or metaclass behaviorOop (a delegate or oop), return a corresponding client behavior
	 appropriate for replicating instances that class.  If there is no
	 mapped behavior, then look for a class of the
	 same name.  If not found, and allowed, generate the client class. If not allowed, signal an error."
	"behaviorDelegate needs to be a delegate in this session"

	| behaviorDelegate clientBehavior |
	behaviorDelegate := behaviorOop asGSObjectInSession: self.
	behaviorDelegate = self oopNil ifTrue: [^nil].
	^self sessionCritical: 
			["See if it's already mapped, and not a stub"
			clientBehavior := self clientObjForDelegate: behaviorDelegate
						otherwise: nil.
			(clientBehavior ~~ nil and: [clientBehavior zzzisStub not])
				ifTrue: [clientBehavior]
				ifFalse: [behaviorDelegate performOnGsServer: #yourself]]
]

{ #category : 'private - printing' }
GbsSession >> printOn: aStream 
[
	"Private"

	aStream nextPutAll: sessionDisplayString
]

{ #category : 'private - printing' }
GbsSession >> gbxDebugPrintOn: aStream
[
	"Private"
	
	self printOn: aStream.
	aStream
		cr;
		tab;
		tab;
		nextPutAll: 'serverMap size is '.
	serverMap size printOn: aStream.
	aStream
		cr;
		tab;
		tab;
		nextPutAll: 'dirtyPool size is '.
	dirtyPool size printOn: aStream
]

{ #category : 'GBS private' }
GbsSession >> isSpecialScaledDecimal: aScaledDecimal
[
	^specialConverter isSpecialScaledDecimal: aScaledDecimal
]

{ #category : 'GBS private' }
GbsSession >> startingToPack: anObject
[
	"AnObject has been identified as a dirty object to pack in a traversal buffer
	to be sent to the gem. Its dirty referents will be packed first, however."

	dirtyPool startingToPack: anObject
]

{ #category : 'GBS private' }
GbsSession >> isSpecialOop: anOop 
[
	^specialConverter isSpecialOop: anOop
]

{ #category : 'GBS private' }
GbsSession >> nestingLevel: anObject
[

	nestingLevel := anObject
]

{ #category : 'GBS private' }
GbsSession >> shouldReplicateExceptions
[
	"Private to GBS. Answer true if exceptions should be replicated. Can only be true when logged into a GS64 3.0 or later server."

	^configuration replicateExceptions
]

{ #category : 'GBS private' }
GbsSession >> delegateForSpecialInteger: anInteger 
[
	"anInteger must be in the range representable as a SmallInteger on the server. 
	Depending on the server version, this may or may not be the same range as 
	SmallIntegers on the client."

	^specialConverter delegateForSpecialInteger: anInteger forSession: self
]

{ #category : 'GBS private' }
GbsSession >> changedSelector: aSelector inClass: aClass
[
	"A metaclass has had a method added, removed, or changed.
	I may need to update my clamps
	if the method is an instVarMap or a replication spec method, 
	and I have the class mapped."

	replicatorManager changedSelector: aSelector inClass: aClass
]

{ #category : 'GBS private' }
GbsSession >> dirtyPoolSize
[
	^dirtyPool size
]

{ #category : 'GBS private' }
GbsSession >> oopIllegal
[
	^specialConverter oopIllegalForSession: self
]

{ #category : 'GBS private' }
GbsSession >> isSpecialDate: aDate
[
	^specialConverter isSpecialDate: aDate
]

{ #category : 'GBS private' }
GbsSession >> delegateForCharacter: aCharacter 
[
	^specialConverter delegateForCharacter: aCharacter forSession: self
]

{ #category : 'GBS private' }
GbsSession >> traversalBufferClass
[
	^specialConverter traversalBufferClass
]

{ #category : 'GBS private' }
GbsSession >> isSpecialDouble: aDouble
[
	"Sender must hold sessionProtect"

	^specialConverter isSpecialDouble: aDouble session: self
]

{ #category : 'GBS private' }
GbsSession >> replicatorManager
[

	^replicatorManager
]

{ #category : 'GBS private' }
GbsSession >> isSpecialInteger: anInteger 
[
	^specialConverter isSpecialInteger: anInteger
]

{ #category : 'GBS private' }
GbsSession >> delegateForSpecialFraction: aFraction
[
	"aFraction must be in the range representable as a SmallFraction on the server. 
	SmallFraction is not available on all server versions."

	^specialConverter delegateForSpecialFraction: aFraction forSession: self
]

{ #category : 'GBS private' }
GbsSession >> nestingLevel
[

	^nestingLevel
]

{ #category : 'GBS private' }
GbsSession >> sessionCriticalWithoutAssertionChecks: criticalBlock unlessBlocked: blockedBlock 
[
	^sessionProtect critical: 
			[self checkSession.
			criticalBlock value]
		unlessBlocked: blockedBlock
]

{ #category : 'GBS private' }
GbsSession >> delegateForSpecialTime: aTime
[
	"If the server version supports SmallTime, answer a delegate for a 
	SmallTime immediate oop, and set aTime to be immutable.
	If the server does not support SmallTime, answer nil and leave
	aTime's mutability unchanged."

	^specialConverter delegateForSpecialTime: aTime forSession: self
]

{ #category : 'GBS private' }
GbsSession >> delegateClass
[
	^specialConverter delegateClass
]

{ #category : 'GBS private' }
GbsSession >> oopArrayClass
[
	^specialConverter oopArrayClass
]

{ #category : 'GBS private' }
GbsSession >> oopFalse
[
	^specialConverter oopFalseForSession: self
]

{ #category : 'GBS private' }
GbsSession >> isSpecialCharacter: aCharacter 
[
	^specialConverter isSpecialCharacter: aCharacter
]

{ #category : 'GBS private' }
GbsSession >> startingInteraction: anInteraction
[

	self sessionCritical: 
			[activeInteractions size == 0
				ifTrue: [self startingFirstInteraction: anInteraction].
			[(activeInteractions includes: anInteraction) not] gbxAssert.
			activeInteractions add: anInteraction]
]

{ #category : 'GBS private' }
GbsSession >> endingLastInteraction: anInteraction
[
	"Can be overridden in subclasses."
	"If we're in unwind from a fatal error discovered during an interaction, 
					my postLogin may already have run, clearing out variables."

	replicatorManager ifNotNil: [replicatorManager endingInteraction].
	serverMap ifNotNil: [serverMap beWeak].
	GbsSessionManager current sessionExitingInteractions
]

{ #category : 'GBS private' }
GbsSession >> localSpecialFromOop: anOop
[
	"Sender must hold sessionProtect."

	^specialConverter localSpecialFromOop: anOop
]

{ #category : 'GBS private' }
GbsSession >> isSpecialFraction: aFraction
[
	^specialConverter isSpecialFraction: aFraction
]

{ #category : 'GBS private' }
GbsSession >> oopTrue
[
	^specialConverter oopTrueForSession: self
]

{ #category : 'GBS private' }
GbsSession >> sessionCritical: criticalBlock unlessBlocked: blockedBlock retryFor: milliseconds
[
	"Trying a single time to get the session critical block sometimes is not enough,
	for example, if our polling has grabbed the session semaphore.
	We can retry for a specified number of milliseconds"

	| blocked startTime result |
	blocked := true.
	startTime := Time millisecondClockValue.
	[Time millisecondClockValue <= (startTime + milliseconds) and: [blocked]]
		whileTrue: 
			[ blocked := false. 
			result := self sessionCritical: criticalBlock unlessBlocked: [blocked := true].
			blocked ifFalse:[^result]].
	^blockedBlock value
]

{ #category : 'GBS private' }
GbsSession >> isSpecialTime: aTime
[
	^specialConverter isSpecialTime: aTime
]

{ #category : 'GBS private' }
GbsSession >> delegateForSpecialDouble: aDouble
[
	"aDouble must be in the range representable as a SmallDouble on the server. 
	Depending on the server version, there may or may not be any Doubles that 
	meet this requirement.
	Sender must hold my sessionProtect"

	^specialConverter delegateForSpecialDouble: aDouble forSession: self
]

{ #category : 'GBS private' }
GbsSession >> removeStoreTraversal: aStoreTraversal
[
	"This method executes as part of cleanup from a failed error, 
	so the session may already be dead and have nilled dirtyPool."

	dirtyPool ifNotNil: [:dp | dp removeStoreTraversal: aStoreTraversal]
]

{ #category : 'GBS private' }
GbsSession >> isUnwindingAsyncAbort: anObject
[

	isUnwindingAsyncAbort := anObject
]

{ #category : 'GBS private' }
GbsSession >> delegateForSpecialScaledDecimal: aScaledDecimal
[
	"If aScaledDecimal is not in the range representable as a SmallScaledDecimal on the server,
	will answer nil.
	SmallScaledDecimal is not available on all server versions."

	^specialConverter delegateForSpecialScaledDecimal: aScaledDecimal
		forSession: self
]

{ #category : 'GBS private' }
GbsSession >> bufferOopClass
[
	^specialConverter bufferOopClass
]

{ #category : 'GBS private' }
GbsSession >> newInteractionState
[
	"In support of GBS Extensions"

	^GbxInteractionState new
]

{ #category : 'GBS private' }
GbsSession >> addStoreTraversal: aStoreTraversal
[

	dirtyPool addStoreTraversal: aStoreTraversal
]

{ #category : 'GBS private' }
GbsSession >> startingFirstInteraction: anInteraction
[
	"Can be overridden in subclasses."

	GbsSessionManager current sessionEnteringInteractions.
	serverInterface makeCacheStrongAndFinalizeIntoBuffers.
	replicatorManager startingInteraction
]

{ #category : 'GBS private' }
GbsSession >> endingInteraction: anInteraction
[
	"Cannot do a session check here -- one of the reasons for ending an interaction is that we're processing a fatal error."

	self sessionCriticalNoSessionCheck: 
			[activeInteractions remove: anInteraction
				ifAbsent: 
					["Ignore. One way this can happen is if the Process is terminated in startingInteraction: before it adds to activeInteractions."
					].
			activeInteractions size == 0
				ifTrue: [self endingLastInteraction: anInteraction]]
]

{ #category : 'GBS private' }
GbsSession >> oopNil
[
	^specialConverter oopNilForSession: self
]

{ #category : 'GBS private' }
GbsSession >> delegateForSpecialDate: aDate
[
	"If aDate is not in the range representable on the server,
	will error. If the server does not support SmallDate, will answer nil.
	Otherwise, will answer a delegate for a SmallDate immediate oop."

	^specialConverter delegateForSpecialDate: aDate forSession: self
]

{ #category : 'GBS private' }
GbsSession >> packed: anObject
[
	"The last (or only) report for anObject has been placed in a traversal buffer
	for transport to the server."

	self storingObjectInTraversal.	"stats"
	dirtyPool packed: anObject
]

{ #category : 'GBS private' }
GbsSession >> isUnwindingAsyncAbort
[

	^isUnwindingAsyncAbort
]

{ #category : 'GBS private' }
GbsSession >> sessionCritical: criticalBlock unlessBlocked: blockedBlock 
[
	"Private to GBS.  Evaluate aBlock while excluding any other thread from
	 doing operations such as a commit, abort, flush, or critical: against this session.
	If some other process appears to hold the session lock, just run blockedBlock instead."

	self sessionCriticalAssertionChecks.
	^self sessionCriticalWithoutAssertionChecks: criticalBlock
		unlessBlocked: blockedBlock
]

{ #category : 'private - transaction control' }
GbsSession >> postAbnormalAbort
[
	"Private.  An abort has just occurred - synchronize caches"
	"self stubDirtyExistingSTObjects."
	"self stubDirtyExistingGSObjects."
	
	self
		sessionCritical:
			[self
				cacheCritical:
					[self uncacheNonExistentGSObjects.
					self stubDirtySTObjects.
					self execute: ' ''do nothing'' '.	"this will get changed objects"
					self resetClassOrganizer]].
	GbsConfiguration current verbose
		ifTrue:
			[self gbsMessenger
				comment: '%1 abnormally aborted at %2.'
				with: self
				with: Time now].
	self changed: #aborted
]

{ #category : 'private - transaction control' }
GbsSession >> resetAsyncAbortActions
[

	asyncAbortStartAction := [:dirtySet | self gbsMessenger error: self asyncAbortSetupErrorMessage].
	asyncAbortFinishAction := ["One error is enough. No need to natter."].
	^self
]

{ #category : 'private - transaction control' }
GbsSession >> asyncAbortSetupErrorMessage
[

	^'Use of transactionless mode or GemAutoServiceSigAbort requires that the asyncAbort Actions be set.\Refer to GbsSession>>#asyncAbortStartAction:finishAction: for details.'
]

{ #category : 'private - transaction control' }
GbsSession >> postAbort
[
	"Private.  An abort has just occurred"

	self resetClassOrganizer.
	GbsConfiguration current verbose 
		ifTrue: 
			[self gbsMessenger 
				comment: '%1 aborted transaction at %2.'
				with: self
				with: Time now].
	self changed: #aborted
]

{ #category : 'private - transaction control' }
GbsSession >> postCommitSucceeded: succeeded
[
	"Private"

	self resetClassOrganizer.
	GbsConfiguration current verbose
		ifTrue: 
			[succeeded
				ifTrue: 
					[self gbsMessenger
						comment: '%1 committed transaction at %2.'
						with: self
						with: Time now]
				ifFalse: 
					[self gbsMessenger
						comment: '%1 commit failed at %2.'
						with: self
						with: Time now]].

	succeeded ifTrue: [self changed: #committed]
]

{ #category : 'notification' }
GbsSession >> signaledObjects
[
	"Returns an array containing the current contents of the signaledObjects set and clears the signaledObjects set."

	^self systemProxy performOnGsServer: #signaledObjects
]

{ #category : 'notification' }
GbsSession >> enableSignaledGemStoneSessionError
[

	"Enables the generation of an error when a signal from another session is received.  When this error is signaled, it is also disabled to allow the exception handler to run without receiving another interrupt.  Therefore, the exception handler should re-enable the condition before returning."

	self systemProxy unsynchronizedPerform: #enableSignaledGemStoneSessionError
]

{ #category : 'notification' }
GbsSession >> enableSignaledObjectsError
[

	"Turn on generation of #rtErrSignalCommit.  This signal indicates that one or more objects in the session's notify set have been modified and committed by some session.  When the signal occurs, further generation of it is disabled."
	"GBSM currentSession enableSignaledObjectsError"

	self systemProxy unsynchronizedPerform: #enableSignaledObjectsError
]

{ #category : 'notification' }
GbsSession >> gemSignalAction: aBlock
[

	"When a gem-to-gem signal is received, evaluate aBlock.  This should be a
	 three-argument block.  The first argument will be the serial number
	 (a SmallInteger) of the sending session; the second argument will be the
	 signal number (a SmallInteger); the third argument will be a signal message
	 (a String).  If the signal is received during GemStone execution, execution
	 will continue after processing the signal.  If aBlock is nil, previously installed
	 gemSignalAction will be deinstalled.  (Use of this method is incompatible
	 with use of sessionSignalAction: during the life of any given session)."
	aBlock isNil
		ifTrue: 
			["This is a request to turn off notification"
			[self disableSignaledGemStoneSessionError]
				on: GbsRtErrSignalGemStoneSession
				do: [:ex | ex resume].
			self
				onEventSignal: GbsRtErrSignalGemStoneSession
				handle: nil
				raiseException: true.
			^nil].

	"We don't want to see any events during installation"
	
	[self stopEventDetection.
	self
		onEventSignal: GbsRtErrSignalGemStoneSession
		handle: 
			[:gsErr :sess |
			sess sessionCritical: 
					[
					[| args |
					args := gsErr arguments.
					[args isNil] whileFalse: 
							[aBlock
								value: (args at: 1) asLocalObject
								value: (args at: 2) asLocalObject
								value: (args at: 3) asLocalObject.
							args := sess signalFromGemStoneSession]]
							ensure: [sess enableSignaledGemStoneSessionError]].
			gsErr]
		raiseException: false.
	self enableSignaledGemStoneSessionError]
			ensure: [self startEventDetection]
]

{ #category : 'notification' }
GbsSession >> notificationAction: aBlock 
[
	"When notification occurs, evaluate aBlock.  This should be a one-argument block.  An IdentitySet of signalling objects (Smalltalk objects) will be passed as the argument.  If notification occurs during GemStone execution, continue that execution.  If aBlock is nil, previously installed notificationAction will be deinstalled."

	| notifSignal |
	notifSignal := GbsError signalFor: #rtErrSignalCommit.
	aBlock isNil 
		ifTrue: 
			["This is a request to turn off notification"

			[self disableSignaledObjectsError] on: notifSignal do: [:ex | ex resume].
			self 
				onEventSignal: notifSignal
				handle: nil
				raiseException: true.
			^nil].

	"We don't want to see any events during installation"
	self stopEventDetection.
	self 
		onEventSignal: notifSignal
		handle: 
			[:gsErr :sess | 
			sess sessionCritical: 
					[
					[| sigs |
					sigs := IdentitySet new.
					sigs addAll: sess signaledObjects.
					sigs isEmpty ifFalse: [aBlock value: sigs]] 
							ensure: [sess enableSignaledObjectsError]].
			gsErr]
		raiseException: false.
	self enableSignaledObjectsError.
	self startEventDetection
]

{ #category : 'notification' }
GbsSession >> notifySet
[
	"Returns an Array of (Smalltalk) objects that are currently registered for notification when a new state is committed"

	^self systemProxy performOnGsServer: #notifySet
]

{ #category : 'notification' }
GbsSession >> addAllToNotifySet: aCollection
[
	"Adds all the elements of aCollection (either a Smalltalk object or a GbsObject) to the set of objects for which this session is notified if a new state for one or more of them is committed."

	self systemProxy
		remotePerform: #addAllToNotifySet:
		with: aCollection
]

{ #category : 'notification' }
GbsSession >> removeAllFromNotifySet: aCollection
[

	"Removes all elements of aCollection from the notifySet.  Does not generate an error if any of the elements is not in the notifySet."

	self systemProxy
		remotePerform: #removeAllFromNotifySet:
		with: aCollection
]

{ #category : 'notification' }
GbsSession >> removeFromNotifySet: anObject
[

	"Removes anObject from the notifySet.  Does not generate an error if anObject is not in the notifySet."

	self systemProxy
		remotePerform: #removeFromNotifySet:
		with: anObject
]

{ #category : 'notification' }
GbsSession >> addToNotifySet: anObject
[
	"Adds anObject (either a Smalltalk object or a GbsObject) to the set of objects for which this session is notified if a new state for one or more of them is committed."

	self systemProxy
		remotePerform: #addToNotifySet:
		with: anObject
]

{ #category : 'notification' }
GbsSession >> sendSignal: aSignal to: sessionIdOrSerial withMessage: aString
[

	"Sends a signal (a SmallInteger) to the session specified by sessionIdOrSerial
	 (a SmallInteger) with the String aString as a message.  The sessionIdOrSerial
	 argument is a SmallInteger specifying a session.  A positive value is interpreted
	 as a serialNumber (you can get the current session's serial number with the
	 expression GsCurrentSession currentSession serialNumber).  A negative value
	 is interpreted as a negated sessionId (the session id with respect to stone as
	 reported by the expression GBSM evaluate: 'System currentSessionNames',
	 not the sessionId instance variable of a GbsSession)."

	self systemProxy
		remotePerform: #_sendSignal:toSess:withMessage:
		with: aSignal
		with: sessionIdOrSerial
		with: aString.
]

{ #category : 'notification' }
GbsSession >> clearNotifySet
[
	"Removes all objects that are currently in the notifySet."

	self systemProxy remotePerform: #clearNotifySet
]

{ #category : 'notification' }
GbsSession >> disableSignaledGemStoneSessionError
[

	"Disables the generation of an error when a signal from another session is received"

	self systemProxy unsynchronizedPerform: #disableSignaledGemStoneSessionError
]

{ #category : 'notification' }
GbsSession >> sessionSignalAction: aBlock
[
	"When a GsInterSessionSignal is received, evaluate aBlock.  This should
	 be a one-argument block.  The argument will be a forwarder to the
	 instance of GsInterSessionSignal that was received.  If the signal is
	 received during GemStone execution, execution will continue after
	 processing the signal.  If aBlock is nil, previously installed
	 sessionSignalAction will be deinstalled.  (Use of this method is
	 incompatible with use of gemSignalAction: during the life of any given
	 session)."

	aBlock isNil
		ifTrue: 
			["This is a request to turn off notification"
			[self disableSignaledGemStoneSessionError]
				on: GbsRtErrSignalGemStoneSession
				do: [:ex | ex resume].
			self
				onEventSignal: GbsRtErrSignalGemStoneSession
				handle: nil
				raiseException: true.
			^nil].

	"We don't want to see any events during installation"
	
	[self stopEventDetection.
	self
		onEventSignal: GbsRtErrSignalGemStoneSession
		handle: 
			[:gsErr :sess |
			sess sessionCritical: 
					[
					["The first signal was consumed by the error object, build an equivalent one and use it."
					| sessionSignal args |
					args := gsErr arguments copyFrom: 1 to: 3.	"3.5 adds a 4th argument - pending signals"
					sessionSignal := sess
								evaluateBlock: self interSessionSignalCreationString
								withArguments: args
								context: nil.	
					[sessionSignal isNil] whileFalse: 
							[aBlock value: sessionSignal.
							sessionSignal := sess evaluate: self interSessionSignalPollString]]
								ensure: [sess enableSignaledGemStoneSessionError]].
			gsErr]
		raiseException: false.
	self enableSignaledGemStoneSessionError]
			ensure: [self startEventDetection]
]

{ #category : 'notification' }
GbsSession >> signalFromGemStoneSession
[
	"Returns an array containing information about a signal from another GemStone session.  If there is no signal in the queue, then nil is returned.  Otherwise, returns a 3 element array with the following information:
	1.  The serial number of the session that sent the signal.
	2.  The signal value (a SmallInteger).
	3.  A signal message (a String)."

	^self systemProxy performOnGsServer: #_signalFromGemStoneSession
]

{ #category : 'notification' }
GbsSession >> disableSignaledObjectsError
[

	"Turn off generation of #rtErrSignalCommit."
	"GBSM currentSession disableSignaledObjectsError"

	self systemProxy unsynchronizedPerform: #disableSignaledObjectsError
]

{ #category : 'private' }
GbsSession >> sessionCriticalNoSessionCheck: aBlock 
[
	"Private.  Evaluate aBlock while excluding any other thread from
	 doing operations such as a commit, abort, flush, or critical: against this session."

	self sessionCriticalAssertionChecks.
	^sessionProtect critical: aBlock
]

{ #category : 'private' }
GbsSession >> gciGemTrace: anInteger
[

	serverInterface gciGemTrace: anInteger
]

{ #category : 'private' }
GbsSession >> postLostOTroot
[
	"Private.  This is executed after abortErrLostOtRoot is received.  The root of the
	 object table was lost due to the fact that the receiver did not respond
	 to rtErrSignalAbort in the specified amount of time (see stone config
	 file options for specifications).  All cached state must be cleared since
	 the writeSet union was lost."

	| clientObjsNeedingUpdate |
	GbsConfiguration isRuntimeImage
		ifTrue: 
			[self logout.
			^self].
	self sessionCritical: 
			[self cacheCritical: 
					["Check each cached object for existence, because the export set might
		 			not have been up-to-date at the time of lostOTroot"
					self uncacheNonExistentGSObjects.
					"Assume all cached objects are GS-dirty."
					clientObjsNeedingUpdate := GbxMappingList new.
					serverMap delegatesAndClientObjsDo: 
							[:del :clientObj |
							(del ~~ nil and: [clientObj ~~ nil and: [clientObj gbxIsProxy not and: [clientObj gbxIsModifiable]]])
								ifTrue: 
									["Update the object - unless it's already a stub, then leave it to lazily update"
									clientObjsNeedingUpdate addDelegate: del clientObj: clientObj
									"identify what objects need updating on one pass, then update on a second pass. 									We avoid problems with changing the map during the iteration this way"]].
					clientObjsNeedingUpdate delegatesAndClientObjsDo: [:del :clientObj | clientObj gbxUpdateFromDelegate: del]]].
	GbsConfiguration current verbose ifTrue: [self gbsMessenger comment: '%1 has been forcefully aborted (lost OT root).' with: self]
]

{ #category : 'private' }
GbsSession >> unauthorizedObjectReplicatorClass
[

	^GbxUnauthorizedObjectReplicator
]

{ #category : 'private' }
GbsSession >> uncachedForwarderAt: aSymbol ifAbsent: aBlock 
[
	"Private.  Like at:ifAbsent:, except the return value is a forwarder that is not added to the GBS cache."

	| result |
	self gbsMessenger 
		statusTag: #uncachedForwarderAt
		message: '(s%1) GbsSession>>uncachedForwarderAt: %2 ifAbsent: %3'
		with: self sessionId
		with: aSymbol
		with: aBlock.
	result := self 
				resolveSymbol: aSymbol
				symbolList: self oopNil
				ifAbsent: [nil].
	self gbsMessenger 
		statusTag: nil
		message: '(s%1) completed GbsSession>>uncachedForwarderAt:..., result = %2'
		with: self sessionId
		with: result.
	result isNil ifTrue: [^aBlock value].
	^result gbsAsUncachedForwarderInSession: self
]

{ #category : 'private' }
GbsSession >> primcheckAuth: arrayOfGSObjects 
[
	"Private"

	^self sessionCritical: 
			[GbsError 
				primResultOrError: (self serverInterface checkAuth: arrayOfGSObjects)
				verifyArgs: 
					[GbsError 
						verify: arrayOfGSObjects
						is: Array
						of: GbxDelegate]
				session: self]
]

{ #category : 'private' }
GbsSession >> remoteSession
[

	^(OGsCurrentSession asGSObjectInSession: self)
		remotePerform: #currentSession
]

{ #category : 'private' }
GbsSession >> unmappedClassReplicatorClass
[

	^GbxUnmappedClassReplicator
]

{ #category : 'private' }
GbsSession >> replicationClass
[
	"No stats, use the plain version."

	^GbxReplication
]

{ #category : 'private' }
GbsSession >> validateAllDirty
[
	"OBSOLETE, needs update if it is to actually work.
	Dirty are tracked both by a dirty bit on a delegate and by inclusion
	 in the session dirtyPool. This ensures that both are consistent with
	 each other for a given session. If both are not correct then dirty
	 objects won't be flushed to GS."
	"	GBSM currentSession validateAllDirty.	"

	| errors |
	self halt: 'Not currently operational. Hasn''t been tested in a long time.'.

	errors := OrderedCollection new.
	self sessionCritical: 
			[| allDirty |
			allDirty := dirtyPool copy.
			gbsm clientMap keysAndValuesDo: 
					[:client :delegates |
					| delegate |
					delegate := delegates forSession: self.
					(delegate notNil and: [(delegates isKindOf: GbxStructureSync) not])
						ifTrue: 
							[| bitDirty sessionDirty |
							bitDirty := delegate isStDirty.
							sessionDirty := self isInDirtyPool: client.
							bitDirty == sessionDirty
								ifFalse: 
									[| msg |
									msg := bitDirty
												ifTrue: 
													['Delegate %2 is marked dirty, but client %1 wasn''t in session dirty pool.']
												ifFalse: 
													['Client %1 in session dirtyPool, but delegate %2 wasn''t marked dirty.'].
									errors add: (Array with: msg with: client with: delegate)].
							sessionDirty ifTrue: [allDirty remove: client]]].
			allDirty do: 
					[:ea |
					errors add: (Array
								with: 'Object %1 was in session dirtyPool but isn''t in StToGs cache.'
								with: ea)]].
	errors isEmpty
		ifFalse: 
			[| sd fd |
			sd := GbsConfiguration current stubDebugging: true.
			fd := GbsConfiguration current forwarderDebugging: true.
			
			[errors do: 
					[:a |
					self gbsMessenger comment: (a at: 1)
						withArguments: (a copyFrom: 2 to: a size)].
			self gbsMessenger comment: 'There were %1 dirty marking errors.'
				with: errors size]
					ensure: 
						[GbsConfiguration current stubDebugging: sd.
						GbsConfiguration current forwarderDebugging: fd]].
	^errors isEmpty
]

{ #category : 'private' }
GbsSession >> replicatorClassForClasses
[

	^GbxClassReplicator
]

{ #category : 'private' }
GbsSession >> replicatorClassForMetaclasses
[

	^GbxMetaclassReplicator
]

{ #category : 'private' }
GbsSession >> clampManagerClass
[

	^GbxClampManager
]

{ #category : 'private' }
GbsSession >> replicatorManagerClass
[

	^GbxReplicatorManager
]

{ #category : 'private' }
GbsSession >> resetClassOrganizer
[

	"Private.  Cause the class organizer to be rebuilt on demand"
	gsClassOrganizer := nil
]

{ #category : 'private' }
GbsSession >> serverInterfaceDo: aBlock 
[
	^self sessionCritical: [aBlock value: serverInterface]
]

{ #category : 'private' }
GbsSession >> checkSession
[
	"Validate that this session has a valid id.  If not, raise an error 
	 which identifies the cause of death, if available."

	self hasValidSessionId ifFalse: [GbsError raiseBadSessionIdFor: self]
]

{ #category : 'private' }
GbsSession >> gemTimeZone
[
	"Return a proxy for this session's default TimeZone instance.
	In server versions starting with GemStone/64 2.2 and later, 
	and in servers with patched time zone support, TimeZone 
	has been replaced with a new version of TimeZone which supports
	the Olsen database. The older version is called ObsoleteTimeZone
	in those servers.  "

	gemTimeZone isNil 
		ifTrue: 
			[gemTimeZone := (OTimeZone asGSObjectInSession: self) 
						unsynchronizedPerform: #current].
	^gemTimeZone
]

{ #category : 'private' }
GbsSession >> forwarderReplicatorClass
[

	^GbxForwarderReplicator
]

{ #category : 'private' }
GbsSession >> sessionCritical: aBlock 
[
	"Private.  Evaluate aBlock while excluding any other thread from
	 doing operations such as a commit, abort, flush, or critical: against this session."

	self sessionCriticalAssertionChecks.
	^sessionProtect critical: 
			[self checkSession.
			aBlock value]
]

{ #category : 'private' }
GbsSession >> gsCurrentSession
[
	"Returns an uncached forwarder to the GsCurrentSession instance on the server that
	corresponds to the receiver."

	^self remoteSession gbsAsUncachedForwarderInSession: self
]

{ #category : 'private' }
GbsSession >> hasValidSessionId
[
	"Private.  The danger of using this method is it trusts
	 the Smalltalk state of the sessionId.  If our actual
	 connection to the repository has been lost, the sessionId
	 instance variable might be a lie.  For a more reliable
	 answer, send #isLoggedIn."

	^sessionId ~~ 0
]

{ #category : 'private' }
GbsSession >> sessionCriticalAssertionChecks
[
	"This method asserts in short that you must hold the session semaphore
	in order to hold any of the other interesting GBS semaphores. Or you must
	hold none of the semaphores"
	"The temporary variables cache the values of the conditions, 
	so in a debugger you can tell which condition caused the assertion failure."

	| stObjectCacheHeld sessionListProtectHeld gciCallProtectHeld |
	
	[(sessionProtect isActiveProcessInCriticalRegion not and: 
			[(stObjectCacheHeld := gbsm hasCacheWriteCriticalAccess)
				| (sessionListProtectHeld := gbsm sessionListProtect isActiveProcessInCriticalRegion)
					| (gciCallProtectHeld := GbxGciCallSequencer isGciCallProtectHeld)])
		ifTrue: 
			['stObjectCacheHeld: ' , stObjectCacheHeld printString , ' sessionListProtectHeld: ' , sessionListProtectHeld printString
				, ' gciCallProtectHeld: ' , gciCallProtectHeld printString]
		ifFalse: [false]]
			gbxAssertEquals: false
			message: 'Semaphores were acquired out of sequence. Deadlocks could occur if session semaphore is obtained after other semaphores.'
]

{ #category : 'private - connectors at login' }
GbsSession >> connectClassConnectorsTypeNoneIn: allConnectors addFailedConnectorsTo: failedConnectors addMessagesTo: messages
[
	"Private.  Used at login time.
	The sender must hold my sessionProtect.
	Bulk connect the qualifying connectors."

	| toConnect behaviorDelegates |
	toConnect := (allConnectors
				select: [:connector | connector isClassConnectorTypeNone]) asArray.
	behaviorDelegates := self
				fetchBehaviorDelegatesForClassConnectors: toConnect.
	1 to: toConnect size
		do: 
			[:i |
			| conn classDel metaclassDel |
			conn := toConnect at: i.
			classDel := behaviorDelegates at: i * 2 - 1.
			metaclassDel := behaviorDelegates at: i * 2.
			classDel = self oopNil
				ifTrue: 
					[failedConnectors add: conn.
					messages add: 'failed bulk name resolution']
				ifFalse: 
					[
					[| clientClass |
					clientClass := conn resolveSTObjMustBeDefined: true.
					self
						connectClientClass: clientClass
						toServerClass: classDel
						serverMetaclass: metaclassDel
						forConnector: conn]
							on: GbsError hostErrorSignal
							do: 
								[:ex |
								failedConnectors add: conn.
								messages add: ex errorString.
								ex return]]]
]

{ #category : 'private - connectors at login' }
GbsSession >> fetchBehaviorDelegatesForFastConnectors: connectors
[
	"Private.  Used at login time.
	The sender must hold my sessionProtect.
	Answer an array of delegates, a pair of delegates for each fast connector in toConnect.
	The first delegate of the pair is for the class, the second for the metaclass.
	If the connector's oop is not that of a class, the 
	class delegate will be oopNil and the metaclass delegate will be meaningless."

	| executeString arrayOfOops |
	connectors isEmpty ifTrue: [^self].
	executeString := WriteStream on: (String new: 500).

	"Each temporary name must be an existing symbol on the server. 
	Or else, if the stone is in restore mode, we can't login because
	symbol creation is restricted. Temporary variable names are 
	created as symbols during method compliation. 
	That's why these temp names seem somewhat odd"
	executeString nextPutAll: '
		| nums  asOop |
		nums := #('.
	connectors do: 
			[:connector |
			executeString
				nextPutAll: (connector resolveGSObjInSession: self) oopValue printString.
			executeString space].
	executeString
		nextPutAll: ').
		asOop := Array new: nums size * 2.
		1 to: nums size
			do: 
				[:i | 
				| cls isClass |
				cls := Object _objectForOop: (nums at: i).
				isClass := cls isBehavior and: [cls isMeta not].
				asOop
					at: i * 2 - 1 put: (isClass ifTrue: [cls asOop] ifFalse: [nil]);
					at: i * 2 put: (isClass ifTrue: [cls class asOop] ifFalse: [nil])].
		^asOop'.

	"Bulk resolve on the server - one network round trip"
	arrayOfOops := self unsynchronizedEvaluate: executeString contents.
	^arrayOfOops collect: 
			[:oop |
			oop == nil ifTrue: [nil] ifFalse: [GbxDelegate oopValue: oop session: self]]
]

{ #category : 'private - connectors at login' }
GbsSession >> connectAllConnectors
[
	"Private.  This message should be sent at login time.
	The sender must hold my sessionProtect."

	| allConnectors toConnect failedConnectors messages |
	allConnectors := gbsm connectorList copy.
	allConnectors addAll: parameters connectorList.
	toConnect := allConnectors
				select: [:connector | connector connectionCondition cull: self].
	failedConnectors := OrderedCollection new.
	messages := OrderedCollection new.
	self
		connectFastConnectorsIn: toConnect
		addFailedConnectorsTo: failedConnectors
		addMessagesTo: messages.
	self
		connectClassConnectorsTypeNoneIn: toConnect
			addFailedConnectorsTo: failedConnectors
			addMessagesTo: messages;
		updateInstVarNamesAndClamps.	"Bulk fetch instvar names for the connectors above. The ones below must be done one at a time."
	self
		connectOtherConnectorsIn: toConnect
		addFailedConnectorsTo: failedConnectors
		addMessagesTo: messages.	"Bulk fetch instvar names for the connectors above. The ones below must be done one at a time."
	"Handle failed connectors.  If RemoveInvalidConnectors, remove them.  Else,
	 if Confirm is true, prompt for their removal. Else, just show a transcript comment if verbose is true"
	self handleFailedConnectors: failedConnectors messages: messages
]

{ #category : 'private - connectors at login' }
GbsSession >> fetchBehaviorDelegatesForClassConnectors: connectors
[
	"Private.  Used at login time.
	The sender must hold my sessionProtect.
	Answer an array of delegates, a pair of delegates for each class connector in toConnect.
	The first delegate of the pair is for the class, the second for the metaclass.
	If the connector's server-side name does not resolve, or does not resolve to a class, the 
	class delegate will be oopNil and the metaclass delegate will be meaningless."

	| objectAndDictionaryNames executionString arrayOfOops |
	connectors isEmpty ifTrue: [^self].
	objectAndDictionaryNames := OrderedCollection new.
	connectors do: 
		[:connector |
		objectAndDictionaryNames
			add: connector gsName;
			add: (connector hasDictionaryName ifTrue: [connector dictionaryName] ifFalse: [nil])].

	executionString := WriteStream on: (String new: 500).
	executionString nextPutAll: '
			"Each temporary name must be an existing symbol on the server. 
			Or else, if the stone is in restore mode, we cannot login because
			symbol creation is restricted. Temporary variable names are 
			created as symbols during method compliation. 
			That is why these temp names seem somewhat odd.

			The names array is successive object names and corresponding dictionary names.
			If the dictionary name is nil, look for the named object in the symbol list,
			otherwise look for it in the named dictionary."

			| names userProfile behaviorOops |
			names := #('.
	objectAndDictionaryNames do: [ :each |
		each storeOn: executionString.
		executionString space ].
	executionString nextPutAll: ').
			userProfile := System myUserProfile.
			behaviorOops := OrderedCollection new: names size.

			1 to: names size
				by: 2
				do: 
					[:index | 
					| name dictName cls |
					name := names at: index.
					dictName := names at: index + 1.
					[cls := dictName isNil
						ifTrue:
							[userProfile objectNamed: name]
						ifFalse:
							[(userProfile objectNamed: dictName)
								ifNotNil: [:dict | dict at: name otherwise: nil]]]
						on: Error
						do: [:ex | ^{index. name. dictName. ex messageText}].
					(cls isBehavior and: [cls isMeta not])
						ifTrue: 
							[behaviorOops
								add: cls asOop;
								add: cls class asOop]
						ifFalse: 
							[behaviorOops
								add: nil;
								add: nil]].
			^behaviorOops asArray'.

	"Bulk resolve on the server - one network round trip"
	arrayOfOops := self unsynchronizedEvaluate: executionString contents.
	^arrayOfOops
		collect: [ :oop |
			oop == nil
				ifTrue: [ self oopNil ]
				ifFalse: [ GbxDelegate oopValue: oop session: self ] ]
]

{ #category : 'private - connectors at login' }
GbsSession >> connectOtherConnectorsIn: allConnectors addFailedConnectorsTo: failedConnectors addMessagesTo: messages
[
	"Private.  This message is sent at login time.
	The sender must hold my sessionProtect.
	Connect all connectors that cannot be connected in bulk one at a time."

	| toConnect |
	toConnect := allConnectors reject: 
					[:connector |
					connector isFastConnectorTypeNone or: [connector isClassConnectorTypeNone]].
	toConnect do: 
			[:conn |
			conn connectInSession: self
				ifFail: 
					[:msg |
					failedConnectors add: conn.
					messages add: msg].
			self updateInstVarNamesAndClamps	"Just in case this connector actually connected a class."]
]

{ #category : 'private - connectors at login' }
GbsSession >> connectFastConnectorsIn: allConnectors addFailedConnectorsTo: failedConnectors addMessagesTo: messages
[
	"Private.  This message is sent at login time.
	The sender must hold my sessionProtect.
	For any fast connectors that connect classes, also connect the metaclasses.
	Metaclass connection requires server interaction, which is done in bulk."

	| toConnect behaviorDelegates |
	toConnect := (allConnectors
				select: [:connector | connector isFastConnectorTypeNone]) asArray.
	behaviorDelegates := self
				fetchBehaviorDelegatesForFastConnectors: toConnect.
	1 to: toConnect size
		do: 
			[:i |
			| conn clientClass classDel metaclassDel |
			conn := toConnect at: i.
			clientClass := conn resolveClientObj.
			classDel := behaviorDelegates at: i * 2 - 1.
			metaclassDel := behaviorDelegates at: i * 2.
			((classDel = self oopNil or: [clientClass isBehavior not])
				or: [clientClass isMeta])
					ifTrue: 
						["Not a class on one side or the other, so no metaclass. Just connect normally."
						conn connectInSession: self
							ifFail: 
								[:desc |
								failedConnectors add: conn.
								messages add: desc]]
					ifFalse: 
						[
						[self
							connectClientClass: clientClass
							toServerClass: classDel
							serverMetaclass: metaclassDel
							forConnector: conn]
								on: GbsError hostErrorSignal
								do: 
									[:ex |
									failedConnectors add: conn.
									messages add: ex errorString.
									ex return]]]
]

{ #category : 'private - connectors at login' }
GbsSession >> mapCrucialClasses
[
	"Private.  This message is used at login time.
	The sender must hold my sessionProtect.
	Map certain crucial kernel classes without mapping their metaclasses, to bootstrap the mapping process.
	We need some classes mapped before we can query the server about metaclasses."
	"We also need a null replicator for our delegate class"

	| unmappableClientClasses mappableClientClasses allConnectors |
	replicatorManager initializeFundamentalReplicators.
	unmappableClientClasses := OrderedCollection new: 10.
	unmappableClientClasses
		add: self delegateClass;
		addAll: Boolean withAllSubclasses;
		add: UndefinedObject;
		add: SmallInteger;
		add: Character;
		add: GbxAbstractProxy;
		add: GbsForwarder.
	unmappableClientClasses do: 
			[:specialClass |
			replicatorManager atClient: specialClass
				put: (GbxNullReplicator forClientClass: specialClass
						manager: replicatorManager)].
	"GbxUnauthorizedStub needs a different replicator, but the replicator established here will be replaced
	when the fast connector connects."
	GbxObjectStub withAllSubclasses do: 
			[:stubClass |
			replicatorManager atClient: stubClass
				put: (GbxStubReplicator forClientClass: stubClass manager: replicatorManager)].
	mappableClientClasses := OrderedCollection new.
	mappableClientClasses
		add: ByteString;
		add: ByteSymbol;
		add: Array.
	allConnectors := gbsm connectorList copy.
	allConnectors addAll: parameters connectorList.
	mappableClientClasses do: 
			[:clientClass |
			(allConnectors
				detect:
					[:conn |
					conn isFastConnectorTypeNone and: [conn resolveClientObj = clientClass]]
				ifNone: [nil])
				ifNotNil: [:conn | conn simpleConnectInSession: self]]
]

{ #category : 'private - connectors at login' }
GbsSession >> connectClientClass: clientClass toServerClass: classDel serverMetaclass: metaclassDel forConnector: conn
[
	"Private.  Used at login time.
	The sender must hold my sessionProtect.
	Sender must verify that clientClass is indeed a (non-meta) class.
	Can only be used with pca #none connectors.
	Does not contact the server unless connectVerification is on and there is a previous mapping for the class."

	| verification oldServerClass oldClientClass |
	verification := GbsConfiguration current connectVerification.
	verification
		ifTrue: 
			[oldServerClass := self cacheAtST: clientClass.
			oldClientClass := self clientObjForDelegate: classDel otherwise: nil].
	(verification not or: 
			[conn
				verifyoldST: oldClientClass
				newST: clientClass
				oldGS: oldServerClass
				newGS: classDel
				session: self])
		ifTrue: 
			[self connectClient: clientClass toServer: classDel.
			self connectClient: clientClass class toServer: metaclassDel.
			conn postConnectClient: clientClass server: classDel inSession: self]
]

{ #category : 'private - connectors at login' }
GbsSession >> handleFailedConnectors: failedConnectors messages: messages
[

	| msg |
	failedConnectors isEmpty ifTrue: [^self].
	msg := self userMessageFromFailedConnectors: failedConnectors
				messages: messages.
	GbsConfiguration current verbose ifTrue: [self gbsMessenger comment: msg].
	(configuration removeInvalidConnectors or: 
			[GbsConfiguration current confirm and: 
					["Prompt the user to see if they want to remove invalid connectors"
					self gbsMessenger
						confirm: 'The following connectors failed to connect - remove them?\\%1'
						with: msg]])
		ifTrue: 
			[failedConnectors do: 
					[:conn |
					gbsm removeGlobalConnector: conn.
					parameters removeConnector: conn]]
]

{ #category : 'testing' }
GbsSession >> isBlocking
[
	"Return true if the GemStone communication protocol being used
	 is blocking.  See the config parameter blockingProtocolRpc."

	^serverInterface isBlocking
]

{ #category : 'testing' }
GbsSession >> isLoggedIn
[
	"Return true if I am logged into GemStone, else return false.  This method raises
	 an exception if it detects that the session has died for some reason."

	| isLoggedIn |
	self sessionCriticalNoSessionCheck: 
			[sessionId == 0 ifTrue: [^false].
			isLoggedIn := serverInterface isLoggedIn].
	isLoggedIn gbxIsGSError 
		ifTrue: 
			["Raise the exception.  For fatal errors, this has the side
		 effect of invoking the fatal error event handler (see
		 GbsSession>>initializeEventHandlers), which will clean
		 up this session as though a logout occurred."

			^isLoggedIn process].
	^isLoggedIn	"isLoggedIn must be true at this point."
]

{ #category : 'testing' }
GbsSession >> isRemote
[
	"Returns true if the gem is a remote process.
	 Note: this may return a different answer than
	 'GBSM isRemote', as a vm capable of having a
	 linked gem can also have a remote gem."

	^isRemote == true
]

{ #category : 'testing' }
GbsSession >> isLinked
[
	"Returns true if the gem for this session is linked with
	 the Smalltalk virtual machine.  Note: this may return a
	 different answer than 'GBSM isLinked', as a vm capable
	 of having a linked session can also have a remote session."

	^isRemote == false
]

{ #category : 'testing' }
GbsSession >> usingSharedCache
[
	"Answer boolean whether the gem is using a shared cache."

	"	GBSM currentSession usingSharedCache.	"

	| zeroBasedSlot |
	zeroBasedSlot := ((OSystem asGSObjectInSession: self) 
				unsynchronizedPerform: #myCacheProcessSlot) asLocalObject.
	^zeroBasedSlot >= 0
]

{ #category : 'private - initialization' }
GbsSession >> initializeWithParameters: aGSSessionParameters
[
	"Private.  Initialize my class translation dictionaries and empty my caches"

	sessionId := 0.	"The invalid session ID. Initialized early so isLoggedIn works right away."
	stats := GbxSessionStatResource new.
	stats session: self.
	parameters := aGSSessionParameters copy.	"Subsequent edits to the parameters should not be reflected in this session."
	dependents := serverMap := nil.
	self initializeSpecialConverter.
	sessionProtect := GbxSessionRecursionLock forMutualExclusion.
	self initializeEventHandlers
]

{ #category : 'private - initialization' }
GbsSession >> abortTransaction
[

	"Abort the GemStone transaction for this session, rolling back all modifications
	 made to committed repository objects and providing a new view of the most
	 current committed state of the repository.  If the transaction mode is #autoBegin,
	 then a new transaction is started.  If #manualBegin, a new transaction must be
	 started by sending beginTransaction.  Returns the receiver on successful abort.
	 Returns nil if any dependent denies permission.  User-abort error is ignored."

	"Don't abort if any of my dependents object"
	(self changeRequest: #queryAbort) ifFalse: [ ^nil ].

	self gbsMessenger
		statusTag: #abortTransaction
		message: '(s%1) GbsSession>>abortTransaction'
		with: self sessionId.

	"The remotePerform will flush this session's dirty client objects before abort,
	 so 'temps' can survive the abort.  After the abort, client replicates of dirty
	 GemStone objects will be updated."
	self systemProxy remotePerform: #abortTransaction.
	self postAbort.

	self gbsMessenger
		statusTag: nil
		message: '(s%1) completed GbsSession>>abortTransaction'
		with: self sessionId.
]

{ #category : 'private - initialization' }
GbsSession >> initialize
[
	"Private. Early initialization, before any attempt to log in."

	notCachedToken := Smalltalk
		at: #NotCachedToken
		ifAbsent: [
			GbsSessionManager initialize.
			Smalltalk at: #NotCachedToken ifAbsentPut: [ 'Not cached' copy ] ].
	(notCachedToken respondsTo: #gbxIsImmutable:)
		ifTrue: [ notCachedToken gbxIsImmutable: true ].
	gbsm := GBSM.	"a-caching we will go... (shared var lookups are expensive if done with high frequency)"
	sessionDisplayString := 'Session (not yet logged in)'.
	activeInteractions := IdentitySet new.
	nestingLevel := 0.
	isUnwindingAsyncAbort := false.
	replicatorManager := self replicatorManagerClass newForSession: self.
	self resetAsyncAbortActions.
	^self
]

{ #category : 'private - initialization' }
GbsSession >> initializeServerInterface
[
	serverInterface := gbsm serverInterfaceClass forSession: self.
	self initializeStatAdaptors
]

{ #category : 'private - initialization' }
GbsSession >> initializeStatAdaptors
[
	"Initialize components that have stat adaptors - disable stats"

	serverInterface := serverInterface statResource: nil.
	self sessionCriticalNoSessionCheck:
		[sessionProtect := sessionProtect statAdaptor: nil]
]

{ #category : 'private - testing' }
GbsSession >> initializeIsRemote
[
	"Private. Should only be sent once immediately after login, as it makes GCI calls
	 which cannot be made in all circumstances."

	isRemote := 
			[self sessionCritical: 
					[GbsError
						primUnpolledResultOrError: self serverInterface sessionIsRemote
						verifyArgs: [true]
						session: self]]
					on: GbsInterfaceError , GbsGemStoneError
					do: [:ex | ex return: nil]
]

{ #category : 'private - testing' }
GbsSession >> isSingleTrip
[
	"Answer false if using the legacy multi-trip interface; 
	true if using the single-trip (GciStoreTravDoTravRefs) interface introduced in GS64 2.2.5.x"
	
	^serverInterface isSingleTrip
]

{ #category : 'testing' }
GbsSession >> mainStatsEnabled
[
	"When main stats are enabled, a session is an instance of GbsSessionWithStats"

	^false
]

{ #category : 'accessing' }
GbsSession >> statResource
[
	^stats
]

{ #category : 'private - testing' }
GbsSession >> hasCriticalAccess
[
	"Answer whether the active process can access this dictionary right now"

	^sessionProtect isActiveProcessInCriticalRegion
]

{ #category : 'private - testing' }
GbsSession >> critical: criticalBlock unlessBlocked: blockedBlock onError: errorBlock retryFor: milliseconds
[
	"this method should be used sparingly. If the result of the session critical access is
	the symbol #blocked, this method will fail."

	| endTime answer |
	endTime := Time millisecondClockValue + milliseconds.
	answer := #blocked.
	[answer == #blocked and: [Time millisecondClockValue < endTime]] whileTrue: 
			[
			[answer := self critical: criticalBlock unlessBlocked: [#blocked].
			(Delay forMilliseconds: 10) wait]
					on: Error
					do: [:ex | ^errorBlock value: ex]].
	^answer == #blocked ifTrue: [blockedBlock value] ifFalse: [answer]
]

{ #category : 'private - testing' }
GbsSession >> critical: criticalBlock unlessBlocked: blockedBlock onError: errorBlock
[

	^[self critical: criticalBlock unlessBlocked: blockedBlock] on: Error do: errorBlock
]

{ #category : 'private - testing' }
GbsSession >> critical: criticalBlock unlessBlocked: blockedBlock 
[
	^sessionProtect critical: criticalBlock unlessBlocked: blockedBlock
]

{ #category : 'private - testing' }
GbsSession >> isStreamsImplementationPortable
[
	"This method is used during login, so it must have a minimal implementation.
	 Replication is not allowed at that point."

	^(self unsynchronizedEvaluate: 'PositionableStream isPortableStreamImplementation') "= OTrue" asLocalObject	"Might work, Booleans are specials."
]

{ #category : 'private - clamping' }
GbsSession >> removeClampedObject: aClientObject withDelegate: aDelegate
[
	"Private.  Remove <anObject> from the list of 'id' clamps in the clamp specification.
	If not present, ignore."

	replicatorManager removeIdentityClampForClient: aClientObject
		withDelegate: aDelegate
]

{ #category : 'private - clamping' }
GbsSession >> addClampedObject: aClientObject withDelegate: aDelegate
[
	"Private.  Add the object to the list of 'id' clamps in all of my clamp specifications."

	replicatorManager addIdentityClampForClient: aClientObject
		withDelegate: aDelegate
]

{ #category : 'private - clamping' }
GbsSession >> replicationSchemeForSet: setSymbol
[

	^self sessionCritical: [replicatorManager replicationSchemeForSet: setSymbol]
]

{ #category : 'private - clamping' }
GbsSession >> currentReplicationScheme
[
	"Private to GBS. Answer the current replication scheme for this thread (Smalltalk Process). 
	If none, answer the scheme for the session. Note this answers a GbxReplicationScheme, 
	not the symbol by which it is known."

	^self sessionCritical: [replicatorManager currentReplicationScheme]
]

{ #category : 'private - clamping' }
GbsSession >> updateInstVarNamesAndClamps
[

	replicatorManager updateInstVarNamesAndClamps
]

{ #category : 'private - clamping' }
GbsSession >> invalidateSchemeWithSelector: aSelector
[
	"If I have a scheme identified by aSelector, and it's valid, invalidate it and answer true.
	Otherwise, answer false."

	^replicatorManager invalidateSchemeWithSelector: aSelector
]

{ #category : 'private - clamping' }
GbsSession >> updateClassClampForReplicator: replicator
[
	"Sender must hold my sessionProtect"

	replicatorManager updateClassClampForReplicator: replicator
]

{ #category : 'private - gs object management' }
GbsSession >> swizzleAlteredOops: alteredDelegatePairs
[
	"Private.  The elements of alteredDelegatePairs are pairs of GemStone Delegates,
       old delegate and new delegate in that order, of GemStone objects whose oops have
	 changed.  An old delegate may be (and probably is) mapped to a client object. The new
	delegate should not be mapped to a client object, and there should be no references to this delegate except those on the stack. We must map the old delegate's client object to the new delegate, and change any references to the old delegate to go to the new delegate."
	"Sender must hold my sessionProtect."

	self cacheCritical: 
			[1 to: alteredDelegatePairs size
				by: 2
				do: 
					[:n |
					| oldDel newDel oldClientObj newClientObj |
					oldDel := alteredDelegatePairs at: n.
					newDel := alteredDelegatePairs at: n + 1.
					oldClientObj := serverMap clientAtOop: oldDel.
					newClientObj := serverMap clientAtOop: newDel.
					newClientObj ~~ notCachedToken
						ifTrue: [self gbsMessenger error: 'Attempt to swizzle to already-mapped oop'].
					serverMap removeOop: oldDel.
					serverMap removeOop: newDel.
					oldDel gbxBecome: newDel.
					oldClientObj == notCachedToken
						ifTrue: [serverMap delegateForOop: oldDel]
						ifFalse: [serverMap atOop: oldDel putClient: oldClientObj]]]
]

{ #category : 'private - gs object management' }
GbsSession >> dirtyGSObjectsInit
[
	"Private.  This method serves two purposes:  First, it must be called to turn on the dirty object set feature.  The gem will not maintain a dirty object set, or signal pre-abort and pre-commit events, until this method is called the first time.  Once the feature is turned on, however, it will remain on until the session logs out.  Second, this method can be called at any time to empty the dirty set."

	GbsError 
		primResultOrError: (self 
				sessionCritical: [self serverInterface dirtyObjectsInit])
		verifyArgs: [true]
		session: self
]

{ #category : 'private - gs object management' }
GbsSession >> getFreeOops: numberOfOops 
[
	"Private.  Allocates GemStone object identifiers without creating objects,
	 and returns these as an array of GbsObjects. A GbsObject returned by
	 this method remains allocated to this session until it is logged out, or
	 the object is sent one of the create* messages.  GbsObjects returned by
	 this method may ONLY be used if subsequently sent a create* message,
	 or stored as a value in a GbsObject>>store* message send, or used as
	 the objId in a GbxObjectReport used by the storeValues: method.

	 If a GbsObject returned from this method is used as a value in a store
	 call before it is sent a create* message, then an 'unresolved foward
	 reference' is created in GemStone object memory. This is a reference to
	 an object that doesn't exist yet.  This forward reference must be satisfied
	 by sending it a create* message before a commit can be successfully executed.

	 If a GemStone commit is attempted prior to satisfying all of the unresolved forward
	 references, an error will be generated and commit will return false.  In this case,
	 create can be used to satisfy the forward references and commit can be reattempted.

	 An abort will remove all unsatified forward references from the session's object
	 space, just as it removes any other uncommitted modifications."

	^GbsError 
		primUnpolledResultOrError: (self 
				sessionCritical: [serverInterface getFreeOops: numberOfOops])
		verifyArgs: [GbsError verify: numberOfOops is: SmallInteger]
		session: self

	"Use of #primUnpolledReultOrError:... was to fix BUG18642."
]

{ #category : 'private - gs object management' }
GbsSession >> getFreeOop
[
	"Private.  Return an oop from this GbsSession's oop cache.  
	This is an oop that has been allocated to this session, for which an object has not actually been created.  "

	^freeOops nextFreeOop
]

{ #category : 'private - gs object management' }
GbsSession >> delegateForOop: anOop
[
	"Answer the canonical delegate for the given oop, which MUST not be a server special oop"
	"Sender must hold my sessionProtect"

	^serverMap delegateForOop: anOop
]

{ #category : 'private - gs object management' }
GbsSession >> checkAuth: arrayOfGSObjects
[

	"Private.  For each object in arrayOfGSObjects, this method checks the authorization for the current user.  The authorization for each input object is returned in the corresponding index of the return array.  Each result is represented as #none, #read, or #write.  The authorization reported for each object is the result of a complete authorization check, including owner, group, and world authorization(s).  Special objects such as SmallIntegers will always be reported as #read authorization.  Reports an error if any member of arrayOfGSObjects is not a legal oop."

	| auths result |
	auths := self primcheckAuth: arrayOfGSObjects.
	result := Array new: auths size.
	1 to: auths size do: [ :i |
		result at: i put: (#( none read write ) at: (auths at: i)) ].
	^result
]

{ #category : 'private - gs object management' }
GbsSession >> saveObjects: delegates
[
	"Delegates must be a sequenceable collection of delegates"
	"Private.  Add each object in delegates to the gem's export set. This prevents their being garabage collected in GemStone, and in 64-bit GemStone has other effects as well. This does NOT cause the objects to be referenced from a permanent object, and thus there is no guarantee that they will be saved in GemStone after this session logs out."

	^GbsError
		primResultOrError: (self sessionCritical: 
					[| result |
					result := serverInterface saveObjects: delegates.
					result gbxIsGSError ifFalse: [delegates do: [:del | del nowExported]].
					result])
		verifyArgs: 
			[GbsError verify: delegates is: SequenceableCollection of: GbxDelegate]
		session: self
]

{ #category : 'private - accessing' }
GbsSession >> gsClassOrganizer
[
	"Private.  Answer an instance of a GemStone ClassOrganizer."

	gsClassOrganizer == nil ifTrue: [ self updateClassOrganizer ].
	^gsClassOrganizer
]

{ #category : 'private - accessing' }
GbsSession >> myUserProfileProxy
[
	"Private"

	^self systemProxy unsynchronizedPerform: #myUserProfile
]

{ #category : 'private - accessing' }
GbsSession >> noCasePatternMatchOn: aString
[

	| executeString pattern |
	pattern := OrderedCollection new.
	aString piecesCutWhere: [:each :next | each = $* or: [each = $?]]
		do: 
			[:piece |
			(piece last = $? or: [piece last = $*])
				ifTrue: 
					[pattern add: (piece copyFrom: 1 to: piece size - 1).
					pattern add: piece last]
				ifFalse: [pattern add: piece]].
	executeString := '[:pattern |  | matches |
		matches := OrderedCollection new.
		self keysDo: [:each |
			(each asSymbol asString findPatternNoCase: pattern startingAt: 1) = 0 ifFalse: [
				"because #findPatternNoCase: finds the pattern
				anywhere in the symbol, we need to make sure
				the lowercase search does a true match." 
					(each asLowercase matchPattern: pattern) ifTrue:[
				matches add: each]]].
		matches]'.
	^self
		evaluateBlock: executeString
		withArguments: (Array with: pattern asArray)
		context: self allSymbols
]

{ #category : 'private - accessing' }
GbsSession >> allSymbols
[
	"Returns a GbsObject for AllSymbols.  In GemStone64, this was removed
	 from Globals and is resolvable only from SymbolUser's UserProfile."

	^self unsynchronizedExecute: '((AllUsers userWithId: ''SymbolUser'') resolveSymbol: #AllSymbols) value'
]

{ #category : 'private - accessing' }
GbsSession >> symbolListProxy
[
	"Private"

	^self myUserProfileProxy unsynchronizedPerform: #symbolList
]

{ #category : 'private - accessing' }
GbsSession >> caseSensitivePatternMatchOn: aString
[

	| executeString pattern |
	pattern := OrderedCollection new.
	aString piecesCutWhere: [:each :next | each = $* or: [each = $?]]
		do: 
			[:piece |
			(piece last = $? or: [piece last = $*])
				ifTrue: 
					[pattern add: (piece copyFrom: 1 to: piece size - 1).
					pattern add: piece last]
				ifFalse: [pattern add: piece]].
	executeString := '[:pattern |  | matches |
		matches := OrderedCollection new.
		self keysDo: [:each |
			(each asSymbol asString matchPattern: pattern) ifTrue: [
				matches add: each]].
		matches]'.
	^self
		evaluateBlock: executeString
		withArguments: (Array with: pattern asArray)
		context: self allSymbols
]

{ #category : 'private - accessing' }
GbsSession >> symbolsMatching: aString
[
	"Private.  Return a list of Symbols that match <aString> which may contain wild-card characters * and ?."
	"Rules.
		If I search for methods called 'from:', I expect only those.
		If I search for methods matching '*from:', I expect only those ending in 'from:' (ignoring case, for convenience).
		If I search for methods matching '*From:', per Martin's suggestion, one would expect the match to be case sensitive.
		If I search for methods called 'copy', I expect only those.
		If I search for methods called 'copy*', I expect all those beginning with 'copy' (ignoring case, for convenience).
		...
		If I want to search for methods embedding 'from', I would need to search for *from*', which would match any selector with 'from' starting in any position. "

	aString isEmpty ifTrue: [^Array new].
	((aString includes: $*) or: [aString includes: $?])
		ifFalse: [^Array with: aString asSymbol].
	(aString detect: [:char | char isUppercase] ifNone: []) isNil
		ifFalse: [^self caseSensitivePatternMatchOn: aString].
	^self noCasePatternMatchOn: aString
]

{ #category : 'private - accessing' }
GbsSession >> serverInterface
[

	"Private.  Return the object implementing the interface to the c repository calls"
	serverInterface isNil ifTrue: [
		^GbsError raiseBadSessionIdFor: self.
	].
	^serverInterface
]

{ #category : 'private - accessing' }
GbsSession >> myDependents: dependentsOrNil
[
	"Private.  Set the receivers dependents."

	dependents := dependentsOrNil
]

{ #category : 'private - accessing' }
GbsSession >> clampedObjects
[
	"Private -- used by tests."

	^replicatorManager identityClamps
]

{ #category : 'private - accessing' }
GbsSession >> classSearchString
[

	^'
	"Answer a five element array for each match, comprising:
		className, its Oop, symbol dictionary name, its Oop, display string
	 The matches are ordered by their display strings."
[:matchPattern |
	| matches dupFilter |
	matches := Array new.
	System myUserProfile symbolList do: [:eachDict |
		| dictName |
		dictName := eachDict name.
		eachDict keysAndValuesDo: [:eachName :eachValue |
			(eachValue isBehavior
				and: [(eachName findPatternNoCase: matchPattern startingAt: 1) == 1])
					ifTrue: [matches add: {eachName. eachValue asOop. dictName. eachDict asOop. eachName asString}]]].
	dupFilter := Dictionary new.
	matches do: [:eachQuint |
		(dupFilter at: eachQuint first "class name" ifAbsentPut: [Array new])
			add: eachQuint].
	"Find those with duplicate class names and revise their display strings to include symbol dictionary name"
	dupFilter := dupFilter select: [:each | each size > 1].
	dupFilter do: [:eachSet |
		eachSet do: [:eachQuint |
			eachQuint
				at: 5 "display string"
				put: (eachQuint at: 1 "class name"), '' ('', (eachQuint at: 3 "dictionary name"), '')'']].
	matches := matches asSortedCollection: [:a :b | a last < b last "display strings"].
	matches asArray]'
]

{ #category : 'private - accessing' }
GbsSession >> systemProxy
[
	"Private"

	^OSystem asGSObjectInSession: self
]

{ #category : 'private - accessing' }
GbsSession >> updateClassOrganizer
[
	"Private"

	GbsConfiguration current verbose 
		ifTrue: [self gbsMessenger comment: 'Updating GemStone class organizer...'].
	gsClassOrganizer := self execute: 'ClassOrganizer new'.
	GbsConfiguration current verbose 
		ifTrue: [self gbsMessenger commentAdd: 'done.']
]

{ #category : 'private - accessing' }
GbsSession >> defaultDictionary
[
	"Private - Creates if not present."

	^self symbolDictionaryNamed: self class defaultDictionaryName
]

{ #category : 'private - accessing' }
GbsSession >> dictionaryNamesMatching: aString
[
	"Private.  Return a list of class names that match <aString> which may contain wild-card characters * and ?."
	"since this is a class name match, it is convenient to make the first char capitalized"

	^self
		evaluateBlock: self dictionarySearchString
		with: aString asGSPattern
		context: nil
]

{ #category : 'private - accessing' }
GbsSession >> dictionarySearchString
[

	^'
[:origPattern |
| matches searchBlock |
matches := OrderedCollection new.
searchBlock :=
		[:pattern |
		System myUserProfile symbolList do:
				[:aDict |
				(aDict name findPatternNoCase: pattern startingAt: 1) == 1
									ifTrue: [matches add: aDict name]]].
searchBlock value: origPattern.
matches isEmpty
	ifTrue: [searchBlock value: origPattern , $*]
	ifFalse: 
		[origPattern size == 1
			ifTrue: 
				["Check for exact match except for case"
				| matchSize exactMatches |
				matchSize := origPattern first size.
				exactMatches := matches select: [:each | each size == matchSize].
				exactMatches isEmpty ifFalse: [matches := exactMatches]]].
matches]'
]

{ #category : 'private - accessing' }
GbsSession >> myDependents
[
	"Private.  Answer the receiver's dependents or nil."

	^dependents
]

{ #category : 'private - session management' }
GbsSession >> basicLogout
[
	"Private. Log me out of the server. If I'm already logged out, ignore the resulting error.
	Has no effect in the client,  the client cleanup is done in senders of this message."

	serverInterface isNil ifFalse: [serverInterface logout]	"This could answer a fatal GbsError, but we're ignoring that error."
]

{ #category : 'private - session management' }
GbsSession >> basicX509Login
[
	"Private.  Log into the server. Answer true if login successful, false otherwise."
	"Sender must hold sessionProtect."

	| error errorHolder isLoggedIn |
	self gbsMessenger statusTag: #basicLogin
		message: 'GbsSession>>basicX509Login'.
	configuration := GbsConfiguration current copy.
	self allocateCaches.
	self initializeServerInterface.
	GBSM initializeServerInterfaceIfNeeded.
	errorHolder := Array new: 1.
	"Between the GciLogin and the setting of sessionId, we don't know how to log out, 
	so we can't allow the process to be terminated during this time."
	[] ensure: 
			[sessionId := serverInterface loginX509: parameters errorHolder: errorHolder].
	isLoggedIn := sessionId ~~ 0.
	error := errorHolder at: 1.
	error gbxIsGSError
		ifTrue: 
			[isLoggedIn ifTrue: [self fixUpDelegatesFor: error].
			error
				processVerifyArgs: [GbsError verify: parameters is: GbsX509SessionParameters]].
	self gbsMessenger
		statusTag: nil
		message: (isLoggedIn
				ifTrue: ['(s%1) login successful, ID = %1']
				ifFalse: ['login failed.'])
		with: self sessionId.
	^isLoggedIn
]

{ #category : 'private - session management' }
GbsSession >> loginLinked: linked 
[
	"Private.  If linked (a Boolean) is true, the login attempt will be for a linked session.  If false, rpc.  Returns the receiver if login is successful, nil otherwise.
	If login does not complete for any reason, log out to clean up."

	| result |
	result := nil.
	[
	self sessionCriticalNoSessionCheck: 
			[(self basicLoginLinked: linked)
				ifTrue: 
					[self postLogin.
					result := self]]]
			ifCurtailed: [self logout].
	result == self
		ifTrue: [self finishPostLogin].
	^result
]

{ #category : 'private - session management' }
GbsSession >> cleanUp
[
	"GBS Private. Akin to #quietLogout, but does not actually 
	ask the gci library to logout. Instead, just do the surrounding
	work."

	self sessionCriticalNoSessionCheck: 
			[self preLogout.
			self postLogout]
]

{ #category : 'private - session management' }
GbsSession >> loginX509
[
	"Private.  Login with x509 parameters, which must already be set.
	 Returns the receiver if login is successful, nil otherwise.
	If login does not complete for any reason, log out to clean up."

	| result |
	result := nil.
	[
	self sessionCriticalNoSessionCheck: 
			[self basicX509Login
				ifTrue: 
					[self postLogin.
					result := self]]]
			ifCurtailed: [self logout].
	result == self
		ifTrue: [self finishPostLogin].
	^result
]

{ #category : 'private - session management' }
GbsSession >> logoutDialog
[

	"Private.  Ask if the user wants to commit before logging out, and give them the chance to cancel the logout"

	| ans commit |
	ans := self gbsMessenger
		confirmOrCancel: 'Commit before logging out %1?'
		with: self.
	ans isNil ifTrue: [ ^self ].
	ans ifFalse: [ ^self logout ].
	commit := self commitTransaction.
	(commit == nil or: [commit == false])
		ifTrue: [(self gbsMessenger confirm: 'Commit denied.  Logout anyway?') ifFalse: [ ^self ]].
	self logout
]

{ #category : 'private - session management' }
GbsSession >> configureGemAbortMaxCrs
[
	"HACK to workaround server bug #49434. See bug #49438."

	[
		self execute: 'System configurationAt: #GemAbortMaxCrs put: 16r3FFFFFFF'
	] on: Exception do: [ ^ self ].
	^ self
]

{ #category : 'private - session management' }
GbsSession >> createTimeZoneConnectors
[
	"we have determined that we are using the new Olsen time
	zone database in the server. Create appropriate connectors"

	| timeZoneInfoClass timeZoneClass timeZoneTransitionClass timeZoneInfoDelegate timeZoneDelegate timeZoneTransitionDelegate |
	timeZoneInfoClass := self gbxResolve: #GbxTimeZoneInfo.
	timeZoneClass := self gbxResolve: #GbxTimeZone.
	timeZoneTransitionClass := self gbxResolve: #GbxTimeZoneTransition.
	timeZoneInfoDelegate := timeZoneInfoClass ifNil: [ nil ] ifNotNil: [ timeZoneInfoClass gbxDelegate ].
	timeZoneDelegate := timeZoneClass ifNil: [ nil ] ifNotNil: [ timeZoneClass gbxDelegate ].
	timeZoneTransitionDelegate := timeZoneTransitionClass ifNil: [ nil ] ifNotNil: [ timeZoneTransitionClass gbxDelegate ].
	((timeZoneInfoDelegate notNil
		and: [(timeZoneInfoDelegate forSession: self) notNil])
		and:
			[timeZoneDelegate notNil
				and: [(timeZoneDelegate forSession: self) notNil]
				and: [timeZoneTransitionDelegate notNil
					and: [(timeZoneTransitionDelegate forSession: self) notNil]]])
		ifTrue: [^self].
	parameters
		addConnectors:
			(Array
				with:
					(GbsClassConnector stName: #'GbxTimeZoneInfo' gsName:
							#TimeZoneInfo)
				with:
					(GbsClassConnector stName: #'GbxTimeZone' gsName: #TimeZone)
				with:
					(GbsClassConnector stName: #'GbxTimeZoneTransition' gsName:
							#TimeZoneTransition))
]

{ #category : 'private - session management' }
GbsSession >> postLogin
[
	"Private.  Things to do immediately after logging in.
	Sender must hold my sessionProtect."

	| manager |
	self isLoggedIn ifFalse: [^self].
	loginTimestamp := DateAndTime now.
	self initializeIsRemote.
	self initializeLoggedInSessionDisplayString.
	"int converter can't be initialized until GCI lib loaded, but must be before connectors connect."
	manager := GbsSessionManager current.
	manager privAddSession: self.
	self dirtyGSObjectsInit.
	self initializeCaches.
	manager currentSession: self.
	manager notifyOfAddedSession: self.	"causes VS session browser to update, so must follow #currentSession: "
	self initializeTimeZone.
	"Event detection and deferred follow-up run after the session critical section unwinds."
	"self startGbsServices."
	GbsConfiguration current verbose
		ifTrue: [self gbsMessenger comment: 'Logged in %1' with: self]
]

{ #category : 'private - session management' }
GbsSession >> finishPostLogin
[
	"Complete login work that should not run while the session critical section
	is still held by the login thread."

	self isLoggedIn ifFalse: [ ^ self ].
	self startEventDetection.
	self startDeferredPostLoginInitialization.
	GbxStatMonitor instance addStatResource: stats.
	^ self
]

{ #category : 'private - session management' }
GbsSession >> enableOopDropping
[
	"per bug #39548-Objects in pure export set should be able to drop from RAM
	Turn on option if connecting to a 3.0+ server"

	[
		self execute: 'System gemConfigurationAt: #GemDropCommittedExportedObjs put: true'
	] on: Exception do: [ ^ self ].
	^ self
]

{ #category : 'private - session management' }
GbsSession >> startDeferredPostLoginInitialization
[
	"These are useful, but they are not required for the login to be usable.
	Keep them off the synchronous login path so GUI login does not block while
	the session is already valid."

	| process |
	process := [
		self hasValidSessionId
			ifTrue: [ [ self enableOopDropping ] on: Error do: [ ] ].
		self hasValidSessionId
			ifTrue: [ [ self configureGemAbortMaxCrs ] on: Error do: [ ] ].
		self hasValidSessionId
			ifTrue: [ [ self getGemIds ] on: Error do: [ ] ] ] gbxNewProcessNamed:
			'GBS PostLogin for ', self printString.
	process priority: Processor userBackgroundPriority.
	process resume.
	^ self
]

{ #category : 'private - session management' }
GbsSession >> fixUpDelegatesFor: error 
[
	"if we got an error on login, the GbsError has contents that are delegates with the wrong sessionId.
	Give them the proper sessionId."

	error serverProcess sessionId: sessionId.
	error category sessionId: sessionId.
	error arguments isNil 
		ifFalse: [error arguments do: [:arg | arg sessionId: sessionId]]
]

{ #category : 'private - session management' }
GbsSession >> postLogout
[
	"Private.  Clean-up required after session has logged out or otherwise terminated"

	| manager |
	self sessionCriticalNoSessionCheck: 
			["Do this work only once per GbsSession"
			self hasValidSessionId ifFalse: [^self].
			gemTimeZone := nil.
			GbxStatMonitor instance removeStatResource: stats.	"Don't try to flush the unexport buffer, or accept any new objects to it."
			self changed: #sessionTerminated.
			self myDependents: nil.
			self emptyCaches.	"Do this before setting sessionId to 0"
			"Once all known delegates for this session are marked dead, 
			 we can remove ourselves from GBSM's list."
			manager := GbsSessionManager current.
			manager disconnectSession: self.
			sessionId := 0.
			((Smalltalk at: #GBSM ifAbsent: [ nil ]) respondsTo: #currentSession)
				ifTrue: [
					[ (Smalltalk at: #GBSM) currentSession == self
						ifTrue: [ (Smalltalk at: #GBSM) currentSession: nil ] ]
						on: Error
						do: [ ] ].
			(parameters respondsTo: #sessionId:)
				ifTrue: [ [ parameters sessionId: nil ] on: Error do: [ ] ].
			[ GbsSessionParameters currentSession == self
				ifTrue: [ GbsSessionParameters currentSession: nil ] ]
				on: Error
				do: [ ].
			[replicatorManager == nil] gbxAssert.
			serverInterface := nil.
			logoutTimestamp := DateAndTime now.
			configuration connectorNilling ifTrue: [parameters nilAllConnectors].
			self initializeLoggedOutSessionDisplayString]
]

{ #category : 'private - session management' }
GbsSession >> preLogout
[
	"Private.  Do any necessary clean-up that must occur before logout.
	Can happen after the session is actually logged out, for fatal errors 
	that do not give us a chance to react before logout.
	It's legal to log out the same session more than once.
	Thus, everything here must be OK to do twice for the same session."

	self stopEventDetection.
	self stopNbWaitSocket.
	self stopProcessBalancer
]

{ #category : 'private - session management' }
GbsSession >> getGemIds
[

	| ids |
	ids := [
		self evaluate: 
				'| current serial description |
				current := GsCurrentSession currentSession.
				serial := current serialNumber.
				description := System descriptionOfSessionSerialNum: serial.
				Dictionary new
					at: #serialNumber put: serial;
					at: #sessionId put: (description at: 10);
					at: #processId put:  (description at: 2);
					yourself'
	] on: Exception do: [ ^ self ].
	(ids respondsTo: #at:ifAbsent:) ifFalse: [ ^ self ].

	gemProcessId :=  ids at: #processId ifAbsent: [ gemProcessId ].
	gemSerialNumber := ids at: #serialNumber ifAbsent: [ gemSerialNumber ].
	gemSessionId := ids at: #sessionId ifAbsent: [ gemSessionId ].

	"Update with the gem ids"
	self initializeLoggedInSessionDisplayString.
	^ self
]

{ #category : 'private - session management' }
GbsSession >> quietLogout
[
	"GBS Private. Do the work of logging out, without asking permission or logging the logout."

	self sessionCriticalNoSessionCheck: 
			[self preLogout.
			[self basicLogout] ensure: [self postLogout]]
]

{ #category : 'private - session management' }
GbsSession >> initializeLoggedInSessionDisplayString
[

	| aStream |
	aStream := WriteStream on: (String new: 100).
	aStream
		nextPutAll: 'Session ';
		print: sessionId;
		nextPutAll: (self isRemote ifTrue: [' (remote) for '] ifFalse: [' (linked) for ']);
		print: parameters;
		nextPutAll: ' PID: ';
		print: gemProcessId;
		nextPutAll: ' Serial #: ';
		print: gemSerialNumber;
		nextPutAll: ' Session ID: ';
		print: gemSessionId.
	sessionDisplayString := aStream contents
]

{ #category : 'private - session management' }
GbsSession >> initializeLoggedOutSessionDisplayString
[

	sessionDisplayString := 'Session (not logged in) for ' , parameters printString
]

{ #category : 'private - session management' }
GbsSession >> basicLoginLinked: linked
[
	"Private.  Log into the server. Answer true if login successful, false otherwise."
	"Sender must hold sessionProtect."

	| passwords error errorHolder isLoggedIn |
	self gbsMessenger statusTag: #basicLogin message: 'GbsSession>>basicLoginLinked: %1' with: linked.
	configuration := GbsConfiguration current copy.
	self allocateCaches.
	linked ifTrue: [configuration blockingProtocolRpc: true].
	self initializeServerInterface.
	GBSM initializeServerInterfaceIfNeeded.
	(linked and: [GBSM isRemote])
		ifTrue: 
			[GBSM changed: #sessionParameters.	"send an update to the session browser to disable the login linked button"
			GbsLinkedLoginError raiseSignal: 'Can''t login linked, shared library is RPC-only.'].
	passwords := parameters passwordsLinked: linked ifCancel: [^false].
	errorHolder := Array new: 1.
	"Between the GciLogin and the setting of sessionId, we don't know how to log out, 
	so we can't allow the process to be terminated during this time."
	[] ensure: [sessionId := serverInterface loginLinked: linked passwords: passwords errorHolder: errorHolder].

	"Make sure passwords are cleared"
	parameters checkPasswords.
	passwords
		at: 1 put: parameters password;
		at: 2 put: parameters hostPassword.
	isLoggedIn := sessionId ~~ 0.
	error := errorHolder at: 1.
	error gbxIsGSError
		ifTrue: 
			[isLoggedIn ifTrue: [self fixUpDelegatesFor: error].
			error processVerifyArgs: 
					[(GbsError verify: linked is: Boolean)
						& (GbsError verifyBytes: parameters gemStoneName)
						& (GbsError verifyBytes: parameters username)
						& (GbsError verify: passwords is: Array)
						& (GbsError verifyBytes: (passwords at: 1))
						& (GbsError verifyBytes: (passwords at: 2))
						& (GbsError verifyBytes: parameters hostUsername)
						& (GbsError verifyBytes: parameters gemService)]].
	self gbsMessenger
		statusTag: nil
		message: (isLoggedIn ifTrue: ['(s%1) login successful, ID = %1'] ifFalse: ['login failed.'])
		with: self sessionId.
	^isLoggedIn
]

{ #category : 'private - session management' }
GbsSession >> initializeTimeZone
[

	^clientTimeZone := TimeZone default
]

{ #category : 'private - session management' }
GbsSession >> initializeTimeZoneFromServer
[
	"predates VW 7.7"
	"initialize a session-specific time zone for this session. 
	If we are not running against a database that supports
	the Olsen timezone database, we leave the session's
	time zone as nil"
	"The current TimeZone is copied because it should
	never be changed on the server and therefore there
	is no value to hanging onto a replicate. Also, it is 
	possible for someone to change a replicate to a forwarder,
	which would break things if done to the timezone."
	"the temporary name must be an existing symbol on the client. 
			Or else, if the stone is in restore mode, we can't login because
			symbol creation is restricted. Apparantly, temporaries are 
			somehow created as symbols during method compliation"

	| useOlsenTimeZones |
	useOlsenTimeZones := self
				evaluate: '
			(Globals at: #TimeZoneInfo ifAbsent:[]) isNil not'.
	useOlsenTimeZones
		ifTrue: 
			[self createTimeZoneConnectors.	"the temporary name must be an existing symbol on the client. 
			Or else, if the stone is in restore mode, we can't login because
			symbol creation is restricted. Apparantly, temporaries are 
			somehow created as symbols during method compliation"
			clientTimeZone := self
						evaluate: '
			| timeZone |
			timeZone := (Globals at: #TimeZoneInfo ifAbsent:[]) isNil not. 
			timeZone ifTrue:[TimeZone current copy] ifFalse:[nil]']
]

{ #category : 'private - cache management' }
GbsSession >> clientObjForDelegate: anOop otherwise: otherwiseObject
[
	"Private to GBS.  If there is an entry for anOop in the serverMap, return the associated client
	 object.  Otherwise, return otherwiseObject."
	"Sender must hold my session's sessionProtect."

	| cachedObj |
	serverMap isNil ifTrue: [^otherwiseObject].
	cachedObj := self lookupOop: anOop.
	^cachedObj == notCachedToken ifTrue: [otherwiseObject] ifFalse: [cachedObj]
]

{ #category : 'private - cache management' }
GbsSession >> connectClient: anObject toServer: oopOrDelegate
[
	"If not already mapped, add entries in the caches relating delegate and anObject."

	| delegate |
	delegate := oopOrDelegate asGSObjectInSession: self.
	"If either the client object or the server obect are immediate objects on their own platform, 
	they should not be added to the cache."
	(anObject isImmediate or: [delegate isSpecial]) ifTrue: [^self].
	self sessionCritical: 
			["May need session semaphore to mark delegate dirty, so must get it first."
			self cacheCritical: 
					[| existingClientObj |
					existingClientObj := serverMap clientAtOop: delegate.
					existingClientObj == anObject
						ifFalse: [self unprotectedConnectPossiblyExistingClient: anObject toServer: delegate]]]
]

{ #category : 'private - cache management' }
GbsSession >> emptyCaches
[
	"Private.  Forget about dirty Smalltalk objects, and remove cache
	 entries for stObjects associated with this session."

	self gbsMessenger statusTag: #cache message: '%1>>emptyCaches.' with: self.
	replicatorManager release.
	replicatorManager := nil.
	self cacheCritical: [gbsm emptyCachesForSession: self].
	self gbxFixMe.	"Should move responsibility for setting dead session flag in delegates to the gsObjectCache, to pick up delegates that do not have a client object."
	serverMap beWeak.	"We need the serverMap around to process post-logout errors in a multi-threaded situation where there's been a fatal error, but if we've had a loss of synchronization due to process termination during a round trip the serverMap may be strongly holding on to lots of garbage."
	dirtyPool := nil.
	freeOops := nil.
	gsClassOrganizer := nil.
	isRemote := nil
]

{ #category : 'private - cache management' }
GbsSession >> disconnectClient: clientObject fromServer: aDelegate
[
	"Private.  Remove entries in the caches relating gsObject and clientObject.
	We expect that clientObject and gsObject are both non-nil.
	 If any of the entries weren't found, no error is reported."
	"If it was a forwarder, remove it from the identity clamp list"

	| delegate |
	delegate := aDelegate forSession: self.
	(delegate isIdentityClamped and: [delegate hasLiveSessionFlag])
		ifTrue: [self removeClampedObject: clientObject withDelegate: delegate].
	"sessionCritical: must always enclose cacheCritical: to avoid deadlock."
	self sessionCritical: 
			[self cacheCritical: 
					["Ignore potential pending dirtiness.  If it's a stub, it's not dirty, so don't
		 bother (remove:ifAbsent: has the side effect of trying to unstub it!)"
					| existingClient |
					
					[existingClient := serverMap clientAtOop: delegate.
					existingClient == notCachedToken or: [existingClient == clientObject]]
							gbxAssertEquals: true
							message: 'Attempted to uncache client, but another object was cached.'.
					"Don't remove the canonical delegate from the dictionary, just put 0 in the client slot."
					serverMap pretendClientIsCollected: delegate.
					"Remove from clientMap"
					gbsm removeAtST: clientObject forSession: self].
			(clientObject gbxIsProxy not and: [clientObject isBehavior])
				ifTrue: 
					[self disconnectReplicatorForClientBehavior: clientObject
						andServerBehavior: aDelegate]]
]

{ #category : 'private - cache management' }
GbsSession >> clientAtOop: anOop 
[
	"Answer the cached client object or NotCachedToken"

	"Sender must hold my session's accessProtect."

	^serverMap clientAtOop: anOop
]

{ #category : 'private - cache management' }
GbsSession >> initializeCaches
[
	"Private.  This should be called at login time.
	The sender must hold my sessionProtect."
	"WARNING: Executing the following code will destroy current Smalltalk/GemStone object relationships"
	"GbsSession allInstancesDo: [ :aGbsSession | aGbsSession isLoggedIn ifTrue: [ aGbsSession initializeCaches ]]"

	gbsm allocateCaches.
	"Connector hashing and equality are based on their resolved Smalltalk object, which changes periodically"
	self mapCrucialClasses.
	parameters rehashConnectors.
	self connectAllConnectors
]

{ #category : 'private - cache management' }
GbsSession >> flushDirtyToGS
[
	"Private.  This method causes all dirty Smalltalk objects associated with this session to be stored in GemStone. 
	Any normal server message send does this.
	Note that if there are dirty objects deeper in the dirtyPool's stack, they will likely *not* get flushed.
	This is, unfortunately, legacy behavior in some nested round trip scenarios, such as on-the-fly class mapping."

	dirtyPool isEmpty ifFalse: [self oopNil remotePerform: #yourself]
]

{ #category : 'private - cache management' }
GbsSession >> isST: anObj connectedToGS: aGSObj
[
	"Private.  Answer true if both the GS->ST and ST->GS caches show anObj and aGSObj connected"

	^self sessionCritical: 
			[(self cacheAtST: anObj) = aGSObj
				and: [(self clientObjForDelegate: aGSObj otherwise: self oopNil) == anObj]]
]

{ #category : 'private - cache management' }
GbsSession >> privateConnectNewClient: clientObject toServer: oop
[
	"Assumes that the client object is newly created, unless it is of an #instancesAreUnique class.
	Answer the canonical delegate for oop."
	"Sender must hold the session semaphore."

	^self
		cacheCritical: [self unprotectedConnectNewClient: clientObject toServer: oop]
]

{ #category : 'private - cache management' }
GbsSession >> unprotectedConnectNewClient: clientObject toServer: oop 
[
	"Assumes that the client object is newly created, unless it is of an #instancesAreUnique class.
	Answer the canonical delegate for oop."

	"Sender must hold session semaphore and cache semaphore."

	| delegate |
	^clientObject gbxBasicClass instancesAreUnique 
		ifTrue: 
			[self unprotectedConnectPossiblyExistingClient: clientObject toServer: oop]
		ifFalse: 
			[delegate := serverMap atOop: oop putClient: clientObject.
			gbsm atNewClient: clientObject putDelegate: delegate.
			"If it's a forwarder or behavior, make sure it gets clamped"
			self clamp: delegate client: clientObject.
			delegate]
]

{ #category : 'private - cache management' }
GbsSession >> dictionaryDepth
[
	"2 if by land, 3 if by GS64 2.0 and later"

	^specialConverter dictionaryDepth
]

{ #category : 'private - cache management' }
GbsSession >> allocateCaches
[
	"Private."

	serverMap := GbxServerMap newForSession: self.
	freeOops := GbxFreeOopStream for: self.
	dirtyPool := GbxDirtyPool newForSession: self
]

{ #category : 'private - cache management' }
GbsSession >> cacheAtST: anObj 
[
	"Private.  If anObj exists in the transparency cache, 
	answer the delegate associated with this session.
	If no such delegate, answer nil."

	| delegates |
	delegates := anObj gbxDelegate.
	^delegates
		ifNil: [ nil ]
		ifNotNil: [ delegates forSession: self ]
]

{ #category : 'private - cache management' }
GbsSession >> basicConnectPossiblyExistingClient: clientObject toServer: oop
[
	"Sender must hold my sessionProtect and the ClientMaps writeProtect semaphores."

	| delegate |
	delegate := serverMap atOop: oop putClient: clientObject.
	gbsm atST: clientObject putGS: delegate.
	^delegate
]

{ #category : 'private - cache management' }
GbsSession >> unprotectedConnectPossiblyExistingClient: clientObject toServer: oop
[
	"We don't know if this object existed previously or not, make sure
	that we do the appropriate checks as we add to the caches.
	Answer the canonical delegate for oop.

	Sender must hold session semaphore and cache semaphore."
	"If it's a forwarder or behavior, make sure it gets clamped"

	| delegate |
	delegate := self basicConnectPossiblyExistingClient: clientObject
				toServer: oop.
	self clamp: delegate client: clientObject.
	(clientObject gbxIsProxy not and: [clientObject isBehavior])
		ifTrue: 
			[replicatorManager mapReplicatorForClientBehavior: clientObject
				serverBehavior: delegate].
	^delegate
]

{ #category : 'private - cache management' }
GbsSession >> cacheAtST: anObject otherwise: otherwiseObject 
[
	"Private.  If anObject has locally cached a GemStone object proxy, or is found in
	 stObjectCache, and its session is identical to the receiver, return the
	 associated remoteObject.  Otherwise, return otherwiseObject.  If anObject is
	 associated with a remoteObject from more than one GbsSession (which is possible
	 for Smalltalk symbols), a GbxObjectList will be encountered.  If the list
	 contains a remoteObject from the receiver session, that remoteObject is returned."

	| remoteObject |
	^(remoteObject := self cacheAtST: anObject) == nil 
		ifTrue: [otherwiseObject]
		ifFalse: [remoteObject]
]

{ #category : 'private - cache management' }
GbsSession >> userMessageFromFailedConnectors: failedConnectors messages: messages 
[
	| msg |
	msg := String new.
	1 to: (failedConnectors size min: 10)
		do: 
			[:i | 
			msg := msg 
						, ((String with: Character cr) , (failedConnectors at: i) printString 
								, ' - ' , (messages at: i) 
								gbxCopyWrappedTo: 75
								indent: 10)].
	failedConnectors size > 10 
		ifTrue: 
			[msg := msg , (String with: Character cr) , '<...' 
						, (failedConnectors size - 10) printString , ' more...>'].
	^msg
]

{ #category : 'private - cache management' }
GbsSession >> cacheCritical: aBlock 
[
	^GBSM clientMap writeCritical: aBlock
]

{ #category : 'private - cache management' }
GbsSession >> clamp: delegate client: clientObject
[

	(clientObject zzzisStub not
		and: [clientObject zzzisForwarder or: [clientObject isBehavior]])
			ifTrue: [self addClampedObject: clientObject withDelegate: delegate]
]

{ #category : 'configuration information' }
GbsSession >> clampByCallback
[

	^configuration clampByCallback
]

{ #category : 'configuration information' }
GbsSession >> clampByCallback: aBoolean
[

	aBoolean = self clampByCallback ifTrue: [^self].
	configuration clampByCallback: aBoolean.
	self sessionCritical: [replicatorManager changedClampByCallback]
]

{ #category : 'configuration information' }
GbsSession >> defaultGStoSTLevel
[
	"Returns a SmallInteger indicating the default number of levels to replicate when updating an object from GemStone to Smalltalk.  A level of 2 means retrieve the root object and each object it references.  A level of 0 indicates no limit."

	^self isRemote 
		ifTrue: [configuration faultLevelRpc]
		ifFalse: [configuration faultLevelLnk]
]

{ #category : 'private - method compilation' }
GbsSession >> compileInstMethod: aString forClass: gemStoneClass inMethodCategory: category 
[
	"Private"

	self 
		compileInstMethod: aString
		forClass: gemStoneClass
		inMethodCategory: category
		symbolList: self oopNil
]

{ #category : 'private - method compilation' }
GbsSession >> compileClassMethod: aString forClass: gemStoneClass inMethodCategory: category symbolList: symlist 
[
	"Private"

	^self 
		compileMethod: aString
		class: gemStoneClass unsynchronizedRemoteClass
		category: category
		symbolList: symlist
]

{ #category : 'private - method compilation' }
GbsSession >> compileClassMethod: aString forClass: gemStoneClass inMethodCategory: category 
[
	"Private"

	self 
		compileClassMethod: aString
		forClass: gemStoneClass
		inMethodCategory: category
		symbolList: self oopNil
]

{ #category : 'private - method compilation' }
GbsSession >> compileMethod: aString class: serverClass category: category symbolList: symlistOrNil
[
	"Compile aString as a method in serverClass in the given method category.  If 
	 serverClass is a metaclass, the method will be a class method.  Use symlistOrNil
	 as the symbol list during parsing.  If symlistOrNil is oop nil, use the default 
	 symbol list"

	| localString symlist errorDescriptor errorString |
	(localString := aString asString) last = Character lf
		ifFalse: [localString := localString , (String with: Character lf)].
	symlist := symlistOrNil = self oopNil
				ifTrue: [self symbolListProxy]
				ifFalse: [symlistOrNil].
	errorDescriptor := self
				evaluateBlock: '[:source :dicts :cat | self compileMethod: source dictionaries: dicts category: cat]'
				withArguments: (Array with: localString with: symlist with: category)
				context: serverClass.
	errorDescriptor = nil
		ifFalse: 
			[errorString := self
						evaluateBlock: '[:errorDescriptor :string | GsNMethod _sourceWithErrors: errorDescriptor fromString: string]'
						withArguments: (Array with: errorDescriptor with: localString)
						context: self oopNil.
			(GbsCompilerError new)
				errorDescriptor: errorDescriptor asLocalObject;
				raiseSignal: errorString]
]

{ #category : 'private - method compilation' }
GbsSession >> checkTransactionContinueCompile
[
	"Private. Answer boolean whether the sender should continue code compilation
	 despite being outside of a transaction."

	self inTransaction ifTrue: [^true].
	GbsConfiguration current confirm ifFalse: [^false].
	^self gbsMessenger 
		confirm: 'Session %1 is not in a transaction.\The results of this compilation will be lost on entering a transaction.\Do you want to proceed with the compilation?'
		with: self
]

{ #category : 'private - method compilation' }
GbsSession >> compileInstMethod: aString forClass: serverClass inMethodCategory: category symbolList: symlist 
[
	"Private"

	^self 
		compileMethod: aString
		class: serverClass
		category: category
		symbolList: symlist
]

{ #category : 'private - offset caching' }
GbsSession >> updateServerInstVarNamesForReplicators: replicators
[
	"The sender must hold my protect semaphore."

	replicatorManager updateServerInstVarNamesForReplicators: replicators
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedExecuteBlock: sourceString with: arg context: contextDelegate
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self
		unsynchronizedExecuteBlock: sourceString
		withArguments: (Array with: arg)
		context: contextDelegate
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateBlock: sourceString context: contextDelegate 
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self 
		unsynchronizedEvaluateBlock: sourceString
		withArguments: #()
		context: contextDelegate
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateBlockReturnResultBodyAsDelegates: sourceString withArguments: args context: contextDelegate
[

	| delegates evaluation |
	self gbsMessenger
		statusTag: #unsynchronizedEvaluateBlock
		message: '(s%1) GbsSession>>unsynchronizedEvaluateBlockReturnResultBodyAsDelegates: %2 withArguments: %3'
		with: self sessionId
		with: sourceString
		with: args.
	evaluation := self newServerEvaluation.
	evaluation
		arguments: args;
		contextDelegate: (self delegateForUnsynchronizedContext: contextDelegate);
		sourceCode: sourceString;
		isBlock: true;
		shouldSynchronize: false;
		shouldReplicateResultBodyAsDelegates: true;
		replicationScheme: GbxNullReplicationScheme new;
		stopForBreakpoints: false;
		replicationLevel: 1.
	delegates := evaluation execute.
	serverInterface saveFetchedOops: delegates.	"Must add to the export set in multi-trip, or they may get GCed"
	^delegates
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedExecuteBlock: sourceString withArguments: args context: contextDelegate
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	| evaluation |
	self gbsMessenger
		statusTag: #unsynchronizedEvaluateBlock
		message: '(s%1) GbsSession>>unsynchronizedExecuteBlock: %2 withArguments: %3 context: %4'
		with: self sessionId
		with: sourceString
		with: args
		with: contextDelegate.
	evaluation := self newServerEvaluation.
	^evaluation
		arguments: args;
		sourceCode: sourceString;
		contextDelegate: (self delegateForUnsynchronizedContext: contextDelegate);
		isBlock: true;
		shouldSynchronize: false;
		shouldReplicateResult: false;
		replicationScheme: GbxNullReplicationScheme new;
		stopForBreakpoints: false;
		execute
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateBlock: sourceString with: arg1 with: arg2
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."
	
	^self
		unsynchronizedEvaluateBlock: sourceString
		withArguments: (Array with: arg1 with: arg2)
]

{ #category : 'private - execution' }
GbsSession >> newMessageSend
[
	"Private to GBS."

	^serverInterface newMessageSend
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedExecute: aString 
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self unsynchronizedExecute: aString symbolList: self oopNil
]

{ #category : 'private - execution' }
GbsSession >> executeBlock: sourceString with: arg1 with: arg2 context: receiverObject
[
	"Private to GBS."

	^self
		executeBlock: sourceString
		withArguments: (Array with: arg1 with: arg2)
		context: receiverObject
]

{ #category : 'private - execution' }
GbsSession >> delegateForUnsynchronizedContext: context
[

	[context gbxCanBeArgForUnsynchronizedOperationInSession: self] gbxAssert.
	^context asGSObjectInSession: self
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedExecute: aString symbolList: aSymbolList 
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self 
		unsynchronizedExecute: aString
		context: self oopNil
		symbolList: aSymbolList
]

{ #category : 'private - execution' }
GbsSession >> executeBlock: sourceString with: arg1 with: arg2 with: arg3 with: arg4 with: arg5 context: receiverObject
[
	"Private to GBS."

	^self
		executeBlock: sourceString
		withArguments: (OrderedCollection new
				add: arg1;
				add: arg2;
				add: arg3;
				add: arg4;
				add: arg5;
				yourself) asArray
		context: receiverObject
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateBlock: sourceString withArguments: args
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self
		unsynchronizedEvaluateBlock: sourceString
		withArguments: args
		context: self oopIllegal
]

{ #category : 'private - execution' }
GbsSession >> evaluateBlock: sourceString with: arg1 with: arg2 context: receiverObject 
[
	"Private to GBS."

	^self 
		evaluateBlock: sourceString
		withArguments: (Array with: arg1 with: arg2)
		context: receiverObject
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluate: sourceString context: contextDelegate
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	| evaluation |
	self gbsMessenger
		statusTag: #unsynchronizedEvaluate
		message: '(s%1) GbsSession>>unsynchronizedEvaluate: %2 context: %3'
		with: self sessionId
		with: sourceString
		with: contextDelegate.
	evaluation := self newServerEvaluation.
	^evaluation
		sourceCode: sourceString;
		contextDelegate: (self delegateForUnsynchronizedContext: contextDelegate);
		shouldSynchronize: false;
		replicationScheme: GbxNullReplicationScheme new;
		replicationLevel: 0;
		stopForBreakpoints: false;
		execute
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateBlockReturnResultBodyAsDelegates: sourceString with: arg1 with: arg2 context: contextDelegate
[
	"Private to GBS.  Special purpose method for fetch*oops; expects to replicate a result Array to level one and
	just return an array of delegates for the stubs it contains.
	Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self
		unsynchronizedEvaluateBlockReturnResultBodyAsDelegates: sourceString
		withArguments: (Array with: arg1 with: arg2)
		context: contextDelegate
]

{ #category : 'private - execution' }
GbsSession >> executeBlock: sourceString with: arg context: receiverObject
[
	"Private to GBS."

	^self
		executeBlock: sourceString
		withArguments: (Array with: arg)
		context: receiverObject
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedExecuteBlock: sourceString with: arg1 with: arg2 with: arg3 context: contextDelegate
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self
		unsynchronizedExecuteBlock: sourceString
		withArguments: (Array with: arg1 with: arg2 with: arg3)
		context: contextDelegate
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateBlock: sourceString with: anObject context: contextDelegate
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self unsynchronizedEvaluateBlock: sourceString
		withArguments: (Array with: anObject)
		context: contextDelegate
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateReturnResultBodyAsDelegates: sourceString context: contextDelegate
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	| evaluation delegates |
	evaluation := self newServerEvaluation.
	evaluation
		sourceCode: sourceString;
		contextDelegate: (self delegateForUnsynchronizedContext: contextDelegate);
		shouldSynchronize: false;
		replicationScheme: GbxNullReplicationScheme new;
		replicationLevel: 1;
		shouldReplicateResultBodyAsDelegates: true;
		stopForBreakpoints: false.
	delegates := evaluation execute.
	serverInterface saveFetchedOops: delegates.	"Must add to the export set in multi-trip, or they may get GCed"
	^delegates
]

{ #category : 'private - execution' }
GbsSession >> executeBlock: sourceString with: arg1 with: arg2 with: arg3 with: arg4 context: receiverObject
[
	"Private to GBS."

	^self
		executeBlock: sourceString
		withArguments: (Array with: arg1 with: arg2 with: arg3 with: arg4)
		context: receiverObject
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateBlock: sourceString with: arg1 with: arg2 with: arg3
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."
	
	^self
		unsynchronizedEvaluateBlock: sourceString
		withArguments: (Array with: arg1 with: arg2 with: arg3)
]

{ #category : 'private - execution' }
GbsSession >> newServerTraversal
[
	"Private to GBS."

	^serverInterface newServerTraversal
]

{ #category : 'private - execution' }
GbsSession >> addToNoLongerReplicated: aDelegate
[
	"This oop is in the server's pure export set, because the server sent a full report for it.
	If we do not replicate the object, or turn the replicate into a stub or forwarder, we must 
	let the server know. The noLongerReplicated list is where we keep the delegates whose 
	oops must be sent to the server at the next round trip."
	"Sender must hold my sessionProtect."

	serverInterface addToNoLongerReplicated: aDelegate
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedExecute: sourceString context: contextDelegate symbolList: gsSymbolList
[
	"Private.  Bypass the normal <execute:> methods so as to avoid store traversals.
	For internal GBS use only. Does not obey replicate synchronization semantics.
	Immune from debugger stepping and asynchronous events."

	| evaluation symListDel |
	self gbsMessenger
		statusTag: #unsynchronizedExecute
		message: '(s%1) GbsSession>>unsynchronizedExecute: %2 context: %3 symbolList: %4'
		with: self sessionId
		with: sourceString
		with: contextDelegate
		with: gsSymbolList.
	evaluation := self newServerEvaluation.
	symListDel := gsSymbolList asGSObjectInSession: self.
	^evaluation
		sourceCode: sourceString;
		contextDelegate: (self delegateForUnsynchronizedContext: contextDelegate);
		symbolListDelegate: symListDel;
		shouldSynchronize: false;
		shouldReplicateResult: false;
		replicationScheme: GbxNullReplicationScheme new;
		stopForBreakpoints: false;
		execute
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateBlockReturnResultBodyAsDelegates: sourceString with: arg1 context: contextDelegate
[
	"Private to GBS.  Special purpose method for fetching oops; expects to replicate a result Array to level one and
	just return an array of delegates for the stubs it contains.
	Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self
		unsynchronizedEvaluateBlockReturnResultBodyAsDelegates: sourceString
		withArguments: (Array with: arg1)
		context: contextDelegate
]

{ #category : 'private - execution' }
GbsSession >> evaluateBlock: sourceString with: anObject context: receiverObject 
[
	"Private to GBS."

	^self 
		evaluateBlock: sourceString
		withArguments: (Array with: anObject)
		context: receiverObject
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedExecuteBlock: sourceString with: arg1 with: arg2 context: contextDelegate
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self
		unsynchronizedExecuteBlock: sourceString
		withArguments: (Array with: arg1 with: arg2)
		context: contextDelegate
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluate: sourceString
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	| evaluation |
	evaluation := self newServerEvaluation.
	^evaluation
		sourceCode: sourceString;
		shouldSynchronize: false;
		replicationScheme: GbxNullReplicationScheme new;
		replicationLevel: 0;
		stopForBreakpoints: false;
		execute
]

{ #category : 'private - execution' }
GbsSession >> evaluateBlock: sourceString withArguments: args context: contextObject toLevel: level
[
	"Private to GBS. Only works in single-trip, at least for now."

	| evaluation |
	self gbsMessenger
		statusTag: #evaluateBlock
		message: '(s%1) GbsSession>>evaluateBlock: %2 withArguments: %3'
		with: self sessionId
		with: sourceString
		with: args.
	evaluation := self newServerEvaluation.
	^evaluation
		arguments: args;
		sourceCode: sourceString;
		isBlock: true;
		contextDelegate: (contextObject asGSObjectInSession: self);
		replicationLevel: level;
		execute
]

{ #category : 'private - execution' }
GbsSession >> newServerEvaluation
[
	"Private to GBS."

	self checkSession.
	^serverInterface newServerEvaluation
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateBlock: sourceString with: anObject 
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self unsynchronizedEvaluateBlock: sourceString
		withArguments: (Array with: anObject)
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateReturnResultBodyAsDelegates: sourceString
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	| evaluation delegates |
	evaluation := self newServerEvaluation.
	evaluation
		sourceCode: sourceString;
		shouldSynchronize: false;
		replicationScheme: GbxNullReplicationScheme new;
		replicationLevel: 1;
		shouldReplicateResultBodyAsDelegates: true;
		stopForBreakpoints: false.
	delegates := evaluation execute.
	serverInterface saveFetchedOops: delegates.	"Must add to the export set in multi-trip, or they may get GCed"
	^delegates
]

{ #category : 'private - execution' }
GbsSession >> executeBlock: sourceString with: arg1 with: arg2 with: arg3 context: receiverObject
[
	"Private to GBS."

	^self
		executeBlock: sourceString
		withArguments: (Array with: arg1 with: arg2 with: arg3)
		context: receiverObject
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateBlock: sourceString with: arg1 with: arg2 context: contextDelegate
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	^self
		unsynchronizedEvaluateBlock: sourceString
		withArguments: (Array with: arg1 with: arg2)
		context: contextDelegate
]

{ #category : 'private - execution' }
GbsSession >> evaluateBlock: sourceString context: receiverObject
[
	"Private to GBS."

	^self 
		evaluateBlock: sourceString
		withArguments: #()
		context: receiverObject
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedExecute: aString context: aContext 
[
	"Private.  Bypass the normal <execute:> methods so as to avoid store traversals.
	For internal GBS use only. Does not obey replicate synchronization semantics.
	Immune from debugger stepping and asynchronous events."

	^self 
		unsynchronizedExecute: aString
		context: aContext
		symbolList: self oopNil
]

{ #category : 'private - execution' }
GbsSession >> executeBlock: sourceString withArguments: args context: contextDelegate
[
	"Private to GBS."

	| evaluation |
	self gbsMessenger
		statusTag: #executeBlock
		message: '(s%1) GbsSession>>executeBlock: %2 withArguments: %3'
		with: self sessionId
		with: sourceString
		with: args.
	evaluation := self newServerEvaluation.
	^evaluation
		arguments: args;
		sourceCode: sourceString;
		isBlock: true;
		shouldReplicateResult: false;
		contextDelegate: (contextDelegate asGSObjectInSession: self);
		execute
]

{ #category : 'private - execution' }
GbsSession >> unsynchronizedEvaluateBlock: sourceString withArguments: args context: contextDelegate
[
	"Private to GBS.  Does not synchronize server and client object spaces, so safe
	only in specific internal GBS operations.
	Immune from debugger stepping and asynchronous events."

	| evaluation |
	self gbsMessenger
		statusTag: #unsynchronizedEvaluateBlock
		message: '(s%1) GbsSession>>unsynchronizedEvaluateBlock: %2 withArguments: %3'
		with: self sessionId
		with: sourceString
		with: args.
	evaluation := self newServerEvaluation.
	^evaluation
		arguments: args;
		contextDelegate: (self delegateForUnsynchronizedContext: contextDelegate);
		sourceCode: sourceString;
		isBlock: true;
		shouldSynchronize: false;
		replicationScheme: GbxNullReplicationScheme new;
		stopForBreakpoints: false;
		replicationLevel: 0;
		execute
]

{ #category : 'private - execution' }
GbsSession >> evaluateBlock: sourceString withArguments: args context: receiverObject
[
	"Private to GBS."

	| evaluation |
	self gbsMessenger
		statusTag: #evaluateBlock
		message: '(s%1) GbsSession>>evaluateBlock: %2 withArguments: %3'
		with: self sessionId
		with: sourceString
		with: args.
	evaluation := self newServerEvaluation.
	^evaluation
		arguments: args;
		sourceCode: sourceString;
		isBlock: true;
		contextDelegate: (receiverObject asGSObjectInSession: self);
		execute
]

{ #category : 'accessing' }
GbsSession >> causeOfDeath
[

	"The first fatal error a session encounters will save that error
	 as the likely cause of death for subsequent errors associated
	 with this session."

	^causeOfDeath
]

{ #category : 'accessing' }
GbsSession >> clientTimeZone: anObject
[
	clientTimeZone := anObject
]

{ #category : 'accessing' }
GbsSession >> gemSessionId
[

	^gemSessionId
]

{ #category : 'accessing' }
GbsSession >> clientTimeZone
[
	^clientTimeZone
]

{ #category : 'accessing' }
GbsSession >> gemSerialNumber
[

	^gemSerialNumber
]

{ #category : 'accessing' }
GbsSession >> causeOfDeath: aGbsError
[
	"Set the cause of this session's death, so subsequent
	 errors can identify their likely cause.

	Sender must hold GciCallProtect, so that only the first 
	detected error is recorded as the cause of death."
	
	causeOfDeath := aGbsError
]

{ #category : 'accessing' }
GbsSession >> gemProcessId
[

	^gemProcessId
]

{ #category : 'accessing' }
GbsSession >> eventDetectorErrorHandler: anObject
[
	eventDetectorErrorHandler := anObject
]

{ #category : 'accessing' }
GbsSession >> logoutTimestamp
[
	"Answer the pper bound for the point in time this session could appear in log files"

	^logoutTimestamp
]

{ #category : 'accessing' }
GbsSession >> configuration
[
	^configuration
]

{ #category : 'accessing' }
GbsSession >> eventDetectorErrorHandler
[
	^eventDetectorErrorHandler
]

{ #category : 'accessing' }
GbsSession >> loginTimestamp
[
	"Answer the lower bound for the point in time this session could appear in log files"

	^loginTimestamp
]

{ #category : 'private - event detection' }
GbsSession >> pollForSignalDeferFatalErrors: deferFatalErrors
[
	"Private.  Checks to see if any GemStone-originated events have been signaled, such
	 as changed object notification, gem-to-gem signals, signaled abort, or lost-OT-root.
	 If so, a GbsError describing the event will raise a Smalltalk signal.  If a fatal error is
	 detected during this call, and deferFatalErrors is true, the error is flagged for deferred
	 processing.  This prevents the event poller thread from reporting fatal errors,
	 allowing the error to be signaled by an application thread instead."

	| resultOrError |
	self sessionCritical: 
			[resultOrError := self serverInterface pollForSignalFor: self
						deferFatalErrors: deferFatalErrors.
			resultOrError gbxIsGSError
				ifTrue: [resultOrError isAsyncAbortError ifTrue: [^self processAsyncAbort]]].
	^resultOrError gbxIsGSError
		ifTrue: [resultOrError processVerifyArgs: [true]]
		ifFalse: [resultOrError]
]

{ #category : 'session management' }
GbsSession >> logout
[
	"This logs this session out of GemStone.  The sessionId will be modified to an invalid id.
	Answers true if logged out, false otherwise."

	"Don't logout if any of my dependents have an objection"

	(self changeRequest: #queryEndSession) ifFalse: [^false].
	self gbsMessenger 
		statusTag: #logout
		message: '(s%1)'
		with: self sessionId.

	"Log out, ignoring bad session id error"
	GbsConfiguration current verbose 
		ifTrue: [self gbsMessenger comment: 'Logging out %1.' with: self].
	self quietLogout.
	^true
]

{ #category : 'session management' }
GbsSession >> setClientTimeZoneFromServer
[
	"public method for setting client time zone from the server."

	self initializeTimeZoneFromServer
]

{ #category : 'session management' }
GbsSession >> parameters
[

	"Returns a GbsSessionParameters, describing the login parameters used for this session"
	^parameters
]

{ #category : 'session management' }
GbsSession >> sessionId
[

	"Return the integer representing the logical GemStone session from the GBC's perspective"
	^sessionId
]

{ #category : 'accessing' }
GbsSession >> sessionProtect
[
	^sessionProtect
]

{ #category : 'session management' }
GbsSession >> version
[
	"Returns a string that provides the version of the Gem, Stone, and repository image for this session."

	| array |
	array := self 
				evaluate: 'Array with: (System gemVersionAt: #gsRelease) with: (System stoneVersionAt: #gsRelease) with: (System stoneVersionAt: #gsRelease)'.
	^'Gem version: ' , (array at: 1) , '; Stone version: ' , (array at: 2) 
		, '; Server image version: ' , (array at: 3) 
		, '.'
]

{ #category : 'private - export set maintenance' }
GbsSession >> serverMap
[
	"Private."

	^serverMap
]

{ #category : 'private - services' }
GbsSession >> servicesWarning
[

	^'GBS Services are not installed in this server, or the GBS Services installed do not support this version of GBS.
Please have your system administrator install GBS services.
GBS may perform erratically until this is done.'
]

{ #category : 'private - async abort' }
GbsSession >> autoServiceSigAbort: aBoolean
[

	self isRemote
		ifFalse: 
			[self gbsMessenger
				error: 'Linked sessions do not support automatic servicing of sigAbort.'].
	self
		evaluateBlock: '[:bool | System configurationAt: #GemAutoServiceSigAbort put: bool]'
		with: aBoolean
		context: nil
]

{ #category : 'private - async abort' }
GbsSession >> processAsyncAbort
[
	"Sender must hold sessionProtect."

	| aggregateDirty result |
	aggregateDirty := IdentitySet new: configuration initialDirtyPoolSize.
	dirtyPool emptyInto: aggregateDirty.
	asyncAbortStartAction value: aggregateDirty.
	self traverseAllServerDirtyObjects.
	result := asyncAbortFinishAction value.
	(GbxReturnNotification returning: result) raiseSignal
]

{ #category : 'private - async abort' }
GbsSession >> traverseAllServerDirtyObjects
[
	"Could get an async abort notification while fetching dirty after an async abort notification.
	Keep repeating until complete."

	
	[
		[self traverseServerDirtyObjects.
		true]
			on: GbxAsyncAbortNotification
			do: [:ex | ex return: false]]
				whileFalse
]

{ #category : 'private - async abort' }
GbsSession >> traverseServerDirtyObjects
[
	"This will prompt the server to traverse to the client any dirty objects that it is holding."

	self oopNil performOnGsServer: #yourself
]

{ #category : 'removing locks' }
GbsSession >> removeLocksForSession
[

	"Removes all locks held by this session.  Returns the receiver.
	This method succeeds even if the session no longer has
	read authorization for one or more of its locked objects."

	self systemProxy remotePerform: #removeLocksForSession
]

{ #category : 'removing locks' }
GbsSession >> removeAllFromCommitOrAbortReleaseLocksSet: aCollection
[

	"Removes all objects in aCollection from a set of locks to be
	 released at the next successful commit or abort."

	self systemProxy
		remotePerform: #removeAllFromCommitOrAbortReleaseLocksSet:
		with: aCollection
]

{ #category : 'removing locks' }
GbsSession >> removeLockAll: aCollection
[

	"Removes all locks held by the current session on the objects in
	 aCollection.  Returns the receiver.  This method will remove the
	 lock on an object even if you lack read authorization for that object.

	 This method generates an error
	 if an object in aCollection is unlocked, special, or not committed."

	self systemProxy
		remotePerform: #removeLockAll:
		with: aCollection
]

{ #category : 'removing locks' }
GbsSession >> addToCommitReleaseLocksSet: anObject
[

	"Adds anObject to a set of locks to be released at the next successful commit.  If anObject is not locked by the current session, it is not added to the set."

	self systemProxy
		remotePerform: #addToCommitReleaseLocksSet:
		with: anObject
]

{ #category : 'removing locks' }
GbsSession >> removeLock: anObject
[

	"Removes the lock held by the current session on anObject.
	Returns the receiver.  This method succeeds even if you do not
	have read authorization for anObject."

	self systemProxy
		remotePerform: #removeLock:
		with: anObject
]

{ #category : 'removing locks' }
GbsSession >> addToCommitOrAbortReleaseLocksSet: anObject
[

	"Adds anObject to a set of locks to be released at the next successful commit or abort.  If anObject is not locked by the current session, it is not added to the set."

	self systemProxy
		remotePerform: #addToCommitOrAbortReleaseLocksSet:
		with: anObject
]

{ #category : 'removing locks' }
GbsSession >> removeFromCommitReleaseLocksSet: anObject
[

	"Removes anObject from a set of locks to be released at the next successful commit."

	self systemProxy
		remotePerform: #removeFromCommitReleaseLocksSet:
		with: anObject
]

{ #category : 'removing locks' }
GbsSession >> addAllToCommitReleaseLocksSet: aCollection
[

	"Adds elements of aCollection to a set of locks to be released at the next successful commit.  If any element of aCollection is not locked by the current session it is not added to the set."

	self systemProxy
		remotePerform: #addAllToCommitReleaseLocksSet:
		with: aCollection
]

{ #category : 'removing locks' }
GbsSession >> removeFromCommitOrAbortReleaseLocksSet: anObject
[

	"Removes anObject from a set of locks to be released at the next successful commit or abort."

	self systemProxy
		remotePerform: #removeFromCommitOrAbortReleaseLocksSet:
		with: anObject
]

{ #category : 'removing locks' }
GbsSession >> addAllToCommitOrAbortReleaseLocksSet: aCollection
[

	"Adds elements of aCollection to a set of locks to be released at the next successful commit or abort.  If any element of aCollection is not locked by the current session it is not added to the set."

	self systemProxy
		remotePerform: #addAllToCommitOrAbortReleaseLocksSet:
		with: aCollection
]

{ #category : 'removing locks' }
GbsSession >> removeAllFromCommitReleaseLocksSet: aCollection
[

	"Removes all objects in aCollection from a set of locks to be
	 released at the next successful commit."

	self systemProxy
		remotePerform: #removeAllFromCommitReleaseLocksSet:
		with: aCollection
]

{ #category : 'copying' }
GbsSession >> copy
[

	"There should only be one instance of this class with a given id"
	^self
]

{ #category : 'private - server kinds' }
GbsSession >> oopForOopNumber: oopNumber 
[
	^specialConverter oopForOopNumber: oopNumber
]

{ #category : 'private - server kinds' }
GbsSession >> oopNumberForOop: oop 
[
	^specialConverter oopNumberForOop: oop
]

{ #category : 'private - server kinds' }
GbsSession >> hashForDelegate: aDelegate
[

	^self sessionCritical: [specialConverter hashForDelegate: aDelegate]
]

{ #category : 'printing' }
GbsSession >> sessionSummaryOn: aStream
[

	aStream
		nextPutAll: self class name;
		space;
		nextPutAll: 'Session Protect: '.
	self sessionProtect semaphoreSummaryOn: aStream
]

{ #category : 'obsolete' }
GbsSession >> commit
[
	"This method is the same as commitTransaction, and may be removed
	 in a future release."

	GbsConfiguration 
		deprecated: 'GbsSession>>commit deprecated March, 2006. Send #commitTransaction instead'.
	^self commitTransaction
]

{ #category : 'obsolete' }
GbsSession >> abort
[

	"This is the same as abortTransaction, and may be removed in a future release."

	^self abortTransaction
]

{ #category : 'private - traversal' }
GbsSession >> lookupOop: anOop
[
	"Private.  Given the GemStone oop, return the client object.  If oop is not found, answer 
	NotCachedToken."
	"Sender must hold my session's sessionProtect."

	| clientObj |
	clientObj := specialConverter localSpecialFromOop: anOop.
	"Check for special oop first, since a common case and fast. If not special, must look in the cache."
	clientObj == notCachedToken
		ifTrue: [clientObj := serverMap clientAtOop: anOop].
	^clientObj
]

{ #category : 'private - store traversal' }
GbsSession >> storeTraversalBuffer: aBuffer
[
	"Private"

	self storeTraversalBuffer: aBuffer flags: self serverInterface storeTravFlags
]

{ #category : 'private - store traversal' }
GbsSession >> storingObjectInTraversal
[

	"Do nothing.  Reimplemented in subclass for statistics"
]

{ #category : 'private - store traversal' }
GbsSession >> flushDirtyPoolTo: aStoreTraversal
[
	"Pack each dirty object in the top dirty pool. If there are more objects dirtied as
	 a side effect of processing while this level is the top, they will also be packed, since
	each level of the dirtp pool is a queue.
	Some lazy-initialization scenarios can dirty while #storeInSession:.

	The sender must hold my sessionProtect."

	dirtyPool packTopIn: aStoreTraversal
]

{ #category : 'private - store traversal' }
GbsSession >> storeTraversalBuffer: aBuffer flags: anInteger
[
	"Private"

	| nilOrError |
	self gbsMessenger
		statusTag: ('storeTraversalFlags' , anInteger printString) asSymbol
		message: '(s%1) GbsSession>>storeTraversalBuffer:flags: %2'
		with: self sessionId
		with: anInteger.
	nilOrError := self serverInterface storeTraversalBuffer: aBuffer
				flags: anInteger.
	(nilOrError notNil and: [nilOrError isAsyncAbortError])
		ifTrue: [GbxAsyncAbortNotification raiseSignal].
	GbsError
		primResultOrError: nilOrError
		verifyArgs: [true]
		session: self.
	self gbsMessenger
		statusTag: nil
		message: '(s%1) completed GbsSession>>storeTraversalBuffer:flags:'
		with: self sessionId
]

{ #category : 'setting locks' }
GbsSession >> readLock: anObject ifDenied: denyBlock ifChanged: changeBlock
[

	"Requests a read lock on anObject.  If the lock is granted, this
	method returns the receiver.

	Generates an error if you do not have read authorization for anObject.

	See System | exclusiveLock:ifDenied:ifChanged:
	for information about conditions that may cause the argument
	blocks to be executed.  Note, however, that with this method,
	a lock is denied if another session already holds a write or
	exclusive lock, but not if another session holds a read lock."

	| result |
	result := self
		execute: 'System
			readLock: self
			ifDenied: [ #denied ]
			ifChanged: [ #changed ]'
		context: (anObject asGSObjectInSession: self).
	(result isGSObject and: [ result ~= OSystem ]) ifTrue: [
		result := result asLocalObject.
		result = #denied ifTrue: [ ^denyBlock value ].
		result = #changed ifTrue: [ ^changeBlock value ].
		^self gbsMessenger error: 'Unexpected result from read lock request' ].
	^self
]

{ #category : 'setting locks' }
GbsSession >> writeLockAll: aCollection
[

	"Requests a write lock on each object in aCollection.
	Returns the receiver if all of the locks are granted.

	See System | exclusiveLockAll: for information about
	conditions that may cause an error to be generated."

	self systemProxy
		remotePerform: #writeLockAll:
		with: aCollection
]

{ #category : 'setting locks' }
GbsSession >> readLock:  anObject
[

	"Requests a read lock on anObject.  If the lock is granted, this
	method returns the receiver.

	Generates an error if you do not have read authorization for anObject,
	if anObject is not committed, or another session already holds a write
	or exclusive lock.

	In addition, an error is generated if another session has committed
	a change to anObject since the beginning of the current transaction.
	In this case, the lock is granted despite the error.  A session holding
	such a 'dirty' lock cannot commit its transaction, but must abort to
	obtain an up-to-date value for anObject.  The lock will, however,
	remain after the transaction is aborted."

	(self systemProxy
		remotePerform: #readLock: with: anObject)
]

{ #category : 'setting locks' }
GbsSession >> writeLock: anObject ifDenied: denyBlock ifChanged: changeBlock
[

	"Requests a write lock on anObject.  If the lock is granted, this
	method returns the receiver.

	See System | exclusiveLock:ifDenied:ifChanged:
	for information about conditions that may cause the argument
	blocks to be executed."

	| result |
	result := self
		execute: 'System
			writeLock: self
			ifDenied: [ #denied ]
			ifChanged: [ #changed ]'
		context: (anObject asGSObjectInSession: self).
	(result isGSObject and: [ result ~= OSystem ]) ifTrue: [
		result := result asLocalObject.
		result = #denied ifTrue: [ ^denyBlock value ].
		result = #changed ifTrue: [ ^changeBlock value ].
		^self gbsMessenger error: 'Unexpected result from write lock request' ].
	^self
]

{ #category : 'setting locks' }
GbsSession >> writeLock: anObject
[

	"Requests a write lock on anObject.  If the lock is granted, this
	method returns the receiver.

	See System | exclusiveLock: for information about
	conditions that may cause an error to be generated."

	self systemProxy
		remotePerform: #writeLock:
		with: anObject
]

{ #category : 'setting locks' }
GbsSession >> readLockAll: aCollection ifIncomplete: incompleteBlock
[

	"Requests a read lock on each object in aCollection.
	Returns the receiver if all of the locks are granted.

	Generates an error if you lack read authorization for any
	element of aCollection.

	See System | exclusiveLockAll:ifIncomplete: for information about
	conditions that may cause incompleteBlock to be executed.  Note,
	however, that with this method, a lock is denied if another
	session already holds a write or exclusive lock, but not
	if another session holds a read lock."

	| results result denied dirty |
	results := self
		execute: '
			| result deniedResult dirtyResult |
			result := System
			readLockAll: self
			ifIncomplete: [ :denied :dirty :obsolete |
				deniedResult := denied.
				dirtyResult := dirty ].
			^Array with: result with: deniedResult with: dirtyResult'
		context: (aCollection asGSObjectInSession: self).

	results := results fetchObjectValues.

	denied := (results at: 2) asLocalObject.
	dirty := (results at: 3) asLocalObject.
	((denied notNil and: [ denied isEmpty not ])
	or: [ dirty notNil and: [ dirty isEmpty not ]])
		ifTrue: [
			"There were denied or dirty locks.  Evaluate the sender-supplied
			 block with the denied & dirty collections we got from GemStone"
			^incompleteBlock value: denied value: dirty value: #() ]
		ifFalse: [
			"There were no denied or dirty locks.  Return the result."
			result := results at: 1.
			result = OSystem
				ifTrue: [ result := self ]
				ifFalse: [ result := result asLocalObject ].
			^result ]
]

{ #category : 'setting locks' }
GbsSession >> readLockAll: aCollection
[

	"Requests a read lock on each object in aCollection.
	Returns the receiver if all of the locks are granted.

	If you lack read authorization for any object in aCollection,
	an error is generated and no locks are granted.

	See System | exclusiveLockAll: for more information about
	conditions that may cause an error to be generated.  Note,
	however, that with this method, a lock is denied if another
	session already holds a write or exclusive lock, but not
	if another session holds a read lock."

	(self systemProxy
		remotePerform: #readLockAll: with: aCollection)
]

{ #category : 'setting locks' }
GbsSession >> writeLockAll: aCollection ifIncomplete: incompleteBlock
[

	"Requests a write lock on each object in aCollection.
	Returns the receiver if all of the locks are granted.

	See System | exclusiveLockAll:ifIncomplete: for information about
	conditions that may cause incompleteBlock to be executed."

	| results result denied dirty |
	results := self
		execute: '
			| result deniedResult dirtyResult |
			result := System
			writeLockAll: self
			ifIncomplete: [ :denied :dirty :obsolete |
				deniedResult := denied.
				dirtyResult := dirty ].
			^Array with: result with: deniedResult with: dirtyResult'
		context: (aCollection asGSObjectInSession: self).

	results := results fetchObjectValues.

	denied := (results at: 2) asLocalObject.
	dirty := (results at: 3) asLocalObject.
	((denied notNil and: [ denied isEmpty not ])
	or: [ dirty notNil and: [ dirty isEmpty not ]])
		ifTrue: [
			"There were denied or dirty locks.  Evaluate the sender-supplied
			 block with the denied & dirty collections we got from GemStone"
			^incompleteBlock value: denied value: dirty value: #() ]
		ifFalse: [
			"There were no denied or dirty locks.  Return the result."
			result := results at: 1.
			result = OSystem
				ifTrue: [ result := self ]
				ifFalse: [ result := result asLocalObject ].
			^result ]
]

{ #category : 'private - notification' }
GbsSession >> interSessionSignalCreationString
[
	"Source code for a block that creates and answers an intersession signal object given the session serial number, the signal number, and the message string as arguments.
	In older servers, there is no accessor for the session serial number, so we have to use the awful instVarAt:put: hack. See bug 30958."
	"^GbxServerVersion current is64v3
		ifTrue: 
			['[:serNum :sigNum :message | InterSessionSignal new fromSession: serNum signal: sigNum message: message]']
		ifFalse: 
			['[:serNum :sigNum :message | | sig | sig := GsInterSessionSignal signal: sigNum message: message.
  sig instVarAt: 1 put: serNum.
  sig]']"
	"The above is problematic. See bug 42902. The below restores older behavior while that's being sorted."

	^'[:serNum :sigNum :message | | sig | sig := GsInterSessionSignal signal: sigNum message: message.
  sig instVarAt: 1 put: serNum.
  sig]'
]

{ #category : 'private - notification' }
GbsSession >> interSessionSignalPollString
[
	"Source code that answers an intersession signal object or nil if there are no more signals to receive right now.
	 The server method #signalFromSession is deprecated. If Deprecated is signalled, GbxEventDetector>>#pollForCurrentSignals
	 will catch it and resume. When this method is modified to stop using a deprecated method, the Event Detector should stop
	 checking for error number 2746."
	"
	^GbxServerVersion current is64v3
		ifTrue: ['InterSessionSignal poll']
		ifFalse: ['GsCurrentSession currentSession signalFromSession']"


	"GBS does not have a non-deprecated implementation yet."
	^'GsCurrentSession currentSession signalFromSession'
]

{ #category : 'private - class redefinition' }
GbsSession >> recompileWithSubclassesFrom: oldClass to: newClass failedMethods: failedMethods symbolList: symList
[
	"Private."

	| rfailed subclasses removedVars newSubclass sel src newMeta cls |
	self gbxFixMe. "replaced by Gbs Service - GbxMigrationService. Can remove once well tested"
	GbsConfiguration current verbose
		ifTrue: 
			[self gbsMessenger comment: 'Versioning and recompiling GemStone class %1.'
				with: oldClass remoteDescription].
	removedVars := self
				evaluateBlock: '[:oldClass :newClass |
								| oldCVs newCVs oldPools newPools |
								oldCVs := ((oldClass _classVars) == nil ifTrue: [Dictionary new] ifFalse:[oldClass _classVars]) keys.
								newCVs := ((newClass _classVars) == nil ifTrue: [Dictionary new] ifFalse:[newClass _classVars]) keys.
								oldCVs removeAllPresent: newCVs.
								oldPools := oldClass sharedPools asSet.
								newPools := newClass sharedPools asSet.
								oldPools removeAllPresent: newPools.
								oldCVs -> oldPools]'
				with: oldClass
				with: newClass
				context: nil.
	rfailed := newClass
				remotePerform: #_copyMethodsAndVariablesFrom:except:dictionaries:
				with: oldClass
				with: (Array
						with: $V
						with: removedVars key
						with: $P
						with: removedVars value)
				with: symList.
	newMeta := newClass unsynchronizedRemoteClass.
	rfailed fetchObjectValues do: 
			[:failedCompiledMethod |
			src := [failedCompiledMethod performOnGsServer: #_sourceString]
						on: GbsError errorSignal
						do: 
							[:ex |
							ex
								return: 'Couldn''t read a method in ' , oldClass remoteDescription
										, (String with: Character cr) , ex description].
			sel := failedCompiledMethod remotePerform: #selector.
			cls := failedCompiledMethod remotePerform: #inClass.
			failedMethods addLast: (GbxMethodErrorHolder
						forClass: (cls = oldClass ifTrue: [newClass] ifFalse: [newMeta])
						source: src
						category: (cls performOnGsServer: #_categoryOfSelector:
								withArguments: (Array with: sel)))].
	subclasses := (self
				evaluateBlock: '[:cls | (self subclassesOf: cls) collect:[:ea | ea asOop]]'
				withArguments: (Array with: oldClass)
				context: self gsClassOrganizer)
					collect: [:ea | GbxDelegate oopValue: ea session: self].


	"Private.  Do this -after- #subclassesOf:, which has the side effect of replacing the new
	  class with the old class in the organizer"
	self gsClassOrganizer remotePerform: #addClass: with: newClass.

	"Iterate over all the first-level subclasses of the old class to create new subclasses"
	
	subclasses do: 
			[:oldSubclass |
			newSubclass := 
					[self gsCurrentSession asGSObject
						remotePerform: #execute:symbolList:
						with: (oldSubclass unsynchronizedPerform: #definition)
						with: symList]
							on: GbsError errorSignal
							do: 
								[:ex |
								self gbsMessenger
									warn: 'Failed to recompile subclass %1\%2'
									with: oldSubclass remoteDescription
									with: ex description.
								ex return: nil].
			newSubclass notNil
				ifTrue: 
					[self
						recompileWithSubclassesFrom: oldSubclass
						to: newSubclass
						failedMethods: failedMethods
						symbolList: symList]]
]

{ #category : 'private - class redefinition' }
GbsSession >> reportFailedMethodRecompiles: failedMethods
[
	"If the GbsTools are loaded, we can open a browser to edit/view the method(s).
	 Otherwise, we can only notify that the compile error(s) occurred and let the user/developer deal with it."

	failedMethods isEmpty ifTrue: [^self].
	(Smalltalk at: #GbxMethodListBrowser ifAbsent: [ nil ])
		ifNotNil: [ :browser |
			browser
				openListBrowserOn: failedMethods
				label: 'methods failing recompilation'
				session: self ]
		ifNil:
			[ | summaryReport fullReport |
			summaryReport := String new writeStream.
			failedMethods doWithIndex:
					[ :methodErrorHolder :index |
					summaryReport
						print: index;
						nextPutAll: ')';
						tab;
						nextPutAll: methodErrorHolder displayString;
						cr ].
			fullReport := String new writeStream.
			failedMethods doWithIndex:
					[ :methodErrorHolder :index |
					fullReport
						print: index;
						nextPutAll: ')';
						tab;
						nextPutAll: methodErrorHolder displayString;
						cr;
						nextPutAll: methodErrorHolder sourceText asString;
						cr;
						cr ].
			self gbsMessenger
				warn: 'Compiler error(s) occurred (details on the Transcript)\%1'
					with: summaryReport contents;
				comment: 'Compiler error(s) occurred:\%1'
					with: fullReport contents ]
]

{ #category : 'private - class redefinition' }
GbsSession >> migrateInstancesWithSubclassesOf: topClass
[

	"Private.  GBS.  This would be much more elegant as a GemStone method."
	self execute: '
	| topClass organizer oldClasses targetClasses oldSubclassCollector instances |
	"Self is a 2-element array passed in by execute:context:"
	topClass := self at: 1.
	organizer := self at: 2.
	oldClasses := Array new.
	targetClasses := Array new.
	"Collect all the old class versions"
	oldSubclassCollector := [ :newClass |
		1 to: newClass classHistory size - 1 do: [ :i |
			oldClasses add: (newClass classHistory at: i).
			targetClasses add: newClass.
			(organizer allSubclassesOf: newClass) do: [ :sub |
				oldSubclassCollector value: sub ]]].
	oldSubclassCollector value: topClass.

	"Get the instances - in one repository sweep"
	instances := SystemRepository listInstances: oldClasses.
	"Migrate them.  We now have 3 parallel arrays."
	1 to: oldClasses size do: [ :i |
		| oldClass |
		(oldClasses at: i)
			migrateInstances: (instances at: i)
			to: (targetClasses at: i) ]'
	context: ((Array with: topClass with: self gsClassOrganizer) putInGSSession: self)
]

{ #category : 'private - class redefinition' }
GbsSession >> versionedOldClass: oldClass withNewClass: newClass
[
	"Private.  Iterate over the old class and all its subclasses to recompile"

	| failedMethods |
	(self
		evaluateBlock: '[:old :new | old == new]'
		with: oldClass
		with: newClass
		context: nil)
			ifFalse: 
				[failedMethods := OrderedCollection new.
				self
					recompileWithSubclassesFrom: oldClass
					to: newClass
					failedMethods: failedMethods
					symbolList: self symbolListProxy.
				self reportFailedMethodRecompiles: failedMethods]
]

{ #category : 'threading' }
GbsSession >> critical: aBlock 
[
	"Evaluate aBlock, not allowing any other client Smalltalk Process 
	to interact with this session until the block completes."

	^self sessionCritical: 
			[GbsConfiguration current alwaysUseGemCursor 
				ifTrue: [gbsm showBusyWhile: aBlock]
				ifFalse: [aBlock value]]
]

{ #category : 'private - object creation' }
GbsSession >> newObjects: classArray withIdxSizes: sizeArray 
[
	"Private.  Returns an array of GbsObjects in this session.  The size of the resulting array is the same size as classArray and sizeArray.  The nth element of the result will be a GbsObject for a new instance of class classArray[n], with an indexable size of sizeArray[n]."

	self gbsMessenger 
		error: '#newObjects:withIdxSizes: is not supported in this version of GBS.'
]

{ #category : 'private - object creation' }
GbsSession >> newObjectOfClass: classDelegate 
[
	"Private.  Returns a proxy for a new GemStone object of the given class in the receiver session."

	self gbxFixMe.	"This method should be removed after all senders of it are gone."
	^self unsynchronizedExecute: 'self _basicNew' context: classDelegate
]

{ #category : 'private - processor balancing' }
GbsSession >> processorSchedulerBalanceClient: clientDelay gemStone: gsDelay 
[
	"Private.  Create a client process to balance processing time between
	 client and GemStone processes.  When this method is called with
	 positive integer values, GemBuilder will fork a client process which
	 will loop indefinately, alternating between delaying for clientDelay
	 milliseconds in the client, and gsDelay milliseconds in GemStone,
	 to allow forked GemStone processes to execute.  Setting gsDelay
	 to a high value will block the use of the GemStone session from the
	 client for longer intervals (if GemBuilder is using non-blocking
	 protocol for that session), or blocking all client Smalltalk processes
	 during those intervals (if GemBuilder is using blocking protocol).
	 Setting the clientDelay high has the effect of not allowing background
	 GemStone processes to run during that period, making GemStone
	 processes run less smoothly.  If this method is called with either
	 argument <= 0, the processor scheduler balancing process will
	 be terminated."

	self stopProcessBalancer.	"Avoid starting multiple poller processes!"
	(clientDelay <= 0 or: [gsDelay <= 0 or: [self isLoggedIn not]]) 
		ifTrue: [^self].
	procBalancer := 
			[
			[self isLoggedIn 
				ifTrue: 
					[[self yieldToGemStoneForMilliseconds: gsDelay] 
						on: GbsError hostErrorSignal
						do: 
							[:ex | 
							procBalancer == Processor activeProcess 
								ifFalse: 
									["The proc balancer has been requested to terminate - ignore the error"

									procBalancer := nil.
									ex return: self]
								ifTrue: 
									[self isLoggedIn 
										ifTrue: 
											["Automatically restart the balancer if a GemStone process
							 gets an exception that causes the balancer to stop"

											self processorSchedulerBalanceClient: clientDelay gemStone: gsDelay.
											"May be debuggable GemStone error - let the exception get handled
							 higher up the stack"
											ex pass]
										ifFalse: 
											["Stack won't be too interesting to the programmer - supply an
							 exception with a more interesting error message."

											self gbsMessenger 
												error: 'Background GemStone processes terminated due to error: %1'
												with: ex errorString.
											ex return: self]]]	"All errors"].
			(GbxDelay forMilliseconds: clientDelay) wait.
			"Terminate when eventPoller has been reassigned or we log out"
			procBalancer == Processor activeProcess and: [self isLoggedIn]] 
					whileTrue: []] 
					newProcess.
	procBalancer priority: configuration eventPriority.
	procBalancer resume
]

{ #category : 'private - processor balancing' }
GbsSession >> yieldToGemStoneForMilliseconds: duration 
[
	"Private.  Yield control to the GemStone ProcessorScheduler"

	"Do the wait at the highest priority, to prevent a higher priority
	 GemStone process from keeping us from getting control back to
	 the client."

	self execute: 'Delay _highPriorityWaitForMilliseconds: self'
		context: duration
]

{ #category : 'private - processor balancing' }
GbsSession >> stopProcessBalancer
[
	"Private"

	procBalancer := nil
]

{ #category : 'named objects' }
GbsSession >> resolveSymbolObj: aGemStoneObject 
[
	"Lookup aGemStoneObject (a Smalltalk string) in the GemStone session's default symbol list.  Raise a GBS error if not found."

	GbsConfiguration 
		deprecated: 'GbsSession>>resolveSymbolObj:  deprecated March, 2006. Use GbsSession>>resolveSymbol: instead'.
	^self 
		resolveSymbolObj: aGemStoneObject
		symbolList: self oopNil
		ifAbsent: 
			[self gbsMessenger error: 'No GemStone object named %1'
				with: aGemStoneObject asLocalObject]
]

{ #category : 'named objects' }
GbsSession >> resolveSymbolObj: aGemStoneObject ifAbsent: aBlock 
[
	"Lookup aGemStoneObject (a GemStone string) in the GemStone session's default symbol list.  If it isn't found, execute zero-argument block aBlock."

	GbsConfiguration 
		deprecated: 'GbsSession>>resolveSymbolObj:ifAbsent:  deprecated March, 2006. Use GbsSession>>resolveSymbol:ifAbsent: instead'.
	^self 
		resolveSymbolObj: aGemStoneObject
		symbolList: self oopNil
		ifAbsent: aBlock
]

{ #category : 'named objects' }
GbsSession >> at: aSymbol put: stObject inDictionaryNamed: dictName
[

	"Stores the GemStone replicate of stObject in the GemStone symbol dictionary named dictName.  The GemStone/Smalltalk object relationship will be registered with the GBS transparency mechanism (if it isn't already registered)."

	| dict |
	self gbsMessenger
		statusTag: #at:put:inDictionaryNamed:
		message: '(s%1) GSSession>>at: #%2 put: %3 inDictionaryNamed: %4'
		with: self sessionId
		with: aSymbol
		with: stObject
		with: dictName.
	dict := self
		resolveSymbol: dictName
		ifAbsent: [ ^self gbsMessenger error: 'There is no dictionary named %1 in your GemStone symbol list' with: dictName ].
	dict
		remotePerform: #at:put:
		with: aSymbol
		with: stObject.
	self gbsMessenger
		statusTag: nil
		message: '(s%1) completed GSSession>>at: #%2 put: %3 inDictionaryNamed: %4'
		with: self sessionId
		with: aSymbol
		with: stObject
		with: dictName.
	^stObject
]

{ #category : 'named objects' }
GbsSession >> fwat: aSymbol
[

	"Like at:, except the return value is a forwarder."

	^self fwat: aSymbol ifAbsent: [ self gbsMessenger error: 'No GemStone object is named %1' with: aSymbol ]
]

{ #category : 'named objects' }
GbsSession >> objectNamed: aString
[

	"This method is to preserve the old protocol.  The new resolveSymbol methods are much faster than the GBS 2.0 objectNamed methods."

	^self resolveSymbol: aString
]

{ #category : 'named objects' }
GbsSession >> resolveSymbolObj: aGSObject symbolList: gsSymbolList 
[
	"Lookup aGSObject (a GemStone string) in the GemStone symbol list gsSymbolList (a GemStoneObject).  If it isn't found, a GBS error is raised."

	GbsConfiguration 
		deprecated: 'GbsSession>>resolveSymbolObj:symbolList:  deprecated March, 2006. Use GbsSession>>resolveSymbol:symbolList: instead'.
	^self 
		resolveSymbolObj: aGSObject
		symbolList: gsSymbolList
		ifAbsent: 
			[self gbsMessenger error: 'No GemStone object named %1' with: aGSObject]
]

{ #category : 'named objects' }
GbsSession >> fwat: aSymbol ifAbsent: aBlock
[
	"Like at:ifAbsent:, except the return value is a forwarder"

	| result |
	self gbsMessenger
		statusTag: #fwat:ifAbsent:
		message: '(s%1) GbsSession>>fwat: #%2 ifAbsent: %3'
		with: self sessionId
		with: aSymbol
		with: aBlock.
	result := self
				resolveSymbol: aSymbol
				symbolList: self oopNil
				ifAbsent: [nil].
	result isNil ifTrue: [^aBlock value].
	"Add it to the export set - resolveSymbol: doesn't do this prior to GS/S 6.0"
	self isSingleTrip ifFalse: [result save].
	result := result asForwarder.
	self gbsMessenger
		statusTag: nil
		message: '(s%1) completed GSSession>>fwat:ifAbsent:, result = %2'
		with: self sessionId
		with: result.
	^result
]

{ #category : 'named objects' }
GbsSession >> objectNamed: aString ifAbsent: aBlock
[

	"This method is to preserve the old protocol.  The new resolveSymbol methods are much faster than the GBS 2.0 objectNamed methods."

	^self resolveSymbol: aString ifAbsent: aBlock
]

{ #category : 'named objects' }
GbsSession >> add: anAssociation
[

	"Stores the GemStone replicate of anAssociation in the GemStone 'UserGlobals' dictionary.  The GemStone/Smalltalk object relationship will be registered with the GBS transparency mechanism (if it isn't already registered)."

	^self at: anAssociation key put: anAssociation value
]

{ #category : 'named objects' }
GbsSession >> resolveSymbolObj: stringDelegate symbolList: gsSymbolList ifAbsent: aBlock 
[
	"Lookup aGSObject (a delegate for a server string) in the server symbol list gsSymbolList (a delegate).  If it isn't found, execute zero-argument block aBlock."

	GbsConfiguration 
		deprecated: 'GbsSession>>resolveSymbolObj:symbolList:  deprecated March, 2006. Use GbsSession>>resolveSymbol:symbolList:ifAbsent: instead'.
	^self 
		resolveSymbol: stringDelegate
		symbolList: gsSymbolList
		ifAbsent: aBlock
]

{ #category : 'named objects' }
GbsSession >> removeKey: aSymbol ifAbsent: aBlock inDictionaryNamed: dictName
[
	"Removes the given key from the GemStone symbol dictionary named dictName.  Returns the Smalltalk replicate of the value that existed at the given key.  If the key doesn't exist, return aBlock value."

	| dict |
	dict := self resolveSymbol: dictName ifAbsent: [nil].
	dict isNil ifTrue: [^aBlock value].
	^[dict performOnGsServer: #removeKey: withArguments: (Array with: aSymbol)] on: (GbsError signalFor: #rtErrKeyNotFound)
		do: [:ex | ex return: aBlock value]
]

{ #category : 'named objects' }
GbsSession >> at: aSymbol ifAbsent: aBlock 
[
	"Resolves aSymbol within this session's GemStone symbol list, and returns the Smalltalk replicate for that GemStone object.  The GemStone/Smalltalk object relationship will be registered with the GBS transparency mechanism."

	| result |
	self gbsMessenger 
		statusTag: #at:ifAbsent:
		message: '(s%1) GSSession>>at: #%2 ifAbsent: %3'
		with: self sessionId
		with: aSymbol
		with: aBlock.
	self flushDirtyToGS.
	result := self 
				resolveSymbol: aSymbol
				symbolList: self oopNil
				ifAbsent: [nil].
	result isNil ifTrue: [^aBlock value].
	result := result asLocalObject.
	self gbsMessenger 
		statusTag: nil
		message: '(s%1) completed GSSession>>at: #%2 ifAbsent: %3, result = %4'
		with: self sessionId
		with: aSymbol
		with: aBlock
		with: result.
	^result
]

{ #category : 'named objects' }
GbsSession >> removeKey: aSymbol ifAbsent: aBlock
[

	"Removes the given key from UserGlobals.  Returns the Smalltalk replicate of the value that existed at the given key.  If the key doesn't exist, return aBlock value."

	^self removeKey: aSymbol ifAbsent: aBlock inDictionaryNamed: #UserGlobals
]

{ #category : 'named objects' }
GbsSession >> removeKey: aSymbol inDictionaryNamed: dictName
[
	"Removes the given key from the GemStone symbol dictionary named dictName.  Returns the Smalltalk replicate of the value that existed at the given key."

	| dict |
	dict := self resolveSymbol: dictName
				ifAbsent: [^self gbsMessenger error: 'There is no dictionary named %1 in your GemStone symbol list' with: dictName].
	^dict performOnGsServer: #removeKey: withArguments: (Array with: aSymbol)
]

{ #category : 'named objects' }
GbsSession >> resolveSymbol: aString 
[
	"Lookup aString (a Smalltalk string) in the GemStone session's default symbol list.  Raise a GBS error if not found."

	^self 
		resolveSymbol: aString
		symbolList: self oopNil
		ifAbsent: 
			[self gbsMessenger error: 'No GemStone object named %1' with: aString]
]

{ #category : 'named objects' }
GbsSession >> at: aSymbol
[

	"Resolves aSymbol within this session's GemStone symbol list, and returns the Smalltalk replicate for that GemStone object.  The GemStone/Smalltalk object relationship will be registered with the GBS transparency mechanism."

	^self at: aSymbol ifAbsent: [ self gbsMessenger error: 'No GemStone object named %1' with: aSymbol ]
]

{ #category : 'named objects' }
GbsSession >> at: aSymbol put: stObject
[

	"Stores the GemStone replicate of stObject in the GemStone 'UserGlobals' dictionary.  The GemStone/Smalltalk object relationship will be registered with the GBS transparency mechanism (if it isn't already registered)."

	^self at: aSymbol put: stObject inDictionaryNamed: #UserGlobals
]

{ #category : 'named objects' }
GbsSession >> removeKey: aSymbol
[

	"Removes the given key from the GemStone symbol dictionary named dictName.  Returns the Smalltalk replicate of the value that existed at the given key."

	^self removeKey: aSymbol inDictionaryNamed: #UserGlobals
]

{ #category : 'named objects' }
GbsSession >> includesKey: aSymbol
[

	"Return true if aSymbol is in this GemStone session's name space"

	^(self resolveSymbol: aSymbol ifAbsent: [ nil ]) notNil
]

{ #category : 'named objects' }
GbsSession >> resolveSymbol: aString ifAbsent: aBlock 
[
	"Lookup aString (a Smalltalk string) in the GemStone session's default symbol list.  If it isn't found, execute zero-argument block aBlock."

	^self 
		resolveSymbol: aString
		symbolList: self oopNil
		ifAbsent: aBlock
]

{ #category : 'named objects' }
GbsSession >> resolveSymbol: aString symbolList: gsSymbolList
[

	"Lookup aString (a Smalltalk string) in the GemStone symbol list gsSymbolList (a GemStoneObject).  If it isn't found, a GBS error is raised."

	^self
		resolveSymbol: aString
		symbolList: gsSymbolList
		ifAbsent: [ self gbsMessenger error: 'No GemStone object named %1' with: aString ]
]

{ #category : 'named objects' }
GbsSession >> resolveSymbol: aString symbolList: gsSymbolList ifAbsent: aBlock
[
	"Lookup aString (a Smalltalk string) in the GemStone symbol list gsSymbolList (a GemStoneObject).
	 If it isn't found, execute zero-argument block aBlock."

	| token result |
	self gbsMessenger
		statusTag: #resolveSymbol:symbolList:
		message: '(s%1) GbsSession>>resolveSymbol: %2, symbolList: %3'
		with: self sessionId
		with: aString
		with: gsSymbolList.
	token := 'NotFoundOnServer' copy asGSObjectInSession: self.
	result := self
				executeBlock: '
					[:string :token | 
					| symbol assoc |
					symbol := string asSymbol.
					assoc := self == nil 
								ifTrue: [GsSession currentSession resolveSymbol: symbol]
								ifFalse: [self resolveSymbol: symbol].
					assoc == nil ifTrue: [token] ifFalse: [assoc value]]'
				with: aString
				with: token
				context: gsSymbolList.
	^result == token ifTrue: [aBlock value] ifFalse: [result]
]

{ #category : 'transaction control' }
GbsSession >> continueTransaction
[
	"Tells the  GemStone session to perform the System>>continueTransaction method.  See the description of System>>continueTransaction in the GemStone documentation.  Answer whether a commit done instead would have been successful."

	| couldCommit |
	self isLoggedIn ifFalse: [^nil].
	self gbsMessenger
		statusTag: #continueTransaction
		message: '(s%1) GbsSession>>continueTransaction'
		with: self sessionId.

	"Don't let other threads flush, commit, or abort during this operation"
	self sessionCritical: 
			["The remotePerform will flush dirty client objects, then perform,
		 then update client replicates of dirty GemStone objects"
			couldCommit := self systemProxy performOnGsServer: #continueTransaction.
			self resetClassOrganizer.
			self changed: #aborted].
	self gbsMessenger
		statusTag: nil
		message: '(s%1) completed GbsSession>>continueTransaction, couldCommit = %2'
		with: self sessionId
		with: couldCommit.
	^couldCommit
]

{ #category : 'transaction control' }
GbsSession >> disableSignaledAbortError
[

	"Turn off generation of #rtErrSignalAbort (which signals that the gem process should abort to connect to a more current repository root).  Ignore the error if it is generated as we turn it off."
	"GBSM currentSession disableSignaledAbortError"

	[ self systemProxy unsynchronizedPerform: #disableSignaledAbortError ]
		on: (GbsError signalFor: #rtErrSignalAbort)
		do: [ :ex | ex return ]
]

{ #category : 'transaction control' }
GbsSession >> enableSignaledAbortError
[
	"Turn on generation of #rtErrSignalAbort, which, when generated, is a suggestion that the session should abort to connect to a more current repository root.  When this signal occurs, it is disabled."

	"GBSM currentSession enableSignaledAbortError"

	self sessionCritical: 
			[self systemProxy unsynchronizedPerform: #enableSignaledAbortError]
]

{ #category : 'transaction control' }
GbsSession >> inTransaction
[
	"Returns true if the receiver is in inside a transaction.  If false, a transaction must be explicitly started with beginTransaction before commit will be permitted."

	^self sessionCritical: 
			[self isLoggedIn 
				and: [(self systemProxy unsynchronizedPerform: #inTransaction) asLocalObject]]
]

{ #category : 'transaction control' }
GbsSession >> needsCommit
[
	"Return true if this session's current transaction might have made changes
	 to the repository.  Return false if it is known that no changes have been made
	 (ie, so far this is a read-only transaction)."

	dirtyPool size > 0 ifTrue: [^true].
	^self systemProxy performOnGsServer: #needsCommit
]

{ #category : 'transaction control' }
GbsSession >> beginTransaction
[

	"Starts a new transaction for the session.  If the session is already in a transaction,
	 aborts the transaction and then starts a new transaction for the session.  If any
	 permanent objects had been written by the session, their state is aborted.
	 Returns the receiver."

	"Don't 'abort' if any of my dependents object"
	(self changeRequest: #queryAbort) ifFalse: [ ^nil ].

	self gbsMessenger
		statusTag: #beginTransaction
		message: '(s%1) GbsSession>>beginTransaction'
		with: self sessionId.

	"The remotePerform will flush this session's dirty client objects before beginTransaction,
	 so 'temps' can survive the abort.  After the beginTransaction, client replicates of dirty
	 GemStone objects will be updated."
	self systemProxy remotePerform: #beginTransaction.
	self postAbort.

	self gbsMessenger
		statusTag: nil
		message: '(s%1) GbsSession>>beginTransaction completed'
		with: self sessionId.

	self changed: #beganTransaction.
]

{ #category : 'transaction control' }
GbsSession >> signaledAbortAction: aBlock 
[
	"When #rtErrSignalAbort occurs, evaluate aBlock.  This should be a zero-argument block.
	 If notification occurs during GemStone execution, continue that execution.  If aBlock is
	 nil, previously installed signaledAbortAction will be deinstalled."

	| abortSignal |
	abortSignal := GbsError signalFor: #rtErrSignalAbort.
	aBlock isNil 
		ifTrue: 
			["This is a request to turn off signalAbort"

			self disableSignaledAbortError.
			self 
				onEventSignal: abortSignal
				handle: nil
				raiseException: true.
			^nil].

	"We don't want to see any events during installation"
	self stopEventDetection.
	self 
		onEventSignal: abortSignal
		handle: 
			[:gsErr :sess | 
			sess 
				sessionCritical: [[aBlock value] ensure: [sess enableSignaledAbortError]].
			gsErr]
		raiseException: false.
	self enableSignaledAbortError.
	self startEventDetection
]

{ #category : 'transaction control' }
GbsSession >> transactionConflicts
[
	"Returns a symbol dictionary in which the keys are:
		Read-Write			ReadSet and WriteSetUnion conflicts.
		Write-Read			WriteSet and ReadSetUnion conflicts.
		Write-Write			WriteSet and WriteSetUnion conflicts.
		Read-ExclusiveLock	ReadSet and ExclusiveLockSet conflicts.
		Write-ReadLock		WriteSet and ExclusiveLockSet conflicts.
		Write-WriteLock		WriteSet and WriteLockSet conflicts.

	The key indicates the kind of conflict detected and the value is
	an array containing references to the objects that are conflicting.
	If the conflict is on an internal object (used for indexes) the
	string 'index object' is included in the array.
	If there are no conflicts for the transaction, an empty dictionary
	is returned.  The conflict sets are cleared at the beginning of a
	commit and therefore may be examined until the next commit."

	^self systemProxy performOnGsServer: #transactionConflicts
]

{ #category : 'transaction control' }
GbsSession >> hasConflicts
[

"Determines, given my present state, if any concurrency
 conflicts exist that would cause a subsequent commit operation to fail.
 Returns false if it finds no conflicts with other concurrent transactions.
 Returns true if it does find conflicts, which can then be examined by
 sending me  #transactionConflicts.

 This method has meaningful results whether or not I am currently
 running inside a transaction.

 Note:  Even if this method returns false, there is no guarantee that a
		subsequent commit operation will succeed.

 If certain updates have been made to reduced conflict objects, it cannot
 be determined until a commit is attempted whether or not a conflict exists.
 In the following cases, this method always returns true:

   * Any change to an RcPositiveCounter during the current session.
   * One or more removals from an RcIdentityBag during the current session.
   * A session performs both additions and removals from an RcQueue which
	 it has not accessed in this transaction or previous transactions.

 A side effect of executing this method is that all of the connected
 objects are flushed to pages."


	^ self gsCurrentSession hasConflicts.
]

{ #category : 'transaction control' }
GbsSession >> transactionMode
[
	"Returns the current state of the transaction mode for the session, either
	 #autoBegin or #manualBegin.  The default for transactionMode is #autoBegin."

	^self unsynchronizedEvaluate: 'System transactionMode'
]

{ #category : 'transaction control' }
GbsSession >> transactionMode: newMode 
[
	"Sets a newMode for the transaction mode and exits the previous mode by performing an abort.  Valid arguments are #autoBegin and #manualBegin.  When the receiver is in the #autoBegin transaction mode, aborts and commits automatically begin a new transaction.  Returns the receiver."

	self gbsMessenger 
		statusTag: #transactionMode
		message: '(s%1) GSSession>>transactionMode: %2'
		with: self sessionId
		with: newMode.
	self sessionCritical: 
			[| onewMode |
			onewMode := newMode asGSObjectInSession: self.

			"Flush this session's dirty Smalltalk objects before abort - so 'temps' can survive the abort."
			self flushDirtyToGS.
			self systemProxy remotePerform: #_primTransactionMode: with: onewMode.
			self postAbort].
	self gbsMessenger 
		statusTag: nil
		message: '(s%1) completed GSSession>>transactionMode:'
		with: self sessionId.
	gbsm changed: #transactionMode with: self
]

{ #category : 'transaction control' }
GbsSession >> asyncAbortStartAction: startBlock finishAction: finishBlock
[
	"Use of this feature requires consulting, since it requires coordinated 
	use of other consulting-only features such as custom replicators.
	
	When an asynchronous abort is detected, the startBlock is evaluated 
	with one argument -- a collection of any objects that were dirty on 
	the client and not successfully sent to the server before the asynchronous
	abort happened. These objects are no longer marked dirty on the client.
	It is the application's responsibility to subsequently mark dirty any of these
	objects that it still wants to send to the server! Usually, the start block
	will change some application-specific state used by custom replicators
	to know that they are handling asynchronous updates to objects.
	
	After the start block's evaluation completes, GBS asks the server
	for a traversal of all replicated objects whose state changed due 
	to the asynchronous abort. This traversal is handled in the usual way.
	It is up to the application's custom replicators to detect and resolve any logical
	conflicts.
	
	After all changed objects are traversed, GBS evaluated the finishBlock 
	with no arguments.
	Typical actions for the finishBlock would be
	to reset application-specific state to let custom replicators react normally,
	and possibly to mark some objects dirty. The value returned by finishBlock
	is returned to the application as the result of the operation originally
	being attempted when the asynchronous abort was detected.
	
	Neither startBlock nor finishBlock should interact with the GemStone server.
	"

	startBlock == nil
		ifFalse: 
			[asyncAbortStartAction := startBlock.
			asyncAbortFinishAction := finishBlock.
			self autoServiceSigAbort: true]
		ifTrue: 
			["Disable async abort *first* since this action might itself detect an async abort."
			self autoServiceSigAbort: false.
			self resetAsyncAbortActions]
]

{ #category : 'transaction control' }
GbsSession >> commitAndReleaseLocks
[
	"Attempts to commit the transaction for the receiver session.
	If the commit succeeds, releases all locks for the session and
	returns true.  Otherwise, returns false and does not release locks."

	^self systemProxy performOnGsServer: #commitAndReleaseLocks
]

{ #category : 'transaction control' }
GbsSession >> commitTransaction
[
	"Attempt to commit the GemStone transaction for this session.  If the commit
	 succeeds and the transaction mode is #autoBegin, a new transaction is
	 started.  If #manualBegin, a new transaction is not started after a successful
	 commit.  If commit is attempted when the session is outside of a transaction,
	 #rtErrPrimOutsideTrans is generated.  Return true if it succeeds, false if it
	 fails.  Returns nil if any dependent denied permission to commit."
	"Don't commit if any of my dependents object"

	| committed |
	(self changeRequest: #queryCommit) ifFalse: [^nil].
	self gbsMessenger
		statusTag: #commitTransaction
		message: '(s%1) GbsSession>>commitTransaction'
		with: self sessionId.

	"The remotePerform will flush dirty client objects, then commit, then update client
	 replicates of dirty GemStone objects, under protection of the commitFlushProtect
	 semaphore."
	committed := self systemProxy performOnGsServer: #commitTransaction.
	self postCommitSucceeded: committed.
	self gbsMessenger
		statusTag: nil
		message: '(s%1) completed GbsSession>>commitTransaction, returned %2'
		with: self sessionId
		with: committed.
	^committed
]

{ #category : 'private - event handling' }
GbsSession >> onEventSignal: signal handle: handler raiseException: raiseException 
[
	"When the signal occurs, handler (a one or two argument block) will be evaluated
	 with an instance of GbsError as the first argument, and the session that received the
	 error as the optional second argument.  The boolean raiseException indicates whether
	 the signal should be raised after executing the handler.
	The event handler (or the exception handler, if an exception is raised) must answer whatever is
	to be answered to the application. If, as in the case of asynchronous notifications, it's not time
	to return to the application, the event handler must answer gsErr, its first argument."

	handler isNil ifTrue: [^eventHandlers removeKey: signal ifAbsent: [nil]].
	eventHandlers
		at: signal
		put: 
			[:gsErr :sess | 
			| result |
			result := handler gbxNumArguments = 1 
						ifTrue: [handler value: gsErr]
						ifFalse: [handler value: gsErr value: sess].
			raiseException
				ifTrue: [gsErr raiseException]
				ifFalse: [result]]
]

{ #category : 'private - event handling' }
GbsSession >> startEventDetection
[
	"Private.  After this method is called, GemStone-generated events occurring in 
	this session will be detected by the Smalltalk client (ex: changed object 
	notification, gem-to-gem notifiers, signaled abort)."

	self sessionCritical: [serverInterface startEventDetection]
]

{ #category : 'private - event handling' }
GbsSession >> handleClientForwarders
[
	"Private.  GBSM currentSession handleClientForwarders"

	self 
		onEventSignal: (GbsError signalFor: #clientForwarderSend)
		handle: [:gsErr :sess | sess doClientForwarderSend: gsErr]
		raiseException: false
]

{ #category : 'private - event handling' }
GbsSession >> doClientForwarderSend: gsErr
[
	"Perform the requested client forwarder send specified by
	 gsErr.  Poke the result into gsResult into gsErr and return
	 that result."

	| receiver sel args result |
	self sessionCritical: 
			[receiver := self clientObjForDelegate: (gsErr arguments at: 1) otherwise: notCachedToken.
			sel := (gsErr arguments at: 3) asLocalObject.
			args := (gsErr arguments at: 4) asLocalObject].
	self gbsMessenger
		statusTag: #clientForwarderSend
		message: '(s%1) GbsSession>>doClientForwarderSend - receiver: a %2, sel: %3'
		with: self sessionId
		with: receiver gbxBasicClass name
		with: sel.
	result := receiver == notCachedToken
				ifTrue: 
					[sel == #class
						ifTrue: 
							["Help sometimes difficult debugging scenarios"
							GbsConfiguration current verbose ifTrue: [self gbsMessenger comment: 'Client forwarder send #class to unknown client object - proceeding with OClientForwarder'].
							OClientForwarder]
						ifFalse: [self gbsMessenger error: 'Client forwarder send (#%1) to unknown client object' with: sel]]
				ifFalse: [receiver perform: sel withArguments: args].
	result := (sel == #class and: [(self cacheAtST: result) isNil]) ifTrue: [OClientForwarder asGSObjectInSession: self] ifFalse: [result asGSObjectInSession: self].	"self flushDirtyToGS.     This will be done automatically, no need for extra round trip here"
	gsErr gsResult: result.
	self gbsMessenger
		statusTag: nil
		message: '(s%1) completed GbsSession>>doClientForwarderSend'
		with: self sessionId.
	^gsErr
]

{ #category : 'private - event handling' }
GbsSession >> stopNbWaitSocket
[
	"Private. It's OK to send this even if we aren't using socket waits, or the socket is already stopped."

	| cif |
	cif := serverInterface.	"cInterface could become nil at any moment, hence the temp var."
	cif notNil ifTrue: [cif stopNbWaitSocket]
]

{ #category : 'private - event handling' }
GbsSession >> initializeEventHandlers
[
	"Private.  Event handlers will get processed before GemBuilder raises
	 an exception for that event."

	eventHandlers := IdentityDictionary new.
	self
		onEventSignal: GbsBkupErrRestoreSuccessful
			handle: [:gsErr :sess | sess sessionCritical: [sess initializeCaches]]
			raiseException: true;
		onEventSignal: GbsAbortErrLostOtRoot
			handle: [:gsErr :sess | sess postLostOTroot]
			raiseException: true;
		onEventSignal: GbsAbortingError
			handle: [:gsErr :sess | sess postAbnormalAbort]
			raiseException: true;
		onEventSignal: GbsFatalError
			handle: 
				[:gsErr :sess |
				"Clean up"
				sess quietLogout]
			raiseException: true;
		onEventSignal: GbsRtErrStep
			handle: 
				[:gsErr :sess | "Nothing to do after 3.3"]
			raiseException: true;
		handleClientForwarders
]

{ #category : 'private - event handling' }
GbsSession >> stopEventDetection
[
	"Private. It's OK to send this even if event detection is already stopped.
	Session could be already logged out, or logging out."

	| sif |
	sif := serverInterface.	"serverInterface could become nil at any moment, hence the temp var."
	sif notNil
		ifTrue: [self sessionCriticalNoSessionCheck: [sif stopEventDetection]]
]

{ #category : 'private - event handling' }
GbsSession >> processEventHandlerFor: aGbsError 
[
	"Private.  If there's an event block for aGbsError, evaluate it."

	| handler match |
	aGbsError dontRaise: true.	"make sure we don't raise this again if we make it here. This happens in debugger stepping"
	match := GbsError closestSignalTo: aGbsError asExceptionClass
				from: eventHandlers keys.
	match isNil ifTrue: [^aGbsError raiseException].

	"There's an event handler for eventSignal"
	self gbsMessenger 
		statusTag: #processEventHandler
		message: '(s%1) GbsSession>>processEventHandlerFor: %2: %3'
		with: self sessionId
		with: aGbsError errorSymbol
		with: aGbsError messageText.
	handler := eventHandlers at: match.
	^handler value: aGbsError value: self
]

{ #category : 'lock status' }
GbsSession >> systemLocks
[
	"Returns a Dictionary describing all objects that are currently
	 locked.  For each Association in the result Dictionary, the key
	 is a SmallInteger (the session number of a GemStone session that
	 holds locks) and the value is the three-element sessionLocks array,
	 whose first element is an array of read-locked objects, second
	 element is an array of write-locked objects, and third element is
	 an array of exclusive-locked objects.  If no sessions hold any locks,
	 the result Dictionary is empty.

	 The Arrays in the result Dictionary contains only those objects
	 visible to the current session.  Locks that the current session
	 cannot see (objects that have been committed since the beginning
	 of the current transaction, uncommitted objects from other sessions,
	 or locks on objects for which this session has no read authorization)
	 are not returned."

	^self systemProxy performOnGsServer: #systemLocks
]

{ #category : 'lock status' }
GbsSession >> lockKind: anObject
[
	"Returns a Symbol (#none, #deferredUnlock, #read, #write, or #exclusive)
	representing the kind of lock held on anObject by any session in the system."

	^self systemProxy
		performOnGsServer: #lockKind:
		withArguments: (Array with: anObject)
]

{ #category : 'lock status' }
GbsSession >> lockOwners: anObject
[
	"Returns an Array of session numbers (SmallIntegers) representing
	the sessions that hold a lock on anObject.  If the object is not
	locked by any session, the result Array is empty.  Note that
	a write or exclusive lock can have only one owner."

	^self systemProxy performOnGsServer: #lockOwners: withArguments: (Array with: anObject)
]

{ #category : 'lock status' }
GbsSession >> sessionLocks
[
	"Returns a three-element Array describing the locks held by the
	 current session.  The first element is an Array of all read-locked
	 objects, the second is an Array of all write-locked objects, and
	 the third is an Array of all exclusive-locked objects. If the current
	 session holds no locks of a particular kind (read, write, exclusive),
	 the corresponding Array is empty.  If the current session holds no
	 locks at all, all three of these Arrays are empty."

	^self systemProxy performOnGsServer: #sessionLocks
]

{ #category : 'private - class translation' }
GbsSession >> doVarsForGS: gsClass match: stClass type: varTypeMessage
[
	"given a server class and a client class, compare the variable names"
	
	| ws |
	ws := WriteStream on: String new.
	ws nextPutAll: '#('.
	(stClass perform: varTypeMessage)
		do:
			[:name | 
			ws
				nextPut: $#;
				nextPut: $';
				nextPutAll: name;
				nextPut: $';
				space].
	ws nextPutAll: ') asSet'.
	(gsClass session
		unsynchronizedEvaluate:
			'self ' , varTypeMessage , ' asSet = ' , ws contents
		context: gsClass) ifFalse: [^false].
	^true
]

{ #category : 'private - class translation' }
GbsSession >> doesClientClass: clientClass matchServerClass: serverClassDel
[
	"Returns true if the given Smalltalk class matches the given GemStone class in
	 implementation structure, or if the Smalltalk class appears to have compensated for any
	 differences by implementing replication support methods."

	| matches |
	matches := self basicDoesClientClass: clientClass
				matchServerClass: serverClassDel.
	(matches or: [GbsConfiguration current confirm not]) ifTrue: [^true].
	^self gbsMessenger
		confirm: 'GemStone class and Smalltalk class named %1 don''t have the same structure--relate them anyway?'
		with: clientClass
]

{ #category : 'private - class translation' }
GbsSession >> lowestConnectedSuperclassesForSt: stClass gs: gsClass ifNone: noneBlock 
[
	"Private.  Returns an association whose key is a Smalltalk class and value is a GbsObject representing a GemStone class, such that a connection exists between those two classes, and it is first (lowest) connection found in tracing up their superclass hierarchy.  If both classes inherit from Object, and no other connection exists, then Object->OObject will be returned.  If either class doesn't inherit from Object and no other connection is found, noneBlock will be evaluated."

	| lowestCommonStSuper connectedStSuper |
	lowestCommonStSuper := stClass superclass.
	
	[lowestCommonStSuper isNil or: 
			[connectedStSuper := self cacheAtST: lowestCommonStSuper.
			connectedStSuper notNil and: 
					[gsClass = connectedStSuper 
						or: [gsClass remoteInheritsFrom: connectedStSuper]]]] 
			whileFalse: [lowestCommonStSuper := lowestCommonStSuper superclass].
	^lowestCommonStSuper isNil 
		ifTrue: [noneBlock value]
		ifFalse: [Association key: lowestCommonStSuper value: connectedStSuper]
]

{ #category : 'private - class translation' }
GbsSession >> mapClientBehavior: clientBehavior toServer: behaviorDelegate
[
	"Map the given client class or metaclass to the given delegate. 
	The sender must ensure that this mapping is not already made, 
	and that the clientBehavior is not mapped to any server object.
	The delegate may already be mapped to a stub or forwarder on the client, 
	in which case all references to the proxy
	must be made to refer to the client behavior.

	The sender must hold my sessionProtect."

	| existingMapping |
	existingMapping := self clientObjForDelegate: behaviorDelegate
				otherwise: nil.
	existingMapping == nil
		ifFalse: 
			[existingMapping gbxIsProxy
				ifTrue: 
					[self disconnectClient: existingMapping fromServer: behaviorDelegate.
					existingMapping oneWayBecome: clientBehavior]
				ifFalse: 
					[self gbsMessenger
						raise: GbsClassGenerationError
						message: 'Attempt to map client class %1 to %3 that is already mapped as a non-stub with client class %2'
						with: clientBehavior
						with: existingMapping
						with: behaviorDelegate remoteDescription]].
	self connectClient: clientBehavior toServer: behaviorDelegate.
	"Since we do not synchronize the state of behaviors, they should *not* be added to the pure export set."
	self updateInstVarNamesAndClamps.
	clientBehavior isMeta
		ifFalse: 
			[GbsConfiguration current verbose
				ifTrue: 
					[self gbsMessenger
						comment: '%1 has mapped GemStone and Smalltalk classes named %2.'
						with: self
						with: clientBehavior name]]
]

{ #category : 'private - class translation' }
GbsSession >> mappedClientClass: clientClass toServer: classDelegate
[
	"Private.  Do any work needed after a class is auto-mapped by a replicator. Auto-mapping is done on a same-name basis, so the server class name will always be the same as the client class simple name."

	(configuration generateClassConnectors
		and: [(self parameters connectorExistsFor: clientClass) not])
			ifTrue: 
				[parameters
					addNoConnectConnector: (GbsClassConnector stName: clientClass fullName
							gsName: clientClass name)]
]

{ #category : 'private - class translation' }
GbsSession >> basicDoesClientClass: clientClass matchServerClass: serverClassDel
[
	"Returns true if the given Smalltalk class matches the given GemStone class in
	 implementation structure, or if the Smalltalk class appears to have compensated for any
	 differences by implementing replication support methods."

	| impClass |

	(self privdoesClientClass: clientClass matchServerClass: serverClassDel)
		ifTrue: [^true].
	clientClass instancesAreForwarders ifTrue: [^true].

	"Structural difference compensated for with class methods?"
	clientClass instVarMap isEmpty ifFalse: [^true].

	"Structural difference compensated for with instance methods?"
	(#(#namedValues #namedValues: #indexableValues #indexableValues: #namedValues:indexableValues: #namedValueAt: #namedValueAt:put: #indexableValueAt: #indexableValueAt:put:)
		detect: 
			[:aSelector |
			impClass := clientClass whichClassIncludesSelector: aSelector.
			impClass notNil and: [impClass ~= Object]]
		ifNone: []) notNil
		ifTrue: [^true].
	^false
]

{ #category : 'private - class translation' }
GbsSession >> privdoesClientClass: clientClass matchServerClass: serverClassDel
[
	"Private.  Returns true if the given Smalltalk class matches the given GemStone class in implementation structure.  
	This message may NOT be called in the middle of a GemStone object traversal, since it initiates server execution.  
	This version of the method does not consider whether the Smalltalk class might compensate for any differences by 
	implementing methods such as namedValues, indexableValues, etc."
	"format instVar"
	"If the classes have added a different # of named instvars
	 from their matching superclasses, they don't match."

	| gsFormat lowestConnection stInstvarsAdded gsInstvarsAdded varTypeMessage |
	clientClass zzzisForwarder
		ifTrue: [^clientClass gbxValidateDelegateAndSession = serverClassDel].
	(clientClass isKindOf: Class)
		ifFalse: 
			[self gbsMessenger error: clientClass printString , ' is not a class'.
			^false].
	lowestConnection := self
				lowestConnectedSuperclassesForSt: clientClass
				gs: serverClassDel
				ifNone: [Association key: Object value: (OObject asGSObjectInSession: self)].
	stInstvarsAdded := clientClass instSize - lowestConnection key instSize.
	"Subtract one for gsobj cache, if added after lowestConnection"
	gsInstvarsAdded := (serverClassDel performOnGsServer: #instSize) 
				- (lowestConnection value performOnGsServer: #instSize) .
	stInstvarsAdded ~= gsInstvarsAdded ifTrue: [^false].

	"compare the variable names"
	varTypeMessage := #instVarNames.
	(self doVarsForGS: serverClassDel match: clientClass type: varTypeMessage)
		ifFalse: [^false].
	varTypeMessage := #classVarNames.
	(self doVarsForGS: serverClassDel match: clientClass type: varTypeMessage)
		ifFalse: [^false].
	varTypeMessage := #instVarNames.
	(self
		doVarsForGS: serverClassDel unsynchronizedRemoteClass
		match: clientClass class
		type: varTypeMessage) ifFalse: [^false].
	gsFormat := (serverClassDel fetchOOPAt: 2) asLocalObject.

	"If both classes are byte classes, they match in structure"
	clientClass isBits ifTrue: [^gsFormat \\ 4 = 1	"bytes"].

	"If both classes are Special, they match"
	gsFormat // 4 \\ 2 = 3
		ifTrue: 
			[^clientClass == SmallInteger | (clientClass == Character)
				| (clientClass == True) | (clientClass == False)
				| (clientClass == UndefinedObject)].

	"If both classes are indexable, they match in structure"
	clientClass isVariable | (clientClass == Collection)
		| (clientClass inheritsFrom: Collection)
			ifTrue: [^gsFormat // 4 \\ 2 = 1 | (gsFormat \\ 4 = 2)	"indexable"	"nsc"].

	"well, the only thing left is non-indexable pointer objects"
	^clientClass isVariable not
		& (gsFormat // 4 \\ 2 = 0 & (gsFormat \\ 4 = 0))	"non indexable"	"pointer"
]

{ #category : 'private - class translation' }
GbsSession >> classesNotToCreateOnServer
[
	" Answer a collection of client classes that should not be created on the server. 
	This is for one of several reasons: 
	* The class is a special class that should already exist on the server 
	* The class is part of GBS machinery and will create havoc if replicated (see bug 32962)
	* The class has unusual semantics that will prevent it from working correctly on the server"

	| classes |
	classes := ClassesNotToCreateOnServer.
	classes isNil 
		ifTrue: 
			[classes := Set new.
			classes
				add: Boolean;
				add: Character;
				add: False;
				add: True;
				add: SmallInteger;
				add: UndefinedObject;
				add: GbxDelegate;
				add: GbsError;
				add: GbsSession;
				add: GbsSessionParameters;
				add: GbsClassConnector;
				add: GbsConnector;
				add: GbxLargeIdentityDictionary;
				add: GbxRecursionLock;
				add: GbxSemaphore;
				add: GbxKernelPomOop.
			ClassesNotToCreateOnServer := classes].
	^classes
]

{ #category : 'private - class translation' }
GbsSession >> createClientClassFor: serverBehavior classified: category
[
	"Private.  Try to create a client class for the given server class or metaclass.  This may require recursion to create the superclasses needed."

	^self
		createClientClassFor: serverBehavior
		usingName: nil
		classified: category
		generateConnector: configuration generateClassConnectors
]

{ #category : 'private - class translation' }
GbsSession >> serverClassDefinitionStringFor: clientClass usingServerName: serverName inDictionaryNamed: serverDictName ifFail: oneArgFailBlock
[

	| instVars classInstVars classVars aStream isBits isVariable creationMessageString |
	instVars := clientClass gbxServerInstVarNames
				collect: [:each | each asString].
	classInstVars := clientClass gbxServerClassInstVarNames
				collect: [:each | each asString].
	classVars := clientClass gbxServerClassVarNames asArray
				collect: [:each | each asString].
	aStream := WriteStream on: (String new: 200).
	isBits := clientClass isBits.
	isVariable := clientClass isVariable & (clientClass gsObjImpl ~= 2).
	creationMessageString := isBits
				ifTrue: 
					[instVars size > 0
						ifTrue: 
							[^oneArgFailBlock
								value: ' - attempt to define server byte class with instance variables'].
					'self byteSubclass: #''']
				ifFalse: 
					[isVariable
						ifTrue: ['self indexableSubclass: #''']
						ifFalse: ['self subclass: #''']].
	aStream
		nextPutAll: creationMessageString;
		nextPutAll: serverName;
		nextPut: $'.
	isBits
		ifFalse: 
			[aStream
				cr;
				tab;
				nextPutAll: 'instVarNames: '.
			instVars storeOn: aStream].
	aStream
		cr;
		tab;
		nextPutAll: 'classVars: '.
	classVars storeOn: aStream.
	aStream
		cr;
		tab;
		nextPutAll: 'classInstVars: '.
	classInstVars storeOn: aStream.
	aStream
		cr;
		tab;
		nextPutAll: 'poolDictionaries: Array new'.
	aStream
		cr;
		tab;
		nextPutAll: 'inDictionary: ';
		nextPutAll: serverDictName.
	^aStream contents
]

{ #category : 'private - class translation' }
GbsSession >> serverClassWithSameNameAs: clientClass inDictionaryNamed: dictionaryNameOrNil
[
	"Given a client class which is not mapped, with a metaclass that is not mapped, 
	 this method checks the server for a compatible class with the same name.
	 If a dictionary name is specified, the class search is restricted to that specific
	 symbol dictionary. (This can arise when creating or updating a class for a connector
	 with a symbol dictionary specified.)
	 If found, it answers a delegate for the class but does not map them.
	 If not found, answer nil.

	 Sender must hold my sessionProtect."

	| classDelegate cName serverString |
	[clientClass isMeta not] gbxAssert.
	cName := clientClass name.
	serverString := (dictionaryNameOrNil isNil
				ifTrue: ['System myUserProfile objectNamed: #<2s>']
				ifFalse: 
					['| dictionary binding class |
					binding := GsSession currentSession resolveSymbol: #<1s>.
					binding == nil ifTrue: [^nil].
					dictionary := binding value.
					binding := dictionary associationAt: #<2s> otherwise: nil.
					binding == nil ifTrue: [^nil].
					class := binding value.
					class'])
						expandMacrosWith: dictionaryNameOrNil
						with: cName.
	classDelegate := self execute: serverString.
	classDelegate = self oopNil ifTrue: [^nil].
	"In some cases, classes were not getting put in the export set."
	[classDelegate isGcProtected] gbxAssertEquals: true
		message: 'Class delegate is not GC protected'.
	"Name may resolve to a non-behavior or to a metaclass, that doesn't count"
	(self evaluate: 'self isBehavior and: [self isMeta not]'
		context: classDelegate) ifFalse: [^nil].
	(self doesClientClass: clientClass matchServerClass: classDelegate)
		ifFalse: 
			[^self gbsMessenger
				raise: GbsClassGenerationError
				message: 'The class %1 is incompatible between GemStone and Smalltalk.'
				with: cName].
	"We now have a valid class."
	(configuration generateClassConnectors
		and: [(self parameters connectorExistsFor: clientClass) not])
			ifTrue: 
				[parameters
					addNoConnectConnector: (GbsClassConnector stName: cName gsName: cName)].
	^classDelegate
]

{ #category : 'private - class translation' }
GbsSession >> createClientClassFor: serverClass usingName: nameOrNil classified: category generateConnector: generateConnector
[
	"Private.  Try to create a client class for the given server class, which must be a delegate for a non-meta server class.  
	This may require recursion to create the superclasses needed.  
	If nameOrNil is nil, the client class will use the same name as the server class.  
	Otherwise, the supplied name will be used."

	| serverName serverSuper clientClass clientSuper gsClassInfo gsInstVars gsClassVars gsCIVs gsFormat clientName |
	self sessionCritical: 
			["The following evaluation will recursively invoke this method if superclass creation is needed."
			"collect information about the server class"
			gsClassInfo := self
						evaluate: '
| result rawClassVars classVarNames |
result := Array new.
rawClassVars := self _classVars.
classVarNames := rawClassVars == nil
			ifTrue: [Array new]
			ifFalse: [rawClassVars keys asArray].
result
	add: self name;
	add: self superclass;
	add: self instVarNames;
	add: classVarNames;
	add: self _classInstVars;
	add: self format.
result'
						context: serverClass.
			serverName := gsClassInfo at: 1.
			clientSuper := gsClassInfo at: 2.
			serverSuper := clientSuper gbxDelegate forSession: self.
			clientName := nameOrNil isNil ifTrue: [serverName] ifFalse: [nameOrNil].
			GbsConfiguration current verbose
				ifTrue: 
					[self gbsMessenger comment: 'Creating client class %1.' with: clientName].
			gsInstVars := gsClassInfo at: 3.
			gsClassVars := (gsClassInfo at: 4)
						collect: [:classVar | classVar asString gbxCapitalized asSymbol].
			gsCIVs := gsClassInfo at: 5.
			gsFormat := gsClassInfo at: 6.
			gsFormat \\ 4 = 3
				ifTrue: 
					[^self gbsMessenger raise: GbsClassGenerationError
						message: 'Attempt to create an immediate client class'].
			clientClass := clientSuper
						gbxCreateSubclassNamed: clientName
						inApplication: nil
						typeName: (gsFormat \\ 4 = 1 ifTrue: ['bytes'] ifFalse: ['pointers'])
						isVariable: (gsFormat \\ 4 = 1
								or: [gsFormat \\ 4 = 0 & (gsFormat // 4 \\ 2 = 1)])
						instanceVariables: gsInstVars
						classVariables: gsClassVars
						classInstanceVariables: gsCIVs
						poolNames: #()
						category: category.
			(clientClass isBehavior and: [clientClass isMeta not])
				ifFalse: 
					[^self gbsMessenger raise: GbsClassGenerationError
						message: 'A non-class object was generated'].
			"A client class has been successfully created"
			(generateConnector
				and: [(self parameters connectorExistsFor: clientClass) not])
					ifTrue: 
						[parameters addNoConnectConnector: (GbsClassConnector stName: clientName
									gsName: serverName)].
			self mapClientBehavior: clientClass toServer: serverClass.
			self mapClientBehavior: clientClass class
				toServer: (serverClass remotePerform: #class)].
	^clientClass
]

{ #category : 'private - class translation' }
GbsSession >> symbolDictionaryNamed: dictName
[
	"Private.  Answer a GbsObject representing the symbol list dictionary named dictName.
	 If no such dictionary exists in the user's symbol list, one is created."

	^self
		unsynchronizedExecuteBlock: 
			'[:name |
			| symbolList |
			symbolList := System myUserProfile symbolList.
			^symbolList
				detect: [:eachDict | eachDict name = name]
				ifNone: 
					["The symbol list does not contain the named dictionary - create it"
					| dict |
					dict := SymbolDictionary new.
					dict name: name.
					System myUserProfile
						insertDictionary: dict
						at: symbolList size + 1.
					dict]]'
		with: dictName asSymbol
		context: nil
]

{ #category : 'private - class translation' }
GbsSession >> validateClassForServerCreation: stClass 
[
	"If clientClass is one that should not be created on the server, raise an exception and 
	answer false if the exception is resumed. Otherwise, answer true."

	| stSuper stName |
	stName := stClass name.
	"Don't try to create a special class"
	(self classesNotToCreateOnServer includes: stClass) 
		ifTrue: 
			[self gbsMessenger 
				raise: GbsClassGenerationError
				message: 'Attempt to create server class for %1.'
				with: stName.
			^false].
	stClass isMeta 
		ifTrue: 
			[self gbsMessenger 
				raise: GbsClassGenerationError
				message: 'Attempt to create a server metaclass for %1.'
				with: stName.
			^false].
	stSuper := stClass superclass.
	(stSuper isNil or: [stSuper isKindOf: Class]) 
		ifFalse: 
			[self gbsMessenger 
				raise: GbsClassGenerationError
				message: 'Attempt to create server class for %1, which has a non-class superclass.'
				with: stClass.
			^false].
	^true
]

{ #category : 'private - class translation' }
GbsSession >> createServerClassFor: clientClass inDictionaryNamed: serverDictName 
[
	"Private.  Try to invent a GemStone class for the given Smalltalk
	 class - this may also require recursion to create the superclasses
	 needed."

	^self 
		createServerClassFor: clientClass
		inDictionaryNamed: serverDictName
		usingName: nil
		generateConnector: (configuration generateClassConnectors 
				and: [(self parameters connectorExistsFor: clientClass) not])
]

{ #category : 'private - class translation' }
GbsSession >> createServerClassFor: clientClass inDictionaryNamed: serverDictName usingName: serverNameOrNil generateConnector: generateConnector
[
	"Try to invent a GemStone class for the given Smalltalk class - this may also require recursion to create the superclasses needed.  If nameOrNil is nil, the name of stClass will be used.  Otherwise, nameOrNil will be used.
	If we are successful in creating the class, we map it to the given clientClass, first unmapping any mapping that the clientClass may have had."

	| classDelegate superclassDelegate definitionString clientName serverName saveGenerate |
	(self validateClassForServerCreation: clientClass) ifFalse: [^nil].
	clientName := clientClass name.
	serverName := serverNameOrNil isNil
				ifTrue: [clientName]
				ifFalse: [serverNameOrNil].
	GbsConfiguration current verbose
		ifTrue: 
			[self gbsMessenger comment: 'Creating Server class %1.' with: serverName].


	"Create the server class"
	definitionString := self
				serverClassDefinitionStringFor: clientClass
				usingServerName: serverName
				inDictionaryNamed: serverDictName
				ifFail: [:msg | self gbsMessenger raise: GbsClassGenerationError message: msg].
	self sessionCritical: 
			["Search for and map existing or create new server superclass (might result in recursive invocation of this method)."
			| existingClassDelegate existingMetaclassDelegate |
			superclassDelegate := self gemStoneClassFor: clientClass superclass.

			"Avoid infinite recursion of class generation"
			saveGenerate := configuration generateServerClasses.
			
			[configuration generateServerClasses: false.
			"Ensure the target dictionary exists."
			self symbolDictionaryNamed: serverDictName.
			classDelegate := self execute: definitionString context: superclassDelegate]
					ensure: [configuration generateServerClasses: saveGenerate].
			(self evaluate: 'self isBehavior and: [self isMeta not]'
				context: classDelegate)
					ifFalse: 
						[^self gbsMessenger
							raise: GbsClassGenerationError
							message: 'Error creating GemStone class for %1.'
							with: clientClass].
			generateConnector
				ifTrue: 
					[parameters addNoConnectConnector: (GbsClassConnector
								stName: clientName
								gsName: serverName
								dictionaryName: serverDictName)].
			existingClassDelegate := self cacheAtST: clientClass.
			existingMetaclassDelegate := self cacheAtST: clientClass class.
			(existingClassDelegate ~~ nil or: [existingMetaclassDelegate ~~ nil])
				ifTrue: 
					[(existingClassDelegate == nil or: [existingMetaclassDelegate == nil])
						ifTrue: 
							[self gbsMessenger
								error: 'Only one of class and metaclass is connected -- it should be both or neither.'].
					self
						disconnectClient: clientClass fromServer: existingClassDelegate;
						disconnectClient: clientClass class fromServer: existingMetaclassDelegate].
			self mapClientBehavior: clientClass toServer: classDelegate.
			self mapClientBehavior: clientClass class
				toServer: (classDelegate remotePerform: #class)].
	^classDelegate
]

{ #category : 'private - replicators' }
GbsSession >> connectReplicator: aReplicator toClientBehavior: clientBehavior andServerBehavior: behaviorDelegate
[
	"For use with most replicators, those that have both client and server behavior."
	"sender must hold my sessionProtect"

	replicatorManager
		atClient: clientBehavior
		andServer: behaviorDelegate
		put: aReplicator
]

{ #category : 'private - replicators' }
GbsSession >> replicatorForClientBehavior: aClientBehavior ifAbsent: alternativeBlock
[

	^replicatorManager replicatorForClientBehavior: aClientBehavior
		ifAbsent: alternativeBlock
]

{ #category : 'private - replicators' }
GbsSession >> replicatorForClient: anObject ifAbsent: alternativeBlock
[
	"Can be overridden in custom session subclasses."

	^self replicatorForClientBehavior: anObject gbxBasicClass
		ifAbsent: alternativeBlock
]

{ #category : 'private - replicators' }
GbsSession >> disconnectReplicatorForServerBehavior: behaviorDelegate
[
	"This message should be used only for replicators that have no 
	client class (for instance, unmapped class replicator), and are therefore
	not mapped by client class."
	"sender must hold my sessionProtect"

	replicatorManager removeReplicatorForServerBehavior: behaviorDelegate
]

{ #category : 'private - replicators' }
GbsSession >> setReplicatorForClient: secondaryBehavior sameAsReplicatorForClient: primaryBehavior
[
	"Used for those rare many-client-to-one-server class or metaclass mappings.
	The canonical mapping must already be present."
	"Sender must hold my sessionProtect semaphore."

	| replicator |
	replicator := self replicatorForClientBehavior: primaryBehavior
				ifAbsent: 
					[self gbsMessenger
						error: 'Attempted second mapping without first mapping present.'].
	replicatorManager atClient: secondaryBehavior put: replicator
]

{ #category : 'private - replicators' }
GbsSession >> disconnectReplicatorForClientBehavior: clientBehavior andServerBehavior: behaviorDelegate
[
	"sender must hold my sessionProtect"

	replicatorManager removeReplicatorForClientBehavior: clientBehavior
		andServerBehavior: behaviorDelegate
]

{ #category : 'private - replicators' }
GbsSession >> replicatorForServerBehavior: oopOrDelegate ifAbsentPut: replicatorCreationBlock
[
	"If there is not already a replicator for the given server behavior, evaluate the block and map it to that server behavior.
	Note that this does *not* map the replicator to a client class."

	^replicatorManager replicatorForServerBehavior: oopOrDelegate
		ifAbsentPut: replicatorCreationBlock
]

{ #category : 'private - replicators' }
GbsSession >> connectReplicator: aReplicator toServerBehavior: behaviorDelegate
[
	"For use only with one-way replicators that do not map a client behavior."
	"sender must hold my sessionProtect"

	replicatorManager connectReplicator: aReplicator
		toServerBehavior: behaviorDelegate
]

{ #category : 'private - replicators' }
GbsSession >> replicatorForServerBehavior: oopOrDelegate ifAbsent: alternativeBlock
[

	^replicatorManager replicatorForServerBehavior: oopOrDelegate
		ifAbsent: alternativeBlock
]

{ #category : 'initialize-release' }
GbsSession >> useDiagnosticSpecialConverter
[
	"The diagnostic special converter can only be used under specific conditions.
	 Otherwise, we'll just use the regular special converted."

	^GbsConfiguration current useDiagnosticSpecialConverter
		and: [GbsConfiguration is64BitClient
		and: [EndianDetector isBigEndian not]]
]

{ #category : 'initialize-release' }
GbsSession >> initializeSpecialConverter
[

	| class |
	class := GbsConfiguration is64BitClient
				ifTrue: [GbxSpecialConverter64]
				ifFalse: [GbxSpecialConverter].
	specialConverter := class new
]

{ #category : 'accessing' }
GbsSession class >> classWithStats
[
	"Answer the class to use to gather session statistics for sessions that are instances of me."

	^GbsSessionWithStats
]

{ #category : 'accessing' }
GbsSession class >> defaultDictionaryName
[

	| found |
	found := self gbxResolve: #GSDefaultClassDictionary.
	^found isNil
		ifTrue: [#UserClasses]
		ifFalse: [ found ]
]

{ #category : 'private - instance creation' }
GbsSession class >> loginLinked: linked withParameters: aGSSessionParameters
[
	"Private to GBS.
	Login with given parameters.  If linked is true, do a linked login, otherwise rpc."
	"On successful login, return a new instance of this class.  Otherwise, return nil."
	"Public protocol for logging in:
		GbsSessionParameters>>login
		GbsSessionParameters>>loginLnk
		GbsSessionParameters>>loginRpc
		GbsSessionParameters>>loginLinked:onPasswordExpirationWarning:"

	| sess loginResult |
	sess := self new.
	sess initializeWithParameters: aGSSessionParameters.
	loginResult := sess loginLinked: linked.
	"login is done with a copy to avoid changing parameters information after login.
	However, make sure if the remember password option is checked, this information
	is retained beyond the life of the session. We do want to retain that."
	sess parameters rememberPassword
		ifTrue: 
			[aGSSessionParameters
				rememberPassword: sess parameters rememberPassword;
				password: sess parameters password].
	^loginResult
]

{ #category : 'private - instance creation' }
GbsSession class >> loginWithX509Parameters: paramaters
[
	"Private to GBS.
	Login with given x509 parameters."
	"On successful login, return a new instance of this class.  Otherwise, return nil."

	| sess |
	sess := self new.
	sess initializeWithParameters: paramaters.
	^sess loginX509
]

{ #category : 'configuring GBS' }
GbsSession class >> generateGSClasses
[
	"Return a Boolean indicating whether GemStone class generation is enabled"

	GbsConfiguration 
		deprecated: 'GbsSession class>>generateGSClasses deprecated August, 2005. Use GbsConfiguration>>generateServerClasses instead'.
	^GbsConfiguration current generateServerClasses
]

{ #category : 'configuring GBS' }
GbsSession class >> generateGSClasses: aBool 
[
	"Enable or disable GemStone class generation"

	GbsConfiguration 
		deprecated: 'GbsSession class>>generateGSClasses: deprecated August, 2005. Use GbsConfiguration>>generateServerClasses: instead'.
	GbsConfiguration current generateServerClasses: aBool
]

{ #category : 'configuring GBS' }
GbsSession class >> assertionChecks
[
	GbsConfiguration 
		deprecated: 'GbsSession class>>assertionChecks deprecated August, 2005. Use GbsConfiguration>>assertionChecks instead'.
	^GbsConfiguration current assertionChecks
]

{ #category : 'configuring GBS' }
GbsSession class >> verbose
[
	"If aBool is true, GemBuilder will put a message on the system transcript when special events occur (logout/login/commit/abort)."

	"GBSM verbose"

	GbsConfiguration 
		deprecated: 'GbsSession class>>verbose deprecated August, 2005. Use GbsConfiguration>>verbose instead'.
	^GbsConfiguration current verbose
]

{ #category : 'configuring GBS' }
GbsSession class >> assertionChecks: aBoolean 
[
	GbsConfiguration 
		deprecated: 'GbsSession class>>assertionChecks: deprecated August, 2005. Use GbsConfiguration>>assertionChecks: instead'.
	GbsConfiguration current assertionChecks: aBoolean
]

{ #category : 'configuring GBS' }
GbsSession class >> generateSTClasses
[
	"Return a Boolean indicating whether Smalltalk class generation is enabled"

	GbsConfiguration 
		deprecated: 'GbsSession class>>generateSTClasses deprecated August, 2005. Use GbsConfiguration>>generateClientClasses instead'.
	^GbsConfiguration current generateClientClasses
]

{ #category : 'configuring GBS' }
GbsSession class >> generateSTClasses: aBool 
[
	"Enable or disable Smalltalk class generation"

	GbsConfiguration 
		deprecated: 'GbsSession class>>generateSTClasses: deprecated August, 2005. Use GbsConfiguration>>generateClientClasses: instead'.
	GbsConfiguration current generateClientClasses: aBool
]

{ #category : 'configuring GBS' }
GbsSession class >> verbose: aBool 
[
	"If aBool is true, GemBuilder will put a message on the system transcript when special events occur (logout/login/commit/abort)."

	"GBSM verbose: true"

	GbsConfiguration 
		deprecated: 'GbsSession class>>verbose: deprecated August, 2005. Use GbsConfiguration>>verbose: instead'.
	GbsConfiguration current verbose: aBool
]

{ #category : 'configuring GBS' }
GbsSession class >> removeInvalidConnectors
[
	GbsConfiguration 
		deprecated: 'GbsSession class>>removeInvalidConnectors deprecated August, 2005. Use GbsConfiguration>>removeInvalidConnectors instead'.
	^GbsConfiguration current removeInvalidConnectors
]

{ #category : 'configuring GBS' }
GbsSession class >> removeInvalidConnectors: aBool 
[
	"If true, connectors which fail to resolve at login time will automatically be removed from the connector collections.  If false, and if Verbose is true, the user is prompted for their removal.  Otherwise, connector failure raises a signal."

	GbsConfiguration 
		deprecated: 'GbsSession class>>removeInvalidConnectors: deprecated August, 2005. Use GbsConfiguration>>removeInvalidConnectors: instead'.
	GbsConfiguration current removeInvalidConnectors: aBool
]

{ #category : 'configuring GBS' }
GbsSession class >> eventPriority
[
	"Return the Smalltalk process priority level for GemStone-initiated events"

	GbsConfiguration 
		deprecated: 'GbsSession class>>eventPriority deprecated August, 2005. Use GbsConfiguration>>eventPriority instead'.
	^GbsConfiguration current eventPriority
]

{ #category : 'configuring GBS' }
GbsSession class >> generateClassConnectors
[
	GbsConfiguration 
		deprecated: 'GbsSession class>>generateClassConnectors deprecated August, 2005. Use GbsConfiguration>>generateClassConnectors instead'.
	^GbsConfiguration current generateClassConnectors
]

{ #category : 'configuring GBS' }
GbsSession class >> eventPriority: priority 
[
	"Set the Smalltalk process priority level for GemStone-initiated events.
	The default priority (Processor userSchedulingPriority) is the safest in that a GemStone event such as 'lost OT root' will not interrupt an application process that might be in the middle of accessing the GBS caches.  Such an interruption might corrupt the caches.  This priority level has the adverse side effect that an event will not be processed unless the application process is idle or does a Processor yield.
	Running the eventPriority at a higher level, such as (Processor userInterruptPriority), will ensure that GemStone events are processed when they are received by GemBuilder, at the risk of corrupting the current application process.  The 'lost OT root' event is very likely to modify the transparency caches, and events such as changed object notification, signaled abort, or gem-to-gem notification will execute whatever user-defined Smalltalk block has been supplied for that event."

	GbsConfiguration 
		deprecated: 'GbsSession class>>eventPriority: deprecated August, 2005. Use GbsConfiguration>>eventPriority: instead'.
	GbsConfiguration current eventPriority: priority
]

{ #category : 'configuring GBS' }
GbsSession class >> generateClassConnectors: aBool 
[
	"If aBool is set to true, then whenever a Smalltalk or GemStone class is generated, or a same-name class mapping is automatically established, a session-based connector will be created for the class mapping."

	"GBSM generateClassConnectors: true"

	GbsConfiguration 
		deprecated: 'GbsSession class>>generateClassConnectors: deprecated August, 2005. Use GbsConfiguration>>generateClassConnectors: instead'.
	GbsConfiguration current generateClassConnectors: aBool
]

{ #category : 'code maintenance' }
GbsSession class >> dependsOnStructureOfServerCall
[
	"Browse senders of this method to find places in the code that depend on the 
	internal structure of GbsSession>>serverCall:verifyArgs"
]
