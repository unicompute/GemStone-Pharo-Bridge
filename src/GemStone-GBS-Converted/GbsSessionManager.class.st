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
		'stats',
		'fastConnectorRegistry'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'actions' }
GbsSessionManager class >> addConnectorClient: clientClassName server: serverClassName [
	| registry c s |
	c := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	s := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	(c isEmpty or: [ s isEmpty ]) ifTrue: [ ^ self ].
	registry := self fastConnectorRegistry ifNil: [ Dictionary new ].
	registry at: c put: s.
	registry at: s put: c.
	self fastConnectorRegistry: registry.
	self ensureConnectorObjectForClient: c server: s
]

{ #category : 'actions' }
GbsSessionManager class >> addConnectorClient: clientClassName server: serverClassName forSession: aSession [
	| c s registry sessionKey |
	c := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	s := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	(c isEmpty or: [ s isEmpty ]) ifTrue: [ ^ self ].
	sessionKey := self sessionKeyForSessionObject: aSession.
	registry := self sessionConnectorRegistry copy.
	(registry at: sessionKey ifAbsentPut: [ Dictionary new ]) at: c put: s.
	(registry at: sessionKey ifAbsentPut: [ Dictionary new ]) at: s put: c.
	Smalltalk globals at: #GbsSessionConnectorRegistry put: registry.
	self ensureConnectorObjectForClient: c server: s
]

{ #category : 'connector state' }
GbsSessionManager class >> clearAllConnectorClassMappings [
	Smalltalk globals at: #GbsConnectorClassMappingRegistry put: Dictionary new.
	self rebuildConnectorObjectRegistry
]

{ #category : 'connector state' }
GbsSessionManager class >> clearConnectorClassForClient: clientClassName server: serverClassName [
	| key registry |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self connectorClassMappingRegistry copy.
	registry removeKey: key ifAbsent: [ ].
	Smalltalk globals at: #GbsConnectorClassMappingRegistry put: registry.
	self removeConnectorObjectForClient: clientClassName server: serverClassName
]

{ #category : 'connector state' }
GbsSessionManager class >> clearPostConnectActionForConnectorClient: clientClassName server: serverClassName [
	| key registry |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self postConnectActionRegistry copy.
	registry removeKey: key ifAbsent: [ ].
	Smalltalk globals at: #GbsConnectorPostConnectActionRegistry put: registry
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorClassChoices [
	^ {
		GbsFastConnector.
		GbsNameConnector.
		GbsClassConnector.
		GbsClassVarConnector.
		GbsClassInstVarConnector.
	}
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorClassForClient: clientClassName server: serverClassName [
	| map key classSpec classObject |
	map := self connectorClassMappingRegistry.
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	classSpec := map at: key ifAbsent: [ nil ].
	classSpec ifNotNil: [
		classObject := (classSpec isBehavior)
			ifTrue: [ classSpec ]
			ifFalse: [ Smalltalk globals at: classSpec asSymbol ifAbsent: [ nil ] ].
		(classObject notNil and: [ classObject inheritsFrom: GbsConnector ])
			ifTrue: [ ^ classObject ] ].
	(self isFastConnectorClient: clientClassName server: serverClassName)
		ifTrue: [ ^ GbsFastConnector ].
	^ GbsNameConnector
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorClassMappingEntries [
	| pairs map |
	pairs := self connectorPairs.
	map := self connectorClassMappingRegistry.
	^ pairs collect: [ :pair |
		| clientName serverName key explicitClass effectiveClass |
		clientName := pair at: 1 ifAbsent: [ '' ].
		serverName := pair at: 2 ifAbsent: [ '' ].
		key := self connectorObjectKeyForClient: clientName server: serverName.
		explicitClass := map at: key ifAbsent: [ nil ].
		explicitClass := explicitClass
			ifNil: [ nil ]
			ifNotNil: [ explicitClass isBehavior ifTrue: [ explicitClass ] ifFalse: [ Smalltalk globals at: explicitClass asSymbol ifAbsent: [ nil ] ] ].
		effectiveClass := self connectorClassForClient: clientName server: serverName.
		{
			clientName asString.
			serverName asString.
			(explicitClass ifNil: [ '<default>' ] ifNotNil: [ explicitClass name asString ]).
			(effectiveClass ifNil: [ '<none>' ] ifNotNil: [ effectiveClass name asString ])
		}
	]
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorClassMappingRegistry [
	^ Smalltalk globals
		at: #GbsConnectorClassMappingRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorClassMappingReportText [
	| entries |
	entries := self connectorClassMappingEntries.
	entries isEmpty ifTrue: [ ^ 'No connectors available.' ].
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Connector Class Mappings'; cr; cr.
		stream nextPutAll: 'Client -> Server'; tab; nextPutAll: 'Override'; tab; nextPutAll: 'Effective'; cr.
		stream nextPutAll: '------------------------------------------------------------'; cr.
		entries do: [ :row |
			stream
				nextPutAll: (row at: 1), ' -> ', (row at: 2);
				tab;
				nextPutAll: (row at: 3);
				tab;
				nextPutAll: (row at: 4);
				cr ] ]
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorConnectionKeyForClient: clientName server: serverName session: sessionKey [
	^ (clientName ifNil: [ '' ] ifNotNil: [ clientName asString ]),
		'->',
		(serverName ifNil: [ '' ] ifNotNil: [ serverName asString ]),
		'@',
		(sessionKey ifNil: [ 'default' ] ifNotNil: [ sessionKey asString ])
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorConnectionRegistry [
	^ Smalltalk globals
		at: #GbsConnectorConnectionRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorObjectForClient: clientClassName server: serverClassName [
	| registry key |
	registry := self connectorObjectRegistry.
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	^ registry at: key ifAbsent: [ self ensureConnectorObjectForClient: clientClassName server: serverClassName ]
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorObjectKeyForClient: clientClassName server: serverClassName [
	^ (clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ]),
		'->',
		(serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ])
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorObjectRegistry [
	^ Smalltalk globals
		at: #GbsConnectorObjectRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'connector groups' }
GbsSessionManager class >> connectorObjects [
	^ self connectorPairs collect: [ :pair |
		self
			ensureConnectorObjectForClient: (pair at: 1 ifAbsent: [ '' ])
			server: (pair at: 2 ifAbsent: [ '' ]) ]
]

{ #category : 'connector groups' }
GbsSessionManager class >> connectorObjectsForGroup: aConnectorGroup [
	| pairs |
	aConnectorGroup ifNil: [ ^ #() ].
	(aConnectorGroup respondsTo: #isGlobalGroup) ifTrue: [
		(aConnectorGroup isGlobalGroup)
			ifTrue: [ ^ self connectorObjects ] ].
	pairs := self connectorPairsForGroup: aConnectorGroup.
	^ pairs collect: [ :pair |
		self
			ensureConnectorObjectForClient: (pair at: 1 ifAbsent: [ '' ])
			server: (pair at: 2 ifAbsent: [ '' ]) ]
]

{ #category : 'accessing' }
GbsSessionManager class >> connectorPairs [
	| registry pairs seen |
	registry := self fastConnectorRegistry.
	(registry isNil or: [ registry isEmpty ]) ifTrue: [ ^ #() ].
	pairs := OrderedCollection new.
	seen := Set new.
	registry keysAndValuesDo: [ :clientName :serverName |
		| c s canonical pairKey |
		c := clientName asString.
		s := serverName asString.
		canonical := { c. s } asSortedCollection asArray.
		pairKey := canonical first, '->', canonical second.
		(seen includes: pairKey) ifFalse: [
			pairs add: canonical.
			seen add: pairKey ] ].
	^ pairs asArray
]

{ #category : 'connector groups' }
GbsSessionManager class >> connectorPairsForGroup: aConnectorGroup [
	| sessionObject |
	aConnectorGroup ifNil: [ ^ #() ].
	(aConnectorGroup respondsTo: #isGlobalGroup)
		ifTrue: [ aConnectorGroup isGlobalGroup ifTrue: [ ^ self connectorPairs ] ].
	sessionObject := (aConnectorGroup respondsTo: #session)
		ifTrue: [ aConnectorGroup session ]
		ifFalse: [ nil ].
	^ self connectorPairsForSession: sessionObject
]

{ #category : 'connector groups' }
GbsSessionManager class >> connectorPairsForSession: aSession [
	| sessionKey registry pairs seen objectRegistry |
	sessionKey := self sessionKeyForSessionObject: aSession.
	registry := self sessionConnectorRegistry at: sessionKey ifAbsent: [ Dictionary new ].
	objectRegistry := self connectorObjectRegistry.
	pairs := OrderedCollection new.
	seen := Set new.
	registry keysAndValuesDo: [ :clientName :serverName |
		| c s pairClient pairServer directKey inverseKey pairKey |
		c := clientName asString.
		s := serverName asString.
		directKey := self connectorObjectKeyForClient: c server: s.
		inverseKey := self connectorObjectKeyForClient: s server: c.
		(objectRegistry includesKey: directKey)
			ifTrue: [
				pairClient := c.
				pairServer := s ]
			ifFalse: [
				(objectRegistry includesKey: inverseKey)
					ifTrue: [
						pairClient := s.
						pairServer := c ]
					ifFalse: [
						pairClient := c.
						pairServer := s ] ].
		pairKey := pairClient, '->', pairServer.
		(seen includes: pairKey) ifFalse: [
			pairs add: { pairClient. pairServer }.
			seen add: pairKey ] ].
	^ pairs asArray
]

{ #category : 'connector state' }
GbsSessionManager class >> ensureConnectorObjectForClient: clientClassName server: serverClassName [
	| registry key connector connectorClass |
	registry := self connectorObjectRegistry copy.
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	connector := registry at: key ifAbsent: [ nil ].
	connector ifNil: [
		connectorClass := self connectorClassForClient: clientClassName server: serverClassName.
		connector := (connectorClass respondsTo: #stName:gsName:)
			ifTrue: [ connectorClass stName: clientClassName gsName: serverClassName ]
			ifFalse: [ connectorClass new ].
		(connector respondsTo: #stName:) ifTrue: [ connector stName: clientClassName ].
		(connector respondsTo: #gsName:) ifTrue: [ connector gsName: serverClassName ].
		(connector respondsTo: #connectorClientName:) ifTrue: [ connector connectorClientName: clientClassName ].
		(connector respondsTo: #connectorServerName:) ifTrue: [ connector connectorServerName: serverClassName ].
		(connector respondsTo: #postConnectAction:) ifTrue: [
			connector postConnectAction: (self
				postConnectActionForConnectorClient: clientClassName
				server: serverClassName) ].
		registry at: key put: connector.
		Smalltalk globals at: #GbsConnectorObjectRegistry put: registry ].
	^ connector
]

{ #category : 'accessing' }
GbsSessionManager class >> fastConnectorRegistry [
	^ Smalltalk globals at: #GbsFastConnectorRegistry ifAbsent: [ Dictionary new ]
]

{ #category : 'accessing' }
GbsSessionManager class >> fastConnectorRegistry: aDictionary [
	Smalltalk globals at: #GbsFastConnectorRegistry put: aDictionary
]

{ #category : 'actions' }
GbsSessionManager class >> generateClassConnectors [
	^ self initializeFastConnectors
]

{ #category : 'connector groups' }
GbsSessionManager class >> globalConnectorGroup [
	^ GbsConnectorGroup globalOnManagerClass: self
]

{ #category : 'as yet unclassified' }
GbsSessionManager class >> globalFastConnectorsList [
	"Answer pairs of #(PharoClientClassName GemStoneServerClassName) for the
	 global fast connectors (VW GbsKernel #globalFastConnectorsList).

	 The registry built from this list is last-wins, so the VW-parity entries
	 come first and the established Pharo mappings at the end take precedence
	 when a client or server name occurs more than once (for example
	 GbxIdentityClampSet and IdentitySet both map to server IdentitySet, but
	 server IdentitySet materializes as Pharo IdentitySet).

	 VW entries whose client is a GemStone.Gbs.ServerClasses shadow class
	 (GsSession, UserProfile, SymbolDictionary, RcQueue, ...) are omitted:
	 those shadow classes do not exist in Pharo."

	^ #(
		"VW parity: GBS client classes"
		#(GbxClampSpecification ClampSpecification)
		#(GbxClassSet ClassSet)
		#(GbxExecBlock ExecBlock)
		#(GbxExecBlock0 ExecBlock0)
		#(GbxExecBlock1 ExecBlock1)
		#(GbxExecBlock2 ExecBlock2)
		#(GbxExecBlock3 ExecBlock3)
		#(GbxExecBlock4 ExecBlock4)
		#(GbxExecBlock5 ExecBlock5)
		#(GbxExecBlockN ExecBlockN)
		#(GbxFastIdentityKeyValueDictionary FastIdentityKeyValueDictionary)
		#(GbxGsMethodDictionary GsMethodDictionary)
		#(GbxUnauthorizedObjectStub UnauthorizedObjectStub)
		#(GbxIdentityClampSet IdentitySet)
		#(IdentityDictionary IdentityKeyValueDictionary)

		"VW parity: kernel classes"
		#(Boolean Boolean)
		#(Collection Collection)
		#(Integer Integer)
		#(Interval Interval)
		#(Number Number)
		#(Object Object)
		#(ReadStream ReadStream)
		#(WriteStream WriteStream)

		"Collections"
		#(Array Array)
		#(OrderedCollection OrderedCollection)
		#(SortedCollection SortedCollection)
		#(Bag Bag)
		#(Set Set)
		#(IdentitySet IdentitySet)
		#(IdentityDictionary IdentityDictionary)
		#(ByteArray ByteArray)
		#(ByteString String)
		#(WideString DoubleByteString) "Pharo uses WideString, GS uses DoubleByteString"
		#(Symbol Symbol)
		#(ByteSymbol Symbol)
		#(WideSymbol DoubleByteSymbol)
		#(Dictionary Dictionary)
		#(Association Association)

		"Numbers"
		#(SmallInteger SmallInteger)
		#(LargePositiveInteger LargePositiveInteger)
		#(LargeNegativeInteger LargeNegativeInteger)
		#(SmallFloat64 Float) "Pharo 64-bit immediate float"
		#(BoxedFloat64 Float) "Pharo 64-bit boxed float"
		#(Fraction Fraction)

		"Magnitudes"
		#(Character Character)
		#(Date Date)
		#(Time Time)
		#(DateAndTime DateTime) "Pharo uses DateAndTime, GS/VW uses DateTime/Timestamp"

		"Booleans & Nil"
		#(True True)
		#(False False)
		#(UndefinedObject UndefinedObject)
	)
]

{ #category : 'accessing' }
GbsSessionManager class >> clientSpecificGlobalConnectorsList [
	"Answer pairs of #(PharoClientClassName GemStoneServerClassName) for the
	 client-dialect-specific global connectors (VW GbsKernelVW
	 #clientSpecificGlobalConnectorsList), translated to Pharo class names.

	 Registered after #globalFastConnectorsList without overwriting, so an
	 entry whose client is already mapped only adds the server->client
	 direction (e.g. server QuadByteString materializes as Pharo WideString,
	 while Pharo WideString still stores as DoubleByteString).

	 Omitted from VW: ISOLatin (VW stream encoder), Double, TwoByteString/
	 TwoByteSymbol and Timestamp (no Pharo class; covered by WideString,
	 WideSymbol and DateAndTime), and the GsFile/GsProcess/GsSocket/SymbolSet
	 server shadow classes."

	^ #(
		#(BlockClosure BlockClosure)
		#(ByteString String)
		#(ByteSymbol Symbol)
		#(WideString QuadByteString) "Pharo WideString holds 32-bit characters"
		#(WideSymbol QuadByteSymbol)
		#(ScaledDecimal ScaledDecimal)
		#(SmallFloat64 SmallDouble) "Pharo analogue of VW (Float SmallFloat)"
		#(LargePositiveInteger LargeInteger)
		#(LargeNegativeInteger LargeInteger)
		#(Metaclass Metaclass)
		#(PositionableStream PositionableStream)
		#(SequenceableCollection SequenceableCollection)
		#(Stream Stream)
		#(String CharacterCollection)
	)
]

{ #category : 'accessing' }
GbsSessionManager class >> exceptionConnectorsList [
	"Answer pairs of #(PharoClientClassName GemStoneServerClassName) mapping
	 exception classes (VW GbsKernel #exceptionConnectorsList). Only meaningful
	 with GS64 3.0 and later servers. Indentation follows the server class
	 hierarchy.

	 VW GemStone.Gbs.Exceptions.* clients are the unprefixed classes in
	 GemStone-GBS-Converted. Pharo has no GenericException, ControlInterrupt
	 or BreakInterrupt, so AbstractException, ControlInterrupt and Breakpoint
	 are not mapped."

	^ #(
		#(Exception Exception)
			#(Halt Halt)
			#(Notification Notification)
				#(Admonition Admonition)
					#(AlmostOutOfMemory AlmostOutOfMemory)
					#(AlmostOutOfStack AlmostOutOfStack)
					#(RepositoryViewLost RepositoryViewLost)
				#(Deprecated Deprecated)
				#(FloatingPointException FloatingPointException)
				#(ObjectsCommittedNotification ObjectsCommittedNotification)
				#(TransactionBacklog TransactionBacklog)
			#(Warning Warning)
				#(InterSessionSignal InterSessionSignal)
			#(Error Error)
				#(MessageNotUnderstood MessageNotUnderstood)
				#(InternalError InternalError)
				#(GciTransportError GciTransportError)
				#(CodeError CompileError)
				#(UserDefinedError UserDefinedError)
				#(SecurityError SecurityError)
				#(ThreadError ThreadError)
				#(ImproperOperation ImproperOperation)
					#(LookupError LookupError)
					#(ArgumentError ArgumentError)
					#(OffsetError OffsetError)
					#(OutOfRange OutOfRange)
						#(FloatingPointError FloatingPointError)
				#(ArgumentTypeError ArgumentTypeError)
				#(BlockCannotReturn CannotReturn)
				#(EndOfStream EndOfStream)
				#(ExternalError ExternalError)
					#(IOError IOError)
						#(SocketError SocketError)
					#(SystemCallError SystemCallError)
				#(IndexingErrorPreventingCommit IndexingErrorPreventingCommit)
				#(LockError LockError)
				#(ArithmeticError NumericError)
					#(ZeroDivide ZeroDivide)
				#(RepositoryError RepositoryError)
				#(TransactionError TransactionError)
				#(UncontinuableError UncontinuableError)
				#(SignalBufferFull SignalBufferFull)
	)
]

{ #category : 'accessing' }
GbsSessionManager class >> globalClassConnectorsList [
	"Answer pairs of #(PharoClientClassName GemStoneServerClassName) for the
	 global class connectors (VW GbsKernel #globalClassConnectorsList).

	 Only GbsReadByteStream has a Pharo client class. The VW stream entries are
	 GemStone.Gbs.ServerClasses shadow classes (PositionableStreamLegacy,
	 ReadStreamPortable, WriteStreamPortable, ...) and Unicode7/16/32, none of
	 which exist in Pharo. The VW optional symbol dictionary
	 (GemStone_Legacy_Streams) and condition number (3) are not used here."

	^ #(
		#(GbsReadByteStream ReadByteStream)
	)
]

{ #category : 'accessing' }
GbsSessionManager class >> additionalGlobalConnectorsLists [
	"Connector lists registered after #globalFastConnectorsList, in VW order."

	^ {
		self clientSpecificGlobalConnectorsList.
		self exceptionConnectorsList.
		self globalClassConnectorsList }
]

{ #category : 'accessing' }
GbsSessionManager class >> allGlobalConnectorsList [
	"Every global connector pair, fast list first (VW initializeGlobalConnectors order)."

	^ self additionalGlobalConnectorsLists
		inject: self globalFastConnectorsList
		into: [ :all :each | all , each ]
]

{ #category : 'initialization' }
GbsSessionManager class >> registerGlobalConnectorsInto: aRegistry [
	"Fill aRegistry with the bidirectional client/server name map.
	 #globalFastConnectorsList is last-wins (its established entries come last).
	 The additional lists never overwrite an existing key. Pairs whose Pharo
	 client class is absent from the image are skipped."

	self globalFastConnectorsList do: [ :pair |
		self registerConnectorPair: pair into: aRegistry overwrite: true ].
	self additionalGlobalConnectorsLists do: [ :list |
		list do: [ :pair |
			self registerConnectorPair: pair into: aRegistry overwrite: false ] ].
	^ aRegistry
]

{ #category : 'initialization' }
GbsSessionManager class >> registerConnectorPair: pair into: aRegistry overwrite: aBoolean [
	| clientClass clientName serverName |
	clientClass := Smalltalk globals at: pair first ifAbsent: [ nil ].
	clientClass ifNil: [ ^ aRegistry ].
	clientName := clientClass name.
	serverName := pair second.
	(aBoolean or: [ (aRegistry includesKey: clientName) not ])
		ifTrue: [ aRegistry at: clientName put: serverName ].
	(aBoolean or: [ (aRegistry includesKey: serverName) not ])
		ifTrue: [ aRegistry at: serverName put: clientName ].
	^ aRegistry
]

{ #category : 'initialization' }
GbsSessionManager class >> initializeFastConnectors [
	"Initialize the global registry of client/server connector class names."

	self fastConnectorRegistry: (self registerGlobalConnectorsInto: Dictionary new).
	self rebuildConnectorObjectRegistry
]

{ #category : 'actions' }
GbsSessionManager class >> initializeGlobalConnectors [
	"VAST parity entrypoint for connector window Group->Initialize"
	^ self initializeFastConnectors
]

{ #category : 'connector state' }
GbsSessionManager class >> resetConnectorState [
	Smalltalk globals at: #GbsFastConnectorRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorConnectionRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorClassMappingRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorPostConnectActionRegistry put: Dictionary new.
	Smalltalk globals at: #GbsSessionConnectorRegistry put: Dictionary new
]

{ #category : 'connector state' }
GbsSessionManager class >> invalidPostConnectActionsForConnectorClient: clientClassName server: serverClassName [
	"Parity hook used by connector browser. Return lower-case action names that are invalid.
	Default fast connector behavior allows all actions."
	| wrapper key registry |
	wrapper := self connectorObjectForClient: clientClassName server: serverClassName.
	(wrapper notNil and: [ wrapper respondsTo: #invalidPostConnectActions ]) ifTrue: [
		^ (wrapper invalidPostConnectActions collect: [ :each | each asString asLowercase ]) asArray ].
	key := (clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ]),
		'->',
		(serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ]).
	registry := Smalltalk globals at: #GbsConnectorInvalidActionRegistry ifAbsent: [ Dictionary new ].
	^ registry at: key ifAbsent: [ #() ]
]

{ #category : 'connector state' }
GbsSessionManager class >> isConnectorClient: clientClassName server: serverClassName connectedInSession: sessionKey [
	| wrapper key registry |
	wrapper := self connectorObjectForClient: clientClassName server: serverClassName.
	(wrapper notNil and: [ wrapper respondsTo: #isConnectedForSessionKey: ]) ifTrue: [
		^ wrapper isConnectedForSessionKey: sessionKey ].
	key := self connectorConnectionKeyForClient: clientClassName server: serverClassName session: sessionKey.
	registry := self connectorConnectionRegistry.
	^ registry at: key ifAbsent: [ true ]
]

{ #category : 'connector state' }
GbsSessionManager class >> isFastConnectorClient: clientClassName server: serverClassName [
	| c s |
	c := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	s := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	^ self globalFastConnectorsList anySatisfy: [ :pair |
		(pair at: 1 ifAbsent: [ '' ]) asString = c
			and: [ (pair at: 2 ifAbsent: [ '' ]) asString = s ] ]
]

{ #category : 'connector groups' }
GbsSessionManager class >> knownParameters [
	| sessions current |
	sessions := GbsSessionParameters allSessions asArray.
	sessions := sessions select: [ :each | each notNil ].
	sessions isEmpty ifTrue: [
		current := GbsSessionParameters currentSession.
		current ifNotNil: [ sessions := { current } ] ].
	^ sessions collect: [ :each |
		GbsConnectorGroup session: each managerClass: self ]
]

{ #category : 'accessing' }
GbsSessionManager class >> loggedInSessions [
	| current |
	current := GbsSessionParameters currentSession.
	current ifNil: [ ^ #() ].
	^ { current }
]

{ #category : 'connector state' }
GbsSessionManager class >> postConnectActionForConnectorClient: clientClassName server: serverClassName [
	| key registry |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self postConnectActionRegistry.
	^ registry at: key ifAbsent: [ 'none' ]
]

{ #category : 'connector state' }
GbsSessionManager class >> postConnectActionRegistry [
	^ Smalltalk globals
		at: #GbsConnectorPostConnectActionRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'connector state' }
GbsSessionManager class >> rebuildConnectorObjectRegistry [
	| pairs registry |
	pairs := self connectorPairs.
	registry := Dictionary new.
	pairs do: [ :pair |
		| clientName serverName key connectorClass connector |
		clientName := pair at: 1 ifAbsent: [ '' ].
		serverName := pair at: 2 ifAbsent: [ '' ].
		key := self connectorObjectKeyForClient: clientName server: serverName.
		connectorClass := self connectorClassForClient: clientName server: serverName.
		connector := (connectorClass respondsTo: #stName:gsName:)
			ifTrue: [ connectorClass stName: clientName gsName: serverName ]
			ifFalse: [ connectorClass new ].
		(connector respondsTo: #stName:) ifTrue: [ connector stName: clientName ].
		(connector respondsTo: #gsName:) ifTrue: [ connector gsName: serverName ].
		(connector respondsTo: #connectorClientName:) ifTrue: [ connector connectorClientName: clientName ].
		(connector respondsTo: #connectorServerName:) ifTrue: [ connector connectorServerName: serverName ].
		(connector respondsTo: #postConnectAction:) ifTrue: [
			connector postConnectAction: (self
				postConnectActionForConnectorClient: clientName
				server: serverName) ].
		registry at: key put: connector ].
	Smalltalk globals at: #GbsConnectorObjectRegistry put: registry
]

{ #category : 'actions' }
GbsSessionManager class >> removeConnectorClient: clientClassName server: serverClassName [
	| registry c s |
	c := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	s := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	registry := self fastConnectorRegistry ifNil: [ Dictionary new ].
	(registry respondsTo: #removeKey:ifAbsent:) ifTrue: [
		registry removeKey: c ifAbsent: [ ].
		registry removeKey: s ifAbsent: [ ] ].
	self fastConnectorRegistry: registry.
	self clearPostConnectActionForConnectorClient: c server: s.
	self removeConnectorObjectForClient: c server: s
]

{ #category : 'actions' }
GbsSessionManager class >> removeConnectorClient: clientClassName server: serverClassName forSession: aSession [
	| c s registry sessionKey sessionRegistry |
	c := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	s := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	sessionKey := self sessionKeyForSessionObject: aSession.
	registry := self sessionConnectorRegistry copy.
	sessionRegistry := (registry at: sessionKey ifAbsent: [ Dictionary new ]) copy.
	sessionRegistry removeKey: c ifAbsent: [ ].
	sessionRegistry removeKey: s ifAbsent: [ ].
	registry at: sessionKey put: sessionRegistry.
	Smalltalk globals at: #GbsSessionConnectorRegistry put: registry.
	self clearPostConnectActionForConnectorClient: c server: s.
	self removeConnectorObjectForClient: c server: s
]

{ #category : 'connector state' }
GbsSessionManager class >> removeConnectorObjectForClient: clientClassName server: serverClassName [
	| registry key |
	registry := self connectorObjectRegistry copy.
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry removeKey: key ifAbsent: [ ].
	Smalltalk globals at: #GbsConnectorObjectRegistry put: registry
]

{ #category : 'actions' }
GbsSessionManager class >> removeInvalidConnectors [
	| registry cleaned |
	registry := self fastConnectorRegistry ifNil: [ Dictionary new ].
	cleaned := Dictionary new.
	registry keysAndValuesDo: [ :clientName :serverName |
		| clientClass |
		clientClass := Smalltalk globals at: clientName asSymbol ifAbsent: [ nil ].
		clientClass ifNotNil: [
			cleaned at: clientName asString put: serverName asString.
			cleaned at: serverName asString put: clientName asString ] ].
	self fastConnectorRegistry: cleaned.
	^ cleaned
]

{ #category : 'accessing' }
GbsSessionManager class >> sessionConnectorRegistry [
	^ Smalltalk globals at: #GbsSessionConnectorRegistry ifAbsent: [ Dictionary new ]
]

{ #category : 'connector groups' }
GbsSessionManager class >> sessionKeyForSessionObject: aSession [
	| params user stone |
	aSession ifNil: [ ^ 'default' ].
	((aSession respondsTo: #username) and: [ aSession respondsTo: #gemStoneName ]) ifTrue: [
		user := [ aSession username ] on: Error do: [ nil ].
		stone := [ aSession gemStoneName ] on: Error do: [ nil ].
		^ (user ifNil: [ 'unknown-user' ] ifNotNil: [ user asString ]),
			'@',
			(stone ifNil: [ 'unknown-stone' ] ifNotNil: [ stone asString ]) ].
	params := (aSession respondsTo: #parameters)
		ifTrue: [ [ aSession parameters ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	params ifNil: [
		(aSession respondsTo: #instVarNamed:)
			ifTrue: [ params := [ aSession instVarNamed: 'parameters' ] on: Error do: [ nil ] ] ].
	params ifNil: [ ^ 'default' ].
	user := [ params username ] on: Error do: [ nil ].
	stone := [ params gemStoneName ] on: Error do: [ nil ].
	^ (user ifNil: [ 'unknown-user' ] ifNotNil: [ user asString ]),
		'@',
		(stone ifNil: [ 'unknown-stone' ] ifNotNil: [ stone asString ])
]

{ #category : 'connector state' }
GbsSessionManager class >> setConnectorClass: connectorClassOrName forClient: clientClassName server: serverClassName [
	| key registry |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self connectorClassMappingRegistry copy.
	registry at: key put: connectorClassOrName.
	Smalltalk globals at: #GbsConnectorClassMappingRegistry put: registry.
	self removeConnectorObjectForClient: clientClassName server: serverClassName
]

{ #category : 'connector state' }
GbsSessionManager class >> setConnectorClient: clientClassName server: serverClassName connected: aBoolean inSession: sessionKey [
	| wrapper key registry |
	wrapper := self connectorObjectForClient: clientClassName server: serverClassName.
	(wrapper notNil and: [ wrapper respondsTo: #setConnected:forSessionKey: ])
		ifTrue: [ wrapper setConnected: aBoolean forSessionKey: sessionKey ].
	key := self connectorConnectionKeyForClient: clientClassName server: serverClassName session: sessionKey.
	registry := self connectorConnectionRegistry copy.
	registry at: key put: (aBoolean == true).
	Smalltalk globals at: #GbsConnectorConnectionRegistry put: registry
]

{ #category : 'connector state' }
GbsSessionManager class >> setInvalidPostConnectActions: aCollection forConnectorClient: clientClassName server: serverClassName [
	| key registry values wrapper |
	key := (clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ]),
		'->',
		(serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ]).
	registry := (Smalltalk globals at: #GbsConnectorInvalidActionRegistry ifAbsent: [ Dictionary new ]) copy.
	values := ((aCollection ifNil: [ #() ]) collect: [ :each | each asString asLowercase ]) asArray.
	registry at: key put: values.
	Smalltalk globals at: #GbsConnectorInvalidActionRegistry put: registry.
	wrapper := self connectorObjectForClient: clientClassName server: serverClassName.
	(wrapper notNil and: [ wrapper respondsTo: #invalidPostConnectActions: ])
		ifTrue: [ wrapper invalidPostConnectActions: values ]
]

{ #category : 'connector state' }
GbsSessionManager class >> setPostConnectAction: actionString forConnectorClient: clientClassName server: serverClassName [
	| key registry normalized wrapper |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	normalized := actionString ifNil: [ 'none' ] ifNotNil: [ actionString asString ].
	registry := self postConnectActionRegistry copy.
	registry at: key put: normalized.
	Smalltalk globals at: #GbsConnectorPostConnectActionRegistry put: registry.
	wrapper := self connectorObjectForClient: clientClassName server: serverClassName.
	(wrapper notNil and: [ wrapper respondsTo: #postConnectAction: ])
		ifTrue: [ wrapper postConnectAction: normalized ].
	^ normalized
]

{ #category : 'actions' }
GbsSessionManager >> addConnectorClient: clientClassName server: serverClassName [
	^ self class addConnectorClient: clientClassName server: serverClassName
]

{ #category : 'connector state' }
GbsSessionManager >> clearConnectorClassForClient: clientClassName server: serverClassName [
	^ self class
		clearConnectorClassForClient: clientClassName
		server: serverClassName
]

{ #category : 'connector state' }
GbsSessionManager >> connectorClassChoices [
	^ self class connectorClassChoices
]

{ #category : 'connector state' }
GbsSessionManager >> connectorObjectForClient: clientClassName server: serverClassName [
	^ self class connectorObjectForClient: clientClassName server: serverClassName
]

{ #category : 'accessing' }
GbsSessionManager >> connectorPairs [
	^ self class connectorPairs
]

{ #category : 'connector groups' }
GbsSessionManager >> connectorPairsForGroup: aConnectorGroup [
	^ self class connectorPairsForGroup: aConnectorGroup
]

{ #category : 'accessing' }
GbsSessionManager >> fastConnectorRegistry [
    ^ fastConnectorRegistry
]

{ #category : 'accessing' }
GbsSessionManager >> fastConnectorRegistry: aDictionary [
    fastConnectorRegistry := aDictionary
]

{ #category : 'actions' }
GbsSessionManager >> generateClassConnectors [
	^ self class generateClassConnectors
]

{ #category : 'connector groups' }
GbsSessionManager >> globalConnectorGroup [
	^ self class globalConnectorGroup
]

{ #category : 'accessing' }
GbsSessionManager >> globalFastConnectorsList [
    ^ self class globalFastConnectorsList
]

{ #category : 'accessing' }
GbsSessionManager >> clientSpecificGlobalConnectorsList [
	^ self class clientSpecificGlobalConnectorsList
]

{ #category : 'accessing' }
GbsSessionManager >> exceptionConnectorsList [
	^ self class exceptionConnectorsList
]

{ #category : 'accessing' }
GbsSessionManager >> globalClassConnectorsList [
	^ self class globalClassConnectorsList
]

{ #category : 'accessing' }
GbsSessionManager >> allGlobalConnectorsList [
	^ self class allGlobalConnectorsList
]

{ #category : 'accessing' }
GbsSessionManager >> initializeFastConnectors [
    | registry |
    registry := Dictionary new.
    
    self globalFastConnectorsList do: [ :pair |
        | clientClassName serverClassName |
        clientClassName := pair first.
        serverClassName := pair second.
        
        "Map Client -> Server"
        registry at: clientClassName put: serverClassName.
        
        "Map Server -> Client"
        registry at: serverClassName put: clientClassName.
    ].

    self fastConnectorRegistry: registry.
]

{ #category : 'actions' }
GbsSessionManager >> initializeGlobalConnectors [
	^ self class initializeGlobalConnectors
]

{ #category : 'connector state' }
GbsSessionManager >> invalidPostConnectActionsForConnectorClient: clientClassName server: serverClassName [
	^ self class
		invalidPostConnectActionsForConnectorClient: clientClassName
		server: serverClassName
]

{ #category : 'connector state' }
GbsSessionManager >> isConnectorClient: clientClassName server: serverClassName connectedInSession: sessionKey [
	^ self class
		isConnectorClient: clientClassName
		server: serverClassName
		connectedInSession: sessionKey
]

{ #category : 'connector groups' }
GbsSessionManager >> knownParameters [
	^ self class knownParameters
]

{ #category : 'accessing' }
GbsSessionManager >> loggedInSessions [
	^ self class loggedInSessions
]

{ #category : 'connector state' }
GbsSessionManager >> postConnectActionForConnectorClient: clientClassName server: serverClassName [
	^ self class
		postConnectActionForConnectorClient: clientClassName
		server: serverClassName
]

{ #category : 'actions' }
GbsSessionManager >> removeConnectorClient: clientClassName server: serverClassName [
	^ self class removeConnectorClient: clientClassName server: serverClassName
]

{ #category : 'actions' }
GbsSessionManager >> removeInvalidConnectors [
	^ self class removeInvalidConnectors
]

{ #category : 'connector state' }
GbsSessionManager >> setConnectorClass: connectorClassOrName forClient: clientClassName server: serverClassName [
	^ self class
		setConnectorClass: connectorClassOrName
		forClient: clientClassName
		server: serverClassName
]

{ #category : 'connector state' }
GbsSessionManager >> setConnectorClient: clientClassName server: serverClassName connected: aBoolean inSession: sessionKey [
	^ self class
		setConnectorClient: clientClassName
		server: serverClassName
		connected: aBoolean
		inSession: sessionKey
]

{ #category : 'connector state' }
GbsSessionManager >> setPostConnectAction: actionString forConnectorClient: clientClassName server: serverClassName [
	^ self class
		setPostConnectAction: actionString
		forConnectorClient: clientClassName
		server: serverClassName
]
