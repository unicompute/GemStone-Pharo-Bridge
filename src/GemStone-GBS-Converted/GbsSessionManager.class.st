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

{ #category : 'typed wrappers' }
GbsSessionManager class >> clearAllTypedWrapperClasses [
	Smalltalk globals at: #GbsTypedWrapperRegistry put: Dictionary new
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> clearTypedWrapperClassForClient: clientClassName server: serverClassName [
	| key registry |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self typedWrapperRegistry copy.
	registry removeKey: key ifAbsent: [ ].
	Smalltalk globals at: #GbsTypedWrapperRegistry put: registry
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
	^ Smalltalk globals
		at: #GbsFastConnectorRegistry
		ifAbsentPut: [ self newFastConnectorRegistry ]
]

{ #category : 'accessing' }
GbsSessionManager class >> fastConnectorRegistry: aDictionary [
	Smalltalk globals at: #GbsFastConnectorRegistry put: aDictionary
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperAutoloadPairs [
	^ self typedWrapperAutoloadPairsForSession: GbsSessionParameters currentSession
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperAutoloadPairsForSession: aSession [
	^ self
		typedWrapperAutoloadPairsFromRegistry: (self typedWrapperAutoloadRegistryForSession: aSession)
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperAutoloadEntries [
	^ self typedWrapperAutoloadEntriesForSession: GbsSessionParameters currentSession
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperAutoloadEntriesForSession: aSession [
	| sessionKey |
	sessionKey := self sessionKeyForSessionObject: aSession.
	^ ((self
		typedWrapperAutoloadEntriesFromRegistry: self fastConnectorRegistry
		scope: 'global'
		source: 'connector')
		, (self
			typedWrapperAutoloadEntriesFromPairs: self typedWrapperExplicitAutoloadPairRegistry
			scope: 'global'
			source: 'explicit')
		, (self
			typedWrapperAutoloadEntriesFromRegistry:
				(self sessionConnectorRegistry at: sessionKey ifAbsent: [ Dictionary new ])
			scope: 'session'
			source: 'connector')
		, (self
			typedWrapperAutoloadEntriesFromPairs:
				(self sessionTypedWrapperExplicitAutoloadPairRegistry at: sessionKey ifAbsent: [ #() ])
			scope: 'session'
			source: 'explicit')) asArray
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperAutoloadPairsFromRegistry: aRegistry [
	| pairs seen |
	(aRegistry isNil or: [ aRegistry isEmpty ]) ifTrue: [ ^ #() ].
	pairs := OrderedCollection new.
	seen := Set new.
	aRegistry keysAndValuesDo: [ :clientName :serverName |
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

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperAutoloadEntriesFromRegistry: aRegistry scope: aScope source: aSource [
	| entries seen |
	(aRegistry isNil or: [ aRegistry isEmpty ]) ifTrue: [ ^ #() ].
	entries := OrderedCollection new.
	seen := Set new.
	aRegistry keysAndValuesDo: [ :clientName :serverName |
		| c s pairKey inverseKey |
		c := clientName asString.
		s := serverName asString.
		pairKey := c, '->', s.
		inverseKey := s, '->', c.
		((seen includes: pairKey) or: [ seen includes: inverseKey ]) ifFalse: [
			entries add: { c. s. aScope. aSource }.
			seen add: pairKey ] ].
	^ entries asArray
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperAutoloadEntriesFromPairs: aCollection scope: aScope source: aSource [
	| entries |
	(aCollection isNil or: [ aCollection isEmpty ]) ifTrue: [ ^ #() ].
	entries := OrderedCollection new.
	aCollection do: [ :pair |
		| clientName serverName |
		clientName := pair first asString.
		serverName := pair second asString.
		entries add: { clientName. serverName. aScope. aSource } ].
	^ entries asArray
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperAutoloadRegistryForSession: aSession [
	| merged sessionKey sessionRegistry |
	merged := self fastConnectorRegistry copy.
	self
		mergeBidirectionalRegistry: self typedWrapperExplicitAutoloadRegistry
		into: merged.
	sessionKey := self sessionKeyForSessionObject: aSession.
	sessionRegistry := self sessionConnectorRegistry at: sessionKey ifAbsent: [ Dictionary new ].
	self mergeBidirectionalRegistry: sessionRegistry into: merged.
	self
		mergeBidirectionalRegistry:
			(self sessionTypedWrapperExplicitAutoloadRegistry
				at: sessionKey
				ifAbsent: [ Dictionary new ])
		into: merged.
	^ merged
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> mergeBidirectionalRegistry: sourceRegistry into: destinationRegistry [
	(sourceRegistry isNil or: [ sourceRegistry isEmpty ]) ifTrue: [ ^ destinationRegistry ].
	sourceRegistry keysAndValuesDo: [ :clientName :serverName |
		destinationRegistry
			at: clientName asString put: serverName asString;
			at: serverName asString put: clientName asString ].
	^ destinationRegistry
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperAutoloadReportText [
	^ self typedWrapperAutoloadReportTextForSession: GbsSessionParameters currentSession
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperAutoloadReportTextForSession: aSession [
	| pairs entries generatedEntries |
	pairs := self typedWrapperAutoloadPairsForSession: aSession.
	entries := self typedWrapperAutoloadEntriesForSession: aSession.
	generatedEntries := self typedWrapperRegistryEntries.
	((pairs isEmpty)
		and: [ entries isEmpty
		and: [ generatedEntries isEmpty ] ]) ifTrue: [
		^ 'No typed-wrapper autoload registrations.' ].
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Typed Wrapper Autoload'; cr; cr.
		stream nextPutAll: 'Autoload Registrations'; cr.
		entries isEmpty
			ifTrue: [ stream nextPutAll: '<none>'; cr ]
			ifFalse: [
				entries do: [ :entry |
					stream
						nextPutAll: (entry at: 1), ' -> ', (entry at: 2);
						tab;
						nextPutAll: (entry at: 3);
						tab;
						nextPutAll: (entry at: 4);
						cr ] ].
		stream cr.
		stream nextPutAll: 'Effective Pairs'; cr.
		pairs isEmpty
			ifTrue: [ stream nextPutAll: '<none>'; cr ]
			ifFalse: [
				pairs do: [ :pair |
					stream
						nextPutAll: (pair at: 1), ' -> ', (pair at: 2);
						cr ] ].
		stream cr.
		stream nextPutAll: 'Generated Wrappers'; cr.
		generatedEntries isEmpty
			ifTrue: [ stream nextPutAll: '<none>' ]
			ifFalse: [
				generatedEntries do: [ :row |
					stream
						nextPutAll: (row at: 1), ' -> ', (row at: 2);
						tab;
						nextPutAll: (row at: 3);
						tab;
						nextPutAll: (row at: 4);
						tab;
						nextPutAll: ((row at: 5) ifTrue: [ 'autoload' ] ifFalse: [ 'manual' ]);
						cr ] ] ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperExplicitAutoloadRegistry [
	^ Smalltalk globals
		at: #GbsTypedWrapperAutoloadRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperExplicitAutoloadRegistry: aDictionary [
	Smalltalk globals
		at: #GbsTypedWrapperAutoloadRegistry
		put: (aDictionary ifNil: [ Dictionary new ])
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> sessionTypedWrapperExplicitAutoloadRegistry [
	^ Smalltalk globals
		at: #GbsSessionTypedWrapperAutoloadRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperExplicitAutoloadPairRegistry [
	^ Smalltalk globals
		at: #GbsTypedWrapperAutoloadPairRegistry
		ifAbsentPut: [ OrderedCollection new ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperExplicitAutoloadPairRegistry: aCollection [
	Smalltalk globals
		at: #GbsTypedWrapperAutoloadPairRegistry
		put: (aCollection ifNil: [ OrderedCollection new ])
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> sessionTypedWrapperExplicitAutoloadPairRegistry [
	^ Smalltalk globals
		at: #GbsSessionTypedWrapperAutoloadPairRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperRegistryEntries [
	| autoloadRegistry entries |
	autoloadRegistry := self typedWrapperAutoloadRegistryForSession: GbsSessionParameters currentSession.
	entries := self typedWrapperRegistry values asSet collect: [ :wrapperClass |
		| clientName serverName source eligible |
		clientName := (wrapperClass respondsTo: #clientBehaviorName)
			ifTrue: [ wrapperClass clientBehaviorName ]
			ifFalse: [ '' ].
		serverName := (wrapperClass respondsTo: #serverBehaviorName)
			ifTrue: [ wrapperClass serverBehaviorName ]
			ifFalse: [ '' ].
		source := (wrapperClass respondsTo: #generatedForwardingSource)
			ifTrue: [ wrapperClass generatedForwardingSource asString ]
			ifFalse: [ 'unknown' ].
		eligible := self
			shouldAutoloadTypedWrapperForClient: clientName
			server: serverName
			usingRegistry: autoloadRegistry.
		{ clientName. serverName. wrapperClass name asString. source. eligible } ].
	^ entries asArray sort: [ :a :b |
		(a first = b first)
			ifTrue: [ a second <= b second ]
			ifFalse: [ a first <= b first ] ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperClasses [
	^ self typedWrapperRegistry values asSet asArray
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperClassesForServerClassNamed: serverClassName [
	| serverName |
	serverName := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	^ self typedWrapperClasses select: [ :each |
		(each respondsTo: #serverBehaviorName)
			and: [ each serverBehaviorName = serverName ] ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperLifecycleEntries [
	^ self typedWrapperLifecycleEntriesForSession: GbsSessionParameters currentSession
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperLifecycleEntriesForSession: aSession [
	^ (self typedWrapperLifecycleObjectsForSession: aSession collect: [ :each |
		{
			each clientName.
			each serverName.
			each wrapperName.
			each source.
			each localVersion.
			each localNumberOfVersions.
			each remoteVersion.
			each remoteNumberOfVersions.
			each status asString
		} ]) asArray sort: [ :a :b |
			(a first = b first)
				ifTrue: [ a second <= b second ]
				ifFalse: [ a first <= b first ] ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperLifecycleReportText [
	^ self typedWrapperLifecycleReportTextForSession: GbsSessionParameters currentSession
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperLifecycleReportTextForSession: aSession [
	^ (self typedWrapperLifecycleReportForSession: aSession) text
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperLifecycleObjectsForSession: aSession [
	^ (self typedWrapperClasses collect: [ :wrapperClass |
		| remoteMirror status |
		remoteMirror := self
			typedWrapperRemoteMirrorFor: wrapperClass
			session: aSession.
		status := self
			typedWrapperLifecycleStatusFor: wrapperClass
			session: aSession.
		GbsTypedWrapperLifecycleEntry
			wrapperClass: wrapperClass
			clientName: ((wrapperClass respondsTo: #clientBehaviorName)
				ifTrue: [ wrapperClass clientBehaviorName ]
				ifFalse: [ '' ])
			serverName: ((wrapperClass respondsTo: #serverBehaviorName)
				ifTrue: [ wrapperClass serverBehaviorName ]
				ifFalse: [ '' ])
			source: ((wrapperClass respondsTo: #generatedForwardingSource)
				ifTrue: [ wrapperClass generatedForwardingSource asString ]
				ifFalse: [ 'unknown' ])
			localVersion: ((wrapperClass respondsTo: #serverBehaviorVersion)
				ifTrue: [ wrapperClass serverBehaviorVersion ]
				ifFalse: [ nil ])
			localNumberOfVersions: ((wrapperClass respondsTo: #serverBehaviorNumberOfVersions)
				ifTrue: [ wrapperClass serverBehaviorNumberOfVersions ]
				ifFalse: [ nil ])
			remoteVersion: (remoteMirror ifNil: [ nil ] ifNotNil: [ remoteMirror version ])
			remoteNumberOfVersions: (remoteMirror ifNil: [ nil ] ifNotNil: [ remoteMirror numberOfVersions ])
			status: status ]) asArray sort: [ :a :b |
				(a clientName = b clientName)
					ifTrue: [ a serverName <= b serverName ]
					ifFalse: [ a clientName <= b clientName ] ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperLifecycleReport [
	^ self typedWrapperLifecycleReportForSession: GbsSessionParameters currentSession
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperLifecycleReportForSession: aSession [
	^ GbsTypedWrapperLifecycleReport
		entries: (self typedWrapperLifecycleObjectsForSession: aSession)
]

{ #category : 'actions' }
GbsSessionManager class >> generateClassConnectors [
	^ self initializeFastConnectors
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> generateTypedWrapperForClient: clientClassName server: serverClassName [
	| clientName serverName wrapperClass |
	clientName := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	serverName := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	(clientName isEmpty or: [ serverName isEmpty ]) ifTrue: [ ^ nil ].
	wrapperClass := GbsTypedWrapperBuilder
		generateWrapperForClient: clientName
		server: serverName
		session: GbsSessionParameters currentSession.
	self
		setTypedWrapperClass: wrapperClass
		forClient: clientName
		server: serverName.
	^ wrapperClass
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> generateTypedWrappersForConnectorPairs [
	^ self connectorPairs collect: [ :pair |
		self
			generateTypedWrapperForClient: (pair at: 1 ifAbsent: [ '' ])
			server: (pair at: 2 ifAbsent: [ '' ]) ]
]

{ #category : 'connector groups' }
GbsSessionManager class >> globalConnectorGroup [
	^ GbsConnectorGroup globalOnManagerClass: self
]

{ #category : 'as yet unclassified' }
GbsSessionManager class >> globalFastConnectorsList [
    "Returns a list of pairs: #(PharoClassName GemStoneClassName).
     These classes are replicated by value instead of passed by reference (proxy)."
    
    ^ #(
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

{ #category : 'initialization' }
GbsSessionManager class >> initializeFastConnectors [
	"Initialize the global registry of classes that should be passed by value."

	| registry |
	registry := self newFastConnectorRegistry.
	self fastConnectorRegistry: registry.
	self rebuildConnectorObjectRegistry.
	^ registry
]

{ #category : 'accessing' }
GbsSessionManager class >> newFastConnectorRegistry [
	| registry |
	registry := Dictionary new.
	self globalFastConnectorsList do: [ :pair |
		| clientClass serverClassName |
		clientClass := Smalltalk globals at: pair first ifAbsent: [ nil ].
		serverClassName := pair second.
		clientClass ifNotNil: [
			registry at: clientClass name put: serverClassName.
			registry at: serverClassName put: clientClass name ] ].
	^ registry
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> setTypedWrapperClass: wrapperClass forClient: clientClassName server: serverClassName [
	| key registry |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self typedWrapperRegistry copy.
	registry at: key put: wrapperClass.
	Smalltalk globals at: #GbsTypedWrapperRegistry put: registry.
	^ wrapperClass
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
	Smalltalk globals at: #GbsSessionConnectorRegistry put: Dictionary new.
	Smalltalk globals at: #GbsTypedWrapperRegistry put: Dictionary new
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
	self clearTypedWrapperClassForClient: c server: s.
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
	self clearTypedWrapperClassForClient: c server: s.
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

{ #category : 'typed wrappers' }
GbsSessionManager class >> registerTypedWrapperAutoloadClient: clientClassName server: serverClassName [
	| c s registry pairs |
	c := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	s := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	(c isEmpty or: [ s isEmpty ]) ifTrue: [ ^ self ].
	registry := self typedWrapperExplicitAutoloadRegistry copy.
	registry
		at: c put: s;
		at: s put: c.
	self typedWrapperExplicitAutoloadRegistry: registry.
	pairs := self typedWrapperExplicitAutoloadPairRegistry copy.
	(pairs anySatisfy: [ :pair | pair first = c and: [ pair second = s ] ])
		ifFalse: [ pairs add: { c. s } ].
	self typedWrapperExplicitAutoloadPairRegistry: pairs.
	^ { c. s }
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> registerTypedWrapperAutoloadClient: clientClassName server: serverClassName forSession: aSession [
	| c s registry sessionKey sessionRegistry pairRegistry pairs |
	c := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	s := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	(c isEmpty or: [ s isEmpty ]) ifTrue: [ ^ self ].
	sessionKey := self sessionKeyForSessionObject: aSession.
	registry := self sessionTypedWrapperExplicitAutoloadRegistry copy.
	sessionRegistry := (registry at: sessionKey ifAbsent: [ Dictionary new ]) copy.
	sessionRegistry
		at: c put: s;
		at: s put: c.
	registry at: sessionKey put: sessionRegistry.
	Smalltalk globals at: #GbsSessionTypedWrapperAutoloadRegistry put: registry.
	pairRegistry := self sessionTypedWrapperExplicitAutoloadPairRegistry copy.
	pairs := (pairRegistry at: sessionKey ifAbsent: [ OrderedCollection new ]) copy.
	(pairs anySatisfy: [ :pair | pair first = c and: [ pair second = s ] ])
		ifFalse: [ pairs add: { c. s } ].
	pairRegistry at: sessionKey put: pairs.
	Smalltalk globals at: #GbsSessionTypedWrapperAutoloadPairRegistry put: pairRegistry.
	^ { c. s }
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> unregisterTypedWrapperAutoloadClient: clientClassName server: serverClassName [
	| c s registry pairs |
	c := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	s := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	registry := self typedWrapperExplicitAutoloadRegistry copy.
	registry
		removeKey: c ifAbsent: [ ];
		removeKey: s ifAbsent: [ ].
	self typedWrapperExplicitAutoloadRegistry: registry.
	pairs := self typedWrapperExplicitAutoloadPairRegistry copy.
	pairs removeAllSuchThat: [ :pair |
		(pair first = c and: [ pair second = s ])
			or: [ pair first = s and: [ pair second = c ] ] ].
	self typedWrapperExplicitAutoloadPairRegistry: pairs.
	^ self
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> unregisterTypedWrapperAutoloadClient: clientClassName server: serverClassName forSession: aSession [
	| c s registry sessionKey sessionRegistry pairRegistry pairs |
	c := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	s := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	sessionKey := self sessionKeyForSessionObject: aSession.
	registry := self sessionTypedWrapperExplicitAutoloadRegistry copy.
	sessionRegistry := (registry at: sessionKey ifAbsent: [ Dictionary new ]) copy.
	sessionRegistry
		removeKey: c ifAbsent: [ ];
		removeKey: s ifAbsent: [ ].
	registry at: sessionKey put: sessionRegistry.
	Smalltalk globals at: #GbsSessionTypedWrapperAutoloadRegistry put: registry.
	pairRegistry := self sessionTypedWrapperExplicitAutoloadPairRegistry copy.
	pairs := (pairRegistry at: sessionKey ifAbsent: [ OrderedCollection new ]) copy.
	pairs removeAllSuchThat: [ :pair |
		(pair first = c and: [ pair second = s ])
			or: [ pair first = s and: [ pair second = c ] ] ].
	pairRegistry at: sessionKey put: pairs.
	Smalltalk globals at: #GbsSessionTypedWrapperAutoloadPairRegistry put: pairRegistry.
	^ self
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> clearTypedWrapperAutoloadRegistrations [
	self typedWrapperExplicitAutoloadRegistry: Dictionary new.
	self typedWrapperExplicitAutoloadPairRegistry: OrderedCollection new.
	^ self
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> clearTypedWrapperAutoloadRegistrationsForSession: aSession [
	| registry pairRegistry sessionKey |
	sessionKey := self sessionKeyForSessionObject: aSession.
	registry := self sessionTypedWrapperExplicitAutoloadRegistry copy.
	registry removeKey: sessionKey ifAbsent: [ ].
	Smalltalk globals at: #GbsSessionTypedWrapperAutoloadRegistry put: registry.
	pairRegistry := self sessionTypedWrapperExplicitAutoloadPairRegistry copy.
	pairRegistry removeKey: sessionKey ifAbsent: [ ].
	Smalltalk globals at: #GbsSessionTypedWrapperAutoloadPairRegistry put: pairRegistry.
	^ self
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperClassForClient: clientClassName server: serverClassName [
	| key registry wrapperClass className |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self typedWrapperRegistry.
	wrapperClass := registry at: key ifAbsent: [ nil ].
	(wrapperClass notNil and: [ wrapperClass inheritsFrom: GbsTypedProxy ])
		ifTrue: [
			(self shouldRefreshTypedWrapperClass: wrapperClass server: serverClassName)
				ifTrue: [
					^ self
						generateTypedWrapperForClient: clientClassName
						server: serverClassName ].
			^ wrapperClass ].
	className := GbsTypedWrapperBuilder
		wrapperClassNameForClient: clientClassName
		server: serverClassName.
	wrapperClass := Smalltalk globals at: className ifAbsent: [ nil ].
	(wrapperClass notNil and: [ wrapperClass inheritsFrom: GbsTypedProxy ])
		ifTrue: [
			self
				setTypedWrapperClass: wrapperClass
				forClient: clientClassName
				server: serverClassName.
			(self shouldRefreshTypedWrapperClass: wrapperClass server: serverClassName)
				ifTrue: [
					^ self
						generateTypedWrapperForClient: clientClassName
						server: serverClassName ].
			^ wrapperClass ].
	(self shouldAutoloadTypedWrapperForClient: clientClassName server: serverClassName)
		ifTrue: [
			^ self
				generateTypedWrapperForClient: clientClassName
				server: serverClassName ].
	^ nil
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperClassForClient: clientClassName server: serverClassName ifAbsentGenerate: aBlock [
	| wrapperClass |
	wrapperClass := self
		typedWrapperClassForClient: clientClassName
		server: serverClassName.
	wrapperClass ifNil: [ ^ aBlock value ].
	^ wrapperClass
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperClassForServerClassNamed: serverClassName [
	| serverName clientName wrapperClass registry |
	serverName := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	serverName isEmpty ifTrue: [ ^ nil ].
	wrapperClass := self typedWrapperRegistry values
		detect: [ :each |
			(each respondsTo: #serverBehaviorName)
				and: [ each serverBehaviorName = serverName ] ]
		ifNone: [ nil ].
	wrapperClass ifNotNil: [
		(self shouldRefreshTypedWrapperClass: wrapperClass server: serverName)
			ifTrue: [
				^ self
				generateTypedWrapperForClient: wrapperClass clientBehaviorName
						server: serverName ].
			^ wrapperClass ].
	registry := self typedWrapperAutoloadRegistryForSession: GbsSessionParameters currentSession.
	clientName := registry at: serverName ifAbsent: [ nil ].
	clientName ifNil: [ ^ nil ].
	^ self
		typedWrapperClassForClient: clientName
		server: serverName
		ifAbsentGenerate: [ self generateTypedWrapperForClient: clientName server: serverName ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> shouldAutoloadTypedWrapperForClient: clientClassName server: serverClassName [
	^ self
		shouldAutoloadTypedWrapperForClient: clientClassName
		server: serverClassName
		usingRegistry: (self typedWrapperAutoloadRegistryForSession: GbsSessionParameters currentSession)
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> shouldAutoloadTypedWrapperForClient: clientClassName server: serverClassName usingRegistry: registry [
	| clientName serverName |
	clientName := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	serverName := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	(clientName isEmpty or: [ serverName isEmpty ]) ifTrue: [ ^ false ].
	^ ((registry at: clientName ifAbsent: [ nil ]) = serverName)
		or: [ (registry at: serverName ifAbsent: [ nil ]) = clientName ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> shouldRefreshTypedWrapperClass: wrapperClass server: serverClassName [
	^ self
		shouldRefreshTypedWrapperClass: wrapperClass
		server: serverClassName
		session: GbsSessionParameters currentSession
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> shouldRefreshTypedWrapperClass: wrapperClass server: serverClassName session: aSession [
	| remoteMirror |
	aSession ifNil: [ ^ false ].
	(wrapperClass respondsTo: #generatedForwardingSource) ifFalse: [ ^ false ].
	wrapperClass generatedForwardingSource ~= #remote ifTrue: [ ^ true ].
	remoteMirror := [ aSession classMirrorOfNamed: serverClassName ]
		on: Error
		do: [ nil ].
	remoteMirror ifNil: [ ^ false ].
	^ (wrapperClass respondsTo: #serverBehaviorVersion)
		and: [ (wrapperClass serverBehaviorVersion ~= remoteMirror version)
		or: [ (wrapperClass respondsTo: #serverBehaviorNumberOfVersions)
		and: [ wrapperClass serverBehaviorNumberOfVersions ~= remoteMirror numberOfVersions ] ] ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> staleTypedWrapperClassesForSession: aSession [
	^ self typedWrapperClasses select: [ :each |
		| serverName |
		serverName := (each respondsTo: #serverBehaviorName)
			ifTrue: [ each serverBehaviorName ]
			ifFalse: [ '' ].
		self
			shouldRefreshTypedWrapperClass: each
			server: serverName
			session: aSession ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> invalidateTypedWrapperClass: wrapperClass [
	(wrapperClass respondsTo: #generatedForwardingSource) ifFalse: [ ^ wrapperClass ].
	wrapperClass class
		compile: 'serverBehaviorVersion
	^ nil'
		classified: 'generated metadata'.
	wrapperClass class
		compile: 'serverBehaviorNumberOfVersions
	^ nil'
		classified: 'generated metadata'.
	^ wrapperClass
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> invalidateTypedWrapperClassesForServerClassNamed: serverClassName [
	| wrappers |
	wrappers := self typedWrapperClassesForServerClassNamed: serverClassName.
	wrappers do: [ :each | self invalidateTypedWrapperClass: each ].
	^ wrappers
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> invalidateStaleTypedWrapperClassesForSession: aSession [
	| wrappers |
	wrappers := self staleTypedWrapperClassesForSession: aSession.
	wrappers do: [ :each | self invalidateTypedWrapperClass: each ].
	^ wrappers
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> refreshStaleTypedWrapperClassesForSession: aSession [
	| wrappers previousSession refreshed |
	wrappers := self staleTypedWrapperClassesForSession: aSession.
	previousSession := GbsSessionParameters currentSession.
	[ GbsSessionParameters currentSession: aSession.
	refreshed := wrappers collect: [ :each |
		self
			generateTypedWrapperForClient: each clientBehaviorName
			server: each serverBehaviorName ] ]
		ensure: [ GbsSessionParameters currentSession: previousSession ].
	^ refreshed ifNil: [ #() ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> refreshAllTypedWrapperClassesForSession: aSession [
	| wrappers previousSession refreshed |
	wrappers := self typedWrapperClasses
		select: [ :each | (each respondsTo: #serverBehaviorName) and: [ each respondsTo: #clientBehaviorName ] ].
	previousSession := GbsSessionParameters currentSession.
	[ GbsSessionParameters currentSession: aSession.
	refreshed := wrappers collect: [ :each |
		self
			generateTypedWrapperForClient: each clientBehaviorName
			server: each serverBehaviorName ] ]
		ensure: [ GbsSessionParameters currentSession: previousSession ].
	^ refreshed ifNil: [ #() ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperLifecycleStatusFor: wrapperClass session: aSession [
	| remoteMirror |
	(wrapperClass respondsTo: #generatedForwardingSource) ifFalse: [ ^ #unknown ].
	wrapperClass generatedForwardingSource ~= #remote ifTrue: [ ^ #clientGenerated ].
	remoteMirror := self
		typedWrapperRemoteMirrorFor: wrapperClass
		session: aSession.
	remoteMirror ifNil: [ ^ #missingRemote ].
	^ (self
		shouldRefreshTypedWrapperClass: wrapperClass
		server: wrapperClass serverBehaviorName
		session: aSession)
			ifTrue: [ #stale ]
			ifFalse: [ #current ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperRemoteMirrorFor: wrapperClass session: aSession [
	| serverName |
	aSession ifNil: [ ^ nil ].
	serverName := (wrapperClass respondsTo: #serverBehaviorName)
		ifTrue: [ wrapperClass serverBehaviorName ]
		ifFalse: [ nil ].
	serverName ifNil: [ ^ nil ].
	^ [ aSession classMirrorOfNamed: serverName ]
		on: Error
		do: [ nil ]
]

{ #category : 'typed wrappers' }
GbsSessionManager class >> typedWrapperRegistry [
	^ Smalltalk globals
		at: #GbsTypedWrapperRegistry
		ifAbsentPut: [ Dictionary new ]
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
