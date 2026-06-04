Extension { #name : 'GbxReplicatorManager' }

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager class >> activeManagersDo: aBlock [
	| sessionClass registry |
	sessionClass := Smalltalk globals at: #GbsSession ifAbsent: [ ^ self ].
	registry := [ sessionClass weakRegistryNamed: #GbsSessionReplicatorManagers ]
		on: Error
		do: [ ^ self ].
	registry values do: [ :manager |
		manager ifNotNil: [
			[ aBlock value: manager ]
				on: Error
				do: [ ] ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager class >> classFromMethodChangeAnnouncement: anAnnouncement [
	#(classAffected behaviorAffected methodClass affectedClass) do: [ :selector |
		(anAnnouncement respondsTo: selector) ifTrue: [
			| value |
			value := [ anAnnouncement perform: selector ] on: Error do: [ nil ].
			value ifNotNil: [ ^ value ] ] ].
	((anAnnouncement respondsTo: #method)
		and: [ anAnnouncement method respondsTo: #methodClass ]) ifTrue: [
			^ [ anAnnouncement method methodClass ] on: Error do: [ nil ] ].
	((anAnnouncement respondsTo: #method)
		and: [ anAnnouncement method respondsTo: #origin ]) ifTrue: [
			^ [ anAnnouncement method origin ] on: Error do: [ nil ] ].
	^ nil
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager class >> handleSystemMethodChangeAnnouncement: anAnnouncement [
	| selector class |
	selector := self selectorFromMethodChangeAnnouncement: anAnnouncement.
	class := self classFromMethodChangeAnnouncement: anAnnouncement.
	(selector isNil or: [ class isNil ]) ifTrue: [ ^ self ].
	(self selectorMayAffectReplication: selector) ifFalse: [ ^ self ].
	self notifyChangedSelector: selector inClass: class
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager class >> installAutomaticMethodChangeInvalidation [
	| announcerClass announcer eventClasses |
	(Smalltalk globals at: #GbsReplicatorManagerMethodChangeInvalidationInstalled ifAbsent: [ false ]) == true ifTrue: [
		^ true ].
	announcerClass := Smalltalk globals at: #SystemAnnouncer ifAbsent: [ ^ false ].
	announcer := [ announcerClass uniqueInstance ] on: Error do: [ ^ false ].
	eventClasses := self methodChangeEventClassesForAutomaticInvalidation.
	eventClasses isEmpty ifTrue: [ ^ false ].
	eventClasses do: [ :eventClass |
		[ announcer weak
			when: eventClass
			send: #handleSystemMethodChangeAnnouncement:
			to: self ]
			on: Error
			do: [
				[ announcer
					when: eventClass
					send: #handleSystemMethodChangeAnnouncement:
					to: self ]
					on: Error
					do: [ ] ] ].
	Smalltalk globals at: #GbsReplicatorManagerMethodChangeInvalidationInstalled put: true.
	^ true
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager class >> methodChangeEventClassesForAutomaticInvalidation [
	| classes globals |
	globals := Smalltalk globals.
	classes := OrderedCollection new.
	#(MethodAdded MethodModified MethodRemoved MethodRecategorized ClassModifiedClassDefinition) do: [ :name |
		(globals at: name ifAbsent: [ nil ]) ifNotNil: [ :eventClass |
			classes add: eventClass ] ].
	^ classes asArray
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager class >> notifyChangedSelector: aSelector inClass: aClass [
	self activeManagersDo: [ :manager |
		manager changedSelector: aSelector inClass: aClass ].
	^ aClass
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager class >> selectorFromMethodChangeAnnouncement: anAnnouncement [
	(anAnnouncement respondsTo: #selector) ifTrue: [
		^ [ anAnnouncement selector ] on: Error do: [ nil ] ].
	((anAnnouncement respondsTo: #method)
		and: [ anAnnouncement method respondsTo: #selector ]) ifTrue: [
			^ [ anAnnouncement method selector ] on: Error do: [ nil ] ].
	((anAnnouncement respondsTo: #oldMethod)
		and: [ anAnnouncement oldMethod respondsTo: #selector ]) ifTrue: [
			^ [ anAnnouncement oldMethod selector ] on: Error do: [ nil ] ].
	^ nil
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager class >> selectorMayAffectReplication: aSelector [
	| selectorText |
	aSelector ifNil: [ ^ false ].
	(#(
		instVarMap
		instVarNames
		allInstVarNames
		classVersion
		classHistory
		classFormat
		instanceVariables
		replicationSpec
		replicationSpecSet) includes: aSelector) ifTrue: [ ^ true ].
	selectorText := aSelector asString asLowercase.
	^ (selectorText includesSubstring: 'instvarmap')
		or: [ (selectorText includesSubstring: 'replicationspec')
		or: [ (selectorText includesSubstring: 'classversion')
		or: [ selectorText includesSubstring: 'classhistory' ] ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager class >> uninstallAutomaticMethodChangeInvalidation [
	| announcerClass announcer |
	announcerClass := Smalltalk globals at: #SystemAnnouncer ifAbsent: [
		Smalltalk globals
			removeKey: #GbsReplicatorManagerMethodChangeInvalidationInstalled
			ifAbsent: [ ].
		^ false ].
	announcer := [ announcerClass uniqueInstance ] on: Error do: [ nil ].
	announcer ifNotNil: [
		[ announcer unsubscribe: self ] on: Error do: [ ] ].
	Smalltalk globals
		removeKey: #GbsReplicatorManagerMethodChangeInvalidationInstalled
		ifAbsent: [ ].
	^ true
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> currentReplicationScheme [
	^ self clampManager currentReplicationScheme
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> clientClassConnectorForClient: clientClassOrName server: serverClassOrName [
	^ GbsClientClassConnector
		client: clientClassOrName
		server: serverClassOrName
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> clientClassConnectorForClientBehavior: clientBehavior serverBehavior: serverBehavior [
	^ self
		clientClassConnectorForClient: clientBehavior
		server: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> changedSelector: aSelector inClass: aClass [
	| behavior refreshedReplicators |
	behavior := (aClass respondsTo: #soleInstance)
		ifTrue: [ aClass soleInstance ]
		ifFalse: [ aClass ].
	refreshedReplicators := IdentitySet new.
	aClass withAllSubclasses do: [ :class |
		| replicator mappedBehavior |
		mappedBehavior := (class respondsTo: #soleInstance)
			ifTrue: [ class soleInstance ]
			ifFalse: [ class ].
		replicator := self replicatorForClientBehavior: mappedBehavior ifAbsent: [ nil ].
		(replicator notNil and: [ (refreshedReplicators includes: replicator) not ]) ifTrue: [
			refreshedReplicators add: replicator.
			(self selectorRequiresServerOffsetRefresh: aSelector) ifTrue: [
				(replicator respondsTo: #initializeServerOffsets) ifTrue: [
					replicator initializeServerOffsets ] ].
			(self clampManager respondsTo: #changedSelector:forReplicator:) ifTrue: [
				self clampManager changedSelector: aSelector forReplicator: replicator ] ] ].
	^ behavior
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectReplicator: aReplicator toServerBehavior: serverBehavior [
	serverMap at: serverBehavior put: aReplicator.
	^ aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorBehaviorNamesFromMap: aDictionary [
	| names |
	names := OrderedCollection new.
	aDictionary keysAndValuesDo: [ :behavior :replicator |
		names add: (self connectorNameForBehavior: behavior) ].
	^ names asArray sort
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorConnectionStateStringsForRows: rows [
	^ rows collect: [ :row |
		self connectorConnectionStringForReportRow: row ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorConnectionStringForReportRow: row [
	| clientName serverName action connected |
	clientName := row at: #client ifAbsent: [ '' ].
	serverName := row at: #server ifAbsent: [ '' ].
	action := row at: #postConnectAction ifAbsent: [ 'none' ].
	connected := row at: #connected ifAbsent: [ false ].
	^ clientName asString,
		'->',
		serverName asString,
		' ',
		(connected ifTrue: [ 'connected' ] ifFalse: [ 'disconnected' ]),
		' postConnect=',
		action asString
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorConnectionRowsForReport [
	| sessionKey rows |
	sessionKey := GbsSessionManager sessionKeyForSessionObject: self session.
	rows := OrderedCollection new.
	self connectorPairsForReport do: [ :pair |
		| clientName serverName connector action connected |
		clientName := pair at: 1 ifAbsent: [ '' ].
		serverName := pair at: 2 ifAbsent: [ '' ].
		connector := GbsSessionManager
			connectorObjectForClient: clientName
			server: serverName.
		action := (connector notNil and: [ connector respondsTo: #postConnectAction ])
			ifTrue: [ connector postConnectAction ]
			ifFalse: [
				GbsSessionManager
					postConnectActionForConnectorClient: clientName
					server: serverName ].
		connected := GbsSessionManager
			isConnectorClient: clientName
			server: serverName
			connectedInSession: sessionKey.
		rows add: (Dictionary new
			at: #client put: clientName asString;
			at: #server put: serverName asString;
			at: #connected put: connected;
			at: #postConnectAction put: action asString;
			yourself) ].
	^ rows asArray
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorManagerReport [
	| report pairs clamps connectionRows |
	pairs := self connectorPairsForReport.
	clamps := [ self identityClamps ] on: Error do: [ #() ].
	connectionRows := self connectorConnectionRowsForReport.
	report := Dictionary new
		at: #clientMapSize put: clientMap size;
		at: #serverMapSize put: serverMap size;
		at: #replicatorCount put: self numberOfReplicators;
		at: #clientAliasCount put: (clientMap size - self numberOfReplicators max: 0);
		at: #connectorPairCount put: pairs size;
		at: #connectedConnectorPairCount put: (connectionRows count: [ :row | row at: #connected ifAbsent: [ false ] ]);
		at: #disconnectedConnectorPairCount put: (connectionRows count: [ :row | (row at: #connected ifAbsent: [ false ]) not ]);
		at: #needsServerInstVarNames put: self needsServerInstVarNames;
		at: #deferredServerInstVarReplicatorCount put: self replicatorsNeedingServerInstVarNames size;
		at: #clientBehaviorNames put: (self connectorBehaviorNamesFromMap: clientMap);
		at: #serverBehaviorNames put: (self connectorBehaviorNamesFromMap: serverMap);
		at: #connectorConnectionStates put: (self connectorConnectionStateStringsForRows: connectionRows);
		at: #currentReplicationSpecSet put: self defaultReplicationSpecSet;
		at: #identityClampCount put: clamps size;
		yourself.
	^ report
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorManagerReportText [
	| report |
	report := self connectorManagerReport.
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Replicator Manager';
			cr;
			cr.
		#(
			clientMapSize
			serverMapSize
			replicatorCount
			clientAliasCount
			connectorPairCount
			connectedConnectorPairCount
			disconnectedConnectorPairCount
			needsServerInstVarNames
			deferredServerInstVarReplicatorCount
			currentReplicationSpecSet
			identityClampCount
			connectorConnectionStates
			clientBehaviorNames
			serverBehaviorNames) do: [ :key |
				stream
					nextPutAll: key asString;
					nextPutAll: '=';
					nextPutAll: (self connectorReportValueString: (report at: key ifAbsent: [ nil ]));
					cr ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorClassVersionReportForClient: clientName server: serverName [
	| connector clientConnector |
	connector := GbsSessionManager
		connectorObjectForClient: clientName
		server: serverName.
	clientConnector := (connector notNil and: [
		connector respondsTo: #clientClassConnectorForSession: ])
			ifTrue: [
				[ connector clientClassConnectorForSession: self session ]
					on: Error
					do: [ nil ] ]
			ifFalse: [ nil ].
	clientConnector ifNil: [
		clientConnector := GbsClientClassConnector
			client: clientName
			server: serverName ].
	^ [ clientConnector verifyClassVersionsInSession: self session ]
		on: Error
		do: [ :ex |
			Dictionary new
				at: #client put: clientName asString;
				at: #server put: serverName asString;
				at: #clientVersion put: nil;
				at: #serverVersion put: nil;
				at: #versionStatus put: #error;
				at: #needsUpdate put: false;
				at: #versionMatches put: true;
				at: #error put: ex messageText;
				yourself ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorClassVersionReports [
	| reports |
	reports := OrderedCollection new.
	self connectorPairsForReport do: [ :pair |
		reports add: (self
			connectorClassVersionReportForClient: (pair at: 1 ifAbsent: [ '' ])
			server: (pair at: 2 ifAbsent: [ '' ])) ].
	^ reports asArray
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorLifecycleReport [
	| managerReport versionReports |
	managerReport := self connectorManagerReport.
	versionReports := self connectorClassVersionReports.
	^ Dictionary new
		at: #connectorPairCount put: self connectorPairsForReport size;
		at: #connectedConnectorPairCount put: (managerReport
			at: #connectedConnectorPairCount
			ifAbsent: [ 0 ]);
		at: #disconnectedConnectorPairCount put: (managerReport
			at: #disconnectedConnectorPairCount
			ifAbsent: [ 0 ]);
		at: #classVersionReports put: versionReports;
		at: #classVersionReportCount put: versionReports size;
		at: #classVersionMismatchCount put: (versionReports count: [ :report |
			(report at: #versionStatus ifAbsent: [ #unknown ]) = #mismatch ]);
		at: #classVersionUnknownCount put: (versionReports count: [ :report |
			(report at: #versionStatus ifAbsent: [ #unknown ]) = #unknown ]);
		at: #classVersionErrorCount put: (versionReports count: [ :report |
			(report at: #versionStatus ifAbsent: [ #unknown ]) = #error ]);
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorNameForBehavior: aBehaviorOrName [
	aBehaviorOrName ifNil: [ ^ '' ].
	(aBehaviorOrName respondsTo: #name) ifTrue: [
		^ aBehaviorOrName name asString ].
	^ aBehaviorOrName asString
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorPairsForReport [
	self session ifNil: [ ^ GbsSessionManager connectorPairs ].
	^ GbsSessionManager connectorPairsForSession: self session
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> connectorReportValueString: anObject [
	anObject ifNil: [ ^ 'nil' ].
	anObject == true ifTrue: [ ^ 'true' ].
	anObject == false ifTrue: [ ^ 'false' ].
	anObject isSymbol ifTrue: [ ^ anObject asString ].
	anObject isString ifTrue: [ ^ anObject ].
	(anObject isKindOf: Array) ifTrue: [
		anObject isEmpty ifTrue: [ ^ 'none' ].
		^ String streamContents: [ :stream |
			anObject doWithIndex: [ :each :index |
				index > 1 ifTrue: [ stream nextPutAll: ', ' ].
				stream nextPutAll: each asString ] ] ].
	^ anObject printString
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> defaultReplicationSpecSet [
	^ self clampManager defaultReplicationSpecSet
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> defaultReplicationSpecSet: aSymbol [
	^ self clampManager defaultReplicationSpecSet: aSymbol
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> identityClamps [
	^ self clampManager identityClamps
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> mapReplicatorForClientBehavior: clientBehavior serverBehavior: serverBehavior [
	| replicator |
	replicator := (self replicatorClassForClientBehavior: clientBehavior) new.
	(replicator respondsTo: #manager:) ifTrue: [ replicator manager: self ].
	(replicator respondsTo: #session:) ifTrue: [ replicator session: self session ].
	(replicator respondsTo: #clientClass:) ifTrue: [ replicator clientClass: clientBehavior ].
	(replicator respondsTo: #serverClass:) ifTrue: [ replicator serverClass: serverBehavior ].
	self atClient: clientBehavior andServer: serverBehavior put: replicator.
	self updateClassClampForReplicator: replicator.
	^ replicator
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> installClientClassConnector: aConnector [
	^ aConnector installInReplicatorManager: self
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> updateSTForClientClassConnector: aConnector [
	^ aConnector updateSTInSession: self session
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> updateGSForClientClassConnector: aConnector [
	^ aConnector updateGSInSession: self session
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> verifyClassVersionsForClientClassConnector: aConnector [
	^ aConnector verifyClassVersionsInSession: self session
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> installClientClassConnectorForClientBehavior: clientBehavior serverBehavior: serverBehavior [
	^ self installClientClassConnector:
		(self
			clientClassConnectorForClientBehavior: clientBehavior
			serverBehavior: serverBehavior)
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> installClientClassConnectorForClientBehavior: clientBehavior serverBehavior: serverBehavior replicationSpec: aReplicationSpec serverInstVarNames: instVarNames [
	^ self installClientClassConnector:
		(GbsClientClassConnector
			client: clientBehavior
			server: serverBehavior
			replicationSpec: aReplicationSpec
			serverInstVarNames: instVarNames)
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> markServerInstVarNamesNeededByReplicator: aReplicator [
	^ self serverInstVarNamesNeededByReplicator: aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> needsServerInstVarNames [
	^ needServerInstVarNames == true
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> invalidateSchemeWithSelector: aSelector [
	^ self clampManager invalidateSchemeWithSelector: aSelector
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> newClampManagerFor: aSession [
	| clampClass |
	aSession ifNil: [ ^ nil ].
	clampClass := (aSession respondsTo: #clampManagerClass)
		ifTrue: [ aSession clampManagerClass ]
		ifFalse: [ GbxClampManager ].
	^ clampClass forManager: self
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> replicationSchemeForSet: setSymbol [
	^ self clampManager replicationSchemeForSet: setSymbol
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> replicatorClassForClientBehavior: clientBehavior [
	((clientBehavior respondsTo: #instancesAreForwarders)
		and: [ [ clientBehavior instancesAreForwarders ] on: Error do: [ false ] ]) ifTrue: [
			^ Smalltalk globals at: #GbxForwarderReplicator ifAbsent: [ self defaultReplicatorClass ] ].
	(clientBehavior respondsTo: #gbsReplicatorClassInSession:) ifTrue: [
		^ clientBehavior gbsReplicatorClassInSession: self session ].
	^ self defaultReplicatorClass
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> replicatorsNeedingServerInstVarNames [
	^ replicatorsNeedingServerInstVarNames asArray
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> removeClientClassConnectorForClientBehavior: clientBehavior serverBehavior: serverBehavior [
	^ self
		removeReplicatorForClientBehavior: clientBehavior
		andServerBehavior: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> serverMap [
	^ serverMap
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> selectorRequiresServerOffsetRefresh: aSelector [
	(self class selectorMayAffectReplication: aSelector) ifFalse: [ ^ false ].
	^ (#(
		instVarMap
		instVarNames
		allInstVarNames
		classVersion
		classHistory
		classFormat
		instanceVariables) includes: aSelector)
		or: [
			| selectorText |
			selectorText := aSelector asString asLowercase.
			(selectorText includesSubstring: 'instvarmap')
				or: [ (selectorText includesSubstring: 'classversion')
				or: [ selectorText includesSubstring: 'classhistory' ] ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> setReplicatorForClient: secondaryBehavior sameAsReplicatorForClient: primaryBehavior [
	| replicator |
	replicator := self
		replicatorForClientBehavior: primaryBehavior
		ifAbsent: [ self error: 'Attempted second mapping without first mapping present.' ].
	self atClient: secondaryBehavior put: replicator.
	^ replicator
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> unregisterConnectorPairForClientBehavior: clientBehavior serverBehavior: serverBehavior [
	| session clientName serverName |
	clientName := self connectorNameForBehavior: clientBehavior.
	serverName := self connectorNameForBehavior: serverBehavior.
	(clientName isEmpty or: [ serverName isEmpty ]) ifTrue: [ ^ self ].
	session := self session.
	session
		ifNil: [
			GbsSessionManager
				removeConnectorClient: clientName
				server: serverName ]
		ifNotNil: [
			GbsSessionManager
				removeConnectorClient: clientName
				server: serverName
				forSession: session ].
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> unregisterConnectorPairsForClientBehaviors: clientBehaviors serverBehaviors: serverBehaviors [
	clientBehaviors do: [ :clientBehavior |
		serverBehaviors do: [ :serverBehavior |
			self
				unregisterConnectorPairForClientBehavior: clientBehavior
				serverBehavior: serverBehavior ] ].
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> updateClassClampForReplicator: aReplicator [
	(self clampManager respondsTo: #updateClassClampForReplicator:) ifTrue: [
		^ self clampManager updateClassClampForReplicator: aReplicator ].
	^ aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicatorManager >> usingReplicationSpecSet: setSymbol do: aBlock [
	^ self clampManager usingReplicationSpecSet: setSymbol do: aBlock
]
