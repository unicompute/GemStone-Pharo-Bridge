Extension { #name : 'GbsClassConnector' }

{ #category : '*GemStone-GBS-Core' }
GbsClassConnector >> clientClassConnectorForSession: aSession [
	| client server connector |
	client := self resolveSTObjMustBeDefined: true.
	server := self resolveGSObjInSession: aSession ifFail: [ self gsName ].
	connector := GbsClientClassConnector
		client: client
		server: server
		replicationSpec: (self replicationSpecForClientBehavior: client)
		serverInstVarNames: #().
	connector
		clientBehaviorName: self stName;
		serverBehaviorName: self gsName.
	^ connector
]

{ #category : '*GemStone-GBS-Core' }
GbsClassConnector >> connectInSession: aSession ifFail: oneArgBlock [
	| manager connector |
	^ [
		manager := aSession replicatorManager.
		GbsSessionManager
			registerConnectorObject: self
			forClient: self stName
			server: self gsName.
		GbsSessionManager
			setPostConnectAction: self postConnectAction
			forConnectorClient: self stName
			server: self gsName.
		connector := self clientClassConnectorForSession: aSession.
		manager installClientClassConnector: connector.
		GbsSessionManager
			addConnectorClient: self stName
			server: self gsName
			forSession: aSession.
		self setConnected: true forSessionKey: (self sessionKeyFor: aSession) ]
		on: Error
		do: [ :ex |
			oneArgBlock cull: ex.
			false ]
]

{ #category : '*GemStone-GBS-Core' }
GbsClassConnector >> disconnectInSession: aSession [
	| manager client server |
	client := self resolveSTObjMustBeDefined: false.
	server := self resolveGSObjInSession: aSession ifFail: [ self gsName ].
	manager := [ aSession replicatorManager ] on: Error do: [ nil ].
	(manager notNil and: [ client notNil ]) ifTrue: [
		manager
			removeReplicatorForClientBehavior: client
			andServerBehavior: server ].
	GbsSessionManager
		removeConnectorClient: self stName
		server: self gsName
		forSession: aSession.
	^ self setConnected: false forSessionKey: (self sessionKeyFor: aSession)
]

{ #category : '*GemStone-GBS-Core' }
GbsClassConnector >> isClassConnector [
	^ true
]

{ #category : '*GemStone-GBS-Core' }
GbsClassConnector >> isClassConnectorTypeNone [
	^ self postConnectAction asString asLowercase = 'none'
]

{ #category : '*GemStone-GBS-Core' }
GbsClassConnector >> replicationSpecForClientBehavior: aBehavior [
	^ (aBehavior respondsTo: #replicationSpec)
		ifTrue: [ aBehavior replicationSpec ]
		ifFalse: [ #() ]
]

{ #category : '*GemStone-GBS-Core' }
GbsClassConnector >> resolveClientObj [
	^ self resolveSTObjMustBeDefined: true
]

{ #category : '*GemStone-GBS-Core' }
GbsClassConnector >> resolveSTObjMustBeDefined: enforceBoolean [
	| name resolved isClassLike isMetaClass |
	name := self stName asString trimBoth.
	name isEmpty ifTrue: [
		enforceBoolean ifTrue: [ self error: 'Client class name is empty.' ].
		^ nil ].
	resolved := Smalltalk globals at: name asSymbol ifAbsent: [ nil ].
	resolved ifNil: [
		enforceBoolean ifTrue: [ self error: 'Failed to resolve the client class named ', name, '.' ].
		^ nil ].
	isClassLike := ((resolved respondsTo: #isBehavior)
		and: [ resolved isBehavior ]) or: [
			(resolved respondsTo: #isClass)
				and: [ resolved isClass ] ].
	isMetaClass := (resolved respondsTo: #isMeta)
		ifTrue: [ resolved isMeta ]
		ifFalse: [
			(resolved respondsTo: #isMetaClass)
				ifTrue: [ resolved isMetaClass ]
				ifFalse: [ false ] ].
	(isClassLike and: [ isMetaClass not ]) ifFalse: [
		self error: 'The client object named ', name, ' is not a class.' ].
	^ resolved
]
