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

{ #category : 'as yet unclassified' }
GbsSessionManager class >> globalFastConnectorsList [
    "Returns a list of pairs: #(PharoClassName GemStoneClassName).
     These classes are replicated by value instead of passed by reference (proxy)."
    
    ^ #(
        "Collections"
        #(Array Array)
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

{ #category : 'connector groups' }
GbsSessionManager class >> globalConnectorGroup [
	^ GbsConnectorGroup globalOnManagerClass: self
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

{ #category : 'initialization' }
GbsSessionManager class >> initializeFastConnectors [
    "Initialize the global registry of classes that should be passed by value."
    
    | registry |
    registry := Dictionary new.
    
    self globalFastConnectorsList do: [ :pair |
        | clientClass serverClassName |
        clientClass := Smalltalk globals at: pair first ifAbsent: [ nil ].
        serverClassName := pair second.
        
        clientClass ifNotNil: [
            "Map both directions: Client -> Server, and Server -> Client"
            registry at: clientClass name put: serverClassName.
            registry at: serverClassName put: clientClass name.
        ].
    ].

    "Store this in your session manager's class instance variable"
	self fastConnectorRegistry: registry.
	self rebuildConnectorObjectRegistry
]

{ #category : 'actions' }
GbsSessionManager class >> initializeGlobalConnectors [
	"VAST parity entrypoint for connector window Group->Initialize"
	^ self initializeFastConnectors
]

{ #category : 'actions' }
GbsSessionManager class >> generateClassConnectors [
	^ self initializeFastConnectors
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
GbsSessionManager class >> connectorPairs [
	| registry pairs seen |
	registry := self fastConnectorRegistry.
	(registry isNil or: [ registry isEmpty ]) ifTrue: [
		self initializeFastConnectors.
		registry := self fastConnectorRegistry ].
	pairs := OrderedCollection new.
	seen := Set new.
	registry keysAndValuesDo: [ :clientName :serverName |
		| c s pairKey inverseKey |
		c := clientName asString.
		s := serverName asString.
		pairKey := c, '->', s.
		inverseKey := s, '->', c.
		((seen includes: pairKey) or: [ seen includes: inverseKey ]) ifFalse: [
			pairs add: { c. s }.
			seen add: pairKey ] ].
	^ pairs asArray
]

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

{ #category : 'accessing' }
GbsSessionManager class >> fastConnectorRegistry [
	^ Smalltalk globals at: #GbsFastConnectorRegistry ifAbsent: [ Dictionary new ]
]

{ #category : 'accessing' }
GbsSessionManager class >> fastConnectorRegistry: aDictionary [
	Smalltalk globals at: #GbsFastConnectorRegistry put: aDictionary
]

{ #category : 'accessing' }
GbsSessionManager class >> sessionConnectorRegistry [
	^ Smalltalk globals at: #GbsSessionConnectorRegistry ifAbsent: [ Dictionary new ]
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorConnectionRegistry [
	^ Smalltalk globals
		at: #GbsConnectorConnectionRegistry
		ifAbsentPut: [ Dictionary new ]
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
GbsSessionManager class >> postConnectActionRegistry [
	^ Smalltalk globals
		at: #GbsConnectorPostConnectActionRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'connector state' }
GbsSessionManager class >> postConnectActionForConnectorClient: clientClassName server: serverClassName [
	| key registry |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self postConnectActionRegistry.
	^ registry at: key ifAbsent: [ 'none' ]
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

{ #category : 'connector state' }
GbsSessionManager class >> clearPostConnectActionForConnectorClient: clientClassName server: serverClassName [
	| key registry |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self postConnectActionRegistry copy.
	registry removeKey: key ifAbsent: [ ].
	Smalltalk globals at: #GbsConnectorPostConnectActionRegistry put: registry
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorObjectForClient: clientClassName server: serverClassName [
	| registry key |
	registry := self connectorObjectRegistry.
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	^ registry at: key ifAbsent: [ self ensureConnectorObjectForClient: clientClassName server: serverClassName ]
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
GbsSessionManager class >> connectorClassMappingRegistry [
	^ Smalltalk globals
		at: #GbsConnectorClassMappingRegistry
		ifAbsentPut: [ Dictionary new ]
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
GbsSessionManager class >> setConnectorClass: connectorClassOrName forClient: clientClassName server: serverClassName [
	| key registry |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self connectorClassMappingRegistry copy.
	registry at: key put: connectorClassOrName.
	Smalltalk globals at: #GbsConnectorClassMappingRegistry put: registry.
	self removeConnectorObjectForClient: clientClassName server: serverClassName
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
GbsSessionManager class >> clearAllConnectorClassMappings [
	Smalltalk globals at: #GbsConnectorClassMappingRegistry put: Dictionary new.
	self rebuildConnectorObjectRegistry
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

{ #category : 'accessing' }
GbsSessionManager class >> loggedInSessions [
	| current |
	current := GbsSessionParameters currentSession.
	current ifNil: [ ^ #() ].
	^ { current }
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
	| sessionKey registry pairs seen |
	sessionKey := self sessionKeyForSessionObject: aSession.
	registry := self sessionConnectorRegistry at: sessionKey ifAbsent: [ Dictionary new ].
	pairs := OrderedCollection new.
	seen := Set new.
	registry keysAndValuesDo: [ :clientName :serverName |
		| c s pairKey inverseKey |
		c := clientName asString.
		s := serverName asString.
		pairKey := c, '->', s.
		inverseKey := s, '->', c.
		((seen includes: pairKey) or: [ seen includes: inverseKey ]) ifFalse: [
			pairs add: { c. s }.
			seen add: pairKey ] ].
	^ pairs asArray
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
	params ifNil: [ ^ 'default' ].
	user := [ params username ] on: Error do: [ nil ].
	stone := [ params gemStoneName ] on: Error do: [ nil ].
	^ (user ifNil: [ 'unknown-user' ] ifNotNil: [ user asString ]),
		'@',
		(stone ifNil: [ 'unknown-stone' ] ifNotNil: [ stone asString ])
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorObjectRegistry [
	^ Smalltalk globals
		at: #GbsConnectorObjectRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'connector state' }
GbsSessionManager class >> connectorObjectKeyForClient: clientClassName server: serverClassName [
	^ (clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ]),
		'->',
		(serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ])
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

{ #category : 'connector state' }
GbsSessionManager class >> removeConnectorObjectForClient: clientClassName server: serverClassName [
	| registry key |
	registry := self connectorObjectRegistry copy.
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry removeKey: key ifAbsent: [ ].
	Smalltalk globals at: #GbsConnectorObjectRegistry put: registry
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

{ #category : 'accessing' }
GbsSessionManager >> fastConnectorRegistry [
    ^ fastConnectorRegistry
]

{ #category : 'accessing' }
GbsSessionManager >> fastConnectorRegistry: aDictionary [
    fastConnectorRegistry := aDictionary
]

{ #category : 'accessing' }
GbsSessionManager >> globalFastConnectorsList [
    ^ #(
        #(Array Array)
        #(ByteString String)
        #(DateAndTime DateTime)
    )
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
