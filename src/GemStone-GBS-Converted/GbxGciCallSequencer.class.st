Class {
	#name : 'GbxGciCallSequencer',
	#superclass : 'Object',
	#instVars : [
		'sessionId',
		'primInterface',
		'errorBuffer',
		'thisSession',
		'configuration'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxGciCallSequencer >> configuration: anObject
[
	configuration := anObject
]

{ #category : 'accessing' }
GbxGciCallSequencer >> configuration
[
	^configuration
]

{ #category : 'accessing' }
GbxGciCallSequencer >> primInterface
[
	"For now, still just the one primInterface. Later, different interfaces per session."

	primInterface == nil ifTrue: [primInterface := self class primInterface].
	^primInterface
]

{ #category : 'accessing' }
GbxGciCallSequencer >> session: aGbsSession 
[
	thisSession := aGbsSession
]

{ #category : 'call services' }
GbxGciCallSequencer >> gciCall: callBlock resultType: typeSymbol 
[
	"The most commonly-used call sequence. Must be used for all calls that
	have a non-blocking variant.
	typeSymbol must be one of the selectors in GbxPointer>results, currently
	#booleanResult
	#intResult
	#oopResult
	#voidResult"

	^self subclassResponsibility
]

{ #category : 'call services' }
GbxGciCallSequencer >> setSessionPerformCheck: aBlock
[
	"Do the operation in <aBlock> after setting the GBC session id so that the operation applies to
	 the correct session. Protect with a global semaphore, rather than the session-based semaphore,
	 because preemption of one gcisetsession/gcisomecall sequence with another
	 will cause the gci call to be executed against the wrong session.  One way
	 to eliminate this need is to rewrite the GCI layer such that all calls take a session id argument.

	Suitable for use only with calls that do not have a non-blocking variant"
	
	^GciCallProtect
		critical:
			[self primInterface gciSetSessionId: thisSession sessionId.
			self performCheck: aBlock]
]

{ #category : 'call services' }
GbxGciCallSequencer >> gciGemTrace: anInteger
[

	self primInterface gciGemTrace: anInteger
]

{ #category : 'call services' }
GbxGciCallSequencer >> loginCall: loginBlock 
[
	"Special call sequence for login, where we have no session ID before, but do after.
	Answer the session ID, which will be zero if we did not log in successfully."

	^self callProtectCritical: 
			[self setInvalidSessionID.
			loginBlock value.
			"If we got an error, we might still be successfully 
			logged in (for instance, if the error is a password expiration warning). 
			Getting the session ID will tell us for sure. We also don't have 
			any other way of knowing what session ID we got."
			sessionId := self primInterface gciGetSessionId.
			sessionId]
]

{ #category : 'private' }
GbxGciCallSequencer >> callProtectCritical: criticalBlock 
[
	"Used only for login"

	^GciCallProtect critical: criticalBlock
]

{ #category : 'private' }
GbxGciCallSequencer >> setInvalidSessionID
[
	"Set invalid GCI session id, then discard the resulting GCI error.
	Any sender of this message should be holding GciCallProtect.
	Only used during login, so it's OK (and necessary) to reset the
	session's cause of death.

	Sender must hold GciCallProtect"
	
	| result |
	result := self primInterface gciSetSessionId: 0.
	result gbxIsGSError
		ifFalse:
			["Clear the GCI error, but don't try to represent the error in GBS yet"
			self primInterface gciErr: self errorBuffer asAddress].
	thisSession causeOfDeath: nil
]

{ #category : 'private - sequencing' }
GbxGciCallSequencer >> performCheck: aBlock
[
	"Evaluate <aBlock> and check for a GBC error.  Return the result of the block 
	or if a GBC error occurred, a GbsError representing the error. This message 
	should only be sent inside a GciCallProtect critical section. Otherwise, 
	another thread could execute another GCI call between our block and our 
	checking for the error, destroying our ability to correlate errors with calls."
	
	| result |
	result := aBlock value.
	result gbxIsGSError
		ifFalse:
			[(self primInterface gciErr: self errorBuffer asAddress)
				ifTrue:
					[| sessOrMgr "A gci error occurred - return a GSError representation of it" "Increment error stats if we're collecting them" |
					sessOrMgr := thisSession == nil
						ifFalse: [thisSession]
						ifTrue: [GBSM].
					(sessOrMgr mainStatsEnabled and: [thisSession ~~ nil])
						ifTrue: [thisSession statResource gbxIncGciErrors].
					result := errorBuffer asGbsErrorForSession: thisSession]].
	^result
]

{ #category : 'support' }
GbxGciCallSequencer >> gciCriticalPerformCheck: aBlock 
[
	"Do the operation in <aBlock> protected from other threads 
	by the GciCallProtect mutual exclusion semaphore.
	This particular method also checks for GBC errors 
	resulting from the execution of <aBlock>.

	This is the message to send to perform Gci calls that are not 
	specific to a particular session, but can generate an error."

	^GciCallProtect critical: [self performCheck: aBlock]
]

{ #category : 'support' }
GbxGciCallSequencer >> socketAccessorOn: handle
[
	"Return a valid socket accessor for the current platform.
	 As of 3.2, it's always the ThreadSafe Socket Accessor."

	^GbxThreadSafeSocketAccessor openOn: handle sequencer: self.
]

{ #category : 'private - accessing' }
GbxGciCallSequencer >> errorBufferClass
[

	^GbxGciErrSType64v3
]

{ #category : 'private - accessing' }
GbxGciCallSequencer >> errorBuffer
[
	"Return a buffer that represents the GciErrSType structure."

	errorBuffer isNil ifTrue: [errorBuffer := self errorBufferClass allocate].
	^errorBuffer
]

{ #category : 'initialize-release' }
GbxGciCallSequencer >> shutdownSocket: aSocket withHandle: handle
[
	"Disable the socket accessor <aSocket> for the current platform. 
	Sender must hold my accessProtect semaphore.
	Must handle the case where the socket has already been shut down by the GCI,
	typically because of a fatal error."

	aSocket notNil ifTrue: [aSocket release]
]

{ #category : 'initialize-release' }
GbxGciCallSequencer >> gbsImageStartup
[
	"Discard defunct C pointers"

	errorBuffer := nil
]

{ #category : 'GbsSessionManager interface' }
GbxGciCallSequencer >> floatKind: aFloatOrDouble 
[
	^self gciCriticalPerformCheck: 
			[self primInterface gciFloatKind: aFloatOrDouble]
]

{ #category : 'GbsSession interface' }
GbxGciCallSequencer >> isRemote
[
	^self 
		gciCriticalPerformCheck: [self primInterface gciIsRemote]
]

{ #category : 'GbsSession interface' }
GbxGciCallSequencer >> getSignalHandle
[
	"Sender must hold my accessProtect semaphore."

	^self setSessionPerformCheck: [self primInterface gciGetSignalHandle]
]

{ #category : 'GbsSession interface' }
GbxGciCallSequencer >> stopNbWaitSocket
[
	"Don't have one, ignore"
]

{ #category : 'testing' }
GbxGciCallSequencer class >> isGciCallProtectHeld
[
	"Answer true if the active thread holds GciCallProtect"

	^GciCallProtect isActiveProcessInCriticalRegion
]

{ #category : 'GCI initialization' }
GbxGciCallSequencer class >> gciInit
[
	self primInterface gciInit
]

{ #category : 'GCI initialization' }
GbxGciCallSequencer class >> initializeGci
[
	"Make the gci initialization calls.  Should only be called by
	 initializeGciHandlingMultipleLibraryFilenames."

	self
		initAppName: 'gbs' logWarnings: true;
		setCacheName: 'GBS';
		gciInit.
	GbsConfiguration current fullCompression 
		ifTrue: [self enableFullCompression]
]

{ #category : 'GCI initialization' }
GbxGciCallSequencer class >> setCacheName: cacheName
[
	"GciSetCacheName"
	self primInterface
		gciSetCacheName: cacheName gbxAsCString
]

{ #category : 'GCI initialization' }
GbxGciCallSequencer class >> initAppName: appName logWarnings: logWarnings
[
	"GciInitAppName"
	self primInterface
		gciInitAppName: appName gbxAsCString
		logWarnings: logWarnings
]

{ #category : 'GCI initialization' }
GbxGciCallSequencer class >> enableFullCompression
[
	"GciEnableFullCompression"
	self primInterface
		gciEnableFullCompression
]

{ #category : 'private - accessing' }
GbxGciCallSequencer class >> gciCallProtect
[
	"very private"

	^GciCallProtect
]

{ #category : 'initialize-release' }
GbxGciCallSequencer class >> initializeGemCursor
[

	"Initialize the gem cursor."

	(SpecialGemStoneObjects at: #GScursor ifAbsent: [ nil ]) isNil ifTrue: [
		SpecialGemStoneObjects at: #GScursor put: (Cursor
			imageArray: #(
			    2r0000000000000000
			    2r0000000000000000
			    2r0000000000000000
			    2r0000000000000000
			    2r0000111111111000
			    2r0001011011011100
			    2r0010100100100110
			    2r0111111111111111
			    2r0010001000100010
			    2r0001000101000100
			    2r0000110010011000
			    2r0000010101010000
			    2r0000001000100000
			    2r0000000101000000
			    2r0000000010000000
			    2r0000000000000000)
			maskArray: #(
			    2r0000000000000000
			    2r0000000000000000
			    2r0000000000000000
			    2r0000111111111000
			    2r0001111111111100
			    2r0011111111111110
			    2r0111101101101111
			    2r1111111111111111
			    2r0111011101110111
			    2r0011101111101110
			    2r0001110111011100
			    2r0000111111111000
			    2r0000011101110000
			    2r0000001111100000
			    2r0000000111000000
			    2r0000000010000000)
			hotSpot:  9@15
			name: '') ]
]

{ #category : 'initialize-release' }
GbxGciCallSequencer class >> nilPrimInterface
[

	PrimInterface := nil
]

{ #category : 'initialize-release' }
GbxGciCallSequencer class >> initialize
[
	"GbxGciCallSequencer initialize"

	GciCallProtect := GbxSemaphore forMutualExclusion.
	self nilPrimInterface
]

{ #category : 'initialize-release' }
GbxGciCallSequencer class >> gciCallProtectStatAdaptor: aStatAdaptorOrNil 
[
	"If aStatResourceOrNil is nil, use a regular semaphore for GciCallProtect.  Otherwise,
	 use a stat-enabled semaphore."

	"Note that whether stats are being enabled or disabled, there is only a single 
	 underlying semaphore (so it's not necessary to do this swap under semaphore
	 protection).  To enable stats, that semaphore is wrapped in a GbxSemaphoreWithStats.
	 To disable, the wrapper is discarded, and a direct reference to the old semaphore is restored."

	GciCallProtect := GciCallProtect statAdaptor: aStatAdaptorOrNil
]

{ #category : 'initialize-release' }
GbxGciCallSequencer class >> postLoad: aParcel 
[
	"During parcel load, by default #initialize will be sent. We can't do that here,
	because some of the code needed to run #initialize is in other parcels. Wait until
	the post-load action for the parcel to initialize."

	"Do nothing."
]

{ #category : 'primInterface' }
GbxGciCallSequencer class >> isPrimInterfaceInitialized
[
	^PrimInterface ~~ nil
]

{ #category : 'primInterface' }
GbxGciCallSequencer class >> primInterface
[
	"Return the instance of the C primitive interface.

	Removed the double initialization of the library for hpux. We can extract from store if need be."

	PrimInterface isNil ifTrue: [self initializePrimInterface].
	^PrimInterface
]

{ #category : 'primInterface' }
GbxGciCallSequencer class >> raiseNotLoaded
[

	GemStone.Gbs.GbsInterfaceError
		raiseErrorString: 'GBS C Interface not loaded'.
	^nil
]

{ #category : 'primInterface' }
GbxGciCallSequencer class >> initializePrimInterface
[
	"GbxCLibrarySelectionInterface determines which subclass of ExternalInterface should be instantiated for the gemstone shared library"

	| selectionLibrary |
	PrimInterface := nil.
	
	[| libraryName |
	libraryName := GbsConfiguration sharedLibraryFilename.
	selectionLibrary := GbxCLibrarySelectionInterface
				tryToLoadLibraryNamed: libraryName.
	selectionLibrary isNil
		and: [GbsConfiguration doesUserWantToRetryAfterFailingToLoad: libraryName]]
			whileTrue: 
				[GbsConfiguration current
					libraryName: GbsConfiguration promptForNewLibraryName].
	selectionLibrary isNil
		ifTrue: [self raiseNotLoaded]
		ifFalse: 
			[| concreteClass |
			concreteClass := selectionLibrary gemstoneLibraryClass.
			PrimInterface := concreteClass
						newInterface: concreteClass sharedLibraryFilename.
			self initializeGci.
			GbsError selectErrorMap].
	self initializeGemCursor
]

{ #category : 'simple GCI calls' }
GbxGciCallSequencer class >> gciProduct
[
	^[self primInterface gciProduct]
		on: GbsError hostErrorSignal
		do: [:ex | ex returnWith: 0	"The code for 'unknown product'"]
]

{ #category : 'simple GCI calls' }
GbxGciCallSequencer class >> gciVersion
[
	^self primInterface gciVersion
]

{ #category : 'simple GCI calls' }
GbxGciCallSequencer class >> noLoadGciVersion
[
	"Don't load the library if it's not loaded, just answer nil"

	^PrimInterface == nil
		ifTrue: [nil]
		ifFalse: [self gciVersion]
]

{ #category : 'simple GCI calls' }
GbxGciCallSequencer class >> noLoadGciProduct
[
	"Don't load the library if it's not loaded, just answer the code for unknown product"

	^PrimInterface == nil
		ifTrue: [0]
		ifFalse: [self gciProduct]
]

{ #category : 'instance creation' }
GbxGciCallSequencer class >> forSession: sess configuration: config
[

	| concreteClass inst |
	concreteClass := config blockingProtocolRpc
				ifTrue: [GbxBlockingGciCallSequencer]
				ifFalse: [GbxNonBlockingGciCallSequencer].
	inst := concreteClass new initialize.
	inst
		session: sess;
		configuration: config.
	^inst
]

