Extension { #name : 'GbsSessionManager' }

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> clearAllTypedWrapperClasses [
	Smalltalk globals at: #GbsTypedWrapperRegistry put: Dictionary new
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> clearTypedWrapperClassForClient: clientClassName server: serverClassName [
	| key registry |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self typedWrapperRegistry copy.
	registry removeKey: key ifAbsent: [ ].
	Smalltalk globals at: #GbsTypedWrapperRegistry put: registry
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> fastConnectorRegistry [
	^ Smalltalk globals
		at: #GbsFastConnectorRegistry
		ifAbsentPut: [ self newFastConnectorRegistry ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperAutoloadPairs [
	^ self typedWrapperAutoloadPairsForSession: GbsSessionParameters currentSession
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperAutoloadPairsForSession: aSession [
	^ self
		typedWrapperAutoloadPairsFromRegistry: (self typedWrapperAutoloadRegistryForSession: aSession)
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperAutoloadEntries [
	^ self typedWrapperAutoloadEntriesForSession: GbsSessionParameters currentSession
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> mergeBidirectionalRegistry: sourceRegistry into: destinationRegistry [
	(sourceRegistry isNil or: [ sourceRegistry isEmpty ]) ifTrue: [ ^ destinationRegistry ].
	sourceRegistry keysAndValuesDo: [ :clientName :serverName |
		destinationRegistry
			at: clientName asString put: serverName asString;
			at: serverName asString put: clientName asString ].
	^ destinationRegistry
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperAutoloadReportText [
	^ self typedWrapperAutoloadReportTextForSession: GbsSessionParameters currentSession
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperExplicitAutoloadRegistry [
	^ Smalltalk globals
		at: #GbsTypedWrapperAutoloadRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperExplicitAutoloadRegistry: aDictionary [
	Smalltalk globals
		at: #GbsTypedWrapperAutoloadRegistry
		put: (aDictionary ifNil: [ Dictionary new ])
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> sessionTypedWrapperExplicitAutoloadRegistry [
	^ Smalltalk globals
		at: #GbsSessionTypedWrapperAutoloadRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperExplicitAutoloadPairRegistry [
	^ Smalltalk globals
		at: #GbsTypedWrapperAutoloadPairRegistry
		ifAbsentPut: [ OrderedCollection new ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperExplicitAutoloadPairRegistry: aCollection [
	Smalltalk globals
		at: #GbsTypedWrapperAutoloadPairRegistry
		put: (aCollection ifNil: [ OrderedCollection new ])
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> sessionTypedWrapperExplicitAutoloadPairRegistry [
	^ Smalltalk globals
		at: #GbsSessionTypedWrapperAutoloadPairRegistry
		ifAbsentPut: [ Dictionary new ]
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperClasses [
	^ self typedWrapperRegistry values asSet asArray
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperClassesForServerClassNamed: serverClassName [
	| serverName |
	serverName := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	^ self typedWrapperClasses select: [ :each |
		(each respondsTo: #serverBehaviorName)
			and: [ each serverBehaviorName = serverName ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperLifecycleEntries [
	^ self typedWrapperLifecycleEntriesForSession: GbsSessionParameters currentSession
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperLifecycleReportText [
	^ self typedWrapperLifecycleReportTextForSession: GbsSessionParameters currentSession
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperLifecycleReportTextForSession: aSession [
	^ (self typedWrapperLifecycleReportForSession: aSession) text
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperLifecycleReport [
	^ self typedWrapperLifecycleReportForSession: GbsSessionParameters currentSession
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperLifecycleReportForSession: aSession [
	^ GbsTypedWrapperLifecycleReport
		entries: (self typedWrapperLifecycleObjectsForSession: aSession)
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> generateTypedWrappersForConnectorPairs [
	^ self connectorPairs collect: [ :pair |
		self
			generateTypedWrapperForClient: (pair at: 1 ifAbsent: [ '' ])
			server: (pair at: 2 ifAbsent: [ '' ]) ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> initializeFastConnectors [
	"Initialize the global registry of classes that should be passed by value."

	| registry |
	registry := self newFastConnectorRegistry.
	self fastConnectorRegistry: registry.
	self rebuildConnectorObjectRegistry.
	^ registry
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> setTypedWrapperClass: wrapperClass forClient: clientClassName server: serverClassName [
	| key registry |
	key := self connectorObjectKeyForClient: clientClassName server: serverClassName.
	registry := self typedWrapperRegistry copy.
	registry at: key put: wrapperClass.
	Smalltalk globals at: #GbsTypedWrapperRegistry put: registry.
	^ wrapperClass
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> resetConnectorState [
	Smalltalk globals at: #GbsFastConnectorRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorConnectionRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorClassMappingRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorPostConnectActionRegistry put: Dictionary new.
	Smalltalk globals at: #GbsSessionConnectorRegistry put: Dictionary new.
	Smalltalk globals at: #GbsTypedWrapperRegistry put: Dictionary new
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> clearTypedWrapperAutoloadRegistrations [
	self typedWrapperExplicitAutoloadRegistry: Dictionary new.
	self typedWrapperExplicitAutoloadPairRegistry: OrderedCollection new.
	^ self
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperClassForClient: clientClassName server: serverClassName ifAbsentGenerate: aBlock [
	| wrapperClass |
	wrapperClass := self
		typedWrapperClassForClient: clientClassName
		server: serverClassName.
	wrapperClass ifNil: [ ^ aBlock value ].
	^ wrapperClass
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> shouldAutoloadTypedWrapperForClient: clientClassName server: serverClassName [
	^ self
		shouldAutoloadTypedWrapperForClient: clientClassName
		server: serverClassName
		usingRegistry: (self typedWrapperAutoloadRegistryForSession: GbsSessionParameters currentSession)
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> shouldAutoloadTypedWrapperForClient: clientClassName server: serverClassName usingRegistry: registry [
	| clientName serverName |
	clientName := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	serverName := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	(clientName isEmpty or: [ serverName isEmpty ]) ifTrue: [ ^ false ].
	^ ((registry at: clientName ifAbsent: [ nil ]) = serverName)
		or: [ (registry at: serverName ifAbsent: [ nil ]) = clientName ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> shouldRefreshTypedWrapperClass: wrapperClass server: serverClassName [
	^ self
		shouldRefreshTypedWrapperClass: wrapperClass
		server: serverClassName
		session: GbsSessionParameters currentSession
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> invalidateTypedWrapperClassesForServerClassNamed: serverClassName [
	| wrappers |
	wrappers := self typedWrapperClassesForServerClassNamed: serverClassName.
	wrappers do: [ :each | self invalidateTypedWrapperClass: each ].
	^ wrappers
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> invalidateStaleTypedWrapperClassesForSession: aSession [
	| wrappers |
	wrappers := self staleTypedWrapperClassesForSession: aSession.
	wrappers do: [ :each | self invalidateTypedWrapperClass: each ].
	^ wrappers
]

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
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

{ #category : '*GemStone-GBS-Core' }
GbsSessionManager class >> typedWrapperRegistry [
	^ Smalltalk globals
		at: #GbsTypedWrapperRegistry
		ifAbsentPut: [ Dictionary new ]
]
