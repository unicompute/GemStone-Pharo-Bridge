Class {
	#name : 'GbsSessionManager',
	#superclass : 'Object',
	#instVars : [
		'clientMap',
		'currentSession',
		'dependents',
		'disconnectedSessions',
		'globalConnectors',
		'isInitialized',
		'isRemote',
		'kernelConnectorConditions',
		'loginProtect',
		'memoryPolicy',
		'numSessionsInInteraction',
		'numSessionsInInteractionProtect',
		'parameters',
		'serverInterface',
		'sessionListProtect',
		'sessions',
		'stats'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'configuring gembuilder' }
GbsSessionManager >> faultLevelRpc
[
	"The default number of levels to fault an object in rpc sessions"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>faultLevelRpc. Deprecated August, 2005. Use GbsConfiguration>>faultLevelRpc instead'.
	^GbsConfiguration current faultLevelRpc
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> blockReplicationEnabled
[
	"Block replication is enabled by default.  If this parameter is set to false, GemBuilder
	 will raise an exception when block replication is attempted.  Setting this to false may
	 be useful in determining if your application is dependent on block replication."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>blockReplicationEnabled. Deprecated August, 2005. Use GbsConfiguration>>blockReplicationEnabled instead'.
	^GbsConfiguration current blockReplicationEnabled
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> connectorNilling: aBoolean 
[
	"If set to true, then GBS will nil the Smalltalk object for all session-based
	connectors after logout that are either name, class var, or class inst var
	connectors and have a post connect action of #updateST or #forwarder.
	This is done to reduce defunct stub errors.  If the last session logs out,
	the Smalltalk object for global connectors is nilled out also.
	Default value is true."

	" GBSM connectorNilling: true "

	" GBSM connectorNilling: false "

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>connectorNilling:. Deprecated August, 2005. Use GbsConfiguration>>connectorNilling: instead'.
	GbsConfiguration current connectorNilling: aBoolean
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> verbose: aBool 
[
	"If aBool is true, GemBuilder will put a message on the system transcript when special events occur (logout/login/commit/abort)."

	"GBSM verbose: true"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>verbose: deprecated August, 2005. Use GbsConfiguration>>verbose: instead'.
	GbsConfiguration current verbose: aBool
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> forwarderDebugging: aBool 
[
	"Turn debugging support on or off.  When debugging is on (aBool = true), some
	 messages to forwarders, e.g., printOn:, instVarAt:, and class (returns
	 GbsForwarder), will be handled by the forwarders themselves. When it's
	 off (aBool = false), these messages are forwarded to the GemStone object."

	"	 GBSM forwarderDebugging: true  	"

	"	 GBSM forwarderDebugging: false 	"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>forwarderDebugging: deprecated August, 2005. Use GbsConfiguration>>forwarderDebugging: instead'.
	GbsConfiguration current forwarderDebugging: aBool
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> blockReplicationPolicy: aSymbol 
[
	"The blockReplicationPolicy parameter can be set to #replicate or #callback.  Block
	 replication requires decompiling and compiling the source code for blocks at run
	 time.  Block callbacks will use client forwarders to evaluate the block in the client."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>blockReplicationPolicy:. Deprecated August, 2005. Use GbsConfiguration>>blockReplicationPolicy: instead'.
	GbsConfiguration current blockReplicationPolicy: aSymbol
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> generateSTClasses: aBool 
[
	"Enable or disable Smalltalk class generation"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>generateSTClasses: deprecated August, 2005. Use GbsConfiguration>>generateClientClasses: instead'.
	GbsConfiguration current generateClientClasses: aBool
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> eventPriority
[
	"Return the Smalltalk process priority level for GemStone-initiated events"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>eventPriority. Deprecated August, 2005. Use GbsConfiguration>>eventPriority instead'.
	^GbsConfiguration current eventPriority
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> fullCompression
[
	GbsConfiguration 
		deprecated: 'GbsSessionManager>>fullCompression Deprecated August, 2005. Use GbsConfiguration>>fullCompression instead'.
	^GbsConfiguration current fullCompression
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> bulkLoad
[
	"Returns true if the GBSM is in bulk load mode"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>bulkLoad. Deprecated August, 2005. Use GbsConfiguration>>bulkLoad instead'.
	^GbsConfiguration current bulkLoad
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> removeInvalidConnectors
[
	GbsConfiguration 
		deprecated: 'GbsSessionManager>>removeInvalidConnectors Deprecated August, 2005. Use GbsConfiguration>>removeInvalidConnectors instead'.
	^GbsConfiguration current removeInvalidConnectors
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> faultLevelLnk: anInteger 
[
	"The default number of levels to fault an object in linked sessions"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>faultLevelLnk:. Deprecated August, 2005. Use GbsConfiguration>>faultLevelLnk: instead'.
	GbsConfiguration current faultLevelLnk: anInteger
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> assertionChecks
[
	GbsConfiguration 
		deprecated: 'GbsSessionManager>>assertionChecks. Deprecated August, 2005. Use GbsConfiguration>>assertionChecks instead'.
	^GbsConfiguration current assertionChecks
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> generateClassConnectors: aBool 
[
	"If aBool is set to true, then whenever a Smalltalk or GemStone class is generated, or a same-name class mapping is automatically established, a session-based connector will be created for the class mapping."

	"GBSM generateClassConnectors: true"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>generateClassConnectors: deprecated August, 2005. Use GbsConfiguration>>generateClassConnectors: instead'.
	GbsConfiguration current generateClassConnectors: aBool
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> stubDebugging: aBool 
[
	"Turn debugging support on or off.  When debugging is on,  instance methods will allow the Smalltalk debugger to operate among stubs without causing them to fault in the GemStone object."

	"	GBSM stubDebugging: true	"

	"	GBSM stubDebugging: false	"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>stubDebugging: deprecated August, 2005. Use GbsConfiguration>>stubDebugging: instead'.
	GbsConfiguration current stubDebugging: aBool
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> forwarderDebugging
[
	"Answer whether forwarder debugging support is on or off.  When debugging is on
	 (ForwarderDebugging = true), some messages to forwarders, e.g., printOn:,
	 instVarAt:, and class (returns GbsForwarder), will be handled by the forwarders
	 themselves.  When it is off (ForwarderDebugging = false), these messages are
	 forwarded to the GemStone object."

	"	 GBSM forwarderDebugging 	"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>forwarderDebugging. Deprecated August, 2005. Use GbsConfiguration>>forwarderDebugging instead'.
	^GbsConfiguration current forwarderDebugging
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> generateSTClasses
[
	"Return a Boolean indicating whether Smalltalk class generation is enabled"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>generateSTClasses Deprecated August, 2005. Use GbsConfiguration>>generateClientClasses instead'.
	^GbsConfiguration current generateClientClasses
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> connectorNilling
[
	"If set to true, then GBS will nil the Smalltalk object for all session-based
	connectors after logout that are either name, class var, or class inst var
	connectors and have a post connect action of #updateST or #forwarder.
	This is done to reduce defunct stub errors.  If the last session logs out,
	the Smalltalk object for global connectors is nilled out also.
	Default value is true."

	" GBSM connectorNilling "

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>connectorNilling. Deprecated August, 2005. Use GbsConfiguration>>connectorNilling instead'.
	^GbsConfiguration current connectorNilling
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> verbose
[
	"If aBool is true, GemBuilder will put a message on the system transcript when special events occur (logout/login/commit/abort)."

	"GBSM verbose"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>> verbose Deprecated August, 2005. Use GbsConfiguration>>verbose instead'.
	^GbsConfiguration current verbose
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> blockReplicationPolicy
[
	"The blockReplicationPolicy parameter can be set to #replicate or #callback.  Block
	 replication requires decompiling and compiling the source code for blocks at run
	 time.  Block callbacks will use client forwarders to evaluate the block in the client."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>blockReplicationPolicy. Deprecated August, 2005. Use GbsConfiguration>>blockReplicationPolicy instead'.
	^GbsConfiguration current blockReplicationPolicy
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> initialDirtyPoolSize: anInteger 
[
	"Pregrow size of GbsSession dirtyPool identity set.  Default is GBSM initialCacheSize // 40.
	 For bulk load situations, making this value larger will reduce the number of times this
	 set needs to grow.  For applications that perform flushes of a small number of objects,
	 making this value smaller (but larger than the number of objects being flushed) will
	 improve flushing performance."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>initialDirtyPoolSize: deprecated August, 2005. Use GbsConfiguration>>initialDirtyPoolSize: instead'.
	GbsConfiguration current initialDirtyPoolSize: anInteger
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> defaultFaultPolicy: faultPolicy 
[
	"An object's faultPolicy is either #lazy or #immediate.  If #lazy, when changes to the GemStone
	 counterpart of a client object are discovered, the client object is turned into a stub and will
	 fault back into the client the first time the stub is sent a message.  If an object's faultPolicy
	 is #immediate, the client object will be updated as soon as a change in the GemStone object
	 is discovered.  The defaultFaultPolicy is what is returned by the default implementation of
	 Object>>faultPolicy (which can be reimplemented in subclasses)."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>defaultFaultPolicy:. Deprecated August, 2005. Use GbsConfiguration>>defaultFaultPolicy: instead'.
	GbsConfiguration current defaultFaultPolicy: faultPolicy
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> freeSlotsOnStubbing: aBoolean 
[
	"Turn persistent slot freeing mode on or off.  When it is on, stubbing an existing replicate will cause all persistent instvars (i.e. those that will be faulted in when the stub is unstubbed) to be set to nil, allowing stubs and old replicates and such to be garbage collected if they become eligible."

	"GbsSessionManager freeSlotsOnStubbing: true"

	"GbsSessionManager freeSlotsOnStubbing: false"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>freeSlotsOnStubbing: deprecated August, 2005. Use GbsConfiguration>>freeSlotsOnStubbing: instead'.
	GbsConfiguration current freeSlotsOnStubbing: aBoolean
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> blockingProtocolRpc: aBoolean 
[
	"A value of false (the default) specifies that rpc sessions will use non-blocking protocol to communicate with GemStone."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>blockingProtocolRpc:. Deprecated August, 2005. Use GbsConfiguration>>blockingProtocolRpc: instead'.
	GbsConfiguration current blockingProtocolRpc: aBoolean
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> faultLevelLnk
[
	"The default number of levels to fault an object in linked sessions"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>faultLevelLnk. Deprecated August, 2005. Use GbsConfiguration>>faultLevelLnk instead'.
	^GbsConfiguration current faultLevelLnk
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> generateClassConnectors
[
	"If true, then whenever a Smalltalk or GemStone class is generated, or a same-name class mapping is automatically established, a session-based connector will be created for the class mapping."

	"GBSM generateClassConnectors"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>generateClassConnectors deprecated August, 2005. Use GbsConfiguration>>generateClassConnectors instead'.
	^GbsConfiguration current generateClassConnectors
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> confirm
[
	"If set to true, then GBS will prompt for confirmation."

	" GBSM confirm "

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>confirm. Deprecated August, 2005. Use GbsConfiguration>>confirm instead'.
	^GbsConfiguration current confirm
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> stubDebugging
[
	"When this value is true, stubs respond to some basic messages locally - such as printOn:, instVarAt:,
	 and class (returns GbxObjectStub) to support debugging.  When it's false, these messages cause
	 the stub to fault into the client image from GemStone."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>stubDebugging Deprecated August, 2005. Use GbsConfiguration>>stubDebugging instead'.
	^GbsConfiguration current stubDebugging
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> faultLevelRpc: anInteger 
[
	"The default number of levels to fault an object in rpc sessions"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>faultLevelRpc:. Deprecated August, 2005. Use GbsConfiguration>>faultLevelRpc: instead'.
	GbsConfiguration current faultLevelRpc: anInteger
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> generateGSClasses: aBool 
[
	"Enable or disable GemStone class generation"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>generateGSClasses: deprecated August, 2005. Use GbsConfiguration>>generateServerClasses: instead'.
	GbsConfiguration current generateServerClasses: aBool
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> defaultFaultPolicy
[
	"An object's faultPolicy is either #lazy or #immediate.  If #lazy, when changes to the GemStone
	 counterpart of a client object are discovered, the client object is turned into a stub and will
	 fault back into the client the first time the stub is sent a message.  If an object's faultPolicy
	 is #immediate, the client object will be updated as soon as a change in the GemStone object
	 is discovered.  The defaultFaultPolicy is what is returned by the default implementation of
	 Object>>faultPolicy (which can be reimplemented in subclasses)."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>defaultFaultPolicy. Deprecated August, 2005. Use GbsConfiguration>>defaultFaultPolicy instead'.
	^GbsConfiguration current defaultFaultPolicy
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> traversalBufferSize: anInteger 
[
	"GBSM traversalBufferSize: 50000"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>traversalBufferSize: deprecated August, 2005. Use GbsConfiguration>>traversalBufferSize: instead'.
	GbsConfiguration current traversalBufferSize: anInteger
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> freeSlotsOnStubbing
[
	"Returns true if the GBSM is in freeSlotsOnStubbing mode"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>freeSlotsOnStubbing deprecated August, 2005. Use GbsConfiguration>>freeSlotsOnStubbing instead'.
	^GbsConfiguration current freeSlotsOnStubbing
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> connectVerification
[
	"If true, connectors will verify that they are not redefining an object connection, and class connectors will verify that the class structures match."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>connectVerification. Deprecated August, 2005. Use GbsConfiguration>>connectVerification instead'.
	^GbsConfiguration current connectVerification
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> blockReplicationEnabled: aBoolean 
[
	"Block replication is enabled by default.  If this parameter is set to false, GemBuilder
	 will raise an exception when block replication is attempted.  Setting this to false may
	 be useful in determining if your application is dependent on block replication."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>blockReplicationEnabled:. Deprecated August, 2005. Use GbsConfiguration>>blockReplicationEnabled: instead'.
	GbsConfiguration current blockReplicationEnabled: aBoolean
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> eventPriority: priority 
[
	"Set the Smalltalk process priority level for GemStone-initiated events."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>eventPriority:. Deprecated August, 2005. Use GbsConfiguration>>eventPriority: instead'.
	GbsConfiguration current eventPriority: priority
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> initialDirtyPoolSize
[
	"Pregrow size of GbsSession dirtyPool identity set.  Default is GBSM initialCacheSize // 40.
	 For bulk load situations, making this value larger will reduce the number of times this
	 set needs to grow.  For applications that perform flushes of a small number of objects,
	 making this value smaller (but larger than the number of objects being flushed) will
	 improve flushing performance."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>initialDirtyPoolSize Deprecated August, 2005. Use GbsConfiguration>>initialDirtyPoolSize instead'.
	^GbsConfiguration current initialDirtyPoolSize
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> fullCompression: aBoolean 
[
	GbsConfiguration 
		deprecated: 'GbsSessionManager>>fullCompression: deprecated August, 2005. Use GbsConfiguration>>fullCompression: instead'.
	GbsConfiguration current fullCompression: aBoolean
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> blockingProtocolRpc
[
	"A value of false (the default) specifies that rpc sessions will use non-blocking protocol to communicate with GemStone."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>blockingProtocolRpc. Deprecated August, 2005. Use GbsConfiguration>>blockingProtocolRpc instead'.
	^GbsConfiguration current blockingProtocolRpc
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> removeInvalidConnectors: aBool 
[
	"If true, connectors which fail to resolve at login time will automatically be removed from the connector collections.  If false, and if Verbose is true, the user is prompted for their removal.  Otherwise, connector failure raises a signal."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>removeInvalidConnectors: deprecated August, 2005. Use GbsConfiguration>>removeInvalidConnectors: instead'.
	GbsConfiguration current removeInvalidConnectors: aBool
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> connectVerification: aBool 
[
	"If aBool is set to true, connectors will verify that they are not redefining an object connection, and class connectors will verify that the class structures match."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>connectVerification:. Deprecated August, 2005. Use GbsConfiguration>>connectVerification: instead'.
	GbsConfiguration current connectVerification: aBool
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> assertionChecks: aBoolean 
[
	GbsConfiguration 
		deprecated: 'GbsSessionManager>>assertionChecks:. Deprecated August, 2005. Use GbsConfiguration>>assertionChecks: instead'.
	GbsConfiguration current assertionChecks: aBoolean
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> generateGSClasses
[
	"Return a Boolean indicating whether GemStone class generation is enabled"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>generateGSClasses deprecated August, 2005. Use GbsConfiguration>>generateServerClasses instead'.
	^GbsConfiguration current generateServerClasses
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> confirm: aBoolean 
[
	"If <aBoolean> is true, then GBS will prompt for confirmation."

	" GBSM confirm "

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>confirm:. Deprecated August, 2005. Use GbsConfiguration>>confirm: instead'.
	GbsConfiguration current confirm: aBoolean
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> bulkLoad: aBoolean 
[
	"Setting bulk load to true means that in fetchAndStore mode, new objects flushed to GemStone will be created as permanent objects,  thus providing a performance gain by bypassing GemStone's garbage collector."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>bulkLoad:. Deprecated August, 2005. Use GbsConfiguration>>bulkLoad: instead'.
	GbsConfiguration current bulkLoad: aBoolean
]

{ #category : 'configuring gembuilder' }
GbsSessionManager >> traversalBufferSize
[
	"GBSM traversalBufferSize"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>traversalBufferSize Deprecated August, 2005. Use GbsConfiguration>>traversalBufferSize instead'.
	^GbsConfiguration current traversalBufferSize
]

{ #category : 'message forwarding' }
GbsSessionManager >> doesNotUnderstand: aMessage
[
	"If I don't understand a message, maybe the current session will.  Use 'self currentSession' rather than direct instvar access, because that method contains code to handle the case of an invalid current session."

	^currentSession
		ifNil: [super doesNotUnderstand: aMessage]
		ifNotNil: [:sess | sess perform: aMessage selector withArguments: aMessage arguments]
]

{ #category : 'message forwarding' }
GbsSessionManager >> at: aSymbol ifAbsent: aBlock
[

	"Resolves aSymbol within the current session's GemStone symbol list, and returns the Smalltalk replicate for that GemStone object.  The GemStone/Smalltalk object relationship will be registered with the GBS transparency mechanism."

	^self currentSession at: aSymbol ifAbsent: aBlock
]

{ #category : 'message forwarding' }
GbsSessionManager >> compilerLanguage: aString
[

	"Forward the compilerLanguage: message to the current session, if there is one.  Otherwise, assume ASCII."
	"GBSM compilerLanguage: #'JIS-EUC'"
	"GBSM compilerLanguage: #ASCII"

	self isLoggedIn
		ifTrue: [ ^currentSession compilerLanguage: aString ]
		ifFalse: [ ^#ASCII ]
]

{ #category : 'message forwarding' }
GbsSessionManager >> at: aSymbol put: stObject inDictionaryNamed: dictName
[

	"Stores the GemStone replicate of stObject in the current session's GemStone symbol dictionary named dictName.  The GemStone/Smalltalk object relationship will be registered with the GBS transparency mechanism (if it isn't already registered)."

	^self currentSession at: aSymbol put: stObject inDictionaryNamed: dictName
]

{ #category : 'message forwarding' }
GbsSessionManager >> at: aSymbol
[

	"Resolves aSymbol within the current session's GemStone symbol list, and returns the Smalltalk replicate for that GemStone object.  The GemStone/Smalltalk object relationship will be registered with the GBS transparency mechanism."

	^self currentSession at: aSymbol
]

{ #category : 'message forwarding' }
GbsSessionManager >> at: aSymbol put: stObject
[

	"Stores the GemStone replicate of stObject in the current session's GemStone 'UserGlobals' dictionary.  The GemStone/Smalltalk object relationship will be registered with the GBS transparency mechanism (if it isn't already registered)."

	^self currentSession at: aSymbol put: stObject inDictionaryNamed: #UserGlobals
]

{ #category : 'GBS private' }
GbsSessionManager >> hasSessionsInInteractions
[
	"Answer true if any session is in replication.
	In a multi-threaded environment this answer is 
	not guaranteed to be accurate by the time it's actually used,
	and in fact we decrement sessionsInReplication slightly before
	the interaction is actually released, but this is a case where
	an answer that is correct most of the time is good enough,
	since it's used as a hint to my MemoryPolicy."

	^numSessionsInInteraction > 0
]

{ #category : 'GBS private' }
GbsSessionManager >> memoryPolicy
[

	^memoryPolicy
]

{ #category : 'GBS private' }
GbsSessionManager >> sessionEnteringInteractions
[

	numSessionsInInteractionProtect critical: [numSessionsInInteraction := numSessionsInInteraction + 1]
]

{ #category : 'GBS private' }
GbsSessionManager >> atNewClient: clientObject putDelegate: delegate 
[
	"Sender must hold the client map's accessProtect."

	clientMap atNewClient: clientObject putDelegate: delegate
]

{ #category : 'GBS private' }
GbsSessionManager >> checkMemoryPolicy
[

	| currentPolicy currentIsGbs useGbsMemoryPolicy |
	useGbsMemoryPolicy := GbsConfiguration current useGbsMemoryPolicy.
	currentPolicy := ObjectMemory currentMemoryPolicy.
	currentIsGbs := currentPolicy respondsTo: #postReplicationAction.
	currentIsGbs == useGbsMemoryPolicy
		ifFalse: 
			[useGbsMemoryPolicy
				ifTrue: 
					["turn on"
					GbsMemoryPolicy install]
				ifFalse: 
					["turn off"
					|  newPolicy |
					newPolicy  := LargeGrainMemoryPolicy new.
					ObjectMemory installMemoryPolicy: newPolicy]]
]

{ #category : 'GBS private' }
GbsSessionManager >> moveParameters: movee from: from to: to
[
	"Private to GBS. Move the given movee parameters from its current position in the parameters collection to 0-based newIndex. 
	Index of 0 will make it the first, any other number will put it after the numbered element, "

	| newParameters |
	(parameters includes: movee)
		ifFalse: 
			[self gbsMessenger error: 'Attempt to move unknown session parameters.'].
	newParameters := parameters copy.
	newParameters add: movee beforeIndex: to + 1.
	newParameters
		removeAtIndex: (from > to ifTrue: [from + 1] ifFalse: [from]).
	parameters := newParameters.
	self changedParameters: (parameters
				at: (from > to ifTrue: [to + 1] ifFalse: [to]))
]

{ #category : 'GBS private' }
GbsSessionManager >> changedSelector: aSelector inClass: aClass
[
	"A metaclass has had a method added, removed, or changed.
	Logged-in sessions may need to update their clamps
	if the method is an instVarMap or a replication spec method."

	(aClass == Object class and: [(aClass includesSelector: aSelector) not])
		ifTrue: [self invalidateSchemesWithSelector: aSelector]
		ifFalse: [self notifySessionsOfChangedSelector: aSelector inClass: aClass]
]

{ #category : 'GBS private' }
GbsSessionManager >> memoryPolicy: aGbsMemoryPolicy
[

	memoryPolicy := aGbsMemoryPolicy
]

{ #category : 'GBS private' }
GbsSessionManager >> loginCriticalAssertionChecks
[
	
	[loginProtect isActiveProcessInCriticalRegion not and: 
			["Check all sessions. This is not totally thread-safe (a session might log in 
			while we're checking), but that's acceptable for this assertion check."

			self sessions 
				contains: [:sess | sess sessionProtect isActiveProcessInCriticalRegion]]] 
			gbxAssertEquals: false
			message: 'Semaphores were acquired out of sequence. Deadlocks could occur if login semaphore is obtained after session semaphore.'
]

{ #category : 'GBS private' }
GbsSessionManager >> sessionListCritical: aBlock 
[
	"Private to GBS."

	^sessionListProtect critical: aBlock
]

{ #category : 'GBS private' }
GbsSessionManager >> loginCritical: aBlock 
[
	"Private to GBS."

	self loginCriticalAssertionChecks.
	^loginProtect critical: aBlock
]

{ #category : 'GBS private' }
GbsSessionManager >> sessionExitingInteractions
[

	numSessionsInInteractionProtect
		critical: [numSessionsInInteraction := numSessionsInInteraction - 1].
	"This may run a fullReclamation even when some session(s) still have strong serverMap(s).
	This is intentional: One session has just made its serverMap weak, so we should at least collect from that one."
	memoryPolicy postReplicationAction
]

{ #category : 'transactions - obsolete' }
GbsSessionManager >> commit
[
	"Select a session to commit"

	"This method is obsolete, and will be removed in a future release.
	 Instead, send commitTransaction directly to a GbsSession, or
	 send GBSM commitTransactionDialog"

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>commit deprecated March, 2006. Send commitTransaction directly to a GbsSession, or send GBSM commitTransactionDialog'.
	^self selectLoggedInSessionSending: #commitTransaction
		label: 'Commit session:'
]

{ #category : 'transactions - obsolete' }
GbsSessionManager >> beginTransaction
[
	"Select a session to beginTransaction"

	"This method is obsolete, and will be removed in a future release.
	 Instead, send beginTransaction directly to a GbsSession, or
	 send GBSM beginTransactionDialog"

	GbsConfiguration 
		deprecated: 'GbsConfiguration>>beginTransaction deprecated March, 2007. Use GbsSession>>beginTransaction instead'.
	^self selectLoggedInSessionSending: #beginTransaction
		label: 'Begin transaction in session:'
]

{ #category : 'transactions - obsolete' }
GbsSessionManager >> abort
[

	"Select a session to abort"
	"This method is obsolete, and will be removed in a future release.
	 Instead, send abortTransaction directly to a GbsSession, or
	 send GBSM abortTransactionDialog"


	^self selectLoggedInSessionSending: #abortTransaction label: 'Abort session:'
]

{ #category : 'private - updating' }
GbsSessionManager >> aboutToQuit
[

	| confirm |
	serverInterface isNil ifTrue: [^self].
	confirm := GbsConfiguration current confirm.
	self loggedInSessions do: 
			[:anActiveSession |
			confirm
				ifTrue: 
					[(anActiveSession needsCommit and: 
							[anActiveSession inTransaction
								and: [self gbsMessenger confirm: 'Commit %1?' with: anActiveSession]])
						ifTrue: [anActiveSession commitTransaction]].
			anActiveSession logout]
]

{ #category : 'printing' }
GbsSessionManager >> sessionSummaryOn: aStream
[

	aStream
		print: self sessions size;
		nextPutAll: ' logged in sessions';
		cr.
	self sessions doWithIndex: 
			[:eachSession :index |
			aStream
				print: index;
				nextPutAll: '. '.
			eachSession
				sessionSummaryOn: aStream.
			aStream cr].
	aStream nextPutAll: 'GCI Call Protect: '.
	(GbxGciCallSequencer gciCallProtect)
		semaphoreSummaryOn: aStream.
	aStream cr.
	aStream nextPutAll: 'Client Map Write Protect: '.
	(GBSM clientMap writeProtect)
		semaphoreSummaryOn: aStream.
	aStream cr.
]

{ #category : 'private - initialization' }
GbsSessionManager >> initializeServerInterfaceIfNeeded
[
	"lazy initialize the server interface for login related questions to the library.
	In short, the serverInterface of GbsSessionManager controls how we want
	 to answer questions about the availability of linked logins. If the serverInterface
	is nil, we answer truthfully that we don't know because the client library isn't 
	loaded.	If the serverInterface has been initialized, we want to load the library, then 
	ask about linked logins.

	Because this method is being sent, presumably we want to load the client
	library, then ask about linked login availability"
	
	self serverInterface
]

{ #category : 'private - initialization' }
GbsSessionManager >> initialize
[
	"Private.  This should not be called at every Smalltalk startup, as it causes known sessions to be lost."

	| obsolete dClassnm |
	isInitialized := false. 
	stats := GbxSessionManagerStatResource new.
	parameters isNil ifTrue: [parameters := OrderedCollection new].
	sessions isNil ifTrue: [sessions := OrderedCollection new: 16].
	sessionListProtect := GbxRecursionLock forMutualExclusion.
	loginProtect := GbxRecursionLock forMutualExclusion.
	numSessionsInInteractionProtect := GbxRecursionLock forMutualExclusion.
	memoryPolicy := GbsMemoryPolicy new.
	self initializeDisconnectedSessions.
	GbsConfiguration isVisualWorksImage
		ifTrue: 
			["Only do this in a ParcPlace Smalltalk image"
			"Clean up any obsolete instances of this class in Smalltalk and ObjectMemory dependents"
			obsolete := (self gbxResolve: #ObjectMemory in: #Kernel) dependents select: 
							[:d |
							"| dClassnm |"
							dClassnm := d class name.
							dClassnm = self class name or: [dClassnm = ('AnObsolete' , self class name)]].
			obsolete do: [:o | (self gbxResolve: #ObjectMemory in: #Kernel) removeDependent: o].
			"Add current instance"
			(self gbxResolve: #ObjectMemory in: #Kernel) addDependent: self].
	GbsConfiguration isVisualAgeImage
		ifTrue: 
			["Hook the 'method changed' callback mechanism to flush the gs offset cache"
			self hookMethodChangedCallback].
	self initializeKernelConnectors.
	self gbsImageStartup.
	isInitialized := true.
	^self
]

{ #category : 'private - initialization' }
GbsSessionManager >> gbsImageStartup
[
	"Private.  This initialization method is called at image startup time"
	"GBSM gbsImageStartup"
	"Throw away any previously snapshotted C bindings"

	| deadSessions |
	self initializeC.	" A lot of funny stuff needed for VA 4.0. "
	numSessionsInInteraction := 0.
	GbxServerVersion initialize.	"Must forget any saved server version."
	GbsConfiguration isVisualAgeImage
		ifTrue: 
			[" warning - calls must be in this order "
			self removeZombieWindows.
			self removeZombieDependents].	"Invalidate session id's, in case snapshot occurred while logged in. Iterate
	 twice so session id invalidation won't test any existing sessions to see
	 if they can be used."
	currentSession := nil.
	deadSessions := self sessions.
	self
		sessionListCritical: [deadSessions do: [:sess | self removeSession: sess]].
	deadSessions do: [:aSess | aSess cleanUp].	"Clean out any old dead sessions"
	self initializeDisconnectedSessions.
	self changed: #sessionRemoved with: nil.
	self emptyCaches.	"Reinitialize the clientMap at image startup. Anything left in it was defunct at this point anyway. This also makes sure that the clientMap and its buckets are not in permSpace, which causes delegates referenced from old buckets to never get GCed."
	self checkMemoryPolicy	"Set the correct memory policy as configured"
]

{ #category : 'private - initialization' }
GbsSessionManager >> initializeDisconnectedSessions
[

	"Initialize the collection that holds disconnected session for error
	 reporting purposes.  Currently, this is a dictionary mapping 
	 sessionId to GbsSession - so, typically, disconnectedSessions
	 will be small, as sessionIds are reused."

	disconnectedSessions := Dictionary new.
]

{ #category : 'private - initialization' }
GbsSessionManager >> initializeC
[
	"Private"

	"removed the unloadLibraries call. The comment indicated that there was a problem prior to
	vw5i which is no longer supported"

	serverInterface := nil.
	self sessions do: [:sess | sess serverInterface gbsImageStartup].
	GbxServerInterface initialize.
	isRemote := nil
]

{ #category : 'private - initialization' }
GbsSessionManager >> serverInterfaceClass
[
	
	^GbxGciSingleTripInterface
]

{ #category : 'private - initialization' }
GbsSessionManager >> newServerInterface
[
	"Create a new server interface to be used by GBSM. For now, GBSM's interface is always blocking."

	| config |
	config := GbsConfiguration current copy.
	config blockingProtocolRpc: true.
	^self serverInterfaceClass forSession: nil
		configuration: config
]

{ #category : 'global connections' }
GbsSessionManager >> addGlobalConnector: aGSConnector
[

	"Add aGSConnector to the global connectors collection.  Connects aGSConnector in any currently logged in session."

	self addNoConnectGlobalConnector: aGSConnector.
	self loggedInSessions do: [ :sess | aGSConnector connectInSession: sess ]
]

{ #category : 'global connections' }
GbsSessionManager >> addNoConnectGlobalConnector: aGSConnector
[
	"Add aGSConnector to the global connectors collection."
	"First, remove any pre-existing connector that resolves to the same stObj"

	| oldConn |
	oldConn := globalConnectors detect: [:each | each = aGSConnector] ifNone: [nil].
	oldConn == nil ifFalse: [globalConnectors remove: oldConn].
	globalConnectors add: aGSConnector.
	aGSConnector resolveClientObj.
]

{ #category : 'global connections' }
GbsSessionManager >> removeGlobalConnector: aGSConnector
[
	"Remove aGSConnector from globalConnectors, if it exists."

	| oldConn |
	oldConn := globalConnectors detect: [:conn | conn = aGSConnector]
				ifNone: [].
	oldConn == nil ifFalse: [globalConnectors remove: oldConn]
]

{ #category : 'accessing' }
GbsSessionManager >> sessionListProtect
[
	"Private to GBS. For assertion use only."

	^sessionListProtect
]

{ #category : 'accessing' }
GbsSessionManager >> isInitialized
[

	^isInitialized
]

{ #category : 'testing' }
GbsSessionManager >> safeIsLoggedIn
[
	"Returns true if this GSSessionManager knows of any GSSessions, and the session thinks it's logged in. It's important that this method not block, so unlike #isLoggedIn, don't set the current session."

	"GBSM safeIsLoggedIn"

	^(currentSession notNil and: [currentSession hasValidSessionId]) 
		ifTrue: [true]
		ifFalse: 
			[| aSess |
			aSess := sessions 
						detect: [:aGSess | aGSess notNil and: [aGSess hasValidSessionId]]
						ifNone: [nil].
			aSess notNil]
]

{ #category : 'testing' }
GbsSessionManager >> privateIsRemote
[
	"Private. Answers boolean or nil if can't determine"

	isRemote isNil ifFalse: [^isRemote].
	serverInterface isNil ifTrue: [^nil].
	^
	[isRemote := GbsError 
				primUnpolledResultOrError: self serverInterface isRemote
				verifyArgs: [true]
				session: nil] 
			on: GbsInterfaceError, GbsGemStoneError
			do: [:ex | ex return: nil]
]

{ #category : 'testing' }
GbsSessionManager >> isRemote
[

	"Returns true if a linked gem is not possible with this Smalltalk virtual machine.
	 Compare this with GbsSession>>isRemote, which can return a different answer.
	 That's because a client capable of having a linked gem is also capable of having
	 a remote gem."

	^self privateIsRemote == true

	"Note: #privateIsRemote can answer boolean or nil if unknown."
]

{ #category : 'testing' }
GbsSessionManager >> isLinkedLoginAvailable
[
	"Answer true if the loaded GCI library can support a linked session and 
	the linked session is not currently logged in. Answer false if not. Always
	tries to load client libraries first. "
	
	self tryToLoadClientLibraries.
	^GBSM isLinked
		and:
			[(GBSM loggedInSessions
				detect: [:s | s isLinked]
				ifNone: [nil]) isNil]
]

{ #category : 'testing' }
GbsSessionManager >> isLoggedIn
[

	"Returns true if this GSSessionManager knows of any logged in GSSessions.  If the current session is invalid, I will try to find one that is, and make it the current session."
	"GBSM isLoggedIn"

	^self searchForCurrentSession notNil
]

{ #category : 'testing' }
GbsSessionManager >> isLinked
[

	"Returns true if a linked gem is possible with this Smalltalk virtual
	 machine.  Compare this with GbsSession>>isLinked, which can return
	 a different answer.  That is because a vm capable of having a linked
	 gem is also capable of having a remote gem."

	^self privateIsRemote == false

	"Note: #privateIsRemote can answer boolean or nil if unknown."
]

{ #category : 'testing' }
GbsSessionManager >> hasCacheWriteCriticalAccess
[
	^clientMap hasCriticalAccess
]

{ #category : 'testing' }
GbsSessionManager >> verifyCurrentSession
[

	"Returns true if there is a current session that is logged in.  Otherwise, sets currentSession to nil and returns false.  This differs from isLoggedIn in that the current session is not changed to another session if the current one is invalid."

	(currentSession notNil and: [ currentSession isLoggedIn ])
		ifTrue: [ ^true ]
		ifFalse: [ currentSession := nil.  ^false ]
]

{ #category : 'transactions' }
GbsSessionManager >> beginTransactionDialog
[

	"Select a session to beginTransaction"
	"GBSM beginTransactionDialog"

	^self selectLoggedInSessionSending: #beginTransaction label: 'Begin transaction in session:'
]

{ #category : 'transactions' }
GbsSessionManager >> commitTransactionDialog
[

	"Select a session to commit"
	"GBSM commitTransactionDialog"

	^self selectLoggedInSessionSending: #commitTransaction label: 'Commit transaction in session:'
]

{ #category : 'transactions' }
GbsSessionManager >> abortTransactionDialog
[

	"Select a session to abort"
	"GBSM abortTransactionDialog"

	^self selectLoggedInSessionSending: #abortTransaction label: 'Abort transaction in session:'
]

{ #category : 'session management' }
GbsSessionManager >> sessions
[
	"Private (new as of 5.1.4 093). Answer a collection of sessions.
	 Use #loggedInSessions to ensure that sessions are really logged in."

	sessions isNil ifTrue: [^Array new].
	^sessions reject: [ :s | s isNil ]
]

{ #category : 'session management' }
GbsSessionManager >> sessionsWithParameters: aGSSessionParameters
[
	"Returns a set of sessions that are currently logged in with the given parameters"

	^self loggedInSessions select: [:s | s parameters = aGSSessionParameters]
]

{ #category : 'session management' }
GbsSessionManager >> currentSessionIfNone: aBlock
[

	"GBSM currentSessionIfNone: [ nil ]"

	^currentSession isNil
		ifTrue: [ aBlock value ]
		ifFalse: [ currentSession ]
]

{ #category : 'session management' }
GbsSessionManager >> knownParameters
[

	"Return all GbsSessionParameters I know about"
	"GBSM knownParameters"

	^parameters
]

{ #category : 'session management' }
GbsSessionManager >> logout
[
	"Prompt the user to select which session should be logged out, then log it out.  Only logged in sessions will appear on the list.  Return that session, or nil if cancelled."

	"GBSM logout"

	| msg |
	msg := GbsConfiguration current confirm 
				ifTrue: [#logoutDialog]
				ifFalse: [#logout].
	^self selectLoggedInSessionSending: msg label: 'Logout session:'
]

{ #category : 'session management' }
GbsSessionManager >> loggedInSessions
[
	"Return a collection containing the logged in sessions.  Take this
	 opportunity to remove any sessions that are not logged in."

	"This method avoids errors caused by discovering a session has died,
	 by sending #quickIsLoggedIn instead of #isLoggedIn.  That also means
	 that this method can return a session which has died, but GBS hasn't
	 yet discovered it has died."

	^self sessions select: [:sess | sess hasValidSessionId]
]

{ #category : 'session management' }
GbsSessionManager >> loginWithParameters: aGSSessionParameters
[

	^aGSSessionParameters login
]

{ #category : 'session management' }
GbsSessionManager >> notifyOfAddedSession: aGSSession 
[
	"Add aGSSession to sessions."

	self changed: #sessionAdded with: aGSSession.
	self triggerEvent: #gbxSessionAdded.
	self statResource setNumSessions
]

{ #category : 'session management' }
GbsSessionManager >> removeParameters: aGSSessionParameters
[

	"Remove a GSSessionParameters from known parameters."

	| aParams |
	aParams := parameters remove: aGSSessionParameters ifAbsent: [ nil ].
	aParams notNil ifTrue: [self changed: #sessionParametersRemoved with: aGSSessionParameters].
	^aParams
]

{ #category : 'session management' }
GbsSessionManager >> removeSession: aGSSession
[
	"If the current session is aGSSession, set it to nil.  Remove aGSSession from sessions and notify dependents. 
	Sender must hold sessionListProtect."

	| index |
	index := sessions indexOf: aGSSession.
	index = 0
		ifFalse: 
			[sessions at: index put: nil.
			currentSession = aGSSession ifTrue: [currentSession := nil].
			self statResource setNumSessions.
			self triggerEvent: #gbxSessionRemoved].
	[sessions size == 0 ifTrue: [numSessionsInInteraction == 0] ifFalse: [true]]
		gbxAssert
]

{ #category : 'session management' }
GbsSessionManager >> addParameters: aGbsSessionParameters
[

	"Register a new GbsSessionParameters."
	"GbsSessionParameters new"

	GbsError verify: aGbsSessionParameters is: GbxSessionSpecification.
	"Avoid multiple occurrences"
	parameters remove: aGbsSessionParameters ifAbsent: [ nil ].
	parameters add: aGbsSessionParameters.
	self changed: #sessionParametersAdded with: aGbsSessionParameters
]

{ #category : 'session management' }
GbsSessionManager >> searchForCurrentSession
[
	"If the current session is a logged in session, return it.  If not, search
	 sessions for a logged in session, make it the current session, and
	 return it.  Otherwise, return nil."

	"This method avoids errors caused by discovering a session has died,
	 by sending #hasValidSessionId instead of #isLoggedIn.  That also means
	 that this method can return a session which has died, but GBS hasn't
	 yet discovered it has died."

	"GBSM searchForCurrentSession"

	(currentSession isNil or: [currentSession hasValidSessionId not]) 
		ifTrue: 
			[| aSess |
			aSess := sessions 
						detect: [:aGSess | aGSess notNil and: [aGSess hasValidSessionId]]
						ifNone: [currentSession := nil].
			aSess notNil ifTrue: [self currentSession: aSess]].
	^currentSession
]

{ #category : 'session management' }
GbsSessionManager >> sessionWithId: anInteger
[

	"Returns a logged in GbsSession with session id of anInteger, if
	 it exists.  Otherwise, answer nil."

	^( anInteger between: 1 and: sessions size )
		ifTrue: [ sessions at: anInteger ]
		ifFalse: [ nil ].
]

{ #category : 'session management' }
GbsSessionManager >> blindlyAddParameters: aGbsSessionParameters
[

	parameters add: aGbsSessionParameters.
	self changed: #sessionParametersAdded with: aGbsSessionParameters
]

{ #category : 'session management' }
GbsSessionManager >> currentSession
[

	"GBSM currentSession"

	^self currentSessionIfNone: [self gbsMessenger error: 'There is no current session']
]

{ #category : 'session management' }
GbsSessionManager >> sessionWithId: anInteger ifNone: failBlock
[

	"Private. Obsolete. Use #sessionWithId: instead. Returns a logged
	 in GbsSession with session id of anInteger, if it exists.
	 Otherwise, answer the result of evaluating failBlock."

	| sess |
	^(sess := self sessionWithId: anInteger) isNil
		ifTrue: [ failBlock value ]
		ifFalse: [ sess ].
]

{ #category : 'session management' }
GbsSessionManager >> currentSession: aGSSession 
[
	"Make aGSSession the current session. Check for a session that knows it's 
	not logged in, but this method must not try to acquire any GBS semaphores, 
	so don't check for a session that is dead but hasn't figured that out yet -- it'll 
	become obvious soon enough."

	aGSSession hasValidSessionId 
		ifFalse: [^GbsError raiseBadSessionIdFor: aGSSession].
	currentSession := aGSSession.
	self changed: #session with: aGSSession
]

{ #category : 'private - stObj cache' }
GbsSessionManager >> emptyCaches
[
	"Very Private.  This is to be used with extreme care. This method may be removed
	 in a future GBS version."

	self gbsMessenger 
		statusTag: #cache
		message: 'WARNING: %1>>emptyCaches. Cache contained %1 objects which are now defunct.'
		with: self
		with: clientMap size.
	"Avoid finalization of current stObjectCache"
	clientMap notNil ifTrue: [clientMap release].
	clientMap := nil.
	self allocateCaches
]

{ #category : 'private - stObj cache' }
GbsSessionManager >> allocateCaches
[
	"Private.  To be sent at login time.  
	The first login will cause the client map to be allocated - but subsequent logins will not re-allocate unless the image has
	been converted from 32 to 64 bits, or vice versa. The client map may change from its stats subclass to the superclass
	and back without being reinitialized on login.
	Note that if an image is converted with stats enabled, the new client map will not have stats enabled."

	(clientMap isKindOf: self clientMapNonStatisticsClass)
		ifFalse: 
			[clientMap ~~ nil ifTrue: [clientMap release].
			clientMap := self clientMapNonStatisticsClass new: GbsConfiguration current clientMapCapacity]
]

{ #category : 'private - stObj cache' }
GbsSessionManager >> delegateForClientObject: anObject
[

	"Private."

	^clientMap delegateAtClient: anObject.
]

{ #category : 'private - stObj cache' }
GbsSessionManager >> clientMapNonStatisticsClass
[
	"Which client map class we use depends on whether we're running 32-bit VW or 64-bit VW.
	The identity hash range differs greatly between the two, so a different approach is used for performance."

	^GbsConfiguration is64BitClient ifTrue: [GbxClientObjDictionary64] ifFalse: [GbxClientObjDictionary32]
]

{ #category : 'private - stObj cache' }
GbsSessionManager >> clientMap
[
	"Private."

	^clientMap
]

{ #category : 'private - stObj cache' }
GbsSessionManager >> removeAtST: anObject forSession: aSession
[
	"Private.  A client object can be associated with more than one
	 proxy (a proxy for each session). This disassociates only from
	 the specified session. Use with great care because anObject
	 will be defunct afterwards."

	clientMap
		removeClient: anObject
		forSession: aSession.
]

{ #category : 'private - stObj cache' }
GbsSessionManager >> atST: anObject putGS: aGSObject
[
	"Private.
	Sender must hold the ClientMap's writeProtect semaphore."

	aGSObject isNil
		ifTrue: 
			[self gbsMessenger error: 'Cache dictionaries don''t expect nil values.'].
	anObject isGSObject
		ifTrue: 
			[self gbsMessenger failure: 'Unexpected StToGs cache key, %1' with: anObject].
	clientMap atClient: anObject putDelegate: aGSObject
]

{ #category : 'private - stObj cache' }
GbsSessionManager >> emptyCachesForSession: aGSSession 
[
	"Private.  Remove all stObjectCache entries that have delegates for
	 aGSSession.  If an object is associated with more than one delegate
	 (via a GbxObjectList), only the delegate associated with aGSSession
	 is removed from that list."

	"Sender must hold the clientMap writeLock."

	self gbsMessenger 
		statusTag: #cache
		message: '%1>>emptyCachesForSession: %2.'
		with: self
		with: aGSSession.
	clientMap isNil ifTrue: [^self].

	"Do this even if the last session is logging out, to invalidate delegate"
	clientMap clearForSession: aGSSession
]

{ #category : 'private - global connections' }
GbsSessionManager >> connectorList
[
	"Private.  For use by the connector browser. 
	A Set of GbsConnectors to be connected whenever any session logs in"

	^globalConnectors
]

{ #category : 'private - global connections' }
GbsSessionManager >> allClassConnectors: sessionConnectors do: aBlock
[
	"Private.  For each global or session class connector, do <aBlock>"

	globalConnectors do: [:each | each clientObjIsUnstubbedClass ifTrue: [aBlock value: each]].
	sessionConnectors do: [:each | each clientObjIsUnstubbedClass ifTrue: [aBlock value: each]].
]

{ #category : 'private - global connections' }
GbsSessionManager >> globalClassConnectorsList
[
	"Note that GBS works explicitly with legacy streams.
	 It should support both legacy and portable, but that
	 will be a big change.
	 Both the dictionary name and the condition number are optional,
	 so if the default dictionary name is desired and the condition number
	 is required, the name needs to be specified (nil, if the name will be found in the symbol list)."

	^#("Private.  
		Client Name"												"Server name"				"Optional Server Symbol Dictionary"	"Optional condition number"
		(GbsReadByteStream							ReadByteStream			GemStone_Legacy_Streams			3)
		(ServerClasses.PositionableStream					PositionableStream			GemStone_Portable_Streams)
		(ServerClasses.PositionableStreamLegacy			PositionableStreamLegacy)
		(ServerClasses.PositionableStreamPortable			PositionableStreamPortable)
		(ServerClasses.FileStreamPortable					FileStreamPortable)
		(ServerClasses.ReadStream						ReadStream				GemStone_Portable_Streams)
		(ServerClasses.ReadStreamLegacy					ReadStreamLegacy)
		(ServerClasses.ReadStreamPortable				ReadStreamPortable)
		(ServerClasses.ReadByteStream					ReadByteStream			GemStone_Portable_Streams			3)
"		(ReadWriteStream					ReadWriteStream			nil								2)"
		(ServerClasses.ReadWriteStreamPortable			ReadWriteStreamPortable)
		(ServerClasses.WriteStream						WriteStream				GemStone_Portable_Streams)
		(ServerClasses.WriteStreamLegacy					WriteStreamLegacy)
		(ServerClasses.WriteStreamPortable				WriteStreamPortable)
		(ServerClasses.TranscriptStreamPortable			TranscriptStreamPortable)
		"In Pharo 13, Unicode7/16/32 cannot be subclassed due to special layouts.
		 GemStone Unicode strings map to Pharo's native ByteString/WideString"
		(Unicode7									ByteString)
		(Unicode16									WideString)
		(Unicode32									WideString)
		)
]

{ #category : 'private - global connections' }
GbsSessionManager >> exceptionConnectorsList
[
	"Private. Answer the specs for mapping exception classes. Only used with GS64 3.0 and later servers."
	"Indentation follows server class hierarchy."
	^#(
		"Client Name(s), cached first"									"Server name"						"Optional condition number"
		(GenericException												AbstractException)
			(Exception													Exception)
				(ControlInterrupt												ControlInterrupt)
					(HaltInterrupt													Halt)
					(BreakInterrupt												Breakpoint)
				(Notification													Notification)
					(Exceptions.Admonition 								Admonition)
						(Exceptions.AlmostOutOfMemory 						AlmostOutOfMemory)
						(Exceptions.AlmostOutOfStack 						AlmostOutOfStack)
						(Exceptions.RepositoryViewLost 						RepositoryViewLost)
					(Exceptions.Deprecated 								Deprecated)
					(Exceptions.FloatingPointException 					FloatingPointException)
					(Exceptions.ObjectsCommittedNotification				 ObjectsCommittedNotification)
					(Exceptions.TransactionBacklog 						TransactionBacklog)
				(Warning 														Warning)
					(Exceptions.InterSessionSignal 						InterSessionSignal)
				(Error 														Error)
					(Exceptions.MessageNotUnderstood 					MessageNotUnderstood)
					(Exceptions.InternalError 							InternalError)
					(Exceptions.GciTransportError 							GciTransportError)
					(CompilationError 												CompileError)
					(Exceptions.UserDefinedError 							UserDefinedError)
					(Exceptions.SecurityError 							SecurityError)
					(Exceptions.ThreadError 								ThreadError)
					(Exceptions.ImproperOperation 						ImproperOperation)
						(Exceptions.LookupError 								LookupError)
						(Exceptions.ArgumentError 							ArgumentError)
						(Exceptions.OffsetError 								OffsetError)
						(Exceptions.OutOfRange 								OutOfRange)
							(Exceptions.FloatingPointError 						FloatingPointError)
					(Exceptions.ArgumentTypeError 						ArgumentTypeError)
					(Exceptions.CannotReturn 							CannotReturn)
					(Exceptions.EndOfStream 							EndOfStream)
					(Exceptions.ExternalError 							ExternalError)
						(Exceptions.IOError 								IOError)
							(Exceptions.SocketError 								SocketError)
						(Exceptions.SystemCallError 							SystemCallError)
					(Exceptions.IndexingErrorPreventingCommit				IndexingErrorPreventingCommit)
					(Exceptions.LockError 								LockError)
					(ArithmeticError 												NumericError)
						(Exceptions.ZeroDivide								ZeroDivide)
					(Exceptions.RepositoryError 							RepositoryError)
					(Exceptions.TransactionError 							TransactionError)
					(Exceptions.UncontinuableError 						UncontinuableError)
					(Exceptions.SignalBufferFull 							SignalBufferFull)
		)
]

{ #category : 'private - global connections' }
GbsSessionManager >> createKernelConnectorFor: array
[
	"The given array should be of size 3 and contain:
	1. A Symbol that is the client class name, or an Array of Symbols that are multiple client class names.
		In the latter case, the first class listed is mapped both ways, whereas the others are only mapped client -> server.
	2. A Symbol that when prefixed with O is the name of a shared variable containing a GbsKernelPomOop.
	3. A block for the connection condition."

	| conn clientName serverOName serverOop |
	clientName := array at: 1.
	serverOName := 'O' , (array at: 2).
	serverOop := self gbxResolve: serverOName in: #SpecialGemStoneObjects.
	clientName isArray
		ifTrue: 
			[| clientObjs |
			clientObjs := clientName collect: [:key | self gbxResolve: key].
			conn := GbxManyClientToOneKernelConnector
						primaryClientObj: clientObjs first
						secondaryClientObjs: (clientObjs allButFirst: 1)
						serverOop: serverOop]
		ifFalse:
			[conn := GbsFastConnector stObj: (self gbxResolve: clientName)
						gsObj: serverOop].
	conn connectionCondition: (array at: 3).
	conn noUpdateOnConnect.
	globalConnectors add: conn.	"Add directly, which allows what would normally be duplicates"
	^conn
]

{ #category : 'private - global connections' }
GbsSessionManager >> initializeKernelConnectors
[
	"Private.  Initialize the set of global connectors.  Any existing global connectors are deleted. 
	This is initialized once when GbsRuntime is loaded.
 
	globalConnectors is a collection of GbsConnectors which will be added to a GbsSession's 
	collection of connectors before it logs in.  After it logs in, its caches are initialized by 
	asking each connector to connect.  The default set of connectors relates numerous 
	GemStone objects with client Smalltalk objects."
	"GBSM initializeKernelConnectors "

	"First forget any existing global connectors. Use an IdentitySet so hash of connectors can change without breaking the collection"
	globalConnectors := IdentitySet new.

	"Now the fast connectors by oop"
	self initializeKernelConnectorConditions.
	self globalFastConnectorsList , self clientSpecificGlobalConnectorsList , self exceptionConnectorsList do: 
			[:array |
			| spec conditionNumber |
			"Copy the spec array and file in the third element with the condition block"
			spec := Array with: nil with: nil with: 0.
			spec replaceFrom: 1 to: array size with: array startingAt: 1.
			conditionNumber := array size > 2 ifTrue: [array at: 3] ifFalse: [1].
			spec at: 3 put: (kernelConnectorConditions at: conditionNumber).
			self createKernelConnectorFor: spec].

	"Finally the name connectors"
	self globalClassConnectorsList do: 
			[:array |
			| spec conditionNumber |
			"Copy the spec array and fill in the last element with the condition block"
			spec := Array with: nil with: nil with: nil with: 0.
			spec replaceFrom: 1 to: array size with: array startingAt: 1.
			conditionNumber := array size > 3 ifTrue: [array at: 4] ifFalse: [1].
			spec at: 4 put: (kernelConnectorConditions at: conditionNumber).
			self createKernelClassConnectorFor: spec]
]

{ #category : 'private - global connections' }
GbsSessionManager >> clientSpecificGlobalConnectorsList
[
	"VisualWorks adds a larger image-specific connector set in a separate package.
	Pharo only needs the small subset of mappings that exist in the base image."

	^#(
		(BlockClosure BlockClosure)
		(ByteString String)
		(ByteSymbol Symbol)
		(Float SmallFloat)
		(Metaclass Metaclass)
		(PositionableStream PositionableStream)
		(SequenceableCollection SequenceableCollection)
		(Stream Stream)
		(WideString DoubleByteString)
		(WideSymbol DoubleByteSymbol)
	)
		select: [ :spec | (self gbxResolve: spec first) notNil ]
]

{ #category : 'private - global connections' }
GbsSessionManager >> createKernelClassConnectorFor: specArray
[
	"The given array should be of size 3 and contain:
	1. A String that is the client class name, fully qualified if not resolvable from Smalltalk.
	2. A Symbol that is the name of a server class or other object.
	3. The server symbol dictionary name, if the symbol would not be found in the symbol list.
	4. A block for the connection condition."

	| conn clientName serverName dictionaryName |
	clientName := specArray at: 1.
	serverName := specArray at: 2.
	dictionaryName := specArray at: 3.
	conn := GbsClassConnector
				stName: clientName
				gsName: serverName
				dictionaryName: dictionaryName.
	conn connectionCondition: (specArray at: 4).
	globalConnectors add: conn.	"Add directly, which allows what would normally be duplicates"
	^conn
]

{ #category : 'private - global connections' }
GbsSessionManager >> initializeKernelConnectorConditions
[
	"Private.  Initialize the conditions used by kernel connectors to determine whether they should connect.
	 The block takes an optional argument, the newly and barely logged in session.
	 This is initialized once when GbsRuntime is loaded. These are keyed by number.
	 GbxServerVersion current is executed separately in each block so that it does not try to load
	 the GCI library when GBS is loaded."
	" GBSM initializeKernelConnectorConditions "

	kernelConnectorConditions := (OrderedCollection new)
				add: 
						["1 - the default"
						true];
				add: 
						[:aSession |
						"2 - portable streams implementation is in effect"
						aSession isStreamsImplementationPortable];
				add: 
						["3 - 3.7 or newer"
						GbxServerVersion current atLeast64v37];
				yourself
]

{ #category : 'private - global connections' }
GbsSessionManager >> globalFastConnectorsList
[

	^#("Private.  
		Client Name(s), cached first"								"Server name"					"Optional condition number"
		(Array												Array)
		(Association											Association)
		(Bag 												Bag)
		(Boolean												Boolean)
		(ByteArray											ByteArray)
		(Character											Character)
		(Collection											Collection)
		(Date												Date)
		(Dictionary											Dictionary)
		(Fraction												Fraction)
		(GbxClampSpecification						ClampSpecification)
		(GbxClassSet 								ClassSet)
		(GbxExecBlock								ExecBlock)
		(GbxExecBlock0							ExecBlock0)
		(GbxExecBlock1							ExecBlock1)
		(GbxExecBlock2							ExecBlock2)
		(GbxExecBlock3							ExecBlock3)
		(GbxExecBlock4							ExecBlock4)
		(GbxExecBlock5							ExecBlock5)
		(GbxExecBlockN							ExecBlockN)
		(GbxFastIdentityKeyValueDictionary 			FastIdentityKeyValueDictionary)
		(GbxGsMethodDictionary 						GsMethodDictionary)
		(GbxUnauthorizedObjectStub 					UnauthorizedObjectStub)
		(ServerClasses.ClientForwarder 				ClientForwarder)
		(ServerClasses.GsClass						Class)
		(ServerClasses.GsClassOrganizer				ClassOrganizer)
		('ServerClasses.GsNMethod' 					GsNMethod)
		(ServerClasses.GsSession					GsSession)
		(ServerClasses.GsCurrentSession				GsCurrentSession)
		(ServerClasses.GsRdbConnection				GsRdbConnection)
		(ServerClasses.GsIdentityDictionary			IdentityDictionary)
		(ServerClasses.GsInterSessionSignal			GsInterSessionSignal)
		(ServerClasses.GsMethod					GsMethod)
		(ServerClasses.IntegerKeyValueDictionary		IntegerKeyValueDictionary)
		(ServerClasses.KeyValueDictionary				KeyValueDictionary)
		(ServerClasses.LanguageDictionary			LanguageDictionary)
		(ServerClasses.RcCounter					RcCounter)
		(ServerClasses.RcIdentityBag					RcIdentityBag)
		(ServerClasses.RcKeyValueDictionary			RcKeyValueDictionary)
		(ServerClasses.RcQueue						RcQueue)
		(ServerClasses.Segment						Segment)
		(ServerClasses.StringKeyValueDictionary		StringKeyValueDictionary)
		(ServerClasses.SymbolDictionary				SymbolDictionary)
		(ServerClasses.SymbolKeyValueDictionary		SymbolKeyValueDictionary)
		(ServerClasses.UserProfile					UserProfile)
		(IdentityBag											IdentityBag)
		(IdentityDictionary										IdentityKeyValueDictionary)
		((IdentitySet
			GbxIdentityClampSet)								IdentitySet)
		(Integer												Integer)
		(Interval												Interval)
		(InvariantArray											InvariantArray)
		(Number												Number)
		(Object												Object)
		(OrderedCollection										OrderedCollection)
		(ReadStream	                              							ReadStream)
		(Set													Set)
		(SmallInteger											SmallInteger)
		(SortedCollection										SortedCollection)
		((SymbolAssociation
			GbxNameAssociation)								SymbolAssociation)
		(Time												Time)
		(UndefinedObject										UndefinedObject)
		(WriteStream											WriteStream)
		)
]

{ #category : 'private' }
GbsSessionManager >> invalidateSchemesWithSelector: aSelector
[

	| sessionsWithInvalidSchemes |
	sessionsWithInvalidSchemes := self loggedInSessions
				select: [:sess | sess invalidateSchemeWithSelector: aSelector].
	sessionsWithInvalidSchemes isEmpty
		ifFalse: 
			[self gbsMessenger
				raise: Warning
				message: 'Warning: The method with selector %1 \has been removed from Object class.\One or more logged-in GemStone sessions were \using that method as a replication spec set.\These sessions may have problems if they\attempt to use that replication spec set.\\If you are seeing this message in a dialog,\both "Yes" and "No" will continue.'
				with: aSelector]
]

{ #category : 'private' }
GbsSessionManager >> myDependents
[
	"Private"

	^dependents
]

{ #category : 'private' }
GbsSessionManager >> serverInterface
[
	"Private"

	(serverInterface isNil or: [
		(serverInterface respondsTo: #loginLinked:passwords:errorHolder:) not ])
		ifTrue: [ serverInterface := self newServerInterface ].
	^serverInterface
]

{ #category : 'private' }
GbsSessionManager >> connectorGroupDescription
[

	"Private.  String to be displayed in a connector browser group list pane"
	^'Global connectors'
]

{ #category : 'private' }
GbsSessionManager >> tryToLoadClientLibraries
[
	
	GBSM initializeServerInterfaceIfNeeded.
	GbxGciCallSequencer primInterface
]

{ #category : 'private' }
GbsSessionManager >> cleanupSessionWithId: aSessionId
[
	"if there exists a session with this id, quietly blow this away
	because a new session with that id is logging in"

	(self sessionWithId: aSessionId)
		ifNotNil: 
			[:deadSess |
			deadSess postLogout.
			GbsConfiguration current verbose
				ifTrue: 
					[self gbsMessenger
						comment: 'Found zombie session with id %1. Replaced with new session.'
						with: aSessionId]]
]

{ #category : 'private' }
GbsSessionManager >> privAddSession: aGSSession
[
	"Private.  Add aGSSession to sessions."

	| sessionId |
	sessionId := aGSSession sessionId.
	self cleanupSessionWithId: sessionId.
	self sessionListCritical: 
			[[sessionId > sessions size] whileTrue: [sessions addLast: nil].
			sessions at: sessionId put: aGSSession]
]

{ #category : 'private' }
GbsSessionManager >> notifySessionsOfChangedSelector: aSelector inClass: aClass
[

	self loggedInSessions
		do: [:sess | sess changedSelector: aSelector inClass: aClass]
]

{ #category : 'private' }
GbsSessionManager >> nilAllConnectors: connectors
[
	"Private.  nil the Smalltalk object for all session-based name, class var,
	or class inst var connectors  in <connectors> that have a post connect action
	of #updateST or #forwarder. If the last session logs out, the Smalltalk object
	for global connectors is nilled out also."

	connectors do: [:conn | conn nilSTObj].
	self loggedInSessions isEmpty ifTrue: [globalConnectors do: [:conn | conn nilSTObj]]
]

{ #category : 'private' }
GbsSessionManager >> myDependents: dependentsOrNil
[
	"Private"

	dependents := dependentsOrNil
]

{ #category : 'private - testing' }
GbsSessionManager >> weakGCIsAtomic
[

	"Private.  In VisualAge, if two weak objects point to object X, it's possible
	 for one weak object to have its reference nilled but the other not.
	 See bug 13765 for details"

	^GbsConfiguration isVisualAgeImage not
]

{ #category : 'private - testing' }
GbsSessionManager >> isLinkedLoginUnavailableWithoutLoadingLibrary
[
	"Answer true if the loaded GCI library is an RPC-only library, or if a 
	linked session is currently logged in. Answer false if not, or if no 
	GCI library is currently loaded (the 'maybe' case)"

	^GBSM isRemote 
		or: [(GBSM loggedInSessions detect: [:s | s isLinked] ifNone: [nil]) notNil]
]

{ #category : 'user actions' }
GbsSessionManager >> loadUserActionLibrary: libraryName 
[
	"Load the user action library named libraryName.  If libraryName does
	 not contain a path then a standard user action library search is done.
	 The proper prefix and suffix are added to the basename if they are
	 needed.  Returns true if the library was successfully loaded, false
	 otherwise."

	GbsConfiguration 
		deprecated: 'GbsSessionManager>>loadUserAction deprecated December, 2006. If you rely on this method, please let GemStone support know how you are using it.'.
	^self serverInterface loadUserActionLibrary: libraryName
]

{ #category : 'private - session management' }
GbsSessionManager >> changedParameters: aGSSessionParameters
[
	"Private.  Broadcast the fact that the parameters have been edited."

	self changed: #sessionParameters with: aGSSessionParameters
]

{ #category : 'private - session management' }
GbsSessionManager >> disconnectSession: aGSSession 
[
	"Private.  The session aGSSession has logged out.  Mark it disconnected.
	We might need to reset the current session"

	self sessionListCritical: 
			[disconnectedSessions at: aGSSession sessionId put: aGSSession.
			self removeSession: aGSSession].
	"Must send the sessionRemoved event before the #session event"
	self changed: #sessionRemoved with: aGSSession.
	self searchForCurrentSession
]

{ #category : 'private - session management' }
GbsSessionManager >> selectLoggedInSessionSending: aSelector label: label
[
	"Private.  Let the user select from the logged in sessions, and send aSelector to that session"

	| sessionArray labels |
	sessionArray := self loggedInSessions.
	sessionArray isEmpty
		ifTrue: [^self gbsMessenger warn: 'No sessions are logged into GemStone'].
	labels := sessionArray collect: [:aSess | aSess printString].
	(self gbsMessenger
		choose: label
		fromList: labels
		values: sessionArray
		lines: 4
		cancel: [^nil]) perform: aSelector
]

{ #category : 'private - session management' }
GbsSessionManager >> disconnectedSessionWithId: id
[

	"Return a session that is disconnected (either logged out or
	 suffered a fatal error), which had the given id - or nil"

	^disconnectedSessions at: id ifAbsent: [ nil ]
]

{ #category : 'version' }
GbsSessionManager >> version
[
	"GBSM version"

	^self class version
]

{ #category : 'accessing' }
GbsSessionManager class >> version
[
	"Return the version string for this release."
	"	self version.	"

	^GbsConfiguration version
]

{ #category : 'initialization' }
GbsSessionManager class >> initializeMiscConstants
[
	"GbsSessionManager initializeMiscConstants"
	| notCachedToken |

	"Minimum traversal buffer size - from GCI_MIN_TRAV_BUFF_SIZE in gci.ht"

	Smalltalk at: #MinTraversalBufferSize put: 2048.
	Smalltalk at: #SmallTraversalBufferSize put: 5000.


	"GemStone object implementation types."
	Smalltalk at: #Pointers put: 0.
	Smalltalk at: #Bytes put: 1.
	Smalltalk at: #NSC put: 2.
	Smalltalk at: #Special put: 3.

	"Store Buffers Flags"
	Smalltalk at: #StoreValuesFinishUpdates put: 8.


	"Other"
	notCachedToken := (Smalltalk at: #NotCachedToken ifAbsent: [ 'Not cached' copy ]) copy.
	(notCachedToken respondsTo: #gbxIsImmutable:)
		ifTrue: [ notCachedToken gbxIsImmutable: true ].
	Smalltalk at: #NotCachedToken put: notCachedToken.
	Smalltalk at: #NameSlot put: 11
]

{ #category : 'initialization' }
GbsSessionManager class >> initialize
[
	"Private.  Load-time initialization, other initialization is done later,
	for instance when the C library is first opened."

	"GbsSessionManager initialize"

	self initializeMiscConstants
]

{ #category : 'initialization' }
GbsSessionManager class >> initializeGBSM
[
	"Added to dictionary before initialized because intialization routine may
	 reference GBSM. Note: #at:put: in vw5i returns a namespace instead
	 of the put object."

	| inst |
	inst := super new.
	Smalltalk at: #GBSM put: inst.
	inst initialize.
]

{ #category : 'initialization' }
GbsSessionManager class >> gbsImageStartup
[
	"Notification that the image is starting up"

	| gbsm |
	(gbsm := self gbxResolve: #GBSM) isNil
	ifTrue:  [ self initializeGBSM ]
	ifFalse: [ gbsm gbsImageStartup ]
]

{ #category : 'initialization' }
GbsSessionManager class >> gbsRemoving
[
	"Private.  Eliminate instances of classes in the application, in preparation
	 for unload. Code was once in ENVY #removing methods but was moved
	 here for parcels. The GbsRuntime parcel should send this as a pre-unload
	 action."

	| gsiAssoc specials |
	gsiAssoc := self gbxBindingFor: #GBSM.
	"First, log out any active sessions"
	(gsiAssoc isNil or: [gsiAssoc value isNil])
		ifFalse: 
			[gsiAssoc value loggedInSessions do: [:s | s logout].
			gsiAssoc value knownParameters copy
				do: [:s | gsiAssoc value removeParameters: s].
			(self gbxResolve: #ObjectMemory in: #Kernel)
				removeDependent: gsiAssoc value.
			gsiAssoc value: nil].
	"Terminate the GbxFinalizer and start a new default WeakArray one."
	WeakArray installFinalizationMechanism.
	GbsTimeZone gbsClassUnloading.
	GbxExecBlock gbsClassUnloading.
	specials := self gbxResolve: #SpecialGemStoneObjects.
	specials isNil ifFalse: [specials bindingsDo: [:assoc | assoc value: nil]].

	"Change GbxNameAssociations into regular associations"
	GbxNameAssociation allInstances do: 
			[:inst |
			inst
				become: (GbxNameAssociation superclass key: inst key value: inst value)].
	((#(#GbsForwarder #GbxObjectStub #GbxCursorWrapper)
		inject: OrderedCollection new
		into: 
			[:all :cname |
			| real |
			real := self gbxResolve: cname.
			real isNil ifFalse: [all addAll: real withAllSubclasses].
			all])
			inject: OrderedCollection new
			into: 
				[:all :cl |
				all addAll: cl allInstances.
				all]) asArray
		do: [:inst | inst gbxBecome: 'ZAPPED during GBSM unload' copy].
	GbxMessageDispatcher initialize
	"Careful: Any send of #gbsMessager that follows will recreate the singleton."
]

{ #category : 'initialization' }
GbsSessionManager class >> postLoad: aParcel
[
	"During parcel load, by default #initialize will be sent. We can't do that here,
	because some of the code needed to run #initialize is in other parcels. Wait until
	the post-load action for the parcel to initialize."

	"Do nothing."
]

{ #category : 'initialization' }
GbsSessionManager class >> gbsLoaded
[
	"Private.  A group of classes was just loaded. Code was once in ENVY #loaded
	 methods but was moved here for parcels. The GbsRuntime parcel should send
	 this as a post-load action, after sending parcelPostLoad"
	"After Store load of a new version, must undo things done by #gbsRemoving"
	"GbsSessionManager gbsLoaded"

	GbxKernelPomOop initialize.
	GbxSpecialOop initialize.
	GbsSessionManager initialize.
	GbxServerInterface initialize.
	GbxGciCallSequencer initialize.
	GbsTimeZone initialize.
	GbxExecBlock initialize.
	self gbsImageStartup
]

{ #category : 'initialization' }
GbsSessionManager class >> parcelPostLoad
[
	"In an ENVY image, sent from the subApplication's loaded method.
	When parcel loading, sent from the parcel's post-load block.
	This method has the responsibility for doing all deferred initialization
	for the entire subApplication/parcel."

	GbsConfiguration initialize.
	GbsError initialize.
	GbsSessionManager initialize.
	"The stat resource classes depend on GbxStatArchiver having
	 initialized first, which we can't rely on."
	GbxStatResource subclasses do: [:cls | cls initialize]
]

{ #category : 'instance creation' }
GbsSessionManager class >> new
[
	"This class has only one instance.  See GbsSessionManager class>>initialize."
	^self shouldNotImplement
]
